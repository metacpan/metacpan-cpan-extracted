#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(getcwd);
use File::Temp qw(tempdir);
use HTTP::Request::Common qw(GET POST);
use Test::More;

use lib 'lib';
use lib 't/lib';

use Developer::Dashboard::Auth;
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::SessionStore;
use Developer::Dashboard::Web::App;
use Developer::Dashboard::Web::DancerApp;
use Local::PSGITest;

# decoded_attr_value($value)
# Decodes one HTML attribute value the way a browser does before it uses the
# value: attribute text is entity-escaped markup, so the URL a browser
# actually requests is the entity-decoded form.
# Input: raw attribute text captured from a response body.
# Output: entity-decoded attribute value string.
sub decoded_attr_value {
    my ($value) = @_;
    return $value if !defined $value;
    $value =~ s/&lt;/</g;
    $value =~ s/&gt;/>/g;
    $value =~ s/&quot;/"/g;
    $value =~ s/&#39;/'/g;
    $value =~ s/&amp;/&/g;
    return $value;
}

# drain($body)
# Flattens one PSGI body array reference into a plain string.
# Input: PSGI response body array reference.
# Output: concatenated body string.
sub drain {
    my ($body) = @_;
    return join '', @{ $body || [] };
}

my $repo_root = getcwd();

# Hermetic runtime: layer discovery and Config resolution both walk from the
# process HOME and the deepest .developer-dashboard layer beneath the current
# working directory, so anchor HOME and the CWD in one throwaway temp dir.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
delete local $ENV{DEVELOPER_DASHBOARD_SSL_PROXIED};
delete local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS};
delete local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
chdir $home or die "Unable to chdir to $home: $!";

my $paths    = Developer::Dashboard::PathRegistry->new( home => $home );
my $files    = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $store    = Developer::Dashboard::PageStore->new( paths => $paths );
my $config   = Developer::Dashboard::Config->new( files => $files, paths => $paths );
my $auth     = Developer::Dashboard::Auth->new( files => $files, paths => $paths );
my $sessions = Developer::Dashboard::SessionStore->new( paths => $paths );

my $app = Developer::Dashboard::Web::App->new(
    auth     => $auth,
    config   => $config,
    pages    => $store,
    sessions => $sessions,
);

my $separator = ':' . ( '-' x 80 ) . ':';

# ---------------------------------------------------------------------------
# 1. The test harness must obey the PSGI spec the way real servers do:
#    Starman (HTTP::Parser::XS) and HTTP::Message::PSGI both hand the
#    application a percent-DECODED PATH_INFO and keep the raw request target
#    in REQUEST_URI. A harness that forwards the encoded path unchanged hides
#    every encoding defect this file exists to pin.
# ---------------------------------------------------------------------------
{
    my $echo = sub {
        my ($env) = @_;
        my $seen = join '|', $env->{PATH_INFO}, ( $env->{REQUEST_URI} // '(none)' );
        return [ 200, [ 'Content-Type' => 'text/plain' ], [$seen] ];
    };
    my $res = Local::PSGITest::request( $echo, GET 'http://127.0.0.1/app/a%20b/c%2523d?x=%20' );
    is(
        $res->content,
        '/app/a b/c%23d|/app/a%20b/c%2523d?x=%20',
        'the harness decodes PATH_INFO exactly once and keeps REQUEST_URI raw, like production servers',
    );
}

# ---------------------------------------------------------------------------
# 2. TDD core: saving a bookmark whose id carries spaces, %, and # must emit
#    chrome links that are valid URLs - every path segment percent-encoded,
#    the / separator between segments kept raw - and each generated link must
#    reach the same page back through the real Dancer route table.
# ---------------------------------------------------------------------------
my $psgi_app = Developer::Dashboard::Web::DancerApp->build_psgi_app( app => $app );

{
    my $id     = 'team kpis/50% done #2';
    my $marker = 'dd423-marker-alpha';
    my $instruction = join "\n",
      'TITLE: Special KPI',
      $separator,
      "BOOKMARK: $id",
      $separator,
      "HTML: <p>$marker</p>";
    my $expected_href = '/app/team%20kpis/50%25%20done%20%232';

    Local::PSGITest::test_psgi $psgi_app, sub {
        my ($cb) = @_;

        my $save = $cb->(
            POST 'http://127.0.0.1/',
            Content => [ instruction => $instruction, mode => 'edit' ],
        );
        is( $save->code, 200, 'saving the special-character bookmark answers 200' );

        my ($play) = $save->content =~ /data-play-url="([^"]*)"/;
        $play = decoded_attr_value($play);
        is(
            $play,
            $expected_href,
            'the play link percent-encodes every special character per segment and keeps the / separator raw',
        );

        my ($share) = $save->content =~ /<a href="([^"]*)" id="share-url">/;
        $share = decoded_attr_value($share);
        is( $share, $expected_href . '/edit', 'the share link is the encoded editor URL' );

        my ($form_action) = $save->content =~ /<form[^>]*\baction="([^"]*)"/;
        $form_action = decoded_attr_value($form_action);
        is( $form_action, $expected_href . '/edit', 'the editor form posts to the encoded editor URL' );

        my $render = $cb->( GET 'http://127.0.0.1' . $play );
        is( $render->code, 200, 'the generated play link is reachable end-to-end' );
        like( $render->content, qr/\Q$marker\E/, 'the play link renders the saved page body' );

        my $edit = $cb->( GET 'http://127.0.0.1' . $share );
        is( $edit->code, 200, 'the generated share link opens the editor' );
        like( $edit->content, qr/\Q$marker\E/, 'the editor loads the same saved source' );

        my $updated_marker      = 'dd423-marker-alpha-updated';
        my $updated_instruction = join "\n",
          'TITLE: Special KPI',
          $separator,
          "BOOKMARK: $id",
          $separator,
          "HTML: <p>$updated_marker</p>";
        my $post = $cb->(
            POST 'http://127.0.0.1' . $form_action,
            Content => [ instruction => $updated_instruction, mode => 'edit' ],
        );
        is( $post->code, 200, 'posting through the encoded form action answers 200' );
        like(
            $store->read_saved_entry($id),
            qr/\Q$updated_marker\E/,
            'the encoded form action round-trips to the same saved bookmark file',
        );
    };
}

# ---------------------------------------------------------------------------
# 3. Symmetry pin: an id that contains literal percent-sequence TEXT must
#    round-trip unchanged. The href double-encodes the literal %, the server
#    decodes exactly once, and the handler sees the true id again. Without
#    outbound encoding a production server would decode the raw href's %20
#    and load the wrong page.
# ---------------------------------------------------------------------------
{
    my $id     = 'release a%20b';
    my $marker = 'dd423-marker-beta';
    my $instruction = join "\n",
      'TITLE: Literal Percent',
      $separator,
      "BOOKMARK: $id",
      $separator,
      "HTML: <p>$marker</p>";

    Local::PSGITest::test_psgi $psgi_app, sub {
        my ($cb) = @_;

        my $save = $cb->(
            POST 'http://127.0.0.1/',
            Content => [ instruction => $instruction, mode => 'edit' ],
        );
        is( $save->code, 200, 'saving the literal-percent bookmark answers 200' );

        my ($play) = $save->content =~ /data-play-url="([^"]*)"/;
        $play = decoded_attr_value($play);
        is( $play, '/app/release%20a%2520b', 'the literal % in the id is itself percent-encoded' );

        my $render = $cb->( GET 'http://127.0.0.1' . $play );
        is( $render->code, 200, 'the double-encoded link resolves' );
        like(
            $render->content,
            qr/\Q$marker\E/,
            'one server-side decode returns the literal-percent id, not a double-decoded one',
        );
    };
}

# ---------------------------------------------------------------------------
# 4. Unit pins for the two URL spaces: the href builder encodes per segment,
#    while the canonical path builder stays decoded because request-context
#    paths and the BOOKMARK: document field live in decoded PATH_INFO space.
# ---------------------------------------------------------------------------
{
    is( $app->_saved_page_href(''), '', 'an empty id builds no href' );
    is( $app->_saved_page_href('a b'), '/app/a%20b', 'a single segment is percent-encoded' );
    is(
        $app->_saved_page_href('/app//team kpis//50% done #2/'),
        '/app/team%20kpis/50%25%20done%20%232',
        'prefix stripping and separator collapsing match the canonical path builder',
    );
    is( $app->_saved_page_url('a b'), '/app/a b', 'the canonical path builder stays in decoded space' );
}

# ---------------------------------------------------------------------------
# 5. Out-of-scope guard from the ticket: the transient play URL keeps its
#    raw ?, &, and = separators; only the token value is escaped.
# ---------------------------------------------------------------------------
{
    my $transient = Developer::Dashboard::PageDocument->from_instruction(
        join "\n", 'TITLE: Transient', $separator, 'HTML: transient body' );
    my $render_url = $store->render_url($transient);
    like(
        $render_url,
        qr{\A/\?mode=render&token=}, 'the transient play URL separators stay unencoded',
    );
    my ($token) = $render_url =~ /token=(.*)\z/s;
    unlike( $token, qr/[?&=#\s]/, 'the transient token itself carries no raw separator characters' );
}

chdir $repo_root or die "Unable to chdir back to $repo_root: $!";

done_testing();

__END__

=pod

=encoding UTF-8

=head1 NAME

t/131-bookmark-url-encoding.t - saved bookmark links percent-encode special characters and stay reachable

=head1 WHAT IT IS

An end-to-end and unit regression suite for the browser links the web layer
generates for saved bookmarks whose ids contain URL-special characters such
as spaces, C<%>, and C<#>.

=head1 WHAT IT IS FOR

It pins four contracts. First, the local PSGI test harness must behave like
production servers: C<PATH_INFO> arrives percent-decoded exactly once and
C<REQUEST_URI> keeps the raw request target. Second, saving a bookmark whose
id contains special characters must emit play, share, and form-action links
whose path segments are percent-encoded while the C</> separators stay raw,
and every generated link must resolve back to the same page through the real
Dancer2 route table. Third, an id containing literal percent-sequence text
must survive the encode-then-decode round trip unchanged. Fourth, the
transient play URL keeps its raw query separators, with only the token value
escaped.

=head1 PURPOSE

Keep every generated saved-bookmark link a valid, reachable URL whatever
special characters the bookmark id carries, and keep the local test harness
faithful to how production servers decode request paths.

=head1 WHY IT EXISTS

The web layer used to interpolate raw bookmark ids into C</app/> hyperlinks.
A C<#> truncated the path at the fragment, a C<?> started a bogus query, and
a literal C<%> was mis-decoded by the server, so the generated link either
opened the wrong page or nothing at all. The harness hid this by forwarding
encoded paths straight through, which no real server does.

=head1 WHEN TO USE

Run it whenever bookmark link generation, saved page routing, or the PSGI
test harness changes.

=head1 HOW TO USE

    prove -lv t/131-bookmark-url-encoding.t

=head1 WHAT USES IT

The standard C<prove -lr t> gate and the release pipeline run it.

=head1 EXAMPLES

    # Full suite
    prove -lr t

    # Just this contract
    prove -lv t/131-bookmark-url-encoding.t

=cut

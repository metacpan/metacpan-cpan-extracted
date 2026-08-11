#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Cwd qw(getcwd);
use File::Find qw(find);
use File::Spec;
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

# The source-scan guard reads lib/ directly, so record the checkout root before
# the hermetic chdir moves the process into a throwaway home.
my $repo_root = getcwd();

# Hermetic runtime: the layer stack and Config discovery both resolve from the
# process HOME and from the deepest .developer-dashboard layer beneath the
# current working directory, so anchor HOME and the CWD in one temp dir.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
delete local $ENV{DEVELOPER_DASHBOARD_SSL_PROXIED};
delete local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS};
delete local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
chdir $home or die "Unable to chdir to $home: $!";

# One payload used throughout: a double quote closes the attribute, the angle
# brackets open a tag, and the tag is one that executes with no interaction.
my $PAYLOAD = 'probe"><svg onload=alert(1)>';
my $BREAKOUT = qr/"><svg onload=alert\(1\)>/;

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

sub drain {
    my ($body) = @_;
    return $body if ref($body) ne 'HASH' || ref( $body->{stream} ) ne 'CODE';
    my $out = '';
    $body->{stream}->( sub { $out .= $_[0] if defined $_[0] } );
    return $out;
}

# ---------------------------------------------------------------------------
# 1. TDD unit: the web layer needs an escaper that is safe inside a quoted
#    HTML attribute. The plain text escaper deliberately leaves quotes alone
#    (they are harmless in element text), so a separate attribute escaper must
#    neutralise both quote characters as well as the markup characters.
# ---------------------------------------------------------------------------
{
    my $escape_attr = Developer::Dashboard::Web::App->can('_escape_html_attr');
    ok( $escape_attr, 'the web layer exposes an attribute-context escaper' );

    if ($escape_attr) {
        is(
            $escape_attr->(q{<a> & "b" 'c'}),
            q{&lt;a&gt; &amp; &quot;b&quot; &#39;c&#39;},
            'the attribute escaper neutralises angle brackets, ampersands, and both quote characters',
        );
        is( $escape_attr->(undef), '', 'the attribute escaper treats an undefined value as empty' );
        is( $escape_attr->('/app/plain'), '/app/plain', 'the attribute escaper leaves an ordinary route untouched' );
    }
}

# ---------------------------------------------------------------------------
# 2. BDD: a saved bookmark whose id carries attribute-breakout characters must
#    not put an executable tag into the rendered page or the editor. PageStore
#    only rejects traversal components, so a quote in a BOOKMARK id reaches the
#    route builders and used to close the href/action attribute it landed in.
# ---------------------------------------------------------------------------
{
    my $page = Developer::Dashboard::PageDocument->new(
        id     => $PAYLOAD,
        title  => 'Planted',
        layout => { body => '<p>planted</p>' },
    );
    $store->save_page($page);

    for my $route ( "/app/$PAYLOAD", "/app/$PAYLOAD/edit" ) {
        my $res  = $app->handle( path => $route, remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } );
        my $body = drain( $res->[2] );
        is( $res->[0], 200, "hostile bookmark id still serves $route" );
        unlike( $body, $BREAKOUT, "$route does not break out of an HTML attribute into an executable tag" );
        # The URL builders percent-encode the id before it ever reaches the
        # attribute escaper, so the id survives as inert, valid-URL text
        # instead of raw markup characters that only entity-escaping defuses.
        like( $body, qr/probe%22%3E%3Csvg/, "$route carries the bookmark id percent-encoded in its URL attributes" );
    }
}

# ---------------------------------------------------------------------------
# 3. Unit: the shared chrome builder is the site that emits the play, source,
#    and share URLs, so it must escape them whatever route strings it is given.
# ---------------------------------------------------------------------------
{
    my $page = Developer::Dashboard::PageDocument->new(
        id     => 'chrome-probe',
        title  => 'Chrome Probe',
        layout => { body => '<p>chrome</p>' },
    );
    my $chrome = $app->_top_chrome_html(
        $page,
        {
            edit   => "/app/$PAYLOAD/edit",
            render => "/app/$PAYLOAD",
            source => "/app/$PAYLOAD/edit",
        },
    );
    unlike( $chrome, $BREAKOUT, 'the shared top chrome escapes the play, source, and share URLs' );
    like( $chrome, qr/data-play-url="[^"]*probe&quot;/, 'the play button keeps the escaped route in its data attribute' );
}

# ---------------------------------------------------------------------------
# 3b. The transient play URL carries a query string, and an ampersand is only
#     markup-legal inside an attribute as &amp;. Escaping it is therefore part
#     of the contract, not an accident: a browser decodes the entity when it
#     reads the attribute, so the round trip still works, and any scrape that
#     replays the value must decode it the same way.
# ---------------------------------------------------------------------------
{
    local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS} = 1;
    my $posted = $app->handle(
        path        => '/',
        method      => 'POST',
        body        => 'instruction=' . 'TITLE%3A%20Transient%0A%3A' . ( '-' x 80 ) . '%3A%0AHTML%3A%20body%0A',
        remote_addr => '127.0.0.1',
        headers     => { host => '127.0.0.1' },
    );
    my ($attr) = drain( $posted->[2] ) =~ m{data-play-url="([^"]+)"};
    ok( $attr, 'the transient editor response still exposes a play URL' );
    like( $attr, qr/&amp;/, 'the play URL escapes its query separator as an entity, as attribute markup requires' );
    unlike( $attr, qr/[^&]&(?!amp;|quot;|lt;|gt;|#39;)/, 'the play URL leaves no bare ampersand in the attribute' );

    ( my $decoded = $attr ) =~ s/&amp;/&/g;
    my ($query) = $decoded =~ /\?(.*)\z/;
    my $replayed = $app->handle( path => '/', query => $query, remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } );
    is( $replayed->[0], 200, 'the decoded play URL still round-trips through token query parsing' );
    like( drain( $replayed->[2] ), qr/body/, 'the decoded play URL replays the transient page body' );
}

# ---------------------------------------------------------------------------
# 4. ATDD: the exploitable chain end to end over the real Dancer route table.
#    When DD-421 landed, a loopback client was auto-admin with no CSRF check,
#    so a page the operator visits could auto-submit this POST from a foreign
#    origin and the escaping alone had to keep the response inert. DD-422 then
#    added the Origin/Referer defense, so today the same drive-by submission
#    must die at the front door: an empty 403 before any save happens.
# ---------------------------------------------------------------------------
{
    my $psgi_app = Developer::Dashboard::Web::DancerApp->build_psgi_app( app => $app );

    my $separator   = ':' . ( '-' x 80 ) . ':';
    my $instruction = join "\n",
      'TITLE: Drive By',
      $separator,
      "BOOKMARK: $PAYLOAD",
      $separator,
      'HTML: <p>drive by</p>';

    Local::PSGITest::test_psgi $psgi_app, sub {
        my ($cb) = @_;

        my $save = $cb->(
            POST 'http://127.0.0.1/',
            Origin  => 'http://evil.example',
            Referer => 'http://evil.example/trap.html',
            Content => [ instruction => $instruction, mode => 'edit' ],
        );
        is( $save->code, 403, 'the foreign-origin drive-by save is rejected outright since DD-422' );
        is(
            $save->content,
            q{},
            'the rejection body is empty, so nothing built from the submitted bookmark id can render',
        );

        my $render = $cb->( GET 'http://127.0.0.1/app/chrome-probe' );
        is( $render->code, 200, 'an ordinary saved page still renders after the escaping change' );
    };
}

# ---------------------------------------------------------------------------
# 5. Regression guard: no module under lib/ may interpolate a bare variable
#    into a quoted HTML attribute. Every such value must pass through an
#    escaper first, so the whole class stays closed instead of just the three
#    sites this ticket found.
# ---------------------------------------------------------------------------
{
    my @offenders;
    find(
        {
            no_chdir => 1,
            wanted   => sub {
                return if $File::Find::name !~ /\.pm\z/;
                open my $fh, '<', $File::Find::name
                  or die "Unable to read $File::Find::name: $!";
                my $line_number = 0;
                while ( my $line = <$fh> ) {
                    $line_number++;
                    next if $line !~ /(?:href|src|action|data-[a-z-]+)="\$[A-Za-z_][A-Za-z0-9_]*"/;
                    my $rel = File::Spec->abs2rel( $File::Find::name, $repo_root );
                    push @offenders, "$rel:$line_number";
                }
                close $fh or die "Unable to close $File::Find::name: $!";
            },
        },
        File::Spec->catdir( $repo_root, 'lib' ),
    );
    is_deeply( \@offenders, [], 'no lib/ module interpolates an unescaped variable into a quoted HTML attribute' )
      or diag( join "\n", @offenders );
}

chdir $repo_root or die "Unable to chdir back to $repo_root: $!";

done_testing();

__END__

=pod

=head1 NAME

t/126-attribute-escaping.t - page-derived values stay inert inside HTML attributes

=head1 PURPOSE

This test is the injection contract for the web layer's HTML attributes. A
saved bookmark id is attacker-influenced data: it comes from the C<BOOKMARK:>
directive of a submitted instruction, and the page store only rejects
traversal components, so quotes and angle brackets reach the route builders
intact. Every route string the web chrome and the bookmark editor interpolate
into a quoted attribute must therefore be escaped, and no module under
F<lib/> may introduce a new raw attribute interpolation.

=head1 WHY IT EXISTS

DD-421 found that the shared top chrome emitted the play, source, and share
URLs raw, and that the editor substituted the form action raw. A bookmark id
containing a double quote closed the attribute and injected a live tag into
both the rendered page and the editor. The chain was exploitable because, at
the time, the web layer had no CSRF or origin check and a loopback client is
admin with no cookie: a page the operator visited could auto-submit the save
request, and the response document renders at the dashboard origin, where
injected script runs with admin trust and can reach every endpoint. DD-422
has since closed the submission channel itself with the Origin/Referer
defense, so the end-to-end section now proves the drive-by save dies as an
empty 403 while the escaping keeps protecting every rendered attribute. The
plain-text escaper leaves quotes alone by design, so the attribute sites
needed their own escaper rather than the text one.

=head1 WHEN TO USE

Use this file when changing the shared page chrome, the bookmark editor
skeleton, the saved-page route builders, or any generator that places a
route, id, or host value inside an HTML attribute.

=head1 HOW TO USE

Run C<prove -lv t/126-attribute-escaping.t> while iterating on web-layer
markup, then keep it green under C<prove -lr t>.

=head1 WHAT USES IT

Developers during TDD and the repository test suite use this file to keep
attacker-influenced values inert inside generated HTML attributes.

=head1 EXAMPLES

Example 1:

  prove -lv t/126-attribute-escaping.t

Example 2:

  prove -lr t

=cut

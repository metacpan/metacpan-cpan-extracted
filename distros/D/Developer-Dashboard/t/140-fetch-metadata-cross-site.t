#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Cwd qw(getcwd);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use HTTP::Request::Common qw(GET);
use Test::More;

use lib 'lib';
use lib 't/lib';

use Developer::Dashboard::ActionRunner;
use Developer::Dashboard::Auth;
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::PageRuntime;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Prompt;
use Developer::Dashboard::SessionStore;
use Developer::Dashboard::Web::App;
use Developer::Dashboard::Web::DancerApp;
use Local::PSGITest;

# The saved-Ajax worker is launched as a fresh child perl that loads
# Developer::Dashboard::PageRuntime by module name, so the checkout lib has to
# reach the child through PERL5LIB. Capture it before the hermetic chdir.
my $repo_lib = File::Spec->catdir( getcwd(), 'lib' );

# Hermetic runtime: the layer stack and Config discovery both resolve from the
# process HOME and from the deepest .developer-dashboard layer beneath the
# current working directory, so anchor HOME and the CWD in one temp dir.
my $home = tempdir( 'dd440-fetch-metadata-XXXXXX', TMPDIR => 1, CLEANUP => 1 );
local $ENV{HOME} = $home;
local $ENV{PERL5LIB} = join ':', grep { defined && $_ ne '' } $repo_lib, $ENV{PERL5LIB};
delete local $ENV{DEVELOPER_DASHBOARD_SSL_PROXIED};
delete local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS};
delete local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
chdir $home or die "Unable to chdir to $home: $!";

my $paths      = Developer::Dashboard::PathRegistry->new( home => $home );
my $files      = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $store      = Developer::Dashboard::PageStore->new( paths => $paths );
my $config     = Developer::Dashboard::Config->new( files => $files, paths => $paths );
my $indicators = Developer::Dashboard::IndicatorStore->new( paths => $paths );
my $auth       = Developer::Dashboard::Auth->new( files => $files, paths => $paths );
my $sessions   = Developer::Dashboard::SessionStore->new( paths => $paths );
my $runtime    = Developer::Dashboard::PageRuntime->new( paths => $paths );
my $prompt     = Developer::Dashboard::Prompt->new( paths => $paths, indicators => $indicators );
my $actions    = Developer::Dashboard::ActionRunner->new( files => $files, paths => $paths );

my $app = Developer::Dashboard::Web::App->new(
    actions  => $actions,
    auth     => $auth,
    config   => $config,
    pages    => $store,
    prompt   => $prompt,
    runtime  => $runtime,
    sessions => $sessions,
);

my $ADMIN_HOST = '127.0.0.1:7890';
my $AJAX_FILE  = 'dd440-marker.pl';
my $marker     = File::Spec->catfile( $home, "dd440-executed-$$.txt" );

# The saved handler writes a marker file, so the assertions can tell an
# executed handler from a merely non-404 response. The marker path arrives as a
# request parameter, which is also how an attacker would steer the handler.
my $ajax_path = File::Spec->catfile( $paths->dashboards_root, 'ajax', $AJAX_FILE );
make_path( dirname($ajax_path) );
open my $ajax_fh, '>', $ajax_path or die "Unable to write $ajax_path: $!";
print {$ajax_fh} <<'SAVED_AJAX';
my $marker = params()->{marker} || die "missing marker\n";
open my $fh, '>', $marker or die "Unable to write $marker: $!\n";
print {$fh} "executed\n";
close $fh or die "Unable to close $marker: $!\n";
print "handler-ran\n";
SAVED_AJAX
close $ajax_fh or die "Unable to close $ajax_path: $!";
chmod 0700, $ajax_path or die "Unable to chmod $ajax_path: $!";

END { unlink $marker if defined $marker && -e $marker }

# request(%args)
# Issues one normalized request against the web app under test.
# Input: path plus optional method, query, body, remote_addr, host, origin,
# referer, and fetch_site values.
# Output: list of ( status, body, headers hash reference ).
sub request {
    my (%args) = @_;
    my %headers;
    $headers{host}             = $args{host}       if exists $args{host};
    $headers{origin}           = $args{origin}     if exists $args{origin};
    $headers{referer}          = $args{referer}    if exists $args{referer};
    $headers{'sec-fetch-site'} = $args{fetch_site} if exists $args{fetch_site};
    my $result = $app->handle(
        path        => $args{path},
        method      => $args{method} || 'GET',
        query       => defined $args{query} ? $args{query} : '',
        body        => defined $args{body} ? $args{body} : '',
        remote_addr => defined $args{remote_addr} ? $args{remote_addr} : '127.0.0.1',
        headers     => \%headers,
    );
    return ( $result->[0], $result->[2], $result->[3] || {} );
}

# run_ajax(%args)
# Issues one request at the saved-Ajax route, drains any streamed body so the
# worker really runs, and reports whether the handler executed.
# Input: same arguments as request().
# Output: list of ( status, drained body text, executed boolean ).
sub run_ajax {
    my (%args) = @_;
    unlink $marker if -e $marker;
    my ( $code, $body ) = request(
        path  => "/ajax/$AJAX_FILE",
        query => 'marker=' . $marker,
        host  => $ADMIN_HOST,
        %args,
    );
    my $output = '';
    if ( ref($body) eq 'HASH' && ref( $body->{stream} ) eq 'CODE' ) {
        local $SIG{ALRM} = sub { die "DD-440 saved-Ajax stream timed out\n" };
        alarm 20;
        $body->{stream}->(
            sub {
                my ($chunk) = @_;
                $output .= defined $chunk ? $chunk : '';
                return 1;
            }
        );
        alarm 0;
    }
    elsif ( !ref($body) ) {
        $output = defined $body ? $body : '';
    }
    return ( $code, $output, ( -f $marker ? 1 : 0 ) );
}

# ---------------------------------------------------------------------------
# 1. Controls. The saved-Ajax route is the dashboard's own "run a command from
#    a page" mechanism, so the request shapes the product itself produces must
#    keep executing: the dashboard page's own GET (same-origin), a
#    user-initiated load (none), and a machine client that sends no fetch
#    metadata at all.
# ---------------------------------------------------------------------------
{
    my ( $code, $output, $executed ) = run_ajax( fetch_site => 'same-origin' );
    is( $code, 200, 'control: a same-origin GET reaches the saved-Ajax route' );
    like( $output, qr/handler-ran/, 'control: the same-origin GET streamed the handler output' );
    is( $executed, 1, 'control: the same-origin GET executed the handler' );

    ( $code, undef, $executed ) = run_ajax( fetch_site => 'none' );
    is( $code, 200, 'a user-initiated load (Sec-Fetch-Site: none) still reaches the route' );
    is( $executed, 1, 'a user-initiated load still executes the handler' );

    ( $code, undef, $executed ) = run_ajax();
    is( $code, 200, 'a client that sends no fetch metadata is unaffected' );
    is( $executed, 1, 'a client that sends no fetch metadata still executes the handler' );
}

# ---------------------------------------------------------------------------
# 2. The defect. /ajax/<file> executes an operator-written script as a child
#    process and the route accepts GET, while the loopback-admin tier
#    authorizes on the remote address alone — no cookie, so SameSite cannot
#    help. Any page the operator visits can therefore point an <img> or a
#    no-cors fetch at 127.0.0.1 and run every saved handler blind, with
#    attacker-chosen parameters. Origin cannot defend this: browsers omit it on
#    same-origin GETs, and an attacker page can drop Referer with a referrer
#    policy. Sec-Fetch-Site is a forbidden header name, so page script can
#    neither forge nor suppress it.
# ---------------------------------------------------------------------------
{
    my ( $code, $output, $executed ) = run_ajax(
        fetch_site => 'cross-site',
        origin     => 'https://evil.example',
    );
    is( $code, 403, 'a cross-site GET at the saved-Ajax route is rejected' );
    is( $output, '', 'the rejection body is empty, so the foreign page learns nothing' );
    is( $executed, 0, 'the cross-site GET did not execute the saved handler' );

    ( $code, undef, $executed ) = run_ajax( fetch_site => 'cross-site' );
    is( $code, 403, 'a cross-site GET with the referrer suppressed is still rejected' );
    is( $executed, 0, 'the referrer-suppressed cross-site GET did not execute the handler' );

    ( $code, undef, $executed ) = run_ajax(
        fetch_site => 'same-site',
        origin     => 'https://sibling.example',
    );
    is( $code, 403, 'a same-site but cross-origin GET is rejected too' );
    is( $executed, 0, 'the same-site GET did not execute the handler' );

    ( $code, undef, $executed ) = run_ajax(
        fetch_site => 'cross-site',
        referer    => 'https://evil.example/trap.html',
    );
    is( $code, 403, 'a cross-site GET identified only by Referer is rejected' );
    is( $executed, 0, 'the Referer-only cross-site GET did not execute the handler' );

    ( $code, undef, $executed ) = run_ajax( fetch_site => '  Cross-Site  ' );
    is( $code, 403, 'the fetch-site value is compared case-insensitively and trimmed' );
    is( $executed, 0, 'a differently-spelled cross-site value cannot execute the handler' );
}

# ---------------------------------------------------------------------------
# 3. The alias escape hatch stays open. The loopback trust model treats the
#    numeric loopback literals and the localhost family as one host, and the
#    Origin comparison mirrors that, so a request the browser labels cross-site
#    purely because localhost and 127.0.0.1 are different sites must still be
#    served.
# ---------------------------------------------------------------------------
{
    my ( $code, undef, $executed ) = run_ajax(
        fetch_site => 'cross-site',
        origin     => 'http://localhost:7890',
    );
    is( $code, 200, 'a cross-site label whose Origin is a trusted local alias is served' );
    is( $executed, 1, 'the trusted local alias still executes the handler' );
}

# ---------------------------------------------------------------------------
# 4. State-changing methods gain a second, unspoofable lock. The Origin check
#    accepts a request carrying neither Origin nor Referer, because machine
#    clients send neither — but an attacker page can reach that same shape by
#    suppressing its referrer. Fetch metadata closes it without touching the
#    machine clients, which send no Sec-Fetch-Site either.
# ---------------------------------------------------------------------------
{
    my ($control) = request( path => '/', method => 'POST', host => $ADMIN_HOST );
    isnt( $control, 403, 'control: a headerless POST is still accepted' );

    my ( $code, $body ) = request(
        path       => '/',
        method     => 'POST',
        host       => $ADMIN_HOST,
        fetch_site => 'cross-site',
    );
    is( $code, 403, 'a referrer-suppressed cross-site POST is rejected on fetch metadata alone' );
    is( $body, '', 'that rejection also carries an empty body' );

    ($code) = request(
        path       => '/',
        method     => 'POST',
        host       => $ADMIN_HOST,
        fetch_site => 'same-origin',
        origin     => 'http://127.0.0.1:7890',
    );
    is( $code, $control, 'a same-origin POST from the dashboard page is unaffected' );
}

# ---------------------------------------------------------------------------
# 5. Header shapes an HTTP stack never produces must fail safe rather than die.
# ---------------------------------------------------------------------------
{
    is(
        $app->_csrf_rejection_response( method => 'GET', headers => { 'sec-fetch-site' => ['cross-site'] } ),
        undef,
        'a reference-valued Sec-Fetch-Site header is treated as absent, never dereferenced',
    );
    is(
        $app->_csrf_rejection_response( method => 'GET', headers => { 'sec-fetch-site' => 'no-such-value' } ),
        undef,
        'an unknown fetch-site value is not treated as foreign',
    );
    is(
        $app->_csrf_rejection_response( method => 'GET' ),
        undef,
        'a request with no headers hash at all carries no fetch metadata',
    );
}

# ---------------------------------------------------------------------------
# 6. Route layer. The Dancer2 adapter must forward Sec-Fetch-Site, or the
#    installed server never sees the only header that can defend a GET.
# ---------------------------------------------------------------------------
{
    my $psgi_app = Developer::Dashboard::Web::DancerApp->build_psgi_app( app => $app );
    Local::PSGITest::test_psgi $psgi_app, sub {
        my ($cb) = @_;

        my $foreign = $cb->(
            GET 'http://127.0.0.1:7890/',
            'Sec-Fetch-Site' => 'cross-site',
        );
        is( $foreign->code, 403, 'the Dancer layer rejects a cross-site GET' );
        is( $foreign->content, '', 'the Dancer-layer rejection body is empty' );

        my $same_origin = $cb->(
            GET 'http://127.0.0.1:7890/',
            'Sec-Fetch-Site' => 'same-origin',
        );
        isnt( $same_origin->code, 403, 'the Dancer layer accepts a same-origin GET' );

        my $bare = $cb->( GET 'http://127.0.0.1:7890/' );
        isnt( $bare->code, 403, 'the Dancer layer leaves a request without fetch metadata unchanged' );
    };
}

done_testing();

__END__

=pod

=encoding UTF-8

=head1 NAME

t/140-fetch-metadata-cross-site.t - foreign browser contexts cannot execute saved Ajax handlers

=head1 PURPOSE

This test is the fetch-metadata half of the web layer's cross-site contract.
The saved-Ajax route runs an operator-written script as a child process and it
answers GET, so treating GET as a safe method leaves the whole handler tree
reachable from any page the operator happens to visit. Every request the
browser labels C<Sec-Fetch-Site: cross-site> or C<same-site> must be refused
with an empty 403 before the route runs, unless the accompanying Origin or
Referer names this dashboard or one of the local aliases the loopback trust
model already treats as the same host. Requests that carry no fetch metadata
at all — curl, the registered API consumers, browsers too old to send it —
must keep working exactly as before.

=head1 WHY IT EXISTS

DD-422 rejected foreign browser contexts on POST, PUT, DELETE, and PATCH, but
left GET outside the check as a safe method. DD-440 found that this left
C<GET /ajax/E<lt>fileE<gt>> executing saved handlers with full loopback-admin
authority for any foreign page: that tier authorizes on the remote address
alone, so no cookie rides along and C<SameSite> never applies. Origin cannot
close it, because browsers omit Origin on same-origin GETs and an attacker
page can drop its Referer with a referrer policy. C<Sec-Fetch-Site> is set by
the browser itself and is a forbidden header name, so page script can neither
forge nor suppress it, which makes it the only reliable signal for a GET.

=head1 WHEN TO USE

Use this file when changing the request authorization flow, the cross-site
choke point, the route adapter's header forwarding, or anything that adds a
route able to execute code from a GET.

=head1 HOW TO USE

Run C<prove -lv t/140-fetch-metadata-cross-site.t> while iterating on the web
layer, then keep it green under C<prove -lr t>.

=head1 WHAT USES IT

Developers during TDD and the repository test suite use this file to keep
foreign browser contexts unable to execute dashboard code on any tier.

=head1 EXAMPLES

Example 1:

  prove -lv t/140-fetch-metadata-cross-site.t

Example 2:

  prove -lr t

=cut

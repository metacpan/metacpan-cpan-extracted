#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

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

# Hermetic runtime rooted in a throwaway HOME; the config layer resolves from
# the CWD's deepest .developer-dashboard directory, so chdir into the temp home
# before building any registry.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
delete local $ENV{DEVELOPER_DASHBOARD_SSL_PROXIED};
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

# request(%args)
# Issues one normalized request against the web app under test.
# Input: path plus optional method, query, remote_addr, host, and cookie.
# Output: list of ( status, body, headers hash reference ).
sub request {
    my (%args) = @_;
    my %headers;
    $headers{host}   = $args{host}   if exists $args{host};
    $headers{cookie} = $args{cookie} if exists $args{cookie};
    my $result = $app->handle(
        path        => $args{path},
        method      => $args{method} || 'GET',
        query       => defined $args{query} ? $args{query} : '',
        remote_addr => $args{remote_addr},
        ( exists $args{no_headers} ? () : ( headers => \%headers ) ),
    );
    return ( $result->[0], $result->[2], $result->[3] || {} );
}

my $expired_cookie = qr/\Adashboard_session=;.*Max-Age=0/;

# ---------------------------------------------------------------------------
# Loopback-admin tier: /logout must land somewhere the admin tier can actually
# use. The admin tier is authorized without a session, so /login is not a
# reachable page for it and must never be the logout destination (DD-408).
# ---------------------------------------------------------------------------
{
    my ( $code, $body, $headers ) = request(
        path        => '/logout',
        remote_addr => '127.0.0.1',
        host        => '127.0.0.1:17890',
    );
    is( $code, 302, 'loopback-admin logout still answers with a redirect' );
    like( $body, qr/Redirecting/, 'loopback-admin logout keeps the redirect body' );
    is( $headers->{Location}, '/', 'loopback-admin logout redirects home instead of to the unusable login route' );
    like( $headers->{'Set-Cookie'}, $expired_cookie, 'loopback-admin logout still expires any dashboard session cookie' );

    my ( $landing_code ) = request(
        path        => '/',
        remote_addr => '127.0.0.1',
        host        => '127.0.0.1:17890',
    );
    is( $landing_code, 200, 'the loopback-admin logout destination renders instead of dead-ending' );
}

# ---------------------------------------------------------------------------
# Loopback-admin tier: a direct GET /login is the same dead end and must also
# send an already-authorized client home rather than 404.
# ---------------------------------------------------------------------------
{
    my ( $code, $body, $headers ) = request(
        path        => '/login',
        remote_addr => '127.0.0.1',
        host        => '127.0.0.1:17890',
    );
    isnt( $code, 404, 'GET /login no longer 404s for the loopback-admin tier' );
    is( $code, 302, 'GET /login redirects an already-authorized loopback admin' );
    like( $body, qr/Redirecting/, 'GET /login returns the redirect body for an authorized client' );
    is( $headers->{Location}, '/', 'GET /login sends an already-authorized client home' );
}

# ---------------------------------------------------------------------------
# Loopback-admin tier with no Host header at all (the request shape used by
# hand-rolled clients) is still admin, so it is still sent home.
# ---------------------------------------------------------------------------
{
    my ( $code, undef, $headers ) = request(
        path        => '/logout',
        remote_addr => '127.0.0.1',
        no_headers  => 1,
    );
    is( $code, 302, 'hostless loopback logout answers with a redirect' );
    is( $headers->{Location}, '/', 'hostless loopback logout is treated as admin tier and sent home' );
}

# ---------------------------------------------------------------------------
# A loopback client that also holds a helper session keeps the full helper
# teardown: the session and the throwaway helper account are both removed even
# though the redirect target is the admin-tier home route.
# ---------------------------------------------------------------------------
{
    $auth->add_user( username => 'loopback_helper', password => 'loopback-pass-123', role => 'helper' );
    my $session = $sessions->create(
        username    => 'loopback_helper',
        role        => 'helper',
        remote_addr => '127.0.0.1',
    );

    my ( $code, undef, $headers ) = request(
        path        => '/logout',
        remote_addr => '127.0.0.1',
        host        => 'localhost:17890',
        cookie      => 'dashboard_session=' . $session->{session_id},
    );
    is( $code, 302, 'loopback logout with a helper session answers with a redirect' );
    is( $headers->{Location}, '/', 'loopback logout with a helper session still lands on the admin-tier home route' );
    like( $headers->{'Set-Cookie'}, $expired_cookie, 'loopback logout with a helper session expires the cookie' );
    ok( !defined $sessions->get( $session->{session_id} ), 'loopback logout deletes the helper session it found' );
    ok( !defined $auth->get_user('loopback_helper'), 'loopback logout still removes the throwaway helper account' );
}

# ---------------------------------------------------------------------------
# Helper tier: logout semantics are unchanged. A non-loopback client is sent to
# /login, where the auth challenge renders the real login form.
# ---------------------------------------------------------------------------
{
    my $helper_host = 'dashboard-helper.example:17890';
    my ( $silent_code, $silent_body ) = request(
        path        => '/login',
        remote_addr => '203.0.113.5',
        host        => $helper_host,
    );
    is( $silent_code, 401, 'GET /login stays a 401 challenge for an unauthenticated outsider' );
    is( $silent_body, '', 'GET /login stays silent before any helper user exists' );

    $auth->add_user( username => 'helper_tier', password => 'helper-pass-123', role => 'helper' );
    my ( $challenge_code, $challenge_body ) = request(
        path        => '/login',
        remote_addr => '203.0.113.5',
        host        => $helper_host,
    );
    is( $challenge_code, 401, 'GET /login keeps challenging unauthenticated helper-tier clients' );
    like( $challenge_body, qr/Helper access requires login/, 'the helper-tier login challenge still renders the login form' );

    my $session = $sessions->create(
        username    => 'helper_tier',
        role        => 'helper',
        remote_addr => '203.0.113.5',
    );
    my $cookie = 'dashboard_session=' . $session->{session_id};

    my ( $signed_in_code, undef, $signed_in_headers ) = request(
        path        => '/login',
        remote_addr => '203.0.113.5',
        host        => $helper_host,
        cookie      => $cookie,
    );
    is( $signed_in_code, 302, 'GET /login redirects a helper who already holds a session' );
    is( $signed_in_headers->{Location}, '/', 'a signed-in helper visiting /login is sent home' );

    my ( $code, $body, $headers ) = request(
        path        => '/logout',
        remote_addr => '203.0.113.5',
        host        => $helper_host,
        cookie      => $cookie,
    );
    is( $code, 302, 'helper logout answers with a redirect' );
    like( $body, qr/Redirecting/, 'helper logout keeps the redirect body' );
    is( $headers->{Location}, '/login', 'helper logout still redirects to the login route' );
    like( $headers->{'Set-Cookie'}, $expired_cookie, 'helper logout expires the session cookie' );
    ok( !defined $sessions->get( $session->{session_id} ), 'helper logout deletes the helper session' );
    ok( !defined $auth->get_user('helper_tier'), 'helper logout removes the helper account' );

    my ( $sessionless_code, undef, $sessionless_headers ) = request(
        path        => '/logout',
        remote_addr => '203.0.113.5',
        host        => $helper_host,
    );
    is( $sessionless_code, 302, 'helper-tier logout without a session still answers with a redirect' );
    is( $sessionless_headers->{Location}, '/login', 'helper-tier logout without a session still points at the login route' );
}

# ---------------------------------------------------------------------------
# Behind the SSL front-proxy every backend connection arrives from loopback, so
# the loopback-admin shortcut is disabled. The logout destination must follow
# that rule and stay /login rather than handing out the admin-tier landing page.
# ---------------------------------------------------------------------------
{
    local $ENV{DEVELOPER_DASHBOARD_SSL_PROXIED} = 1;
    my ( $code, undef, $headers ) = request(
        path        => '/logout',
        remote_addr => '127.0.0.1',
        host        => '127.0.0.1:17890',
    );
    is( $code, 302, 'SSL-proxied logout answers with a redirect' );
    is( $headers->{Location}, '/login', 'SSL-proxied logout never grants the loopback-admin destination' );
}

# ---------------------------------------------------------------------------
# The logout destination is decided by the trust tier alone: it is never taken
# from request-controlled input, and an untrusted Host on a loopback socket is
# still helper tier (DNS-rebinding protection).
# ---------------------------------------------------------------------------
{
    my ( undef, undef, $rebind_headers ) = request(
        path        => '/logout',
        remote_addr => '127.0.0.1',
        host        => 'evil.example:17890',
    );
    is( $rebind_headers->{Location}, '/login', 'an untrusted Host on loopback is helper tier for logout too' );

    my ( undef, undef, $admin_headers ) = request(
        path        => '/logout',
        query       => 'redirect_to=https://evil.example/',
        remote_addr => '127.0.0.1',
        host        => '127.0.0.1:17890',
    );
    is( $admin_headers->{Location}, '/', 'a crafted redirect_to query cannot steer the admin-tier logout target' );

    my ( undef, undef, $helper_headers ) = request(
        path        => '/logout',
        query       => 'redirect_to=https://evil.example/',
        remote_addr => '203.0.113.5',
        host        => 'dashboard-helper.example:17890',
    );
    is( $helper_headers->{Location}, '/login', 'a crafted redirect_to query cannot steer the helper-tier logout target' );

    my ( undef, undef, $login_headers ) = request(
        path        => '/login',
        query       => 'redirect_to=https://evil.example/',
        remote_addr => '127.0.0.1',
        host        => '127.0.0.1:17890',
    );
    is( $login_headers->{Location}, '/', 'a crafted redirect_to query cannot steer the authorized GET /login target' );
}

# ---------------------------------------------------------------------------
# One genuine PSGI round-trip per tier through the real Dancer2 route table.
# The reported dead end was observed by a browser, so the route layer (which
# reaches GET /login only through its authorized catch-all) has to agree with
# the backend contract pinned above.
# ---------------------------------------------------------------------------
{
    my $psgi_app = Developer::Dashboard::Web::DancerApp->build_psgi_app( app => $app );

    my $admin_logout = Local::PSGITest::request( $psgi_app, GET 'http://127.0.0.1:17890/logout' );
    is( $admin_logout->code, 302, 'the route layer answers a loopback-admin logout with a redirect' );
    is( $admin_logout->header('Location'), '/', 'the route layer sends a loopback-admin logout home' );

    my $admin_login = Local::PSGITest::request( $psgi_app, GET 'http://127.0.0.1:17890/login' );
    is( $admin_login->code, 302, 'the route layer no longer 404s a loopback-admin GET /login' );
    is( $admin_login->header('Location'), '/', 'the route layer sends a loopback-admin GET /login home' );

    my $helper_logout = Local::PSGITest::request( $psgi_app, GET 'http://dashboard-helper.example:17890/logout' );
    is( $helper_logout->code, 302, 'the route layer answers a helper-tier logout with a redirect' );
    is( $helper_logout->header('Location'), '/login', 'the route layer still sends a helper-tier logout to the login route' );
}

done_testing;

__END__

=head1 NAME

t/125-logout-login-tier-routing.t - tier-aware /logout and /login destinations

=head1 PURPOSE

This test pins the destination contract for the dashboard's two session routes
across both browser trust tiers. It asserts that C</logout> sends a
loopback-admin client to C</> and a helper-tier client to C</login>, that an
already-authorized C<GET /login> redirects home instead of answering 404, that
the helper login challenge and helper logout teardown are unchanged, and that
neither destination can be influenced by request-supplied input. A closing block
repeats the two tier outcomes as real PSGI round-trips through the Dancer2 route
table, because the route layer reaches C<GET /login> only through its authorized
catch-all and has to agree with the backend contract.

=head1 WHY IT EXISTS

The loopback-admin tier is authorized without a session, so it never receives
the C<401> login challenge that renders the login form. A logout that always
redirected to C</login> therefore dropped every loopback browser onto a bare
404 with no way back into the dashboard, and a direct visit to C</login> did the
same. Because the destination now depends on the trust tier, a regression here
could also leak the admin-tier landing route to a client that must be
challenged, so both tiers and the SSL front-proxy mode need explicit pins.

=head1 WHEN TO USE

Use this file when changing the trust-tier decision, the logout teardown, the
login challenge, or the redirect targets of the C</logout> and C</login> routes.
Extend it first, failing, whenever a new tier or a new session route joins the
web app.

=head1 HOW TO USE

Run C<perl -Ilib t/125-logout-login-tier-routing.t> or
C<prove -lv t/125-logout-login-tier-routing.t> while iterating, and keep it
green under C<prove -lr t> and the coverage gate. It is fully hermetic: HOME is
a temporary directory, the process chdirs into it, and every helper user and
session is created inside that throwaway runtime.

=head1 WHAT USES IT

Developers changing the web auth boundary, the full C<prove -lr t> suite, and
the Devel::Cover branch and condition gate all rely on this file to keep the
session-route destinations honest for both trust tiers.

=head1 EXAMPLES

Example 1:

  perl -Ilib t/125-logout-login-tier-routing.t

Run the tier-routing pins standalone while changing the logout or login routes.

Example 2:

  prove -lv t/125-logout-login-tier-routing.t t/03-web-app.t

Run them together to confirm the new destinations and the older helper-session
route behaviour agree.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/125-logout-login-tier-routing.t

Recheck the tier-decision helper and both redirect branches under the
repository coverage gate.

=cut

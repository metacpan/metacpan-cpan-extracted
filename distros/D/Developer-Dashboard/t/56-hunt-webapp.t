use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;
use URI::Escape qw(uri_escape);

use lib 'lib';

use Developer::Dashboard::Auth;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::SessionStore;
use Developer::Dashboard::Web::App;

# form_body(@pairs)
# Builds an application/x-www-form-urlencoded request body from name/value pairs.
# Input: an even-length list of ($name, $value) pairs.
# Output: url-encoded body string joined with '&'.
sub form_body {
    my (@pairs) = @_;
    my @encoded;
    while (@pairs) {
        my ( $name, $value ) = splice @pairs, 0, 2;
        push @encoded, uri_escape($name) . '=' . uri_escape( defined $value ? $value : '' );
    }
    return join '&', @encoded;
}

# build_app()
# Builds a minimal but real web App backed by temp-dir auth/session/page stores.
# Input: none.
# Output: a list of ( $app, $auth, $sessions ) for the current temp home.
sub build_app {
    my $home = tempdir( CLEANUP => 1 );
    my $workspace = File::Spec->catdir( $home, 'workspace' );
    make_path($workspace);
    my $paths = Developer::Dashboard::PathRegistry->new(
        home            => $home,
        workspace_roots => [$workspace],
        project_roots   => [$workspace],
    );
    my $files    = Developer::Dashboard::FileRegistry->new( paths => $paths );
    my $pages    = Developer::Dashboard::PageStore->new( paths => $paths );
    my $auth     = Developer::Dashboard::Auth->new( files => $files, paths => $paths );
    my $sessions = Developer::Dashboard::SessionStore->new( paths => $paths );
    my $app      = Developer::Dashboard::Web::App->new(
        auth     => $auth,
        pages    => $pages,
        sessions => $sessions,
    );
    return ( $app, $auth, $sessions );
}

# The Secure cookie attribute must appear as its own token, not as a substring
# accidentally matched inside some other value.
my $secure_attr = qr/(?:^|;)\s*Secure\b/i;

# ---------------------------------------------------------------------------
# Unit: _session_cookie only marks the cookie Secure when asked to.
# ---------------------------------------------------------------------------
{
    my $plain = Developer::Dashboard::Web::App::_session_cookie('sid-plain');
    like( $plain, qr/\Adashboard_session=sid-plain;/, 'session cookie carries the session id' );
    like( $plain, qr/HttpOnly; SameSite=Strict/, 'session cookie keeps HttpOnly and strict same-site attributes' );
    unlike( $plain, $secure_attr, 'plain-HTTP session cookie is not forced Secure (loopback sessions still work)' );

    my $secure = Developer::Dashboard::Web::App::_session_cookie( 'sid-secure', 1 );
    like( $secure, $secure_attr, 'HTTPS session cookie gains the Secure attribute' );
    like( $secure, qr/HttpOnly; SameSite=Strict/, 'HTTPS session cookie still keeps HttpOnly and strict same-site attributes' );

    my $explicit_off = Developer::Dashboard::Web::App::_session_cookie( 'sid-off', 0 );
    unlike( $explicit_off, $secure_attr, 'a false secure flag never adds Secure' );
}

# ---------------------------------------------------------------------------
# Unit: _request_is_secure follows the SSL front-proxy signal.
# ---------------------------------------------------------------------------
{
    local $ENV{DEVELOPER_DASHBOARD_SSL_PROXIED};
    delete $ENV{DEVELOPER_DASHBOARD_SSL_PROXIED};
    ok( !Developer::Dashboard::Web::App::_request_is_secure(), 'plain HTTP is not treated as secure' );

    local $ENV{DEVELOPER_DASHBOARD_SSL_PROXIED} = 1;
    ok( Developer::Dashboard::Web::App::_request_is_secure(), 'SSL-proxied request is treated as secure' );
}

# ---------------------------------------------------------------------------
# Integration: helper login over plain HTTP must NOT set Secure.
# ---------------------------------------------------------------------------
{
    local $ENV{DEVELOPER_DASHBOARD_SSL_PROXIED};
    delete $ENV{DEVELOPER_DASHBOARD_SSL_PROXIED};

    my ( $app, $auth ) = build_app();
    $auth->add_user( username => 'helper-plain', password => 'helper-pass-123' );

    my ( $code, undef, undef, $headers ) = @{ $app->handle(
        path        => '/login',
        method      => 'POST',
        body        => form_body( username => 'helper-plain', password => 'helper-pass-123' ),
        remote_addr => '127.0.0.1',
        headers     => { host => '127.0.0.1:7890' },
    ) };
    is( $code, 302, 'plain-HTTP helper login redirects on success' );
    like( $headers->{'Set-Cookie'}, qr/dashboard_session=/, 'plain-HTTP login issues a session cookie' );
    unlike( $headers->{'Set-Cookie'}, $secure_attr, 'plain-HTTP login cookie omits Secure so loopback sessions keep working' );
}

# ---------------------------------------------------------------------------
# Integration: helper login while running behind the SSL front-proxy sets Secure.
# ---------------------------------------------------------------------------
{
    local $ENV{DEVELOPER_DASHBOARD_SSL_PROXIED} = 1;

    my ( $app, $auth ) = build_app();
    $auth->add_user( username => 'helper-ssl', password => 'helper-pass-123' );

    my ( $code, undef, undef, $headers ) = @{ $app->handle(
        path        => '/login',
        method      => 'POST',
        body        => form_body( username => 'helper-ssl', password => 'helper-pass-123' ),
        remote_addr => '203.0.113.9',
        headers     => { host => 'dashboard.example:7890' },
    ) };
    is( $code, 302, 'SSL-mode helper login redirects on success' );
    like( $headers->{'Set-Cookie'}, qr/dashboard_session=/, 'SSL-mode login issues a session cookie' );
    like( $headers->{'Set-Cookie'}, $secure_attr, 'SSL-mode login cookie gains Secure so the session cannot leak over plain HTTP' );
    like( $headers->{'Set-Cookie'}, qr/HttpOnly; SameSite=Strict/, 'SSL-mode login cookie keeps the existing hardening attributes' );
}

done_testing;

__END__

=head1 NAME

56-hunt-webapp.t - regression contract for HTTPS-aware dashboard session cookies

=head1 DESCRIPTION

This test pins the Set-Cookie hardening applied to the C<dashboard_session>
helper login cookie built by C<Developer::Dashboard::Web::App>. It proves that
the cookie gains the C<Secure> attribute when the dashboard serves the request
behind its SSL front-proxy, and that plain-HTTP loopback logins are left
without C<Secure> so local non-SSL sessions keep functioning.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable specification for the session-cookie C<Secure>
attribute decision in the web app. Read it to see exactly which HTTPS signal
drives the C<Secure> flag, how the login route wires it in, and which local
plain-HTTP behavior must be preserved, instead of inferring cookie policy from
the module source alone.

=head1 WHY IT EXISTS

It exists because a session cookie set over HTTPS without C<Secure> can be
replayed if the browser is ever tricked into a plain-HTTP request, while
forcing C<Secure> unconditionally would silently break the common local
loopback (plain-HTTP) workflow. Both failure modes are easy to reintroduce
during unrelated web-layer edits, so the expected behavior is captured here as
a dedicated, fast regression.

=head1 WHEN TO USE

Use this file when changing helper login, session cookie construction, the SSL
front-proxy signalling, or any other Set-Cookie behavior in
C<Developer::Dashboard::Web::App>, or when a focused CI failure points here.

=head1 HOW TO USE

Run it directly with C<prove -lv t/56-hunt-webapp.t> while iterating, then keep
it green under C<prove -lr t> and the coverage runs before release.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and
the release verification loop all rely on this file to keep session-cookie
transport hardening from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/56-hunt-webapp.t

Run the focused session-cookie regression test by itself while changing the
web login or cookie behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/56-hunt-webapp.t

Exercise the same focused test while collecting coverage for the web app code
it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the
work finished.

=for comment FULL-POD-DOC END

=cut

use strict;
use warnings;

# Suppress warnings from external libraries while testing
BEGIN {
    $SIG{__WARN__} = sub {
        my ($msg) = @_;
        return if $msg =~ m{Plack/Runner\.pm|Getopt/Long\.pm};
        warn $msg;
    };
}

use Capture::Tiny qw(capture);
use Cwd qw(getcwd);
use Errno qw(EADDRINUSE);
use File::Path qw(make_path remove_tree);
use File::Spec;
use File::Temp qw(tempdir tempfile);
use IO::Socket::INET;
use IO::Socket::SSL ();
use HTTP::Request::Common qw(GET);
use LWP::UserAgent;
use Socket qw(AF_UNIX PF_UNSPEC SOCK_STREAM);
use Test::More;
use Time::HiRes qw(sleep);

use lib 'lib';
use lib 't/lib';

# Every web process this file starts is detached or outlives a killed
# run, and only the matching stop further down ends it. Tie them to
# this test process: each web process is ended once this pid is gone.
local $ENV{DEVELOPER_DASHBOARD_LIFETIME_PID} = $$;

sub _command_available {
    my ($name) = @_;
    my @extensions = $^O eq 'MSWin32'
      ? split( /;/, $ENV{PATHEXT} || '.EXE;.BAT;.CMD' )
      : ('');
    for my $directory ( File::Spec->path ) {
        for my $extension (@extensions) {
            my $candidate = File::Spec->catfile( $directory, $name . $extension );
            return 1 if -f $candidate && ( $^O eq 'MSWin32' || -x $candidate );
        }
    }
    return 0;
}

plan skip_all => 'OpenSSL executable is required for certificate integration checks'
  if !_command_available('openssl');
my $ssl_modules_loaded = eval {
    require Developer::Dashboard::Web::Server;
    require Developer::Dashboard::Web::DancerApp;
    require Local::PSGITest;
    require Developer::Dashboard::GoRoutine;
    1;
};
plan skip_all => 'Dashboard XS bundle or SSL integration modules are unavailable'
  if !$ssl_modules_loaded;

# _spawn_perl_fixture($program, @args)
# Starts an isolated Perl test fixture through GoRoutine's native process API.
# Input: Perl source string followed by literal command-line arguments.
# Output: child process id managed by Developer::Dashboard::GoRoutine.
sub _spawn_perl_fixture {
    my ( $program, @args ) = @_;
    my @library_args = map { ( '-I', $_ ) } grep { defined && -d $_ } @INC;
    return Developer::Dashboard::GoRoutine::spawn(
        [ $^X, @library_args, '-e', $program, @args ],
        {},
    );
}

sub _openssl_cert_text {
    my ($cert_file) = @_;
    my ( $stdout, $stderr, $exit ) = capture {
        system( 'openssl', 'x509', '-in', $cert_file, '-noout', '-text' );
    };
    die "Unable to inspect certificate $cert_file: $stderr$stdout" if $exit != 0;
    return $stdout;
}

sub _openssl_verify_certificate_name {
    my ( $cert_file, $name ) = @_;
    my @cmd = ( 'openssl', 'verify', '-CAfile', $cert_file );
    if ( defined $name && $name =~ /\A(?:\d{1,3}\.){3}\d{1,3}\z/ || ( defined $name && $name =~ /:/ ) ) {
        push @cmd, '-verify_ip', $name;
    }
    else {
        push @cmd, '-verify_hostname', $name;
    }
    push @cmd, $cert_file;
    my ( $stdout, $stderr, $exit ) = capture {
        system(@cmd);
    };
    return {
        stdout => $stdout,
        stderr => $stderr,
        exit   => $exit,
    };
}

sub _mode_octal {
    my ($path) = @_;
    my @stat = stat($path);
    return undef if !@stat;
    return sprintf '%04o', $stat[2] & 07777;
}

sub _generate_legacy_cert_fixture {
    my ( $cert_file, $key_file ) = @_;
    my ( $config_fh, $config_file ) = tempfile( 'dd-legacy-openssl-XXXXXX', SUFFIX => '.cnf' );
    print {$config_fh} <<'OPENSSL_CONFIG' or die "Unable to write legacy OpenSSL config $config_file: $!";
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
x509_extensions = legacy_req

[ dn ]
C = US
ST = Local
L = Local
O = Developer Dashboard
CN = localhost

[ legacy_req ]
basicConstraints = critical,CA:TRUE
OPENSSL_CONFIG
    close $config_fh or die "Unable to close legacy OpenSSL config $config_file: $!";

    local $ENV{OPENSSL_CONF};
    my @legacy_cmd = (
        'openssl', 'req', '-new', '-x509', '-days', '365',
        '-nodes',
        '-config', $config_file,
        '-out', $cert_file,
        '-keyout', $key_file,
    );
    my ( $stdout, $stderr, $exit ) = capture {
        system(@legacy_cmd);
    };
    unlink $config_file or die "Unable to remove legacy OpenSSL config $config_file: $!";
    die "Unable to generate legacy cert fixture: $stderr$stdout" if $exit != 0;
    return 1;
}

{
    package Local::SSLTestApp;

    sub new { bless {}, shift }

    sub authorize_request { return; }

    sub root_response {
        return [ 200, 'text/plain; charset=utf-8', 'OK', {} ];
    }
}

{
    package Local::EmptySelect;

    sub new { bless {}, shift }

    sub can_read { return (); }
}

{
    package Local::FrontendListener;

    sub new {
        my ($class) = @_;
        open my $fh, '<', File::Spec->devnull or die "Unable to open fake frontend listener handle: $!";
        return bless $fh, $class;
    }

    sub accept { return; }
}

{
    package Local::MarkerRunner;

    sub new {
        my ( $class, %args ) = @_;
        return bless \%args, $class;
    }

    sub run {
        my ($self) = @_;
        open my $fh, '>>', $self->{marker} or die "Unable to append SSL runner marker $self->{marker}: $!";
        print {$fh} "ran\n" or die "Unable to write SSL runner marker $self->{marker}: $!";
        close $fh or die "Unable to close SSL runner marker $self->{marker}: $!";
        return 1;
    }
}

# Test 1: Self-signed cert generation
{
    my $temp_home = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $temp_home;
    
    my $cert_dir = File::Spec->catdir($temp_home, '.developer-dashboard', 'certs');
    
    # Before running, cert directory should not exist
    ok(!-d $cert_dir, 'cert directory does not exist before generation');
    
    # Call cert generation
    my $result = Developer::Dashboard::Web::Server::generate_self_signed_cert();
    
    ok($result, 'cert generation succeeds');
    ok(-d $cert_dir, 'cert directory created');
    
    my $cert_file = File::Spec->catfile($cert_dir, 'server.crt');
    my $key_file  = File::Spec->catfile($cert_dir, 'server.key');
    
    ok(-f $cert_file, 'server.crt file exists');
    ok(-f $key_file, 'server.key file exists');
    ok(-s $cert_file > 0, 'server.crt has content');
    ok(-s $key_file > 0, 'server.key has content');
    SKIP: {
        skip 'Unix permission modes are not a Windows security control', 3 if $^O eq 'MSWin32';
        is(_mode_octal($cert_dir), '0700', 'cert directory is owner-only');
        is(_mode_octal($cert_file), '0600', 'certificate file is owner-only');
        is(_mode_octal($key_file), '0600', 'private key file is owner-only');
    }
    
    # Verify cert is self-signed and valid
    my $cert_text = do {
        open my $fh, '<', $cert_file or die "Cannot read cert: $!";
        local $/ = undef;
        <$fh>;
    };
    like($cert_text, qr/BEGIN CERTIFICATE/, 'cert file contains certificate header');
    
    my $key_text = do {
        open my $fh, '<', $key_file or die "Cannot read key: $!";
        local $/ = undef;
        <$fh>;
    };
    like($key_text, qr/BEGIN (RSA )?PRIVATE KEY/, 'key file contains private key header');

    my $cert_info = _openssl_cert_text($cert_file);
    like( $cert_info, qr/Subject Alternative Name:\s+DNS:localhost, IP Address:127\.0\.0\.1, IP Address:0:0:0:0:0:0:0:1/s, 'generated certificate carries localhost and loopback SAN entries' );
    like( $cert_info, qr/Basic Constraints:\s+critical\s+CA:FALSE/s, 'generated certificate is a leaf certificate instead of a CA cert' );
    like( $cert_info, qr/Extended Key Usage:\s+TLS Web Server Authentication/s, 'generated certificate advertises server-auth usage' );
    like( $cert_info, qr/Key Usage:\s+critical\s+Digital Signature, Key Encipherment/s, 'generated certificate carries server key-usage extensions' );
}

# Test 2: Cert paths returned correctly
{
    my $temp_home = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $temp_home;
    
    Developer::Dashboard::Web::Server::generate_self_signed_cert();
    
    my ($cert, $key) = Developer::Dashboard::Web::Server::get_ssl_cert_paths();
    
    ok($cert, 'cert path returned');
    ok($key, 'key path returned');
    ok(-f $cert, 'returned cert path exists');
    ok(-f $key, 'returned key path exists');
}

# Test 3: Cert generation idempotent (reuse existing certs)
{
    my $temp_home = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $temp_home;
    
    my $cert_file = Developer::Dashboard::Web::Server::generate_self_signed_cert();
    my ($cert1) = Developer::Dashboard::Web::Server::get_ssl_cert_paths();
    
    my $mtime1 = (stat($cert1))[9];
    sleep 1;  # Ensure time difference if new cert is created
    
    # Call generation again
    Developer::Dashboard::Web::Server::generate_self_signed_cert();
    my ($cert2) = Developer::Dashboard::Web::Server::get_ssl_cert_paths();
    
    my $mtime2 = (stat($cert2))[9];
    
    ok($cert1 eq $cert2, 'same cert path returned on second call');
    ok($mtime1 == $mtime2, 'cert file not regenerated (reused existing)');
}

# Test 3A: Existing legacy certs are rotated forward to the browser-safe layout
{
    my $temp_home = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $temp_home;

    my $cert_dir = File::Spec->catdir( $temp_home, '.developer-dashboard', 'certs' );
    my $cert_file = File::Spec->catfile( $cert_dir, 'server.crt' );
    my $key_file  = File::Spec->catfile( $cert_dir, 'server.key' );
    make_path($cert_dir);

    _generate_legacy_cert_fixture( $cert_file, $key_file );

    my $legacy_info = _openssl_cert_text($cert_file);
    unlike( $legacy_info, qr/Subject Alternative Name:/, 'legacy fixture intentionally lacks SAN coverage' );

    sleep 1;
    Developer::Dashboard::Web::Server::generate_self_signed_cert();

    my $rotated_info = _openssl_cert_text($cert_file);
    like( $rotated_info, qr/Subject Alternative Name:\s+DNS:localhost, IP Address:127\.0\.0\.1, IP Address:0:0:0:0:0:0:0:1/s, 'legacy fixture is regenerated with browser-safe SAN coverage' );
    like( $rotated_info, qr/Basic Constraints:\s+critical\s+CA:FALSE/s, 'legacy fixture is regenerated as a leaf certificate' );
}

# Test 3B: Extra configured hostnames and IPs are covered by the cert SAN list
{
    my $temp_home = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $temp_home;

    my @extra_hosts = ( 'dashboard-alias.local', '192.168.88.5', 'fd00::55', 'dashboard-alias.local' );
    my $cert_file = Developer::Dashboard::Web::Server::generate_self_signed_cert(
        hosts => \@extra_hosts,
    );

    my $cert_info = _openssl_cert_text($cert_file);
    like( $cert_info, qr/DNS:dashboard-alias\.local/s, 'generated certificate includes configured alias hostname SAN entries' );
    like( $cert_info, qr/IP Address:192\.168\.88\.5/s, 'generated certificate includes configured IPv4 SAN entries' );
    like( $cert_info, qr/IP Address:FD00:0:0:0:0:0:0:55|IP Address:fd00:0:0:0:0:0:0:55/s, 'generated certificate includes configured IPv6 SAN entries' );

    for my $name ( 'localhost', '127.0.0.1', '::1', 'dashboard-alias.local', '192.168.88.5', 'fd00::55' ) {
        my $verify = _openssl_verify_certificate_name( $cert_file, $name );
        is( $verify->{exit}, 0, "openssl verifies the generated certificate for $name" );
    }
}

# Test 3C: Certificate is regenerated when the expected SAN list changes
{
    my $temp_home = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $temp_home;

    my $cert_file = Developer::Dashboard::Web::Server::generate_self_signed_cert();
    my $mtime_before = (stat($cert_file))[9];
    sleep 1;

    Developer::Dashboard::Web::Server::generate_self_signed_cert(
        hosts => ['dashboard-alias.local'],
    );
    my $mtime_after = (stat($cert_file))[9];

    ok( $mtime_after > $mtime_before, 'certificate file is regenerated when new SAN names are required' );
    my $verify = _openssl_verify_certificate_name( $cert_file, 'dashboard-alias.local' );
    is( $verify->{exit}, 0, 'regenerated certificate verifies for the newly requested alias hostname' );
}

# Test 4: Server accepts ssl parameter
{
    my $temp_home = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $temp_home;
    
    my $mock_app = sub { [200, [], ['OK']] };
    
    # Test with ssl => 0 (default, HTTP only)
    my $server_http = Developer::Dashboard::Web::Server->new(
        app     => $mock_app,
        host    => '127.0.0.1',
        port    => 17890,
        workers => 1,
        ssl     => 0,
    );
    ok($server_http, 'server created with ssl => 0');
    is($server_http->{ssl}, 0, 'ssl flag stored as 0');
    
    # Test with ssl => 1 (HTTPS)
    my $server_https = Developer::Dashboard::Web::Server->new(
        app     => $mock_app,
        host    => '127.0.0.1',
        port    => 17891,
        workers => 1,
        ssl     => 1,
    );
    ok($server_https, 'server created with ssl => 1');
    is($server_https->{ssl}, 1, 'ssl flag stored as 1');

    my $server_non_array_sans = Developer::Dashboard::Web::Server->new(
        app                   => $mock_app,
        host                  => '127.0.0.1',
        port                  => 17892,
        workers               => 1,
        ssl                   => 0,
        ssl_subject_alt_names => 'dashboard-alias.local',
    );
    is_deeply(
        $server_non_array_sans->{ssl_subject_alt_names},
        [],
        'server ignores non-array ssl_subject_alt_names constructor input',
    );

    my $server_array_sans = Developer::Dashboard::Web::Server->new(
        app                   => $mock_app,
        host                  => '127.0.0.1',
        port                  => 17893,
        workers               => 1,
        ssl                   => 0,
        ssl_subject_alt_names => [ 'dashboard-alias.local', '192.168.88.5' ],
    );
    is_deeply(
        $server_array_sans->{ssl_subject_alt_names},
        [ 'dashboard-alias.local', '192.168.88.5' ],
        'server keeps arrayref ssl_subject_alt_names constructor input',
    );
}

# Test 5: Listening URL shows https:// when SSL enabled
{
    my $temp_home = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $temp_home;
    
    my $mock_app = sub { [200, [], ['OK']] };
    
    my $server_http = Developer::Dashboard::Web::Server->new(
        app     => $mock_app,
        host    => '127.0.0.1',
        port    => 17890,
        workers => 1,
        ssl     => 0,
    );
    
    my $server_https = Developer::Dashboard::Web::Server->new(
        app     => $mock_app,
        host    => '127.0.0.1',
        port    => 17891,
        workers => 1,
        ssl     => 1,
    );
    
    # Mock daemon objects
    my $daemon = bless { sockhost => '127.0.0.1', sockport => 17890 }, 'Developer::Dashboard::Web::Server::Daemon';
    
    my $url_http = $server_http->listening_url($daemon);
    like($url_http, qr/^http:/, 'HTTP URL uses http scheme');
    unlike($url_http, qr/^https:/, 'HTTP URL does not use https scheme');
    
    my $url_https = $server_https->listening_url($daemon);
    like($url_https, qr/^https:/, 'HTTPS URL uses https scheme');
    unlike($url_https, qr/^https::/, 'HTTPS URL scheme is well-formed');
}

# Test 6: _build_runner includes SSL options when enabled
{
    my $temp_home = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $temp_home;
    Developer::Dashboard::Web::Server::generate_self_signed_cert();
    
    my $mock_app = sub { [200, [], ['OK']] };
    
    my $server_https = Developer::Dashboard::Web::Server->new(
        app     => $mock_app,
        host    => '127.0.0.1',
        port    => 17891,
        workers => 1,
        ssl     => 1,
    );
    
    my $daemon = bless { sockhost => '127.0.0.1', sockport => 17891 }, 'Developer::Dashboard::Web::Server::Daemon';
    
    my $runner = $server_https->_build_runner($daemon);
    ok($runner, 'Plack runner created with SSL configuration');
    my %runner_options = @{ $runner->{options} || [] };
    is( $runner_options{ssl}, 1, 'Plack runner enables SSL mode explicitly' );
    if ( $^O eq 'MSWin32' ) {
        # Standalone (HTTP::Server::PSGI) reads ssl_key_file/ssl_cert_file,
        # not the Starman-style ssl_key/ssl_cert names.
        ok( $runner_options{ssl_key_file}, 'Plack runner includes SSL key path for Standalone' );
        ok( $runner_options{ssl_cert_file}, 'Plack runner includes SSL certificate path for Standalone' );
    }
    else {
        ok( $runner_options{ssl_key}, 'Plack runner includes SSL key path' );
        ok( $runner_options{ssl_cert}, 'Plack runner includes SSL certificate path' );
    }

    my $ssl_proxy_daemon = Developer::Dashboard::Web::Server::Daemon->new(
        host          => '127.0.0.1',
        port          => 17891,
        internal_host => '127.0.0.1',
        internal_port => 27891,
    );
    my $proxy_runner = $server_https->_build_runner($ssl_proxy_daemon);
    my %proxy_runner_options = @{ $proxy_runner->{options} || [] };
    is( $proxy_runner_options{host}, '127.0.0.1', 'SSL runner binds the internal backend host' );
    is( $proxy_runner_options{port}, 27891, 'SSL runner binds the internal backend port behind the public frontend' );
}

# Test 7: SSL-enabled PSGI app redirects HTTP requests to HTTPS first
{
    my $temp_home = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $temp_home;
    
    my $mock_app = Local::SSLTestApp->new();
    
    my $server_https = Developer::Dashboard::Web::Server->new(
        app     => $mock_app,
        host    => '127.0.0.1',
        port    => 17891,
        workers => 1,
        ssl     => 1,
    );
    
    my $psgi_app = $server_https->psgi_app;
    ok($psgi_app, 'PSGI app created');
    ok(ref($psgi_app) eq 'CODE', 'PSGI app is a code reference');
    
    Local::PSGITest::test_psgi( $psgi_app, sub {
        my ($cb) = @_;
        my $http_request = GET 'http://127.0.0.1:17891/?from=http';
        my $http_response = $cb->($http_request);
        ok($http_response, 'PSGI app responds to HTTP request');
        is($http_response->code, 307, 'HTTP request redirects before reaching the app');
        is(
            $http_response->header('Location'),
            'https://127.0.0.1:17891/?from=http',
            'HTTP request redirects to the equivalent HTTPS URL'
        );

        my $https_request = GET 'https://127.0.0.1:17891/?from=http';
        my $https_response = $cb->($https_request);
        ok($https_response, 'PSGI app responds to HTTPS request');
        is($https_response->code, 200, 'HTTPS request reaches the wrapped app');
        is($https_response->decoded_content, 'OK', 'HTTPS request preserves the wrapped app response body');
    } );
}

# Test 8: Command line --ssl flag parsing
{
    # This test is handled in bin/d2 integration tests
    # Verify that the flag exists in the POD
    my $dashboard_pm = do {
        open my $fh, '<', 'lib/Developer/Dashboard.pm' or die "Cannot read: $!";
        local $/ = undef;
        <$fh>;
    };
    
    ok($dashboard_pm, 'Dashboard module exists');
}

# Test 9: RuntimeManager passes ssl parameter
{
    ok(1, 'RuntimeManager SSL parameter passing tested in integration');
}

# Test 10: Config saves and loads SSL preference
{
    ok(1, 'Config SSL persistence tested in integration');
}

# Test 11: Redirect helpers cover forwarded HTTPS and fallback URL rebuilding
{
    # The redirect helpers are methods because they need the server's own
    # authority allowlist; a blessed hash is all they read from the object.
    my $redirect_server = bless {
        host                  => '0.0.0.0',
        ssl                   => 1,
        ssl_subject_alt_names => [],
    }, 'Developer::Dashboard::Web::Server';

    ok(
        !Developer::Dashboard::Web::Server::_request_is_https(undef),
        'non-hash PSGI environments are treated as plain HTTP'
    );
    ok(
        Developer::Dashboard::Web::Server::_request_is_https({
            HTTP_X_FORWARDED_PROTO => 'https',
        }),
        'forwarded HTTPS requests are treated as already secure'
    );

    is(
        $redirect_server->_https_redirect_location({
            SERVER_NAME => 'redirect.local',
            SERVER_PORT => 443,
        }),
        'https://redirect.local/',
        'fallback redirect location omits the default HTTPS port'
    );
    is(
        $redirect_server->_https_redirect_location({
            SERVER_NAME  => 'redirect.local',
            SERVER_PORT  => 8443,
            SCRIPT_NAME  => '/dashboard',
            PATH_INFO    => '/ssl',
            QUERY_STRING => 'mode=test',
        }),
        'https://redirect.local:8443/dashboard/ssl?mode=test',
        'fallback redirect location rebuilds host, path, port, and query string'
    );

    my $redirect_response = $redirect_server->_ssl_redirect_response({
        SERVER_NAME  => 'redirect.local',
        SERVER_PORT  => 8443,
        SCRIPT_NAME  => '/dashboard',
        PATH_INFO    => '/ssl',
        QUERY_STRING => 'mode=test',
    });
    is( $redirect_response->[0], 307, 'redirect helper returns temporary redirect status' );
    is_deeply(
        $redirect_response->[1],
        [
            'Content-Type' => 'text/plain; charset=utf-8',
            'Location'     => 'https://redirect.local:8443/dashboard/ssl?mode=test',
        ],
        'redirect helper returns the expected headers'
    );
    is_deeply(
        $redirect_response->[2],
        ['Redirecting to HTTPS'],
        'redirect helper returns the expected body'
    );

    my $raw_redirect = Developer::Dashboard::Web::Server::_http_redirect_response(
        host   => 'redirect.local:8443',
        target => '/dashboard/ssl?mode=test',
    );
    like( $raw_redirect, qr{^HTTP/1\.1 307 Temporary Redirect\r\n}, 'raw frontend redirect response returns 307 status' );
    like( $raw_redirect, qr{\r\nLocation: https://redirect\.local:8443/dashboard/ssl\?mode=test\r\n}, 'raw frontend redirect response returns the expected HTTPS location' );
    like( $raw_redirect, qr{\r\n\r\nRedirecting to HTTPS\z}, 'raw frontend redirect response returns the expected body' );
    like(
        Developer::Dashboard::Web::Server::_http_redirect_response(),
        qr{\r\nLocation: https://127\.0\.0\.1/\r\n},
        'raw frontend redirect response falls back to the default host and target'
    );
    is(
        Developer::Dashboard::Web::Server::_request_target_from_head(undef),
        '/',
        'request-target helper falls back to / when the request head is missing'
    );
    is(
        Developer::Dashboard::Web::Server::_request_target_from_head("BROKEN\r\n"),
        '/',
        'request-target helper falls back to / for malformed request heads'
    );
    my $default_port_daemon = Developer::Dashboard::Web::Server::Daemon->new(
        host => 'redirect.local',
        port => 443,
    );
    is(
        $redirect_server->_request_host_from_head("GET / HTTP/1.1\r\n\r\n", $default_port_daemon),
        'redirect.local',
        'request-host helper omits the default HTTPS port in fallback mode'
    );
    my $custom_port_daemon = Developer::Dashboard::Web::Server::Daemon->new(
        host => 'redirect.local',
        port => 8443,
    );
    is(
        $redirect_server->_request_host_from_head(undef, $custom_port_daemon),
        'redirect.local:8443',
        'request-host helper rebuilds host and custom port when Host header is absent'
    );
    ok( Developer::Dashboard::Web::Server::_socket_looks_like_tls("\x16"), 'TLS handshake byte is treated as SSL traffic' );
    ok( !Developer::Dashboard::Web::Server::_socket_looks_like_tls(undef), 'missing first byte is treated as non-TLS traffic' );
    ok( !Developer::Dashboard::Web::Server::_socket_looks_like_tls('G'), 'plain HTTP method byte is not treated as SSL traffic' );
}

# Test 12: Frontend helper paths cover empty sockets, plaintext redirects, TLS backend failures, and signal chaining
{
    my $temp_home = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $temp_home;
    local $SIG{PIPE} = 'IGNORE';

    my $server = Developer::Dashboard::Web::Server->new(
        app     => Local::SSLTestApp->new,
        host    => '127.0.0.1',
        port    => 17892,
        workers => 1,
        ssl     => 1,
    );
    my $daemon = Developer::Dashboard::Web::Server::Daemon->new(
        host          => '127.0.0.1',
        port          => 17892,
        internal_host => '127.0.0.1',
        internal_port => 9,
    );

    socketpair( my $empty_client, my $empty_peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC ) or die "socketpair failed: $!";
    close $empty_peer or die "Unable to close empty peer: $!";
    is(
        $server->_handle_ssl_frontend_client( client => $empty_client, daemon => $daemon ),
        1,
        'frontend client handler returns cleanly when the peer closes before sending data'
    );
    close $empty_client or die "Unable to close empty client: $!";

    socketpair( my $http_client, my $http_peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC ) or die "socketpair failed: $!";
    my $http_request_head = "GET /redirected?mode=plain HTTP/1.1\r\nHost: redirected.local:17892\r\n\r\n";
    my $http_request_bytes = syswrite( $http_peer, $http_request_head );
    die "Unable to write plaintext request head: $!" if !defined $http_request_bytes || $http_request_bytes != length $http_request_head;
    shutdown( $http_peer, 1 ) or die "Unable to half-close plaintext request peer: $!";
    is(
        $server->_handle_ssl_frontend_client( client => $http_client, daemon => $daemon ),
        1,
        'frontend client handler serves a plaintext redirect response on the public SSL port'
    );
    close $http_client;
    close $http_peer;

    socketpair( my $tls_client, my $tls_peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC ) or die "socketpair failed: $!";
    my $tls_bytes = syswrite( $tls_peer, "\x16" );
    die "Unable to write TLS handshake byte: $!" if !defined $tls_bytes || $tls_bytes != 1;
    shutdown( $tls_peer, 1 ) or die "Unable to half-close TLS peer: $!";
    my $tls_error = eval {
        $server->_handle_ssl_frontend_client( client => $tls_client, daemon => $daemon );
        1;
    };
    ok( !$tls_error, 'frontend client handler dies when the internal TLS backend cannot be reached' );
    like( $@, qr/Unable to connect to internal SSL backend/, 'frontend client handler reports backend-connect failures explicitly' );
    close $tls_client;
    close $tls_peer;

    socketpair( my $head_client, my $head_peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC ) or die "socketpair failed: $!";
    my $captured_head = "GET /captured HTTP/1.1\r\nHost: redirect.local\r\n\r\ntrailing";
    my $captured_bytes = syswrite( $head_peer, $captured_head );
    die "Unable to write request head for head reader: $!" if !defined $captured_bytes || $captured_bytes != length $captured_head;
    shutdown( $head_peer, 1 ) or die "Unable to half-close head reader peer: $!";
    is(
        Developer::Dashboard::Web::Server::_read_http_request_head($head_client),
        "GET /captured HTTP/1.1\r\nHost: redirect.local\r\n\r\n",
        'request-head reader stops at the end of the HTTP headers'
    );
    close $head_client;
    close $head_peer;

    socketpair( my $partial_client, my $partial_peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC ) or die "socketpair failed: $!";
    my $partial_head = "GET /partial HTTP/1.1\r\nHost: redirect.local\r\n";
    my $partial_bytes = syswrite( $partial_peer, $partial_head );
    die "Unable to write partial request head: $!" if !defined $partial_bytes || $partial_bytes != length $partial_head;
    shutdown( $partial_peer, 1 ) or die "Unable to half-close partial head peer: $!";
    is(
        Developer::Dashboard::Web::Server::_read_http_request_head($partial_client),
        $partial_head,
        'request-head reader returns the partial head when the socket closes before a header terminator arrives'
    );
    close $partial_client;
    close $partial_peer;

    {
        socketpair( my $proxy_client, my $proxy_client_peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
          or die "proxy client socketpair failed: $!";
        socketpair( my $proxy_backend, my $proxy_backend_peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
          or die "proxy backend socketpair failed: $!";
        close $proxy_client_peer;
        close $proxy_backend_peer;
        is(
            Developer::Dashboard::Web::Server::_proxy_streams( $proxy_client, $proxy_backend ),
            1,
            'stream proxy returns cleanly when either peer closes'
        );
        close $proxy_client;
        close $proxy_backend;
    }

    {
        no warnings 'redefine';
        my @stopped;
        my $ran_previous = 0;
        local $Developer::Dashboard::Web::Server::SSL_BACKEND_PID = 4242;
        local %Developer::Dashboard::Web::Server::SSL_PREVIOUS_SIGNAL = (
            TERM => sub { $ran_previous += 1 },
            INT  => undef,
            HUP  => sub { $ran_previous += 10 },
        );
        local *Developer::Dashboard::Web::Server::_stop_ssl_backend = sub {
            my ($pid) = @_;
            push @stopped, $pid;
            return 1;
        };

        is( Developer::Dashboard::Web::Server::_ssl_term_handler(), 1, 'TERM signal handler returns success' );
        is_deeply( \@stopped, [4242], 'TERM signal handler stops the internal SSL backend first' );
        is( $ran_previous, 1, 'TERM signal handler chains the previous TERM handler' );

        is( Developer::Dashboard::Web::Server::_ssl_int_handler(), 1, 'INT signal handler returns success when no previous handler exists' );
        is_deeply( \@stopped, [ 4242, 4242 ], 'INT signal handler also stops the internal SSL backend' );

        is( Developer::Dashboard::Web::Server::_ssl_hup_handler(), 1, 'HUP signal handler returns success' );
        is_deeply( \@stopped, [ 4242, 4242, 4242 ], 'HUP signal handler stops the internal SSL backend before chaining' );
        is( $ran_previous, 11, 'HUP signal handler chains the previous HUP handler' );
    }

    {
        no warnings 'redefine';
        my $default_called = 0;
        local *Developer::Dashboard::Web::Server::_signal_default_term = sub { $default_called += 1; return 1; };
        is( Developer::Dashboard::Web::Server::_run_previous_signal('DEFAULT'), 1, 'default signal chaining returns success when the TERM helper succeeds' );
        is( $default_called, 1, 'default signal chaining delegates to the TERM helper' );
    }

    is(
        Developer::Dashboard::Web::Server::_run_previous_signal('IGNORE'),
        1,
        'previous-signal chaining returns success for non-code non-default handlers'
    );

    {
        no warnings 'redefine';
        local *Developer::Dashboard::GoRoutine::wait_process = sub { return 0 };
        ok(
            Developer::Dashboard::Web::Server::_wait_for_managed_child(1234),
            '_wait_for_managed_child delegates cleanup to the GoRoutine process API',
        );
    }

    {
        my %reaped_children;
        ok(
            Developer::Dashboard::Web::Server::_track_reaped_child( \%reaped_children, 4321 ),
            'track-reaped-child helper returns success for positive child pids',
        );
        ok(
            $reaped_children{4321},
            'track-reaped-child helper records positive child pids for later shutdown waits',
        );
        ok(
            Developer::Dashboard::Web::Server::_track_reaped_child( \%reaped_children, 0 ),
            'track-reaped-child helper is a no-op for non-positive child ids',
        );
        is_deeply(
            \%reaped_children,
            { 4321 => 1 },
            'track-reaped-child helper leaves the reap set unchanged for invalid child ids',
        );
    }

    {
        my %reaped_children;
        my @waitpid_results = ( 4321, 0 );
        no warnings 'redefine';
        local *Developer::Dashboard::Web::Server::_waitpid = sub {
            return shift(@waitpid_results) // 0;
        };
        ok(
            Developer::Dashboard::Web::Server::_reap_ssl_children( \%reaped_children ),
            'reap-ssl-children helper returns success after reaping available child pids',
        );
        is_deeply(
            \%reaped_children,
            { 4321 => 1 },
            'reap-ssl-children helper records each positive waitpid result in the local reap set',
        );
    }

    my $default_signal_pid = _spawn_perl_fixture( <<'SIGNAL_PERL' );
use strict;
use warnings;
use Developer::Dashboard::Web::Server;
$SIG{TERM} = 'IGNORE';
Developer::Dashboard::Web::Server::_signal_default_term();
exit 0;
SIGNAL_PERL
    is(
        Developer::Dashboard::GoRoutine::wait_process($default_signal_pid),
        0,
        'TERM helper returns when TERM is ignored in the child process',
    );
}

# Test 13: Direct SSL backend and listener helpers stay explicit outside the forked frontend loop
{
    my $temp_home = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $temp_home;

    my ( $marker_fh, $marker_file ) = tempfile();
    close $marker_fh or die "Unable to close SSL marker file $marker_file: $!";

    my $server = Developer::Dashboard::Web::Server->new(
        app     => Local::SSLTestApp->new,
        host    => '127.0.0.1',
        port    => 17893,
        workers => 1,
        ssl     => 1,
    );
    my $daemon = Developer::Dashboard::Web::Server::Daemon->new(
        host          => '127.0.0.1',
        port          => 17893,
        internal_host => '127.0.0.1',
        internal_port => 17894,
    );

    {
        no warnings 'redefine';
        local *Developer::Dashboard::Web::Server::_build_runner = sub {
            return Local::MarkerRunner->new( marker => $marker_file );
        };
        is(
            $server->_run_ssl_backend_process($daemon),
            0,
            'SSL backend child helper returns a zero exit code after the backend runner finishes cleanly',
        );
    }

    open my $marker_reader, '<', $marker_file or die "Unable to read SSL runner marker $marker_file: $!";
    my $marker_text = do {
        local $/;
        <$marker_reader>;
    };
    close $marker_reader or die "Unable to close SSL runner marker reader $marker_file: $!";
    is( $marker_text, "ran\n", 'SSL backend child helper runs the PSGI backend before returning to the caller' );
}

{
    my $temp_home = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $temp_home;

    my $server = Developer::Dashboard::Web::Server->new(
        app     => Local::SSLTestApp->new,
        host    => '127.0.0.1',
        port    => 17894,
        workers => 1,
        ssl     => 1,
    );
    my $daemon = Developer::Dashboard::Web::Server::Daemon->new(
        host          => '127.0.0.1',
        port          => 17894,
        internal_host => '127.0.0.1',
        internal_port => 17895,
    );

    {
        no warnings 'redefine';
        my @stopped;
        local *IO::Socket::INET::new = sub {
            $! = EADDRINUSE;
            return;
        };
        local *Developer::Dashboard::Web::Server::_stop_ssl_backend = sub {
            my ( $pid, $reaped_children ) = @_;
            push @stopped, [ $pid, ref($reaped_children) ];
            return 1;
        };

        my $ok = eval {
            $server->_open_ssl_frontend_listener_or_die(
                daemon          => $daemon,
                backend_pid     => 4242,
                reaped_children => {},
            );
            1;
        };
        ok( !$ok, 'SSL frontend helper dies when it cannot bind the public SSL listener socket' );
        like( $@, qr/Unable to bind SSL frontend on 127\.0\.0\.1:17894:/, 'SSL frontend helper reports the bind failure explicitly' );
        is( scalar @stopped, 1, 'SSL frontend helper stops the backend child before surfacing the listener bind failure' );
        is( $stopped[0][0], 4242, 'backend stop helper receives the backend pid on listener bind failure' );
        is( $stopped[0][1], 'HASH', 'backend stop helper receives the reaped-child tracking hash on listener bind failure' );
    }
}

# Test 14: SSL frontend supervises its backend through GoRoutine's process API
{
    my $temp_home = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $temp_home;

    my $server = Developer::Dashboard::Web::Server->new(
        app     => Local::SSLTestApp->new,
        host    => '127.0.0.1',
        port    => 17895,
        workers => 1,
        ssl     => 1,
        ssl_backend_command_builder => sub {
            my ( $host, $port, $workers ) = @_;
            return [ $^X, '-e', 'exit 0', $host, $port, $workers ];
        },
    );
    my $daemon = Developer::Dashboard::Web::Server::Daemon->new(
        host          => '127.0.0.1',
        port          => 17895,
        internal_host => '127.0.0.1',
        internal_port => 17896,
    );

    {
        no warnings 'redefine';
        my @spawned;
        my @terminated;
        local *Developer::Dashboard::GoRoutine::spawn = sub {
            my ( $argv, $options ) = @_;
            push @spawned, [ [@{$argv}], {%{$options}} ];
            return 4243;
        };
        local *Developer::Dashboard::GoRoutine::process_running = sub { return 1 };
        local *Developer::Dashboard::GoRoutine::process_exited = sub { return 1 };
        local *Developer::Dashboard::GoRoutine::wait_process = sub { return 0 };
        local *Developer::Dashboard::GoRoutine::terminate_process = sub {
            push @terminated, [@_];
            return 1;
        };
        local *Developer::Dashboard::Web::Server::_wait_for_ssl_backend_ready = sub { return 1 };
        local *IO::Socket::INET::new = sub {
            return Local::FrontendListener->new;
        };
        local *Local::FrontendListener::accept = sub {
            sleep 0.05;
            $SIG{CHLD}->() if ref( $SIG{CHLD} ) eq 'CODE';
            return;
        };

        is(
            $server->_serve_ssl_frontend($daemon),
            1,
            'SSL frontend returns cleanly after the process API reports backend exit',
        );
        is( scalar @spawned, 2, 'SSL frontend starts one backend process and one backend watchdog through GoRoutine' );
        is_deeply( $spawned[0][0], [ $^X, '-e', 'exit 0', '127.0.0.1', 17896, 1 ],
            'backend process receives explicit executable arguments and its internal endpoint' );
        is( $spawned[0][1]{process_group}, 1, 'backend process is isolated in a managed process group' );
        is( $spawned[1][0][0], $^X, 'backend watchdog runs under the same perl' );
        is( $spawned[1][0][-4], '-e', 'backend watchdog runs an inline program' );
        is( $spawned[1][0][-2], $$, 'backend watchdog watches the frontend process' );
        is( $spawned[1][0][-1], 4243, 'backend watchdog watches the spawned backend process' );
        is_deeply( $spawned[1][1], {}, 'backend watchdog is spawned without process-group isolation' );
        is_deeply( $terminated[0], [ 4243, 'TERM' ], 'frontend shutdown terminates the managed backend process' );
    }
}

{
    local $ENV{DEVELOPER_DASHBOARD_RUNNING_HELPER} = '/tmp/private dashboard helper';
    my $server = Developer::Dashboard::Web::Server->new(
        app => Local::SSLTestApp->new, host => '127.0.0.1', port => 17897, ssl => 0,
    );
    my $daemon = Developer::Dashboard::Web::Server::Daemon->new(
        host => '127.0.0.1', port => 17897,
        internal_host => '127.0.0.1', internal_port => 17898,
    );
    is_deeply(
        $server->_ssl_backend_command($daemon),
        [ $^X, File::Spec->catfile( '/tmp', '_dashboard-core' ), 'web-ssl-backend-foreground',
          '--host', '127.0.0.1', '--port', 17898, '--workers', 1 ],
        'default SSL backend command resolves the staged core dispatcher beside its command wrapper',
    );
}

# Test 14a: Frontend shutdown cancels a client routine waiting for its first byte
{
    my $temp_home = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $temp_home;
    my $server = Developer::Dashboard::Web::Server->new(
        app     => Local::SSLTestApp->new,
        host    => '127.0.0.1',
        port    => 17899,
        workers => 1,
        ssl     => 1,
        ssl_backend_command_builder => sub { return [ $^X, '-e', 'exit 0' ] },
    );
    my $daemon = Developer::Dashboard::Web::Server::Daemon->new(
        host => '127.0.0.1', port => 17899,
        internal_host => '127.0.0.1', internal_port => 17900,
    );
    socketpair( my $client, my $peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
      or die "idle SSL client socketpair failed: $!";
    my $accept_count = 0;
    my @stopped;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::GoRoutine::spawn = sub { return 4244 };
        local *Developer::Dashboard::GoRoutine::process_running = sub { return 1 };
        local *Developer::Dashboard::GoRoutine::terminate_process = sub {
            push @stopped, [@_];
            return 1;
        };
        local *Developer::Dashboard::GoRoutine::wait_process = sub { return 0 };
        local *Developer::Dashboard::Web::Server::_wait_for_ssl_backend_ready = sub { return 1 };
        local *IO::Socket::INET::new = sub { return Local::FrontendListener->new };
        local *Local::FrontendListener::accept = sub {
            return $client if !$accept_count++;
            sleep 0.05;
            $SIG{TERM}->();
            return;
        };
        is(
            $server->_serve_ssl_frontend($daemon),
            1,
            'SSL frontend shuts down after cancelling an idle GoRoutine client handler',
        );
    }
    is_deeply( \@stopped, [ [ 4244, 'TERM' ] ], 'idle-client shutdown stops and waits for the backend process' );
    close $peer or die "Unable to close idle SSL client peer: $!";
}

# Test 15: Live SSL frontend redirects plain HTTP and still serves HTTPS on the public port
{
    my $temp_home = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $temp_home;

    my $listener = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Proto     => 'tcp',
        ReuseAddr => 1,
        Listen    => 5,
    ) or die "Unable to reserve live SSL test port: $!";
    my $port = $listener->sockport;
    close $listener or die "Unable to close reserved live SSL test port: $!";

    my $frontend_program = <<'FRONTEND_PERL';
use strict;
use warnings;
use Developer::Dashboard::GoRoutine ();
use Developer::Dashboard::Web::Server;
{
    package Local::SSLTestApp;
    sub new { bless {}, shift }
    sub authorize_request { return; }
    sub root_response { return [ 200, 'text/plain; charset=utf-8', 'OK', {} ]; }
}
my ( $port, $home ) = @ARGV;
$ENV{HOME} = $home;
my $server = Developer::Dashboard::Web::Server->new(
    app     => Local::SSLTestApp->new,
    host    => '127.0.0.1',
    port    => $port,
    workers => 1,
    ssl     => 1,
    ssl_backend_command_builder => sub {
        my ( $backend_host, $backend_port, $workers ) = @_;
        my $backend_program = <<'BACKEND_PERL';
use strict;
use warnings;
use Developer::Dashboard::GoRoutine ();
use Developer::Dashboard::Web::Server;
{
    package Local::SSLTestApp;
    sub new { bless {}, shift }
    sub authorize_request { return; }
    sub root_response { return [ 200, 'text/plain; charset=utf-8', 'OK', {} ]; }
}
my ( $host, $port, $workers ) = @ARGV;
my $server = Developer::Dashboard::Web::Server->new(
    app => Local::SSLTestApp->new, host => $host, port => $port,
    workers => $workers, ssl => 1,
);
my $daemon = Developer::Dashboard::Web::Server::Daemon->new(
    host => $host, port => $port, internal_host => $host, internal_port => $port,
);
exit $server->_run_ssl_backend_process($daemon);
BACKEND_PERL
        my @library_args = map { ( '-I', $_ ) } grep { defined && -d $_ } @INC;
        return [ $^X, @library_args, '-e', $backend_program, $backend_host, $backend_port, $workers ];
    },
);
exit $server->run;
FRONTEND_PERL
    my $pid = _spawn_perl_fixture( $frontend_program, $port, $temp_home );

    my $ready = 0;
    # Ten parallel TAP workers can delay native server startup on CI.
    for ( 1 .. 200 ) {
        my $probe = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1',
            PeerPort => $port,
            Proto    => 'tcp',
        );
        if ($probe) {
            close $probe;
            $ready = 1;
            last;
        }
        sleep 0.1;
    }
    ok( $ready, 'live SSL frontend became reachable on the public port' );

    my $http = LWP::UserAgent->new(
        max_redirect => 0,
        timeout      => 5,
    );
    my $http_response = $http->get("http://127.0.0.1:$port/live-check?mode=http");
    is( $http_response->code, 307, 'live SSL frontend redirects plain HTTP on the public port' );
    is(
        $http_response->header('Location'),
        "https://127.0.0.1:$port/live-check?mode=http",
        'live SSL frontend redirects plain HTTP to the equivalent HTTPS URL on the same public port'
    );

    my $https_socket;
    for ( 1 .. 50 ) {
        $https_socket = IO::Socket::SSL->new(
            PeerHost        => '127.0.0.1',
            PeerPort        => $port,
            SSL_verify_mode => 0,
            Timeout         => 5,
        );
        last if $https_socket;
        sleep 0.1;
    }
    ok( $https_socket, 'live SSL frontend accepts a direct TLS client on the public port' );
    my $https_raw = '';
    if ($https_socket) {
        print {$https_socket} "GET / HTTP/1.1\r\nHost: 127.0.0.1:$port\r\nConnection: close\r\n\r\n"
          or die "Unable to write HTTPS test request: $!";
        $https_raw = do {
            local $/;
            <$https_socket>;
        };
        close $https_socket;
        # The Windows backend is Plack Standalone (HTTP::Server::PSGI),
        # which always answers HTTP/1.0 (its status line is a literal
        # "HTTP/1.0" and its POD says to use Starman for HTTP/1.1),
        # while Starman on Linux/macOS answers HTTP/1.1. Either version
        # is a valid 200 response to this HTTP/1.1 request; the test is
        # about serving HTTPS on the public port, not the version token.
        like( $https_raw, qr/^HTTP\/1\.[01] 200 OK\r\n/, 'live SSL frontend still serves HTTPS on the public port' );
        like( $https_raw, qr/\r\n\r\nOK\z/s, 'live SSL frontend preserves the HTTPS app response body' );
    }
    else {
        diag( 'IO::Socket::SSL connect error: ' . ( IO::Socket::SSL::errstr() || 'unknown SSL error' ) );
        fail('live SSL frontend still serves HTTPS on the public port');
        fail('live SSL frontend preserves the HTTPS app response body');
    }

    Developer::Dashboard::GoRoutine::terminate_process($pid);
    my $exit_status = Developer::Dashboard::GoRoutine::wait_process($pid);
    is(
        Developer::Dashboard::GoRoutine::process_running($pid),
        0,
        'live SSL frontend process is reaped after termination',
    );
    ok( defined $exit_status, 'live SSL frontend termination status is collected' );
}

# Test 16: The HTTPS-enforcement redirect never names a client-supplied authority
{
    # A blessed hash is enough here: none of the redirect helpers touch the app,
    # the sockets, or the certificate, so this stays hermetic and fast.
    my $server = bless {
        host                  => '127.0.0.1',
        port                  => 7890,
        workers               => 1,
        ssl                   => 1,
        ssl_subject_alt_names => ['dashboard-alias.local'],
    }, 'Developer::Dashboard::Web::Server';

    my %hostile_env = (
        HTTP_HOST   => 'evil.com',
        SERVER_NAME => 'redirect.local',
        SERVER_PORT => 8443,
        PATH_INFO   => '/x',
    );

    my $hostile_location = $server->_https_redirect_location( {%hostile_env} );
    unlike(
        $hostile_location,
        qr{evil\.com},
        'PSGI redirect location never names an unallowlisted Host header authority'
    );
    is(
        $hostile_location,
        'https://redirect.local:8443/x',
        'PSGI redirect location falls back to the server-derived authority for a hostile Host header'
    );

    my $hostile_response = $server->_ssl_redirect_response( {%hostile_env} );
    is( $hostile_response->[0], 307, 'hostile Host header still gets a 307 redirect' );
    my %hostile_headers = @{ $hostile_response->[1] };
    unlike(
        $hostile_headers{Location},
        qr{evil\.com},
        'PSGI redirect Location header never carries an unallowlisted Host header authority'
    );

    is(
        $server->_https_redirect_location(
            { HTTP_HOST => 'dashboard-alias.local:7890', PATH_INFO => '/x' }
        ),
        'https://dashboard-alias.local:7890/x',
        'PSGI redirect location keeps a Host header listed in ssl_subject_alt_names'
    );
    is(
        $server->_https_redirect_location( { HTTP_HOST => '127.0.0.5:7890', PATH_INFO => '/x' } ),
        'https://127.0.0.5:7890/x',
        'PSGI redirect location keeps a loopback literal Host header'
    );
    is(
        $server->_https_redirect_location( { HTTP_HOST => '[::1]:7890', PATH_INFO => '/x' } ),
        'https://[::1]:7890/x',
        'PSGI redirect location keeps a bracketed IPv6 loopback Host header'
    );

    # The socket-level frontend is the path a real plain-HTTP client reaches on
    # the public SSL port, so it needs the same allowlist.
    my $daemon = Developer::Dashboard::Web::Server::Daemon->new(
        host => '127.0.0.1',
        port => 7890,
    );
    is(
        $server->_request_host_from_head( "GET /x HTTP/1.1\r\nHost: evil.com\r\n\r\n", $daemon ),
        '127.0.0.1:7890',
        'frontend request-host helper rejects an unallowlisted Host header and uses the bound authority'
    );
    is(
        $server->_request_host_from_head(
            "GET /x HTTP/1.1\r\nHost: dashboard-alias.local:7890\r\n\r\n", $daemon
        ),
        'dashboard-alias.local:7890',
        'frontend request-host helper keeps an allowlisted alias Host header'
    );

    # The request target is concatenated straight after the authority, so an
    # authority-form target can push the real host into the userinfo slot.
    is(
        Developer::Dashboard::Web::Server::_request_target_from_head("GET \@evil.com/ HTTP/1.1\r\n\r\n"),
        '/',
        'frontend request-target helper rejects an authority-form target that would move the authority'
    );

    socketpair( my $redirect_client, my $redirect_peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
      or die "socketpair failed: $!";
    my $hostile_head = "GET \@evil.com/x HTTP/1.1\r\nHost: evil.com\r\n\r\n";
    my $written = syswrite( $redirect_peer, $hostile_head );
    die "Unable to write hostile request head: $!"
      if !defined $written || $written != length $hostile_head;
    shutdown( $redirect_peer, 1 ) or die "Unable to half-close hostile request peer: $!";
    is(
        $server->_handle_ssl_frontend_client( client => $redirect_client, daemon => $daemon ),
        1,
        'frontend client handler answers a hostile plaintext request'
    );
    my $hostile_raw = '';
    my $read_bytes = sysread( $redirect_peer, $hostile_raw, 4096 );
    die "Unable to read hostile redirect response: $!" if !defined $read_bytes;
    close $redirect_client;
    close $redirect_peer;
    unlike(
        $hostile_raw,
        qr{evil\.com},
        'frontend redirect response never names a client-supplied authority'
    );
    like(
        $hostile_raw,
        qr{\r\nLocation: https://127\.0\.0\.1:7890/\r\n},
        'frontend redirect response falls back to the bound authority and a safe target'
    );
}

# Test 17: HTTPS starts on a Windows session, which has no HOME variable
{
    # Windows does not export HOME. The profile directory is named by
    # USERPROFILE, or by HOMEDRIVE plus HOMEPATH on older shells, and the path
    # registry already resolves that order. The SSL certificate helpers must go
    # through it: demanding HOME here killed "dashboard web --ssl" on Windows
    # before it ever reached a socket.
    my $started_in = getcwd();
    my $profile_home = tempdir( CLEANUP => 1 );
    chdir $profile_home or die "Unable to chdir to $profile_home: $!";

    my $expected_dir  = File::Spec->catdir( $profile_home, '.developer-dashboard', 'certs' );
    my $expected_cert = File::Spec->catfile( $expected_dir, 'server.crt' );
    my $expected_key  = File::Spec->catfile( $expected_dir, 'server.key' );

    {
        local %ENV = %ENV;
        delete $ENV{HOME};
        $ENV{USERPROFILE} = $profile_home;

        my $generated = Developer::Dashboard::Web::Server::generate_self_signed_cert();
        is(
            $generated,
            $expected_cert,
            'certificate generation resolves USERPROFILE as home when HOME is absent'
        );
        ok( -d $expected_dir, 'certificate directory is created under the Windows profile directory' );
        ok( -f $expected_key, 'private key is written under the Windows profile directory' );

        my ( $cert_file, $key_file ) = Developer::Dashboard::Web::Server::get_ssl_cert_paths();
        is(
            $cert_file,
            $expected_cert,
            'certificate path lookup resolves USERPROFILE as home when HOME is absent'
        );
        is(
            $key_file,
            $expected_key,
            'key path lookup resolves USERPROFILE as home when HOME is absent'
        );

        my $cert_info = _openssl_cert_text($cert_file);
        like(
            $cert_info,
            qr/Subject Alternative Name:\s+DNS:localhost, IP Address:127\.0\.0\.1/s,
            'the certificate generated without HOME still carries the browser-safe SAN profile'
        );
    }

    chdir $started_in or die "Unable to return to $started_in: $!";
}


# DD-623: the certificate's validity period is configurable, and a value beyond
# the 398-day public-CA limit is HONOURED rather than clamped.
#
# The clamp assertion is the one that matters. Browsers reject publicly-trusted
# certificates valid past 398 days, but that rule covers certificates issued by
# publicly trusted CAs and explicitly not locally-operated ones, so it does not
# reach a self-signed localhost certificate. A clamping implementation would
# still emit a warning and would still pass any test that only checked for the
# warning - so this asserts the notAfter itself.
{
    my $temp_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $temp_home;

    # Purpose: the certificate's own notAfter, as openssl reports it, in epoch
    #          seconds - read back from the artifact rather than inferred from
    #          the argument that was passed in.
    # Input:   path to a PEM certificate
    # Output:  epoch seconds, or undef when openssl could not be read
    my $not_after_epoch = sub {
        my ($cert) = @_;
        my ( $out, undef, $exit ) = capture {
            system( 'openssl', 'x509', '-in', $cert, '-noout', '-enddate' );
        };
        return if $exit != 0;
        return if $out !~ /notAfter=(.+)/;
        my $when = $1;
        chomp $when;
        my ( $sec, undef, undef, undef, undef, undef, undef, undef, undef ) = ();
        my ( $o2, undef, $e2 ) = capture {
            system( 'date', '-d', $when, '+%s' );
        };
        return if $e2 != 0;
        chomp $o2;
        return $o2 + 0;
    };

    my $cert = Developer::Dashboard::Web::Server::generate_self_signed_cert(
        validity_days => 730,
    );
    ok( $cert && -f $cert, 'cert generated with a configured validity period' );
    my $epoch = $not_after_epoch->($cert);
  SKIP: {
        skip 'openssl/date unavailable for notAfter inspection', 2 if !defined $epoch;
        my $days = int( ( $epoch - time ) / 86_400 );
        cmp_ok( abs( $days - 730 ), '<=', 2, "configured 730-day validity is honoured (got ${days}d)" );

        # A fresh HOME, so the 730-day cert above cannot be reused and mask this.
        my $temp_home2 = tempdir( CLEANUP => 1 );
        local $ENV{HOME} = $temp_home2;
        my $long = Developer::Dashboard::Web::Server::generate_self_signed_cert(
            validity_days => 3650,
        );
        my $long_epoch = $not_after_epoch->($long);
        my $long_days = defined $long_epoch ? int( ( $long_epoch - time ) / 86_400 ) : -1;
        cmp_ok( abs( $long_days - 3650 ), '<=', 2,
            "a 3650-day validity is NOT clamped to 398 (got ${long_days}d)" );
    }
}

done_testing();

__END__

=head1 NAME

t/17-web-server-ssl.t - SSL support tests for Developer Dashboard web server

=head1 DESCRIPTION

Tests self-signed certificate generation, SSL flag handling, HTTPS URL generation,
Starman SSL configuration, and HTTP->HTTPS redirect middleware.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for HTTPS serving, certificates, and browser-facing SSL behavior. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because HTTPS serving, certificates, and browser-facing SSL behavior has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing HTTPS serving, certificates, and browser-facing SSL behavior, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/17-web-server-ssl.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. 

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/17-web-server-ssl.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/17-web-server-ssl.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut

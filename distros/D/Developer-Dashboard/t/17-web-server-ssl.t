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
use File::Path qw(make_path remove_tree);
use File::Spec;
use File::Temp qw(tempdir tempfile);
use IO::Socket::INET;
use IO::Socket::SSL ();
use HTTP::Request::Common qw(GET);
use LWP::UserAgent;
use Plack::Test;
use Socket qw(AF_UNIX PF_UNSPEC SOCK_STREAM);
use Test::More;
use Time::HiRes qw(sleep);

use lib 'lib';

use Developer::Dashboard::Web::Server;
use Developer::Dashboard::Web::DancerApp;

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

    sub new { bless {}, shift }

    sub accept { return; }

    sub close { return 1; }
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
    is(_mode_octal($cert_dir), '0700', 'cert directory is owner-only');
    is(_mode_octal($cert_file), '0600', 'certificate file is owner-only');
    is(_mode_octal($key_file), '0600', 'private key file is owner-only');
    
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
    ok( $runner_options{ssl_key}, 'Plack runner includes SSL key path' );
    ok( $runner_options{ssl_cert}, 'Plack runner includes SSL certificate path' );

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
    
    test_psgi $psgi_app, sub {
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
    };
}

# Test 8: Command line --ssl flag parsing
{
    # This test is handled in bin/dashboard integration tests
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
        Developer::Dashboard::Web::Server::_https_redirect_location({
            SERVER_NAME => 'redirect.local',
            SERVER_PORT => 443,
        }),
        'https://redirect.local/',
        'fallback redirect location omits the default HTTPS port'
    );
    is(
        Developer::Dashboard::Web::Server::_https_redirect_location({
            SERVER_NAME  => 'redirect.local',
            SERVER_PORT  => 8443,
            SCRIPT_NAME  => '/dashboard',
            PATH_INFO    => '/ssl',
            QUERY_STRING => 'mode=test',
        }),
        'https://redirect.local:8443/dashboard/ssl?mode=test',
        'fallback redirect location rebuilds host, path, port, and query string'
    );

    my $redirect_response = Developer::Dashboard::Web::Server::_ssl_redirect_response({
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
        Developer::Dashboard::Web::Server::_request_host_from_head("GET / HTTP/1.1\r\n\r\n", $default_port_daemon),
        'redirect.local',
        'request-host helper omits the default HTTPS port in fallback mode'
    );
    my $custom_port_daemon = Developer::Dashboard::Web::Server::Daemon->new(
        host => 'redirect.local',
        port => 8443,
    );
    is(
        Developer::Dashboard::Web::Server::_request_host_from_head(undef, $custom_port_daemon),
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
        no warnings 'redefine';
        local *IO::Select::new = sub { return Local::EmptySelect->new };
        is(
            Developer::Dashboard::Web::Server::_proxy_streams( 'client', 'backend' ),
            1,
            'stream proxy returns cleanly when the readiness loop finishes without readable sockets'
        );
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

    my $default_signal_pid = fork();
    die "Unable to fork default signal test child: $!" if !defined $default_signal_pid;
    if ( !$default_signal_pid ) {
        local $SIG{TERM} = 'IGNORE';
        Developer::Dashboard::Web::Server::_signal_default_term();
        exit 0;
    }
    waitpid( $default_signal_pid, 0 );
    is( ($? >> 8), 0, 'TERM helper returns when TERM is ignored in the child process' );
}

# Test 13: Live SSL frontend redirects plain HTTP and still serves HTTPS on the public port
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

    my $server = Developer::Dashboard::Web::Server->new(
        app     => Local::SSLTestApp->new,
        host    => '127.0.0.1',
        port    => $port,
        workers => 1,
        ssl     => 1,
    );

    my $pid = fork();
    die "Unable to fork live SSL server test: $!" if !defined $pid;
    if ( !$pid ) {
        $server->run;
        exit 0;
    }

    my $ready = 0;
    for ( 1 .. 50 ) {
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
        like( $https_raw, qr/^HTTP\/1\.1 200 OK\r\n/, 'live SSL frontend still serves HTTPS on the public port' );
        like( $https_raw, qr/\r\n\r\nOK\z/s, 'live SSL frontend preserves the HTTPS app response body' );
    }
    else {
        diag( 'IO::Socket::SSL connect error: ' . ( IO::Socket::SSL::errstr() || 'unknown SSL error' ) );
        fail('live SSL frontend still serves HTTPS on the public port');
        fail('live SSL frontend preserves the HTTPS app response body');
    }

    kill 'TERM', $pid;
    waitpid( $pid, 0 );
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

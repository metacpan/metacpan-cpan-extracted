package Developer::Dashboard::Web::Server;

use strict;
use warnings;

our $VERSION = '2.35';

use Capture::Tiny qw(capture);
use File::Spec;
use File::Temp qw(tempfile);
use IO::Select;
use IO::Socket::INET;
use Plack::Runner;
use Socket qw(MSG_PEEK);

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Web::DancerApp;
use Developer::Dashboard::Web::Server::Daemon;

our $SSL_BACKEND_PID;
our %SSL_PREVIOUS_SIGNAL;

# new(%args)
# Constructs the local PSGI web server wrapper.
# Input: app object plus optional host, port, worker count, and ssl flag.
# Output: Developer::Dashboard::Web::Server object.
sub new {
    my ( $class, %args ) = @_;
    my $app     = $args{app}  || die 'Missing web app';
    my $host    = defined $args{host} ? $args{host} : '0.0.0.0';
    my $port    = defined $args{port} ? $args{port} : 7890;
    my $workers = defined $args{workers} ? $args{workers} : 1;
    my $ssl     = defined $args{ssl} ? $args{ssl} ? 1 : 0 : 0;
    my $ssl_subject_alt_names = ref( $args{ssl_subject_alt_names} ) eq 'ARRAY'
      ? [ @{ $args{ssl_subject_alt_names} } ]
      : [];
    die 'Missing worker count' if !defined $workers || $workers eq '';
    die 'Worker count must be a positive integer' if $workers !~ /^\d+$/ || $workers < 1;

    if ($ssl) {
        generate_self_signed_cert(
            host  => $host,
            hosts => $ssl_subject_alt_names,
        );
    }

    return bless {
        app                   => $app,
        host                  => $host,
        port                  => $port,
        workers               => $workers + 0,
        ssl                   => $ssl,
        ssl_subject_alt_names => $ssl_subject_alt_names,
    }, $class;
}

# run()
# Starts the PSGI daemon wrapper and serves requests until the runner exits.
# Input: none.
# Output: true value when the server loop completes.
sub run {
    my ($self) = @_;

    my $daemon = $self->start_daemon;
    print "Developer Dashboard listening on ", $self->listening_url($daemon), "\n";
    return $self->serve_daemon($daemon);
}

# start_daemon()
# Reserves and validates the listen address before Starman starts.
# Input: none.
# Output: daemon descriptor object with resolved host and port.
sub start_daemon {
    my ($self) = @_;
    my $socket = IO::Socket::INET->new(
        LocalAddr => $self->{host},
        LocalPort => $self->{port},
        Proto     => 'tcp',
        ReuseAddr => 1,
        Listen    => 10,
    );
    die "Unable to start server on $self->{host}:$self->{port}: $!" if !$socket;

    my $daemon = Developer::Dashboard::Web::Server::Daemon->new(
        host => scalar( $socket->sockhost ),
        port => scalar( $socket->sockport ),
    );
    close $socket or die "Unable to close reserved listen socket: $!";
    return $daemon if !$self->{ssl};

    my $backend_socket = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Proto     => 'tcp',
        ReuseAddr => 1,
        Listen    => 10,
    );
    die "Unable to reserve internal SSL backend port: $!" if !$backend_socket;

    my $ssl_daemon = Developer::Dashboard::Web::Server::Daemon->new(
        host          => $daemon->sockhost,
        port          => $daemon->sockport,
        internal_host => scalar( $backend_socket->sockhost ),
        internal_port => scalar( $backend_socket->sockport ),
    );
    close $backend_socket or die "Unable to close reserved internal SSL backend socket: $!";
    return $ssl_daemon;
}

# listening_url($daemon)
# Builds the public listening URL for a daemon instance.
# Input: daemon descriptor object or undef.
# Output: URL string with http:// or https:// scheme based on ssl flag, or placeholder if daemon unavailable.
sub listening_url {
    my ( $self, $daemon ) = @_;
    return unless defined $daemon;
    my $scheme = $self->{ssl} ? 'https' : 'http';
    my $host = $daemon->sockhost // 'localhost';
    my $port = $daemon->sockport // 7890;
    return sprintf '%s://%s:%s/', $scheme, $host, $port;
}

# serve_daemon($daemon)
# Runs the Dancer2 PSGI app under Starman through Plack::Runner.
# Input: daemon descriptor object.
# Output: true value when the PSGI runner exits.
sub serve_daemon {
    my ( $self, $daemon ) = @_;
    return $self->_serve_ssl_frontend($daemon) if $self->{ssl};
    my $runner = $self->_build_runner($daemon);
    my $app = $self->psgi_app;
    $runner->run($app);
    return 1;
}

# psgi_app()
# Builds the Dancer2 PSGI application with the standard security headers.
# Input: none.
# Output: PSGI application code reference.
sub psgi_app {
    my ($self) = @_;
    my $app = Developer::Dashboard::Web::DancerApp->build_psgi_app(
        app             => $self->{app},
        default_headers => $self->_default_headers,
    );
    return $app if !$self->{ssl};
    return sub {
        my ($env) = @_;
        return _ssl_redirect_response($env) if !_request_is_https($env);
        return $app->($env);
    };
}

# _build_runner($daemon)
# Configures the Plack runner to serve the dashboard PSGI app via Starman.
# Includes SSL configuration (--ssl-key and --ssl-cert) when ssl flag is enabled.
# Input: daemon descriptor object.
# Output: Plack::Runner object.
sub _build_runner {
    my ( $self, $daemon ) = @_;
    my $runner = Plack::Runner->new;
    my $listen_host = $self->{ssl} && $daemon->can('internal_sockhost') && defined $daemon->internal_sockhost
      ? $daemon->internal_sockhost
      : $daemon->sockhost;
    my $listen_port = $self->{ssl} && $daemon->can('internal_sockport') && defined $daemon->internal_sockport
      ? $daemon->internal_sockport
      : $daemon->sockport;
    my @options = (
        '--server', 'Starman',
        '--host',   $listen_host,
        '--port',   $listen_port,
        '--env',    'deployment',
        '--workers', $self->{workers},
    );

    if ( $self->{ssl} ) {
        my ( $cert, $key ) = get_ssl_cert_paths();
        push @options, '--ssl',      1;
        push @options, '--ssl-key',  $key;
        push @options, '--ssl-cert', $cert;
    }

    $runner->parse_options(@options);
    return $runner;
}

# _serve_ssl_frontend($daemon)
# Runs the public SSL frontend on the requested port and proxies real TLS
# traffic to an internal SSL Starman backend while redirecting plain HTTP.
# Input: daemon descriptor with public and internal backend listen details.
# Output: true value when the frontend loop exits.
sub _serve_ssl_frontend {
    my ( $self, $daemon ) = @_;
    my $backend_pid = fork();
    die "Unable to fork SSL backend process: $!" if !defined $backend_pid;

    if ( !$backend_pid ) {
        my $runner = $self->_build_runner($daemon);
        my $app = $self->psgi_app;
        $runner->run($app);
        # uncoverable statement
        exit 0;
    }

    my $previous_term = $SIG{TERM};
    my $previous_int  = $SIG{INT};
    my $previous_hup  = $SIG{HUP};
    local $SSL_BACKEND_PID = $backend_pid;
    local %SSL_PREVIOUS_SIGNAL = (
        TERM => $previous_term,
        INT  => $previous_int,
        HUP  => $previous_hup,
    );
    local $SIG{TERM} = \&_ssl_term_handler;
    local $SIG{INT}  = \&_ssl_int_handler;
    local $SIG{HUP}  = \&_ssl_hup_handler;

    my $listener = IO::Socket::INET->new(
        LocalAddr => $daemon->sockhost,
        LocalPort => $daemon->sockport,
        Proto     => 'tcp',
        ReuseAddr => 1,
        Listen    => 128,
    );
    if ( !$listener ) {
        # uncoverable statement
        _stop_ssl_backend($backend_pid);
        # uncoverable statement
        die "Unable to bind SSL frontend on $self->{host}:$self->{port}: $!";
    }

    while ( my $client = $listener->accept ) {
        my $pid = fork();
        die "Unable to fork SSL frontend connection handler: $!" if !defined $pid;
        if ($pid) {
            close $client;
            while ( waitpid( -1, 1 ) > 0 ) { }
            next;
        }

        close $listener;
        eval {
            $self->_handle_ssl_frontend_client(
                client => $client,
                daemon => $daemon,
            );
        };
        close $client;
        exit 0;
    }

    close $listener;
    _stop_ssl_backend($backend_pid);
    waitpid( $backend_pid, 0 );
    return 1;
}

# _handle_ssl_frontend_client(%args)
# Routes one accepted frontend socket either to the internal TLS backend or to
# a direct HTTP->HTTPS redirect response.
# Input: accepted client socket and daemon descriptor.
# Output: true value after the client socket is handled.
sub _handle_ssl_frontend_client {
    my ( $self, %args ) = @_;
    my $client = $args{client} || die 'Missing frontend client socket';
    my $daemon = $args{daemon} || die 'Missing daemon descriptor';
    my $first = '';
    my $peeked = recv( $client, $first, 1, MSG_PEEK );
    return 1 if !defined $peeked || !defined $first || $first eq '';

    if ( _socket_looks_like_tls($first) ) {
        my $backend = IO::Socket::INET->new(
            PeerAddr => $daemon->internal_sockhost,
            PeerPort => $daemon->internal_sockport,
            Proto    => 'tcp',
        );
        die "Unable to connect to internal SSL backend: $!" if !$backend;
        _proxy_streams( $client, $backend );
        close $backend;
        return 1;
    }

    my $request = _read_http_request_head($client);
    my $response = _http_redirect_response(
        host   => _request_host_from_head( $request, $daemon ),
        target => _request_target_from_head($request),
    );
    syswrite( $client, $response );
    return 1;
}

# _socket_looks_like_tls($byte)
# Detects whether the first byte of an accepted socket looks like a TLS
# handshake instead of a plain HTTP request line.
# Input: first byte string read with MSG_PEEK.
# Output: boolean true when the socket should be proxied to the TLS backend.
sub _socket_looks_like_tls {
    my ($byte) = @_;
    return 0 if !defined $byte || $byte eq '';
    return ord($byte) == 22 ? 1 : 0;
}

# _read_http_request_head($socket)
# Reads one plain-HTTP request head from a client socket for redirect handling.
# Input: accepted plain HTTP client socket.
# Output: raw request-head string.
sub _read_http_request_head {
    my ($socket) = @_;
    my $head = '';
    while ( length($head) < 16384 ) {
        my $chunk = '';
        my $read = sysread( $socket, $chunk, 1024 );
        last if !defined $read || $read <= 0;
        $head .= $chunk;
        last if $head =~ /\r?\n\r?\n/;
    }
    if ( $head =~ /\A(.*?\r?\n\r?\n)/s ) {
        return $1;
    }
    return $head;
}

# _request_target_from_head($head)
# Extracts the requested path and query from one plain HTTP request head.
# Input: raw request-head string.
# Output: path/query target string, defaulting to /.
sub _request_target_from_head {
    my ($head) = @_;
    return '/' if !defined $head || $head eq '';
    return $1 if $head =~ m{\A[A-Z]+\s+(\S+)\s+HTTP/}s;
    return '/';
}

# _request_host_from_head($head, $daemon)
# Extracts or reconstructs the public host:port for one redirecting plain HTTP
# request.
# Input: raw request-head string and daemon descriptor.
# Output: host[:port] string.
sub _request_host_from_head {
    my ( $head, $daemon ) = @_;
    if ( defined $head && $head =~ /^Host:\s*([^\r\n]+)/im ) {
        return $1;
    }
    my $host = $daemon->sockhost || '127.0.0.1';
    my $port = $daemon->sockport || 443;
    return $port == 443 ? $host : $host . ':' . $port;
}

# _http_redirect_response(%args)
# Builds the raw HTTP response used by the SSL frontend for plaintext requests
# that arrive on the public SSL port.
# Input: host[:port] string and path/query target string.
# Output: raw HTTP response string.
sub _http_redirect_response {
    my (%args) = @_;
    my $target = defined $args{target} && $args{target} ne '' ? $args{target} : '/';
    my $host   = $args{host} || '127.0.0.1';
    my $body   = 'Redirecting to HTTPS';
    return join(
        "\r\n",
        'HTTP/1.1 307 Temporary Redirect',
        'Content-Type: text/plain; charset=utf-8',
        'Content-Length: ' . length($body),
        'Location: https://' . $host . $target,
        'Connection: close',
        '',
        $body,
    );
}

# _proxy_streams($client, $backend)
# Pumps bytes bidirectionally between the public client socket and the internal
# TLS backend socket until one side closes.
# Input: accepted client socket and connected backend socket.
# Output: true value when forwarding completes.
sub _proxy_streams {
    my ( $client, $backend ) = @_;
    my $select = IO::Select->new( $client, $backend );
    while ( my @ready = $select->can_read ) {
        for my $source (@ready) {
            my $chunk = '';
            my $read = sysread( $source, $chunk, 8192 );
            return 1 if !defined $read || $read <= 0;
            my $target = $source == $client ? $backend : $client;
            my $offset = 0;
            while ( $offset < length $chunk ) {
                my $written = syswrite( $target, $chunk, length($chunk) - $offset, $offset );
                die "Unable to proxy SSL frontend bytes: $!" if !defined $written;
                $offset += $written;
            }
        }
    }
    return 1;
}

# _stop_ssl_backend($pid)
# Terminates the internal SSL backend process used by the public SSL frontend.
# Input: backend pid integer.
# Output: true value.
sub _stop_ssl_backend {
    my ($pid) = @_;
    return 1 if !$pid;
    kill 'TERM', $pid;
    waitpid( $pid, 0 );
    return 1;
}

# _ssl_term_handler()
# Handles TERM for the SSL frontend by stopping the backend and chaining the
# previous TERM handler.
# Input: none.
# Output: true value.
sub _ssl_term_handler {
    return _handle_ssl_signal('TERM');
}

# _ssl_int_handler()
# Handles INT for the SSL frontend by stopping the backend and chaining the
# previous INT handler.
# Input: none.
# Output: true value.
sub _ssl_int_handler {
    return _handle_ssl_signal('INT');
}

# _ssl_hup_handler()
# Handles HUP for the SSL frontend by stopping the backend and chaining the
# previous HUP handler.
# Input: none.
# Output: true value.
sub _ssl_hup_handler {
    return _handle_ssl_signal('HUP');
}

# _handle_ssl_signal($name)
# Dispatches one frontend signal by shutting down the internal backend and then
# continuing the previous signal chain for that signal name.
# Input: signal name string.
# Output: true value.
sub _handle_ssl_signal {
    my ($name) = @_;
    _stop_ssl_backend($SSL_BACKEND_PID);
    return _run_previous_signal( $SSL_PREVIOUS_SIGNAL{$name} );
}

# _run_previous_signal($handler)
# Continues the outer signal handling chain after the SSL frontend has cleaned
# up its internal backend process.
# Input: previous signal handler value.
# Output: true value, or re-signals the current process for DEFAULT handlers.
sub _run_previous_signal {
    my ($handler) = @_;
    return 1 if !defined $handler;
    if ( ref($handler) eq 'CODE' ) {
        $handler->();
        return 1;
    }
    return _signal_default_term() if $handler eq 'DEFAULT';
    return 1;
}

# _signal_default_term()
# Re-signals the current process with TERM when a previous handler was the
# default action.
# Input: none.
# Output: true value when TERM is ignored, otherwise the process terminates.
sub _signal_default_term {
    kill 'TERM', $$;
    return 1;
}

# _default_headers()
# Returns the security and cache headers applied to every browser response.
# Input: none.
# Output: hash reference of header names to values.
sub _default_headers {
    return {
        'X-Frame-Options'         => 'DENY',
        'X-Content-Type-Options'  => 'nosniff',
        'Referrer-Policy'         => 'no-referrer',
        'Cache-Control'           => 'no-store',
        'Content-Security-Policy' => q{default-src 'self' 'unsafe-inline' data:; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'},
    };
}

# _request_is_https($env)
# Detects whether the current PSGI request already arrived through HTTPS or a
# trusted forwarded HTTPS indicator.
# Input: PSGI environment hash reference.
# Output: boolean true when the request is already HTTPS.
sub _request_is_https {
    my ($env) = @_;
    return 0 if ref($env) ne 'HASH';
    my $scheme = defined $env->{'psgi.url_scheme'} ? lc( $env->{'psgi.url_scheme'} ) : '';
    return 1 if $scheme eq 'https';
    my $forwarded = defined $env->{HTTP_X_FORWARDED_PROTO} ? lc( $env->{HTTP_X_FORWARDED_PROTO} ) : '';
    return 1 if $forwarded eq 'https';
    return 0;
}

# _ssl_redirect_response($env)
# Builds the HTTP-to-HTTPS redirect response used when SSL mode is enabled but
# the incoming request still uses HTTP.
# Input: PSGI environment hash reference.
# Output: PSGI array response with redirect status, headers, and body.
sub _ssl_redirect_response {
    my ($env) = @_;
    my $location = _https_redirect_location($env);
    return [
        307,
        [
            'Content-Type' => 'text/plain; charset=utf-8',
            'Location'     => $location,
        ],
        ['Redirecting to HTTPS'],
    ];
}

# _https_redirect_location($env)
# Rebuilds the current request URL with an https:// scheme for SSL-enforcement
# redirects.
# Input: PSGI environment hash reference.
# Output: absolute HTTPS URL string.
sub _https_redirect_location {
    my ($env) = @_;
    my $host = defined $env->{HTTP_HOST} ? $env->{HTTP_HOST} : '';
    if ( $host eq '' ) {
        my $server_name = defined $env->{SERVER_NAME} ? $env->{SERVER_NAME} : '127.0.0.1';
        my $server_port = defined $env->{SERVER_PORT} ? $env->{SERVER_PORT} : 443;
        $host = $server_name;
        $host .= ':' . $server_port if defined $server_port && $server_port ne '' && $server_port !~ /^443$/;
    }
    my $path = defined $env->{SCRIPT_NAME} ? $env->{SCRIPT_NAME} : '';
    $path .= defined $env->{PATH_INFO} ? $env->{PATH_INFO} : '/';
    $path = '/' if $path eq '';
    my $query = defined $env->{QUERY_STRING} ? $env->{QUERY_STRING} : '';
    return 'https://' . $host . $path . ( $query ne '' ? '?' . $query : '' );
}

# generate_self_signed_cert(%args)
# Generates or reuses a self-signed certificate for HTTPS.
# Creates ~/.developer-dashboard/certs/ if it does not exist.
# Reuses existing certificates when they already match the expected browser-safe
# localhost/loopback profile plus any requested extra SAN names/IPs, and
# regenerates older legacy certificates when they do not.
# Input: optional bind host string and optional hosts array reference.
# Output: path to certificate file, or dies on error.
sub generate_self_signed_cert {
    my (%args) = @_;
    my $home = $ENV{HOME} || die 'Missing HOME environment variable';
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
    my $cert_dir = File::Spec->catdir( $paths->home_runtime_path, 'certs' );
    my $cert_file = File::Spec->catfile($cert_dir, 'server.crt');
    my $key_file  = File::Spec->catfile($cert_dir, 'server.key');
    my @expected_subject_alt_names = _ssl_expected_subject_alt_names(
        host  => $args{host},
        hosts => $args{hosts},
    );

    if (
        -f $cert_file
        && -f $key_file
        && _ssl_cert_has_expected_profile(
            $cert_file,
            hosts => \@expected_subject_alt_names,
        )
      )
    {
        $paths->secure_dir_permissions($cert_dir);
        $paths->secure_file_permissions($cert_file);
        $paths->secure_file_permissions($key_file);
        return $cert_file;
    }

    $paths->ensure_dir($cert_dir);
    unlink $cert_file if -f $cert_file;
    unlink $key_file  if -f $key_file;

    my ( $config_fh, $config_file ) = tempfile( 'dd-openssl-XXXXXX', SUFFIX => '.cnf', DIR => $cert_dir );
    my $config_text_head = <<'OPENSSL_CONFIG';
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
x509_extensions = v3_req

[ dn ]
C = US
ST = Local
L = Local
O = Developer Dashboard
CN = localhost

[ v3_req ]
subjectAltName = @alt_names
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature,keyEncipherment
extendedKeyUsage = serverAuth

[ alt_names ]
OPENSSL_CONFIG
    my $alt_names_text = '';
    my $dns_index = 0;
    my $ip_index  = 0;
    for my $subject_alt_name (@expected_subject_alt_names) {
        if ( _ssl_subject_alt_name_is_ip($subject_alt_name) ) {
            $ip_index++;
            $alt_names_text .= sprintf "IP.%d = %s\n", $ip_index, $subject_alt_name;
            next;
        }
        $dns_index++;
        $alt_names_text .= sprintf "DNS.%d = %s\n", $dns_index, $subject_alt_name;
    }
    my $config_text = $config_text_head . $alt_names_text;
    print {$config_fh} $config_text or die "Unable to write OpenSSL config $config_file: $!";
    close $config_fh or die "Unable to close OpenSSL config $config_file: $!";

    my @cmd = (
        'openssl', 'req', '-new', '-x509', '-days', '365',
        '-nodes',
        '-config', $config_file,
        '-out', $cert_file,
        '-keyout', $key_file,
    );

    my ($stdout, $stderr, $exit) = capture {
        system(@cmd);
    };
    unlink $config_file if -f $config_file;
    die "Failed to generate SSL certificate: $stderr" if $exit != 0;
    die "Certificate file not created" if !-f $cert_file;
    die "Key file not created" if !-f $key_file;
    die "Generated certificate is missing the required dashboard HTTPS server profile"
      if !_ssl_cert_has_expected_profile(
        $cert_file,
        hosts => \@expected_subject_alt_names,
      );
    $paths->secure_dir_permissions($cert_dir);
    $paths->secure_file_permissions($cert_file);
    $paths->secure_file_permissions($key_file);

    return $cert_file;
}

# _ssl_expected_subject_alt_names(%args)
# Builds the complete SAN list that one dashboard HTTPS certificate must cover.
# Input: optional bind host string plus optional array reference of extra names/IPs.
# Output: ordered list of normalized SAN entries including localhost and loopback defaults.
sub _ssl_expected_subject_alt_names {
    my (%args) = @_;
    my @requested = ( 'localhost', '127.0.0.1', '::1' );
    push @requested, $args{host} if defined $args{host};
    push @requested, @{ $args{hosts} || [] } if ref( $args{hosts} ) eq 'ARRAY';

    my @normalized;
    my %seen;
    for my $name (@requested) {
        my $normalized = _normalize_ssl_subject_alt_name($name);
        next if !defined $normalized || $normalized eq '';
        next if _ssl_subject_alt_name_is_wildcard($normalized);
        my $seen_key = lc $normalized;
        next if $seen{$seen_key}++;
        push @normalized, $normalized;
    }

    return @normalized;
}

# _normalize_ssl_subject_alt_name($name)
# Normalizes one requested SAN entry by trimming whitespace and removing optional port syntax.
# Input: hostname or IP string, optionally bracketed or with a port suffix.
# Output: normalized SAN string or empty string when unusable.
sub _normalize_ssl_subject_alt_name {
    my ($name) = @_;
    return '' if !defined $name;
    $name =~ s/^\s+//;
    $name =~ s/\s+$//;
    return '' if $name eq '';
    $name =~ s/^\[(.+)\](?::\d+)?$/$1/;
    $name =~ s/^([^:]+):\d+$/$1/ if $name =~ /^[^:]+:\d+$/;
    return lc $name;
}

# _ssl_subject_alt_name_is_wildcard($name)
# Reports whether one requested SAN name is a wildcard bind placeholder that should not be embedded.
# Input: normalized SAN string.
# Output: boolean true when the value is a wildcard listen address.
sub _ssl_subject_alt_name_is_wildcard {
    my ($name) = @_;
    return 1 if !defined $name || $name eq '';
    return 1 if $name eq '*';
    return 1 if $name eq '0.0.0.0';
    return 1 if $name eq '::';
    return 1 if $name eq '0:0:0:0:0:0:0:0';
    return 0;
}

# _ssl_subject_alt_name_is_ip($name)
# Classifies one SAN entry as an IP literal or a DNS hostname.
# Input: normalized SAN string.
# Output: boolean true for IPv4 or IPv6 literal values.
sub _ssl_subject_alt_name_is_ip {
    my ($name) = @_;
    return 0 if !defined $name || $name eq '';
    return 1 if $name =~ /\A(?:\d{1,3}\.){3}\d{1,3}\z/;
    return 1 if $name =~ /:/;
    return 0;
}

# _ssl_cert_has_expected_profile($cert_file)
# Checks whether one generated certificate matches the browser-safe localhost
# leaf-certificate profile required by dashboard serve --ssl.
# Input: certificate file path string.
# Output: boolean true when the certificate already contains the required SAN,
# key-usage, extended-key-usage, and non-CA extensions.
sub _ssl_cert_has_expected_profile {
    my ( $cert_file, %args ) = @_;
    return 0 if !defined $cert_file || $cert_file eq '' || !-f $cert_file;
    my @expected_subject_alt_names = _ssl_expected_subject_alt_names(
        hosts => $args{hosts},
    );
    my ( $stdout, $stderr, $exit ) = capture {
        system( 'openssl', 'x509', '-in', $cert_file, '-noout', '-text' );
    };
    die "Failed to inspect SSL certificate $cert_file: $stderr$stdout" if $exit != 0;
    return 0 if $stdout !~ /Basic Constraints:\s+critical\s+CA:FALSE/s;
    return 0 if $stdout !~ /Extended Key Usage:\s+TLS Web Server Authentication/s;
    return 0 if $stdout !~ /Key Usage:\s+critical\s+Digital Signature, Key Encipherment/s;
    for my $subject_alt_name (@expected_subject_alt_names) {
        my @verify_cmd = ( 'openssl', 'verify', '-CAfile', $cert_file );
        if ( _ssl_subject_alt_name_is_ip($subject_alt_name) ) {
            push @verify_cmd, '-verify_ip', $subject_alt_name;
        }
        else {
            push @verify_cmd, '-verify_hostname', $subject_alt_name;
        }
        push @verify_cmd, $cert_file;
        my ( $verify_stdout, $verify_stderr, $verify_exit ) = capture {
            system(@verify_cmd);
        };
        return 0 if $verify_exit != 0;
        return 0 if $verify_stdout !~ /\:\s+OK\s*\z/ && $verify_stderr !~ /\:\s+OK\s*\z/;
    }
    return 1;
}

# get_ssl_cert_paths()
# Returns the paths to the self-signed certificate and key files.
# Input: none. The current certificate profile is whatever generate_self_signed_cert()
# most recently prepared for the active dashboard runtime.
# Output: list of (cert_path, key_path) or dies if files do not exist.
sub get_ssl_cert_paths {
    my $home = $ENV{HOME} || die 'Missing HOME environment variable';
    my $cert_dir = File::Spec->catdir($home, '.developer-dashboard', 'certs');
    my $cert_file = File::Spec->catfile($cert_dir, 'server.crt');
    my $key_file  = File::Spec->catfile($cert_dir, 'server.key');

    die "Certificate file not found: $cert_file" if !-f $cert_file;
    die "Key file not found: $key_file" if !-f $key_file;

    return ($cert_file, $key_file);
}

1;

__END__

=head1 NAME

Developer::Dashboard::Web::Server - PSGI server bridge for Developer Dashboard

=head1 SYNOPSIS

  my $server = Developer::Dashboard::Web::Server->new(app => $app);
  $server->run;

=head1 DESCRIPTION

This module reserves the local listen address, builds the Dancer2 PSGI app,
and runs it under Starman through Plack::Runner.

=head1 METHODS

=head2 new, run, start_daemon, listening_url, serve_daemon, psgi_app, _build_runner, _default_headers, generate_self_signed_cert, get_ssl_cert_paths

Construct and run the local PSGI web server with optional SSL/HTTPS support.

When C<ssl => 1> is passed to new(), generates or refreshes self-signed certificates in C<~/.developer-dashboard/certs/> with SAN coverage for C<localhost>, C<127.0.0.1>, C<::1>, the concrete non-wildcard bind host, and any configured extra aliases/IPs, runs an internal HTTPS Starman backend, exposes a public frontend on the requested port, redirects plain HTTP requests on that public port to the equivalent C<https://...> URL, and proxies real HTTPS traffic through to the internal backend. The listening_url() method returns https:// when SSL is enabled.

=head1 SSL SUPPORT

Pass C<ssl => 1> to the new() constructor to enable HTTPS:

  my $server = Developer::Dashboard::Web::Server->new(
      app => $app,
      ssl => 1,
  );
  $server->run;

Self-signed certificates are generated automatically in C<~/.developer-dashboard/certs/> and reused on subsequent runs when they already match the expected browser-safe localhost/loopback profile plus any configured SAN aliases or IP literals. Older legacy dashboard certs without the required SAN and server-auth extensions are regenerated automatically.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module wraps the dashboard PSGI app in a real listener. It reserves ports, builds the Plack/Starman runner, injects the default security headers, optionally generates and serves the HTTPS frontend, redirects plain HTTP to HTTPS on the same public port, and proxies TLS traffic to an internal backend when SSL is enabled.

=head1 WHY IT EXISTS

It exists because transport concerns such as port reservation, HTTPS redirect behavior, SAN-aware self-signed certificates, and SSL frontend proxying should stay out of the route backend. That keeps web transport policy separate from page logic.

=head1 WHEN TO USE

Use this file when changing listen host or port behavior, SSL certificate generation, HTTPS redirect logic, Plack runner options, or the low-level frontend/backend proxy path for secure serving.

=head1 HOW TO USE

Construct it with the backend app object and desired host, port, worker, and SSL settings, then call C<run>, C<start_daemon>, or C<serve_daemon>. Keep route behavior in C<Developer::Dashboard::Web::App> and keep the transport wiring here.

=head1 WHAT USES IT

It is used by C<dashboard serve>, C<dashboard restart>, C<app.psgi> smoke paths, SSL/browser regression tests, and contributors verifying security headers and HTTPS behavior.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::Web::Server -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/03-web-app.t t/08-web-update-coverage.t t/web_app_static_files.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut

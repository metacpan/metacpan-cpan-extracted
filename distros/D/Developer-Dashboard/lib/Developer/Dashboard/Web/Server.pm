package Developer::Dashboard::Web::Server;

use strict;
use warnings;

our $VERSION = '4.26';

use Capture::Tiny qw(capture);
use Errno qw(EINTR);
use File::Spec;
use File::Temp qw(tempfile);
use IO::Select;
use IO::Socket::INET;
use Plack::Runner;
use Socket qw(MSG_PEEK);

use Developer::Dashboard::Platform qw(is_windows);
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Web::DancerApp;
use Developer::Dashboard::Web::Server::Daemon;

our $SSL_BACKEND_PID;
our $SSL_SHUTDOWN_REQUESTED;
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
    die 'Missing worker count' if !defined $workers || $workers eq '';    # uncoverable condition left
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
        return $self->_ssl_redirect_response($env) if !_request_is_https($env);
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
    my $server_name = is_windows() ? 'Standalone' : 'Starman';
    my @options = (
        '--server', $server_name,
        '--host',   $listen_host,
        '--port',   $listen_port,
        '--env',    'deployment',
    );

    push @options, '--workers', $self->{workers} if !is_windows();

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
        my $exit_code = $self->_run_ssl_backend_process($daemon);
        exit $exit_code; # uncoverable statement
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
    local $SSL_SHUTDOWN_REQUESTED = 0;
    my %reaped_children;
    local $SIG{CHLD} = sub {
        _reap_ssl_children( \%reaped_children );
        return;
    };

    my $listener = $self->_open_ssl_frontend_listener_or_die(
        daemon          => $daemon,
        backend_pid     => $backend_pid,
        reaped_children => \%reaped_children,
    );

    while (1) {
        last if $SSL_SHUTDOWN_REQUESTED;
        my $client = $listener->accept;
        if ( !defined $client ) {
            next if $! == EINTR && !$SSL_SHUTDOWN_REQUESTED;
            last;
        }
        my $pid = fork();
        die "Unable to fork SSL frontend connection handler: $!" if !defined $pid;
        if ($pid) {
            close $client;
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
    _stop_ssl_backend( $backend_pid, \%reaped_children );
    _wait_for_managed_child( $backend_pid, \%reaped_children );
    return 1;
}

# _run_ssl_backend_process($daemon)
# Runs the internal SSL PSGI backend inside the forked child process and
# returns its exit code to the immediate caller.
# Input: daemon descriptor object.
# Output: numeric process exit code.
sub _run_ssl_backend_process {
    my ( $self, $daemon ) = @_;
    # Mark this process as the internal backend behind the SSL front-proxy so
    # authorize_request never auto-grants loopback admin (every connection here
    # arrives from the proxy's loopback socket). Starman workers fork from here
    # and inherit the flag.
    local $ENV{DEVELOPER_DASHBOARD_SSL_PROXIED} = 1;
    my $runner = $self->_build_runner($daemon);
    my $app = $self->psgi_app;
    $runner->run($app);
    return 0;
}

# _open_ssl_frontend_listener_or_die(%args)
# Opens the public SSL frontend listener or stops the backend child and dies
# with an explicit bind error when the public socket cannot be reserved.
# Input: daemon descriptor, backend pid integer, and reaped-child hash ref.
# Output: bound listener socket handle.
sub _open_ssl_frontend_listener_or_die {
    my ( $self, %args ) = @_;
    my $daemon          = $args{daemon}          || die 'Missing SSL frontend daemon descriptor';
    my $backend_pid     = $args{backend_pid};
    my $reaped_children = $args{reaped_children};
    my $listener = IO::Socket::INET->new(
        LocalAddr => $daemon->sockhost,
        LocalPort => $daemon->sockport,
        Proto     => 'tcp',
        ReuseAddr => 1,
        Listen    => 128,
    );
    return $listener if $listener;
    _stop_ssl_backend( $backend_pid, $reaped_children );
    die "Unable to bind SSL frontend on $self->{host}:$self->{port}: $!";
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
    return 1 if !defined $peeked || $first eq '';

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
        host   => $self->_request_host_from_head( $request, $daemon ),
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
# Extracts the requested path and query from one plain HTTP request head and
# reduces it to a target that is safe to append to the redirect authority.
# Input: raw request-head string.
# Output: path/query target string, defaulting to /.
sub _request_target_from_head {
    my ($head) = @_;
    return '/' if !defined $head || $head eq '';
    return _safe_redirect_target($1) if $head =~ m{\A[A-Z]+\s+(\S+)\s+HTTP/}s;
    return '/';
}

# _request_host_from_head($head, $daemon)
# Extracts or reconstructs the public host:port for one redirecting plain HTTP
# request. This is the authority a real plain-HTTP client sees in the Location
# header of the public SSL port, so the client-supplied Host header is only
# reused when it passes the same allowlist the PSGI redirect applies; otherwise
# the bound listener address is used.
# Input: raw request-head string and daemon descriptor.
# Output: host[:port] string.
sub _request_host_from_head {
    my ( $self, $head, $daemon ) = @_;
    if ( defined $head && $head =~ /^Host:[ \t]*([^\r\n]*)/im ) {
        my $requested = $1;
        $requested =~ s/[ \t]+\z//;
        my $allowed = $self->_allowlisted_redirect_authority($requested);
        return $allowed if $allowed ne '';
    }
    my $host = $daemon->sockhost || '127.0.0.1';
    my $port = $daemon->sockport || 443;
    return _redirect_authority( $host, $port == 443 ? undef : $port );
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

# _stop_ssl_backend($pid, $reaped_children)
# Terminates the internal SSL backend process used by the public SSL frontend.
# Input: backend pid integer and optional hash reference of already reaped
# child pids.
# Output: true value.
sub _stop_ssl_backend {
    my ( $pid, $reaped_children ) = @_;
    return 1 if !$pid;
    kill 15, $pid;
    _wait_for_managed_child( $pid, $reaped_children );
    return 1;
}

# _wait_for_managed_child($pid, $reaped_children)
# Waits for one managed child process unless a local SIGCHLD handler has
# already reaped it.
# Input: child pid integer and optional hash reference of already reaped pids.
# Output: true value.
sub _wait_for_managed_child {
    my ( $pid, $reaped_children ) = @_;
    return 1 if !$pid;
    return 1 if ref($reaped_children) eq 'HASH' && $reaped_children->{$pid};
    my $waited = _waitpid( $pid, 0 );
    return 1 if $waited == $pid || $waited == -1;
    return 1;
}

# _waitpid($pid, $flags)
# Wraps Perl waitpid so tests can force one child-wait return path directly.
# Input: pid integer and wait flags integer.
# Output: waitpid return integer.
sub _waitpid {
    my ( $pid, $flags ) = @_;
    return waitpid( $pid, $flags );
}

# _track_reaped_child($reaped_children, $pid)
# Records one locally reaped child pid so later shutdown waits can skip
# already-collected children.
# Input: hash reference used as the local reap set and one positive process id.
# Output: true value.
sub _track_reaped_child {
    my ( $reaped_children, $pid ) = @_;
    return 1 if ref($reaped_children) ne 'HASH';
    return 1 if !defined $pid || $pid <= 0;
    $reaped_children->{$pid} = 1;
    return 1;
}

# _reap_ssl_children($reaped_children)
# Reaps any exited SSL frontend/backend children and records them in the local
# reap set used by shutdown helpers.
# Input: hash reference used as the local reap set.
# Output: true value.
sub _reap_ssl_children {
    my ($reaped_children) = @_;
    while (1) {
        my $reaped = _waitpid( -1, 1 );
        last if $reaped <= 0;
        _track_reaped_child( $reaped_children, $reaped );
    }
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
    $SSL_SHUTDOWN_REQUESTED = 1;
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
    kill 15, $$;
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
    my ( $self, $env ) = @_;
    my $location = $self->_https_redirect_location($env);
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
# redirects. The client-supplied Host header is only reused when it names an
# authority this server can actually answer for; anything else falls back to
# the server-derived SERVER_NAME/SERVER_PORT authority.
# Input: PSGI environment hash reference.
# Output: absolute HTTPS URL string.
sub _https_redirect_location {
    my ( $self, $env ) = @_;
    my $host = $self->_allowlisted_redirect_authority( $env->{HTTP_HOST} );
    if ( $host eq '' ) {
        my $server_name = defined $env->{SERVER_NAME} ? $env->{SERVER_NAME} : '127.0.0.1';
        my $server_port = defined $env->{SERVER_PORT} ? $env->{SERVER_PORT} : 443;
        my $fallback_port =
          $server_port ne '' && $server_port !~ /^443$/ ? $server_port : undef;
        $host = _redirect_authority( _split_request_authority( $server_name, $fallback_port ) );
        $host = '127.0.0.1' if $host eq '';
    }
    my $path = defined $env->{SCRIPT_NAME} ? $env->{SCRIPT_NAME} : '';
    $path .= defined $env->{PATH_INFO} ? $env->{PATH_INFO} : '/';
    my $query = defined $env->{QUERY_STRING} ? $env->{QUERY_STRING} : '';
    my $target = _safe_redirect_target( $path . ( $query ne '' ? '?' . $query : '' ) );
    return 'https://' . $host . $target;
}

# _allowlisted_redirect_authority($authority)
# Validates one client-supplied authority before it may appear in a Location
# header. Echoing a raw Host header back turns the plain-HTTP listener into an
# open redirect: the server binds 0.0.0.0 by default, so any remote client can
# name its own authority and have the dashboard launder a redirect to it. The
# allowlist is the same trust set the rest of the app already uses - loopback
# literals plus the names this server's own certificate covers, which is every
# authority it can legitimately serve HTTPS for.
# Input: raw Host header string or undef.
# Output: normalized authority string, or empty string when it is not allowed.
sub _allowlisted_redirect_authority {
    my ( $self, $authority ) = @_;
    my ( $host, $port ) = _split_request_authority($authority);
    return '' if !defined $host;
    return '' if !$self->_redirect_host_is_allowed($host);
    return _redirect_authority( $host, $port );
}

# _redirect_host_is_allowed($host)
# Reports whether one already-parsed host may be named in a redirect Location.
# Input: normalized lowercase host string without port.
# Output: boolean true when the host is loopback or a covered certificate name.
sub _redirect_host_is_allowed {
    my ( $self, $host ) = @_;
    return 1 if _host_is_loopback_literal($host);
    my %allowed = map { $_ => 1 } _ssl_expected_subject_alt_names(
        host  => $self->{host},
        hosts => $self->{ssl_subject_alt_names},
    );
    return $allowed{$host} ? 1 : 0;
}

# _host_is_loopback_literal($host)
# Reports whether one host is a loopback IP literal. A loopback authority can
# never point at an attacker-controlled origin, so it stays acceptable in a
# redirect even when the certificate only covers 127.0.0.1. This mirrors the
# loopback rule in Developer::Dashboard::Auth on purpose - the whole 127.0.0.0/8
# range with strict 0-255 octets, plus both spellings of the IPv6 loopback - and
# the two must stay in step.
# Input: normalized lowercase host string.
# Output: boolean true for loopback literals only.
sub _host_is_loopback_literal {
    my ($host) = @_;
    return 0 if !defined $host || $host eq '';
    return 1 if $host =~ /\A127(?:\.(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])){3}\z/;
    return 1 if $host eq '::1' || $host eq '0:0:0:0:0:0:0:1';
    return 0;
}

# _split_request_authority($authority, $port)
# Parses one authority into its host and port parts, rejecting anything that is
# not a syntactically valid HTTP authority. Parsing rather than pattern-matching
# is deliberate: the caller rebuilds the authority from these parts, so no byte
# of the original string can survive into a header.
# Input: raw authority string (host with optional port) and an optional port
# override used when the caller already holds the port separately.
# Output: (host, port) list with a lowercase host and an undefined port when
# absent, or an empty list when the authority is not usable.
sub _split_request_authority {
    my ( $authority, $port_override ) = @_;
    return () if !defined $authority || $authority eq '';
    return () if length($authority) > 255;
    my ( $host, $port );
    if ( $authority =~ /\A\[([0-9A-Fa-f:.]{2,45})\](?::(\d{1,5}))?\z/ ) {
        ( $host, $port ) = ( $1, $2 );
    }
    elsif ( $authority =~ /\A([A-Za-z0-9](?:[A-Za-z0-9._-]*[A-Za-z0-9])?)(?::(\d{1,5}))?\z/ ) {
        ( $host, $port ) = ( $1, $2 );
    }
    else {
        return ();
    }
    $port = $port_override if defined $port_override;
    if ( defined $port ) {
        return () if $port !~ /\A\d{1,5}\z/;
        return () if $port < 1 || $port > 65535;
    }
    return ( lc $host, $port );
}

# _redirect_authority($host, $port)
# Rebuilds one authority string from validated parts, bracketing IPv6 literals
# so the result is always a parseable URL authority.
# Input: normalized host string (or empty list) and optional port.
# Output: authority string, or empty string when no host was supplied.
sub _redirect_authority {
    my ( $host, $port ) = @_;
    return '' if !defined $host || $host eq '';
    my $literal = $host =~ /:/ ? '[' . $host . ']' : $host;
    return defined $port ? $literal . ':' . $port : $literal;
}

# _safe_redirect_target($target)
# Reduces one request target to a form that cannot move the authority of the
# URL it is appended to. The target is concatenated straight after the
# authority, so an authority-form target such as "@evil.com/" would demote the
# real host to userinfo and hand the redirect to the attacker. Only an
# origin-form path is safe, and - matching the login redirect sanitizer - a
# backslash or raw ASCII control byte is rejected too, because URL parsers fold
# or strip those before parsing. A legitimate target percent-encodes them.
# Input: raw request target string (path plus optional query).
# Output: the target when it is safe, otherwise '/'.
sub _safe_redirect_target {
    my ($target) = @_;
    return '/' if !defined $target || $target eq '';
    return '/' if $target !~ m{\A/};
    return '/' if $target =~ m{\A//};
    return '/' if $target =~ m{\\};
    return '/' if $target =~ m{[\x00-\x1f\x7f]};
    return $target;
}

# _ssl_certificate_directory()
# Resolves the home-layer certificate directory for the current user. The home
# directory itself is resolved by the path registry, which understands HOME,
# then USERPROFILE, then HOMEDRIVE plus HOMEPATH. Reading $ENV{HOME} directly
# here would refuse to serve HTTPS on Windows, which does not export HOME at
# all, before the server ever reached a listening socket.
# Input: none.
# Output: list of (path registry object, certificate directory path string); dies
# when no home directory is resolvable from the environment.
sub _ssl_certificate_directory {
    my $paths = Developer::Dashboard::PathRegistry->new;
    return ( $paths, File::Spec->catdir( $paths->home_runtime_path, 'certs' ) );
}

# generate_self_signed_cert(%args)
# Generates or reuses a self-signed certificate for HTTPS.
# Creates the certs/ directory in the home runtime layer if it does not exist.
# Reuses existing certificates when they already match the expected browser-safe
# localhost/loopback profile plus any requested extra SAN names/IPs, and
# regenerates older legacy certificates when they do not.
# Input: optional bind host string and optional hosts array reference.
# Output: path to certificate file, or dies on error.
sub generate_self_signed_cert {
    my (%args) = @_;
    my ( $paths, $cert_dir ) = _ssl_certificate_directory();
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
    push @requested, @{ $args{hosts} } if ref( $args{hosts} ) eq 'ARRAY';

    my @normalized;
    my %seen;
    for my $name (@requested) {
        my $normalized = _normalize_ssl_subject_alt_name($name);
        next if !defined $normalized || $normalized eq '';    # uncoverable condition left
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
    my ( undef, $cert_dir ) = _ssl_certificate_directory();
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

=head2 new, run, start_daemon, listening_url, serve_daemon, psgi_app, _build_runner, _default_headers, _ssl_certificate_directory, generate_self_signed_cert, get_ssl_cert_paths

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

Both C<generate_self_signed_cert> and C<get_ssl_cert_paths> locate that directory through C<_ssl_certificate_directory>, which asks C<Developer::Dashboard::PathRegistry> for the home runtime layer. The registry resolves the home directory from C<HOME>, then C<USERPROFILE>, then C<HOMEDRIVE> plus C<HOMEPATH>, so HTTPS also starts on a Windows session, which does not export C<HOME> at all. Only an environment that names no home directory by any of those variables is an error, and it is reported as a missing home directory rather than as a missing single variable.

=head1 HTTPS REDIRECT TRUST BOUNDARY

The public listener binds C<0.0.0.0> by default, so the plain-HTTP redirect it
serves on the SSL port is reachable from the network and its C<Location> header
must never be built from client-controlled input. Two values reach that header
and both are validated:

=over 4

=item *

The B<authority> comes from the request C<Host> header only when that header
parses as a valid host with an optional in-range port B<and> names an authority
this server can legitimately answer for: a loopback IP literal, or one of the
names its own certificate covers (C<localhost>, C<127.0.0.1>, C<::1>, the
concrete non-wildcard bind host, and every entry in
C<web.ssl_subject_alt_names>). Anything else is discarded and the redirect uses
the server-derived listen authority instead. The accepted authority is rebuilt
from the parsed parts, so no byte of the original header survives into the
header value.

=item *

The B<target> is only reused when it is an origin-form path. A target is
concatenated directly after the authority, so an authority-form target such as
C<@evil.com/> would demote the real host to userinfo and hand the redirect to
the attacker; a backslash or raw ASCII control byte is rejected for the same
reason the login redirect sanitizer rejects them, because URL parsers fold or
strip those bytes before parsing. Anything unsafe collapses to C</>.

=back

Both the PSGI-level redirect used by C<psgi_app> and the socket-level redirect
served by the SSL front-proxy apply the same rules.

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

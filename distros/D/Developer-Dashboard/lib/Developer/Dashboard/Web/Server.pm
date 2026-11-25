package Developer::Dashboard::Web::Server;

use strict;
use warnings;

our $VERSION = '6.31';

use Capture::Tiny qw(capture);
use Errno qw(EAGAIN EINTR EWOULDBLOCK);
use File::Basename qw(dirname);
use File::Spec;
use File::Temp qw(tempfile);
use IO::Select;
use IO::Socket::INET;
use IO::Socket::SSL ();
use Plack::Runner;
use Socket qw(MSG_PEEK SO_TYPE SOL_SOCKET);
use Time::HiRes qw(sleep time);

use Developer::Dashboard::GoRoutine;
use Developer::Dashboard::Platform qw(is_windows);
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::ProcessSupervision ();
use Developer::Dashboard::Web::DancerApp;
use Developer::Dashboard::Web::Server::Daemon;

our $SSL_BACKEND_PID;
our %SSL_BACKEND_REAPED;
our $SSL_SHUTDOWN_REQUESTED;
our %SSL_PREVIOUS_SIGNAL;

# new(%args)
# Constructs the local PSGI web server wrapper.
# Input: app object, optional path registry, host, port, worker count, and ssl flag.
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
    die 'Missing worker count' if $workers eq '';
    die 'Worker count must be a positive integer' if $workers !~ /^\d+$/ || $workers < 1;

    if ($ssl) {
        generate_self_signed_cert(
            host          => $host,
            hosts         => $ssl_subject_alt_names,
            validity_days => $args{ssl_validity_days},
        );
    }

    return bless {
        app                   => $app,
        paths                 => $args{paths},
        host                  => $host,
        port                  => $port,
        workers               => $workers + 0,
        ssl                   => $ssl,
        ssl_backend_command_builder => $args{ssl_backend_command_builder},
        ssl_subject_alt_names => $ssl_subject_alt_names,
    }, $class;
}

# run()
# Starts the PSGI daemon wrapper and serves requests until the runner exits.
# Input: none.
# Output: true value when the server loop completes.
sub run {
    my ($self) = @_;

    _start_lifetime_owner_watcher();
    my $daemon = $self->start_daemon;
    print "Developer Dashboard listening on ", $self->listening_url($daemon), "\n";
    return $self->serve_daemon($daemon);
}

# _web_lifetime_owner_watcher_log_path($web_pid)
# Path of the log file the lifetime-owner watcher for one web process
# writes its stop line to when it ends that web process because its
# lifetime owner is gone. One file per web pid, under the logs root, so
# a later reader can find the line for a web process it started without
# knowing anything else about it. The file is only ever created by the
# watcher writing its stop line; nothing reads it in normal use.
# Input: web process id integer.
# Output: log file path string, or undef for a malformed web pid.
sub _web_lifetime_owner_watcher_log_path {
    my ($web_pid) = @_;
    return if !defined $web_pid || $web_pid !~ /\A\d+\z/ || $web_pid < 1;
    my $paths = Developer::Dashboard::PathRegistry->new;
    return File::Spec->catfile( $paths->logs_root, "web-lifetime-owner-watcher-$web_pid.log" );
}

# _start_lifetime_owner_watcher()
# Starts a separate watcher process that ends this web process once the
# opted-in lifetime owner is dead. A starter opts in by exporting
# DEVELOPER_DASHBOARD_LIFETIME_PID (see _lifetime_owner_pid in
# Developer::Dashboard::ProcessSupervision, the one reader of that
# variable); an ordinary user never sets it, so no watcher is started
# and nothing changes. The web process cannot watch the owner itself:
# once the PSGI server is running, the main loop belongs to that server
# and none of this code gets a turn. The watcher is started before the
# listen socket exists, so it never holds the port, and with its
# standard streams on the null device, so it never holds a test
# harness pipe open. It ends by itself as soon as this web process is
# gone, however that happened. The watcher is told the path of its log
# file, so it has somewhere to write what it did once the owner is
# gone; a watcher that cannot work out its log path still starts, it
# just keeps no log. This web process writes the first line of that
# log itself: that a watcher was started, with its pid, or that it
# could not be started and why. A spawn that dies is caught and logged
# the same way, and never stops the web process starting.
# Input: none.
# Output: watcher pid integer, or 0 when the starter did not opt in or
# the watcher could not be started.
sub _start_lifetime_owner_watcher {
    return 0 if !defined Developer::Dashboard::ProcessSupervision::_lifetime_owner_pid();
    my $log_path = eval { _web_lifetime_owner_watcher_log_path($$) };
    my @watcher_args = ($$);
    push @watcher_args, $log_path if defined $log_path;
    my $watcher_program = <<'WATCHER_PERL';
use strict;
use warnings;
use Developer::Dashboard::RuntimeManager ();
exit Developer::Dashboard::RuntimeManager->_run_web_lifetime_owner_watcher(@ARGV);
WATCHER_PERL
    my @library_args = map { ( '-I', $_ ) } grep { defined && !ref && -d $_ } @INC;
    my $null = File::Spec->devnull();
    my $owner_pid   = Developer::Dashboard::ProcessSupervision::_lifetime_owner_pid();
    my $watcher_pid = eval {
        Developer::Dashboard::GoRoutine::spawn(
            [ $^X, @library_args, '-e', $watcher_program, @watcher_args ],
            { stdin => $null, stdout => $null, stderr => $null },
        );
    };
    my $error = $@;
    if ($watcher_pid) {
        _log_lifetime_owner_watcher_start( $log_path,
            "watcher started: watcher pid $watcher_pid was started by web pid $$ for lifetime owner pid $owner_pid" );
        return $watcher_pid;
    }
    $error = 'the spawn returned no pid' if !defined $error || !length $error;
    _log_lifetime_owner_watcher_start( $log_path,
        "watcher not started: web pid $$ could not start its watcher for lifetime owner pid $owner_pid: $error" );
    return 0;
}

# _log_lifetime_owner_watcher_start($log_path, $text)
# Appends one time-stamped line to the watcher log from the web process
# side, saying that a watcher was started or could not be. The watcher
# runs with its standard streams on the null device, so without this
# line a watcher that never started, or died while loading, would leave
# nothing behind: with it, a started line with no watching line after it
# from the watcher itself means the watcher died early. A failed write
# is silent and never stops the web process starting.
# Input: log file path string (undef means no log is kept) and the line
# text without its time stamp or line ending.
# Output: 1 when the line was written, otherwise undef.
sub _log_lifetime_owner_watcher_start {
    my ( $log_path, $text ) = @_;
    return if !defined $log_path || !length $log_path;
    return if !defined $text     || !length $text;
    $text =~ s/\s+/ /g;
    $text =~ s/\A | \z//g;
    my @now = gmtime;
    my $stamp = sprintf '%04d-%02d-%02dT%02d:%02d:%02dZ', $now[5] + 1900, $now[4] + 1, @now[ 3, 2, 1, 0 ];
    open my $fh, '>>', $log_path or return;
    print {$fh} "$stamp $text\n";
    close $fh;
    return 1;
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
        paths           => $self->{paths},
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
        if ( is_windows() ) {
            # Standalone (HTTP::Server::PSGI) reads ssl_key_file/ssl_cert_file.
            # The Starman-style --ssl-key/--ssl-cert names are silently dropped,
            # leaving the backend with no certificate, so every TLS handshake
            # fails with a fatal handshake_failure alert and the readiness
            # probe times out. (t/17 Test 15, Windows only.)
            push @options, '--ssl-key-file',  $key;
            push @options, '--ssl-cert-file', $cert;
        }
        else {
            push @options, '--ssl-key',  $key;
            push @options, '--ssl-cert', $cert;
        }
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
    my $backend_command = $self->_ssl_backend_command($daemon);
    my $backend_pid = Developer::Dashboard::GoRoutine::spawn(
        $backend_command,
        { process_group => 1 },
    );
    _start_ssl_backend_watchdog($backend_pid);

    my $previous_term = $SIG{TERM};
    my $previous_int  = $SIG{INT};
    my $previous_hup  = $SIG{HUP};
    local $SSL_BACKEND_PID = $backend_pid;
    local %SSL_BACKEND_REAPED;
    local %SSL_PREVIOUS_SIGNAL = (
        TERM => $previous_term,
        INT  => $previous_int,
        HUP  => $previous_hup,
    );
    local $SIG{TERM} = \&_ssl_term_handler;
    local $SIG{INT}  = \&_ssl_int_handler;
    local $SIG{HUP}  = \&_ssl_hup_handler;
    local $SSL_SHUTDOWN_REQUESTED = 0;
    $self->_wait_for_ssl_backend_ready( $daemon, $backend_pid );
    my %reaped_children;
    my $listener = $self->_open_ssl_frontend_listener_or_die(
        daemon          => $daemon,
        backend_pid     => $backend_pid,
        reaped_children => \%reaped_children,
    );

    # Plain values now: one interpreter, no cross-interpreter sharing.
    # Each accepted client is owned by one repeating-timer routine that
    # steps its state machine; the routine closes the socket when done.
    # The parent never closes a client handle: there is only one handle
    # now, and closing it here would close the routine's socket too.
    my @client_states;
    my @client_errors;
    my $frontend_close_error;
    my $worker_server = bless {
        host                  => $self->{host},
        ssl_subject_alt_names => [ @{ $self->{ssl_subject_alt_names} || [] } ],
    }, ref($self);
    my $listener_select = IO::Select->new($listener);

    # select() only works on sockets on Windows: on a plain filehandle
    # can_read() never reports readable, so the accept below would never
    # run and the loop would spin forever in pump(). Probe with
    # getsockopt first; a non-socket skips the readiness wait and goes
    # straight to accept, which fails and exits the loop (t/17
    # devnull-listener case, same class as the t/88 client hang fixed
    # in 1c1034de). A real socket waits exactly as before.
    my $listener_is_socket = defined getsockopt( $listener, SOL_SOCKET, SO_TYPE );

    # Pump the engine (drives the client routines) and accept any pending
    # client without blocking. The accept never blocks on a real socket:
    # can_read(0) proves a connection is waiting before accept is called.
    # A non-socket listener has no readiness to prove, so accept is called
    # directly and its failure exits the loop.
    FRONTEND: while ( !$SSL_SHUTDOWN_REQUESTED ) {
        Developer::Dashboard::GoRoutine::pump(0.05);
        while ( !$listener_is_socket || $listener_select->can_read(0) ) {
            my $client = $listener->accept;
            if ( !defined $client ) {
                next if $! == EINTR && !$SSL_SHUTDOWN_REQUESTED;
                last FRONTEND;
            }
            push @client_states, _start_ssl_frontend_client(
                $worker_server, $daemon, $client, \@client_errors,
            );
        }
    }

    # Cancel every client routine that is still waiting and finish the
    # client the same way its own last step would: cancel the routine,
    # close its sockets, mark it done. No routine is running here: pump
    # only returns after the routines it dispatched have returned, so the
    # pending ones are idle and safe to cancel. There is nothing to poll
    # for: a killed routine never fires again, so no is_running wait is
    # needed. Clients are finished before the listener is closed, so a
    # client close failure is reported before any listener close failure,
    # as the old handler did.
    for my $state (@client_states) {
        _ssl_frontend_client_finish($state);
    }

    if ( !$self->_close_ssl_frontend_handle($listener) ) {
        if ( !defined $frontend_close_error ) {
            $frontend_close_error = "Unable to close SSL frontend listener: $!";
        }
    }
    my @routine_errors = @client_errors;
    _stop_ssl_backend( $backend_pid, \%reaped_children );
    die "SSL frontend client handler failed: $routine_errors[0]" if @routine_errors;
    die $frontend_close_error if defined $frontend_close_error;
    return 1;
}

# _close_ssl_frontend_handle($handle)
# Closes one SSL frontend socket handle and returns the close result unchanged.
# Input: open socket or filehandle reference owned by the SSL frontend.
# Output: true when closed successfully, false when Perl reports a close error.
sub _close_ssl_frontend_handle {
    my ( $self, $handle ) = @_;
    return close $handle;
}

# _wait_for_ssl_backend_ready($daemon, $pid)
# Waits until the isolated SSL backend completes a loopback TLS handshake or reports
# a startup failure, preventing public requests from racing backend startup.
# Input: daemon descriptor and GoRoutine-managed backend process identifier.
# Output: true when the backend listener accepts a connection; dies on failure.
sub _wait_for_ssl_backend_ready {
    my ( $self, $daemon, $pid ) = @_;
    my $deadline = time() + 45;
    while ( time() < $deadline ) {
        if ( Developer::Dashboard::GoRoutine::process_exited($pid) ) {
            my $status = Developer::Dashboard::GoRoutine::wait_process($pid);
            $SSL_BACKEND_REAPED{$pid} = 1;
            die "SSL backend exited before becoming ready (status $status)";
        }
        my $backend = IO::Socket::SSL->new(
            PeerAddr => $daemon->internal_sockhost,
            PeerPort => $daemon->internal_sockport,
            Proto    => 'tcp',
            SSL_verify_mode => 0,
            SSL_hostname    => 'localhost',
            Timeout         => 1,
        );
        if ($backend) {
            close $backend or die "Unable to close SSL backend readiness probe: $!";
            return 1;
        }
        sleep 0.05;
    }
    _stop_ssl_backend($pid);
    die 'Timed out waiting for SSL backend listener readiness';
}

# _ssl_backend_command($daemon)
# Builds the staged-core command that runs the isolated SSL Starman backend,
# resolving the core dispatcher beside the current helper wrapper.
# Input: daemon descriptor with public and internal endpoints.
# Output: argv array reference safe for GoRoutine's native process API.
sub _ssl_backend_command {
    my ( $self, $daemon ) = @_;
    if ( ref( $self->{ssl_backend_command_builder} ) eq 'CODE' ) {
        my $command = $self->{ssl_backend_command_builder}->(
            $daemon->internal_sockhost,
            $daemon->internal_sockport,
            $self->{workers},
        );
        die 'SSL backend command builder must return an argv array reference'
          if ref($command) ne 'ARRAY' || !@{$command};
        return $command;
    }
    my $running_helper = $ENV{DEVELOPER_DASHBOARD_RUNNING_HELPER};
    die 'Missing private Dashboard helper for SSL backend process'
      if !defined $running_helper || $running_helper eq '';
    my $helper = File::Spec->catfile( dirname($running_helper), '_dashboard-core' );
    return [
        $^X, $helper, 'web-ssl-backend-foreground',
        '--host',    $daemon->internal_sockhost,
        '--port',    $daemon->internal_sockport,
        '--workers', $self->{workers},
    ];
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
# a direct HTTP->HTTPS redirect response. Synchronous wrapper around the
# non-blocking step machine below: it steps the client until done, so direct
# callers (and tests) keep the old blocking call while the production
# frontend drives the same steps from a pump-driven routine.
# Input: accepted client socket and daemon descriptor.
# Output: true value after the client socket is handled.
sub _handle_ssl_frontend_client {
    my ( $self, %args ) = @_;
    my $client = $args{client} || die 'Missing frontend client socket';
    my $daemon = $args{daemon} || die 'Missing daemon descriptor';
    my @errors;
    my $state = _start_ssl_frontend_client_state( $self, $daemon, $client, \@errors );
    # Direct callers own the client socket (as the old handler left it open
    # for the caller to close); only the backend is closed by the handler.
    $state->{owns_sockets} = 0;
    while ( !_ssl_frontend_client_step($state) ) {
        select undef, undef, undef, 0.01;
    }
    die $errors[0] if @errors;
    return 1;
}

# _start_ssl_frontend_client($worker_server, $daemon, $client, $errors)
# Starts one accepted frontend client on the event loop: the client socket
# is set non-blocking and a repeating 0.05s timer routine steps its state
# machine. Returns the client state hash reference.
# Input: worker server object, daemon descriptor, accepted client socket,
#        and an array reference collecting handler errors.
# Output: client state hash reference (holds the routine for shutdown).
sub _start_ssl_frontend_client {
    my ( $worker_server, $daemon, $client, $errors ) = @_;
    my $state = _start_ssl_frontend_client_state( $worker_server, $daemon, $client, $errors );
    $state->{routine} = Developer::Dashboard::GoRoutine::go(
        sub { _ssl_frontend_client_step($state) },
        { every => 0.05 },
    );
    return $state;
}

# _start_ssl_frontend_client_state($worker_server, $daemon, $client, $errors)
# Builds one accepted client's state machine state. The client socket is set
# non-blocking so no step can stall the pump.
# Input: worker server object, daemon descriptor, accepted client socket,
#        and an array reference collecting handler errors.
# Output: client state hash reference.
sub _start_ssl_frontend_client_state {
    my ( $worker_server, $daemon, $client, $errors ) = @_;
    $client->blocking(0) if $client->can('blocking');
    return {
        worker_server => $worker_server,
        daemon        => $daemon,
        client        => $client,
        errors        => $errors,
        routine       => undef,
        done          => 0,
        owns_sockets  => 1,
        phase         => 'WAIT_FIRST',
        backend       => undef,
        head          => '',
        write_buf     => '',
        write_off     => 0,
        buf_c2b       => '',
        off_c2b       => 0,
        buf_b2c       => '',
        off_b2c       => 0,
    };
}

# _ssl_frontend_client_step($state)
# Runs one non-blocking step of one accepted frontend client and advances its
# phase (WAIT_FIRST -> PROXY / READ_HEAD -> WRITE_REDIRECT -> DONE).
# Input: client state hash reference.
# Output: true once the client is done (sockets closed), false while it
#         still needs work; never dies (a step failure is recorded in the
#         state's error list and the client is finished).
sub _ssl_frontend_client_step {
    my ($state) = @_;
    return 1 if $state->{done};
    my $ok = eval {
        if ( $state->{phase} eq 'WAIT_FIRST' ) {
            _ssl_frontend_client_wait_first($state);
        }
        elsif ( $state->{phase} eq 'PROXY' ) {
            _ssl_frontend_client_proxy($state);
        }
        elsif ( $state->{phase} eq 'READ_HEAD' ) {
            _ssl_frontend_client_read_head($state);
        }
        elsif ( $state->{phase} eq 'WRITE_REDIRECT' ) {
            _ssl_frontend_client_write_redirect($state);
        }
        1;
    };
    if ( !$ok ) {
        my $error = $@;
        $error = 'unknown client error' if !defined $error || $error eq '';
        push @{ $state->{errors} }, $error;
        _ssl_frontend_client_finish($state);
        return 1;
    }
    return $state->{done} ? 1 : 0;
}

# _ssl_frontend_client_wait_first($state)
# Waits for the first byte of one accepted client, then routes it: a TLS
# first byte opens the internal backend (PROXY), anything else starts the
# plain-HTTP redirect read (READ_HEAD). A non-socket handle never becomes
# readable under select, so it is probed first and the peek runs at once
# instead of spinning (t/88 devnull case).
# Input: client state hash reference.
# Output: nothing; advances the state phase or finishes the client.
sub _ssl_frontend_client_wait_first {
    my ($state) = @_;
    my $client = $state->{client};
    my $is_socket = defined getsockopt( $client, SOL_SOCKET, SO_TYPE );
    if ($is_socket) {
        my $select = IO::Select->new($client);
        return if !$select->can_read(0);
    }
    my $first = '';
    my $peeked = recv( $client, $first, 1, MSG_PEEK );
    if ( !defined $peeked || $first eq '' ) {
        _ssl_frontend_client_finish($state);
        return;
    }
    if ( _socket_looks_like_tls($first) ) {
        my $backend = IO::Socket::INET->new(
            PeerAddr => $state->{daemon}->internal_sockhost,
            PeerPort => $state->{daemon}->internal_sockport,
            Proto    => 'tcp',
            Timeout  => 5,
        );
        die "Unable to connect to internal SSL backend: $!" if !$backend;
        $backend->blocking(0) if $backend->can('blocking');
        $state->{backend} = $backend;
        $state->{phase} = 'PROXY';
        return;
    }
    $state->{head} = '';
    $state->{phase} = 'READ_HEAD';
    return;
}

# _ssl_frontend_client_proxy($state)
# Pumps bytes bidirectionally between the public client socket and the
# internal TLS backend socket for one step. A closed source ends the client.
# Input: client state hash reference.
# Output: nothing; advances buffers or finishes the client.
sub _ssl_frontend_client_proxy {
    my ($state) = @_;
    return if $state->{done};
    _ssl_frontend_client_proxy_dir(
        $state, $state->{client}, $state->{backend}, 'buf_c2b', 'off_c2b' );
    return if $state->{done};
    _ssl_frontend_client_proxy_dir(
        $state, $state->{backend}, $state->{client}, 'buf_b2c', 'off_b2c' );
    return;
}

# _ssl_frontend_client_proxy_dir($state, $from, $to, $buf_key, $off_key)
# Moves bytes in one proxy direction for one step: flushes bytes left over
# from a partial write, then reads one fresh chunk and writes it out.
# A partial write is buffered and retried on the next tick.
# Input: client state, source and target sockets, and the state keys holding
#        the direction's pending bytes and written offset.
# Output: nothing; advances the direction's buffer or finishes the client.
sub _ssl_frontend_client_proxy_dir {
    my ( $state, $from, $to, $buf_key, $off_key ) = @_;
    if ( length $state->{$buf_key} ) {
        my $select = IO::Select->new($to);
        return if !$select->can_write(0);
        my $written = syswrite( $to, $state->{$buf_key},
            length( $state->{$buf_key} ) - $state->{$off_key}, $state->{$off_key} );
        if ( !defined $written ) {
            return if $! == EAGAIN || $! == EWOULDBLOCK;
            die "Unable to proxy SSL frontend bytes: $!";
        }
        $state->{$off_key} += $written;
        if ( $state->{$off_key} >= length $state->{$buf_key} ) {
            $state->{$buf_key} = '';
            $state->{$off_key} = 0;
            # Buffer fully flushed: fall through and read in the same
            # step instead of waiting for the next 50ms tick. A partial
            # write still returns here, so a new chunk can never
            # overwrite data that has not been flushed yet.
        }
        else {
            return;
        }
    }
    my $select = IO::Select->new($from);
    return if !$select->can_read(0);
    my $chunk = '';
    my $read = sysread( $from, $chunk, 8192 );
    if ( !defined $read ) {
        return if $! == EAGAIN || $! == EWOULDBLOCK;
        _ssl_frontend_client_finish($state);
        return;
    }
    if ( $read <= 0 ) {
        _ssl_frontend_client_finish($state);
        return;
    }
    $state->{$buf_key} = $chunk;
    $state->{$off_key} = 0;
    return;
}

# _ssl_frontend_client_read_head($state)
# Reads one plain-HTTP request head chunk for one step. When the head is
# complete (or at the 16KB cap) the redirect response is built and the
# client moves to WRITE_REDIRECT.
# Input: client state hash reference.
# Output: nothing; advances the accumulated head or finishes the client.
sub _ssl_frontend_client_read_head {
    my ($state) = @_;
    my $client = $state->{client};
    my $select = IO::Select->new($client);
    return if !$select->can_read(0);
    my $chunk = '';
    my $read = sysread( $client, $chunk, 1024 );
    if ( !defined $read ) {
        return if $! == EAGAIN || $! == EWOULDBLOCK;
        _ssl_frontend_client_finish($state);
        return;
    }
    if ( $read <= 0 ) {
        _ssl_frontend_client_finish($state);
        return;
    }
    $state->{head} .= $chunk;
    return
      if length( $state->{head} ) < 16384 && $state->{head} !~ /\r?\n\r?\n/;
    $state->{write_buf} = _http_redirect_response(
        host => $state->{worker_server}
          ->_request_host_from_head( $state->{head}, $state->{daemon} ),
        target => _request_target_from_head( $state->{head} ),
    );
    $state->{write_off} = 0;
    $state->{phase} = 'WRITE_REDIRECT';
    return;
}

# _ssl_frontend_client_write_redirect($state)
# Writes the redirect response for one step. A partial write resumes on the
# next tick; a failed write is ignored, as the old code never checked it.
# Input: client state hash reference.
# Output: nothing; advances the written offset or finishes the client.
sub _ssl_frontend_client_write_redirect {
    my ($state) = @_;
    my $client = $state->{client};
    my $select = IO::Select->new($client);
    return if !$select->can_write(0);
    my $written = syswrite( $client, $state->{write_buf},
        length( $state->{write_buf} ) - $state->{write_off}, $state->{write_off} );
    if ( !defined $written ) {
        return if $! == EAGAIN || $! == EWOULDBLOCK;
        _ssl_frontend_client_finish($state);
        return;
    }
    $state->{write_off} += $written;
    if ( $state->{write_off} >= length $state->{write_buf} ) {
        _ssl_frontend_client_finish($state);
    }
    return;
}

# _ssl_frontend_client_finish($state)
# Finishes one accepted frontend client: cancels its routine, closes the
# backend, and marks it done. The client socket is closed too, unless the
# state is a direct-call wrapper (owns_sockets false), where the caller
# owns the client and closes it. A failed client close is recorded in the
# state's error list, as the old handler did.
# Input: client state hash reference.
# Output: nothing.
sub _ssl_frontend_client_finish {
    my ($state) = @_;
    return if $state->{done};
    $state->{done} = 1;
    $state->{routine}->kill if $state->{routine};
    if ( $state->{client} && $state->{owns_sockets} ) {
        $state->{worker_server}->_close_ssl_frontend_handle( $state->{client} )
          or push @{ $state->{errors} },
          "Unable to close SSL frontend client: $!";
    }
    close $state->{backend} if $state->{backend};
    return;
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
    my $select = IO::Select->new($socket);
    while ( length($head) < 16384 ) {
        next if !$select->can_read(0.25);
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
    while (1) {
        my @ready = $select->can_read(0.25);
        next if !@ready;
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
}

# _stop_ssl_backend($pid, $reaped_children)
# Terminates the internal SSL backend process used by the public SSL frontend.
# Input: backend pid integer and optional hash reference of already reaped
# child pids.
# Output: true value.
sub _stop_ssl_backend {
    my ( $pid, $reaped_children ) = @_;
    return 1 if !$pid;
    return 1 if $SSL_BACKEND_REAPED{$pid};
    return 1 if ref($reaped_children) eq 'HASH' && $reaped_children->{$pid};
    Developer::Dashboard::GoRoutine::terminate_process( $pid, 'TERM' )
      if Developer::Dashboard::GoRoutine::process_running($pid);
    Developer::Dashboard::GoRoutine::wait_process($pid);
    $SSL_BACKEND_REAPED{$pid} = 1;
    return 1;
}

# _start_ssl_backend_watchdog($backend_pid)
# Starts a separate watchdog process that ends the internal SSL backend
# when the frontend process disappears. The frontend can be killed with
# TerminateProcess (Windows) or SIGKILL, which gives it no chance to run
# its TERM handler and stop the backend, so the orphaned backend would
# otherwise hold the test harness pipes open forever and keep listening.
# The watcher polls the frontend pid every 0.25s; when the frontend is
# gone it terminates the backend (never dying on the kill: the backend
# may already be dead) and exits. Its lifetime is bounded by the
# frontend's own lifetime: a server runs for hours, and the watchdog
# must outlive it however long that is. The investigation micro's 120s
# bound was test safety so the micro could never hang forever, and the
# old loop-branch parent watchdog was likewise unbounded (while (1)).
# When DEVELOPER_DASHBOARD_SSL_WATCHDOG_LOG names a file, the watcher
# appends its decisions there (started, frontend gone, exiting); the
# variable is unset in normal use, so the watcher stays silent.
# Input: backend pid integer.
# Output: watchdog pid integer, or 0 when the backend pid is unusable.
sub _start_ssl_backend_watchdog {
    my ($backend_pid) = @_;
    return 0 if !defined $backend_pid || $backend_pid !~ /^\d+$/ || $backend_pid < 1;
    my $watcher_program = <<'WATCHER_PERL';
use strict;
use warnings;
use Developer::Dashboard::GoRoutine ();
my ( $frontend_pid, $backend_pid ) = @ARGV;
my $log = $ENV{DEVELOPER_DASHBOARD_SSL_WATCHDOG_LOG} // '';
my $_watchdog_log = sub {
    my ($line) = @_;
    return if $log eq '';
    if ( open my $fh, '>>', $log ) {
        print {$fh} $line . "\n";
        close $fh;
    }
};
$_watchdog_log->( "watcher started frontend=$frontend_pid backend=$backend_pid " . time() );
while (1) {
    if ( !Developer::Dashboard::GoRoutine::process_running($frontend_pid) ) {
        $_watchdog_log->("watcher: frontend gone, killing backend=$backend_pid " . time());
        eval { Developer::Dashboard::GoRoutine::terminate_process($backend_pid); };
        for ( 1 .. 40 ) {
            last if !Developer::Dashboard::GoRoutine::process_running($backend_pid);
            select undef, undef, undef, 0.25;
        }
        $_watchdog_log->(
            "watcher exiting backend_alive="
              . ( Developer::Dashboard::GoRoutine::process_running($backend_pid) ? 1 : 0 )
              . " " . time()
        );
        exit 0;
    }
    select undef, undef, undef, 0.25;
}
WATCHER_PERL
    my @library_args = map { ( '-I', $_ ) } grep { defined && -d $_ } @INC;
    return Developer::Dashboard::GoRoutine::spawn(
        [ $^X, @library_args, '-e', $watcher_program, $$, $backend_pid ],
        {},
    );
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
    Developer::Dashboard::GoRoutine::wait_process($pid);
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

    # Validation lives in Config::ssl_validity_days, which is the single place a
    # user-supplied value is checked; this is only the default for a caller that
    # supplies nothing. Deliberately not re-validating here - a second copy of
    # the same guard is how two implementations drift apart (DD-615).
    my $validity_days = $args{validity_days} // 365;

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
        'openssl', 'req', '-new', '-x509', '-days', $validity_days,
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
        next if $normalized eq '';
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
# leaf-certificate profile required by d2 serve --ssl.
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

  my $server = Developer::Dashboard::Web::Server->new(app => $app, paths => $paths);
  $server->run;

=head1 DESCRIPTION

This module reserves the local listen address, builds the Dancer2 PSGI app,
passes the path registry so skill C<lib/Dashboard.pm> extensions can load,
and runs it under Starman through Plack::Runner.

=head1 METHODS

=head2 new, run, start_daemon, listening_url, serve_daemon, psgi_app, _build_runner, _serve_ssl_frontend, _close_ssl_frontend_handle, _ssl_backend_command, _wait_for_ssl_backend_ready, _handle_ssl_frontend_client, _default_headers, _ssl_certificate_directory, generate_self_signed_cert, get_ssl_cert_paths

Construct and run the local PSGI web server with optional SSL/HTTPS support.

When C<ssl => 1> is passed to new(), generates or refreshes self-signed certificates in C<~/.developer-dashboard/certs/> with SAN coverage for C<localhost>, C<127.0.0.1>, C<::1>, the concrete non-wildcard bind host, and any configured extra aliases/IPs. It launches the internal HTTPS Starman backend as an argv-based GoRoutine-managed helper process, waits for a successful loopback TLS handshake before opening the public listener, and runs accepted client handlers as cancellable GoRoutine routines sharing their socket and minimal server state. Shutdown cancels and joins handlers, terminates and waits for the backend, and reports handler or lifecycle errors. The public frontend redirects plain HTTP requests to the equivalent C<https://...> URL and proxies TLS traffic to the internal backend. The listening_url() method returns https:// when SSL is enabled.

=head1 SSL SUPPORT

The public front-proxy owns the external listener. It starts the internal
Starman server with the private C<web-ssl-backend-foreground> helper using an
argument vector, not a shell command. The command targets the staged
C<_dashboard-core> dispatcher beside the running helper rather than reusing
the command wrapper named by C<DEVELOPER_DASHBOARD_RUNNING_HELPER>; wrappers
prepend their own command name and would otherwise recursively start SSL
frontends. The helper reconstructs the ordinary application and serves only on
the reserved internal endpoint. Startup is not considered ready until a TLS
handshake succeeds. Readiness checks detect exited-but-unreaped child
processes, and premature helper exit and timeout are reported as errors.

Each accepted client socket is handed to a GoRoutine worker with shared socket,
daemon descriptor, and minimal host/SAN state. Workers use bounded readiness
waits so shutdown cancellation also works when a client remains idle. The
front-end cancels and joins workers before stopping and waiting for the backend,
and surfaces worker failures unless shutdown itself requested cancellation.
Socket close errors are retained while workers and the managed backend are
cleaned up, then reported so a failed close cannot strand the backend process.
The worker contract depends on GoRoutine's supported shared filehandle and
reference types; it does not claim that arbitrary opaque native pointers can
be shared.

=head2 _close_ssl_frontend_handle($handle)

Closes one SSL frontend socket or filehandle and returns Perl's close result
unchanged. The SSL frontend uses this helper for worker sockets, listener-side
socket release, and the public listener so each close error can be preserved
while shutdown finishes. The input is an open socket or filehandle reference;
the output is true on success or false when Perl reports a close error.

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

Construct it with the backend app object, path registry, and desired host, port, worker, and SSL settings, then call C<run>, C<start_daemon>, or C<serve_daemon>. The path registry is passed into C<Developer::Dashboard::Web::DancerApp> so installed skills can register their Dancer2 routes and settings during startup. Keep transport wiring here.

=head1 WHAT USES IT

It is used by C<d2 serve>, C<d2 restart>, C<app.psgi> smoke paths, SSL/browser regression tests, and contributors verifying security headers and HTTPS behavior.

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

#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

# The web server forks its internal SSL backend and its per-connection
# handlers directly through the fork builtin, so the only way to drive the
# "fork failed" arms is to override the global fork op before the module under
# test is compiled. The override stays transparent unless a test opts in.
our $FORK_OVERRIDE;
our $EXIT_OVERRIDE;
our $KILL_OVERRIDE;

BEGIN {
    *CORE::GLOBAL::fork = sub {
        return $main::FORK_OVERRIDE->() if $main::FORK_OVERRIDE;
        return CORE::fork();
    };
    *CORE::GLOBAL::exit = sub {
        return $main::EXIT_OVERRIDE->(@_) if $main::EXIT_OVERRIDE;
        return CORE::exit(@_);
    };
    *CORE::GLOBAL::kill = sub {
        return $main::KILL_OVERRIDE->(@_) if $main::KILL_OVERRIDE;
        return CORE::kill(@_);
    };
}

use Capture::Tiny qw(capture);
use Errno qw(EINTR);
use File::Basename qw(basename dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir tempfile);
use IO::Select;
use IO::Socket::INET;
use Socket qw(AF_UNIX PF_UNSPEC SOCK_STREAM SOL_SOCKET SO_LINGER);
use Symbol qw(gensym);
use Test::More;

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Web::Server;
use Developer::Dashboard::Web::Server::Daemon;

# Hermetic runtime: every layer lookup resolves from this temp home and cwd.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
ok( $paths->home_runtime_path, 'hermetic path registry resolves a home runtime path' );

{
    package Local::StubApp;

    sub new { return bless {}, shift }

    sub authorize_request { return }
}

# A stub listen socket whose close() succeeds or fails on demand. The failing
# variant is a read pipe from a child that exits non-zero, which is a real
# close failure rather than a faked return value.
{
    package Local::StubSocket;

    our $HOST = '127.0.0.1';
    our $PORT = 17901;

    sub new {
        my ( $class, %args ) = @_;
        my $fh;
        if ( $args{closeable} ) {
            open $fh, '<', File::Spec->devnull
              or die "Unable to open closeable stub socket fixture: $!";
        }
        else {
            open $fh, '-|', 'sh', '-c', 'exit 3'
              or die "Unable to open uncloseable stub socket fixture: $!";
        }
        return bless $fh, $class;
    }

    sub sockhost { return $HOST }

    sub sockport { return $PORT }
}

# A frontend listener whose accept() replays a scripted sequence of results.
{
    package Local::ScriptedListener;

    our @ACCEPTS;

    sub new {
        my ($class) = @_;
        open my $fh, '<', File::Spec->devnull
          or die "Unable to open scripted listener fixture: $!";
        return bless $fh, $class;
    }

    sub accept {
        my $next = shift @ACCEPTS;
        return $next->() if $next;
        $! = 0;
        return;
    }
}

# Tied handles that fail at print time / at close time without leaving a
# half-open filehandle behind for the interpreter to complain about.
{
    package Local::FailingPrintHandle;

    sub TIEHANDLE { return bless {}, shift }

    sub PRINT { return 0 }

    sub CLOSE { return 1 }
}

{
    package Local::FailingCloseHandle;

    sub TIEHANDLE { return bless {}, shift }

    sub PRINT { return 1 }

    sub CLOSE { return 0 }
}

{
    package Local::WorkingHandle;

    sub TIEHANDLE { return bless {}, shift }

    sub PRINT { return 1 }

    sub CLOSE { return 1 }
}

{
    package Local::Runner;

    sub new { return bless { parsed => undef, ran => undef }, shift }

    sub parse_options {
        my ( $self, @options ) = @_;
        $self->{parsed} = \@options;
        return 1;
    }

    sub run {
        my ( $self, $app ) = @_;
        $self->{ran} = $app;
        return 1;
    }
}

# _tied_handle($package)
# Builds an anonymous filehandle backed by one of the tied fixtures above.
sub _tied_handle {
    my ($package) = @_;
    my $fh = gensym();
    tie *{$fh}, $package;
    return $fh;
}

# _write_file($path, $text)
# Writes one fixture file, dying loudly on any failure.
sub _write_file {
    my ( $path, $text ) = @_;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $text or die "Unable to write $path: $!";
    close $fh or die "Unable to close $path: $!";
    return 1;
}

# _reset_client_socket()
# Returns a connected loopback client socket whose peer has already sent a TCP
# RST, so the next sysread on it fails with ECONNRESET instead of reading EOF.
sub _reset_client_socket {
    my $listener = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Proto     => 'tcp',
        ReuseAddr => 1,
        Listen    => 5,
    ) or die "Unable to reserve reset-fixture listener: $!";
    my $client = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => $listener->sockport,
        Proto    => 'tcp',
    ) or die "Unable to connect reset-fixture client: $!";
    my $accepted = $listener->accept
      or die "Unable to accept reset-fixture connection: $!";
    setsockopt( $accepted, SOL_SOCKET, SO_LINGER, pack( 'II', 1, 0 ) )
      or die "Unable to force reset-fixture linger: $!";
    close $accepted or die "Unable to reset the fixture peer socket: $!";
    return ( $client, $listener );
}

# _redirect_server(@extra_subject_alt_names)
# Returns a bare Web::Server instance carrying only the fields the redirect
# helpers read, so the authority allowlist can be driven without generating a
# certificate or binding a socket.
sub _redirect_server {
    my (@extra_subject_alt_names) = @_;
    return bless {
        host                  => '0.0.0.0',
        port                  => 7890,
        workers               => 1,
        ssl                   => 1,
        ssl_subject_alt_names => \@extra_subject_alt_names,
    }, 'Developer::Dashboard::Web::Server';
}

# _profile_fixture_cert($cert_file, $key_file, $extensions)
# Generates a self-signed certificate carrying only the requested v3
# extensions, so the profile checker can be driven down each rejection arm.
sub _profile_fixture_cert {
    my ( $cert_file, $key_file, $extensions ) = @_;
    my ( $config_fh, $config_file ) =
      tempfile( 'dd-profile-XXXXXX', SUFFIX => '.cnf', TMPDIR => 1 );
    print {$config_fh} <<"OPENSSL_CONFIG" or die "Unable to write profile fixture config $config_file: $!";
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
x509_extensions = fixture_req

[ dn ]
C = US
ST = Local
L = Local
O = Developer Dashboard
CN = localhost

[ fixture_req ]
$extensions
OPENSSL_CONFIG
    close $config_fh or die "Unable to close profile fixture config $config_file: $!";
    my ( $stdout, $stderr, $exit ) = capture {
        system(
            'openssl', 'req', '-new', '-x509', '-days', '365', '-nodes',
            '-config', $config_file,
            '-out',    $cert_file,
            '-keyout', $key_file,
        );
    };
    unlink $config_file or die "Unable to remove profile fixture config $config_file: $!";
    die "Unable to generate profile fixture certificate: $stderr$stdout" if $exit != 0;
    return $cert_file;
}

my $app = Local::StubApp->new;

# One shared SSL-enabled server. Building it also exercises the real
# certificate generation path once, which is reused by the SSL frontend tests.
my $ssl_home = tempdir( CLEANUP => 1 );
my $ssl_server = do {
    local $ENV{HOME} = $ssl_home;
    Developer::Dashboard::Web::Server->new(
        app     => $app,
        host    => '127.0.0.1',
        port    => 17902,
        workers => 1,
        ssl     => 1,
    );
};
isa_ok( $ssl_server, 'Developer::Dashboard::Web::Server' );

my $ssl_daemon = Developer::Dashboard::Web::Server::Daemon->new(
    host          => '127.0.0.1',
    port          => 17902,
    internal_host => '127.0.0.1',
    internal_port => 17903,
);

# --- new(): worker count validation -----------------------------------------
{
    my $blank = eval {
        Developer::Dashboard::Web::Server->new( app => $app, workers => '' );
        1;
    };
    ok( !$blank, 'constructor rejects an empty worker count' );
    like( $@, qr/Missing worker count/, 'constructor names the missing worker count explicitly' );

    my $word = eval {
        Developer::Dashboard::Web::Server->new( app => $app, workers => 'two' );
        1;
    };
    ok( !$word, 'constructor rejects a non-numeric worker count' );
    like(
        $@,
        qr/Worker count must be a positive integer/,
        'constructor reports non-numeric worker counts as invalid integers',
    );

    my $zero = eval {
        Developer::Dashboard::Web::Server->new( app => $app, workers => 0 );
        1;
    };
    ok( !$zero, 'constructor rejects a zero worker count' );
    like(
        $@,
        qr/Worker count must be a positive integer/,
        'constructor reports a numeric-but-too-small worker count as invalid',
    );
}

# --- start_daemon(): socket reservation and close failures ------------------
{
    my $server = Developer::Dashboard::Web::Server->new(
        app     => $app,
        host    => '127.0.0.1',
        port    => 17901,
        workers => 1,
    );

    no warnings 'redefine';
    local *IO::Socket::INET::new = sub { return Local::StubSocket->new( closeable => 0 ) };
    my $ok = eval { $server->start_daemon; 1 };
    ok( !$ok, 'start_daemon fails when the reserved listen socket cannot be closed' );
    like(
        $@,
        qr/Unable to close reserved listen socket/,
        'start_daemon reports a failed listen-socket close explicitly',
    );
}

{
    no warnings 'redefine';
    local *IO::Socket::INET::new = sub {
        my ( $class, %args ) = @_;
        return Local::StubSocket->new( closeable => 1 ) if $args{LocalPort};
        return;
    };
    my $ok = eval { $ssl_server->start_daemon; 1 };
    ok( !$ok, 'start_daemon fails when the internal SSL backend port cannot be reserved' );
    like(
        $@,
        qr/Unable to reserve internal SSL backend port/,
        'start_daemon reports a failed internal SSL backend reservation explicitly',
    );
}

{
    no warnings 'redefine';
    local *IO::Socket::INET::new = sub {
        my ( $class, %args ) = @_;
        return Local::StubSocket->new( closeable => 1 ) if $args{LocalPort};
        return Local::StubSocket->new( closeable => 0 );
    };
    my $ok = eval { $ssl_server->start_daemon; 1 };
    ok( !$ok, 'start_daemon fails when the reserved internal SSL backend socket cannot be closed' );
    like(
        $@,
        qr/Unable to close reserved internal SSL backend socket/,
        'start_daemon reports a failed internal SSL backend close explicitly',
    );
}

# --- listening_url(): missing daemon ----------------------------------------
{
    my $url = $ssl_server->listening_url(undef);
    is( $url, undef, 'listening_url returns nothing when no daemon descriptor is available' );
}

# --- _serve_ssl_frontend(): fork failures and loop exits ---------------------
{
    local $main::FORK_OVERRIDE = sub { return undef };
    my $ok = eval { $ssl_server->_serve_ssl_frontend($ssl_daemon); 1 };
    ok( !$ok, 'SSL frontend fails when the internal backend process cannot be forked' );
    like(
        $@,
        qr/Unable to fork SSL backend process/,
        'SSL frontend reports a failed backend fork explicitly',
    );
}

{
    socketpair( my $client, my $client_peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
      or die "Unable to build frontend client fixture: $!";

    local @Local::ScriptedListener::ACCEPTS = (
        sub {
            $! = EINTR;
            return undef;
        },
        sub { return $client },
    );

    my $forks = 0;
    local $main::FORK_OVERRIDE = sub {
        $forks++;
        return 991001 if $forks == 1;
        $Developer::Dashboard::Web::Server::SSL_SHUTDOWN_REQUESTED = 1;
        return 991002;
    };

    my @stopped;
    no warnings 'redefine';
    local *IO::Socket::INET::new = sub { return Local::ScriptedListener->new };
    local *Developer::Dashboard::Web::Server::_stop_ssl_backend = sub {
        push @stopped, $_[0];
        return 1;
    };
    local *Developer::Dashboard::Web::Server::_wait_for_managed_child = sub { return 1 };

    is(
        $ssl_server->_serve_ssl_frontend($ssl_daemon),
        1,
        'SSL frontend retries an interrupted accept and then exits once shutdown is requested',
    );
    is( $forks, 2, 'SSL frontend forks the backend once and one connection handler' );
    is_deeply( \@stopped, [991001], 'SSL frontend stops the internal backend before returning' );

    close $client_peer or die "Unable to close frontend client fixture peer: $!";
}

{
    socketpair( my $client, my $client_peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
      or die "Unable to build frontend handler-fork fixture: $!";

    local @Local::ScriptedListener::ACCEPTS = ( sub { return $client } );

    my $forks = 0;
    local $main::FORK_OVERRIDE = sub {
        $forks++;
        return 991003 if $forks == 1;
        return undef;
    };

    no warnings 'redefine';
    local *IO::Socket::INET::new = sub { return Local::ScriptedListener->new };
    local *Developer::Dashboard::Web::Server::_stop_ssl_backend = sub { return 1 };
    local *Developer::Dashboard::Web::Server::_wait_for_managed_child = sub { return 1 };

    my $ok = eval { $ssl_server->_serve_ssl_frontend($ssl_daemon); 1 };
    ok( !$ok, 'SSL frontend fails when a connection handler cannot be forked' );
    like(
        $@,
        qr/Unable to fork SSL frontend connection handler/,
        'SSL frontend reports a failed connection-handler fork explicitly',
    );

    close $client      or die "Unable to close handler-fork fixture client: $!";
    close $client_peer or die "Unable to close handler-fork fixture peer: $!";
}

# --- SSL frontend helper argument guards ------------------------------------
{
    my $ok = eval { $ssl_server->_open_ssl_frontend_listener_or_die(); 1 };
    ok( !$ok, 'SSL listener helper refuses to run without a daemon descriptor' );
    like(
        $@,
        qr/Missing SSL frontend daemon descriptor/,
        'SSL listener helper names the missing daemon descriptor',
    );
}

{
    my $ok = eval { $ssl_server->_handle_ssl_frontend_client(); 1 };
    ok( !$ok, 'frontend client handler refuses to run without a client socket' );
    like( $@, qr/Missing frontend client socket/, 'frontend client handler names the missing client socket' );

    open my $not_a_socket, '<', File::Spec->devnull
      or die "Unable to open non-socket client fixture: $!";

    my $no_daemon = eval {
        $ssl_server->_handle_ssl_frontend_client( client => $not_a_socket );
        1;
    };
    ok( !$no_daemon, 'frontend client handler refuses to run without a daemon descriptor' );
    like( $@, qr/Missing daemon descriptor/, 'frontend client handler names the missing daemon descriptor' );

    # recv() on a plain filehandle fails with ENOTSOCK, which is the only way
    # the peek can come back undefined rather than empty.
    is(
        $ssl_server->_handle_ssl_frontend_client(
            client => $not_a_socket,
            daemon => $ssl_daemon,
        ),
        1,
        'frontend client handler returns cleanly when the first-byte peek fails outright',
    );
    close $not_a_socket or die "Unable to close non-socket client fixture: $!";
}

# --- byte / head / target / host parsing edges ------------------------------
{
    is(
        Developer::Dashboard::Web::Server::_socket_looks_like_tls(''),
        0,
        'an empty first byte is not treated as TLS traffic',
    );
    is(
        Developer::Dashboard::Web::Server::_request_target_from_head(''),
        '/',
        'request-target helper falls back to / for an empty request head',
    );

    my $blank_daemon = Developer::Dashboard::Web::Server::Daemon->new( host => '', port => 0 );
    is(
        _redirect_server()->_request_host_from_head( undef, $blank_daemon ),
        '127.0.0.1',
        'request-host helper falls back to loopback and the default HTTPS port',
    );
    is(
        _redirect_server()->_request_host_from_head( "GET / HTTP/1.1\r\nHost:\t \r\n\r\n", $blank_daemon ),
        '127.0.0.1',
        'request-host helper falls back when the Host header value is only whitespace',
    );

    like(
        Developer::Dashboard::Web::Server::_http_redirect_response(
            host   => 'redirect.local',
            target => '',
        ),
        qr{\r\nLocation: https://redirect\.local/\r\n},
        'raw redirect response falls back to / for an empty target',
    );
}

# --- _read_http_request_head(): read error ----------------------------------
{
    my ( $client, $listener ) = _reset_client_socket();
    is(
        Developer::Dashboard::Web::Server::_read_http_request_head($client),
        '',
        'request-head reader stops with an empty head when the socket read fails',
    );
    close $client   or die "Unable to close reset request-head client: $!";
    close $listener or die "Unable to close reset request-head listener: $!";
}

# --- _proxy_streams(): read error and write error ---------------------------
{
    my ( $client, $listener ) = _reset_client_socket();
    socketpair( my $backend, my $backend_peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
      or die "Unable to build proxy backend fixture: $!";
    is(
        Developer::Dashboard::Web::Server::_proxy_streams( $client, $backend ),
        1,
        'stream proxy returns cleanly when a source socket read fails',
    );
    close $client       or die "Unable to close proxy read-error client: $!";
    close $listener     or die "Unable to close proxy read-error listener: $!";
    close $backend      or die "Unable to close proxy read-error backend: $!";
    close $backend_peer or die "Unable to close proxy read-error backend peer: $!";
}

{
    local $SIG{PIPE} = 'IGNORE';
    socketpair( my $client, my $client_peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
      or die "Unable to build proxy client fixture: $!";
    socketpair( my $backend, my $backend_peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
      or die "Unable to build proxy write-error backend fixture: $!";

    my $payload = 'proxy-payload';
    my $wrote = syswrite( $client_peer, $payload );
    die "Unable to prime the proxy client fixture: $!" if !defined $wrote || $wrote != length $payload;
    shutdown( $backend, 1 ) or die "Unable to half-close the proxy backend fixture: $!";

    my $ok = eval {
        Developer::Dashboard::Web::Server::_proxy_streams( $client, $backend );
        1;
    };
    ok( !$ok, 'stream proxy fails when forwarded bytes cannot be written to the target socket' );
    like(
        $@,
        qr/Unable to proxy SSL frontend bytes/,
        'stream proxy reports an unwritable target socket explicitly',
    );

    close $client       or die "Unable to close proxy write-error client: $!";
    close $client_peer  or die "Unable to close proxy write-error client peer: $!";
    close $backend      or die "Unable to close proxy write-error backend: $!";
    close $backend_peer or die "Unable to close proxy write-error backend peer: $!";
}

# --- child bookkeeping helpers ----------------------------------------------
{
    is(
        Developer::Dashboard::Web::Server::_stop_ssl_backend(0),
        1,
        'backend stop helper is a no-op when no backend pid is known',
    );
    is(
        Developer::Dashboard::Web::Server::_wait_for_managed_child(0),
        1,
        'managed-child wait helper is a no-op when no child pid is known',
    );
    is(
        Developer::Dashboard::Web::Server::_wait_for_managed_child( 4321, { 4321 => 1 } ),
        1,
        'managed-child wait helper skips children the local CHLD handler already reaped',
    );
    is(
        Developer::Dashboard::Web::Server::_track_reaped_child( undef, 4321 ),
        1,
        'track-reaped-child helper is a no-op without a reap set',
    );
    is(
        Developer::Dashboard::Web::Server::_track_reaped_child( {}, undef ),
        1,
        'track-reaped-child helper is a no-op for an undefined child pid',
    );
}

# --- _https_redirect_location(): host, port, and path rebuilding ------------
{
    is(
        _redirect_server('host.local')->_https_redirect_location(
            { HTTP_HOST => 'host.local:8443', PATH_INFO => '/x' }
        ),
        'https://host.local:8443/x',
        'redirect location reuses an allowlisted Host header',
    );
    is(
        _redirect_server()->_https_redirect_location( {} ),
        'https://127.0.0.1/',
        'redirect location falls back to loopback, the default HTTPS port, and /',
    );
    is(
        _redirect_server()->_https_redirect_location(
            { SERVER_NAME => 'n.local', SERVER_PORT => '', PATH_INFO => '/p' }
        ),
        'https://n.local/p',
        'redirect location omits an empty server port',
    );
    is(
        _redirect_server()->_https_redirect_location(
            {
                SERVER_NAME  => 'n.local',
                SERVER_PORT  => 8443,
                PATH_INFO    => '/p',
                QUERY_STRING => 'a=1',
            }
        ),
        'https://n.local:8443/p?a=1',
        'redirect location keeps a non-default server port and the query string',
    );
    is(
        _redirect_server()->_https_redirect_location( { PATH_INFO => '' } ),
        'https://127.0.0.1/',
        'redirect location falls back to / when the rebuilt path is empty',
    );
    is(
        _redirect_server()->_https_redirect_location( { SERVER_NAME => '', PATH_INFO => '/p' } ),
        'https://127.0.0.1/p',
        'redirect location falls back to loopback when the server name is unusable',
    );
}

# --- redirect authority allowlist: accept and reject arms -------------------
{
    my $server = _redirect_server('Alias.Local');

    is(
        $server->_allowlisted_redirect_authority('evil.com'),
        '',
        'authority allowlist rejects an unrelated host',
    );
    is(
        $server->_allowlisted_redirect_authority(undef),
        '',
        'authority allowlist rejects a missing Host header',
    );
    is(
        $server->_allowlisted_redirect_authority(''),
        '',
        'authority allowlist rejects an empty Host header',
    );
    is(
        $server->_allowlisted_redirect_authority( 'a' x 256 ),
        '',
        'authority allowlist rejects an over-long Host header',
    );
    is(
        $server->_allowlisted_redirect_authority('alias.local'),
        'alias.local',
        'authority allowlist accepts a configured SAN alias',
    );
    is(
        $server->_allowlisted_redirect_authority('ALIAS.LOCAL:8443'),
        'alias.local:8443',
        'authority allowlist normalizes case and keeps a valid port',
    );
    is(
        $server->_allowlisted_redirect_authority('localhost'),
        'localhost',
        'authority allowlist accepts the default localhost SAN',
    );
    is(
        $server->_allowlisted_redirect_authority('127.0.0.9'),
        '127.0.0.9',
        'authority allowlist accepts any loopback literal',
    );
    is(
        $server->_allowlisted_redirect_authority('[0:0:0:0:0:0:0:1]'),
        '[0:0:0:0:0:0:0:1]',
        'authority allowlist accepts the expanded IPv6 loopback literal',
    );
    is(
        $server->_allowlisted_redirect_authority('127.0.0.999'),
        '',
        'authority allowlist rejects an out-of-range loopback-looking octet',
    );
    is(
        $server->_allowlisted_redirect_authority('alias.local:0'),
        '',
        'authority allowlist rejects a zero port',
    );
    is(
        $server->_allowlisted_redirect_authority('alias.local:99999'),
        '',
        'authority allowlist rejects an out-of-range port',
    );
    is(
        $server->_allowlisted_redirect_authority('alias.local:'),
        '',
        'authority allowlist rejects a trailing empty port',
    );
    is(
        $server->_allowlisted_redirect_authority('alias.local/@evil.com'),
        '',
        'authority allowlist rejects an authority carrying a path separator',
    );
    is(
        $server->_allowlisted_redirect_authority('[not:an:address!]'),
        '',
        'authority allowlist rejects a malformed bracketed literal',
    );
    is(
        $server->_allowlisted_redirect_authority('[::1]:7890'),
        '[::1]:7890',
        'authority allowlist re-brackets an accepted IPv6 literal with its port',
    );

    is(
        Developer::Dashboard::Web::Server::_host_is_loopback_literal(undef),
        0,
        'loopback literal check rejects an undefined host',
    );
    is(
        Developer::Dashboard::Web::Server::_host_is_loopback_literal(''),
        0,
        'loopback literal check rejects an empty host',
    );
    is(
        Developer::Dashboard::Web::Server::_host_is_loopback_literal('128.0.0.1'),
        0,
        'loopback literal check rejects a non-loopback IPv4 literal',
    );
    is(
        Developer::Dashboard::Web::Server::_host_is_loopback_literal('127.255.255.254'),
        1,
        'loopback literal check accepts the whole 127.0.0.0/8 range',
    );

    is(
        Developer::Dashboard::Web::Server::_redirect_authority(undef),
        '',
        'authority rebuilder returns an empty string without a host',
    );
    is(
        Developer::Dashboard::Web::Server::_redirect_authority(''),
        '',
        'authority rebuilder returns an empty string for an empty host',
    );

    is_deeply(
        [ Developer::Dashboard::Web::Server::_split_request_authority( 'n.local:8443', 9443 ) ],
        [ 'n.local', 9443 ],
        'authority parser honors an explicit port override',
    );
    is_deeply(
        [ Developer::Dashboard::Web::Server::_split_request_authority( 'n.local', 'bad' ) ],
        [],
        'authority parser rejects a non-numeric port override',
    );
}

# --- _safe_redirect_target(): every rejection arm ---------------------------
{
    my %rejected = (
        'an undefined target'    => undef,
        'an empty target'        => '',
        'a relative target'      => 'x',
        'an authority-form target' => '@evil.com/',
        'a protocol-relative target' => '//evil.com/',
        'a backslash target'     => '/\\evil.com',
        'a tab target'           => "/\t/evil.com",
        'a newline target'       => "/x\nY",
        'a delete-byte target'   => "/x\x7f",
    );
    for my $label ( sort keys %rejected ) {
        is(
            Developer::Dashboard::Web::Server::_safe_redirect_target( $rejected{$label} ),
            '/',
            "redirect target sanitizer rejects $label",
        );
    }
    is(
        Developer::Dashboard::Web::Server::_safe_redirect_target('/a/b?c=1&d=%2F'),
        '/a/b?c=1&d=%2F',
        'redirect target sanitizer keeps a normal origin-form path and query',
    );
    is(
        Developer::Dashboard::Web::Server::_request_target_from_head("GET //evil.com/ HTTP/1.1\r\n\r\n"),
        '/',
        'request-target helper sanitizes a protocol-relative target from the request line',
    );
}

# --- SAN normalization helpers ----------------------------------------------
{
    is_deeply(
        [
            Developer::Dashboard::Web::Server::_ssl_expected_subject_alt_names(
                hosts => [ '', '0.0.0.0', 'Alias.Local:8443' ],
            )
        ],
        [ 'localhost', '127.0.0.1', '::1', 'alias.local' ],
        'expected SAN list drops empty and wildcard entries and strips ports',
    );

    is(
        Developer::Dashboard::Web::Server::_normalize_ssl_subject_alt_name(undef),
        '',
        'SAN normalizer returns an empty string for an undefined name',
    );

    for my $wildcard ( undef, '', '*', '0.0.0.0', '::', '0:0:0:0:0:0:0:0' ) {
        my $label = defined $wildcard ? ( $wildcard eq '' ? 'an empty name' : $wildcard ) : 'an undefined name';
        is(
            Developer::Dashboard::Web::Server::_ssl_subject_alt_name_is_wildcard($wildcard),
            1,
            "SAN wildcard check rejects $label",
        );
    }

    is(
        Developer::Dashboard::Web::Server::_ssl_subject_alt_name_is_ip(undef),
        0,
        'SAN IP check treats an undefined name as a non-IP entry',
    );
    is(
        Developer::Dashboard::Web::Server::_ssl_subject_alt_name_is_ip(''),
        0,
        'SAN IP check treats an empty name as a non-IP entry',
    );
}

# --- _ssl_cert_has_expected_profile(): input guards -------------------------
{
    is(
        Developer::Dashboard::Web::Server::_ssl_cert_has_expected_profile(undef),
        0,
        'profile check rejects an undefined certificate path',
    );
    is(
        Developer::Dashboard::Web::Server::_ssl_cert_has_expected_profile(''),
        0,
        'profile check rejects an empty certificate path',
    );
    is(
        Developer::Dashboard::Web::Server::_ssl_cert_has_expected_profile(
            File::Spec->catfile( $home, 'missing-server.crt' )
        ),
        0,
        'profile check rejects a certificate path that does not exist',
    );
}

# --- _ssl_cert_has_expected_profile(): inspection and extension arms --------
{
    my $junk = File::Spec->catfile( $home, 'not-a-certificate.crt' );
    _write_file( $junk, "this is definitely not a certificate\n" );
    my $ok = eval {
        Developer::Dashboard::Web::Server::_ssl_cert_has_expected_profile($junk);
        1;
    };
    ok( !$ok, 'profile check fails when the certificate cannot be inspected' );
    like(
        $@,
        qr/Failed to inspect SSL certificate/,
        'profile check reports an uninspectable certificate explicitly',
    );
}

{
    my $fixture_dir = tempdir( CLEANUP => 1 );

    my $no_eku_cert = File::Spec->catfile( $fixture_dir, 'no-eku.crt' );
    _profile_fixture_cert(
        $no_eku_cert,
        File::Spec->catfile( $fixture_dir, 'no-eku.key' ),
        'basicConstraints = critical,CA:FALSE',
    );
    is(
        Developer::Dashboard::Web::Server::_ssl_cert_has_expected_profile($no_eku_cert),
        0,
        'profile check rejects a leaf certificate without the server-auth extended key usage',
    );

    my $no_ku_cert = File::Spec->catfile( $fixture_dir, 'no-ku.crt' );
    _profile_fixture_cert(
        $no_ku_cert,
        File::Spec->catfile( $fixture_dir, 'no-ku.key' ),
        "basicConstraints = critical,CA:FALSE\nextendedKeyUsage = serverAuth",
    );
    is(
        Developer::Dashboard::Web::Server::_ssl_cert_has_expected_profile($no_ku_cert),
        0,
        'profile check rejects a server-auth certificate without the required key usage',
    );
}

# --- _ssl_cert_has_expected_profile(): openssl verify output streams --------
{
    my $verify_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $verify_home;
    my $cert_file = Developer::Dashboard::Web::Server::generate_self_signed_cert();
    ok( -f $cert_file, 'a real dashboard certificate backs the verify-output checks' );

    my $real_capture = \&Capture::Tiny::capture;

    {
        my $calls = 0;
        no warnings 'redefine';
        local *Developer::Dashboard::Web::Server::capture = sub {
            my ($code) = @_;
            $calls++;
            return $real_capture->($code) if $calls == 1;
            return ( '', "$cert_file: OK\n", 0 );
        };
        is(
            Developer::Dashboard::Web::Server::_ssl_cert_has_expected_profile($cert_file),
            1,
            'profile check accepts an openssl verify that reports OK on stderr only',
        );
    }

    {
        my $calls = 0;
        no warnings 'redefine';
        local *Developer::Dashboard::Web::Server::capture = sub {
            my ($code) = @_;
            $calls++;
            return $real_capture->($code) if $calls == 1;
            return ( "verified\n", "nothing to report\n", 0 );
        };
        is(
            Developer::Dashboard::Web::Server::_ssl_cert_has_expected_profile($cert_file),
            0,
            'profile check rejects an openssl verify that reports OK on neither stream',
        );
    }
}

# --- generate_self_signed_cert(): the Windows home-resolution chain ---------
{
    # No HOME at all is the normal Windows shape, so the certificate directory
    # has to come from the path registry's resolution order rather than from a
    # bare HOME lookup that dies before the server can bind anything.
    local %ENV = %ENV;
    delete $ENV{HOME};
    delete $ENV{HOMEDRIVE};
    delete $ENV{HOMEPATH};

    my $profile_home = tempdir( CLEANUP => 1 );
    $ENV{USERPROFILE} = $profile_home;
    is(
        Developer::Dashboard::Web::Server::generate_self_signed_cert(),
        File::Spec->catfile( $profile_home, '.developer-dashboard', 'certs', 'server.crt' ),
        'certificate generation resolves USERPROFILE as home when HOME is unset',
    );
    ok(
        -f File::Spec->catfile( $profile_home, '.developer-dashboard', 'certs', 'server.key' ),
        'certificate generation writes the private key under the USERPROFILE home',
    );

    # Older Windows shells only export the drive and the path halves.
    delete $ENV{USERPROFILE};
    my $split_home = tempdir( CLEANUP => 1 );
    $ENV{HOMEDRIVE} = dirname($split_home);
    $ENV{HOMEPATH}  = basename($split_home);
    is(
        Developer::Dashboard::Web::Server::generate_self_signed_cert(),
        File::Spec->catfile( $split_home, '.developer-dashboard', 'certs', 'server.crt' ),
        'certificate generation resolves HOMEDRIVE and HOMEPATH when HOME and USERPROFILE are unset',
    );
}

# --- generate_self_signed_cert(): no resolvable home at all -----------------
{
    # Nothing names a home: the failure has to stay explicit instead of writing
    # certificates into an unrelated directory.
    local %ENV = %ENV;
    delete $ENV{HOME};
    delete $ENV{USERPROFILE};
    delete $ENV{HOMEDRIVE};
    delete $ENV{HOMEPATH};

    my $ok = eval {
        Developer::Dashboard::Web::Server::generate_self_signed_cert();
        1;
    };
    ok( !$ok, 'certificate generation fails when no home directory can be resolved' );
    like( $@, qr/Missing home directory/, 'certificate generation names the unresolvable home directory' );
}

# --- generate_self_signed_cert(): certificate present without its key -------
{
    my $half_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $half_home;
    my $cert_dir = File::Spec->catdir( $half_home, '.developer-dashboard', 'certs' );
    make_path($cert_dir);
    my $cert_file = File::Spec->catfile( $cert_dir, 'server.crt' );
    my $key_file  = File::Spec->catfile( $cert_dir, 'server.key' );
    _write_file( $cert_file, "stale certificate without a key\n" );

    is(
        Developer::Dashboard::Web::Server::generate_self_signed_cert(),
        $cert_file,
        'certificate generation regenerates when the certificate exists but its key is gone',
    );
    ok( -f $key_file, 'certificate generation restores the missing private key' );
}

# --- generate_self_signed_cert(): OpenSSL config write/close failures -------
{
    my $write_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $write_home;
    no warnings 'redefine';
    local *Developer::Dashboard::Web::Server::tempfile = sub {
        return (
            _tied_handle('Local::FailingPrintHandle'),
            File::Spec->catfile( $write_home, 'dd-openssl-unwritable.cnf' ),
        );
    };
    my $ok = eval {
        Developer::Dashboard::Web::Server::generate_self_signed_cert();
        1;
    };
    ok( !$ok, 'certificate generation fails when the OpenSSL config cannot be written' );
    like( $@, qr/Unable to write OpenSSL config/, 'certificate generation reports an unwritable OpenSSL config' );
}

{
    my $close_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $close_home;
    no warnings 'redefine';
    local *Developer::Dashboard::Web::Server::tempfile = sub {
        return (
            _tied_handle('Local::FailingCloseHandle'),
            File::Spec->catfile( $close_home, 'dd-openssl-unclosable.cnf' ),
        );
    };
    my $ok = eval {
        Developer::Dashboard::Web::Server::generate_self_signed_cert();
        1;
    };
    ok( !$ok, 'certificate generation fails when the OpenSSL config cannot be closed' );
    like( $@, qr/Unable to close OpenSSL config/, 'certificate generation reports an unclosable OpenSSL config' );
}

# --- generate_self_signed_cert(): openssl failure with no config left behind
{
    my $missing_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $missing_home;
    no warnings 'redefine';
    local *Developer::Dashboard::Web::Server::tempfile = sub {
        return (
            _tied_handle('Local::WorkingHandle'),
            File::Spec->catfile( $missing_home, 'dd-openssl-absent.cnf' ),
        );
    };
    my $ok = eval {
        Developer::Dashboard::Web::Server::generate_self_signed_cert();
        1;
    };
    ok( !$ok, 'certificate generation fails when openssl cannot read its config' );
    like(
        $@,
        qr/Failed to generate SSL certificate/,
        'certificate generation reports a non-zero openssl exit explicitly',
    );
}

# --- generate_self_signed_cert(): openssl succeeds but produces nothing -----
{
    my $silent_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $silent_home;
    no warnings 'redefine';
    local *Developer::Dashboard::Web::Server::capture = sub { return ( '', '', 0 ) };
    my $ok = eval {
        Developer::Dashboard::Web::Server::generate_self_signed_cert();
        1;
    };
    ok( !$ok, 'certificate generation fails when openssl exits cleanly without writing a certificate' );
    like( $@, qr/Certificate file not created/, 'certificate generation reports the missing certificate file' );
}

{
    my $cert_only_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $cert_only_home;
    my $cert_file = File::Spec->catfile( $cert_only_home, '.developer-dashboard', 'certs', 'server.crt' );
    no warnings 'redefine';
    local *Developer::Dashboard::Web::Server::capture = sub {
        _write_file( $cert_file, "generated certificate placeholder\n" );
        return ( '', '', 0 );
    };
    my $ok = eval {
        Developer::Dashboard::Web::Server::generate_self_signed_cert();
        1;
    };
    ok( !$ok, 'certificate generation fails when openssl writes no private key' );
    like( $@, qr/Key file not created/, 'certificate generation reports the missing key file' );
}

{
    my $profile_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $profile_home;
    my $cert_dir  = File::Spec->catdir( $profile_home, '.developer-dashboard', 'certs' );
    my $cert_file = File::Spec->catfile( $cert_dir, 'server.crt' );
    my $key_file  = File::Spec->catfile( $cert_dir, 'server.key' );
    no warnings 'redefine';
    local *Developer::Dashboard::Web::Server::capture = sub {
        _write_file( $cert_file, "generated certificate placeholder\n" );
        _write_file( $key_file,  "generated key placeholder\n" );
        return ( '', '', 0 );
    };
    my $ok = eval {
        Developer::Dashboard::Web::Server::generate_self_signed_cert();
        1;
    };
    ok( !$ok, 'certificate generation fails when the generated certificate misses the dashboard profile' );
    like(
        $@,
        qr/Generated certificate is missing the required dashboard HTTPS server profile/,
        'certificate generation reports a certificate that does not match the dashboard HTTPS profile',
    );
}

# --- get_ssl_cert_paths(): the Windows home-resolution chain ----------------
{
    # The path lookup runs on every HTTPS start, so it has to resolve a Windows
    # profile home exactly like the generator does.
    local %ENV = %ENV;
    delete $ENV{HOME};
    delete $ENV{HOMEDRIVE};
    delete $ENV{HOMEPATH};

    my $profile_home = tempdir( CLEANUP => 1 );
    $ENV{USERPROFILE} = $profile_home;
    my $profile_cert_dir = File::Spec->catdir( $profile_home, '.developer-dashboard', 'certs' );
    my $profile_cert = File::Spec->catfile( $profile_cert_dir, 'server.crt' );
    my $profile_key  = File::Spec->catfile( $profile_cert_dir, 'server.key' );

    my $unresolved = eval {
        Developer::Dashboard::Web::Server::get_ssl_cert_paths();
        1;
    };
    ok( !$unresolved, 'certificate path lookup still fails when the profile home holds no certificate' );
    like(
        $@,
        qr/\QCertificate file not found: $profile_cert\E/,
        'certificate path lookup names the USERPROFILE-resolved certificate path when HOME is unset',
    );

    make_path($profile_cert_dir);
    _write_file( $profile_cert, "profile certificate placeholder\n" );
    _write_file( $profile_key,  "profile key placeholder\n" );
    is_deeply(
        [ Developer::Dashboard::Web::Server::get_ssl_cert_paths() ],
        [ $profile_cert, $profile_key ],
        'certificate path lookup returns the USERPROFILE-resolved certificate and key when HOME is unset',
    );

    # Older Windows shells only export the drive and the path halves.
    delete $ENV{USERPROFILE};
    my $split_home = tempdir( CLEANUP => 1 );
    $ENV{HOMEDRIVE} = dirname($split_home);
    $ENV{HOMEPATH}  = basename($split_home);
    my $split_cert_dir = File::Spec->catdir( $split_home, '.developer-dashboard', 'certs' );
    my $split_cert = File::Spec->catfile( $split_cert_dir, 'server.crt' );
    my $split_key  = File::Spec->catfile( $split_cert_dir, 'server.key' );
    make_path($split_cert_dir);
    _write_file( $split_cert, "split-home certificate placeholder\n" );
    _write_file( $split_key,  "split-home key placeholder\n" );
    is_deeply(
        [ Developer::Dashboard::Web::Server::get_ssl_cert_paths() ],
        [ $split_cert, $split_key ],
        'certificate path lookup resolves HOMEDRIVE and HOMEPATH when HOME and USERPROFILE are unset',
    );
}

# --- get_ssl_cert_paths(): no resolvable home at all ------------------------
{
    local %ENV = %ENV;
    delete $ENV{HOME};
    delete $ENV{USERPROFILE};
    delete $ENV{HOMEDRIVE};
    delete $ENV{HOMEPATH};

    my $ok = eval {
        Developer::Dashboard::Web::Server::get_ssl_cert_paths();
        1;
    };
    ok( !$ok, 'certificate path lookup fails when no home directory can be resolved' );
    like( $@, qr/Missing home directory/, 'certificate path lookup names the unresolvable home directory' );
}

{
    my $empty_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $empty_home;
    my $ok = eval {
        Developer::Dashboard::Web::Server::get_ssl_cert_paths();
        1;
    };
    ok( !$ok, 'certificate path lookup fails when the certificate file is absent' );
    like( $@, qr/Certificate file not found/, 'certificate path lookup names the missing certificate file' );

    my $cert_dir = File::Spec->catdir( $empty_home, '.developer-dashboard', 'certs' );
    make_path($cert_dir);
    _write_file( File::Spec->catfile( $cert_dir, 'server.crt' ), "certificate placeholder\n" );
    my $key_missing = eval {
        Developer::Dashboard::Web::Server::get_ssl_cert_paths();
        1;
    };
    ok( !$key_missing, 'certificate path lookup fails when the private key file is absent' );
    like( $@, qr/Key file not found/, 'certificate path lookup names the missing key file' );
}

# --- server entry points and SSL-only branches -----------------------------
{
    my $plain = Developer::Dashboard::Web::Server->new(
        app                   => $app,
        ssl                   => 0,
        ssl_subject_alt_names => 'not-an-array',
    );
    is( $plain->{ssl}, 0, 'constructor accepts an explicit false SSL flag' );
    is_deeply( $plain->{ssl_subject_alt_names}, [], 'constructor ignores non-array SAN input' );

    my $https = bless { ssl => 1, workers => 1 }, 'Developer::Dashboard::Web::Server';
    my $empty_daemon = Developer::Dashboard::Web::Server::Daemon->new( host => undef, port => undef );
    my $http_url = $plain->listening_url($empty_daemon);
    is( $http_url, 'http://localhost:7890/', 'HTTP URL defaults missing daemon host and port' );
    is(
        $https->listening_url($empty_daemon),
        'https://localhost:7890/',
        'HTTPS URL defaults missing daemon host and port',
    );

    my $plain_daemon = Developer::Dashboard::Web::Server::Daemon->new( host => '127.0.0.1', port => 17920 );
    my $https_daemon = Developer::Dashboard::Web::Server::Daemon->new(
        host => '127.0.0.1', port => 17921,
        internal_host => '127.0.0.1', internal_port => 17922,
    );
    no warnings 'redefine';
    local *Plack::Runner::new = sub { return Local::Runner->new };
    local *Developer::Dashboard::Web::Server::get_ssl_cert_paths = sub { return ( 'server.crt', 'server.key' ) };

    my $plain_runner = $plain->_build_runner($plain_daemon);
    is_deeply(
        $plain_runner->{parsed},
        [ '--server', 'Starman', '--host', '127.0.0.1', '--port', 17920, '--env', 'deployment', '--workers', 1 ],
        'runner uses the public listener and omits SSL options for a plain server',
    );
    my $ssl_runner = $https->_build_runner($https_daemon);
    is_deeply(
        $ssl_runner->{parsed},
        [ '--server', 'Starman', '--host', '127.0.0.1', '--port', 17922, '--env', 'deployment', '--workers', 1,
          '--ssl', 1, '--ssl-key', 'server.key', '--ssl-cert', 'server.crt' ],
        'runner selects the internal SSL listener and adds the certificate options',
    );

    my $plain_app = sub { return [ 200, [], ['plain'] ] };
    local *Developer::Dashboard::Web::Server::_build_runner = sub { return $plain_runner };
    local *Developer::Dashboard::Web::Server::psgi_app = sub { return $plain_app };
    my $served = $plain->serve_daemon($plain_daemon);
    is( $served, 1, 'plain serve_daemon runs the PSGI app through Plack::Runner' );
    is( $plain_runner->{ran}, $plain_app, 'plain runner receives the built PSGI app' );

    my $ssl_served = 0;
    local *Developer::Dashboard::Web::Server::_serve_ssl_frontend = sub { $ssl_served++; return 1 };
    is( $https->serve_daemon($https_daemon), 1, 'SSL serve_daemon delegates to its public frontend' );
    is( $ssl_served, 1, 'SSL frontend is called once' );
}

{
    my $built_args;
    my $inner = sub { return [ 200, [], ['inner'] ] };
    no warnings 'redefine';
    local *Developer::Dashboard::Web::DancerApp::build_psgi_app = sub {
        my ( $class, %args ) = @_;
        $built_args = \%args;
        return $inner;
    };
    my $plain = bless { app => $app, ssl => 0, paths => $paths }, 'Developer::Dashboard::Web::Server';
    is( $plain->psgi_app, $inner, 'plain PSGI app is returned without an SSL wrapper' );
    is( $built_args->{paths}, $paths, 'PSGI construction receives the path registry' );
    ok( $built_args->{default_headers}{'X-Content-Type-Options'}, 'PSGI construction receives default security headers' );

    my $https = bless { app => $app, ssl => 1, paths => $paths }, 'Developer::Dashboard::Web::Server';
    my $redirected = 0;
    local *Developer::Dashboard::Web::Server::_ssl_redirect_response = sub { $redirected++; return ['redirect'] };
    my $wrapped = $https->psgi_app;
    is_deeply( $wrapped->({ 'psgi.url_scheme' => 'http' }), ['redirect'], 'SSL PSGI wrapper redirects plaintext requests' );
    is( $redirected, 1, 'SSL redirect response is requested once' );
    is_deeply( $wrapped->({ 'psgi.url_scheme' => 'https' }), [ 200, [], ['inner'] ], 'SSL PSGI wrapper passes HTTPS requests through' );
}

{
    my $run_saw_proxy_flag;
    my $runner = Local::Runner->new;
    no warnings 'redefine';
    local *Developer::Dashboard::Web::Server::_build_runner = sub { return $runner };
    local *Developer::Dashboard::Web::Server::psgi_app = sub { return sub { return [200, [], []] } };
    local *Local::Runner::run = sub { $run_saw_proxy_flag = $ENV{DEVELOPER_DASHBOARD_SSL_PROXIED}; return 1 };
    is( $ssl_server->_run_ssl_backend_process($ssl_daemon), 0, 'SSL backend process returns a successful runner status' );
    is( $run_saw_proxy_flag, 1, 'SSL backend marks its worker tree as proxy-originated' );
    ok( !exists $ENV{DEVELOPER_DASHBOARD_SSL_PROXIED}, 'proxy-origin marker is restored after the backend call' );
}

{
    my $daemon = Developer::Dashboard::Web::Server::Daemon->new( host => '127.0.0.1', port => 17923 );
    my $listener = Local::StubSocket->new( closeable => 1 );
    no warnings 'redefine';
    local *IO::Socket::INET::new = sub { return $listener };
    is(
        $ssl_server->_open_ssl_frontend_listener_or_die( daemon => $daemon, backend_pid => 1234, reaped_children => {} ),
        $listener,
        'SSL listener helper returns a successfully bound public listener',
    );

    my @stopped;
    local *IO::Socket::INET::new = sub { return };
    local *Developer::Dashboard::Web::Server::_stop_ssl_backend = sub { push @stopped, [@_]; return 1 };
    my $ok = eval { $ssl_server->_open_ssl_frontend_listener_or_die( daemon => $daemon, backend_pid => 9876 ); 1 };
    ok( !$ok, 'SSL listener helper fails when the public bind cannot be reserved' );
    like( $@, qr/Unable to bind SSL frontend/, 'SSL listener bind failure is explicit' );
    is( $stopped[0][0], 9876, 'failed public bind shuts down the backend process' );
}

{
    socketpair( my $client, my $peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
      or die "Unable to build TLS peek fixture: $!";
    syswrite( $peer, "\x16" ) == 1 or die "Unable to prime TLS peek fixture: $!";
    my $backend = _tied_handle('Local::WorkingHandle');
    my $proxied = 0;
    no warnings 'redefine';
    local *IO::Socket::INET::new = sub { return $backend };
    local *Developer::Dashboard::Web::Server::_proxy_streams = sub { $proxied++; return 1 };
    is(
        $ssl_server->_handle_ssl_frontend_client( client => $client, daemon => $ssl_daemon ),
        1,
        'frontend routes a TLS handshake byte to the internal backend',
    );
    is( $proxied, 1, 'frontend proxies the TLS client stream exactly once' );
    close $client or die "Unable to close TLS peek fixture client: $!";
    close $peer or die "Unable to close TLS peek fixture peer: $!";
}

{
    socketpair( my $client, my $peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
      or die "Unable to build HTTP redirect fixture: $!";
    my $request = "GET /alpha?x=1 HTTP/1.1\r\nHost: localhost:7890\r\n\r\n";
    syswrite( $peer, $request ) == length($request) or die "Unable to prime HTTP redirect fixture: $!";
    my $daemon = Developer::Dashboard::Web::Server::Daemon->new( host => '127.0.0.1', port => 7890 );
    is(
        $ssl_server->_handle_ssl_frontend_client( client => $client, daemon => $daemon ),
        1,
        'frontend handles a plain HTTP request on the public SSL port',
    );
    my $response = '';
    sysread( $peer, $response, 2048 );
    like( $response, qr{Location: https://localhost:7890/alpha\?x=1}, 'plain HTTP response carries the safe HTTPS redirect' );
    close $client or die "Unable to close HTTP redirect fixture client: $!";
    close $peer or die "Unable to close HTTP redirect fixture peer: $!";
}

{
    my $captured = '';
    my $server = _redirect_server();
    my $head = "POST /submit HTTP/1.1\r\nHost: localhost\r\n\r\nbody";
    socketpair( my $client, my $peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
      or die "Unable to build complete request-head fixture: $!";
    syswrite( $peer, $head ) == length($head) or die "Unable to prime complete request-head fixture: $!";
    $captured = Developer::Dashboard::Web::Server::_read_http_request_head($client);
    is( $captured, "POST /submit HTTP/1.1\r\nHost: localhost\r\n\r\n", 'request-head reader returns through the complete header terminator' );
    close $client or die "Unable to close request-head fixture client: $!";
    close $peer or die "Unable to close request-head fixture peer: $!";

    is( Developer::Dashboard::Web::Server::_request_target_from_head("BROKEN\r\n"), '/', 'malformed request line defaults to the root target' );
    is(
        $server->_request_host_from_head(
            "GET / HTTP/1.1\r\nHost: localhost:8443\r\n\r\n",
            Developer::Dashboard::Web::Server::Daemon->new( host => '127.0.0.1', port => 7890 ),
        ),
        'localhost:8443',
        'request-host helper preserves an allowlisted authority and custom public port',
    );
    like( Developer::Dashboard::Web::Server::_http_redirect_response(), qr{Location: https://127\.0\.0\.1/}, 'raw redirect response supplies both default authority and target' );
}

{
    socketpair( my $client, my $client_peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
      or die "Unable to build proxy success client fixture: $!";
    socketpair( my $backend, my $backend_peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
      or die "Unable to build proxy success backend fixture: $!";
    my $request = 'client-to-backend';
    my $reply = 'backend-to-client';
    syswrite( $client_peer, $request ) == length($request) or die "Unable to prime proxy client payload: $!";
    syswrite( $backend_peer, $reply ) == length($reply) or die "Unable to prime proxy backend payload: $!";
    shutdown( $client_peer, 1 ) or die "Unable to half-close proxy client fixture: $!";
    shutdown( $backend_peer, 1 ) or die "Unable to half-close proxy backend fixture: $!";
    is( Developer::Dashboard::Web::Server::_proxy_streams( $client, $backend ), 1, 'proxy forwards each socket direction until both peers close' );
    my ( $client_data, $backend_data ) = ( '', '' );
    sysread( $client_peer, $client_data, 1024 );
    sysread( $backend_peer, $backend_data, 1024 );
    is( $client_data, $reply, 'backend bytes reach the public client' );
    is( $backend_data, $request, 'client bytes reach the internal backend' );
    close $_ or die "Unable to close proxy success fixture socket: $!" for ( $client, $client_peer, $backend, $backend_peer );
}

{
    is( Developer::Dashboard::Web::Server::_request_is_https(undef), 0, 'HTTPS detector rejects non-hash PSGI environments' );
    is( Developer::Dashboard::Web::Server::_request_is_https({ 'psgi.url_scheme' => 'http' }), 0, 'HTTPS detector rejects a plain HTTP scheme' );
    is( Developer::Dashboard::Web::Server::_request_is_https({ 'psgi.url_scheme' => 'HTTPS' }), 1, 'HTTPS detector accepts a case-insensitive HTTPS scheme' );
    is( Developer::Dashboard::Web::Server::_request_is_https({ HTTP_X_FORWARDED_PROTO => 'HTTPS' }), 1, 'HTTPS detector accepts trusted forwarded HTTPS' );
    is( Developer::Dashboard::Web::Server::_request_is_https({}), 0, 'HTTPS detector handles absent scheme and forwarding headers' );

    my $server = _redirect_server();
    my $redirect = $server->_ssl_redirect_response({ SERVER_NAME => 'localhost', PATH_INFO => '/secure' });
    is( $redirect->[0], 307, 'HTTPS enforcement returns temporary-redirect status' );
    is( $redirect->[2][0], 'Redirecting to HTTPS', 'HTTPS enforcement includes a plain-text explanation' );
    is( $server->_https_redirect_location({ SCRIPT_NAME => '/mount', PATH_INFO => '/page' }), 'https://127.0.0.1/mount/page', 'redirect URL preserves a defined PSGI script mount prefix' );
}

{
    is( Developer::Dashboard::Web::Server::_stop_ssl_backend(4242), 1, 'backend stop helper signals a known backend and waits for it' );
    my @signals;
    local $main::KILL_OVERRIDE = sub { push @signals, [@_]; return 1 };
    is( Developer::Dashboard::Web::Server::_signal_default_term(), 1, 'default TERM helper re-signals the current process through the signal adapter' );
    is_deeply( $signals[0], [ 15, $$ ], 'default TERM helper targets the current process with TERM' );

    my %already = ();
    local *Developer::Dashboard::Web::Server::_waitpid = sub { return 4421 };
    is( Developer::Dashboard::Web::Server::_wait_for_managed_child(4421), 1, 'managed wait accepts the requested child pid' );
    local *Developer::Dashboard::Web::Server::_waitpid = sub { return -1 };
    is( Developer::Dashboard::Web::Server::_wait_for_managed_child(4422), 1, 'managed wait accepts an already-vanished child' );
    local *Developer::Dashboard::Web::Server::_waitpid = sub { return 0 };
    is( Developer::Dashboard::Web::Server::_wait_for_managed_child(4423), 1, 'managed wait returns cleanly when waitpid reports no child yet' );

    my %reaped;
    my @wait_results = ( 501, 502, 0 );
    local *Developer::Dashboard::Web::Server::_waitpid = sub { return shift @wait_results };
    is( Developer::Dashboard::Web::Server::_reap_ssl_children(\%reaped), 1, 'SSL child reaper drains all completed children' );
    is_deeply( \%reaped, { 501 => 1, 502 => 1 }, 'SSL child reaper records each collected pid' );

    local $Developer::Dashboard::Web::Server::SSL_BACKEND_PID = 7744;
    local %Developer::Dashboard::Web::Server::SSL_PREVIOUS_SIGNAL = ( TERM => sub { push @signals, ['old-term'] } );
    local *Developer::Dashboard::Web::Server::_stop_ssl_backend = sub { push @signals, ['stop', $_[0]]; return 1 };
    is( Developer::Dashboard::Web::Server::_ssl_term_handler(), 1, 'TERM cleanup stops backend then chains the prior callback' );
    is( Developer::Dashboard::Web::Server::_ssl_int_handler(), 1, 'INT cleanup handles an absent prior signal action' );
    is( Developer::Dashboard::Web::Server::_ssl_hup_handler(), 1, 'HUP cleanup handles an absent prior signal action' );
    is( $signals[-1][0], 'stop', 'signal cleanup records the backend stop' );
    is( Developer::Dashboard::Web::Server::_run_previous_signal('IGNORE'), 1, 'IGNORE signal action needs no further dispatch' );
    my $previous_called = 0;
    is( Developer::Dashboard::Web::Server::_run_previous_signal(sub { $previous_called++ }), 1, 'custom signal callback is invoked' );
    is( $previous_called, 1, 'custom previous signal callback runs exactly once' );
    local $main::KILL_OVERRIDE = sub { push @signals, ['default', @_]; return 1 };
    is( Developer::Dashboard::Web::Server::_run_previous_signal('DEFAULT'), 1, 'DEFAULT signal action dispatches through the TERM helper' );
}

{
    my $pid = CORE::fork();
    die "Unable to isolate SSL child-handler test: $!" if !defined $pid;
    if ( !$pid ) {
        socketpair( my $client, my $peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
          or CORE::exit(30);
        local @Local::ScriptedListener::ACCEPTS = ( sub { return $client } );
        my $fork_count = 0;
        local $main::FORK_OVERRIDE = sub { return ++$fork_count == 1 ? 991111 : 0 };
        local $main::EXIT_OVERRIDE = sub { $Developer::Dashboard::Web::Server::SSL_SHUTDOWN_REQUESTED = 1; return 1 };
        no warnings 'redefine';
        local *IO::Socket::INET::new = sub { return Local::ScriptedListener->new };
        local *Developer::Dashboard::Web::Server::_handle_ssl_frontend_client = sub { return 1 };
        local *Developer::Dashboard::Web::Server::_stop_ssl_backend = sub { return 1 };
        local *Developer::Dashboard::Web::Server::_wait_for_managed_child = sub { return 1 };
        my $result = $ssl_server->_serve_ssl_frontend($ssl_daemon);
        CORE::exit( $result == 1 ? 0 : 31 );
    }
    waitpid( $pid, 0 );
    is( $? >> 8, 0, 'SSL frontend connection child handles the client, exits, and allows parent cleanup' );
}

{
    my $reached = 0;
    local @Local::ScriptedListener::ACCEPTS = ( sub { $Developer::Dashboard::Web::Server::SSL_SHUTDOWN_REQUESTED = 1; $! = EINTR; return } );
    local $main::FORK_OVERRIDE = sub { return 991222 };
    no warnings 'redefine';
    local *IO::Socket::INET::new = sub { return Local::ScriptedListener->new };
    local *Developer::Dashboard::Web::Server::_stop_ssl_backend = sub { $reached++; return 1 };
    local *Developer::Dashboard::Web::Server::_wait_for_managed_child = sub { return 1 };
    is( $ssl_server->_serve_ssl_frontend($ssl_daemon), 1, 'SSL accept loop exits on EINTR after shutdown has been requested' );
    is( $reached, 1, 'SSL accept shutdown still stops its backend' );
}

{
    my $profile = File::Spec->catfile( $home, 'legacy-profile.crt' );
    _write_file( $profile, "placeholder certificate\n" );
    my $calls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::Web::Server::capture = sub {
        $calls++;
        return (
            "Basic Constraints: critical\n                CA:FALSE\n"
              . "Extended Key Usage:\n                TLS Web Server Authentication\n"
              . "Key Usage: critical\n                Digital Signature, Key Encipherment\n",
            '', 0,
        ) if $calls == 1;
        return ( '', 'verify rejected the fixture', 1 );
    };
    is(
        Developer::Dashboard::Web::Server::_ssl_cert_has_expected_profile($profile),
        0,
        'certificate profile rejects a failed openssl SAN verification command',
    );
}

done_testing;

__END__

=pod

=head1 NAME

t/88-web-server-coverage.t - branch and condition coverage for the PSGI web server wrapper

=head1 PURPOSE

This test is the executable contract for the failure and fallback arms of
C<Developer::Dashboard::Web::Server>: worker-count validation, listen-socket
reservation and close failures, the SSL frontend fork/accept loop, the raw
HTTP-to-HTTPS redirect helpers, SAN normalization, self-signed certificate
generation, the certificate directory's home resolution order, and certificate
profile verification. It drives every branch and condition those paths own,
including the ones that only appear when a socket, a pipe, a fork, or openssl
itself fails.

The home resolution cases matter because Windows exports no HOME variable: the
certificate helpers are driven here with HOME deleted and only USERPROFILE set,
then with only HOMEDRIVE and HOMEPATH set, and finally with no home variable at
all, where the failure must stay explicit instead of writing certificates into
an unrelated directory.

=head1 WHY IT EXISTS

The web server is the only module that owns transport failure handling for the
dashboard, and its error arms are exactly the code that never runs during a
normal serve. Without a dedicated test they stay unexercised, so a regression
in the cleanup path, the redirect fallback, or the certificate profile check
would ship silently. This file exists to keep those arms honest under the
repository's all-metric coverage gate rather than lowering the bar with
annotations.

=head1 WHEN TO USE

Use this file when changing listen-address reservation, the SSL frontend
proxy loop, signal-driven backend shutdown, HTTP-to-HTTPS redirect
construction, subject alternative name handling, or self-signed certificate
generation and validation.

=head1 HOW TO USE

Run C<prove -lv t/88-web-server-coverage.t> while iterating on the web server.
Keep it green under C<prove -lr t> and under the branch/condition coverage run
before release. It is fully hermetic: it works inside temporary homes and
loopback sockets, and it never touches the operator's real runtime directory.

=head1 WHAT USES IT

Developers during TDD, the full repository suite, and the Devel::Cover gate all
use this file to keep the web server's transport failure handling from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/88-web-server-coverage.t

Run the web server coverage contract by itself while changing transport code.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/88-web-server-coverage.t

Collect branch and condition coverage for the web server from this file alone.

Example 3:

  prove -lr t

Put the change back through the whole repository suite before release.

=cut

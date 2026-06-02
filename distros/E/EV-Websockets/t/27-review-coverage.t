use strict;
use warnings;
use Test::More;
use POSIX ();
use EV;
use EV::Websockets;

use if -d 'blib', lib => 'blib/lib', 'blib/arch';

EV::Websockets::_set_debug(1) if $ENV{EV_WS_DEBUG};

# Perform a raw WebSocket upgrade against $port and invoke $cb with the full
# raw HTTP response once the headers are in. Breaks the loop on failure.
sub raw_upgrade {
    my ($port, $cb) = @_;
    require IO::Socket::INET;
    require MIME::Base64;

    my $sock = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1', PeerPort => $port,
        Proto => 'tcp', Timeout => 5,
    );
    unless ($sock) { diag "raw TCP connect failed: $!"; EV::break; return; }

    my $key = MIME::Base64::encode_base64(pack("N4",
        12345, 23456, 34567, 45678), '');
    $sock->syswrite(
        "GET / HTTP/1.1\r\n"
      . "Host: 127.0.0.1:$port\r\n"
      . "Upgrade: websocket\r\n"
      . "Connection: Upgrade\r\n"
      . "Sec-WebSocket-Key: $key\r\n"
      . "Sec-WebSocket-Version: 13\r\n\r\n");

    my $resp = '';
    my $io; $io = EV::io($sock, EV::READ, sub {
        my $buf;
        my $n = $sock->sysread($buf, 4096);
        if ($n) {
            $resp .= $buf;
            if ($resp =~ /\r\n\r\n/) {
                undef $io; close $sock;
                $cb->($resp);
                my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
            }
        } else {
            undef $io; close $sock; EV::break;
        }
    });
}

# 1. ssl_init option: 0, 1, and auto-detect default all create a context.
{
    my $c0 = EV::Websockets::Context->new(ssl_init => 0);
    ok($c0, "context with ssl_init => 0");
    my $c1 = EV::Websockets::Context->new(ssl_init => 1);
    ok($c1, "context with ssl_init => 1");
    my $cd = EV::Websockets::Context->new();
    ok($cd, "context with default (auto-detect) ssl_init");
}

# 2. die inside on_error is caught/warned and does NOT recurse.
{
    my $ctx = EV::Websockets::Context->new();
    my @warnings;
    my $err_calls = 0;
    my %keep;

    local $SIG{__WARN__} = sub {
        push @warnings, $_[0];
        EV::break if $_[0] =~ /exception in error handler/;
    };

    $keep{cli} = $ctx->connect(
        url        => "ws://127.0.0.1:1",
        on_connect => sub { },
        on_error   => sub { $err_calls++; die "boom in on_error\n" },
    );

    my $to = EV::timer(5, 0, sub { diag "Timeout!"; EV::break });
    EV::run;

    is($err_calls, 1, "on_error invoked exactly once (no recursion)");
    ok((grep { /exception in error handler/ } @warnings),
       "die in on_error was warned, not fatal");
}

# 3. close() while still connecting is a documented no-op.
{
    my $ctx = EV::Websockets::Context->new();
    my %keep;
    my ($was_connecting, $state_after_close, $established, $closed);

    my $port = $ctx->listen(
        port       => 0,
        on_connect => sub { $keep{srv} = $_[0] },
        on_message => sub { },
        on_close   => sub { delete $keep{srv} },
    );

    $keep{cli} = $ctx->connect(
        url        => "ws://127.0.0.1:$port",
        on_connect => sub { $established = 1; $_[0]->close(1000) },
        on_message => sub { },
        on_close   => sub { $closed = 1; delete $keep{cli}; EV::break },
        on_error   => sub { delete $keep{cli}; EV::break },
    );

    $was_connecting    = $keep{cli}->is_connecting;
    $keep{cli}->close(1000);                 # no-op while connecting
    $state_after_close = $keep{cli}->state;

    my $to = EV::timer(10, 0, sub { diag "Timeout!"; EV::break });
    EV::run;

    ok($was_connecting, "is_connecting true immediately after connect()");
    is($state_after_close, "connecting",
       "close() while connecting did not change state");
    ok($established, "connection still established (close-while-connecting was a no-op)");
    ok($closed, "the real close() after on_connect did fire on_close");
}

# 4. Static listen(headers => {...}) are injected into the 101 response.
{
    my $ctx = EV::Websockets::Context->new();
    my %keep;
    my $found = 0;
    my $got101 = 0;

    my $port = $ctx->listen(
        port       => 0,
        headers    => { 'X-Static-Hdr' => 'static-val' },
        on_connect => sub { $keep{srv} = $_[0] },
        on_message => sub { },
        on_close   => sub { delete $keep{srv} },
    );

    my $t = EV::timer(0.1, 0, sub {
        raw_upgrade($port, sub {
            my ($resp) = @_;
            $got101 = 1 if $resp =~ m{^HTTP/1\.1 101};
            $found  = 1 if $resp =~ /X-Static-Hdr:\s*static-val/i;
        });
    });

    my $to = EV::timer(10, 0, sub { diag "Timeout!"; EV::break });
    EV::run;

    ok($got101, "raw client got a 101 response");
    ok($found, "static listen(headers => ...) injected into 101 response");
}

# 5. on_drain does NOT fire once close() has been queued.
{
    my $ctx = EV::Websockets::Context->new();
    my %keep;
    my ($drain_after_close, $closed) = (0, 0);

    my $port = $ctx->listen(
        port       => 0,
        on_connect => sub { $keep{srv} = $_[0] },
        on_message => sub { },
        on_close   => sub { delete $keep{srv} },
    );

    $keep{cli} = $ctx->connect(
        url        => "ws://127.0.0.1:$port",
        on_connect => sub {
            my ($c) = @_;
            $c->send("x" x 1024) for 1 .. 5;   # queue payload
            $c->close(1000);                    # then start closing
        },
        on_drain   => sub { $drain_after_close = 1 },
        on_message => sub { },
        on_close   => sub {
            $closed = 1; delete $keep{cli};
            my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
        },
        on_error   => sub { delete $keep{cli}; EV::break },
    );

    my $to = EV::timer(10, 0, sub { diag "Timeout!"; EV::break });
    EV::run;

    ok($closed, "connection closed after queue + close()");
    ok(!$drain_after_close, "on_drain suppressed once close() was queued");
}

# 6a. listen() reserved-name guard croaks and cleans up its callback SVs.
{
    my $ctx = EV::Websockets::Context->new();
    my $ok = eval {
        $ctx->listen(port => 0, name => 'default', on_message => sub { });
        1;
    };
    ok(!$ok, "listen(name => 'default') croaked");
    like($@, qr/reserved/i, "croak says the name is reserved");
}

# NOTE: the listen() bind-failure (RETVAL <= 0) path isn't driven here:
# colliding on an explicit port is unreliable under SO_REUSEPORT (the bind
# succeeds, and a 2-vhost-same-port context tickles an lws-internal teardown
# read). The vhost-creation-failure path (free_server_svs) is exercised by an
# unreadable-TLS-cert listen in t/28 (fork-contained) -- that path once
# SIGSEGV'd via OpenSSL's ERR path after a context had been destroyed, but the
# SSL keepalive fix resolved it. free_server_svs also runs on every successful
# listen() teardown via PROTOCOL_DESTROY.

# 7. Saving $conn inside on_error then dropping it must not crash.
#    Exercises the connect() failure path where perl_self is set during a
#    (possibly synchronous) connection error.
{
    my $ctx = EV::Websockets::Context->new();
    my $saved;
    my $err = 0;

    {
        my %keep;
        $keep{cli} = $ctx->connect(
            url        => "ws://127.0.0.1:1",
            on_connect => sub { },
            on_error   => sub { $saved = $_[0]; $err++; EV::break },
        );
        my $to = EV::timer(5, 0, sub { diag "Timeout!"; EV::break });
        EV::run;
    }

    ok($err, "on_error fired for refused connection");
    isa_ok($saved, 'EV::Websockets::Connection', "conn captured in on_error");
    is($saved->state, 'closed', "captured conn reports 'closed'");
    is($saved->send_queue_size, 0, "send_queue_size is 0 on closed conn (no croak)");
    $saved = undef;   # drop the last reference -> DESTROY
    pass("no crash after dropping the saved conn reference");
}

# 8. send_queue_size returns 0 (no croak) after the context is destroyed.
{
    my $conn;
    {
        my $ctx = EV::Websockets::Context->new();
        my %keep;
        my $port = $ctx->listen(
            port       => 0,
            on_connect => sub { $keep{srv} = $_[0] },
            on_message => sub { },
            on_close   => sub { delete $keep{srv} },
        );
        $keep{cli} = $ctx->connect(
            url        => "ws://127.0.0.1:$port",
            on_connect => sub { $conn = $_[0]; EV::break },
            on_error   => sub { EV::break },
        );
        my $to = EV::timer(10, 0, sub { diag "Timeout!"; EV::break });
        EV::run;
        # $ctx and %keep drop here -> Context::DESTROY -> conn becomes "closed"
    }

    ok($conn, "captured a live connection");
    is($conn->state, 'closed', "conn is 'closed' after context destroyed");
    is($conn->send_queue_size, 0, "send_queue_size returns 0 on closed conn");
    $conn = undef;
}

# 9. connections() excludes a still-connecting conn, includes it once open.
#    (get_protocol, peer_address and send_queue_size>0 happy paths are already
#    covered by t/18 and t/24; only the connecting-exclusion is untested.)
{
    my $ctx = EV::Websockets::Context->new();
    my %keep;
    my $port = $ctx->listen(
        port       => 0,
        on_connect => sub { $keep{srv} = $_[0] },
        on_message => sub { },
        on_close   => sub { delete $keep{srv} },
    );

    $keep{cli} = $ctx->connect(
        url        => "ws://127.0.0.1:$port",
        on_connect => sub { EV::break },
        on_error   => sub { EV::break },
    );

    my @during = $ctx->connections;   # synchronous: client is still "connecting"
    is(scalar(@during), 0, "connections() excludes a still-connecting conn");

    my $to = EV::timer(10, 0, sub { diag "Timeout!"; EV::break });
    EV::run;

    my @after = $ctx->connections;    # client + server endpoints now open
    ok(scalar(@after) >= 1, "connections() includes the established conn(s)");
    $keep{cli}->close(1000) if $keep{cli};
}

# 10. send_fragment binary path: binary fragments reassemble into one binary
#     message; $is_binary on continuation frames is ignored (type set by first).
{
    my $ctx = EV::Websockets::Context->new();
    my %keep;
    my ($got_data, $got_binary, $closed);

    my $port = $ctx->listen(
        port       => 0,
        on_connect => sub { $keep{srv} = $_[0] },
        on_message => sub {
            my ($c, $data, $is_binary) = @_;
            $got_data = $data; $got_binary = $is_binary;
            $c->close(1000);
        },
        on_close   => sub { delete $keep{srv} },
    );

    $keep{cli} = $ctx->connect(
        url        => "ws://127.0.0.1:$port",
        on_connect => sub {
            my ($c) = @_;
            $c->send_fragment("AB", 1, 0);   # binary, not final
            $c->send_fragment("CD", 0, 0);   # continuation ($is_binary ignored)
            $c->send_fragment("EF", 0, 1);   # continuation, final
        },
        on_message => sub { },
        on_close   => sub {
            $closed = 1; delete $keep{cli};
            my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
        },
        on_error   => sub { delete $keep{cli}; EV::break },
    );

    my $to = EV::timer(10, 0, sub { diag "Timeout!"; EV::break });
    EV::run;

    is($got_data, "ABCDEF", "binary fragments reassembled in order");
    ok($got_binary, "reassembled message reported as binary");
    ok($closed, "connection closed");
}

# 11. connections() includes a conn in the "closing" state (drain in progress).
{
    my $ctx = EV::Websockets::Context->new();
    my %keep;
    my ($closing_listed, $closed);

    my $port = $ctx->listen(
        port       => 0,
        on_connect => sub { $keep{srv} = $_[0] },
        on_message => sub { },
        on_close   => sub { delete $keep{srv} },
    );

    $keep{cli} = $ctx->connect(
        url        => "ws://127.0.0.1:$port",
        on_connect => sub {
            my ($c) = @_;
            $c->send("y" x 2048) for 1 .. 5;   # ensure the drain is not instant
            $c->close(1000);                    # -> state "closing"
            # synchronous: the conn keeps connected==1 during drain, so it is
            # still listed, now in the "closing" state.
            $closing_listed = grep { $_->state eq 'closing' } $ctx->connections;
        },
        on_message => sub { },
        on_close   => sub {
            $closed = 1; delete $keep{cli};
            my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
        },
        on_error   => sub { delete $keep{cli}; EV::break },
    );

    my $to = EV::timer(10, 0, sub { diag "Timeout!"; EV::break });
    EV::run;

    ok($closing_listed, "connections() includes a conn in 'closing' state");
    ok($closed, "connection closed");
}

# 12. die inside on_handshake rejects the connection (unlike other callbacks,
#     where a die is warned and the connection continues).
{
    my $ctx = EV::Websockets::Context->new();
    my %keep;
    my @warnings;
    my ($server_connected, $client_error) = (0, 0);

    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $port = $ctx->listen(
        port         => 0,
        on_handshake => sub { die "boom in on_handshake\n" },
        on_connect   => sub { $server_connected = 1; $keep{srv} = $_[0] },
        on_message   => sub { },
        on_close     => sub { delete $keep{srv} },
    );

    $keep{cli} = $ctx->connect(
        url        => "ws://127.0.0.1:$port",
        on_connect => sub { EV::break },               # should NOT happen
        on_error   => sub { $client_error = 1; delete $keep{cli}; EV::break },
        on_close   => sub { delete $keep{cli}; EV::break },
    );

    my $to = EV::timer(10, 0, sub { diag "Timeout!"; EV::break });
    EV::run;

    ok($client_error, "client on_error fired (handshake rejected by die)");
    ok(!$server_connected, "server on_connect did NOT fire (connection rejected)");
    ok((grep { /exception in on_handshake/ } @warnings),
       "die in on_handshake was warned");
}

# 13. IPv6 bracket-notation connect() URL. The bracket-parsing C path runs on
#     every platform (so this exercises host_header assembly, checkable under
#     valgrind); the round-trip is asserted only where IPv6 client connects
#     actually work, and skipped otherwise so it never fails spuriously.
{
    my $ctx = EV::Websockets::Context->new();
    my %keep;
    my ($got, $failed, $established);

    my $port = $ctx->listen(
        port       => 0,
        on_connect => sub { $keep{srv} = $_[0] },
        on_message => sub { my ($c, $d) = @_; $c->send("echo:$d") },
        on_close   => sub { delete $keep{srv} },
    );

    my $conn = eval {
        $ctx->connect(
            url        => "ws://[::1]:$port/",
            on_connect => sub { $established = 1; $_[0]->send("ipv6") },
            on_message => sub { $got = $_[1]; $_[0]->close(1000) },
            on_close   => sub { delete $keep{cli}; EV::break },
            on_error   => sub { $failed = 1; delete $keep{cli}; EV::break },
        );
    };
    ok(1, "connect() with a ws://[::1] bracket URL did not crash");

    SKIP: {
        skip "IPv6 client connect unavailable in this environment", 1 unless $conn;
        $keep{cli} = $conn;
        my $to = EV::timer(5, 0, sub { EV::break });
        EV::run;
        skip "IPv6 loopback did not establish here", 1 if $failed || !$established;
        is($got, "echo:ipv6", "IPv6 bracket URL connect round-tripped");
    }
}

done_testing;

POSIX::_exit(Test::More->builder->is_passing ? 0 : 1);

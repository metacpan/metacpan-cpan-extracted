use strict;
use warnings;
use Test::More;
use POSIX ();
use EV;
use EV::Websockets;

use if -d 'blib', lib => 'blib/lib', 'blib/arch';

EV::Websockets::_set_debug(1) if $ENV{EV_WS_DEBUG};

# 1. on_drain server-side: fires after server sends burst of messages
{
    my $ctx = EV::Websockets::Context->new();
    my $srv_drain_fired = 0;
    my %keep;

    my $port = $ctx->listen(
        port => 0,
        on_connect => sub {
            my ($c) = @_;
            $keep{srv} = $c;
            # Burst of messages to client
            $c->send("burst_$_") for 1..20;
        },
        on_drain => sub {
            $srv_drain_fired = 1;
        },
        on_message => sub { },
        on_close   => sub { delete $keep{srv} },
    );

    my $msg_count = 0;
    $keep{cli} = $ctx->connect(
        url => "ws://127.0.0.1:$port",
        on_connect => sub { },
        on_message => sub { $msg_count++ },
        on_drain => sub { },
        on_close => sub { delete $keep{cli}; EV::break },
        on_error => sub { delete $keep{cli}; EV::break },
    );

    # Give drain time to fire, then close
    my $closer; $closer = EV::timer(2, 0, sub {
        undef $closer;
        $keep{cli}->close(1000) if $keep{cli};
    });

    my $to = EV::timer(10, 0, sub { diag "Timeout!"; EV::break });
    EV::run;

    ok($srv_drain_fired, "server on_drain fired after burst send");
    ok($msg_count > 0, "client received messages from burst ($msg_count)");
}

# 2. send_fragment mid-stream close: close before final fragment
{
    my $ctx = EV::Websockets::Context->new();
    my $srv_close_fired = 0;
    my $no_crash = 1;
    my %keep;

    my $port = $ctx->listen(
        port => 0,
        on_connect => sub { $keep{srv} = $_[0] },
        on_message => sub { },
        on_close   => sub {
            $srv_close_fired = 1;
            delete $keep{srv};
        },
    );

    my $t = EV::timer(0.1, 0, sub {
        $keep{cli} = $ctx->connect(
            url => "ws://127.0.0.1:$port",
            on_connect => sub {
                my ($c) = @_;
                # Start fragmented message, not final
                $c->send_fragment("partial", 0, 0);
                # Close before sending final fragment
                $c->close(1000);
            },
            on_close => sub {
                delete $keep{cli};
                my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
            },
            on_error => sub { delete $keep{cli}; EV::break },
        );
    });

    my $to = EV::timer(10, 0, sub { diag "Timeout!"; EV::break });
    EV::run;

    ok($no_crash, "no crash after send_fragment + close without final");
    ok($srv_close_fired, "server on_close fired for mid-fragment close");
}

# 3. stash server-side: persists data between on_connect and on_message
{
    my $ctx = EV::Websockets::Context->new();
    my ($resp1, $resp2);
    my $phase = 0;
    my %keep;

    my $port = $ctx->listen(
        port => 0,
        on_connect => sub {
            my ($c) = @_;
            $keep{srv} = $c;
            $c->stash->{session_id} = 'abc-789';
            $c->stash->{msg_count}  = 0;
        },
        on_message => sub {
            my ($c, $data) = @_;
            $c->stash->{msg_count}++;
            $c->send("sid=" . $c->stash->{session_id}
                    . ",n=" . $c->stash->{msg_count});
        },
        on_close => sub { delete $keep{srv} },
    );

    $keep{cli} = $ctx->connect(
        url => "ws://127.0.0.1:$port",
        on_connect => sub { $_[0]->send("ping1") },
        on_message => sub {
            my ($c, $data) = @_;
            if ($phase == 0) {
                $resp1 = $data;
                $phase = 1;
                $c->send("ping2");
            } else {
                $resp2 = $data;
                $c->close(1000);
            }
        },
        on_close => sub {
            delete $keep{cli};
            my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
        },
        on_error => sub { delete $keep{cli}; EV::break },
    );

    my $to = EV::timer(10, 0, sub { diag "Timeout!"; EV::break });
    EV::run;

    is($resp1, "sid=abc-789,n=1",
       "first response has correct stash data");
    is($resp2, "sid=abc-789,n=2",
       "second response shows stash persisted across messages");
}

# 4. connect_timeout cancellation: successful connect does not fire timeout
{
    my $ctx = EV::Websockets::Context->new();
    my ($connected, $got_error, $roundtrip_ok);
    my %keep;

    my $port = $ctx->listen(
        port => 0,
        on_connect => sub { $keep{srv} = $_[0] },
        on_message => sub {
            my ($c, $data) = @_;
            $c->send("echo:$data");
        },
        on_close => sub { delete $keep{srv} },
    );

    my $t = EV::timer(0.1, 0, sub {
        $keep{cli} = $ctx->connect(
            url             => "ws://127.0.0.1:$port",
            connect_timeout => 5.0,
            on_connect => sub {
                my ($c) = @_;
                $connected = 1;
                $c->send("hello");
            },
            on_message => sub {
                my ($c, $data) = @_;
                $roundtrip_ok = ($data eq "echo:hello");
                $c->close(1000);
            },
            on_close => sub {
                delete $keep{cli};
                my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
            },
            on_error => sub {
                my ($c, $err) = @_;
                $got_error = $err;
                delete $keep{cli};
                EV::break;
            },
        );
    });

    my $to = EV::timer(10, 0, sub { diag "Timeout!"; EV::break });
    EV::run;

    ok($connected, "on_connect fired with connect_timeout set");
    ok(!$got_error, "on_error did NOT fire (timeout cancelled)");
    ok($roundtrip_ok, "send/receive works normally after connect");
}

# 5. on_handshake header injection end-to-end via raw TCP client
{
    my $ctx = EV::Websockets::Context->new();
    my $handshake_called = 0;
    my %keep;

    my $port = $ctx->listen(
        port => 0,
        on_handshake => sub {
            $handshake_called = 1;
            return { 'X-Custom' => 'test123' };
        },
        on_connect => sub { $keep{srv} = $_[0] },
        on_message => sub { },
        on_close   => sub { delete $keep{srv} },
    );

    my $raw_response = '';
    my $found_header = 0;

    my $t = EV::timer(0.1, 0, sub {
        require IO::Socket::INET;
        require MIME::Base64;

        my $sock = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1',
            PeerPort => $port,
            Proto    => 'tcp',
            Timeout  => 5,
        );
        unless ($sock) {
            diag "raw TCP connect failed: $!";
            EV::break;
            return;
        }

        # Proper WebSocket upgrade request with a valid key
        my $key = MIME::Base64::encode_base64(pack("N4",
            int(rand(2**32)), int(rand(2**32)),
            int(rand(2**32)), int(rand(2**32))), '');

        my $req = "GET / HTTP/1.1\r\n"
                . "Host: 127.0.0.1:$port\r\n"
                . "Upgrade: websocket\r\n"
                . "Connection: Upgrade\r\n"
                . "Sec-WebSocket-Key: $key\r\n"
                . "Sec-WebSocket-Version: 13\r\n"
                . "\r\n";

        $sock->syswrite($req);

        # Read raw 101 response
        my $io; $io = EV::io($sock, EV::READ, sub {
            my $buf;
            my $n = $sock->sysread($buf, 4096);
            if ($n) {
                $raw_response .= $buf;
                if ($raw_response =~ /\r\n\r\n/) {
                    $found_header = ($raw_response =~ /X-Custom:\s*test123/i) ? 1 : 0;
                    undef $io;
                    close $sock;
                    my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
                }
            } else {
                undef $io;
                close $sock;
                EV::break;
            }
        });
    });

    my $to = EV::timer(10, 0, sub { diag "Timeout!"; EV::break });
    EV::run;

    ok($handshake_called, "on_handshake was invoked");
    ok($raw_response =~ /^HTTP\/1\.1 101/, "got 101 response")
        or diag "Response: $raw_response";
    ok($found_header, "X-Custom: test123 header present in raw 101 response")
        or diag "Raw response headers:\n$raw_response";
}

done_testing;

POSIX::_exit(Test::More->builder->is_passing ? 0 : 1);

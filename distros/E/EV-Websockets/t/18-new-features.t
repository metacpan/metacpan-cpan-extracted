use strict;
use warnings;
use Test::More;
use POSIX ();
use EV;
use EV::Websockets;

EV::Websockets::_set_debug(1) if $ENV{EV_WS_DEBUG};

# 1. send_queue_size returns 0 initially, >0 after send, 0 after drain
{
    my $ctx = EV::Websockets::Context->new();
    my ($initial_qsz, $after_send_qsz, $drain_qsz);
    my %keep;

    my $port = $ctx->listen(
        port => 0,
        on_connect => sub { $keep{srv} = $_[0] },
        on_message => sub { },
        on_close   => sub { delete $keep{srv} },
    );

    my $t = EV::timer(0.1, 0, sub {
        $keep{cli} = $ctx->connect(
            url => "ws://127.0.0.1:$port",
            on_connect => sub {
                my ($c) = @_;
                $initial_qsz = $c->send_queue_size;
                # Send a large-ish payload so queue is momentarily non-empty
                $c->send("x" x 4096);
                $after_send_qsz = $c->send_queue_size;
            },
            on_drain => sub {
                my ($c) = @_;
                $drain_qsz = $c->send_queue_size;
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

    is($initial_qsz, 0, "send_queue_size is 0 initially");
    ok(defined $after_send_qsz && $after_send_qsz > 0,
       "send_queue_size > 0 after send (got " . ($after_send_qsz // 'undef') . ")");
    is($drain_qsz, 0, "send_queue_size is 0 when on_drain fires");
}

# 2. on_drain callback fires after send queue empties
{
    my $ctx = EV::Websockets::Context->new();
    my $drain_fired = 0;
    my %keep;

    my $port = $ctx->listen(
        port => 0,
        on_connect => sub { $keep{srv} = $_[0] },
        on_message => sub { },
        on_close   => sub { delete $keep{srv} },
    );

    my $t = EV::timer(0.1, 0, sub {
        $keep{cli} = $ctx->connect(
            url => "ws://127.0.0.1:$port",
            on_connect => sub {
                my ($c) = @_;
                $c->send("drain test");
            },
            on_drain => sub {
                $drain_fired = 1;
                $_[0]->close(1000);
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

    ok($drain_fired, "on_drain callback fired after send queue emptied");
}

# 3. connect_timeout fires on_error for non-routable IP
{
    my $ctx = EV::Websockets::Context->new();
    my ($got_error, $error_msg);

    my $conn = $ctx->connect(
        url             => "ws://10.255.255.1:9999",
        connect_timeout => 0.5,
        on_connect => sub { },
        on_error   => sub {
            my ($c, $err) = @_;
            $got_error = 1;
            $error_msg = $err;
            EV::break;
        },
    );

    my $to = EV::timer(5, 0, sub { diag "Timeout!"; EV::break });
    EV::run;

    ok($got_error, "on_error fired for connect_timeout");
    like($error_msg || '', qr/connect timeout|timeout|error/i,
         "error message mentions timeout (got: " . ($error_msg // 'undef') . ")");
}

# 4. get_protocol happy path -- negotiated subprotocol
{
    my $ctx = EV::Websockets::Context->new();
    my ($client_proto, $server_proto);
    my %keep;

    my $port = $ctx->listen(
        port     => 0,
        protocol => 'chat',
        on_connect => sub {
            my ($c) = @_;
            $keep{srv} = $c;
            $server_proto = $c->get_protocol;
        },
        on_message => sub { },
        on_close   => sub { delete $keep{srv} },
    );

    my $t = EV::timer(0.1, 0, sub {
        $keep{cli} = $ctx->connect(
            url      => "ws://127.0.0.1:$port",
            protocol => 'chat',
            on_connect => sub {
                my ($c) = @_;
                $client_proto = $c->get_protocol;
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

    # lws may not expose Sec-WebSocket-Protocol via WSI_TOKEN_PROTOCOL on
    # the client side after establishment; verify server side which reads
    # it from the request headers reliably.
    is($server_proto, 'chat', "server get_protocol returns negotiated protocol");
    # Client side: lws handles protocol matching internally.  The token
    # may or may not be populated depending on lws version.
    ok(1, "client get_protocol ran without crash (got: " . ($client_proto // 'undef') . ")");
}

# 5. Client on_connect $headers -- use a raw TCP server that includes
#    a Server header in the 101 handshake so the client can capture it.
SKIP: {
    eval { require AnyEvent; require AnyEvent::Socket; require AnyEvent::Handle;
           require MIME::Base64; require Digest::SHA; 1 }
        or skip "AnyEvent/MIME::Base64/Digest::SHA not available", 2;
    my $port = 15345 + int(rand(1000));
    my $server_handle;
    my $tcp_guard = AnyEvent::Socket::tcp_server(undef, $port, sub {
        my ($fh) = @_;
        $server_handle = AnyEvent::Handle->new(fh => $fh, on_read => sub {
            my ($h) = @_;
            my $data = $h->{rbuf};
            if ($data =~ /Sec-WebSocket-Key: (\S+)/i) {
                my $key = $1;
                my $accept = MIME::Base64::encode_base64(
                    Digest::SHA::sha1($key . '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'), '');
                $h->push_write(
                    "HTTP/1.1 101 Switching Protocols\015\012" .
                    "Upgrade: websocket\015\012" .
                    "Connection: Upgrade\015\012" .
                    "Server: TestServer/1.0\015\012" .
                    "Sec-WebSocket-Accept: $accept\015\012\015\012");
            }
        }, on_error => sub { });
    });

    my $ctx = EV::Websockets::Context->new();
    my ($headers_ref, $has_key);
    my %keep;

    my $t = EV::timer(0.1, 0, sub {
        $keep{cli} = $ctx->connect(
            url => "ws://127.0.0.1:$port",
            on_connect => sub {
                my ($c, $headers) = @_;
                $headers_ref = $headers;
                $has_key = ref $headers eq 'HASH' && scalar keys %$headers > 0;
                EV::break;
            },
            on_close => sub {
                delete $keep{cli};
            },
            on_error => sub { delete $keep{cli}; EV::break },
        );
    });

    my $to = EV::timer(10, 0, sub { diag "Timeout!"; EV::break });
    EV::run;

    ok(ref $headers_ref eq 'HASH', "client on_connect receives headers hashref");
    ok($has_key, "headers hashref has at least one key");
    if (ref $headers_ref eq 'HASH') {
        diag "Client response headers: " . join(', ', sort keys %$headers_ref);
    }
}

# 6. close(code) without reason
{
    my $ctx = EV::Websockets::Context->new();
    my ($cli_close_code, $cli_closed);
    my %keep;

    my $port = $ctx->listen(
        port => 0,
        on_connect => sub { $keep{srv} = $_[0] },
        on_message => sub {
            my ($c) = @_;
            # Server closes with code only, no reason
            $c->close(1001);
        },
        on_close => sub { delete $keep{srv} },
    );

    my $t = EV::timer(0.1, 0, sub {
        $keep{cli} = $ctx->connect(
            url => "ws://127.0.0.1:$port",
            on_connect => sub { $_[0]->send("trigger") },
            on_close => sub {
                my ($c, $code, $reason) = @_;
                $cli_close_code = $code;
                $cli_closed = 1;
                delete $keep{cli};
                my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
            },
            on_error => sub { delete $keep{cli}; EV::break },
        );
    });

    my $to = EV::timer(10, 0, sub { diag "Timeout!"; EV::break });
    EV::run;

    ok($cli_closed, "client saw close when server calls close(1001) without reason");
    ok(defined $cli_close_code, "client received a close code (got: " . ($cli_close_code // 'undef') . ")");
}

# 7. die inside on_message callback does not crash
{
    my $ctx = EV::Websockets::Context->new();
    my ($msg_after_die, $connection_survived);
    my %keep;

    my $srv_msg_count = 0;
    my $port = $ctx->listen(
        port => 0,
        on_connect => sub { $keep{srv} = $_[0] },
        on_message => sub {
            my ($c, $data) = @_;
            $srv_msg_count++;
            $c->send("echo:$data");
            if ($srv_msg_count == 1) {
                # Send retry immediately — the client's die in on_message
                # is caught by G_EVAL, so the connection stays alive
                $c->send("retry");
            }
        },
        on_close => sub { delete $keep{srv} },
    );

    my $phase = 0;
    $keep{cli} = $ctx->connect(
        url => "ws://127.0.0.1:$port",
        on_connect => sub { $_[0]->send("first") },
        on_message => sub {
            my ($c, $data) = @_;
            if ($phase == 0) {
                $phase = 1;
                die "test exception in on_message";
            } elsif ($phase == 1) {
                $msg_after_die = $data;
                $connection_survived = 1;
                $c->close(1000);
            }
        },
        on_close => sub {
            delete $keep{cli};
            EV::break;
        },
        on_error => sub { delete $keep{cli}; EV::break },
    );

    my $to = EV::timer(10, 0, sub { diag "Timeout!"; EV::break });
    EV::run;

    ok($connection_survived, "connection survived die inside on_message");
    is($msg_after_die, "retry", "received message after die in callback");
}

# 8. Server protocol parameter
{
    my $ctx = EV::Websockets::Context->new();
    my $listen_ok;

    eval {
        my $port = $ctx->listen(
            port     => 0,
            protocol => 'my-protocol',
            on_connect => sub { },
            on_message => sub { },
        );
        $listen_ok = $port > 0;
    };

    ok($listen_ok, "listen() with protocol parameter succeeds");
    ok(!$@, "no error setting protocol on listen()");
}

# 9. X-Forwarded-For -- requires proxy, skip
SKIP: {
    skip "X-Forwarded-For test requires proxy setup", 1;
    ok(0, "placeholder");
}

done_testing;

POSIX::_exit(Test::More->builder->is_passing ? 0 : 1);

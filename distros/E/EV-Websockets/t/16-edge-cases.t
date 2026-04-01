use strict;
use warnings;
use Test::More;
use POSIX ();
use EV;
use EV::Websockets;

# Edge case tests for paths that could silently regress.
# Uses minimal context creation to avoid lws multi-context issues.

# Shared context for tests 1-5
my $ctx = EV::Websockets::Context->new();

# 1. Sequential connection reuse after failure
{
    my $port = $ctx->listen(
        port => 0,
        on_connect => sub {},
        on_message => sub { $_[0]->send("ok") },
    );

    my ($err1, $err2, $got_msg);
    my %keep;

    my $t1 = EV::timer(0.1, 0, sub {
        $keep{c1} = $ctx->connect(
            url => "ws://127.0.0.1:1",
            on_error => sub { $err1 = $_[1]; delete $keep{c1} },
        );
    });

    my $t2 = EV::timer(1.0, 0, sub {
        $keep{c2} = $ctx->connect(
            url => "ws://127.0.0.1:$port",
            on_connect => sub { $_[0]->send("ping") },
            on_message => sub {
                $got_msg = $_[1];
                $_[0]->close(1000);
            },
            on_close => sub {
                delete $keep{c2};
                my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
            },
            on_error => sub { $err2 = $_[1]; delete $keep{c2}; EV::break },
        );
    });

    my $to = EV::timer(10, 0, sub { EV::break });
    EV::run;

    ok(defined $err1, "first connection failed as expected");
    ok(!defined $err2, "second connection did not error");
    is($got_msg, "ok", "second connection worked after first failure");
}

# 2. Server on_connect without storing $_[0]
{
    my $srv_msg;
    my %keep;

    my $port = $ctx->listen(
        port => 0,
        on_connect => sub {},
        on_message => sub {
            my ($c, $data) = @_;
            $srv_msg = $data;
            $c->send("echo:$data");
        },
    );

    my $t = EV::timer(0.1, 0, sub {
        $keep{c} = $ctx->connect(
            url => "ws://127.0.0.1:$port",
            on_connect => sub { $_[0]->send("test") },
            on_message => sub { $_[0]->close(1000) },
            on_close => sub {
                delete $keep{c};
                my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
            },
            on_error => sub { delete $keep{c}; EV::break },
        );
    });

    my $to = EV::timer(10, 0, sub { EV::break });
    EV::run;

    is($srv_msg, "test", "server received message without storing conn in on_connect");
}

# 3. state() returns "closed" during on_close
{
    my ($close_state, $close_is_connected);
    my %keep;

    my $port = $ctx->listen(
        port => 0,
        on_connect => sub { $keep{s} = $_[0] },
        on_message => sub { $_[0]->send("ack") },
        on_close => sub { delete $keep{s} },
    );

    my $t = EV::timer(0.1, 0, sub {
        $keep{c} = $ctx->connect(
            url => "ws://127.0.0.1:$port",
            on_connect => sub { $_[0]->send("x") },
            on_message => sub { $_[0]->close(1000) },
            on_close => sub {
                my ($c) = @_;
                $close_state = $c->state;
                $close_is_connected = $c->is_connected;
                delete $keep{c};
                my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
            },
            on_error => sub { delete $keep{c}; EV::break },
        );
    });

    my $to = EV::timer(10, 0, sub { EV::break });
    EV::run;

    is($close_state, "closed", "state() is 'closed' during on_close");
    ok(!$close_is_connected, "is_connected is false during on_close");
}

# 4. send() after close() should croak
{
    my $send_after_close_err;
    my %keep;

    my $port = $ctx->listen(
        port => 0,
        on_connect => sub { $keep{s} = $_[0] },
        on_message => sub { $_[0]->send("ack") },
        on_close => sub { delete $keep{s} },
    );

    my $t = EV::timer(0.1, 0, sub {
        $keep{c} = $ctx->connect(
            url => "ws://127.0.0.1:$port",
            on_connect => sub {
                my ($c) = @_;
                $c->close(1000);
                eval { $c->send("after close") };
                $send_after_close_err = $@;
            },
            on_close => sub {
                delete $keep{c};
                my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
            },
            on_error => sub { delete $keep{c}; EV::break },
        );
    });

    my $to = EV::timer(10, 0, sub { EV::break });
    EV::run;

    like($send_after_close_err, qr/not open/, "send after close croaks");
}

# 5. peer_address and get_protocol on closed connection return undef
{
    my ($closed_peer, $closed_proto);
    my %keep;

    my $port = $ctx->listen(
        port => 0,
        on_connect => sub { $keep{s} = $_[0] },
        on_close => sub { delete $keep{s} },
    );

    my $t = EV::timer(0.1, 0, sub {
        $keep{c} = $ctx->connect(
            url => "ws://127.0.0.1:$port",
            on_connect => sub { $_[0]->close(1000) },
            on_close => sub {
                my ($c) = @_;
                $closed_peer = $c->peer_address;
                $closed_proto = $c->get_protocol;
                delete $keep{c};
                my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
            },
            on_error => sub { delete $keep{c}; EV::break },
        );
    });

    my $to = EV::timer(10, 0, sub { EV::break });
    EV::run;

    ok(!defined $closed_peer, "peer_address returns undef on closed connection");
    ok(!defined $closed_proto, "get_protocol returns undef on closed connection");
}

# Drop the shared context before test 6
undef $ctx;

# 6. Context destroy from inside on_message (alive_flag test)
{
    my $ctx2 = EV::Websockets::Context->new();
    my ($msg_received, $destroyed_ok);
    my %keep;

    my $port = $ctx2->listen(
        port => 0,
        on_connect => sub { $keep{s} = $_[0] },
        on_message => sub { $_[0]->send("ack") },
        on_close => sub { delete $keep{s} },
    );

    my $t = EV::timer(0.1, 0, sub {
        $keep{c} = $ctx2->connect(
            url => "ws://127.0.0.1:$port",
            on_connect => sub { $_[0]->send("boom") },
            on_message => sub {
                $msg_received = 1;
                %keep = ();
                undef $ctx2;
                $destroyed_ok = 1;
                EV::break;
            },
            on_error => sub { %keep = (); EV::break },
        );
    });

    my $to = EV::timer(10, 0, sub { EV::break });
    EV::run;

    ok($msg_received, "message received before context destroy");
    ok($destroyed_ok, "context destroyed from inside on_message without crash");
}

done_testing;

# Avoid SEGV during global destruction
POSIX::_exit(Test::More->builder->is_passing ? 0 : 1);

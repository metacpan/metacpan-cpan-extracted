use strict;
use warnings;
use Test::More;
use EV;
use EV::Websockets;

EV::Websockets::_set_debug(1) if $ENV{EV_WS_DEBUG};

# Coverage gaps surfaced in code review:
# - die in on_close / on_pong / on_drain caught by G_EVAL
# - peer_address on a live connected conn returns a string
# - get_protocol returns undef when no subprotocol negotiated
# - is_connecting returns true before handshake completes
# - stash() croaks after the connection is destroyed

# 1. is_connecting true synchronously after connect()
{
    my $ctx = EV::Websockets::Context->new;
    my %keep;
    my $port = $ctx->listen(
        port => 0,
        on_connect => sub { $keep{srv} = $_[0] },
        on_message => sub { },
        on_close => sub { delete $keep{srv} },
    );
    my $conn = $ctx->connect(
        url => "ws://127.0.0.1:$port",
        on_connect => sub { $_[0]->close(1000); EV::break },
        on_error => sub { EV::break },
    );
    ok($conn->is_connecting, "is_connecting true before handshake");
    ok(!$conn->is_connected, "is_connected false before handshake");
    is($conn->state, "connecting", "state == 'connecting' before handshake");
    my $to = EV::timer(5, 0, sub { diag "timeout"; EV::break });
    EV::run;
}

# 2. peer_address on live conn + get_protocol undef when none negotiated
{
    my $ctx = EV::Websockets::Context->new;
    my ($srv_peer, $cli_proto, $srv_proto);
    my %keep;
    my $port = $ctx->listen(
        port => 0,
        on_connect => sub {
            my ($c) = @_;
            $keep{srv} = $c;
            $srv_peer  = $c->peer_address;
            $srv_proto = $c->get_protocol;
        },
        on_message => sub { $_[0]->close(1000) },
        on_close => sub { delete $keep{srv} },
    );
    $keep{cli} = $ctx->connect(
        url => "ws://127.0.0.1:$port",
        on_connect => sub {
            $cli_proto = $_[0]->get_protocol;
            $_[0]->send("hi");
        },
        on_close => sub { delete $keep{cli}; EV::break },
        on_error => sub { delete $keep{cli}; EV::break },
    );
    my $to = EV::timer(5, 0, sub { diag "timeout"; EV::break });
    EV::run;
    ok(defined $srv_peer && length $srv_peer,
       "peer_address on live conn returned: " . ($srv_peer // 'undef'));
    like($srv_peer // '', qr/^(127\.0\.0\.1|::1|::ffff:127\.0\.0\.1)$/,
        "peer_address looks like a loopback address");
    ok(!defined $cli_proto, "client get_protocol undef when none negotiated");
    ok(!defined $srv_proto, "server get_protocol undef when none negotiated");
}

# 3. die in on_pong is caught and connection survives
{
    my $ctx = EV::Websockets::Context->new;
    my ($pong_seen, $survived);
    my %keep;
    my $port = $ctx->listen(
        port => 0,
        on_connect => sub { $keep{srv} = $_[0] },
        on_message => sub { $_[0]->send("ack:" . $_[1]) },
        on_close => sub { delete $keep{srv} },
    );
    $keep{cli} = $ctx->connect(
        url => "ws://127.0.0.1:$port",
        on_connect => sub { $_[0]->send_ping("ping") },
        on_pong => sub {
            $pong_seen = 1;
            $_[0]->send("after_pong");
            die "intentional die in on_pong";
        },
        on_message => sub {
            $survived = 1 if $_[1] eq "ack:after_pong";
            $_[0]->close(1000);
        },
        on_close => sub { delete $keep{cli}; EV::break },
        on_error => sub { delete $keep{cli}; EV::break },
    );
    my $to = EV::timer(5, 0, sub { diag "timeout"; EV::break });
    {
        local $SIG{__WARN__} = sub { };  # silence the caught warning
        EV::run;
    }
    ok($pong_seen, "on_pong fired");
    ok($survived, "connection survived die in on_pong");
}

# 4. die in on_drain is caught and connection survives
{
    my $ctx = EV::Websockets::Context->new;
    my ($drain_seen, $survived);
    my %keep;
    my $port = $ctx->listen(
        port => 0,
        on_connect => sub { $keep{srv} = $_[0] },
        on_message => sub { $_[0]->send("ack") },
        on_close => sub { delete $keep{srv} },
    );
    $keep{cli} = $ctx->connect(
        url => "ws://127.0.0.1:$port",
        on_connect => sub { $_[0]->send("x" x 4096) },
        on_drain => sub {
            $drain_seen = 1;
            die "intentional die in on_drain";
        },
        on_message => sub {
            $survived = 1 if $_[1] eq "ack";
            $_[0]->close(1000);
        },
        on_close => sub { delete $keep{cli}; EV::break },
        on_error => sub { delete $keep{cli}; EV::break },
    );
    my $to = EV::timer(5, 0, sub { diag "timeout"; EV::break });
    {
        local $SIG{__WARN__} = sub { };
        EV::run;
    }
    ok($drain_seen, "on_drain fired");
    ok($survived, "connection survived die in on_drain");
}

# 5. die in on_close is caught and warned via the G_EVAL warn path
{
    my $ctx = EV::Websockets::Context->new;
    my ($close_seen, $warn_text) = (0, "");
    my %keep;
    my $port = $ctx->listen(
        port => 0,
        on_connect => sub { $keep{srv} = $_[0]; $_[0]->close(1001, "bye") },
        on_message => sub { },
        on_close => sub { delete $keep{srv} },
    );
    $keep{cli} = $ctx->connect(
        url => "ws://127.0.0.1:$port",
        on_connect => sub { },
        on_message => sub { },
        on_close => sub {
            $close_seen = 1;
            delete $keep{cli};
            my $t; $t = EV::timer(0.05, 0, sub { undef $t; EV::break });
            die "intentional die in on_close";
        },
        on_error => sub { delete $keep{cli}; EV::break },
    );
    my $to = EV::timer(5, 0, sub { diag "timeout"; EV::break });
    {
        local $SIG{__WARN__} = sub { $warn_text .= $_[0] };
        EV::run;
    }
    ok($close_seen, "on_close fired");
    like($warn_text, qr/exception in close handler/,
        "G_EVAL warned 'exception in close handler'");
    like($warn_text, qr/intentional die in on_close/,
        "warn carries the die message");
}

# 6. die in on_connect is caught and connection survives
{
    my $ctx = EV::Websockets::Context->new;
    my ($connect_seen, $msg_after, $warn_text) = (0, undef, "");
    my %keep;
    my $port = $ctx->listen(
        port => 0,
        on_connect => sub { $keep{srv} = $_[0] },
        on_message => sub { $_[0]->send("ack:" . $_[1]) },
        on_close => sub { delete $keep{srv} },
    );
    $keep{cli} = $ctx->connect(
        url => "ws://127.0.0.1:$port",
        on_connect => sub {
            $connect_seen = 1;
            $_[0]->send("after_connect");
            die "intentional die in on_connect";
        },
        on_message => sub {
            $msg_after = $_[1];
            $_[0]->close(1000);
        },
        on_close => sub { delete $keep{cli}; EV::break },
        on_error => sub { delete $keep{cli}; EV::break },
    );
    my $to = EV::timer(5, 0, sub { diag "timeout"; EV::break });
    {
        local $SIG{__WARN__} = sub { $warn_text .= $_[0] };
        EV::run;
    }
    ok($connect_seen, "on_connect fired");
    like($warn_text, qr/exception in connect handler/,
        "G_EVAL warned 'exception in connect handler'");
    is($msg_after, "ack:after_connect",
        "connection survived die in on_connect and round-tripped a message");
}

# 7. stash() croaks after the connection is destroyed
{
    my $ctx = EV::Websockets::Context->new;
    my ($conn_after, %keep);
    my $port = $ctx->listen(
        port => 0,
        on_connect => sub { $keep{srv} = $_[0] },
        on_message => sub { $_[0]->close(1000) },
        on_close => sub { delete $keep{srv} },
    );
    $keep{cli} = $ctx->connect(
        url => "ws://127.0.0.1:$port",
        on_connect => sub { $_[0]->send("done") },
        on_close => sub {
            $conn_after = $_[0];        # keep a strong ref past EV::run
            delete $keep{cli};
            my $t; $t = EV::timer(0.1, 0, sub { undef $t; EV::break });
        },
        on_error => sub { delete $keep{cli}; EV::break },
    );
    my $to = EV::timer(5, 0, sub { diag "timeout"; EV::break });
    EV::run;
    undef $ctx;
    # $conn_after is still a Perl-side EV::Websockets::Connection object;
    # the wsi is gone but stash() should still work on it (state="closed").
    # The destroyed-magic croak fires only after the C struct is freed,
    # which happens when the last Perl ref drops. We can verify the
    # already-closed-but-not-destroyed branch:
    ok(eval { $conn_after->stash; 1 }, "stash on closed-but-alive conn returns hashref");
    is(ref $conn_after->stash, "HASH", "stash hashref persists across close");
}

done_testing;

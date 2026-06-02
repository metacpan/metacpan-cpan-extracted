use strict;
use warnings;
use Test::More;
use POSIX ();
use EV;
use EV::Websockets;

use if -d 'blib', lib => 'blib/lib', 'blib/arch';

EV::Websockets::_set_debug(1) if $ENV{EV_WS_DEBUG};

# Control-frame payloads are capped at 125 bytes (RFC 6455 5.5); send_ping /
# send_pong silently truncate. Verify the truncation at the wire.

# 1. send_pong: an oversized unsolicited PONG arrives truncated to 125 bytes.
{
    my $ctx = EV::Websockets::Context->new();
    my %keep;
    my ($srv_pong_len, $closed);
    my $port = $ctx->listen(
        port       => 0,
        on_connect => sub { $keep{srv} = $_[0] },
        on_pong    => sub { my ($c, $p) = @_; $srv_pong_len = length($p); $c->send("ack") },
        on_message => sub { },
        on_close   => sub { delete $keep{srv} },
    );
    $keep{cli} = $ctx->connect(
        url        => "ws://127.0.0.1:$port",
        on_connect => sub { $_[0]->send_pong("Z" x 200) },   # 200 -> 125
        on_message => sub { $_[0]->close(1000) },            # got ack -> done
        on_close   => sub {
            $closed = 1; delete $keep{cli};
            my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
        },
        on_error   => sub { delete $keep{cli}; EV::break },
    );
    my $to = EV::timer(10, 0, sub { diag "Timeout"; EV::break });
    EV::run;
    ok($closed, "send_pong: round-trip completed");
    is($srv_pong_len, 125, "send_pong truncates an oversized payload to 125 bytes");
}

# 2. send_ping: an oversized PING is truncated to 125; the peer's automatic
#    PONG echoes the (already truncated) payload back.
{
    my $ctx = EV::Websockets::Context->new();
    my %keep;
    my ($cli_pong_len, $closed);
    my $port = $ctx->listen(
        port       => 0,
        on_connect => sub { $keep{srv} = $_[0] },
        on_message => sub { },
        on_close   => sub { delete $keep{srv} },
    );
    $keep{cli} = $ctx->connect(
        url        => "ws://127.0.0.1:$port",
        on_connect => sub { $_[0]->send_ping("Q" x 200) },   # 200 -> 125, peer PONGs it
        on_pong    => sub { my ($c, $p) = @_; $cli_pong_len = length($p); $c->close(1000) },
        on_message => sub { },
        on_close   => sub {
            $closed = 1; delete $keep{cli};
            my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
        },
        on_error   => sub { delete $keep{cli}; EV::break },
    );
    my $to = EV::timer(10, 0, sub { diag "Timeout"; EV::break });
    EV::run;
    ok($closed, "send_ping: round-trip completed");
    is($cli_pong_len, 125, "send_ping truncates to 125 (echoed in the auto-PONG)");
}

done_testing;

POSIX::_exit(Test::More->builder->is_passing ? 0 : 1);

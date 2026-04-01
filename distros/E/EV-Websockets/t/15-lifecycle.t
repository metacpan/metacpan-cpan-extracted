use strict;
use warnings;
use Test::More;
use EV;
use EV::Websockets;

# Test lifecycle: context DESTROY with live connections,
# is_connected/is_connecting states, connection state after close

my $ctx = EV::Websockets::Context->new();
my (%keep, $state_connecting, $state_connected, $state_after_close);

my $port = $ctx->listen(
    port => 0,
    on_connect => sub { $keep{srv} = $_[0] },
    on_message => sub { $_[0]->send("ack") },
    on_close => sub { delete $keep{srv} },
);

my $start = EV::timer(0.1, 0, sub {
    my $c = $ctx->connect(
        url => "ws://127.0.0.1:$port",
        on_connect => sub {
            my ($c) = @_;
            $state_connected = $c->state;
            ok($c->is_connected, "is_connected true after connect");
            ok(!$c->is_connecting, "is_connecting false after connect");
            $c->send("test");
        },
        on_message => sub {
            my ($c) = @_;
            $c->close(1000);
        },
        on_close => sub {
            my ($c) = @_;
            $state_after_close = $c->state;
            $keep{cli} = undef;
            my $t; $t = EV::timer(0.3, 0, sub { undef $t; EV::break });
        },
        on_error => sub { EV::break },
    );
    $keep{cli} = $c;
    # Check state right after connect() returns (before handshake completes)
    $state_connecting = $c->state;
});

my $to = EV::timer(10, 0, sub { diag "Timeout"; EV::break });
EV::run;

is($state_connecting, "connecting", "state is 'connecting' right after connect()");
is($state_connected, "connected", "state is 'connected' in on_connect");
like($state_after_close, qr/clos/, "state is closing/closed in on_close");

# Test context DESTROY with orphaned connection reference
{
    my $ctx2 = EV::Websockets::Context->new();
    my $port2 = $ctx2->listen(
        port => 0,
        on_connect => sub {},
        on_message => sub {},
    );
    # Create a connection and keep the reference
    my $orphan = $ctx2->connect(
        url => "ws://127.0.0.1:$port2",
        on_error => sub {},
    );
    # Destroy context while connection is connecting
    undef $ctx2;
    # orphan should now be in a safe state
    is($orphan->state, "closed", "orphaned connection state is 'closed' after context destroy");
    ok(!$orphan->is_connected, "orphaned connection is not connected");
    # calling close on orphan should not crash
    $orphan->close(1000);
    pass("close on orphaned connection did not crash");
}

done_testing;

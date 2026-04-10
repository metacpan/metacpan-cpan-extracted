#!/usr/bin/env perl
# Auto-reconnect with subscription restore
use strict;
use warnings;
use EV;
use EV::Nats;

my $nats = EV::Nats->new(
    host                   => $ENV{NATS_HOST} // '127.0.0.1',
    port                   => $ENV{NATS_PORT} // 4222,
    reconnect              => 1,
    reconnect_delay        => 2000,
    max_reconnect_attempts => 0, # unlimited
    on_error   => sub { warn "error: @_\n" },
    on_connect => sub {
        print "connected (subscriptions auto-restored)\n";
    },
    on_disconnect => sub {
        print "disconnected, will reconnect...\n";
    },
);

# subscribe before connect — will be sent on first connect and restored on reconnect
$nats->subscribe('heartbeat', sub {
    my ($subject, $payload) = @_;
    print "heartbeat: $payload\n";
});

# periodic publish
my $n = 0;
my $t; $t = EV::timer 1, 1, sub {
    if ($nats->is_connected) {
        $nats->publish('heartbeat', "beat-" . ++$n);
    }
};

print "running (kill nats-server to test reconnect)...\n";
EV::run;

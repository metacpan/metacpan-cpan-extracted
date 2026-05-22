#!/usr/bin/env perl
# auto_reconnect — recover from a dropped connection with exponential backoff.
#
# Force a disconnect (e.g. KILL CONNECTION on the server, or restart it)
# while this script is running and watch the queries land after the
# connection comes back.
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $ch;
my $reconnect_count = 0;

$ch = EV::ClickHouse->new(
    host                 => $ENV{CLICKHOUSE_HOST} // $ENV{TEST_CLICKHOUSE_HOST} // '127.0.0.1',
    port                 => $ENV{CLICKHOUSE_NATIVE_PORT} // $ENV{TEST_CLICKHOUSE_NATIVE_PORT} // 9000,
    protocol             => 'native',
    auto_reconnect       => 1,
    reconnect_delay      => 0.5,
    reconnect_max_delay  => 5,
    on_connect    => sub {
        $reconnect_count++;
        printf "[%s] connected (#%d)\n", scalar(localtime), $reconnect_count;
    },
    on_disconnect => sub {
        printf "[%s] disconnected — auto_reconnect will retry\n", scalar(localtime);
    },
    on_error      => sub { warn "  error: $_[0]\n" },
);

# Send a query every second forever. Queries queued during a disconnect
# are preserved and dispatched on the new connection.
my $tick = 0;
my $w = EV::timer(0, 1, sub {
    $tick++;
    $ch->query("select $tick as tick", sub {
        my ($rows, $err) = @_;
        return if $err;
        printf "  tick %d: %d\n", $tick, $rows->[0][0];
    });
});

# Stop after 30 seconds.
EV::timer(30, 0, sub { $ch->finish; EV::break });

EV::run;

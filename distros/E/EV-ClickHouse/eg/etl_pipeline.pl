#!/usr/bin/env perl
# ETL pipeline pattern: producer pushes rows into an insert_streamer with
# high_water backpressure; the streamer batches and dispatches inserts via
# a connection pool. Each batch carries an idempotent token so the server
# deduplicates a batch that lands twice. Demonstrates the reliable-ingest
# shape:
#
#   producer ---push_row---> Streamer (batch + high_water)
#                           |
#                           v
#                       insert (idempotent token per batch)
#
# The `idempotent` option must be passed to insert_streamer (it is per-insert
# settings) - putting it on the Pool constructor would send it as an unknown
# server setting.
#
# Requires the target table:
#   create table events (id UInt64, name String) engine=Memory;
#
# Set CLICKHOUSE_HOST / CLICKHOUSE_NATIVE_PORT to point at a real CH.
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $host  = $ENV{CLICKHOUSE_HOST}        // '127.0.0.1';
my $nport = $ENV{CLICKHOUSE_NATIVE_PORT} // 9000;

my $pool = EV::ClickHouse::Pool->new(
    host => $host, port => $nport, protocol => 'native',
    size => 4,
);

# Each member has its own streamer. We pin the streamer to one member so
# back-to-back batches go through the same connection (preserves the
# server-side dedup window).
my @members  = $pool->conns;
my @streamers;
my $pause    = 0;          # backpressure flag the producer respects
for my $ch (@members) {
    push @streamers, $ch->insert_streamer('events',
        batch_size      => 5_000,
        high_water      => 20_000,
        settings        => { idempotent => 1 },   # per-batch dedup token
        on_high_water   => sub {
            my ($buffered, $in_flight) = @_;
            warn "[backpressure] buffered=$buffered in_flight=$in_flight\n";
            $pause = 1;
        },
    );
}

# Producer side - in a real ETL this would be reading from Kafka/files/etc.
my $produced = 0;
my $target   = 1_000_000;
my $producer; $producer = EV::idle(sub {
    return if $pause;
    my $i = $produced++;
    $streamers[ $i % @streamers ]->push_row([$i, "event-$i"]);
    if ($produced >= $target) {
        $producer->stop;
        warn "[producer] done at $produced\n";
        # Drain every streamer in turn.
        my $left = scalar @streamers;
        $_->finish(sub {
            my (undef, $err) = @_;
            warn "[finish] err=$err\n" if $err;
            EV::break unless --$left;
        }) for @streamers;
    }
});

# Resume producer once the buffer drains. Cheap polling timer.
my $unpause = EV::timer(0.1, 0.1, sub {
    return unless $pause;
    my $still_high = 0;
    for my $s (@streamers) {
        $still_high = 1, last if $s->buffered_count > 5_000;
    }
    $pause = 0 unless $still_high;
});

EV::run;
$pool->finish;
print "Inserted $produced rows via pool of ", scalar @members, " members.\n";

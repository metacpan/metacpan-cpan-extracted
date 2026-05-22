#!/usr/bin/env perl
# ETL skeleton: pseudo-Kafka consumer feeding insert_streamer with
# backpressure. Replace the consumer stub with your real source.
#
# The streamer batches push_row() calls into INSERTs of `batch_size`,
# serialised against the native one-insert-at-a-time constraint. The
# `high_water` hook lets the consumer pause when in-flight buffering
# climbs past N rows.
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $consume_paused = 0;
my $consumed_total = 0;

my $ch;
$ch = EV::ClickHouse->new(
    host       => $ENV{CLICKHOUSE_HOST}        // '127.0.0.1',
    port       => $ENV{CLICKHOUSE_NATIVE_PORT} // 9000,
    protocol   => 'native',
    on_connect => sub {
        $ch->query("create temporary table eg_etl "
                 . "(ts DateTime, msg String) ENGINE = Memory", sub {
            my $streamer = $ch->insert_streamer('eg_etl',
                batch_size     => 1_000,
                high_water     => 5_000,
                on_high_water  => sub {
                    my ($buf, $in_flight) = @_;
                    warn "backpressure: buffered=$buf in_flight=$in_flight\n";
                    $consume_paused = 1;
                },
                on_batch_error => sub { warn "batch err: $_[0]\n" },
            );

            # Pseudo-Kafka consumer: a periodic EV timer producing rows.
            my $tick;
            $tick = EV::timer(0, 0.001, sub {
                # Throttle if the streamer signalled high-water.
                if ($consume_paused) {
                    $consume_paused = 0
                        if $streamer->buffered_count < 1_000;
                    return;
                }
                for (1..50) {
                    $streamer->push_row([ time, "evt-" . ($consumed_total++) ]);
                }
                if ($consumed_total >= 20_000) {
                    $tick->stop;
                    $streamer->finish(sub {
                        my (undef, $err) = @_;
                        die "ingest err: $err" if $err;
                        $ch->query("select count() from eg_etl", sub {
                            my ($r) = @_;
                            print "ingested ", $r->[0][0], " rows\n";
                            EV::break;
                        });
                    });
                }
            });
        });
    },
    on_error => sub { die "Error: $_[0]\n" },
);
EV::run;

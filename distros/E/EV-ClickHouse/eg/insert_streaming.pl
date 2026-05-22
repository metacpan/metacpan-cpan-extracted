#!/usr/bin/env perl
# Streaming insert — push rows one-by-one into a streamer that batches
# them into INSERTs of `batch_size`. Useful for ETL where rows trickle in.
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $ch;
$ch = EV::ClickHouse->new(
    host       => $ENV{CLICKHOUSE_HOST} // $ENV{TEST_CLICKHOUSE_HOST} // '127.0.0.1',
    port       => $ENV{CLICKHOUSE_NATIVE_PORT} // $ENV{TEST_CLICKHOUSE_NATIVE_PORT} // 9000,
    protocol   => 'native',
    on_connect => sub {
        $ch->query(
            "create temporary table eg_stream (id UInt32, payload String) ENGINE = Memory",
            sub {
                my $s = $ch->insert_streamer('eg_stream',
                    batch_size     => 1_000,
                    on_batch_error => sub { warn "batch failed: $_[0]\n" },
                );

                # Trickle 5_000 rows; the streamer emits 5 INSERTs of 1k rows.
                for my $i (1 .. 5_000) {
                    $s->push_row([ $i, "payload-$i" ]);
                }

                $s->finish(sub {
                    my (undef, $err) = @_;
                    die "ingest failed: $err" if $err;

                    $ch->query("select count() from eg_stream", sub {
                        my ($rows) = @_;
                        printf "Inserted %d rows via 5 batches\n", $rows->[0][0];
                        EV::break;
                    });
                });
            },
        );
    },
    on_error => sub { die "Error: $_[0]\n" },
);

EV::run;

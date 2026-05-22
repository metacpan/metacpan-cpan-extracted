#!/usr/bin/env perl
# ETL with a dead-letter queue.
#
# The streamer batches asynchronously, so naive 1:1 push-side tracking
# can race with the flush boundary. We use await_drain to serialize:
# push one batch_size chunk, wait for it to flush, then push the next.
# When on_batch_error fires for a chunk, we know exactly which rows
# were in it and dump them into a sibling DLQ table.
#
# Schema setup:
#   create table events     (ts DateTime, user_id UInt64, tags Array(String)) engine=Memory;
#   create table events_dlq (ts String,   user_id String, tags String, err String) engine=Memory;

use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $host       = $ENV{CLICKHOUSE_HOST}        // '127.0.0.1';
my $port       = $ENV{CLICKHOUSE_NATIVE_PORT} // 9000;
my $batch_size = 3;

# Mixed source: rows whose `tags` is a non-arrayref hit the native
# encoder's "unsupported type" rejection, taking the whole batch with
# them. With batch_size=3 every batch containing one bad row → DLQ.
my @source = (
    [ '2026-05-19 12:00:00', 1001, ['ui', 'click']   ],
    [ '2026-05-19 12:00:01', 1002, ['ui', 'view']    ],
    [ '2026-05-19 12:00:02', 1003, ['ui', 'click']   ],
    [ '2026-05-19 12:00:03', 1004, ['api', 'mutate'] ],
    [ '2026-05-19 12:00:04', 1005, ['ui']            ],
    [ '2026-05-19 12:00:05', 1006, 'oops'            ],   # bad
    [ '2026-05-19 12:00:06', 1007, 'still bad'       ],   # bad
    [ '2026-05-19 12:00:07', 1008, 42                ],   # bad
    [ '2026-05-19 12:00:08', 1009, ['api']           ],
    [ '2026-05-19 12:00:09', 1010, ['ui', 'click']   ],
);

# Split source into batch_size chunks up front so the feed loop is
# trivial.
my @chunks;
while (my @c = splice @source, 0, $batch_size) { push @chunks, [@c] }

my $ch; $ch = EV::ClickHouse->new(
    host => $host, port => $port, protocol => 'native',
    on_connect => sub {
        my $dlq = $ch->insert_streamer('events_dlq', batch_size => 10);

        my @in_flight;     # the chunk currently being flushed
        my $main; $main = $ch->insert_streamer(
            'events',
            batch_size     => $batch_size,
            on_batch_error => sub {
                my ($err) = @_;
                warn "batch failed: $err\n";
                for my $r (@in_flight) {
                    my $tags = ref $r->[2] eq 'ARRAY'
                             ? '[' . join(',', @{ $r->[2] }) . ']'
                             : "$r->[2]";
                    $dlq->push_row([ "$r->[0]", "$r->[1]", $tags, $err ]);
                }
            },
        );

        my $report = sub {
            $dlq->finish(sub {
                $ch->query("select count() from events", sub {
                    printf "events:     %d rows\n", $_[0][0][0];
                    $ch->query("select count() from events_dlq", sub {
                        printf "events_dlq: %d rows\n", $_[0][0][0];
                        EV::break;
                    });
                });
            });
        };
        my $feed; $feed = sub {
            my $chunk = shift @chunks;
            unless ($chunk) {
                # finish() also flushes any sub-batch_size remainder
                # and waits for it to complete or fail.
                return $main->finish(sub { $report->() });
            }
            @in_flight = @$chunk;
            $main->push_row($_) for @$chunk;
            if (@chunks) {
                $main->await_drain($feed);     # next chunk after this flush
            } else {
                # Last chunk — finish() will flush whatever remains.
                $feed->();
            }
        };
        $feed->();
    },
    on_error => sub { warn "ch: $_[0]\n"; EV::break },
);

EV::run;
$ch->finish;

#!/usr/bin/env perl
# Idempotent insert: the same dedup token across retries makes ClickHouse
# skip a duplicate insert from a reconnect-during-insert race. Pass
# `idempotent => 1` to mint a token automatically, or pass your own.
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $ch;
$ch = EV::ClickHouse->new(
    host       => $ENV{CLICKHOUSE_HOST}        // '127.0.0.1',
    port       => $ENV{CLICKHOUSE_NATIVE_PORT} // 9000,
    protocol   => 'native',
    on_connect => sub {
        # MergeTree dedupe requires non_replicated_deduplication_window > 0
        # (ReplicatedMergeTree has it on by default).
        $ch->query("create temporary table eg_idem (n UInt32) "
                 . "ENGINE = MergeTree order by n "
                 . "settings non_replicated_deduplication_window = 100", sub {
            $ch->insert('eg_idem', [[1],[2],[3]],
                        { idempotent => 1 }, sub {
                # Re-insert exactly the same rows with the same token.
                # MergeTree dedupe skips the duplicate block.
                $ch->insert('eg_idem', [[1],[2],[3]],
                            { idempotent => 'my-fixed-token-001' }, sub {
                    $ch->insert('eg_idem', [[1],[2],[3]],
                                { idempotent => 'my-fixed-token-001' }, sub {
                        $ch->query("select count() from eg_idem", sub {
                            my ($r) = @_;
                            printf "count after 3 INSERTs (2 with same token): %d\n",
                                   $r->[0][0];
                            EV::break;
                        });
                    });
                });
            });
        });
    },
    on_error => sub { die "Error: $_[0]\n" },
);
EV::run;

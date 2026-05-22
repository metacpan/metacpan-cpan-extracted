#!/usr/bin/env perl
# Server-side async_insert: ClickHouse buffers many small INSERTs into
# one bigger batch on the server side. Pass `async_insert => 1` in the
# per-query settings to turn it on; the helper sets the matching
# wait_for_async_insert=0 default so the call returns immediately.
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $ch;
my $remaining = 100;
$ch = EV::ClickHouse->new(
    host       => $ENV{CLICKHOUSE_HOST}        // '127.0.0.1',
    port       => $ENV{CLICKHOUSE_NATIVE_PORT} // 9000,
    protocol   => 'native',
    on_connect => sub {
        $ch->query("create table if not exists eg_async (n UInt32) "
                 . "ENGINE = MergeTree order by n", sub {
            for my $i (1 .. 100) {
                $ch->insert('eg_async', [[$i]],
                            { async_insert => 1 }, sub {
                    my (undef, $err) = @_;
                    warn "insert $i err: $err\n" if $err;
                    EV::break unless --$remaining;
                });
            }
        });
    },
);
EV::run;
$ch->query("system flush async insert queue", sub {
    $ch->query("select count() from eg_async", sub {
        my ($r) = @_;
        printf "Inserted (async-batched) %d rows\n", $r->[0][0];
        $ch->query("drop table eg_async", sub { EV::break });
    });
});
EV::run;
$ch->finish;

#!/usr/bin/env perl
# Cancel a streaming select mid-flight from inside the on_data callback,
# once a condition is met. The connection stays alive for follow-up queries.
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $ch;
my $blocks_seen = 0;
$ch = EV::ClickHouse->new(
    host       => $ENV{CLICKHOUSE_HOST} // '127.0.0.1',
    port       => $ENV{CLICKHOUSE_NATIVE_PORT} // 9000,
    protocol   => 'native',
    on_connect => sub {
        $ch->query(
            "select number from numbers_mt(1_000_000_000)",   # huge — we cancel early
            { on_data => sub {
                my ($rows) = @_;
                $blocks_seen++;
                printf "block %d: %d rows\n", $blocks_seen, scalar @$rows;
                # Stop after we've seen a couple of blocks
                $ch->cancel if $blocks_seen >= 2;
            } },
            sub {
                # Native cancel doesn't raise — the callback simply fires
                # once the server acks with EndOfStream.
                print "Cancelled after $blocks_seen blocks\n";

                # The connection is still alive. Run a normal query.
                $ch->query("select 1 + 1", sub {
                    my ($r) = @_;
                    print "Follow-up query: ", $r->[0][0], "\n";
                    EV::break;
                });
            },
        );
    },
    on_error => sub { die "Error: $_[0]\n" },
);

EV::run;

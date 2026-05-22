#!/usr/bin/env perl
# External tables: ship an in-memory data block with a query so the
# server can JOIN against it or use it in an IN filter — without
# creating a temporary table. Native protocol only.
#
# Typical use: you have a set of IDs (or a small lookup table) on the
# client side and want the server to filter/enrich against it in one
# round trip.
#
# Set CLICKHOUSE_HOST / CLICKHOUSE_NATIVE_PORT to point at a real CH.
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $host  = $ENV{CLICKHOUSE_HOST}        // '127.0.0.1';
my $nport = $ENV{CLICKHOUSE_NATIVE_PORT} // 9000;

my $ch;
$ch = EV::ClickHouse->new(
    host       => $host,
    port       => $nport,
    protocol   => 'native',
    on_connect => sub {
        # 1. IN-filter: keep only the numbers present in our client-side set.
        $ch->query(
            "select number from numbers(1000) "
          . "where number in _wanted order by number",
            { external => {
                _wanted => {
                    structure => [ id => 'UInt64' ],
                    data      => [ [3], [17], [256], [999] ],
                },
            } },
            sub {
                my ($rows, $err) = @_;
                die "IN-filter: $err\n" if $err;
                print "matched: ", join(', ', map { $_->[0] } @$rows), "\n";

                # 2. JOIN a server table-function against a client lookup table.
                $ch->query(
                    "select n.number, lbl.label "
                  . "from numbers(5) n "
                  . "join _labels lbl on n.number = lbl.id "
                  . "order by n.number",
                    { external => {
                        _labels => {
                            structure => [ id => 'UInt64', label => 'String' ],
                            data      => [ [1,'one'], [2,'two'], [4,'four'] ],
                        },
                    } },
                    sub {
                        my ($rows, $err) = @_;
                        die "join: $err\n" if $err;
                        printf "  %d => %s\n", @$_ for @$rows;
                        EV::break;
                    },
                );
            },
        );
    },
    on_error => sub { die "Error: $_[0]\n" },
);

EV::run;

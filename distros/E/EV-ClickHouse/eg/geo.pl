#!/usr/bin/env perl
# Geo column round-trip: Point and Polygon as Tuple(Float64,Float64) /
# Array(Array(Tuple(Float64,Float64))). EV::ClickHouse decodes them
# automatically as nested arrayrefs / tuples.
use strict;
use warnings;
use EV;
use EV::ClickHouse;
use Data::Dumper; $Data::Dumper::Sortkeys = 1;

my $ch;
$ch = EV::ClickHouse->new(
    host       => $ENV{CLICKHOUSE_HOST}        // '127.0.0.1',
    port       => $ENV{CLICKHOUSE_NATIVE_PORT} // 9000,
    protocol   => 'native',
    on_connect => sub {
        $ch->query(
            "select toPoint(1, 2) as pt, "
          . "[[(0,0),(0,1),(1,1),(1,0),(0,0)]]::Polygon as poly",
            sub {
                my ($rows) = @_;
                print Dumper($rows);
                EV::break;
            },
        );
    },
    on_error => sub { die "Error: $_[0]\n" },
);
EV::run;

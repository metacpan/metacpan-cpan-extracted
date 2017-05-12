#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use Log::Any::Adapter;
Log::Any::Adapter->set( 'Stderr');

use Measure::Everything::Adapter;
use Measure::Everything::Adapter::InfluxDB::TCP;

Measure::Everything::Adapter->set( 'InfluxDB::TCP',
    host => 'localhost',   # default
    port => 8094,          # default
    precision => 'ns'      # default is ns (nanoseconds)
);

use Measure::Everything qw($stats);

for my $cnt (1 .. 30) {
    $stats->write('test', $cnt);
    say $cnt;
    sleep(1);
}


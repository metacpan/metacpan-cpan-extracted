#!/usr/bin/perl
use Test::More;
use lib 'lib';

require_ok( 'Measure::Everything::Adapter::InfluxDB::TCP' );

done_testing();

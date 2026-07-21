#!/usr/bin/perl
use 5.014;
use strict;
use warnings FATAL => 'all';
use Test::More;

eval {require Map::Tube::London; 1} or plan skip_all => 'This test requires Map::Tube::London';
my $tube = Map::Tube::London->new();

ok( scalar($tube->list_drivers() ), 'List of GraphViz drivers' );
ok( scalar($tube->list_formats() ), 'List of GraphViz output formats' );

done_testing;

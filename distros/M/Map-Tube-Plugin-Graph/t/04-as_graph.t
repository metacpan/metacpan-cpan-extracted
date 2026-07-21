#!/usr/bin/perl
use 5.014;
use strict;
use warnings FATAL => 'all';
use Test::More;

eval {require Map::Tube::London; 1} or plan skip_all => 'This test requires Map::Tube::London';

my $tube = Map::Tube::London->new();
my $g = $tube->as_graph();
isnt( scalar $g->successors('Bank'), 0, 'Graph representation' );

done_testing;

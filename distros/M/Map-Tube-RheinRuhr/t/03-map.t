#!perl
use strict;
use warnings FATAL => 'all';
use Test::More 0.82;
use Map::Tube::RheinRuhr;

eval 'use Test::Map::Tube tests => 2';
plan skip_all => 'Test::Map::Tube required for this test' if $@;

my $map = Map::Tube::RheinRuhr->new( );
ok_map($map);
ok_map_functions($map);

done_testing( );

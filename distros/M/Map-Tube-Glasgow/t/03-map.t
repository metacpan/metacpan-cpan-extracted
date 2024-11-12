#!perl

use strict;
use warnings FATAL => 'all';
use Test::More 0.82;
use Map::Tube::Glasgow;

eval 'use Test::Map::Tube';
plan skip_all => 'Test::Map::Tube required for this test' if $@;

ok_map( Map::Tube::Glasgow->new( ) );

done_testing( );

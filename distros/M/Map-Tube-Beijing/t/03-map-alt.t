#!perl -T

use strict;
use warnings FATAL => 'all';
use utf8;
use Test::More 0.82;
use Map::Tube::Beijing;

eval 'use Test::Map::Tube';
plan skip_all => 'Test::Map::Tube required for this test' if $@;

ok_map( Map::Tube::Beijing->new( nametype => 'alt' ) );

done_testing( );

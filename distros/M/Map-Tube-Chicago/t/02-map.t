#!perl
use 5.12.0;
use strict;
use utf8;
use warnings FATAL => 'all';
use Test::More 0.82;
use Map::Tube::Chicago;

eval 'use Test::Map::Tube tests => 3';
plan skip_all => 'Test::Map::Tube required for this test' if $@;

my $map = new_ok( 'Map::Tube::Chicago' );

ok_map_functions($map);

my @routes = <DATA>;
ok_map_routes( $map, \@routes );

__DATA__
Route 1|Armitage (A)|Polk|Armitage (A), Sedgwick (A), Chicago (B), Merch Mart, Washington/Wells,Clinton (A), Morgan (B), Ashland (A), Polk
Route 2|35TH/ARCHER|sox-35th|35th/Archer, Ashland (B), Halsted (A), Roosevelt, Cermak-Chinatown, Sox-35th

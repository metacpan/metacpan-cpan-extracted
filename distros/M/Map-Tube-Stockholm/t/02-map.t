#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More 0.82;
use Map::Tube::Stockholm;

eval 'use Test::Map::Tube tests => 3';
plan skip_all => 'Test::Map::Tube required for this test' if $@;

my $map = new_ok( 'Map::Tube::Stockholm' );

ok_map_functions($map);

my @routes = <DATA>;
ok_map_routes( $map, \@routes );

__DATA__
Route 1|Nacka|Luma|Nacka, Sickla, Sickla udde, Sickla kaj, Luma
Route 2|aga|KARLAPLAN|AGA, Larsberg, Bodal, Baggeby, Torsvik, Ropsten, Gärdet, Karlaplan

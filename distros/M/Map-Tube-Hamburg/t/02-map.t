#!perl
use 5.14.0;
use strict;
use utf8;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More 0.82;
use Map::Tube::Hamburg;

eval 'use Test::Map::Tube tests => 3';
plan skip_all => 'Test::Map::Tube required for this test' if $@;

my $map = new_ok( 'Map::Tube::Hamburg' );

ok_map_functions($map);

my @routes = <DATA>;
ok_map_routes( $map, \@routes );

__DATA__
Route 1|Schlump|Othmarschen|Schlump, Sternschanze (Messe), Holstenstraße, Altona, Ortensen, Bahrenfeld, Othmarschen
Route 2|christuskirche|ALTONA|Christuskirche, Schlump, Sternschanze (Messe), Holstenstraße, Altona

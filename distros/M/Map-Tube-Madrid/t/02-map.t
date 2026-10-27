#!perl
use v5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More 0.82;
use Map::Tube::Madrid;

eval 'use Test::Map::Tube tests => 3';
plan skip_all => 'Test::Map::Tube required for this test' if $@;

my $map = new_ok( 'Map::Tube::Madrid' );

ok_map_functions($map);

my @routes = <DATA>;
ok_map_routes( $map, \@routes );

__DATA__
Route 1|Quevedo|Cruz del Rayo|Quevedo, Canal, Alonso Cano, Gregorio Marañón, Avenida de América, Cruz del Rayo
Route 2|quevedo|CRUZ DEL RAYO|Quevedo, Canal, Alonso Cano, Gregorio Marañón, Avenida de América, Cruz del Rayo

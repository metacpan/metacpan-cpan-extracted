#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More 0.82;
use Map::Tube::Lyon;

eval 'use Test::Map::Tube tests => 3';
plan skip_all => 'Test::Map::Tube required for this test' if $@;

my $map = new_ok( 'Map::Tube::Lyon' );

ok_map_functions($map);

my @routes = <DATA>;
ok_map_routes( $map, \@routes );

__DATA__
Route 1|Foch|Saxe-Gambetta|Foch, Hôtel de Ville - Louis Pradel, Cordeliers, Bellecour, Guillotière - Gabriel Péri, Saxe-Gambetta
Route 2|cuire|GARIBALDI|Cuire, Henon, Croix-Rousse, Croix-Paquet, Hôtel de Ville - Louis Pradel, Cordeliers, Bellecour, Guillotière - Gabriel Péri, Saxe-Gambetta, Garibaldi

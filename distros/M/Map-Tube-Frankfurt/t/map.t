#!perl -T

use v5.10;

use strict;
use warnings FATAL => 'all';

use utf8;

use Test::More;

my $min_ver = 0.35;
eval "use Test::Map::Tube $min_ver tests => 3";
plan skip_all => "Test::Map::Tube $min_ver required." if $@;

use utf8;
use Map::Tube::Frankfurt;
my $map = Map::Tube::Frankfurt->new;
ok_map($map);
ok_map_functions($map);

my @routes = <DATA>;
ok_map_routes($map, \@routes);

diag $map->to_string( $map->get_shortest_route( 'Riedstadt-Goddelau', 'Hauptbahnhof' ) );

__DATA__
Route 1|Riedstadt-Goddelau|Hauptbahnhof|Riedstadt-Goddelau,Riedstadt-Wolfskehlen,Groß-Gerau Dornheim,Groß-Gerau Dornberg,Mörfelden,Walldorf,Neu-Isenburg-Zeppelinheim,Stadion,Niederrad,Hauptbahnhof
Route 2|Hauptbahnhof|Galluswarte|Hauptbahnhof,Galluswarte

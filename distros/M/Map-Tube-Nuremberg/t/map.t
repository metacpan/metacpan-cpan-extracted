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
use Map::Tube::Nuremberg;
my $map = Map::Tube::Nuremberg->new;
ok_map($map);
ok_map_functions($map);

my @routes = <DATA>;
diag ok_map_routes($map, \@routes);

diag $map->to_string( $map->get_shortest_route('Hauptbahnhof', 'Opernhaus') );
diag $map->to_string( $map->get_shortest_route('Opernhaus', 'Aufseßplatz') );


__DATA__
Route 1|Hauptbahnhof|Opernhaus|Hauptbahnhof,Opernhaus
Route 2|Opernhaus|Aufseßplatz|Opernhaus,Hauptbahnhof,Aufseßplatz
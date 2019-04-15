#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use Test::More;

my $min_ver = '0.44';
eval "use Test::Map::Tube $min_ver tests => 4";
plan skip_all => "Test::Map::Tube $min_ver required." if $@;

use utf8;
use Map::Tube::Madrid;
my $map = new_ok('Map::Tube::Madrid');

SKIP: {
    ok_map($map) or skip "Skip map function and routes test.", 2;
    ok_map_functions($map);

    my @routes = <DATA>;
    ok_map_routes($map, \@routes);
}

__DATA__
Route 1|Canal|Iglesia|Canal,Cuatro Caminos,Ríos Rosas,Iglesia
Route 2|Canal|Bilbao|Canal,Quevedo,San Bernardo,Bilbao
Route 3|Moncloa|Canal|Moncloa,Argüelles,San Bernardo,Quevedo,Canal

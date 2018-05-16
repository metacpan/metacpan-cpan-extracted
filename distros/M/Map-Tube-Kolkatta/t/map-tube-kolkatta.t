#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use Test::More;

my $min_ver = 0.44;
eval "use Test::Map::Tube $min_ver tests => 4";
plan skip_all => "Test::Map::Tube $min_ver required." if $@;

use utf8;
use Map::Tube::Kolkatta;

SKIP: {

    my $map;
    eval { $map = Map::Tube::Kolkatta->new };
    if (defined ($map)) {
        pass("Wellformed Map Data");
    }
    else {
        fail("Malformed Map Data") or skip "", 3;
    }

    ok_map($map) or skip "Skip map function and routes test.", 2;

    ok_map_functions($map);

    my @routes = <DATA>;
    ok_map_routes($map, \@routes);
}

__DATA__
Route 1|Esplanade|Central|Esplanade,Chandni Chowk,Central

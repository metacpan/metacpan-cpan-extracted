#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use Test::More;

my $min_ver = '0.60';
eval "use Test::Map::Tube $min_ver tests => 4";
plan skip_all => "Test::Map::Tube $min_ver required." if $@;

use utf8;
use Map::Tube::Rome;
my $map = new_ok("Map::Tube::Rome");

SKIP: {
    ok_map($map) or skip "Skip map function and routes test.", 2;

    ok_map_functions($map);

    my @routes = <DATA>;
    ok_map_routes($map, \@routes);
}

done_testing;

__DATA__
Route 1|Anagnina|Arco di Travertino|Anagnina,Cinecittà,Subaugusta,Giulio Agricola,Lucio Sestio,Numidio Quadrato,Porta Furba Quadraro,Arco di Travertino

#!/usr/bin/perl

use v5.14;
use strict;
use warnings FATAL => 'all';
use Test::More;

my $min_ver = 0.44;
eval "use Test::Map::Tube $min_ver tests => 4";
plan skip_all => "Test::Map::Tube $min_ver required." if $@;

use utf8;
use Map::Tube::Leipzig;

my $map = new_ok('Map::Tube::Leipzig');
ok_map($map);
ok_map_functions($map);

my @routes = <DATA>;
ok_map_routes($map, \@routes);

__DATA__
Route 1|Trotha|Halle Messe|Trotha,Wohnstadt Nord,Zoo,Dessauer Brücke,Steintorbrücke,Halle Hbf,Halle Messe

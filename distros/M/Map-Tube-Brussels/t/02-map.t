#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More 0.82;
use Map::Tube::Brussels;

eval 'use Test::Map::Tube tests => 3';
plan skip_all => 'Test::Map::Tube required for this test' if $@;

my $map = new_ok( 'Map::Tube::Brussels' );

ok_map_functions($map);

my @routes = <DATA>;
ok_map_routes( $map, \@routes );

__DATA__
Route 1|Madou|Diamant|Madou, Arts-Loi, Maelbeek, Schuman, Merode, Montgomery, Georges Henri, Diamant
Route 2|DELACROIX|Cureghem|Delacroix, Clemenceau, Gare du Midi, Bara, Conseil, Albert I, Cureghem

#!perl
use 5.12.0;
use strict;
use utf8;
use warnings FATAL => 'all';
use Test::More 0.82;
use Map::Tube::Brussels;

eval 'use Test::Map::Tube tests => 3';
plan skip_all => 'Test::Map::Tube required for this test' if $@;

my $map = new_ok( 'Map::Tube::Brussels' => [ nametype => 'alt' ] );

ok_map_functions($map);

my @routes = <DATA>;
ok_map_routes( $map, \@routes );

__DATA__
Route 1|Madou|Diamant|Madou, Kunst-Wet, Maalbeek, Schuman, Merode, Montgomery, Georges Henri, Diamant
Route 2|DELACROIX|kuregem|Delacroix, Clemenceau, Zuidstation, Bara, Raad, Albert I, Kuregem

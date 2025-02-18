#!perl
use 5.12.0;
use strict;
use utf8;
use warnings FATAL => 'all';
use Test::More 0.82;
use Map::Tube::Toulouse;

eval 'use Test::Map::Tube tests => 3';
plan skip_all => 'Test::Map::Tube required for this test' if $@;

my $map = new_ok( 'Map::Tube::Toulouse' );

ok_map_functions($map);

my @routes = <DATA>;
ok_map_routes( $map, \@routes );

__DATA__
Route 1|Patte d'Oie|Canal du Midi|Patte d'Oie, St Cyprien - République, Esquirol, Capitole, Jean Jaurès, Jeanne d'Arc, Compans Caffarelli, Canal du Midi
Route 2|oncopole - lise enjalbert|RAMASSIERS|Oncopole - Lise Enjalbert,Hôpital Rangueil - Louis Lareng,Université Paul Sabatier,Faculté de Pharmacie,Rangeuil,Saouzelong,Saint Agne,Empalot,Saint Michel - Marcel Langer,Palais de Justice,Île du Ramier,Fer à Cheval,Av. Muret - M. Cavaillé,Croix de Pierre,Déodat de Séverac,Arènes,Le TOEC,Lardenne,Saint Martin du Touch,Ramassiers

#!perl

use strict;
use warnings FATAL => 'all';
use Test::More tests => 9;
use Map::Tube::Lyon;

my $map = new_ok( 'Map::Tube::Lyon' );

eval { $map->get_shortest_route( ); };
like( $@, qr/ERROR: Missing Station Name\./, 'No stations for get_shortest_route( )' );

eval { $map->get_shortest_route('Foch'); };
like( $@, qr/ERROR: Missing Station Name\./, 'Just one station for get_shortest_route( )'  );

eval { $map->get_shortest_route( 'XYZ', 'Foch' ); };
like( $@, qr/\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E/, 'Must specify two existing stations for get_shortest_route( )' );

eval { $map->get_shortest_route( 'Foch', 'XYZ' ); };
like( $@, qr/\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E/, 'Must specify two existing stations for get_shortest_route( )' );

{
  my $ret = $map->get_shortest_route( 'Foch', 'Flachet - Alain Gilles' );
  isa_ok( $ret, 'Map::Tube::Route' );
  is( $ret,
      'Foch (A), Masséna (A), Charpennes - Charles Hernu (A, B, T1), République - Villeurbanne (A), Gratte-Ciel (A), Flachet - Alain Gilles (A)',
      'Foch - Flachet Alain Gilles'
    );
}

{
  my $ret = $map->get_shortest_route( 'cuire', 'GARIBALDI' );
  isa_ok( $ret, 'Map::Tube::Route' );
  is( $ret,
      'Cuire (C), Henon (C), Croix-Rousse (C), Croix-Paquet (C), Hôtel de Ville - Louis Pradel (A, C), ' .
      'Cordeliers (A), Bellecour (A, D), Guillotière - Gabriel Péri (D, T1), Saxe-Gambetta (B, D), Garibaldi (D)',
      'cuire - GARIBALDI case-insensitive'
    );
}


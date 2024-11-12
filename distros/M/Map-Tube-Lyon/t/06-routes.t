#!perl

use strict;
use warnings FATAL => 'all';
use Test::More tests => 11;
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
  my $ret = $map->get_shortest_route( 'Foch', 'Saxe-Gambetta' );
  isa_ok( $ret, 'Map::Tube::Route' );
  is( $ret,
      'Foch (A), Hôtel de Ville - Louis Pradel (A, C), Cordeliers (A), Bellecour (A, D), Guillotière - Gabriel Péri (D, T1), Saxe-Gambetta (B, D)',
      'Foch - Saxe-Gambetta'
    );
}

{
  my $ret = $map->get_shortest_route( 'Foch', 'Saxe-Gambetta' )->preferred( );
  isa_ok( $ret, 'Map::Tube::Route' );
  is( $ret,
      'Foch (A), Hôtel de Ville - Louis Pradel (A), Cordeliers (A), Bellecour (A, D), Guillotière - Gabriel Péri (D), Saxe-Gambetta (D)',
      'Foch - Saxe-Gambetta preferred route'
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


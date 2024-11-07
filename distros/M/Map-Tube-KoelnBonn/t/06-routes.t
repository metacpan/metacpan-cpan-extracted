#!perl

use strict;
use warnings FATAL => 'all';
use Test::More tests => 9;
use Map::Tube::KoelnBonn;

my $map = new_ok( 'Map::Tube::KoelnBonn' );

eval { $map->get_shortest_route( ); };
like( $@, qr/ERROR: Missing Station Name\./, 'No stations for get_shortest_route( )' );

eval { $map->get_shortest_route('Neumarkt'); };
like( $@, qr/ERROR: Missing Station Name\./, 'Just one station for get_shortest_route( )'  );

eval { $map->get_shortest_route( 'XYZ', 'Neumarkt' ); };
like( $@, qr/\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E/, 'Must specify two existing stations for get_shortest_route( )' );

eval { $map->get_shortest_route( 'Neumarkt', 'XYZ' ); };
like( $@, qr/\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E/, 'Must specify two existing stations for get_shortest_route( )' );

{
  my $ret = $map->get_shortest_route( 'Neumarkt', 'Ebertplatz' );
  isa_ok( $ret, 'Map::Tube::Route' );
  is( $ret,
      'Neumarkt (1, 16, 18, 3, 4, 7, 9), Appellhofplatz / Breite Str. (16, 18, 3, 4), ' .
      'Dom / Hbf (16, 18, 5, street), Breslauer Platz / Hbf (16, 18, street), Ebertplatz (12, 15, 16, 18)',
      'Neumarkt - Ebertplatz'
    );
}

{
  my $ret = $map->get_shortest_route( 'wurzerstr.', 'RAMERSDORF' );
  isa_ok( $ret, 'Map::Tube::Route' );
  is( $ret,
      'Wurzerstr. (16, 63, 67), Hochkreuz / Deutsches Museum Bonn (16, 63, 67), Max-Löbner-Str. ' .
      '/ Friesdorf (16, 63, 67), Olof-Palme-Allee (16, 63, 66, 67, 68), Robert-Schuman-Platz ' .
      '(66, 68), Rheinaue (66, 68), Ramersdorf (62, 65, 66, 68)',
      'wurzerstr. - RAMERSDORF case-insensitive'
    );
}


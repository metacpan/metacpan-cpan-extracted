#!perl
use strict;
use warnings FATAL => 'all';
use Test::More tests => 11;
use Map::Tube::Hamburg;

my $map = new_ok( 'Map::Tube::Hamburg' );

eval { $map->get_shortest_route( ); };
like( $@, qr/ERROR: Missing Station Name\./, 'No stations for get_shortest_route( )' );

eval { $map->get_shortest_route('Schlump'); };
like( $@, qr/ERROR: Missing Station Name\./, 'Just one station for get_shortest_route( )'  );

eval { $map->get_shortest_route( 'XYZ', 'Schlump' ); };
like( $@, qr/\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E/, 'Node XYZ should not exist' );

eval { $map->get_shortest_route( 'Schlump', 'XYZ' ); };
like( $@, qr/\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E/, 'Node XYZ should not exist' );

{
  my $ret = $map->get_shortest_route( 'Schlump', 'Othmarschen' );
  isa_ok( $ret, 'Map::Tube::Route' );
  is( $ret,
      'Schlump (U2, U3), Sternschanze (Messe) (S2, S5, U3), ' .
      'Holstenstraﬂe (S2, S5), Altona (S1, S2, S3), ' .
      'Ortensen (S1), Bahrenfeld (S1), Othmarschen (S1)',
      'Schlump - Othmarschen'
    );
}

{
  my $ret = $map->get_shortest_route( 'Schlump', 'Othmarschen' )->preferred( );
  isa_ok( $ret, 'Map::Tube::Route' );
  is( $ret,
      'Schlump (U3), Sternschanze (Messe) (S2, S5, U3), ' .
      'Holstenstraﬂe (S2, S5), Altona (S1, S2), ' .
      'Ortensen (S1), Bahrenfeld (S1), Othmarschen (S1)',
      'Schlump - Othmarschen, preferred route'
    );
}

{
  my $ret = $map->get_shortest_route( 'christuskirche', 'ALTONA' );
  isa_ok( $ret, 'Map::Tube::Route' );
  is( $ret,
      'Christuskirche (U2), Schlump (U2, U3), Sternschanze (Messe) (S2, S5, U3), Holstenstraﬂe (S2, S5), Altona (S1, S2, S3)',
      'christuskirche - ALTONA case-insensitive'
    );
}


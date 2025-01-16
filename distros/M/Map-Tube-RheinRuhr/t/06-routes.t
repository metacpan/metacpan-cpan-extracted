#!perl
use strict;
use warnings FATAL => 'all';
use Test::More tests => 11;
use Map::Tube::RheinRuhr;

my $map = new_ok( 'Map::Tube::RheinRuhr' );

eval { $map->get_shortest_route( ); };
like( $@, qr/ERROR: Missing Station Name\./, 'No stations for get_shortest_route( )' );

eval { $map->get_shortest_route('Westentor'); };
like( $@, qr/ERROR: Missing Station Name\./, 'Just one station for get_shortest_route( )'  );

eval { $map->get_shortest_route( 'XYZ', 'Westentor' ); };
like( $@, qr/\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E/, 'Node XYZ should not exist' );

eval { $map->get_shortest_route( 'Westentor', 'XYZ' ); };
like( $@, qr/\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E/, 'Node XYZ should not exist' );

{
  my $ret = $map->get_shortest_route( 'Westentor', 'Saarlandstr.' );
  isa_ok( $ret, 'Map::Tube::Route' );
  is( $ret,
      'Westentor (U43, U44), Kampstr. (Dortmund) (U41, U43, U44, U45, U47, U49), ' .
      'Stadtgarten (103, 109, U41, U42, U45, U46, U47, U49), Saarlandstr. (U46)',
      'Westentor - Saarlandstr.'
    );
}

{
  my $ret = $map->get_shortest_route( 'Westentor', 'Saarlandstr.' )->preferred( );
  isa_ok( $ret, 'Map::Tube::Route' );
  is( $ret,
      'Westentor (U43, U44), Kampstr. (Dortmund) (U41, U43, U44, U45, U47, U49), ' .
      'Stadtgarten (U41, U45, U46, U47, U49), Saarlandstr. (U46)',
      'Westentor - Saarlandstr., preferred route'
    );
}

{
  my $ret = $map->get_shortest_route( 'westentor', 'SAARLANDSTR.' );
  isa_ok( $ret, 'Map::Tube::Route' );
  is( $ret,
      'Westentor (U43, U44), Kampstr. (Dortmund) (U41, U43, U44, U45, U47, U49), ' .
      'Stadtgarten (103, 109, U41, U42, U45, U46, U47, U49), Saarlandstr. (U46)',
      'westentor - SAARLANDSTR. case-insensitive'
    );
}


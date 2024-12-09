#!perl

use strict;
use warnings FATAL => 'all';
use Test::More tests => 9;
use Map::Tube::Glasgow;

my $map = new_ok( 'Map::Tube::Glasgow' );

eval { $map->get_shortest_route( ); };
like( $@, qr/ERROR: Missing Station Name\./, 'No stations for get_shortest_route( )' );

eval { $map->get_shortest_route('Cowcaddens'); };
like( $@, qr/ERROR: Missing Station Name\./, 'Just one station for get_shortest_route( )'  );

eval { $map->get_shortest_route( 'XYZ', 'Cowcaddens' ); };
# Different Map::Tube versions give different error messages for the following:
like( $@,
      qr/(\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E)|(\QMap::Tube::get_node_by_id(): ERROR: Missing Station ID\E)/,
      'Must specify two existing stations for get_shortest_route( )'
    );

eval { $map->get_shortest_route( 'Cowcaddens', 'XYZ' ); };
# Different Map::Tube versions give different error messages for the following:
like( $@,
      qr/(\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E)|(\QMap::Tube::get_node_by_id(): ERROR: Missing Station ID\E)/,
      'Must specify two existing stations for get_shortest_route( )'
    );

{
  my $ret = $map->get_shortest_route( 'Cowcaddens', 'Ibrox' );
  isa_ok( $ret, 'Map::Tube::Route' );
  is( $ret,
      'Cowcaddens (SPT), St George\'s Cross (SPT), Kelvinbridge (SPT), Hillhead (SPT), ' .
      'Kelvinhall (SPT), Partick (SPT), Govan (SPT), Ibrox (SPT)',
      'Cowcaddens - Ibrox'
    );
}

{
  my $ret = $map->get_shortest_route( 'hillhead', 'IBROX' );
  isa_ok( $ret, 'Map::Tube::Route' );
  is( $ret,
      'Hillhead (SPT), Kelvinhall (SPT), Partick (SPT), Govan (SPT), Ibrox (SPT)',
      'hillhead - IBROX'
    );
}


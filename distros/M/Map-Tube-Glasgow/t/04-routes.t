#!perl

use strict;
use Test::More tests => 9;
use Map::Tube::Glasgow;

my $map = new_ok( 'Map::Tube::Glasgow' );

eval { $map->get_shortest_route(); };
like($@, qr/ERROR: Either FROM\/TO node is undefined/);

eval { $map->get_shortest_route('Cowcaddens'); };
like($@, qr/ERROR: Either FROM\/TO node is undefined/);

eval { $map->get_shortest_route('XYZ', 'Cowcaddens'); };
like($@, qr/\QMap::Tube::get_shortest_route(): ERROR: Received invalid FROM node 'XYZ'\E/);

eval { $map->get_shortest_route('Cowcaddens', 'XYZ'); };
like($@, qr/\QMap::Tube::get_shortest_route(): ERROR: Received invalid TO node 'XYZ'\E/);

{
  my $ret = $map->get_shortest_route('Cowcaddens', 'Hillhead');
  isa_ok( $ret, 'Map::Tube::Route' );
  is( $ret, 'Cowcaddens (SPT), St George\'s Cross (SPT), Kelvinbridge (SPT), Hillhead (SPT)', 'Cowcaddens - Hillhead' );
}

{
  my $ret = $map->get_shortest_route('kinning park', 'KELVINBRIDGE');
  isa_ok( $ret, 'Map::Tube::Route' );
  is( $ret, 'Kinning Park (SPT), Cessnock (SPT), Ibrox (SPT), Govan (SPT), Partick (SPT), Kelvinhall (SPT), Hillhead (SPT), Kelvinbridge (SPT)', 'kinning park - KELVINBRIDGE case-insensitive' );
}


#!perl

use strict;
use warnings FATAL => 'all';
use Test::More tests => 23;
use Map::Tube::Beijing;

my $map = new_ok( 'Map::Tube::Beijing' => [ 'nametype' => 'alt' ] );

# {
#   Optional additional debug output, helps to identify mistakes in per-line station indexes
#   (watch out for stations not showing up in the data -- they may have been unceremoniously dropped!)
#   my $stationref = $map->get_stations( );
#   my @stations = @{ $stationref };
#   print STDERR "\n*******\n";
#   print STDERR join("\n", sort map { $_->id( ) } @stations ), "\n";
#   print STDERR "*** ", scalar(@stations), "\n";
#   print STDERR "*******\n";
# }

is( $map->name( ), 'Beijing Subway', 'Name of map does not match' );

eval { $map->get_node_by_name('XYZ'); };
like($@, qr/\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E/, 'Node XYZ should not exist' );

{
  my $ret = $map->get_node_by_name('Guoyuan');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'BT09', 'Node id not correct for Guoyuan' );
  is( $ret->name( ), 'Guoyuan', 'Node name not correct for Guoyuan' );
  is( $ret->link( ), 'BT08,BT10', 'Links not correct for Guoyuan' );
  is( join( ',', sort map { $_->name( ) } @{ $ret->line( ) } ),  'Batong Line', 'Line(s) not correct for Guoyuan' );
}

{
  my $ret = $map->get_node_by_id('BT09');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'BT09',    'Node id not correct for BT09' );
  is( $ret->name( ), 'Guoyuan', 'Node name not correct for BT09' );
}

{
  my $stationref = $map->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 290, 'Number of stations incorrect for map' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Agricultural.*Zhuxinzhuang$), 'Stations not correct for map' );
}

{
  my $stationref = $map->get_stations('Batong Line');
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 13, 'Number of stations incorrect for line Batong Line' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Baliqiao.*Tuqiao$), 'Stations not correct for line Batong Line -- station indexes still have to be added' );
}

{
  my $stationref = $map->get_next_stations( 'Dawanglu' );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( $stations[0], 'Map::Tube::Node' );
  is( scalar(@stations), 4, 'Number of neighbouring stations incorrect for Dawanglu' );
  like( join( ',', sort map { $_->name( ) } @stations ), qr(^Guomao.*Sihui$), 'Neighbouring stations not correct for Dawanglu -- station indexes still have to be added' );
}


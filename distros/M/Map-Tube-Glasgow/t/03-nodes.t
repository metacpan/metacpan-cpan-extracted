#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 23;
use Map::Tube::Glasgow;

my $map = new_ok( 'Map::Tube::Glasgow' );

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

is( $map->name( ), 'Glasgow tube', 'Name of map does not match' );

eval { $map->get_node_by_name('XYZ'); };
like( $@, qr/\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E/, 'Node XYZ should not exist' );

{
  my $ret = $map->get_node_by_name('Cowcaddens');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'gg_cc',      'Node id not correct for Cowcaddens' );
  is( $ret->name( ), 'Cowcaddens', 'Node name not correct for Cowcaddens' );
  is( $ret->link( ), 'gg_bu,gg_sg', 'Links not correct for Cowcaddens' );
  is( join( ',', sort map { $_->name( ) } @{ $ret->line( ) } ),  'SPT', 'Lines not correct for Cowcaddens' );
}

{
  my $ret = $map->get_node_by_id('gg_cc');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'gg_cc',      'Node id not correct for gg_cc' );
  is( $ret->name( ), 'Cowcaddens', 'Node name not correct for gg_cc' );
}

{
  my $stationref = $map->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 15, 'Number of stations incorrect for map' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Bridge.*West Street$), 'Stations not correct for map' );
}

{
  my $stationref = $map->get_stations('SPT');
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 15, 'Number of stations incorrect for line SPT' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Bridge.*West Street$), 'Stations not correct for line SPT' );
}

{
  my $stationref = $map->get_next_stations( 'Cowcaddens' );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( $stations[0], 'Map::Tube::Node' );
  is( scalar(@stations), 2, 'Number of neighbouring stations incorrect for Cowcaddens' );
  like( join( ',', sort map { $_->name( ) } @stations ), qr(^Buchanan.*Cross$), 'Neighbouring stations not correct for Cowcaddens' );
}


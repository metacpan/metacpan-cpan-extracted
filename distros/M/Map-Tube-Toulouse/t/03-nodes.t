#!perl
use 5.12.0;
use strict;
use utf8;
use Test::More tests => 23;
use Map::Tube::Toulouse;

my $map = new_ok( 'Map::Tube::Toulouse' );

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

is( $map->name( ), 'Toulouse métro, tram et funiculaire', 'Name of map does not match' );

eval { $map->get_node_by_name('XYZ'); };
like( $@, qr/\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E/, 'Node XYZ should not exist' );

{
  my $ret = $map->get_node_by_name('Mermoz');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'tou_a13', 'Node id not correct for station named Mermoz' );
  is( $ret->name( ), 'Mermoz',  'Node name not correct for station named Mermoz' );
  is( $ret->link( ), 'tou_a12,tou_a14', 'Links not correct for station named Mermoz' );
  is( join( ',', sort map { $_->name( ) } @{ $ret->line( ) } ),  'A', 'Lines not correct for station named Mermoz' );
}

{
  my $ret = $map->get_node_by_id('tou_a13');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'tou_a13', 'Node id not correct for station id tou_a13' );
  is( $ret->name( ), 'Mermoz',  'Node name not correct for station id tou_a13' );
}

{
  my $stationref = $map->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 67, 'Number of stations incorrect for map' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Ancely.*Île du Ramier$), 'Stations not correct for map' );
}

{
  my $stationref = $map->get_stations('A');
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 18, 'Number of stations incorrect for line SPT' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Argoulets.*St Cyprien - République$), 'Stations not correct for line A' );
}

{
  my $stationref = $map->get_next_stations( 'Mermoz' );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( $stations[0], 'Map::Tube::Node' );
  is( scalar(@stations), 2, 'Number of neighbouring stations incorrect for Mermoz' );
  is( join( ',', sort map { $_->name( ) } @stations ), 'Bagatelle,Fontaine Lestang', 'Neighbouring stations not correct for Mermoz' );
}


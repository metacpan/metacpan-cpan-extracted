#!perl
use strict;
use warnings FATAL => 'all';
use Test::More tests => 23;
use Map::Tube::Hamburg;

my $map = new_ok( 'Map::Tube::Hamburg' );

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

is( $map->name( ), 'Hamburg U- and S-Bahn and AKN', 'Name of map does not match' );

eval { $map->get_node_by_name('XYZ'); };
like( $@, qr/\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E/, 'Node XYZ should not exist' );

{
  my $ret = $map->get_node_by_name('Schlump');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'u211',    'Node id not correct for Schlump' );
  is( $ret->name( ), 'Schlump', 'Node name not correct for Schlump' );
  is( $ret->link( ), 'u210,u212,u306,u307', 'Links not correct for Schlump' );
  is( join( ',', sort map { $_->name( ) } @{ $ret->line( ) } ),  'U2,U3', 'Lines not correct for Schlump' );
}

{
  my $ret = $map->get_node_by_id('u211');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'u211',    'Node id not correct for u211' );
  is( $ret->name( ), 'Schlump', 'Node name not correct for u211' );
}

{
  my $stationref = $map->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 193, 'Number of stations incorrect for map' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Agathenburg.*berseequartier$), 'Stations not correct for map' );
}

{
  my $stationref = $map->get_stations('U3');
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 25, 'Number of stations incorrect for line U3' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Barmbek.*Gartenstadt$), 'Stations not correct for line U3' );
}

{
  my $stationref = $map->get_next_stations('Schlump');
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( $stations[0], 'Map::Tube::Node' );
  is( scalar(@stations), 4, 'Number of neighbouring stations incorrect for Schlump' );
  like( join( ',', sort map { $_->name( ) } @stations ), qr(^Christuskirche.*Sternschanze [(]Messe[)]$), 'Neighbouring stations not correct for Schlump' );
}


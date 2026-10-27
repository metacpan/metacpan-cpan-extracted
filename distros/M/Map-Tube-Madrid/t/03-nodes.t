#!perl
use v5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More tests => 23;
use Map::Tube::Madrid;

my $map = new_ok( 'Map::Tube::Madrid' );

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

is( $map->name( ), 'Madrid Metro', 'Name of map does not match' );

eval { $map->get_node_by_name('XYZ'); };
like( $@, qr/\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E/, 'Node XYZ should not exist' );

{
  my $ret = $map->get_node_by_name('Tribunal');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'TRIBUNAL', 'Node id not correct for station named Tribunal' );
  is( $ret->name( ), 'Tribunal', 'Node name not correct for station named Tribunal' );
  is( $ret->link( ), 'BILBAO,GRAN-VIA,ALONSO-MARTINEZ,L3-15', 'Links not correct for station named Tribunal' );
  is( join( ',', sort map { $_->name( ) } @{ $ret->line( ) } ),  'L1,L10', 'Lines not correct for station named Tribunal' );
}

{
  my $ret = $map->get_node_by_id('TRIBUNAL');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'TRIBUNAL', 'Node id not correct for station id TRIBUNAL' );
  is( $ret->name( ), 'Tribunal', 'Node name not correct for station id TRIBUNAL' );
}

{
  my $stationref = $map->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 274, 'Number of stations incorrect for map' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Abrantes.*Ópera$), 'Stations not correct for map' );
}

{
  my $stationref = $map->get_stations('L2');
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 20, 'Number of stations incorrect for line named L2' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Alsacia.*Ópera$), 'Stations not correct for line named L2' );
}

{
  my $stationref = $map->get_next_stations('Tribunal');
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( $stations[0], 'Map::Tube::Node' );
  is( scalar(@stations), 4, 'Number of neighbouring stations incorrect for station named Tribunal' );
  is( join( ', ', sort map { $_->name( ) } @stations ),
      'Alonso Martínez, Bilbao, Gran Vía, Plaza de España',
      'Neighbouring stations not correct for station named Tribunal'
    );
}


#!perl
use 5.12.0;
use utf8;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 23;
use Map::Tube::Napoli;

my $map = new_ok( 'Map::Tube::Napoli' );

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

is( $map->name( ), 'Naples Metropolitan and Funicular Network', 'Name of map does not match' );

eval { $map->get_node_by_name('XYZ'); };
like( $@, qr/\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E/, 'Node XYZ should not exist' );

{
  my $ret = $map->get_node_by_name('Piave');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'nap_circum02',              'Node id not correct for Piave' );
  is( $ret->name( ), 'Piave',                     'Node name not correct for Piave' );
  is( $ret->link( ), 'nap_circum03,nap_linea108', 'Links not correct for Piave' );
  is( join( ',', sort map { $_->name( ) } @{ $ret->line( ) } ), 'Circumflegrea', 'Lines not correct for Piave' );
}

{
  my $ret = $map->get_node_by_id('nap_circum02');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'nap_circum02',  'Node id not correct for nap_circum02' );
  is( $ret->name( ), 'Piave', 'Node name not correct for nap_circum02' );
}

{
  my $stationref = $map->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 162, 'Number of stations incorrect for map' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Acerra.*San Erasmo$), 'Stations not correct for map' );
}

{
  my $stationref = $map->get_stations('Linea 2');
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 35, 'Number of stations incorrect for Linea 2' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Acerra.*Amalfi$), 'Stations not correct for Linea 2' );
}

{
  my $stationref = $map->get_next_stations( 'Piave' );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( $stations[0], 'Map::Tube::Node' );
  is( scalar(@stations), 2, 'Number of neighbouring stations incorrect for Piave' );
  like( join( ',', sort map { $_->name( ) } @stations ), qr(Montesanto,Soccavo), 'Neighbouring stations not correct for Piave' );
}


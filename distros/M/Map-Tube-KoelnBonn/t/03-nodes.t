#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More tests => 23;
use Map::Tube::KoelnBonn;

my $map = new_ok( 'Map::Tube::KoelnBonn' );

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

is( $map->name( ), 'Köln-Bonn U- and S-Bahn and Tramways', 'Name of map does not match' );

eval { $map->get_node_by_name('XYZ'); };
like( $@, qr/\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E/, 'Node XYZ should not exist' );

{
  my $ret = $map->get_node_by_name('Neumarkt');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'vrs_s017', 'Node id not correct for Neumarkt' );
  is( $ret->name( ), 'Neumarkt', 'Node name not correct for Neumarkt' );
  is( $ret->link( ), 'vrs_s016,vrs_s018,vrs_s050,vrs_s051,vrs_s125', 'Links not correct for Neumarkt' );
  is( join( ',', sort map { $_->name( ) } @{ $ret->line( ) } ),  '1,16,18,3,4,7,9', 'Lines not correct for Neumarkt' );
}

{
  my $ret = $map->get_node_by_id('vrs_s017');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'vrs_s017', 'Node id not correct for id vrs_s017' );
  is( $ret->name( ), 'Neumarkt', 'Node name not correct for id vrs_s017' );
}

{
  my $stationref = $map->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 375, 'Number of stations incorrect for map' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Aachener.*Kanalstr\.$), 'Stations not correct for map' );
}

{
  my $stationref = $map->get_stations(16);
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 50, 'Number of stations incorrect for line 16' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Amsterdamer.*Wurzerstr\.$), 'Stations not correct for line 16' );
}

{
  my $stationref = $map->get_next_stations( 'Neumarkt' );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( $stations[0], 'Map::Tube::Node' );
  is( scalar(@stations), 5, 'Number of neighbouring stations incorrect for Neumarkt' );
  like( join( ',', sort map { $_->name( ) } @stations ), qr(^Appellhofplatz.*Rudolfplatz$), 'Neighbouring stations not correct for Neumarkt' );
}


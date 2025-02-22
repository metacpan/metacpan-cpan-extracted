#!perl
use 5.12.0;
use utf8;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 23;
use Map::Tube::Oslo;

my $map = new_ok( 'Map::Tube::Oslo' );

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

is( $map->name( ), 'Oslo Tube and Tram', 'Name of map does not match' );

eval { $map->get_node_by_name('XYZ'); };
like( $@, qr/\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E/, 'Node XYZ should not exist' );

{
  my $ret = $map->get_node_by_name('Borgen');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'osl_210',         'Node id not correct for Borgen' );
  is( $ret->name( ), 'Borgen',          'Node name not correct for Borgen' );
  is( $ret->link( ), 'osl_119,osl_209', 'Links not correct for Borgen' );
  is( join( ',', sort map { $_->name( ) } @{ $ret->line( ) } ), '2,3', 'Lines not correct for Borgen' );
}

{
  my $ret = $map->get_node_by_id('osl_210');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'osl_210',  'Node id not correct for osl_210' );
  is( $ret->name( ), 'Borgen', 'Node name not correct for osl_210' );
}

{
  my $stationref = $map->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 175, 'Number of stations incorrect for map' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Abbediengen.*Slottsgate$), 'Stations not correct for map' );
}

{
  my $stationref = $map->get_stations('4');
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 37, 'Number of stations incorrect for line 4' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Ammerud.*Økern$), 'Stations not correct for line 4' );
}

{
  my $stationref = $map->get_next_stations( 'Borgen' );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( $stations[0], 'Map::Tube::Node' );
  is( scalar(@stations), 2, 'Number of neighbouring stations incorrect for Borgen' );
  like( join( ',', sort map { $_->name( ) } @stations ), qr(Majorstuen,Smestad), 'Neighbouring stations not correct for Borgen' );
}


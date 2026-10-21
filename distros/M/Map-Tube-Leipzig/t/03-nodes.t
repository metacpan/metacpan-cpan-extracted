#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More tests => 23;
use Map::Tube::Leipzig;

my $map = new_ok( 'Map::Tube::Leipzig' );

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

is( $map->name( ), 'Leipzig/Halle S-Bahn and Tram', 'Name of map does not match' );

eval { $map->get_node_by_name('XYZ'); };
like( $@, qr/\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E/, 'Node XYZ should not exist' );

{
  my $ret = $map->get_node_by_name('Westplatz');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'lei_l118', 'Node id not correct for station named Westplatz' );
  is( $ret->name( ), 'Westplatz', 'Node name not correct for station named Westplatz' );
  is( $ret->link( ), 'lei_l117,lei_l119,lei_l1424,lei_l209,lei_l321', 'Links not correct for station named Westplatz' );
  is( join( ',', sort map { $_->name( ) } @{ $ret->line( ) } ),  'L1,L14,L2,L39,L8', 'Lines not correct for station named Westplatz' );
}

{
  my $ret = $map->get_node_by_id('lei_l118');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'lei_l118', 'Node id not correct for station id lei_l118' );
  is( $ret->name( ), 'Westplatz', 'Node name not correct for station id lei_l118' );
}

{
  my $stationref = $map->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 526, 'Number of stations incorrect for map' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^A\.-Hoffmann-/R\.-Lehmann-Straße.*Zwickau Hbf.*$), 'Stations not correct for map' );
}

{
  my $stationref = $map->get_stations('L1');
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 34, 'Number of stations incorrect for line named L1' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Adler.*Zschampertaue$), 'Stations not correct for line named L1' );
}

{
  my $stationref = $map->get_next_stations('Westplatz');
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( $stations[0], 'Map::Tube::Node' );
  is( scalar(@stations), 5, 'Number of neighbouring stations incorrect for station named Westplatz' );
  is( join( ', ', sort map { $_->name( ) } @stations ),
      'Gottschedstraße, Marschnerstraße, Neues Rathaus, Nonnenstraße, Waldplatz',
      'Neighbouring stations not correct for station named Westplatz'
    );
}


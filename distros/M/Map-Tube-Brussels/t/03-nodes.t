#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More tests => 23;
use Map::Tube::Brussels;

my $map = new_ok( 'Map::Tube::Brussels' );

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

is( $map->name( ), 'Bruxelles Métro et Tram', 'Name of map does not match' );

eval { $map->get_node_by_name('XYZ'); };
like( $@, qr/\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E/, 'Node XYZ should not exist' );

{
  my $ret = $map->get_node_by_name('Pétillon');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'bx_524',                      'Node id not correct for Pétillon' );
  is( $ret->name( ), 'Pétillon',                    'Node name not correct for Pétillon' );
  is( $ret->link( ), 'bx_522,bx_523,bx_525,bx_721', 'Links not correct for Pétillon' );
  is( join( ',', sort map { $_->name( ) } @{ $ret->line( ) } ), '25,5,7', 'Lines not correct for Pétillon' );
}

{
  my $ret = $map->get_node_by_id('bx_524');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'bx_524',   'Node id not correct for bx_524' );
  is( $ret->name( ), 'Pétillon', 'Node name not correct for bx_524' );
}

{
  my $stationref = $map->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]),  'Map::Tube::Node' );
  is( scalar(@stations), 321, 'Number of stations incorrect for map' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Abbaye.*Étangs Noirs$), 'Stations not correct for map' );
}

{
  my $stationref = $map->get_stations('6');
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 26, 'Number of stations incorrect for line 6' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Arts-Loi.*Yser$), 'Stations not correct for line 6' );
}

{
  my $stationref = $map->get_next_stations( 'Pétillon' );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( $stations[0], 'Map::Tube::Node' );
  is( scalar(@stations), 4, 'Number of neighbouring stations incorrect for Pétillon' );
  is( join( ',', sort map { $_->name( ) } @stations ), 'Arsenal,Boileau,Hankar,Thieffry', 'Neighbouring stations not correct for Pétillon' );
}


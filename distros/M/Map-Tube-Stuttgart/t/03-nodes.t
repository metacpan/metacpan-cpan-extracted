#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More tests => 23;
use Map::Tube::Stuttgart;

my $map = new_ok( 'Map::Tube::Stuttgart' );

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

is( $map->name( ), 'Stuttgart Stadt- and S-Bahn', 'Name of map does not match' );

eval { $map->get_node_by_name('XYZ'); };
like( $@, qr/\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E/, 'Node XYZ should not exist' );

{
  my $ret = $map->get_node_by_name('Bopser');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'stu_u509',                   'Node id not correct for Bopser' );
  is( $ret->name( ), 'Bopser',                     'Node name not correct for Bopser' );
  is( $ret->link( ), 'stu_u508,stu_u510,stu_u723', 'Links not correct for Bopser' );
  is( join( ',', sort map { $_->name( ) } @{ $ret->line( ) } ), 'U12,U5,U6,U7', 'Lines not correct for Bopser' );
}

{
  my $ret = $map->get_node_by_id('stu_u509');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'stu_u509', 'Node id not correct for stu_u509' );
  is( $ret->name( ), 'Bopser',   'Node name not correct for stu_u509' );
}

{
  my $stationref = $map->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]),  'Map::Tube::Node' );
  is( scalar(@stations), 283, 'Number of stations incorrect for map' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Altbach.*Ötlingen$), 'Stations not correct for map' );
}

{
  my $stationref = $map->get_stations('U6');
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 43, 'Number of stations incorrect for line U6' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Bergheimer Hof.*Wolfbusch$), 'Stations not correct for line U6' );
}

{
  my $stationref = $map->get_next_stations( 'Bopser' );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( $stations[0], 'Map::Tube::Node' );
  is( scalar(@stations), 3, 'Number of neighbouring stations incorrect for Bopser' );
  is( join( ',', sort map { $_->name( ) } @stations ), 'Dobelstr.,Waldau,Weinsteige', 'Neighbouring stations not correct for Bopser' );
}


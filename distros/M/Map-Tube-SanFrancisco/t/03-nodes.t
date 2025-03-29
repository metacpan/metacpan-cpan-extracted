#!perl
use 5.12.0;
use utf8;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 23;
use Map::Tube::SanFrancisco;

my $map = new_ok( 'Map::Tube::SanFrancisco' );

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

is( $map->name( ), 'San Francisco rapid transport, underground, trams, and cable cars', 'Name of map does not match' );

eval { $map->get_node_by_name('XYZ'); };
like( $@, qr/\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E/, 'Node XYZ should not exist' );

{
  my $ret = $map->get_node_by_name('MacArthur');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'sf_red07',                      'Node id not correct for MacArthur' );
  is( $ret->name( ), 'MacArthur',                     'Node name not correct for MacArthur' );
  is( $ret->link( ), 'sf_red06,sf_red08,sf_yellow10', 'Links not correct for MacArthur' );
  is( join( ',', sort map { $_->name( ) } @{ $ret->line( ) } ),
      'Orange Line,Red Line,Yellow Line',
      'Lines not correct for MacArthur'
    );
}

{
  my $ret = $map->get_node_by_id('sf_red07');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'sf_red07',  'Node id not correct for sf_red07' );
  is( $ret->name( ), 'MacArthur',  'Node name not correct for sf_red07' );
}

{
  my $stationref = $map->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 271, 'Number of stations incorrect for map' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^12th St/Oakland.*Moscone$), 'Stations not correct for map' );
}

{
  my $stationref = $map->get_stations('Blue Line');
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 18, 'Number of stations incorrect for Blue Line' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^16th St & Mission.*West Oakland$), 'Stations not correct for Blue Line' );
}

{
  my $stationref = $map->get_next_stations( 'MacArthur' );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( $stations[0], 'Map::Tube::Node' );
  is( scalar(@stations), 3, 'Number of neighbouring stations incorrect for MacArthur' );
  like( join( ',', sort map { $_->name( ) } @stations ), qr(19th St/Oakland,Ashby,Rockridge), 'Neighbouring stations not correct for MacArthur' );
}


#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More tests => 23;
use Map::Tube::Muenchen;

my $map = new_ok( 'Map::Tube::Muenchen' );

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

is( $map->name( ), 'München U- and S-Bahn and Trams', 'Name of map does not match' );

eval { $map->get_node_by_name('XYZ'); };
like( $@, qr/\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E/, 'Node XYZ should not exist' );

{
  my $ret = $map->get_node_by_name('Odeonsplatz');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'mvg_u312',    'Node id not correct for station named Odeonsplatz' );
  is( $ret->name( ), 'Odeonsplatz', 'Node name not correct for station named Odeonsplatz' );
  is( $ret->link( ), 'mvg_u311,mvg_u313,mvg_u406,mvg_u408',      'Links not correct for station named Odeonsplatz' );
  is( join( ',', sort map { $_->name( ) } @{ $ret->line( ) } ),  'U3,U4,U5,U6', 'Lines not correct for station named Odeonsplatz' );
}

{
  my $ret = $map->get_node_by_id('mvg_u312');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'mvg_u312',    'Node id not correct for station id mvg_u312' );
  is( $ret->name( ), 'Odeonsplatz', 'Node name not correct for station id mvg_u312' );
}

{
  my $stationref = $map->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]),  'Map::Tube::Node' );
  is( scalar(@stations), 380, 'Number of stations incorrect for map' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Ackermannstr\..*Zorneding$), 'Stations not correct for map' );
}

{
  my $stationref = $map->get_stations('U4');
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 13, 'Number of stations incorrect for line named U4' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Arabellapark.*Westendstr\.$), 'Stations not correct for line named U47' );
}

{
  my $stationref = $map->get_next_stations('Laim');
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( $stations[0], 'Map::Tube::Node' );
  is( scalar(@stations), 4, 'Number of neighbouring stations incorrect for station named Laim' );
  is( join( ', ', sort map { $_->name( ) } @stations ),
      'Hirschgarten, Moosach, Obermenzing, Pasing',
      'Neighbouring stations not correct for station named Laim'
    );
}


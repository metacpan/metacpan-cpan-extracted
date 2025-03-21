#!perl
use 5.12.0;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 23;
use Map::Tube::RheinRuhr;

my $map = new_ok( 'Map::Tube::RheinRuhr' );

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

is( $map->name( ), 'Rhein/Ruhr U- and S-Bahn and Trams', 'Name of map does not match' );

eval { $map->get_node_by_name('XYZ'); };
like( $@, qr/\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E/, 'Node XYZ should not exist' );

{
  my $ret = $map->get_node_by_name('Westentor');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'vrr_u4328', 'Node id not correct for station named Westentor' );
  is( $ret->name( ), 'Westentor', 'Node name not correct for station named Westentor' );
  is( $ret->link( ), 'vrr_u4120,vrr_u4329', 'Links not correct for station named Westentor' );
  is( join( ',', sort map { $_->name( ) } @{ $ret->line( ) } ),  'U43,U44', 'Lines not correct for station named Westentor' );
}

{
  my $ret = $map->get_node_by_id('vrr_u4328');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'vrr_u4328', 'Node id not correct for station id vrr_u4328' );
  is( $ret->name( ), 'Westentor', 'Node name not correct for station id vrr_u4328' );
}

{
  my $stationref = $map->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 994, 'Number of stations incorrect for map' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Aachener Platz.*ckendorfer Platz$), 'Stations not correct for map' );
}

{
  my $stationref = $map->get_stations('U47');
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 25, 'Number of stations incorrect for line named U47' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Allerstr.*Westendorfstr\.$), 'Stations not correct for line named U47' );
}

{
  my $stationref = $map->get_next_stations('Kampstr. (Dortmund)');
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( $stations[0], 'Map::Tube::Node' );
  is( scalar(@stations), 4, 'Number of neighbouring stations incorrect for station named Kampstr. (Dortmund)' );
  is( join( ', ', sort map { $_->name( ) } @stations ),
      'Dortmund Hbf, Reinoldikirche, Stadtgarten Dortmund, Westentor',
      'Neighbouring stations not correct for station named Kampstr. (Dortmund)'
    );
}


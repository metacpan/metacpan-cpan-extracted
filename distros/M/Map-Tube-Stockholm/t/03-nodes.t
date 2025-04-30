#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More tests => 23;
use Map::Tube::Stockholm;

my $map = new_ok( 'Map::Tube::Stockholm' );

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

is( $map->name( ), 'Stockholm Rail Network', 'Name of map does not match' );

eval { $map->get_node_by_name('XYZ'); };
like( $@, qr/\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E/, 'Node XYZ should not exist' );

{
  my $ret = $map->get_node_by_name('Gamla stan');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'st_roda06',          'Node id not correct for Gamla stan' );
  is( $ret->name( ), 'Gamla stan',         'Node name not correct for Gamla stan' );
  is( $ret->link( ), 'st_bla13,st_roda07', 'Links not correct for Gamla stan' );
  is( join( ',', sort map { $_->name( ) } @{ $ret->line( ) } ),
      'Gröna linjen (17),Gröna linjen (18),Gröna linjen (19),Röda linjen (13),Röda linjen (14)',
      'Lines not correct for Gamla stan' );
}

{
  my $ret = $map->get_node_by_id('st_roda06');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'st_roda06',  'Node id not correct for st_roda06' );
  is( $ret->name( ), 'Gamla stan', 'Node name not correct for st_roda06' );
}

{
  my $stationref = $map->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 255, 'Number of stations incorrect for map' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^AGA.*ålstens gård$), 'Stations not correct for map' );
}

{
  my $stationref = $map->get_stations('43');
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 28, 'Number of stations incorrect for line 43' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Barkarby.*Ösmo$), 'Stations not correct for line 43' );
}

{
  my $stationref = $map->get_next_stations( 'Gamla stan' );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( $stations[0], 'Map::Tube::Node' );
  is( scalar(@stations), 2, 'Number of neighbouring stations incorrect for Gamla stan' );
  like( join( ',', sort map { $_->name( ) } @stations ), qr(Slussen,T-Centralen), 'Neighbouring stations not correct for Gamla stan' );
}


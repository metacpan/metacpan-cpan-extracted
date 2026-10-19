#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More tests => 23;
use Map::Tube::Hannover;

my $map = new_ok( 'Map::Tube::Hannover' );

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

is( $map->name( ), 'Hannover S-Bahn and U-Bahn/Tram', 'Name of map does not match' );

eval { $map->get_node_by_name('XYZ'); };
like( $@, qr/\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E/, 'Node XYZ should not exist' );

{
  my $ret = $map->get_node_by_name('Aegidientorplatz');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'han_118', 'Node id not correct for station named Aegidientorplatz' );
  is( $ret->name( ), 'Aegidientorplatz', 'Node name not correct for station named Aegidientorplatz' );
  is( $ret->link( ), 'han_117,han_119,han_423', 'Links not correct for station named Aegidientorplatz' );
  is( join( ',', sort map { $_->name( ) } @{ $ret->line( ) } ),  '1,11,2,4,5,6,8', 'Lines not correct for station named Aegidientorplatz' );
}

{
  my $ret = $map->get_node_by_id('han_118');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'han_118', 'Node id not correct for station id han_118' );
  is( $ret->name( ), 'Aegidientorplatz', 'Node name not correct for station id han_118' );
}

{
  my $stationref = $map->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 271, 'Number of stations incorrect for map' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Aegidientorplatz.*Zuschlagstr\.$), 'Stations not correct for map' );
}

{
  my $stationref = $map->get_stations('S5');
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 26, 'Number of stations incorrect for line named S5' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Altenbeken.*Weetzen$), 'Stations not correct for line named S5' );
}

{
  my $stationref = $map->get_next_stations('Aegidientorplatz');
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( $stations[0], 'Map::Tube::Node' );
  is( scalar(@stations), 3, 'Number of neighbouring stations incorrect for station named Aegidientorplatz' );
  is( join( ', ', sort map { $_->name( ) } @stations ),
      'Kröpcke, Marienstr., Schlägerstr.',
      'Neighbouring stations not correct for station named Aegidientorplatz'
    );
}


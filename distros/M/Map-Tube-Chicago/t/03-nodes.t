#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More tests => 23;
use Map::Tube::Chicago;

my $map = new_ok( 'Map::Tube::Chicago' );

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

is( $map->name( ), 'Chicago L System', 'Name of map does not match' );

eval { $map->get_node_by_name('XYZ'); };
like( $@, qr/\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E/, 'Node XYZ should not exist' );

{
  my $ret = $map->get_node_by_name('Ashland (Green/Pink Line)');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'chi_green13',                                                     'Node id not correct for Ashland (Green/Pink Line)' );
  is( $ret->name( ), 'Ashland (Green/Pink Line)',                                       'Node name not correct for Ashland (Green/Pink Line)' );
  is( $ret->link( ), 'chi_green12,chi_green14,chi_pink11,chi_pink13',                   'Links not correct for Ashland (Green/Pink Line)' );
  is( join( ',', sort map { $_->name( ) } @{ $ret->line( ) } ), 'Green Line,Pink Line', 'Lines not correct for Ashland (Green/Pink Line)' );
}

{
  my $ret = $map->get_node_by_id('chi_green13');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'chi_green13',  'Node id not correct for chi_green13' );
  is( $ret->name( ), 'Ashland (Green/Pink Line)',  'Node name not correct for chi_green13' );
}

{
  my $stationref = $map->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 156, 'Number of stations incorrect for map' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^18th.*Wilson$), 'Stations not correct for map' );
}

{
  my $stationref = $map->get_stations('Pink Line');
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 22, 'Number of stations incorrect for Pink Line' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^18th.*Western [(]Pink Line[)]$), 'Stations not correct for Pink Line' );
}

{
  my $stationref = $map->get_next_stations( 'Ashland (Green/Pink Line)' );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( $stations[0], 'Map::Tube::Node' );
  is( scalar(@stations), 4, 'Number of neighbouring stations incorrect for Ashland (Green/Pink Line)' );
  like( join( ',', sort map { $_->name( ) } @stations ), qr(\QDamen (Green Line),Morgan (Green Line),Morgan (Pink Line),Polk\E), 'Neighbouring stations not correct for Ashland (Green/Pink Line)' );
}


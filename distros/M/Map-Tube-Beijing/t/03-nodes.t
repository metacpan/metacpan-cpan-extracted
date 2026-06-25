#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More tests => 23;
use Map::Tube::Beijing;

my $map = new_ok('Map::Tube::Beijing');

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

is( $map->name( ), 'Beijing Subway', 'Name of map does not match' );

eval { $map->get_node_by_name('XYZ'); };
like( $@, qr/\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E/, 'Node XYZ should not exist' );

{
  my $ret = $map->get_node_by_name('Guoyuan');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   's_guoyuan', 'Node id not correct for Guoyuan' );
  is( $ret->name( ), 'Guoyuan', 'Node name not correct for Guoyuan' );
  is( $ret->link( ), 's_jiukeshu,s_tongzhoubeiyuan', 'Links not correct for Guoyuan' );
  is( join( ',', sort map { $_->name( ) } @{ $ret->line( ) } ),  'Line 1 and Batong Line', 'Line(s) not correct for Guoyuan' );
}

{
  my $ret = $map->get_node_by_id('s_guoyuan');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   's_guoyuan', 'Node id not correct for s_guoyuan' );
  is( $ret->name( ), 'Guoyuan',   'Node name not correct for s_guoyuan' );
}

{
  my $stationref = $map->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 398, 'Number of stations incorrect for map' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Agricultural.*Zuojiazhuang$), 'Stations not correct for map' );
}

{
  my $stationref = $map->get_stations('Line 1 and Batong Line');
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 36, 'Number of stations incorrect for Line 1 and Batong Line' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Babaoshan.*Yuquan Lu$), 'Stations not correct for Line 1 and Batong Line' );
}

{
  my $stationref = $map->get_next_stations( 'Dawang Lu' );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( $stations[0], 'Map::Tube::Node' );
  is( scalar(@stations), 4, 'Number of neighbouring stations incorrect for Dawang Lu' );
  is( join( ',', sort map { $_->name( ) } @stations ), 'Guomao,Jintai Lu,Jiulongshan,Sihui', 'Neighbouring stations not correct for Dawang Lu' );
}


#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More tests => 16;
use Map::Tube::Hannover;

my $map = new_ok( 'Map::Tube::Hannover' );

eval { $map->get_line_by_name('XYZ'); };
like($@, qr/\QMap::Tube::get_line_by_name(): ERROR: Invalid Line Name [XYZ]\E/, 'Line XYZ should not exist' );

{
  my $ret = $map->get_line_by_name('S5');
  isa_ok( $ret,       'Map::Tube::Line' );
  is( $ret->id( ),    'HAN_S5', 'Line id not correct for line named S5' );
  is( $ret->name( ),  'S5',     'Node name not correct for line named S5' );
  is( $ret->color( ), '#F68B1F', 'Color not correct for line named S5' );
  my $stationref = $ret->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 26, 'Number of stations incorrect for line named S5' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Altenbeken.*Weetzen$), 'Stations not correct for line S5' );
}

{
  my $ret = $map->get_line_by_id('HAN_S5');
  isa_ok( $ret,      'Map::Tube::Line' );
  is( $ret->id( ),   'HAN_S5', 'Line id not correct for line id HAN_S5' );
  is( $ret->name( ), 'S5',     'Line name not correct for line id HAN_S5' );
}

{
  my $ret = $map->get_lines( );
  isa_ok( $ret,      'ARRAY' );
  my @lines = @{ $ret };
  isa_ok( $lines[0],  'Map::Tube::Line' );
  is( scalar(@lines), 23, 'Number of lines incorrect' );
}


#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More tests => 16;
use Map::Tube::Leipzig;

my $map = new_ok( 'Map::Tube::Leipzig' );

eval { $map->get_line_by_name('XYZ'); };
like($@, qr/\QMap::Tube::get_line_by_name(): ERROR: Invalid Line Name [XYZ]\E/, 'Line XYZ should not exist' );

{
  my $ret = $map->get_line_by_name('S6');
  isa_ok( $ret,       'Map::Tube::Line' );
  is( $ret->id( ),    'LEI_S6',  'Line id not correct for line named S6' );
  is( $ret->name( ),  'S6',      'Line name not correct for line named S6' );
  is( $ret->color( ), '#5D1339', 'Color not correct for line named S6' );
  my $stationref = $ret->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 14, 'Number of stations incorrect for line named S6' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Bad D.rrenberg.*Wei.enfels$), 'Stations not correct for line S6' );
}

{
  my $ret = $map->get_line_by_id('LEI_S6');
  isa_ok( $ret,      'Map::Tube::Line' );
  is( $ret->id( ),   'LEI_S6', 'Line id not correct for line id LEI_S6' );
  is( $ret->name( ), 'S6',     'Line name not correct for line id LEI_S6' );
}

{
  my $ret = $map->get_lines( );
  isa_ok( $ret,      'ARRAY' );
  my @lines = @{ $ret };
  isa_ok( $lines[0],  'Map::Tube::Line' );
  is( scalar(@lines), 39, 'Number of lines incorrect' );
}


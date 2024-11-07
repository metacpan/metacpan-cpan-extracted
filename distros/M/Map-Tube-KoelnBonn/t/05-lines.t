#!perl

use strict;
use warnings FATAL => 'all';
use Test::More tests => 16;
use Map::Tube::KoelnBonn;

my $map = new_ok( 'Map::Tube::KoelnBonn' );

eval { $map->get_line_by_name('XYZ'); };
like($@, qr/\QMap::Tube::get_line_by_name(): ERROR: Invalid Line Name [XYZ]\E/, 'Line XYZ should not exist' );

{
  my $ret = $map->get_line_by_name('16');
  isa_ok( $ret,       'Map::Tube::Line' );
  is( $ret->id( ),    '16', 'Line id not correct for line 16' );
  is( $ret->name( ),  '16', 'Node name not correct for line 16' );
  is( $ret->color( ), '#00B6AD', 'Color not correct for line 16' );
  my $stationref = $ret->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 50, 'Number of stations incorrect for line 16' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Amsterdamer.*Wurzerstr\.$), 'Stations not correct for line 16' );
}

{
  my $ret = $map->get_line_by_id('16');
  isa_ok( $ret,      'Map::Tube::Line' );
  is( $ret->id( ),   '16', 'Line id not correct for line 16' );
  is( $ret->name( ), '16', 'Line name not correct for line 16' );
}

{
  my $ret = $map->get_lines( );
  isa_ok( $ret,      'ARRAY' );
  my @lines = @{ $ret };
  isa_ok( $lines[0],  'Map::Tube::Line' );
  is( scalar(@lines), 25, 'Number of lines incorrect' );
}


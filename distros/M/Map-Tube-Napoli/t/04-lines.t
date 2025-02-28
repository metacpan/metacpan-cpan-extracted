#!perl
use 5.12.0;
use utf8;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 14;
use Map::Tube::Napoli;

my $map = new_ok( 'Map::Tube::Napoli' );

eval { $map->get_line_by_name('XYZ'); };
like($@, qr/\QMap::Tube::get_line_by_name(): ERROR: Invalid Line Name [XYZ]\E/, 'Line XYZ should not exist' );

{
  my $ret = $map->get_line_by_name('Linea 2');
  isa_ok( $ret,       'Map::Tube::Line' );
  is( $ret->id( ),    'NAP_LINEA2', 'Line id not correct for line named Linea 2' );
  is( $ret->name( ),  'Linea 2',    'Line name not correct for line named Linea 2' );
  is( $ret->color( ), '#0161AD',    'Color not correct for line named Linea 2' );
  my $stationref = $ret->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
}

{
  my $ret = $map->get_line_by_id('NAP_LINEA2');
  isa_ok( $ret,      'Map::Tube::Line' );
  is( $ret->id( ),   'NAP_LINEA2', 'Line id not correct for line id NAP_LINEA2' );
  is( $ret->name( ), 'Linea 2',    'Line name not correct for line id NAP_LINEA2' );
}

{
  my $ret = $map->get_lines( );
  isa_ok( $ret,      'ARRAY' );
  my @lines = @{ $ret };
  isa_ok( $lines[0],  'Map::Tube::Line' );
  is( scalar(@lines), 14, 'Number of lines incorrect' );
}


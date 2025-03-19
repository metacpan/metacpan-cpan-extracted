#!perl
use 5.12.0;
use utf8;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 14;
use Map::Tube::Stuttgart;

my $map = new_ok( 'Map::Tube::Stuttgart' );

eval { $map->get_line_by_name('XYZ'); };
like($@, qr/\QMap::Tube::get_line_by_name(): ERROR: Invalid Line Name [XYZ]\E/, 'Line XYZ should not exist' );

{
  my $ret = $map->get_line_by_name('U6');
  isa_ok( $ret,       'Map::Tube::Line' );
  is( $ret->id( ),    'STU_U6',  'Line id not correct for line named U6' );
  is( $ret->name( ),  'U6',      'Line name not correct for line named U6' );
  is( $ret->color( ), '#EC028D', 'Color not correct for line named U6' );
  my $stationref = $ret->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
}

{
  my $ret = $map->get_line_by_id('STU_U6');
  isa_ok( $ret,      'Map::Tube::Line' );
  is( $ret->id( ),   'STU_U6', 'Line id not correct for line id STU_U6' );
  is( $ret->name( ), 'U6',     'Line name not correct for line id STU_U6' );
}

{
  my $ret = $map->get_lines( );
  isa_ok( $ret,      'ARRAY' );
  my @lines = @{ $ret };
  isa_ok( $lines[0],  'Map::Tube::Line' );
  is( scalar(@lines), 27, 'Number of lines incorrect' );
}


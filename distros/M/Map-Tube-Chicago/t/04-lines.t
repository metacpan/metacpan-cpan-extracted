#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More tests => 14;
use Map::Tube::Chicago;

my $map = new_ok( 'Map::Tube::Chicago' );

eval { $map->get_line_by_name('XYZ'); };
like($@, qr/\QMap::Tube::get_line_by_name(): ERROR: Invalid Line Name [XYZ]\E/, 'Line XYZ should not exist' );

{
  my $ret = $map->get_line_by_name('Pink Line');
  isa_ok( $ret,       'Map::Tube::Line' );
  is( $ret->id( ),    'CHI_PINK',  'Line id not correct for line named Pink Line' );
  is( $ret->name( ),  'Pink Line', 'Line name not correct for line named Pink Line' );
  is( $ret->color( ), '#F06DA9',   'Color not correct for line named Pink Line' );
  my $stationref = $ret->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
}

{
  my $ret = $map->get_line_by_id('CHI_PINK');
  isa_ok( $ret,      'Map::Tube::Line' );
  is( $ret->id( ),   'CHI_PINK',  'Line id not correct for line id CHI_PINK' );
  is( $ret->name( ), 'Pink Line', 'Line name not correct for line id CHI_PINK' );
}

{
  my $ret = $map->get_lines( );
  isa_ok( $ret,      'ARRAY' );
  my @lines = @{ $ret };
  isa_ok( $lines[0],  'Map::Tube::Line' );
  is( scalar(@lines), 9, 'Number of lines incorrect' );
}


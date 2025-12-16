#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More tests => 14;
use Map::Tube::Paris;

my $map = new_ok( 'Map::Tube::Paris' );

eval { $map->get_line_by_name('XYZ'); };
like($@, qr/\QMap::Tube::get_line_by_name(): ERROR: Invalid Line Name [XYZ]\E/, 'Line XYZ should not exist' );

{
  my $ret = $map->get_line_by_name('4');
  isa_ok( $ret,                  'Map::Tube::Line' );
  is( $ret->id( ),    'P_4',     'Line id not correct for line named 4' );
  is( $ret->name( ),  '4',       'Line name not correct for line named 4' );
  is( $ret->color( ), '#A0006E', 'Color not correct for line named 4' );
  my $stationref = $ret->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]),     'Map::Tube::Node' );
}

{
  my $ret = $map->get_line_by_id('P_4');
  isa_ok( $ret,             'Map::Tube::Line' );
  is( $ret->id( ),   'P_4', 'Line id not correct for line id P_4' );
  is( $ret->name( ), '4',   'Line name not correct for line id P_4' );
}

{
  my $ret = $map->get_lines( );
  isa_ok( $ret,      'ARRAY' );
  my @lines = @{ $ret };
  isa_ok( $lines[0],      'Map::Tube::Line' );
  is( scalar(@lines), 49, 'Number of lines incorrect' );
}


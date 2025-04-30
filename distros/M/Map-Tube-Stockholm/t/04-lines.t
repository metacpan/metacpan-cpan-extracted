#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More tests => 16;
use Map::Tube::Stockholm;

my $map = new_ok( 'Map::Tube::Stockholm' );

eval { $map->get_line_by_name('XYZ'); };
like($@, qr/\QMap::Tube::get_line_by_name(): ERROR: Invalid Line Name [XYZ]\E/, 'Line XYZ should not exist' );

{
  my $ret = $map->get_line_by_name('44');
  isa_ok( $ret,       'Map::Tube::Line' );
  is( $ret->id( ),    'ST_44',   'Line id not correct for line named 44' );
  is( $ret->name( ),  '44',      'Line name not correct for line named 44' );
  is( $ret->color( ), '#F266A6', 'Color not correct for line named 44' );
  my $stationref = $ret->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 22, 'Number of stations incorrect for line named 44' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Barkarby.*Östertälje$), 'Stations not correct for line named 44' );
}

{
  my $ret = $map->get_line_by_id('ST_44');
  isa_ok( $ret,      'Map::Tube::Line' );
  is( $ret->id( ),   'ST_44', 'Line id not correct for line id ST_44' );
  is( $ret->name( ), '44',    'Line name not correct for line id ST_44' );
}

{
  my $ret = $map->get_lines( );
  isa_ok( $ret,      'ARRAY' );
  my @lines = @{ $ret };
  isa_ok( $lines[0],  'Map::Tube::Line' );
  is( scalar(@lines), 23, 'Number of lines incorrect' );
}


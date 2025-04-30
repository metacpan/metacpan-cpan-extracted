#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More tests => 16;
use Map::Tube::Lyon;

my $map = new_ok( 'Map::Tube::Lyon' );

eval { $map->get_line_by_name('XYZ'); };
like($@, qr/\QMap::Tube::get_line_by_name(): ERROR: Invalid Line Name [XYZ]\E/, 'Line XYZ should not exist' );

{
  my $ret = $map->get_line_by_name('B');
  isa_ok( $ret,       'Map::Tube::Line' );
  is( $ret->id( ),    'ly_B', 'Line id not correct for line named B' );
  is( $ret->name( ),  'B',    'Node name not correct for line named B' );
  is( $ret->color( ), '#0094D7', 'Color not correct for line named B' );
  my $stationref = $ret->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 12, 'Number of stations incorrect for line named B' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Brotteaux.*Le LOU$), 'Stations not correct for line named B' );
}

{
  my $ret = $map->get_line_by_id('ly_B');
  isa_ok( $ret,      'Map::Tube::Line' );
  is( $ret->id( ),   'ly_B', 'Line id not correct for line id ly_B' );
  is( $ret->name( ), 'B',    'Line name not correct for line id ly_B' );
}

{
  my $ret = $map->get_lines( );
  isa_ok( $ret,      'ARRAY' );
  my @lines = @{ $ret };
  isa_ok( $lines[0],  'Map::Tube::Line' );
  is( scalar(@lines), 14, 'Number of lines incorrect' );
}


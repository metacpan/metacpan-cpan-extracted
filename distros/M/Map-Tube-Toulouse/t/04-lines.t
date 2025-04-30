#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More tests => 16;
use Map::Tube::Toulouse;

my $map = new_ok( 'Map::Tube::Toulouse' );

eval { $map->get_line_by_name('XYZ'); };
like($@, qr/\QMap::Tube::get_line_by_name(): ERROR: Invalid Line Name [XYZ]\E/, 'Line XYZ should not exist' );

{
  my $ret = $map->get_line_by_name('A');
  isa_ok( $ret,       'Map::Tube::Line' );
  is( $ret->id( ),    'tou_A',   'Line id not correct for line named A' );
  is( $ret->name( ),  'A',       'Node name not correct for line named A' );
  is( $ret->color( ), '#FD2A17', 'Color not correct for line named A' );
  my $stationref = $ret->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 18, 'Number of stations incorrect for line named A' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Argoulets.*St Cyprien - République$), 'Stations not correct for line named A' );
}

{
  my $ret = $map->get_line_by_id('tou_A');
  isa_ok( $ret,      'Map::Tube::Line' );
  is( $ret->id( ),   'tou_A', 'Line id not correct for line id tou_A' );
  is( $ret->name( ), 'A',     'Line name not correct for line id tou_A' );
}

{
  my $ret = $map->get_lines( );
  isa_ok( $ret,      'ARRAY' );
  my @lines = @{ $ret };
  isa_ok( $lines[0],  'Map::Tube::Line' );
  is( scalar(@lines), 5, 'Number of lines incorrect' );
}


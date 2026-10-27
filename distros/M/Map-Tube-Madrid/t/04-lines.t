#!perl
use v5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More tests => 16;
use Map::Tube::Madrid;

my $map = new_ok( 'Map::Tube::Madrid' );

eval { $map->get_line_by_name('XYZ'); };
like($@, qr/\QMap::Tube::get_line_by_name(): ERROR: Invalid Line Name [XYZ]\E/, 'Line XYZ should not exist' );

{
  my $ret = $map->get_line_by_name('L2');
  isa_ok( $ret,       'Map::Tube::Line' );
  is( $ret->id( ),    'L2',      'Line id not correct for line named L2' );
  is( $ret->name( ),  'L2',      'Line name not correct for line named L2' );
  is( $ret->color( ), '#EA312A', 'Color not correct for line named L2' );
  my $stationref = $ret->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 20, 'Number of stations incorrect for line named L2' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Alsacia.*Ópera$), 'Stations not correct for line L2' );
}

{
  my $ret = $map->get_line_by_id('L2');
  isa_ok( $ret,      'Map::Tube::Line' );
  is( $ret->id( ),   'L2', 'Line id not correct for line id L2' );
  is( $ret->name( ), 'L2', 'Line name not correct for line id L2' );
}

{
  my $ret = $map->get_lines( );
  isa_ok( $ret,      'ARRAY' );
  my @lines = @{ $ret };
  isa_ok( $lines[0],  'Map::Tube::Line' );
  is( scalar(@lines), 15, 'Number of lines incorrect' );
}


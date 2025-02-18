#!perl
use 5.12.0;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 16;
use Map::Tube::Glasgow;

my $map = new_ok( 'Map::Tube::Glasgow' );

eval { $map->get_line_by_name('XYZ'); };
like($@, qr/\QMap::Tube::get_line_by_name(): ERROR: Invalid Line Name [XYZ]\E/, 'Line XYZ should not exist' );

{
  my $ret = $map->get_line_by_name('SPT');
  isa_ok( $ret,       'Map::Tube::Line' );
  is( $ret->id( ),    'gg_SPT',  'Line id not correct for line named SPT' );
  is( $ret->name( ),  'SPT',     'Node name not correct for line named SPT' );
  is( $ret->color( ), '#68232E', 'Color not correct for line named SPT' );
  my $stationref = $ret->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 15, 'Number of stations incorrect for line named SPT' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Bridge.*West Street$), 'Stations not correct for line named SPT' );
}

{
  my $ret = $map->get_line_by_id('gg_SPT');
  isa_ok( $ret,      'Map::Tube::Line' );
  is( $ret->id( ),   'gg_SPT', 'Line id not correct for line id gg_SPT' );
  is( $ret->name( ), 'SPT',    'Line name not correct for line id gg_SPT' );
}

{
  my $ret = $map->get_lines( );
  isa_ok( $ret,      'ARRAY' );
  my @lines = @{ $ret };
  isa_ok( $lines[0],  'Map::Tube::Line' );
  is( scalar(@lines), 1, 'Number of lines incorrect' );
}


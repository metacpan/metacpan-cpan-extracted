#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More tests => 16;
use Map::Tube::Hamburg;

my $map = new_ok( 'Map::Tube::Hamburg' );

eval { $map->get_line_by_name('XYZ'); };
like($@, qr/\QMap::Tube::get_line_by_name(): ERROR: Invalid Line Name [XYZ]\E/, 'Line XYZ should not exist' );

{
  my $ret = $map->get_line_by_name('U3');
  isa_ok( $ret,       'Map::Tube::Line' );
  is( $ret->id( ),    'hh_U3', 'Line id not correct for line named U3' );
  is( $ret->name( ),  'U3',    'Node name not correct for line named U3' );
  is( $ret->color( ), '#FFDC01', 'Color not correct for line named U3' );
  my $stationref = $ret->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 25, 'Number of stations incorrect for line U3' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Barmbek.*Gartenstadt$), 'Stations not correct for line U3' );
}

{
  my $ret = $map->get_line_by_id('hh_U3');
  isa_ok( $ret,      'Map::Tube::Line' );
  is( $ret->id( ),   'hh_U3', 'Line id not correct for line id hh_U3' );
  is( $ret->name( ), 'U3',    'Line name not correct for line id hh_U3' );
}

{
  my $ret = $map->get_lines( );
  isa_ok( $ret,      'ARRAY' );
  my @lines = @{ $ret };
  isa_ok( $lines[0],  'Map::Tube::Line' );
  is( scalar(@lines), 11, 'Number of lines incorrect' );
}


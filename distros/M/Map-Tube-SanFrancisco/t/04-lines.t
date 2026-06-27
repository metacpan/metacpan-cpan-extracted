#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More tests => 14;
use Map::Tube::SanFrancisco;

my $map = new_ok( 'Map::Tube::SanFrancisco' );

eval { $map->get_line_by_name('XYZ'); };
like($@, qr/\QMap::Tube::get_line_by_name(): ERROR: Invalid Line Name [XYZ]\E/, 'Line XYZ should not exist' );

{
  my $ret = $map->get_line_by_name('Blue Line');
  isa_ok( $ret,       'Map::Tube::Line' );
  is( $ret->id( ),    'SF_BLUE',   'Line id not correct for line named Blue Line' );
  is( $ret->name( ),  'Blue Line', 'Line name not correct for line named Blue Line' );
  is( $ret->color( ), '#009AD9',   'Color not correct for line named Blue Line' );
  my $stationref = $ret->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
}

{
  my $ret = $map->get_line_by_id('SF_BLUE');
  isa_ok( $ret,      'Map::Tube::Line' );
  is( $ret->id( ),   'SF_BLUE',   'Line id not correct for line id SF_BLUE' );
  is( $ret->name( ), 'Blue Line', 'Line name not correct for line id SF_BLUE' );
}

{
  my $ret = $map->get_lines( );
  isa_ok( $ret,      'ARRAY' );
  my @lines = @{ $ret };
  isa_ok( $lines[0],  'Map::Tube::Line' );
  is( scalar(@lines), 17, 'Number of lines incorrect' );
}


#!perl
use 5.12.0;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 16;
use Map::Tube::RheinRuhr;

my $map = new_ok( 'Map::Tube::RheinRuhr' );

eval { $map->get_line_by_name('XYZ'); };
like($@, qr/\QMap::Tube::get_line_by_name(): ERROR: Invalid Line Name [XYZ]\E/, 'Line XYZ should not exist' );

{
  my $ret = $map->get_line_by_name('U42');
  isa_ok( $ret,       'Map::Tube::Line' );
  is( $ret->id( ),    'vrr_U42', 'Line id not correct for line named U42' );
  is( $ret->name( ),  'U42',     'Node name not correct for line named U42' );
  is( $ret->color( ), '#FBBA00', 'Color not correct for line named U42' );
  my $stationref = $ret->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 28, 'Number of stations incorrect for line named U42' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Am Beilst.*Fliedner-Heim$), 'Stations not correct for line U42' );
}

{
  my $ret = $map->get_line_by_id('vrr_U42');
  isa_ok( $ret,      'Map::Tube::Line' );
  is( $ret->id( ),   'vrr_U42', 'Line id not correct for line id vrr_U42' );
  is( $ret->name( ), 'U42',     'Line name not correct for line id vrr_U42' );
}

{
  my $ret = $map->get_lines( );
  isa_ok( $ret,      'ARRAY' );
  my @lines = @{ $ret };
  isa_ok( $lines[0],  'Map::Tube::Line' );
  is( scalar(@lines), 63, 'Number of lines incorrect' );
}


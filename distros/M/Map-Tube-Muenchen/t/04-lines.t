#!perl
use 5.12.0;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 16;
use Map::Tube::Muenchen;

my $map = new_ok( 'Map::Tube::Muenchen' );

eval { $map->get_line_by_name('XYZ'); };
like($@, qr/\QMap::Tube::get_line_by_name(): ERROR: Invalid Line Name [XYZ]\E/, 'Line XYZ should not exist' );

{
  my $ret = $map->get_line_by_name('U4');
  isa_ok( $ret,       'Map::Tube::Line' );
  is( $ret->id( ),    'MVG_U4',  'Line id not correct for line named U4' );
  is( $ret->name( ),  'U4',      'Node name not correct for line named U4' );
  is( $ret->color( ), '#05A983', 'Color not correct for line named U4' );
  my $stationref = $ret->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 13, 'Number of stations incorrect for line named U4' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Arabellapark.*Westendstr\.$), 'Stations not correct for line U4' );
}

{
  my $ret = $map->get_line_by_id('MVG_U4');
  isa_ok( $ret,      'Map::Tube::Line' );
  is( $ret->id( ),   'MVG_U4', 'Line id not correct for line id MVG_U4' );
  is( $ret->name( ), 'U4',     'Line name not correct for line id MVG_U4' );
}

{
  my $ret = $map->get_lines( );
  isa_ok( $ret,      'ARRAY' );
  my @lines = @{ $ret };
  isa_ok( $lines[0],  'Map::Tube::Line' );
  is( scalar(@lines), 27, 'Number of lines incorrect' );
}


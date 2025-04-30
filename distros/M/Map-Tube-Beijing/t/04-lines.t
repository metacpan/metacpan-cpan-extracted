#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More tests => 16;
use Map::Tube::Beijing;

my $map = new_ok('Map::Tube::Beijing');

eval { $map->get_line_by_name('XYZ'); };
like($@, qr/\QMap::Tube::get_line_by_name(): ERROR: Invalid Line Name [XYZ]\E/, 'Line XYZ should not exist' );

{
  my $ret = $map->get_line_by_name('Changping Line');
  isa_ok( $ret,             'Map::Tube::Line' );
  is( $ret->id( ),          'L_changpingline', 'Line id not correct for Changping Line' );
  is( $ret->name( ),        'Changping Line', 'Node name not correct for Changping Line' );
  is( lc( $ret->color( ) ), '#d986ba', 'Color not correct for line Changping Line' );
  my $stationref = $ret->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 18, 'Number of stations incorrect for line Changping Line' );
  like( join( ',', map { $_->name( ) } @stations ),  qr(^Changping.*Xitucheng$), 'Stations not correct for line Changping Line' );
}

{
  my $ret = $map->get_line_by_id('L_changpingline');
  isa_ok( $ret,      'Map::Tube::Line' );
  is( $ret->id( ),   'L_changpingline',  'Line id not correct for Changping Line' );
  is( $ret->name( ), 'Changping Line',   'Line name not correct for Changping Line' );
}

{
  my $ret = $map->get_lines( );
  isa_ok( $ret,      'ARRAY' );
  my @lines = @{ $ret };
  isa_ok( $lines[0],  'Map::Tube::Line' );
  is( scalar(@lines), 25, 'Number of lines incorrect' );
}


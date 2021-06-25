use strict;
use warnings;
use Test::Number::Delta;
use Test::More tests => 6;
use FFI::CheckLib qw{find_lib};
my $lib = find_lib(lib=>'h3');

SKIP: {
  skip 'libh3 not available', 6 unless $lib;

  require_ok 'Geo::H3::FFI';

  my $obj       = Geo::H3::FFI->new;
  isa_ok($obj, 'Geo::H3::FFI');

  #$ h3ToGeo -i 8a2a1072b59ffff
  #40.6894218437 -74.0444313999

  my $string    = '8a2a1072b59ffff';
  my $size      = length($string);
  my $index     = '622236750694711295';
  my $lat       = 40.6894218437;
  my $lon       = -74.0444313999;
  my $lat_rad   = $obj->degsToRads($lat);
  my $lon_rad   = $obj->degsToRads($lon);

  my $geo       = $obj->geo;        #empty structure
  isa_ok($geo, 'Geo::H3::FFI::Struct::GeoCoord');

  my $void2     = $obj->h3ToGeo($index, $geo); #assigns into structure
  isa_ok($geo, 'Geo::H3::FFI::Struct::GeoCoord');
  delta_within($geo->lat, $lat_rad, 1e-11, '$geo->lat');
  delta_within($geo->lon, $lon_rad, 1e-11, '$geo->lon');
}

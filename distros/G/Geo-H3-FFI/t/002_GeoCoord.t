use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 15;
use FFI::CheckLib qw{find_lib};
my $lib = find_lib(lib=>'h3');

SKIP: {
  skip 'libh3 not available', 15 unless $lib;
  require_ok 'Geo::H3::FFI';

  my $obj = Geo::H3::FFI->new;
  isa_ok($obj, 'Geo::H3::FFI');

  my $lat        = 40.689167;
  my $lon        = -74.044444;
  my $lat_rad    = $obj->degsToRads($lat);
  my $lon_rad    = $obj->degsToRads($lon);

  is($lat, $obj->radsToDegs($lat_rad), 'lat round trip');
  is($lon, $obj->radsToDegs($lon_rad), 'lon round trip');

  my $geo        = $obj->geo(lat => $lat_rad, lon => $lon_rad);
  isa_ok($geo, 'Geo::H3::FFI::Struct::GeoCoord');
  can_ok($geo, 'lat');
  can_ok($geo, 'lon');
  is($geo->lat, $lat_rad, 'lat');
  is($geo->lon, $lon_rad, 'lon');

  my $resolution = 10;
  {
    my $index      = $obj->geoToH3($geo, $resolution);

    #$ geoToH3 --lat 40.689167 --lon -74.044444 --resolution 10
    #8a2a1072b59ffff
    is($index, '622236750694711295', 'h3->index');
    is(sprintf("%x", $index), '8a2a1072b59ffff', 'sprintf');
  }

  {
    my $index      = $obj->geoToH3Wrapper(lat=>$lat_rad, lon=>$lon_rad, resolution=>$resolution);

    #$ geoToH3 --lat 40.689167 --lon -74.044444 --resolution 10
    #8a2a1072b59ffff
    is($index, '622236750694711295', 'h3->index');
    is(sprintf("%x", $index), '8a2a1072b59ffff', 'sprintf');
  }
  {
    my $index      = $obj->geoToH3Wrapper(lat=>$lat, lon=>$lon, resolution=>$resolution, uom=>"deg");

    #$ geoToH3 --lat 40.689167 --lon -74.044444 --resolution 10
    #8a2a1072b59ffff
    is($index, '622236750694711295', 'h3->index');
    is(sprintf("%x", $index), '8a2a1072b59ffff', 'sprintf');
  }
}

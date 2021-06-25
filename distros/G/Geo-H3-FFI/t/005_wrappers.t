use strict;
use warnings;
use Test::More tests => 28;

use FFI::CheckLib qw{find_lib};
my $lib = find_lib(lib=>'h3');

SKIP: {
  skip 'libh3 not available', 28 unless $lib;

  require_ok 'Geo::H3::FFI';

  my $obj = Geo::H3::FFI->new;
  isa_ok($obj, 'Geo::H3::FFI');

  my $index  = '622236750694711295';
  my $geo    = $obj->h3ToGeoWrapper($index);
  isa_ok($geo, 'Geo::H3::FFI::Struct::GeoCoord');
  is($geo->lat, '0.710164381905454', '$geo->lat');
  is($geo->lon, '-1.29231912069548', '$geo->lon');

  my $string = $obj->h3ToStringWrapper($index);
  is($string, sprintf("%x", $index), 'h3ToStringWrapper');

  my $gb      = $obj->h3ToGeoBoundaryWrapper($index);
  isa_ok($gb, 'Geo::H3::FFI::Struct::GeoBoundary');

  can_ok($gb, 'num_verts');
  can_ok($gb, 'verts');
  is($gb->num_verts, 6, '$gb->num_verts');

  foreach my $count (1 .. $gb->num_verts) {
    my $vert = $gb->verts->[$count - 1]; #$gb->verts sizeof 10
    isa_ok($vert, 'Geo::H3::FFI::Struct::GeoCoord');
    can_ok($vert, 'lat');
    can_ok($vert, 'lon');
    diag(sprintf("Count: %s, Lat: %s (%s), Lon: %s (%s)", $count, $vert->lat, $obj->radsToDegs($vert->lat),
                                                                  $vert->lon, $obj->radsToDegs($vert->lon)));
  }
}

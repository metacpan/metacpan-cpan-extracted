use strict;
use warnings;
use Test::Number::Delta;
use Test::More tests => 18;
use FFI::CheckLib qw{find_lib};
my $lib = find_lib(lib=>'h3');

SKIP: {
  skip 'libh3 not available', 18 unless $lib;

  require_ok 'Geo::H3::FFI';

  my $obj = Geo::H3::FFI->new;
  isa_ok($obj, 'Geo::H3::FFI');

  #$ geoToH3 --lat 40.689167 --lon -74.044444 --resolution 10
  #8a2a1072b59ffff

  my $index      = 622236750694711295;   #8a2a1072b59ffff
  my $resolution = 10;
  is(sprintf("%x", $index ), '8a2a1072b59ffff', 'index' );

  #$ffi->attach(hexAreaKm2 => ['int'] => 'double');
  my $hexAreaKm2 = $obj->hexAreaKm2($resolution);
  is($hexAreaKm2, 0.0150475, 'hexAreaKm2');

  #$ffi->attach(hexAreaM2 => ['int'] => 'double');
  my $hexAreaM2 = $obj->hexAreaM2($resolution);
  is($hexAreaM2, 15047.5, 'hexAreaM2');

  #$ffi->attach(cellAreaM2 => ['uint64_t'] => 'double');
  my $cellAreaM2 = $obj->cellAreaM2($index);
  is($cellAreaM2, 15111.0082455306, 'cellAreaM2'); #how to verify

  #$ffi->attach(cellAreaRads2 => ['uint64_t'] => 'double');
  my $cellAreaRads2 = $obj->cellAreaRads2($index);
  is($cellAreaRads2, 3.72286470372421e-10, 'cellAreaRads2');

  #$ffi->attach(edgeLengthKm=> ['int'] => 'double');
  my $edgeLengthKm = $obj->edgeLengthKm($resolution);
  is($edgeLengthKm, 0.065907807, 'edgeLengthKm');

  #$ffi->attach(edgeLengthM=> ['int'] => 'double');
  my $edgeLengthM = $obj->edgeLengthM($resolution);
  delta_within($edgeLengthM, 65.907807, 1e-6, 'edgeLengthM');

  {
  local $TODO = 'exactEdgeLengthXXX not working as expected...';

  #$ffi->attach(exactEdgeLengthKm=> ['uint64_t'] => 'double');
  my $exactEdgeLengthKm = $obj->exactEdgeLengthKm($index);
  is($exactEdgeLengthKm, 0.065907807, 'exactEdgeLengthKm');

  #$ffi->attach(exactEdgeLengthM => ['uint64_t'] => 'double');
  my $exactEdgeLengthM = $obj->exactEdgeLengthM($index);
  is($exactEdgeLengthM, 65.907807, 'exactEdgeLengthM');

  #$ffi->attach(exactEdgeLengthRads => ['uint64_t'] => 'double');
  my $exactEdgeLengthRads = $obj->exactEdgeLengthRads($index);
  is($exactEdgeLengthRads, 1.0344958831218645479632869891048e-5, 'exactEdgeLengthRads');
  }

  #$ffi->attach(numHexagons => ['int'] => 'int64_t');
  my $numHexagons = $obj->numHexagons($resolution);
  is($numHexagons, 33897029882, 'numHexagons');

  #$ffi->attach(res0IndexCount => [] => 'int');
  my $res0IndexCount = $obj->res0IndexCount();
  is($res0IndexCount, 122, 'res0IndexCount');

  #$ffi->attach(pentagonIndexCount => [] => 'int');
  my $pentagonIndexCount = $obj->pentagonIndexCount();
  is($pentagonIndexCount, 12, 'pentagonIndexCount');

  my $distanceM = 2819.91206504797; #mean Earth radius Rho = 6371.0071809184764922128882879993
  my $lat1      = 40.689167;
  my $lon1      = -74.044444;
  my $lat1_rad  = $obj->degsToRads($lat1);
  my $lon1_rad  = $obj->degsToRads($lon1);
  my $geo1      = $obj->geo(lat => $lat1_rad, lon => $lon1_rad);
  my $lat2      = 40.703468;
  my $lon2      = -74.016821;
  my $lat2_rad  = $obj->degsToRads($lat2);
  my $lon2_rad  = $obj->degsToRads($lon2);
  my $geo2      = $obj->geo(lat => $lat2_rad, lon => $lon2_rad);

  #$ffi->attach(pointDistKm => ['geo_coord_t', 'geo_coord_t'] => 'double');
  my $pointDistKm = $obj->pointDistKm($geo1, $geo2);
  is($pointDistKm, $distanceM/1_000, 'pointDistKm');

  #$ffi->attach(pointDistM => ['geo_coord_t', 'geo_coord_t'] => 'double');
  my $pointDistM = $obj->pointDistM($geo1, $geo2);
  is($pointDistM, $distanceM, 'pointDistM');

  #$ffi->attach(pointDistRads => ['geo_coord_t', 'geo_coord_t'] => 'double');
  my $pointDistRads = $obj->pointDistRads($geo1, $geo2);
  is($pointDistRads, 0.000442616368961844, 'pointDistRads');
}

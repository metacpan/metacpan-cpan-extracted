use strict;
use warnings;
use Test::Number::Delta;
use Test::More tests => 11;
use FFI::CheckLib qw{find_lib};
my $lib = find_lib(lib=>'h3');

SKIP: {
  skip 'libh3 not available', 11 unless $lib;
  require_ok 'Geo::H3::FFI';

  my $obj = Geo::H3::FFI->new;
  isa_ok($obj, 'Geo::H3::FFI');

  my $geo = $obj->geo;
  isa_ok($geo, 'Geo::H3::FFI::Struct::GeoCoord');

  my $pi  = '3.14159265358979';

  delta_within($obj->degsToRads(0),       0, 1e-11, 'degsToRads');
  delta_within($obj->degsToRads(90),  $pi/2, 1e-11, 'degsToRads');
  delta_within($obj->degsToRads(180),   $pi, 1e-11, 'degsToRads');
  delta_within($obj->degsToRads(360), 2*$pi, 1e-11, 'degsToRads');
  delta_within($obj->radsToDegs(0),       0, 1e-11, 'radsToDegs');
  delta_within($obj->radsToDegs($pi/2),  90, 1e-11, 'radsToDegs');
  delta_within($obj->radsToDegs($pi),   180, 1e-11, 'radsToDegs');
  delta_within($obj->radsToDegs(2*$pi), 360, 1e-11, 'radsToDegs');
}

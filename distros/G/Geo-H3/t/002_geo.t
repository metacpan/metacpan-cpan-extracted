#! --perl--
use strict;
use warnings;
use Test::More tests => 7;
use FFI::CheckLib qw{find_lib};
my $lib = find_lib(lib=>'h3');

SKIP: {
  skip 'libh3 not available', 7 unless $lib;

  require_ok 'Geo::H3::Geo';
  my $lat = 38.780276;
  my $lon = -77.386706;
  my $geo = Geo::H3::Geo->new(lat=>$lat, lon=>$lon);
  isa_ok($geo, 'Geo::H3::Geo');
  can_ok($geo, 'new');
  can_ok($geo, 'lat');
  can_ok($geo, 'lon');
  can_ok($geo, 'h3');
  can_ok($geo, 'distance');
}

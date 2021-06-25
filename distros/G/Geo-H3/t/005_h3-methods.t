use strict;
use warnings;
use Test::Number::Delta;
use Test::More tests => 12;
use FFI::CheckLib qw{find_lib};
my $lib = find_lib(lib=>'h3');
  
#geoToH3 --latitude 40.689167 --longitude -74.044444 --resolution 7
#872a1072bffffff
 
#h3ToGeo --index 872a1072bffffff
#40.6852839752 -74.0302183235

SKIP: {
  skip 'libh3 not available', 12 unless $lib;

  require_ok 'Geo::H3';

  my $index      = 608725951823478783;
  my $resolution = 7;
  my $h3         = Geo::H3->new->h3(index=>$index);
  isa_ok($h3, 'Geo::H3::Index');
  is($h3->index, $index, 'index');
  is($h3->string, '872a1072bffffff', 'string');
  is($h3->resolution, $resolution);

  my $geo        = $h3->geo;
  my $lat        = 40.6852839752;
  my $lon        = -74.0302183235;

  isa_ok($geo, 'Geo::H3::Geo');
  delta_within($geo->lat, $lat, 1e-10, '$geo->lat');
  delta_within($geo->lon, $lon, 1e-10, '$geo->lon');

  ok($h3->isValid,         'isValid');
  ok($h3->isResClassIII,   'isResClassIII');
  ok(!$h3->isPentagon,     'isPentagon');
  is($h3->maxFaceCount, 2, 'maxFaceCount');
}

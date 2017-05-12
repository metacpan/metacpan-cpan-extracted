use Test::More tests => 2;
use Geo::MedianCenter::XS qw/median_center/;
use strict;
use warnings;

my ($lat, $lon) = median_center({
  points => [
    [ 54.721326,  8.704710 ],
    [ 49.484678,  8.476724 ],
    [ 52.129111, 11.634432 ],
  ]
});

is int($lat), 52, "lat ok";
is int($lon), 10, "lat ok";

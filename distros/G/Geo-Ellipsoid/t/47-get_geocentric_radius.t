#!perl

use strict;
use warnings;

use Test::More tests => 10;
use Test::Number::Delta relative => 1e-15;

use Geo::Ellipsoid;

my $geo = Geo::Ellipsoid -> new(ellipsoid  => 'WGS84',
                                angle_unit => 'degrees',
                               );

my $table =
  [
   [  0, 6378137          ],
   [ 10, 6377489.01405125 ],
   [ 20, 6375624.31533888 ],
   [ 30, 6372770.60113719 ],
   [ 40, 6369275.23022569 ],
   [ 50, 6365561.84390246 ],
   [ 60, 6362078.31479107 ],
   [ 70, 6359242.74336278 ],
   [ 80, 6357393.99922064 ],
   [ 90, 6356752.31424518 ],
  ];

for my $entry (@$table) {
    my $angle  = $entry -> [0];
    my $radius = $entry -> [1];
    delta_ok($geo -> get_geocentric_radius($angle), $radius,
             "geocentric radius at angle $angle is within tolerance");
}

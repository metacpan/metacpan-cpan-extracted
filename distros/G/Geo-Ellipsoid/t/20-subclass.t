#!perl

use strict;
use warnings;

use Test::More          tests  => 33;
use Test::Number::Delta within => 1e-14;

###############################################################################
# Geo::Ellipsoid::Subclass is a subclass of Geo::Ellipsoid that implements
# _inverse() and _forward() using cartesian coordinates. This is not useful in
# practice, but it serves the purposes of checking whether its own _inverse()
# and _forward() are called or the ones in the parent class. Geo::Ellipsoid up
# until version 1.12 would only call its own _inverse() and _forward(), even
# for subclasses, so the tests below would fail for Geo::Ellipsoid <= v1.12.

package Geo::Ellipsoid::Subclass;

use Geo::Ellipsoid;
our @ISA = 'Geo::Ellipsoid';

sub _inverse {
    my $self = shift;
    my ($lat0, $lon0, $lat1, $lon1) = @_;
    my $dlat = $lat1 - $lat0;
    my $dlon = $lon1 - $lon0;
    my $rng = sqrt($dlat * $dlat + $dlon * $dlon);
    my $brg = atan2($dlon, $dlat);
    return $rng, $brg;
}

sub _forward {
    my $self = shift;
    my ($lat0, $lon0, $rng, $brg) = @_;
    my $dlat = $rng * cos($brg);
    my $dlon = $rng * sin($brg);
    my $lat1 = $lat0 + $dlat;
    my $lon1 = $lon0 + $dlon;
    return $lat1, $lon1;
}

###############################################################################

package main;

my $geo = Geo::Ellipsoid::Subclass -> new();
isa_ok($geo, 'Geo::Ellipsoid::Subclass');

$geo -> set_units('radians');
$geo -> set_distance_unit('meter');
$geo -> set_custom_ellipsoid('sphere', 1, 1e16);

my $pi = atan2 0, -1;

my $entries =
  [
   [ 0.1, 0.2, 0.2, 0.2, 0.1,              0,       'N',  ],
   [ 0.1, 0.2, 0.2, 0.3, 0.14142135623731, 1/4*$pi, 'NE', ],
   [ 0.1, 0.2, 0.1, 0.3, 0.1,              1/2*$pi, 'E',  ],
   [ 0.1, 0.2, 0,   0.3, 0.14142135623731, 3/4*$pi, 'SE', ],
   [ 0.1, 0.2, 0,   0.2, 0.1,              $pi,     'S',  ],
   [ 0.1, 0.2, 0,   0.1, 0.14142135623731, 5/4*$pi, 'SW', ],
   [ 0.1, 0.2, 0.1, 0.1, 0.1,              3/2*$pi, 'W',  ],
   [ 0.1, 0.2, 0.2, 0.1, 0.14142135623731, 7/4*$pi, 'NW', ],
  ];

for my $entry (@$entries) {
    my ($lat0, $lon0, $lat1, $lon1, $rng0, $brg0, $dir) = @$entry;

    my ($lat, $lon) = $geo -> at($lat0, $lon0, $rng0, $brg0);
    delta_ok($lat, $lat1, "latitude in direction $dir");
    delta_ok($lon, $lon1, "longitude in direction $dir");

    my ($rng, $brg) = $geo -> to($lat0, $lon0, $lat1, $lon1);
    delta_ok($rng, $rng0, "range in direction $dir");
    delta_ok($brg, $brg0, "bearing in direction $dir");
}

1;

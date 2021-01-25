#!perl

use strict;
use warnings;

use Test::More tests => 20;
use Test::Number::Delta relative => 1e-14;

use Geo::Ellipsoid;

my %ellipsoids = (
    'AIRY'               => 0.0816733738741419,
    'AIRY-MODIFIED'      => 0.0816733738741419,
    'AUSTRALIAN'         => 0.0818201799960599,
    'BESSEL-1841'        => 0.0816968312225275,
    'CLARKE-1880'        => 0.0824834000441850,
    'EVEREST-1830'       => 0.0814729809826527,
    'EVEREST-MODIFIED'   => 0.0814729809826527,
    'FISHER-1960'        => 0.0818133340169312,
    'FISHER-1968'        => 0.0818133340169312,
    'GRS80'              => 0.0818191910428322,
    'HAYFORD'            => 0.0819918899790298,
    'HOUGH-1956'         => 0.0819918899790298,
    'IAU76'              => 0.0818192214555232,
    'KRASSOVSKY-1938'    => 0.0818133340169312,
    'NAD27'              => 0.0822718542230180,
    'NWL-9D'             => 0.0818201799960599,
    'SOUTHAMERICAN-1969' => 0.0818201799960599,
    'SOVIET-1985'        => 0.0818192214555232,
    'WGS72'              => 0.0818188106627487,
    'WGS84'              => 0.0818191908426215,
);

for my $ellipsoid (sort keys %ellipsoids) {
    my $e = Geo::Ellipsoid -> new(ellipsoid => $ellipsoid);
    my $r = $e -> get_eccentricity();
    delta_ok($r, $ellipsoids{$ellipsoid},
             "eccentricity for ellipsoid '$ellipsoid'");
}

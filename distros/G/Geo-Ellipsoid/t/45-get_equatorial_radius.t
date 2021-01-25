#!perl

use strict;
use warnings;

use Test::More tests => 20;
use Test::Number::Delta relative => 1e-14;

use Geo::Ellipsoid;

my %ellipsoids = (
    'AIRY'               => 6377563.396,
    'AIRY-MODIFIED'      => 6377340.189,
    'AUSTRALIAN'         => 6378160,
    'BESSEL-1841'        => 6377397.155,
    'CLARKE-1880'        => 6378249.145,
    'EVEREST-1830'       => 6377276.345,
    'EVEREST-MODIFIED'   => 6377304.063,
    'FISHER-1960'        => 6378166,
    'FISHER-1968'        => 6378150,
    'GRS80'              => 6378137,
    'HAYFORD'            => 6378388,
    'HOUGH-1956'         => 6378270,
    'IAU76'              => 6378140,
    'KRASSOVSKY-1938'    => 6378245,
    'NAD27'              => 6378206.4,
    'NWL-9D'             => 6378145,
    'SOUTHAMERICAN-1969' => 6378160,
    'SOVIET-1985'        => 6378136,
    'WGS72'              => 6378135,
    'WGS84'              => 6378137,
);

for my $ellipsoid (sort keys %ellipsoids) {
    my $e = Geo::Ellipsoid -> new(ellipsoid => $ellipsoid);
    my $r = $e -> get_equatorial_radius();
    #printf qq|    %-20s => %s,\n|, "'$ellipsoid'", $r;
    delta_ok($r, $ellipsoids{$ellipsoid},
             "equatorial radius for ellipsoid '$ellipsoid'");
}

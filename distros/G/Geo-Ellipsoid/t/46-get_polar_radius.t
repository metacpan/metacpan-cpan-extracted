#!perl

use strict;
use warnings;

use Test::More tests => 20;
use Test::Number::Delta relative => 1e-14;

use Geo::Ellipsoid;

my %ellipsoids = (
    'AIRY'               => 6356256.90923729,
    'AIRY-MODIFIED'      => 6356034.44793853,
    'AUSTRALIAN'         => 6356774.71919531,
    'BESSEL-1841'        => 6356078.96281819,
    'CLARKE-1880'        => 6356514.86954978,
    'EVEREST-1830'       => 6356075.41314024,
    'EVEREST-MODIFIED'   => 6356103.03899315,
    'FISHER-1960'        => 6356784.28360711,
    'FISHER-1968'        => 6356768.33724438,
    'GRS80'              => 6356752.31414035,
    'HAYFORD'            => 6356911.94612795,
    'HOUGH-1956'         => 6356794.34343434,
    'IAU76'              => 6356755.28815753,
    'KRASSOVSKY-1938'    => 6356863.01877305,
    'NAD27'              => 6356583.79999999,
    'NWL-9D'             => 6356759.76948868,
    'SOUTHAMERICAN-1969' => 6356774.71919531,
    'SOVIET-1985'        => 6356751.30156878,
    'WGS72'              => 6356750.52001609,
    'WGS84'              => 6356752.31424518,
);

for my $ellipsoid (sort keys %ellipsoids) {
    my $e = Geo::Ellipsoid -> new(ellipsoid => $ellipsoid);
    my $r = $e -> get_polar_radius();
    #printf qq|    %-20s => %s,\n|, "'$ellipsoid'", $r;
    delta_ok($r, $ellipsoids{$ellipsoid},
             "polar radius for ellipsoid '$ellipsoid'");
}

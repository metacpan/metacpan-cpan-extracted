#!perl

use strict;
use warnings;

use Test::More tests => 20;
use Test::Number::Delta relative => 1e-14;

use Geo::Ellipsoid;

my %ellipsoids = (
    'AIRY'               => 0.00334085064149708,
    'AIRY-MODIFIED'      => 0.00334085064149708,
    'AUSTRALIAN'         => 0.00335289186923722,
    'BESSEL-1841'        => 0.00334277318217481,
    'CLARKE-1880'        => 0.00340756137869933,
    'EVEREST-1830'       => 0.00332444929666288,
    'EVEREST-MODIFIED'   => 0.00332444929666288,
    'FISHER-1960'        => 0.00335232986925913,
    'FISHER-1968'        => 0.00335232986925913,
    'GRS80'              => 0.00335281068118367,
    'HAYFORD'            => 0.00336700336700337,
    'HOUGH-1956'         => 0.00336700336700337,
    'IAU76'              => 0.00335281317789691,
    'KRASSOVSKY-1938'    => 0.00335232986925913,
    'NAD27'              => 0.00339007530392992,
    'NWL-9D'             => 0.00335289186923722,
    'SOUTHAMERICAN-1969' => 0.00335289186923722,
    'SOVIET-1985'        => 0.00335281317789691,
    'WGS72'              => 0.00335277945416750,
    'WGS84'              => 0.00335281066474748,
);

for my $ellipsoid (sort keys %ellipsoids) {
    my $e = Geo::Ellipsoid -> new(ellipsoid => $ellipsoid);
    my $r = $e -> get_flattening();
    #printf qq|    %-20s => %s,\n|, "'$ellipsoid'", $r;
    delta_ok($r, $ellipsoids{$ellipsoid},
             "flattening for ellipsoid '$ellipsoid'");
}

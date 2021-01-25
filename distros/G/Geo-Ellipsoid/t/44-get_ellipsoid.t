#!perl

use strict;
use warnings;

use Test::More tests => 200;
use Test::Number::Delta relative => 1e-6;

use Geo::Ellipsoid;

my $e0 = Geo::Ellipsoid->new();

my $entries = [
 # name                  # semi-major semi-minor        flattening
 [ 'AIRY',               6377563.396, 6356256.90923729, 0.00334085064149708, ],
 [ 'AIRY-MODIFIED',      6377340.189, 6356034.44793853, 0.00334085064149708, ],
 [ 'AUSTRALIAN',         6378160,     6356774.71919531, 0.00335289186923722, ],
 [ 'BESSEL-1841',        6377397.155, 6356078.96281819, 0.00334277318217481, ],
 [ 'CLARKE-1880',        6378249.145, 6356514.86954978, 0.00340756137869933, ],
 [ 'EVEREST-1830',       6377276.345, 6356075.41314024, 0.00332444929666288, ],
 [ 'EVEREST-MODIFIED',   6377304.063, 6356103.03899315, 0.00332444929666288, ],
 [ 'FISHER-1960',        6378166,     6356784.28360711, 0.00335232986925913, ],
 [ 'FISHER-1968',        6378150,     6356768.33724438, 0.00335232986925913, ],
 [ 'GRS80',              6378137,     6356752.31414035, 0.00335281068118367, ],
 [ 'HAYFORD',            6378388,     6356911.94612795, 0.00336700336700337, ],
 [ 'HOUGH-1956',         6378270,     6356794.34343434, 0.00336700336700337, ],
 [ 'IAU76',              6378140,     6356755.28815753, 0.00335281317789691, ],
 [ 'KRASSOVSKY-1938',    6378245,     6356863.01877305, 0.00335232986925913, ],
 [ 'NAD27',              6378206.4,   6356583.79999999, 0.00339007530392992, ],
 [ 'NWL-9D',             6378145,     6356759.76948868, 0.00335289186923722, ],
 [ 'SOUTHAMERICAN-1969', 6378160,     6356774.71919531, 0.00335289186923722, ],
 [ 'SOVIET-1985',        6378136,     6356751.30156878, 0.00335281317789691, ],
 [ 'WGS72',              6378135,     6356750.52001609, 0.0033527794541675,  ],
 [ 'WGS84',              6378137,     6356752.31424518, 0.00335281066474748, ],
];

for my $entry (@$entries) {
    my ($ellipsoid, $equatorial, $polar, $flattening) = @$entry;
    my $e1 = Geo::Ellipsoid->new();

    $e0->set_ellipsoid($ellipsoid);
    $e1->set_ellipsoid($ellipsoid);

    is($e0->{ellipsoid},        $ellipsoid);
    is($e1->{ellipsoid},        $ellipsoid);

    is($e0 -> get_ellipsoid(),  $ellipsoid);
    is($e1 -> get_ellipsoid(),  $ellipsoid);

    delta_ok($e1->{equatorial}, $equatorial);
    delta_ok($e1->{polar},      $polar);
    delta_ok($e1->{flattening}, $flattening);

    delta_ok($e0->{equatorial}, $equatorial);
    delta_ok($e0->{polar},      $polar);
    delta_ok($e0->{flattening}, $flattening);
}

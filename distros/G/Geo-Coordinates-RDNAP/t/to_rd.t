#!perl -T

use strict;
BEGIN { $^W = 1 }

use Test::More 'no_plan';

use Geo::Coordinates::RDNAP qw/to_rd/;

# Transformations checked at http://www.rdnap.nl/omreken/omreken.html.
my @table = (
#     X(km)  Y(km)   H(m) phi(ddmmss...) lab(dmmss...)   h(m)
    [  155,   463,     0, '52091862245', '5231393343', 43.264, "Amersfoort" ],
    [  227,   619,     5, '53330778370', '6282465367', 45.191, "North" ],
    [   14,   372,    -1, '51191078190', '3215187343', 43.429, "West" ],
    [  200,   307,   323, '50450430222', '6012930458', 369.366, "Southeast" ],
);

for (@table) {
    my ($x, $y, $z, $lat, $lon, $h, $name) = @$_;

    $lat =~ /^(..)(..)(..)(.*)$/;
    $lat = $1+$2/60+("$3.$4"/3600);

    $lon =~ /^(.)(..)(..)(.*)$/;
    $lon = $1+$2/60+("$3.$4"/3600);

    my @coord = to_rd( $lat, $lon, $h);

    # Error should be < ~30 cm in x and y.
    # Error in h is only accurate to the meter.

    ok(abs($coord[0] - $x*1000) < 3e-1, "X $name");
    ok(abs($coord[1] - $y*1000) < 3e-1, "Y $name");
    ok(abs($coord[2] - $z) < 1, "Height $name");
}

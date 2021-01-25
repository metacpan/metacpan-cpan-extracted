#!perl

use strict;
use warnings;

use Test::More tests => 2006;

use Geo::Ellipsoid;
use Math::Trig qw< pi pi2 >;

use lib 't';
use Geo::Ellipsoid::TestUtils qw< rand_latlon >;

# WGS84 defined semi-major axis is 6378137 m
# WGS84 defined reciprocal flattening is 298.257223562
# WGS84 derived semi-minor axis is approximately 6356752.314 m
# WGS84 derived distance from equator to pole is approximatly 10001.966 m.

my $pi    = pi;
my $twopi = pi2;

###############################################################################
# Longitude is not symmetric around zero.

{
    my $e = Geo::Ellipsoid->new(ellipsoid => "WGS84",
                                angle_unit => "radians",
                                longitude_symmetric => 0);

    # Check the value that was set via the constructor.

    ok(!$e -> get_longitude_symmetric(),
       "get_longitude_symmetric() returns false");

    # Set the value via set_longitude_symmetric().

    $e -> set_longitude_symmetric(1);

    # Check the value that was set via the set_longitude_symmetric().

    ok($e -> get_longitude_symmetric(),
       "get_longitude_symmetric() returns true");

    # Set the value via set_longitude_symmetric().

    $e -> set_longitude_symmetric(0);

    # Check the value that was set via the set_longitude_symmetric().

    ok(!$e -> get_longitude_symmetric(),
       "get_longitude_symmetric() returns false");

    # Generate random data and check the longitude.

    for (1 .. 1000) {
        my ($lat0, $lon0) = rand_latlon;
        my $rng = rand 10001.966;
        my $brg = rand $twopi;
        my ($lat1, $lon1) = $e -> at($lat0, $lon0, $rng, $brg);
        ok(0 <= $lon1 && $lon1 < $twopi) or diag <<"EOF";

\$e -> at($lat0, $lon0, $rng, $brg);
    output lat: $lat1
    output lon: $lon1 (does not satisfy 0 <= lon < 2*PI)

EOF
    }
}

###############################################################################
# Longitude is symmetric around zero.

{
    my $e = Geo::Ellipsoid->new(ellipsoid => "WGS84",
                                angle_unit => "radians",
                                longitude_symmetric => 1);

    # Check the value that was set via the constructor.

    ok($e -> get_longitude_symmetric(),
       "get_longitude_symmetric() returns true");

    # Set the value via set_longitude_symmetric().

    $e -> set_longitude_symmetric(0);

    # Check the value that was set via the set_longitude_symmetric().

    ok(!$e -> get_longitude_symmetric(),
       "get_longitude_symmetric() returns false");

    # Set the value via set_longitude_symmetric().

    $e -> set_longitude_symmetric(1);

    # Check the value that was set via the set_longitude_symmetric().

    ok($e -> get_longitude_symmetric(),
       "get_longitude_symmetric() returns true");

    # Generate random data and check the longitude.

    for (1 .. 1000) {
        my ($lat0, $lon0) = rand_latlon;
        my $rng = rand 10001.966;
        my $brg = rand $twopi;
        my ($lat1, $lon1) = $e -> at($lat0, $lon0, $rng, $brg);
        ok(-$pi <= $lon1 && $lon1 < $pi) or diag <<"EOF";

\$e -> at($lat0, $lon0, $rng, $brg);
    output lat: $lat1
    output lon: $lon1 (does not satisfy -PI <= lon < PI)

EOF
    }
}

#!perl

use strict;
use warnings;

use Test::More tests => 2006;

use Geo::Ellipsoid;
use Math::Trig qw< pi pi2 >;

use lib 't';
use Geo::Ellipsoid::TestUtils qw< rand_latlon >;

my $pi    = pi;
my $twopi = pi2;

###############################################################################
# Longitude is not symmetric around zero.

{
    my $e = Geo::Ellipsoid->new(ellipsoid => "WGS84",
                                angle_unit => "radians",
                                bearing_symmetric => 0);

    # Check the value that was set via the constructor.

    ok(!$e -> get_bearing_symmetric(),
       "get_bearing_symmetric() returns false");

    # Set the value via set_bearing_symmetric().

    $e -> set_bearing_symmetric(1);

    # Check the value that was set via the set_bearing_symmetric().

    ok($e -> get_bearing_symmetric(),
       "get_bearing_symmetric() returns true");

    # Set the value via set_bearing_symmetric().

    $e -> set_bearing_symmetric(0);

    # Check the value that was set via the set_bearing_symmetric().

    ok(!$e -> get_bearing_symmetric(),
       "get_bearing_symmetric() returns false");

    # Generate random data and check the bearing.

    for (1 .. 1000) {
        my ($lat0, $lon0) = rand_latlon;
        my ($lat1, $lon1) = rand_latlon;
        my $bearing = $e -> bearing($lat0, $lon0, $lat1, $lon1);
        ok(0 <= $bearing && $bearing < $twopi) or diag <<"EOF";

\$e -> bearing($lat0, $lon0, $lat1, $lon1);
    output bearing: $bearing (does not satisfy 0 <= lon < 2*PI)

EOF
    }
}

###############################################################################
# Bearing is symmetric around zero.

{
    my $e = Geo::Ellipsoid->new(ellipsoid => "WGS84",
                                angle_unit => "radians",
                                bearing_symmetric => 1);

    # Check the value that was set via the constructor.

    ok($e -> get_bearing_symmetric(),
       "get_bearing_symmetric() returns true");

    # Set the value via set_bearing_symmetric().

    $e -> set_bearing_symmetric(0);

    # Check the value that was set via the set_bearing_symmetric().

    ok(!$e -> get_bearing_symmetric(),
       "get_bearing_symmetric() returns false");

    # Set the value via set_bearing_symmetric().

    $e -> set_bearing_symmetric(1);

    # Check the value that was set via the set_bearing_symmetric().

    ok($e -> get_bearing_symmetric(),
       "get_bearing_symmetric() returns true");

    # Generate random data and check the bearing.

    for (1 .. 1000) {
        my ($lat0, $lon0) = rand_latlon;
        my ($lat1, $lon1) = rand_latlon;
        my $bearing = $e -> bearing($lat0, $lon0, $lat1, $lon1);
        ok(-$pi <= $bearing && $bearing < $pi) or diag <<"EOF";

\$e -> bearing($lat0, $lon0, $lat1, $lon1);
    output bearing: $bearing (does not satisfy -PI <= bearing < PI)

EOF
    }
}

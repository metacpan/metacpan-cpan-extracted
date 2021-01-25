package Geo::Ellipsoid::TestUtils;

use strict;
use warnings;

use Math::Trig qw< asin >;

require Exporter;
our @ISA       = qw< Exporter >;
our @EXPORT_OK = qw< rand_latlon >;

# Return latitude and longitude in radians for a point randomly distributed on
# the surface of a sphere.

sub rand_latlon {

    # Generate a random 3D point uniformly distributed inside a unit sphere.

    my ($x, $y, $z, $dist_sq);
  LOOP: {
        $x = -1 + 2 * rand;
        $y = -1 + 2 * rand;
        $z = -1 + 2 * rand;
        $dist_sq = $x * $x + $y * $y + $z * $z;
        redo LOOP if $dist_sq > 1;
    }

    # Normalize by the length to get a 3D point uniformly distributed on the
    # surface of a unit sphere.

    my $d = sqrt $dist_sq;
    $x /= $d;
    $y /= $d;
    $z /= $d;

    # Convert from (x,y,z) coordinates to (lat,lon) coordinates.

    my $lat = asin $z;
    my $lon = atan2 $y, $x;
    return $lat, $lon;
}

1;

package Geo::Compass::Variation;

use strict; 
use warnings;

our $VERSION = '0.01';

use Exporter qw(import);
 
our @EXPORT_OK = qw(
    mag_dec
    mag_var
    mag_inc
);
 
our %EXPORT_TAGS;
$EXPORT_TAGS{all} = [@EXPORT_OK];

use constant {
    DEG2RAD             => atan2(1, 1) / 45,
    WMM_RELEASE_YEAR    => 2015,
    WMM_EXPIRE_YEAR     => 2019,
    DEFAULT_YEAR_ARG    => 2017.5,
    DEFAULT_ALT_ARG     => 0,
};

*mag_var = \&mag_dec;

sub mag_dec {
    my ($X, $Y) = mag_field(_args(@_));
    return atan2($Y, $X) / DEG2RAD;
}
sub mag_inc {
    my ($X, $Y, $Z) = mag_field(_args(@_));
    return atan2($Z, sqrt($X*$X + $Y*$Y)) / DEG2RAD;
}
sub mag_field {
    my ($lat, $lon, $hgt, $yr) = @_;

    $lon *= DEG2RAD;
    $lat *= DEG2RAD;

    my @WMM = _wmm();

    my ($geo_r, $geo_lat) = do {
        # geocentric coordinates
        my $A = 6378137;

        # reference ellipsoid semimajor axis
        my $f = 1 / 298.257223563;

        # flattening
        my $e2 = $f * (2 - $f);

        # eccentricity
        my $Rc = $A / sqrt(1 - $e2 * sin($lat) ** 2);

        # radius of curvature
        my $p = ($Rc + $hgt) * cos($lat);

        # radius in x-y plane
        my $z = ($Rc * (1 - $e2) + $hgt) * sin($lat);
        (sqrt($p * $p + $z * $z), atan2($z, $p))
    };
    my $s = sin($geo_lat);
    my $c = cos($geo_lat);

    # associated Legendre polynomials (P) and derivatives (dP)
    my @P = ([ 1 ], [ $s, $c ]);
    my @dP = ([ 0 ], [ $c, - $s ]);
    for my $n (2 .. $#WMM) {
        my $k = 2 * $n - 1;
        for my $m (0 .. $n - 2) {
            my $k1 = $k / ($n - $m);
            my $k2 = ($n + $m - 1) / ($n - $m);
            $P[$n][$m] = $k1 * $s * $P[$n - 1][$m] - $k2 * $P[$n - 2][$m];
            $dP[$n][$m] = $k1 * ($s * $dP[$n - 1][$m] + $c * $P[$n - 1][$m])
                - $k2 * $dP[$n - 2][$m];
        }
        my $y = $k * $P[$n - 1][$n - 1];
        my $dy = $k * $dP[$n - 1][$n - 1];
        $P[$n][$n - 1] = $s * $y;
        $dP[$n][$n - 1] = $s * $dy + $c * $y;
        $P[$n][$n] = $c * $y;
        $dP[$n][$n] = $c * $dy - $s * $y;
    }

    # Schmidt quasi-normalization
    for my $n (1 .. $#WMM) {
        my $f = sqrt(2);
        for my $m (1 .. $n) {
            $f /= sqrt(($n - $m + 1) * ($n + $m));
            $P[$n][$m] *= $f;
            $dP[$n][$m] *= $f;
        }
    }

    my $X = 0;                  # magnetic field north component in nT
    my $Y = 0;                  # east component
    my $Z = 0;                  # vertical component
    my $t = $yr - 2015;
    my $r = 6371200 / $geo_r;   # radius relative to geomagnetic reference
    my $R = $r * $r;
    my @c = map cos($_ * $lon), 0 .. $#WMM;
    my @s = map sin($_ * $lon), 0 .. $#WMM;
    for my $n (1 .. $#WMM) {
        my $x = my $y = my $z = 0;
        for my $m (0 .. $n) {
            my $row = $WMM[$n][$m];
            my $g = $row->[0] + $t * $row->[2];
            my $h = $row->[1] + $t * $row->[3];
            $x += ($g * $c[$m] + $h * $s[$m]) * $dP[$n][$m];
            $y += ($g * $s[$m] - $h * $c[$m]) * $P[$n][$m] * $m;
            $z += ($g * $c[$m] + $h * $s[$m]) * $P[$n][$m];
        }
        $R *= $r;
        $X -= $x * $R;
        $Y += $y * $R;
        $Z -= $z * $R * ($n + 1);
    }
    $Y /= $c;

    $c = cos($geo_lat - $lat); # transform back to geodetic coords
    $s = sin($geo_lat - $lat);
    ($X, $Z) = ($X * $c - $Z * $s, $X * $s + $Z * $c);

    return ($X, $Y, $Z);
}
sub _args {
    die "Minimum latitude and longitude must be sent in\n" if @_ < 2;

    my ($lat, $lon, $alt, $year) = @_;

    die "Latitude must be a number\n" if $lat !~ /^-?\d+(?:\.\d+)?$/;
    die "Longitude must be a number\n" if $lon !~ /^-?\d+(?:\.\d+)?$/;
    die "Altitude must be an integer\n" if defined $alt && $alt !~ /^\d+$/;
    die "Year must be a number\n"
      if defined $year && $year !~ /^-?\d+(?:\.\d+)?$/;

    if ($lat < -180 || $lat > 180){
       die "Latitude must be between -180 and 180 degrees\n";
    }
    if ($lon < -180 || $lon > 180){
       die "Longitude must be between -180 and 180 degrees\n";
    }

    $alt = defined $alt ? $alt : DEFAULT_ALT_ARG;

    if (defined $year){
       if ($year < WMM_RELEASE_YEAR || $year > WMM_EXPIRE_YEAR){
           die "Calculation model has expired: "
               . WMM_RELEASE_YEAR . '-' . WMM_EXPIRE_YEAR . "\n";
       }
    }
    else {
       $year = DEFAULT_YEAR_ARG;
    }

    return ($lat, $lon, $alt, $year);
}
sub _wmm {
    # 2015
    my $wmm = [
        [],
        [ [-29438.5, 0, 10.7, 0],
          [-1501.1, 4796.2, 17.9, -26.8] ],
        [ [-2445.3, 0, -8.6, 0],
          [3012.5, -2845.6, -3.3, -27.1],
          [1676.6, -642, 2.4, -13.3] ],
        [ [1351.1, 0, 3.1, 0],
          [-2352.3, -115.3, -6.2, 8.4],
          [1225.6, 245, -0.4, -0.4],
          [581.9, -538.3, -10.4, 2.3] ],
        [ [907.2, 0, -0.4, 0],
          [813.7, 283.4, 0.8, -0.6],
          [120.3, -188.6, -9.2, 5.3],
          [-335, 180.9, 4, 3],
          [70.3, -329.5, -4.2, -5.3] ],
        [ [-232.6, 0, -0.2, 0],
          [360.1, 47.4, 0.1, 0.4],
          [192.4, 196.9, -1.4, 1.6],
          [-141, -119.4, 0, -1.1],
          [-157.4, 16.1, 1.3, 3.3],
          [4.3, 100.1, 3.8, 0.1] ],
        [ [69.5, 0, -0.5, 0],
          [67.4, -20.7, -0.2, 0],
          [72.8, 33.2, -0.6, -2.2],
          [-129.8, 58.8, 2.4, -0.7],
          [-29, -66.5, -1.1, 0.1],
          [13.2, 7.3, 0.3, 1],
          [-70.9, 62.5, 1.5, 1.3] ],
        [ [81.6, 0, 0.2, 0],
          [-76.1, -54.1, -0.2, 0.7],
          [-6.8, -19.4, -0.4, 0.5],
          [51.9, 5.6, 1.3, -0.2],
          [15, 24.4, 0.2, -0.1],
          [9.3, 3.3, -0.4, -0.7],
          [-2.8, -27.5, -0.9, 0.1],
          [6.7, -2.3, 0.3, 0.1] ],
        [ [24, 0, 0, 0],
          [8.6, 10.2, 0.1, -0.3],
          [-16.9, -18.1, -0.5, 0.3],
          [-3.2, 13.2, 0.5, 0.3],
          [-20.6, -14.6, -0.2, 0.6],
          [13.3, 16.2, 0.4, -0.1],
          [11.7, 5.7, 0.2, -0.2],
          [-16, -9.1, -0.4, 0.3],
          [-2, 2.2, 0.3, 0] ],
        [ [5.4, 0, 0, 0],
          [8.8, -21.6, -0.1, -0.2],
          [3.1, 10.8, -0.1, -0.1],
          [-3.1, 11.7, 0.4, -0.2],
          [0.6, -6.8, -0.5, 0.1],
          [-13.3, -6.9, -0.2, 0.1],
          [-0.1, 7.8, 0.1, 0],
          [8.7, 1, 0, -0.2],
          [-9.1, -3.9, -0.2, 0.4],
          [-10.5, 8.5, -0.1, 0.3] ],
        [ [-1.9, 0, 0, 0],
          [-6.5, 3.3, 0, 0.1],
          [0.2, -0.3, -0.1, -0.1],
          [0.6, 4.6, 0.3, 0],
          [-0.6, 4.4, -0.1, 0],
          [1.7, -7.9, -0.1, -0.2],
          [-0.7, -0.6, -0.1, 0.1],
          [2.1, -4.1, 0, -0.1],
          [2.3, -2.8, -0.2, -0.2],
          [-1.8, -1.1, -0.1, 0.1],
          [-3.6, -8.7, -0.2, -0.1] ],
        [ [3.1, 0, 0, 0],
          [-1.5, -0.1, 0, 0],
          [-2.3, 2.1, -0.1, 0.1],
          [2.1, -0.7, 0.1, 0],
          [-0.9, -1.1, 0, 0.1],
          [0.6, 0.7, 0, 0],
          [-0.7, -0.2, 0, 0],
          [0.2, -2.1, 0, 0.1],
          [1.7, -1.5, 0, 0],
          [-0.2, -2.5, 0, -0.1],
          [0.4, -2, -0.1, 0],
          [3.5, -2.3, -0.1, -0.1] ],
        [ [-2, 0, 0.1, 0],
          [-0.3, -1, 0, 0],
          [0.4, 0.5, 0, 0],
          [1.3, 1.8, 0.1, -0.1],
          [-0.9, -2.2, -0.1, 0],
          [0.9, 0.3, 0, 0],
          [0.1, 0.7, 0.1, 0],
          [0.5, -0.1, 0, 0],
          [-0.4, 0.3, 0, 0],
          [-0.4, 0.2, 0, 0],
          [0.2, -0.9, 0, 0],
          [-0.9, -0.2, 0, 0],
          [0, 0.7, 0, 0] 
        ],
    ];

    return @$wmm;
}
sub _pod_placeholder {}

1; __END__

=head1 NAME

Geo::Compass::Variation - Accurately calculate magnetic declination and
inclination

=head1 SYNOPSIS

    use Geo::Compass::Variation qw(mag_dec mag_inc);

    my $lat = 53.1234567;
    my $lon = -114.1234567;
    my $alt = 1098;

    my $declination = mag_dec($lat, $lon, $alt);
    my $inclination = mag_inc($lat, $lon, $alt);

=head1 DESCRIPTION

This module calculates and returns the Magnetic declination and inclination
(dip) calculations based on WMM earth magnetism model for a specified latitude
and longitude pair.

See L<NOAA|https://www.ngdc.noaa.gov/geomag/WMM/DoDWMM.shtml> for details.

=head1 EXPORT_OK

All functions must be imported explicitly:

    use Geo::Compass::Variation qw(mag_dec mag_inc);

    # or

    use Geo::Compass::Variation qw(:all);

Note: The C<mag_dec> function has an alias of C<mag_var> which can be imported
explicitly, or with the C<:all> tag.

=head1 FUNCTIONS

=head2 mag_dec

Calculates and returns the magnetic declination of a pair of GPS coordinates.

Parameters:

    $lat

Mandatory, Float: Latitude, in signed notation (eg: C<53.1111111>. Negative is
South and positive is North of the Equator.

    $lon

Mandatory, Float: Longitude, in signed notiation (eg: C<-114.11111>. Negative is
West and positive is East of the Prime Meridian.

    $alt

Optional, Integer: Altitude above sea level, in metres. Defaults to C<0>.

    $year

Optional, Integer|Float: The year to base the calculation from. Defaults to
C<2017.5>.

Return: A floating point number representing the magnetic declination.

=head2 mag_var

Simply an alias for L</mag_dec>.

=head2 mag_inc

Calculates and returns the magnetic inclination of a pair of GPS coordinates.

Parameters:

Parameters are exactly the same as for the L</mag_dec> function. Please review
that documentation section for full details.

Return: A floating point number representing the magnetic inclination.

=head2 mag_field

Core function that calcluates the raw magnetic field north component (C<$X>),
the east component (C<$Y>) and the vertical component (C<$Z>).

Takes the same parameters as L</mag_dec>. Please see that function's
documentation for full details.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

All the thanks goes out to L<no_slogan|http://perlmonks.org/?node_id=78006> of 
L<Perlmonks|http://perlmonks.org> for all of the core functionality.

It was presented L<here|http://perlmonks.org/?node_id=1191907>, in response to
L<this thread|http://perlmonks.org/?node_id=1191753> I had started regarding a
code review of some prototype code I wrote to calculate the direction between
two pairs of GPS coordinates.

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


package Geo::Compass::Variation;

use strict; 
use warnings;

our $VERSION = '1.06';

use Carp qw(croak);
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
    WMM_RELEASE_YEAR    => 2020,
    WMM_EXPIRE_YEAR     => 2024,
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
    my $t = $yr - WMM_RELEASE_YEAR;
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
    croak("Minimum latitude and longitude must be sent in\n") if @_ < 2;

    my ($lat, $lon, $alt, $year) = @_;

    croak("Latitude must be a number\n") if $lat !~ /^-?\d+(?:\.\d+)?$/;
    croak("Longitude must be a number\n") if $lon !~ /^-?\d+(?:\.\d+)?$/;
    croak("Altitude must be an integer\n") if defined $alt && $alt !~ /^\d+$/;
    croak("Year must be a number\n")
      if defined $year && $year !~ /^-?\d+(?:\.\d+)?$/;

    if ($lat < -180 || $lat > 180){
       croak("Latitude must be between -180 and 180 degrees\n");
    }
    if ($lon < -180 || $lon > 180){
       croak("Longitude must be between -180 and 180 degrees\n");
    }

    $alt = defined $alt ? $alt : DEFAULT_ALT_ARG;
    $year = defined $year ? $year : _calc_year();

    if ($year < WMM_RELEASE_YEAR || $year > WMM_EXPIRE_YEAR){
        warn "Calculation model is expired: "
            . WMM_RELEASE_YEAR . '-' . WMM_EXPIRE_YEAR . "\n";
    }

    return ($lat, $lon, $alt, $year);
}
sub _calc_year {
    my (undef, undef, undef, undef, $month_num, $year) = localtime;
    $year += 1900;
    $month_num += 1; # starts at zero

    # normalization of month, where:
    # oldvalue = $month_num
    # oldmin = 1 (month starts at one)
    # newmax = 10
    # newmin = 1
    # oldmax = 12

    # ((oldvalue - oldmin) * (newmax - newmin)) / (oldmax - oldmin) + newmin
    my $month_normalized = int(((($month_num - 1) * (10 - 1)) / (12 - 1)) + 1);

    return "$year.$month_normalized";
}
sub _wmm {
    # 2015 v2
    my $wmm = [
        [],
        [[-29404.5, "0.0", 6.7, "0.0"], [-1450.7, 4652.9, 7.7, -25.1]],
        [
            ["-2500.0", "0.0", -11.5, "0.0"],
            ["2982.0", -2991.6, -7.1, -30.2],
            [1676.8, -734.8, -2.2, -23.9],
        ],
        [
            [1363.9, "0.0", 2.8, "0.0"],
            ["-2381.0", -82.2, -6.2, 5.7],
            [1236.2, 241.8, 3.4, "-1.0"],
            [525.7, -542.9, -12.2, 1.1],
        ],
        [
            [903.1, "0.0", -1.1, "0.0"],
            [809.4, "282.0", -1.6, 0.2],
            [86.2, -158.4, "-6.0", 6.9],
            [-309.4, 199.8, 5.4, 3.7],
            [47.9, -350.1, -5.5, -5.6],
        ],
        [
            [-234.4, "0.0", -0.3, "0.0"],
            [363.1, 47.7, 0.6, 0.1],
            [187.8, 208.4, -0.7, 2.5],
            [-140.7, -121.3, 0.1, -0.9],
            [-151.2, 32.2, 1.2, "3.0"],
            [13.7, 99.1, "1.0", 0.5],
        ],
        [
            [65.9, "0.0", -0.6, "0.0"],
            [65.6, -19.1, -0.4, 0.1],
            ["73.0", "25.0", 0.5, -1.8],
            [-121.5, 52.7, 1.4, -1.4],
            [-36.2, -64.4, -1.4, 0.9],
            [13.5, "9.0", "-0.0", 0.1],
            [-64.7, 68.1, 0.8, "1.0"],
        ],
        [
            [80.6, "0.0", -0.1, "0.0"],
            [-76.8, -51.4, -0.3, 0.5],
            [-8.3, -16.8, -0.1, 0.6],
            [56.5, 2.3, 0.7, -0.7],
            [15.8, 23.5, 0.2, -0.2],
            [6.4, -2.2, -0.5, -1.2],
            [-7.2, -27.2, -0.8, 0.2],
            [9.8, -1.9, "1.0", 0.3],
        ],
        [
            [23.6, "0.0", -0.1, "0.0"],
            [9.8, 8.4, 0.1, -0.3],
            [-17.5, -15.3, -0.1, 0.7],
            [-0.4, 12.8, 0.5, -0.2],
            [-21.1, -11.8, -0.1, 0.5],
            [15.3, 14.9, 0.4, -0.3],
            [13.7, 3.6, 0.5, -0.5],
            [-16.5, -6.9, "0.0", 0.4],
            [-0.3, 2.8, 0.4, 0.1],
        ],
        [
            ["5.0", "0.0", -0.1, "0.0"],
            [8.2, -23.3, -0.2, -0.3],
            [2.9, 11.1, "-0.0", 0.2],
            [-1.4, 9.8, 0.4, -0.4],
            [-1.1, -5.1, -0.3, 0.4],
            [-13.3, -6.2, "-0.0", 0.1],
            [1.1, 7.8, 0.3, "-0.0"],
            [8.9, 0.4, "-0.0", -0.2],
            [-9.3, -1.5, "-0.0", 0.5],
            [-11.9, 9.7, -0.4, 0.2],
        ],
        [
            [-1.9, "0.0", "0.0", "0.0"],
            [-6.2, 3.4, "-0.0", "-0.0"],
            [-0.1, -0.2, "-0.0", 0.1],
            [1.7, 3.5, 0.2, -0.3],
            [-0.9, 4.8, -0.1, 0.1],
            [0.6, -8.6, -0.2, -0.2],
            [-0.9, -0.1, "-0.0", 0.1],
            [1.9, -4.2, -0.1, "-0.0"],
            [1.4, -3.4, -0.2, -0.1],
            [-2.4, -0.1, -0.1, 0.2],
            [-3.9, -8.8, "-0.0", "-0.0"],
        ],
        [
            ["3.0", "0.0", "-0.0", "0.0"],
            [-1.4, "-0.0", -0.1, "-0.0"],
            [-2.5, 2.6, "-0.0", 0.1],
            [2.4, -0.5, "0.0", "0.0"],
            [-0.9, -0.4, "-0.0", 0.2],
            [0.3, 0.6, -0.1, "-0.0"],
            [-0.7, -0.2, "0.0", "0.0"],
            [-0.1, -1.7, "-0.0", 0.1],
            [1.4, -1.6, -0.1, "-0.0"],
            [-0.6, "-3.0", -0.1, -0.1],
            [0.2, "-2.0", -0.1, "0.0"],
            [3.1, -2.6, -0.1, "-0.0"],
        ],
        [
            ["-2.0", "0.0", "0.0", "0.0"],
            [-0.1, -1.2, "-0.0", "-0.0"],
            [0.5, 0.5, "-0.0", "0.0"],
            [1.3, 1.3, "0.0", -0.1],
            [-1.2, -1.8, "-0.0", 0.1],
            [0.7, 0.1, "-0.0", "-0.0"],
            [0.3, 0.7, "0.0", "0.0"],
            [0.5, -0.1, "-0.0", "-0.0"],
            [-0.2, 0.6, "0.0", 0.1],
            [-0.5, 0.2, "-0.0", "-0.0"],
            [0.1, -0.9, "-0.0", "-0.0"],
            [-1.1, "-0.0", "-0.0", "0.0"],
            [-0.3, 0.5, -0.1, -0.1],
        ],
    ];

    return @$wmm;
}
sub _pod_placeholder {}

1; __END__

=head1 NAME

Geo::Compass::Variation - Accurately calculate magnetic declination and
inclination

=for html
<a href="http://travis-ci.com/stevieb9/geo-compass-variation"><img src="https://www.travis-ci.com/stevieb9/geo-compass-variation.svg?branch=master"/>
<a href='https://coveralls.io/github/stevieb9/geo-compass-variation?branch=master'><img src='https://coveralls.io/repos/stevieb9/geo-compass-variation/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>

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

The WMM data is currently valid from January 1, 2020 through December 31, 2024.
This module will be updated with new WMM data as it becomes available. (Last
update was the Dec 10, 2019 dataset).

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
C<YYYY.M>, where C<YYYY> is the year from C<localtime()> and C<M> is the month
number from C<localtime()>, normalized to a digit between 1-10.

We will C<warn()> if the year is out of range of the current WMM specification.

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

Copyright 2017-2020 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


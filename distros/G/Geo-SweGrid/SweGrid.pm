package Geo::SweGrid;

use strict;
use Math::Trig;

our $VERSION = "1.0";

=head1 NAME

Geo::SweGrid - Convert coordinates between geodetic WGS84 and Swedish grid RT90 and SWEREF99 systems

=head1 SYNOPSIS

  use Geo::SweGrid;

  my $grid = Geo::SweGrid->new("rt90_2.5_gon_v") or die "No grid, projection not recognized";

  my ($lat, $lon) = $grid->grid_to_geodetic(7011002, 1299996);

  my ($x, $y) = $grid->geodetic_to_grid(63.1530261140462, 11.8353976399345);


=head1 DESCRIPTION

Convert coordinates between geodetic WGS84 and Swedish grid RT90 and SWEREF99 systems.

Implementation of "Gauss Conformal Projection (Transverse Mercator), Krügers Formulas".

Parameters for SWEREF99 lat-long to/from RT90 and SWEREF99
coordinates (RT90 and SWEREF99 are used in Swedish maps).


=over 2

=item $grid = Geo::SweGrid->new($projection)

Constructor for Geo::SweGrid

Creates an instance and sets up parameters for the given RT90 or SWEREF99TM projection.
Note: Parameters for RT90 are choosen to eliminate the
differences between Bessel and GRS80-ellipsoides.
Bessel-variants should only be used if lat/long are given as
RT90-lat/long based on the Bessel ellipsoide (from old maps).

Parameters:

 $projection (string). Must match a recognized projection.

List of supported projections:

  rt90_0.0_gon_v
  rt90_2.5_gon_o
  rt90_2.5_gon_v
  rt90_5.0_gon_o
  rt90_5.0_gon_v
  rt90_7.5_gon_v
  bessel_rt90_0.0_gon_v
  bessel_rt90_2.5_gon_o
  bessel_rt90_2.5_gon_v
  bessel_rt90_5.0_gon_o
  bessel_rt90_5.0_gon_v
  bessel_rt90_7.5_gon_v
  sweref_99_1200
  sweref_99_1330
  sweref_99_1415
  sweref_99_1500
  sweref_99_1545
  sweref_99_1630
  sweref_99_1715
  sweref_99_1800
  sweref_99_1845
  sweref_99_2015
  sweref_99_2145
  sweref_99_2315
  sweref_99_tm


Example:

 my $grid = Geo::SweGrid->new("rt90_2.5_gon_v") or die "No grid, projection not recognized";

Returns:

the created instance;

=cut

sub new {
	my $class = shift;
	my $projection = shift;
	my $self = bless {}, $class;

	$self->{axis}             = undef; # Semi-major axis of the ellipsoid.
	$self->{flattening}       = undef; # Flattening of the ellipsoid.
	$self->{central_meridian} = undef; # Central meridian for the projection.
	$self->{lat_of_origin}    = undef; # Latitude of origin.
	$self->{scale}            = undef; # Scale on central meridian.
	$self->{false_northing}   = undef; # Offset for origo.
	$self->{false_easting}    = undef; # Offset for origo.

	# RT90 parameters, GRS 80 ellipsoid.
	if ($projection eq "rt90_7.5_gon_v") {
		$self->_grs80_params();
		$self->{central_meridian} = 11.0 + 18.375/60.0;
		$self->{scale} = 1.000006000000;
		$self->{false_northing} = -667.282;
		$self->{false_easting} = 1500025.141;
	}
	elsif ($projection eq "rt90_5.0_gon_v") {
		$self->_grs80_params();
		$self->{central_meridian} = 13.0 + 33.376/60.0;
		$self->{scale} = 1.000005800000;
		$self->{false_northing} = -667.130;
		$self->{false_easting} = 1500044.695;
	}
	elsif ($projection eq "rt90_2.5_gon_v") {
		$self->_grs80_params();
		$self->{central_meridian} = 15.0 + 48.0/60.0 + 22.624306/3600.0;
		$self->{scale} = 1.00000561024;
		$self->{false_northing} = -667.711;
		$self->{false_easting} = 1500064.274;
	}
	elsif ($projection eq "rt90_0.0_gon_v") {
		$self->_grs80_params();
		$self->{central_meridian} = 18.0 + 3.378/60.0;
		$self->{scale} = 1.000005400000;
		$self->{false_northing} = -668.844;
		$self->{false_easting} = 1500083.521;
	}
	elsif ($projection eq "rt90_2.5_gon_o") {
		$self->_grs80_params();
		$self->{central_meridian} = 20.0 + 18.379/60.0;
		$self->{scale} = 1.000005200000;
		$self->{false_northing} = -670.706;
		$self->{false_easting} = 1500102.765;
	}
	elsif ($projection eq "rt90_5.0_gon_o") {
		$self->_grs80_params();
		$self->{central_meridian} = 22.0 + 33.380/60.0;
		$self->{scale} = 1.000004900000;
		$self->{false_northing} = -672.557;
		$self->{false_easting} = 1500121.846;
	}

	# RT90 parameters, Bessel 1841 ellipsoid.
	elsif ($projection eq "bessel_rt90_7.5_gon_v") {
		$self->_bessel_params();
		$self->{central_meridian} = 11.0 + 18.0/60.0 + 29.8/3600.0;
	}
	elsif ($projection eq "bessel_rt90_5.0_gon_v") {
		$self->_bessel_params();
		$self->{central_meridian} = 13.0 + 33.0/60.0 + 29.8/3600.0;
	}
	elsif ($projection eq "bessel_rt90_2.5_gon_v") {
		$self->_bessel_params();
		$self->{central_meridian} = 15.0 + 48.0/60.0 + 29.8/3600.0;
	}
	elsif ($projection eq "bessel_rt90_0.0_gon_v") {
		$self->_bessel_params();
		$self->{central_meridian} = 18.0 + 3.0/60.0 + 29.8/3600.0;
	}
	elsif ($projection eq "bessel_rt90_2.5_gon_o") {
		$self->_bessel_params();
		$self->{central_meridian} = 20.0 + 18.0/60.0 + 29.8/3600.0;
	}
	elsif ($projection eq "bessel_rt90_5.0_gon_o") {
		$self->_bessel_params();
		$self->{central_meridian} = 22.0 + 33.0/60.0 + 29.8/3600.0;
	}

	# SWEREF99TM and SWEREF99ddmm  parameters.
	elsif ($projection eq "sweref_99_tm") {
		$self->_sweref99_params();
		$self->{central_meridian} = 15.00;
		$self->{lat_of_origin} = 0.0;
		$self->{scale} = 0.9996;
		$self->{false_northing} = 0.0;
		$self->{false_easting} = 500000.0;
	}
	elsif ($projection eq "sweref_99_1200") {
		$self->_sweref99_params();
		$self->{central_meridian} = 12.00;
	}
	elsif ($projection eq "sweref_99_1330") {
		$self->_sweref99_params();
		$self->{central_meridian} = 13.50;
	}
	elsif ($projection eq "sweref_99_1500") {
		$self->_sweref99_params();
		$self->{central_meridian} = 15.00;
	}
	elsif ($projection eq "sweref_99_1630") {
		$self->_sweref99_params();
		$self->{central_meridian} = 16.50;
	}
	elsif ($projection eq "sweref_99_1800") {
		$self->_sweref99_params();
		$self->{central_meridian} = 18.00;
	}
	elsif ($projection eq "sweref_99_1415") {
		$self->_sweref99_params();
		$self->{central_meridian} = 14.25;
	}
	elsif ($projection eq "sweref_99_1545") {
		$self->_sweref99_params();
		$self->{central_meridian} = 15.75;
	}
	elsif ($projection eq "sweref_99_1715") {
		$self->_sweref99_params();
		$self->{central_meridian} = 17.25;
	}
	elsif ($projection eq "sweref_99_1845") {
		$self->_sweref99_params();
		$self->{central_meridian} = 18.75;
	}
	elsif ($projection eq "sweref_99_2015") {
		$self->_sweref99_params();
		$self->{central_meridian} = 20.25;
	}
	elsif ($projection eq "sweref_99_2145") {
		$self->_sweref99_params();
		$self->{central_meridian} = 21.75;
	}
	elsif ($projection eq "sweref_99_2315") {
		$self->_sweref99_params();
		$self->{central_meridian} = 23.25;
	}

	# Test-case:
	#	Lat: 66 0'0", lon: 24 0'0".
	#	X:1135809.413803 Y:555304.016555.
	elsif ($projection eq "test_case") {
		$self->{axis} = 6378137.0;
		$self->{flattening} = 1.0 / 298.257222101;
		$self->{central_meridian} = 13.0 + 35.0/60.0 + 7.692000/3600.0;
		$self->{lat_of_origin} = 0.0;
		$self->{scale} = 1.000002540000;
		$self->{false_northing} = -6226307.8640;
		$self->{false_easting} = 84182.8790;

	# Not a valid $projection.
	} else {
		return undef;
	}

	return $self;
}

# Sets of default parameters.
sub _grs80_params() {
	my $self = shift;
	$self->{axis} = 6378137.0; # GRS 80.
	$self->{flattening} = 1.0 / 298.257222101; # GRS 80.
	$self->{central_meridian} = undef;
	$self->{lat_of_origin} = 0.0;
}

sub _bessel_params() {
	my $self = shift;
	$self->{axis} = 6377397.155; # Bessel 1841.
	$self->{flattening} = 1.0 / 299.1528128; # Bessel 1841.
	$self->{central_meridian} = undef;
	$self->{lat_of_origin} = 0.0;
	$self->{scale} = 1.0;
	$self->{false_northing} = 0.0;
	$self->{false_easting} = 1500000.0;
}

sub _sweref99_params() {
	my $self = shift;
	$self->{axis} = 6378137.0; # GRS 80.
	$self->{flattening} = 1.0 / 298.257222101; # GRS 80.
	$self->{central_meridian} = undef;
	$self->{lat_of_origin} = 0.0;
	$self->{scale} = 1.0;
	$self->{false_northing} = 0.0;
	$self->{false_easting} = 150000.0;
}


=item ($x, $y) = $grid->geodetic_to_grid($lat, $lon)

Conversion from geodetic coordinates to grid coordinates.

Parameters:

 $latitude  (number)
 $longitude (number)

Example:

 my ($x, $y) = $grid->geodetic_to_grid(63.1530261140462, 11.8353976399345);

Returns:

the x and y grid coordinates;

=cut

sub geodetic_to_grid {
	my $self = shift;
	my ($latitude, $longitude) = @_;

	unless (defined $self->{central_meridian}) {
		return (undef, undef);
	}

	# Prepare ellipsoid-based stuff.
	my $e2 = $self->{flattening} * (2.0 - $self->{flattening});
	my $n  = $self->{flattening} / (2.0 - $self->{flattening});
	my $a_roof = $self->{axis} / (1.0 + $n) * (1.0 + $n*$n/4.0 + $n*$n*$n*$n/64.0);
	my $A = $e2;
	my $B = (5.0*$e2*$e2 - $e2*$e2*$e2) / 6.0;
	my $C = (104.0*$e2*$e2*$e2 - 45.0*$e2*$e2*$e2*$e2) / 120.0;
	my $D = (1237.0*$e2*$e2*$e2*$e2) / 1260.0;
	my $beta1 = $n/2.0 - 2.0*$n*$n/3.0 + 5.0*$n*$n*$n/16.0 + 41.0*$n*$n*$n*$n/180.0;
	my $beta2 = 13.0*$n*$n/48.0 - 3.0*$n*$n*$n/5.0 + 557.0*$n*$n*$n*$n/1440.0;
	my $beta3 = 61.0*$n*$n*$n/240.0 - 103.0*$n*$n*$n*$n/140.0;
	my $beta4 = 49561.0*$n*$n*$n*$n/161280.0;

	# Convert.
	my $deg_to_rad = pi / 180.0;
	my $phi = $latitude * $deg_to_rad;
	my $lambda = $longitude * $deg_to_rad;
	my $lambda_zero = $self->{central_meridian} * $deg_to_rad;

	my $phi_star = $phi - sin($phi) * cos($phi) * ($A +
					 $B * sin($phi) ** 2 +
					 $C * sin($phi) ** 4 +
					 $D * sin($phi) ** 6);
	my $delta_lambda = $lambda - $lambda_zero;
	my $xi_prim = atan(tan($phi_star) / cos($delta_lambda));
	my $eta_prim = atanh(cos($phi_star) * sin($delta_lambda));
	my $x = $self->{scale} * $a_roof * ($xi_prim +
					$beta1 * sin(2.0*$xi_prim) * cosh(2.0*$eta_prim) +
					$beta2 * sin(4.0*$xi_prim) * cosh(4.0*$eta_prim) +
					$beta3 * sin(6.0*$xi_prim) * cosh(6.0*$eta_prim) +
					$beta4 * sin(8.0*$xi_prim) * cosh(8.0*$eta_prim)) +
					$self->{false_northing};
	my $y = $self->{scale} * $a_roof * ($eta_prim +
					$beta1 * cos(2.0*$xi_prim) * sinh(2.0*$eta_prim) +
					$beta2 * cos(4.0*$xi_prim) * sinh(4.0*$eta_prim) +
					$beta3 * cos(6.0*$xi_prim) * sinh(6.0*$eta_prim) +
					$beta4 * cos(8.0*$xi_prim) * sinh(8.0*$eta_prim)) +
					$self->{false_easting};
	$x = int($x * 1000.0) / 1000.0;
	$y = int($y * 1000.0) / 1000.0;
	return ($x, $y);
}


=item ($lat, $lon) = $grid->grid_to_geodetic($x, $y)

Conversion from grid coordinates to geodetic coordinates.

Parameters:

 $x (number)
 $y (number)

Example:

 my ($lat, $lon) = $grid->grid_to_geodetic(7011002, 1299996);

Returns:

the latitude and longitude geodetic coordinates;

=back

=cut

sub grid_to_geodetic {
	my $self = shift;
	my ($x, $y) = @_;

	unless (defined $self->{central_meridian}) {
		return (undef, undef);
	}

	# Prepare ellipsoid-based stuff.
	my $e2 = $self->{flattening} * (2.0 - $self->{flattening});
	my $n  = $self->{flattening} / (2.0 - $self->{flattening});
	my $a_roof = $self->{axis} / (1.0 + $n) * (1.0 + $n*$n/4.0 + $n*$n*$n*$n/64.0);
	my $delta1 = $n/2.0 - 2.0*$n*$n/3.0 + 37.0*$n*$n*$n/96.0 - $n*$n*$n*$n/360.0;
	my $delta2 = $n*$n/48.0 + $n*$n*$n/15.0 - 437.0*$n*$n*$n*$n/1440.0;
	my $delta3 = 17.0*$n*$n*$n/480.0 - 37*$n*$n*$n*$n/840.0;
	my $delta4 = 4397.0*$n*$n*$n*$n/161280.0;

	my $Astar = $e2 + $e2*$e2 + $e2*$e2*$e2 + $e2*$e2*$e2*$e2;
	my $Bstar = -(7.0*$e2*$e2 + 17.0*$e2*$e2*$e2 + 30.0*$e2*$e2*$e2*$e2) / 6.0;
	my $Cstar = (224.0*$e2*$e2*$e2 + 889.0*$e2*$e2*$e2*$e2) / 120.0;
	my $Dstar = -(4279.0*$e2*$e2*$e2*$e2) / 1260.0;

	# Convert.
	my $deg_to_rad = pi / 180;
	my $lambda_zero = $self->{central_meridian} * $deg_to_rad;
	my $xi  = ($x - $self->{false_northing}) / ($self->{scale} * $a_roof);
	my $eta = ($y - $self->{false_easting})  / ($self->{scale} * $a_roof);
	my $xi_prim = $xi -
					$delta1*sin(2.0*$xi) * cosh(2.0*$eta) -
					$delta2*sin(4.0*$xi) * cosh(4.0*$eta) -
					$delta3*sin(6.0*$xi) * cosh(6.0*$eta) -
					$delta4*sin(8.0*$xi) * cosh(8.0*$eta);
	my $eta_prim = $eta -
					$delta1*cos(2.0*$xi) * sinh(2.0*$eta) -
					$delta2*cos(4.0*$xi) * sinh(4.0*$eta) -
					$delta3*cos(6.0*$xi) * sinh(6.0*$eta) -
					$delta4*cos(8.0*$xi) * sinh(8.0*$eta);
	my $phi_star = asin(sin($xi_prim) / cosh($eta_prim));
	my $delta_lambda = atan(sinh($eta_prim) / cos($xi_prim));
	my $lon_radian = $lambda_zero + $delta_lambda;
	my $lat_radian = $phi_star + sin($phi_star) * cos($phi_star) *
					($Astar +
					 $Bstar*sin($phi_star) ** 2 +
					 $Cstar*sin($phi_star) ** 4 +
					 $Dstar*sin($phi_star) ** 6);

	my $latitude  = $lat_radian * 180.0 / pi;
	my $longitude = $lon_radian * 180.0 / pi;
	return ($latitude, $longitude);
}

1;

=head1 SEE ALSO

Source: http://www.lantmateriet.se/templates/LMV_Entrance.aspx?id=68&amp;lang=EN

=head1 COPYRIGHT

License: http://creativecommons.org/licenses/by-nc-sa/3.0/

=head1 AUTHORS

Original Javascript-version: http://mellifica.se/geodesi/gausskruger.js

Author: Arnold Andreasson, 2007. http://mellifica.se/konsult

Rewritten as object-oriented Perl by: Johan Beronius, 2009. http://www.athega.se/

=cut

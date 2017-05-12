package Geo::Coordinates::Convert;

use 5.006;
use strict;
use warnings;

use Exporter ();
use vars qw($VERSION @ISA @EXPORT);

@EXPORT = qw(
	set_Mean_Longitude
	geo2lII
	lII2geo
);

@ISA = qw(Exporter);

$VERSION = '0.01';

# some constants
my $PIsur4 = atan2(1, 1);
my $PIsur180 = $PIsur4 / 45;
my $PI = $PIsur4 * 4;
my $PIsur2 = $PIsur4 * 2;
my $precision = 0.001; # degrees

# these "constants" are relative to France (see www.ign.fr)
my $N = 0.7289686274;
my $C = 11745793.39;
my $XS = 600000;
my $YS = 8199695.768; # Lambert II (6199695.768 for extended LambertII)
my $E = 0.08248325676;
my $Esur2 = $E / 2;

# mean longitude. 2.3372 is the longitude of the meridian of Paris (degrees)
my $mean_longitude = 2.3372;

sub set_Mean_Longitude {
	$mean_longitude = $_[0];
}

sub geo2lII {
# Conversion from geographics coordinates (decimal degrees) to Lambert II coordinates (meters)
#
# list in (decimal degrees):
#   (geographic longitude, geographic latitude, mean longitude)
# list out (meters):
#   (lambert II longitude, lambert II latitude)
#
# longitudes from -180° west to +180° east
# latitudes from -90° (south) to +90° (north)

my ($l, $r, $gamma, $sinlat, $xl, $yl);
	# arguments
	my ($lon, $lat, $ml) = @_;
	$sinlat = sin($lat * $PIsur180);
	set_Mean_Latitude($ml) if $ml;

	$l = 0.5 * (
		log (
			(1 + $sinlat) / (1 - $sinlat)
		)
		- $E * log (
			(1 + $E * $sinlat) / (1 - $E * $sinlat)
		)
	);

	$r = $C * exp(-$N * $l);

	$gamma = $N * ($lon - $mean_longitude) * $PIsur180;

	$xl = $XS + $r * sin($gamma);
	$yl = $YS - $r * cos($gamma);

	return ($xl, $yl);
}

sub lII2geo {
# Conversion from Lambert II coordinates (meters) to geographics coordinates (decimal degrees)
#
# list in (meters):
#   (lambert II longitude, lambert II latitude)
# list out (decimal degrees):
#   (geographic longitude, geographic latitude)
# conventions:
# - negatives western longitudes, positives eastern
# - negatives southern latitudes, positives northern

	my ($el, $r, $gamma, $lon, $lat, $latp);

	my ($xl, $yl) = @_;

	$r = sqrt( ($xl - $XS) * ($xl - $XS) + ($yl - $YS) * ($yl - $YS) );
	$gamma = atan2 ( ($xl - $XS) / ($YS - $yl), 1 );

	$lon = $mean_longitude * $PIsur180 + $gamma / $N;
	$el = exp( - log ($r / $C) / $N );

	$lat = $PIsur4;
	$latp = 0;
	while (abs($latp - $lat) > $precision) {
		$latp = $lat;
		$lat = 2 * atan2( ((1 + $E * $latp) / (1 - $E * $latp) )** $Esur2 * $el, 1 ) - $PIsur2;
	}

	return ($lon/$PIsur180, $lat/$PIsur180);
}


1;
__END__

=head1 NAME

Geo::Coordinates::Convert - Perl extension for converting geographic coordinates from decimal
degrees to Lambert II and vice versa

=head1 SYNOPSIS


  use Geo::Coordinates::Convert;

  set_Mean_Longitude( $my_mean_longitude ); # decimal degrees

  ($long_LII, $lat_LII) = geo2lII( $long_degrees, $lat_degrees, [$mean_longitude] );

  ($long_degrees, $lat_degrees) = lII2geo( $long_LII, $lat_LII );


=head1 DESCRIPTION


Geo::Coordinates::Convert provides you a function converting classical geographics
coordinates (e.g. 50.25° E, 12.3° S) to Lambert II coordinates (x meters, y meters)
you can draw easily on a flat map using translation and scaling factors.
Geo::Coordinates::Convert provides also the reverse function converting Lambert II coordinates
to classical geographics coordinates.

Conventions:

longitudes from -180° west to +180° east

latitudes from -90° south to +90° north (excluding -90° and +90°)


=head1 TODO

- add a third parameter "mean_lambert_longitude" to the "lII2geo" function.
- extend to Lambert I, Lambert II extended, Lambert III and so on.

=head1 CAUTION

I'm not sure these subs works fine for all longitudes (despite the sub
set_Mean_Longitude), nor other latitudes, especially northern ones or equatorial ones.
I don't know the place to find the parameters $N, $C, $XS, $YS for other countries than France.

=head1 HISTORY

version 0.01 2002/09/20 first release.

=head1 AUTHOR


Jean-Pierre Vidal, E<lt>jeanpierre.vidal@free.frE<gt>

=head1 SEE ALSO

L<http://www.ign.fr>

=head1 COPYRIGHT AND LICENCE


Copyright (C) 2002 Jean-Pierre Vidal, jeanpierre.vidal@free.fr

This package is free software and is provided "as is"
without express or implied warranty. It may be used, modified,
and redistributed under the same terms as Perl itself.

=cut

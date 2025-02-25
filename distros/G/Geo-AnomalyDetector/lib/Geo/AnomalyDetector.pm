package Geo::AnomalyDetector;

use strict;
use warnings;

use Statistics::Basic qw(mean stddev);

=head1 NAME

Geo::AnomalyDetector - Detect anomalies in geospatial coordinate datasets

=head1 SYNOPSIS

This module analyzes latitude and longitude data points to identify anomalies based on their distance from the mean location.

  use Geo::AnomalyDetector;
 
  my $detector = Geo::AnomalyDetector->new(threshold => 3);
  my $coords = [ [37.7749, -122.4194], [40.7128, -74.0060], [35.6895, 139.6917] ];
  my $anomalies = $detector->detect_anomalies($coords);
  print "Anomalies: " . join ", ", map { "($_->[0], $_->[1])" } @$anomalies;

=head1	VERSION

0.01

=cut

our $VERSION = '0.01';

sub new {
	my ($class, %args) = @_;
	my $self = {
		threshold => $args{threshold} || 3,
		unit => $args{unit} || 'K',
	};
	bless $self, $class;
	return $self;
}

sub detect_anomalies {
	my ($self, $coordinates) = @_;

	my @distances;
	my $mean_lat = mean(map { $_->[0] } @$coordinates);
	my $mean_lon = mean(map { $_->[1] } @$coordinates);

	foreach my $coord (@$coordinates) {
		my ($lat, $lon) = @$coord;
		die if(!defined($lat) || !defined($lon));
		my $distance = distance($lat, $lon, $mean_lat, $mean_lon, 'K');
		push @distances, $distance;
	}

	my $mean_dist = mean(@distances);
	my $std_dist = stddev(@distances);

	my @anomalies;
	for my $i (0 .. $#distances) {
		if (abs($distances[$i] - $mean_dist) > ($self->{threshold} * $std_dist)) {
			push @anomalies, $coordinates->[$i];
		}
	}

	return \@anomalies;
}

sub distance {
	my ($lat1, $lon1, $lat2, $lon2, $unit) = @_;
	my $theta = $lon1 - $lon2;
	my $dist = sin(_deg2rad($lat1)) * sin(_deg2rad($lat2)) + cos(_deg2rad($lat1)) * cos(_deg2rad($lat2)) * cos(_deg2rad($theta));
	$dist = _acos($dist);
	$dist = _rad2deg($dist);
	$dist = $dist * 60 * 1.1515;
	if ($unit eq 'K') {
		$dist = $dist * 1.609344;	# number of kilometres in a mile
	} elsif ($unit eq 'N') {
		$dist = $dist * 0.8684;
	}
	return ($dist);
}

my $pi = atan2(1,1) * 4;

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#:::  This function get the arccos function using arctan function   :::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
sub _acos {
	my ($rad) = @_;
	my $ret = atan2(sqrt(1 - $rad**2), $rad);
	return $ret;
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#:::  This function converts decimal degrees to radians			 :::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
sub _deg2rad {
	my ($deg) = @_;
	return ($deg * $pi / 180);
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#:::  This function converts radians to decimal degrees			 :::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
sub _rad2deg {
	my ($rad) = @_;
	return ($rad * 180 / $pi);
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

=head1 SEE ALSO

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-geo-info at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-AnomalyDetector>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Geo::AnomalyDetector

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/Geo-AnomalyDetector>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-AnomalyDetector>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Geo-AnomalyDetector>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Geo::AnomalyDetector>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2025 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;

__END__

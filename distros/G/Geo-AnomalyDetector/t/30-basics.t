#!/usr/bin/env perl

use strict;
use warnings;

use Geo::Location::Point;
use Test::Most;

BEGIN { use_ok('Geo::AnomalyDetector') }

# Create a new anomaly detector with a threshold of 1 standard deviation
my $detector = Geo::AnomalyDetector->new(threshold => 1);

# Sample data: mostly clustered points with one outlier
my $coords = [
	[37.7749, -122.4194],	# San Francisco
	# [37.7750, -122.4195],	# Near San Francisco
	Geo::Location::Point->new({ latitude => 37.7750, longitude => -122.4195 }),
	[37.7751, -122.4196],	# Near San Francisco
	[0.0000, 0.0000],	# Outlier
];

# Run anomaly detection
my $anomalies = $detector->detect_anomalies($coords);

# Test if anomalies were detected
ok(@{$anomalies} > 0, 'Anomalies detected');

# Ensure the detected anomaly is the expected one
is_deeply($anomalies, [[0.0000, 0.0000]], 'Correct anomaly detected');

# The documented name is units, and unit was the only one read before 0.03
is(Geo::AnomalyDetector->new()->{'unit'}, 'K', 'Kilometres by default');
is(Geo::AnomalyDetector->new(units => 'M')->{'unit'}, 'M', 'units is honoured');
is(Geo::AnomalyDetector->new(unit => 'M')->{'unit'}, 'M', 'unit is still honoured');

# The unit is internal, so it mustn't change what is found
is_deeply(Geo::AnomalyDetector->new(threshold => 1, units => 'M')->detect_anomalies($coords), $anomalies, 'Same anomalies in miles');

done_testing();

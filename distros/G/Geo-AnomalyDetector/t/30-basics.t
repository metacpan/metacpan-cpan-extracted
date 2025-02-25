#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

BEGIN { use_ok('Geo::AnomalyDetector') }

# Create a new anomaly detector with a threshold of 1 standard deviation
my $detector = Geo::AnomalyDetector->new(threshold => 1);

# Sample data: mostly clustered points with one outlier
my $coords = [
	[37.7749, -122.4194],	# San Francisco
	[37.7750, -122.4195],	# Near San Francisco
	[37.7751, -122.4196],	# Near San Francisco
	[0.0000, 0.0000],	# Outlier
];

# Run anomaly detection
my $anomalies = $detector->detect_anomalies($coords);

# Test if anomalies were detected
ok(@{$anomalies} > 0, 'Anomalies detected');

# Ensure the detected anomaly is the expected one
is_deeply($anomalies, [[0.0000, 0.0000]], 'Correct anomaly detected');

done_testing();

#!/usr/bin/env perl

# Test rate limiting and cache

use strict;
use warnings;

use CHI;
use Time::HiRes qw(time);
use Test::Most tests => 8;

BEGIN { use_ok('HTML::OSM') }

RATE_LIMIT: {
	# --- Create a custom LWP::UserAgent for testing ---
	{
		package MyTestUA;
		use parent 'LWP::UserAgent';
		use HTTP::Response;

		# Global variables to count requests and record request times
		our $REQUEST_COUNT = 0;
		our @REQUEST_TIMES;

		sub get {
			my ($self, $url) = @_;
			push @REQUEST_TIMES, time();
			$REQUEST_COUNT++;

			# Return a dummy successful JSON response. The JSON is a simplified
			# version of what the openstreetmap API might return.
			my $content = '{"lon":"20","lat":"-20"}';
			return HTTP::Response->new(200, 'OK', [], $content);
		}
	}

	# Set a short minimum interval for testing purposes (e.g. 1 second)
	# But don't test for less than a second without changing the test timer to track microseconds
	my $min_interval = 1;

	# Create our custom user agent
	my $ua = MyTestUA->new();

	# Create an in-memory cache using CHI
	my $cache = CHI->new(
		driver => 'Memory',
		global => 1,
		expires_in => '1 hour',
	);

	# Instantiate with our custom UA and min_interval
	my $osm = HTML::OSM->new(
		cache => $cache,
		min_interval => $min_interval,
		ua => $ua
	);

	ok($osm->add_marker(point => 'New York', html => 'New York'));
	ok($osm->add_marker(point => 'San Francisco', html => 'San Francisco'));
	ok($osm->add_marker(point => 'San Francisco', html => 'San Francisco'));	# Add twice to check caching

	# Verify that the rate limiting was enforced by comparing the timestamps of
	# the two API calls. There should now be two entries in @MyTestUA::REQUEST_TIMES.
	my $num_requests = scalar @MyTestUA::REQUEST_TIMES;
	ok($num_requests >= 2, 'At least two API requests have been made');
	cmp_ok($num_requests, '==', $MyTestUA::REQUEST_COUNT);

	if($num_requests >= 2) {
		my $elapsed = $MyTestUA::REQUEST_TIMES[1] - $MyTestUA::REQUEST_TIMES[0];
		cmp_ok($elapsed, '>=', $min_interval, "Rate limiting enforced: elapsed time >= $min_interval sec");
	}

	diag(join(', ', $cache->get_keys())) if($ENV{'TEST_VERBOSE'});

	cmp_ok(ref($cache->get('osm:New%20York')), 'eq', 'HASH');
}

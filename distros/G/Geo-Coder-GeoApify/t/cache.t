#!/usr/bin/env perl

# Test caching and rate limiting

use strict;
use warnings;
use Test::Most;
use CHI;
use Time::HiRes qw(time);

BEGIN { use_ok('Geo::Coder::GeoApify') }

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
		# version of what the API might return.
		my $content = '{"features": {"geometry": [{"coordinates": [0.01, 0.02]}]}}';
		return HTTP::Response->new(200, 'OK', [], $content);
	}
}

# --- Reset our test UA counters (in case tests are run more than once) ---
{
	no warnings 'once';
	$MyTestUA::REQUEST_COUNT = 0;
	@MyTestUA::REQUEST_TIMES = ();
}

# --- Create a Geo::Coder::GeoApify object with caching and rate limiting ---

# Set a short minimum interval for testing purposes (e.g. 1 second)
# But don't test for less than a second without changing the test timer to track microseconds
my $min_interval = 1;

# Create an in-memory cache using CHI
my $cache = CHI->new(
	driver => 'Memory',
	global => 1,
	expires_in => '1 hour',
);

# Create our custom user agent
my $ua = MyTestUA->new();

# Instantiate the geocoder with our custom UA, cache, and min_interval
my $geo = Geo::Coder::GeoApify->new(
	apiKey => 'dummy',	# This makes no actual calls so we don't need a key
	ua => $ua,
	cache => $cache,
	min_interval => $min_interval,
);

# --- Test 1: Calling geocode with a valid address returns a hashref ---
my $res1 = $geo->geocode(location => '4600 Silver Hill Rd., Suitland, MD');
ok($res1 && ref($res1) eq 'HASH', 'First geocode call returns hashref');
ok(exists $res1->{features}, "Result contains key 'features'");
ok(ref($res1->{features}{geometry}) eq 'ARRAY',
	"Result contains 'geometry' array");

# --- Test 2: Caching: repeat the same address, should not call the API again ---
my $res2 = $geo->geocode(location => '4600 Silver Hill Rd., Suitland, MD');
is_deeply($res1, $res2, 'Second call returns cached features (same as first)');
is($MyTestUA::REQUEST_COUNT, 1, 'Only one API request made for duplicate queries');

# --- Test 3: Rate Limiting: force a cache miss by changing the address ---
# Note: This will cause a real "sleep" if the elapsed time is less than min_interval.
my $res3 = $geo->geocode(location => '1600 Pennsylvania Avenue NW, Washington, DC');
ok($res3 && ref($res3) eq 'HASH', 'Third geocode call (different address) returns hashref');

# Verify that the rate limiting was enforced by comparing the timestamps of
# the two API calls. There should now be two entries in @MyTestUA::REQUEST_TIMES.
my $num_requests = scalar @MyTestUA::REQUEST_TIMES;
ok($num_requests >= 2, 'At least two API requests have been made');
cmp_ok($num_requests, '==', $MyTestUA::REQUEST_COUNT);

if($num_requests >= 2) {
	my $elapsed = $MyTestUA::REQUEST_TIMES[1] - $MyTestUA::REQUEST_TIMES[0];
	cmp_ok($elapsed, '>=', $min_interval, "Rate limiting enforced: elapsed time >= $min_interval sec");
}

done_testing();

#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most tests => 11;
use Test::NoWarnings;
use Error;
# use CHI::Driver::SharedMem;
use CHI::Driver::Null;

BEGIN { use_ok('Geo::Coder::Free::Utils') }

# Mock configuration data
my $valid_disk_config = {
	disc_cache => {
		driver => 'File',
		root_dir => '/tmp/cache',
	}
};

my $valid_memory_config = {
	# memory_cache => {
		# driver => 'SharedMem',
		# shm_key => 98766789,
		# max_size => 1024,
		# shm_size => 16 * 1024,
	# }
	memory_cache => {
		driver => 'Null',
	}
};

my $invalid_config = {};

# Test create_disc_cache
sub test_create_disc_cache {
	# Valid configuration
	my $disk_cache = eval { create_disc_cache({ config => $valid_disk_config, namespace => 'test_disk' }) };
	ok($disk_cache, 'Disk cache created successfully');
	like($disk_cache, qr/^CHI/, 'Disk cache is a CHI object');

	# Invalid configuration
	eval { create_disc_cache({ config => $invalid_config }) };
	ok($@, 'Disk cache creation failed with missing configuration');
	like($@, qr/root_dir is not optional/, 'Proper error message for missing root_dir');
}

# Test create_memory_cache
sub test_create_memory_cache {
	# Valid configuration
	my $memory_cache = eval { create_memory_cache({ config => $valid_memory_config, namespace => 'test_memory' }) };
	ok($memory_cache, 'Memory cache created successfully');
	like($memory_cache, qr/^CHI/, 'Memory cache is a CHI object');
}

# Test distance calculation
sub test_distance {
	# Test known distances
	my $dist_km = distance(40.7128, -74.0060, 34.0522, -118.2437, 'K'); # NYC to LA
	is_approx($dist_km, 3940, 5, 'Distance between NYC and LA in km is approximately 3940 km');

	my $dist_miles = distance(40.7128, -74.0060, 34.0522, -118.2437, ''); # Default miles
	is_approx($dist_miles, 2445, 1, 'Distance between NYC and LA in miles is approximately 2445 miles');

	my $dist_nautical = distance(40.7128, -74.0060, 34.0522, -118.2437, 'N'); # Nautical miles
	is_approx($dist_nautical, 2123, 1, 'Distance between NYC and LA in nautical miles is approximately 2123 nautical miles');
}

# Helper to compare floating-point numbers
sub is_approx {
	my ($got, $expected, $tolerance, $test_name) = @_;
	my $diff = abs($got - $expected);
	cmp_ok($diff, '<=', $tolerance, $test_name);
}

# Run tests
test_create_disc_cache();
test_create_memory_cache();
test_distance();

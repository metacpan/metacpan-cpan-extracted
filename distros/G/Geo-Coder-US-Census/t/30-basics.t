#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Geo::Coder::US::Census;
use Test::RequiresInternet ('geocoding.geo.census.gov' => 'https');

# Note:
# These tests perform live HTTP queries against the Census Bureau's API.
# If you experience network issues or if the API is unavailable,
# you might need to mark these tests as TODO or SKIP them.

plan tests => 9;

### 1. Create a Geo::Coder::US::Census object ###
my $geo = Geo::Coder::US::Census->new();
ok($geo, 'Created Geo::Coder::US::Census object');

### 2. Check that the ua accessor returns a LWP::UserAgent object ###
isa_ok( $geo->ua, 'LWP::UserAgent', 'ua accessor returns a LWP::UserAgent object' );

### 3. Test geocode with a valid address ###
lives_ok {
	# Use a typical address that should be recognized by the Census API.
	my $result = $geo->geocode(location => '4600 Silver Hill Rd., Suitland, MD');
	
	# Check that we got a hash reference back.
	is( ref($result), 'HASH', 'geocode returns a hash reference' );
	
	# The Census API returns a structure containing a key "result"
	ok( exists $result->{result}, 'Result contains key "result"' );
	
	# The "result" key should contain an "addressMatches" array
	ok( ref($result->{result}{addressMatches}) eq 'ARRAY', 'Result contains addressMatches array' );
} 'geocode with valid address works';

### 4. Test geocode with an address missing city/state ###
{
	my $warning;
	local $SIG{__WARN__} = sub { $warning = $_[0] };

	# Supply an address that lacks sufficient information.
	my $bad_result = $geo->geocode(location => '123 Fake Street');

	ok( !defined($bad_result), 'geocode returns undef for address without city/state' );
	like( $warning, qr/city and state are mandatory/, 'Warns that city and state are mandatory' );
}

### 5. Test that reverse_geocode croaks ###
dies_ok { $geo->reverse_geocode(latlng => '37.778907,-122.39732') } 'reverse_geocode croaks as expected';

done_testing();

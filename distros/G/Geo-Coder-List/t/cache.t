#!/usr/bin/env perl

# Test using a HASH as a cache

use strict;
use warnings;

use Test::Mockingbird;
use Test::Most;
use Test::Needs 'Geo::Coder::Free';

BEGIN { use_ok('Geo::Coder::List') }

my $cache = {}; # Simple in-memory cache for testing

Test::Mockingbird::mock('Geo::Coder::Free', 'geocode', sub {
	shift;	# Discard $self
	return { lat => 34.0522, lon => -118.2437 };
});

my $list = Geo::Coder::List->new(cache => $cache)->push(new_ok('Geo::Coder::Free'));

# First call (not cached)
my $result = $list->geocode(location => 'Los Angeles, USA');
ok($result, 'Result obtained from geocoder');

# Second call (cached)
my $cached_result = $list->geocode(location => 'Los Angeles, USA');
# The cached result is a shallow copy of the stored HASH, so it differs from
# $result (which was stripped to just {geometry} by the L2 write path).
# Compare the canonical coordinates that the cache is actually preserving.
is_deeply($cached_result->{geometry}, $result->{geometry},
	'Cached geometry matches original');
is($cached_result->{geocoder}, 'cache', 'Cache indicator set');
ok(ref($cache->{'Los Angeles, USA'}) eq 'HASH');

done_testing();

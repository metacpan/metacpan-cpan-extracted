#!/usr/bin/env perl

# Test using a HASH as a cache

use strict;
use warnings;

use Test::MockModule;
use Test::Most;
use Test::Needs 'Geo::Coder::Free';

BEGIN { use_ok('Geo::Coder::List') }

my $cache = {}; # Simple in-memory cache for testing

my $mock = Test::MockModule->new('Geo::Coder::Free');
$mock->mock('geocode', sub { return { lat => 34.0522, lon => -118.2437 } });

my $list = Geo::Coder::List->new(cache => $cache)->push(new_ok('Geo::Coder::Free'));

# First call (not cached)
my $result = $list->geocode(location => 'Los Angeles, USA');
ok($result, 'Result obtained from geocoder');

# Second call (cached)
my $cached_result = $list->geocode(location => 'Los Angeles, USA');
is_deeply($cached_result, $result, 'Result retrieved from cache');
is($cached_result->{geocoder}, 'cache', 'Cache indicator set');
ok(ref($cache->{'Los Angeles, USA'}) eq 'HASH');

done_testing();

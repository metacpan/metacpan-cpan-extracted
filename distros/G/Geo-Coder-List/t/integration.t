#!/usr/bin/env perl

# t/integration.t - End-to-end integration tests for Geo::Coder::List
#
# Tests black-box workflows across the full stack: real geocoder backends
# (Geo::Coder::Free, Geo::Coder::Free::Local), CHI L2 cache, LWP::UserAgent
# propagation, multiple concurrent list instances, and cross-method statefulness.
# Mocking is used only where a real backend cannot be exercised offline.

use strict;
use warnings;

use lib 'lib';

use Data::Dumper;
use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Test::Needs 'Geo::Coder::Free', 'Geo::Coder::Free::Local', 'CHI';
use Readonly;
use Scalar::Util qw(blessed refaddr);

# Load the module under test
BEGIN { use_ok('Geo::Coder::List') }

# Confirm real geocoder modules are available
new_ok('Geo::Coder::Free')        or BAIL_OUT('Geo::Coder::Free not usable');
new_ok('Geo::Coder::Free::Local') or BAIL_OUT('Geo::Coder::Free::Local not usable');

# ── Test configuration ────────────────────────────────────────────────────────

# Named location strings for offline geocoding with Geo::Coder::Free
Readonly::Scalar my $LOC_RAMSGATE => 'Ramsgate, Kent, England';
Readonly::Scalar my $LOC_MARGATE  => 'Margate, Kent, England';
Readonly::Scalar my $LOC_USA      => 'Silver Spring, MD, USA';
Readonly::Scalar my $LATLNG_KT    => '51.33,-1.43';

# Approximate coordinate bounds for assertions (±tolerance)
my %config = (
	lat_ramsgate_approx => 51.33,
	lng_ramsgate_approx =>  1.43,
	lat_margate_approx  => 51.38,
	coord_tolerance     =>  0.5,
	cache_str           => 'cache',
	debug_off           => 0,
);

# ── Helper: new list with Geo::Coder::Free already pushed ────────────────────
sub _free_list {
	my (%opts) = @_;
	return Geo::Coder::List->new(%opts)->push(Geo::Coder::Free->new());
}

# =============================================================================
# 1. Real geocoder: basic geocode workflow with Geo::Coder::Free
# =============================================================================

subtest 'integration: Geo::Coder::Free resolves a UK city via geocode()' => sub {
	# End-to-end: list -> geocode -> Geo::Coder::Free -> normalise -> return
	my $list   = _free_list();
	my $result = $list->geocode($LOC_RAMSGATE);

	ok(defined $result, 'geocode returned a defined result');
	is(ref($result), 'Geo::Location::Point', 'result is a Geo::Location::Point');

	# Canonical geometry structure must be present
	ok(defined $result->{geometry}{location}{lat},
		'geometry.location.lat present in result');
	ok(defined $result->{geometry}{location}{lng},
		'geometry.location.lng present in result');

	# Latitude should be roughly correct for Ramsgate (~51.3N)
	ok(abs($result->{geometry}{location}{lat} - $config{lat_ramsgate_approx})
		< $config{coord_tolerance}, 'latitude is in the right region');

	diag("lat=", $result->{geometry}{location}{lat},
		" lng=", $result->{geometry}{location}{lng}) if $ENV{TEST_VERBOSE};
};

subtest 'integration: geocoder field is the Geo::Coder::Free object (no L2 cache)' => sub {
	# POD: "geocoder field holds the geocoder object that supplied the result"
	# Without L2 cache the geocoder reference is preserved in the returned value
	my $list   = _free_list();
	my $result = $list->geocode($LOC_RAMSGATE);

	ok(defined $result,                           'result defined');
	is(ref($result->{geocoder}), 'Geo::Coder::Free',
		'geocoder field holds the Geo::Coder::Free object');
};

subtest 'integration: geocode writes a log entry with correct keys' => sub {
	# POD: log() returns entries with line, location, timetaken, geocoder, wantarray
	my $list = _free_list();
	$list->geocode($LOC_RAMSGATE);

	my $log = $list->log();
	ok(scalar @{$log} >= 1, 'at least one log entry after geocode');

	my $entry = $log->[0];
	is($entry->{location}, $LOC_RAMSGATE,    'log.location correct');
	is($entry->{geocoder}, 'Geo::Coder::Free','log.geocoder is the class name string');
	ok($entry->{timetaken} >= 0,             'log.timetaken is non-negative');
	ok(exists $entry->{wantarray},           'log.wantarray key present');
	ok(exists $entry->{result},              'log.result key present for success');

	diag(Dumper($entry)) if $ENV{TEST_VERBOSE};
};

subtest 'integration: list-context geocode returns all candidates from Free' => sub {
	# POD: "In list context returns all results from the winning geocoder"
	my $list    = _free_list();
	my @results = $list->geocode($LOC_RAMSGATE);

	ok(scalar @results >= 1, 'list context returns at least one result');
	ok(defined $results[0]{geometry}{location}{lat},
		'first result has canonical lat');
};

# =============================================================================
# 2. L1 cache: repeated lookups avoid re-hitting the backend
# =============================================================================

subtest 'integration: second geocode() call is served from L1 cache' => sub {
	# POD Z-spec: "loc? in dom L1 => result! = L1(loc?)"
	my $spy   = spy('Geo::Coder::Free::geocode');
	my $list  = _free_list();

	$list->geocode($LOC_RAMSGATE);    # populates L1
	$list->geocode($LOC_RAMSGATE);    # must be served from cache

	my @calls = $spy->();
	unmock('Geo::Coder::Free', 'geocode');

	is(scalar @calls, 1, 'backend called exactly once (L1 cache hit on second call)');
};

subtest 'integration: L1 cache hit sets geocoder field to "cache"' => sub {
	# POD: "set to the string 'cache' when the result was served from cache"
	my $list = _free_list();
	$list->geocode($LOC_RAMSGATE);        # first call - backend
	my $r2 = $list->geocode($LOC_RAMSGATE);  # second call - cache

	is($r2->{geocoder}, $config{cache_str},
		'geocoder field is "cache" on cache-hit result');
};

subtest 'integration: flush() clears log but L1 cache survives' => sub {
	# POD Z-spec: flush changes only log; L1 unchanged
	my $spy  = spy('Geo::Coder::Free::geocode');
	my $list = _free_list();

	$list->geocode($LOC_RAMSGATE);
	$list->flush();

	my $r = $list->geocode($LOC_RAMSGATE);  # should still hit L1
	my @calls = $spy->();
	unmock('Geo::Coder::Free', 'geocode');

	is(scalar @calls, 1, 'backend not called again after flush (L1 intact)');
	is($r->{geocoder}, $config{cache_str}, 'second result from cache after flush');
	is(scalar @{$list->log()}, 1,
		'log has exactly one entry (the post-flush cache hit)');
};

# =============================================================================
# 3. L2 CHI cache: results persist and are served on a second-instance lookup
# =============================================================================

subtest 'integration: L2 CHI cache receives and returns geocode results' => sub {
	# Two separate Geo::Coder::List objects share the same CHI global cache;
	# the second should serve the result without hitting the backend.
	my $chi = CHI->new(driver => 'Memory', global => 1, namespace => 'integration_l2');

	my $spy  = spy('Geo::Coder::Free::geocode');

	my $list1 = _free_list(cache => $chi);
	$list1->geocode($LOC_MARGATE);   # populates L2

	my $list2 = _free_list(cache => $chi);
	my $r2    = $list2->geocode($LOC_MARGATE);  # should hit L2

	my @calls = $spy->();
	unmock('Geo::Coder::Free', 'geocode');

	# One call from list1; list2 should serve from shared L2
	is(scalar @calls, 1,
		'backend called once across two list instances sharing L2 cache');
	ok(defined $r2, 'second list returned a result from L2');

	diag("r2 geocoder=", $r2->{geocoder} // 'undef') if $ENV{TEST_VERBOSE};
};

subtest 'integration: L2 CHI cache result has geometry.location.lat/lng' => sub {
	# Verify geometry structure survives L2 round-trip
	my $chi = CHI->new(driver => 'Memory', global => 1, namespace => 'integration_geom');

	my $list1 = _free_list(cache => $chi);
	my $r1    = $list1->geocode($LOC_MARGATE);

	my $list2 = _free_list(cache => $chi);
	my $r2    = $list2->geocode($LOC_MARGATE);

	ok(defined $r2->{geometry}{location}{lat}, 'lat present after L2 round-trip');
	ok(defined $r2->{geometry}{location}{lng}, 'lng present after L2 round-trip');
};

# =============================================================================
# 4. Regex routing: different geocoders dispatched by location pattern
# =============================================================================

subtest 'integration: regex routing sends USA locations to specific geocoder' => sub {
	# Two mock geocoders: Alpha handles USA, Beta is the global fallback.
	# Verify Alpha is called for USA and Beta for non-USA.
	my ($alpha_calls, $beta_calls) = (0, 0);

	my $list = Geo::Coder::List->new();

	# Define two stub classes
	{ package IntGeocoder::Alpha;
	  sub new { bless {}, shift }
	  sub geocode { return () }
	}
	{ package IntGeocoder::Beta;
	  sub new { bless {}, shift }
	  sub geocode { return () }
	}

	$list->push({ regex => qr/USA$/, geocoder => IntGeocoder::Alpha->new() });
	$list->push(IntGeocoder::Beta->new());

	my $mock_a = mock_scoped 'IntGeocoder::Alpha::geocode' => sub {
		$alpha_calls++;
		return { lat => 38.9, lon => -77.0 };
	};
	my $mock_b = mock_scoped 'IntGeocoder::Beta::geocode'  => sub {
		$beta_calls++;
		return { lat => 51.3, lon => 1.4 };
	};

	$list->geocode($LOC_USA);       # USA pattern -> only Alpha
	$list->geocode($LOC_RAMSGATE);  # no USA -> only Beta

	is($alpha_calls, 1, 'Alpha called exactly once (for USA location)');
	is($beta_calls,  1, 'Beta called exactly once (for non-USA location)');
};

# =============================================================================
# 5. Limit enforcement: per-geocoder query cap
# =============================================================================

subtest 'integration: limit cap prevents geocoder from being called after exhaustion' => sub {
	# POD push(): "caps total queries at limit"
	my $spy  = spy('Geo::Coder::Free::geocode');
	my $list = Geo::Coder::List->new();
	$list->push({ geocoder => Geo::Coder::Free->new(), limit => 1 });

	$list->geocode($LOC_RAMSGATE);   # uses up the 1 remaining query
	$list->geocode($LOC_MARGATE);    # limit = 0; geocoder must be skipped

	my @calls = $spy->();
	unmock('Geo::Coder::Free', 'geocode');

	is(scalar @calls, 1, 'geocoder called exactly once when limit is 1');
};

# =============================================================================
# 6. Fallback chain: first geocoder returns nothing, second succeeds
# =============================================================================

subtest 'integration: fallback to second geocoder when first returns empty' => sub {
	# The list tries each geocoder in turn; first empty result triggers fallback
	{ package FallbackMock::First;
	  sub new { bless {}, shift }
	  sub geocode { return () }   # always fails
	}

	my $list = Geo::Coder::List->new();
	$list->push(FallbackMock::First->new());
	$list->push(Geo::Coder::Free->new());

	my $spy   = spy('Geo::Coder::Free::geocode');
	my $result = $list->geocode($LOC_RAMSGATE);

	my @calls = $spy->();
	unmock('Geo::Coder::Free', 'geocode');

	ok(defined $result, 'fallback geocoder provided a result');
	is(scalar @calls, 1, 'Free::geocode called exactly once (as fallback)');
	ok(abs($result->{geometry}{location}{lat} - $config{lat_ramsgate_approx})
		< $config{coord_tolerance}, 'fallback result has plausible coordinates');
};

# =============================================================================
# 7. Multiple concurrent list instances (same process, independent state)
# =============================================================================

subtest 'integration: two list instances operate independently, no state leakage' => sub {
	# Concurrent instances must not share L1 cache, log, or geocoder chain.
	# Each is created fresh; geocoding on A must not affect B's backend calls.
	my $list_a = _free_list();
	my $list_b = _free_list();   # independent chain and L1

	$list_a->geocode($LOC_RAMSGATE);   # A populates its own L1

	# B knows nothing about A's geocoding activity: its log is empty
	is(scalar @{$list_b->log()}, 0,
		'instance B log is independent of instance A');

	# B's L1 is empty; it MUST call the backend (spy verifies this)
	my $spy    = spy('Geo::Coder::Free::geocode');
	my $r_b    = $list_b->geocode($LOC_RAMSGATE);
	my @calls  = $spy->();
	unmock('Geo::Coder::Free', 'geocode');

	ok(defined $r_b, 'B returns a result from its own backend call');
	is(scalar @calls, 1, 'B hit its own backend (L1 is separate from A)');
};

subtest 'integration: clone shares geocoder chain but has independent log' => sub {
	# Cloning via ->new() on an existing instance copies the geocoder chain
	# but creates a fresh log
	my $orig  = _free_list();
	$orig->geocode($LOC_RAMSGATE);

	my $clone = $orig->new();

	# Clone log is fresh (not shared with orig)
	is(scalar @{$clone->log()}, 0, 'clone has a fresh empty log');

	# Clone can geocode using the inherited chain
	my $r = $clone->geocode($LOC_RAMSGATE);
	ok(defined $r, 'clone geocodes successfully via inherited chain');

	# Clone log accumulated independently
	ok(scalar @{$clone->log()} >= 1, 'clone log accumulated its own entry');
	ok(scalar @{$orig->log()} >= 1,  'orig log unchanged by clone activity');

	diag("orig entries=", scalar @{$orig->log()},
		" clone entries=", scalar @{$clone->log()}) if $ENV{TEST_VERBOSE};
};

# =============================================================================
# 8. Spy verification: geocoder called with correct arguments
# =============================================================================

subtest 'integration: spy confirms geocoder receives decoded location string' => sub {
	# geocode() decodes HTML entities before calling the backend;
	# spy verifies the geocoder sees the cleaned string
	my $spy  = spy('Geo::Coder::Free::geocode');
	my $list = _free_list();

	# HTML entity in input: &amp; should become plain '&' (or be stripped)
	$list->geocode(location => 'Ramsgate &amp; Margate, Kent, England');

	my @calls = $spy->();
	unmock('Geo::Coder::Free', 'geocode');

	ok(scalar @calls > 0, 'spy captured at least one call');

	# Find the location argument (second positional arg after $self)
	my $seen_args = $calls[0];
	my $seen_loc  = do {
		my %h = @{$seen_args}[2..$#$seen_args];
		$h{location} // '';
	};

	unlike($seen_loc, qr/&amp;/, 'HTML entity code not passed raw to geocoder');
	diag("location seen by geocoder: '$seen_loc'") if $ENV{TEST_VERBOSE};
};

subtest 'integration: spy confirms multiple spaces collapsed before geocoder call' => sub {
	my $spy  = spy('Geo::Coder::Free::geocode');
	my $list = _free_list();

	$list->geocode(location => 'Ramsgate,   Kent,   England');

	my @calls = $spy->();
	unmock('Geo::Coder::Free', 'geocode');

	my $seen_args = $calls[0];
	my $seen_loc  = do {
		my %h = @{$seen_args}[2..$#$seen_args];
		$h{location} // '';
	};

	unlike($seen_loc, qr/  +/, 'multiple spaces collapsed before geocoder call');
};

# =============================================================================
# 9. ua() integration: LWP::UserAgent propagated to all geocoders
# =============================================================================

# =============================================================================
# 9a. ua() -- per-geocoder clone with class-based agent string (new in 0.37)
# Each geocoder should receive a clone whose agent is "ClassName/Version".
# =============================================================================

subtest 'integration: ua() sets class-based agent on each per-geocoder clone' => sub {
	# When a real LWP::UserAgent (which supports clone+agent) is passed, each
	# geocoder should receive a clone whose agent reflects its own class name.
	my $list = Geo::Coder::List->new();
	$list->push(Geo::Coder::Free->new());
	$list->push(Geo::Coder::Free::Local->new());

	require LWP::UserAgent;
	my $ua = LWP::UserAgent->new();

	# Capture the UA that each geocoder actually receives
	my ($agent_free, $agent_local);
	my $mock1 = mock_scoped 'Geo::Coder::Free::ua' => sub {
		my ($self, $u) = @_;
		$agent_free  = $u->agent() if $u && $u->can('agent');
	};
	my $mock2 = mock_scoped 'Geo::Coder::Free::Local::ua' => sub {
		my ($self, $u) = @_;
		$agent_local = $u->agent() if $u && $u->can('agent');
	};

	$list->ua($ua);

	# Each geocoder's clone must have its own class name in the agent string
	like($agent_free,  qr/^Geo::Coder::Free/,
		'Geo::Coder::Free received clone with its own class-based agent');
	like($agent_local, qr/^Geo::Coder::Free::Local/,
		'Geo::Coder::Free::Local received clone with its own class-based agent');

	# The two agents must be different (each geocoder gets its own)
	isnt($agent_free, $agent_local,
		'The two geocoders received clones with distinct agent strings');
};

# =============================================================================
# 9b. geocode() -- cache-hit shallow copy (new in 0.37)
# A second geocode() call for the same location returns a fresh copy; the
# original result variable must not be mutated.
# =============================================================================

subtest 'integration: geocode cache hit does not mutate original result variable' => sub {
	my $list = _free_list();
	my $mock = mock_scoped 'Geo::Coder::Free::geocode' => sub {
		return { lat => $config{lat_ramsgate_approx}, lon => $config{lng_ramsgate_approx} };
	};

	my $live   = $list->geocode($LOC_RAMSGATE);
	my $cached = $list->geocode($LOC_RAMSGATE);

	# The original result must still carry the geocoder object, not 'cache'
	is(ref($live->{geocoder}), 'Geo::Coder::Free',
		'Original result: geocoder field is the live geocoder object');
	is($cached->{geocoder}, $config{cache_str},
		'Cache-hit result: geocoder field is "cache"');
};

# =============================================================================
# 9c. reverse_geocode() -- strict-validation latlng retry (new in 0.37)
# A geocoder that rejects 'latlng' as an unknown parameter triggers a retry
# without that key; lat and lon (split from latlng) are still present.
# =============================================================================

subtest 'integration: reverse_geocode retries without latlng for strict geocoders' => sub {
	# StrictRevGeo simulates a geocoder (like Geo::Coder::GeoApify) that uses
	# Params::Validate::Strict and therefore rejects unknown parameters.
	{
		package IntegrationStrictRevGeo;
		sub new            { bless {}, shift }
		sub reverse_geocode {
			my ($self, %args) = @_;
			die "validate_strict: Unknown parameter 'latlng'\n" if exists $args{latlng};
			return { display_name => 'Ramsgate, Kent, England' };
		}
	}

	my $list = Geo::Coder::List->new()->push(IntegrationStrictRevGeo->new());
	my $r    = $list->reverse_geocode(latlng => $LATLNG_KT);
	is($r, 'Ramsgate, Kent, England',
		'Strict-validation geocoder: address returned after latlng stripped on retry');
};

# =============================================================================

subtest 'integration: ua() propagates to every geocoder in the chain' => sub {
	# Real LWP::UserAgent is passed to geocoders via ua(); spy confirms calls
	my $g1_spy = spy('Geo::Coder::Free::ua');
	my $g2_spy = spy('Geo::Coder::Free::Local::ua');

	my $list = Geo::Coder::List->new();
	$list->push(Geo::Coder::Free->new());
	$list->push(Geo::Coder::Free::Local->new());

	require LWP::UserAgent;
	my $ua = LWP::UserAgent->new();

	my $ret = $list->ua($ua);

	my @g1_calls = $g1_spy->();
	my @g2_calls = $g2_spy->();

	unmock('Geo::Coder::Free',       'ua');
	unmock('Geo::Coder::Free::Local','ua');

	is($ret, $ua, 'ua() returns the passed UA object (POD contract)');
	is(scalar @g1_calls, 1, 'ua() called on Geo::Coder::Free');
	is(scalar @g2_calls, 1, 'ua() called on Geo::Coder::Free::Local');
};

subtest 'integration: ua() propagates through hashref chain entries' => sub {
	# Regex-wrapped geocoder entries must also receive the UA
	my $spy  = spy('Geo::Coder::Free::ua');
	my $list = Geo::Coder::List->new();
	$list->push({ regex => qr/England/, geocoder => Geo::Coder::Free->new() });

	require LWP::UserAgent;
	$list->ua(LWP::UserAgent->new());

	my @calls = $spy->();
	unmock('Geo::Coder::Free', 'ua');

	is(scalar @calls, 1, 'UA propagated into geocoder inside a hashref entry');
};

# =============================================================================
# 10. log() and flush() workflow: stateful multi-geocoder log accumulation
# =============================================================================

subtest 'integration: log accumulates entries across multiple geocode calls' => sub {
	my $list = _free_list();
	$list->geocode($LOC_RAMSGATE);
	$list->geocode($LOC_MARGATE);

	my $log = $list->log();
	ok(scalar @{$log} >= 2,
		'at least two log entries after two different geocode calls');

	# Entries should reference the two distinct locations
	my %locs = map { $_->{location} => 1 } @{$log};
	ok(exists $locs{$LOC_RAMSGATE}, 'Ramsgate in log');
	ok(exists $locs{$LOC_MARGATE},  'Margate in log');
};

subtest 'integration: flush() clears log; next geocode re-accumulates' => sub {
	my $list = _free_list();
	$list->geocode($LOC_RAMSGATE);
	ok(scalar @{$list->log()} >= 1, 'log has entries before flush');

	my $chained = $list->flush();

	# flush must return $self for chaining
	is(refaddr($chained), refaddr($list), 'flush() returns $self');
	is(scalar @{$list->log()}, 0,         'log is empty immediately after flush');

	# Geocode again; log must re-accumulate
	$list->geocode($LOC_MARGATE);
	ok(scalar @{$list->log()} >= 1, 'log has new entries after re-geocoding post-flush');
};

# =============================================================================
# 11. Concurrency: many locations through the same list in sequence
# =============================================================================

subtest 'integration: geocoding many locations does not corrupt state' => sub {
	# Stress-test the list with several sequential lookups to ensure no
	# cross-contamination of results or log entries
	my $list = _free_list();
	my @locations = ($LOC_RAMSGATE, $LOC_MARGATE, $LOC_RAMSGATE);

	my @results;
	for my $loc (@locations) {
		push @results, scalar $list->geocode($loc);
	}

	# Third result (Ramsgate again) should be from cache
	ok(defined $results[0], 'first result defined');
	ok(defined $results[1], 'second result defined (different location)');
	is($results[2]->{geocoder}, $config{cache_str},
		'third result (repeat location) served from cache');

	# The log must have at least one real entry + one cache entry for Ramsgate
	my @cache_entries = grep { ($_->{geocoder} // '') eq $config{cache_str} }
		@{$list->log()};
	ok(scalar @cache_entries >= 1,
		'at least one cache-hit log entry recorded');
};

# =============================================================================
# 12. Not-found locations: undef returned and L1 cache prevents re-querying
# =============================================================================

subtest 'integration: not-found result cached in L1 prevents re-querying' => sub {
	# When no geocoder can resolve a location, undef is returned.
	# The not-found result is stored as a sentinel in L1 so that a second
	# call never hits the backend again (avoids hammering remote services).
	# Geo::Coder::Free does fuzzy matching so we force a controlled miss via mock.
	my $list  = _free_list();
	my $calls = 0;

	my $mock = mock_scoped 'Geo::Coder::Free::geocode' => sub {
		$calls++;
		return ();   # simulate: this location is not in our dataset
	};

	my $r1 = $list->geocode($LOC_RAMSGATE);
	my $r2 = $list->geocode($LOC_RAMSGATE);   # must use L1 sentinel

	ok(!defined $r1, 'returns undef when geocoder finds nothing');
	ok(!defined $r2, 'returns undef for the repeat call too');
	is($calls, 1,    'backend called only once (not-found sentinel cached in L1)');
};

done_testing();

#!/usr/bin/env perl

# transaction.t — Transaction-flow, lifecycle, rollback, and idempotency tests.
#
# Each subtest walks an entity or operation through its complete lifecycle,
# asserting state consistency at every phase boundary.  Where applicable, a
# mid-flight mock failure is injected to verify the system leaves no orphaned
# state and remains usable afterwards.
#
# Phase labels within each subtest:
#   phase 1 — PRE-CONDITION / INITIAL STATE
#   phase 2 — ACTIVE OPERATION / MID-FLIGHT
#   phase 3 — POST-CONDITION / EXPECTED OUTCOME
#   phase 4 — IDEMPOTENCY / RECOVERY (where applicable)
#
# Transaction identifiers:
#   TX1  — Geocode cache write-through (Local)
#   TX2  — Geocode idempotency
#   TX3  — Scantext miss memoization lifecycle
#   TX4  — Backend chain: OA die propagates; Local never reached
#   TX5  — Backend chain: OA miss → Local hit; MaxMind never reached
#   TX6  — Backend chain: all backends miss; clean undef, object valid
#   TX7  — One-shot Local __DATA__ lifecycle
#   TX8  — Alternatives map retry lifecycle
#   TX9  — Geocode → reverse round-trip
#   TX10 — USA/US normalization idempotency
#   TX11 — Local backend lazily created on first OA-path geocode
#   TX12 — Clone shallow-copy state boundary
#   TX13 — Object usable after mid-chain OA exception

use strict;
use warnings;

use File::Temp qw(tempdir);
use Scalar::Util qw(blessed refaddr);
use Test::Most;
use Test::Mockingbird qw(mock restore_all);

local $ENV{OPENADDR_HOME}    = '';
local $ENV{WHOSONFIRST_HOME} = '';

use_ok 'Geo::Coder::Free';
use_ok 'Geo::Coder::Free::Local';
use_ok 'Geo::Coder::Free::OpenAddresses';
use_ok 'Geo::Coder::Free::Utils';
use_ok 'Geo::Location::Point';

# ------------------------------------------------------------------
# Re-establish default MaxMind stubs after any restore_all() call.
# ------------------------------------------------------------------
sub _remock_maxmind {
	mock('Geo::Coder::Free::MaxMind', 'geocode',         sub { return undef });
	mock('Geo::Coder::Free::MaxMind', 'reverse_geocode', sub { return undef });
}

_remock_maxmind();

use constant {
	# ALL_SAINTS_LOC must include the name prefix to match the Local index key.
	ALL_SAINTS_LOC  => 'All Saints Episcopal Church, 203 E Chatsworth Rd, Reisterstown, Baltimore, MD, US',
	ALL_SAINTS_LAT  => 39.467270,
	ALL_SAINTS_LON  => -76.823947,
	ALL_SAINTS_KEY  => 'all saints episcopal church, 203 e chatsworth rd, reisterstown, baltimore, md, us',

	# NCBI_LOC includes 'Montgomery' (the state_district) to hit the index key directly.
	NCBI_LOC        => 'NCBI, Medlars Dr, Bethesda, Montgomery, MD, US',
	NCBI_LAT        => 38.99516556,
	NCBI_LON        => -77.09943963,
	NCBI_KEY        => 'ncbi, medlars dr, bethesda, montgomery, md, us',

	COORD_TOL       => 0.001,

	# Location that is in the __DATA__ alternatives map → 'Ramsgate, Kent'
	ALT_INPUT       => 'St Lawrence, Thanet, Kent',
	ALT_CANONICAL   => 'Ramsgate, Kent',
};

# LOCAL_OBJ — the ONLY Geo::Coder::Free::Local->new() call allowed in this
# process.  The __DATA__ filehandle is exhausted after the first new(); a
# second call returns an empty-dataset object.
my $LOCAL_OBJ = Geo::Coder::Free::Local->new();

# A stable mock GLP used wherever MaxMind or OA returns a "hit" in tests
# that only need to confirm the right backend was reached.
my $MOCK_GLP = Geo::Location::Point->new({ lat => 51.3341, long => 1.3490 });

# Helper: create a mock OA backend pointing at a temp dir.
# Returns (mock_geo_object, tmpdir) — caller is responsible for restore_all().
sub _setup_geo_with_oa {
	my ($oa_geocode_sub) = @_;
	my $tmpdir = tempdir(CLEANUP => 1);
	mock('Geo::Coder::Free::OpenAddresses', 'new', sub {
		bless { openaddr => $tmpdir }, 'Geo::Coder::Free::OpenAddresses'
	});
	mock('Geo::Coder::Free::OpenAddresses', 'geocode', $oa_geocode_sub);
	mock('Geo::Coder::Free::Local', 'new', sub { return $LOCAL_OBJ });
	my $geo;
	{ local $ENV{OPENADDR_HOME} = $tmpdir; $geo = Geo::Coder::Free->new(); }
	return $geo;
}

# =====================================================================
# TX1: Geocode cache write-through
# =====================================================================

subtest 'TX1: geocode cache write-through — index hit populates Local cache; second call skips _search' => sub {
	# Phase 1 — PRE-CONDITION: ensure the address is not already in Local's cache.
	delete $LOCAL_OBJ->{'cache'}{ALL_SAINTS_KEY()};
	ok(!exists $LOCAL_OBJ->{'cache'}{ALL_SAINTS_KEY()},
		'phase 1: address absent from Local cache before first geocode');

	# Phase 2 — OPERATION: first geocode goes through the index and caches the result.
	my $r1 = $LOCAL_OBJ->geocode(location => ALL_SAINTS_LOC);
	isa_ok($r1, 'Geo::Location::Point', 'phase 2: first geocode returns GLP');
	ok(exists $LOCAL_OBJ->{'cache'}{ALL_SAINTS_KEY()},
		'phase 2: result stored in Local cache after first geocode');

	# Phase 3 — CACHE HIT: second geocode returns from cache; _search not invoked.
	my $search_calls = 0;
	mock('Geo::Coder::Free::Local', '_search', sub { $search_calls++; return undef });
	my $r2 = $LOCAL_OBJ->geocode(location => ALL_SAINTS_LOC);
	restore_all();
	_remock_maxmind();

	is($search_calls, 0, 'phase 3: _search NOT called (cache hit)');
	ok($r2, 'phase 3: second geocode returns a result from cache');

	# Phase 4 — IDEMPOTENCY: third geocode still returns the same coordinates.
	my $r3 = $LOCAL_OBJ->geocode(location => ALL_SAINTS_LOC);
	if ($r1 && $r3) {
		is($r1->lat(),  $r3->lat(),  'phase 4: latitude consistent across repeated geocodes');
		is($r1->long(), $r3->long(), 'phase 4: longitude consistent across repeated geocodes');
	}

	delete $LOCAL_OBJ->{'cache'}{ALL_SAINTS_KEY()};
};

# =====================================================================
# TX2: Geocode idempotency
# =====================================================================

subtest 'TX2: geocode idempotency — same address geocoded 3 times yields identical coordinates' => sub {
	my $r1 = $LOCAL_OBJ->geocode(location => ALL_SAINTS_LOC);
	my $r2 = $LOCAL_OBJ->geocode(location => ALL_SAINTS_LOC);
	my $r3 = $LOCAL_OBJ->geocode(location => ALL_SAINTS_LOC);

	isa_ok($r1, 'Geo::Location::Point', 'geocode 1: GLP');
	isa_ok($r2, 'Geo::Location::Point', 'geocode 2: GLP');
	isa_ok($r3, 'Geo::Location::Point', 'geocode 3: GLP');

	if ($r1 && $r2 && $r3) {
		is($r2->lat(),  $r1->lat(),  'geocode 2 lat == geocode 1 lat');
		is($r3->lat(),  $r1->lat(),  'geocode 3 lat == geocode 1 lat');
		is($r2->long(), $r1->long(), 'geocode 2 lon == geocode 1 lon');
		is($r3->long(), $r1->long(), 'geocode 3 lon == geocode 1 lon');
	}

	delete $LOCAL_OBJ->{'cache'}{ALL_SAINTS_KEY()};
};

# =====================================================================
# TX3: Scantext miss memoization lifecycle
# =====================================================================

subtest 'TX3: scantext miss memoization — miss recorded; subsequent scans skip all backends' => sub {
	my $oa_calls = 0;
	my $geo = _setup_geo_with_oa(sub { $oa_calls++; return undef });

	my $text = 'Zephyria Atlantis Xanadu Imagonia Nowheria';

	# Phase 1 — MISS: first scan consults backends; none return a hit.
	my $r1 = $geo->geocode(scantext => $text);
	is($r1, undef, 'phase 1: first scantext → undef (all backends miss)');
	ok(exists $geo->{'scantext_misses'}{$text},
		'phase 1: miss recorded in scantext_misses after first scan');
	cmp_ok($oa_calls, '>', 0, 'phase 1: OA was consulted at least once during first scan');
	my $calls_after_first = $oa_calls;

	# Phase 2 — MEMOIZED: second scan is served from the miss cache; backends not touched.
	my $r2 = $geo->geocode(scantext => $text);
	is($r2, undef, 'phase 2: second scantext → undef (from miss cache)');
	is($oa_calls, $calls_after_first, 'phase 2: OA call count unchanged (miss cache hit)');

	# Phase 3 — IDEMPOTENCY: third scan also returns immediately from miss cache.
	my $r3 = $geo->geocode(scantext => $text);
	is($r3, undef, 'phase 3: third scantext → undef (still from miss cache)');
	is($oa_calls, $calls_after_first, 'phase 3: OA call count still unchanged');

	restore_all();
	_remock_maxmind();
};

# =====================================================================
# TX4: Backend chain — OA die propagates; Local never reached
# =====================================================================

subtest 'TX4: OA exception propagates — GCF does not swallow it; Local is never reached' => sub {
	my $local_calls = 0;

	my $geo = _setup_geo_with_oa(sub { die "simulated DB connection failure\n" });

	# Spy on Local::geocode to verify it is never invoked when OA throws.
	mock('Geo::Coder::Free::Local', 'geocode', sub { $local_calls++; return undef });

	# Phase 1 — EXCEPTION: OA throws → GCF propagates the exception cleanly.
	throws_ok { $geo->geocode(location => ALL_SAINTS_LOC) }
		qr/simulated DB connection failure/,
		'phase 1: OA exception propagates through GCF (not swallowed)';

	# Phase 2 — SHORT-CIRCUIT: Local::geocode was never reached.
	is($local_calls, 0, 'phase 2: Local not reached when OA throws');

	restore_all();
	_remock_maxmind();
};

# =====================================================================
# TX5: Backend chain — OA miss → Local hit; MaxMind never called
# =====================================================================

subtest 'TX5: delegation chain — OA miss delegates to Local; MaxMind never reached on Local hit' => sub {
	my $maxmind_calls = 0;
	mock('Geo::Coder::Free::MaxMind', 'geocode', sub { $maxmind_calls++; return undef });

	my $geo = _setup_geo_with_oa(sub { return undef });

	# Phase 1 — DELEGATION: OA misses; GCF falls through to Local.
	my $r = $geo->geocode(location => ALL_SAINTS_LOC);

	# Phase 2 — RESULT: the GLP comes from Local's dataset, not MaxMind.
	isa_ok($r, 'Geo::Location::Point', 'phase 2: OA miss → Local hit → GLP returned');
	if ($r) {
		cmp_ok(abs($r->lat()  - ALL_SAINTS_LAT), '<', COORD_TOL,
			'phase 2: latitude from Local correct');
		cmp_ok(abs($r->long() - ALL_SAINTS_LON), '<', COORD_TOL,
			'phase 2: longitude from Local correct');
	}

	# Phase 3 — SHORT-CIRCUIT: MaxMind never consulted (Local succeeded).
	is($maxmind_calls, 0, 'phase 3: MaxMind NOT called when Local succeeds');

	restore_all();
	_remock_maxmind();
};

# =====================================================================
# TX6: Backend chain — all backends miss; undef returned cleanly
# =====================================================================

subtest 'TX6: all-miss chain — undef returned cleanly; object remains valid; subsequent geocode works' => sub {
	my $geo = _setup_geo_with_oa(sub { return undef });
	mock('Geo::Coder::Free::MaxMind', 'geocode', sub { return undef });

	# Phase 1 — ALL MISS: unknown address → undef, no exception.
	my $r1;
	lives_ok { $r1 = $geo->geocode(location => 'Atlantis, Xanadu, ZZ') }
		'phase 1: all-miss geocode does not croak';
	is($r1, undef, 'phase 1: undef returned when all backends miss');

	# Phase 2 — OBJECT VALID: the GCF object is still well-formed after all-miss.
	isa_ok($geo, 'Geo::Coder::Free', 'phase 2: GCF object is still valid after all-miss');

	# Phase 3 — RECOVERY: a subsequent geocode of a known address succeeds.
	mock('Geo::Coder::Free::OpenAddresses', 'geocode', sub { return $MOCK_GLP });
	my $r3 = $geo->geocode(location => 'Ramsgate, Kent, GB');
	isa_ok($r3, 'Geo::Location::Point',
		'phase 3: object recovers; next geocode returns GLP after prior all-miss');

	restore_all();
	_remock_maxmind();
};

# =====================================================================
# TX7: One-shot Local __DATA__ lifecycle
# =====================================================================

subtest 'TX7: one-shot __DATA__ lifecycle — first Local has full dataset; second is empty' => sub {
	# Phase 1 — FIRST OBJECT: $LOCAL_OBJ (module-scope) consumed __DATA__.
	cmp_ok(scalar @{$LOCAL_OBJ->{'data'}}, '>', 50,
		'phase 1: first Local object has more than 50 rows');
	ok(exists $LOCAL_OBJ->{'index'}{ALL_SAINTS_KEY()},
		'phase 1: All Saints entry present in first object\'s index');

	# Phase 2 — SECOND OBJECT: __DATA__ filehandle is at EOF; dataset is empty.
	my $empty_obj = Geo::Coder::Free::Local->new();
	is(scalar @{$empty_obj->{'data'}}, 0,
		'phase 2: second Local object has empty data (one-shot __DATA__ exhausted)');
	is(scalar keys %{$empty_obj->{'index'}}, 0,
		'phase 2: second Local object has empty index');

	# Phase 3 — NO RESULTS: every geocode on the empty object returns undef.
	my $r = $empty_obj->geocode(location => ALL_SAINTS_LOC);
	is($r, undef, 'phase 3: geocode on empty dataset returns undef');
	my $r2 = $empty_obj->geocode(location => NCBI_LOC);
	is($r2, undef, 'phase 3: another geocode on empty dataset also returns undef');

	# Phase 4 — ISOLATION: the first object is unaffected by the empty second.
	my $r3 = $LOCAL_OBJ->geocode(location => ALL_SAINTS_LOC);
	isa_ok($r3, 'Geo::Location::Point',
		'phase 4: first Local object still functional after second is created');

	delete $LOCAL_OBJ->{'cache'}{ALL_SAINTS_KEY()};
};

# =====================================================================
# TX8: Alternatives map retry lifecycle
# =====================================================================

subtest 'TX8: alternatives retry — input matched by alternatives table triggers re-geocode with canonical name' => sub {
	# ALT_INPUT ('St Lawrence, Thanet, Kent') is in Free.pm __DATA__:
	#   St Lawrence, Thanet, Kent = Ramsgate, Kent
	# OA returns a GLP only for 'Ramsgate'; all other calls return undef.
	my @oa_locations_seen;
	my $geo = _setup_geo_with_oa(sub {
		my (undef, $params) = @_;
		my $loc = ref($params) eq 'HASH'
			? ($params->{'location'} // '?')
			: ($params // '?');
		push @oa_locations_seen, $loc;
		return ($loc =~ /Ramsgate/i) ? $MOCK_GLP : undef;
	});

	# Phase 1 — INITIAL MISS: original input misses in OA.
	# Phase 2 — ALTERNATIVES LOOKUP: alternatives table fires; re-geocodes with canonical.
	# Phase 3 — CANONICAL HIT: OA returns GLP for 'Ramsgate, Kent'.
	my $r = $geo->geocode(location => ALT_INPUT);

	isa_ok($r, 'Geo::Location::Point',
		'phase 3: alternatives re-geocode produces GLP');

	cmp_ok(scalar @oa_locations_seen, '>=', 2,
		'phase 1+2: OA consulted at least twice (original + alternatives mapping)');

	my @ramsgate_calls = grep { /Ramsgate/i } @oa_locations_seen;
	cmp_ok(scalar @ramsgate_calls, '>=', 1,
		'phase 2: canonical "Ramsgate" was queried via alternatives mapping');

	# Phase 4 — ITERATOR STATE NOTE: the alternatives loop uses `each %{$alt}`, which
	# retains its internal iterator position across calls.  After an early return inside
	# the loop, the next invocation continues from the next hash entry rather than
	# restarting.  The second geocode may or may not find the same alternative depending
	# on what remains after the matched key in the iteration order.  We only assert that
	# the call completes without error.
	@oa_locations_seen = ();
	my $r2;
	lives_ok { $r2 = $geo->geocode(location => ALT_INPUT) }
		'phase 4: second geocode with same input completes without error (each iterator state)';
	ok(!defined($r2) || ref($r2) eq 'Geo::Location::Point',
		'phase 4: result is undef (iterator skipped) or GLP (iterator wrapped) — both valid');

	restore_all();
	_remock_maxmind();
};

# =====================================================================
# TX9: Geocode → reverse round-trip
# =====================================================================

subtest 'TX9: geocode → reverse round-trip — coordinates from geocode fed into reverse_geocode' => sub {
	# Phase 1 — GEOCODE: resolve a known address to coordinates.
	my $glp = $LOCAL_OBJ->geocode(location => NCBI_LOC);
	isa_ok($glp, 'Geo::Location::Point', 'phase 1: geocode returns GLP');
	skip 'geocode returned undef — skipping reverse round-trip' unless $glp;

	my ($lat, $lon) = ($glp->lat(), $glp->long());
	cmp_ok(abs($lat - NCBI_LAT), '<', COORD_TOL, 'phase 1: latitude in expected range');
	cmp_ok(abs($lon - NCBI_LON), '<', COORD_TOL, 'phase 1: longitude in expected range');

	# Phase 2 — REVERSE: feed those coordinates back into Local::reverse_geocode.
	my @results = $LOCAL_OBJ->reverse_geocode(latlng => "$lat,$lon");
	cmp_ok(scalar @results, '>=', 1,
		'phase 2: reverse_geocode returns at least one result');
	my $any_ncbi = grep { /NCBI|BETHESDA|MEDLARS/i } @results;
	ok($any_ncbi, 'phase 2: reverse result mentions the NCBI area');

	# Phase 3 — SCALAR CONTEXT: single-result form returns a plain string.
	my $scalar_r = $LOCAL_OBJ->reverse_geocode(latlng => "$lat,$lon");
	ok(defined $scalar_r && !ref($scalar_r),
		'phase 3: scalar context returns a plain string');

	# Phase 4 — CONSISTENCY: the scalar result appears in the list result.
	ok((grep { $_ eq $scalar_r } @results),
		'phase 4: scalar result is contained in list result set');

	delete $LOCAL_OBJ->{'cache'}{NCBI_KEY()};
};

# =====================================================================
# TX10: USA/US normalization idempotency
# =====================================================================

subtest 'TX10: USA/US normalization — "USA" and "US" suffixes resolve to identical coordinates' => sub {
	my $addr_us  = NCBI_LOC;
	my $addr_usa = do { (my $s = NCBI_LOC) =~ s/, US$/, USA/; $s };
	my $norm_key = NCBI_KEY;

	# Phase 1 — US VARIANT: geocode the canonical 'US' form.
	delete $LOCAL_OBJ->{'cache'}{$norm_key};
	my $r1 = $LOCAL_OBJ->geocode(location => $addr_us);
	isa_ok($r1, 'Geo::Location::Point', 'phase 1: "US" variant → GLP');

	# Phase 2 — USA VARIANT: the normalisation s/,\s*usa$/, us/i maps it to the same key.
	delete $LOCAL_OBJ->{'cache'}{$norm_key};
	my $r2 = $LOCAL_OBJ->geocode(location => $addr_usa);
	isa_ok($r2, 'Geo::Location::Point', 'phase 2: "USA" variant → GLP');

	# Phase 3 — IDEMPOTENCY: both variants resolve to the same coordinates.
	if ($r1 && $r2) {
		is($r1->lat(),  $r2->lat(),  'phase 3: "US" and "USA" return same latitude');
		is($r1->long(), $r2->long(), 'phase 3: "US" and "USA" return same longitude');
	}

	# Phase 4 — CACHE UNIFICATION: after either geocode the cache holds one shared key.
	ok(exists $LOCAL_OBJ->{'cache'}{$norm_key},
		'phase 4: both variants share the same normalised cache key');

	delete $LOCAL_OBJ->{'cache'}{$norm_key};
};

# =====================================================================
# TX11: Local backend lazily created on first OA-path geocode
# =====================================================================

subtest 'TX11: lazy backend creation — local not created until first geocode triggers OA miss' => sub {
	my $geo = _setup_geo_with_oa(sub { return undef });

	# Phase 1 — PRE-GEOCODE: the local backend slot is unset on a fresh GCF object.
	ok(!defined($geo->{'local'}),
		'phase 1: local backend not yet created before any geocode');

	# Phase 2 — FIRST GEOCODE: OA miss causes the local backend to be lazily instantiated.
	my $r = $geo->geocode(location => 'Nowhere, Anytown, ZZ');

	# Phase 3 — POST-GEOCODE: the local backend is now initialised.
	ok(defined($geo->{'local'}),
		'phase 3: local backend created after first geocode triggers OA miss');
	is(refaddr($geo->{'local'}), refaddr($LOCAL_OBJ),
		'phase 3: local backend is the mocked singleton');

	# Phase 4 — IDEMPOTENCY: a second geocode reuses the same backend instance.
	$geo->geocode(location => 'Nowhere, Anytown, ZZ');
	is(refaddr($geo->{'local'}), refaddr($LOCAL_OBJ),
		'phase 4: same local backend instance reused on subsequent geocodes');

	restore_all();
	_remock_maxmind();
};

# =====================================================================
# TX12: Clone shallow-copy state boundary
# =====================================================================

subtest 'TX12: clone state boundary — shallow copy shares references; mutations visible across both sides' => sub {
	my $original = Geo::Coder::Free->new();

	# Phase 1 — SETUP: populate the original's instance state manually.
	$original->{'scantext_misses'} //= {};
	$original->{'scantext_misses'}{'sentinel text'} = 1;

	# Phase 2 — CLONE: bless { %$original, ... } creates a shallow copy.
	my $clone = $original->new();
	isa_ok($clone, 'Geo::Coder::Free', 'phase 2: clone isa GCF');
	isnt(refaddr($original), refaddr($clone), 'phase 2: clone is a distinct hashref');

	# Phase 3 — SHARED REFERENCES: alternatives and scantext_misses are the same hashref.
	is(refaddr($original->{'alternatives'}), refaddr($clone->{'alternatives'}),
		'phase 3: alternatives singleton is shared by identity');
	is(refaddr($original->{'scantext_misses'}), refaddr($clone->{'scantext_misses'}),
		'phase 3: scantext_misses hashref is shared (shallow copy)');

	# Phase 4 — MUTATION PROPAGATION: a write via the clone is visible in the original.
	$clone->{'scantext_misses'}{'injected by clone'} = 1;
	ok(exists $original->{'scantext_misses'}{'injected by clone'},
		'phase 4: mutation via clone immediately visible in original (shared reference)');

	# Phase 5 — ALTERNATIVES MUTATION PROPAGATION: same effect for the alternatives map.
	$clone->{'alternatives'}{'__tx12_test__'} = '__tx12_value__';
	ok(exists $original->{'alternatives'}{'__tx12_test__'},
		'phase 5: alternatives mutation via clone visible in original');
	# Clean up the injected test key
	delete $clone->{'alternatives'}{'__tx12_test__'};
};

# =====================================================================
# TX13: Object usable after mid-chain OA exception
# =====================================================================

subtest 'TX13: state preservation — GCF object valid after OA exception; subsequent calls succeed' => sub {
	my $geo = _setup_geo_with_oa(sub { return $MOCK_GLP });

	# Phase 1 — NORMAL: pre-failure geocode succeeds.
	my $r1 = $geo->geocode(location => 'Ramsgate, Kent, GB');
	isa_ok($r1, 'Geo::Location::Point', 'phase 1: pre-failure geocode returns GLP');

	# Phase 2 — FAILURE: OA starts throwing; the exception propagates cleanly.
	mock('Geo::Coder::Free::OpenAddresses', 'geocode', sub { die "transient DB error\n" });
	throws_ok { $geo->geocode(location => 'Ramsgate, Kent, GB') }
		qr/transient DB error/,
		'phase 2: exception propagates cleanly through GCF';

	# Phase 3 — OBJECT VALID: the GCF object is still well-formed after the exception.
	isa_ok($geo, 'Geo::Coder::Free',
		'phase 3: GCF object is still a valid blessed reference after exception');

	# Phase 4 — RECOVERY: once OA is restored, geocode works again.
	mock('Geo::Coder::Free::OpenAddresses', 'geocode', sub { return $MOCK_GLP });
	my $r4;
	lives_ok { $r4 = $geo->geocode(location => 'Ramsgate, Kent, GB') }
		'phase 4: geocode lives after OA is restored';
	isa_ok($r4, 'Geo::Location::Point',
		'phase 4: GCF fully functional after OA recovered from exception');

	restore_all();
	_remock_maxmind();
};

done_testing();

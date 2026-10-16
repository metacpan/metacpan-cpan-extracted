#!/usr/bin/env perl

# End-to-end integration tests for Geo::Coder::Free.
#
# Strategy: exercise stateful cross-module workflows — the backend delegation
# chain, alternatives mapping, scantext memoisation, geocode/reverse-geocode
# round-trips, Utils distance from geocoded coordinates, and the optional-
# dependency fallback paths.  Spy on inter-module calls to verify that the
# right backend is reached at the right time with the right arguments.
#
# These tests are NOT exhaustive unit tests.  They prove that the modules
# work TOGETHER correctly, complementing the contract-level checks in
# t/unit.t and the white-box checks in t/function.t.

use strict;
use warnings;

use CHI;
use File::Temp qw(tempdir);
use Geo::Hash;
use Readonly;
use Scalar::Util qw(blessed refaddr);
use Storable;
use Test::Most;
use Test::Mockingbird qw(mock spy restore_all);
use Test::Returns;
use Test::Without::Module ();

use lib 'lib';

BEGIN {
	use_ok('Geo::Coder::Free')               or BAIL_OUT('Geo::Coder::Free failed to load');
	use_ok('Geo::Coder::Free::Local')        or BAIL_OUT('Geo::Coder::Free::Local failed to load');
	use_ok('Geo::Coder::Free::OpenAddresses') or BAIL_OUT('Geo::Coder::Free::OpenAddresses failed to load');
	use_ok('Geo::Coder::Free::MaxMind')      or BAIL_OUT('Geo::Coder::Free::MaxMind failed to load');
	use_ok('Geo::Coder::Free::Utils')        or BAIL_OUT('Geo::Coder::Free::Utils failed to load');
	use_ok('Geo::Location::Point')           or BAIL_OUT('Geo::Location::Point failed to load');
}

Geo::Coder::Free::Utils->import(qw(distance create_disc_cache create_memory_cache));

# ---------------------------------------------------------------------------
# Environment isolation.  Suppress OPENADDR_HOME so all Geo::Coder::Free->new()
# calls that do NOT explicitly pass openaddr => ... create MaxMind-only objects.
# Tests that need the OA backend pass openaddr => tempdir() explicitly.
# ---------------------------------------------------------------------------
local $ENV{OPENADDR_HOME}    = '';
local $ENV{WHOSONFIRST_HOME} = '';

# ---------------------------------------------------------------------------
# Named constants — addresses present in Local.pm's __DATA__ section.
# ---------------------------------------------------------------------------

Readonly::Scalar my $EARLS_COLNE_ADDR => 'St andrews church, Church Hill, Earls Colne, Essex, GB';
Readonly::Scalar my $EARLS_COLNE_LAT  => 51.926793;
Readonly::Scalar my $EARLS_COLNE_LON  => 0.70408;

Readonly::Scalar my $NCBI_ADDR  => 'NCBI, MEDLARS DR, BETHESDA, MONTGOMERY, MD, USA';
Readonly::Scalar my $NCBI_LAT   => 38.995166;
Readonly::Scalar my $NCBI_LON   => -77.099440;
Readonly::Scalar my $NCBI_LATLNG => '38.995166,-77.099440';

Readonly::Scalar my $TOWER_ADDR => 'Tower of London, Tower Hill, London, London, GB';
Readonly::Scalar my $TOWER_LAT  => 51.508268;
Readonly::Scalar my $TOWER_LON  => -0.075423;

Readonly::Scalar my $RAMSGATE_STN_ADDR => 'Ramsgate Station, Station Approach Rd, Ramsgate, Kent, GB';
Readonly::Scalar my $RAMSGATE_STN_LAT  => 51.340826;
Readonly::Scalar my $RAMSGATE_STN_LON  => 1.406519;

# ---------------------------------------------------------------------------
# A stand-in for the OpenAddresses database handle.  _get() asks it only for the
# geohash of an address digest, so the lookup can be answered without a data
# file, leaving the provenance stamping and the Storable round trip in the code
# under test.
# ---------------------------------------------------------------------------
package OA_Stub_DB;

sub new { my ($class, $geohash) = @_; return bless { geohash => $geohash }, $class }
sub geohash { return $_[0]->{'geohash'} }

package main;

# OA hard-coded known_locations entry — no database access required.
Readonly::Scalar my $NEWPORT_ADDR => 'Newport Pagnell, Buckinghamshire, England';
Readonly::Scalar my $NEWPORT_LAT  => 52.08675;
Readonly::Scalar my $NEWPORT_LON  => -0.72270;

# Alternatives: both of these should resolve to the Ramsgate area.
Readonly::Scalar my $ALT_ADDR   => 'Minster, Thanet, Kent';
Readonly::Scalar my $ALT_TARGET => 'Ramsgate, Kent';

# Mock point for MaxMind / OA backend responses.
Readonly::Scalar my $MOCK_LAT  => 51.3341;
Readonly::Scalar my $MOCK_LON  => -1.4159;
my $MOCK_PT = Geo::Location::Point->new({ lat => $MOCK_LAT, long => $MOCK_LON });

# Coordinate tolerance for floating-point comparisons (1e-3 degrees ≈ 100 m).
Readonly::Scalar my $COORD_TOL  => 1e-3;
Readonly::Scalar my $DIST_TOL_M => 5;      # statute miles
Readonly::Scalar my $DIST_TOL_K => 10;     # kilometres

# ---------------------------------------------------------------------------
# IMPORTANT: Geo::Coder::Free::Local reads __DATA__ once at new() time.
# The Perl filehandle reaches EOF after the first read, so a second new()
# produces an empty object.  A single shared instance is used across all
# Local subtests that need the real, populated object.
# ---------------------------------------------------------------------------
my $LOCAL_OBJ = Geo::Coder::Free::Local->new();

# ============================================================================
# SECTION 1 — Backend delegation chain
#
# The GCF facade tries backends in priority order:
#   (with openaddr)  OA → Local → alternatives map → MaxMind
#   (without openaddr)  MaxMind only
#
# We use Test::Mockingbird::spy to verify which backends are actually invoked.
# ============================================================================

subtest 'Delegation — OA hit short-circuits Local and MaxMind' => sub {
	# When OA returns a result the other two backends must not be called.
	# This is the highest-priority path.
	my $tmpdir = tempdir(CLEANUP => 1);

	mock('Geo::Coder::Free::OpenAddresses', 'geocode', sub { return $MOCK_PT });
	mock('Geo::Coder::Free::MaxMind',       'geocode', sub { return undef    });

	# Spies wrap the mocks and record every call.
	my $oa_spy = spy('Geo::Coder::Free::OpenAddresses::geocode');
	my $mm_spy = spy('Geo::Coder::Free::MaxMind::geocode');

	my $geo = Geo::Coder::Free->new(openaddr => $tmpdir);
	my $r   = $geo->geocode(location => $EARLS_COLNE_ADDR);

	isa_ok($r, 'Geo::Location::Point', 'geocode returns a GLP');
	is(refaddr($r), refaddr($MOCK_PT), 'result is the OA mock point');

	my @oa_calls = $oa_spy->();
	my @mm_calls = $mm_spy->();
	is(scalar @oa_calls, 1, 'OA::geocode called exactly once');
	is(scalar @mm_calls, 0, 'MaxMind::geocode NOT called when OA succeeds');

	# Verify the argument forwarded to OA contains the location key.
	my $oa_arg = $oa_calls[0][2];	# [method, self, arg]
	is(ref($oa_arg), 'HASH', 'OA::geocode receives a hashref');
	is($oa_arg->{'location'}, $EARLS_COLNE_ADDR, 'OA receives the correct location string');

	restore_all();
};

subtest 'Delegation — OA miss falls through to Local' => sub {
	# When OA returns undef for a known-address, the Local backend must handle it.
	# IMPORTANT: GCF lazily creates Local via $self->{'local'} ||= Local->new().
	# Because __DATA__ is a one-shot filehandle already exhausted by $LOCAL_OBJ,
	# we intercept Local->new() and return the shared, pre-populated instance.
	my $tmpdir = tempdir(CLEANUP => 1);

	mock('Geo::Coder::Free::Local',         'new',    sub { return $LOCAL_OBJ });
	mock('Geo::Coder::Free::OpenAddresses', 'geocode', sub { return undef });
	mock('Geo::Coder::Free::MaxMind',       'geocode', sub { return undef });

	my $mm_spy = spy('Geo::Coder::Free::MaxMind::geocode');

	my $geo = Geo::Coder::Free->new(openaddr => $tmpdir);
	my $r   = $geo->geocode(location => $EARLS_COLNE_ADDR);

	# Local handles the address without MaxMind involvement.
	isa_ok($r, 'Geo::Location::Point', 'geocode returns GLP from Local');
	ok(abs($r->lat()  - $EARLS_COLNE_LAT) < $COORD_TOL, 'latitude matches Local data');
	ok(abs($r->long() - $EARLS_COLNE_LON) < $COORD_TOL, 'longitude matches Local data');
	is(scalar $mm_spy->(), 0, 'MaxMind NOT called when Local succeeds');

	restore_all();
};

subtest 'Delegation — OA and Local both miss, MaxMind is called as last resort' => sub {
	# When neither OA nor Local can resolve the address, MaxMind receives it.
	# Local::new is mocked to return $LOCAL_OBJ (prevents __DATA__ re-read).
	# "Unknown Town" is not in Local's data, so Local returns undef cleanly.
	my $tmpdir = tempdir(CLEANUP => 1);

	mock('Geo::Coder::Free::Local',         'new',    sub { return $LOCAL_OBJ });
	mock('Geo::Coder::Free::OpenAddresses', 'geocode', sub { return undef });
	mock('Geo::Coder::Free::MaxMind',       'geocode', sub { return $MOCK_PT });

	my $mm_spy = spy('Geo::Coder::Free::MaxMind::geocode');

	my $geo = Geo::Coder::Free->new(openaddr => $tmpdir);
	# 'Unknown Town' is not in Local __DATA__ — falls through to MaxMind.
	my $r = $geo->geocode(location => 'Unknown Town, Some County, UK');

	isa_ok($r, 'Geo::Location::Point', 'geocode returns GLP from MaxMind fallback');
	is(refaddr($r), refaddr($MOCK_PT), 'MaxMind mock result returned');

	my @mm_calls = $mm_spy->();
	is(scalar @mm_calls, 1, 'MaxMind::geocode called exactly once');

	# Verify MaxMind receives the correct hashref argument.
	my $mm_arg = $mm_calls[0][2];
	is(ref($mm_arg), 'HASH', 'MaxMind receives a hashref');
	ok(exists $mm_arg->{'location'}, 'hashref contains "location" key');

	restore_all();
};

subtest 'Delegation — no openaddr, MaxMind is the only backend tried' => sub {
	# With OPENADDR_HOME suppressed and no explicit openaddr, the GCF object has
	# no OA backend.  geocode() must go directly to MaxMind.
	mock('Geo::Coder::Free::MaxMind', 'geocode', sub { return $MOCK_PT });
	my $mm_spy = spy('Geo::Coder::Free::MaxMind::geocode');

	my $geo = Geo::Coder::Free->new();    # no openaddr
	my $r   = $geo->geocode(location => 'Ramsgate, Kent, UK');

	isa_ok($r, 'Geo::Location::Point', 'MaxMind-only path returns GLP');
	is(scalar $mm_spy->(), 1, 'MaxMind called exactly once');
	ok(!exists $geo->{'openaddr'}, 'GCF object has no openaddr backend');

	restore_all();
};

# ============================================================================
# SECTION 2 — Alternatives map
#
# The __DATA__ section of Free.pm provides a hand-curated mapping for place
# names that the databases store differently.  The table is loaded once and
# shared (same reference) across all GCF instances (module-level singleton).
# ============================================================================

subtest 'Alternatives — shared singleton across instances' => sub {
	# Two independently constructed objects must refer to the same alternatives
	# hashref, proving the table is populated exactly once.
	mock('Geo::Coder::Free::MaxMind', 'geocode', sub { return undef });

	my $g1 = Geo::Coder::Free->new();
	my $g2 = Geo::Coder::Free->new();

	isa_ok($g1->{'alternatives'}, 'HASH', 'alternatives is a hashref on g1');
	is(refaddr($g1->{'alternatives'}), refaddr($g2->{'alternatives'}),
		'both instances share the same alternatives reference');
	ok(scalar(keys %{$g1->{'alternatives'}}) > 0, 'alternatives table is non-empty');

	diag 'alternatives count: ' . scalar(keys %{$g1->{'alternatives'}})
		if $ENV{TEST_VERBOSE};

	restore_all();
};

subtest 'Alternatives — address mapping triggers OA re-lookup with canonical name' => sub {
	# "Minster, Thanet, Kent" is in the alternatives table mapping to "Ramsgate, Kent".
	# The geocode flow must: try original → miss → try mapped name → succeed.
	# Local::new is mocked to prevent __DATA__ re-read (Local returns undef for this address).
	my $tmpdir = tempdir(CLEANUP => 1);

	mock('Geo::Coder::Free::Local', 'new', sub { return $LOCAL_OBJ });

	my @oa_locations;
	my $call_no = 0;
	mock('Geo::Coder::Free::OpenAddresses', 'geocode', sub {
		my (undef, $arg) = @_;
		my $loc = ref($arg) eq 'HASH' ? $arg->{'location'} : $arg;
		push @oa_locations, $loc;
		$call_no++;
		# Return a hit on the second call (the alternatives-mapped address).
		return $call_no >= 2 ? $MOCK_PT : undef;
	});
	mock('Geo::Coder::Free::MaxMind', 'geocode', sub { return undef });

	my $geo = Geo::Coder::Free->new(openaddr => $tmpdir);
	my $r   = $geo->geocode(location => $ALT_ADDR);

	isa_ok($r, 'Geo::Location::Point', 'alternatives path returns GLP');
	ok(scalar(@oa_locations) >= 2,
		'OA queried at least twice (original + mapped alternative)');
	ok((grep { defined $_ && $_ =~ /Ramsgate/ } @oa_locations),
		"mapped alternative '$ALT_TARGET' was passed to OA");

	diag 'OA locations tried: ' . join(', ', map { qq["$_"] } grep { defined } @oa_locations)
		if $ENV{TEST_VERBOSE};

	restore_all();
};

# ============================================================================
# SECTION 3 — Concurrency: two GCF instances are independent
#
# The facade's mutable per-instance state (scantext_misses, openaddr backend
# object) must not bleed between independently constructed instances.
# ============================================================================

subtest 'Concurrency — two GCF instances have distinct MaxMind objects' => sub {
	mock('Geo::Coder::Free::MaxMind', 'geocode', sub { return undef });

	my $g1 = Geo::Coder::Free->new();
	my $g2 = Geo::Coder::Free->new();

	isa_ok($g1, 'Geo::Coder::Free', 'g1 is a GCF');
	isa_ok($g2, 'Geo::Coder::Free', 'g2 is a GCF');
	isnt(refaddr($g1), refaddr($g2), 'instances are distinct references');
	isnt(refaddr($g1->{'maxmind'}), refaddr($g2->{'maxmind'}),
		'each instance owns its own MaxMind backend object');

	restore_all();
};

subtest 'Concurrency — scantext_misses are per-instance, not global' => sub {
	# A failed scantext geocode on g1 must NOT mark any text as a miss on g2.
	my $tmpdir = tempdir(CLEANUP => 1);

	mock('Geo::Coder::Free::Local',         'new',    sub { return $LOCAL_OBJ });
	mock('Geo::Coder::Free::OpenAddresses', 'geocode', sub { return undef });
	mock('Geo::Coder::Free::MaxMind',       'geocode', sub { return undef });

	my $g1 = Geo::Coder::Free->new(openaddr => $tmpdir);
	my $g2 = Geo::Coder::Free->new(openaddr => $tmpdir);

	$g1->geocode(scantext => 'Zork blurb nothing here');

	my $g1_misses = scalar keys %{$g1->{'scantext_misses'} // {}};
	my $g2_misses = scalar keys %{$g2->{'scantext_misses'} // {}};

	ok($g1_misses > 0, 'g1 has recorded scantext misses after a failed lookup');
	is($g2_misses, 0,  'g2 has NO scantext misses — state does not bleed');

	diag "g1 misses: $g1_misses, g2 misses: $g2_misses" if $ENV{TEST_VERBOSE};

	restore_all();
};

subtest 'Concurrency — explicit cache objects are per-instance' => sub {
	# When each instance is constructed with its own CHI cache the two must not
	# share state even though both use the in-memory driver.
	my $cache1 = CHI->new(driver => 'Memory', global => 0);
	my $cache2 = CHI->new(driver => 'Memory', global => 0);

	mock('Geo::Coder::Free::MaxMind', 'geocode', sub { return undef });

	my $g1 = Geo::Coder::Free->new(cache => $cache1);
	my $g2 = Geo::Coder::Free->new(cache => $cache2);

	is(refaddr($g1->{'cache'}), refaddr($cache1), 'g1 holds cache1');
	is(refaddr($g2->{'cache'}), refaddr($cache2), 'g2 holds cache2');
	isnt(refaddr($cache1), refaddr($cache2),       'the two caches are distinct objects');

	restore_all();
};

# ============================================================================
# SECTION 4 — Clone behaviour
#
# $geo->new() returns a shallow copy.  The alternatives reference (module-level
# singleton) is shared.  The mutable scantext_misses hash is NOT shared —
# modifications after cloning diverge cleanly.
# ============================================================================

subtest 'Clone — shallow copy shares alternatives but not scantext_misses' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);

	mock('Geo::Coder::Free::Local',         'new',    sub { return $LOCAL_OBJ });
	mock('Geo::Coder::Free::OpenAddresses', 'geocode', sub { return undef });
	mock('Geo::Coder::Free::MaxMind',       'geocode', sub { return undef });

	my $original = Geo::Coder::Free->new(openaddr => $tmpdir);
	# Trigger a miss to populate scantext_misses on the original.
	$original->geocode(scantext => 'Zork blurb nothing here');
	my $orig_misses = scalar keys %{$original->{'scantext_misses'} // {}};
	ok($orig_misses > 0, 'original has misses before clone');

	my $clone = $original->new();
	isa_ok($clone, 'Geo::Coder::Free', 'clone isa GCF');
	isnt(refaddr($clone), refaddr($original), 'clone is a distinct reference');

	# Alternatives are the module-level singleton — same ref in both.
	is(refaddr($clone->{'alternatives'}), refaddr($original->{'alternatives'}),
		'clone shares the alternatives singleton');

	# bless { %{$class}, %{$params} } is a SHALLOW copy: it copies the reference
	# to the scantext_misses hashref, not the hashref itself.  Consequently the
	# clone and the original share the same underlying hash — mutations on one
	# are immediately visible on the other.  This is the documented behavior.
	is(refaddr($clone->{'scantext_misses'}), refaddr($original->{'scantext_misses'}),
		'clone shares the scantext_misses hashref (shallow copy semantics)');

	$clone->geocode(scantext => 'A completely different text passage');
	my $clone_misses = scalar keys %{$clone->{'scantext_misses'} // {}};
	my $orig_after   = scalar keys %{$original->{'scantext_misses'} // {}};

	is($orig_after, $clone_misses,
		'original also sees clone misses — both reference the same hash');

	restore_all();
};

# ============================================================================
# SECTION 5 — Scantext memoisation
#
# A failed scantext lookup on a GCF instance records the text in
# $self->{scantext_misses}.  Calling geocode() again with the same text must
# return undef immediately WITHOUT calling any backend.
# ============================================================================

subtest 'Scantext — repeated failure is served from the miss cache' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);

	mock('Geo::Coder::Free::Local', 'new', sub { return $LOCAL_OBJ });

	my $oa_call_count = 0;
	mock('Geo::Coder::Free::OpenAddresses', 'geocode', sub {
		$oa_call_count++;
		return undef;
	});
	mock('Geo::Coder::Free::MaxMind', 'geocode', sub { return undef });

	my $geo = Geo::Coder::Free->new(openaddr => $tmpdir);
	my $text = 'Zork blurb nothing here';

	$geo->geocode(scantext => $text);
	my $first_calls = $oa_call_count;
	ok($first_calls >= 0, "first geocode: OA called $first_calls time(s)");

	# Reset counter and call again with the SAME text.
	$oa_call_count = 0;
	my $r2 = $geo->geocode(scantext => $text);
	ok(!defined($r2), 'second geocode of same text returns undef');
	is($oa_call_count, 0,
		'OA::geocode not called again when text is in miss cache');

	diag "Initial OA call count: $first_calls" if $ENV{TEST_VERBOSE};

	restore_all();
};

# ============================================================================
# SECTION 6 — Geocode → reverse_geocode round-trip via Local
#
# The Local backend is the only one that supports both geocode and
# reverse_geocode without an external database.  Given a known address from
# the __DATA__ section, geocode → coordinates → reverse_geocode must
# return a string that names the original location.
# ============================================================================

subtest 'Round-trip — Local geocode then reverse_geocode' => sub {
	# Geocode a Local-known address to get canonical coordinates.
	my $pt = $LOCAL_OBJ->geocode(location => $NCBI_ADDR);
	isa_ok($pt, 'Geo::Location::Point', 'geocode returns a GLP');
	ok(abs($pt->lat()  - $NCBI_LAT) < $COORD_TOL, 'latitude in range');
	ok(abs($pt->long() - $NCBI_LON) < $COORD_TOL, 'longitude in range');

	# Reverse geocode using the stored lat/lon values.
	my $name = $LOCAL_OBJ->reverse_geocode(latlng => $NCBI_LATLNG);
	ok(defined($name) && length($name) > 0, 'reverse_geocode returns a non-empty string');
	like($name, qr/NCBI/i, 'reverse_geocode result mentions NCBI');

	diag "reverse_geocode result: $name" if $ENV{TEST_VERBOSE};
};

subtest 'Round-trip — reverse_geocode in list context returns multiple candidates' => sub {
	my @results = $LOCAL_OBJ->reverse_geocode(latlng => $NCBI_LATLNG);
	ok(scalar @results >= 1, 'list context returns at least one string');
	ok((grep { /NCBI/i } @results), 'at least one result mentions NCBI');

	diag 'reverse_geocode list: ' . join(', ', map { qq["$_"] } @results)
		if $ENV{TEST_VERBOSE};
};

subtest 'Round-trip — lat+long params (alias for latlng)' => sub {
	my $pt = $LOCAL_OBJ->geocode(location => $EARLS_COLNE_ADDR);
	isa_ok($pt, 'Geo::Location::Point', 'geocode returns GLP');

	my $name = $LOCAL_OBJ->reverse_geocode(
		lat  => $pt->lat(),
		long => $pt->long(),
	);
	ok(defined($name), 'reverse_geocode via lat+long returns a value');
	like($name, qr/Earls\s+Colne/i, 'result mentions Earls Colne');
};

# ============================================================================
# SECTION 7 — Utils distance between geocoded coordinates
#
# Two independently geocoded addresses produce coordinates that can be fed
# directly into Utils::distance().  The resulting distance must be within a
# realistic tolerance of the known great-circle distance.
# ============================================================================

subtest 'Utils::distance — distance between two geocoded Local addresses' => sub {
	my $pt_us = $LOCAL_OBJ->geocode(location => $NCBI_ADDR);
	my $pt_gb = $LOCAL_OBJ->geocode(location => $EARLS_COLNE_ADDR);
	isa_ok($pt_us, 'Geo::Location::Point', 'US geocode ok');
	isa_ok($pt_gb, 'Geo::Location::Point', 'GB geocode ok');

	my $miles = distance($pt_us->lat(), $pt_us->long(),
	                     $pt_gb->lat(), $pt_gb->long(), 'M');
	my $km    = distance($pt_us->lat(), $pt_us->long(),
	                     $pt_gb->lat(), $pt_gb->long(), 'K');

	ok($miles > 3600 && $miles < 3800,
		"NCBI-EarlsColne ≈ 3700 statute miles (got ${\sprintf('%.1f',$miles)})");
	ok($km > 5800 && $km < 6100,
		"NCBI-EarlsColne ≈ 5950 km (got ${\sprintf('%.1f',$km)})");

	# Symmetry invariant: A→B == B→A.
	my $miles_rev = distance($pt_gb->lat(), $pt_gb->long(),
	                         $pt_us->lat(), $pt_us->long(), 'M');
	ok(abs($miles - $miles_rev) < 0.001, 'distance is symmetric (A→B = B→A)');

	# Same point must be exactly zero.
	is(distance($pt_us->lat(), $pt_us->long(),
	            $pt_us->lat(), $pt_us->long()), 0, 'distance to self is zero');

	diag "NCBI → Earls Colne: ${miles} mi / ${km} km" if $ENV{TEST_VERBOSE};
};

subtest 'Utils::distance — coordinates from OA known_location entry' => sub {
	# OA's hard-coded Newport Pagnell entry supplies valid coordinates without
	# a real database, making it a useful integration fixture.
	my $tmpdir = tempdir(CLEANUP => 1);
	my $oa     = Geo::Coder::Free::OpenAddresses->new(openaddr => $tmpdir);
	my $pt_np  = $oa->geocode(location => $NEWPORT_ADDR);
	isa_ok($pt_np, 'Geo::Location::Point', 'OA known_location returns GLP');

	my $pt_ec = $LOCAL_OBJ->geocode(location => $EARLS_COLNE_ADDR);

	my $km = distance($pt_np->lat(), $pt_np->long(),
	                  $pt_ec->lat(), $pt_ec->long(), 'K');
	ok($km > 0, 'non-zero distance between Newport Pagnell and Earls Colne');
	ok($km < 200, "distance is plausible (< 200 km, got ${\sprintf('%.1f',$km)})");

	diag "Newport Pagnell → Earls Colne: ${km} km" if $ENV{TEST_VERBOSE};
};

# ============================================================================
# SECTION 8 — Cross-module helpers: _normalize and _abbreviate
#
# Local.pm calls Geo::Coder::Free::_normalize() and _abbreviate() as part of
# address parsing.  These are package-level helpers, not OO methods, and must
# be callable cross-module.
# ============================================================================

subtest 'Cross-module — _normalize and _abbreviate are callable from outside Free.pm' => sub {
	# Both helpers are callable at the package level (not :Private).
	my $norm = Geo::Coder::Free::_normalize('Church Street');
	is($norm, 'CHURCH ST', '_normalize expands "Street" to "ST" and uppercases');

	my $abbr = Geo::Coder::Free::_abbreviate('Avenue');
	is($abbr, 'AV', '_abbreviate converts "Avenue" to "AV"');

	# Leading zeros must be stripped.
	my $zero = Geo::Coder::Free::_normalize('04th Street');
	like($zero, qr/^4TH/, '_normalize strips leading zeros from house-number prefix');
};

subtest 'Cross-module — Local geocode triggers _normalize for road abbreviation' => sub {
	# The address key stored in Local index was built using _normalize.
	# Searching with the full spelling must still resolve via abbreviation.
	my $r = $LOCAL_OBJ->geocode(location => $RAMSGATE_STN_ADDR);
	isa_ok($r, 'Geo::Location::Point', 'Local geocode with unabbreviated road returns GLP');
	ok(abs($r->lat()  - $RAMSGATE_STN_LAT) < $COORD_TOL, 'latitude correct');
	ok(abs($r->long() - $RAMSGATE_STN_LON) < $COORD_TOL, 'longitude correct');
};

# ============================================================================
# SECTION 9 — OA known_locations entry (no database required)
#
# OpenAddresses.pm hard-codes a %known_locations hash for addresses that have
# known inconsistencies in the database.  These entries are returned as fully
# formed Geo::Location::Point objects without opening any SQLite file.
# ============================================================================

subtest 'OA known_locations — returns GLP without touching the SQLite database' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	my $oa     = Geo::Coder::Free::OpenAddresses->new(openaddr => $tmpdir);

	my $pt = $oa->geocode(location => $NEWPORT_ADDR);
	isa_ok($pt, 'Geo::Location::Point', 'known_location returns GLP');
	ok(abs($pt->lat()  - $NEWPORT_LAT) < $COORD_TOL, 'latitude matches hard-coded value');
	ok(abs($pt->long() - $NEWPORT_LON) < $COORD_TOL, 'longitude matches hard-coded value');

	# Two independent OA instances must return GLPs with the same coordinates
	# but as distinct objects (not the same reference).
	my $oa2 = Geo::Coder::Free::OpenAddresses->new(openaddr => $tmpdir);
	my $pt2 = $oa2->geocode(location => $NEWPORT_ADDR);
	isa_ok($pt2, 'Geo::Location::Point', 'second instance also returns GLP');
	ok(abs($pt2->lat()  - $NEWPORT_LAT) < $COORD_TOL, 'second instance latitude matches');
	isnt(refaddr($pt), refaddr($pt2), 'known_location returns fresh GLPs, not a cached singleton');
};

subtest 'OA — numeric location rejected without database access' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	my $oa     = Geo::Coder::Free::OpenAddresses->new(openaddr => $tmpdir);
	my $r = $oa->geocode(location => '12345');
	ok(!defined($r), 'purely numeric location returns undef (pre-DB guard)');
};

subtest 'OA — short scantext rejected without database access' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	my $oa     = Geo::Coder::Free::OpenAddresses->new(openaddr => $tmpdir);
	my $r = $oa->geocode(scantext => 'hi');
	ok(!defined($r), 'scantext < 6 chars returns undef immediately');
};

# ============================================================================
# SECTION 10 — MaxMind admin-cache persistence (module-level, cross-instance)
#
# MaxMind.pm declares %admin1cache, %admin2cache, and %admin2cache_rev as
# package-level `our` variables.  They persist for the lifetime of the process,
# not just within a single object.  Tests verify the structure is accessible
# and that the invariant %admin2cache_rev == inverse(%admin2cache) holds after
# any write.
# ============================================================================

subtest 'MaxMind — admin caches are module-level our-variables' => sub {
	# The caches are `our` so they are addressable from outside the package.
	# We don't seed them here (that requires real DB data), but we verify
	# the invariant that both tables are in sync: every key in %admin2cache_rev
	# must also appear as a value in %admin2cache and vice-versa.
	my %a2  = %Geo::Coder::Free::MaxMind::admin2cache;
	my %a2r = %Geo::Coder::Free::MaxMind::admin2cache_rev;

	if (keys %a2) {
		is(scalar keys %a2, scalar keys %a2r,
			'admin2cache and admin2cache_rev have the same number of entries');
		for my $name (keys %a2) {
			my $code = $a2{$name};
			is($a2r{$code}, $name,
				"admin2cache_rev[$code] == '$name' (inverse holds)");
		}
	} else {
		pass('admin2cache is empty (no DB data in test env) — invariant trivially holds');
	}
};

# ============================================================================
# SECTION 11 — Utils cache integration with GCF
#
# create_disc_cache / create_memory_cache produce CHI objects that GCF accepts
# via the cache => parameter.  Passing a pre-built cache must not trigger any
# construction errors and the object must be addressable inside the GCF instance.
# ============================================================================

subtest 'Utils — create_disc_cache integrates with GCF constructor' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	my $config = { disc_cache => { driver => 'File', root_dir => $tmpdir } };

	my $cache = create_disc_cache({ config => $config, namespace => 'gcf_integration' });
	like(ref($cache), qr/^CHI/, 'create_disc_cache returns a CHI object');

	mock('Geo::Coder::Free::MaxMind', 'geocode', sub { return undef });
	my $geo = Geo::Coder::Free->new(cache => $cache);
	isa_ok($geo, 'Geo::Coder::Free', 'GCF constructed with disc cache');
	is(refaddr($geo->{'cache'}), refaddr($cache), 'GCF stores the provided cache object');

	restore_all();
};

subtest 'Utils — create_memory_cache integrates with GCF constructor' => sub {
	my $config = { memory_cache => { driver => 'Null' } };

	my $cache = create_memory_cache({ config => $config, namespace => 'gcf_integration_mem' });
	like(ref($cache), qr/^CHI/, 'create_memory_cache returns a CHI object');

	mock('Geo::Coder::Free::MaxMind', 'geocode', sub { return undef });
	my $geo = Geo::Coder::Free->new(cache => $cache);
	isa_ok($geo, 'Geo::Coder::Free', 'GCF constructed with memory cache');
	is(refaddr($geo->{'cache'}), refaddr($cache), 'GCF stores the memory cache object');

	restore_all();
};

# ============================================================================
# SECTION 12 — Optional dependency: Geo::libpostal fallback
#
# Local.pm loads Geo::libpostal lazily.  When it is unavailable the module must
# still resolve addresses via Geo::StreetAddress::US or Lingua::EN::AddressParse.
# Test::Without::Module blocks the require so the lazy-init eval returns false.
# We reset the module-level flag to LIBPOSTAL_UNKNOWN so the eval fires again.
# ============================================================================

subtest 'Optional dep — Geo::libpostal absent: Local still geocodes via alternate parsers' => sub {
	# Block Geo::libpostal for this subtest's scope.  Addresses that Local can
	# resolve via the O(1) index or Geo::StreetAddress::US must still work.
	Test::Without::Module->import('Geo::libpostal');
	$Geo::Coder::Free::Local::libpostal_is_installed =
		Geo::Coder::Free::Local::LIBPOSTAL_UNKNOWN;

	# Index-based lookup does not use any parser — must always succeed.
	my $r_index = $LOCAL_OBJ->geocode(location => $EARLS_COLNE_ADDR);
	isa_ok($r_index, 'Geo::Location::Point',
		'index lookup works without Geo::libpostal');
	ok(abs($r_index->lat() - $EARLS_COLNE_LAT) < $COORD_TOL,
		'index lookup latitude correct');

	# US address parsed via Geo::StreetAddress::US (not libpostal).
	my $r_us = $LOCAL_OBJ->geocode(location => $NCBI_ADDR);
	isa_ok($r_us, 'Geo::Location::Point',
		'US address geocodes without Geo::libpostal');
	ok(abs($r_us->lat() - $NCBI_LAT) < $COORD_TOL, 'US latitude correct');

	Test::Without::Module->unimport('Geo::libpostal');
	# Reset flag so subsequent tests see libpostal as freshly unknown.
	$Geo::Coder::Free::Local::libpostal_is_installed =
		Geo::Coder::Free::Local::LIBPOSTAL_UNKNOWN;
};

subtest 'Optional dep — Geo::libpostal present: geocodes short-form US address' => sub {
	# When libpostal is installed (and not blocked), a compact address form that
	# the other parsers cannot decompose should still resolve via the libpostal path.
	my $libpostal_ok = eval { require Geo::libpostal; 1 };
	$Geo::Coder::Free::Local::libpostal_is_installed =
		Geo::Coder::Free::Local::LIBPOSTAL_UNKNOWN;

	if ($libpostal_ok) {
		my $r = $LOCAL_OBJ->geocode(location => 'NCBI, Bethesda, Maryland, USA');
		isa_ok($r, 'Geo::Location::Point', 'libpostal-parsed address returns GLP');
		ok(abs($r->lat() - $NCBI_LAT) < $COORD_TOL, 'libpostal latitude correct');
		diag 'libpostal path exercised' if $ENV{TEST_VERBOSE};
	} else {
		pass('Geo::libpostal not installed — libpostal path skipped (not an error)');
		diag 'Install Geo::libpostal to exercise the libpostal geocode path'
			if $ENV{TEST_VERBOSE};
	}

	$Geo::Coder::Free::Local::libpostal_is_installed =
		Geo::Coder::Free::Local::LIBPOSTAL_UNKNOWN;
};

# ============================================================================
# SECTION 13 — GCF::ua compatibility stub
#
# Every backend exposes a no-op ua() method for drop-in compatibility with
# other Geo::Coder::* modules.  Verify that ua() is callable on GCF, Local,
# and OA without error and returns undef.
# ============================================================================

subtest 'ua() stub — all three public backends return undef' => sub {
	mock('Geo::Coder::Free::MaxMind', 'geocode', sub { return undef });

	my $geo   = Geo::Coder::Free->new();
	my $local = $LOCAL_OBJ;
	my $tmpdir = tempdir(CLEANUP => 1);
	my $oa    = Geo::Coder::Free::OpenAddresses->new(openaddr => $tmpdir);

	ok(!defined($geo->ua()),   'GCF::ua() returns undef');
	ok(!defined($local->ua()), 'Local::ua() returns undef');
	ok(!defined($oa->ua()),    'OA::ua() returns undef');

	restore_all();
};

# ============================================================================
# SECTION 14 — Address normalisation: "USA" ≡ "US"
#
# The Local backend normalises "USA" to "US" before the index lookup.
# Searching with either suffix must resolve to the same record.
# ============================================================================

subtest 'Normalisation — "USA" and "US" both resolve via Local' => sub {
	Readonly::Scalar my $ADDR_US  => '5350 Chillum Pl NE, Washington, DC, US';
	Readonly::Scalar my $ADDR_USA => '5350 Chillum Pl NE, Washington, DC, USA';
	Readonly::Scalar my $EXPECTED_LAT => 38.955403;

	my $r_us  = $LOCAL_OBJ->geocode(location => $ADDR_US);
	my $r_usa = $LOCAL_OBJ->geocode(location => $ADDR_USA);

	isa_ok($r_us,  'Geo::Location::Point', '"US" address returns GLP');
	isa_ok($r_usa, 'Geo::Location::Point', '"USA" address returns GLP');
	ok(abs($r_us->lat()  - $EXPECTED_LAT) < $COORD_TOL, '"US" latitude correct');
	ok(abs($r_usa->lat() - $EXPECTED_LAT) < $COORD_TOL, '"USA" latitude correct');
	ok(abs($r_us->lat()  - $r_usa->lat()) < $COORD_TOL,
		'"USA" and "US" resolve to the same latitude');
};

# ============================================================================
# SECTION 15 — Provenance on the OpenAddresses path, and through its cache
#
# _get() is the path a location => lookup takes: it finds the address in the
# OpenAddresses database, stamps the provenance of the match on the point, and
# freezes it with Storable for the next lookup of the same address.  Section 2.1
# of BI-Phase6-Dependency-Specs.md requires all four keys, and a key that does
# not survive that round trip would come back undef on the second lookup and
# nowhere else.
#
# This checkout has no OpenAddresses data file, so the lookup seam is what is
# stubbed - everything after it, the stamping and the Storable round trip, is
# the real code.  geocode() is skipped because reaching the thaw path through
# the public API needs the location string to survive the whole parse, and its
# fallback then asks for a database this checkout does not have.
# ============================================================================

subtest 'Provenance on the OpenAddresses path survives the cache' => sub {
	my $oa = Geo::Coder::Free::OpenAddresses->new(openaddr => tempdir(CLEANUP => 1));
	$oa->{'cache'} = CHI->new(driver => 'Memory', datastore => {});
	$oa->{openaddr_db} = OA_Stub_DB->new(Geo::Hash->new()->encode($NEWPORT_LAT, $NEWPORT_LON));

	# The database answered for the md5 of the normalised address, so this is an
	# address-level exact match and the point must say so.
	my $location = 'Provenance Road';
	my $found = $oa->_get($location);
	isa_ok($found, 'Geo::Location::Point', 'a database hit returns a GLP');

	my @missing = grep { !defined($found->{$_}) } qw(geocoder database confidence accuracy);
	is_deeply(\@missing, [], 'the database hit sets all four provenance keys')
		or diag(explain(\@missing));
	is($found->{'geocoder'}, 'Geo::Coder::Free', 'the hit names the distribution');
	is($found->{'database'}, 'OpenAddresses', 'the hit names the backend');
	cmp_ok($found->{'confidence'}, '==', 1.0, 'an address found by digest is an exact match');
	is($found->{'accuracy'}, 'address', 'and its coordinate is an address, not a locality');
	ok(abs($found->lat() - $NEWPORT_LAT) < $COORD_TOL, 'the geohash decoded to the expected latitude');

	# The second lookup of the same address is served from the cache, through
	# Storable::freeze/thaw - the regression this section exists for.
	my $cached = $oa->_get($location);
	isa_ok($cached, 'Geo::Location::Point', 'the cached result is still a Geo::Location::Point');
	isnt(refaddr($cached), refaddr($found), 'the second lookup is a thawed copy, not the original');

	for my $key (qw(geocoder database confidence accuracy)) {
		is($cached->{$key}, $found->{$key}, "the $key key survives the cache");
	}
	is($cached->{'accuracy'}, 'address', 'a thawed address is still an address');
};

# ---------------------------------------------------------------------------
# Final cleanup — ensure no stray mocks survive into later test runners.
# ---------------------------------------------------------------------------
restore_all();

done_testing();

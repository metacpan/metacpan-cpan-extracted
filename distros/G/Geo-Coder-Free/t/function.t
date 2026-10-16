#!/usr/bin/env perl
# t/function.t — White-box function tests for all .pm files in lib/.
#
# Strategy: each subtest exercises one helper in isolation.  Pure functions
# are called directly via package-qualified names.  Helpers with external
# dependencies (openaddr backend, CHI) use Test::Mockingbird or inline stub
# classes so the tests run without OPENADDR_HOME or a real database.
#
# Libraries:
#   Test::Most         — core assertion toolkit (is, like, ok, throws_ok, …)
#   Test::Mockingbird  — mock/spy for dependency-injected helpers
#   Test::Returns      — schema validation of return values
#   Test::Memory::Cycle — circular-reference detection on constructed objects

use strict;
use warnings;

use Test::Most;
use Test::Memory::Cycle;
use Test::Returns;
use Test::Mockingbird qw(mock spy restore_all intercept_new);
use Readonly;
use Scalar::Util qw(refaddr);

use lib 'lib';

# -----------------------------------------------------------------------
# Module loading — bail out early so later subtests don't get garbled errors
# -----------------------------------------------------------------------
BEGIN {
	use_ok('Geo::Coder::Free')            or BAIL_OUT('Geo::Coder::Free failed to load');
	use_ok('Geo::Coder::Free::Local')     or BAIL_OUT('Geo::Coder::Free::Local failed to load');
	use_ok('Geo::Coder::Free::Utils')     or BAIL_OUT('Geo::Coder::Free::Utils failed to load');
	use_ok('Geo::Coder::Free::Validate')  or BAIL_OUT('Geo::Coder::Free::Validate failed to load');
	use_ok('Geo::Coder::Abbreviations');
	use_ok('Geo::Location::Point');
}

# -----------------------------------------------------------------------
# Named constants — never embed magic strings/numbers in assertions
# -----------------------------------------------------------------------
Readonly::Scalar my $PKG_FREE     => 'Geo::Coder::Free';
Readonly::Scalar my $PKG_LOCAL    => 'Geo::Coder::Free::Local';
Readonly::Scalar my $PKG_UTILS    => 'Geo::Coder::Free::Utils';
Readonly::Scalar my $PKG_VALIDATE => 'Geo::Coder::Free::Validate';

# Coordinates for NYC and LA used across Utils::distance tests
Readonly::Scalar my $NYC_LAT => 40.7128;
Readonly::Scalar my $NYC_LON => -74.0060;
Readonly::Scalar my $LA_LAT  => 34.0522;
Readonly::Scalar my $LA_LON  => -118.2437;

# Haversine result bounds for NYC→LA (Haversine is used, not spherical-cosines)
Readonly::Scalar my $NYC_LA_MILES_LO => 2400;
Readonly::Scalar my $NYC_LA_MILES_HI => 2500;
Readonly::Scalar my $NYC_LA_KM_LO    => 3860;
Readonly::Scalar my $NYC_LA_KM_HI    => 3960;
Readonly::Scalar my $NYC_LA_NM_LO    => 2080;
Readonly::Scalar my $NYC_LA_NM_HI    => 2200;

# Known abbreviations from Geo::Coder::Abbreviations — confirmed by inspection
Readonly::Scalar my $ROAD_ABBR   => 'RD';
Readonly::Scalar my $STREET_ABBR => 'ST';

# =====================================================================
# SECTION 1: Geo::Coder::Free — pure-function helpers
# =====================================================================

# _i18n wraps a private %_MESSAGES lookup.  Test it by verifying known-key
# output and the resilient fallback when a key is absent.
subtest '_i18n: message lookup and sprintf interpolation' => sub {
	# Known key with no sprintf args — raw template returned
	my $raw = Geo::Coder::Free::_i18n('reverse_unsupported');
	ok(defined $raw, '_i18n: defined result for known key');
	like($raw, qr/not yet supported/i, '_i18n: correct text for reverse_unsupported');
	returns_ok($raw, { type => 'scalar' }, '_i18n returns a scalar string');
	diag("raw message: $raw") if $ENV{TEST_VERBOSE};

	# Known key with one sprintf arg — %s placeholder consumed
	my $with_pkg = Geo::Coder::Free::_i18n('use_arrow_new', 'MyPkg');
	like($with_pkg, qr/MyPkg/, '_i18n: package name interpolated into message');
	unlike($with_pkg, qr/%s/,  '_i18n: no unconsumed %s placeholder in result');

	# Multiple sprintf args
	my $two_args = Geo::Coder::Free::_i18n('invalid_location', 'Pkg', 'bad_loc');
	like($two_args, qr/Pkg/,     '_i18n: first arg interpolated');
	like($two_args, qr/bad_loc/, '_i18n: second arg interpolated');

	# Unknown key — falls back to the key itself (resilient; never dies)
	my $miss = Geo::Coder::Free::_i18n('no_such_message_key_xyz');
	is($miss, 'no_such_message_key_xyz', '_i18n: unknown key echoed back as fallback');
};

# _normalize_args is tested more thoroughly (all 6 partitions) in logic-reducer.t.
# Here we add white-box checks on the exact returned structure.
subtest '_normalize_args (Free): structural return-value verification' => sub {
	# P1: hashref → all keys preserved
	my %hr = Geo::Coder::Free::_normalize_args('e', 'location',
		{ location => 'London', region => 'GB', exact => 1 });
	is($hr{location}, 'London', 'P1: location key preserved');
	is($hr{region},   'GB',     'P1: region key preserved');
	is($hr{exact},    1,        'P1: exact key preserved');

	# P4: bare string → wrapped under bare_key; no other keys
	my %bare = Geo::Coder::Free::_normalize_args('e', 'location', 'Ramsgate, Kent');
	is(scalar keys %bare,    1,                 'P4: exactly one key in result');
	is($bare{location},      'Ramsgate, Kent',  'P4: value bound to bare_key');

	# P5: no args → empty hash (not undef, not list with one undef)
	my %empty = Geo::Coder::Free::_normalize_args('e', 'location');
	is(scalar keys %empty, 0, 'P5: empty args → zero-key hash');

	# P6: odd-count > 1 → croak; check the croak message is the supplied error
	throws_ok { Geo::Coder::Free::_normalize_args('EXACT_ERR_MSG', 'location', 'a', 'b', 'c') }
		qr/EXACT_ERR_MSG/, 'P6: croak uses the caller-supplied error message verbatim';
};

# _find_word_ngrams slides a window of $n words over text.  Commas become
# spaces, numeric tokens and stopwords are removed before windowing.
subtest '_find_word_ngrams: window size, stopwords, numeric filter, comma strip' => sub {
	my %stop = map { $_ => 1 } qw(the a and in);

	# 4 clean words → 3 bigrams, 2 trigrams
	my @bi = Geo::Coder::Free::_find_word_ngrams('London Kent Surrey Sussex', 2, \%stop);
	is(scalar @bi, 3,                    'bigrams: correct count from 4 clean words');
	is($bi[0],     'London, Kent',       'bigram[0] value');
	is($bi[1],     'Kent, Surrey',       'bigram[1] value');
	is($bi[2],     'Surrey, Sussex',     'bigram[2] value');
	diag("bigrams: @bi") if $ENV{TEST_VERBOSE};

	my @tri = Geo::Coder::Free::_find_word_ngrams('London Kent Surrey Sussex', 3, \%stop);
	is(scalar @tri, 2,                         'trigrams: correct count');
	is($tri[0],     'London, Kent, Surrey',    'trigram[0] value');
	is($tri[1],     'Kent, Surrey, Sussex',    'trigram[1] value');

	# Stopwords removed before windowing — 'the' and 'in' suppressed
	my @filt = Geo::Coder::Free::_find_word_ngrams('London the City in Kent', 2, \%stop);
	is(scalar @filt, 2,               'stopword-filtered: 3 real words → 2 bigrams');
	is($filt[0], 'London, City',      'stopword-filtered bigram[0]');
	is($filt[1], 'City, Kent',        'stopword-filtered bigram[1]');

	# Numeric tokens removed — '1944' must not appear in any gram
	my @nonums = Geo::Coder::Free::_find_word_ngrams('Battle 1944 Hastings', 2, \%stop);
	is(scalar @nonums, 1,                  'numeric token removed → 1 bigram');
	is($nonums[0],     'Battle, Hastings', 'only non-numeric bigram produced');

	# Commas become spaces — "London,Kent,Surrey" treated as three words
	my @csv = Geo::Coder::Free::_find_word_ngrams('London,Kent,Surrey', 2, \%stop);
	is(scalar @csv, 2, 'comma-separated input split correctly into bigrams');

	# Single word → no grams possible
	my @one = Geo::Coder::Free::_find_word_ngrams('London', 2, \%stop);
	is(scalar @one, 0, 'single word produces no bigrams');

	# Entirely stopwords → nothing to window
	my @all_stop = Geo::Coder::Free::_find_word_ngrams('the and in a', 2, \%stop);
	is(scalar @all_stop, 0, 'all-stopword input → empty output');
};

# _normalize upcases, abbreviates the street-type word, removes leading zeros.
# Known abbreviations: ROAD→RD, STREET→ST (confirmed from Geo::Coder::Abbreviations).
subtest '_normalize: split-based abbreviation — structural cases' => sub {
	# 2-word input: last word abbreviated (ROAD → RD)
	my $two = Geo::Coder::Free::_normalize('MAIN ROAD');
	is($two, "MAIN $ROAD_ABBR", '2-word: last word abbreviated');

	# 3-word input where [-2] has no abbreviation → falls through to [-1]
	my $three = Geo::Coder::Free::_normalize('NORTH MAIN ROAD');
	is($three, "NORTH MAIN $ROAD_ABBR", '3-word: [-2] has no abbreviation → last word abbreviated');

	# Embedded street type in second-to-last when it IS abbreviatable
	# "NORTH ROAD NORTH" → [-2]='ROAD' which abbreviates to 'RD' → 'NORTH RD NORTH'
	my $embedded = Geo::Coder::Free::_normalize('NORTH ROAD NORTH');
	like($embedded, qr/NORTH $ROAD_ABBR NORTH/i, '3-word: [-2] abbreviated when it is a street type');

	# Cross guard: when [-2] is 'cross', skip it and abbreviate [-1] instead
	my $cross = Geo::Coder::Free::_normalize('SAINT CROSS ROAD');
	is($cross, "SAINT CROSS $ROAD_ABBR", 'cross guard: [-2]=cross skipped, last word abbreviated');

	# Leading zeros stripped
	my $zero = Geo::Coder::Free::_normalize('04TH STREET');
	like($zero, qr/^4TH\s+$STREET_ABBR/i, 'leading zero removed from result');

	# Single-word input: nothing to abbreviate — just uppercased
	my $one = Geo::Coder::Free::_normalize('street');
	is($one, 'STREET', '1-word: uppercased and returned as-is (no truncation)');

	# Already uppercase: idempotent
	my $already = Geo::Coder::Free::_normalize('MAIN RD');
	like($already, qr/MAIN/i, 'already-abbreviated input survives _normalize');

	returns_ok($two, { type => 'scalar' }, '_normalize returns a scalar');
};

# _abbreviate uppercases input before lookup and returns original if no abbreviation.
# Uses Test::Mockingbird to verify that Geo::Coder::Abbreviations::abbreviate is called.
subtest '_abbreviate: delegation and pass-through for unknown tokens' => sub {
	# Known type is abbreviated
	my $road = Geo::Coder::Free::_abbreviate('ROAD');
	is($road, $ROAD_ABBR, '_abbreviate: ROAD → RD');

	# Lowercase input is uppercased before lookup
	my $lower = Geo::Coder::Free::_abbreviate('road');
	is($lower, $ROAD_ABBR, '_abbreviate: lowercase road also → RD (case-insensitive)');

	# Unknown word: returns the uppercased original (not undef)
	my $xyzzy = Geo::Coder::Free::_abbreviate('xyzzy');
	is($xyzzy, 'XYZZY', '_abbreviate: unknown word returned uppercased unchanged');
	ok(defined $xyzzy, '_abbreviate: never returns undef');

	# Spy: verify _abbreviate actually delegates to Geo::Coder::Abbreviations::abbreviate
	my $spy = spy 'Geo::Coder::Abbreviations::abbreviate';
	Geo::Coder::Free::_abbreviate('STREET');
	my @calls = $spy->();
	ok(scalar @calls >= 1, 'spy: Abbreviations::abbreviate was called by _abbreviate');
	restore_all();
};

# _find_us_addresses extracts structured US addresses from free text.
# The regex requires: house-number, street-type, comma, city, comma, state-code.
subtest '_find_us_addresses: pattern extraction and non-match guard' => sub {
	# Full address with zip in surrounding prose
	my $text = 'Visit us at 1600 Pennsylvania Avenue NW, Washington, DC 20500 for more info.';
	my @found = Geo::Coder::Free::_find_us_addresses($text);
	ok(scalar @found >= 1, 'matched at least one US address from prose');
	like($found[0], qr/1600/, 'match contains house number');
	like($found[0], qr/Pennsylvania.*Avenue/, 'match contains street name and type');
	like($found[0], qr/DC/, 'match contains state abbreviation');
	diag("US match: $found[0]") if $ENV{TEST_VERBOSE};

	# Address without state abbreviation — must not match
	my @no_state = Geo::Coder::Free::_find_us_addresses('123 Main Street, Springfield');
	is(scalar @no_state, 0, 'address without state abbreviation is not matched');

	# Pure prose — must not match
	my @none = Geo::Coder::Free::_find_us_addresses('No address here, just text.');
	is(scalar @none, 0, 'plain prose returns empty list');

	# Short house number (1 digit) also valid
	my @short = Geo::Coder::Free::_find_us_addresses('1 Main Street, Boston, MA');
	ok(scalar @short >= 1, 'single-digit house number still matches');
};

# _find_gb_addresses uses mandatory commas to eliminate catastrophic backtracking.
# The key white-box test: comma-free text MUST produce zero matches.
subtest '_find_gb_addresses: mandatory-comma anchor eliminates backtracking' => sub {
	# Well-formed UK address with all three separating commas
	my $uk = '10 Downing Street, Westminster, London, England';
	my @found = Geo::Coder::Free::_find_gb_addresses($uk);
	ok(scalar @found >= 1, 'comma-separated UK address matched');
	diag("GB match: $found[0]") if $ENV{TEST_VERBOSE};

	# Comma-free text — verifies that the ReDoS fix is behaviourally effective
	my @no_commas = Geo::Coder::Free::_find_gb_addresses(
		'The quick brown fox jumps over the lazy dog'
	);
	is(scalar @no_commas, 0, 'comma-free text produces no matches (ReDoS guard active)');

	# Only spaces (no commas) between address parts — must not match the 4-part pattern
	my @spaces_only = Geo::Coder::Free::_find_gb_addresses(
		'10 Downing Street Westminster London England'
	);
	is(scalar @spaces_only, 0, 'space-only separators do not satisfy the comma requirement');

	# Missing one comma (only 2 of 3) — not enough to span all 4 parts
	my @two_commas = Geo::Coder::Free::_find_gb_addresses(
		'10 Downing Street, Westminster London England'
	);
	# May or may not match a 3-part subset — just confirm no 4-part match
	for my $m (@two_commas) {
		unlike($m, qr/England\s*$/, 'match without third comma does not include country part');
	}
};

# _find_ca_addresses uses the same bounded structure as US but with Canadian postal codes.
subtest '_find_ca_addresses: Canadian postal code pattern' => sub {
	# Full Canadian address with postal code
	my $ca = '123 Maple Drive, Ottawa, ON K1A 0A9';
	my @found = Geo::Coder::Free::_find_ca_addresses($ca);
	ok(scalar @found >= 1, 'matched valid Canadian address with postal code');
	like($found[0], qr/123.*Maple.*Drive/, 'match contains house number and street');
	like($found[0], qr/Ottawa/, 'match contains city');
	diag("CA match: $found[0]") if $ENV{TEST_VERBOSE};

	# Without postal code — optional, so should still match
	my @no_postal = Geo::Coder::Free::_find_ca_addresses('456 Oak Avenue, Toronto, ON');
	ok(scalar @no_postal >= 1, 'Canadian address without postal code still matches');

	# Plain prose — no match
	my @none = Geo::Coder::Free::_find_ca_addresses('Nothing to see here.');
	is(scalar @none, 0, 'plain prose returns empty list');
};

# _resolve_scan_candidates annotates geocoder hits with location/text/confidence
# and memoizes misses to avoid re-querying the same failing place string.
# Uses an inline stub class (FakeOA) to simulate the openaddr backend.
subtest '_resolve_scan_candidates: hit annotation and miss memoization' => sub {
	{
		# Stub that returns a hit for any string not containing 'NoSuchPlace'
		package	# hide from CPAN indexer
			FakeOA;
		sub geocode {
			my ($self, $loc) = @_;
			return () if $loc =~ /NoSuchPlace/;
			return Geo::Location::Point->new(lat => 51.3, long => 1.4);
		}
	}

	my $fake_oa = bless {}, 'FakeOA';
	my $geo = bless {
		openaddr        => $fake_oa,
		scantext_misses => {},
	}, 'Geo::Coder::Free';

	# -- HIT path: result is annotated with confidence/text/location metadata --
	my $res = $geo->_resolve_scan_candidates(['Ramsgate'], undef, 0.8, 'Test scantext');
	returns_ok($res, { type => 'arrayref' }, '_resolve_scan_candidates returns arrayref');
	ok(scalar @{$res} >= 1, 'hit: at least one result returned');
	is($res->[0]{'confidence'}, 0.8,           'hit: annotated with supplied confidence');
	is($res->[0]{'text'},       'Test scantext','hit: annotated with scantext arg');
	ok(defined $res->[0]{'location'},           'hit: location field set');
	diag("confidence=$res->[0]{confidence} text=$res->[0]{text}") if $ENV{TEST_VERBOSE};

	# -- MISS path: memoized in scantext_misses, returns empty arrayref --
	my $before = scalar keys %{$geo->{'scantext_misses'}};
	my $miss_res = $geo->_resolve_scan_candidates(['NoSuchPlace'], undef, 0.8, 't1');
	is(scalar @{$miss_res}, 0, 'miss: empty arrayref returned');
	my $after = scalar keys %{$geo->{'scantext_misses'}};
	is($after, $before + 1, 'miss: exactly one new entry added to scantext_misses');

	# -- RE-QUERY of memoized miss: skipped, misses count unchanged --
	my $miss_res2 = $geo->_resolve_scan_candidates(['NoSuchPlace'], undef, 0.8, 't2');
	is(scalar @{$miss_res2}, 0,
		're-query of memoized miss returns empty');
	is(scalar keys %{$geo->{'scantext_misses'}}, $after,
		're-query: misses count unchanged (geocode not called again)');

	# -- Region appended when supplied: memoized key includes the region --
	my $miss_region = $geo->_resolve_scan_candidates(['NoSuchPlace'], 'US', 0.7, 't3');
	my $key_with_region = 'NoSuchPlace, US';
	ok(exists $geo->{'scantext_misses'}{$key_with_region},
		'miss with region stored under "place, region" key');
};

# =====================================================================
# SECTION 2: Geo::Coder::Free::Local — helper functions
# =====================================================================

subtest 'Local::_normalize_args: latlng bare_key variant' => sub {
	# P4: bare string → bound to 'latlng' (not 'location')
	my %r4 = Geo::Coder::Free::Local::_normalize_args('e', 'latlng', '39.7,-77.1');
	is(scalar keys %r4, 1,           'P4 (Local): exactly one key');
	is($r4{'latlng'},   '39.7,-77.1','P4 (Local): bare string bound to latlng');
	ok(!exists $r4{'location'},      'P4 (Local): location key absent (bare_key=latlng)');

	# P1: hashref still works, multi-key preserved
	my %r1 = Geo::Coder::Free::Local::_normalize_args('e', 'latlng',
		{ latlng => '51.5,0.1', extra => 'val' });
	is($r1{'latlng'}, '51.5,0.1', 'P1 (Local): latlng key from hashref');
	is($r1{'extra'},  'val',      'P1 (Local): extra key preserved');

	# P6: odd > 1 croaks with the supplied message
	throws_ok { Geo::Coder::Free::Local::_normalize_args('LOCAL_ERR', 'latlng', 'a', 'b', 'c') }
		qr/LOCAL_ERR/, 'P6 (Local): odd-count > 1 croaks';
};

# _cache_and_return is a write-through helper: it stores the value in the cache
# and returns it transparently so callers can use "return $self->_cache_and_return(...)".
subtest 'Local::_cache_and_return: write-through transparency' => sub {
	my $obj = bless { cache => {} }, 'Geo::Coder::Free::Local';
	my $pt  = bless { lat => 51.3, longitude => 1.4 }, 'Geo::Location::Point';

	# Returned value is the exact object passed in (identity, not a copy).
	# Use refaddr to avoid triggering Geo::Location::Point's stringify overload,
	# which warns when optional fields (city, country) are uninitialized.
	my $ret = $obj->_cache_and_return('mykey', $pt);
	is(refaddr($ret), refaddr($pt), '_cache_and_return: same reference returned (not a copy)');

	# Cache is updated synchronously with the exact same reference
	is(refaddr($obj->{'cache'}{'mykey'}), refaddr($pt),
		'_cache_and_return: cache stores the exact same reference');

	# Storing undef is also supported (cache negative result to prevent re-lookup)
	my $undef_ret = $obj->_cache_and_return('missingkey', undef);
	ok(exists $obj->{'cache'}{'missingkey'}, '_cache_and_return: undef stored (negative cache)');
	ok(!defined $undef_ret, '_cache_and_return: undef returned transparently');
};

# _to_two_letter_state resolves full state/province names to two-letter codes.
# Short-circuit: already-2-letter inputs returned unchanged, regardless of country.
subtest 'Local::_to_two_letter_state: US, CA, passthrough, short-circuit' => sub {
	# Already 2 characters — short-circuit, no Locale:: lookup
	is(Geo::Coder::Free::Local::_to_two_letter_state('US', 'CA'),
		'CA', 'short-circuit: 2-char input returned unchanged');

	# US full state name → 2-letter code
	my $us = Geo::Coder::Free::Local::_to_two_letter_state('United States', 'California');
	is($us, 'CA', 'US: California → CA');
	my $us2 = Geo::Coder::Free::Local::_to_two_letter_state('USA', 'New York');
	is($us2, 'NY', 'US (alias USA): New York → NY');
	diag("US state: $us") if $ENV{TEST_VERBOSE};

	# Canadian province → 2-letter code
	my $ca = Geo::Coder::Free::Local::_to_two_letter_state('Canada', 'Ontario');
	is($ca, 'ON', 'CA: Ontario → ON');
	my $ca2 = Geo::Coder::Free::Local::_to_two_letter_state('Canada', 'British Columbia');
	is($ca2, 'BC', 'CA: British Columbia → BC');

	# Non-US/CA country — state returned as-is
	my $au = Geo::Coder::Free::Local::_to_two_letter_state('Australia', 'Queensland');
	is($au, 'Queensland', 'non-US/CA country: state returned unchanged');

	# Undef state: early-return guard emits empty string (not undef)
	my $undef_st = Geo::Coder::Free::Local::_to_two_letter_state('US', undef);
	is($undef_st, '', 'undef state → empty string (no fatal undef propagation)');
};

# _equal compares two floats at a given number of significant figures using
# sprintf %.Ng format.  This avoids IEEE754 floating-point equality traps.
subtest 'Local::_equal: significant-figure comparison' => sub {
	# Identical values — always equal at any precision
	ok(Geo::Coder::Free::Local::_equal(51.3341, 51.3341, 4),
		'identical values: equal at 4 sig-figs');

	# Values differing only at 5th significant figure → equal at 4 sig-figs
	# %.4g of both 51.33409 and 51.33411 → '51.33' (4 sig figs, trailing zero removed)
	ok(Geo::Coder::Free::Local::_equal(51.33409, 51.33411, 4),
		'values differing at 5th sig-fig: equal at 4 sig-figs');

	# Values differing at 4th significant figure → NOT equal at 4 sig-figs
	# %.4g of 51.334 → '51.33'; %.4g of 51.344 → '51.34'
	ok(!Geo::Coder::Free::Local::_equal(51.334, 51.344, 4),
		'values differing at 4th sig-fig: not equal at 4 sig-figs');

	# Demonstrate precision boundary: 1.23456 vs 1.23457
	# %.4g of both → '1.235' (equal at 4 sig-figs)
	ok(Geo::Coder::Free::Local::_equal(1.23456, 1.23457, 4),
		'1.23456 vs 1.23457: equal at 4 sig-figs');
	# %.6g → '1.23456' vs '1.23457' (differ at 6th significant figure)
	ok(!Geo::Coder::Free::Local::_equal(1.23456, 1.23457, 6),
		'1.23456 vs 1.23457: not equal at 6 sig-figs');

	# Negative coordinates: close values equal at 4 sig-figs
	# %.4g of -77.0 and -77.001 both → '-77' (4 sig figs of 77.0 and 77.001 → '77')
	ok(Geo::Coder::Free::Local::_equal(-77.0, -77.001, 4),
		'negative: close values equal at 4 sig-figs');

	# Negative coordinates: values differing at 4th sig-fig → not equal
	# %.4g of -77.01 → '-77.01'; %.4g of -77.02 → '-77.02'
	ok(!Geo::Coder::Free::Local::_equal(-77.01, -77.02, 4),
		'negative: values differing at 4th sig-fig: not equal');
};

# _calculate_centre computes the arithmetic mean of lat/lon for a location group.
# Results are formatted to 6 decimal places as strings.
subtest 'Local::_calculate_centre: arithmetic mean to 6dp' => sub {
	my $locs = [
		{ latitude => 0.0, longitude => 0.0 },
		{ latitude => 2.0, longitude => 4.0 },
		{ latitude => 4.0, longitude => 8.0 },
	];
	my ($lat, $lon) = Geo::Coder::Free::Local::_calculate_centre($locs);
	# Mean lat = (0+2+4)/3 = 2.0 → '2.000000'
	# Mean lon = (0+4+8)/3 = 4.0 → '4.000000'
	is($lat, '2.000000', '_calculate_centre: mean latitude to 6dp');
	is($lon, '4.000000', '_calculate_centre: mean longitude to 6dp');
	diag("centre: $lat, $lon") if $ENV{TEST_VERBOSE};

	# Single-point: centre equals the point
	my ($slat, $slon) = Geo::Coder::Free::Local::_calculate_centre([
		{ latitude => 51.3, longitude => 1.4 }
	]);
	is($slat, '51.300000', 'single-point cluster: latitude preserved to 6dp');
	is($slon, '1.400000',  'single-point cluster: longitude preserved to 6dp');

	# Negative coordinates
	my ($nlat, $nlon) = Geo::Coder::Free::Local::_calculate_centre([
		{ latitude => -10.0, longitude => -20.0 },
		{ latitude => -20.0, longitude => -40.0 },
	]);
	is($nlat, '-15.000000', 'negative latitudes: mean correct');
	is($nlon, '-30.000000', 'negative longitudes: mean correct');
};

# _find_geographic_centres groups rows by city|state|country key and emits
# centroids only for clusters of 3 or more points (too sparse otherwise).
subtest 'Local::_find_geographic_centres: cluster threshold and output structure' => sub {
	# 2-point cluster — below threshold → undef returned
	my $sparse = [
		{ city => 'TC', state => 'TS', country => 'GB', latitude => 51.3, longitude => 1.4 },
		{ city => 'TC', state => 'TS', country => 'GB', latitude => 51.4, longitude => 1.5 },
	];
	my $r = Geo::Coder::Free::Local::_find_geographic_centres($sparse);
	ok(!defined $r, '2-point cluster: undef returned (below threshold)');

	# Exactly 3 points — threshold met → one centre
	my $cluster = [
		{ city => 'TestCity', state => 'TX', country => 'GB', latitude => 51.3, longitude => 1.4 },
		{ city => 'TestCity', state => 'TX', country => 'GB', latitude => 51.4, longitude => 1.5 },
		{ city => 'TestCity', state => 'TX', country => 'GB', latitude => 51.5, longitude => 1.6 },
	];
	my $centres = Geo::Coder::Free::Local::_find_geographic_centres($cluster);
	ok(defined $centres,                    '3-point cluster: defined result');
	returns_ok($centres, { type => 'arrayref' }, 'result is arrayref');
	is(scalar @{$centres}, 1,              '3-point cluster: one centre generated');
	is($centres->[0]{'city'},    'TestCity','centre: city label correct');
	is($centres->[0]{'state'},   'TX',      'centre: state label correct');
	is($centres->[0]{'country'}, 'GB',      'centre: country label correct');
	# mean lat = (51.3+51.4+51.5)/3 = 51.4
	like($centres->[0]{'lat'}, qr/^51\.4/, 'centre: lat is arithmetic mean of inputs');
	ok(exists $centres->[0]{'latitude'},   'centre: latitude alias present');
	ok(exists $centres->[0]{'longitude'},  'centre: longitude alias present');
	ok(exists $centres->[0]{'long'},       'centre: long alias present');
	ok(exists $centres->[0]{'lng'},        'centre: lng alias present');
	diag("centre lat=$centres->[0]{lat}") if $ENV{TEST_VERBOSE};

	# Rows with non-numeric coordinates must be skipped
	my $invalid = [
		{ city => 'X', state => 'Y', country => 'Z', latitude => 'bad', longitude => 1.0 },
		{ city => 'X', state => 'Y', country => 'Z', latitude => 51.0,  longitude => 1.0 },
		{ city => 'X', state => 'Y', country => 'Z', latitude => 51.1,  longitude => 1.1 },
	];
	# 'bad' latitude fails the /^-?\d+\.?\d*$/ guard → only 2 valid rows → undef
	my $inv = Geo::Coder::Free::Local::_find_geographic_centres($invalid);
	ok(!defined $inv, 'invalid-coord row skipped; 2 valid rows → under threshold → undef');

	# Two distinct clusters in one input — both centres generated
	my $two_clusters = [
		{ city => 'A', state => 'S', country => 'G', latitude => 10.0, longitude => 10.0 },
		{ city => 'A', state => 'S', country => 'G', latitude => 10.2, longitude => 10.2 },
		{ city => 'A', state => 'S', country => 'G', latitude => 10.4, longitude => 10.4 },
		{ city => 'B', state => 'S', country => 'G', latitude => 20.0, longitude => 20.0 },
		{ city => 'B', state => 'S', country => 'G', latitude => 20.2, longitude => 20.2 },
		{ city => 'B', state => 'S', country => 'G', latitude => 20.4, longitude => 20.4 },
	];
	my $two = Geo::Coder::Free::Local::_find_geographic_centres($two_clusters);
	ok(defined $two, 'two qualifying clusters: defined result');
	is(scalar @{$two}, 2, 'two distinct clusters → two centres');
};

# _search iterates data rows and requires >= 3 column matches.
# Confidence is EXACT (1.0) when all columns match, HIGH (0.7) for 4+, MEDIUM (0.5) for 3.
subtest 'Local::_search: minimum threshold and confidence assignment' => sub {
	my $row = {
		city      => 'Ramsgate',
		state     => 'Kent',
		country   => 'GB',
		latitude  => 51.336,
		longitude => 1.416,
	};
	my $local = bless { data => [$row] }, 'Geo::Coder::Free::Local';

	# All 3 requested columns match → CONF_EXACT
	my $match = $local->_search({ city => 'Ramsgate', state => 'Kent', country => 'GB' },
		qw(city state country));
	ok(defined $match,              '3-column exact match returns defined result');
	isa_ok($match, 'Geo::Location::Point', 'result is a Geo::Location::Point object');
	is($match->{'confidence'}, 1.0,  'all-column match: CONF_EXACT = 1.0');
	diag("confidence=$match->{confidence}") if $ENV{TEST_VERBOSE};

	# Case-insensitive: lowercase input matches uppercase data row
	my $ci = $local->_search({ city => 'ramsgate', state => 'kent', country => 'gb' },
		qw(city state country));
	ok(defined $ci, '_search is case-insensitive');

	# Below the minimum 3-column threshold → undef
	my $too_few = $local->_search({ city => 'Ramsgate', state => 'Kent' },
		qw(city state));
	ok(!defined $too_few, 'only 2 matching columns returns undef (< threshold of 3)');

	# Mismatched value → no match
	my $bad = $local->_search({ city => 'NoSuchCity', state => 'Kent', country => 'GB' },
		qw(city state country));
	ok(!defined $bad, 'mismatched city returns undef');

	# Undef column in $data: the column is skipped (deleted from $data) rather than
	# treated as a mismatch, so the match can still succeed on the remaining columns.
	my $data_with_undef = { city => 'Ramsgate', state => 'Kent', country => 'GB', number => undef };
	my $partial = $local->_search($data_with_undef, qw(number city state country));
	# number is undef in $data but exists as key → deleted; 3 remaining columns match
	ok(defined $partial, 'undef column skipped; 3 remaining columns → match');
};

# =====================================================================
# SECTION 3: Geo::Coder::Free::Local — constructor and object lifecycle
# =====================================================================

subtest 'Local::new: data load, index, region_index, memory safety' => sub {
	my $local = new_ok('Geo::Coder::Free::Local');
	ok(defined $local, 'new() returns defined object');
	isa_ok($local, 'Geo::Coder::Free::Local', 'correctly blessed');

	# Data loaded from __DATA__ CSV block
	ok(ref($local->{'data'}) eq 'ARRAY',     'data attribute is an arrayref');
	ok(scalar @{$local->{'data'}} > 0,       'at least one data row loaded');

	# Index built from stringified GLP key
	ok(ref($local->{'index'}) eq 'HASH',     'index attribute is a hashref');
	ok(scalar keys %{$local->{'index'}} > 0, 'index has at least one entry');

	# Data rows are blessed as Geo::Location::Point (side-effect of index build)
	my $first_row = $local->{'data'}[0];
	isa_ok($first_row, 'Geo::Location::Point', 'data rows are Geo::Location::Point objects');

	diag('data rows: ' . scalar @{$local->{'data'}}) if $ENV{TEST_VERBOSE};

	# Clone constructor: calling new() on an existing instance returns a clone
	my $clone = $local->new();
	isa_ok($clone, 'Geo::Coder::Free::Local', 'clone is correctly blessed');
	isnt($clone, $local, 'clone is a different reference (not same object)');

	# Memory safety — no circular references that would defeat refcount GC
	memory_cycle_ok($local, 'Geo::Coder::Free::Local: no circular references');
};

# =====================================================================
# SECTION 4: Geo::Coder::Free::Utils — distance and cache construction
# =====================================================================

subtest 'Utils::distance: Haversine formula, units, input validation' => sub {
	use Geo::Coder::Free::Utils qw(distance);

	# Identical points → 0 (short-circuit before formula)
	is(distance(51.3, 1.4, 51.3, 1.4), 0, 'identical points: distance = 0');

	# NYC → LA in statute miles (default unit 'M')
	my $miles = distance($NYC_LAT, $NYC_LON, $LA_LAT, $LA_LON, 'M');
	cmp_ok($miles, '>', $NYC_LA_MILES_LO, "NYC→LA miles: > $NYC_LA_MILES_LO");
	cmp_ok($miles, '<', $NYC_LA_MILES_HI, "NYC→LA miles: < $NYC_LA_MILES_HI");
	diag("NYC→LA miles: $miles") if $ENV{TEST_VERBOSE};

	# NYC → LA in kilometres
	my $km = distance($NYC_LAT, $NYC_LON, $LA_LAT, $LA_LON, 'K');
	cmp_ok($km, '>', $NYC_LA_KM_LO, "NYC→LA km: > $NYC_LA_KM_LO");
	cmp_ok($km, '<', $NYC_LA_KM_HI, "NYC→LA km: < $NYC_LA_KM_HI");

	# NYC → LA in nautical miles
	my $nm = distance($NYC_LAT, $NYC_LON, $LA_LAT, $LA_LON, 'N');
	cmp_ok($nm, '>', $NYC_LA_NM_LO, "NYC→LA NM: > $NYC_LA_NM_LO");
	cmp_ok($nm, '<', $NYC_LA_NM_HI, "NYC→LA NM: < $NYC_LA_NM_HI");

	# KM should be greater than statute miles (1 km < 1 mile)
	cmp_ok($km, '>', $miles, 'km distance > miles distance (unit sanity check)');

	# Commutativity: d(A,B) == d(B,A)
	my $rev = distance($LA_LAT, $LA_LON, $NYC_LAT, $NYC_LON, 'M');
	ok(abs($rev - $miles) < 0.001, 'distance is commutative: d(A,B) ≈ d(B,A)');

	# -- Input validation: croak on invalid inputs --

	# Undefined coordinate
	throws_ok { distance(undef, 0, 0, 0) }
		qr/lat1 must be defined/, 'croak: undef lat1';
	throws_ok { distance(0, undef, 0, 0) }
		qr/lon1 must be defined/, 'croak: undef lon1';

	# Non-numeric coordinate
	throws_ok { distance('abc', 0, 0, 0) }
		qr/lat1 must be numeric/, 'croak: non-numeric lat1';

	# Latitude out of range
	throws_ok { distance(91, 0, 0, 0) }
		qr/Latitude must be between/, 'croak: lat1 > 90';
	throws_ok { distance(-91, 0, 0, 0) }
		qr/Latitude must be between/, 'croak: lat1 < -90';

	# Longitude out of range
	throws_ok { distance(0, 181, 0, 0) }
		qr/Longitude must be between/, 'croak: lon1 > 180';
	throws_ok { distance(0, 0, 0, -181) }
		qr/Longitude must be between/, 'croak: lon2 < -180';

	# Unknown unit string
	throws_ok { distance(0, 0, 1, 1, 'X') }
		qr/Unknown unit/, "croak: unit 'X' not in K/N/M";

	returns_ok($miles, { type => 'scalar' }, 'distance returns a scalar');
};

subtest 'Utils::create_memory_cache: returns a usable CHI object' => sub {
	use Geo::Coder::Free::Utils qw(create_memory_cache);

	my $cfg = { memory_cache => { driver => 'Null' } };
	my $cache = create_memory_cache({ config => $cfg });
	ok(defined $cache, 'create_memory_cache returns defined object');
	like(ref($cache), qr/CHI/, 'returned object is a CHI instance');
	returns_ok($cache, { type => 'object' }, 'cache is an object');

	# Missing config → croak
	throws_ok { create_memory_cache({ config => {} }) }
		qr//, 'croak on empty config (no driver or root_dir)';

	diag('cache class: ' . ref($cache)) if $ENV{TEST_VERBOSE};
};

# =====================================================================
# SECTION 5: Geo::Coder::Free::Validate — the one definition of the rule
# =====================================================================

# The rule the facade applies before it queries a backend, and the backends apply
# to what a caller hands them directly.  Its equivalence classes are: a string of
# digits only (the numeric column read by mistake) and undef/''/a reference, all
# false; and anything holding a non-digit character, true.  The last two cases
# matter as much as the first: '3.14' and '-' are not addresses, but they are not
# a numeric column either, and the guard has never rejected them.
subtest "$PKG_VALIDATE\::_valid_location: the rule, by equivalence class" => sub {
	use Geo::Coder::Free::Validate qw(_valid_location);

	# The candidates are held as strings so that a case cannot be confused with
	# the assertion it feeds: '0' and 0 are different questions.
	my @not_locations = (
		[undef,  'undef'],
		['',     'the empty string'],
		['0044', 'a zero-padded number'],
		['12345', 'a bare number'],
		['0',    'the number zero'],
		[\42,    'a reference'],
	);
	for my $case (@not_locations) {
		my ($value, $what) = @$case;
		# Exactly 0, not merely false: the callers put this straight into an
		# if(), but the value is also the documented answer.
		is(_valid_location($value), 0, "$what is not a location");
	}

	my @locations = (
		['Ramsgate, Kent', 'an address'],
		['London',         'a single word'],
		['3.14',           'a decimal - it has a non-digit in it'],
		['-',              'a lone punctuation character'],
		['0044 ',          'a number with a trailing space'],
		[' a',             'text with leading whitespace'],
		[12345.5,          'a number in a scalar (not a string of digits only)'],
	);
	for my $case (@locations) {
		my ($value, $what) = @$case;
		is(_valid_location($value), 1, "$what is a location");
	}

	# The facade imports this sub rather than owning a copy of it, which is what
	# keeps the public predicate and the backends on one answer (t/edge_cases.t
	# checks all three call sites).  refaddr() is the identity of the code
	# reference itself; two copies of the same body would not match.
	is(refaddr($PKG_FREE->can('_valid_location')), refaddr(\&_valid_location),
		'the facade holds the rule itself, not a copy of its body');
};

done_testing();

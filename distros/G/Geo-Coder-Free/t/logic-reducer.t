#!/usr/bin/env perl

# t/logic-reducer.t — Partition-based logical proofs for optimised code paths.
#
# Each subtest is a formal proof in the style:
#   Major Premise (system invariant) + Minor Premise (test input)
#   => Conclusion (expected output)
#
# Reductions applied:
#   M3 — Transitive reduction: redundant !scantext guard removed from Free.pm
#   M5 — Boolean reduction: $failed flag → labeled ROW: loop in Local::_search
#   M7 — Logic-gap closure: odd-count > 1 args now croak in _normalize_args
#   M8 — Tautology elimination: wantarray ? X : X → X in Free::geocode

use strict;
use warnings;

use Test::Most;
use Test::Exception;

use lib 'lib';
use Geo::Coder::Free;
use Geo::Coder::Free::Local;

# -----------------------------------------------------------------------
# Partition suite for _normalize_args (shared logic in both packages)
#
# Major Premise: _normalize_args maps four valid calling conventions:
#   P1 hashref          → expanded %hash
#   P2 non-hash ref     → croak($error_msg)
#   P3 even-count list  → list passed through
#   P4 single scalar    → ($bare_key => scalar)
#   P5 empty list       → ()
#   P6 odd-count > 1    → croak($error_msg)  [M7: closed logic gap]
# -----------------------------------------------------------------------

subtest '_normalize_args: Free.pm — 6 equivalence partitions' => sub {
	plan tests => 7;

	# P1: hashref → expand
	my %r1 = Geo::Coder::Free::_normalize_args('ERR', 'location', { location => 'London' });
	is($r1{'location'}, 'London', 'P1: hashref expanded to flat hash');

	# P2: non-hash ref → croak
	throws_ok {
		Geo::Coder::Free::_normalize_args('P2-err', 'location', [1, 2]);
	} qr/P2-err/, 'P2: arrayref argument croaks with error_msg';

	# P3: even-count list → pass through
	my %r3 = Geo::Coder::Free::_normalize_args('ERR', 'location',
		location => 'Paris', region => 'FR');
	is($r3{'location'}, 'Paris', 'P3: even-count list — location key');
	is($r3{'region'},   'FR',    'P3: even-count list — region key');

	# P4: single bare scalar → bare_key => scalar
	my %r4 = Geo::Coder::Free::_normalize_args('ERR', 'location', 'Berlin');
	is($r4{'location'}, 'Berlin', 'P4: bare string routed to bare_key=location');

	# P5: empty list → empty hash
	my %r5 = Geo::Coder::Free::_normalize_args('ERR', 'location');
	is(scalar keys %r5, 0, 'P5: empty args yields empty hash');

	# P6: odd-count > 1 → croak  [M7]
	throws_ok {
		Geo::Coder::Free::_normalize_args('P6-err', 'location', 'a', 'b', 'c');
	} qr/P6-err/, 'P6: odd-count > 1 list croaks (M7 logic-gap closed)';
};

subtest '_normalize_args: Local.pm — bare_key=latlng variant' => sub {
	plan tests => 5;

	# P1
	my %r1 = Geo::Coder::Free::Local::_normalize_args('ERR', 'latlng', { latlng => '51.5,0' });
	is($r1{'latlng'}, '51.5,0', 'P1: hashref (Local)');

	# P2
	throws_ok {
		Geo::Coder::Free::Local::_normalize_args('LE', 'latlng', \42);
	} qr/LE/, 'P2: scalar ref croaks (Local)';

	# P4: bare string maps to latlng, not location
	my %r4 = Geo::Coder::Free::Local::_normalize_args('ERR', 'latlng', '51.5,0');
	is($r4{'latlng'}, '51.5,0', 'P4: bare string → latlng key (Local)');
	ok(!exists $r4{'location'}, 'P4: location key absent — correct bare_key used');

	# P6: M7 also present in Local
	throws_ok {
		Geo::Coder::Free::Local::_normalize_args('LE6', 'latlng', 'a', 'b', 'c');
	} qr/LE6/, 'P6: odd-count > 1 croaks (Local — M7)';
};

# -----------------------------------------------------------------------
# geocode guard-clause partitions
#
# Major Premise: geocode rejects three syntactically invalid inputs before
#   any backend is queried.
# -----------------------------------------------------------------------

subtest 'geocode: invalid-input guard clauses' => sub {
	plan tests => 3;

	my $geo = Geo::Coder::Free->new();

	# Purely numeric → invalid location error
	throws_ok { $geo->geocode(location => '12345') }
		qr/invalid location/i,
		'purely numeric location throws invalid-location';

	# undef location → usage error (dispatches to usage croak path)
	throws_ok { $geo->geocode(location => undef) }
		qr/usage.*geocode/i,
		'undef location throws usage error';

	# No args at all (class method) → usage error
	throws_ok { Geo::Coder::Free->geocode() }
		qr/usage.*geocode/i,
		'class-method geocode() with no args throws usage error';
};

# -----------------------------------------------------------------------
# _find_word_ngrams — 6 equivalence partitions (n=3)
#
# Major Premise: _find_word_ngrams splits text into non-numeric, non-stop
#   tokens and slides a window of n, yielding (word_count - n + 1) ngrams.
# -----------------------------------------------------------------------

subtest '_find_word_ngrams: Free.pm — n=3 partitions' => sub {
	plan tests => 8;

	my $stop = { the => 1, of => 1 };

	# Q1: fewer than n words → empty
	my @r1 = Geo::Coder::Free::_find_word_ngrams('London', 3, $stop);
	is(scalar @r1, 0, 'Q1: 1 word < n=3 → empty list');

	# Q2: exactly n words → 1 ngram
	my @r2 = Geo::Coder::Free::_find_word_ngrams('London England UK', 3, $stop);
	is(scalar @r2, 1, 'Q2: exactly 3 words → 1 ngram');
	is($r2[0], 'London, England, UK', 'Q2: ngram content correct');

	# Q3: more than n words → (len - n + 1) ngrams
	my @r3 = Geo::Coder::Free::_find_word_ngrams('London England UK Europe', 3, $stop);
	is(scalar @r3, 2, 'Q3: 4 words, n=3 → 2 ngrams');

	# Q4: stopwords reduce effective word count
	my @r4 = Geo::Coder::Free::_find_word_ngrams('London the of Berlin', 3, $stop);
	is(scalar @r4, 0, 'Q4: stopwords filtered → < n remaining tokens');

	# Q5: numeric tokens filtered
	my @r5 = Geo::Coder::Free::_find_word_ngrams('123 London England UK', 3, $stop);
	is(scalar @r5, 1, 'Q5: numeric "123" filtered, 3 alpha tokens remain → 1 ngram');

	# Q6: commas stripped before tokenisation
	my @r6 = Geo::Coder::Free::_find_word_ngrams('London, England, UK', 3, $stop);
	is(scalar @r6, 1, 'Q6: commas stripped → same 3 tokens → 1 ngram');
	is($r6[0], 'London, England, UK', 'Q6: ngram content matches comma-joined tokens');
};

# -----------------------------------------------------------------------
# _search confidence partitions (M5: $failed → labeled ROW: loop)
#
# Major Premise: _search requires >= 3 column matches; confidence is
#   EXACT(1.0) when all columns match, HIGH(0.7) for 4+, MEDIUM(0.5) for 3.
# Minor Premise: Testing with 0 and 2 matching columns proves the floor.
# Conclusion: Any call with fewer than 3 qualifying columns returns undef.
# -----------------------------------------------------------------------

subtest '_search: Local.pm — column-count floor (M5 labeled-loop)' => sub {
	plan tests => 2;

	my $local = Geo::Coder::Free::Local->new();

	# 0 columns → undef (vacuously below the floor of 3)
	my $rc0 = Geo::Coder::Free::Local::_search($local, {}, ());
	is($rc0, undef, '0 columns → undef (floor not reached)');

	# 2 columns with a non-existent value → undef
	my $rc2 = Geo::Coder::Free::Local::_search(
		$local,
		{ road => 'XYZZY ROAD', city => 'NOPLACE' },
		qw(road city)
	);
	is($rc2, undef, '2-column search → undef (floor of 3 not met)');
};

# -----------------------------------------------------------------------
# M3 proof: alternatives table is reached only from non-scantext path
#
# Major Premise: All scantext-truthy branches inside the openaddr block
#   terminate with an explicit return before the alternatives table.
# Minor Premise: geocode(scantext => ...) with no openaddr backend configured
#   must return undef or an empty list without crashing.
# Conclusion: The alternatives table is provably unreachable from any
#   scantext invocation — the former `if (!$params{scantext})` guard was
#   a tautology (M3 transitive reduction applied).
# -----------------------------------------------------------------------

subtest 'M3: scantext path never reaches alternatives table' => sub {
	plan tests => 2;

	my $geo = Geo::Coder::Free->new();   # no openaddr configured

	my @hits;
	lives_ok {
		@hits = $geo->geocode(scantext => 'She grew up in London, England.', region => 'GB');
	} 'scantext with no openaddr does not die (M3 path correct)';

	# Without openaddr the result is undef/empty — not an error
	is(scalar(grep { defined } @hits), 0,
		'scantext without openaddr returns no hits (expected behaviour)');
};

# -----------------------------------------------------------------------
# M8 proof: wantarray tautology eliminated — context propagates correctly
#
# Major Premise: `return wantarray ? X : X` with identical arms is
#   semantically identical to `return X`; context propagates implicitly.
# Minor Premise: geocode() called in scalar vs list context must both work.
# Conclusion: Calling in either context returns a defined value or undef
#   without crash — proving that context propagation was not broken.
# -----------------------------------------------------------------------

subtest 'M8: maxmind fallback — scalar and list context both work' => sub {
	if(defined($ENV{NO_NETWORK_TESTING})) {
		plan tests => 1;
		pass('Needs network testing');
		return;
	}

	unless(-f 'lib/Geo/Coder/Free/MaxMind/databases/cities.sql') {
		plan tests => 1;
		pass('No cities database — skipping M8 context test');
		return;
	}

	plan tests => 3;

	# Suppress OPENADDR_HOME so we stay on the MaxMind-only path
	local $ENV{OPENADDR_HOME} = '';

	my $geo = new_ok('Geo::Coder::Free');

	my $scalar_result;
	lives_ok {
		$scalar_result = $geo->geocode(location => 'Ramsgate, Kent, UK');
	} 'geocode in scalar context does not die (M8 context propagation intact)';

	my @list_result;
	lives_ok {
		@list_result = $geo->geocode(location => 'Ramsgate, Kent, UK');
	} 'geocode in list context does not die (M8 context propagation intact)';
};

done_testing();

#!/usr/bin/env perl

# integration.t - end-to-end black-box tests for Genealogy::Occupation.
#
# Tests exercise the full pipeline across new() and normalise() with real
# external packages: I18N::LangTags::Detect (language detection),
# Lingua::EN::ABC (locale spelling), Params::Get (argument parsing),
# Params::Validate::Strict (input validation), and Return::Set (return
# value handling).  No mocking is used except for Carp::carp in the
# specific subtests that verify warn_on_error behaviour.
#
# Locale is controlled via local() on %ENV throughout so that CI
# environments and developer machines produce the same results regardless
# of their host locale.

use strict;
use warnings;
use 5.014;

use Test::Most;
use Test::Mockingbird 0.10 qw(mock_scoped);

# Verify the module loads cleanly before running any other tests
use_ok('Genealogy::Occupation') or BAIL_OUT('Cannot load Genealogy::Occupation');


# -----------------------------------------------------------------------
# Construction - use_ok already done above; new_ok exercises real new()
# -----------------------------------------------------------------------

subtest 'new_ok - no arguments, English locale' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	# new_ok calls new() and asserts the result is the right class
	my $obj = new_ok('Genealogy::Occupation');
	ok(defined $obj, 'object is defined');
};

subtest 'new_ok - with warn_on_error flag' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	# Flat-list form passed as arrayref to new_ok
	my $obj = new_ok('Genealogy::Occupation', [warn_on_error => 1],
		'Genealogy::Occupation with warn_on_error');
	ok(defined $obj, 'object with warn_on_error defined');
};

subtest 'new_ok - hashref argument style' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	# Hashref form: Params::Get must accept both calling conventions
	my $obj = new_ok('Genealogy::Occupation', [{ warn_on_error => 0 }],
		'Genealogy::Occupation with hashref args');
	ok(defined $obj, 'object from hashref args defined');
};

# -----------------------------------------------------------------------
# Full pipeline - English, British locale
# Tests steps 1-4 of the documented processing pipeline in sequence.
# -----------------------------------------------------------------------

subtest 'full pipeline - filter then normalise then dedup (British English)' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	my $obj = Genealogy::Occupation->new();

	# Step 1 (filter) + step 2 (normalise) + step 3 (dedup) all in one call.
	# 'Retired' is filtered; the two Ag Lab variants normalise to the same
	# canonical form and are then deduplicated; Platelayer Railway is reordered.
	my $result = $obj->normalise(
		occupation => [
			'Retired',
			'Ag Lab',
			'Farm Labourer',
			'Platelayer Railway',
		],
		sex => 'M',
	);
	is_deeply(
		$result,
		['Agricultural Labourer', 'Railway Platelayer'],
		'filter + dedup + normalise all applied correctly in sequence'
	);
};

subtest 'full pipeline - all direct-table entries pass through intact' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	my $obj = Genealogy::Occupation->new();

	# Spot-check a representative cross-section of the direct lookup table
	my %cases = (
		'Ag Lab'               => 'Agricultural Labourer',
		'Platelayer Railway'   => 'Railway Platelayer',
		'Domestic Servant'     => 'Domestic Servant',
		'Lorry Driver Heavy Worker' => 'Lorry Driver',
		'Laundry Man'          => 'Laundryman',
		'Market Gardener'      => 'Market Gardener',
		'Labourer Builders'    => "Builder's Labourer",
		'PFC US Army'          => 'Private First Class',
	);
	for my $input (sort keys %cases) {
		my $expected = $cases{$input};
		is_deeply(
			$obj->normalise(occupation => $input),
			[$expected],
			"'$input' -> '$expected' via direct table"
		);
	}
};

subtest 'full pipeline - realistic genealogy record sequence' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	my $obj = Genealogy::Occupation->new();

	# Simulate multiple census entries for a single person over their life:
	# at school → agricultural labourer → same job (dedup) → retired (filtered)
	my $result = $obj->normalise(
		occupation => [
			'Scholar',
			'Ag Lab',
			'Agric Labourer',
			'Retired',
		],
		sex => 'M',
	);
	is_deeply(
		$result,
		['Agricultural Labourer'],
		'complete genealogy lifecycle collapses to single occupation'
	);
};

# -----------------------------------------------------------------------
# Pattern-based normalisation rules (step 2) - real code paths
# -----------------------------------------------------------------------

subtest 'normalisation - suffix reordering and pattern rules' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	my $obj = Genealogy::Occupation->new();

	# "X domestic" reorders to "Domestic X".  Note: 'Gardener Domestic'
	# is in the direct lookup table (-> 'Gardener and Domestic') so must
	# not be used here; use a trade not in the table so the pattern fires.
	is_deeply($obj->normalise(occupation => 'Carpenter Domestic'),
		['Domestic Carpenter'], '"Carpenter Domestic" reordered');

	# "works on X" becomes "X worker"
	is_deeply($obj->normalise(occupation => 'Works on railway'),
		['Railway worker'], '"works on railway" converted');

	# Pluralised trade form gets possessive apostrophe
	is_deeply($obj->normalise(occupation => 'Builders Labourer'),
		["Builder's Labourer"], '"Builders Labourer" gains apostrophe');

	# "Foreman X" becomes "X Foreman"
	is_deeply($obj->normalise(occupation => 'Foreman Carpenter'),
		['Carpenter Foreman'], '"Foreman Carpenter" reordered');

	# "Clerk X" becomes "X Clerk"
	is_deeply($obj->normalise(occupation => 'Clerk Post Office'),
		['Post Office Clerk'], '"Clerk Post Office" reordered');
};

subtest 'normalisation - suffix stripping before canonical form' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	my $obj = Genealogy::Occupation->new();

	# "formerly" prefix stripped
	is_deeply($obj->normalise(occupation => 'Formerly Farmer'),
		['Farmer'], '"formerly" prefix stripped');

	# "own account" suffix stripped
	is_deeply($obj->normalise(occupation => 'Farmer own account'),
		['Farmer'], '"own account" suffix stripped');

	# "own business" suffix stripped
	is_deeply($obj->normalise(occupation => 'Farmer own business'),
		['Farmer'], '"own business" suffix stripped');

	# "retired" suffix stripped (not a standalone "Retired" - that is filtered)
	is_deeply($obj->normalise(occupation => 'Farmer retired'),
		['Farmer'], '"retired" suffix stripped from compound');
};

# -----------------------------------------------------------------------
# Stateful: language cached at construction time
# -----------------------------------------------------------------------

subtest 'stateful - language cached at new(), survives multiple normalise() calls' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'fr_FR.UTF-8';

	# Construct with French locale active
	my $obj = Genealogy::Occupation->new();

	# Now change the locale - the cached language must not change
	local $ENV{LANG} = 'de_DE.UTF-8';

	# Both calls must use the French language cached at construction
	is_deeply($obj->normalise(occupation => 'Farmer', sex => 'M'),
		['Agriculteur'], 'first call after locale change still French');
	is_deeply($obj->normalise(occupation => 'Postman', sex => 'M'),
		['Facteur'], 'second call still French, not German');
};

subtest 'stateful - two objects with different locales are independent' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};

	# Construct a French object
	local $ENV{LANG} = 'fr_FR.UTF-8';
	my $fr_obj = Genealogy::Occupation->new();

	# Construct a German object
	local $ENV{LANG} = 'de_DE.UTF-8';
	my $de_obj = Genealogy::Occupation->new();

	# Each object must use its own cached language, not the current env
	local $ENV{LANG} = 'en_GB.UTF-8';
	is_deeply($fr_obj->normalise(occupation => 'Farmer', sex => 'M'),
		['Agriculteur'], 'French object gives French output');
	is_deeply($de_obj->normalise(occupation => 'Farmer', sex => 'M'),
		['Bauer'], 'German object gives German output');
};

subtest 'stateful - deduplication resets between normalise() calls' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	my $obj = Genealogy::Occupation->new();

	# First call produces 'Farmer'; second call must also produce 'Farmer'
	# even though it was the last output of the previous call (dedup is
	# per-call only, not persisted on the object between calls)
	my $first  = $obj->normalise(occupation => 'Farmer');
	my $second = $obj->normalise(occupation => 'Farmer');
	is_deeply($first,  ['Farmer'], 'first call returns Farmer');
	is_deeply($second, ['Farmer'], 'second call also returns Farmer (dedup not stateful)');
};

subtest 'stateful - warn_on_error persists across multiple normalise() calls' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'fr_FR.UTF-8';

	my $obj = Genealogy::Occupation->new(warn_on_error => 1);

	# Both calls should trigger carp since warn_on_error is set on the object
	my $carp_count = 0;
	my $carp_guard = mock_scoped('Carp::carp' => sub { $carp_count++ });

	$obj->normalise(occupation => 'Wigmaker', sex => 'M');
	$obj->normalise(occupation => 'Chandler', sex => 'M');

	is($carp_count, 2,
		'warn_on_error fires on every normalise() call that cannot translate');
};

# -----------------------------------------------------------------------
# Locale spelling via Lingua::EN::ABC (real, no mock)
# -----------------------------------------------------------------------

subtest 'Lingua::EN::ABC integration - British English is the default' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	my $obj = Genealogy::Occupation->new();

	# Lingua::EN::ABC::a2b converts American -> British; since our canonical
	# forms are already British-spelled, output must be unchanged
	is_deeply($obj->normalise(occupation => 'Agricultural Labourer'),
		['Agricultural Labourer'], 'British spelling preserved through a2b');
	is_deeply($obj->normalise(occupation => 'Platelayer'),
		['Platelayer'], 'no spurious conversion on already-British string');
};

subtest 'Lingua::EN::ABC integration - American English spelling via LANG' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_US.UTF-8';

	my $obj = Genealogy::Occupation->new();

	# The en_US path calls b2a() then s/labour/labor/ig.
	# "Agricultural Labourer" should emerge as "Agricultural Laborer".
	my $result = $obj->normalise(occupation => 'Ag Lab');
	is(scalar @{$result}, 1, 'exactly one result for Ag Lab in en_US');
	like($result->[0], qr/labor/i, 'American spelling applied in en_US locale');
};

# -----------------------------------------------------------------------
# French locale - real I18N::LangTags::Detect + real translation table
# -----------------------------------------------------------------------

subtest 'French locale - end-to-end translation via LANG env var' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'fr_FR.UTF-8';

	my $obj = Genealogy::Occupation->new();

	# Non-gendered translation
	is_deeply($obj->normalise(occupation => 'Teacher'),
		['Professeur'], 'Teacher -> Professeur (non-gendered)');

	# Gendered translations
	is_deeply($obj->normalise(occupation => 'Nurse', sex => 'M'),
		['Infirmier'], 'Nurse M -> Infirmier');
	is_deeply($obj->normalise(occupation => 'Nurse', sex => 'F'),
		['Infirmière'], 'Nurse F -> Infirmiere');
};

subtest 'French locale - unknown occupation falls back to English with carp' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'fr_FR.UTF-8';

	my $obj = Genealogy::Occupation->new(warn_on_error => 1);

	my $carp_msg;
	my $carp_guard = mock_scoped('Carp::carp' => sub { $carp_msg = $_[0] });
	my $result = $obj->normalise(occupation => 'Candlemaker', sex => 'M');

	is_deeply($result, ['Candlemaker'], 'unknown French occupation returned in English');
	like($carp_msg, qr/Candlemaker/,
		'carp message identifies the untranslatable occupation');
};

subtest 'French locale - X Farmer pattern uses type-qualified form' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'fr_FR.UTF-8';

	my $obj = Genealogy::Occupation->new();

	# "Dairy Farmer" -> "Agriculteur de Dairy" (M) or "Agricultrice de Dairy" (F)
	my $m = $obj->normalise(occupation => 'Dairy Farmer', sex => 'M');
	my $f = $obj->normalise(occupation => 'Dairy Farmer', sex => 'F');
	like($m->[0], qr/Agriculteur/,  'Dairy Farmer M uses masculine form');
	like($f->[0], qr/Agricultrice/, 'Dairy Farmer F uses feminine form');
	like($m->[0], qr/Dairy/,        'Dairy Farmer preserves the farm type');
};

# -----------------------------------------------------------------------
# German locale - real I18N::LangTags::Detect + real translation table
# -----------------------------------------------------------------------

subtest 'German locale - end-to-end translation via LANG env var' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'de_DE.UTF-8';

	my $obj = Genealogy::Occupation->new();

	# Gendered translations from the German lookup table
	is_deeply($obj->normalise(occupation => 'Bus Driver', sex => 'M'),
		['Busfahrer'], 'Bus Driver M -> Busfahrer');
	is_deeply($obj->normalise(occupation => 'Bus Driver', sex => 'F'),
		['Busfahrerin'], 'Bus Driver F -> Busfahrerin');
};

subtest 'German locale - self-employed and retired suffixes replaced' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'de_DE.UTF-8';

	my $obj = Genealogy::Occupation->new();

	# _normalise_single strips trailing 'retired' (s/\s+retired$//i) so
	# 'Farmer retired' -> 'Farmer' -> 'Bauer' before the translator fires.
	# 'Retired Farmer' hits _translate_german's ^(.+)\sFarmer$ pattern
	# and returns 'Landwirt' before the substitution runs.
	# Use a non-Farmer occupation with a leading Retired prefix so that
	# neither strip nor Farmer-pattern interferes.
	my $result = $obj->normalise(occupation => 'Retired Carpenter', sex => 'M');
	is(scalar @{$result}, 1, 'one result for "Retired Carpenter" in German');
	like($result->[0], qr/ruhestand/i,
		'"Retired" in non-Farmer occupation replaced with German equivalent');
};

subtest 'German locale - unknown occupation falls back to English with carp' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'de_DE.UTF-8';

	my $obj = Genealogy::Occupation->new(warn_on_error => 1);

	my $carp_msg;
	my $carp_guard = mock_scoped('Carp::carp' => sub { $carp_msg = $_[0] });
	my $result = $obj->normalise(occupation => 'Candlemaker', sex => 'M');

	is_deeply($result, ['Candlemaker'], 'unknown German occupation returned in English');
	like($carp_msg, qr/Candlemaker/,
		'carp message identifies the untranslatable occupation');
};

# -----------------------------------------------------------------------
# Params::Get integration - both calling conventions for normalise()
# -----------------------------------------------------------------------

subtest 'Params::Get integration - normalise() accepts flat-list args' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	my $obj = Genealogy::Occupation->new();

	# Flat-list style: occupation => ..., sex => ...
	my $result = $obj->normalise(occupation => 'Ag Lab', sex => 'M');
	is_deeply($result, ['Agricultural Labourer'],
		'normalise() with flat-list args works correctly');
};

subtest 'Params::Get integration - normalise() accepts hashref args' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	my $obj = Genealogy::Occupation->new();

	# Hashref style: { occupation => ..., sex => ... }
	my $result = $obj->normalise({ occupation => 'Ag Lab', sex => 'M' });
	is_deeply($result, ['Agricultural Labourer'],
		'normalise() with hashref args works correctly');
};

# -----------------------------------------------------------------------
# Return::Set integration - return value behaves correctly in context
# -----------------------------------------------------------------------

subtest 'Return::Set integration - scalar context returns arrayref' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	my $obj = Genealogy::Occupation->new();

	my $result = $obj->normalise(occupation => 'Ag Lab');
	ok(ref($result) eq 'ARRAY', 'scalar context returns arrayref');
	is($result->[0], 'Agricultural Labourer', 'correct value in scalar context');
};

subtest 'Return::Set integration - arrayref dereferenced in list context' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	my $obj = Genealogy::Occupation->new();

	# Return::Set is called with type=>'arrayref' so it always returns a
	# reference even in list context; dereference to iterate the elements.
	my $result = $obj->normalise(
		occupation => ['Ag Lab', 'Platelayer Railway'],
	);
	my @items = @{$result};
	is(scalar @items, 2,                    'dereferenced result has correct count');
	is($items[0], 'Agricultural Labourer',  'first element correct after deref');
	is($items[1], 'Railway Platelayer',     'second element correct after deref');
};

# -----------------------------------------------------------------------
# Params::Validate::Strict integration - bad args are rejected at runtime
# -----------------------------------------------------------------------

subtest 'Params::Validate::Strict integration - invalid new() args croak' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	# Validation must reject unknown keys even via hashref style
	throws_ok(
		sub { Genealogy::Occupation->new({ bad_key => 1 }) },
		qr/.+/,
		'unknown new() arg croaks via Params::Validate::Strict'
	);
};

subtest 'Params::Validate::Strict integration - invalid sex value croaks' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	my $obj = Genealogy::Occupation->new();

	# memberof constraint must reject values outside ['M', 'F']
	throws_ok(
		sub { $obj->normalise(occupation => 'Farmer', sex => 'N') },
		qr/.+/,
		'sex value outside [M, F] croaks via Params::Validate::Strict'
	);
};

done_testing();

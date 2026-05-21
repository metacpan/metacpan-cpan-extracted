#!/usr/bin/env perl

# unit.t - black-box unit tests for the public API of Genealogy::Occupation.
#
# Each subtest targets one documented behaviour from the POD.  External
# dependencies are isolated via Test::Mockingbird so that results do not
# vary with the host locale, installed CPAN modules, or environment.
#
# Dependencies mocked:
#   I18N::LangTags::Detect::detect  - language detection called by new()
#   Carp::carp                      - verifies warn_on_error behaviour

use strict;
use warnings;
use 5.014;

use Test::Most;
use Test::Mockingbird 0.10 qw(mock_scoped);

use_ok('Genealogy::Occupation') or BAIL_OUT('Cannot load Genealogy::Occupation');

# -----------------------------------------------------------------------
# new()
# -----------------------------------------------------------------------

subtest 'new() - returns a blessed Genealogy::Occupation object' => sub {
	# Suppress language detection so the result is locale-independent
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });

	isa_ok(Genealogy::Occupation->new(), 'Genealogy::Occupation');
};

subtest 'new() - accepts hashref argument style' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });

	isa_ok(
		Genealogy::Occupation->new({ warn_on_error => 0 }),
		'Genealogy::Occupation',
		'hashref argument accepted'
	);
};

subtest 'new() - accepts flat-list argument style' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });

	isa_ok(
		Genealogy::Occupation->new(warn_on_error => 0),
		'Genealogy::Occupation',
		'flat-list argument accepted'
	);
};

subtest 'new() - unknown argument causes croak' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });

	# Params::Validate::Strict must reject unrecognised keys
	throws_ok(
		sub { Genealogy::Occupation->new(not_a_real_arg => 1) },
		qr/.+/,
		'unknown constructor argument causes croak'
	);
};

# -----------------------------------------------------------------------
# normalise() - argument validation
# -----------------------------------------------------------------------

subtest 'normalise() - missing occupation causes croak' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# occupation is required; omitting it must croak with a useful message
	throws_ok(
		sub { $obj->normalise(sex => 'M') },
		qr/occupation/i,
		'omitting occupation argument causes croak'
	);
};

subtest 'normalise() - invalid sex value causes croak' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# sex must be 'M' or 'F'; anything else must croak
	throws_ok(
		sub { $obj->normalise(occupation => 'Farmer', sex => 'X') },
		qr/.+/,
		'sex value other than M or F causes croak'
	);
};

# -----------------------------------------------------------------------
# normalise() - return type
# -----------------------------------------------------------------------

subtest 'normalise() - return value is an arrayref of strings' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	my $result = $obj->normalise(occupation => 'Farmer');

	# POD API specification: type => 'arrayref', element_type => 'string'
	ok(ref($result) eq 'ARRAY', 'return value is an arrayref');
	is(ref($result->[0]), '', 'array elements are plain strings') if @{$result};
};

# -----------------------------------------------------------------------
# normalise() - single-string and arrayref inputs
# -----------------------------------------------------------------------

subtest 'normalise() - single string expanded via direct lookup table' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	is_deeply(
		$obj->normalise(occupation => 'Ag Lab'),
		['Agricultural Labourer'],
		'Ag Lab expanded to Agricultural Labourer'
	);
};

subtest 'normalise() - arrayref input processes all elements' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	is_deeply(
		$obj->normalise(occupation => ['Ag Lab', 'Platelayer Railway']),
		['Agricultural Labourer', 'Railway Platelayer'],
		'arrayref of two occupations both expanded correctly'
	);
};

subtest 'normalise() - unrecognised occupation returned with ucfirst' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# Occupations not in any lookup table pass through unchanged
	is_deeply(
		$obj->normalise(occupation => 'Watchmaker'),
		['Watchmaker'],
		'unrecognised occupation returned as-is'
	);
};

# -----------------------------------------------------------------------
# normalise() - filtering
# -----------------------------------------------------------------------

subtest 'normalise() - Retired filtered out' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# Both mixed-case and lowercase forms must be caught
	is_deeply($obj->normalise(occupation => 'Retired'), [], 'Retired filtered');
	is_deeply($obj->normalise(occupation => 'retired'), [], 'retired (lc) filtered');
};

subtest 'normalise() - Unemployed filtered out' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	is_deeply($obj->normalise(occupation => 'Unemployed'), [], 'Unemployed filtered');
};

subtest 'normalise() - Scholar and School patterns filtered out' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# Filter pattern: ^scho(?:ol|lar)
	is_deeply($obj->normalise(occupation => 'Scholar'),   [], 'Scholar filtered');
	is_deeply($obj->normalise(occupation => 'Schoolboy'), [], 'Schoolboy filtered');
	is_deeply($obj->normalise(occupation => 'At School'), [], 'At School filtered');
};

subtest 'normalise() - wife suffix pattern filtered out' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# Filter pattern: wife$
	is_deeply($obj->normalise(occupation => "Farmer's wife"), [], "Farmer's wife filtered");
	is_deeply($obj->normalise(occupation => 'Housewife'),     [], 'Housewife filtered');
};

subtest 'normalise() - domestic duties patterns filtered out' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	is_deeply($obj->normalise(occupation => 'Domestic duties'),   [], 'Domestic duties filtered');
	is_deeply($obj->normalise(occupation => 'Home duties'),       [], 'Home duties filtered');
	is_deeply($obj->normalise(occupation => 'Household duties'),  [], 'Household duties filtered');
	# The pattern also tolerates a space between house and hold
	is_deeply($obj->normalise(occupation => 'House hold duties'), [], 'House hold duties (with space) filtered');
};

subtest 'normalise() - seeking work pattern filtered out' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	is_deeply($obj->normalise(occupation => 'Seeking work'), [], 'Seeking work filtered');
};

subtest 'normalise() - entirely filtered input returns empty arrayref' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# Every element is a non-occupation; the result must be an empty arrayref, not undef
	my $result = $obj->normalise(occupation => ['Retired', 'Unemployed', 'Scholar']);
	is_deeply($result, [], 'all-filtered input returns empty arrayref');
	ok(ref($result) eq 'ARRAY', 'return value is still an arrayref when empty');
};

# -----------------------------------------------------------------------
# normalise() - deduplication
# -----------------------------------------------------------------------

subtest 'normalise() - consecutive identical entries deduplicated' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	is_deeply(
		$obj->normalise(occupation => ['Ag Lab', 'Ag Lab']),
		['Agricultural Labourer'],
		'duplicate Ag Lab collapses to single entry'
	);
};

subtest 'normalise() - deduplication operates on normalised forms' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# Different abbreviations that both expand to the same canonical form
	# should be deduplicated after normalisation, not before
	is_deeply(
		$obj->normalise(occupation => ['Ag Lab', 'Farm Labourer']),
		['Agricultural Labourer'],
		'two abbreviations for the same occupation deduplicate after normalisation'
	);
};

subtest 'normalise() - non-consecutive duplicates are preserved' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# POD notes deduplication only applies to consecutive entries
	is_deeply(
		$obj->normalise(occupation => ['Farmer', 'Gardener', 'Farmer']),
		['Farmer', 'Gardener', 'Farmer'],
		'non-consecutive duplicate Farmer entries both appear in output'
	);
};

subtest 'normalise() - consecutive duplicates deduplicate in non-English locale' => sub {
	# Regression test for the $last_normalised fix (0.02): dedup previously
	# compared the already-translated $result[-1] against the incoming
	# English-normalised string, so two consecutive 'Farmer' entries both
	# became 'Agriculteur' without being collapsed.
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Occupation->new();

	# Two identical English occupations must collapse to one translated form
	is_deeply(
		$obj->normalise(occupation => ['Farmer', 'Farmer'], sex => 'M'),
		['Agriculteur'],
		'consecutive Farmer pair collapses to one Agriculteur in French locale'
	);

	# Non-consecutive duplicates must still both appear
	is_deeply(
		$obj->normalise(occupation => ['Farmer', 'Teacher', 'Farmer'], sex => 'M'),
		['Agriculteur', 'Professeur', 'Agriculteur'],
		'non-consecutive Farmer entries both translated in French locale'
	);
};

# -----------------------------------------------------------------------
# normalise() - French translation
# -----------------------------------------------------------------------

subtest 'normalise() - French masculine translation' => sub {
	# Mocking detect() to return 'fr' causes new() to cache language as French
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Occupation->new();

	is_deeply(
		$obj->normalise(occupation => 'Farmer', sex => 'M'),
		['Agriculteur'],
		'Farmer -> Agriculteur for male in French locale'
	);
};

subtest 'normalise() - French feminine translation' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Occupation->new();

	is_deeply(
		$obj->normalise(occupation => 'Farmer', sex => 'F'),
		['Agricultrice'],
		'Farmer -> Agricultrice for female in French locale'
	);
};

subtest 'normalise() - French unknown occupation falls back to English silently' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	# warn_on_error defaults to 0, so no carp should fire
	my $obj = Genealogy::Occupation->new();

	is_deeply(
		$obj->normalise(occupation => 'Wigmaker', sex => 'M'),
		['Wigmaker'],
		'untranslatable French occupation returned in English with no warning'
	);
};

subtest 'normalise() - French unknown occupation carps when warn_on_error set' => sub {
	my $detect_guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Occupation->new(warn_on_error => 1);

	# Capture carp calls to verify the warning path is taken
	my $carp_count = 0;
	my $carp_guard = mock_scoped('Carp::carp' => sub { $carp_count++ });
	$obj->normalise(occupation => 'Wigmaker', sex => 'M');
	ok($carp_count > 0, 'Carp::carp fired for untranslatable French occupation');
};

subtest 'normalise() - French no carp when warn_on_error unset' => sub {
	my $detect_guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Occupation->new(warn_on_error => 0);

	# Verify the carp path is NOT taken when warn_on_error is false
	my $carp_count = 0;
	my $carp_guard = mock_scoped('Carp::carp' => sub { $carp_count++ });
	$obj->normalise(occupation => 'Wigmaker', sex => 'M');
	is($carp_count, 0, 'Carp::carp not called when warn_on_error is false');
};

# -----------------------------------------------------------------------
# normalise() - German translation
# -----------------------------------------------------------------------

subtest 'normalise() - German masculine translation' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Occupation->new();

	is_deeply(
		$obj->normalise(occupation => 'Teacher', sex => 'M'),
		['Lehrer'],
		'Teacher -> Lehrer for male in German locale'
	);
};

subtest 'normalise() - German feminine translation' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Occupation->new();

	is_deeply(
		$obj->normalise(occupation => 'Teacher', sex => 'F'),
		['Lehrerin'],
		'Teacher -> Lehrerin for female in German locale'
	);
};

subtest 'normalise() - German unknown occupation falls back to English silently' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Occupation->new();

	is_deeply(
		$obj->normalise(occupation => 'Wigmaker', sex => 'M'),
		['Wigmaker'],
		'untranslatable German occupation returned in English with no warning'
	);
};

subtest 'normalise() - German unknown occupation carps when warn_on_error set' => sub {
	my $detect_guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Occupation->new(warn_on_error => 1);

	my $carp_count = 0;
	my $carp_guard = mock_scoped('Carp::carp' => sub { $carp_count++ });
	$obj->normalise(occupation => 'Wigmaker', sex => 'M');
	ok($carp_count > 0, 'Carp::carp fired for untranslatable German occupation');
};

subtest 'normalise() - German no carp when warn_on_error unset' => sub {
	my $detect_guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Occupation->new(warn_on_error => 0);

	my $carp_count = 0;
	my $carp_guard = mock_scoped('Carp::carp' => sub { $carp_count++ });
	$obj->normalise(occupation => 'Wigmaker', sex => 'M');
	is($carp_count, 0, 'Carp::carp not called when warn_on_error is false');
};

# -----------------------------------------------------------------------
# normalise() - sex default
# -----------------------------------------------------------------------

subtest 'normalise() - sex defaults to M for gendered translations' => sub {
	# French: Farmer M => Agriculteur, F => Agricultrice
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Occupation->new();

	# Omitting sex should yield the masculine form per the POD default
	is_deeply(
		$obj->normalise(occupation => 'Farmer'),
		['Agriculteur'],
		'omitting sex gives masculine translation'
	);
};

done_testing();

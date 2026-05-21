#!/usr/bin/env perl

# extended_tests.t - targeted coverage tests for Genealogy::Occupation.
#
# Each subtest is chosen to exercise a specific branch, linear code
# sequence, or decision point not reached by unit.t, integration.t, or
# edge_cases.t.  Together they aim for >=95% statement coverage and
# maximum LCSAJ/TER3 scores by exercising every reachable path through
# _normalise_single, _get_language, _translate_french, _translate_german,
# and _apply_locale.
#
# External dependencies are mocked where needed to isolate code paths;
# env vars are localised to prevent host-locale interference.

use strict;
use warnings;
use 5.014;

use Test::Most;
use Test::Mockingbird 0.10 qw(mock_scoped);

use_ok('Genealogy::Occupation') or BAIL_OUT('Cannot load Genealogy::Occupation');

# -----------------------------------------------------------------------
# _normalise_single - uncovered suffix-stripping branches
# -----------------------------------------------------------------------

subtest '_normalise_single - "heavy worker" suffix stripped' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# s/\s+heavy worker$//i - "Lorry Driver heavy worker" is in the direct
	# table; use a trade not in the table to force the suffix-stripping path
	is_deeply($obj->normalise(occupation => 'Farmer heavy worker'),
		['Farmer'], '"heavy worker" suffix stripped from non-table occupation');

	# Confirm it is case-insensitive
	is_deeply($obj->normalise(occupation => 'Farmer Heavy Worker'),
		['Farmer'], '"Heavy Worker" (title case) suffix also stripped');
};

subtest '_normalise_single - American "Labor" converted to British "Labour"' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# s/Labor/Labour/ig fires before any pattern rules; the corrected string
	# can then match later patterns or the direct table
	is_deeply($obj->normalise(occupation => 'Agricultural Labor'),
		['Agricultural Labour'], 'American "Labor" corrected to British "Labour"');

	# Case-insensitive: 'labor' in lowercase should also be caught.
	# Note: ucfirst only touches the first character, so only the first
	# word gains a capital; the rest of the casing is preserved as-is.
	is_deeply($obj->normalise(occupation => 'Farm labor'),
		['Farm Labour'], 'lowercase "labor" also converted by /i flag');
};

subtest '_normalise_single - "dom" suffix variant reorders to "Domestic X"' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# The pattern /^(.+)\s(?:domestic|dom)$/i has two alternatives;
	# "domestic" is tested elsewhere - exercise the "dom" branch here
	is_deeply($obj->normalise(occupation => 'Carpenter Dom'),
		['Domestic Carpenter'], '"Carpenter Dom" reordered to "Domestic Carpenter"');

	is_deeply($obj->normalise(occupation => 'Painter dom'),
		['Domestic Painter'], 'lowercase "dom" also matches');
};

subtest '_normalise_single - "works for" variant of works pattern' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# /works?\s+(?:on|for)\s+(.+)/i has two preposition alternatives;
	# "on" is tested elsewhere - exercise "for" here
	is_deeply($obj->normalise(occupation => 'Works for railway'),
		['Railway worker'], '"works for" converted to "X worker"');

	# Also test the singular "work" form (works? makes the s optional)
	is_deeply($obj->normalise(occupation => 'Work on canal'),
		['Canal worker'], 'singular "work on" also matches');
};

subtest '_normalise_single - "Cleaner X" prefix reordered to "X cleaner"' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# /^Cleaner\s+(.+)/i - untested branch
	is_deeply($obj->normalise(occupation => 'Cleaner Windows'),
		['Windows cleaner'], '"Cleaner Windows" reordered to "Windows cleaner"');

	is_deeply($obj->normalise(occupation => 'Cleaner Chimney'),
		['Chimney cleaner'], '"Cleaner Chimney" reordered');
};

subtest '_normalise_single - "Salesman X" prefix reordered to "X Salesman"' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# /^Salesman\s+(.*)/i - untested branch
	is_deeply($obj->normalise(occupation => 'Salesman Bread'),
		['Bread Salesman'], '"Salesman Bread" reordered to "Bread Salesman"');

	is_deeply($obj->normalise(occupation => 'Salesman Insurance'),
		['Insurance Salesman'], '"Salesman Insurance" reordered');
};

subtest '_normalise_single - "Shop Assistant X" gets possessive prefix' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# /^Shop Assistant\s+(.+)/i - untested branch
	is_deeply($obj->normalise(occupation => "Shop Assistant Bakery"),
		["Bakery's Shop Assistant"],
		'"Shop Assistant Bakery" gains possessive prefix');

	is_deeply($obj->normalise(occupation => 'Shop Assistant Draper'),
		["Draper's Shop Assistant"], '"Shop Assistant Draper" reordered');
};

subtest '_normalise_single - Assistant passthrough cases' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# Trade already has possessive: `unless($trade =~ /'s$/...)` passes it through
	is_deeply($obj->normalise(occupation => "Miner's Assistant"),
		["Miner's Assistant"],
		'trade already possessive - passes through unchanged');

	# Trade is 'shop': `|| lc($trade) eq 'shop'` passes it through
	is_deeply($obj->normalise(occupation => 'Shop Assistant'),
		['Shop Assistant'],
		'"Shop Assistant" (no trailing word) passes through unchanged');
};

subtest '_normalise_single - "police" suffix triggers "officer" append' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# /police$/i - untested branch; match is on trailing 'police'
	is_deeply($obj->normalise(occupation => 'Metropolitan Police'),
		['Metropolitan Police officer'],
		'"Metropolitan Police" gains "officer" suffix');

	# Plain "Police" also matches
	is_deeply($obj->normalise(occupation => 'Police'),
		['Police officer'], 'bare "Police" gains "officer"');
};

subtest '_normalise_single - "on farm" pattern inserts article "a"' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# /^(.+)\s+on farm$/i - untested branch
	is_deeply($obj->normalise(occupation => 'Labourer on farm'),
		['Labourer on a farm'], '"Labourer on farm" gains article "a"');

	is_deeply($obj->normalise(occupation => 'Carter on farm'),
		['Carter on a farm'], '"Carter on farm" also gains "a"');
};

# -----------------------------------------------------------------------
# _get_language - environment variable cascade (all fallback paths)
# -----------------------------------------------------------------------

subtest '_get_language - LANGUAGE env var used when detect() returns nothing' => sub {
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	delete local $ENV{LANG};
	local $ENV{LANGUAGE} = 'de_DE.UTF-8';

	# detect() returns nothing; _get_language must fall through to LANGUAGE
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	is_deeply($obj->normalise(occupation => 'Teacher', sex => 'M'),
		['Lehrer'], 'LANGUAGE env var drives German language detection');
};

subtest '_get_language - LC_ALL used when LANGUAGE and detect() both absent' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_MESSAGES};
	delete local $ENV{LANG};
	local $ENV{LC_ALL} = 'fr_FR.UTF-8';

	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	is_deeply($obj->normalise(occupation => 'Farmer', sex => 'M'),
		['Agriculteur'], 'LC_ALL env var drives French language detection');
};

subtest '_get_language - LC_MESSAGES used when higher-priority vars absent' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LANG};
	local $ENV{LC_MESSAGES} = 'de_DE.UTF-8';

	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	is_deeply($obj->normalise(occupation => 'Farmer', sex => 'M'),
		['Bauer'], 'LC_MESSAGES env var drives German language detection');
};

subtest '_get_language - C.UTF-8 locale treated as English' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'C.UTF-8';

	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });

	# /^C(\.|$)/ matches both 'C' and 'C.anything' and returns 'en'
	my $obj = Genealogy::Occupation->new();
	is_deeply($obj->normalise(occupation => 'Ag Lab'), ['Agricultural Labourer'],
		'C.UTF-8 locale treated as English');
};

subtest '_get_language - detect() returning hyphenated tag extracts prefix' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	# 'fr-FR' → /^([a-z]{2})/i → 'fr'; object should behave as French
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr-FR' });
	my $obj = Genealogy::Occupation->new();

	is_deeply($obj->normalise(occupation => 'Farmer', sex => 'M'),
		['Agriculteur'], 'hyphenated detect() tag "fr-FR" extracts "fr"');
};

subtest '_get_language - non-matching detect() tag falls through to env vars' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'de_DE.UTF-8';

	# '123' does not match /^([a-z]{2})/i → loop exhausted → falls to env vars
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { '123' });
	my $obj = Genealogy::Occupation->new();

	is_deeply($obj->normalise(occupation => 'Farmer', sex => 'M'),
		['Bauer'], 'non-matching detect() tag falls through to LANG env var');
};

subtest '_get_language - undef returned when no locale detectable' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	delete local $ENV{LANG};

	# With no env vars and detect() returning nothing, _get_language returns
	# undef; normalise() must default gracefully via $language // 'en'
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	lives_ok(sub { $obj->normalise(occupation => 'Farmer') },
		'undef language defaults to English without crashing');
	is_deeply($obj->normalise(occupation => 'Ag Lab'),
		['Agricultural Labourer'], 'undef language treated as English');
};

# -----------------------------------------------------------------------
# _translate_french - all untested branches
# -----------------------------------------------------------------------

subtest '_translate_french - teaching path returns "professeur"' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Occupation->new();

	# /teaching/i fires for any occupation containing the word
	is_deeply($obj->normalise(occupation => 'Teaching'),
		['Professeur'], '"Teaching" → Professeur via teaching regex');

	is_deeply($obj->normalise(occupation => 'Teaching Assistant'),
		['Professeur'], '"Teaching Assistant" also hits teaching path');
};

subtest '_translate_french - "retired" substituted with French phrase' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Occupation->new();

	# _normalise_single strips TRAILING \s+retired$ but not a leading
	# "Retired" prefix; that prefix survives to _translate_french where
	# s/retired/\x{e0} la retraite/i fires.  The Farmer pattern is then
	# absent so the substituted string falls through to the lookup/fallback.
	my $result = $obj->normalise(occupation => 'Retired Carpenter', sex => 'M');
	is(scalar @{$result}, 1, 'one result for "Retired Carpenter" in French');
	like($result->[0], qr/retraite/i,
		'"Retired" prefix replaced with French retirement phrase');
};

subtest '_translate_french - Postman M and F translations' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Occupation->new();

	# Exercises the gendered hash branch in the French lookup table
	is_deeply($obj->normalise(occupation => 'Postman', sex => 'M'),
		['Facteur'], 'Postman M → Facteur');
	is_deeply($obj->normalise(occupation => 'Postman', sex => 'F'),
		['Factrice'], 'Postman F → Factrice');
};

subtest '_translate_french - Nurse M translation (Infirmier)' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Occupation->new();

	# Nurse has both M and F keys; M form is ASCII and safe to compare directly
	is_deeply($obj->normalise(occupation => 'Nurse', sex => 'M'),
		['Infirmier'], 'Nurse M → Infirmier');
};

subtest '_translate_french - X Farmer feminine form uses Agricultrice' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Occupation->new();

	# The /^(.+)\sFarmer$/i branch returns gendered form; F path untested
	my $f = $obj->normalise(occupation => 'Dairy Farmer', sex => 'F');
	like($f->[0], qr/^Agricultrice/, 'Dairy Farmer F uses Agricultrice prefix');
	like($f->[0], qr/Dairy/, 'Dairy Farmer F preserves type in output');

	# Compare M and F so both branches are exercised in one subtest
	my $m = $obj->normalise(occupation => 'Dairy Farmer', sex => 'M');
	like($m->[0], qr/^Agriculteur/, 'Dairy Farmer M uses Agriculteur prefix');
	isnt($m->[0], $f->[0], 'M and F Farmer forms differ');
};

subtest '_translate_french - non-gendered lookup table entry (Teacher)' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Occupation->new();

	# 'teacher' => 'Professeur' is a plain string (not a hashref);
	# exercises the `return $translation` scalar branch
	is_deeply($obj->normalise(occupation => 'Teacher', sex => 'M'),
		['Professeur'], 'non-gendered French table entry returned as-is (M)');
	is_deeply($obj->normalise(occupation => 'Teacher', sex => 'F'),
		['Professeur'], 'non-gendered French table entry same for F');
};

# -----------------------------------------------------------------------
# _translate_german - all untested branches
# -----------------------------------------------------------------------

subtest '_translate_german - teaching M and F both covered' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Occupation->new();

	# Two branches: $sex eq 'F' → Lehrerin, else → Lehrer
	is_deeply($obj->normalise(occupation => 'Teaching', sex => 'M'),
		['Lehrer'], 'Teaching M → Lehrer');
	is_deeply($obj->normalise(occupation => 'Teaching', sex => 'F'),
		['Lehrerin'], 'Teaching F → Lehrerin');
};

subtest '_translate_german - self-employed substitution fires' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Occupation->new();

	# s/self-employed/selbstst\x{e4}ndig/i - entirely untested path.
	# The substituted form is not in the lookup table so falls back;
	# we verify the substitution fired using a substring match.
	my $result = $obj->normalise(occupation => 'Self-employed Carpenter', sex => 'M');
	is(scalar @{$result}, 1, 'one result for "Self-employed Carpenter" in German');
	like($result->[0], qr/selbst/i,
		'"self-employed" replaced with German equivalent in output');
};

subtest '_translate_german - Farmer M (Bauer) and F (Bauerin) table entries' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Occupation->new();

	# 'farmer' is in %GERMAN as a gendered hashref; both sexes exercised
	is_deeply($obj->normalise(occupation => 'Farmer', sex => 'M'),
		['Bauer'], 'Farmer M → Bauer');
	is_deeply($obj->normalise(occupation => 'Farmer', sex => 'F'),
		['Bauerin'], 'Farmer F → Bauerin');
};

subtest '_translate_german - X Farmer pattern (Landwirt/Landwirtin)' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Occupation->new();

	# /^(.+)\sFarmer$/i returns before lookup table; M and F branches both
	is_deeply($obj->normalise(occupation => 'Dairy Farmer', sex => 'M'),
		['Landwirt'], 'Dairy Farmer M → Landwirt');
	is_deeply($obj->normalise(occupation => 'Dairy Farmer', sex => 'F'),
		['Landwirtin'], 'Dairy Farmer F → Landwirtin');
};

subtest '_translate_german - non-gendered lookup returns scalar' => sub {
	# %GERMAN has no non-gendered entries currently; test that the hashref
	# branch returns the correct sex-keyed value and the // fallback to M
	# when sex key is present covers both branches of the ternary.
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Occupation->new();

	# Bus Driver M → Busfahrer, F → Busfahrerin (both keys exist in hashref)
	is_deeply($obj->normalise(occupation => 'Bus Driver', sex => 'M'),
		['Busfahrer'], 'Bus Driver M → Busfahrer');
	is_deeply($obj->normalise(occupation => 'Bus Driver', sex => 'F'),
		['Busfahrerin'], 'Bus Driver F → Busfahrerin');
};

# -----------------------------------------------------------------------
# _apply_locale - Canadian English path (Lingua::EN::ABC::b2c)
# -----------------------------------------------------------------------

subtest '_apply_locale - Canadian English path does not crash' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_CA.UTF-8';

	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# b2c path: confirm it fires without error and returns a string
	my $result;
	lives_ok(sub { $result = $obj->normalise(occupation => 'Ag Lab') },
		'en_CA locale does not crash during normalise()');
	is(scalar @{$result}, 1, 'en_CA returns one result');
	like($result->[0], qr/Agricultural/i,
		'en_CA result still contains "Agricultural"');
};

# -----------------------------------------------------------------------
# Direct-table entries not yet exercised by other test files
# -----------------------------------------------------------------------

subtest 'direct table - additional entries verified individually' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# Entries not hit in any other test file
	my %cases = (
		'Ag Labourer Pauper'			   => 'Agricultural Labourer',
		'Agric Labourer'				   => 'Agricultural Labourer',
		'Agril Labourer'				   => 'Agricultural Labourer',
		'Agricultural Farm Labourer'	   => 'Agricultural Labourer',
		'Ordinary Agricultural Labourer'   => 'Agricultural Labourer',
		'Work on farm'					 => 'Agricultural Labourer',
		'Ag Lab Pauper'					=> 'Agricultural Labourer',
		'Labourer Ag'					  => 'Agricultural Labourer',
		'Labourer Gas Stoker'			  => 'Gas Stoker',
		'Gardner and Domestic Servant'	 => 'Gardener and Domestic',
		'Domestic Under Gardner'		   => 'Domestic Gardener',
		'Plate Glass Cutter'			   => 'Plate Glass Cutter',
		'Gardener Domestic'				=> 'Gardener and Domestic',
		'Under Gardener Domestic'		  => 'Domestic Gardener',
	);
	for my $input (sort keys %cases) {
		my $expected = $cases{$input};
		is_deeply(
			$obj->normalise(occupation => $input),
			[$expected],
			"direct table: '$input' → '$expected'"
		);
	}
};

subtest 'direct table - "Labourer (Ag)" with parens cleaned before lookup' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# s/[\(\)]//g removes parens: 'Labourer (Ag)' → 'Labourer Ag' → direct table
	is_deeply($obj->normalise(occupation => 'Labourer (Ag)'),
		['Agricultural Labourer'],
		'"Labourer (Ag)" cleaned of parens then matched via direct table');
};

# -----------------------------------------------------------------------
# Sex parameter in non-translation context
# -----------------------------------------------------------------------

subtest 'sex => "F" in English locale is accepted and ignored gracefully' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# In English there is no gendered translation; sex must not cause errors
	is_deeply($obj->normalise(occupation => 'Farmer', sex => 'F'),
		['Farmer'], 'sex => F in English locale accepted without error');
	is_deeply($obj->normalise(occupation => 'Ag Lab', sex => 'F'),
		['Agricultural Labourer'],
		'sex => F does not affect English direct-table lookup');
};

# -----------------------------------------------------------------------
# Combined multi-path scenarios for LCSAJ coverage
# -----------------------------------------------------------------------

subtest 'French locale: mixed array with translatable and untranslatable entries' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Occupation->new();

	# Exercises filter, translation-hit, translation-miss, and dedup paths
	# all in one normalise() call with French active
	my $result = $obj->normalise(
		occupation => [
			'Retired',		  # filtered
			'Farmer',		   # translates: Agriculteur
			'Farmer',		   # deduped
			'Wigmaker',		 # falls back to English
			'Teacher',		  # translates: Professeur
		],
		sex => 'M',
	);
	is(scalar @{$result}, 3, 'three distinct results after filter and dedup');
	is($result->[0], 'Agriculteur', 'first result: Farmer → Agriculteur');
	is($result->[1], 'Wigmaker',	'second result: Wigmaker falls back to English');
	is($result->[2], 'Professeur',  'third result: Teacher → Professeur');
};

subtest 'German locale: mixed array exercises all German branches' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Occupation->new();

	# Filter + teaching path + lookup path + X Farmer path + fallback
	my $result = $obj->normalise(
		occupation => [
			'Scholar',		 # filtered
			'Teaching',		# → Lehrer (M)
			'Bus Driver',	  # → Busfahrer (M)
			'Dairy Farmer',	# → Landwirt (M)
			'Wigmaker',		# fallback to English
		],
		sex => 'M',
	);
	is(scalar @{$result}, 4, 'four results after filter');
	is($result->[0], 'Lehrer',	 'Teaching → Lehrer');
	is($result->[1], 'Busfahrer',  'Bus Driver → Busfahrer');
	is($result->[2], 'Landwirt',   'Dairy Farmer → Landwirt');
	is($result->[3], 'Wigmaker',   'Wigmaker falls back to English');
};

subtest 'warn_on_error carp message contains occupation name and language hint' => sub {
	my $detect_guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Occupation->new(warn_on_error => 1);

	# Capture the full carp message and verify it contains useful content
	my @messages;
	my $carp_guard = mock_scoped('Carp::carp' => sub { push @messages, $_[0] });

	$obj->normalise(occupation => 'Wigmaker', sex => 'M');

	is(scalar @messages, 1, 'exactly one carp message emitted');
	like($messages[0], qr/Wigmaker/, 'carp message names the occupation');
	like($messages[0], qr/German|german|translation/i,
		'carp message hints at the translation context');
};

subtest 'normalise() called repeatedly on same object - no state leakage' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# Call normalise() ten times; each call must be independent of the last
	for my $i (1..10) {
		my $result = $obj->normalise(occupation => 'Ag Lab');
		is_deeply($result, ['Agricultural Labourer'],
			"call $i: same result regardless of previous calls");
	}
};

subtest 'all five normalise() pipeline steps active in one call' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# Step 1 (filter): 'Housewife' removed
	# Step 2 (normalise): 'Ag Lab' → 'Agricultural Labourer'
	# Step 3 (dedup): second 'Ag Lab' removed
	# Step 4 (locale): Lingua::EN::ABC::a2b applied (no-op for British input)
	# Step 5 (translate): language is 'en', no translation applied
	my $result = $obj->normalise(
		occupation => ['Housewife', 'Ag Lab', 'Farm Labourer', 'Platelayer Railway'],
		sex => 'M',
	);
	is_deeply($result, ['Agricultural Labourer', 'Railway Platelayer'],
		'all five pipeline steps exercised correctly in one call');
};

subtest 'General Servant Domestic regex variants all produce Domestic Servant' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# /^general serv.+dom/i matches any variant of the servant/domestic string;
	# the .+ means at least one char between 'serv' and 'dom'
	is_deeply($obj->normalise(occupation => 'General Service Domestic'),
		['Domestic Servant'], 'general service domestic matches regex variant');
	is_deeply($obj->normalise(occupation => 'General Servant of the Domestic'),
		['Domestic Servant'], 'general servant of the domestic matches');
	is_deeply($obj->normalise(occupation => 'GENERAL SERVANT DOMESTIC'),
		['Domestic Servant'], 'case-insensitive match on general servant regex');
};

subtest '_translate_german - non-gendered scalar table entry returned as-is' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Occupation->new();

	# 'doctor' => 'Arzt' is a plain string entry (not a hashref);
	# exercises the scalar return $translation branch, killing
	# the BOOL_NEGATE_676 and RETURN_UNDEF_676 mutants
	is_deeply($obj->normalise(occupation => 'Doctor', sex => 'M'),
		['Arzt'], 'non-gendered German table entry returned as-is (M)');
	is_deeply($obj->normalise(occupation => 'Doctor', sex => 'F'),
		['Arzt'], 'non-gendered German table entry same for F');
};

done_testing();

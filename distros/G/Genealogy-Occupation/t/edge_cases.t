#!/usr/bin/env perl

# edge_cases.t - destructive, pathological, and boundary-condition tests
# for Genealogy::Occupation.
#
# Tests are deliberately adversarial: malformed input, boundary-straddling
# strings, homoglyphs, empty arrays, enormous arrays, regex-hostile
# characters, filter-vs-normalise ordering traps, and known false-positive
# risks in the filter patterns.  Each subtest documents the exact behaviour
# that results, even when that behaviour is surprising.

use strict;
use warnings;
use 5.014;

use Test::Most;
use Test::Mockingbird 0.10 qw(mock_scoped);

use_ok('Genealogy::Occupation') or BAIL_OUT('Cannot load Genealogy::Occupation');

# Convenience: English-locale object with language detection mocked out
# so that individual test environment locale cannot affect results.
# Returns ($obj, $guard); caller must keep $guard in scope.
sub _en {
	my %args   = @_;
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard  = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj    = Genealogy::Occupation->new(%args);
	# Return guard separately so the caller can keep it alive past return
	return ($obj, $guard);
}

# -----------------------------------------------------------------------
# String-cleaning step boundary conditions
# The cleaning pipeline runs in this order:
#   tr/\r\n/ /   -> s/\.+$//   -> s/[\(\)]//g ->
#   s/\s\s+/ /g  -> s/\s+$//   -> s/\./;/g
# -----------------------------------------------------------------------

subtest 'cleaning - dots-only string collapses to empty and is skipped' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# '...' -> s/\.+$// -> '' -> length 0 -> skipped entirely
	is_deeply($obj->normalise(occupation => '...'), [],
		'dots-only string produces empty result');
};

subtest 'cleaning - parentheses-only string collapses to empty and is skipped' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# '()' -> s/[\(\)]//g -> '' -> length 0 -> skipped
	is_deeply($obj->normalise(occupation => '()'), [],
		'parentheses-only string produces empty result');

	# Parens with only whitespace inside also collapses
	is_deeply($obj->normalise(occupation => '(  )'), [],
		'whitespace-inside-parens string produces empty result');
};

subtest 'cleaning - embedded CR+LF normalised to single space' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# tr/\r\n/ / converts each \r and \n to a space, then s/\s\s+/ /g
	# collapses them, restoring the string to a matchable form
	is_deeply($obj->normalise(occupation => "Ag\r\nLab"), ['Agricultural Labourer'],
		'CRLF within occupation string cleaned to single space before lookup');

	# Multiple newlines also collapse
	is_deeply($obj->normalise(occupation => "Ag\n\n\nLab"), ['Agricultural Labourer'],
		'multiple newlines collapsed to single space');
};

subtest 'cleaning - trailing dots stripped, internal dots become semicolons' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# Trailing dots are stripped before s/\./;/g fires, so 'Ag Lab...'
	# becomes 'Ag Lab' and matches the direct table
	is_deeply($obj->normalise(occupation => 'Ag Lab...'), ['Agricultural Labourer'],
		'trailing dots stripped restoring direct-table matchability');

	# Internal dots survive the trailing-dot strip and become semicolons;
	# 'Ag.Lab' -> 'Ag;Lab' -> no direct-table match -> passes through
	my $result = $obj->normalise(occupation => 'Ag.Lab');
	isnt($result->[0], 'Agricultural Labourer',
		'internal dot becomes semicolon, breaking direct-table lookup');
};

subtest 'cleaning - leading whitespace is NOT stripped (only trailing is)' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# s/\s+$// strips trailing only; a single leading space survives
	# and prevents the direct-table lookup from matching
	my $result = $obj->normalise(occupation => ' Ag Lab');
	TODO: {
		local $TODO = 'leading whitespace not stripped; direct-table lookup misses';
		is_deeply($result, ['Agricultural Labourer'],
			'leading-space occupation should ideally still normalise');
	}
};

subtest 'cleaning - tab character within string is not converted by tr' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# tr/\r\n/ / does NOT touch tabs; a single tab is not caught by
	# s/\s\s+/ /g (requires 2+ whitespace chars), so 'Ag\tLab' is never
	# normalised to the direct-table key 'ag lab'
	my $result = $obj->normalise(occupation => "Ag\tLab");
	TODO: {
		local $TODO = 'embedded tab not collapsed; direct-table lookup misses';
		is_deeply($result, ['Agricultural Labourer'],
			'tab-separated occupation should ideally normalise');
	}
};

# -----------------------------------------------------------------------
# Filter boundary conditions
# -----------------------------------------------------------------------

subtest 'filter - case-insensitive exact-word filter matches all cases' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# %FILTER uses lc() so all case variants must be caught
	for my $variant (qw(Retired RETIRED retired rEtIrEd)) {
		is_deeply($obj->normalise(occupation => $variant), [],
			"'$variant' filtered by exact-word filter");
	}
};

subtest 'filter - "at school" pattern requires exact whole-string match' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# /^at school$/i requires the entire cleaned string to be 'at school'
	is_deeply($obj->normalise(occupation => 'At School'), [],
		'"At School" (exact) is filtered');

	# Any extra text prevents the anchor from matching
	my $r = $obj->normalise(occupation => 'at school teacher');
	isnt(scalar @{$r}, 0,
		'"at school teacher" not filtered - trailing word breaks anchor');
};

subtest 'filter - "wife" pattern is a suffix anchor (false-positive risk)' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# The intended targets
	is_deeply($obj->normalise(occupation => "Farmer's wife"), [],
		"Farmer's wife filtered by /wife\$/ pattern");
	is_deeply($obj->normalise(occupation => 'Housewife'), [],
		'Housewife filtered by /wife$/ pattern');

	# Midwife is a genuine genealogical occupation but matches /wife$/i;
	# document the current (surprising) behaviour with a TODO
	TODO: {
		local $TODO = 'Midwife is a real occupation but matches /wife$/ filter';
		my $r = $obj->normalise(occupation => 'Midwife');
		isnt(scalar @{$r}, 0, 'Midwife should not be filtered');
	}
};

subtest 'filter - "seeking work" is an unanchored substring match' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# The pattern /seeking work/i has no anchors, so it fires anywhere
	is_deeply($obj->normalise(occupation => 'Seeking work'),    [], 'plain form filtered');
	is_deeply($obj->normalise(occupation => 'Not seeking work'), [], 'negated form also filtered');
	is_deeply($obj->normalise(occupation => 'Seeking work as a farmer'), [],
		'extended form filtered - unanchored pattern fires mid-string');
};

subtest 'filter - "formerly retired" slips through filter but emerges as Retired' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# The filter runs on the RAW (cleaned) string, not the normalised form.
	# 'Formerly retired' does not match any filter rule, so it proceeds to
	# _normalise_single where s/^formerly //i strips the prefix, leaving
	# 'retired', which then passes the length check and emerges as 'Retired'.
	my $result = $obj->normalise(occupation => 'Formerly retired');
	TODO: {
		local $TODO = 'filter-normalise ordering: formerly-prefixed blocked words slip through';
		is_deeply($result, [], '"Formerly retired" should ideally be filtered');
	}
};

# -----------------------------------------------------------------------
# Possessives regex - regression tests for the $base/$last fix
# -----------------------------------------------------------------------

subtest 'possessives - Bus Driver is NOT rewritten (lc($base) eq "bu" guard)' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# Before the fix, "Bus Driver" became "Buu's Driver" because the guard
	# compared "$base$last" (= "Buu") instead of $base (= "Bu").
	is_deeply($obj->normalise(occupation => 'Bus Driver'), ['Bus Driver'],
		'Bus Driver not rewritten as possessive (regression guard)');
};

subtest 'possessives - Harness Maker is NOT rewritten (lc($base) eq "harnes" guard)' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# "Harness Maker": $base="Harnes", without the guard this would have
	# become "Harnes's Maker".
	is_deeply($obj->normalise(occupation => 'Harness Maker'), ['Harness Maker'],
		'Harness Maker not rewritten as possessive (regression guard)');
};

subtest 'possessives - Gas Works occupations are excluded entirely' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# /gas works/i guard prevents the possessives regex from firing at all
	is_deeply($obj->normalise(occupation => 'Gas Works Manager'), ['Gas Works Manager'],
		'Gas Works occupations skip the possessives rewrite');
};

subtest 'possessives - legitimate trade plurals are rewritten correctly' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# These ARE intended to be rewritten
	is_deeply($obj->normalise(occupation => 'Builders Labourer'),
		["Builder's Labourer"], 'Builders Labourer gains apostrophe');
	is_deeply($obj->normalise(occupation => 'Bakers Assistant'),
		["Baker's Assistant"],  'Bakers Assistant gains apostrophe via special case');
	is_deeply($obj->normalise(occupation => 'Butchers Assistant'),
		["Butcher's Assistant"], 'Butchers Assistant gains apostrophe via special case');
};

# -----------------------------------------------------------------------
# Manager / Foreman / Clerk / Salesman pattern boundary conditions
# -----------------------------------------------------------------------

subtest 'Manager patterns - guards prevent rewrite in special forms' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# "Manager of X" is guarded from rewrite
	is_deeply($obj->normalise(occupation => 'Manager of the Works'),
		['Manager of the Works'], '"Manager of X" guard prevents rewrite');

	# "Manager & X" is also guarded
	is_deeply($obj->normalise(occupation => 'Manager & Partner'),
		['Manager & Partner'], '"Manager & X" guard prevents rewrite');

	# Plain "Manager X" IS rewritten
	is_deeply($obj->normalise(occupation => 'Manager Shop'),
		['Shop Manager'], 'plain "Manager X" rewritten to "X Manager"');
};

subtest 'Foreman "of the" stripping works correctly' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# "Foreman of the Mill" -> $of='of the Mill' -> s/^of the //i -> 'Mill Foreman'
	is_deeply($obj->normalise(occupation => 'Foreman of the Mill'),
		['Mill Foreman'], '"Foreman of the X" correctly strips "of the"');

	# "Foreman Pit" -> no "of the" to strip -> 'Pit Foreman'
	is_deeply($obj->normalise(occupation => 'Foreman Pit'),
		['Pit Foreman'], 'plain Foreman rewrite without "of the"');
};

# -----------------------------------------------------------------------
# Pathological array inputs
# -----------------------------------------------------------------------

subtest 'empty arrayref produces empty result without error' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	my $result = $obj->normalise(occupation => []);
	is_deeply($result, [], 'empty arrayref input gives empty arrayref output');
	ok(ref($result) eq 'ARRAY', 'return is still an arrayref for empty input');
};

subtest 'large arrayref of identical entries deduplicates to one' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# 1000 copies should deduplicate to exactly one result with no error
	my $result = $obj->normalise(occupation => [('Ag Lab') x 1000]);
	is_deeply($result, ['Agricultural Labourer'],
		'1000 identical entries deduplicate to a single result');
};

subtest 'large arrayref of all-filtered entries gives empty result' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# Mix of every filter type, 100 of each
	my @all_filtered = (
		('Retired')           x 100,
		('Unemployed')        x 100,
		('Scholar')           x 100,
		('Housewife')         x 100,
		('Domestic duties')   x 100,
		('Seeking work')      x 100,
	);
	my $result = $obj->normalise(occupation => \@all_filtered);
	is_deeply($result, [],
		'large all-filtered array returns empty arrayref');
};

subtest 'arrayref with empty strings and valid entries mixed' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# Empty strings pass the filter (not in %FILTER) but _normalise_single
	# returns '' for them, which is then caught by `next unless length`
	my $result = $obj->normalise(occupation => ['', 'Ag Lab', '', 'Platelayer Railway', '']);
	is_deeply(
		$result,
		['Agricultural Labourer', 'Railway Platelayer'],
		'empty strings in array are silently skipped'
	);
};

subtest 'arrayref with whitespace-only strings are silently skipped' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# '   ' -> s/\s\s+/ /g -> ' ' -> s/\s+$// -> '' -> skipped
	my $result = $obj->normalise(occupation => ['   ', 'Farmer', "\t\t"]);
	is_deeply($result, ['Farmer'],
		'whitespace-only strings in array are silently skipped'
	);
};

# -----------------------------------------------------------------------
# Regex-hostile characters in occupation strings
# -----------------------------------------------------------------------

subtest 'regex-special characters in occupation pass through safely' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# These characters are dangerous if the occupation were ever used as a
	# regex pattern; confirm they pass through normalisation without dying
	for my $hostile ('A+B Worker', 'A*B Worker', 'A[B Worker', 'A{2} Worker') {
		my $result;
		lives_ok(
			sub { $result = $obj->normalise(occupation => $hostile) },
			"regex-hostile '$hostile' does not crash normalise()"
		);
		ok(defined $result, "result is defined for '$hostile'");
	}
};

# -----------------------------------------------------------------------
# Unicode and non-ASCII characters
# -----------------------------------------------------------------------

subtest 'Unicode characters in occupation pass through without corruption' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# Genealogy records sometimes contain accented or Unicode characters;
	# confirm they are not corrupted by the cleaning or normalisation steps
	is_deeply($obj->normalise(occupation => "B\x{00E4}cker"), ["B\x{00E4}cker"],
		'German umlaut in occupation preserved');
	is_deeply($obj->normalise(occupation => "Cha\x{00EE}nier"), ["Cha\x{00EE}nier"],
		'French circumflex accent in occupation preserved');
};

subtest 'French-locale output preserves non-ASCII in translation strings' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Occupation->new();

	# The module stores 'Infirmière' as raw bytes without use utf8; comparing
	# with a \x{} escape (Unicode code point) fails because the encodings
	# differ.  Use a regex instead so the non-ASCII byte is matched loosely
	# while still verifying the surrounding ASCII frame is intact.
	my $result = $obj->normalise(occupation => 'Nurse', sex => 'F');
	like($result->[0], qr/^Infirmi.+re$/,
		'feminine French nurse contains expected ASCII frame around non-ASCII bytes');

	# Verify the feminine and masculine forms are distinct
	my $m = $obj->normalise(occupation => 'Nurse', sex => 'M');
	isnt($result->[0], $m->[0],
		'feminine French nurse differs from masculine form');
};

# -----------------------------------------------------------------------
# Language detection extremes
# -----------------------------------------------------------------------

subtest 'C locale treated as English' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'C';

	# _get_language returns 'en' for C locale; object must behave as English
	my $obj = Genealogy::Occupation->new();
	is_deeply($obj->normalise(occupation => 'Ag Lab'), ['Agricultural Labourer'],
		'C locale object normalises as English');
};

subtest 'no locale variables set - falls back gracefully' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	delete local $ENV{LANG};
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });

	# _get_language returns undef; normalise() defaults to 'en' via // 'en'
	my $obj = Genealogy::Occupation->new();
	lives_ok(
		sub { $obj->normalise(occupation => 'Farmer') },
		'no locale set does not crash normalise()'
	);
};

subtest 'short LANG code without country suffix is accepted' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'fr';

	# 'fr' without '_FR.UTF-8' should still detect as French
	my $obj = Genealogy::Occupation->new();
	is_deeply(
		$obj->normalise(occupation => 'Farmer', sex => 'M'),
		['Agriculteur'],
		'short LANG="fr" still triggers French translation'
	);
};

# -----------------------------------------------------------------------
# Calling-convention edge cases
# -----------------------------------------------------------------------

subtest 'undef occupation causes croak' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	throws_ok(
		sub { $obj->normalise(occupation => undef) },
		qr/occupation/i,
		'explicitly passing undef as occupation causes croak'
	);
};

subtest 'occupation key entirely absent causes croak' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	throws_ok(
		sub { $obj->normalise() },
		qr/occupation/i,
		'calling normalise() with no arguments causes croak'
	);
};

# -----------------------------------------------------------------------
# Very long input string
# -----------------------------------------------------------------------

subtest 'very long occupation string does not crash or hang' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# 10,000 character occupation string - must complete without dying
	my $long = 'x' x 10_000;
	my $result;
	lives_ok(
		sub { $result = $obj->normalise(occupation => $long) },
		'10,000-character occupation string does not crash'
	);
	is(scalar @{$result}, 1, 'long string returns exactly one result');
	is(length($result->[0]), 10_000, 'long string returned at full length');
};

subtest 'very long occupation string that matches a filter pattern' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# A string ending in 'wife' but 10,000 chars long - filter must not hang
	my $long_wife = ('x' x 9_995) . 'swife';
	my $result;
	lives_ok(
		sub { $result = $obj->normalise(occupation => $long_wife) },
		'10,000-character string matching /wife$/ filter does not hang'
	);
	is_deeply($result, [], 'long wife-suffix string is filtered out');
};

# -----------------------------------------------------------------------
# Deduplication boundary conditions
# -----------------------------------------------------------------------

subtest 'deduplication is case-insensitive on the normalised form' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# The dedup check is lc($result[-1]) eq lc($occupation).
	# If one abbreviation normalises to 'Farmer' and the next also to
	# 'farmer', they should collapse.  Use two abbreviations whose
	# canonical forms differ only in case (hard to construct artificially,
	# so test the documented direct-table case).
	is_deeply(
		$obj->normalise(occupation => ['Ag Lab', 'Agricultural Labourer']),
		['Agricultural Labourer'],
		'two forms of the same occupation deduplicate after normalisation'
	);
};

subtest 'alternating non-consecutive duplicates all survive' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# A B A B - only consecutive duplicates are removed; alternation survives
	my $result = $obj->normalise(
		occupation => ['Farmer', 'Gardener', 'Farmer', 'Gardener', 'Farmer'],
	);
	is(scalar @{$result}, 5,
		'alternating A/B/A/B/A pattern produces all 5 entries');
};

# -----------------------------------------------------------------------
# General servant regex boundary conditions
# -----------------------------------------------------------------------

subtest 'general servant regex matches expected variants' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Occupation->new();

	# Pattern: /^general serv.+dom/i
	is_deeply($obj->normalise(occupation => 'General Servant Domestic'),
		['Domestic Servant'], 'canonical form matches');
	is_deeply($obj->normalise(occupation => 'General Service Domestic'),
		['Domestic Servant'], 'serv.+ matches "service" variant');

	# Does NOT fire when 'dom' is absent
	my $r = $obj->normalise(occupation => 'General Servant');
	isnt($r->[0], 'Domestic Servant',
		'"General Servant" without "dom" suffix does not match pattern');
};

done_testing();

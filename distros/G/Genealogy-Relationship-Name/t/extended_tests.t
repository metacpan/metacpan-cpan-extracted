#!/usr/bin/env perl

# extended_tests.t - Extended tests to raise coverage, LCSAJ/TER3 scores,
# and kill common mutants for Genealogy::Relationship::Name.
#
# Covers:
#  * All language/sex table branches
#  * Invalid language croak branch (validate_strict rejects non-en/fr/de)
#  * Region-subtag stripping branch
#  * Constructor default-language branch vs no default
#  * wantarray branches in supported_languages() and known_sexes()
#  * undef-return path for un-tabulated pairs
#  * Exact string-equality assertions to kill value-substitution mutants

use strict;
use warnings;

use Test::Most;

use lib 'lib', '../lib';

BEGIN {
	use_ok('Genealogy::Relationship::Name')
		or BAIL_OUT('Cannot load Genealogy::Relationship::Name');
}

# =========================================================================
# 1. Exercise every branch in name(): language source priority
#    Branch A: language from arg
#    Branch B: language from constructor
#    Branch C: language hard default 'en'
# =========================================================================

subtest 'Language source: per-call > constructor > hard default' => sub {
	plan tests => 3;

	# Branch C: no language anywhere → hard default 'en'
	my $namer_bare = Genealogy::Relationship::Name->new();
	is($namer_bare->name(steps_to_ancestor => 1, steps_from_ancestor => 1, sex => 'M'),
		'brother', 'Branch C: hard default en used');

	# Branch B: constructor-only → use constructor lang
	my $namer_fr = Genealogy::Relationship::Name->new(language => 'fr');
	is($namer_fr->name(steps_to_ancestor => 1, steps_from_ancestor => 1, sex => 'M'),
		"fr\N{U+00E8}re", 'Branch B: constructor lang fr used');

	# Branch A: per-call overrides constructor
	is($namer_fr->name(steps_to_ancestor => 1, steps_from_ancestor => 1,
	                   sex => 'M', language => 'de'),
		'Bruder', 'Branch A: per-call lang de overrides constructor fr');
};

# =========================================================================
# 2. Region-subtag stripping branch
# =========================================================================

subtest 'Region subtag stripping branch' => sub {
	plan tests => 4;

	my $namer = Genealogy::Relationship::Name->new();

	# All should resolve to 'en' after stripping
	for my $lang_tag (qw(en-GB en-US en-AU en-NZ)) {
		is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 0, sex => 'M', language => $lang_tag),
			'father', "$lang_tag stripped to en -> father");
	}
};

# =========================================================================
# 3. Invalid language branch: validate_strict croaks before any lookup
# =========================================================================

subtest 'Unsupported language: validate_strict croaks' => sub {
	plan tests => 3;

	my $namer = Genealogy::Relationship::Name->new();

	# Each invalid language code must croak, not silently fall back
	for my $bad (qw(xx zz zh)) {
		throws_ok {
			$namer->name(steps_to_ancestor => 2, steps_from_ancestor => 0,
			             sex => 'F', language => $bad)
		} qr/must match pattern/, "language '$bad' croaks";
	}
};

# =========================================================================
# 4. Exhaust all male table entries: kill value-substitution mutants
# =========================================================================

subtest 'English male table: every tabulated entry' => sub {
	my $namer = Genealogy::Relationship::Name->new();

	my %expected = (
		'0,0' => 'self',
		'0,1' => 'son',
		'0,2' => 'grandson',
		'0,3' => 'great-grandson',
		'0,4' => 'great-great-grandson',
		'1,0' => 'father',
		'1,1' => 'brother',
		'1,2' => 'nephew',
		'1,3' => 'great-nephew',
		'1,4' => 'great-great-nephew',
		'2,0' => 'grandfather',
		'2,1' => 'uncle',
		'2,2' => 'first cousin',
		'2,3' => 'first cousin once-removed',
		'2,4' => 'first cousin twice-removed',
		'2,5' => 'first cousin three-times-removed',
		'3,0' => 'great-grandfather',
		'3,1' => 'great-uncle',
		'3,2' => 'first cousin once-removed',
		'3,3' => 'second cousin',
		'3,4' => 'second cousin once-removed',
		'3,5' => 'second cousin twice-removed',
		'3,6' => 'second cousin three-times-removed',
		'4,0' => 'great-great-grandfather',
		'4,1' => 'great-great-uncle',
		'4,2' => 'first cousin twice-removed',
		'4,3' => 'second cousin once-removed',
		'4,4' => 'third cousin',
		'4,5' => 'third cousin once-removed',
		'4,6' => 'third cousin twice-removed',
		'5,0' => 'great-great-great-grandfather',
		'5,1' => 'great-great-great-uncle',
		'5,2' => 'first cousin three-times-removed',
		'5,3' => 'second cousin twice-removed',
		'5,4' => 'third cousin once-removed',
		'5,5' => 'fourth cousin',
		'5,6' => 'fourth cousin once-removed',
		'6,0' => 'great-great-great-great-grandfather',
		'6,2' => 'first cousin four-times-removed',
		'6,3' => 'second cousin three-times-removed',
		'6,4' => 'third cousin twice-removed',
		'6,5' => 'fourth cousin once-removed',
		'6,6' => 'fifth cousin',
	);

	plan tests => scalar keys %expected;

	while(my ($key, $want) = each %expected) {
		my ($s1, $s2) = split /,/, $key;
		my $got = $namer->name(steps_to_ancestor => $s1, steps_from_ancestor => $s2, sex => 'M');
		is($got, $want, "en M $key => $want");
	}
};

# =========================================================================
# 5. Exhaust all female table entries
# =========================================================================

subtest 'English female table: every tabulated entry' => sub {
	my $namer = Genealogy::Relationship::Name->new();

	my %expected = (
		'0,0' => 'self',
		'0,1' => 'daughter',
		'0,2' => 'granddaughter',
		'0,3' => 'great-granddaughter',
		'0,4' => 'great-great-granddaughter',
		'1,0' => 'mother',
		'1,1' => 'sister',
		'1,2' => 'niece',
		'1,3' => 'great-niece',
		'1,4' => 'great-great-niece',
		'2,0' => 'grandmother',
		'2,1' => 'aunt',
		'2,2' => 'first cousin',
		'2,3' => 'first cousin once-removed',
		'2,4' => 'first cousin twice-removed',
		'2,5' => 'first cousin three-times-removed',
		'3,0' => 'great-grandmother',
		'3,1' => 'great-aunt',
		'3,2' => 'first cousin once-removed',
		'3,3' => 'second cousin',
		'3,4' => 'second cousin once-removed',
		'3,5' => 'second cousin twice-removed',
		'3,6' => 'second cousin three-times-removed',
		'4,0' => 'great-great-grandmother',
		'4,1' => 'great-great-aunt',
		'4,2' => 'first cousin twice-removed',
		'4,3' => 'second cousin once-removed',
		'4,4' => 'third cousin',
		'4,5' => 'third cousin once-removed',
		'4,6' => 'third cousin twice-removed',
		'5,0' => 'great-great-great-grandmother',
		'5,1' => 'great-great-great-aunt',
		'5,2' => 'first cousin three-times-removed',
		'5,3' => 'second cousin twice-removed',
		'5,4' => 'third cousin once-removed',
		'5,5' => 'fourth cousin',
		'5,6' => 'fourth cousin once-removed',
		'6,0' => 'great-great-great-great-grandmother',
		'6,2' => 'first cousin four-times-removed',
		'6,3' => 'second cousin three-times-removed',
		'6,4' => 'third cousin twice-removed',
		'6,5' => 'fourth cousin once-removed',
		'6,6' => 'fifth cousin',
	);

	plan tests => scalar keys %expected;

	while(my ($key, $want) = each %expected) {
		my ($s1, $s2) = split /,/, $key;
		my $got = $namer->name(steps_to_ancestor => $s1, steps_from_ancestor => $s2, sex => 'F');
		is($got, $want, "en F $key => $want");
	}
};

# =========================================================================
# 6. wantarray branch: supported_languages() in both contexts
# =========================================================================

subtest 'wantarray branch: supported_languages() list vs scalar' => sub {
	plan tests => 4;

	my $namer = Genealogy::Relationship::Name->new();

	# List context
	my @list = $namer->supported_languages();
	ok(scalar @list == 7, 'List context: 7 items');
	ok(ref(\@list) eq 'ARRAY', 'List context: got list');

	# Scalar context
	my $ref = $namer->supported_languages();
	isa_ok($ref, 'ARRAY', 'Scalar context: got ARRAY ref');
	is(scalar @{$ref}, 7, 'Scalar context: ref has 7 items');
};

# =========================================================================
# 7. wantarray branch: known_sexes() in both contexts
# =========================================================================

subtest 'wantarray branch: known_sexes() list vs scalar' => sub {
	plan tests => 4;

	my $namer = Genealogy::Relationship::Name->new();

	my @list = $namer->known_sexes();
	is(scalar @list, 2, 'List context: 2 items');
	is_deeply([sort @list], ['F', 'M'], 'List context: F and M sorted');

	my $ref = $namer->known_sexes();
	isa_ok($ref, 'ARRAY');
	is(scalar @{$ref}, 2, 'Scalar context: 2 items in ref');
};

# =========================================================================
# 8. Mutation-killing: confirm distinct names for adjacent cousins
# =========================================================================

subtest 'Mutation kill: adjacent cousin steps give distinct names' => sub {
	plan tests => 4;

	my $namer = Genealogy::Relationship::Name->new();

	# Must not be equal: first vs second cousin etc.
	isnt(
		$namer->name(steps_to_ancestor => 2, steps_from_ancestor => 2, sex => 'M'),
		$namer->name(steps_to_ancestor => 3, steps_from_ancestor => 3, sex => 'M'),
		'first cousin != second cousin'
	);
	isnt(
		$namer->name(steps_to_ancestor => 3, steps_from_ancestor => 3, sex => 'M'),
		$namer->name(steps_to_ancestor => 4, steps_from_ancestor => 4, sex => 'M'),
		'second cousin != third cousin'
	);
	isnt(
		$namer->name(steps_to_ancestor => 0, steps_from_ancestor => 1, sex => 'M'),
		$namer->name(steps_to_ancestor => 0, steps_from_ancestor => 2, sex => 'M'),
		'son != grandson'
	);
	isnt(
		$namer->name(steps_to_ancestor => 1, steps_from_ancestor => 1, sex => 'M'),
		$namer->name(steps_to_ancestor => 1, steps_from_ancestor => 1, sex => 'F'),
		'brother != sister'
	);
};

# =========================================================================
# 9. Mutation-killing: male != female for gender-specific terms
# =========================================================================

subtest 'Mutation kill: male and female differ for gender-specific terms' => sub {
	plan tests => 6;

	my $namer = Genealogy::Relationship::Name->new();

	my @gendered = (
		[0, 1],   # son vs daughter
		[1, 0],   # father vs mother
		[2, 0],   # grandfather vs grandmother
		[0, 2],   # grandson vs granddaughter
		[1, 1],   # brother vs sister
		[2, 1],   # uncle vs aunt
	);

	for my $pair (@gendered) {
		my ($s1, $s2) = @{$pair};
		my $m = $namer->name(steps_to_ancestor => $s1, steps_from_ancestor => $s2, sex => 'M');
		my $f = $namer->name(steps_to_ancestor => $s1, steps_from_ancestor => $s2, sex => 'F');
		isnt($m, $f, "${s1},${s2}: '$m' (M) != '$f' (F)");
	}
};

# =========================================================================
# 10. French table completeness spot-check: all tabulated keys return defined
# =========================================================================

subtest 'French table: tabulated keys all return defined values' => sub {
	my $namer = Genealogy::Relationship::Name->new();

	my @keys = (
		[0,0], [0,1], [0,2], [0,3], [0,4],
		[1,0], [1,1], [1,2], [1,3], [1,4],
		[2,0], [2,1], [2,2], [2,3], [2,4],
		[3,0], [3,1], [3,2], [3,3], [3,4],
		[4,0], [4,1], [4,2], [4,3], [4,4],
		[5,0], [5,5], [6,0], [6,6],
	);

	plan tests => scalar(@keys) * 2;

	for my $k (@keys) {
		my ($s1, $s2) = @{$k};
		for my $sex (qw(M F)) {
			my $r = $namer->name(steps_to_ancestor => $s1, steps_from_ancestor => $s2,
			                     sex => $sex, language => 'fr');
			ok(defined $r, "fr ${s1},${s2} $sex => defined");
		}
	}
};

# =========================================================================
# 11. German table completeness spot-check
# =========================================================================

subtest 'German table: tabulated keys all return defined values' => sub {
	my $namer = Genealogy::Relationship::Name->new();

	my @keys = (
		[0,0], [0,1], [0,2], [0,3], [0,4],
		[1,0], [1,1], [1,2], [1,3], [1,4],
		[2,0], [2,1], [2,2], [2,3], [2,4],
		[3,0], [3,1], [3,2], [3,3], [3,4],
		[4,0], [4,1], [4,2], [4,3], [4,4],
		[5,0], [5,5], [6,0], [6,6],
	);

	plan tests => scalar(@keys) * 2;

	for my $k (@keys) {
		my ($s1, $s2) = @{$k};
		for my $sex (qw(M F)) {
			my $r = $namer->name(steps_to_ancestor => $s1, steps_from_ancestor => $s2,
			                     sex => $sex, language => 'de');
			ok(defined $r, "de ${s1},${s2} $sex => defined");
		}
	}
};

# =========================================================================
# 12. LCSAJ: ensure the undef return branch is exercised for each language
# =========================================================================

subtest 'LCSAJ: undef-return branch exercised for all languages' => sub {
	plan tests => 3;

	my $namer = Genealogy::Relationship::Name->new();

	for my $lang (qw(en fr de)) {
		my $r = $namer->name(steps_to_ancestor => 99, steps_from_ancestor => 99,
		                     sex => 'M', language => $lang);
		is($r, undef, "undef return branch hit for lang=$lang");
	}
};

# =========================================================================
# 13. Call idempotency: same args always give the same result
# =========================================================================

subtest 'Idempotency: repeated calls with same args give same result' => sub {
	plan tests => 4;

	my $namer = Genealogy::Relationship::Name->new();

	my @args = (steps_to_ancestor => 3, steps_from_ancestor => 4, sex => 'F');
	my $first = $namer->name(@args);

	for my $i (1..4) {
		is($namer->name(@args), $first, "Call $i gives same result as call 0");
	}
};

# =========================================================================
# 14. Test that the constructor stores arbitrary extra keys (Object::Configure)
# =========================================================================

subtest 'Constructor stores arbitrary config keys' => sub {
	plan tests => 2;

	my $namer = Genealogy::Relationship::Name->new(language => 'fr', author => 'NJH');
	is($namer->{language}, 'fr', 'language stored');
	is($namer->{author},   'NJH', 'arbitrary key stored for Object::Configure compat');
};

# =========================================================================
# 15. Verify module VERSION is set
# =========================================================================

subtest 'Module VERSION is defined' => sub {
	plan tests => 2;

	ok(defined $Genealogy::Relationship::Name::VERSION, 'VERSION is defined');
	like($Genealogy::Relationship::Name::VERSION, qr/^\d+\.\d+/, 'VERSION looks numeric');
};

done_testing();

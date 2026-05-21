#!/usr/bin/env perl

# mutant_survivors.t - Tests to kill surviving mutants identified by App::Test::Generator
# Generated stubs completed: 2026-05-14
#
# Survivors targeted:
#   BOOL_NEGATE_346_2  / RETURN_UNDEF_346_2  - new()                  line 346
#   BOOL_NEGATE_484_2  / RETURN_UNDEF_484_2  - name()                 line 484
#   BOOL_NEGATE_543_2  / RETURN_UNDEF_543_2  - supported_languages()  line 543
#   BOOL_NEGATE_601_2  / RETURN_UNDEF_601_2  - known_sexes()          line 601
#
# Strategy: for each return statement, assert:
#   1. The return value is defined (kills RETURN_UNDEF)
#   2. The return value is truthy / correct type (kills BOOL_NEGATE)
#   3. The exact value or structure is correct (kills both)

use strict;
use warnings;

use Test::Most;

use lib 'lib', '../lib';

BEGIN {
	use_ok('Genealogy::Relationship::Name')
		or BAIL_OUT('Cannot load Genealogy::Relationship::Name');
}

# =========================================================================
# BOOL_NEGATE_346_2 / RETURN_UNDEF_346_2
# Source: return $self;   in new()
# Kill: assert the return is defined, blessed, and correct class
# =========================================================================

subtest 'new() return value: defined, blessed, correct class' => sub {
	plan tests => 4;

	my $obj = Genealogy::Relationship::Name->new();

	# Kills RETURN_UNDEF: undef would fail this
	ok(defined $obj, 'new() returns a defined value');

	# Kills BOOL_NEGATE: a negated/false value would fail this
	ok($obj, 'new() returns a truthy value');

	# Kills both: wrong ref type or class would fail these
	ok(ref $obj, 'new() returns a reference');
	isa_ok($obj, 'Genealogy::Relationship::Name');
};

# =========================================================================
# BOOL_NEGATE_484_2 / RETURN_UNDEF_484_2
# Source: return $result;   in name()
# Kill: assert the return is defined and matches expected string exactly
# for a known key; also assert undef for an unknown key (not just falsiness)
# =========================================================================

subtest 'name() return value: defined and exact for known key' => sub {
	plan tests => 5;

	my $obj = Genealogy::Relationship::Name->new();

	# Known key: assert defined, truthy, and exact string value
	my $result = $obj->name(steps_to_ancestor => 1, steps_from_ancestor => 1, sex => 'M');

	# Kills RETURN_UNDEF: undef would fail this
	ok(defined $result, 'name() returns defined for known key');

	# Kills BOOL_NEGATE: empty string or 0 would fail this
	ok($result, 'name() returns truthy for known key');

	# Kills both via exact string match
	is($result, 'brother', 'name() returns exact expected string');

	# Second known key with female sex — kills value-substitution too
	my $result2 = $obj->name(steps_to_ancestor => 1, steps_from_ancestor => 1, sex => 'F');
	ok(defined $result2, 'name() returns defined for female sibling');
	is($result2, 'sister', 'name() returns exact string for female sibling');
};

subtest 'name() return value: strict undef for unknown key' => sub {
	plan tests => 2;

	my $obj = Genealogy::Relationship::Name->new();

	my $result = $obj->name(steps_to_ancestor => 99, steps_from_ancestor => 99, sex => 'M');

	# Must be exactly undef, not just falsy (e.g. 0 or '')
	ok(!defined $result, 'name() returns undef (not just falsy) for unknown key');
	is($result, undef, 'name() return is strictly undef for unknown key');
};

# =========================================================================
# BOOL_NEGATE_543_2 / RETURN_UNDEF_543_2
# Source: return wantarray ? @langs : \@langs;   in supported_languages()
# Kill: assert list context returns a non-empty list of defined strings,
# and scalar context returns a defined, non-empty arrayref
# =========================================================================

subtest 'supported_languages() list context: defined, truthy, correct content' => sub {
	plan tests => 5;

	my $obj   = Genealogy::Relationship::Name->new();
	my @langs = $obj->supported_languages();

	# Kills RETURN_UNDEF: an undef list assignment would give 0 elements
	ok(scalar @langs > 0, 'supported_languages() list is non-empty');

	# Kills BOOL_NEGATE: a negated wantarray would return arrayref in list ctx
	ok(!ref $langs[0], 'First element is a plain scalar, not a ref');

	# Exact content assertions kill value-substitution mutants
	ok(defined $langs[0], 'First language is defined');
	is(scalar @langs, 3, 'Exactly three supported languages');
	is_deeply([sort @langs], [qw(de en fr)], 'Languages are de, en, fr');
};

subtest 'supported_languages() scalar context: defined arrayref with content' => sub {
	plan tests => 4;

	my $obj = Genealogy::Relationship::Name->new();
	my $ref = $obj->supported_languages();

	# Kills RETURN_UNDEF
	ok(defined $ref, 'supported_languages() scalar returns defined');

	# Kills BOOL_NEGATE: negated wantarray would return list (odd number of
	# elements assigned to scalar = last element or count)
	isa_ok($ref, 'ARRAY');

	# Exact content
	is(scalar @{$ref}, 3, 'Arrayref has 3 elements');
	is_deeply([sort @{$ref}], [qw(de en fr)], 'Arrayref content is de, en, fr');
};

# =========================================================================
# BOOL_NEGATE_601_2 / RETURN_UNDEF_601_2
# Source: return wantarray ? @sexes : \@sexes;   in known_sexes()
# Kill: same strategy as supported_languages()
# =========================================================================

subtest 'known_sexes() list context: defined, truthy, correct content' => sub {
	plan tests => 4;

	my $obj   = Genealogy::Relationship::Name->new();
	my @sexes = $obj->known_sexes();

	# Kills RETURN_UNDEF
	ok(scalar @sexes > 0, 'known_sexes() list is non-empty');

	# Kills BOOL_NEGATE (negated wantarray returns ref, not list)
	ok(!ref $sexes[0], 'First element is a plain scalar, not a ref');

	# Exact content
	is(scalar @sexes, 2, 'Exactly two sex codes');
	is_deeply([sort @sexes], [qw(F M)], 'Sex codes are F and M');
};

subtest 'known_sexes() scalar context: defined arrayref with content' => sub {
	plan tests => 4;

	my $obj = Genealogy::Relationship::Name->new();
	my $ref = $obj->known_sexes();

	# Kills RETURN_UNDEF
	ok(defined $ref, 'known_sexes() scalar returns defined');

	# Kills BOOL_NEGATE
	isa_ok($ref, 'ARRAY');

	# Exact content
	is(scalar @{$ref}, 2, 'Arrayref has 2 elements');
	is_deeply([sort @{$ref}], [qw(F M)], 'Arrayref content is F and M');
};

done_testing();

#!/usr/bin/env perl

# unit.t - black-box tests for public API of Genealogy::Relationship::Name
# Tests are strictly driven by the POD API documentation.
# Non-core dependencies outside this module are mocked via Test::Mockingbird.

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird;

use Log::Abstraction;
use lib 'lib', '../lib';

BEGIN {
	use_ok('Genealogy::Relationship::Name')
		or BAIL_OUT('Cannot load Genealogy::Relationship::Name');
}

# =========================================================================
# new()
# =========================================================================

subtest 'new() contract' => sub {
	plan tests => 4;

	# No-arg construction
	my $obj = new_ok('Genealogy::Relationship::Name');

	# Returns blessed ref
	isa_ok($obj, 'Genealogy::Relationship::Name');

	# With language default
	my $obj_de = Genealogy::Relationship::Name->new(language => 'de');
	isa_ok($obj_de, 'Genealogy::Relationship::Name');
	is($obj_de->{language}, 'de', 'de default stored');
};

# =========================================================================
# name() – return type contract
# =========================================================================

subtest 'name() returns a string for known keys' => sub {
	plan tests => 3;

	my $namer = Genealogy::Relationship::Name->new();

	my $r = $namer->name(steps_to_ancestor => 1, steps_from_ancestor => 0, sex => 'M');
	ok(defined $r, 'Returns defined value for known key');
	ok(length($r) > 0, 'Returns non-empty string');
	ok(!ref($r), 'Returns a plain scalar, not a ref');
};

subtest 'name() returns undef for unknown keys' => sub {
	plan tests => 1;

	my $namer = Genealogy::Relationship::Name->new();
	my $r = $namer->name(steps_to_ancestor => 99, steps_from_ancestor => 99, sex => 'F');
	is($r, undef, 'Returns undef for deeply unknown combination');
};

# =========================================================================
# name() – English coverage table
# =========================================================================

subtest 'name() English – exhaustive known-key checks' => sub {
	my $namer = Genealogy::Relationship::Name->new();

	# [ steps_to, steps_from, sex, expected ]
	my @cases = (
		[0, 0, 'M', 'self'],
		[0, 0, 'F', 'self'],
		[0, 1, 'M', 'son'],
		[0, 1, 'F', 'daughter'],
		[0, 2, 'M', 'grandson'],
		[0, 2, 'F', 'granddaughter'],
		[0, 3, 'M', 'great-grandson'],
		[0, 3, 'F', 'great-granddaughter'],
		[0, 4, 'M', 'great-great-grandson'],
		[0, 4, 'F', 'great-great-granddaughter'],
		[1, 0, 'M', 'father'],
		[1, 0, 'F', 'mother'],
		[1, 1, 'M', 'brother'],
		[1, 1, 'F', 'sister'],
		[1, 2, 'M', 'nephew'],
		[1, 2, 'F', 'niece'],
		[1, 3, 'M', 'great-nephew'],
		[1, 3, 'F', 'great-niece'],
		[2, 0, 'M', 'grandfather'],
		[2, 0, 'F', 'grandmother'],
		[2, 1, 'M', 'uncle'],
		[2, 1, 'F', 'aunt'],
		[2, 2, 'M', 'first cousin'],
		[2, 2, 'F', 'first cousin'],
		[2, 3, 'M', 'first cousin once-removed'],
		[2, 3, 'F', 'first cousin once-removed'],
		[2, 4, 'M', 'first cousin twice-removed'],
		[3, 0, 'M', 'great-grandfather'],
		[3, 0, 'F', 'great-grandmother'],
		[3, 1, 'M', 'great-uncle'],
		[3, 1, 'F', 'great-aunt'],
		[3, 2, 'M', 'first cousin once-removed'],
		[3, 3, 'M', 'second cousin'],
		[3, 3, 'F', 'second cousin'],
		[3, 4, 'M', 'second cousin once-removed'],
		[4, 0, 'M', 'great-great-grandfather'],
		[4, 0, 'F', 'great-great-grandmother'],
		[4, 4, 'M', 'third cousin'],
		[5, 5, 'M', 'fourth cousin'],
		[6, 6, 'M', 'fifth cousin'],
	);

	plan tests => scalar @cases;

	for my $c (@cases) {
		my($s1, $s2, $sex, $want) = @{$c};
		my $got = $namer->name(steps_to_ancestor => $s1, steps_from_ancestor => $s2, sex => $sex);
		is($got, $want, "en ${s1},${s2} ${sex} => $want");
	}
};

# =========================================================================
# name() – French coverage
# =========================================================================

subtest 'name() French – key spot-checks' => sub {
	plan tests => 8;

	my $namer = Genealogy::Relationship::Name->new();

	my @cases = (
		[0, 1, 'M', 'fr', 'fils'],
		[0, 1, 'F', 'fr', 'fille'],
		[1, 0, 'M', 'fr', 'pere'],
		[1, 0, 'F', 'fr', 'mere'],
		[1, 1, 'M', 'fr', 'frere'],
		[1, 1, 'F', 'fr', 'soeur'],
		[2, 2, 'M', 'fr', 'cousin germain'],
		[2, 2, 'F', 'fr', 'cousine germaine'],
	);

	for my $c (@cases) {
		my($s1, $s2, $sex, $lang, $want) = @{$c};
		is($namer->name(steps_to_ancestor => $s1, steps_from_ancestor => $s2,
		                sex => $sex, language => $lang),
			$want, "fr ${s1},${s2} ${sex} => $want");
	}
};

# =========================================================================
# name() – German coverage
# =========================================================================

subtest 'name() German – key spot-checks' => sub {
	plan tests => 8;

	my $namer = Genealogy::Relationship::Name->new();

	my @cases = (
		[0, 1, 'M', 'de', 'Sohn'],
		[0, 1, 'F', 'de', 'Tochter'],
		[1, 0, 'M', 'de', 'Vater'],
		[1, 0, 'F', 'de', 'Mutter'],
		[1, 1, 'M', 'de', 'Bruder'],
		[1, 1, 'F', 'de', 'Schwester'],
		[2, 2, 'M', 'de', 'Cousin'],
		[2, 2, 'F', 'de', 'Cousine'],
	);

	for my $c (@cases) {
		my($s1, $s2, $sex, $lang, $want) = @{$c};
		is($namer->name(steps_to_ancestor => $s1, steps_from_ancestor => $s2,
		                sex => $sex, language => $lang),
			$want, "de ${s1},${s2} ${sex} => $want");
	}
};

# =========================================================================
# name() – language override precedence
# =========================================================================

subtest 'name() per-call language overrides constructor default' => sub {
	plan tests => 3;

	my $namer = Genealogy::Relationship::Name->new(language => 'de');

	# No per-call language → uses 'de' default
	is($namer->name(steps_to_ancestor => 0, steps_from_ancestor => 1, sex => 'M'),
		'Sohn', 'de default used when no per-call language');

	# Per-call 'en' overrides 'de' default
	is($namer->name(steps_to_ancestor => 0, steps_from_ancestor => 1, sex => 'M', language => 'en'),
		'son', 'en per-call overrides de default');

	# Per-call 'fr' overrides 'de' default
	is($namer->name(steps_to_ancestor => 0, steps_from_ancestor => 1, sex => 'M', language => 'fr'),
		'fils', 'fr per-call overrides de default');
};

# =========================================================================
# name() – language subtag stripping
# =========================================================================

subtest 'name() strips region subtag' => sub {
	plan tests => 3;

	my $namer = Genealogy::Relationship::Name->new();

	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 1, sex => 'M', language => 'en-GB'),
		'brother', 'en-GB -> en');
	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 1, sex => 'M', language => 'en-US'),
		'brother', 'en-US -> en');
	is($namer->name(steps_to_ancestor => 0, steps_from_ancestor => 1, sex => 'F', language => 'fr-FR'),
		'fille', 'fr-FR -> fr');
};

# =========================================================================
# supported_languages()
# =========================================================================

subtest 'supported_languages() list context' => sub {
	plan tests => 5;

	my $namer = Genealogy::Relationship::Name->new();
	my @langs = $namer->supported_languages();

	ok(@langs >= 3, 'At least three languages');
	ok((grep { $_ eq 'en' } @langs), 'en present');
	ok((grep { $_ eq 'fr' } @langs), 'fr present');
	ok((grep { $_ eq 'de' } @langs), 'de present');

	# Result should be sorted
	my @sorted = sort @langs;
	is_deeply(\@langs, \@sorted, 'List is sorted');
};

subtest 'supported_languages() scalar context' => sub {
	plan tests => 2;

	my $namer = Genealogy::Relationship::Name->new();
	my $ref   = $namer->supported_languages();

	isa_ok($ref, 'ARRAY');
	is(scalar @{$ref}, 3, 'Arrayref contains 3 entries');
};

# =========================================================================
# known_sexes()
# =========================================================================

subtest 'known_sexes() list context' => sub {
	plan tests => 3;

	my $namer  = Genealogy::Relationship::Name->new();
	my @sexes  = $namer->known_sexes();

	is(scalar @sexes, 2, 'Exactly two sex codes');
	ok((grep { $_ eq 'M' } @sexes), 'M present');
	ok((grep { $_ eq 'F' } @sexes), 'F present');
};

subtest 'known_sexes() scalar context' => sub {
	plan tests => 2;

	my $namer = Genealogy::Relationship::Name->new();
	my $ref   = $namer->known_sexes();

	isa_ok($ref, 'ARRAY');
	is(scalar @{$ref}, 2, 'Arrayref contains 2 entries');
};


# =========================================================================
# logger: black-box contract tests
# =========================================================================

subtest 'new() accepts Log::Abstraction logger object' => sub {
	plan tests => 2;

	my $la    = Log::Abstraction->new(logger => sub {});
	my $namer = Genealogy::Relationship::Name->new(logger => $la);
	ok(defined $namer, 'new() with logger returns defined object');
	isa_ok($namer, 'Genealogy::Relationship::Name');
};

subtest 'croak on missing arg' => sub {
	plan tests => 2;

	my $namer = new_ok('Genealogy::Relationship::Name');
	my $fake = bless {}, 'SomePerson';

	# Passing undef is distinct from not passing the arg at all;
	# validate_strict accepts it (type=integer allows undef=not given),
	# but the // croak guard fires on extraction
	throws_ok {
		$namer->name(
			steps_to_ancestor   => undef,
			steps_from_ancestor => 1,
			sex                 => 'M',
			person              => $fake,
		)
	} qr/steps_to_ancestor not given/, 'undef steps_to_ancestor is caught by // croak';
};

subtest 'person arg accepted by name() without on_error' => sub {
	plan tests => 1;

	# person is optional and silently ignored when no on_error is set
	# and no error occurs
	my $namer = Genealogy::Relationship::Name->new();
	my $fake  = bless {}, 'SomePerson';
	my $result = $namer->name(
		steps_to_ancestor   => 1,
		steps_from_ancestor => 1,
		sex                 => 'M',
		person              => $fake,
	);
	is($result, 'brother', 'person arg ignored on success, correct result returned');
};


# =========================================================================
# logger: Log::Abstraction object black-box contract tests
# =========================================================================

subtest 'new() accepts a Log::Abstraction logger object' => sub {
	plan tests => 2;

	my $la    = Log::Abstraction->new(logger => sub {});
	my $namer = Genealogy::Relationship::Name->new(logger => $la);
	ok(defined $namer, 'new() with Log::Abstraction logger returns defined');
	isa_ok($namer, 'Genealogy::Relationship::Name');
};

subtest 'validate_strict croaks; neither logger nor on_error is invoked' => sub {
	plan tests => 3;

	my (@logger_calls, @error_calls);
	my $la = Log::Abstraction->new(logger => sub { push @logger_calls, shift });
	my $namer = Genealogy::Relationship::Name->new(
		logger   => $la,
		on_error => sub { push @error_calls, {@_} },
	);

	# validate_strict croaks directly
	eval { $namer->name(steps_to_ancestor => undef, steps_from_ancestor => 1, sex => 'M') };
	ok($@, 'validate_strict croaked');
	is(scalar @logger_calls, 1, 'logger invoked — validate_strict first');
	is(scalar @error_calls,  0, 'on_error not invoked — validate_strict croaked first');
};

subtest 'Log::Abstraction object stored correctly by new()' => sub {
	plan tests => 2;

	my $la    = Log::Abstraction->new(logger => sub {});
	my $namer = Genealogy::Relationship::Name->new(logger => $la);

	ok(defined $namer->{logger}, 'logger key present on object');
	isa_ok($namer->{logger}, 'Log::Abstraction');
};

done_testing();

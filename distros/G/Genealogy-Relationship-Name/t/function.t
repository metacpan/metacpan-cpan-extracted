#!/usr/bin/env perl

# function.t - white-box unit tests for Genealogy::Relationship::Name
# Tests each function individually, mocking non-core dependencies.
# Uses Test::Mockingbird for mocking.

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird;

# Add lib path so we can load from the distribution tree
use Log::Abstraction;
use lib 'lib', '../lib';

# -------------------------------------------------------------------------
# 1. Load the module
# -------------------------------------------------------------------------

BEGIN {
	use_ok('Genealogy::Relationship::Name')
		or BAIL_OUT('Cannot load Genealogy::Relationship::Name');
}

# -------------------------------------------------------------------------
# 2. Constructor: new()
# -------------------------------------------------------------------------

subtest 'new() returns a blessed object' => sub {
	plan tests => 3;

	# Basic construction
	my $namer = new_ok('Genealogy::Relationship::Name');

	# Object is a hash-based blessed ref
	isa_ok($namer, 'Genealogy::Relationship::Name');

	# Constructor accepts language kwarg and stores it
	my $namer_fr = Genealogy::Relationship::Name->new(language => 'fr');
	is($namer_fr->{language}, 'fr', 'language stored in object');
};

# -------------------------------------------------------------------------
# 3. name() – happy path, English male
# -------------------------------------------------------------------------

subtest 'name() English male relationships' => sub {
	plan tests => 10;

	my $namer = Genealogy::Relationship::Name->new();

	# Direct-line relationships
	is($namer->name(steps_to_ancestor => 0, steps_from_ancestor => 1, sex => 'M'),
		'son',    '0,1 M => son');
	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 0, sex => 'M'),
		'father', '1,0 M => father');
	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 0, sex => 'M'),
		'grandfather', '2,0 M => grandfather');
	is($namer->name(steps_to_ancestor => 0, steps_from_ancestor => 2, sex => 'M'),
		'grandson', '0,2 M => grandson');

	# Sibling
	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 1, sex => 'M'),
		'brother', '1,1 M => brother');

	# First cousin
	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 2, sex => 'M'),
		'first cousin', '2,2 M => first cousin');

	# First cousin once-removed
	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 3, sex => 'M'),
		'first cousin once-removed', '2,3 M => first cousin once-removed');

	# Second cousin
	is($namer->name(steps_to_ancestor => 3, steps_from_ancestor => 3, sex => 'M'),
		'second cousin', '3,3 M => second cousin');

	# Uncle / great-uncle
	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 1, sex => 'M'),
		'uncle', '2,1 M => uncle');
	is($namer->name(steps_to_ancestor => 3, steps_from_ancestor => 1, sex => 'M'),
		'great-uncle', '3,1 M => great-uncle');
};

# -------------------------------------------------------------------------
# 4. name() – happy path, English female
# -------------------------------------------------------------------------

subtest 'name() English female relationships' => sub {
	plan tests => 8;

	my $namer = Genealogy::Relationship::Name->new();

	is($namer->name(steps_to_ancestor => 0, steps_from_ancestor => 1, sex => 'F'),
		'daughter', '0,1 F => daughter');
	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 0, sex => 'F'),
		'mother', '1,0 F => mother');
	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 0, sex => 'F'),
		'grandmother', '2,0 F => grandmother');
	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 1, sex => 'F'),
		'sister', '1,1 F => sister');
	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 1, sex => 'F'),
		'aunt', '2,1 F => aunt');
	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 2, sex => 'F'),
		'first cousin', '2,2 F => first cousin');
	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 2, sex => 'F'),
		'niece', '1,2 F => niece');
	is($namer->name(steps_to_ancestor => 3, steps_from_ancestor => 1, sex => 'F'),
		'great-aunt', '3,1 F => great-aunt');
};

# -------------------------------------------------------------------------
# 5. name() – French relationships
# -------------------------------------------------------------------------

subtest 'name() French relationships' => sub {
	plan tests => 6;

	my $namer = Genealogy::Relationship::Name->new();

	is($namer->name(steps_to_ancestor => 0, steps_from_ancestor => 1, sex => 'M', language => 'fr'),
		'fils', 'fr 0,1 M => fils');
	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 0, sex => 'F', language => 'fr'),
		'mere', 'fr 1,0 F => mere');
	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 2, sex => 'M', language => 'fr'),
		'cousin germain', 'fr 2,2 M => cousin germain');
	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 2, sex => 'F', language => 'fr'),
		'cousine germaine', 'fr 2,2 F => cousine germaine');
	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 0, sex => 'F', language => 'fr'),
		'grand-mere', 'fr 2,0 F => grand-mere');
	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 1, sex => 'M', language => 'fr'),
		'oncle', 'fr 2,1 M => oncle');
};

# -------------------------------------------------------------------------
# 6. name() – German relationships
# -------------------------------------------------------------------------

subtest 'name() German relationships' => sub {
	plan tests => 6;

	my $namer = Genealogy::Relationship::Name->new();

	is($namer->name(steps_to_ancestor => 0, steps_from_ancestor => 1, sex => 'M', language => 'de'),
		'Sohn', 'de 0,1 M => Sohn');
	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 0, sex => 'F', language => 'de'),
		'Mutter', 'de 1,0 F => Mutter');
	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 1, sex => 'M', language => 'de'),
		'Bruder', 'de 1,1 M => Bruder');
	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 1, sex => 'F', language => 'de'),
		'Schwester', 'de 1,1 F => Schwester');
	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 1, sex => 'F', language => 'de'),
		'Tante', 'de 2,1 F => Tante');
	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 2, sex => 'M', language => 'de'),
		'Cousin', 'de 2,2 M => Cousin');
};

# -------------------------------------------------------------------------
# 7. name() – default language from constructor
# -------------------------------------------------------------------------

subtest 'name() uses constructor-level default language' => sub {
	plan tests => 2;

	# Object constructed with French as default
	my $namer_fr = Genealogy::Relationship::Name->new(language => 'fr');

	is($namer_fr->name(steps_to_ancestor => 0, steps_from_ancestor => 1, sex => 'M'),
		'fils', 'Constructor language=fr used when no per-call language given');

	# Per-call language overrides constructor default
	is($namer_fr->name(steps_to_ancestor => 0, steps_from_ancestor => 1, sex => 'M', language => 'en'),
		'son', 'Per-call language overrides constructor default');
};

# -------------------------------------------------------------------------
# 8. name() – unknown key returns undef
# -------------------------------------------------------------------------

subtest 'name() returns undef for unknown step combination' => sub {
	plan tests => 2;

	my $namer = Genealogy::Relationship::Name->new();

	# A combination not in the table
	my $result = $namer->name(steps_to_ancestor => 9, steps_from_ancestor => 9, sex => 'M');
	is($result, undef, 'Very large step count returns undef');

	# Asymmetric combination not tabulated
	my $result2 = $namer->name(steps_to_ancestor => 6, steps_from_ancestor => 1, sex => 'F');
	is($result2, undef, '6,1 not in table => undef');
};

# -------------------------------------------------------------------------
# 9. name() – language region subtag is stripped
# -------------------------------------------------------------------------

subtest 'name() strips region subtag from language' => sub {
	plan tests => 1;

	my $namer = Genealogy::Relationship::Name->new();

	# 'en-GB' should work the same as 'en'
	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 1, sex => 'M', language => 'en-GB'),
		'brother', 'en-GB stripped to en');
};

# -------------------------------------------------------------------------
# 10. name() – unsupported language croaks via validate_strict
# -------------------------------------------------------------------------

subtest 'name() croaks for unsupported language' => sub {
	plan tests => 2;

	my $namer = new_ok('Genealogy::Relationship::Name');

	throws_ok {
		$namer->name(steps_to_ancestor => 1, steps_from_ancestor => 1,
		             sex => 'M', language => 'xx');
	} qr/must match pattern/, 'Croak for unsupported language';
};

# -------------------------------------------------------------------------
# 11. supported_languages()
# -------------------------------------------------------------------------

subtest 'supported_languages() list context' => sub {
	plan tests => 4;

	my $namer = Genealogy::Relationship::Name->new();
	my @langs = $namer->supported_languages();

	is(scalar @langs, 3, 'Three supported languages');
	ok((grep { $_ eq 'en' } @langs), 'en is in list');
	ok((grep { $_ eq 'fr' } @langs), 'fr is in list');
	ok((grep { $_ eq 'de' } @langs), 'de is in list');
};

subtest 'supported_languages() scalar context returns arrayref' => sub {
	plan tests => 2;

	my $namer  = Genealogy::Relationship::Name->new();
	my $ref    = $namer->supported_languages();

	ok(ref $ref eq 'ARRAY', 'Scalar context returns ARRAY ref');
	is(scalar @{$ref}, 3, 'Arrayref has 3 elements');
};

# -------------------------------------------------------------------------
# 12. known_sexes()
# -------------------------------------------------------------------------

subtest 'known_sexes() returns F and M' => sub {
	plan tests => 3;

	my $namer = Genealogy::Relationship::Name->new();
	my @sexes = $namer->known_sexes();

	is(scalar @sexes, 2, 'Two sex codes');
	ok((grep { $_ eq 'M' } @sexes), 'M in list');
	ok((grep { $_ eq 'F' } @sexes), 'F in list');
};

subtest 'known_sexes() scalar context returns arrayref' => sub {
	plan tests => 1;

	my $namer = Genealogy::Relationship::Name->new();
	my $ref   = $namer->known_sexes();
	ok(ref $ref eq 'ARRAY', 'Scalar context => ARRAY ref');
};

# -------------------------------------------------------------------------
# 13. name() – self-referential 0,0 case
# -------------------------------------------------------------------------

subtest 'name() handles 0,0 self case' => sub {
	plan tests => 2;

	my $namer = Genealogy::Relationship::Name->new();

	is($namer->name(steps_to_ancestor => 0, steps_from_ancestor => 0, sex => 'M'),
		'self', '0,0 M => self');
	is($namer->name(steps_to_ancestor => 0, steps_from_ancestor => 0, sex => 'F'),
		'self', '0,0 F => self');
};

# -------------------------------------------------------------------------
# 14. name() – great-grandparent / great-grandchild
# -------------------------------------------------------------------------

subtest 'name() multi-great relationships' => sub {
	plan tests => 4;

	my $namer = Genealogy::Relationship::Name->new();

	is($namer->name(steps_to_ancestor => 3, steps_from_ancestor => 0, sex => 'M'),
		'great-grandfather', '3,0 M => great-grandfather');
	is($namer->name(steps_to_ancestor => 4, steps_from_ancestor => 0, sex => 'F'),
		'great-great-grandmother', '4,0 F => great-great-grandmother');
	is($namer->name(steps_to_ancestor => 0, steps_from_ancestor => 3, sex => 'M'),
		'great-grandson', '0,3 M => great-grandson');
	is($namer->name(steps_to_ancestor => 0, steps_from_ancestor => 4, sex => 'F'),
		'great-great-granddaughter', '0,4 F => great-great-granddaughter');
};




# -------------------------------------------------------------------------
# 16. Log::Abstraction object stored correctly in new()
# -------------------------------------------------------------------------

subtest 'new() stores Log::Abstraction object as logger' => sub {
	plan tests => 3;

	my $la    = Log::Abstraction->new(logger => sub {});
	my $namer = Genealogy::Relationship::Name->new(logger => $la);

	isa_ok($namer, 'Genealogy::Relationship::Name');
	ok(defined $namer->{logger}, 'logger stored on object');
	isa_ok($namer->{logger}, 'Log::Abstraction');
};

# -------------------------------------------------------------------------
# 17. undef args: logger invoked if set, croak otherwise
# -------------------------------------------------------------------------

subtest 'undef arg: logger invoked when set' => sub {
	plan tests => 2;

	my @log_calls;
	my $la = Log::Abstraction->new(logger => sub { push @log_calls, shift });
	my $namer = Genealogy::Relationship::Name->new(logger => $la);

	eval { $namer->name(steps_to_ancestor => undef, steps_from_ancestor => 1, sex => 'M') };
	is(scalar @log_calls, 1, 'logger called for undef arg');
	like(join('', @{$log_calls[0]{message}}), qr/steps_to_ancestor not given/, 'correct message');
};

# -------------------------------------------------------------------------
# 18. Log::Abstraction object stored correctly in new()
# -------------------------------------------------------------------------

subtest 'new() stores Log::Abstraction object as logger' => sub {
	plan tests => 3;

	my $la    = Log::Abstraction->new(logger => sub {});
	my $namer = Genealogy::Relationship::Name->new(logger => $la);

	isa_ok($namer, 'Genealogy::Relationship::Name');
	ok(defined $namer->{logger}, 'logger stored on object');
	isa_ok($namer->{logger}, 'Log::Abstraction');
};

done_testing();

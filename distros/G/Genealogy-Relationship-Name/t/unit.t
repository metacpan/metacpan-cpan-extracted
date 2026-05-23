#!/usr/bin/env perl

# unit.t - black-box tests for public API of Genealogy::Relationship::Name
# Tests are strictly driven by the POD API documentation.

use utf8;
use open ':std', ':encoding(UTF-8)'; # Tells Perl to output UTF-8 to the terminal
use strict;
use warnings;

use Test::Most;

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
# name() - return type contract
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
# name() - English coverage table
# =========================================================================

subtest 'name() English - exhaustive known-key checks' => sub {
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
# name() - French coverage
# =========================================================================

subtest 'name() French - key spot-checks' => sub {
	plan tests => 8;

	my $namer = Genealogy::Relationship::Name->new();

	my @cases = (
		[0, 1, 'M', 'fr', 'fils'],
		[0, 1, 'F', 'fr', 'fille'],
		[1, 0, 'M', 'fr', 'pere'],
		[1, 0, 'F', 'fr', 'mere'],
		[1, 1, 'M', 'fr', "fr\N{U+00E8}re"],
		[1, 1, 'F', 'fr', "s\N{U+0153}ur"],
		[2, 2, 'M', 'fr', 'cousin germain'],
		[2, 2, 'F', 'fr', 'cousine germaine'],
	);

	for my $c (@cases) {
		my($s1, $s2, $sex, $lang, $want) = @{$c};
		is($namer->name(steps_to_ancestor => $s1, steps_from_ancestor => $s2, sex => $sex, language => $lang),
			$want, "fr ${s1},${s2} ${sex} => $want");
	}
};

# =========================================================================
# name() - German coverage
# =========================================================================

subtest 'name() German - key spot-checks' => sub {
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
# name() - language override precedence
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
# name() - language subtag stripping
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
	is(scalar @{$ref}, 7, 'Arrayref contains 7 entries');
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

	# undef steps_to_ancestor: validate_strict passes it through (undef ok for integer type),
	# then the foreach guard fires and calls $logger->error()
	eval { $namer->name(steps_to_ancestor => undef, steps_from_ancestor => 1, sex => 'M') };
	is(scalar @logger_calls, 1, 'logger invoked for undef arg');
	is(scalar @error_calls,  0, 'on_error not invoked when logger set');
	ok($@, 'croak even when logger handles the error');
};

subtest 'Log::Abstraction object stored correctly by new()' => sub {
	plan tests => 2;

	my $la    = Log::Abstraction->new(logger => sub {});
	my $namer = Genealogy::Relationship::Name->new(logger => $la);

	ok(defined $namer->{logger}, 'logger key present on object');
	isa_ok($namer->{logger}, 'Log::Abstraction');
};

# =========================================================================
# name() - Spanish coverage
# =========================================================================

subtest 'name() Spanish - key spot-checks' => sub {
	plan tests => 10;

	my $namer = Genealogy::Relationship::Name->new();

	my @cases = (
		[0, 1, 'M', 'es', 'hijo'],
		[0, 1, 'F', 'es', 'hija'],
		[1, 0, 'M', 'es', 'padre'],
		[1, 0, 'F', 'es', 'madre'],
		[1, 1, 'M', 'es', 'hermano'],
		[1, 1, 'F', 'es', 'hermana'],
		[2, 1, 'M', 'es', 'tio'],
		[2, 1, 'F', 'es', 'tia'],
		[2, 2, 'M', 'es', 'primo hermano'],
		[2, 2, 'F', 'es', 'prima hermana'],
	);

	for my $c (@cases) {
		my($s1, $s2, $sex, $lang, $want) = @{$c};
		is($namer->name(steps_to_ancestor => $s1, steps_from_ancestor => $s2,
		                sex => $sex, language => $lang),
			$want, "es ${s1},${s2} ${sex} => $want");
	}
};

subtest 'name() Spanish - extended cousin terms' => sub {
	plan tests => 4;

	my $namer = Genealogy::Relationship::Name->new();

	is($namer->name(steps_to_ancestor => 3, steps_from_ancestor => 3, sex => 'M', language => 'es'),
		'primo segundo', 'es 3,3 M => primo segundo');
	is($namer->name(steps_to_ancestor => 3, steps_from_ancestor => 3, sex => 'F', language => 'es'),
		'prima segunda', 'es 3,3 F => prima segunda');
	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 3, sex => 'M', language => 'es'),
		'primo hermano una vez removido', 'es 2,3 M removed');
	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 3, sex => 'F', language => 'es'),
		'prima hermana una vez removida', 'es 2,3 F removed');
};

# =========================================================================
# name() - Farsi coverage
# =========================================================================

subtest 'name() Farsi - key spot-checks (Unicode escapes)' => sub {
	plan tests => 6;

	my $namer = Genealogy::Relationship::Name->new();

	# Father: \N{U+067E}\N{U+062F}\N{U+0631} = پدر
	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 0, sex => 'M', language => 'fa'),
		"\N{U+067E}\N{U+062F}\N{U+0631}", 'fa 1,0 M => pdar');

	# Mother: مادر
	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 0, sex => 'F', language => 'fa'),
		"\N{U+0645}\N{U+0627}\N{U+062F}\N{U+0631}", 'fa 1,0 F => madar');

	# Brother: برادر
	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 1, sex => 'M', language => 'fa'),
		"\N{U+0628}\N{U+0631}\N{U+0627}\N{U+062F}\N{U+0631}", 'fa 1,1 M => baradar');

	# Sister: خواهر
	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 1, sex => 'F', language => 'fa'),
		"\N{U+062E}\N{U+0648}\N{U+0627}\N{U+0647}\N{U+0631}", 'fa 1,1 F => khwahar');

	# Son: پسر
	is($namer->name(steps_to_ancestor => 0, steps_from_ancestor => 1, sex => 'M', language => 'fa'),
		"\N{U+067E}\N{U+0633}\N{U+0631}", 'fa 0,1 M => pesar');

	# Daughter: دختر
	is($namer->name(steps_to_ancestor => 0, steps_from_ancestor => 1, sex => 'F', language => 'fa'),
		"\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}", 'fa 0,1 F => dokhtar');
};

subtest 'name() Farsi - family_side for uncle/aunt' => sub {
	plan tests => 4;

	my $namer = Genealogy::Relationship::Name->new();

	# Paternal uncle: عمو amoo
	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 1, sex => 'M',
	                language => 'fa', family_side => 'paternal'),
		"\N{U+0639}\N{U+0645}\N{U+0648}", 'fa 2,1 M paternal => amoo');

	# Maternal uncle: دایی dayi
	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 1, sex => 'M',
	                language => 'fa', family_side => 'maternal'),
		"\N{U+062F}\N{U+0627}\N{U+06CC}\N{U+06CC}", 'fa 2,1 M maternal => dayi');

	# Paternal aunt: عمه ammeh
	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 1, sex => 'F',
	                language => 'fa', family_side => 'paternal'),
		"\N{U+0639}\N{U+0645}\N{U+0647}", 'fa 2,1 F paternal => ammeh');

	# Maternal aunt: خاله khaleh
	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 1, sex => 'F',
	                language => 'fa', family_side => 'maternal'),
		"\N{U+062E}\N{U+0627}\N{U+0644}\N{U+0647}", 'fa 2,1 F maternal => khaleh');
};

subtest 'name() Farsi - family_side fallback without side' => sub {
	plan tests => 2;

	my $namer = Genealogy::Relationship::Name->new();

	# Without family_side, falls back to generic (paternal default)
	my $uncle = $namer->name(steps_to_ancestor => 2, steps_from_ancestor => 1,
	                          sex => 'M', language => 'fa');
	ok(defined $uncle, 'fa uncle without family_side returns defined');
	is($uncle, "\N{U+0639}\N{U+0645}\N{U+0648}", 'fa uncle generic fallback => amoo');
};

# =========================================================================
# name() - Classical Latin coverage
# =========================================================================

subtest 'name() Latin - direct line and siblings' => sub {
	plan tests => 8;

	my $namer = Genealogy::Relationship::Name->new();

	my @cases = (
		[0, 1, 'M', 'la', 'filius'],
		[0, 1, 'F', 'la', 'filia'],
		[1, 0, 'M', 'la', 'pater'],
		[1, 0, 'F', 'la', 'mater'],
		[1, 1, 'M', 'la', 'frater'],
		[1, 1, 'F', 'la', 'soror'],
		[2, 0, 'M', 'la', 'avus'],
		[2, 0, 'F', 'la', 'avia'],
	);

	for my $c (@cases) {
		my($s1, $s2, $sex, $lang, $want) = @{$c};
		is($namer->name(steps_to_ancestor => $s1, steps_from_ancestor => $s2,
		                sex => $sex, language => $lang),
			$want, "la ${s1},${s2} ${sex} => $want");
	}
};

subtest 'name() Latin - ancestors' => sub {
	plan tests => 6;

	my $namer = Genealogy::Relationship::Name->new();

	my @cases = (
		[3, 0, 'M', 'proavus'],
		[3, 0, 'F', 'proavia'],
		[4, 0, 'M', 'abavus'],
		[5, 0, 'M', 'atavus'],
		[5, 0, 'F', 'atavia'],
		[6, 0, 'M', 'tritavus'],
	);

	for my $c (@cases) {
		my($s1, $s2, $sex, $want) = @{$c};
		is($namer->name(steps_to_ancestor => $s1, steps_from_ancestor => $s2,
		                sex => $sex, language => 'la'),
			$want, "la ${s1},${s2} ${sex} => $want");
	}
};

subtest 'name() Latin - descendants' => sub {
	plan tests => 4;

	my $namer = Genealogy::Relationship::Name->new();

	my @cases = (
		[0, 2, 'M', 'nepos'],
		[0, 2, 'F', 'neptis'],
		[0, 3, 'M', 'pronepos'],
		[0, 4, 'F', 'abneptis'],
	);

	for my $c (@cases) {
		my($s1, $s2, $sex, $want) = @{$c};
		is($namer->name(steps_to_ancestor => $s1, steps_from_ancestor => $s2,
		                sex => $sex, language => 'la'),
			$want, "la ${s1},${s2} ${sex} => $want");
	}
};

subtest 'name() Latin - family_side uncle/aunt' => sub {
	plan tests => 6;

	my $namer = Genealogy::Relationship::Name->new();

	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 1, sex => 'M',
	                language => 'la', family_side => 'paternal'),
		'patruus', 'la 2,1 M paternal => patruus');

	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 1, sex => 'M',
	                language => 'la', family_side => 'maternal'),
		'avunculus', 'la 2,1 M maternal => avunculus');

	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 1, sex => 'F',
	                language => 'la', family_side => 'paternal'),
		'amita', 'la 2,1 F paternal => amita');

	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 1, sex => 'F',
	                language => 'la', family_side => 'maternal'),
		'matertera', 'la 2,1 F maternal => matertera');

	is($namer->name(steps_to_ancestor => 3, steps_from_ancestor => 1, sex => 'M',
	                language => 'la', family_side => 'paternal'),
		'patruus magnus', 'la 3,1 M paternal => patruus magnus');

	is($namer->name(steps_to_ancestor => 3, steps_from_ancestor => 1, sex => 'M',
	                language => 'la', family_side => 'maternal'),
		'avunculus magnus', 'la 3,1 M maternal => avunculus magnus');
};

subtest 'name() Latin - family_side cousin' => sub {
	plan tests => 3;

	my $namer = Genealogy::Relationship::Name->new();

	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 2, sex => 'M',
	                language => 'la', family_side => 'paternal'),
		'patruelis', 'la 2,2 M paternal => patruelis');

	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 2, sex => 'M',
	                language => 'la', family_side => 'maternal'),
		'consobrinus', 'la 2,2 M maternal => consobrinus');

	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 2, sex => 'F',
	                language => 'la', family_side => 'maternal'),
		'consobrina', 'la 2,2 F maternal => consobrina');
};

subtest 'name() Latin - sparse table returns undef for unknown combos' => sub {
	plan tests => 2;

	my $namer = Genealogy::Relationship::Name->new();

	# Latin has no classical term for 3rd cousin etc.
	is($namer->name(steps_to_ancestor => 4, steps_from_ancestor => 4, sex => 'M', language => 'la'),
		undef, 'la 4,4 M => undef (no classical term)');
	is($namer->name(steps_to_ancestor => 7, steps_from_ancestor => 7, sex => 'F', language => 'la'),
		undef, 'la 7,7 F => undef (no classical term)');
};

subtest 'name() Latin - family_side fallback to generic' => sub {
	plan tests => 1;

	my $namer = Genealogy::Relationship::Name->new();

	# Without family_side, fallback to generic (patruus for uncle)
	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 1,
	                sex => 'M', language => 'la'),
		'patruus', 'la uncle without family_side => patruus (generic fallback)');
};

# =========================================================================
# name() - Swiss German (de-CH) coverage
# =========================================================================

subtest 'name() Swiss German (de-CH) - uses ss not eszett' => sub {
	plan tests => 6;

	my $namer = Genealogy::Relationship::Name->new();

	# de-CH should give Grossvater (ss), not Gro\N{U+00DF}vater
	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 0, sex => 'M', language => 'de-CH'),
		'Grossvater', 'de-CH 2,0 M => Grossvater (ss)');
	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 0, sex => 'F', language => 'de-CH'),
		'Grossmutter', 'de-CH 2,0 F => Grossmutter (ss)');
	is($namer->name(steps_to_ancestor => 3, steps_from_ancestor => 1, sex => 'M', language => 'de-CH'),
		'Grossonkel', 'de-CH 3,1 M => Grossonkel (ss)');
	is($namer->name(steps_to_ancestor => 3, steps_from_ancestor => 1, sex => 'F', language => 'de-CH'),
		'Grosstante', 'de-CH 3,1 F => Grosstante (ss)');
	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 3, sex => 'M', language => 'de-CH'),
		'Grossneffe', 'de-CH 1,3 M => Grossneffe (ss)');
	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 3, sex => 'F', language => 'de-CH'),
		'Grossnichte', 'de-CH 1,3 F => Grossnichte (ss)');
};

# =========================================================================
# name() - Standard German eszett
# =========================================================================

subtest 'name() Standard German (de) - uses eszett not ss' => sub {
	plan tests => 6;

	my $namer = Genealogy::Relationship::Name->new();

	# Standard de should give Gro\N{U+00DF}vater, NOT Grossvater
	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 0, sex => 'M', language => 'de'),
		"Gro\N{U+00DF}vater", "de 2,0 M => Gro\N{U+00DF}vater (eszett)");
	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 0, sex => 'F', language => 'de'),
		"Gro\N{U+00DF}mutter", "de 2,0 F => Gro\N{U+00DF}mutter (eszett)");
	is($namer->name(steps_to_ancestor => 3, steps_from_ancestor => 1, sex => 'M', language => 'de'),
		"Gro\N{U+00DF}onkel", "de 3,1 M => Gro\N{U+00DF}onkel (eszett)");
	is($namer->name(steps_to_ancestor => 3, steps_from_ancestor => 1, sex => 'F', language => 'de'),
		"Gro\N{U+00DF}tante", "de 3,1 F => Gro\N{U+00DF}tante (eszett)");
	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 3, sex => 'M', language => 'de'),
		"Gro\N{U+00DF}neffe", "de 1,3 M => Gro\N{U+00DF}neffe (eszett)");

	# de-CH must differ from de for these terms
	isnt($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 0, sex => 'M', language => 'de'),
		$namer->name(steps_to_ancestor => 2, steps_from_ancestor => 0, sex => 'M', language => 'de-CH'),
		'de and de-CH give different strings for grandfather');
};

# =========================================================================
# name() - Extended table coverage (0-10)
# =========================================================================

subtest 'name() English - extended table 7-10 spot-checks' => sub {
	plan tests => 8;

	my $namer = Genealogy::Relationship::Name->new();

	is($namer->name(steps_to_ancestor => 7, steps_from_ancestor => 7, sex => 'M'),
		'sixth cousin', '7,7 M => sixth cousin');
	is($namer->name(steps_to_ancestor => 8, steps_from_ancestor => 8, sex => 'F'),
		'seventh cousin', '8,8 F => seventh cousin');
	is($namer->name(steps_to_ancestor => 9, steps_from_ancestor => 9, sex => 'M'),
		'eighth cousin', '9,9 M => eighth cousin');
	is($namer->name(steps_to_ancestor => 10, steps_from_ancestor => 10, sex => 'F'),
		'ninth cousin', '10,10 F => ninth cousin');
	is($namer->name(steps_to_ancestor => 0, steps_from_ancestor => 10, sex => 'M'),
		'great-great-great-great-great-great-great-great-grandson',
		'0,10 M => 8x great-grandson');
	is($namer->name(steps_to_ancestor => 10, steps_from_ancestor => 0, sex => 'F'),
		'great-great-great-great-great-great-great-great-grandmother',
		'10,0 F => 8x great-grandmother');
	is($namer->name(steps_to_ancestor => 5, steps_from_ancestor => 10, sex => 'M'),
		'fourth cousin five-times-removed', '5,10 M => fourth cousin five-times-removed');
	is($namer->name(steps_to_ancestor => 10, steps_from_ancestor => 3, sex => 'F'),
		'second cousin seven-times-removed', '10,3 F => second cousin seven-times-removed');
};

# =========================================================================
# name() - family_side fallback: non-Latin/Farsi language ignores it
# =========================================================================

subtest 'name() family_side ignored for languages without side-specific entries' => sub {
	plan tests => 2;

	my $namer = Genealogy::Relationship::Name->new();

	# English has no side-specific keys; family_side is silently ignored
	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 1, sex => 'M',
	                language => 'en', family_side => 'paternal'),
		'uncle', 'en uncle with family_side => uncle (ignored)');
	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 1, sex => 'M',
	                language => 'en', family_side => 'maternal'),
		'uncle', 'en uncle maternal family_side => same result');
};

# =========================================================================
# supported_languages() - all new languages present
# =========================================================================

subtest 'supported_languages() includes all new languages' => sub {
	plan tests => 5;

	my $namer = Genealogy::Relationship::Name->new();
	my @langs = $namer->supported_languages();

	for my $lang (qw(es fa la de_ch)) {
		ok((grep { $_ eq $lang } @langs), "$lang in supported_languages()");
	}

	is(scalar @langs, 7, 'Exactly 7 supported languages');
};


done_testing();

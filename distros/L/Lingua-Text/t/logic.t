#!/usr/bin/env perl
# t/logic.t -- Logical proof tests using equivalence partitioning.
#
# Each test case is the unique boundary representative of one equivalence class.
# Redundant tests for values within an already-proven partition are omitted.
#
# Structure mirrors the Z calculus invariant:
#   LinguaText.texts : LANG -> STRING   (partial function)
#
# Every subtest asserts:
#   Pre-condition (minor premise) + system invariant (major premise)
#     => Post-condition (conclusion / Z postcondition)

use strict;
use warnings;
use Test::Most;
use Test::Carp;

BEGIN {
	use_ok('Lingua::Text') or BAIL_OUT('Module failed to load -- all proofs invalid');
}

# ===========================================================================
# PARTITION 1 -- new()
# Major premise: new() always returns a blessed Lingua::Text object (or undef
# on misuse), and texts contains only validated ISO 639-1 keys.
# ===========================================================================
subtest 'new -- construction invariants' => sub {
	# EC1: function-style call, no args -- allowed; returns empty object
	# (Lingua::Text::new() with undef invocant assigns $class = __PACKAGE__)
	{
		my $t = Lingua::Text::new();
		isa_ok($t, 'Lingua::Text', 'EC1: function-style no-args returns object');
	}

	# EC2: method-style, no args -- canonical empty construction
	{
		local %ENV;
		my $t = Lingua::Text->new();
		isa_ok($t, 'Lingua::Text', 'EC2: method-style no-args returns empty object');
		ok(!defined($t->en()), 'EC2: empty object has no translations');
	}

	# EC3: flat key/value pairs
	{
		local %ENV;
		my $t = Lingua::Text->new(en => 'boat', fr => 'bateau');
		is($t->en(), 'boat',   'EC3: flat pair -- English stored');
		is($t->fr(), 'bateau', 'EC3: flat pair -- French stored');
	}

	# EC4: hashref argument (boundary: one HASHREF vs flat list)
	{
		local %ENV;
		my $t = Lingua::Text->new({ en => 'boat', fr => 'bateau' });
		is($t->en(), 'boat', 'EC4: hashref -- English stored');
	}

	# EC5: single scalar + locale set -- stored under locale lang
	{
		local %ENV;
		$ENV{LANG} = 'en_US.UTF-8';
		my $t = Lingua::Text->new('hello');
		is($t->en(), 'hello', 'EC5: single scalar + locale => stored under en');
	}

	# EC6: object invocant, no extra args -- shallow clone; texts hashref is SHARED
	# new() without extra params does: bless { %$self }, ref($self)
	# %$self spreads (texts => $ref) but does NOT deep-copy the inner hashref.
	# Consequence: AUTOLOAD mutations on either object are visible in both.
	{
		local %ENV;
		my $orig  = Lingua::Text->new(en => 'cat', fr => 'chat');
		my $clone = $orig->new();
		is($clone->en(), 'cat',  'EC6: shallow clone preserves en');
		is($clone->fr(), 'chat', 'EC6: shallow clone preserves fr');
		# Prove shared backing: mutating orig also mutates the clone
		$orig->en('kitten');
		is($clone->en(), 'kitten', 'EC6: shallow clone shares texts hashref with original');
	}

	# EC7: object invocant with extra pairs -- clone merges, new key wins
	{
		local %ENV;
		my $base = Lingua::Text->new(en => 'colour', fr => 'couleur');
		my $us   = $base->new(en => 'color');
		is($us->en(),   'color',   'EC7: override key replaced in clone');
		is($us->fr(),   'couleur', 'EC7: non-overridden key preserved in clone');
		is($base->en(), 'colour',  'EC7: original unchanged after clone');
	}

	# EC8: non-class invocant + args -- carp + undef
	# 'notaclass' is: defined, not a ref, not blessed, not isa Lingua::Text
	# => the guard "unless($is_object || $is_class)" fires and carp is issued.
	# Boundary: distinguishes a valid class name (no carp) from an arbitrary string.
	{
		local %ENV;
		my $result;
		does_carp_that_matches(
			sub { $result = Lingua::Text::new('notaclass', en => 'x') },
			'EC8: non-class string invocant triggers carp',
			qr/use ->new\(\)/,
		);
		ok(!defined($result), 'EC8: carp path returns undef');
	}
};

# ===========================================================================
# PARTITION 2 -- set()
# Major premise: set() stores exactly one lang->text pair under a validated
# ISO 639-1 key, or returns undef and carps/croaks on invalid input.
# ===========================================================================
subtest 'set -- state transition proofs' => sub {
	# EC1: no args at all -- croak (programmer error, not a runtime warning)
	{
		local %ENV;
		my $t = Lingua::Text->new();
		does_croak_that_matches(
			sub { $t->set() },
			'EC1: set() with no args croaks',
			qr/Usage/,
		);
	}

	# EC2: valid lang + defined text -- stored, $self returned
	{
		local %ENV;
		my $t = Lingua::Text->new();
		my $ret = $t->set(text => 'House', lang => 'en');
		isa_ok($ret, 'Lingua::Text', 'EC2: set() returns $self on success');
		is($t->en(), 'House', 'EC2: text was stored under the correct key');
	}

	# EC3: text is undef -- carp, nothing stored
	{
		local %ENV;
		$ENV{LANG} = 'en_US.UTF-8';
		my $t = Lingua::Text->new();
		does_carp_that_matches(
			sub { $t->set(lang => 'en', text => undef) },
			'EC3: undef text triggers carp',
			qr/usage/,
		);
		ok(!defined($t->en()), 'EC3: nothing stored when text is undef');
	}

	# EC4: lang missing and no locale -- carp
	{
		local %ENV;
		my $t = Lingua::Text->new();
		does_carp_that_matches(
			sub { $t->set(text => 'hello') },
			'EC4: missing lang with no locale triggers carp',
			qr/usage/,
		);
	}

	# EC5: lang supplied but fails ISO 639-1 validation -- carp, invariant preserved
	# (Bug fix: previously stored under invalid key, violating the object invariant)
	{
		local %ENV;
		my $t = Lingua::Text->new();
		does_carp_that_matches(
			sub { $t->set(text => 'hello', lang => 'abc') },
			'EC5: three-char lang code triggers carp',
			qr/usage/,
		);
		ok(!defined($t->as_string('abc')),
			'EC5: invalid lang was not stored (invariant preserved)');
	}

	# EC6: text is the falsy string '0' -- stored correctly
	# (Proves the fix: "if(defined($text))" not "if($text)")
	{
		local %ENV;
		my $t = Lingua::Text->new();
		$t->set(text => '0', lang => 'en');
		is($t->en(), '0', 'EC6: falsy string "0" is stored');
	}

	# EC7: text is the empty string '' -- stored correctly
	{
		local %ENV;
		my $t = Lingua::Text->new();
		$t->set(text => '', lang => 'fr');
		ok(defined($t->fr()), 'EC7: empty string text is defined after set');
		is($t->fr(), '', 'EC7: empty string text is stored verbatim');
	}

	# EC8: positional scalar + locale -- stored under locale lang
	{
		local %ENV;
		$ENV{LANG} = 'de_DE.UTF-8';
		my $t = Lingua::Text->new();
		$t->set('Haus');
		is($t->de(), 'Haus', 'EC8: positional set() uses system locale lang');
	}

	# EC9: chaining -- set() returns $self, enabling method chains
	{
		local %ENV;
		my $t = Lingua::Text->new()
			->set(text => 'Hello', lang => 'en')
			->set(text => 'Hola',  lang => 'es');
		is($t->en(), 'Hello', 'EC9: chain first link stored');
		is($t->es(), 'Hola',  'EC9: chain second link stored');
	}
};

# ===========================================================================
# PARTITION 3 -- as_string()
# Major premise: as_string() never modifies state (Xi schema); it maps
# lang->STRING when the key exists, or lang->undef when absent.
# ===========================================================================
subtest 'as_string -- state-preserving query proofs' => sub {
	# EC1: explicit lang, translation exists
	{
		local %ENV;
		my $t = Lingua::Text->new(en => 'boat', fr => 'bateau');
		is($t->as_string('en'), 'boat',   'EC1: positional lang arg');
		is($t->as_string(lang => 'fr'), 'bateau', 'EC1: named lang arg');
		is($t->as_string({ lang => 'en' }), 'boat', 'EC1: hashref lang arg');
	}

	# EC2: explicit lang, NO translation stored -- undef, no warning
	# Boundary: distinguishes "not found" (silent) from "no lang" (carp)
	{
		local %ENV;
		my $t = Lingua::Text->new(en => 'boat');
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned = 1 };
		my $result = $t->as_string('de');
		ok(!defined($result), 'EC2: missing translation returns undef');
		ok(!$warned, 'EC2: missing translation does NOT emit a warning');
	}

	# EC3: no lang arg, no locale -- carp
	{
		local %ENV;
		my $t = Lingua::Text->new(en => 'boat');
		does_carp_that_matches(
			sub { $t->as_string() },
			'EC3: no lang + no locale triggers carp',
			qr/usage/,
		);
	}

	# EC4: no lang arg, locale set, translation exists -- uses locale
	{
		local %ENV;
		$ENV{LANG} = 'fr_FR.UTF-8';
		my $t = Lingua::Text->new(en => 'boat', fr => 'bateau');
		is($t->as_string(), 'bateau', 'EC4: no lang + locale => locale translation');
	}

	# EC5: stringify overload invokes as_string with the overload convention
	# Perl passes ($self, $other, $swap) -- extra args must not corrupt result
	{
		local %ENV;
		$ENV{LANG} = 'en_US.UTF-8';
		my $t = Lingua::Text->new(en => 'boat');
		is("$t", 'boat', 'EC5: stringify overload returns correct translation');
		is($t . '', 'boat', 'EC5: concatenation overload also correct');
	}

	# EC6: state preservation -- as_string() leaves texts unchanged
	{
		local %ENV;
		$ENV{LANG} = 'en_US.UTF-8';
		my $t = Lingua::Text->new(en => 'boat', fr => 'bateau');
		$t->as_string('fr');
		is($t->en(), 'boat',   'EC6: en unchanged after as_string(fr)');
		is($t->fr(), 'bateau', 'EC6: fr unchanged after as_string(fr)');
	}
};

# ===========================================================================
# PARTITION 4 -- encode()
# Major premise: encode() applies HTML entity encoding to every stored value
# in place; dom(texts) is unchanged but all values are transformed.
# ===========================================================================
subtest 'encode -- state mutation proofs' => sub {
	# EC1: ASCII-only text -- value unchanged by encoding
	{
		local %ENV;
		my $t = Lingua::Text->new(en => 'study')->encode();
		is($t->en(), 'study', 'EC1: ASCII text unaffected by encode()');
	}

	# EC2: non-ASCII text (U+00E9 = e-acute) -- encoded to HTML entity
	{
		local %ENV;
		my $t = Lingua::Text->new(fr => "\x{E9}tude")->encode();
		is($t->fr(), '&eacute;tude', 'EC2: e-acute encoded to &eacute;');
	}

	# EC3: returns $self -- encode() is chainable
	{
		local %ENV;
		my $t = Lingua::Text->new(en => 'hello');
		isa_ok($t->encode(), 'Lingua::Text', 'EC3: encode() returns $self');
	}

	# EC4: double-encode proof (the documented pitfall)
	# P1: encode() is idempotent only for plain ASCII.
	# P2: & is a special HTML character; a second encode() encodes it again.
	# Conclusion: calling encode() twice corrupts the output.
	{
		local %ENV;
		my $t = Lingua::Text->new(fr => "\x{E9}tude")->encode()->encode();
		is($t->fr(), '&amp;eacute;tude',
			'EC4: double-encode corrupts output (the documented pitfall)');
	}
};

# ===========================================================================
# PARTITION 5 -- AUTOLOAD language accessors
# Major premise: any two-letter lowercase method name is a valid setter/getter;
# all other names return undef silently.
# ===========================================================================
subtest 'AUTOLOAD -- dispatch boundary proofs' => sub {
	# EC1: setter with truthy value -- stored and returned
	{
		my $t = Lingua::Text->new();
		is($t->en('Hello'), 'Hello', 'EC1: truthy setter returns value');
		is($t->en(),        'Hello', 'EC1: getter retrieves stored value');
	}

	# EC2: setter with '0' (falsy string) -- stored correctly
	# Proves the @_ presence check (not truthiness) is correct.
	{
		my $t = Lingua::Text->new();
		$t->en('before');
		my $ret = $t->en('0');
		is($ret,    '0', 'EC2: falsy string "0" returned by setter');
		is($t->en(), '0', 'EC2: falsy string "0" stored by setter');
	}

	# EC3: setter with empty string '' -- stored correctly
	{
		my $t = Lingua::Text->new();
		$t->fr('before');
		$t->fr('');
		ok(defined($t->fr()), 'EC3: empty string is defined');
		is($t->fr(), '', 'EC3: empty string stored verbatim');
	}

	# EC4: setter with undef -- stored (clearing the translation)
	{
		my $t = Lingua::Text->new();
		$t->de('Guten Tag');
		$t->de(undef);
		ok(!defined($t->de()), 'EC4: undef setter clears the translation');
	}

	# EC5: getter on missing translation -- undef, no warning
	{
		my $t    = Lingua::Text->new(en => 'hello');
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned = 1 };
		ok(!defined($t->ja()), 'EC5: getter for missing lang returns undef');
		ok(!$warned, 'EC5: no warning emitted for missing lang');
	}

	# EC6: uppercase 2-char code -- silently rejected
	# Proves the i-flag removal: 'EN' fails /^[a-z]{2}$/ (no i-flag).
	{
		my $t = Lingua::Text->new();
		$t->set(text => 'Hello', lang => 'en');
		ok(!defined($t->EN()), 'EC6: uppercase EN() returns undef (not a valid accessor)');
	}

	# EC7: 3-char code -- falls outside the ^[a-z]{2}$ gate, returns undef
	{
		my $t = Lingua::Text->new();
		ok(!defined($t->xyz()), 'EC7: 3-char code returns undef silently');
	}

	# EC8: method typo -- silently returns undef
	{
		my $t = Lingua::Text->new(en => 'hello');
		ok(!defined($t->enn()), 'EC8: typo "enn" returns undef (not "en")');
	}
};

done_testing();

#!/usr/bin/env perl
# t/domain.t -- Equivalence Partitioning (EP) and Boundary Value Analysis (BVA)
# for every public API input domain in Lingua::Text.
#
# Methodology:
#   EP:  one representative per valid partition, one per invalid partition.
#   BVA: test the exact boundary edge, the value just below, and the value
#        just above for every input with a defined numeric or length constraint.
#   Combinatorial: exercise maximum-of-one-param with minimum-of-another.
#
# ============================================================================
# DOMAIN TABLES (summarised here; full detail in lib/Lingua/Text.pm POD)
# ============================================================================
#
# new() -- invocant
#   V1 : class string that isa Lingua::Text   -> object returned
#   V2 : blessed Lingua::Text object          -> clone returned
#   V3 : undef + no args (bare function call) -> empty object returned
#   I1 : foreign blessed ref                  -> carp + undef
#   I2 : non-class string with args           -> carp + undef
#
# new() -- argument form
#   V1 : no args                              -> empty object
#   V2 : flat key/value pairs                 -> texts populated
#   V3 : hash ref                             -> texts populated
#   V4 : single scalar + locale set           -> stored under locale lang
#   V5 : single scalar + no locale            -> silently discarded
#   BVA: falsy scalars '' and '0' are valid text values (defined, not undef)
#
# set() -- lang parameter (regex: /^[a-z]{2}(?:_[A-Z]{2})?$/)
#   V1 : 2 lowercase chars 'en'              -> valid (minimum boundary)
#   V2 : 2 lower + country 'en_US'           -> valid (maximum with suffix)
#   I1 : 1 char 'e'                          -> invalid (below minimum)
#   I2 : 3 lowercase 'eng'                   -> invalid (above simple max)
#   I3 : 2 uppercase 'EN'                    -> invalid (wrong case)
#   I4 : 1 upper + 1 lower 'En'             -> invalid (mixed case)
#   I5 : 2 digits '12'                       -> invalid (non-alpha)
#   I6 : empty ''                            -> invalid
#   I7 : 6 chars 'en_USA'                   -> invalid (country code too long)
#   I8 : 4 chars 'en_U'                     -> invalid (country code too short)
#   I9 : lower + underscore only 'en_'      -> invalid (no country code)
#
# set() -- text parameter
#   V1 : regular ASCII string               -> stored verbatim
#   V2 : empty string ''                    -> stored as '' (BVA: min length)
#   V3 : falsy string '0'                   -> stored as '0'
#   V4 : Unicode string                     -> stored verbatim
#   V5 : 1 MB string                        -> stored verbatim (BVA: large)
#   I1 : undef                              -> carp + undef returned
#
# as_string() -- lang argument (NO validation; any defined scalar = hash key)
#   V1 : stored key                         -> returns stored text
#   V2 : valid-format key not in texts      -> returns undef (no warning)
#   V3 : malformed key (3 chars) not stored -> returns undef (no warning)
#   V4 : empty string ''                    -> returns undef (no warning)
#   V5 : no argument                        -> falls back to _get_language()
#   V6 : undef argument                     -> falls back to _get_language()
#
# AUTOLOAD accessor -- method name (regex: /^[a-z]{2}$/)
#   V1 : 2 lowercase chars 'en'            -> accessor installed, getter/setter
#   I1 : 1 char 'e'                        -> undef, no accessor
#   I2 : 3 chars 'eng'                     -> undef, no accessor
#   I3 : 2 uppercase 'EN'                  -> undef, no accessor
#   I4 : mixed 'En'                        -> undef, no accessor
#   I5 : 'en_US' (underscore)             -> undef, no accessor (AUTOLOAD \w+ match)
#
# encode() -- per-slot value domain
#   V1 : ASCII text                        -> unchanged
#   V2 : Latin-1 accented (UTF-8 flagged) -> entity-encoded
#   V3 : HTML special chars < > & "       -> entity-encoded
#   V4 : undef slot                        -> skipped (preserved as undef)
#   V5 : ref slot                          -> skipped (preserved as ref)
#   V6 : non-lang key slot ('eng')        -> skipped by _is_valid_language

use strict;
use warnings;

use Test::Most;
use Test::Carp;
use Test::Mockingbird;
use Test::Returns;
use Readonly;
use Scalar::Util qw(blessed refaddr);

BEGIN {
	use_ok('Lingua::Text') or BAIL_OUT('Cannot load Lingua::Text -- all tests invalid');
}

# ---------------------------------------------------------------------------
# Constants -- one name per domain boundary or representative value
# ---------------------------------------------------------------------------

# Locale strings
Readonly::Scalar my $LOCALE_EN   => 'en_US.UTF-8';
Readonly::Scalar my $LOCALE_FR   => 'fr_FR.UTF-8';

# Valid lang codes (EP representatives)
Readonly::Scalar my $LANG_EN     => 'en';    # V1: 2 lowercase -- minimum valid
Readonly::Scalar my $LANG_FR     => 'fr';    # V1: another representative
Readonly::Scalar my $LANG_EN_US  => 'en_US'; # V2: with ISO 3166-1 country suffix

# Invalid lang codes -- each is a distinct partition/boundary
Readonly::Scalar my $LANG_1CHAR  => 'e';      # I1: 1 char (below minimum)
Readonly::Scalar my $LANG_3CHAR  => 'eng';    # I2: 3 lowercase (above maximum)
Readonly::Scalar my $LANG_UPPER  => 'EN';     # I3: 2 uppercase
Readonly::Scalar my $LANG_MIXED  => 'En';     # I4: mixed case
Readonly::Scalar my $LANG_DIGITS => '12';     # I5: 2 digits
Readonly::Scalar my $LANG_EMPTY  => '';       # I6: empty string
Readonly::Scalar my $LANG_LONG   => 'en_USA'; # I7: country code 3 chars
Readonly::Scalar my $LANG_SHORT  => 'en_U';   # I8: country code 1 char
Readonly::Scalar my $LANG_NOCTRY => 'en_';    # I9: trailing underscore, no country

# Text values
Readonly::Scalar my $TEXT_EN     => 'hello';
Readonly::Scalar my $TEXT_FR     => 'bonjour';
Readonly::Scalar my $TEXT_EMPTY  => '';               # BVA: minimum length (0 chars)
Readonly::Scalar my $TEXT_ZERO   => '0';              # falsy but defined
Readonly::Scalar my $TEXT_LARGE  => 'x' x 1_000_000; # BVA: 1 MB string
Readonly::Scalar my $TEXT_ACUTE  => "\x{E9}tude";    # accented -- U+00E9
Readonly::Scalar my $TEXT_ACUTE_E => '&eacute;tude'; # expected encoded form
Readonly::Scalar my $TEXT_HTML   => '<b>bold</b>';
Readonly::Scalar my $TEXT_HTML_E => '&lt;b&gt;bold&lt;/b&gt;';

# ---------------------------------------------------------------------------
# Helper: a foreign (non-Lingua::Text) blessed object used as an invocant.
# ---------------------------------------------------------------------------
{
	package ForeignObj;
	sub new { bless {}, shift }
}

# ===========================================================================
# 1. new() -- invocant domain (EP)
#
# Three valid partitions: class-name, existing object, undef+no-args.
# Two invalid partitions: foreign-ref, non-class string with args.
#
# V3 (undef + no args) is tested simply as Lingua::Text::new() -- the
# auto-promotion to __PACKAGE__ makes a valid empty object.
# ===========================================================================
subtest 'new() -- invocant EP: valid partitions' => sub {
	# V1: class-name invocant.
	my $t = Lingua::Text->new(en => $TEXT_EN);
	isa_ok($t, 'Lingua::Text', 'V1 class-name invocant: returns Lingua::Text');
	is($t->en(), $TEXT_EN, 'V1: text stored correctly');

	# V2: existing Lingua::Text object as invocant (clone path).
	my $clone = $t->new(fr => $TEXT_FR);
	isa_ok($clone, 'Lingua::Text', 'V2 object invocant: clone returned');
	is($clone->en(), $TEXT_EN, 'V2: en inherited from original');
	is($clone->fr(), $TEXT_FR, 'V2: fr added by clone call');
	isnt(refaddr($clone->{'texts'}), refaddr($t->{'texts'}),
		'V2: clone has independent {texts} hash (no aliasing)');

	# V3: undef invocant + no args => bare function call => empty object.
	my $bare = Lingua::Text::new();
	isa_ok($bare, 'Lingua::Text', 'V3 bare new() with no args: returns empty object');
	ok(!defined($bare->en()), 'V3: no texts in empty object');
};

subtest 'new() -- invocant EP: invalid partitions' => sub {
	my $result;

	# I1: foreign blessed reference -- passes blessed() but not isa().
	my $foreign = ForeignObj->new();
	does_carp_that_matches(
		sub { $result = Lingua::Text::new($foreign, en => $TEXT_EN) },
		'I1 foreign ref: carp emitted',
		qr/use ->new\(\)/,
	);
	ok(!defined($result), 'I1 foreign ref: returns undef');

	# I2: non-class string accidentally consumed as invocant.
	# 'en' is not a Lingua::Text subclass, so the check fails.
	does_carp_that_matches(
		sub { $result = Lingua::Text::new('en', $TEXT_EN) },
		'I2 non-class string: carp emitted',
		qr/use ->new\(\)/,
	);
	ok(!defined($result), 'I2 non-class string: returns undef');
};

# ===========================================================================
# 2. new() -- argument form domain (EP + BVA on falsy scalars)
#
# Five valid argument forms.  Each form must produce a correctly populated
# object without croaking or carping.
# ===========================================================================
subtest 'new() -- argument form EP' => sub {
	# Mock configure to keep {texts} predictable (no injected 'logger' etc.).
	mock 'Object::Configure::configure' => sub { $_[1] };

	# V1: no arguments -- empty object.
	my $empty = Lingua::Text->new();
	isa_ok($empty, 'Lingua::Text', 'V1 no-args: object created');
	ok(!defined($empty->en()), 'V1: no texts stored');

	# V2: flat key/value pairs.
	my $flat = Lingua::Text->new(en => $TEXT_EN, fr => $TEXT_FR);
	is($flat->en(), $TEXT_EN, 'V2 flat pairs: en stored');
	is($flat->fr(), $TEXT_FR, 'V2 flat pairs: fr stored');

	# V3: hash reference.
	my $href = Lingua::Text->new({ en => $TEXT_EN, fr => $TEXT_FR });
	is($href->en(), $TEXT_EN, 'V3 hashref: en stored');
	is($href->fr(), $TEXT_FR, 'V3 hashref: fr stored');

	# V4: single non-ref scalar with locale set -> stored under locale lang.
	{
		local %ENV;
		$ENV{LANG} = $LOCALE_EN;
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		my $scalar = Lingua::Text->new($TEXT_EN);
		is($scalar->en(), $TEXT_EN,
			'V4 single scalar + locale: stored under locale lang');
		restore_all();
	}

	# V5: single non-ref scalar with NO locale -> silently discarded.
	{
		local %ENV;
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		my $nolocale = Lingua::Text->new($TEXT_EN);
		ok(!defined($nolocale->en()),
			'V5 single scalar + no locale: text silently discarded');
		restore_all();
	}

	restore_all();    # restore configure mock
};

subtest 'new() -- single scalar BVA: falsy but defined values are stored' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	local %ENV;
	$ENV{LANG} = $LOCALE_EN;
	mock 'I18N::LangTags::Detect::detect' => sub { () };

	# BVA: empty string is defined -- must be stored (length-0 boundary).
	my $t_empty = Lingua::Text->new($TEXT_EMPTY);
	is($t_empty->en(), $TEXT_EMPTY,
		"BVA single scalar '': empty string stored (not undef)");

	# BVA: '0' is defined but falsy -- must be stored.
	my $t_zero = Lingua::Text->new($TEXT_ZERO);
	is($t_zero->en(), $TEXT_ZERO,
		"BVA single scalar '0': falsy string stored (not discarded)");

	restore_all();
};

# ===========================================================================
# 3. new() -- language key domain inside the texts hash (EP)
#
# new() stores ALL keys verbatim; no validation happens at construction time.
# Access restrictions come later: AUTOLOAD ignores non-^[a-z]{2}$ keys;
# encode() ignores keys that fail _is_valid_language().
#
# EP: what keys are accessible via AUTOLOAD vs. silently stored-but-ignored.
# ===========================================================================
subtest 'new() -- language key domain in texts (EP)' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };

	# V1: 2-char lowercase -- accessible via AUTOLOAD.
	my $t = Lingua::Text->new(en => $TEXT_EN, fr => $TEXT_FR);
	is($t->en(), $TEXT_EN, 'V1 key "en" (2-lower): accessible via AUTOLOAD');
	is($t->fr(), $TEXT_FR, 'V1 key "fr" (2-lower): accessible via AUTOLOAD');

	# V2: 2-lower + country suffix -- valid for _is_valid_language() and encode(),
	#     but NOT accessible via AUTOLOAD (AUTOLOAD filter is ^[a-z]{2}$ only).
	my $t2 = Lingua::Text->new('en_US' => 'color');
	ok(!defined($t2->can('en_US')),
		'V2 key "en_US": no AUTOLOAD accessor installed');
	# Direct access via the texts hash confirms storage.
	is($t2->{'texts'}{'en_US'}, 'color',
		'V2 key "en_US": stored in {texts} (accessible internally)');

	# I1: 1-char key -- stored but AUTOLOAD ignores it.
	my $t3 = Lingua::Text->new(e => 'solo');
	ok(!defined($t3->e()), 'I1 key "e" (1-char): AUTOLOAD returns undef');

	# I2: 3-char key -- stored but AUTOLOAD ignores it.
	my $t4 = Lingua::Text->new(eng => 'english');
	ok(!defined($t4->eng()), 'I2 key "eng" (3-char): AUTOLOAD returns undef');

	restore_all();
};

# ===========================================================================
# 4. set() -- lang parameter BVA
#
# Valid partitions: ^[a-z]{2}$ and ^[a-z]{2}_[A-Z]{2}$
# Min boundary: exactly 2 lowercase chars.
# Invalid: 1 char (below min), 3 chars (above simple max), wrong case, digits,
#          empty, country-code too long/short, trailing underscore only.
# ===========================================================================
subtest 'set() -- lang parameter BVA: valid partitions' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };

	# V1: minimum valid (2 lowercase chars).
	my $t = Lingua::Text->new();
	my $ret = $t->set(text => $TEXT_EN, lang => $LANG_EN);
	is(ref($ret), 'Lingua::Text', "V1 lang='$LANG_EN' (min boundary): returns self");
	is($t->en(), $TEXT_EN, "V1 lang='$LANG_EN': text stored");

	# V2: maximum with country suffix (5 chars total: 2 + _ + 2).
	# Note: not AUTOLOAD-accessible but valid for storage.
	my $t2 = Lingua::Text->new();
	my $ret2 = $t2->set(text => 'color', lang => $LANG_EN_US);
	is(ref($ret2), 'Lingua::Text', "V2 lang='$LANG_EN_US' (with suffix): returns self");
	is($t2->{'texts'}{$LANG_EN_US}, 'color', "V2 lang='$LANG_EN_US': stored in texts");

	restore_all();
};

subtest 'set() -- lang parameter BVA: invalid partitions (each carps)' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	local %ENV;    # clear locale so _get_language() returns undef (no env fallback)
	mock 'I18N::LangTags::Detect::detect' => sub { () };

	my $t = Lingua::Text->new();

	my %invalid = (
		"I1 '$LANG_1CHAR' (1 char, below min)"   => $LANG_1CHAR,
		"I2 '$LANG_3CHAR' (3 chars, above max)"  => $LANG_3CHAR,
		"I3 '$LANG_UPPER' (2 uppercase)"          => $LANG_UPPER,
		"I4 '$LANG_MIXED' (mixed case)"           => $LANG_MIXED,
		"I5 '$LANG_DIGITS' (2 digits)"            => $LANG_DIGITS,
		"I7 '$LANG_LONG' (country 3-char)"        => $LANG_LONG,
		"I8 '$LANG_SHORT' (country 1-char)"       => $LANG_SHORT,
		"I9 '$LANG_NOCTRY' (trailing underscore)" => $LANG_NOCTRY,
	);

	for my $name (sort keys %invalid) {
		my $bad_lang = $invalid{$name};
		my $result;
		does_carp_that_matches(
			sub { $result = $t->set(text => $TEXT_EN, lang => $bad_lang) },
			"$name: carp emitted",
			qr/usage: set\(text/i,
		);
		ok(!defined($result), "$name: returns undef");
	}

	# I6: empty string as lang -- carp.
	{
		my $result;
		does_carp_that_matches(
			sub { $result = $t->set(text => $TEXT_EN, lang => $LANG_EMPTY) },
			"I6 '' (empty string): carp emitted",
			qr/usage: set\(text/i,
		);
		ok(!defined($result), "I6 '': returns undef");
	}

	restore_all();
};

subtest 'set() -- lang falls back to locale when omitted' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };

	# V: lang omitted + locale set -> uses _get_language().
	{
		local %ENV;
		$ENV{LANG} = $LOCALE_FR;
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		my $t   = Lingua::Text->new();
		my $ret = $t->set(text => $TEXT_FR);
		is(ref($ret), 'Lingua::Text',
			'lang omitted + locale set: returns self (locale used)');
		is($t->fr(), $TEXT_FR, 'lang omitted + locale set: text stored under locale lang');
		restore_all();
	}

	# I: lang omitted + NO locale -> carp.
	{
		local %ENV;
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		my $t = Lingua::Text->new();
		my $result;
		does_carp_that_matches(
			sub { $result = $t->set(text => $TEXT_EN) },
			'lang omitted + no locale: carp emitted',
			qr/usage: set\(text/i,
		);
		ok(!defined($result), 'lang omitted + no locale: returns undef');
		restore_all();
	}

	restore_all();
};

# ===========================================================================
# 5. set() -- text parameter domain (EP + BVA)
#
# Any defined scalar is a valid text value.  Only undef is rejected.
# BVA: empty string (length 0) is the minimum; 1 MB is a large-value probe.
# ===========================================================================
subtest 'set() -- text parameter EP + BVA' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	my $t = Lingua::Text->new();

	# V1: regular ASCII string (representative of the main valid partition).
	$t->set(text => $TEXT_EN, lang => $LANG_EN);
	is($t->en(), $TEXT_EN, 'V1 regular text: stored');

	# V2: empty string (BVA: minimum length = 0 chars).
	$t->set(text => $TEXT_EMPTY, lang => $LANG_EN);
	is($t->en(), $TEXT_EMPTY, "V2 text='': empty string stored (not undef)");
	ok(defined($t->en()), "V2 text='': defined (empty != undef)");

	# V3: falsy string '0' (BVA: defined but || would discard it).
	$t->set(text => $TEXT_ZERO, lang => $LANG_EN);
	is($t->en(), $TEXT_ZERO, "V3 text='0': falsy string stored");

	# V4: Unicode string (accented characters).
	$t->set(text => $TEXT_ACUTE, lang => $LANG_FR);
	is($t->fr(), $TEXT_ACUTE, 'V4 Unicode text: stored verbatim (not modified)');

	# V5: 1 MB string (BVA: large value, no documented limit).
	$t->set(text => $TEXT_LARGE, lang => $LANG_EN);
	is(length($t->en()), length($TEXT_LARGE),
		'V5 1 MB text: stored without truncation');

	# I1: undef text -- must carp.
	{
		my $result;
		does_carp_that_matches(
			sub { $result = $t->set(text => undef, lang => $LANG_EN) },
			'I1 text=undef: carp emitted',
			qr/usage: set\(text/i,
		);
		ok(!defined($result), 'I1 text=undef: returns undef');
	}

	restore_all();
};

# ===========================================================================
# 6. set() -- argument form domain (EP)
#
# set() accepts four distinct calling conventions.  Calling with NO arguments
# is the only form that croaks (programmer error); missing text or lang carps.
# ===========================================================================
subtest 'set() -- argument form EP' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	my $t = Lingua::Text->new();

	# V1: flat hash form.
	$t->set(text => $TEXT_EN, lang => $LANG_EN);
	is($t->en(), $TEXT_EN, 'V1 flat hash: stored');

	# V2: hash reference form.
	$t->set({ text => $TEXT_FR, lang => $LANG_FR });
	is($t->fr(), $TEXT_FR, 'V2 hashref: stored');

	# V3: positional text only (lang from locale).
	{
		local %ENV;
		$ENV{LANG} = $LOCALE_FR;
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		$t->set($TEXT_FR);
		is($t->fr(), $TEXT_FR, 'V3 positional text: stored under locale lang');
		restore_all();
	}

	# I: no arguments at all -- CROAK (programmer error, not carp).
	does_croak_that_matches(
		sub { $t->set() },
		'no args: croaks',
		qr/Usage: set\(text/,
	);

	restore_all();
};

# ===========================================================================
# 7. as_string() -- lang argument domain (EP)
#
# IMPORTANT: as_string() performs NO validation on the lang argument.
# Any defined scalar is accepted and used directly as a hash key.
# This distinguishes as_string() from set() which calls _is_valid_language().
# ===========================================================================
subtest 'as_string() -- lang argument EP: defined values used as hash key' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	my $t = Lingua::Text->new(en => $TEXT_EN, fr => $TEXT_FR);

	# V1: valid key that is stored -- returns the text.
	is($t->as_string($LANG_EN), $TEXT_EN,
		"V1 lang='$LANG_EN' (stored key): returns text");

	# V2: valid-format key NOT stored -- returns undef (no warning).
	my $r;
	lives_ok(
		sub { $r = $t->as_string('de') },
		"V2 lang='de' (not stored): no exception",
	);
	ok(!defined($r), "V2 lang='de' (not stored): returns undef silently");

	# V3: malformed-format key (3 chars) not stored -- returns undef (no warning).
	# as_string() does NOT call _is_valid_language(); it just does a hash lookup.
	lives_ok(
		sub { $r = $t->as_string($LANG_3CHAR) },
		"V3 lang='$LANG_3CHAR' (3 chars, malformed): no exception",
	);
	ok(!defined($r), "V3 lang='$LANG_3CHAR' (malformed): returns undef silently");

	# V4: empty string -- returns undef (no warning, because '' is defined).
	lives_ok(
		sub { $r = $t->as_string($LANG_EMPTY) },
		"V4 lang='' (empty string): no exception",
	);
	ok(!defined($r), "V4 lang='' (empty string): returns undef silently");

	# V5: no argument -- falls back to _get_language(); carps if no locale set.
	{
		local %ENV;
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		does_carp_that_matches(
			sub { $r = $t->as_string() },
			'V5 no arg + no locale: carp emitted',
			qr/usage: as_string/i,
		);
		ok(!defined($r), 'V5 no arg + no locale: returns undef');
		restore_all();
	}

	# V6: undef argument -- treated the same as no argument.
	{
		local %ENV;
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		does_carp_that_matches(
			sub { $r = $t->as_string(undef) },
			'V6 lang=undef: carp emitted (falls back to _get_language())',
			qr/usage: as_string/i,
		);
		ok(!defined($r), 'V6 lang=undef: returns undef');
		restore_all();
	}

	restore_all();
};

subtest 'as_string() -- argument form EP (positional / named / hashref)' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	my $t = Lingua::Text->new(en => $TEXT_EN, fr => $TEXT_FR);

	# V1: positional.
	is($t->as_string($LANG_EN),          $TEXT_EN, 'V1 positional: correct text');

	# V2: named hash form.
	is($t->as_string(lang => $LANG_FR),  $TEXT_FR, 'V2 named: correct text');

	# V3: hash-reference form.
	is($t->as_string({ lang => $LANG_EN }), $TEXT_EN, 'V3 hashref: correct text');

	restore_all();
};

# ===========================================================================
# 8. AUTOLOAD accessor -- method name BVA
#
# The filter is: /^[a-z]{2}$/ -- exactly 2 lowercase ASCII letters, nothing
# else.  Any non-matching method name returns undef silently and does NOT
# install a permanent accessor.  DESTROY is explicitly excluded before the
# filter runs so it never reaches user-visible code.
#
# BVA on length: 1 char (below min), 2 chars (min = valid), 3 chars (above).
# ===========================================================================
subtest 'AUTOLOAD accessor -- method name BVA' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	my $t = Lingua::Text->new(en => $TEXT_EN);

	# V1: exactly 2 lowercase chars (minimum valid boundary).
	is($t->en(), $TEXT_EN, "V1 name 'en' (2-lower, min valid): getter works");
	$t->fr($TEXT_FR);
	is($t->fr(), $TEXT_FR, "V1 name 'fr' (2-lower): setter + getter works");

	# I1: 1 char (below minimum) -- no accessor, undef returned.
	ok(!defined($t->e()), "I1 name 'e' (1 char, below min): undef");

	# I2: 3 chars (above 2-char maximum) -- no accessor.
	ok(!defined($t->eng()), "I2 name 'eng' (3 chars, above max): undef");

	# I3: 2 uppercase -- fails regex (requires [a-z]).
	# Must call via AUTOLOAD since 'EN' is not a declared sub.
	# We verify by using AUTOLOAD indirectly: if no accessor exists, returns undef.
	my $got_EN;
	{
		no strict 'refs';
		# Install a temporary proxy that calls through AUTOLOAD dispatch.
		# Calling EN() as a method: Perl routes through AUTOLOAD.
		eval { $got_EN = $t->EN() };
	}
	ok(!defined($got_EN), "I3 name 'EN' (2 uppercase): undef");

	# I4: mixed case -- fails regex.
	my $got_mixed;
	eval { $got_mixed = $t->En() };
	ok(!defined($got_mixed), "I4 name 'En' (mixed): undef");

	# I5: 'en_US' with underscore -- AUTOLOAD captures en_US (\w+ includes _)
	#     but /^[a-z]{2}$/ fails because it has 5 chars and an underscore.
	my $got_enu;
	eval { $got_enu = $t->en_US() };
	ok(!defined($got_enu), "I5 name 'en_US' (underscore suffix): undef");

	restore_all();
};

# ===========================================================================
# 9. AUTOLOAD accessor -- value domain (setter EP + BVA)
#
# The setter stores whatever is passed, including falsy and reference values.
# encode() later filters refs; the accessor itself is a transparent store.
# ===========================================================================
subtest 'AUTOLOAD accessor -- value domain EP (setter)' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	my $t = Lingua::Text->new();

	# V1: regular ASCII string.
	$t->en($TEXT_EN);
	is($t->en(), $TEXT_EN, "V1 set '$TEXT_EN': stored and retrieved");

	# V2: empty string (BVA: minimum length = 0).
	$t->en($TEXT_EMPTY);
	is($t->en(), $TEXT_EMPTY, "V2 set '': empty string stored (not undef)");
	ok(defined($t->en()), "V2: defined('')==true (empty != undef)");

	# V3: falsy string '0' -- stored correctly.
	$t->en($TEXT_ZERO);
	is($t->en(), $TEXT_ZERO, "V3 set '0': falsy string stored");

	# V4: undef -- stored as undef (encode() later skips it, but storage is fine).
	$t->en(undef);
	ok(!defined($t->en()), 'V4 set undef: stored as undef');

	# V5: arrayref -- stored as reference (encode() will skip it).
	my $ref = [1, 2, 3];
	$t->fr($ref);
	is(ref($t->fr()), 'ARRAY', 'V5 set arrayref: ref stored (not dereferenced)');
	is($t->fr(), $ref, 'V5 set arrayref: same ref returned');

	restore_all();
};

# ===========================================================================
# 10. encode() -- stored value domain (EP)
#
# encode() iterates {texts} and applies HTML entity encoding.  It filters by:
#   (a) _is_valid_language($key): skip non-lang keys
#   (b) defined($v) && !ref($v): skip undef and ref values
# Only plain, defined strings under valid ISO 639-1 keys are encoded.
# ===========================================================================
subtest 'encode() -- stored value domain EP' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };

	# V1: ASCII-only text -- encode() must leave it unchanged.
	my $t = Lingua::Text->new(en => $TEXT_EN);
	$t->encode();
	is($t->en(), $TEXT_EN, 'V1 ASCII text: unchanged by encode()');

	# V2: accented text (UTF-8 flagged) -- entity-encoded.
	my $t2 = Lingua::Text->new(fr => $TEXT_ACUTE);
	$t2->encode();
	is($t2->fr(), $TEXT_ACUTE_E, 'V2 accented text (UTF-8 flagged): entity-encoded');

	# V3: HTML special characters -- entity-encoded.
	my $t3 = Lingua::Text->new(en => $TEXT_HTML);
	$t3->encode();
	is($t3->en(), $TEXT_HTML_E, 'V3 HTML special chars: entity-encoded');

	# V4: undef slot -- preserved as undef (not encoded, not '' ).
	my $t4 = Lingua::Text->new(en => $TEXT_EN);
	$t4->fr(undef);    # store undef in fr slot
	$t4->encode();
	ok(!defined($t4->fr()), 'V4 undef slot: skipped by encode() (preserved as undef)');
	is($t4->en(), $TEXT_EN, 'V4: other slots still encoded correctly');

	# V5: ref slot -- preserved as ref (not encoded).
	my $t5 = Lingua::Text->new(en => $TEXT_EN);
	my $ref = [1, 2, 3];
	$t5->fr($ref);
	$t5->encode();
	is($t5->fr(), $ref, 'V5 ref slot: skipped by encode() (ref preserved)');

	# V6: non-language key in texts -- skipped by _is_valid_language().
	# Inject a 3-char key directly to bypass AUTOLOAD validation.
	my $t6 = Lingua::Text->new(en => $TEXT_HTML);
	$t6->{'texts'}{'eng'} = $TEXT_HTML;    # 3-char key: not a valid lang code
	$t6->encode();
	is($t6->{'texts'}{'eng'}, $TEXT_HTML,
		'V6 non-lang key "eng": skipped by encode() (raw HTML preserved)');
	is($t6->en(), $TEXT_HTML_E,
		'V6: valid lang key "en" still encoded despite skip');

	restore_all();
};

# ===========================================================================
# 11. encode() -- idempotence and double-encode (documented pitfall BVA)
#
# encode() modifies in place.  Calling it twice double-encodes entities.
# This is the documented "minimum call = 1 time" boundary.
# ===========================================================================
subtest 'encode() -- single vs double encode boundary' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };

	# Single encode (correct use): accented text -> entities.
	my $t1 = Lingua::Text->new(fr => $TEXT_ACUTE);
	$t1->encode();
	is($t1->fr(), $TEXT_ACUTE_E, 'single encode: correct entity form');

	# Double encode (documented pitfall): entities get re-encoded.
	my $t2 = Lingua::Text->new(fr => $TEXT_ACUTE);
	$t2->encode()->encode();    # second encode() re-encodes the first output
	isnt($t2->fr(), $TEXT_ACUTE_E,
		'double encode: result differs (& in &eacute; becomes &amp;eacute;)');
	like($t2->fr(), qr/&amp;eacute;/,
		'double encode: & is itself entity-encoded on second pass');

	restore_all();
};

# ===========================================================================
# 12. Combinatorial boundary: lang at minimum, text at maximum
#
# Cross-parameter tests probe interactions between boundary values from
# different parameters hitting the system simultaneously.
# ===========================================================================
subtest 'combinatorial: min lang + max text' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };

	# lang = 'en' (2-char minimum) + text = 1 MB (large-value boundary).
	my $t = Lingua::Text->new();
	$t->set(text => $TEXT_LARGE, lang => $LANG_EN);
	is(length($t->en()), length($TEXT_LARGE),
		'min lang + max text: 1 MB stored without truncation under min-length lang');

	restore_all();
};

subtest 'combinatorial: lang with country suffix + empty text' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };

	# lang = 'en_US' (5-char max with suffix) + text = '' (0-char minimum).
	my $t = Lingua::Text->new();
	$t->set(text => $TEXT_EMPTY, lang => $LANG_EN_US);
	is($t->{'texts'}{$LANG_EN_US}, $TEXT_EMPTY,
		'max lang (with suffix) + min text (empty): stored correctly');
	ok(defined($t->{'texts'}{$LANG_EN_US}),
		'max lang + empty text: defined (not undef)');

	restore_all();
};

subtest 'combinatorial: multiple langs at their boundaries simultaneously' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };

	# All valid partitions of the lang domain stored in one object.
	# Verifies independent storage with no cross-contamination.
	my $t = Lingua::Text->new(
		en => 'english',    # V1: 2-lower (canonical)
		fr => 'french',     # V1: another 2-lower
		de => 'german',     # V1: another 2-lower
	);
	$t->{'texts'}{'en_US'} = 'american';    # V2: 2-lower + country

	is($t->en(),                   'english',  'lang "en": independent');
	is($t->fr(),                   'french',   'lang "fr": independent');
	is($t->de(),                   'german',   'lang "de": independent');
	is($t->{'texts'}{'en_US'},     'american', 'lang "en_US": independent');

	# Overwrite one lang: verify others are unaffected.
	$t->set(text => 'updated', lang => $LANG_EN);
	is($t->en(),                   'updated',  'after set(en): en updated');
	is($t->fr(),                   'french',   'after set(en): fr unchanged');
	is($t->de(),                   'german',   'after set(en): de unchanged');

	restore_all();
};

done_testing();

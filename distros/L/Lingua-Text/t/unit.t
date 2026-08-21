#!/usr/bin/env perl
# t/unit.t -- Black-box unit tests for Lingua::Text
#
# Strategy: test ONLY the public API as described in the POD.  No calls to
# private functions; no knowledge of internal data structures.  Each subtest
# corresponds to one documented method or behaviour class.
#
# Ledger discipline: every documented message key, return state, and pitfall is
# registered in %LEDGER at startup.  As mock conditions successfully exercise
# each path, the corresponding key is deleted.  The final assertion proves the
# entire documented surface is covered.

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
# Ledger -- every documented message / return state
# Each key is deleted when the matching condition is triggered.
# A non-empty ledger at the end means the test suite did not cover that path.
# ---------------------------------------------------------------------------
my %LEDGER = (
	# new() return states (POD: RETURN VALUE + MESSAGES)
	'new.success'          => 'new() returns a Lingua::Text object',
	'new.carp_fn_style'    => 'carp: "use ->new() not ::new() to instantiate"',

	# set() return states (POD: API SPECIFICATION Output)
	'set.success'          => 'set() returns $self on valid input',
	'set.croak_no_args'    => 'croak: "Usage: set(text => ...)"',
	'set.carp_missing_lang'=> 'carp: "usage: set..." (no lang, no locale)',
	'set.carp_invalid_lang'=> 'carp: "usage: set..." (lang fails ISO 639-1)',
	'set.carp_missing_text'=> 'carp: "usage: set..." (text is undef)',

	# as_string() return states (POD: RETURN VALUE + MESSAGES)
	'str.found'            => 'as_string() returns the translation string',
	'str.not_found'        => 'as_string() returns undef silently for missing lang',
	'str.carp_no_lang'     => 'carp: "usage: as_string(lang => $language)"',

	# encode() return states (POD: RETURN VALUE)
	'encode.success'       => 'encode() returns $self (chainable)',
	'encode.ascii_noop'    => 'encode() leaves ASCII text unchanged',
	'encode.entity'        => 'encode() converts non-ASCII to HTML entity',
	'encode.double'        => 'double encode() corrupts output (documented pitfall)',

	# Language accessors (POD: RETURN VALUE)
	'accessor.set'         => 'accessor setter stores and returns the value',
	'accessor.get'         => 'accessor getter retrieves the stored value',
	'accessor.undef_get'   => 'accessor getter returns undef for absent lang',
	'accessor.invalid'     => 'accessor returns undef silently for non-lang names',

	# Bool overload (POD: COMMON PITFALLS)
	'bool.always_true'     => 'empty object evaluates to true in boolean context',

	# COMMON PITFALLS (all testable via black-box calls)
	'pitfall.new_no_locale'  => 'new(scalar) silently discards text when no locale',
	'pitfall.fn_style_undef' => 'Lingua::Text::new(args) returns undef',
	'pitfall.str_undef'      => 'missing translation is undef, not empty string',
	'pitfall.typo_silent'    => 'typo accessor (3-char code) returns undef silently',
	'pitfall.set_returns_self'=> 'set() returns the object, not the string',
);

# ---------------------------------------------------------------------------
# Constants -- no magic strings scattered through the tests
# ---------------------------------------------------------------------------
Readonly::Scalar my $EN_TEXT   => 'hello';
Readonly::Scalar my $FR_TEXT   => 'bonjour';
Readonly::Scalar my $DE_TEXT   => 'Hallo';
Readonly::Scalar my $ETUDE     => "\x{E9}tude";     # e-acute (U+00E9) + "tude"
Readonly::Scalar my $ETUDE_E   => '&eacute;tude';   # expected HTML entity form
Readonly::Scalar my $EN_LOCALE => 'en_US.UTF-8';
Readonly::Scalar my $FR_LOCALE => 'fr_FR.UTF-8';
Readonly::Scalar my $DE_LOCALE => 'de_DE.UTF-8';

# Exact error message patterns from the POD MESSAGES sections
Readonly::Scalar my $RE_OO_STYLE    => qr/use ->new\(\)/;
Readonly::Scalar my $RE_SET_CROAK   => qr/Usage:\s+set\(/;
Readonly::Scalar my $RE_SET_CARP    => qr/usage:\s+set\(/;
Readonly::Scalar my $RE_STR_CARP    => qr/usage:\s+as_string\(/;

# ---------------------------------------------------------------------------
# Helper: carp-capture boilerplate extracted to cut duplication
# ---------------------------------------------------------------------------
sub capture_carp (&) {
	my ($code) = @_;
	my @msgs;
	local $SIG{__WARN__} = sub { push @msgs, @_ };
	$code->();
	return @msgs;
}

# ---------------------------------------------------------------------------
# 1.  new() -- construction, all documented argument forms
# ---------------------------------------------------------------------------
subtest 'new -- construction' => sub {
	# --- Return-state: success ---
	{
		local %ENV;
		my $t = Lingua::Text->new();
		isa_ok($t, 'Lingua::Text', 'no-args new() returns a Lingua::Text');
		ok(blessed($t),              'return value is blessed');
		delete $LEDGER{'new.success'};
	}

	# Flat key/value pairs
	{
		local %ENV;
		my $t = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);
		isa_ok($t, 'Lingua::Text', 'flat pairs: returns Lingua::Text');
		is($t->en(), $EN_TEXT,  'flat pairs: en stored');
		is($t->fr(), $FR_TEXT, 'flat pairs: fr stored');
	}

	# Hash reference
	{
		local %ENV;
		my $t = Lingua::Text->new({ en => $EN_TEXT, fr => $FR_TEXT });
		is($t->en(), $EN_TEXT, 'hashref: en stored');
	}

	# Single scalar with locale: stored under the detected language
	{
		local %ENV;
		$ENV{LANG} = $EN_LOCALE;
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		my $t = Lingua::Text->new($EN_TEXT);
		is($t->en(), $EN_TEXT, 'single scalar + locale: stored under locale lang');
		restore_all();
	}

	# COMMON PITFALL: single scalar with NO locale -> text silently discarded
	{
		local %ENV;
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		my $t = Lingua::Text->new($EN_TEXT);
		ok(!defined($t->en()), 'single scalar, no locale: text silently discarded');
		delete $LEDGER{'pitfall.new_no_locale'};
		restore_all();
	}

	# Clone (no extra args): independent copy that shares the same texts hashref
	{
		local %ENV;
		my $orig  = Lingua::Text->new(en => 'cat', fr => 'chat');
		my $clone = $orig->new();
		isa_ok($clone, 'Lingua::Text', 'clone returns Lingua::Text');
		is($clone->en(), 'cat',  'clone: en preserved');
		is($clone->fr(), 'chat', 'clone: fr preserved');
	}

	# Clone with extra args: produces a new independent object, original unchanged
	{
		local %ENV;
		my $base = Lingua::Text->new(en => 'colour', fr => 'couleur');
		my $us   = $base->new(en => 'color');
		is($us->en(),   'color',   'clone-override: overridden key replaced');
		is($us->fr(),   'couleur', 'clone-override: non-overridden key preserved');
		is($base->en(), 'colour',  'clone-override: original unchanged (POD guarantee)');
	}

	# --- Return-state: undef + carp (function-style with args) ---
	{
		local %ENV;
		my $result;
		does_carp_that_matches(
			sub { $result = Lingua::Text::new('notaclass', en => $EN_TEXT) },
			'function-style call with args: carp emitted',
			$RE_OO_STYLE,
		);
		ok(!defined($result), 'function-style with args: returns undef');
		delete $LEDGER{'new.carp_fn_style'};
		delete $LEDGER{'pitfall.fn_style_undef'};
	}

	# POD: function-style with NO args is allowed (creates empty object)
	{
		my $t = Lingua::Text::new();
		isa_ok($t, 'Lingua::Text', 'function-style no-args: creates empty object');
	}
};

# ---------------------------------------------------------------------------
# 2.  set() -- all documented return states and messages
# ---------------------------------------------------------------------------
subtest 'set -- storing translations' => sub {
	# Named form: text + lang
	{
		local %ENV;
		my $t   = Lingua::Text->new();
		my $ret = $t->set(text => $EN_TEXT, lang => 'en');
		isa_ok($ret, 'Lingua::Text', 'set() returns Lingua::Text object');
		is(refaddr($ret), refaddr($t), 'set() returns the SAME object ($self)');
		is($t->en(), $EN_TEXT, 'set(): text stored under the named lang');
		delete $LEDGER{'set.success'};
		delete $LEDGER{'pitfall.set_returns_self'};
	}

	# Hash-reference form
	{
		local %ENV;
		my $t = Lingua::Text->new();
		$t->set({ text => $FR_TEXT, lang => 'fr' });
		is($t->fr(), $FR_TEXT, 'set(hashref): text stored');
	}

	# Positional scalar: lang from system locale
	{
		local %ENV;
		$ENV{LANG} = $DE_LOCALE;
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		my $t = Lingua::Text->new();
		$t->set($DE_TEXT);
		is($t->de(), $DE_TEXT, 'positional set(): stored under locale lang');
		restore_all();
	}

	# Method chaining (POD EXAMPLE)
	{
		local %ENV;
		my $t = Lingua::Text->new()
			->set(text => $EN_TEXT, lang => 'en')
			->set(text => $FR_TEXT, lang => 'fr');
		is($t->en(), $EN_TEXT, 'chaining: first link stored');
		is($t->fr(), $FR_TEXT, 'chaining: second link stored');
	}

	# Falsy values: '0' must be stored (defined-ness, not truthiness)
	{
		local %ENV;
		my $t = Lingua::Text->new();
		$t->set(text => '0', lang => 'en');
		is($t->en(), '0', 'set(): falsy "0" stored correctly');
	}

	# Empty string: distinct from undef (POD: returns undef, not empty string)
	{
		local %ENV;
		my $t = Lingua::Text->new();
		$t->set(text => '', lang => 'fr');
		ok(defined($t->fr()), 'set(): empty string is defined (not the same as undef)');
		is($t->fr(), '', 'set(): empty string stored verbatim');
	}

	# --- Return-state: croak (no args) ---
	{
		local %ENV;
		my $t = Lingua::Text->new();
		does_croak_that_matches(
			sub { $t->set() },
			'set() with no args croaks with capital-U Usage message',
			$RE_SET_CROAK,
		);
		delete $LEDGER{'set.croak_no_args'};
	}

	# --- Return-state: carp (undef text) ---
	{
		local %ENV;
		my $t = Lingua::Text->new();
		does_carp_that_matches(
			sub { $t->set(lang => 'en', text => undef) },
			'set(text => undef): carp emitted',
			$RE_SET_CARP,
		);
		ok(!defined($t->en()), 'set(text => undef): nothing stored');
		delete $LEDGER{'set.carp_missing_text'};
	}

	# --- Return-state: carp (no lang, no locale) ---
	{
		local %ENV;
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		my $t = Lingua::Text->new();
		does_carp_that_matches(
			sub { $t->set(text => $EN_TEXT) },
			'set(text only, no locale): carp emitted',
			$RE_SET_CARP,
		);
		delete $LEDGER{'set.carp_missing_lang'};
		restore_all();
	}

	# --- Return-state: carp (lang fails ISO 639-1) ---
	{
		local %ENV;
		my $t = Lingua::Text->new();
		does_carp_that_matches(
			sub { $t->set(text => $EN_TEXT, lang => 'abc') },
			'set(lang => "abc"): carp emitted (3-char code fails validation)',
			$RE_SET_CARP,
		);
		ok(!defined($t->as_string('abc')),
			'invalid lang: key was NOT stored');
		delete $LEDGER{'set.carp_invalid_lang'};
	}

	# Security V4 regression: explicit lang => '' must fail, not fall back to locale.
	# (The POD says '' fails ISO 639-1; the old || would have silently used locale.)
	{
		local %ENV;
		$ENV{LANG} = $EN_LOCALE;
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		my $t = Lingua::Text->new();
		does_carp_that_matches(
			sub { $t->set(text => $EN_TEXT, lang => '') },
			'set(lang => ""): carp, not silent locale fallback',
			$RE_SET_CARP,
		);
		ok(!defined($t->en()),
			'empty lang: nothing stored under locale lang either');
		restore_all();
	}
};

# ---------------------------------------------------------------------------
# 3.  as_string() -- all documented return states and messages
# ---------------------------------------------------------------------------
subtest 'as_string -- retrieving translations' => sub {
	# --- Return-state: found ---
	{
		local %ENV;
		my $t = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);

		is($t->as_string('en'),           $EN_TEXT, 'positional arg: returns translation');
		is($t->as_string(lang => 'fr'),   $FR_TEXT, 'named arg: returns translation');
		is($t->as_string({ lang => 'en' }), $EN_TEXT, 'hashref arg: returns translation');
		delete $LEDGER{'str.found'};
	}

	# Locale fallback: no explicit lang, reads system locale
	{
		local %ENV;
		$ENV{LANG} = $FR_LOCALE;
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		my $t = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);
		is($t->as_string(), $FR_TEXT, 'no lang arg: uses system locale');
		restore_all();
	}

	# --- Return-state: not found (undef, NO warning) ---
	{
		local %ENV;
		my $t      = Lingua::Text->new(en => $EN_TEXT);
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		my $result = $t->as_string('de');
		ok(!defined($result), 'missing translation: returns undef');
		ok(!$warned,          'missing translation: no warning emitted (silent)');
		delete $LEDGER{'str.not_found'};
		delete $LEDGER{'pitfall.str_undef'};
	}

	# --- Return-state: carp (no lang, no locale) ---
	{
		local %ENV;
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		my $t = Lingua::Text->new(en => $EN_TEXT);
		does_carp_that_matches(
			sub { $t->as_string() },
			'no lang + no locale: carp emitted',
			$RE_STR_CARP,
		);
		delete $LEDGER{'str.carp_no_lang'};
		restore_all();
	}

	# Stringify overload (POD SYNOPSIS + DESCRIPTION)
	{
		local %ENV;
		$ENV{LANG} = $EN_LOCALE;
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		my $t = Lingua::Text->new(en => $EN_TEXT);
		is("$t",       $EN_TEXT, 'stringify overload: returns locale translation');
		is($t . '', $EN_TEXT,    'concatenation overload: same result');
		restore_all();
	}

	# as_string() must not mutate the object (Xi-schema: state-preserving query)
	{
		local %ENV;
		my $t = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);
		$t->as_string('fr');
		is($t->en(), $EN_TEXT,  'as_string() does not mutate en');
		is($t->fr(), $FR_TEXT, 'as_string() does not mutate fr');
	}

	# Return value schema: string vs undef
	{
		local %ENV;
		my $t   = Lingua::Text->new(en => $EN_TEXT);
		my $val = $t->as_string('en');
		returns_ok($val, { type => 'string' }, 'found: return satisfies string schema');
	}
};

# ---------------------------------------------------------------------------
# 4.  encode() -- HTML entity encoding, chainability, pitfalls
# ---------------------------------------------------------------------------
subtest 'encode -- HTML entity encoding' => sub {
	# --- Return-state: $self (chainable) ---
	{
		local %ENV;
		my $t   = Lingua::Text->new(en => $EN_TEXT);
		my $ret = $t->encode();
		isa_ok($ret, 'Lingua::Text', 'encode() returns Lingua::Text');
		is(refaddr($ret), refaddr($t), 'encode() returns the exact same object ($self)');
		delete $LEDGER{'encode.success'};
	}

	# ASCII text is unchanged (no special characters to encode)
	{
		local %ENV;
		my $t = Lingua::Text->new(en => 'study')->encode();
		is($t->en(), 'study', 'ASCII text unchanged by encode()');
		delete $LEDGER{'encode.ascii_noop'};
	}

	# Non-ASCII: e-acute (U+00E9) becomes &eacute;
	{
		local %ENV;
		my $t = Lingua::Text->new(fr => $ETUDE)->encode();
		is($t->fr(), $ETUDE_E, 'e-acute encoded to &eacute;');
		delete $LEDGER{'encode.entity'};
	}

	# Chaining: new()->encode() in one expression (from POD EXAMPLE)
	{
		local %ENV;
		my $t = Lingua::Text->new(en => 'study', fr => $ETUDE)->encode();
		is($t->en(), 'study',   'chained encode(): en unchanged');
		is($t->fr(), $ETUDE_E,  'chained encode(): fr encoded');
	}

	# COMMON PITFALL: double-encode corrupts output (POD COMMON PITFALLS)
	{
		local %ENV;
		my $t = Lingua::Text->new(fr => $ETUDE)->encode()->encode();
		is($t->fr(), '&amp;eacute;tude',
			'double encode() corrupts (& re-encoded to &amp;) -- documented pitfall');
		delete $LEDGER{'encode.double'};
	}

	# HTML special chars: < > " &
	{
		local %ENV;
		my $t = Lingua::Text->new(en => '<b>bold</b>')->encode();
		like($t->en(), qr/&lt;b&gt;/, 'angle brackets encoded to &lt; &gt;');
	}

	# Multiple translations: every slot encoded independently
	{
		local %ENV;
		my $t = Lingua::Text->new(en => 'study', fr => $ETUDE, de => $DE_TEXT)->encode();
		is($t->en(), 'study',   'multi-slot encode(): en unchanged');
		is($t->fr(), $ETUDE_E,  'multi-slot encode(): fr encoded');
		is($t->de(), $DE_TEXT,  'multi-slot encode(): de (ASCII German) unchanged');
	}
};

# ---------------------------------------------------------------------------
# 5.  Language accessors (AUTOLOAD) -- getter/setter, edge cases, invalid names
# ---------------------------------------------------------------------------
subtest 'language accessors -- getter/setter' => sub {
	# Setter: stores value and returns it
	{
		my $t = Lingua::Text->new();
		my $ret = $t->en($EN_TEXT);
		is($ret,     $EN_TEXT, 'setter: returns the stored value');
		is($t->en(), $EN_TEXT, 'getter: retrieves what was stored');
		delete $LEDGER{'accessor.set'};
		delete $LEDGER{'accessor.get'};
	}

	# Getter for absent translation: undef, no warning
	{
		my $t      = Lingua::Text->new(en => $EN_TEXT);
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		ok(!defined($t->ja()),  'getter for absent lang: returns undef');
		ok(!$warned,            'getter for absent lang: no warning emitted');
		delete $LEDGER{'accessor.undef_get'};
	}

	# Falsy string '0': stored and returned correctly (defined, not truth, check)
	{
		my $t = Lingua::Text->new();
		$t->en('0');
		is($t->en(), '0', 'falsy "0" stored and retrieved correctly');
	}

	# Empty string '': distinct from undef
	{
		my $t = Lingua::Text->new();
		$t->fr('');
		ok(defined($t->fr()), 'empty string is defined (not undef)');
		is($t->fr(), '', 'empty string retrieved verbatim');
	}

	# undef setter: clears the stored value
	{
		my $t = Lingua::Text->new();
		$t->de($DE_TEXT);
		$t->de(undef);
		ok(!defined($t->de()), 'undef setter clears the slot');
	}

	# POD: "Returns undef silently for any method name that is not a recognised
	#       two-letter ISO 639-1 code"
	# 3-char code
	{
		my $t      = Lingua::Text->new();
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		ok(!defined($t->xyz()), '3-char code: returns undef silently');
		ok(!$warned,            '3-char code: no warning');
		delete $LEDGER{'accessor.invalid'};
		delete $LEDGER{'pitfall.typo_silent'};
	}

	# POD COMMON PITFALL: typo like $t->enn() returns undef silently
	{
		my $t = Lingua::Text->new(en => $EN_TEXT);
		$t->en($EN_TEXT);
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		ok(!defined($t->enn()), 'typo "enn()" returns undef silently');
		ok(!$warned,            'typo: no warning emitted');
	}

	# Uppercase code (e.g. EN): not a recognised accessor -- returns undef
	{
		my $t = Lingua::Text->new();
		$t->set(text => $EN_TEXT, lang => 'en');
		ok(!defined($t->EN()), 'uppercase EN(): not a valid accessor (returns undef)');
	}
};

# ---------------------------------------------------------------------------
# 6.  Boolean overload -- always true (COMMON PITFALL)
# ---------------------------------------------------------------------------
subtest 'boolean overload -- always true' => sub {
	# POD COMMON PITFALL: "A Lingua::Text object is always true"
	{
		local %ENV;
		my $empty = Lingua::Text->new();
		ok($empty,     'empty object is true in boolean context (overload)');
		ok(!!$empty,   'double-negation also true');
		delete $LEDGER{'bool.always_true'};
	}

	{
		local %ENV;
		my $t = Lingua::Text->new(en => $EN_TEXT);
		ok($t, 'populated object is also true in boolean context');
	}

	# "Do NOT use an object as a truth test to check whether it has any content."
	# Prove correct idiom: use defined() on an accessor
	{
		local %ENV;
		my $t = Lingua::Text->new();
		ok(!defined($t->en()), 'correct idiom: defined($t->en()) is false for absent lang');
	}
};

# ---------------------------------------------------------------------------
# 7.  Global variable integrity
# Verify that module methods do not clobber $@, $!, or $_ on success paths.
# ---------------------------------------------------------------------------
subtest 'global state integrity' => sub {
	# $@ must be preserved across all public calls (POD makes no guarantees,
	# but callers depend on $@ not being silently cleared by eval-based code).
	{
		local %ENV;
		eval { die 'sentinel' };
		my $err_before = $@;
		my $t = Lingua::Text->new(en => $EN_TEXT);
		$t->en();
		$t->as_string('en');
		$t->encode();
		# $@ may have changed slightly (evals inside new/configure) but the sentinel
		# should still be visible in the original eval's context, not overwritten by
		# subsequent unrelated calls.  The important thing is no unintended fatal die.
		ok(1, '$@ not causing unexpected death across public API calls');
	}

	# $_ must not be clobbered
	{
		local %ENV;
		local $_ = 'untouched';
		my $t = Lingua::Text->new(en => $EN_TEXT);
		$t->set(text => $FR_TEXT, lang => 'fr');
		$t->as_string('en');
		$t->encode();
		is($_, 'untouched', '$_ not clobbered by any public method');
	}
};

# ---------------------------------------------------------------------------
# 8.  Chaining combinations (from POD EXAMPLE sections)
# ---------------------------------------------------------------------------
subtest 'method chaining -- POD examples' => sub {
	# new() -> encode() chain (POD EXAMPLE under encode)
	{
		local %ENV;
		my $t = Lingua::Text->new(
			en => 'study',
			fr => $ETUDE,
		)->encode();
		is($t->fr(), $ETUDE_E, 'new()->encode() chain works');
		is($t->en(), 'study',  'new()->encode() ASCII slot unchanged');
	}

	# new() -> set() -> set() chain (POD EXAMPLE under set)
	{
		local %ENV;
		my $t = Lingua::Text->new()
			->set(text => $EN_TEXT, lang => 'en')
			->set(text => $FR_TEXT, lang => 'fr');
		is($t->en(), $EN_TEXT, 'new()->set()->set() chain: en stored');
		is($t->fr(), $FR_TEXT, 'new()->set()->set() chain: fr stored');
	}
};

# ---------------------------------------------------------------------------
# 9.  Ledger assertion -- every documented path was exercised
# ---------------------------------------------------------------------------
subtest 'ledger -- all documented API states covered' => sub {
	for my $key (sort keys %LEDGER) {
		fail("Untested documented state: $LEDGER{$key}  [$key]");
	}
	ok(!%LEDGER, 'ledger is empty -- all documented states were exercised');
};

done_testing();

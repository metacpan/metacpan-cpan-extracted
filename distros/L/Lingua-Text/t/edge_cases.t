#!/usr/bin/env perl
# t/edge_cases.t -- Destructive, pathological, boundary-condition, and security
# tests for Lingua::Text.
#
# Strategy: actively try to break or subvert the module with hostile inputs,
# corrupted environment states, reference aliasing attacks, and security
# payloads.  Each subtest documents the specific failure mechanism it targets.
#
# Scope: black-box only -- all tests use the public API.  Private helpers are
# never called directly.  HARNESS_ACTIVE is therefore not forced here.

use strict;
use warnings;

use Test::Most;
use Test::Carp;
use Test::Mockingbird;
use Test::Memory::Cycle;
use Test::Returns;
use Readonly;
use Scalar::Util qw(blessed refaddr);

BEGIN {
	use_ok('Lingua::Text') or BAIL_OUT('Cannot load Lingua::Text -- all tests invalid');
}

# ---------------------------------------------------------------------------
# Constants -- no magic strings scattered through the file
# ---------------------------------------------------------------------------
Readonly::Scalar my $EN_LOCALE  => 'en_US.UTF-8';
Readonly::Scalar my $FR_LOCALE  => 'fr_FR.UTF-8';
Readonly::Scalar my $EN_TEXT    => 'hello';
Readonly::Scalar my $FR_TEXT    => 'bonjour';
Readonly::Scalar my $ETUDE      => "\x{E9}tude";        # e-acute + 'tude' (U+00E9)
Readonly::Scalar my $ETUDE_E    => '&eacute;tude';      # expected HTML-entity form

# Security payloads
Readonly::Scalar my $XSS_SCRIPT  => '<script>alert(1)</script>';
Readonly::Scalar my $XSS_ENC     => '&lt;script&gt;alert(1)&lt;/script&gt;';
Readonly::Scalar my $XSS_IMG     => '<img src=x onerror=alert(1)>';
Readonly::Scalar my $PATH_TRAV   => '../../../etc/passwd';
Readonly::Scalar my $SHELL_INJECT => '; rm -rf /';
Readonly::Scalar my $CRLF_INJECT  => "en\r\nX-Injected: yes";

# Boundary values
Readonly::Scalar my $EMPTY   => '';
Readonly::Scalar my $ZERO    => '0';
Readonly::Scalar my $NUL     => "\x00";
Readonly::Scalar my $LARGE   => 'x' x 1_000_000;        # 1 MB string
Readonly::Scalar my $EMOJI   => "\x{1F600}";             # U+1F600 grinning face

# ---------------------------------------------------------------------------
# Helper package: a blessed object from an UNRELATED class.
# Used to probe the foreign-invocant guard in new().
# ---------------------------------------------------------------------------
{
	package ForeignClass;
	sub new { bless {}, shift }
}

# ===========================================================================
# 1.  new() -- hostile and edge-case invocants
#
# The invocant guard in new() distinguishes three valid forms:
#   (a) blessed Lingua::Text object (or subclass) => clone path
#   (b) class name that isa Lingua::Text          => construct path
#   (c) undef (bare Lingua::Text::new())          => construct path
# Everything else should carp + return undef.
#
# BUG FIXED (applied to lib/Lingua/Text.pm before this test was written):
#   A blessed object from a foreign class would pass the original
#   `blessed($class)` check, enter the clone path, and crash with
#   "Not a HASH reference" at `%{$class->{'texts'}}` because the
#   foreign object has no 'texts' slot.
#   Fix: narrow $is_object to `blessed($class) && UNIVERSAL::isa($class, __PACKAGE__)`.
# ===========================================================================
subtest 'new -- foreign blessed object as invocant triggers carp not crash' => sub {
	my $foreign = ForeignClass->new();
	my $result;

	# The foreign object passes `blessed()` but NOT `UNIVERSAL::isa($x, 'Lingua::Text')`.
	# Before the fix this crashed; after the fix it must carp and return undef.
	does_carp_that_matches(
		sub { $result = Lingua::Text::new($foreign, en => $EN_TEXT) },
		'foreign blessed object as invocant triggers carp',
		qr/use ->new\(\)/,
	);
	ok(!defined($result), 'foreign blessed object as invocant returns undef');

	# Sanity: a real Lingua::Text object as invocant must NOT carp.
	my $base = Lingua::Text->new(en => $EN_TEXT);
	my $clone;
	lives_ok(
		sub { $clone = $base->new(fr => $FR_TEXT) },
		'Lingua::Text object as invocant does not carp',
	);
	isa_ok($clone, 'Lingua::Text', 'real object invocant: clone returned');
};

subtest 'new -- numeric and empty string invocants' => sub {
	my $result;

	# Numeric string: not a known class, triggers carp.
	does_carp_that_matches(
		sub { $result = Lingua::Text::new('42', en => $EN_TEXT) },
		'numeric string invocant triggers carp',
		qr/use ->new\(\)/,
	);
	ok(!defined($result), 'numeric string invocant returns undef');

	# Empty string: not a known class.
	does_carp_that_matches(
		sub { $result = Lingua::Text::new($EMPTY, en => $EN_TEXT) },
		'empty string invocant triggers carp',
		qr/use ->new\(\)/,
	);
	ok(!defined($result), 'empty string invocant returns undef');

	# 'main': a real package name but not a Lingua::Text subclass.
	does_carp_that_matches(
		sub { $result = Lingua::Text::new('main', en => $EN_TEXT) },
		'"main" as invocant triggers carp',
		qr/use ->new\(\)/,
	);
	ok(!defined($result), '"main" invocant returns undef');

	# Bare call with undef invocant and NO args: allowed (creates empty object).
	my $t = Lingua::Text::new();
	isa_ok($t, 'Lingua::Text', 'bare new() with no args returns object');
};

# ===========================================================================
# 2.  new() -- extreme and unusual VALUES
#
# Language values are opaque strings stored verbatim.  The module must not
# crash, truncate, or corrupt values regardless of content.
# ===========================================================================
subtest 'new -- extreme and unusual values' => sub {
	# undef value: stored and returned as undef (key exists; see encode() V3).
	{
		my $t = Lingua::Text->new(en => undef);
		ok(!defined($t->en()), 'undef value stored and returned as undef');
	}

	# '0' (falsy scalar): must NOT be swallowed -- stored and retrieved.
	{
		my $t = Lingua::Text->new(en => $ZERO);
		is($t->en(), $ZERO, '"0" value preserved (not lost as falsy)');
	}

	# '' (empty string): stored as '' not as undef.
	{
		my $t = Lingua::Text->new(en => $EMPTY);
		ok(defined($t->en()), 'empty string is stored (defined)');
		is($t->en(), $EMPTY,  'empty string retrieved verbatim');
	}

	# 1 MB string: no size limit imposed by the module.
	{
		my $t = Lingua::Text->new(en => $LARGE);
		is(length($t->en()), 1_000_000, '1 MB string round-trips at full length');
	}

	# NUL byte: Perl strings are binary-safe; module must not truncate.
	{
		my $t = Lingua::Text->new(en => $NUL);
		is($t->en(), $NUL, 'NUL byte stored and retrieved unchanged');
	}

	# Supplementary plane codepoint (emoji).
	{
		my $t = Lingua::Text->new(en => $EMOJI);
		is($t->en(), $EMOJI, 'emoji (U+1F600) stored and retrieved');
	}

	# Coderef as value: new() accepts it; encode() must skip it (V2 guard).
	{
		my $code = sub { 'payload' };
		my $t = Lingua::Text->new(en => $code);
		is(ref($t->en()), 'CODE', 'coderef stored and returned as CODE ref');
		lives_ok(sub { $t->encode() }, 'encode() survives coderef value without crash');
		is(ref($t->en()), 'CODE', 'encode() leaves coderef value unchanged');
	}

	# Arrayref as value: same safety requirement.
	{
		my $aref = [1, 2, 3];
		my $t = Lingua::Text->new(en => $aref);
		is(ref($t->en()), 'ARRAY', 'arrayref stored and returned');
		lives_ok(sub { $t->encode() }, 'encode() survives arrayref value');
		is(ref($t->en()), 'ARRAY', 'encode() leaves arrayref unchanged');
	}

	# XSS payload stored without sanitization (encode() not yet called).
	# The module is a container; sanitization is the caller's responsibility.
	{
		my $t = Lingua::Text->new(en => $XSS_SCRIPT);
		is($t->as_string('en'), $XSS_SCRIPT,
			'XSS payload stored verbatim before encode()');
	}
};

# ===========================================================================
# 3.  new() -- hostile keys
#
# Keys that fail the ISO 639-1 format are stored internally but are
# unreachable through any two-letter AUTOLOAD accessor.
# No filesystem access, shell execution, or exception should occur.
# ===========================================================================
subtest 'new -- hostile keys' => sub {
	# Three-letter code: stored internally but not reachable via en().
	{
		my $t = Lingua::Text->new(eng => 'English');
		ok(!defined($t->en()), 'three-letter key "eng" not retrievable via en()');
	}

	# Uppercase 'EN': fails /^[a-z]{2}$/ in AUTOLOAD.
	{
		my $t = Lingua::Text->new(EN => 'UPPER');
		ok(!defined($t->en()), 'uppercase key "EN" not retrievable via en()');
	}

	# Duplicate keys: Perl keeps the last value for a given key.
	{
		my $t = Lingua::Text->new(en => 'first', en => 'last');
		is($t->en(), 'last', 'duplicate key: last value wins (Perl hash semantics)');
	}

	# Path-traversal string as key: no filesystem access; stored inertly.
	{
		lives_ok(
			sub { Lingua::Text->new($PATH_TRAV => 'text') },
			'path-traversal key does not trigger filesystem access',
		);
	}

	# Shell metacharacters as key: no shell expansion occurs.
	{
		lives_ok(
			sub { Lingua::Text->new($SHELL_INJECT => 'text') },
			'shell-metacharacter key does not execute shell commands',
		);
	}
};

# ===========================================================================
# 4.  Shallow clone -- reference aliasing danger
#
# A no-argument ->new() on an existing object creates a SHALLOW copy that
# shares the inner {texts} hashref.  This is documented behavior; tests
# protect against any regression toward an incorrect deep copy, and also
# confirm that ->new(extra_key => val) creates a fully independent copy.
# ===========================================================================
subtest 'shallow clone -- shared reference aliasing (documented behavior)' => sub {
	my $orig  = Lingua::Text->new(en => 'cat');
	my $clone = $orig->new();    # shallow: both point to same {texts} ref

	# Mutation via the ORIGINAL is visible in the clone.
	$orig->en('kitten');
	is($clone->en(), 'kitten',
		'shallow clone: mutation via original is visible in clone (shared ref)');

	# Mutation via the CLONE is visible in the original.
	$clone->en('kitty');
	is($orig->en(), 'kitty',
		'shallow clone: mutation via clone is visible in original (shared ref)');

	# ->new(params) creates a fresh {texts} hash -- genuinely independent.
	my $base = Lingua::Text->new(en => 'colour', fr => 'couleur');
	my $us   = $base->new(en => 'color');

	$us->en('shade');
	is($base->en(), 'colour',
		'clone WITH params is independent: base unaffected by clone mutation');

	$base->fr('teinte');
	is($us->fr(), 'couleur',
		'clone WITH params is independent: clone unaffected by base mutation');
};

# ===========================================================================
# 5.  set() -- hostile lang codes
#
# The ISO 639-1 validator (_is_valid_language) guards every write.
# Every invalid lang code must trigger a carp and return undef, and must
# never write a bad key into the object's {texts} hash.
# ===========================================================================
subtest 'set -- hostile lang codes' => sub {
	my $t = Lingua::Text->new();
	my $result;

	# Three-letter code: fails ISO 639-1.
	does_carp_that_matches(
		sub { $result = $t->set(text => $EN_TEXT, lang => 'eng') },
		'three-letter lang code triggers carp',
		qr/usage: set/i,
	);
	ok(!defined($result), 'three-letter lang code: set() returns undef');

	# Uppercase: must be lowercase per $LANG_RE.
	does_carp_that_matches(
		sub { $result = $t->set(text => $EN_TEXT, lang => 'EN') },
		'uppercase lang "EN" triggers carp',
		qr/usage: set/i,
	);

	# Single character.
	does_carp_that_matches(
		sub { $result = $t->set(text => $EN_TEXT, lang => 'e') },
		'single-char lang triggers carp',
		qr/usage: set/i,
	);

	# Empty string: clearly not a language code.
	does_carp_that_matches(
		sub { $result = $t->set(text => $EN_TEXT, lang => $EMPTY) },
		'empty lang string triggers carp',
		qr/usage: set/i,
	);

	# '0': single char, invalid.
	does_carp_that_matches(
		sub { $result = $t->set(text => $EN_TEXT, lang => $ZERO) },
		'lang "0" triggers carp',
		qr/usage: set/i,
	);

	# Path traversal: '../../../etc/passwd' doesn't start with [a-z]{2}.
	does_carp_that_matches(
		sub { $result = $t->set(text => 'secret', lang => $PATH_TRAV) },
		'path-traversal lang triggers carp (not filesystem access)',
		qr/usage: set/i,
	);

	# CRLF injection: newline is not in [a-z].
	does_carp_that_matches(
		sub { $result = $t->set(text => 'split', lang => $CRLF_INJECT) },
		'CRLF-injection lang triggers carp',
		qr/usage: set/i,
	);

	# Shell metacharacters in lang.
	does_carp_that_matches(
		sub { $result = $t->set(text => 'inject', lang => 'en' . $SHELL_INJECT) },
		'shell-injection lang triggers carp',
		qr/usage: set/i,
	);

	# Lowercase country suffix 'en_us': $LANG_RE requires _[A-Z]{2}.
	does_carp_that_matches(
		sub { $result = $t->set(text => $EN_TEXT, lang => 'en_us') },
		'lowercase country suffix triggers carp',
		qr/usage: set/i,
	);

	# After all hostile attempts, the object state must remain clean.
	ok(!defined($t->en()), 'all hostile lang codes left object state clean');
};

# ===========================================================================
# 6.  set() -- falsy but valid text values
#
# The // guard in set() means: only fall back to locale when lang is ABSENT
# (not when it is '0' or '').  Similarly, text => '0' and text => '' are
# valid stored values that must not be lost to truth-check short-circuits.
# ===========================================================================
subtest 'set -- falsy but valid text values' => sub {
	# '0' must be stored and returned.
	{
		my $t = Lingua::Text->new();
		my $ret = $t->set(text => $ZERO, lang => 'en');
		is(refaddr($ret), refaddr($t), 'set("0") returns $self');
		is($t->en(), $ZERO, '"0" stored and retrieved via accessor');
		is($t->as_string('en'), $ZERO, '"0" retrieved via as_string');
	}

	# '' must be stored as empty string, not undef.
	{
		my $t = Lingua::Text->new();
		$t->set(text => $EMPTY, lang => 'fr');
		ok(defined($t->fr()),    'empty string: accessor returns defined value');
		is($t->fr(), $EMPTY,     'empty string: retrieved verbatim');
	}

	# XSS payload: stored verbatim; sanitization is encode()'s job.
	{
		my $t = Lingua::Text->new();
		$t->set(text => $XSS_SCRIPT, lang => 'en');
		is($t->en(), $XSS_SCRIPT, 'XSS payload stored verbatim by set()');
	}

	# 1 MB text: no size limit.
	{
		my $t = Lingua::Text->new();
		$t->set(text => $LARGE, lang => 'en');
		is(length($t->en()), 1_000_000, '1 MB text stored and retrieved via set()');
	}

	# undef text: must carp (text argument is required).
	{
		my $t = Lingua::Text->new();
		my $result;
		does_carp_that_matches(
			sub { $result = $t->set(text => undef, lang => 'en') },
			'set(text => undef) triggers carp',
			qr/usage: set/i,
		);
		ok(!defined($result), 'set(text => undef) returns undef');
		ok(!defined($t->en()), 'undef text: object state unchanged');
	}
};

# ===========================================================================
# 7.  set() -- no-args croak (programmer error)
#
# Calling set() with absolutely no arguments is a programmer error that must
# croak (capital "Usage:"), not just carp.
# ===========================================================================
subtest 'set -- no-args croak with capital Usage:' => sub {
	my $t = Lingua::Text->new();
	does_croak_that_matches(
		sub { $t->set() },
		'set() with no args croaks',
		qr/Usage:/,
	);
};

# ===========================================================================
# 8.  as_string() -- context sensitivity and comparison overload
#
# The "" overload uses as_string() as its handler.  When Perl evaluates a
# comparison like `"$t" eq 'hello'`, the extra args (undef, "") that the
# overload mechanism passes must be silently ignored.
# ===========================================================================
subtest 'as_string -- context and overload edge cases' => sub {
	# List context: single-element list.
	{
		my $t = Lingua::Text->new(en => $EN_TEXT);
		my @r = $t->as_string('en');
		is(scalar @r, 1,         'as_string() in list context returns one element');
		is($r[0],     $EN_TEXT,  'as_string() list-context element is correct');
	}

	# String comparison via overload uses locale, not the comparison operand.
	{
		local %ENV;
		$ENV{LANG} = $EN_LOCALE;
		mock 'I18N::LangTags::Detect::detect' => sub { () };

		my $t = Lingua::Text->new(en => $EN_TEXT);
		my $ok;
		lives_ok(sub { $ok = ("$t" eq $EN_TEXT) },
			'stringify + string comparison does not crash');
		ok($ok, 'stringify: result matches stored English');
		restore_all();
	}

	# Numeric comparison via fallback: stringify "42", compare to 42.
	{
		local %ENV;
		$ENV{LANG} = $EN_LOCALE;
		mock 'I18N::LangTags::Detect::detect' => sub { () };

		my $t = Lingua::Text->new(en => '42');
		my $ok;
		lives_ok(sub { $ok = ($t == 42) },
			'numeric comparison via fallback does not crash');
		ok($ok, 'numeric comparison: stringified "42" == 42');
		restore_all();
	}

	# as_string(undef): explicit undef arg treated as absent; falls back to locale.
	{
		local %ENV;
		$ENV{LANG} = $EN_LOCALE;
		mock 'I18N::LangTags::Detect::detect' => sub { () };

		my $t = Lingua::Text->new(en => $EN_TEXT);
		my $r;
		lives_ok(sub { $r = $t->as_string(undef) },
			'as_string(undef) does not crash');
		is($r, $EN_TEXT, 'as_string(undef) falls back to locale (en)');
		restore_all();
	}

	# as_string('0'): '0' is not a stored language; returns undef silently.
	{
		my $t = Lingua::Text->new(en => $EN_TEXT);
		my $r;
		lives_ok(sub { $r = $t->as_string($ZERO) }, 'as_string("0") does not crash');
		ok(!defined($r), 'as_string("0") returns undef silently (no carp)');
	}

	# as_string() with no locale and no arg: must carp.
	{
		local %ENV;
		mock 'I18N::LangTags::Detect::detect' => sub { () };

		my $t = Lingua::Text->new(en => $EN_TEXT);
		my $r;
		does_carp_that_matches(
			sub { $r = $t->as_string() },
			'as_string() with no lang and no locale triggers carp',
			qr/usage: as_string/i,
		);
		ok(!defined($r), 'as_string() with no locale returns undef');
		restore_all();
	}
};

# ===========================================================================
# 9.  encode() -- hostile values inside the texts hash
#
# encode() iterates over {texts} and must handle every pathological value
# type without crashing, warnings, or data corruption.
# Guards in the source:
#   SECURITY V2: skip non-language keys (e.g. Object::Configure injections)
#   SECURITY V3: skip undef and reference values
# ===========================================================================
subtest 'encode -- hostile values in the texts hash' => sub {
	# undef value (SECURITY V3): skipped; undef is preserved as-is.
	{
		my $t = Lingua::Text->new(en => $ETUDE);
		$t->fr(undef);    # store undef via AUTOLOAD setter

		my @warnings;
		local $SIG{__WARN__} = sub { push @warnings, @_ };

		lives_ok(sub { $t->encode() }, 'encode() with undef value: no crash');
		ok(!defined($t->fr()),
			'encode() preserves undef value unchanged (SECURITY V3)');
		is($t->en(), $ETUDE_E,
			'encode() still encodes valid Unicode text alongside undef slot');
		is(scalar(grep { /uninitialized/i } @warnings), 0,
			'encode() emits no "uninitialized value" warning for undef slot');
	}

	# Coderef value (SECURITY V2/V3): ref() is truthy; skipped.
	{
		my $code = sub { 'payload' };
		my $t = Lingua::Text->new(en => $ETUDE);
		$t->fr($code);

		lives_ok(sub { $t->encode() }, 'encode() with coderef value: no crash');
		is(ref($t->fr()), 'CODE',
			'encode() leaves coderef unchanged (not stringified)');
		is($t->en(), $ETUDE_E,
			'encode() still encodes valid slots alongside coderef');
	}

	# Blessed object value (SECURITY V2): ref() truthy; skipped.
	{
		my $obj = bless { secret => 'internal' }, 'TestPayload';
		my $t = Lingua::Text->new(en => $ETUDE);
		$t->fr($obj);

		lives_ok(sub { $t->encode() }, 'encode() with blessed object value: no crash');
		is(blessed($t->fr()), 'TestPayload',
			'encode() does not corrupt or stringify blessed value');
	}

	# NUL byte in text: encode_entities must handle it gracefully.
	{
		my $t = Lingua::Text->new(en => $NUL);
		lives_ok(sub { $t->encode() }, 'encode() with NUL byte: no crash');
	}

	# Invalid UTF-8 bytes: utf8::decode() may silently fail; module must not crash.
	{
		my $bad_utf8 = "\xFF\xFE";
		my $t = Lingua::Text->new(en => $bad_utf8);
		lives_ok(sub { $t->encode() }, 'encode() with invalid UTF-8 bytes: no crash');
	}

	# Very large text: no size limit.
	{
		my $t = Lingua::Text->new(en => $LARGE);
		lives_ok(sub { $t->encode() }, 'encode() with 1 MB text: no crash');
	}
};

# ===========================================================================
# 10. encode() -- double-encode pitfall (documented COMMON PITFALL regression)
#
# Calling encode() twice corrupts HTML entities (& -> &amp;).
# This is the DOCUMENTED behavior -- the test exists so any "fix" that
# silently changes the double-encode output is immediately caught as a
# potential contract violation.
# ===========================================================================
subtest 'encode -- double-encode pitfall (documented regression)' => sub {
	my $t = Lingua::Text->new(fr => $ETUDE);

	$t->encode();
	is($t->fr(), $ETUDE_E, 'first encode(): e-acute -> &eacute;tude');

	$t->encode();    # documented corruption: & -> &amp;
	my $double = $t->fr();
	like($double,   qr/&amp;/,    'second encode() corrupts: & becomes &amp;');
	unlike($double, qr/^&eacute;/, 'second encode() breaks original entity');

	# encode() must still return $self regardless.
	my $t2 = Lingua::Text->new(en => 'plain');
	is(refaddr($t2->encode()->encode()), refaddr($t2),
		'double encode() still returns $self each time');
};

# ===========================================================================
# 11. AUTOLOAD -- hostile and boundary method names
#
# AUTOLOAD must return undef silently for any name that is not exactly two
# lowercase ASCII letters, and must never install a bogus closure or crash.
#
# Perl keyword two-letter names (do, no, or) DO pass /^[a-z]{2}$/ and are
# valid storage slots -- AUTOLOAD installs closures for them without conflict
# because method dispatch does not clash with Perl keywords.
# ===========================================================================
subtest 'AUTOLOAD -- hostile method names' => sub {
	my $t = Lingua::Text->new();

	# Three-letter codes: silently return undef.
	ok(!defined($t->zzz()),  'three-letter name returns undef');
	ok(!defined($t->abc()),  'three-letter name "abc" returns undef');

	# Single letter.
	ok(!defined($t->z()),    'single letter returns undef');

	# Digit in name.
	ok(!defined($t->e1()),   'name with digit returns undef');

	# Underscore prefix (private-style names).
	ok(!defined($t->_e()),   'underscore prefix returns undef');

	# DESTROY must be intercepted and return undef (not install a closure).
	lives_ok(sub { $t->DESTROY() }, 'DESTROY call does not crash');

	# Perl keyword two-letter names: valid method dispatch, not keywords here.
	lives_ok(sub { $t->do('do-value') }, '"do" keyword as lang code: setter does not crash');
	is($t->do(), 'do-value', '"do" accessor stores and retrieves');

	lives_ok(sub { $t->or('or-value') }, '"or" keyword as lang code: no crash');
	is($t->or(), 'or-value', '"or" accessor stores and retrieves');

	lives_ok(sub { $t->no('no-value') }, '"no" keyword as lang code: no crash');
	is($t->no(), 'no-value', '"no" accessor stores and retrieves');

	# Extra args to getter: extra args beyond the first are silently ignored
	# by the installed closure (shift + @_ check), not a crash.
	$t->en($EN_TEXT);
	lives_ok(sub { $t->en('a', 'b', 'c') }, 'accessor with extra args: no crash');
};

# ===========================================================================
# 12. AUTOLOAD -- falsy stored values
#
# The installed closure uses `if(@_)` (presence), not truthiness.
# '0', '', and undef must each be stored and returned correctly.
# ===========================================================================
subtest 'AUTOLOAD -- falsy stored values' => sub {
	my $t = Lingua::Text->new();

	# '0' must be stored (not swallowed as falsy).
	$t->en($ZERO);
	is($t->en(), $ZERO, 'AUTOLOAD: "0" stored and retrieved');

	# '' must be stored as empty string, not undef.
	$t->fr($EMPTY);
	ok(defined($t->fr()),    'AUTOLOAD: "" is stored (defined)');
	is($t->fr(), $EMPTY,     'AUTOLOAD: "" retrieved verbatim');

	# undef: stored; accessor returns undef (same as absent, but key exists).
	$t->de(undef);
	ok(!defined($t->de()),   'AUTOLOAD: undef stored and returned as undef');

	# Overwrite: last call wins.
	$t->en($EN_TEXT);
	$t->en('world');
	is($t->en(), 'world',    'AUTOLOAD overwrite: last value wins');
};

# ===========================================================================
# 13. Security -- XSS passthrough and encode() defence
#
# Lingua::Text is a data container; it performs no implicit sanitization.
# Without encode(): XSS payloads pass through unchanged.
# With encode():    XSS payloads are neutralized to HTML entities.
# Both sides of this contract must hold to avoid surprised callers.
# ===========================================================================
subtest 'security -- XSS passthrough vs encode() defence' => sub {
	# Without encode(): raw payloads returned verbatim.
	{
		my $t = Lingua::Text->new(en => $XSS_SCRIPT, fr => $XSS_IMG);
		is($t->as_string('en'), $XSS_SCRIPT,
			'pre-encode: <script> payload returned verbatim');
		is($t->as_string('fr'), $XSS_IMG,
			'pre-encode: <img onerror> payload returned verbatim');
	}

	# With encode(): payloads neutralized.
	{
		my $t = Lingua::Text->new(en => $XSS_SCRIPT)->encode();
		is($t->as_string('en'), $XSS_ENC,
			'post-encode: <script> neutralized to HTML entities');
	}

	{
		my $t = Lingua::Text->new(en => $XSS_IMG)->encode();
		unlike($t->as_string('en'), qr/<img/,
			'post-encode: <img> tag is gone');
		like($t->as_string('en'), qr/&lt;img/,
			'post-encode: <img> is HTML-entity-encoded');
	}
};

# ===========================================================================
# 14. Security -- non-language key injection into {texts}
#
# Object::Configure may inject keys like 'logger' into {texts}.  Other
# callers might inject arbitrary keys directly.  encode() must skip any key
# that fails the ISO 639-1 check (SECURITY V2), and the two-letter AUTOLOAD
# must not accidentally expose them.
# ===========================================================================
subtest 'security -- non-language key injection via direct hash access' => sub {
	my $t = Lingua::Text->new(en => $EN_TEXT);

	# Inject a non-language blessed-object key directly (simulates Object::Configure).
	$t->{'texts'}{'logger'} = bless { secret => 'internal' }, 'FakeLogger';

	lives_ok(sub { $t->encode() },
		'encode() survives injected blessed-object key (SECURITY V2)');

	is($t->as_string('en'), $EN_TEXT,
		'as_string() unaffected by injected non-language key');

	# 'logger' is 6 chars; AUTOLOAD must return undef for it.
	ok(!defined($t->logger()),
		'AUTOLOAD: injected "logger" key (6 chars) returns undef silently');

	# Inject a key that looks almost like a language code but isn't.
	$t->{'texts'}{'E1'} = 'bad';
	lives_ok(sub { $t->encode() },
		'encode() survives uppercase+digit injected key');
};

# ===========================================================================
# 15. Security -- $_ not clobbered by any public method
#
# for/foreach without an explicit loop variable iterates via $_, which is
# a global.  encode() uses `for my $lang` to avoid this.  Verify that NO
# public method leaks a modified $_ to the caller.
# ===========================================================================
subtest 'security -- $_ not clobbered by any public method' => sub {
	local $_ = 'sentinel';

	my $t = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);

	$t->as_string('en');
	is($_, 'sentinel', 'as_string() does not clobber $_');

	$t->set(text => 'hi', lang => 'de');
	is($_, 'sentinel', 'set() does not clobber $_');

	$t->encode();
	is($_, 'sentinel', 'encode() does not clobber $_');

	$t->en('morning');
	is($_, 'sentinel', 'AUTOLOAD setter does not clobber $_');

	$t->en();
	is($_, 'sentinel', 'AUTOLOAD getter does not clobber $_');

	my $clone = $t->new();
	is($_, 'sentinel', 'new() on object does not clobber $_');
};

# ===========================================================================
# 16. Locale injection -- hostile environment variable values
#
# _get_language() reads %ENV through I18N::LangTags::Detect and then
# direct regex extraction.  Hostile values must not cause code execution,
# path traversal, or unexpected language selection.
# ===========================================================================
subtest 'locale injection -- hostile LANG values' => sub {
	# Shell metacharacters: regex extracts only [a-z]{2}; no shell is invoked.
	{
		local %ENV;
		$ENV{LANG} = 'en' . $SHELL_INJECT;
		mock 'I18N::LangTags::Detect::detect' => sub { () };

		my $t = Lingua::Text->new(en => $EN_TEXT);
		my $r;
		lives_ok(sub { $r = "$t" }, 'shell-metacharacter LANG does not crash');
		is($r, $EN_TEXT, 'shell LANG: first two chars "en" extracted safely');
		restore_all();
	}

	# Path traversal: '../' does not start with [a-z]{2}; no file is read.
	{
		local %ENV;
		$ENV{LANG} = $PATH_TRAV;
		mock 'I18N::LangTags::Detect::detect' => sub { () };

		my $t = Lingua::Text->new(en => $EN_TEXT);
		lives_ok(sub { $t->as_string('en') },
			'path-traversal LANG does not crash');
		restore_all();
	}

	# LANG=POSIX: not 'C'; not two lowercase letters; undef from locale.
	{
		local %ENV;
		$ENV{LANG} = 'POSIX';
		mock 'I18N::LangTags::Detect::detect' => sub { () };

		my $t = Lingua::Text->new(en => $EN_TEXT);
		lives_ok(sub { $t->as_string('en') }, 'LANG=POSIX does not crash');
		is($t->as_string('en'), $EN_TEXT, 'explicit lang "en" still works under LANG=POSIX');
		restore_all();
	}

	# LANG=C: documented to return 'en'.
	{
		local %ENV;
		$ENV{LANG} = 'C';
		mock 'I18N::LangTags::Detect::detect' => sub { () };

		my $t = Lingua::Text->new(en => $EN_TEXT);
		is("$t", $EN_TEXT, 'LANG=C treated as English (documented)');
		restore_all();
	}

	# LANG=C.UTF-8: also treated as English.
	{
		local %ENV;
		$ENV{LANG} = 'C.UTF-8';
		mock 'I18N::LangTags::Detect::detect' => sub { () };

		my $t = Lingua::Text->new(en => $EN_TEXT);
		is("$t", $EN_TEXT, 'LANG=C.UTF-8 treated as English');
		restore_all();
	}

	# LANGUAGE takes precedence over LANG.
	{
		local %ENV;
		$ENV{LANG}     = $EN_LOCALE;
		$ENV{LANGUAGE} = 'fr:en';
		mock 'I18N::LangTags::Detect::detect' => sub { () };

		my $t = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);
		is("$t", $FR_TEXT, 'LANGUAGE takes precedence over LANG');
		restore_all();
	}

	# Very long LANG value: regex extracts only first two chars; no hang.
	{
		local %ENV;
		$ENV{LANG} = 'en' . ('x' x 100_000);
		mock 'I18N::LangTags::Detect::detect' => sub { () };

		my $t = Lingua::Text->new(en => $EN_TEXT);
		my $r;
		lives_ok(sub { $r = "$t" }, '100 000-char LANG does not hang or crash');
		is($r, $EN_TEXT, '100 000-char LANG: "en" prefix extracted correctly');
		restore_all();
	}
};

# ===========================================================================
# 17. Locale injection -- detect() upstream failures
#
# I18N::LangTags::Detect::detect() is the first locale probe.
# Mock it to return hostile or degenerate values and confirm the module
# falls back correctly without crashing.
# ===========================================================================
subtest 'locale injection -- detect() upstream failures' => sub {
	# detect() returns empty list: fall through to LANG env-var fallback.
	{
		local %ENV;
		$ENV{LANG} = $EN_LOCALE;
		mock 'I18N::LangTags::Detect::detect' => sub { () };

		my $t = Lingua::Text->new(en => $EN_TEXT);
		is("$t", $EN_TEXT, 'detect() empty list: LANG fallback picks English');
		restore_all();
	}

	# detect() returns a tag with no [a-z]{2} prefix: fallback to LANG.
	{
		local %ENV;
		$ENV{LANG} = $FR_LOCALE;
		mock 'I18N::LangTags::Detect::detect' => sub { ('123-invalid') };

		my $t = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);
		lives_ok(sub { "$t" }, 'detect() with numeric tag: no crash');
		restore_all();
	}

	# detect() returns the empty string: must not match [a-z]{2}.
	{
		local %ENV;
		$ENV{LANG} = $EN_LOCALE;
		mock 'I18N::LangTags::Detect::detect' => sub { ($EMPTY) };

		my $t = Lingua::Text->new(en => $EN_TEXT);
		lives_ok(sub { "$t" }, 'detect() returning empty string: no crash');
		restore_all();
	}

	# detect() returns a shell-injection string: regex extracts safely.
	{
		local %ENV;
		$ENV{LANG} = $EN_LOCALE;
		mock 'I18N::LangTags::Detect::detect' => sub { ('en' . $SHELL_INJECT) };

		my $t = Lingua::Text->new(en => $EN_TEXT);
		lives_ok(sub { "$t" }, 'detect() returning shell-injection string: no crash');
		restore_all();
	}
};

# ===========================================================================
# 18. Regression -- new('text') with no locale must NOT croak
#
# BEFORE FIX (lib/Lingua/Text.pm):
#   new('text') with no locale would fall through to
#   Params::Get::get_params(undef, 'text') -- an odd-length list -- which
#   croaks: "Usage: Params::Get->Lingua::Text::new()".
#
# AFTER FIX:
#   A single non-ref scalar is handled BEFORE get_params(); when no locale
#   is set, the text is silently discarded and an empty object is returned.
# ===========================================================================
subtest 'regression -- new("text") with no locale does not croak' => sub {
	local %ENV;
	mock 'I18N::LangTags::Detect::detect' => sub { () };

	my $t;
	lives_ok(
		sub { $t = Lingua::Text->new($EN_TEXT) },
		'new("text") with no locale: no croak (regression guard)',
	);
	isa_ok($t, 'Lingua::Text', 'new("text") with no locale returns a Lingua::Text object');
	ok(!defined($t->en()), 'new("text") with no locale silently discards the text');
	restore_all();
};

# ===========================================================================
# 19. Regression -- encode() on a slot holding undef emits no warning
#
# BEFORE SECURITY V3 guard:
#   encode_entities(undef) emitted "Use of uninitialized value".
#   utf8::decode(undef) also misbehaves.
#   SECURITY V3: `next unless defined($v) && !ref($v)` guards both.
# ===========================================================================
subtest 'regression -- encode() with undef slot: no "uninitialized value" warning' => sub {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	my $t = Lingua::Text->new(en => undef, fr => $FR_TEXT);
	$t->encode();

	my @undef_warns = grep { /uninitialized/i } @warnings;
	is(scalar @undef_warns, 0,
		'encode() emits zero "uninitialized value" warnings for undef slot (SECURITY V3)');

	# The defined slot must still be encoded.
	is($t->fr(), $FR_TEXT,
		'encode() still processes defined text slots alongside undef slot');
};

# ===========================================================================
# 20. Memory -- no circular references after hostile mutations
# ===========================================================================
subtest 'memory -- no circular refs after hostile mutations' => sub {
	my $t = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);
	$t->set(text => 'hi', lang => 'de');
	$t->encode();
	$t->en('morning');

	memory_cycle_ok($t, 'no circular refs after set/encode/accessor sequence');

	my $clone = $t->new(es => 'hola');
	memory_cycle_ok($clone, 'no circular refs in clone-with-params');
};

# ===========================================================================
# 21. Stress -- 50 concurrent objects: no shared state
#
# Rapid construction of many objects with overlapping language codes must
# not cause AUTOLOAD method-installation to bleed state between objects.
# ===========================================================================
subtest 'stress -- 50 concurrent objects with no shared state' => sub {
	my @objs = map { Lingua::Text->new(en => "item-$_", fr => "el-$_") } 1..50;

	for my $i (0 .. $#objs) {
		is($objs[$i]->en(), 'item-' . ($i + 1),
			"object ${\($i+1)}: en returns correct value");
	}

	# Mutate every other object and confirm neighbours are unaffected.
	$objs[$_]->en('mutated') for 0, 2, 4, 6;

	is($objs[1]->en(), 'item-2',  'odd-index object unaffected by even-index mutation');
	is($objs[3]->en(), 'item-4',  'odd-index object unaffected by even-index mutation');
	is($objs[5]->en(), 'item-6',  'odd-index object unaffected by even-index mutation');
};

done_testing();

#!/usr/bin/env perl
# t/function.t -- White-box unit tests for Lingua::Text
#
# Strategy: test every public and private function using equivalence
# partitioning.  Each subtest covers one function and mocks its dependencies
# so that only the unit under test is exercised.
#
# Private functions (_err, _is_valid_language, _get_language, _carp_set_usage)
# are accessible because 'prove' sets HARNESS_ACTIVE, which Sub::Private uses
# to bypass its enforcement gate.  The BEGIN below guarantees the flag is set
# before 'use Lingua::Text' loads Sub::Private.

use strict;
use warnings;

BEGIN { $ENV{HARNESS_ACTIVE} = 1 }

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
Readonly::Hash my %LANG => (
	en => 'en',
	fr => 'fr',
	de => 'de',
	zh => 'zh',
);
Readonly::Scalar my $EN_TEXT  => 'hello';
Readonly::Scalar my $FR_TEXT  => 'bonjour';
Readonly::Scalar my $DE_TEXT  => 'Hallo';
Readonly::Scalar my $ETUDE    => "\x{E9}tude";       # e-acute + 'tude'  (U+00E9)
Readonly::Scalar my $ETUDE_E  => '&eacute;tude';     # expected HTML-entity form
Readonly::Scalar my $EN_LOCALE => 'en_US.UTF-8';
Readonly::Scalar my $FR_LOCALE => 'fr_FR.UTF-8';
Readonly::Scalar my $DE_LOCALE => 'de_DE.UTF-8';

# ---------------------------------------------------------------------------
# 1.  new() -- construction paths
#
# Covers: function-style no-args, method-style no-args, flat pairs, hashref,
#         single scalar (with/without locale), shallow clone, clone with params,
#         non-class invocant.
# ---------------------------------------------------------------------------
subtest 'new -- construction paths' => sub {
	# Function-style no-args (Lingua::Text::new()) with undef invocant is
	# explicitly allowed: the guard detects "no defined class" and assigns
	# __PACKAGE__ as the class.
	{
		my $t = Lingua::Text::new();
		isa_ok($t, 'Lingua::Text', 'function-style no-args returns object');
		ok(ref($t) && blessed($t), 'new() returns a blessed reference');
		memory_cycle_ok($t, 'no cycle in empty object');
	}

	# Method-style no-args: canonical empty construction
	{
		local %ENV;
		my $t = Lingua::Text->new();
		isa_ok($t, 'Lingua::Text', 'method-style no-args returns object');
		ok(!defined($t->en()), 'empty object has no translations');
	}

	# Flat key/value pairs
	{
		local %ENV;
		my $t = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);
		is($t->en(), $EN_TEXT,  'flat pairs: English stored');
		is($t->fr(), $FR_TEXT, 'flat pairs: French stored');
	}

	# Hashref argument
	{
		local %ENV;
		my $t = Lingua::Text->new({ en => $EN_TEXT, fr => $FR_TEXT });
		is($t->en(), $EN_TEXT, 'hashref argument: English stored');
	}

	# Single scalar with locale: stored under the detected language
	{
		local %ENV;
		$ENV{LANG} = $EN_LOCALE;
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		my $t = Lingua::Text->new($EN_TEXT);
		is($t->en(), $EN_TEXT, 'single scalar with locale: stored under detected lang');
		restore_all();
	}

	# Single scalar with NO locale: text is silently discarded because there is
	# no language code to store it under.  This is a documented COMMON PITFALL.
	{
		local %ENV;
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		my $t = Lingua::Text->new($EN_TEXT);
		ok(!defined($t->en()), 'single scalar with no locale: text silently discarded');
		restore_all();
	}

	# Non-class invocant + args: carp emitted, undef returned
	{
		local %ENV;
		my $result;
		does_carp_that_matches(
			sub { $result = Lingua::Text::new('notaclass', en => $EN_TEXT) },
			'non-class invocant triggers carp',
			qr/use ->new\(\)/,
		);
		ok(!defined($result), 'non-class invocant returns undef');
	}

	# Shallow clone (no extra params): bless { %$orig } copies the
	# (texts => $ref) pair but NOT the hashref itself.  Both objects share
	# the same inner {texts} reference, so mutations on either are visible
	# in both.
	{
		local %ENV;
		my $orig  = Lingua::Text->new(en => 'cat', fr => 'chat');
		my $clone = $orig->new();
		isa_ok($clone, 'Lingua::Text', 'clone returns Lingua::Text');
		is($clone->en(), 'cat',  'shallow clone: en preserved');
		is($clone->fr(), 'chat', 'shallow clone: fr preserved');
		$orig->en('kitten');    # mutate the original
		is($clone->en(), 'kitten',
			'shallow clone shares {texts} hashref -- mutation is visible');
		memory_cycle_ok($clone, 'no cycle in shallow clone');
	}

	# Clone with extra params: creates a new {texts} hash merging original and
	# the extra pairs.  The new key wins; the original is unchanged.
	{
		local %ENV;
		my $base = Lingua::Text->new(en => 'colour', fr => 'couleur');
		my $us   = $base->new(en => 'color');
		is($us->en(),   'color',   'clone with override: overridden key replaced');
		is($us->fr(),   'couleur', 'clone with override: non-overridden key preserved');
		is($base->en(), 'colour',  'clone with override: original unchanged');
	}
};

# ---------------------------------------------------------------------------
# 2.  set() -- state transitions
#
# Covers: croak on no-args, named/hashref/positional forms, the // fix for
#         empty-string lang, invalid lang, undef text, missing lang without
#         locale, falsy '0' and '' values, method chaining.
# ---------------------------------------------------------------------------
subtest 'set -- state transitions' => sub {
	# No args at all: croak (programmer error -- capital 'U' in Usage)
	{
		local %ENV;
		my $t = Lingua::Text->new();
		does_croak_that_matches(
			sub { $t->set() },
			'set() with no args croaks',
			qr/Usage/,
		);
	}

	# Named form: text + lang
	{
		local %ENV;
		my $t   = Lingua::Text->new();
		my $ret = $t->set(text => $EN_TEXT, lang => $LANG{en});
		is($t->en(), $EN_TEXT, 'named form: text stored');
		is(refaddr($ret), refaddr($t), 'set() returns $self (chainable)');
	}

	# Hashref form
	{
		local %ENV;
		my $t = Lingua::Text->new();
		$t->set({ text => $FR_TEXT, lang => $LANG{fr} });
		is($t->fr(), $FR_TEXT, 'hashref form: text stored');
	}

	# Positional form (single scalar): lang inferred from system locale
	{
		local %ENV;
		$ENV{LANG} = $DE_LOCALE;
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		my $t = Lingua::Text->new();
		$t->set($DE_TEXT);
		is($t->de(), $DE_TEXT, 'positional form: stored under locale lang');
		restore_all();
	}

	# Security V4 regression test: explicit lang => '' must trigger carp, not
	# silently fall back to the system locale.  This proves the // fix is in
	# place -- the old || operator would have treated '' as falsy and called
	# _get_language() instead of rejecting the empty string.
	{
		local %ENV;
		$ENV{LANG} = $EN_LOCALE;
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		my $t = Lingua::Text->new();
		does_carp_that_matches(
			sub { $t->set(text => $EN_TEXT, lang => '') },
			'explicit empty lang triggers carp (not silent locale fallback)',
			qr/usage/,
		);
		ok(!defined($t->en()),
			'empty lang: nothing written under the locale lang either');
		restore_all();
	}

	# Invalid lang code (3-char): carp, object invariant preserved
	{
		local %ENV;
		my $t = Lingua::Text->new();
		does_carp_that_matches(
			sub { $t->set(text => $EN_TEXT, lang => 'abc') },
			'3-char lang code triggers carp',
			qr/usage/,
		);
		ok(!exists($t->{'texts'}{'abc'}),
			'3-char lang key NOT written to {texts} (invariant preserved)');
	}

	# undef text: carp, nothing stored
	{
		local %ENV;
		my $t = Lingua::Text->new();
		does_carp_that_matches(
			sub { $t->set(lang => $LANG{en}, text => undef) },
			'undef text triggers carp',
			qr/usage/,
		);
		ok(!defined($t->en()), 'undef text: nothing stored');
	}

	# Missing lang with no locale: carp (not croak -- this is a runtime condition)
	{
		local %ENV;
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		my $t = Lingua::Text->new();
		does_carp_that_matches(
			sub { $t->set(text => $EN_TEXT) },
			'missing lang with no locale triggers carp',
			qr/usage/,
		);
		restore_all();
	}

	# Falsy '0' must be stored -- uses defined(), not truthiness
	{
		local %ENV;
		my $t = Lingua::Text->new();
		$t->set(text => '0', lang => $LANG{en});
		is($t->en(), '0', 'falsy string "0" stored correctly via set()');
	}

	# Empty string '' must be stored -- distinct from undef
	{
		local %ENV;
		my $t = Lingua::Text->new();
		$t->set(text => '', lang => $LANG{fr});
		ok(defined($t->fr()), 'empty string is defined after set()');
		is($t->fr(), '', 'empty string stored verbatim');
	}

	# Method chaining: set() returns $self enabling fluent chains
	{
		local %ENV;
		my $t = Lingua::Text->new()
			->set(text => $EN_TEXT, lang => $LANG{en})
			->set(text => $FR_TEXT, lang => $LANG{fr});
		is($t->en(), $EN_TEXT,  'chain: first link stored');
		is($t->fr(), $FR_TEXT, 'chain: second link stored');
	}
};

# ---------------------------------------------------------------------------
# 3.  as_string() -- read-only query (Xi schema: no mutation)
#
# Covers: positional, named, hashref forms; locale fallback; missing
#         translation (silent undef); no-lang carp; stringify overload;
#         state preservation.
# ---------------------------------------------------------------------------
subtest 'as_string -- read-only query' => sub {
	# Positional form: as_string('en')
	{
		local %ENV;
		my $t = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);
		is($t->as_string($LANG{en}), $EN_TEXT,  'positional: en');
		is($t->as_string($LANG{fr}), $FR_TEXT, 'positional: fr');
	}

	# Named form: as_string(lang => 'fr')
	{
		local %ENV;
		my $t = Lingua::Text->new(fr => $FR_TEXT);
		is($t->as_string(lang => $LANG{fr}), $FR_TEXT, 'named lang arg');
	}

	# Hashref form: as_string({ lang => 'en' })
	{
		local %ENV;
		my $t = Lingua::Text->new(en => $EN_TEXT);
		is($t->as_string({ lang => $LANG{en} }), $EN_TEXT, 'hashref lang arg');
	}

	# Locale: no explicit lang -- uses system locale
	{
		local %ENV;
		$ENV{LANG} = $FR_LOCALE;
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		my $t = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);
		is($t->as_string(), $FR_TEXT, 'no explicit lang: uses system locale');
		restore_all();
	}

	# Missing translation: undef returned silently (no warning)
	{
		local %ENV;
		my $t      = Lingua::Text->new(en => $EN_TEXT);
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		my $result = $t->as_string($LANG{de});
		ok(!defined($result), 'missing translation returns undef');
		ok(!$warned,          'missing translation emits no warning');
	}

	# No lang, no locale: carp
	{
		local %ENV;
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		my $t = Lingua::Text->new(en => $EN_TEXT);
		does_carp_that_matches(
			sub { $t->as_string() },
			'no lang + no locale triggers carp',
			qr/usage/,
		);
		restore_all();
	}

	# Stringify overload: "$t" invokes as_string via the "" overload
	{
		local %ENV;
		$ENV{LANG} = $EN_LOCALE;
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		my $t = Lingua::Text->new(en => $EN_TEXT);
		is("$t", $EN_TEXT, 'stringify overload returns correct translation');
		restore_all();
	}

	# Xi schema: as_string() must not mutate {texts} -- any lang arg or locale
	{
		local %ENV;
		$ENV{LANG} = $EN_LOCALE;
		my $t      = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);
		my $before = { %{$t->{'texts'}} };
		$t->as_string($LANG{fr});
		is_deeply($t->{'texts'}, $before,
			'as_string() does not mutate {texts} (Xi schema)');
	}

	# Return value schema
	{
		local %ENV;
		my $t   = Lingua::Text->new(en => $EN_TEXT);
		my $val = $t->as_string($LANG{en});
		returns_ok($val, { type => 'string' }, 'found: returns string');
		# Test::Returns warns on undef -- use ok(!defined) instead of returns_not_ok
		ok(!defined($t->as_string($LANG{de})),
			'not-found: returns undef (not a string)');
	}
};

# ---------------------------------------------------------------------------
# 4.  encode() -- in-place HTML entity encoding
#
# Covers: ASCII unchanged, non-ASCII encoded, chainability, double-encode
#         pitfall, security V2 (non-language key skip), security V3 (undef
#         value skip), no memory cycles.
# ---------------------------------------------------------------------------
subtest 'encode -- in-place mutation' => sub {
	# ASCII text is passed through unchanged
	{
		local %ENV;
		my $t = Lingua::Text->new(en => 'study')->encode();
		is($t->en(), 'study', 'ASCII text unaffected by encode()');
	}

	# Non-ASCII (e-acute) encoded to named HTML entity
	{
		local %ENV;
		my $t = Lingua::Text->new(fr => $ETUDE)->encode();
		is($t->fr(), $ETUDE_E, 'e-acute encoded to &eacute;');
	}

	# Chainability: encode() returns the same object, not a copy
	{
		local %ENV;
		my $t   = Lingua::Text->new(en => $EN_TEXT);
		my $ret = $t->encode();
		isa_ok($ret, 'Lingua::Text', 'encode() returns Lingua::Text');
		is(refaddr($ret), refaddr($t),
			'encode() returns the exact same object (not a copy)');
	}

	# Double-encode: documented pitfall -- '&' itself is a special HTML char,
	# so a second encode() will encode the '&' in '&eacute;' to '&amp;'.
	{
		local %ENV;
		my $t = Lingua::Text->new(fr => $ETUDE)->encode()->encode();
		is($t->fr(), '&amp;eacute;tude',
			'double-encode corrupts output (documented pitfall)');
	}

	# Security V2: Object::Configure may inject non-language keys (e.g. 'logger')
	# that hold blessed references.  encode() must skip them entirely to avoid
	# corrupting the injected object's internal string buffer via utf8::decode().
	{
		local %ENV;
		my $fake_logger = bless { secret => 'auth-token' }, 'FakeLogger';
		my $t = Lingua::Text->new(en => '<b>bold</b>');
		$t->{'texts'}{'logger'} = $fake_logger;    # simulate Object::Configure
		$t->encode();
		is(ref($t->{'texts'}{'logger'}), 'FakeLogger',
			'encode() does not corrupt the injected non-language key');
		is($fake_logger->{'secret'}, 'auth-token',
			'injected object contents unchanged after encode()');
		like($t->en(), qr/&lt;b&gt;/,
			'language key was encoded despite non-language sibling');
	}

	# Security V3: undef stored via $t->en(undef) must be preserved, not
	# converted to '' by encode_entities(undef).  Also no "uninitialized"
	# warning must appear.
	{
		local %ENV;
		my $t = Lingua::Text->new();
		$t->en(undef);    # store undef explicitly
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		$t->encode();
		ok(!defined($t->en()),
			'encode() preserves stored undef (not converted to "")');
		ok(!$warned, 'encode() emits no warning for undef value');
	}

	# No memory cycles introduced by encode()
	{
		local %ENV;
		my $t = Lingua::Text->new(en => $EN_TEXT, fr => $ETUDE)->encode();
		memory_cycle_ok($t, 'no cycle after encode()');
	}
};

# ---------------------------------------------------------------------------
# 5.  AUTOLOAD -- language accessor dispatch + method installation
#
# Covers: setter/getter round-trip, falsy '0', empty '', undef, missing lang
#         (silent undef), uppercase rejection, 3-char code rejection, DESTROY
#         bypass, method installation after first call.
# ---------------------------------------------------------------------------
subtest 'AUTOLOAD -- accessor dispatch' => sub {
	# Setter + getter round-trip
	{
		my $t = Lingua::Text->new();
		is($t->en($EN_TEXT), $EN_TEXT, 'setter: returns stored value');
		is($t->en(),         $EN_TEXT, 'getter: retrieves stored value');
	}

	# Falsy '0' must be stored -- proves @_ presence check, not truthiness
	{
		my $t = Lingua::Text->new();
		$t->en($EN_TEXT);
		is($t->en('0'), '0', 'falsy "0" returned by setter');
		is($t->en(),    '0', 'falsy "0" stored by setter');
	}

	# Empty string '' must be stored
	{
		my $t = Lingua::Text->new();
		$t->fr($FR_TEXT);
		$t->fr('');
		ok(defined($t->fr()), 'empty string is defined after setter');
		is($t->fr(), '', 'empty string stored verbatim');
	}

	# undef clears the translation (sets the slot to undef)
	{
		my $t = Lingua::Text->new();
		$t->de($DE_TEXT);
		$t->de(undef);
		ok(!defined($t->de()), 'undef setter clears the translation');
	}

	# Getter for missing lang: undef, no warning (not a carp situation)
	{
		my $t      = Lingua::Text->new(en => $EN_TEXT);
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		ok(!defined($t->ja()), 'getter for missing lang returns undef');
		ok(!$warned,           'no warning for missing lang');
	}

	# Uppercase code (EN): silently rejected.  The /^[a-z]{2}$/ guard has no
	# i-flag by design -- RFC 5646 language tags are always lower-case.
	{
		my $t = Lingua::Text->new();
		$t->set(text => $EN_TEXT, lang => $LANG{en});
		ok(!defined($t->EN()), 'uppercase EN() returns undef (no i-flag guard)');
	}

	# 3-char code: outside the ^[a-z]{2}$ gate
	{
		my $t = Lingua::Text->new();
		ok(!defined($t->xyz()), '3-char code xyz() returns undef silently');
	}

	# DESTROY must NOT be intercepted -- the 'return if $key eq DESTROY' guard
	# prevents the destructor from being treated as a language accessor.
	{
		my $t      = Lingua::Text->new();
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		eval { $t->DESTROY() };
		ok(!$warned, 'DESTROY not intercepted by AUTOLOAD');
	}

	# Method installation: after the first call to a two-letter accessor via
	# AUTOLOAD, a real subroutine is installed in the symbol table.  Subsequent
	# calls bypass AUTOLOAD entirely.
	#
	# We use 'xq' (not a real ISO 639-1 code) so it won't clash with any real
	# translation, and we delete it first to guarantee a clean slate.
	{
		{
			no strict 'refs';
			delete ${'Lingua::Text::'}{'xq'};
		}
		# can() does a runtime MRO lookup -- immune to the compile-time caching
		# that makes defined(&Pkg::name) return a stale false after stash deletion.
		ok(!Lingua::Text->can('xq'),
			'xq() method not yet installed before first call');

		my $t = Lingua::Text->new();
		$t->xq('test-value');    # first call triggers AUTOLOAD and installs sub

		ok(Lingua::Text->can('xq'),
			'xq() method installed in symbol table after first AUTOLOAD call');
		is($t->xq(), 'test-value',
			'installed method returns correct value');

		# Second object: the installed method works without hitting AUTOLOAD
		my $t2 = Lingua::Text->new();
		$t2->xq('another-value');
		is($t2->xq(), 'another-value',
			'installed method works correctly on a second object');
	}
};

# ---------------------------------------------------------------------------
# 6.  _err() -- private message formatter
#
# Purpose: verify that the catalog + sprintf pipeline formats messages with
# the package name substituted, and that unknown keys fall back gracefully.
# ---------------------------------------------------------------------------
subtest '_err -- private message formatter' => sub {
	is(Lingua::Text::_err('set_no_args'),
		'Lingua::Text: Usage: set(text => $text, lang => $language)',
		'_err(set_no_args): capital U (croak-class message)');

	is(Lingua::Text::_err('set_usage'),
		'Lingua::Text: usage: set(text => $text, lang => $language)',
		'_err(set_usage): lower-case u (carp-class message)');

	is(Lingua::Text::_err('str_usage'),
		'Lingua::Text: usage: as_string(lang => $language)',
		'_err(str_usage): formats correctly');

	is(Lingua::Text::_err('new_oo_style'),
		'Lingua::Text: use ->new() not ::new() to instantiate',
		'_err(new_oo_style): formats correctly');

	# Unknown key: must confess with the bad key name so the programmer sees
	# it immediately at the call site rather than getting a silent wrong message.
	throws_ok(
		sub { Lingua::Text::_err('no_such_key') },
		qr/Internal error.*no_such_key/,
		'_err(unknown key): confesses with key name in message',
	);
};

# ---------------------------------------------------------------------------
# 7.  _is_valid_language() -- ISO 639-1 / 3166-1 validation
#
# Boundary: everything the storage invariant relies on.
# ---------------------------------------------------------------------------
subtest '_is_valid_language -- ISO 639-1 validation' => sub {
	# Valid: plain two-char lower-case codes (a representive sample)
	for my $code (qw(en fr de zh ja es ar pt ru)) {
		ok(Lingua::Text::_is_valid_language($code),
			"'$code' is valid");
	}

	# Valid: two-char code + underscore + two-char upper-case country
	for my $code (qw(en_US en_GB fr_FR de_DE zh_CN pt_BR)) {
		ok(Lingua::Text::_is_valid_language($code),
			"'$code' with country suffix is valid");
	}

	# Invalid: three-char codes
	ok(!Lingua::Text::_is_valid_language('abc'), '3-char code invalid');
	ok(!Lingua::Text::_is_valid_language('eng'), '3-char ISO 639-2 code invalid');

	# Invalid: one-char code
	ok(!Lingua::Text::_is_valid_language('a'),   '1-char code invalid');

	# Invalid: uppercase without suffix (the regex is case-sensitive by design)
	ok(!Lingua::Text::_is_valid_language('EN'),  'uppercase EN invalid');
	ok(!Lingua::Text::_is_valid_language('FR'),  'uppercase FR invalid');

	# Invalid: empty string
	ok(!Lingua::Text::_is_valid_language(''),    'empty string invalid');

	# Invalid: security boundary -- injection payloads must never pass validation
	for my $payload ('en; rm -rf /', 'en|cat', '../etc', "en\x00", "en\r\nX-Inject: x") {
		ok(!Lingua::Text::_is_valid_language($payload),
			"hostile payload rejected: '$payload'");
	}

	# Boundary: shortest valid code and just-over-length
	ok( Lingua::Text::_is_valid_language('aa'),  "'aa' is valid (minimum length)");
	ok(!Lingua::Text::_is_valid_language('aaa'), "'aaa' is invalid (one char too long)");
};

# ---------------------------------------------------------------------------
# 8.  _get_language() -- locale detection, memoisation, fallback chain
#
# Strategy: mock I18N::LangTags::Detect::detect() so we can control which
# tags it "sees", then probe the fallback chain via %ENV manipulation.
# The memoisation test explicitly forces a cache miss then a cache hit and
# counts detect() invocations.
# ---------------------------------------------------------------------------
subtest '_get_language -- locale detection' => sub {
	# $Sub::Private::BYPASS = 1 lets us call the private sub from this test
	# package without relying on HARNESS_ACTIVE.  We need this because
	# 'local %ENV' creates an EMPTY copy of %ENV, which wipes HARNESS_ACTIVE
	# inside every inner {local %ENV; ...} block.
	local $Sub::Private::BYPASS = 1;

	# detect() tag takes precedence over all %ENV probing
	{
		local %ENV;
		mock 'I18N::LangTags::Detect::detect' => sub { ('fr-FR', 'en') };
		is(Lingua::Text::_get_language(), 'fr',
			'detect() result used first');
		restore_all();
	}

	# LANGUAGE env var: used when detect() returns nothing
	{
		local %ENV;
		$ENV{LANGUAGE} = 'de:en';
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		is(Lingua::Text::_get_language(), 'de',
			'LANGUAGE env var used when detect() empty');
		restore_all();
	}

	# LC_ALL fallback
	{
		local %ENV;
		$ENV{LC_ALL} = $FR_LOCALE;
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		is(Lingua::Text::_get_language(), 'fr', 'LC_ALL fallback');
		restore_all();
	}

	# LC_MESSAGES fallback (lower priority than LC_ALL)
	{
		local %ENV;
		$ENV{LC_MESSAGES} = $DE_LOCALE;
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		is(Lingua::Text::_get_language(), 'de', 'LC_MESSAGES fallback');
		restore_all();
	}

	# LANG fallback (lowest priority among the three LC_* vars)
	{
		local %ENV;
		$ENV{LANG} = 'zh_CN.UTF-8';
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		is(Lingua::Text::_get_language(), 'zh', 'LANG fallback');
		restore_all();
	}

	# POSIX 'C' locale must map to 'en' (the historical English convention)
	{
		local %ENV;
		$ENV{LANG} = 'C';
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		is(Lingua::Text::_get_language(), 'en', "LANG=C -> 'en'");
		restore_all();
	}

	# POSIX 'C.UTF-8' variant also maps to 'en'
	{
		local %ENV;
		$ENV{LANG} = 'C.UTF-8';
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		is(Lingua::Text::_get_language(), 'en', "LANG=C.UTF-8 -> 'en'");
		restore_all();
	}

	# No locale at all: returns undef (caller is responsible for handling this)
	{
		local %ENV;
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		ok(!defined(Lingua::Text::_get_language()),
			'no locale environment: returns undef');
		restore_all();
	}

	# Memoisation: detect() must be called only ONCE when env vars do not change.
	# Mechanism: after the first call we prime the cache; subsequent calls with
	# the same env snapshot must return the cached result without re-probing.
	{
		local %ENV;
		my $detect_count = 0;
		mock 'I18N::LangTags::Detect::detect' => sub { $detect_count++; ('en-US') };

		# Phase 1: force a cache miss by using an unusual locale, then reset counter
		$ENV{LANG} = 'zz_ZZ.UTF-8';     # unique value not used anywhere else
		Lingua::Text::_get_language();   # primes cache with zz
		$detect_count = 0;               # reset counter; only count from here

		# Phase 2: switch to the real test locale -- cache is now stale
		$ENV{LANG} = $EN_LOCALE;
		Lingua::Text::_get_language();   # slow path: 1 detect() call
		Lingua::Text::_get_language();   # cache hit: no detect() call
		Lingua::Text::_get_language();   # cache hit: no detect() call

		is($detect_count, 1,
			'memoisation: detect() called once for three calls with same env');
		restore_all();
	}

	# Cache invalidation: changing any tracked env var forces a recompute
	{
		local %ENV;
		my $detect_count = 0;
		mock 'I18N::LangTags::Detect::detect' => sub { $detect_count++; () };

		$ENV{LANG} = $EN_LOCALE;
		Lingua::Text::_get_language();   # primes cache
		$detect_count = 0;

		$ENV{LANG} = $FR_LOCALE;         # change LANG -> cache stale
		Lingua::Text::_get_language();   # must recompute
		is($detect_count, 1, 'cache invalidated when LANG changes');
		restore_all();
	}
};

# ---------------------------------------------------------------------------
# 9.  _carp_set_usage() -- the carp wrapper extracted from set()
#
# Purpose: verify the exact message and that the return value is always undef.
# ---------------------------------------------------------------------------
subtest '_carp_set_usage -- carp wrapper' => sub {
	my $ret;
	does_carp_that_matches(
		sub { $ret = Lingua::Text::_carp_set_usage() },
		'_carp_set_usage() emits the set-usage carp message',
		qr/usage: set\(/,
	);
	ok(!defined($ret), '_carp_set_usage() returns undef');
};

# ---------------------------------------------------------------------------
# 10.  Memory cycle checks
#
# Lingua::Text objects hold a hashref but no circular back-references.
# Verify this for the common construction and usage patterns.
# ---------------------------------------------------------------------------
subtest 'memory -- no circular references' => sub {
	{
		local %ENV;
		my $t = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);
		memory_cycle_ok($t, 'no cycle in freshly built object');
	}
	{
		local %ENV;
		my $orig  = Lingua::Text->new(en => $EN_TEXT);
		my $clone = $orig->new(fr => $FR_TEXT);
		memory_cycle_ok($clone, 'no cycle in clone with extra params');
	}
	{
		local %ENV;
		my $t = Lingua::Text->new(en => $EN_TEXT, fr => $ETUDE)->encode();
		memory_cycle_ok($t, 'no cycle after encode()');
	}
	{
		local %ENV;
		my $t = new_ok('Lingua::Text');
		$t->set(text => $EN_TEXT, lang => $LANG{en});
		$t->set(text => $FR_TEXT, lang => $LANG{fr});
		memory_cycle_ok($t, 'no cycle after multiple set() calls');
	}
};

done_testing();

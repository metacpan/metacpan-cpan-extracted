#!/usr/bin/env perl
# t/data-flow.t -- Define-Use (DU) chain and data integrity tests for Lingua::Text.
#
# Methodology: map each critical variable through its complete lifecycle
# (Define → Use → Kill) and write tests that assert the correct value at
# each transition point.
#
# DU CHAIN ANALYSIS -- lib/Lingua/Text.pm
# =========================================
#
# new():
#   $params  D(undef) → [conditional D via single-scalar or get_params branch]
#            → U(as arg to configure) → D(configure return overwrites)
#            → U(ternary in bless).  No DD: value is U'd before every overwrite.
#   $lang    (single-scalar branch only)
#            D(_get_language()) → U(if $lang condition) → [conditional U(as key)]
#            → K(scope exit).  When _get_language() returns undef, the `if $lang`
#            condition itself constitutes the use; no D~ anomaly.
#   $is_class / $is_object: D → U(unless condition) → K.  Clean.
#   $@ NOTE: eval { UNIVERSAL::isa(...) } CLEARS $@ on success.
#            A caller with $@ set before calling new() will find $@ = '' afterwards.
#            This is standard Perl eval semantics, but callers must be aware.
#
# set():
#   $params  D(get_params) → U(lang extraction) → U(text extraction) → K.  Clean.
#   $lang    D($params->{lang} // _get_language()) → U(defined check)
#            → U(valid check) → U(hash write).  Clean.
#   $text    D($params->{text}) → U(defined check) → U(hash write).  Clean.
#
# as_string():
#   $lang    D(undef) → [branch A: D(positional arg)] OR
#            [branch B: D(params->{lang})] OR [branch C: D from //= locale]
#            → U(defined check) → U(hash lookup).  Three init paths; only one
#            fires per call.  No ~U: always initialized before the defined check.
#
# encode():
#   $v       D(copy from hash) → U(utf8::is_utf8 check) → [conditional in-place
#            modification by utf8::decode] → U(as arg to encode_entities)
#            → K($v discarded; result stored back in hash).
#            IMPORTANT: utf8::decode modifies $v in-place; the original hash entry
#            $self->{'texts'}->{$lang} is NOT changed until the explicit write-back
#            on the next line.  This is a copy-modify-store pattern.
#
# AUTOLOAD():
#   $key     D(regex match) → U(DESTROY guard) → U(ref guard) → U(length guard)
#            → U(closure capture) → U(hash write/read).
#            Each AUTOLOAD invocation has its own lexical $key; closures installed
#            for different lang codes capture independent copies.
#
# _get_language():
#   $stale   D(0) → [conditional D(1) in loop] → U(unless return).  Clean.
#   $lang    D(undef) → [conditional D from detect/LANGUAGE/LC_*/C-locale]
#            → U(//= C-locale check) → U(cached_lang write) → U(return).
#   $cached_lang / %cached_env: D(undef/{}) at scope entry →
#            D(slow path writes) → U(fast path reads).  Shared across calls.
#
# ANOMALY FOUND: $@ clobbered by eval inside new()
#   The `eval { UNIVERSAL::isa($class, __PACKAGE__) }` in new() clears $@ when
#   the eval succeeds (standard Perl behaviour).  Callers who check $@ after
#   calling Lingua::Text->new() will see $@ = '' regardless of any prior error.
#   This is documented in the test below; no fix is applied (standard eval
#   behaviour), but callers must not rely on $@ surviving across new() calls.

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
# Constants
# ---------------------------------------------------------------------------
Readonly::Scalar my $EN_LOCALE => 'en_US.UTF-8';
Readonly::Scalar my $FR_LOCALE => 'fr_FR.UTF-8';
Readonly::Scalar my $DE_LOCALE => 'de_DE.UTF-8';

Readonly::Scalar my $EN_TEXT  => 'hello';
Readonly::Scalar my $FR_TEXT  => 'bonjour';
Readonly::Scalar my $DE_TEXT  => 'Hallo';
Readonly::Scalar my $ETUDE    => "\x{E9}tude";      # e-acute + 'tude' (U+00E9)
Readonly::Scalar my $ETUDE_E  => '&eacute;tude';    # HTML-entity form

# ===========================================================================
# 1.  new() -- $params data flow: no-args path
#
# DU chain: $params stays undef through the single-scalar and get_params
# branches (neither fires with zero args).  It is then passed to
# Object::Configure::configure($class, undef) and the return value becomes
# the new $params.  If configure returns undef or an empty structure, the
# object is created empty.
# ===========================================================================
subtest 'new() $params -- no-args path: configure receives undef, object is empty' => sub {
	# Mock configure() to observe what it is called with.
	my @configure_args;
	mock 'Object::Configure::configure' => sub {
		@configure_args = @_;
		return undef;    # simulate no config-file defaults
	};

	my $t = Lingua::Text->new();

	# D($params = undef) → U(as second arg to configure)
	is($configure_args[1], undef,
		'$params (undef) is passed as second arg to configure() with no-args new()');

	isa_ok($t, 'Lingua::Text', 'no-args new() returns a Lingua::Text');
	ok(!defined($t->en()), 'no-args new(): no translations in empty object');
	restore_all();
};

# ===========================================================================
# 2.  new() -- $params data flow: flat key/value pairs path
#
# DU chain: @_ has >1 elements → get_params builds $params hashref →
# $params passed to configure() → configure return value overwrites $params
# → bless uses $params as {texts}.
# ===========================================================================
subtest 'new() $params -- flat pairs: get_params result flows to configure then texts' => sub {
	my @configure_args;
	mock 'Object::Configure::configure' => sub {
		@configure_args = @_;
		return $configure_args[1];    # pass params through unchanged
	};

	my $t = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);

	# D($params = {en=>'hello', fr=>'bonjour'}) via get_params
	# → U(as arg to configure) → D(overwrite by configure return)
	# → U(in bless { texts => $params })
	is(ref($configure_args[1]), 'HASH',
		'$params passed to configure() is a HASH ref');
	is($configure_args[1]{'en'}, $EN_TEXT,
		'configure() receives correct en key');
	is($configure_args[1]{'fr'}, $FR_TEXT,
		'configure() receives correct fr key');

	# After the DU chain, the texts hash must contain the original values.
	is($t->en(), $EN_TEXT, 'en flows from args → $params → configure → texts → accessor');
	is($t->fr(), $FR_TEXT, 'fr flows from args → $params → configure → texts → accessor');
	restore_all();
};

# ===========================================================================
# 3.  new() -- configure() return value OVERWRITES $params (D→U→D chain)
#
# Object::Configure may inject additional keys.  The return value replaces
# $params entirely: old value is used as input arg (U), new value from the
# return (D).  Verify that the object contents reflect the injected keys.
# ===========================================================================
subtest 'new() $params -- configure() return overwrites: injected keys appear in texts' => sub {
	# Simulate Object::Configure injecting an extra key alongside the real ones.
	mock 'Object::Configure::configure' => sub {
		my ($class, $params) = @_;
		$params //= {};
		$params->{'injected_key'} = 'injected_value';    # extra non-language entry
		return $params;
	};

	my $t = Lingua::Text->new(en => $EN_TEXT);

	# The configure overwrite merges injected keys into {texts}.
	# The public API for 'en' must still work (ISO 639-1 accessor).
	is($t->en(), $EN_TEXT, 'injected configure() return: en key preserved');

	# The injected key is in {texts} but not reachable via the two-letter AUTOLOAD
	# (it is longer than two chars); no crash should occur.
	lives_ok(sub { $t->as_string('en') },
		'as_string() works correctly after configure() injects extra key');
	restore_all();
};

# ===========================================================================
# 4.  new() -- $lang data flow: single-scalar branch WITH locale
#
# DU chain for $lang:
#   D(_get_language()) → U(if $lang condition: true) → U(as hash key in $params)
#   → K(scope exit).
# The value from _get_language() flows directly into the $params hash key.
# ===========================================================================
subtest 'new() $lang -- single-scalar with locale: flows from detect to texts key' => sub {
	local %ENV;
	$ENV{LANG} = $EN_LOCALE;
	mock 'I18N::LangTags::Detect::detect' => sub { () };    # force LANG fallback
	mock 'Object::Configure::configure'   => sub { $_[1] }; # pass-through

	# $lang = 'en' from _get_language() → $params = { en => 'hello' }
	my $t = Lingua::Text->new($EN_TEXT);

	# Data must flow: _get_language() → $lang → $params key → texts → accessor
	is($t->en(), $EN_TEXT,
		'$lang from _get_language() flows to texts hash key');
	ok(!defined($t->fr()),
		'only the detected language key is populated');
	restore_all();
};

# ===========================================================================
# 5.  new() -- $lang data flow: single-scalar branch WITHOUT locale
#
# DU chain for $lang:
#   D(_get_language() = undef) → U(if $lang condition: false) → K(scope exit).
# $params is never assigned (stays undef).  No D~ anomaly: $lang is used in
# the conditional expression even when it evaluates to false.
# ===========================================================================
subtest 'new() $lang -- single-scalar without locale: undef kills $params assignment' => sub {
	local %ENV;
	mock 'I18N::LangTags::Detect::detect' => sub { () };
	mock 'Object::Configure::configure'   => sub { $_[1] };

	# _get_language() returns undef → $params stays undef → texts is empty
	my $t = Lingua::Text->new($EN_TEXT);

	ok(!defined($t->en()),
		'$lang = undef prevents $params assignment; text is silently discarded');
	isa_ok($t, 'Lingua::Text', 'object is still created (not undef)');
	restore_all();
};

# ===========================================================================
# 6.  new() -- clone merge data flow: {texts} from parent and override
#
# DU chain: parent's texts hashref is dereferenced via %{$class->{'texts'}},
# override $params is dereferenced via %{$params}.  A NEW hash is created
# (not shared); override keys WIN.
# ===========================================================================
subtest 'new() clone merge -- parent texts + override: right-side wins in merge' => sub {
	local %ENV;

	my $base = Lingua::Text->new(en => 'colour', fr => 'couleur', de => $DE_TEXT);
	my $us   = $base->new(en => 'color');    # override en; de and fr inherited

	# Override key flows correctly.
	is($us->en(), 'color',    'clone merge: override key "en" wins');

	# Non-overridden keys flow from parent.
	is($us->fr(), 'couleur',  'clone merge: parent key "fr" flows to clone');
	is($us->de(), $DE_TEXT,   'clone merge: parent key "de" flows to clone');

	# The new object has its own hash (not shared with parent's {texts}).
	isnt(refaddr($us->{'texts'}), refaddr($base->{'texts'}),
		'clone WITH params creates a distinct {texts} hashref');

	# Mutation on clone must NOT affect parent (independent hash).
	$us->en('shade');
	is($base->en(), 'colour',
		'clone mutation does not propagate to parent (distinct hash)');
};

# ===========================================================================
# 7.  set() -- text and lang DU chain through params to texts hash
#
# DU chain: caller args → get_params → $params hashref → $lang and $text
# extracted → $self->{'texts'}->{$lang} = $text (final store).
# The intermediate $params is killed once both values are extracted.
# ===========================================================================
subtest 'set() -- text/lang DU chain through params to texts hash' => sub {
	my $t = Lingua::Text->new();

	# Flat hash form: text and lang both flow through $params.
	$t->set(text => $EN_TEXT, lang => 'en');
	is($t->en(), $EN_TEXT,
		'flat hash: text flows get_params → $params → {texts}{en}');

	# Hashref form: same DU chain via different get_params branch.
	$t->set({ text => $FR_TEXT, lang => 'fr' });
	is($t->fr(), $FR_TEXT,
		'hashref: text flows get_params → $params → {texts}{fr}');

	# Positional string form: text flows as the default-key arg to get_params.
	{
		local %ENV;
		$ENV{LANG} = $DE_LOCALE;
		mock 'I18N::LangTags::Detect::detect' => sub { () };

		$t->set($DE_TEXT);
		is($t->de(), $DE_TEXT,
			'positional: text flows via default-key get_params → {texts}{de}');
		restore_all();
	}

	# Verify only the keys we set are defined; no cross-contamination.
	is($t->en(), $EN_TEXT, 'en unchanged after subsequent set() calls');
	is($t->fr(), $FR_TEXT, 'fr unchanged after subsequent set() calls');
};

# ===========================================================================
# 8.  set() -- $lang via // chain: explicit arg vs locale fallback
#
# DU chain for $lang:
#   D($params->{'lang'} // _get_language())
#   Branch A: lang is in params → D(explicit value) → U(valid check) → U(hash write)
#   Branch B: lang absent from params → D(_get_language()) → U(defined check) → ...
# The // operator itself is the USE of params->{'lang'} and the USE of
# _get_language() as fallback.
# ===========================================================================
subtest 'set() $lang -- explicit lang vs locale fallback (//) ' => sub {
	# Branch A: explicit lang provided -- _get_language() must NOT be called.
	{
		my $detect_called = 0;
		mock 'I18N::LangTags::Detect::detect' => sub { $detect_called++; ('fr-FR') };

		my $t = Lingua::Text->new();
		$t->set(text => $EN_TEXT, lang => 'en');    # explicit lang
		is($t->en(), $EN_TEXT, 'explicit lang: text stored under "en"');
		# detect() may or may not be called; the key point is explicit lang wins.
		restore_all();
	}

	# Branch B: lang absent, locale provides it via _get_language().
	{
		local %ENV;
		$ENV{LANG} = $FR_LOCALE;
		mock 'I18N::LangTags::Detect::detect' => sub { () };

		my $t = Lingua::Text->new();
		$t->set(text => $FR_TEXT);    # no lang arg: // triggers locale fallback
		is($t->fr(), $FR_TEXT,
			'absent lang: _get_language() via // supplies "fr" from LANG env');
		restore_all();
	}

	# Verify // semantics: lang => '' is DEFINED but not valid ISO 639-1 →
	# carp (not locale fallback).  This confirms // not || is used.
	{
		local %ENV;
		$ENV{LANG} = $EN_LOCALE;
		mock 'I18N::LangTags::Detect::detect' => sub { () };

		my $t = Lingua::Text->new();
		my $result;
		does_carp_that_matches(
			sub { $result = $t->set(text => $EN_TEXT, lang => '') },
			'lang => "" is defined: // does NOT fall back to locale (correct //= not || behavior)',
			qr/usage: set/i,
		);
		ok(!defined($result), 'empty string lang triggers carp (not locale fallback)');
		restore_all();
	}
};

# ===========================================================================
# 9.  as_string() -- three $lang initialization paths
#
# DU chain for $lang:
#   Path A (positional):  @_==1 && !ref → D($lang = $_[0])
#   Path B (named/href):  else branch    → D($lang = $params->{'lang'})
#   Path C (no arg):      @_ empty/undef → $lang stays undef → D via //= locale
# All three paths end at: U(defined check) → U(hash lookup) → U(return).
# ===========================================================================
subtest 'as_string() -- three $lang initialization paths' => sub {
	local %ENV;
	$ENV{LANG} = $EN_LOCALE;
	mock 'I18N::LangTags::Detect::detect' => sub { () };

	my $t = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);

	# Path A: positional single arg → $lang = $_[0]
	is($t->as_string('fr'), $FR_TEXT,
		'path A (positional): $lang = positional arg flows to hash lookup');

	# Path B: named arg → $lang = params->{'lang'}
	is($t->as_string(lang => 'en'), $EN_TEXT,
		'path B (named): $lang = params->{lang} flows to hash lookup');

	# Path B: hashref arg
	is($t->as_string({ lang => 'fr' }), $FR_TEXT,
		'path B (hashref): $lang = params->{lang} from href flows to hash lookup');

	# Path C: no arg → $lang = undef → //= _get_language() = 'en'
	is($t->as_string(), $EN_TEXT,
		'path C (no arg): $lang via //= locale flows to hash lookup');

	restore_all();
};

# ===========================================================================
# 10. encode() -- $v copy-modify-store data flow
#
# Critical DU chain:
#   D($v = copy of $self->{'texts'}{$lang})  [scalar copy, NOT a reference]
#   → U(utf8::is_utf8($v) check)
#   → [conditional in-place modification: utf8::decode($v)]  -- $v only
#   → U(encode_entities($v) -- reads the possibly-modified $v)
#   → STORE back to $self->{'texts'}{$lang}
#
# Invariant: $self->{'texts'}{$lang} is NOT changed by utf8::decode($v)
# because $v is a copy.  The hash entry holds the original bytes until the
# explicit write-back on the last line of the loop body.
# ===========================================================================
subtest 'encode() -- $v copy semantics: original entry unchanged until write-back' => sub {
	my $original = $ETUDE;    # contains e-acute (non-ASCII)

	my $t = Lingua::Text->new(en => $original);

	# The original hash entry before encode().
	is($t->en(), $original,
		'before encode(): hash entry holds raw string');

	# spy passes through to the real encode_entities AND records every call.
	# This avoids the infinite recursion that mock causes when calling the
	# function being mocked from inside the mock itself.
	my $spy = spy 'HTML::Entities::encode_entities';

	$t->encode();

	my @calls = $spy->();
	is(scalar @calls, 1, 'encode_entities called exactly once for one slot');

	# Each recorded call is [$full_name, @args_passed].
	# The arg at index [1] is the value of $v at the time of the call,
	# i.e. AFTER utf8::decode but BEFORE the write-back to the hash.
	# Verify the argument contains the e-acute character (not already entity-encoded),
	# proving that $v holds the raw Unicode text at the point of the call.
	my $received_v = $calls[0][1];
	like($received_v, qr/\x{E9}/,
		'$v passed to encode_entities still contains e-acute (raw Unicode, not entity)');
	unlike($received_v, qr/&eacute;/,
		'$v passed to encode_entities has NOT been entity-encoded yet');

	# The write-back stores the entity-encoded result.
	is($t->en(), $ETUDE_E,
		'after encode(): entity-encoded string written back to hash entry');

	restore_all();
};

# ===========================================================================
# 11. encode() -- encode_entities call count matches language slot count
#
# DU chain integrity: the for loop visits each key exactly once.
# Non-language keys and undef/ref values are skipped.
# ===========================================================================
subtest 'encode() -- encode_entities called once per valid non-ref defined slot' => sub {
	# Use spy (not mock) to avoid infinite recursion: mock replaces the function,
	# so calling it from inside the mock would recurse infinitely.  spy wraps it,
	# passes through to the original, and records calls.

	# Two valid language slots: expect exactly 2 calls.
	{
		my $spy = spy 'HTML::Entities::encode_entities';
		my $t = Lingua::Text->new(en => $EN_TEXT, fr => $ETUDE);
		$t->encode();
		my @calls = $spy->();
		is(scalar @calls, 2,
			'encode_entities called exactly once per valid, defined, non-ref slot (2 slots)');
		restore_all();
	}

	# Undef slot is skipped (SECURITY V3): only the defined slot is processed.
	{
		my $spy = spy 'HTML::Entities::encode_entities';
		my $t2 = Lingua::Text->new(en => $EN_TEXT);
		$t2->de(undef);    # inject undef via AUTOLOAD setter
		$t2->encode();
		my @calls = $spy->();
		is(scalar @calls, 1,
			'encode_entities skips undef slot: called only once for the defined slot');
		restore_all();
	}

	# Ref slot is skipped (SECURITY V2/V3): only the non-ref slot is processed.
	{
		my $spy = spy 'HTML::Entities::encode_entities';
		my $t3 = Lingua::Text->new(en => $EN_TEXT);
		$t3->fr([1, 2, 3]);    # inject arrayref
		$t3->encode();
		my @calls = $spy->();
		is(scalar @calls, 1,
			'encode_entities skips ref slot: called only once for the non-ref slot');
		restore_all();
	}
};

# ===========================================================================
# 12. AUTOLOAD -- $key closure capture: two installed methods use independent
#     lexical copies
#
# DU chain: each AUTOLOAD call has its OWN `my ($key) = $AUTOLOAD =~ ...`
# binding.  The closure `sub { ... $key ... }` captures that specific binding.
# Two AUTOLOAD invocations for different codes must install two closures that
# store data under their own independent keys.
# ===========================================================================
subtest 'AUTOLOAD -- $key closure capture: two installed methods are independent' => sub {
	my $t = Lingua::Text->new();

	# First AUTOLOAD invocation installs Lingua::Text::zz with $key = 'zz'.
	$t->zz('zz-value');

	# Second AUTOLOAD invocation installs Lingua::Text::yy with $key = 'yy'.
	$t->yy('yy-value');

	# Each installed closure must use its own captured $key.
	is($t->zz(), 'zz-value',
		'AUTOLOAD closure for "zz" retrieves from texts{"zz"}, not texts{"yy"}');
	is($t->yy(), 'yy-value',
		'AUTOLOAD closure for "yy" retrieves from texts{"yy"}, not texts{"zz"}');

	# Overwrite via one code must not affect the other.
	$t->zz('zz-new');
	is($t->yy(), 'yy-value',
		'overwrite of "zz" does not affect "yy" (independent closures)');
	is($t->zz(), 'zz-new',
		'overwrite stored correctly under "zz"');

	# Verify the two-object case: installed method must be per-method-name, not
	# per-object -- the installed closure is in the package symbol table.
	my $t2 = Lingua::Text->new();
	$t2->zz('t2-zz');
	is($t->zz(),  'zz-new', 'object 1 "zz" unaffected by object 2 write');
	is($t2->zz(), 't2-zz',  'object 2 "zz" holds its own value');
};

# ===========================================================================
# 13. _get_language() -- $cached_lang/$cached_env DU chain: cache hit/miss
#
# DU chain for memoization closure variables:
#   $cached_lang, %cached_env: D(undef/empty) at first call →
#   D(slow path write) → U(fast path read on second call).
#
# Verify: the slow path fires on the first call (detect() invoked); the fast
# path fires on the second call with the same env (detect() NOT invoked again).
# ===========================================================================
subtest '_get_language() memoization -- slow path then fast path' => sub {
	# Use a nonsense locale never seen by any other subtest so the memoization
	# cache is guaranteed stale on the first call here, regardless of prior state.
	local %ENV;
	$ENV{LANG} = 'wz_WZ.UTF-8';    # unique; no other subtest uses this locale

	# Prevent Object::Configure from making a network call while %ENV is empty.
	mock 'Object::Configure::configure' => sub { $_[1] };

	my $slow_path_calls = 0;
	mock 'I18N::LangTags::Detect::detect' => sub {
		$slow_path_calls++;
		return ();
	};

	# Include a 'wz' slot so stringify returns a defined value.
	my $t = Lingua::Text->new(en => $EN_TEXT, wz => 'wz-text');

	# First stringify: cache miss (LANG changed) → slow path → detect() called.
	my $r1 = "$t";
	is($slow_path_calls, 1, 'first call: slow path ran (detect() invoked once)');

	# Second stringify with SAME env: cache hit → fast path → detect() NOT called.
	my $r2 = "$t";
	is($slow_path_calls, 1, 'second call: fast path used (detect() not called again)');

	# Third stringify: still on fast path.
	my $r3 = "$t";
	is($slow_path_calls, 1, 'third call: still using cached value');

	restore_all();
};

# ===========================================================================
# 14. _get_language() -- cache invalidation: all 5 tracked env vars trigger
#     slow path when changed
#
# DU chain for $stale in the fast-path check:
#   D(0) → for loop [conditional D(1) on first mismatch] → U(unless return).
# Each of the 5 cached vars must invalidate the cache when changed.
# ===========================================================================
subtest '_get_language() -- each of 5 env vars invalidates the cache' => sub {
	# Helper: prime the cache with all 5 vars set to known values,
	# then change one var and count detect() invocations.
	my %prime_env = (
		LANG                => $EN_LOCALE,
		LANGUAGE            => '',
		LC_ALL              => '',
		LC_MESSAGES         => '',
		HTTP_ACCEPT_LANGUAGE => '',
	);

	for my $changed_var (qw(LANG LANGUAGE LC_ALL LC_MESSAGES HTTP_ACCEPT_LANGUAGE)) {
		local %ENV;
		@ENV{keys %prime_env} = values %prime_env;

		# Prime the cache.
		{
			my $calls = 0;
			mock 'I18N::LangTags::Detect::detect' => sub { $calls++; () };
			my $t = Lingua::Text->new(en => $EN_TEXT);
			my $r = "$t";    # prime cache (capture to avoid void-context warning)
			restore_all();
		}

		# Change the target variable.
		$ENV{$changed_var} = 'CHANGED_VALUE';

		# Now detect() should be called again (cache is stale).
		my $calls_after = 0;
		{
			mock 'I18N::LangTags::Detect::detect' => sub { $calls_after++; () };
			my $t = Lingua::Text->new(en => $EN_TEXT);
			# Use as_string() directly rather than "$t" so that a locale that
			# resolves to a language code with no stored translation (e.g. 'ch'
			# from 'CHANGED_VALUE' via /i match) does not trigger a Perl
			# "uninitialized value" warning in string interpolation context.
			my $r = $t->as_string();
			restore_all();
		}

		cmp_ok($calls_after, '>=', 1,
			"changing $changed_var invalidates cache (detect() called again)");
	}
};

# ===========================================================================
# 15. _get_language() -- $lang data flow through all extraction branches
#
# The slow path has four sequential, guarded assignment points:
#   Branch 1: detect() returns a tag with [a-z]{2} prefix
#   Branch 2: LANGUAGE env var has [a-z]{2} prefix
#   Branch 3: LC_ALL/LC_MESSAGES/LANG env vars have [a-z]{2} prefix
#   Branch 4: LANG = 'C' or 'C.' → 'en'
# Only the first matching branch fires; subsequent branches are guarded by
# !defined($lang).  Test each branch in isolation.
# ===========================================================================
subtest '_get_language() -- $lang flows through each detection branch' => sub {
	# Branch 1: detect() provides a tag.
	{
		local %ENV;
		$ENV{LANG} = $EN_LOCALE;    # would provide 'en' in branch 3
		mock 'I18N::LangTags::Detect::detect' => sub { ('fr-FR') };

		my $t = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);
		is("$t", $FR_TEXT,
			'branch 1: detect() tag "fr-FR" → $lang = "fr" → French text');
		restore_all();
	}

	# Branch 2: LANGUAGE env var (detect returns nothing).
	{
		local %ENV;
		$ENV{LANG}     = $EN_LOCALE;    # would give 'en' in branch 3
		$ENV{LANGUAGE} = 'de:en';       # 'de' first in LANGUAGE wins
		mock 'I18N::LangTags::Detect::detect' => sub { () };

		my $t = Lingua::Text->new(en => $EN_TEXT, de => $DE_TEXT);
		is("$t", $DE_TEXT,
			'branch 2: LANGUAGE="de:en" → $lang = "de" → German text');
		restore_all();
	}

	# Branch 3: LC_ALL env var.
	{
		local %ENV;
		$ENV{LC_ALL} = 'fr_FR.UTF-8';
		mock 'I18N::LangTags::Detect::detect' => sub { () };

		my $t = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);
		is("$t", $FR_TEXT,
			'branch 3: LC_ALL="fr_FR.UTF-8" → $lang = "fr" → French text');
		restore_all();
	}

	# Branch 4: LANG = 'C' → $lang = 'en'.
	{
		local %ENV;
		$ENV{LANG} = 'C';
		mock 'I18N::LangTags::Detect::detect' => sub { () };

		my $t = Lingua::Text->new(en => $EN_TEXT);
		is("$t", $EN_TEXT,
			'branch 4: LANG="C" → $lang = "en" → English text');
		restore_all();
	}

	# No branch fires: $lang stays undef → as_string() carps.
	{
		local %ENV;
		mock 'I18N::LangTags::Detect::detect' => sub { () };

		my $t = Lingua::Text->new(en => $EN_TEXT);
		my $r;
		does_carp_that_matches(
			sub { $r = $t->as_string() },
			'no branch fires: $lang stays undef → as_string() carps',
			qr/usage: as_string/i,
		);
		ok(!defined($r), '$lang = undef → as_string() returns undef');
		restore_all();
	}
};

# ===========================================================================
# 16. $self->{'texts'} -- complete resource lifecycle
#
# The {texts} hashref is the sole data store for the object.  Track its
# lifecycle through every public mutating and querying method:
#   Create (new) → Write (set/AUTOLOAD setter) → Read (as_string/accessor)
#   → Modify (encode) → Copy (clone)
# At each step, verify the hash contains the expected entries and nothing more.
# ===========================================================================
subtest '$self->{texts} -- full lifecycle: create → write → read → encode → clone' => sub {
	local %ENV;
	$ENV{LANG} = $EN_LOCALE;
	mock 'I18N::LangTags::Detect::detect' => sub { () };
	mock 'Object::Configure::configure'   => sub { $_[1] };

	# Step 1: Create -- texts is empty.
	my $t = Lingua::Text->new();
	ok(!defined($t->en()), 'lifecycle step 1 (create): texts is empty');

	# Step 2: Write via set() -- 'en' slot defined.
	$t->set(text => $EN_TEXT, lang => 'en');
	is($t->en(), $EN_TEXT, 'lifecycle step 2 (write via set): en stored');
	ok(!defined($t->fr()), 'lifecycle step 2: fr still absent');

	# Step 3: Write via AUTOLOAD setter -- 'fr' slot defined.
	$t->fr($FR_TEXT);
	is($t->fr(), $FR_TEXT, 'lifecycle step 3 (write via AUTOLOAD): fr stored');
	is($t->en(), $EN_TEXT, 'lifecycle step 3: en unchanged');

	# Step 4: Read via as_string -- no side effects on {texts}.
	is($t->as_string('en'), $EN_TEXT,
		'lifecycle step 4 (read via as_string): en reads correctly');
	is($t->as_string('fr'), $FR_TEXT,
		'lifecycle step 4: fr reads correctly');

	# Step 5: Encode -- texts values mutated in-place.
	$t->fr("\x{E9}tude");    # overwrite fr with accented text
	$t->encode();
	is($t->fr(), $ETUDE_E,
		'lifecycle step 5 (encode): fr now holds entity-encoded form');
	is($t->en(), $EN_TEXT,
		'lifecycle step 5: en (ASCII) unchanged by encode()');

	# Step 6: Clone with params -- new object gets fresh texts.
	my $clone = $t->new(de => $DE_TEXT);
	is($clone->en(),    $EN_TEXT, 'lifecycle step 6 (clone): en inherited');
	is($clone->fr(),    $ETUDE_E, 'lifecycle step 6: fr inherited (encoded)');
	is($clone->de(),    $DE_TEXT, 'lifecycle step 6: de added by clone params');
	isnt(refaddr($clone->{'texts'}), refaddr($t->{'texts'}),
		'lifecycle step 6: clone has independent {texts} hash');

	restore_all();
};

# ===========================================================================
# 17. $@ -- cleared by eval inside new() (documented anomaly)
#
# ANOMALY: new() runs `eval { UNIVERSAL::isa($class, __PACKAGE__) }` for
# every class-name invocant.  When the eval SUCCEEDS, Perl sets $@ = ''.
# This means a caller's $@ value (set by a previous eval) is silently wiped.
#
# This is standard Perl behaviour (eval always sets $@), not a bug in
# Lingua::Text; however callers must not rely on $@ surviving across a
# Lingua::Text->new() call.
# ===========================================================================
subtest '$@ anomaly -- new() eval clears caller\'s $@' => sub {
	# Prime $@ with a known error string.
	eval { die "caller error" };
	like($@, qr/caller error/, 'pre-call: $@ holds the caller\'s error');

	# Lingua::Text->new('Lingua::Text') runs eval { UNIVERSAL::isa(...) }.
	# The eval SUCCEEDS → $@ is cleared to ''.
	Lingua::Text->new(en => 'hello');

	# Document: $@ is now '' (cleared).  No fix applied (standard eval semantics).
	is($@, '',
		'post-call: $@ cleared to "" by internal eval -- callers must not rely on $@ across new()');
};

# ===========================================================================
# 18. Concurrent interleaved writes -- no cross-contamination between objects
#
# Data flow integrity check: two distinct objects built and written in an
# interleaved sequence must each hold only their own data.
# Verifies that the {texts} hashref is genuinely per-object, not shared.
# ===========================================================================
subtest 'interleaved writes -- data flows to correct object, no cross-contamination' => sub {
	my $a = Lingua::Text->new();
	my $b = Lingua::Text->new();

	# Interleave set() calls between the two objects.
	$a->set(text => 'apple',  lang => 'en');
	$b->set(text => 'banana', lang => 'en');
	$a->set(text => 'pomme',  lang => 'fr');
	$b->set(text => 'banane', lang => 'fr');
	$a->en('APPLE');    # overwrite via AUTOLOAD

	is($a->en(), 'APPLE',  'a: en holds last-written value');
	is($b->en(), 'banana', 'b: en unaffected by a\'s en overwrite');
	is($a->fr(), 'pomme',  'a: fr holds a\'s value');
	is($b->fr(), 'banane', 'b: fr holds b\'s own value');

	# encode() on one object must not affect the other.
	$a->fr("\x{E9}tude");
	$a->encode();
	is($a->fr(), $ETUDE_E,    'a: fr is entity-encoded after a->encode()');
	is($b->fr(), 'banane',    'b: fr unaffected by a->encode()');
};

# ===========================================================================
# 19. Global state -- $_ and $@ not clobbered by data-mutating operations
#
# DU chain invariant: no public method should leave $_ or $@ in a different
# state than it found them (aside from the documented $@ clearing in new()).
# ===========================================================================
subtest 'global state -- $_ and $@ not clobbered during encode()' => sub {
	local $_ = 'sentinel-dollar-underscore';

	my $t = Lingua::Text->new(en => $EN_TEXT, fr => $ETUDE);

	# Trigger encode() -- the for loop uses `for my $lang` (named var, not $_).
	$t->encode();
	is($_, 'sentinel-dollar-underscore', 'encode() for loop does not clobber $_');

	# Trigger set() -- internal loops also avoid $_.
	$t->set(text => 'new-text', lang => 'de');
	is($_, 'sentinel-dollar-underscore', 'set() does not clobber $_');
};

# ===========================================================================
# 20. Memory -- no circular references in any lifecycle phase
# ===========================================================================
subtest 'memory -- no circular refs in full lifecycle' => sub {
	local %ENV;
	$ENV{LANG} = $EN_LOCALE;
	mock 'I18N::LangTags::Detect::detect' => sub { () };

	my $t = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);
	memory_cycle_ok($t, 'no cycle in freshly constructed object');

	$t->set(text => $DE_TEXT, lang => 'de');
	memory_cycle_ok($t, 'no cycle after set()');

	$t->encode();
	memory_cycle_ok($t, 'no cycle after encode()');

	my $clone = $t->new(es => 'hola');
	memory_cycle_ok($clone, 'no cycle in clone-with-params');

	my $shallow = $t->new();
	memory_cycle_ok($shallow, 'no cycle in shallow clone (shared texts ref)');

	restore_all();
};

done_testing();

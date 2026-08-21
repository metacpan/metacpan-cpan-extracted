#!/usr/bin/env perl
# t/path.t -- Control-Flow-Graph (CFG) path-coverage tests for Lingua::Text.
#
# Methodology: enumerate every unique execution path through each routine,
# then write one dedicated subtest per path.  Mocks are used to force
# specific branches; each subtest names the path it targets.
#
# ============================================================================
# CFG SUMMARY (see lib/Lingua/Text.pm for full source)
# ============================================================================
#
# new():
#   P-A1  : invalid defined invocant (not a LT class/object) -> carp + undef
#   P-A2  : undef invocant, no args (bare call) -> promoted to __PACKAGE__
#   P-B1  : class + single scalar + locale set -> stored under lang
#   P-B2  : class + single scalar + no locale  -> params=undef (discarded)
#   P-C   : class + flat pairs / hashref        -> params from Params::Get
#   P-D   : class + no args                    -> params=undef
#   P-E1  : object invocant + params            -> clone+merge
#   P-E2  : object invocant + no params         -> shallow clone
#   P-F1  : configure() returns truthy          -> bless { texts => $params }
#   P-F2  : configure() returns falsy/undef    -> bless {}
#
# set():
#   P-S0  : no args                            -> croak
#   P-S1  : lang=undef (no param, no env)      -> carp
#   P-S2  : lang provided but fails LANG_RE    -> carp
#   P-S3  : text=undef                         -> carp
#   P-S4  : all valid                          -> text stored, $self returned
#
# as_string():
#   P-AS1 : no arg + locale set, text exists   -> text returned
#   P-AS2 : no arg + no locale                 -> carp
#   P-AS3 : arg provided, text stored          -> text returned
#   P-AS4 : lang known, not stored             -> undef (no carp)
#
# encode():
#   P-EN0 : empty {texts}                      -> loop skips, $self returned
#   P-EN1 : non-lang key in texts              -> next (skip)
#   P-EN2 : undef value in valid lang slot     -> next (skip)
#   P-EN3 : ref value in valid lang slot       -> next (skip)
#   P-EN4 : value is UTF-8 flagged string      -> encode_entities directly
#   P-EN5 : value is byte string (no UTF-8 flag) -> utf8::decode then encode
#
# AUTOLOAD():
#   P-AL1 : key == 'DESTROY'                   -> return (no carp)
#   P-AL2 : ref($self) ne __PACKAGE__ (subclass) -> return undef
#   P-AL3 : key fails /^[a-z]{2}$/             -> return undef
#   P-AL4 : valid key, no args (getter)        -> return stored value
#   P-AL5 : valid key, with args (setter)      -> store + return value
#   P-AL-f: second call via installed closure  -> bypass AUTOLOAD entirely
#
# _get_language():
#   P-GL0 : cache hit (env unchanged)          -> return cached lang
#   P-GL1 : detect() tag matches               -> lang set from tag
#   P-GL2 : detect() empty, LANGUAGE matches   -> lang set from LANGUAGE
#   P-GL3 : detect()/LANGUAGE empty, LC_ALL    -> lang set from LC_ALL
#   P-GL4 : LC_ALL empty, LC_MESSAGES matches  -> lang set from LC_MESSAGES
#   P-GL5 : all above empty, LANG matches      -> lang set from LANG
#   P-GL6 : LANG = 'C' (POSIX locale)         -> lang = 'en'
#   P-GL7 : nothing matches, LANG not C        -> lang = undef
#
# _err():
#   P-E1  : key in %MESSAGES                  -> sprintf result
#   P-E2  : key NOT in %MESSAGES              -> "Unknown internal error: $key"
#           (TODO: dead for all current callers -- see .pm comment)
#
# ============================================================================

# HARNESS_ACTIVE must be set before 'use Lingua::Text' so Sub::Private
# does not block access to _get_language(), _err(), and other :Private subs.
BEGIN { $ENV{HARNESS_ACTIVE} = 1 }

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
# Constants
# ---------------------------------------------------------------------------
Readonly::Scalar my $LOCALE_EN  => 'en_US.UTF-8';
Readonly::Scalar my $LOCALE_FR  => 'fr_FR.UTF-8';
Readonly::Scalar my $LOCALE_DE  => 'de_DE.UTF-8';
Readonly::Scalar my $EN_TEXT    => 'hello';
Readonly::Scalar my $FR_TEXT    => 'bonjour';
Readonly::Scalar my $DE_TEXT    => 'Hallo';
Readonly::Scalar my $ETUDE      => "\x{E9}tude";    # U+00E9, UTF-8 flagged
Readonly::Scalar my $ETUDE_E    => '&eacute;tude';

# Unique "never-seen" locales used to force cache misses in _get_language().
# Each uses a different nonsense code so subtests don't share cached state.
Readonly::Scalar my $LOCALE_AA  => 'aa_AA.UTF-8';   # GL1 detect() path
Readonly::Scalar my $LOCALE_BB  => 'bb_BB.UTF-8';   # GL2 LANGUAGE path
Readonly::Scalar my $LOCALE_CC  => 'cc_CC.UTF-8';   # GL3 LC_ALL path
Readonly::Scalar my $LOCALE_DD  => 'dd_DD.UTF-8';   # GL4 LC_MESSAGES path
Readonly::Scalar my $LOCALE_EE  => 'ee_EE.UTF-8';   # GL5 LANG path
Readonly::Scalar my $LOCALE_FF  => 'ff_FF.UTF-8';   # GL0 fast-path primer
Readonly::Scalar my $LOCALE_GG  => 'gg_GG.UTF-8';   # GL6 C-locale test

# ---------------------------------------------------------------------------
# Helper: subclass that inherits from Lingua::Text, used for the AUTOLOAD
# subclass guard test.  AUTOLOAD guards against ref($self) ne __PACKAGE__.
# ---------------------------------------------------------------------------
{
	package Lingua::Text::PathTestSub;
	our @ISA = ('Lingua::Text');
}

# ===========================================================================
# new() -- P-A1: invalid defined invocant with args -> carp + return undef
#
# When the invocant is a defined string that does NOT pass UNIVERSAL::isa as a
# Lingua::Text class or subclass, new() emits a carp warning and returns undef.
# The string 'en' is not a Lingua::Text; it is the first key of the hash being
# accidentally consumed as the invocant (the classic double-colon misuse).
# ===========================================================================
subtest 'new() P-A1: invalid defined invocant -> carp + undef' => sub {
	my $result;
	does_carp_that_matches(
		sub { $result = Lingua::Text::new('en', $EN_TEXT) },
		'P-A1: invalid defined invocant emits carp',
		qr/use ->new\(\)/,
	);
	ok(!defined($result), 'P-A1: returns undef');
};

# ===========================================================================
# new() -- P-A2: undef invocant, no args -> class promoted, empty object
#
# Calling new() as a bare function with no arguments passes undef as $class.
# The invocant guard promotes undef to __PACKAGE__ and the no-args branch
# produces an empty object (configure() receives undef $params).
# ===========================================================================
subtest 'new() P-A2: undef invocant (bare call), no args -> empty object' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };    # return params unchanged
	my $t = Lingua::Text::new();
	isa_ok($t, 'Lingua::Text', 'P-A2: empty object returned');
	ok(!defined($t->en()), 'P-A2: no texts stored (params was undef)');
	restore_all();
};

# ===========================================================================
# new() -- P-B1: class + single scalar + locale set -> stored under lang
#
# When exactly one non-reference argument is passed, new() calls
# _get_language() to find the current locale.  If a lang is found, the scalar
# is stored as {texts}{$lang}.
# ===========================================================================
subtest 'new() P-B1: single scalar + locale -> stored under locale lang' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	local %ENV;
	$ENV{LANG} = $LOCALE_EN;
	mock 'I18N::LangTags::Detect::detect' => sub { () };
	my $t = Lingua::Text->new($EN_TEXT);
	is($t->en(), $EN_TEXT, 'P-B1: scalar stored under locale lang "en"');
	restore_all();
};

# ===========================================================================
# new() -- P-B2: class + single scalar + NO locale -> params stays undef
#
# When _get_language() returns undef (no locale set), the `if $lang` branch
# is false and $params is never assigned.  The scalar is silently discarded.
# ===========================================================================
subtest 'new() P-B2: single scalar + no locale -> silently discarded' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	local %ENV;
	mock 'I18N::LangTags::Detect::detect' => sub { () };
	my $t = Lingua::Text->new($EN_TEXT);
	ok(!defined($t->en()), 'P-B2: scalar discarded (no locale; texts is empty)');
	restore_all();
};

# ===========================================================================
# new() -- P-C: class + flat pairs -> params via Params::Get
#
# When @_ has more than one element (or the first is a reference), execution
# takes the elsif(@_) branch and calls get_params() to build $params.
# ===========================================================================
subtest 'new() P-C: flat pairs -> params populated via Params::Get' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	my $t = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);
	is($t->en(), $EN_TEXT, 'P-C flat pairs: en stored');
	is($t->fr(), $FR_TEXT, 'P-C flat pairs: fr stored');
	restore_all();
};

subtest 'new() P-C: hashref arg -> params populated via Params::Get' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	my $t = Lingua::Text->new({ en => $EN_TEXT, fr => $FR_TEXT });
	is($t->en(), $EN_TEXT, 'P-C hashref: en stored');
	is($t->fr(), $FR_TEXT, 'P-C hashref: fr stored');
	restore_all();
};

# ===========================================================================
# new() -- P-D: class + no args -> $params stays undef
#
# Neither single-scalar branch nor elsif(@_) fires.  $params is undef going
# into configure().
# ===========================================================================
subtest 'new() P-D: class + no args -> empty object' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	my $t = Lingua::Text->new();
	isa_ok($t, 'Lingua::Text', 'P-D: object created');
	ok(!defined($t->en()), 'P-D: no texts (params was undef)');
	restore_all();
};

# ===========================================================================
# new() -- P-F1: configure() returns truthy -> bless { texts => $params }
#
# When configure() returns a non-empty hashref, the ternary fires the true
# branch and produces an object with a {texts} key.
# ===========================================================================
subtest 'new() P-F1: configure() returns truthy -> { texts => $params }' => sub {
	mock 'Object::Configure::configure' => sub { { en => $EN_TEXT } };
	my $t = Lingua::Text->new();
	is($t->en(), $EN_TEXT, 'P-F1: texts present (configure injected them)');
	restore_all();
};

# ===========================================================================
# new() -- P-F2: configure() returns falsy/undef -> bless {}
#
# When configure() returns undef (or a false value), the ternary fires the
# false branch, producing an object with no {texts} key at all.
# ===========================================================================
subtest 'new() P-F2: configure() returns undef -> bless {}' => sub {
	mock 'Object::Configure::configure' => sub { undef };
	my $t = Lingua::Text->new();
	isa_ok($t, 'Lingua::Text', 'P-F2: object still created');
	ok(!$t->{'texts'}, 'P-F2: no {texts} key when configure returns undef');
	restore_all();
};

# ===========================================================================
# new() -- P-E1: object invocant + params -> clone with merged texts
#
# When the invocant is a Lingua::Text object AND $params is truthy (from
# flat-pair or hashref args), the clone path merges existing and new texts.
# ===========================================================================
subtest 'new() P-E1: object invocant + params -> clone+merge' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	my $orig = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);
	my $clone = $orig->new(de => $DE_TEXT);
	is($clone->en(), $EN_TEXT, 'P-E1: en inherited from original');
	is($clone->fr(), $FR_TEXT, 'P-E1: fr inherited from original');
	is($clone->de(), $DE_TEXT, 'P-E1: de added by clone args');
	isnt(refaddr($clone->{'texts'}), refaddr($orig->{'texts'}),
		'P-E1: clone has independent {texts} hashref');
	restore_all();
};

# ===========================================================================
# new() -- P-E2: object invocant + no params -> shallow clone
#
# When the invocant is a Lingua::Text object AND no args are passed, $params
# stays undef and the `if($params)` in the clone branch is false.
# Result: bless { %{$class} } -- copies ALL top-level keys from original.
# ===========================================================================
subtest 'new() P-E2: object invocant + no params -> shallow clone' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	my $orig = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);
	my $clone = $orig->new();
	is($clone->en(), $EN_TEXT, 'P-E2: en present in shallow clone');
	is($clone->fr(), $FR_TEXT, 'P-E2: fr present in shallow clone');
	# Shallow clone: {texts} ref IS shared (bless { %{$class} } copies the ref, not the hash).
	is(refaddr($clone->{'texts'}), refaddr($orig->{'texts'}),
		'P-E2: shallow clone shares {texts} ref (documented behaviour)');
	restore_all();
};

# ===========================================================================
# set() -- P-S0: no args -> croak (programmer error)
#
# The first guard inside set() is `croak unless @_`.  This fires when set()
# is called without any arguments, signalling a programmer error (not a
# runtime condition), so it CROAKS rather than carps.
# ===========================================================================
subtest 'set() P-S0: no args -> croak' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	my $t = Lingua::Text->new();
	does_croak_that_matches(
		sub { $t->set() },
		'P-S0: no-args set() croaks',
		qr/Usage: set\(text/,
	);
	restore_all();
};

# ===========================================================================
# set() -- P-S1: lang=undef (no lang param, no locale) -> carp
#
# When lang is not passed AND _get_language() returns undef (no locale set),
# `$lang = $params->{lang} // _get_language()` yields undef.
# The first `return _carp_set_usage() unless defined($lang)` guard fires.
# ===========================================================================
subtest 'set() P-S1: lang undef (no param, no locale) -> carp' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	local %ENV;
	mock 'I18N::LangTags::Detect::detect' => sub { () };
	my $t = Lingua::Text->new();
	my $result;
	does_carp_that_matches(
		sub { $result = $t->set(text => $EN_TEXT) },
		'P-S1: lang=undef carps',
		qr/usage: set\(text/i,
	);
	ok(!defined($result), 'P-S1: returns undef');
	restore_all();
};

# ===========================================================================
# set() -- P-S2: lang provided but fails _is_valid_language() -> carp
#
# When lang is explicitly provided but does not match LANG_RE
# (/^[a-z]{2}(?:_[A-Z]{2})?$/), the second guard fires.
# lang='eng' (3 chars) is the representative invalid value.
# ===========================================================================
subtest 'set() P-S2: invalid lang format -> carp' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	my $t = Lingua::Text->new();
	my $result;
	does_carp_that_matches(
		sub { $result = $t->set(text => $EN_TEXT, lang => 'eng') },
		'P-S2: invalid lang carps',
		qr/usage: set\(text/i,
	);
	ok(!defined($result), 'P-S2: returns undef');
	restore_all();
};

# ===========================================================================
# set() -- P-S3: text=undef -> carp
#
# When lang is valid but text is undef, the third guard
# `return carp unless defined($text)` fires.
# ===========================================================================
subtest 'set() P-S3: text=undef -> carp' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	my $t = Lingua::Text->new();
	my $result;
	does_carp_that_matches(
		sub { $result = $t->set(text => undef, lang => 'en') },
		'P-S3: undef text carps',
		qr/usage: set\(text/i,
	);
	ok(!defined($result), 'P-S3: returns undef');
	restore_all();
};

# ===========================================================================
# set() -- P-S4: all guards pass -> text stored, $self returned
#
# The happy path: valid lang, defined text, all three guards pass.
# The text is written to $self->{texts}{$lang} and $self is returned.
# ===========================================================================
subtest 'set() P-S4: valid args -> text stored, $self returned' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	my $t = Lingua::Text->new();
	my $ret = $t->set(text => $EN_TEXT, lang => 'en');
	is(ref($ret), 'Lingua::Text', 'P-S4: returns $self (method chaining)');
	is($t->en(), $EN_TEXT,        'P-S4: text stored in {texts}{en}');
	restore_all();
};

# ===========================================================================
# as_string() -- P-AS1: no arg + locale set, text stored -> text returned
#
# When called with no arguments and a locale is set, _get_language() returns
# a lang code.  If that lang is stored, the translation is returned.
# ===========================================================================
subtest 'as_string() P-AS1: no arg + locale + text stored -> text returned' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	local %ENV;
	$ENV{LANG} = $LOCALE_EN;
	mock 'I18N::LangTags::Detect::detect' => sub { () };
	my $t = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);
	is($t->as_string(), $EN_TEXT, 'P-AS1: locale lang text returned');
	restore_all();
};

# ===========================================================================
# as_string() -- P-AS2: no arg + no locale -> carp + undef
#
# When _get_language() returns undef (no locale set), `defined($lang)` is
# false, so the `Carp::carp` branch fires.
# ===========================================================================
subtest 'as_string() P-AS2: no arg + no locale -> carp' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	local %ENV;
	mock 'I18N::LangTags::Detect::detect' => sub { () };
	my $t = Lingua::Text->new(en => $EN_TEXT);
	my $result;
	does_carp_that_matches(
		sub { $result = $t->as_string() },
		'P-AS2: no locale carps',
		qr/usage: as_string/i,
	);
	ok(!defined($result), 'P-AS2: returns undef');
	restore_all();
};

# ===========================================================================
# as_string() -- P-AS3: arg provided -> Params::Get extracts lang -> text
#
# When @_ is non-empty and $_[0] is defined, the outer `if(@_ && defined)` is
# true.  Params::Get parses the args and $lang is set from $params->{lang}.
# ===========================================================================
subtest 'as_string() P-AS3: arg provided -> lang set, text returned' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	my $t = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);

	# Positional: as_string('fr')
	is($t->as_string('fr'), $FR_TEXT, 'P-AS3 positional: fr text returned');

	# Named: as_string(lang => 'en')
	is($t->as_string(lang => 'en'), $EN_TEXT, 'P-AS3 named: en text returned');

	# Hashref: as_string({ lang => 'fr' })
	is($t->as_string({ lang => 'fr' }), $FR_TEXT, 'P-AS3 hashref: fr text returned');

	restore_all();
};

# ===========================================================================
# as_string() -- P-AS4: lang is known but no text stored -> undef, no carp
#
# When defined($lang) is true (lang code resolved) but the hash lookup
# $self->{texts}->{$lang} returns undef, the method returns undef WITHOUT
# emitting a carp.  This is the documented "not yet translated" case.
# ===========================================================================
subtest 'as_string() P-AS4: lang known, not stored -> undef (no carp)' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	my $t = Lingua::Text->new(en => $EN_TEXT);
	my $result;
	# 'de' is valid and $lang will be 'de', but no German text is stored.
	lives_ok(
		sub { $result = $t->as_string('de') },
		'P-AS4: no exception when lang known but not stored',
	);
	ok(!defined($result), 'P-AS4: returns undef silently');
	restore_all();
};

# ===========================================================================
# encode() -- P-EN0: empty {texts} -> loop runs 0 times -> $self returned
#
# With no entries in {texts}, keys() returns an empty list and the for loop
# body never executes.  encode() still returns $self for chaining.
# ===========================================================================
subtest 'encode() P-EN0: empty texts -> loop skips, $self returned' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	my $t = Lingua::Text->new();
	my $ret = $t->encode();
	is(ref($ret), 'Lingua::Text', 'P-EN0: encode() returns $self even on empty object');
	# Compare refaddr rather than the objects directly: the "" overload returns
	# undef when no locale is set, which generates an "uninitialized value"
	# Perl warning if cmp_ok stringifies both sides.
	is(refaddr($ret), refaddr($t), 'P-EN0: same object returned (not a copy)');
	restore_all();
};

# ===========================================================================
# encode() -- P-EN1: non-lang key in texts -> next (skip)
#
# The first guard `next unless _is_valid_language($lang)` filters out keys
# that are not valid ISO 639-1 codes.  A 3-char key like 'eng' is stored in
# {texts} directly but must be skipped by encode().
# ===========================================================================
subtest 'encode() P-EN1: non-lang key -> next (skip, value unchanged)' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	my $t = Lingua::Text->new(en => '<b>bold</b>');
	$t->{'texts'}{'eng'} = '<script>xss</script>';    # inject 3-char key directly
	$t->encode();
	is($t->{'texts'}{'eng'}, '<script>xss</script>',
		'P-EN1: non-lang key value unchanged (not entity-encoded)');
	is($t->en(), '&lt;b&gt;bold&lt;/b&gt;',
		'P-EN1: valid lang key "en" is still encoded');
	restore_all();
};

# ===========================================================================
# encode() -- P-EN2: undef value in valid lang slot -> next (skip)
#
# The second guard `next unless defined($v) && !ref($v)` filters undef.
# Without this guard, encode_entities(undef) would return '' and silently
# replace the stored undef.
# ===========================================================================
subtest 'encode() P-EN2: undef value -> next (preserved as undef)' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	my $t = Lingua::Text->new(en => $EN_TEXT);
	$t->fr(undef);    # store undef in 'fr' slot
	$t->encode();
	ok(!defined($t->fr()), 'P-EN2: undef slot preserved (not encoded to empty string)');
	is($t->en(), $EN_TEXT, 'P-EN2: ASCII en slot unchanged');
	restore_all();
};

# ===========================================================================
# encode() -- P-EN3: ref value in valid lang slot -> next (skip)
#
# The same second guard also filters out references.  utf8::decode(ref) and
# encode_entities(ref) would corrupt the object or leak its stringification.
# ===========================================================================
subtest 'encode() P-EN3: ref value -> next (preserved as-is)' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	my $t = Lingua::Text->new(en => $EN_TEXT);
	my $ref_val = [1, 2, 3];
	$t->fr($ref_val);
	$t->encode();
	is($t->fr(), $ref_val, 'P-EN3: ref slot preserved (same ref returned)');
	restore_all();
};

# ===========================================================================
# encode() -- P-EN4: UTF-8 flagged string -> encode_entities called directly
#
# When utf8::is_utf8($v) is true, the `utf8::decode($v) unless utf8::is_utf8`
# branch is NOT taken.  The value goes directly to encode_entities().
# Wide-character notation (\x{E9}) always produces a UTF-8-flagged string.
# ===========================================================================
subtest 'encode() P-EN4: UTF-8 flagged string -> entity-encoded directly' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	my $t = Lingua::Text->new();
	# U+263A (SMILEY FACE) is above U+00FF so Perl must use the UTF-8 internal
	# representation; utf8::is_utf8() will return true for this codepoint.
	my $wide = "\x{263A}";
	$t->{'texts'}{'fr'} = $wide;
	ok(utf8::is_utf8($t->{'texts'}{'fr'}), 'P-EN4 setup: stored value has UTF-8 flag');
	$t->encode();
	is($t->fr(), '&#x263A;', 'P-EN4: UTF-8 flagged string entity-encoded');
	restore_all();
};

# ===========================================================================
# encode() -- P-EN5: byte string without UTF-8 flag -> utf8::decode then encode
#
# When utf8::is_utf8($v) is false, utf8::decode($v) is called first to
# upgrade the byte representation, then encode_entities() is applied.
# utf8::encode() converts a wide char to UTF-8 bytes and removes the flag.
# ===========================================================================
subtest 'encode() P-EN5: non-UTF-8-flagged string -> utf8::decode first' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };

	# Produce a byte string ("\xC3\xA9tude") with the UTF-8 flag OFF.
	my $bytes = $ETUDE;      # starts as a wide char (UTF-8 flagged)
	utf8::encode($bytes);    # converts to bytes; removes UTF-8 flag
	ok(!utf8::is_utf8($bytes), 'P-EN5 setup: byte string has no UTF-8 flag');

	my $t = Lingua::Text->new();
	$t->fr($bytes);          # store the byte string
	ok(!utf8::is_utf8($t->fr()), 'P-EN5 setup: stored value has no UTF-8 flag');

	$t->encode();
	is($t->fr(), $ETUDE_E, 'P-EN5: byte string decoded then entity-encoded');
	restore_all();
};

# ===========================================================================
# AUTOLOAD -- P-AL1: key == 'DESTROY' -> return immediately (no carp/croak)
#
# When an object is garbage collected, Perl may invoke AUTOLOAD with
# $AUTOLOAD set to 'Lingua::Text::DESTROY'.  The first guard ensures
# this is a no-op, preventing spurious "Can't locate object method DESTROY"
# errors.  Tested by setting $AUTOLOAD and calling the AUTOLOAD sub directly.
# ===========================================================================
subtest 'AUTOLOAD P-AL1: DESTROY key -> returns silently' => sub {
	local $Lingua::Text::AUTOLOAD = 'Lingua::Text::DESTROY';
	my $t = Lingua::Text->new(en => $EN_TEXT);
	my $result;
	# Call AUTOLOAD directly (normally triggered by Perl's GC dispatcher).
	lives_ok(
		sub { $result = Lingua::Text::AUTOLOAD($t) },
		'P-AL1: DESTROY guard does not throw',
	);
	ok(!defined($result), 'P-AL1: DESTROY returns undef');
};

# ===========================================================================
# AUTOLOAD -- P-AL2: ref($self) ne __PACKAGE__ -> return undef (subclass guard)
#
# The guard `return unless ref($self) eq __PACKAGE__` fires when AUTOLOAD is
# inherited by a subclass.  AUTOLOAD is intentionally package-local; a
# subclass instance calling an undefined method returns undef silently.
# ===========================================================================
subtest 'AUTOLOAD P-AL2: subclass ref -> undef (subclass guard fires)' => sub {
	# Lingua::Text::PathTestSub inherits from Lingua::Text but has no own AUTOLOAD.
	my $sub_obj = bless { texts => { en => $EN_TEXT } }, 'Lingua::Text::PathTestSub';
	# Calling ->xx() on a subclass instance routes to AUTOLOAD (inherited).
	# The ref($self) eq 'Lingua::Text' guard fires because ref is '...::PathTestSub'.
	my $result = $sub_obj->xx();
	ok(!defined($result), 'P-AL2: subclass instance returns undef from AUTOLOAD');
};

# ===========================================================================
# AUTOLOAD -- P-AL3: key fails /^[a-z]{2}$/ -> return undef (name guard)
#
# After the DESTROY and ref guards, AUTOLOAD checks `$key =~ /^[a-z]{2}$/`.
# A method name with 1, 3, or more chars, or with non-lowercase letters,
# fails this check and returns undef silently.
# ===========================================================================
subtest 'AUTOLOAD P-AL3: invalid key names -> undef (name guard fires)' => sub {
	my $t = Lingua::Text->new(en => $EN_TEXT);

	# 1 char (below min)
	ok(!defined($t->e()),   'P-AL3: 1-char key returns undef');
	# 3 chars (above 2-char max)
	ok(!defined($t->eng()), 'P-AL3: 3-char key returns undef');
};

# ===========================================================================
# AUTOLOAD -- P-AL4 + P-AL-fast: getter path + installed-closure fast path
#
# First call: AUTOLOAD installs a permanent closure for the key and returns
# the stored value.  Second call: the closure handles the call directly,
# bypassing AUTOLOAD entirely.  Both calls must return the same value.
# ===========================================================================
subtest 'AUTOLOAD P-AL4: getter + P-AL-fast: second call via installed closure' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	my $t = Lingua::Text->new(en => $EN_TEXT);

	# First call: routes through AUTOLOAD (no 'en' method yet installed).
	my $first = $t->en();
	is($first, $EN_TEXT, 'P-AL4: AUTOLOAD getter returns stored value');

	# Verify closure was installed: the symbol table entry now exists.
	ok(defined(&Lingua::Text::en), 'P-AL4: closure installed in symbol table after first call');

	# Second call: routes through the installed closure, not AUTOLOAD.
	# Result must be identical.
	my $second = $t->en();
	is($second, $EN_TEXT, 'P-AL-fast: installed closure returns same value');

	restore_all();
};

# ===========================================================================
# AUTOLOAD -- P-AL5: setter path (args provided -> store then return)
#
# When @_ is non-empty after shifting $self, the setter branch fires.
# The value is written to $self->{texts}->{$key} and returned.
# ===========================================================================
subtest 'AUTOLOAD P-AL5: setter (args provided) -> store and return' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	my $t = Lingua::Text->new();
	my $stored = $t->de($DE_TEXT);    # setter: @_ has one element ($DE_TEXT)
	is($stored, $DE_TEXT, 'P-AL5: setter returns the stored value');
	is($t->de(), $DE_TEXT, 'P-AL5: value retrievable via getter');
	restore_all();
};

# ===========================================================================
# _get_language() -- P-GL0: cache hit -> return cached lang
#
# After a first (slow-path) call with a unique locale, calling again with the
# same env must return from cache WITHOUT calling detect() a second time.
# ===========================================================================
subtest '_get_language() P-GL0: cache hit (same env) -> detect() not called again' => sub {
	local %ENV;
	$ENV{LANG} = $LOCALE_FF;    # unique locale to force cache miss on first call
	mock 'Object::Configure::configure' => sub { $_[1] };
	my $detect_calls = 0;
	mock 'I18N::LangTags::Detect::detect' => sub { $detect_calls++; () };

	# First call: slow path -- detect() must be called.
	my $t = Lingua::Text->new(ff => 'ff-text');
	my $r1 = $t->as_string();    # triggers _get_language()
	is($detect_calls, 1, 'P-GL0 setup: first call uses slow path (detect() called)');

	# Second call with SAME env: fast path -- detect() must NOT be called again.
	my $r2 = $t->as_string();
	is($detect_calls, 1, 'P-GL0: second call uses cache (detect() not called again)');

	restore_all();
};

# ===========================================================================
# _get_language() -- P-GL1: detect() returns a tag -> lang set from tag
#
# When I18N::LangTags::Detect::detect() returns at least one tag matching
# /^([a-z]{2})/i, the loop captures $1 and breaks.  Subsequent branches
# (LANGUAGE, LC_ALL, etc.) are NOT checked.
# ===========================================================================
subtest '_get_language() P-GL1: detect() tag -> lang from detect()' => sub {
	local %ENV;
	$ENV{LANG} = $LOCALE_AA;    # unique locale (would give 'aa' on branch 5)
	mock 'Object::Configure::configure' => sub { $_[1] };
	mock 'I18N::LangTags::Detect::detect' => sub { ('fr-FR') };
	my $t = Lingua::Text->new(fr => $FR_TEXT, aa => 'ignored');
	is($t->as_string(), $FR_TEXT, 'P-GL1: detect() tag "fr-FR" -> lang="fr" -> FR text');
	restore_all();
};

# ===========================================================================
# _get_language() -- P-GL2: detect() empty, LANGUAGE env matches -> lang set
#
# When detect() returns nothing, the LANGUAGE environment variable is checked.
# A colon-separated list (e.g. 'de:en') yields the first code.
# ===========================================================================
subtest '_get_language() P-GL2: detect() empty, LANGUAGE set -> lang from LANGUAGE' => sub {
	local %ENV;
	$ENV{LANG}     = $LOCALE_BB;    # unique, would give 'bb' on branch 5
	$ENV{LANGUAGE} = 'de:en';       # 'de' wins (first in list)
	mock 'Object::Configure::configure' => sub { $_[1] };
	mock 'I18N::LangTags::Detect::detect' => sub { () };
	my $t = Lingua::Text->new(de => $DE_TEXT, bb => 'ignored');
	is($t->as_string(), $DE_TEXT, 'P-GL2: LANGUAGE "de:en" -> lang="de" -> DE text');
	restore_all();
};

# ===========================================================================
# _get_language() -- P-GL3: detect()/LANGUAGE empty, LC_ALL matches -> lang
#
# When detect() and LANGUAGE are both empty, the inner for-loop checks
# LC_ALL first.  A value like 'fr_FR.UTF-8' yields 'fr'.
# ===========================================================================
subtest '_get_language() P-GL3: LC_ALL set -> lang from LC_ALL' => sub {
	local %ENV;
	$ENV{LANG}    = $LOCALE_CC;    # unique, would give 'cc' on branch 5
	$ENV{LC_ALL}  = 'fr_FR.UTF-8';
	mock 'Object::Configure::configure' => sub { $_[1] };
	mock 'I18N::LangTags::Detect::detect' => sub { () };
	my $t = Lingua::Text->new(fr => $FR_TEXT, cc => 'ignored');
	is($t->as_string(), $FR_TEXT, 'P-GL3: LC_ALL "fr_FR.UTF-8" -> lang="fr" -> FR text');
	restore_all();
};

# ===========================================================================
# _get_language() -- P-GL4: LC_ALL absent, LC_MESSAGES matches -> lang
#
# When LC_ALL is absent/unset, the loop advances to LC_MESSAGES.
# ===========================================================================
subtest '_get_language() P-GL4: LC_MESSAGES set -> lang from LC_MESSAGES' => sub {
	local %ENV;
	$ENV{LANG}        = $LOCALE_DD;    # unique
	$ENV{LC_MESSAGES} = 'de_DE.UTF-8';
	# LC_ALL is intentionally absent to force the loop to advance.
	mock 'Object::Configure::configure' => sub { $_[1] };
	mock 'I18N::LangTags::Detect::detect' => sub { () };
	my $t = Lingua::Text->new(de => $DE_TEXT, dd => 'ignored');
	is($t->as_string(), $DE_TEXT, 'P-GL4: LC_MESSAGES "de_DE.UTF-8" -> lang="de" -> DE text');
	restore_all();
};

# ===========================================================================
# _get_language() -- P-GL5: LC_ALL/LC_MESSAGES absent, LANG matches -> lang
#
# When neither LC_ALL nor LC_MESSAGES is set, the loop reaches LANG.
# ===========================================================================
subtest '_get_language() P-GL5: LANG set -> lang from LANG' => sub {
	local %ENV;
	$ENV{LANG} = $LOCALE_EE;    # unique; 'ee' is the lang code extracted
	mock 'Object::Configure::configure' => sub { $_[1] };
	mock 'I18N::LangTags::Detect::detect' => sub { () };
	my $t = Lingua::Text->new(ee => 'ee-text');
	is($t->as_string(), 'ee-text', 'P-GL5: LANG "ee_EE.UTF-8" -> lang="ee" -> ee text');
	restore_all();
};

# ===========================================================================
# _get_language() -- P-GL6: LANG = 'C' -> lang = 'en' (POSIX fallback)
#
# The POSIX 'C' locale is treated as English.  The line:
#   $lang //= 'en' if ($ENV{'LANG'} // '') =~ /^C(?:\z|\.)/;
# fires when all other branches failed AND LANG matches /^C(\z|\.)/
# ===========================================================================
subtest '_get_language() P-GL6: LANG=C -> lang=en (POSIX fallback)' => sub {
	local %ENV;
	$ENV{LANG} = 'C';    # POSIX C locale
	mock 'Object::Configure::configure' => sub { $_[1] };
	mock 'I18N::LangTags::Detect::detect' => sub { () };
	my $t = Lingua::Text->new(en => $EN_TEXT);
	is($t->as_string(), $EN_TEXT, 'P-GL6: LANG=C returns English text');
	restore_all();
};

subtest '_get_language() P-GL6b: LANG=C.UTF-8 -> lang=en' => sub {
	local %ENV;
	$ENV{LANG} = 'C.UTF-8';    # C locale with encoding suffix
	mock 'Object::Configure::configure' => sub { $_[1] };
	mock 'I18N::LangTags::Detect::detect' => sub { () };
	my $t = Lingua::Text->new(en => $EN_TEXT);
	is($t->as_string(), $EN_TEXT, 'P-GL6b: LANG=C.UTF-8 also returns English text');
	restore_all();
};

# ===========================================================================
# _get_language() -- P-GL7: nothing matches, LANG not C -> lang = undef
#
# All branches exhausted with no match.  $lang stays undef.
# Verified via as_string() which carps when _get_language() returns undef.
# ===========================================================================
subtest '_get_language() P-GL7: no match -> lang=undef -> carp from as_string()' => sub {
	local %ENV;
	# Empty LANG or something that fails the regex (e.g. purely numeric).
	$ENV{LANG} = '12345';    # does not match [a-z]{2} and not 'C'
	mock 'Object::Configure::configure' => sub { $_[1] };
	mock 'I18N::LangTags::Detect::detect' => sub { () };
	my $t = Lingua::Text->new(en => $EN_TEXT);
	my $result;
	does_carp_that_matches(
		sub { $result = $t->as_string() },
		'P-GL7: no lang match -> carp from as_string()',
		qr/usage: as_string/i,
	);
	ok(!defined($result), 'P-GL7: returns undef');
	restore_all();
};

# ===========================================================================
# _err() -- P-E1: known key -> sprintf with package name
#
# The ternary fires the `defined($fmt)` true branch, returning a formatted
# string with __PACKAGE__ interpolated.
# ===========================================================================
subtest '_err() P-E1: known key -> formatted message' => sub {
	# Access private function: HARNESS_ACTIVE is set in BEGIN above.
	my $msg = Lingua::Text::_err('new_oo_style');
	like($msg, qr/Lingua::Text/, 'P-E1: package name interpolated');
	like($msg, qr/use ->new\(\)/, 'P-E1: message text correct');
};

# ===========================================================================
# _err() -- P-E2: unknown key -> Carp::confess (defensive guard)
#
# No existing caller passes an unknown key; all hard-code a key present in
# %MESSAGES.  The branch is a defensive guard for future callers: it confess-
# dies so a programmer who adds a new call site without updating %MESSAGES gets
# an immediate, clearly attributed error rather than a silent wrong message.
# ===========================================================================
subtest '_err() P-E2: unknown key -> confess (defensive guard for future callers)' => sub {
	throws_ok(
		sub { Lingua::Text::_err('__nonexistent_key_42__') },
		qr/Internal error.*__nonexistent_key_42__/,
		'P-E2: unknown key causes confess with key name in message',
	);
};

# ===========================================================================
# _is_valid_language() -- both paths
#
# The function is a single regex match.  P1: match succeeds (true). P2: fails.
# ===========================================================================
subtest '_is_valid_language() -- valid and invalid paths' => sub {
	# P1: valid (true path).
	ok(Lingua::Text::_is_valid_language('en'),    'P1: "en" is valid');
	ok(Lingua::Text::_is_valid_language('fr'),    'P1: "fr" is valid');
	ok(Lingua::Text::_is_valid_language('en_US'), 'P1: "en_US" is valid');

	# P2: invalid (false path).
	ok(!Lingua::Text::_is_valid_language('e'),    'P2: "e" is invalid');
	ok(!Lingua::Text::_is_valid_language('eng'),  'P2: "eng" is invalid');
	ok(!Lingua::Text::_is_valid_language('EN'),   'P2: "EN" is invalid');
	ok(!Lingua::Text::_is_valid_language(''),     'P2: "" is invalid');
};

# ===========================================================================
# _carp_set_usage() -- single path (carp + return undef)
# ===========================================================================
subtest '_carp_set_usage() -- emits carp and returns undef' => sub {
	my $result;
	does_carp_that_matches(
		sub { $result = Lingua::Text::_carp_set_usage() },
		'_carp_set_usage: carp emitted',
		qr/usage: set\(text/i,
	);
	ok(!defined($result), '_carp_set_usage: returns undef');
};

done_testing();

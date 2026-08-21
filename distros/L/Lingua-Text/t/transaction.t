#!/usr/bin/env perl
# t/transaction.t -- Multi-step lifecycle and transaction-flow tests for Lingua::Text.
#
# METHODOLOGY
# -----------
# Each subtest walks an entity through multiple sequential steps and asserts
# state consistency at every boundary.  The focus is on:
#
#   * Multi-step integrity: correct state after each phase.
#   * Mid-flight failures and rollback: a bad step must not corrupt prior state.
#   * Idempotency: repeating the same transaction must yield the same outcome.
#   * Ordering guarantees: steps taken out of order must behave as documented.
#   * Concurrent independence: two concurrent objects must not share state.
#
# ============================================================================
# LIFECYCLE TRANSACTION MAP
# ============================================================================
#
# TXN-1  Build → Populate (set) → Retrieve: basic ordered pipeline
# TXN-2  Build → Populate (AUTOLOAD setters) → Retrieve: accessor pipeline
# TXN-3  Mixed population (set + AUTOLOAD) → Retrieve: consistent merged state
# TXN-4  Build → Populate → encode() → Render: HTML pipeline (core use case)
# TXN-5  Double-encode: encode() called twice → documented corruption pattern
# TXN-6  set() mid-sequence partial failure: bad lang on step N; step N-1 preserved
# TXN-7  Chained set() pipeline: new→set→set→set→encode (return-value chain)
# TXN-8  Clone isolation: parent → clone (merge) → mutate clone → parent unchanged
# TXN-9  Shallow-clone shared {texts}: bare new() → both objects share the ref
# TXN-10 encode() before cloning: clone still gets encoded text
# TXN-11 Idempotency of set(): same key twice → same state, no error
# TXN-12 Idempotency of new() from the same hashref: two independent objects
# TXN-13 Concurrent objects: two objects built from the same source do not interfere
# TXN-14 Locale switch mid-pipeline: build under locale A → switch to B → retrieve
# TXN-15 Object::Configure key injection → encode() skips injected keys
# TXN-16 Single-scalar new() under locale → locale removed → stale object still serves
# ============================================================================

# HARNESS_ACTIVE must be set BEFORE 'use Lingua::Text' so Sub::Private's
# enforce mode does not block access to private helpers called inside the
# module when AUTOLOAD or _get_language() are exercised in tests.
BEGIN { $ENV{HARNESS_ACTIVE} = 1 }

use strict;
use warnings;

use Test::Most;
use Test::Carp;
use Test::Mockingbird;
use Readonly;

BEGIN {
	use_ok('Lingua::Text') or BAIL_OUT('Cannot load Lingua::Text -- all tests invalid');
}

# ---------------------------------------------------------------------------
# Constants (no magic strings or numbers anywhere in the test body)
# ---------------------------------------------------------------------------
Readonly::Scalar my $EN   => 'en';
Readonly::Scalar my $FR   => 'fr';
Readonly::Scalar my $DE   => 'de';
Readonly::Scalar my $ES   => 'es';
Readonly::Scalar my $ZH   => 'zh';

Readonly::Scalar my $EN_TEXT => 'Hello';
Readonly::Scalar my $FR_TEXT => 'Bonjour';
Readonly::Scalar my $DE_TEXT => 'Hallo';
Readonly::Scalar my $ES_TEXT => 'Hola';

# Text containing HTML special characters -- used for encode() pipeline tests.
Readonly::Scalar my $HTML_RAW     => '<b>bold & bright</b>';
Readonly::Scalar my $HTML_ENCODED => '&lt;b&gt;bold &amp; bright&lt;/b&gt;';

# French text with an accented character stored as a byte string ('e' + 0xC3 0xA9).
# Produced by utf8::encode() so the UTF-8 flag is OFF -- exercises the
# utf8::decode-then-encode path inside encode().
Readonly::Scalar my $FR_ACUTE_RAW     => "\xC3\xA9tude";   # 3 bytes, no UTF-8 flag
Readonly::Scalar my $FR_ACUTE_ENCODED => '&eacute;tude';

# Unique nonsense locales used to force _get_language() cache misses.
# Each uses a different two-letter prefix that never appears in any other subtest.
Readonly::Scalar my $LOCALE_MX => 'mx_MX.UTF-8';    # TXN-4/5/7 encode() pipeline
Readonly::Scalar my $LOCALE_NY => 'ny_NY.UTF-8';    # TXN-14 locale-switch test
Readonly::Scalar my $LOCALE_PQ => 'pq_PQ.UTF-8';    # TXN-16 single-scalar new()

# ===========================================================================
# TXN-1: Build → Populate (set) → Retrieve
#
# Walk an object through three sequential set() calls, one per language, and
# verify that each stored value is exactly what was passed.  No prior state
# should pollute a later step, and no step should erase a prior one.
# ===========================================================================
subtest 'TXN-1: Build → Populate via set() → Retrieve each language' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };

	# Step 1: construct empty object.
	my $t = Lingua::Text->new();
	ok(!defined($t->en()), 'TXN-1 step 1: en absent before any set()');
	ok(!defined($t->fr()), 'TXN-1 step 1: fr absent before any set()');
	ok(!defined($t->de()), 'TXN-1 step 1: de absent before any set()');

	# Step 2: populate English.
	my $r1 = $t->set(text => $EN_TEXT, lang => $EN);
	is(ref($r1), 'Lingua::Text', 'TXN-1 step 2: set() returns $self');
	is($t->en(), $EN_TEXT, 'TXN-1 step 2: en stored correctly');
	ok(!defined($t->fr()), 'TXN-1 step 2: fr still absent after en set');

	# Step 3: populate French.
	$t->set(text => $FR_TEXT, lang => $FR);
	is($t->fr(), $FR_TEXT, 'TXN-1 step 3: fr stored correctly');
	is($t->en(), $EN_TEXT, 'TXN-1 step 3: en preserved after fr set');

	# Step 4: populate German.
	$t->set(text => $DE_TEXT, lang => $DE);
	is($t->de(), $DE_TEXT, 'TXN-1 step 4: de stored correctly');
	is($t->fr(), $FR_TEXT, 'TXN-1 step 4: fr preserved after de set');
	is($t->en(), $EN_TEXT, 'TXN-1 step 4: en preserved after de set');

	restore_all();
};

# ===========================================================================
# TXN-2: Build → Populate via AUTOLOAD setters → Retrieve
#
# Uses the language-accessor shorthand ($t->en('Hello')) instead of set().
# The AUTOLOAD setter installs a real closure on first call; all later calls
# use that closure.  Verify state accumulation is identical to the set() path.
# ===========================================================================
subtest 'TXN-2: Build → Populate via AUTOLOAD setters → Retrieve' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };

	my $t = Lingua::Text->new();

	# Step 1: set English via AUTOLOAD setter.
	my $stored_en = $t->en($EN_TEXT);
	is($stored_en, $EN_TEXT, 'TXN-2 step 1: AUTOLOAD setter returns stored value');

	# Step 2: set French.
	$t->fr($FR_TEXT);
	is($t->fr(), $FR_TEXT, 'TXN-2 step 2: fr retrievable via getter');
	is($t->en(), $EN_TEXT, 'TXN-2 step 2: en preserved after fr set');

	# Step 3: set German.
	$t->de($DE_TEXT);
	is($t->de(), $DE_TEXT, 'TXN-2 step 3: de retrievable via getter');
	is($t->fr(), $FR_TEXT, 'TXN-2 step 3: fr preserved after de set');
	is($t->en(), $EN_TEXT, 'TXN-2 step 3: en preserved after de set');

	restore_all();
};

# ===========================================================================
# TXN-3: Mixed population (set() + AUTOLOAD) → Retrieve: consistent merged state
#
# Interleaves set() and AUTOLOAD-accessor calls.  The module stores all values
# in the same {texts} hash regardless of which API was used.  Verifies the
# two population paths do not interfere.
# ===========================================================================
subtest 'TXN-3: Mixed population (set + AUTOLOAD) → Retrieve' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };

	my $t = Lingua::Text->new();

	# Step 1: set() for English, accessor for French.
	$t->set(text => $EN_TEXT, lang => $EN);
	$t->fr($FR_TEXT);

	# Step 2: accessor for Spanish, set() for German.
	$t->es($ES_TEXT);
	$t->set(text => $DE_TEXT, lang => $DE);

	# Step 3: all four languages retrievable regardless of how they were stored.
	is($t->en(), $EN_TEXT, 'TXN-3: en (set()) retrievable');
	is($t->fr(), $FR_TEXT, 'TXN-3: fr (accessor) retrievable');
	is($t->es(), $ES_TEXT, 'TXN-3: es (accessor) retrievable');
	is($t->de(), $DE_TEXT, 'TXN-3: de (set()) retrievable');

	restore_all();
};

# ===========================================================================
# TXN-4: Build → Populate → encode() → Render (HTML pipeline)
#
# The primary production lifecycle: build an object with raw text that
# contains HTML special characters, entity-encode it, then render it.
# Assert state at each step boundary.
# ===========================================================================
subtest 'TXN-4: Build → Populate → encode() → Render HTML pipeline' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };
	local %ENV;
	$ENV{LANG} = $LOCALE_MX;
	mock 'I18N::LangTags::Detect::detect' => sub { () };

	# Step 1: build with raw HTML content.
	my $t = Lingua::Text->new(en => $HTML_RAW, fr => $FR_TEXT);
	is($t->en(), $HTML_RAW, 'TXN-4 step 1: raw HTML stored');
	is($t->fr(), $FR_TEXT,  'TXN-4 step 1: plain FR text stored');

	# Step 2: encode() returns $self (supports chaining).
	my $ret = $t->encode();
	is(ref($ret), 'Lingua::Text', 'TXN-4 step 2: encode() returns $self');
	# Compare refaddr rather than the objects directly: stringify overload returns
	# undef in a no-locale env, which triggers a Perl "uninitialized value" warning.
	use Scalar::Util 'refaddr';
	is(refaddr($ret), refaddr($t), 'TXN-4 step 2: encode() returns the SAME object (in-place)');

	# Step 3: post-encode state -- HTML special chars converted to entities.
	is($t->en(), $HTML_ENCODED, 'TXN-4 step 3: HTML encoded in-place');
	is($t->fr(), $FR_TEXT,      'TXN-4 step 3: plain ASCII text unchanged');

	# Step 4: as_string() renders the encoded text via locale.
	# LOCALE_MX -> 'mx' -> no 'mx' slot -> undef; use explicit lang instead.
	is($t->as_string($EN), $HTML_ENCODED, 'TXN-4 step 4: as_string() returns encoded text');

	restore_all();
};

# ===========================================================================
# TXN-5: Double-encode pitfall (documented in COMMON PITFALLS)
#
# Calling encode() twice must produce the double-encoded representation
# ('&amp;lt;b&amp;gt;…') documented in the POD.  This test validates the
# documented behaviour so a future change to encode() that accidentally
# makes it idempotent does NOT silently pass.
# ===========================================================================
subtest 'TXN-5: Double-encode produces documented corruption' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };

	# Step 1: single encode() -- expected result.
	my $t1 = Lingua::Text->new(en => $HTML_RAW);
	$t1->encode();
	is($t1->en(), $HTML_ENCODED, 'TXN-5 step 1: first encode() correct');

	# Step 2: second encode() -- entities are re-encoded (ampersand escapes).
	$t1->encode();
	my $double = $t1->en();
	like($double, qr/&amp;lt;/, 'TXN-5 step 2: second encode() re-encodes the ampersands');
	isnt($double, $HTML_ENCODED, 'TXN-5 step 2: double-encoded differs from single-encoded');

	# Demonstrate a two-byte accented char path: byte string.
	my $t2 = Lingua::Text->new(fr => $FR_TEXT);
	$t2->{'texts'}{$FR} = $FR_ACUTE_RAW;    # inject byte string directly
	$t2->encode();
	is($t2->fr(), $FR_ACUTE_ENCODED, 'TXN-5 step 2b: accented byte string encoded');
	$t2->encode();    # second call on already-encoded HTML entity
	like($t2->fr(), qr/&amp;/, 'TXN-5 step 2b: second encode() doubles the ampersand');

	restore_all();
};

# ===========================================================================
# TXN-6: set() mid-sequence partial failure -- prior state preserved
#
# When step N of a set() chain fails (bad language code), only step N is
# rejected.  Steps 1 through N-1 must remain committed in {texts}.
# This verifies there is no implicit rollback of previously stored values.
# ===========================================================================
subtest 'TXN-6: set() mid-sequence failure preserves prior committed state' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };

	my $t = Lingua::Text->new();

	# Step 1: valid set -- must commit.
	$t->set(text => $EN_TEXT, lang => $EN);
	is($t->en(), $EN_TEXT, 'TXN-6 step 1: en committed');

	# Step 2: invalid lang ('eng') -- must fail without corrupting step 1.
	my $result;
	does_carp_that_matches(
		sub { $result = $t->set(text => $DE_TEXT, lang => 'eng') },
		'TXN-6 step 2: invalid lang emits carp',
		qr/usage: set\(text/i,
	);
	ok(!defined($result), 'TXN-6 step 2: invalid set() returns undef');
	is($t->en(), $EN_TEXT, 'TXN-6 step 2: en still present after failed set()');
	ok(!defined($t->de()), 'TXN-6 step 2: de NOT stored (invalid lang rejected)');

	# Step 3: undef text -- must fail without corrupting prior state.
	does_carp_that_matches(
		sub { $result = $t->set(text => undef, lang => $FR) },
		'TXN-6 step 3: undef text emits carp',
		qr/usage: set\(text/i,
	);
	ok(!defined($result), 'TXN-6 step 3: undef-text set() returns undef');
	is($t->en(), $EN_TEXT, 'TXN-6 step 3: en still intact after second failure');
	ok(!defined($t->fr()), 'TXN-6 step 3: fr NOT stored (undef text rejected)');

	# Step 4: valid French -- must commit; English must still be present.
	$t->set(text => $FR_TEXT, lang => $FR);
	is($t->fr(), $FR_TEXT, 'TXN-6 step 4: fr committed after two prior failures');
	is($t->en(), $EN_TEXT, 'TXN-6 step 4: en still intact');

	restore_all();
};

# ===========================================================================
# TXN-7: Method-chaining pipeline: new()->set()->set()->encode()
#
# Tests that the return-value contract (set() returns $self, encode() returns
# $self) works across a full chained expression, and that the final object
# carries the expected encoded state.
# ===========================================================================
subtest 'TXN-7: Chained new→set→set→encode pipeline via return values' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };

	# Build the object entirely via chaining -- each call uses the previous return.
	my $t = Lingua::Text->new()
		->set(text => $HTML_RAW, lang => $EN)
		->set(text => $FR_TEXT,  lang => $FR)
		->set(text => $DE_TEXT,  lang => $DE)
		->encode();

	isa_ok($t, 'Lingua::Text', 'TXN-7: chained expression yields Lingua::Text');
	is($t->en(), $HTML_ENCODED, 'TXN-7: en entity-encoded after full chain');
	is($t->fr(), $FR_TEXT,      'TXN-7: fr (plain ASCII) unchanged by encode()');
	is($t->de(), $DE_TEXT,      'TXN-7: de (plain ASCII) unchanged by encode()');

	restore_all();
};

# ===========================================================================
# TXN-8: Clone isolation -- parent → clone-with-merge → mutate clone
#
# After a merge-clone, the clone has independent {texts} memory.  Mutations
# to the clone (via set() or accessor) must NOT appear in the original.
# The original must be truly frozen from the clone's perspective.
# ===========================================================================
subtest 'TXN-8: Clone merge isolation -- clone mutations do not affect parent' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };

	# Step 1: build parent.
	my $parent = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);

	# Step 2: create a merge-clone (passes params → deep-copies {texts}).
	my $clone = $parent->new(de => $DE_TEXT);
	is($clone->en(), $EN_TEXT, 'TXN-8 step 2: clone inherits en from parent');
	is($clone->fr(), $FR_TEXT, 'TXN-8 step 2: clone inherits fr from parent');
	is($clone->de(), $DE_TEXT, 'TXN-8 step 2: clone has new de entry');

	# Step 3: mutate the clone in three ways.
	$clone->set(text => 'Hi', lang => $EN);        # overwrite inherited en
	$clone->es($ES_TEXT);                           # add new language via accessor
	$clone->encode();                               # in-place encode

	# Step 4: parent must be completely unchanged.
	is($parent->en(), $EN_TEXT, 'TXN-8 step 4: parent en unaffected by clone overwrite');
	is($parent->fr(), $FR_TEXT, 'TXN-8 step 4: parent fr unaffected by clone encode');
	ok(!defined($parent->de()), 'TXN-8 step 4: parent de unaffected -- not present in parent');
	ok(!defined($parent->es()), 'TXN-8 step 4: parent es unaffected by clone addition');

	restore_all();
};

# ===========================================================================
# TXN-9: Shallow clone via bare new() -- {texts} ref shared
#
# When new() is called on an object with NO arguments, the clone path does
# `bless { %{$class} }`, which copies the top-level hash slots but keeps the
# same {texts} hashref.  This is documented behaviour; the test confirms it.
# A post-clone mutation of the SHARED {texts} DOES affect both objects --
# callers who need isolation must pass arguments to trigger the merge path.
# ===========================================================================
subtest 'TXN-9: Bare clone shares {texts} ref (documented shallow-copy behaviour)' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };

	my $orig  = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);
	my $clone = $orig->new();    # no args: shallow bless { %$class }

	# Verify both objects see the same texts initially.
	is($clone->en(), $EN_TEXT, 'TXN-9: clone inherits en from shallow copy');
	is($clone->fr(), $FR_TEXT, 'TXN-9: clone inherits fr from shallow copy');

	# Both {texts} slots must be the same scalar reference.
	is($orig->{'texts'}, $clone->{'texts'}, 'TXN-9: {texts} ref is identical (shared)');

	# A direct write to the shared hash propagates to both objects (documented).
	$clone->{'texts'}{$DE} = $DE_TEXT;
	is($orig->de(), $DE_TEXT,
		'TXN-9: mutation via shared ref visible on original (expected shallow-copy risk)');

	restore_all();    # CRITICAL: must restore before TXN-10 or the leaked mock
	                  # stacks under subsequent mocks and corrupts TXN-12's params.
};

# ===========================================================================
# TXN-10: encode() before cloning -- clone inherits encoded text
#
# When encode() is called on the parent and then a merge-clone is created,
# the clone receives the already-encoded values (because the merge copies
# the current {texts} state).  Calling encode() again on the clone would
# double-encode; this test asserts the clone starts in the encoded state.
# ===========================================================================
subtest 'TXN-10: encode() before merge-clone -- clone inherits encoded state' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };

	# Step 1: build and encode the parent.
	my $parent = Lingua::Text->new(en => $HTML_RAW, fr => $FR_TEXT);
	$parent->encode();
	is($parent->en(), $HTML_ENCODED, 'TXN-10 step 1: parent en is encoded');

	# Step 2: merge-clone the encoded parent (add DE).
	my $clone = $parent->new(de => $DE_TEXT);
	is($clone->en(), $HTML_ENCODED, 'TXN-10 step 2: clone inherits encoded en');
	is($clone->fr(), $FR_TEXT,      'TXN-10 step 2: clone inherits encoded fr (plain)');
	is($clone->de(), $DE_TEXT,      'TXN-10 step 2: clone has new raw de entry');

	# Step 3: calling encode() AGAIN on the clone would double-encode 'en'.
	# (The de slot starts raw and gets encoded; the en slot gets double-encoded.)
	$clone->encode();
	like($clone->en(), qr/&amp;lt;/, 'TXN-10 step 3: double-encode visible on clone en');
	isnt($clone->en(), $HTML_ENCODED, 'TXN-10 step 3: clone en differs from singly-encoded');

	# Step 4: parent is not affected by the clone's second encode().
	is($parent->en(), $HTML_ENCODED, 'TXN-10 step 4: parent en unchanged (clone has own {texts})');

	restore_all();
};

# ===========================================================================
# TXN-11: Idempotency of set() -- same key stored twice with same value
#
# Running the same set() call twice must produce the identical final state
# with no errors and no side effects (no duplicate-key errors, no carp).
# ===========================================================================
subtest 'TXN-11: set() idempotency -- same lang+text twice yields same state' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };

	my $t = Lingua::Text->new();

	# First set: commit.
	$t->set(text => $EN_TEXT, lang => $EN);
	is($t->en(), $EN_TEXT, 'TXN-11: first set() stored correctly');

	# Second set: identical args -- must succeed silently.
	my $result;
	lives_ok(
		sub { $result = $t->set(text => $EN_TEXT, lang => $EN) },
		'TXN-11: second identical set() does not throw',
	);
	is(ref($result), 'Lingua::Text', 'TXN-11: second set() still returns $self');
	is($t->en(), $EN_TEXT, 'TXN-11: state unchanged after second set()');

	# Third set: overwrite with a different value.
	$t->set(text => 'Goodbye', lang => $EN);
	is($t->en(), 'Goodbye', 'TXN-11: overwrite with new value works correctly');

	restore_all();
};

# ===========================================================================
# TXN-12: Idempotency of new() with identical flat-pair args -- two independent objects
#
# Constructing two objects from identical flat key/value pairs must yield
# independent objects.  Params::Get::get_params() builds a fresh hash for flat
# pairs (unlike a hashref, which is returned as-is), so both objects get their
# own {texts} hash even though the source content is identical.
#
# NOTE on hashref sharing: passing the SAME hashref twice (new(\%h); new(\%h))
# causes both objects to share the ref because get_params() returns the input
# hashref unchanged and the mocked configure() passes it through.  That is
# covered (as the documented shallow-copy risk) by TXN-9.  Here we use flat
# pairs to prove object independence when the source content is the same.
# ===========================================================================
subtest 'TXN-12: new() idempotency -- two objects from identical flat pairs are independent' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };

	# Build t1 and t2 with identical flat pairs (not the same hashref).
	my $t1 = Lingua::Text->new($EN => $EN_TEXT, $FR => $FR_TEXT);
	is($t1->en(), $EN_TEXT, 'TXN-12: t1 en correct');
	is($t1->fr(), $FR_TEXT, 'TXN-12: t1 fr correct');

	my $t2 = Lingua::Text->new($EN => $EN_TEXT, $FR => $FR_TEXT);
	is($t2->en(), $EN_TEXT, 'TXN-12: t2 en correct');
	is($t2->fr(), $FR_TEXT, 'TXN-12: t2 fr correct');

	# Verify objects have independent {texts} hashrefs.
	use Scalar::Util 'refaddr';
	isnt(refaddr($t1->{'texts'}), refaddr($t2->{'texts'}),
		'TXN-12: t1 and t2 have independent {texts} hashrefs');

	# Mutate t1 -- t2 must not change.
	$t1->set(text => $DE_TEXT, lang => $DE);
	$t1->set(text => 'Hi',     lang => $EN);

	ok(!defined($t2->de()), 'TXN-12: t2 de absent after t1 mutation');
	is($t2->en(), $EN_TEXT,  'TXN-12: t2 en unchanged after t1 mutation');

	# Mutate t2 -- t1 must not change.
	$t2->set(text => $ES_TEXT, lang => $ES);
	ok(!defined($t1->es()), 'TXN-12: t1 es absent after t2 mutation');

	restore_all();
};

# ===========================================================================
# TXN-13: Concurrent objects do not interfere
#
# Two distinct objects populated with different content must maintain
# independent state throughout their lifecycles, even when the same
# language codes are used.
# ===========================================================================
subtest 'TXN-13: Concurrent objects maintain independent state' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };

	my $greeting = Lingua::Text->new(en => 'Hello', fr => 'Bonjour');
	my $farewell = Lingua::Text->new(en => 'Goodbye', fr => 'Au revoir');

	# Step 1: each object has its own content.
	is($greeting->en(), 'Hello',     'TXN-13 step 1: greeting en correct');
	is($farewell->en(), 'Goodbye',   'TXN-13 step 1: farewell en correct');

	# Step 2: mutate farewell -- greeting must be unaffected.
	$farewell->set(text => 'Tschuss', lang => $DE);
	ok(!defined($greeting->de()), 'TXN-13 step 2: greeting has no de after farewell mutation');

	# Step 3: encode farewell -- greeting still holds raw text.
	$greeting->set(text => $HTML_RAW, lang => $EN);
	$farewell->encode();
	is($greeting->en(), $HTML_RAW, 'TXN-13 step 3: greeting en still raw after farewell encode');

	# Step 4: encode greeting -- farewell already encoded; no interference.
	$greeting->encode();
	is($greeting->en(), $HTML_ENCODED, 'TXN-13 step 4: greeting en now encoded');
	is($farewell->en(), 'Goodbye',     'TXN-13 step 4: farewell en unchanged by greeting encode');

	restore_all();
};

# ===========================================================================
# TXN-14: Locale switch mid-pipeline
#
# An object built while one locale is active can still be queried for a
# specific language explicitly regardless of a subsequent locale change.
# However, as_string() with no argument always reads the CURRENT locale.
# ===========================================================================
subtest 'TXN-14: Locale switch between build and retrieve' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };

	# Step 1: set locale to 'ny', build an object with ny+fr text.
	local %ENV;
	$ENV{LANG} = $LOCALE_NY;
	mock 'I18N::LangTags::Detect::detect' => sub { () };

	my $t = Lingua::Text->new(ny => 'Moni', fr => $FR_TEXT, en => $EN_TEXT);
	is($t->ny(), 'Moni', 'TXN-14 step 1: ny text stored under ny locale');

	# Step 2: switch locale to French mid-pipeline.
	$ENV{LANG} = $LOCALE_NY;    # must change the cached value
	$ENV{LANG} = 'fr_FR.UTF-8'; # now point at French

	# as_string() uses the CURRENT locale; the object has fr text.
	is($t->as_string(), $FR_TEXT, 'TXN-14 step 2: as_string() reflects new locale (fr)');

	# Step 3: explicit lang is always locale-independent.
	is($t->as_string($EN), $EN_TEXT, 'TXN-14 step 3: explicit lang unaffected by locale change');
	is($t->as_string('ny'), 'Moni',  'TXN-14 step 3: ny text still retrievable explicitly');

	# Step 4: switch to a locale with no stored text -> undef (no carp).
	$ENV{LANG} = 'de_DE.UTF-8';
	my $missing;
	lives_ok(
		sub { $missing = $t->as_string() },
		'TXN-14 step 4: no exception when locale has no stored text',
	);
	ok(!defined($missing), 'TXN-14 step 4: undef returned for locale with no stored text');

	restore_all();
};

# ===========================================================================
# TXN-15: Object::Configure key injection → encode() skips injected keys
#
# Object::Configure may inject non-language keys (e.g. 'logger', 'config_path')
# into the params hash that becomes {texts}.  The encode() guard must skip
# these so that blessed-reference values are not corrupted by utf8::decode().
# ===========================================================================
subtest 'TXN-15: Object::Configure injection → encode() skips injected keys' => sub {
	# Simulate Object::Configure injecting a logger reference alongside lang keys.
	my $fake_logger = bless { level => 'info' }, 'FakeLogger';
	mock 'Object::Configure::configure' => sub {
		my $params = $_[1] // {};
		$params->{'logger'} = $fake_logger;
		return $params;
	};

	# Step 1: construct object; configure() injects 'logger' into {texts}.
	my $t = Lingua::Text->new(en => $HTML_RAW, fr => $FR_TEXT);
	is(ref($t->{'texts'}{'logger'}), 'FakeLogger',
		'TXN-15 step 1: logger ref present in {texts} after configure()');

	# Step 2: encode() -- must process en and fr, but skip 'logger'.
	lives_ok(sub { $t->encode() }, 'TXN-15 step 2: encode() does not throw on injected ref');
	is($t->en(), $HTML_ENCODED, 'TXN-15 step 2: en entity-encoded');
	is($t->fr(), $FR_TEXT,      'TXN-15 step 2: fr plain text unchanged');
	is(ref($t->{'texts'}{'logger'}), 'FakeLogger',
		'TXN-15 step 2: logger ref preserved (not corrupted by encode)');

	# Step 3: verify the injected key was not string-corrupted.
	is($fake_logger->{'level'}, 'info',
		'TXN-15 step 3: logger object internal state intact after encode()');

	restore_all();
};

# ===========================================================================
# TXN-16: Single-scalar new() under locale → locale removed → object still serves
#
# When new('text') is used while a locale is active, the text is filed under
# that locale's language.  If the locale is subsequently removed, the stored
# text remains accessible by explicit language lookup, even though no-arg
# as_string() can no longer determine which language to use.
# ===========================================================================
subtest 'TXN-16: Single-scalar new() under locale; locale removed; object still serves' => sub {
	mock 'Object::Configure::configure' => sub { $_[1] };

	# Step 1: set a unique locale and call new('text').
	local %ENV;
	$ENV{LANG} = $LOCALE_PQ;    # -> lang 'pq'
	mock 'I18N::LangTags::Detect::detect' => sub { () };

	my $t = Lingua::Text->new('pq-text');
	is($t->pq(), 'pq-text', 'TXN-16 step 1: text stored under locale lang "pq"');

	# Step 2: remove the locale variable (simulate locale-less environment).
	delete $ENV{LANG};

	# Step 3: no-arg as_string() now cannot resolve the language -> carp.
	my $result;
	does_carp_that_matches(
		sub { $result = $t->as_string() },
		'TXN-16 step 3: no-locale as_string() carps',
		qr/usage: as_string/i,
	);
	ok(!defined($result), 'TXN-16 step 3: undef returned when no locale');

	# Step 4: explicit as_string('pq') still works -- text was not lost.
	is($t->as_string('pq'), 'pq-text',
		'TXN-16 step 4: explicit lang still serves text despite missing locale');

	restore_all();
};

done_testing();

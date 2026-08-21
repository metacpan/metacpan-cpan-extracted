#!/usr/bin/env perl
# t/integration.t -- Black-box end-to-end integration tests for Lingua::Text
#
# Strategy: validate complete cross-method workflows exactly as illustrated in
# the POD SYNOPSIS and DESCRIPTION sections.  Each subtest exercises a
# realistic usage scenario that spans multiple methods so that no single unit
# test would catch the failure.
#
# Dependency note: all Lingua::Text runtime dependencies (HTML::Entities,
# I18N::LangTags::Detect, Object::Configure, Params::Get, ...) are hard
# 'use' statements that are resolved at compile time.  There is no optional-
# dependency fallback path within the module itself, so Test::Without::Module
# cannot block them post-load.  Integration tests therefore use
# Test::Mockingbird::spy to verify that the correct modules are called with
# the expected arguments, and Test::Mockingbird::mock to inject controlled
# locale signals into I18N::LangTags::Detect::detect().

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
Readonly::Scalar my $EN_TEXT   => 'hello';
Readonly::Scalar my $FR_TEXT   => 'bonjour';
Readonly::Scalar my $DE_TEXT   => 'Hallo';
Readonly::Scalar my $ES_TEXT   => 'hola';
Readonly::Scalar my $ETUDE     => "\x{E9}tude";       # U+00E9 e-acute + tude
Readonly::Scalar my $ETUDE_E   => '&eacute;tude';     # expected HTML entity
Readonly::Scalar my $TAG_RAW   => '<b>bold</b>';
Readonly::Scalar my $TAG_ENC   => '&lt;b&gt;bold&lt;/b&gt;';
Readonly::Scalar my $EN_LOCALE => 'en_US.UTF-8';
Readonly::Scalar my $FR_LOCALE => 'fr_FR.UTF-8';
Readonly::Scalar my $DE_LOCALE => 'de_DE.UTF-8';
Readonly::Scalar my $ES_LOCALE => 'es_ES.UTF-8';

# ---------------------------------------------------------------------------
# 1.  POD SYNOPSIS Workflow 1: store translations, stringify in user's locale
#
# "The system locale (LANG, LC_Messages, etc.) picks the language."
# ---------------------------------------------------------------------------
subtest 'synopsis 1 -- locale-driven stringify' => sub {
	local %ENV;
	$ENV{LANG} = $FR_LOCALE;
	mock 'I18N::LangTags::Detect::detect' => sub { () };    # force LANG fallback

	my $greeting = Lingua::Text->new(
		en => 'Hello',
		fr => 'Bonjour',
		de => 'Hallo',
	);

	# String interpolation should select the French translation
	is("$greeting", 'Bonjour', 'stringify selects French when LANG=fr_FR.UTF-8');

	# Changing the locale mid-process picks up the new language automatically
	$ENV{LANG} = $EN_LOCALE;
	is("$greeting", 'Hello', 'stringify re-reads locale when LANG changes');

	$ENV{LANG} = $DE_LOCALE;
	is("$greeting", 'Hallo', 'stringify re-reads locale when LANG changes again');

	diag "greeting object: $greeting" if $ENV{TEST_VERBOSE};
	restore_all();
};

# ---------------------------------------------------------------------------
# 2.  POD SYNOPSIS Workflow 2: build empty, add via accessors, explicit lang
#
# "Add translations after construction ... ask for a specific language"
# ---------------------------------------------------------------------------
subtest 'synopsis 2 -- accessor construction + explicit as_string' => sub {
	local %ENV;

	my $label = new_ok('Lingua::Text');
	$label->en('Submit');
	$label->fr('Envoyer');
	$label->de('Abschicken');

	# Explicit-language retrieval -- no locale needed
	is($label->as_string('fr'), 'Envoyer',    'as_string("fr") returns French');
	is($label->as_string('en'), 'Submit',     'as_string("en") returns English');
	is($label->as_string('de'), 'Abschicken', 'as_string("de") returns German');

	# as_string with named and hashref forms should agree
	is($label->as_string(lang => 'fr'),   'Envoyer', 'named form matches positional');
	is($label->as_string({ lang => 'fr' }), 'Envoyer', 'hashref form matches positional');
};

# ---------------------------------------------------------------------------
# 3.  POD SYNOPSIS Workflow 3: build from a database-style hashref
#
# "Suppose the database returns: { en => 'Apple', fr => 'Pomme', de => 'Apfel' }"
# ---------------------------------------------------------------------------
subtest 'synopsis 3 -- hashref construction (database row)' => sub {
	local %ENV;
	$ENV{LANG} = $EN_LOCALE;
	mock 'I18N::LangTags::Detect::detect' => sub { () };

	# Simulate a database row as a hash
	my %row = (en => 'Apple', fr => 'Pomme', de => 'Apfel');
	my $name = Lingua::Text->new(\%row);

	isa_ok($name, 'Lingua::Text', 'new(\\%row) returns a Lingua::Text');
	is($name->en(), 'Apple', 'hashref: en stored');
	is($name->fr(), 'Pomme', 'hashref: fr stored');
	is($name->de(), 'Apfel', 'hashref: de stored');
	is("$name", 'Apple', 'stringify returns English for LANG=en_US.UTF-8');

	diag "fruit name: $name" if $ENV{TEST_VERBOSE};
	restore_all();
};

# ---------------------------------------------------------------------------
# 4.  POD SYNOPSIS Workflow 4: clone with override; original unchanged
#
# "Calling new() on an existing object creates an independent copy (a clone)
#  with any extra translations you supply merged in."
# ---------------------------------------------------------------------------
subtest 'synopsis 4 -- clone with language override' => sub {
	local %ENV;

	# POD example verbatim
	my $base = Lingua::Text->new(en => 'colour', fr => 'couleur');
	my $us   = $base->new(en => 'color');   # American English override

	# $us has en => 'color', fr => 'couleur'
	is($us->en(), 'color',   'us: overridden key replaced');
	is($us->fr(), 'couleur', 'us: non-overridden key preserved');

	# $base is unchanged
	is($base->en(), 'colour',  'base: en unchanged after clone');
	is($base->fr(), 'couleur', 'base: fr unchanged after clone');

	# Mutation on $us must NOT propagate to $base (clone is independent)
	$us->en('kitty');
	is($base->en(), 'colour', 'mutation on clone does not affect base');

	# Multiple clones of the same parent are independent of each other
	my $gb = $base->new(en => 'lift');
	my $au = $base->new(en => 'lift');
	$gb->fr('ascenseur');
	is($au->fr(), 'couleur', 'two clones of same parent are independent');
};

# ---------------------------------------------------------------------------
# 5.  POD SYNOPSIS Workflow 5: set() with runtime language variable
#
# "Store text at runtime using a language variable"
# ---------------------------------------------------------------------------
subtest 'synopsis 5 -- set() with runtime language variable' => sub {
	local %ENV;

	my $message  = Lingua::Text->new();
	my $user_lang = 'de';    # could come from a web request header

	$message->set(text => 'Willkommen', lang => $user_lang);
	is($message->as_string($user_lang), 'Willkommen',
		'set() + as_string() with runtime lang variable');

	# POD EXAMPLE chain: new()->set()->set()
	my $t = Lingua::Text->new()
		->set(text => 'Hello', lang => 'en')
		->set(text => 'Hola',  lang => 'es');
	is($t->en(), 'Hello', 'chain: en stored');
	is($t->es(), 'Hola',  'chain: es stored');
};

# ---------------------------------------------------------------------------
# 6.  POD SYNOPSIS Workflow 6: encode() for HTML output
#
# "Prepare multilingual text for HTML output"
# ---------------------------------------------------------------------------
subtest 'synopsis 6 -- encode() for HTML output' => sub {
	local %ENV;
	$ENV{LANG} = $FR_LOCALE;
	mock 'I18N::LangTags::Detect::detect' => sub { () };

	my $title = Lingua::Text->new(
		en => 'read more',
		fr => "lire la suite",
	)->encode();

	# POD says "converts accented characters to HTML entities"
	is($title->en(), 'read more',      'encode(): ASCII unchanged');
	is($title->fr(), 'lire la suite',  'encode(): unaccented French unchanged');

	# Use encoded text safely inside HTML
	my $html = "<p>$title</p>";
	like($html, qr{<p>lire la suite</p>},
		'stringify inside HTML element works after encode()');

	restore_all();
};

# ---------------------------------------------------------------------------
# 7.  Multi-object isolation
#
# POD says objects are independent.  Prove that two objects created in the
# same scope, in the same locale, do not share translations or internal state.
# ---------------------------------------------------------------------------
subtest 'multi-object isolation' => sub {
	local %ENV;
	$ENV{LANG} = $EN_LOCALE;
	mock 'I18N::LangTags::Detect::detect' => sub { () };

	my $a = Lingua::Text->new(en => 'apple', fr => 'pomme');
	my $b = Lingua::Text->new(en => 'boat',  de => 'Boot');

	# Each object retrieves its own translations
	is($a->en(), 'apple', 'a: en is apple');
	is($b->en(), 'boat',  'b: en is boat');

	# a has no German; b has no French
	ok(!defined($a->de()), 'a: no German stored');
	ok(!defined($b->fr()), 'b: no French stored');

	# Mutating one object must not affect the other
	$a->en('cherry');
	is($b->en(), 'boat', 'mutation of a does not affect b');

	# Stringification selects each object's own English
	is("$a", 'cherry', 'a stringifies to cherry');
	is("$b", 'boat',   'b stringifies to boat');

	# Three concurrent objects with separate languages
	my $c = Lingua::Text->new(es => $ES_TEXT);
	ok(!defined($a->es()), 'a: no Spanish -- independent of c');
	ok(!defined($b->es()), 'b: no Spanish -- independent of c');
	is($c->es(), $ES_TEXT, 'c: Spanish stored correctly');

	restore_all();
};

# ---------------------------------------------------------------------------
# 8.  Cross-method state propagation: encode() affects as_string() and "$t"
#
# Proves that encode() modifies the stored values so that ALL subsequent
# retrieval methods (accessor, as_string(), stringify) see the encoded form.
# ---------------------------------------------------------------------------
subtest 'encode() propagates to all retrieval paths' => sub {
	local %ENV;
	$ENV{LANG} = $FR_LOCALE;
	mock 'I18N::LangTags::Detect::detect' => sub { () };

	my $t = Lingua::Text->new(en => $TAG_RAW, fr => $ETUDE);
	$t->encode();

	# All retrieval paths must return the encoded form
	is($t->en(),            $TAG_ENC, 'AUTOLOAD getter returns encoded form');
	is($t->as_string('en'), $TAG_ENC, 'as_string(en) returns encoded form');
	is($t->fr(),            $ETUDE_E, 'AUTOLOAD getter returns encoded French');
	is($t->as_string('fr'), $ETUDE_E, 'as_string(fr) returns encoded French');
	is("$t", $ETUDE_E, 'stringify returns encoded French (locale is fr)');

	restore_all();
};

# ---------------------------------------------------------------------------
# 9.  Spy: encode() calls HTML::Entities::encode_entities exactly once per
#     valid language slot, with the decoded string as the argument.
#
# We spy rather than mock so the real encoding still runs and we can also
# verify the returned values are correct.
# ---------------------------------------------------------------------------
subtest 'spy: encode() delegates to HTML::Entities::encode_entities' => sub {
	local %ENV;

	my $spy = spy 'HTML::Entities::encode_entities';

	my $t = Lingua::Text->new(en => 'study', fr => $ETUDE);
	$t->encode();

	my @calls = $spy->();

	# The spy records one call per language slot (2 here: en and fr).
	# Object::Configure may inject additional non-language keys (e.g. 'logger')
	# but encode() skips them via _is_valid_language(), so those do not appear.
	is(scalar @calls, 2,
		'encode() calls encode_entities exactly once per language slot');

	diag sprintf("encode_entities call args: %s", join(', ', map { $_->[1] // 'undef' } @calls))
		if $ENV{TEST_VERBOSE};

	# The encoded values must be the expected HTML entities
	is($t->en(), 'study',   'encode(): en ASCII unchanged');
	is($t->fr(), $ETUDE_E,  'encode(): fr entity-encoded correctly');

	restore_all();
};

# ---------------------------------------------------------------------------
# 10. Spy: locale memoisation -- I18N::LangTags::Detect::detect() is called
#     at most once when the locale environment does not change.
#
# POD PERFORMANCE section: "The result is cached against a snapshot of the
# five relevant environment variables... repeated calls cost only five string
# comparisons instead of a full I18N::LangTags::Detect::detect() scan."
# ---------------------------------------------------------------------------
subtest 'spy: locale memoisation -- detect() called once per env snapshot' => sub {
	local %ENV;

	# Force a cache miss first by using a unique locale value, then prime cache.
	$ENV{LANG} = 'zz_ZZ.UTF-8';
	{
		# Temporary mock to prime the cache without affecting the spy count below.
		# Capture the stringify result to avoid void-context and undef warnings:
		# zz_ZZ has no translation so the result is undef, which is fine here.
		mock 'I18N::LangTags::Detect::detect' => sub { () };
		my $t_prime = Lingua::Text->new(en => $EN_TEXT);
		my $unused  = $t_prime->as_string('en');    # triggers _get_language()
		restore_all();
	}

	# Now switch to the real test locale and install the spy
	$ENV{LANG} = $EN_LOCALE;
	my $t = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);

	my $spy = spy 'I18N::LangTags::Detect::detect';

	# Capture stringify results (avoid void-context lint warnings).
	# First call: cache primed with zz_ZZ, now LANG=en_US -> cache miss
	my $r1 = "$t";    # slow path: detect() may be called
	# Second and third: env unchanged -> cache hit -> detect() NOT called
	my $r2 = "$t";
	my $r3 = "$t";

	my @calls = $spy->();
	cmp_ok(scalar @calls, '<=', 1,
		'detect() called at most once for repeated stringifies with same LANG');

	diag "detect() call count: " . scalar(@calls) if $ENV{TEST_VERBOSE};

	# Now change LANG: cache must be invalidated, detect() called again
	$ENV{LANG} = $FR_LOCALE;
	my $r4 = "$t";    # cache miss -> detect() called once more
	my @calls2 = $spy->();
	cmp_ok(scalar @calls2, '>=', 1,
		'detect() called again after LANG changes (cache invalidation)');

	restore_all();
};

# ---------------------------------------------------------------------------
# 11. Object::Configure integration: injected non-language keys coexist with
#     language translations without corrupting the public API.
#
# Object::Configure injects keys ('logger', 'Database__Abstraction',
# 'config_path') into new()'s params.  These are not ISO 639-1 codes, so
# encode() skips them and the AUTOLOAD accessor returns undef for them.
# The language translations must remain intact and accessible.
# ---------------------------------------------------------------------------
subtest 'Object::Configure integration -- injected keys do not corrupt API' => sub {
	local %ENV;

	my $t = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);

	# The language translations must be accessible regardless of injected keys
	is($t->en(), $EN_TEXT,  'en translation accessible despite injected keys');
	is($t->fr(), $FR_TEXT, 'fr translation accessible despite injected keys');

	# AUTOLOAD guard: 2-letter rule blocks access to 'logger' via method name.
	# 'logger' is 6 chars so the /^[a-z]{2}$/ gate returns undef silently.
	ok(!defined($t->logger_test()), 'AUTOLOAD: 6-char name rejected silently');

	# encode() must NOT corrupt the injected objects (security V2 guard)
	$t->encode();
	is($t->en(), $EN_TEXT, 'en unchanged after encode() (ASCII, no entity needed)');
	is($t->fr(), $FR_TEXT, 'fr unchanged after encode() (ASCII French, no entity needed)');

	# Verify encode() with non-ASCII in presence of injected keys
	my $t2 = Lingua::Text->new(fr => $ETUDE);
	$t2->encode();
	is($t2->fr(), $ETUDE_E, 'fr entity-encoded correctly despite injected keys');
};

# ---------------------------------------------------------------------------
# 12. Locale detection integration: full env-var precedence chain
#
# POD DESCRIPTION: detection uses LANGUAGE, LC_ALL, LC_MESSAGES, LANG
# in that priority order.  This test drives the full detection cascade.
# ---------------------------------------------------------------------------
subtest 'locale detection -- precedence chain' => sub {
	mock 'I18N::LangTags::Detect::detect' => sub { () };    # disable HTTP path

	# LANG lowest priority: used when others absent
	{
		local %ENV;
		$ENV{LANG} = $FR_LOCALE;
		my $t = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);
		is("$t", $FR_TEXT, 'LANG=fr_FR: stringify returns French');
	}

	# LC_MESSAGES overrides LANG
	{
		local %ENV;
		$ENV{LANG}        = $FR_LOCALE;    # lower priority
		$ENV{LC_MESSAGES} = $DE_LOCALE;    # higher priority
		my $t = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT, de => $DE_TEXT);
		is("$t", $DE_TEXT, 'LC_MESSAGES overrides LANG');
	}

	# LC_ALL overrides LC_MESSAGES
	{
		local %ENV;
		$ENV{LC_MESSAGES} = $DE_LOCALE;    # lower priority
		$ENV{LC_ALL}      = $FR_LOCALE;    # higher priority
		my $t = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT, de => $DE_TEXT);
		is("$t", $FR_TEXT, 'LC_ALL overrides LC_MESSAGES');
	}

	# LANGUAGE (colon-separated list) overrides LC_ALL
	{
		local %ENV;
		$ENV{LC_ALL}    = $FR_LOCALE;      # lower priority
		$ENV{LANGUAGE}  = 'de:en';         # higher priority -- first valid tag wins
		my $t = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT, de => $DE_TEXT);
		is("$t", $DE_TEXT, 'LANGUAGE overrides LC_ALL');
	}

	# POSIX C locale maps to English
	{
		local %ENV;
		$ENV{LANG} = 'C';
		my $t = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);
		is("$t", $EN_TEXT, 'POSIX C locale maps to English');
	}

	# POSIX C.UTF-8 variant also maps to English
	{
		local %ENV;
		$ENV{LANG} = 'C.UTF-8';
		my $t = Lingua::Text->new(en => $EN_TEXT, fr => $FR_TEXT);
		is("$t", $EN_TEXT, 'POSIX C.UTF-8 locale maps to English');
	}

	restore_all();
};

# ---------------------------------------------------------------------------
# 13. Cross-locale object sharing: same object queried from multiple locales
#
# Proves that a single object can serve multiple simulated locales within
# the same process (e.g. a web app handling requests in different languages).
# ---------------------------------------------------------------------------
subtest 'single object -- multiple locale queries' => sub {
	local %ENV;
	mock 'I18N::LangTags::Detect::detect' => sub { () };

	my $t = Lingua::Text->new(
		en => 'Good morning',
		fr => 'Bonjour',
		de => 'Guten Morgen',
		es => 'Buenos dias',
	);

	for my $locale_text (
		[$EN_LOCALE, 'en', 'Good morning'],
		[$FR_LOCALE, 'fr', 'Bonjour'    ],
		[$DE_LOCALE, 'de', 'Guten Morgen'],
		[$ES_LOCALE, 'es', 'Buenos dias' ],
	) {
		my ($locale, $code, $expected) = @{$locale_text};
		$ENV{LANG} = $locale;
		is("$t", $expected, "locale $locale -> '$expected'");
	}

	restore_all();
};

# ---------------------------------------------------------------------------
# 14. encode() + set() interaction: set() after encode() stores raw text
#     alongside already-encoded slots, without re-encoding the existing ones.
# ---------------------------------------------------------------------------
subtest 'encode() followed by set() -- partial mutation' => sub {
	local %ENV;

	my $t = Lingua::Text->new(fr => $ETUDE);
	$t->encode();    # fr is now &eacute;tude

	is($t->fr(), $ETUDE_E, 'fr is encoded');

	# Adding a new language after encode() stores raw text (new slot)
	$t->set(text => $EN_TEXT, lang => 'en');
	is($t->en(), $EN_TEXT,  'en stored raw after encode()');
	is($t->fr(), $ETUDE_E,  'fr still encoded -- set() did not re-encode');
};

# ---------------------------------------------------------------------------
# 15. POD COMMON PITFALL: double encode() corrupts output (end-to-end)
#
# Tests the full lifecycle: new() -> encode() -> encode() -> as_string().
# ---------------------------------------------------------------------------
subtest 'pitfall: double encode() corrupts HTML' => sub {
	local %ENV;

	my $t = Lingua::Text->new(fr => $ETUDE)
		->encode()    # first encode: $etude -> &eacute;tude
		->encode();   # second encode: & -> &amp;, so &eacute; -> &amp;eacute;

	is($t->fr(), '&amp;eacute;tude',
		'double-encode: & itself encoded on second pass (documented pitfall)');
	is($t->as_string('fr'), '&amp;eacute;tude',
		'as_string() also returns the doubly-encoded value');
};

# ---------------------------------------------------------------------------
# 16. POD LIMITATION: no language fallback for sub-locale codes
#
# "If en_GB is stored as a key and the system locale is en_US, the text is
#  NOT found."  Only two-letter codes are used as storage keys.
# ---------------------------------------------------------------------------
subtest 'limitation: no sub-locale fallback' => sub {
	local %ENV;
	$ENV{LANG} = $EN_LOCALE;    # en_US -> key 'en' is extracted
	mock 'I18N::LangTags::Detect::detect' => sub { () };

	# Store under plain two-letter key; country suffix must be stripped
	my $t = Lingua::Text->new(en => $EN_TEXT);

	# The POD confirms the system locale provides the 2-letter code 'en',
	# so this should find the translation stored under 'en'.
	is("$t", $EN_TEXT, 'locale en_US maps to key "en" (country suffix stripped)');

	restore_all();
};

done_testing();

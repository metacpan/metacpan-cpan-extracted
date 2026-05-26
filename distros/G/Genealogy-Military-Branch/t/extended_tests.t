#!/usr/bin/env perl

# extended_tests.t - targeted coverage tests for Genealogy::Military::Branch.
#
# Each subtest is chosen to exercise a specific branch, linear code
# sequence, or decision point not reached by unit.t, integration.t, or
# edge_cases.t.  Together they aim for >=95% statement coverage and
# maximum LCSAJ/TER3 scores by exercising every reachable path through
# _get_language, _translate, new(), and detect().
#
# External dependencies are mocked where needed to isolate code paths;
# env vars are localised to prevent host-locale interference.

use strict;
use warnings;
use 5.014;

use Test::Most;
use Test::Mockingbird 0.09 qw(mock_scoped);

use_ok('Genealogy::Military::Branch') or BAIL_OUT('Cannot load Genealogy::Military::Branch');

# -----------------------------------------------------------------------
# _get_language - environment variable cascade (all fallback paths)
# Each subtest exercises a distinct branch in the cascade:
#   detect() → LANGUAGE → LC_ALL → LC_MESSAGES → LANG → C-locale → undef
# -----------------------------------------------------------------------

subtest '_get_language - LANGUAGE env var used when detect() returns nothing' => sub {
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	delete local $ENV{LANG};
	local $ENV{LANGUAGE} = 'de_DE.UTF-8';

	# detect() returns nothing so the I18N::LangTags path is skipped;
	# _get_language must fall through to the LANGUAGE env var
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'He served in the Navy'),
		'Marine', 'LANGUAGE env var drives German language detection');
};

subtest '_get_language - LC_ALL used when LANGUAGE and detect() both absent' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_MESSAGES};
	delete local $ENV{LANG};
	local $ENV{LC_ALL} = 'fr_FR.UTF-8';

	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# LC_ALL is the first entry in the foreach fallback list
	is($obj->detect(text => 'He served in the Navy'),
		'marine', 'LC_ALL env var drives French language detection');
};

subtest '_get_language - LC_MESSAGES used when higher-priority vars absent' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LANG};
	local $ENV{LC_MESSAGES} = 'de_DE.UTF-8';

	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# LC_MESSAGES is the second entry in the foreach fallback list
	is($obj->detect(text => 'He served in the Navy'),
		'Marine', 'LC_MESSAGES env var drives German language detection');
};

subtest '_get_language - C.UTF-8 locale treated as English' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'C.UTF-8';

	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });

	# 'C.UTF-8' does not start with two letters so the foreach loop skips it;
	# the explicit /^C(\.|$)/ guard then fires and returns 'en'
	my $obj = Genealogy::Military::Branch->new();
	is($obj->detect(text => 'He served in the Navy'),
		'navy', 'C.UTF-8 locale treated as English');
};

subtest '_get_language - detect() returning hyphenated tag extracts prefix' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	# 'fr-FR' → /^([a-z]{2})/i captures 'fr'; object behaves as French
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr-FR' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'He served in the Navy'),
		'marine', 'hyphenated detect() tag "fr-FR" extracts "fr"');
};

subtest '_get_language - non-matching detect() tag falls through to env vars' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'de_DE.UTF-8';

	# '123' does not match /^([a-z]{2})/i so the loop exhausts without returning;
	# control falls through to the LANGUAGE/LC_ALL/LC_MESSAGES/LANG cascade
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { '123' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'He served in the Navy'),
		'Marine', 'non-matching detect() tag falls through to LANG env var');
};

subtest '_get_language - undef returned when no locale detectable' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	delete local $ENV{LANG};

	# All env vars absent and detect() empty → _get_language returns undef;
	# new() must default gracefully via $language // _get_language() // 'en'
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	lives_ok(sub { $obj->detect(text => 'He served in the Navy') },
		'undef language defaults to English without crashing');
	is($obj->detect(text => 'He served in the Navy'),
		'navy', 'undef language treated as English');
};

# -----------------------------------------------------------------------
# _translate - uncovered branches
# -----------------------------------------------------------------------

subtest '_translate - unknown language falls back to English' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });

	# 'es' is not a key in %TRANSLATIONS; _translate must fall back to 'en'
	my $obj = Genealogy::Military::Branch->new(language => 'es');
	is($obj->detect(text => 'He served in the Navy'),
		'navy', 'unknown language "es" falls back to English "navy"');
	is($obj->detect(text => 'Served with the RAF'),
		'RAF', 'unknown language "es" falls back to English "RAF"');
};

subtest '_translate - bare key returned when absent from all translation tables' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });

	# Call _translate directly with a key present in neither lang-specific nor
	# 'en' tables; the final $key fallback ($TRANSLATIONS{'en'}{$key} // $key)
	# must return the key itself
	my $obj = Genealogy::Military::Branch->new(language => 'en');
	is($obj->_translate('nonexistent_branch_key'),
		'nonexistent_branch_key',
		'_translate returns bare key when absent from all translation tables');
};

subtest '_translate - undef language field defaults to "en"' => sub {
	# Forge an object with language => undef to exercise the $lang // 'en' guard
	# inside _translate; this bypasses the constructor's own // 'en' default
	my $obj = bless { language => undef, warn_on_error => 0 },
		'Genealogy::Military::Branch';

	is($obj->_translate('navy'), 'navy',
		'undef language field defaults to "en" inside _translate');
	is($obj->_translate('military'), 'military',
		'_translate with undef language returns English "military"');
};

# -----------------------------------------------------------------------
# new() - explicit language arg bypasses _get_language
# -----------------------------------------------------------------------

subtest 'new() with explicit language arg does not call _get_language' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	my $call_count = 0;
	my $spy = mock_scoped(
		'Genealogy::Military::Branch::_get_language' => sub { $call_count++; 'de' }
	);

	# The // operator short-circuits: language is truthy so _get_language is never
	# reached
	my $obj = Genealogy::Military::Branch->new(language => 'fr');
	is($call_count, 0,
		'_get_language not called when language explicitly provided');
	is($obj->detect(text => 'He served in the Navy'),
		'marine', 'explicit language "fr" honoured, not overridden by spy');
};

# -----------------------------------------------------------------------
# All French translation table entries exercised in isolation
# -----------------------------------------------------------------------

subtest 'French - navy key → "marine"' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'Royal Navy seaman'), 'marine',
		'navy key → French "marine"');
};

subtest 'French - army key → "arm\x{e9}e"' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'served in the Army'),
		"arm\x{e9}e", 'army key → French "arm\x{e9}e"');
};

subtest 'French - RAF key → "RAF" (unchanged)' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'Served with the RAF'),
		'RAF', 'RAF key → French "RAF" (same as English)');
};

subtest 'French - military default → "militaire"' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Military::Branch->new();

	# No branch matched → falls back to _translate('military')
	is($obj->detect(text => 'some unrelated text'),
		'militaire', 'no-match fallback → French "militaire"');
};

subtest 'French - marines key → "marines" (same as English)' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'served with the Royal Marines'),
		'marines', 'marines key → French "marines"');
};

subtest "French - air force key → arm\x{e9}e de l'air" => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'served in the Air Force'),
		"arm\x{e9}e de l'air", "air force key → French \"arm\x{e9}e de l'air\"");
};

# -----------------------------------------------------------------------
# English keys that fall back through French (not in fr table)
# -----------------------------------------------------------------------

subtest 'French - Royal Flying Corps falls back to English' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'served in the Royal Flying Corps'),
		'Royal Flying Corps',
		'Royal Flying Corps absent from fr table → English fallback');
};

subtest 'French - Merchant Navy falls back to English' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'Merchant Navy sailor'),
		'Merchant Navy', 'Merchant Navy absent from fr table → English fallback');
};

subtest 'French - Coast Guard falls back to English' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'served in the Coast Guard'),
		'Coast Guard', 'Coast Guard absent from fr table → English fallback');
};

subtest 'French - National Guard falls back to English' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'served in the National Guard'),
		'National Guard', 'National Guard absent from fr table → English fallback');
};

subtest 'French - Royal Engineers falls back to English' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'served in the Royal Engineers'),
		'Royal Engineers',
		'Royal Engineers absent from fr table → English fallback');
};

subtest 'French - Royal Artillery falls back to English' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'served in the Royal Artillery'),
		'Royal Artillery',
		'Royal Artillery absent from fr table → English fallback');
};

# -----------------------------------------------------------------------
# All German translation table entries exercised in isolation
# -----------------------------------------------------------------------

subtest 'German - navy key → "Marine"' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'Royal Navy seaman'), 'Marine',
		'navy key → German "Marine"');
};

subtest 'German - army key → "Armee"' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'served in the Army'), 'Armee',
		'army key → German "Armee"');
};

subtest 'German - RAF key → "RAF" (unchanged)' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'Served with the RAF'), 'RAF',
		'RAF key → German "RAF" (same as English)');
};

subtest 'German - military default → "Milit\x{e4}r"' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Military::Branch->new();

	# No branch matched → falls back to _translate('military')
	is($obj->detect(text => 'some unrelated text'),
		"Milit\x{e4}r", "no-match fallback → German \"Milit\x{e4}r\"");
};

subtest 'German - air force key → "Luftwaffe"' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'served in the Air Force'), 'Luftwaffe',
		'air force key → German "Luftwaffe"');
};

# -----------------------------------------------------------------------
# English keys that fall back through German (not in de table)
# -----------------------------------------------------------------------

subtest 'German - marines falls back to English' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'served with the Royal Marines'),
		'marines', 'marines absent from de table → English fallback');
};

subtest 'German - Royal Engineers falls back to English' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'served in the Royal Engineers'),
		'Royal Engineers',
		'Royal Engineers absent from de table → English fallback');
};

subtest 'German - Royal Artillery falls back to English' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'served in the Royal Artillery'),
		'Royal Artillery',
		'Royal Artillery absent from de table → English fallback');
};

subtest 'German - Royal Flying Corps falls back to English' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'served in the Royal Flying Corps'),
		'Royal Flying Corps',
		'Royal Flying Corps absent from de table → English fallback');
};

subtest 'German - Merchant Navy falls back to English' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'Merchant Navy sailor'),
		'Merchant Navy', 'Merchant Navy absent from de table → English fallback');
};

subtest 'German - Coast Guard falls back to English' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'served in the Coast Guard'),
		'Coast Guard', 'Coast Guard absent from de table → English fallback');
};

subtest 'German - National Guard falls back to English' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'served in the National Guard'),
		'National Guard', 'National Guard absent from de table → English fallback');
};

# -----------------------------------------------------------------------
# warn_on_error carp message content
# -----------------------------------------------------------------------

subtest 'warn_on_error carp message contains module name' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $detect_guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new(warn_on_error => 1);

	# Capture the full carp message and verify it names the module
	my @messages;
	my $carp_guard = mock_scoped('Carp::carp' => sub { push @messages, $_[0] });

	$obj->detect(text => 'unrelated text with no military branch');

	is(scalar @messages, 1, 'exactly one carp message emitted');
	like($messages[0], qr/Genealogy::Military::Branch/,
		'carp message names the module');
};

# -----------------------------------------------------------------------
# detect() called repeatedly on same object — no state leakage
# -----------------------------------------------------------------------

subtest 'detect() called repeatedly on same object - no state leakage' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# Ten calls with the same text must each return the same result
	for my $i (1..10) {
		is($obj->detect(text => 'He served in the Royal Navy'),
			'navy', "call $i: same result regardless of previous calls");
	}
};

# -----------------------------------------------------------------------
# Combined multi-path scenarios for LCSAJ coverage
# -----------------------------------------------------------------------

subtest 'French locale: translation hit, English fallback, and default' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Military::Branch->new();

	# Three distinct code paths exercised in succession on the same object
	is($obj->detect(text => 'Royal Navy sailor'),
		'marine', 'navy → French "marine" (translation hit)');
	is($obj->detect(text => 'Merchant Navy sailor'),
		'Merchant Navy',
		'Merchant Navy → English fallback in French locale');
	is($obj->detect(text => 'unspecified service'),
		'militaire', 'no match → French "militaire" default');
};

subtest 'German locale: translation hit, English fallback, and default' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Military::Branch->new();

	# Three distinct code paths exercised in succession on the same object
	is($obj->detect(text => 'served in the Air Force'),
		'Luftwaffe', 'air force → German "Luftwaffe" (translation hit)');
	is($obj->detect(text => 'served with the Royal Marines'),
		'marines', 'marines → English fallback in German locale');
	is($obj->detect(text => 'unspecified service'),
		"Milit\x{e4}r", "no match → German \"Milit\x{e4}r\" default");
};

subtest 'explicit language overrides env var and detect() for all three locales' => sub {
	# Force env to German; explicit constructor arg must win in every case
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'de_DE.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });

	my @cases = (
		[ 'en', 'navy'   ],
		[ 'fr', 'marine' ],
		[ 'de', 'Marine' ],
	);
	for my $spec (@cases) {
		my ($lang, $expected) = @{$spec};
		my $obj = Genealogy::Military::Branch->new(language => $lang);
		is($obj->detect(text => 'He served in the Navy'),
			$expected,
			"explicit language '$lang' overrides env/detect() → '$expected'");
	}
};

done_testing();

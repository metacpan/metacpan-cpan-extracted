#!/usr/bin/env perl

# integration.t - end-to-end black-box tests for Genealogy::Military::Branch.
#
# Tests exercise the full pipeline across new() and detect() with real
# external packages: I18N::LangTags::Detect (language detection),
# Params::Get (argument parsing), Params::Validate::Strict (input
# validation), and Return::Set (return value handling).  No mocking is
# used except for Carp::carp in the specific subtests that verify
# warn_on_error behaviour.
#
# Locale is controlled via local() on %ENV throughout so that CI
# environments and developer machines produce the same results regardless
# of their host locale.

use strict;
use warnings;
use 5.014;

use Test::Most;
use Test::Mockingbird 0.09 qw(mock_scoped);

# Verify the module loads cleanly before running any other tests
use_ok('Genealogy::Military::Branch') or BAIL_OUT('Cannot load Genealogy::Military::Branch');

# -----------------------------------------------------------------------
# Construction
# -----------------------------------------------------------------------

subtest 'new_ok - no arguments, English locale' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	my $obj = new_ok('Genealogy::Military::Branch');
	ok(defined $obj, 'object is defined');
};

subtest 'new_ok - with warn_on_error flag' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	# Flat-list form passed as arrayref to new_ok
	my $obj = new_ok('Genealogy::Military::Branch', [warn_on_error => 1],
		'Genealogy::Military::Branch with warn_on_error');
	ok(defined $obj, 'object with warn_on_error defined');
};

subtest 'new_ok - hashref argument style' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	# Hashref form: Params::Get must accept both calling conventions
	my $obj = new_ok('Genealogy::Military::Branch', [{ warn_on_error => 0 }],
		'Genealogy::Military::Branch with hashref args');
	ok(defined $obj, 'object from hashref args defined');
};

subtest 'new_ok - explicit language arg' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	# Explicit language overrides environment detection
	my $obj = new_ok('Genealogy::Military::Branch', [{ language => 'fr' }],
		'Genealogy::Military::Branch with explicit language');
	is($obj->{'language'}, 'fr', 'explicit language stored on object');
};

# -----------------------------------------------------------------------
# Full pipeline - realistic genealogy scenarios
# -----------------------------------------------------------------------

subtest 'full pipeline - Royal Navy service note' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	my $obj = Genealogy::Military::Branch->new();

	# Realistic free-text genealogy note for a WWI naval veteran
	is(
		$obj->detect(text => 'Served in the Royal Navy 1914-1918, saw action at Jutland'),
		'navy',
		'realistic Royal Navy service note -> navy'
	);
};

subtest 'full pipeline - RAF service note' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	my $obj = Genealogy::Military::Branch->new();

	# Realistic WWII RAF note
	is(
		$obj->detect(text => 'Flight Sergeant, RAF, Bomber Command 1940-1945'),
		'RAF',
		'realistic RAF service note -> RAF'
	);
};

subtest 'full pipeline - Army service note' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	my $obj = Genealogy::Military::Branch->new();

	# Realistic WWI Army note
	is(
		$obj->detect(text => 'Served as a soldier with the 2nd Battalion from 1915'),
		'army',
		'realistic Army service note -> army'
	);
};

subtest 'full pipeline - no military notes returns military' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	my $obj = Genealogy::Military::Branch->new();

	# A military service event with no branch information
	is(
		$obj->detect(text => 'Awarded campaign medal. No further details.'),
		'military',
		'service note with no branch -> military'
	);
};

# -----------------------------------------------------------------------
# Representative branch patterns - end-to-end spot-checks
# -----------------------------------------------------------------------

subtest 'full pipeline - spot-check all branch patterns' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	my $obj = Genealogy::Military::Branch->new();

	# Representative input -> expected output pairs for each detector
	my %cases = (
		'served in the Navy'            => 'navy',
		'RAF pilot'                     => 'RAF',
		'Royal Air Force officer'       => 'RAF',
		'Army private'                  => 'army',
		'joined the Regiment'           => 'army',
		'Royal Marines commando'        => 'marines',
		'US Marine Corps'               => 'marines',
		'Royal Engineers'               => 'Royal Engineers',
		'Royal Artillery'               => 'Royal Artillery',
		'Royal Flying Corps'            => 'Royal Flying Corps',
		'RFC observer'                  => 'Royal Flying Corps',
		'Merchant Navy seaman'          => 'Merchant Navy',
		'US Air Force'                  => 'air force',
		'Coast Guard'                   => 'Coast Guard',
		'National Guard'                => 'National Guard',
		'Infantry battalion'            => 'army',
		'Cavalry regiment'              => 'army',
		'no branch mentioned'           => 'military',
	);
	for my $input (sort keys %cases) {
		my $expected = $cases{$input};
		is(
			$obj->detect(text => $input),
			$expected,
			"'$input' -> '$expected'"
		);
	}
};

# -----------------------------------------------------------------------
# Specificity ordering - more-specific patterns beat broader ones
# -----------------------------------------------------------------------

subtest 'specificity - Merchant Navy beats Navy' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	my $obj = Genealogy::Military::Branch->new();

	# "Merchant Navy" contains the word "Navy"; the more-specific pattern wins
	is($obj->detect(text => 'Merchant Navy'),    'Merchant Navy', 'Merchant Navy wins over Navy');
	isnt($obj->detect(text => 'Merchant Navy'), 'navy',          'Merchant Navy does not return navy');
};

subtest 'specificity - Royal Air Force beats Air Force' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	my $obj = Genealogy::Military::Branch->new();

	# "Royal Air Force" contains "Air Force"; the RAF detector must fire first
	is($obj->detect(text => 'Royal Air Force'),    'RAF',       'Royal Air Force wins over Air Force');
	isnt($obj->detect(text => 'Royal Air Force'), 'air force', 'Royal Air Force does not return air force');
};

# -----------------------------------------------------------------------
# Stateful behaviour
# -----------------------------------------------------------------------

subtest 'stateful - language cached at new(), survives multiple detect() calls' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'fr_FR.UTF-8';

	# Construct with French locale active
	my $obj = Genealogy::Military::Branch->new();

	# Now change the locale - the cached language must not change
	local $ENV{LANG} = 'de_DE.UTF-8';

	# Both calls must use the French language cached at construction
	is($obj->detect(text => 'served in the Navy'),
		'marine', 'first call after locale change still French');
	is($obj->detect(text => 'joined the Army'),
		"arm\x{e9}e", 'second call still French, not German');
};

subtest 'stateful - two objects with different locales are independent' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};

	# Construct a French object
	local $ENV{LANG} = 'fr_FR.UTF-8';
	my $fr_obj = Genealogy::Military::Branch->new();

	# Construct a German object
	local $ENV{LANG} = 'de_DE.UTF-8';
	my $de_obj = Genealogy::Military::Branch->new();

	# Each object must use its own cached language, not the current env
	local $ENV{LANG} = 'en_GB.UTF-8';
	is($fr_obj->detect(text => 'served in the Navy'),
		'marine', 'French object gives French output');
	is($de_obj->detect(text => 'served in the Navy'),
		'Marine', 'German object gives German output');
};

subtest 'stateful - detect() is stateless between calls' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	my $obj = Genealogy::Military::Branch->new();

	# Unlike normalise() dedup, detect() carries no state between calls;
	# successive calls on the same object must give independent results
	my $first  = $obj->detect(text => 'served in the Navy');
	my $second = $obj->detect(text => 'joined the Army');
	my $third  = $obj->detect(text => 'served in the Navy');

	is($first,  'navy',  'first call returns navy');
	is($second, 'army',  'second call returns army (no state bleed)');
	is($third,  'navy',  'third call returns navy again (stateless)');
};

subtest 'stateful - warn_on_error persists across multiple detect() calls' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	my $obj = Genealogy::Military::Branch->new(warn_on_error => 1);

	# Both calls should trigger carp since warn_on_error is set on the object
	my $carp_count = 0;
	my $carp_guard = mock_scoped('Carp::carp' => sub { $carp_count++ });

	$obj->detect(text => 'no branch here');
	$obj->detect(text => 'still no branch');

	is($carp_count, 2, 'warn_on_error fires on every detect() call with no match');
};

# -----------------------------------------------------------------------
# French locale - real I18N::LangTags::Detect + real translation table
# -----------------------------------------------------------------------

subtest 'French locale - end-to-end translation via LANG env var' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'fr_FR.UTF-8';

	my $obj = Genealogy::Military::Branch->new();

	# Known French translations from %TRANSLATIONS
	is($obj->detect(text => 'Royal Navy sailor'),  'marine',    'navy -> marine');
	is($obj->detect(text => 'Army regiment'),       "arm\x{e9}e", 'army -> armee');
	is($obj->detect(text => 'RAF Bomber Command'),  'RAF',       'RAF stays RAF');
	is($obj->detect(text => 'Marines landing'),     'marines',   'marines stays marines');
	is($obj->detect(text => 'no branch'),           'militaire', 'default -> militaire');
};

subtest 'French locale - untranslated key falls back to English with carp' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'fr_FR.UTF-8';

	my $obj = Genealogy::Military::Branch->new(warn_on_error => 1);

	# 'Royal Engineers' has no French translation; must return English and carp
	my $carp_msg;
	my $carp_guard = mock_scoped('Carp::carp' => sub { $carp_msg = $_[0] });

	# The branch IS detected (Royal Engineers matched), but the key has no
	# French entry so it falls back to English silently (no carp here).
	# warn_on_error only fires when NO branch is matched at all.
	my $result = $obj->detect(text => 'Royal Engineers sapper');
	is($result, 'Royal Engineers', 'Royal Engineers falls back to English in French locale');
};

subtest 'French locale - air force translation' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'fr_FR.UTF-8';

	my $obj = Genealogy::Military::Branch->new();

	# 'air force' has a French translation: "armée de l'air"
	is(
		$obj->detect(text => 'US Air Force'),
		"arm\x{e9}e de l'air",
		"air force -> armée de l'air in French"
	);
};

# -----------------------------------------------------------------------
# German locale - real I18N::LangTags::Detect + real translation table
# -----------------------------------------------------------------------

subtest 'German locale - end-to-end translation via LANG env var' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'de_DE.UTF-8';

	my $obj = Genealogy::Military::Branch->new();

	# Known German translations from %TRANSLATIONS
	is($obj->detect(text => 'Royal Navy sailor'),  'Marine',     'navy -> Marine');
	is($obj->detect(text => 'Army regiment'),       'Armee',      'army -> Armee');
	is($obj->detect(text => 'RAF Bomber Command'),  'RAF',        'RAF stays RAF');
	is($obj->detect(text => 'US Air Force'),        'Luftwaffe',  'air force -> Luftwaffe');
	is($obj->detect(text => 'no branch'),           "Milit\x{e4}r", 'default -> Militaer');
};

subtest 'German locale - untranslated key falls back to English' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'de_DE.UTF-8';

	my $obj = Genealogy::Military::Branch->new();

	# 'Royal Artillery' has no German translation; must fall back to English
	is(
		$obj->detect(text => 'Royal Artillery gunner'),
		'Royal Artillery',
		'Royal Artillery falls back to English in German locale'
	);
};

subtest 'German locale - unknown occupation carps when warn_on_error set' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'de_DE.UTF-8';

	my $obj = Genealogy::Military::Branch->new(warn_on_error => 1);

	my $carp_msg;
	my $carp_guard = mock_scoped('Carp::carp' => sub { $carp_msg = $_[0] });
	my $result = $obj->detect(text => 'no branch at all');

	is($result, "Milit\x{e4}r", 'unmatched text returns German default');
	ok(defined $carp_msg, 'carp fired for unmatched text with warn_on_error');
};

# -----------------------------------------------------------------------
# Params::Get integration - all three calling styles for detect()
# -----------------------------------------------------------------------

subtest 'Params::Get integration - detect() accepts flat-list named args' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	my $obj = Genealogy::Military::Branch->new();

	# Flat-list named arg: text => '...'
	is(
		$obj->detect(text => 'Royal Navy'),
		'navy',
		'detect() with flat-list named arg works'
	);
};

subtest 'Params::Get integration - detect() accepts hashref arg' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	my $obj = Genealogy::Military::Branch->new();

	# Hashref style: { text => '...' }
	is(
		$obj->detect({ text => 'Royal Navy' }),
		'navy',
		'detect() with hashref arg works'
	);
};

subtest 'Params::Get integration - detect() accepts positional string' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	my $obj = Genealogy::Military::Branch->new();

	# Positional form: bare string as first argument
	is(
		$obj->detect('Royal Navy'),
		'navy',
		'detect() with positional string arg works'
	);
};

# -----------------------------------------------------------------------
# Return::Set integration - return value is a plain scalar string
# -----------------------------------------------------------------------

subtest 'Return::Set integration - result is a plain scalar string' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	my $obj = Genealogy::Military::Branch->new();

	# Return::Set is called with type => 'string'; result must be a plain scalar
	my $result = $obj->detect(text => 'Royal Navy');
	is(ref($result), '', 'result has no reference type (plain scalar)');
	ok(defined $result,  'result is defined');
	ok(length $result,   'result is non-empty');
};

subtest 'Return::Set integration - result is never undef regardless of input' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	my $obj = Genealogy::Military::Branch->new();

	# POD guarantees never undef - test for both matching and non-matching input
	ok(defined $obj->detect(text => 'Royal Navy'),        'matched text: result defined');
	ok(defined $obj->detect(text => 'no branch at all'),  'unmatched text: result defined');
};

# -----------------------------------------------------------------------
# Params::Validate::Strict integration - bad args rejected at runtime
# -----------------------------------------------------------------------

subtest 'Params::Validate::Strict integration - unknown new() arg croaks' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	# Validation must reject unknown keys even via hashref style
	throws_ok(
		sub { Genealogy::Military::Branch->new({ bad_key => 1 }) },
		qr/.+/,
		'unknown new() arg croaks via Params::Validate::Strict'
	);
};

subtest 'Params::Validate::Strict integration - missing detect() text croaks' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';

	my $obj = Genealogy::Military::Branch->new();

	# text is required; omitting it must croak
	throws_ok(
		sub { $obj->detect() },
		qr/.+/,
		'omitting text argument causes croak'
	);
};

done_testing();

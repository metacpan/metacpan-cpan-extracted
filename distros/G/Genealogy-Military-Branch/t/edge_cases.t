#!/usr/bin/env perl

# edge_cases.t - destructive, pathological, and boundary-condition tests
# for Genealogy::Military::Branch.
#
# Tests are deliberately adversarial: empty strings, whitespace-only input,
# compound words that must NOT fire word-boundary patterns, strings containing
# multiple branch names, detector-ordering traps, regex-hostile characters,
# Unicode, very long strings, and known false-positive risks in the RFC
# pattern.  Each subtest documents the exact behaviour that results, even
# when that behaviour is surprising.

use strict;
use warnings;
use 5.014;

use Test::Most;
use Test::Mockingbird 0.09 qw(mock_scoped);

use_ok('Genealogy::Military::Branch') or BAIL_OUT('Cannot load Genealogy::Military::Branch');

# -----------------------------------------------------------------------
# Word-boundary edge cases
# \b prevents the patterns firing inside compound words, but NOT across
# punctuation such as hyphens, because '-' is not a \w character.
# -----------------------------------------------------------------------

subtest 'word boundary - Navy does not match inside Navyman' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# 'Navyman' has no \b after 'y' because 'm' is \w; pattern must not fire
	is($obj->detect(text => 'He was a Navyman'), 'military',
		'\bNavy\b does not match inside Navyman');
};

subtest 'word boundary - RAFT does not match RAF' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# In 'RAFT', 'RAF' is followed by 'T' (\w), so \b after 'F' fails
	is($obj->detect(text => 'Built a RAFT'), 'military',
		'\bRAF\b does not match inside RAFT');
	is($obj->detect(text => 'He sailed on a raft'), 'military',
		'\bRAF\b does not match raft (case-insensitive guard)');
};

subtest 'word boundary - Cavalryman does not match Cavalry' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# 'Cavalry' inside 'Cavalryman' is followed by 'm' (\w); \b fails
	is($obj->detect(text => 'A proud Cavalryman'), 'military',
		'\bCavalry\b does not match inside Cavalryman');
};

subtest 'word boundary - Infantrymen does not match Infantry' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# 'Infantry' inside 'Infantrymen' is followed by 'm' (\w); \b fails
	is($obj->detect(text => 'Infantrymen marched'), 'military',
		'\bInfantry\b does not match inside Infantrymen');

	# The same word with a trailing space DOES match
	is($obj->detect(text => 'Infantry men'), 'army',
		'\bInfantry\b matches when followed by a space');
};

subtest 'word boundary - Battlenavy does not match Navy' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# In 'Battlenavy', the 'n' of 'navy' is preceded by 'e' (\w); \b before 'n' fails
	is($obj->detect(text => 'Battlenavy vessel'), 'military',
		'\bNavy\b does not match navy embedded mid-word');
};

# -----------------------------------------------------------------------
# Detector ordering - the first detector in @DETECTORS to match wins,
# regardless of which branch name appears first in the input string.
# Detector order: Merchant Navy, RFC, Royal Engineers, Royal Artillery,
# RAF, Air Force, Marines, Navy, Coast Guard, National Guard, Army.
# -----------------------------------------------------------------------

subtest 'detector ordering - RAF fires before Army even when Army appears first' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# @DETECTORS checks RAF (index 4) before Army (index 10); RAF wins
	is($obj->detect(text => 'transferred from the Army to the RAF'),
		'RAF', 'RAF detector fires before Army detector');
};

subtest 'detector ordering - Marines fires before Navy even when Navy appears first' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# @DETECTORS checks Marines (index 6) before Navy (index 7); Marines wins
	is($obj->detect(text => 'Royal Navy and the Marines'),
		'marines', 'Marines detector fires before Navy detector');
};

subtest 'detector ordering - Royal Engineers fires before Army' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# Royal Engineers (index 2) before Army (index 10)
	is($obj->detect(text => 'Soldier in the Royal Engineers'),
		'Royal Engineers', 'Royal Engineers fires before Army/Soldier');
};

# -----------------------------------------------------------------------
# Empty and whitespace-only text
# -----------------------------------------------------------------------

subtest 'empty string returns military' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# Empty string is a valid string; no pattern matches so default fires
	is($obj->detect(text => ''), 'military', 'empty string returns military');
};

subtest 'whitespace-only string returns military' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# No word characters means no \b boundary can fire
	is($obj->detect(text => '   '),   'military', 'spaces-only string returns military');
	is($obj->detect(text => "\t\n "), 'military', 'tabs and newlines returns military');
};

# -----------------------------------------------------------------------
# Very long strings
# -----------------------------------------------------------------------

subtest 'very long string with no branch does not crash' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# 10,000-character string with no branch keywords must complete without dying
	my $long = 'x' x 10_000;
	my $result;
	lives_ok(
		sub { $result = $obj->detect(text => $long) },
		'10,000-character string with no branch does not crash'
	);
	is($result, 'military', 'long branchless string returns military');
};

subtest 'very long string containing a branch keyword returns the branch' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# 'Navy' buried at the end of a 10,000-character note
	my $long_navy = ('x' x 9_994) . ' Navy ';
	my $result;
	lives_ok(
		sub { $result = $obj->detect(text => $long_navy) },
		'10,000-character string containing Navy does not crash'
	);
	is($result, 'navy', 'Navy found in long string returns navy');
};

# -----------------------------------------------------------------------
# Regex-hostile characters in text
# The input is matched with compiled qr// patterns; the text is the target
# string, not the pattern, so regex metacharacters in the text are safe.
# -----------------------------------------------------------------------

subtest 'regex-hostile characters in text do not crash detect()' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# These characters are dangerous if used as regex patterns; in the target
	# string they are safe because the patterns are pre-compiled qr// objects
	for my $hostile ('A+B', 'A*B', 'A[B', 'A{2}B', 'A(B', 'A?B', 'A.B') {
		my $result;
		lives_ok(
			sub { $result = $obj->detect(text => $hostile) },
			"regex-hostile '$hostile' does not crash detect()"
		);
		is($result, 'military', "regex-hostile '$hostile' returns military");
	}
};

subtest 'regex-hostile text containing a branch keyword still detects correctly' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# Hostile characters surrounding a real branch name must not prevent detection
	is($obj->detect(text => 'Army+Regiment'), 'army',
		'Army in "Army+Regiment" detected despite adjacent + sign');
	is($obj->detect(text => '[RAF]'),         'RAF',
		'RAF in "[RAF]" detected despite square brackets');
};

# -----------------------------------------------------------------------
# Unicode characters in text
# -----------------------------------------------------------------------

subtest 'Unicode characters in text do not corrupt or crash' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# Accented and non-Latin characters must not cause crashes or garbled output
	lives_ok(
		sub { $obj->detect(text => "Serv\x{00E9} dans la Marine nationale") },
		'French text with accented character does not crash'
	);
	lives_ok(
		sub { $obj->detect(text => "\x{4E2D}\x{6587}\x{6587}\x{5B57}") },
		'CJK characters in text do not crash'
	);

	# Non-ASCII text with no branch keyword returns military
	is(
		$obj->detect(text => "M\x{00FC}nchen 1943, keine Angabe"),
		'military',
		'non-ASCII text with no branch returns military'
	);
};

subtest 'Unicode text containing a branch keyword detects correctly' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# ASCII branch keyword embedded in Unicode-containing text
	is(
		$obj->detect(text => "K\x{00E4}mpfte in der Army, 1944"),
		'army',
		'Army detected in string containing non-ASCII characters'
	);
};

# -----------------------------------------------------------------------
# Return value is always from %TRANSLATIONS, not from the input text
# -----------------------------------------------------------------------

subtest 'return value case comes from translation table, not from input' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# The English table has 'navy' (lc), 'RAF' (upper), 'army' (lc)
	# regardless of the case used in the input text
	is($obj->detect(text => 'NAVY'),  'navy', 'NAVY input -> navy (table form)');
	is($obj->detect(text => 'navy'),  'navy', 'navy input -> navy (table form)');
	is($obj->detect(text => 'raf'),   'RAF',  'raf input  -> RAF (table form)');
	is($obj->detect(text => 'ARMY'),  'army', 'ARMY input -> army (table form)');
};

# -----------------------------------------------------------------------
# Language detection extremes
# -----------------------------------------------------------------------

subtest 'C locale is treated as English' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'C';

	# _get_language() returns 'en' for C locale; object must behave as English
	my $obj = Genealogy::Military::Branch->new();
	is($obj->detect(text => 'served in the Navy'), 'navy',
		'C locale object detects as English');
	is($obj->detect(text => 'no branch'), 'military',
		'C locale default is military (English)');
};

subtest 'no locale variables set falls back gracefully' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	delete local $ENV{LANG};
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });

	# _get_language() returns undef; new() defaults via // 'en'
	my $obj;
	lives_ok(
		sub { $obj = Genealogy::Military::Branch->new() },
		'new() with no locale vars does not crash'
	);
	lives_ok(
		sub { $obj->detect(text => 'Navy service') },
		'detect() with no locale vars does not crash'
	);
	is($obj->detect(text => 'Navy service'), 'navy',
		'no locale vars: English detection still works');
};

subtest 'short LANG code without country suffix is accepted' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'fr';

	# 'fr' without '_FR.UTF-8' should still detect as French
	my $obj = Genealogy::Military::Branch->new();
	is($obj->detect(text => 'served in the Navy'), 'marine',
		'short LANG="fr" triggers French translation');
	is($obj->detect(text => 'no branch'), 'militaire',
		'short LANG="fr" default is militaire');
};

# -----------------------------------------------------------------------
# Calling convention edge cases
# -----------------------------------------------------------------------

subtest 'detect() with no arguments causes croak' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# Params::Get throws when $default is set but no args are provided
	throws_ok(
		sub { $obj->detect() },
		qr/.+/,
		'calling detect() with no arguments causes croak'
	);
};

subtest 'detect() with undef text causes croak' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# validate_strict rejects undef for a required 'string' type
	throws_ok(
		sub { $obj->detect(text => undef) },
		qr/.+/,
		'passing undef as text causes croak'
	);
};

subtest 'detect() with empty string does not croak' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# An empty string IS a valid string; validate_strict must accept it
	lives_ok(
		sub { $obj->detect(text => '') },
		'empty string text does not croak'
	);
	is($obj->detect(text => ''), 'military',
		'empty string text returns military');
};

# -----------------------------------------------------------------------
# RFC false-positive risk
# 'RFC' is included as a pattern for Royal Flying Corps (WWI).  In
# genealogy notes this is almost always intentional, but RFC is also
# used as a standards identifier (e.g. "RFC 2616"), which would be a
# false positive if that text appeared in a service note annotation.
# -----------------------------------------------------------------------

subtest 'RFC pattern matches Royal Flying Corps in military context' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# Intended use: RFC in a WWI genealogy note
	is($obj->detect(text => 'RFC observer, 1916'), 'Royal Flying Corps',
		'RFC in military context -> Royal Flying Corps');
};

subtest 'RFC pattern known false-positive: standards identifier' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# Document the current behaviour: RFC matches regardless of context
	is($obj->detect(text => 'See RFC 2616 for details'), 'Royal Flying Corps',
		'RFC standards identifier currently matches Royal Flying Corps (known behaviour)');

	# The desired future behaviour would be to return military for this case
	TODO: {
		local $TODO = 'RFC pattern risks false positive for RFC standards identifiers in annotations';
		is($obj->detect(text => 'See RFC 2616 for details'), 'military',
			'RFC standards number should not match Royal Flying Corps');
	}
};

# -----------------------------------------------------------------------
# warn_on_error fires exactly once per unmatched detect() call
# -----------------------------------------------------------------------

subtest 'warn_on_error fires exactly once per unmatched call, not per detector' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $detect_guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new(warn_on_error => 1);

	# A single unmatched call walks all 11 detectors; carp must fire exactly once
	my $carp_count = 0;
	my $carp_guard = mock_scoped('Carp::carp' => sub { $carp_count++ });
	$obj->detect(text => 'no branch here');
	is($carp_count, 1, 'carp fires exactly once for one unmatched call');
};

subtest 'warn_on_error does not fire when a branch is detected' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $detect_guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new(warn_on_error => 1);

	my $carp_count = 0;
	my $carp_guard = mock_scoped('Carp::carp' => sub { $carp_count++ });

	# Successful detection: each of these returns early; carp must never fire
	$obj->detect(text => 'Navy');
	$obj->detect(text => 'RAF');
	$obj->detect(text => 'Army');
	is($carp_count, 0, 'carp never fires when branch is successfully detected');
};

done_testing();

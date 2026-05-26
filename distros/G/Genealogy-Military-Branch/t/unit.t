#!/usr/bin/env perl

# unit.t - black-box unit tests for the public API of Genealogy::Military::Branch.
#
# Each subtest targets one documented behaviour from the POD.  External
# dependencies are isolated via Test::Mockingbird so that results do not
# vary with the host locale, installed CPAN modules, or environment.
#
# Dependencies mocked:
#   I18N::LangTags::Detect::detect  - language detection called by new()
#   Carp::carp                      - verifies warn_on_error behaviour

use strict;
use warnings;
use 5.014;

use Test::Most;
use Test::Mockingbird 0.09 qw(mock_scoped);

use_ok('Genealogy::Military::Branch') or BAIL_OUT('Cannot load Genealogy::Military::Branch');

# -----------------------------------------------------------------------
# new()
# -----------------------------------------------------------------------

subtest 'new() - returns a blessed Genealogy::Military::Branch object' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });

	isa_ok(Genealogy::Military::Branch->new(), 'Genealogy::Military::Branch');
};

subtest 'new() - accepts hashref argument style' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });

	isa_ok(
		Genealogy::Military::Branch->new({ warn_on_error => 0 }),
		'Genealogy::Military::Branch',
		'hashref argument accepted'
	);
};

subtest 'new() - accepts flat-list argument style' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });

	isa_ok(
		Genealogy::Military::Branch->new(warn_on_error => 0),
		'Genealogy::Military::Branch',
		'flat-list argument accepted'
	);
};

subtest 'new() - unknown argument causes croak' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });

	# Params::Validate::Strict must reject unrecognised keys
	throws_ok(
		sub { Genealogy::Military::Branch->new(not_a_real_arg => 1) },
		qr/.+/,
		'unknown constructor argument causes croak'
	);
};

subtest 'new() - explicit language stored on object' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });

	my $obj = Genealogy::Military::Branch->new({ language => 'fr' });
	is($obj->{'language'}, 'fr', 'explicit language stored correctly');
};

subtest 'new() - warn_on_error stored on object' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });

	my $obj = Genealogy::Military::Branch->new({ warn_on_error => 1 });
	is($obj->{'warn_on_error'}, 1, 'warn_on_error => 1 stored correctly');
};

subtest 'new() - warn_on_error defaults to 0' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });

	my $obj = Genealogy::Military::Branch->new();
	is($obj->{'warn_on_error'}, 0, 'warn_on_error defaults to 0');
};

# -----------------------------------------------------------------------
# detect() - return type contract
# -----------------------------------------------------------------------

subtest 'detect() - return value is always a plain string' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# POD API specification: type => 'string'
	my $result = $obj->detect(text => 'He served in the Navy');
	is(ref($result), '', 'return value is a plain scalar string');
};

subtest 'detect() - return value is never undef' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# POD guarantees: never returns undef
	ok(defined $obj->detect(text => 'unmatched text'), 'result is defined for unmatched text');
	ok(defined $obj->detect(text => 'Navy service'),   'result is defined for matched text');
};

# -----------------------------------------------------------------------
# detect() - argument styles
# -----------------------------------------------------------------------

subtest 'detect() - accepts named argument style' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'Royal Navy'), 'navy', 'named argument form accepted');
};

subtest 'detect() - accepts positional string argument' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# POD notes the text may be passed positionally
	is($obj->detect('Royal Navy'), 'navy', 'positional string argument accepted');
};

# -----------------------------------------------------------------------
# detect() - English branch patterns
# -----------------------------------------------------------------------

subtest 'detect() - Navy pattern returns navy' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'served in the Royal Navy'), 'navy', '\bNavy\b -> navy');
};

subtest 'detect() - RAF pattern returns RAF' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'served with the RAF'), 'RAF', '\bRAF\b -> RAF');
};

subtest 'detect() - Royal Air Force pattern returns RAF' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'Royal Air Force pilot'), 'RAF', '\bRoyal Air Force\b -> RAF');
};

subtest 'detect() - Army pattern returns army' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'enlisted in the Army'),   'army', '\bArmy\b -> army');
	is($obj->detect(text => 'joined the Regiment'),    'army', '\bRegiment\b -> army');
	is($obj->detect(text => 'a brave Soldier'),        'army', '\bSoldier\b -> army');
	is($obj->detect(text => 'Infantry battalion'),     'army', '\bInfantry\b -> army');
	is($obj->detect(text => 'Cavalry charge'),         'army', '\bCavalry\b -> army');
};

subtest 'detect() - Marines patterns return marines' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'Royal Marines commando'), 'marines', '\bRoyal Marines\b -> marines');
	is($obj->detect(text => 'US Marine Corps'),        'marines', '\bMarine Corps\b -> marines');
	is($obj->detect(text => 'serving with Marines'),   'marines', '\bMarines\b -> marines');
};

subtest 'detect() - Royal Engineers pattern returns Royal Engineers' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	is(
		$obj->detect(text => 'Royal Engineers sapper'),
		'Royal Engineers',
		'\bRoyal Engineers\b -> Royal Engineers'
	);
};

subtest 'detect() - Royal Artillery pattern returns Royal Artillery' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	is(
		$obj->detect(text => 'Royal Artillery gunner'),
		'Royal Artillery',
		'\bRoyal Artillery\b -> Royal Artillery'
	);
};

subtest 'detect() - Royal Flying Corps pattern returns Royal Flying Corps' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	is(
		$obj->detect(text => 'Royal Flying Corps observer'),
		'Royal Flying Corps',
		'\bRoyal Flying Corps\b -> Royal Flying Corps'
	);
	is(
		$obj->detect(text => 'RFC pilot in WWI'),
		'Royal Flying Corps',
		'\bRFC\b -> Royal Flying Corps'
	);
};

subtest 'detect() - Merchant Navy pattern returns Merchant Navy' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	is(
		$obj->detect(text => 'Merchant Navy seaman'),
		'Merchant Navy',
		'\bMerchant Navy\b -> Merchant Navy'
	);
};

subtest 'detect() - Air Force pattern returns air force' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'US Air Force'), 'air force', '\bAir Force\b -> air force');
};

subtest 'detect() - Coast Guard pattern returns Coast Guard' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'Coast Guard station'), 'Coast Guard', '\bCoast Guard\b -> Coast Guard');
};

subtest 'detect() - National Guard pattern returns National Guard' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'National Guard unit'), 'National Guard', '\bNational Guard\b -> National Guard');
};

subtest 'detect() - unmatched text returns military' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# POD: returns 'military' when no branch is detected
	is($obj->detect(text => 'no branch mentioned here'), 'military', 'no match -> military');
	is($obj->detect(text => 'born in 1890'),             'military', 'date-only text -> military');
};

# -----------------------------------------------------------------------
# detect() - specificity ordering
# -----------------------------------------------------------------------

subtest 'detect() - Merchant Navy returns Merchant Navy, not navy' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# More-specific pattern must win over the broader \bNavy\b
	is($obj->detect(text => 'Merchant Navy'),    'Merchant Navy', 'Merchant Navy wins over Navy');
	isnt($obj->detect(text => 'Merchant Navy'), 'navy',          'Merchant Navy does not return navy');
};

subtest 'detect() - Royal Air Force returns RAF, not air force' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# RAF detector must fire before the generic Air Force detector
	is($obj->detect(text => 'Royal Air Force'),    'RAF',       'Royal Air Force wins over Air Force');
	isnt($obj->detect(text => 'Royal Air Force'), 'air force', 'Royal Air Force does not return air force');
};

# -----------------------------------------------------------------------
# detect() - case insensitivity
# -----------------------------------------------------------------------

subtest 'detect() - patterns match regardless of input case' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new();

	# Case of the input text must not affect the detection result
	is($obj->detect(text => 'royal navy'),      'navy', 'lowercase navy matches');
	is($obj->detect(text => 'ROYAL NAVY'),      'navy', 'uppercase NAVY matches');
	is($obj->detect(text => 'royal air force'), 'RAF',  'lowercase royal air force matches');
	is($obj->detect(text => 'ARMY REGIMENT'),   'army', 'uppercase ARMY REGIMENT matches');
};

# -----------------------------------------------------------------------
# detect() - warn_on_error
# -----------------------------------------------------------------------

subtest 'detect() - no carp when warn_on_error is 0 and no match' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $detect_guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new(warn_on_error => 0);

	my $carp_count = 0;
	my $carp_guard = mock_scoped('Carp::carp' => sub { $carp_count++ });
	$obj->detect(text => 'unrelated text');
	is($carp_count, 0, 'Carp::carp not called when warn_on_error is 0');
};

subtest 'detect() - carp fires when warn_on_error is 1 and no match' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $detect_guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new(warn_on_error => 1);

	my $carp_count = 0;
	my $carp_guard = mock_scoped('Carp::carp' => sub { $carp_count++ });
	$obj->detect(text => 'unrelated text');
	ok($carp_count > 0, 'Carp::carp fired when warn_on_error is 1 and no branch matched');
};

subtest 'detect() - no carp when warn_on_error is 1 and branch matched' => sub {
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $detect_guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });
	my $obj = Genealogy::Military::Branch->new(warn_on_error => 1);

	# A successful match must not trigger the warning path
	my $carp_count = 0;
	my $carp_guard = mock_scoped('Carp::carp' => sub { $carp_count++ });
	$obj->detect(text => 'served in the Navy');
	is($carp_count, 0, 'Carp::carp not called when branch was successfully detected');
};

# -----------------------------------------------------------------------
# detect() - French locale translations
# -----------------------------------------------------------------------

subtest 'detect() - French: navy returns marine' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'served in the Navy'), 'marine', 'navy -> marine in French');
};

subtest 'detect() - French: army returns armee' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'joined the Army'), "arm\x{e9}e", 'army -> armee in French');
};

subtest 'detect() - French: RAF stays RAF' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'RAF pilot'), 'RAF', 'RAF unchanged in French');
};

subtest 'detect() - French: default returns militaire' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'no branch here'), 'militaire', 'default -> militaire in French');
};

subtest 'detect() - French: untranslated key falls back to English' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'fr' });
	my $obj = Genealogy::Military::Branch->new();

	# 'Royal Engineers' has no French translation; must fall back to English
	is(
		$obj->detect(text => 'Royal Engineers'),
		'Royal Engineers',
		'Royal Engineers falls back to English in French locale'
	);
};

# -----------------------------------------------------------------------
# detect() - German locale translations
# -----------------------------------------------------------------------

subtest 'detect() - German: navy returns Marine' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'served in the Navy'), 'Marine', 'navy -> Marine in German');
};

subtest 'detect() - German: army returns Armee' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'joined the Army'), 'Armee', 'army -> Armee in German');
};

subtest 'detect() - German: RAF stays RAF' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'RAF pilot'), 'RAF', 'RAF unchanged in German');
};

subtest 'detect() - German: default returns Militaer' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Military::Branch->new();

	is($obj->detect(text => 'no branch here'), "Milit\x{e4}r", 'default -> Militaer in German');
};

subtest 'detect() - German: untranslated key falls back to English' => sub {
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { 'de' });
	my $obj = Genealogy::Military::Branch->new();

	# 'Royal Artillery' has no German translation; must fall back to English
	is(
		$obj->detect(text => 'Royal Artillery'),
		'Royal Artillery',
		'Royal Artillery falls back to English in German locale'
	);
};

# -----------------------------------------------------------------------
# detect() - explicit language constructor override
# -----------------------------------------------------------------------

subtest 'detect() - explicit language constructor arg overrides environment' => sub {
	# ENV says English, but constructor says French
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	local $ENV{LANG} = 'en_GB.UTF-8';
	my $guard = mock_scoped('I18N::LangTags::Detect::detect' => sub { () });

	my $obj = Genealogy::Military::Branch->new({ language => 'fr' });
	is(
		$obj->detect(text => 'served in the Navy'),
		'marine',
		'explicit language => fr gives French result despite English ENV'
	);
};

done_testing();

use strict;
use warnings;
use Test::Most;
use Test::Mockingbird 0.09;

# Test private functions directly as standalone functions
use_ok('Genealogy::Military::Branch');

# ----------------------------------------------------------------
# Subtest: _get_language() via %ENV manipulation
# ----------------------------------------------------------------
subtest '_get_language via ENV' => sub {
	local %ENV = %ENV;

	# Test LANGUAGE variable takes priority over all others
	$ENV{'LANGUAGE'} = 'fr:en';
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LANG'};
	is(
		Genealogy::Military::Branch::_get_language(),
		'fr',
		'LANGUAGE=fr:en returns fr'
	);

	# Test LC_ALL fallback when LANGUAGE not set
	delete $ENV{'LANGUAGE'};
	$ENV{'LC_ALL'} = 'de_DE.UTF-8';
	is(
		Genealogy::Military::Branch::_get_language(),
		'de',
		'LC_ALL=de_DE.UTF-8 returns de'
	);

	# Test LC_MESSAGES fallback when LC_ALL not set
	delete $ENV{'LC_ALL'};
	$ENV{'LC_MESSAGES'} = 'es_ES.UTF-8';
	is(
		Genealogy::Military::Branch::_get_language(),
		'es',
		'LC_MESSAGES=es_ES.UTF-8 returns es'
	);

	# Test LANG fallback when all others not set
	delete $ENV{'LC_MESSAGES'};
	$ENV{'LANG'} = 'en_GB.UTF-8';
	is(
		Genealogy::Military::Branch::_get_language(),
		'en',
		'LANG=en_GB.UTF-8 returns en'
	);

	# Test C locale explicitly returns en
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	$ENV{'LANG'} = 'C';
	is(
		Genealogy::Military::Branch::_get_language(),
		'en',
		'LANG=C returns en'
	);

	# Test C.UTF-8 locale also returns en
	$ENV{'LANG'} = 'C.UTF-8';
	is(
		Genealogy::Military::Branch::_get_language(),
		'en',
		'LANG=C.UTF-8 returns en'
	);

	# Test undef returned when no env vars set at all
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LANG'};
	is(
		Genealogy::Military::Branch::_get_language(),
		undef,
		'No env vars returns undef'
	);
};

# ----------------------------------------------------------------
# Subtest: _get_language() via I18N::LangTags::Detect mock
# ----------------------------------------------------------------
subtest '_get_language via I18N::LangTags::Detect mock' => sub {
	local %ENV = %ENV;

	# Remove all language env vars so only the mock fires
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LANG'};

	# Mock detect() to return a French tag
	{
		my $g = mock_scoped
			'I18N::LangTags::Detect::detect' => sub { return ('fr-FR', 'en') };
		is(
			Genealogy::Military::Branch::_get_language(),
			'fr',
			'I18N::LangTags::Detect returning fr-FR gives fr'
		);
	}

	# Mock detect() returning empty list, falling through to ENV
	$ENV{'LANG'} = 'de_DE.UTF-8';
	{
		my $g = mock_scoped
			'I18N::LangTags::Detect::detect' => sub { return () };
		is(
			Genealogy::Military::Branch::_get_language(),
			'de',
			'Empty detect() falls through to LANG env var'
		);
	}
};

# ----------------------------------------------------------------
# Subtest: new()
# ----------------------------------------------------------------
subtest 'new()' => sub {

	# Construction with no arguments should succeed
	my $obj = Genealogy::Military::Branch->new();
	isa_ok($obj, 'Genealogy::Military::Branch', 'new() with no args returns object');

	# Construction with warn_on_error => 1
	my $obj2 = Genealogy::Military::Branch->new({ warn_on_error => 1 });
	isa_ok($obj2, 'Genealogy::Military::Branch', 'new() with warn_on_error returns object');
	is($obj2->{'warn_on_error'}, 1, 'warn_on_error stored correctly');

	# Construction with explicit language
	my $obj3 = Genealogy::Military::Branch->new({ language => 'fr' });
	is($obj3->{'language'}, 'fr', 'language stored correctly');

	# Invalid argument should croak via validate_strict
	{
		my $g = mock_scoped
			'Params::Validate::Strict::validate_strict' =>
			sub { die "validate_strict: invalid argument\n" };
		dies_ok(
			sub { Genealogy::Military::Branch->new({ warn_on_error => 'not_a_boolean' }) },
			'new() with invalid warn_on_error croaks'
		);
	}
};

# ----------------------------------------------------------------
# Subtest: detect() - English branch patterns
# ----------------------------------------------------------------
subtest 'detect() English patterns' => sub {
	local %ENV = %ENV;

	# Force English locale for predictable results
	$ENV{'LANG'} = 'en_GB.UTF-8';
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};

	my $d = Genealogy::Military::Branch->new();

	# Navy patterns
	is($d->detect('He served in the Royal Navy'), 'navy', 'Royal Navy -> navy');
	is($d->detect(text => 'navy sailor'), 'navy', 'navy (named arg) -> navy');

	# RAF patterns
	is($d->detect('Served with the RAF'), 'RAF', 'RAF -> RAF');
	is($d->detect('Royal Air Force pilot'), 'RAF', 'Royal Air Force -> RAF');

	# Army patterns
	is($d->detect('enlisted in the Army'), 'army', 'Army -> army');
	is($d->detect('joined the Regiment'), 'army', 'Regiment -> army');
	is($d->detect('a brave Soldier'), 'army', 'Soldier -> army');
	is($d->detect('Infantry battalion'), 'army', 'Infantry -> army');
	is($d->detect('Cavalry charge'), 'army', 'Cavalry -> army');

	# Marine patterns
	is($d->detect('Royal Marines commando'), 'marines', 'Royal Marines -> marines');
	is($d->detect('US Marine Corps'), 'marines', 'Marine Corps -> marines');
	is($d->detect('serving with the Marines'), 'marines', 'Marines -> marines');

	# Specific British corps
	is($d->detect('Royal Engineers sapper'), 'Royal Engineers', 'Royal Engineers -> Royal Engineers');
	is($d->detect('Royal Artillery gunner'), 'Royal Artillery', 'Royal Artillery -> Royal Artillery');

	# Royal Flying Corps
	is($d->detect('Royal Flying Corps observer'), 'Royal Flying Corps', 'Royal Flying Corps -> Royal Flying Corps');
	is($d->detect('RFC pilot in WWI'), 'Royal Flying Corps', 'RFC -> Royal Flying Corps');

	# Merchant Navy - must not return 'navy'
	is($d->detect('Merchant Navy seaman'), 'Merchant Navy', 'Merchant Navy -> Merchant Navy');
	isnt($d->detect('Merchant Navy seaman'), 'navy', 'Merchant Navy does not return navy');

	# Air Force (non-RAF)
	is($d->detect('US Air Force'), 'air force', 'Air Force -> air force');

	# Coast Guard and National Guard
	is($d->detect('Coast Guard station'), 'Coast Guard', 'Coast Guard -> Coast Guard');
	is($d->detect('National Guard unit'), 'National Guard', 'National Guard -> National Guard');

	# Default when no branch detected
	is($d->detect('Some unrelated text'), 'military', 'unmatched text -> military');
	is($d->detect('born in 1890'), 'military', 'no branch text -> military');
};

# ----------------------------------------------------------------
# Subtest: detect() - specificity ordering
# ----------------------------------------------------------------
subtest 'detect() specificity ordering' => sub {
	local %ENV = %ENV;

	$ENV{'LANG'} = 'en_GB.UTF-8';
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};

	my $d = Genealogy::Military::Branch->new();

	# Royal Air Force must return RAF, not air force
	is($d->detect('Royal Air Force'), 'RAF', 'Royal Air Force returns RAF not air force');

	# Merchant Navy must return Merchant Navy, not navy
	is($d->detect('Merchant Navy'), 'Merchant Navy', 'Merchant Navy returns Merchant Navy not navy');
};

# ----------------------------------------------------------------
# Subtest: detect() - case insensitivity
# ----------------------------------------------------------------
subtest 'detect() case insensitivity' => sub {
	local %ENV = %ENV;

	$ENV{'LANG'} = 'en_GB.UTF-8';
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};

	my $d = Genealogy::Military::Branch->new();

	# Patterns must match regardless of case in the input text
	is($d->detect('royal navy'), 'navy', 'lowercase navy matches');
	is($d->detect('ARMY REGIMENT'), 'army', 'uppercase army matches');
	is($d->detect('royal air force'), 'RAF', 'lowercase royal air force matches');
};

# ----------------------------------------------------------------
# Subtest: detect() - warn_on_error
# ----------------------------------------------------------------
subtest 'detect() warn_on_error' => sub {
	local %ENV = %ENV;

	$ENV{'LANG'} = 'en_GB.UTF-8';
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};

	# warn_on_error => 0 should not carp
	{
		my $warned = 0;
		my $g = mock_scoped 'Carp::carp' => sub { $warned = 1 };
		my $d = Genealogy::Military::Branch->new({ warn_on_error => 0 });
		$d->detect('unrelated text');
		ok(!$warned, 'warn_on_error => 0 does not carp');
	}

	# warn_on_error => 1 should carp on no match
	{
		my $warned = 0;
		my $g = mock_scoped 'Carp::carp' => sub { $warned = 1 };
		my $d = Genealogy::Military::Branch->new({ warn_on_error => 1 });
		$d->detect('unrelated text');
		ok($warned, 'warn_on_error => 1 carps on no match');
	}

	# warn_on_error => 1 should not carp when a branch is found
	{
		my $warned = 0;
		my $g = mock_scoped 'Carp::carp' => sub { $warned = 1 };
		my $d = Genealogy::Military::Branch->new({ warn_on_error => 1 });
		$d->detect('served in the Navy');
		ok(!$warned, 'warn_on_error => 1 does not carp when branch detected');
	}
};

# ----------------------------------------------------------------
# Subtest: detect() - French locale translations
# ----------------------------------------------------------------
subtest 'detect() French locale' => sub {
	local %ENV = %ENV;

	$ENV{'LANG'} = 'fr_FR.UTF-8';
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};

	my $d = Genealogy::Military::Branch->new();

	# Known French translations
	is($d->detect('served in the Navy'), 'marine', 'navy -> marine in French');
	is($d->detect('joined the Army'), "arm\x{e9}e", 'army -> armee in French');
	is($d->detect('RAF pilot'), 'RAF', 'RAF stays RAF in French');
	is($d->detect('no branch here'), 'militaire', 'default -> militaire in French');
	is($d->detect('joined the Marines'), 'marines', 'marines stays marines in French');

	# Keys with no French translation fall back to English
	is($d->detect('Royal Engineers'), 'Royal Engineers', 'Royal Engineers falls back to English in French');
	is($d->detect('National Guard'), 'National Guard', 'National Guard falls back to English in French');
};

# ----------------------------------------------------------------
# Subtest: detect() - German locale translations
# ----------------------------------------------------------------
subtest 'detect() German locale' => sub {
	local %ENV = %ENV;

	$ENV{'LANG'} = 'de_DE.UTF-8';
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};

	my $d = Genealogy::Military::Branch->new();

	# Known German translations
	is($d->detect('served in the Navy'), 'Marine', 'navy -> Marine in German');
	is($d->detect('joined the Army'), 'Armee', 'army -> Armee in German');
	is($d->detect('RAF pilot'), 'RAF', 'RAF stays RAF in German');
	is($d->detect('no branch here'), "Milit\x{e4}r", 'default -> Militaer in German');

	# Keys with no German translation fall back to English
	is($d->detect('Royal Artillery'), 'Royal Artillery', 'Royal Artillery falls back to English in German');
};

# ----------------------------------------------------------------
# Subtest: detect() - explicit language constructor arg
# ----------------------------------------------------------------
subtest 'detect() explicit language override' => sub {

	# Constructor language arg takes precedence over environment
	my $d = Genealogy::Military::Branch->new({ language => 'fr' });
	is($d->detect('served in the Navy'), 'marine', 'explicit language => fr overrides ENV');

	# German override
	my $d2 = Genealogy::Military::Branch->new({ language => 'de' });
	is($d2->detect('joined the Army'), 'Armee', 'explicit language => de overrides ENV');
};

# ----------------------------------------------------------------
# Subtest: detect() - positional argument form
# ----------------------------------------------------------------
subtest 'detect() positional arg' => sub {
	local %ENV = %ENV;

	$ENV{'LANG'} = 'en_GB.UTF-8';
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};

	my $d = Genealogy::Military::Branch->new();

	# Text may be passed as a bare positional string
	is($d->detect('Royal Navy sailor'), 'navy', 'positional text arg works');
	is($d->detect('no match'), 'military', 'positional text arg returns default');
};

done_testing();

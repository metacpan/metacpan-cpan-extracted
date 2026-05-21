use strict;
use warnings;
use Test::Most;
use Test::Mockingbird 0.10;

# We test private functions directly as standalone functions,
# so we need access to the package internals
use_ok('Genealogy::Occupation');

# ----------------------------------------------------------------
# Subtest: _get_language() via %ENV manipulation
# ----------------------------------------------------------------
subtest '_get_language via ENV' => sub {
	# Save original environment to restore after each test
	local %ENV = %ENV;

	# Test LANGUAGE variable takes priority over all others
	$ENV{'LANGUAGE'} = 'fr:en';
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LANG'};
	is(
		Genealogy::Occupation::_get_language(),
		'fr',
		'LANGUAGE=fr:en returns fr'
	);

	# Test LC_ALL fallback when LANGUAGE not set
	delete $ENV{'LANGUAGE'};
	$ENV{'LC_ALL'} = 'de_DE.UTF-8';
	is(
		Genealogy::Occupation::_get_language(),
		'de',
		'LC_ALL=de_DE.UTF-8 returns de'
	);

	# Test LC_MESSAGES fallback when LC_ALL not set
	delete $ENV{'LC_ALL'};
	$ENV{'LC_MESSAGES'} = 'es_ES.UTF-8';
	is(
		Genealogy::Occupation::_get_language(),
		'es',
		'LC_MESSAGES=es_ES.UTF-8 returns es'
	);

	# Test LANG fallback when all others not set
	delete $ENV{'LC_MESSAGES'};
	$ENV{'LANG'} = 'en_GB.UTF-8';
	is(
		Genealogy::Occupation::_get_language(),
		'en',
		'LANG=en_GB.UTF-8 returns en'
	);

	# Test C locale explicitly returns en
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	$ENV{'LANG'} = 'C';
	is(
		Genealogy::Occupation::_get_language(),
		'en',
		'LANG=C returns en'
	);

	# Test C.UTF-8 locale also returns en
	$ENV{'LANG'} = 'C.UTF-8';
	is(
		Genealogy::Occupation::_get_language(),
		'en',
		'LANG=C.UTF-8 returns en'
	);

	# Test undef returned when no env vars set at all
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LANG'};
	is(
		Genealogy::Occupation::_get_language(),
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

	# Mock detect() to return a French tag - guard goes out of scope
	# at end of block, restoring the original function automatically
	{
		my $g = mock_scoped
			'I18N::LangTags::Detect::detect' => sub { return ('fr-FR', 'en') };
		is(
			Genealogy::Occupation::_get_language(),
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
			Genealogy::Occupation::_get_language(),
			'de',
			'Empty detect() falls through to LANG env var'
		);
	}
};

# ----------------------------------------------------------------
# Subtest: _normalise_single()
# ----------------------------------------------------------------
subtest '_normalise_single' => sub {

	# Direct lookup table - exact matches
	is(
		Genealogy::Occupation::_normalise_single('Ag Lab'),
		'Agricultural Labourer',
		'Ag Lab normalises correctly'
	);
	is(
		Genealogy::Occupation::_normalise_single('ag lab'),
		'Agricultural Labourer',
		'ag lab (lowercase) normalises correctly'
	);
	is(
		Genealogy::Occupation::_normalise_single('Farm Labourer'),
		'Agricultural Labourer',
		'Farm Labourer normalises correctly'
	);
	is(
		Genealogy::Occupation::_normalise_single('Platelayer Railway'),
		'Railway Platelayer',
		'Platelayer Railway reordered correctly'
	);
	is(
		Genealogy::Occupation::_normalise_single('General Servant Domestic'),
		'Domestic Servant',
		'General Servant Domestic normalises correctly'
	);
	is(
		Genealogy::Occupation::_normalise_single('Lorry Driver Heavy Worker'),
		'Lorry Driver',
		'Lorry Driver Heavy Worker normalises correctly'
	);
	is(
		Genealogy::Occupation::_normalise_single('Laundry Man'),
		'Laundryman',
		'Laundry Man normalises correctly'
	);

	# Pattern-based matches - "X domestic" and "X dom" reordering
	is(
		Genealogy::Occupation::_normalise_single('Cook Domestic'),
		'Domestic Cook',
		'"X domestic" pattern reorders correctly'
	);
	is(
		Genealogy::Occupation::_normalise_single('Cook Dom'),
		'Domestic Cook',
		'"X dom" pattern reorders correctly'
	);

	# Pattern-based - "works on/for X" conversion
	is(
		Genealogy::Occupation::_normalise_single('Works on Railway'),
		'Railway worker',
		'"works on X" pattern normalises correctly'
	);

	# Pattern-based - clerk/salesman/foreman/manager reordering
	is(
		Genealogy::Occupation::_normalise_single('Clerk Post Office'),
		'Post Office Clerk',
		'"Clerk X" reorders correctly'
	);
	is(
		Genealogy::Occupation::_normalise_single('Salesman Insurance'),
		'Insurance Salesman',
		'"Salesman X" reorders correctly'
	);
	is(
		Genealogy::Occupation::_normalise_single('Foreman of the Works'),
		'Works Foreman',
		'"Foreman of the X" reorders correctly'
	);
	is(
		Genealogy::Occupation::_normalise_single('Manager Shop'),
		'Shop Manager',
		'"Manager X" reorders correctly'
	);

	# Pattern-based - possessive assistant forms
	is(
		Genealogy::Occupation::_normalise_single('Bakers Assistant'),
		"Baker's Assistant",
		'"Bakers Assistant" gets possessive'
	);
	is(
		Genealogy::Occupation::_normalise_single('Butchers Assistant'),
		"Butcher's Assistant",
		'"Butchers Assistant" gets possessive'
	);

	# Police suffix appending
	is(
		Genealogy::Occupation::_normalise_single('Police'),
		'Police officer',
		'"police" suffix gets "officer" appended'
	);

	# Bus Driver should not be treated as possessive "Bu's Driver"
	is(
		Genealogy::Occupation::_normalise_single('Bus Driver'),
		'Bus Driver',
		'"Bus Driver" not incorrectly treated as possessive'
	);

	# Suffix removal cases
	is(
		Genealogy::Occupation::_normalise_single('Carpenter Retired'),
		'Carpenter',
		'"retired" suffix removed'
	);
	is(
		Genealogy::Occupation::_normalise_single('Formerly Carpenter'),
		'Carpenter',
		'"Formerly" prefix removed'
	);
	is(
		Genealogy::Occupation::_normalise_single('Carpenter Own Account'),
		'Carpenter',
		'"Own Account" suffix removed'
	);
	is(
		Genealogy::Occupation::_normalise_single('Carpenter Heavy Worker'),
		'Carpenter',
		'"Heavy Worker" suffix removed'
	);
	is(
		Genealogy::Occupation::_normalise_single('Carpenter Own Business'),
		'Carpenter',
		'"Own Business" suffix removed'
	);

	# Labor/Labour normalisation
	is(
		Genealogy::Occupation::_normalise_single('Railroad Labor'),
		'Railroad Labour',
		'Labor normalised to Labour'
	);

	# Unknown occupation passed through unchanged
	is(
		Genealogy::Occupation::_normalise_single('Carpenter'),
		'Carpenter',
		'Unknown occupation passed through unchanged'
	);
};

# ----------------------------------------------------------------
# Subtest: _apply_locale() with mocked Lingua::EN::ABC functions
# ----------------------------------------------------------------
subtest '_apply_locale' => sub {
	local %ENV = %ENV;

	# Test en_US locale - b2a should be called with labor spelling
	$ENV{'LANG'} = 'en_US.UTF-8';
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	{
		my $g = mock_scoped
			'Lingua::EN::ABC::b2a' => sub {
				my $s = lc(shift);
				$s =~ s/labour/labor/g;
				return $s;
			};
		is(
			Genealogy::Occupation::_apply_locale('Agricultural Labourer'),
			'agricultural laborer',
			'en_US locale applies b2a and labor spelling'
		);
	}

	# Test en_CA locale - b2c should be called
	$ENV{'LANG'} = 'en_CA.UTF-8';
	{
		my $g = mock_scoped
			'Lingua::EN::ABC::b2c' => sub { return lc(shift) };
		is(
			Genealogy::Occupation::_apply_locale('Agricultural Labourer'),
			'agricultural labourer',
			'en_CA locale applies b2c'
		);
	}

	# Test en_GB locale - a2b should be called
	$ENV{'LANG'} = 'en_GB.UTF-8';
	{
		my $g = mock_scoped
			'Lingua::EN::ABC::a2b' => sub { return lc(shift) };
		is(
			Genealogy::Occupation::_apply_locale('Agricultural Laborer'),
			'agricultural laborer',
			'en_GB locale applies a2b'
		);
	}
};

# ----------------------------------------------------------------
# Subtest: _translate_french()
# ----------------------------------------------------------------
subtest '_translate_french' => sub {

	# Direct lookup - ungendered
	is(
		Genealogy::Occupation::_translate_french('Teacher', 'M', 0),
		'Professeur',
		'Teacher translates to Professeur regardless of sex'
	);

	# Direct lookup - gendered male
	is(
		Genealogy::Occupation::_translate_french('Postman', 'M', 0),
		'Facteur',
		'Postman translates to Facteur for male'
	);

	# Direct lookup - gendered female
	is(
		Genealogy::Occupation::_translate_french('Postman', 'F', 0),
		'Factrice',
		'Postman translates to Factrice for female'
	);

	# Farmer pattern - male
	is(
		Genealogy::Occupation::_translate_french('Dairy Farmer', 'M', 0),
		'Agriculteur de Dairy',
		'X Farmer pattern translates male correctly'
	);

	# Farmer pattern - female
	is(
		Genealogy::Occupation::_translate_french('Dairy Farmer', 'F', 0),
		'Agricultrice de Dairy',
		'X Farmer pattern translates female correctly'
	);

	# Teaching regex case
	is(
		Genealogy::Occupation::_translate_french('Teaching', 'M', 0),
		'professeur',
		'Teaching translates to professeur'
	);

	# Retired suffix replacement
	like(
		Genealogy::Occupation::_translate_french('Carpenter Retired', 'M', 0),
		qr/retraite/,
		'Retired suffix replaced with French equivalent'
	);

	# Unknown occupation - no warning, falls back to English
	is(
		Genealogy::Occupation::_translate_french('Wigmaker', 'M', 0),
		'Wigmaker',
		'Unknown occupation falls back to English silently'
	);

	# Unknown occupation - warn_on_error triggers carp
	{
		my $warned = 0;
		my $g = mock_scoped
			'Carp::carp' => sub { $warned = 1 };
		Genealogy::Occupation::_translate_french('Wigmaker', 'M', 1);
		ok($warned, 'carp called for unknown occupation when warn_on_error is true');
	}
};

# ----------------------------------------------------------------
# Subtest: _translate_german()
# ----------------------------------------------------------------
subtest '_translate_german' => sub {

	# Direct lookup - gendered male
	is(
		Genealogy::Occupation::_translate_german('Teacher', 'M', 0),
		'Lehrer',
		'Teacher translates to Lehrer for male'
	);

	# Direct lookup - gendered female
	is(
		Genealogy::Occupation::_translate_german('Teacher', 'F', 0),
		'Lehrerin',
		'Teacher translates to Lehrerin for female'
	);

	# Bus driver - male
	is(
		Genealogy::Occupation::_translate_german('Bus Driver', 'M', 0),
		'Busfahrer',
		'Bus Driver translates to Busfahrer for male'
	);

	# Bus driver - female
	is(
		Genealogy::Occupation::_translate_german('Bus Driver', 'F', 0),
		'Busfahrerin',
		'Bus Driver translates to Busfahrerin for female'
	);

	# Farmer pattern - male
	is(
		Genealogy::Occupation::_translate_german('Dairy Farmer', 'M', 0),
		'Landwirt',
		'X Farmer pattern translates to Landwirt for male'
	);

	# Farmer pattern - female
	is(
		Genealogy::Occupation::_translate_german('Dairy Farmer', 'F', 0),
		'Landwirtin',
		'X Farmer pattern translates to Landwirtin for female'
	);

	# Teaching regex case - male
	is(
		Genealogy::Occupation::_translate_german('Teaching', 'M', 0),
		'Lehrer',
		'Teaching translates to Lehrer for male'
	);

	# Teaching regex case - female
	is(
		Genealogy::Occupation::_translate_german('Teaching', 'F', 0),
		'Lehrerin',
		'Teaching translates to Lehrerin for female'
	);

	# Retired suffix replacement
	like(
		Genealogy::Occupation::_translate_german('Carpenter Retired', 'M', 0),
		qr/ruhestand/,
		'Retired suffix replaced with German equivalent'
	);

	# Self-employed replacement
	like(
		Genealogy::Occupation::_translate_german('Self-Employed', 'M', 0),
		qr/selbstst/,
		'Self-employed replaced with German equivalent'
	);

	# Unknown occupation - no warning, falls back to English
	is(
		Genealogy::Occupation::_translate_german('Wigmaker', 'M', 0),
		'Wigmaker',
		'Unknown occupation falls back to English silently'
	);

	# Unknown occupation - warn_on_error triggers carp
	{
		my $warned = 0;
		my $g = mock_scoped
			'Carp::carp' => sub { $warned = 1 };
		Genealogy::Occupation::_translate_german('Wigmaker', 'M', 1);
		ok($warned, 'carp called for unknown occupation when warn_on_error is true');
	}
};

# ----------------------------------------------------------------
# Subtest: new()
# ----------------------------------------------------------------
subtest 'new()' => sub {

	# Construction with no arguments should succeed
	my $obj = Genealogy::Occupation->new();
	isa_ok($obj, 'Genealogy::Occupation', 'new() with no args returns object');

	# Construction with warn_on_error => 1
	my $obj2 = Genealogy::Occupation->new({ warn_on_error => 1 });
	isa_ok($obj2, 'Genealogy::Occupation', 'new() with warn_on_error returns object');
	is($obj2->{warn_on_error}, 1, 'warn_on_error stored correctly');

	# Construction with warn_on_error => 0 explicitly
	my $obj3 = Genealogy::Occupation->new({ warn_on_error => 0 });
	is($obj3->{warn_on_error}, 0, 'warn_on_error => 0 stored correctly');

	# Invalid argument should croak via validate_strict
	{
		my $g = mock_scoped
			'Params::Validate::Strict::validate_strict' =>
			sub { die "validate_strict: invalid argument\n" };
		dies_ok(
			sub { Genealogy::Occupation->new({ warn_on_error => 'not_a_boolean' }) },
			'new() with invalid warn_on_error croaks'
		);
	}
};

# ----------------------------------------------------------------
# Subtest: normalise()
# ----------------------------------------------------------------
subtest 'normalise()' => sub {
	local %ENV = %ENV;

	# Force British English locale for predictable results
	$ENV{'LANG'} = 'en_GB.UTF-8';
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};

	my $normaliser = Genealogy::Occupation->new();

	# Single string input normalised correctly
	is_deeply(
		$normaliser->normalise(occupation => 'Ag Lab', sex => 'M'),
		['Agricultural Labourer'],
		'Single string occupation normalised correctly'
	);

	# Arrayref input with consecutive deduplication
	is_deeply(
		$normaliser->normalise(
			occupation => ['Ag Lab', 'Ag Lab'],
			sex        => 'M',
		),
		['Agricultural Labourer'],
		'Duplicate occupations deduplicated correctly'
	);

	# Arrayref input with filtering of non-occupations
	is_deeply(
		$normaliser->normalise(
			occupation => ['Ag Lab', 'Retired'],
			sex        => 'M',
		),
		['Agricultural Labourer'],
		'Retired filtered out correctly'
	);

	# All occupations filtered returns empty arrayref
	is_deeply(
		$normaliser->normalise(
			occupation => ['Retired', 'Scholar'],
			sex        => 'M',
		),
		[],
		'All filtered occupations return empty arrayref'
	);

	# ucfirst applied to result
	is_deeply(
		$normaliser->normalise(occupation => 'carpenter', sex => 'M'),
		['Carpenter'],
		'Result has ucfirst applied'
	);

	# Invalid argument croaks via validate_strict
	{
		my $g = mock_scoped
			'Params::Validate::Strict::validate_strict' =>
			sub { die "validate_strict: invalid argument\n" };
		dies_ok(
			sub { $normaliser->normalise(occupation => undef) },
			'normalise() with undef occupation croaks'
		);
	}

	# French locale - male gendered translation
	$ENV{'LANG'} = 'fr_FR.UTF-8';
	my $fr_normaliser = Genealogy::Occupation->new();
	is_deeply(
		$fr_normaliser->normalise(occupation => 'Postman', sex => 'M'),
		['Facteur'],
		'Male Postman translates to Facteur in French locale'
	);

	# French locale - female gendered translation
	is_deeply(
		$fr_normaliser->normalise(occupation => 'Postman', sex => 'F'),
		['Factrice'],
		'Female Postman translates to Factrice in French locale'
	);

	# German locale - male gendered translation
	$ENV{'LANG'} = 'de_DE.UTF-8';
	my $de_normaliser = Genealogy::Occupation->new();
	is_deeply(
		$de_normaliser->normalise(occupation => 'Teacher', sex => 'M'),
		['Lehrer'],
		'Male Teacher translates to Lehrer in German locale'
	);

	# German locale - female gendered translation
	is_deeply(
		$de_normaliser->normalise(occupation => 'Teacher', sex => 'F'),
		['Lehrerin'],
		'Female Teacher translates to Lehrerin in German locale'
	);
};

done_testing();

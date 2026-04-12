#!/usr/bin/env perl

# function.t - White-box tests for Geo::Address::Parser::Country
#
# Covers every public method and every internal helper, including all
# branches in resolve() (steps 1-9) and _append_country().
# Uses stub locale objects (plain blessed hashrefs — no can('new')
# required since that schema check was removed).

use strict;
use warnings;

use Test::Most;

use_ok('Geo::Address::Parser::Country');

# ---------------------------------------------------------------------------
# Helpers: build lightweight locale stubs.  Each stub is a blessed hashref
# with the lookup tables the production code accesses directly.
# ---------------------------------------------------------------------------

# Build a minimal Locale::US stand-in
sub _make_us {
	my $obj = bless {
		code2state => {
			TX => 'Texas',
			CA => 'California',
			NY => 'New York',
		},
		state2code => {
			TEXAS	  => 'TX',
			CALIFORNIA => 'CA',
			'NEW YORK' => 'NY',
		},
	}, 'Fake::US';
	return $obj;
}

# Build a minimal Locale::CA (English) stand-in
sub _make_ca_en {
	return bless {
		code2province  => { ON => 'Ontario', BC => 'British Columbia', QC => 'Quebec',
							NL => 'Newfoundland and Labrador', NU => 'Nunavut' },
		province2code  => { ONTARIO => 'ON', 'BRITISH COLUMBIA' => 'BC', QUEBEC => 'QC',
							'NEWFOUNDLAND AND LABRADOR' => 'NL', NUNAVUT => 'NU' },
	}, 'Fake::CA';
}

# Build a minimal Locale::CA (French) stand-in
sub _make_ca_fr {
	return bless {
		code2province  => { QC => 'Québec' },
		province2code  => { 'QUÉBEC' => 'QC' },
	}, 'Fake::CA';
}

# Build a minimal Locale::AU stand-in.
# Note: production code uses $self->{au}{code2state}{$component}
# (not upcased) for the code path and uc($component) for state2code.
sub _make_au {
	return bless {
		code2state => {
			NSW => 'New South Wales',
			VIC => 'Victoria',
			WA  => 'Western Australia',
		},
		state2code => {
			'NEW SOUTH WALES' => 'NSW',
			'VICTORIA'		=> 'VIC',
		},
	}, 'Fake::AU';
}

# Factory: a fully populated resolver with no GeoNames object
sub _resolver {
	return Geo::Address::Parser::Country->new({
		us	=> _make_us(),
		ca_en => _make_ca_en(),
		ca_fr => _make_ca_fr(),
		au	=> _make_au(),
	});
}

# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# 1. new() — constructor smoke test
# ---------------------------------------------------------------------------
subtest 'new() - constructs blessed object' => sub {
	my $r = _resolver();
	isa_ok $r, 'Geo::Address::Parser::Country', 'blessed into correct class';
};

subtest 'new() - stores locale objects' => sub {
	my $us	= _make_us();
	my $ca_en = _make_ca_en();
	my $ca_fr = _make_ca_fr();
	my $au	= _make_au();

	my $r = Geo::Address::Parser::Country->new({
		us	=> $us,
		ca_en => $ca_en,
		ca_fr => $ca_fr,
		au	=> $au,
	});

	is $r->{us},	$us,	'us stored';
	is $r->{ca_en}, $ca_en, 'ca_en stored';
	is $r->{ca_fr}, $ca_fr, 'ca_fr stored';
	is $r->{au},	$au,	'au stored';
	ok !defined $r->{geonames}, 'geonames absent when not supplied';
};

subtest 'new() - accepts flat list as well as hashref' => sub {
	my $r;
	lives_ok {
		$r = Geo::Address::Parser::Country->new(
			us	=> _make_us(),
			ca_en => _make_ca_en(),
			ca_fr => _make_ca_fr(),
			au	=> _make_au(),
		);
	} 'flat list accepted by constructor';
	isa_ok $r, 'Geo::Address::Parser::Country';
};

subtest 'new() - optional geonames stored when supplied' => sub {
	# A stub that satisfies 'can => search'
	my $gn = bless {}, 'Fake::GeoNames';
	{
		no strict 'refs';
		*{'Fake::GeoNames::new'}	= sub { shift };
		*{'Fake::GeoNames::search'} = sub { [] };
	}

	my $r = Geo::Address::Parser::Country->new({
		us	   => _make_us(),
		ca_en	=> _make_ca_en(),
		ca_fr	=> _make_ca_fr(),
		au	   => _make_au(),
		geonames => $gn,
	});
	is $r->{geonames}, $gn, 'geonames stored';
};

# ---------------------------------------------------------------------------
# 2. resolve() — step 1: %DIRECT plain-string matches
# ---------------------------------------------------------------------------
subtest 'resolve() step 1 - %DIRECT plain string: UK variants' => sub {
	my $r = _resolver();

	for my $input (qw(England Scotland Wales), 'Isle of Man', 'Northern Ireland', 'UK',
				   'england uk', 'england, uk') {
		my $res = $r->resolve(component => $input, place => "Somewhere, $input");
		is $res->{country}, 'United Kingdom', "'$input' -> United Kingdom";
		is $res->{unknown}, 0,				"'$input' unknown == 0";
		is_deeply $res->{warnings}, [],	   "'$input' no warnings";
	}
};

subtest 'resolve() step 1 - %DIRECT plain string: US variants' => sub {
	my $r = _resolver();

	for my $input ('USA', 'US', 'U.S.A.', 'United States of America', 'United States') {
		my $res = $r->resolve(component => $input, place => "New York, $input");
		is $res->{country}, 'United States', "'$input' -> United States";
		is_deeply $res->{warnings}, [],	  "'$input' no warnings";
	}
};

subtest 'resolve() step 1 - %DIRECT plain string: Germany / Netherlands / Slovenia' => sub {
	my $r = _resolver();

	my %expected = (
		'Preussen'	 => 'Germany',
		"Preu\x{00DF}en" => 'Germany',
		'Deutschland'  => 'Germany',
		'Holland'	  => 'Netherlands',
		'The Netherlands' => 'Netherlands',
		'Slovenija'	=> 'Slovenia',
	);
	while(my ($input, $country) = each %expected) {
		my $res = $r->resolve(component => $input, place => "Place, $input");
		is $res->{country}, $country, "'$input' -> $country";
	}
};

subtest 'resolve() step 1 - %DIRECT hashref with warning: Scot' => sub {
	my $r = _resolver();
	my $res = $r->resolve(component => 'Scot', place => 'Aberdeen, Scot');
	is $res->{country}, 'United Kingdom', 'Scot -> United Kingdom';
	like $res->{warnings}[0], qr/Scotland/, 'warning mentions Scotland';
};

subtest 'resolve() step 1 - %DIRECT: NL removed (was Netherlands, now Canada via Locale::CA)' => sub {
	my $r = _resolver();
	# NL was removed from %DIRECT because it shadowed the Canadian province
	# code for Newfoundland and Labrador.  It now falls through to the
	# Locale::CA province-code path (step 4) and resolves to Canada.
	my $res = $r->resolve(component => 'NL', place => 'City, NL');
	is $res->{country}, 'Canada', 'NL -> Canada (via Locale::CA, not %DIRECT)';
	like $res->{warnings}[0], qr/Canada/, 'warning mentions Canada';
};

subtest 'resolve() step 1 - %DIRECT hashref: Canadian province abbreviations' => sub {
	my $r = _resolver();

	for my $abbr ('Nova Scotia', 'Newfoundland', 'Nfld', 'NS', 'Can.') {
		my $res = $r->resolve(component => $abbr, place => "Place, $abbr");
		is $res->{country}, 'Canada', "'$abbr' -> Canada";
		like $res->{warnings}[0], qr/Canada.*missing/i, "'$abbr' warns about missing Canada";
	}
};

# ---------------------------------------------------------------------------
# 3. resolve() — step 2: two-letter US state code
# ---------------------------------------------------------------------------
subtest 'resolve() step 2 - US state two-letter code (TX)' => sub {
	my $r = _resolver();
	my $res = $r->resolve(component => 'TX', place => 'Houston, TX');
	is $res->{country}, 'United States',	   'TX -> United States';
	like $res->{warnings}[0], qr/United States/, 'warning present';
	like $res->{place},	   qr/USA$/,		  'USA appended to place';
	is $res->{unknown}, 0, 'unknown == 0';
};

subtest 'resolve() step 2 - US state two-letter code case-insensitive (tx)' => sub {
	my $r = _resolver();
	my $res = $r->resolve(component => 'tx', place => 'Dallas, tx');
	is $res->{country}, 'United States', 'lowercase tx -> United States';
	like $res->{place}, qr/USA$/, 'USA appended';
};

subtest 'resolve() step 2 - place already has USA: no double-append' => sub {
	my $r = _resolver();
	my $res = $r->resolve(component => 'CA', place => 'Los Angeles, CA, USA');
	like $res->{place}, qr/USA$/, 'USA still at end';
	unlike $res->{place}, qr/USA.*USA/, 'USA not duplicated';
};

# ---------------------------------------------------------------------------
# 4. resolve() — step 3: US state full name
# ---------------------------------------------------------------------------
subtest 'resolve() step 3 - US state full name (Texas)' => sub {
	my $r = _resolver();
	my $res = $r->resolve(component => 'Texas', place => 'Austin, Texas');
	is $res->{country}, 'United States', 'Texas -> United States';
	like $res->{warnings}[0], qr/United States/, 'warning present';
	like $res->{place},	   qr/USA$/,		   'USA appended';
};

# ---------------------------------------------------------------------------
# 5. resolve() — steps 4 & 5: Canadian province
# ---------------------------------------------------------------------------
subtest 'resolve() step 4 - Canadian province two-letter code (ON)' => sub {
	my $r = _resolver();
	my $res = $r->resolve(component => 'ON', place => 'Toronto, ON');
	is $res->{country}, 'Canada',		'ON -> Canada';
	like $res->{warnings}[0], qr/Canada/, 'warning present';
	like $res->{place},	   qr/Canada$/, 'Canada appended';
};

subtest 'resolve() step 4 - Canadian province via French locale (QC)' => sub {
	# QC is in both, confirm it resolves to Canada
	my $r = _resolver();
	my $res = $r->resolve(component => 'QC', place => 'Montreal, QC');
	is $res->{country}, 'Canada', 'QC -> Canada';
};

subtest 'resolve() step 5 - Canadian province full name (Ontario)' => sub {
	my $r = _resolver();
	my $res = $r->resolve(component => 'Ontario', place => 'Ottawa, Ontario');
	is $res->{country}, 'Canada',		 'Ontario -> Canada';
	like $res->{place}, qr/Canada$/,	  'Canada appended';
};

# ---------------------------------------------------------------------------
# 6. resolve() — steps 6 & 7: Australian state
# ---------------------------------------------------------------------------
subtest 'resolve() step 6 - Australian state code (NSW)' => sub {
	my $r = _resolver();
	my $res = $r->resolve(component => 'NSW', place => 'Sydney, NSW');
	is $res->{country}, 'Australia',	   'NSW -> Australia';
	like $res->{warnings}[0], qr/Australia/, 'warning present';
	like $res->{place},	   qr/Australia$/, 'Australia appended';
};

subtest 'resolve() step 6 - Australian WA code (2-letter, not a US state)' => sub {
	# WA is a US state AND an AU state.  Production code reaches the AU
	# code path only if the US paths failed, which won't happen for WA
	# since it is also a valid US code in our stub.
	# Confirm US wins (step 2 fires first).
	my $r = _resolver();

	# To test the AU branch for WA we need a resolver with no WA in US lookup
	my $us_no_wa = bless {
		code2state => { TX => 'Texas' },   # WA absent
		state2code => { TEXAS => 'TX' },
	}, 'Fake::US';

	my $r2 = Geo::Address::Parser::Country->new({
		us	=> $us_no_wa,
		ca_en => _make_ca_en(),
		ca_fr => _make_ca_fr(),
		au	=> _make_au(),
	});

	my $res = $r2->resolve(component => 'WA', place => 'Perth, WA');
	is $res->{country}, 'Australia', 'WA -> Australia when not a US state';
	like $res->{place}, qr/Australia$/, 'Australia appended';
};

subtest 'resolve() step 7 - Australian state full name (Victoria)' => sub {
	my $r = _resolver();
	my $res = $r->resolve(component => 'Victoria', place => 'Melbourne, Victoria');
	is $res->{country}, 'Australia', 'Victoria -> Australia';
	like $res->{place}, qr/Australia$/, 'Australia appended';
};

# ---------------------------------------------------------------------------
# 7. resolve() — step 8: Locale::Object::Country fallback
# ---------------------------------------------------------------------------
subtest 'resolve() step 8 - Locale::Object::Country: France' => sub {
	my $r = _resolver();
	my $res = $r->resolve(component => 'France', place => 'Paris, France');
	is $res->{country}, 'France', 'France -> France via Locale::Object::Country';
	is_deeply $res->{warnings}, [], 'no warnings from L::O::Country path';
	is $res->{unknown}, 0, 'unknown == 0';
};

subtest 'resolve() step 8 - Locale::Object::Country: Germany' => sub {
	# 'Germany' is not in %DIRECT (only German-language forms are), so
	# it must fall through to step 8.
	my $r = _resolver();
	my $res = $r->resolve(component => 'Germany', place => 'Berlin, Germany');
	is $res->{country}, 'Germany', 'Germany -> Germany via L::O::Country';
};

# ---------------------------------------------------------------------------
# 8. resolve() — step 9: GeoNames fallback
# ---------------------------------------------------------------------------
subtest 'resolve() step 9 - GeoNames fallback success' => sub {
	# Use a distinct package name to avoid redefinition warnings from
	# any previous subtest that also defined a Fake::GeoNames* package.
	my $gn = bless {}, 'Fake::GeoNames::A';
	{
		no strict 'refs';
		*{'Fake::GeoNames::A::new'}	= sub { shift };
		*{'Fake::GeoNames::A::search'} = sub {
			return [ { countryName => 'Ruritania' } ];
		};
	}

	my $r = Geo::Address::Parser::Country->new({
		us	   => _make_us(),
		ca_en	=> _make_ca_en(),
		ca_fr	=> _make_ca_fr(),
		au	   => _make_au(),
		geonames => $gn,
	});

	# "Ruritania" is not a real country so L::O::Country warns; suppress it
	# so the test output is clean.  The GeoNames step is what we're testing.
	my $res;
	local $SIG{__WARN__} = sub {};
	$res = $r->resolve(component => 'Ruritania', place => 'Streslau, Ruritania');
	is $res->{country}, 'Ruritania',		 'GeoNames country returned';
	like $res->{warnings}[0], qr/Ruritania/, 'warning emitted by GeoNames path';
	is $res->{unknown}, 0,				   'unknown == 0';
};

subtest 'resolve() step 9 - GeoNames fallback: empty result yields unknown' => sub {
	my $gn = bless {}, 'Fake::GeoNames::B';
	{
		no strict 'refs';
		*{'Fake::GeoNames::B::new'}	= sub { shift };
		*{'Fake::GeoNames::B::search'} = sub { [] };
	}

	my $r = Geo::Address::Parser::Country->new({
		us	   => _make_us(),
		ca_en	=> _make_ca_en(),
		ca_fr	=> _make_ca_fr(),
		au	   => _make_au(),
		geonames => $gn,
	});

	my $res;
	local $SIG{__WARN__} = sub {};
	$res = $r->resolve(component => 'Zyx', place => 'Nowhere, Zyx');
	ok !defined $res->{country}, 'country undef when GeoNames returns nothing';
	is $res->{unknown}, 1,	   'unknown == 1';
};

subtest 'resolve() step 9 - GeoNames fallback: scalar (non-array) result handled' => sub {
	my $gn = bless {}, 'Fake::GeoNames::C';
	{
		no strict 'refs';
		*{'Fake::GeoNames::C::new'}	= sub { shift };
		*{'Fake::GeoNames::C::search'} = sub {
			return { countryName => 'Freedonia' };
		};
	}

	my $r = Geo::Address::Parser::Country->new({
		us	   => _make_us(),
		ca_en	=> _make_ca_en(),
		ca_fr	=> _make_ca_fr(),
		au	   => _make_au(),
		geonames => $gn,
	});

	my $res;
	local $SIG{__WARN__} = sub {};
	$res = $r->resolve(component => 'Freedonia', place => 'Fredonia, Freedonia');
	is $res->{country}, 'Freedonia', 'scalar GeoNames result handled';
};

# ---------------------------------------------------------------------------
# 9. resolve() — fully unknown (no GeoNames, no match anywhere)
# ---------------------------------------------------------------------------
subtest 'resolve() - completely unknown component returns unknown => 1' => sub {
	my $r = _resolver();
	my $res;
	local $SIG{__WARN__} = sub {};   # L::O::Country warns for unknown names
	$res = $r->resolve(
		component => 'Xyzzy',
		place	 => 'Somewhere, Xyzzy',
	);
	ok !defined $res->{country}, 'country undef for unknown';
	is $res->{unknown},  1,				  'unknown == 1';
	is $res->{place},	'Somewhere, Xyzzy', 'place unchanged';
	is_deeply $res->{warnings}, [],		  'no spurious warnings';
};

# ---------------------------------------------------------------------------
# 10. resolve() — return structure invariants
# ---------------------------------------------------------------------------
subtest 'resolve() - always returns required keys' => sub {
	my $r = _resolver();
	my $res = $r->resolve(component => 'England', place => 'London, England');

	ok exists $res->{country},  'country key present';
	ok exists $res->{place},	'place key present';
	ok exists $res->{warnings}, 'warnings key present';
	ok exists $res->{unknown},  'unknown key present';
	isa_ok $res->{warnings}, 'ARRAY', 'warnings';
};

subtest 'resolve() - place always returned even when country found' => sub {
	my $r = _resolver();
	my $res = $r->resolve(component => 'England', place => 'Ramsgate, Kent, England');
	is $res->{place}, 'Ramsgate, Kent, England', 'place returned unchanged when no append needed';
};

# ---------------------------------------------------------------------------
# 11. _append_country() — internal helper
# ---------------------------------------------------------------------------
subtest '_append_country() - appends suffix when absent' => sub {
	my $r = _resolver();
	is $r->_append_country('Houston, TX', 'USA'),
	   'Houston, TX, USA',
	   'suffix appended';
};

subtest '_append_country() - no double-append: exact match' => sub {
	my $r = _resolver();
	is $r->_append_country('Houston, TX, USA', 'USA'),
	   'Houston, TX, USA',
	   'not appended when already present';
};

subtest '_append_country() - no double-append: trailing whitespace in place' => sub {
	my $r = _resolver();
	is $r->_append_country('Houston, TX, USA  ', 'USA'),
	   'Houston, TX, USA  ',
	   'trailing whitespace still counts as already-present';
};

subtest '_append_country() - case-insensitive dedup' => sub {
	my $r = _resolver();
	is $r->_append_country('Toronto, ON, canada', 'Canada'),
	   'Toronto, ON, canada',
	   'case-insensitive: not appended';
};

subtest '_append_country() - appends Canada correctly' => sub {
	my $r = _resolver();
	is $r->_append_country('Toronto, ON', 'Canada'),
	   'Toronto, ON, Canada',
	   'Canada appended';
};

subtest '_append_country() - appends Australia correctly' => sub {
	my $r = _resolver();
	is $r->_append_country('Sydney, NSW', 'Australia'),
	   'Sydney, NSW, Australia',
	   'Australia appended';
};

# ---------------------------------------------------------------------------
# 12. _geonames_lookup() — internal helper directly
# ---------------------------------------------------------------------------
subtest '_geonames_lookup() - returns country name on success' => sub {
	my $gn = bless {}, 'Fake::GN_direct';
	{
		no strict 'refs';
		*{'Fake::GN_direct::search'} = sub {
			return [ { countryName => 'Borovia' } ];
		};
	}

	my $r = Geo::Address::Parser::Country->new({
		us	   => _make_us(),
		ca_en	=> _make_ca_en(),
		ca_fr	=> _make_ca_fr(),
		au	   => _make_au(),
		geonames => $gn,
	});

	my @warnings;
	# Call the helper directly — L::O::Country is not in the call chain here
	my $country = $r->_geonames_lookup('Kessler, Borovia', 'Borovia', \@warnings);
	is $country, 'Borovia', 'returned country name';
	like $warnings[0], qr/Borovia/, 'warning pushed onto arrayref';
};

subtest '_geonames_lookup() - returns undef when no countryName in result' => sub {
	my $gn = bless {}, 'Fake::GN_empty';
	{
		no strict 'refs';
		*{'Fake::GN_empty::search'} = sub {
			return [ { someOtherKey => 'value' } ];
		};
	}

	my $r = Geo::Address::Parser::Country->new({
		us	   => _make_us(),
		ca_en	=> _make_ca_en(),
		ca_fr	=> _make_ca_fr(),
		au	   => _make_au(),
		geonames => $gn,
	});

	my @warnings;
	my $country = $r->_geonames_lookup('Nowhere', 'Nowhere', \@warnings);
	ok !defined $country, 'undef returned when no countryName';
	is scalar @warnings, 0, 'no warning pushed on failure';
};

subtest '_geonames_lookup() - passes full place string as query' => sub {
	my $received_q;
	my $gn = bless {}, 'Fake::GN_spy';
	{
		no strict 'refs';
		*{'Fake::GN_spy::search'} = sub {
			my (undef, %args) = @_;
			$received_q = $args{q};
			return [];
		};
	}

	my $r = Geo::Address::Parser::Country->new({
		us	   => _make_us(),
		ca_en	=> _make_ca_en(),
		ca_fr	=> _make_ca_fr(),
		au	   => _make_au(),
		geonames => $gn,
	});

	my @warnings;
	$r->_geonames_lookup('Streslau, Ruritania', 'Ruritania', \@warnings);
	is $received_q, 'Streslau, Ruritania', 'full place string passed as q';
};

subtest '_geonames_lookup() - requests FULL style' => sub {
	my $received_style;
	my $gn = bless {}, 'Fake::GN_style';
	{
		no strict 'refs';
		*{'Fake::GN_style::search'} = sub {
			my (undef, %args) = @_;
			$received_style = $args{style};
			return [];
		};
	}

	my $r = Geo::Address::Parser::Country->new({
		us	   => _make_us(),
		ca_en	=> _make_ca_en(),
		ca_fr	=> _make_ca_fr(),
		au	   => _make_au(),
		geonames => $gn,
	});

	my @warnings;
	$r->_geonames_lookup('Paris, France', 'France', \@warnings);
	is $received_style, 'FULL', 'FULL style requested';
};

# ---------------------------------------------------------------------------
# 13. %DIRECT coverage — edge cases and case folding
# ---------------------------------------------------------------------------
subtest '%DIRECT - lowercase folding applied before lookup' => sub {
	my $r = _resolver();
	# All entries in %DIRECT are lowercase keys; resolve() uses lc($component)
	my $res = $r->resolve(component => 'ENGLAND', place => 'London, ENGLAND');
	is $res->{country}, 'United Kingdom', 'uppercase ENGLAND still matched';
};

subtest '%DIRECT - mixed-case UK' => sub {
	my $r = _resolver();
	my $res = $r->resolve(component => 'Uk', place => 'London, Uk');
	is $res->{country}, 'United Kingdom', 'Uk (mixed case) matched';
};

subtest '%DIRECT - U.S.A. with dots' => sub {
	my $r = _resolver();
	my $res = $r->resolve(component => 'U.S.A.', place => 'Chicago, U.S.A.');
	is $res->{country}, 'United States', 'U.S.A. matched';
};

# ---------------------------------------------------------------------------
# 14. Warnings list accumulation across paths
# ---------------------------------------------------------------------------
subtest 'resolve() - warnings is always arrayref, never undef' => sub {
	my $r = _resolver();

	for my $input ('England', 'TX', 'Ontario', 'NSW', 'France', 'Xyzzy') {
		my $res;
		local $SIG{__WARN__} = sub {};   # silence L::O::Country for unknowns
		$res = $r->resolve(component => $input, place => "A, $input");
		isa_ok $res->{warnings}, 'ARRAY', "'$input' warnings is ARRAY";
	}
};

subtest 'resolve() - DIRECT hashref emits exactly one warning per call' => sub {
	my $r = _resolver();
	my $res = $r->resolve(component => 'Scot', place => 'Glasgow, Scot');
	is scalar @{ $res->{warnings} }, 1, 'exactly one warning for Scot';
};

done_testing();

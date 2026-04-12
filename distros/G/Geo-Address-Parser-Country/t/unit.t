#!/usr/bin/env perl

# unit.t - Black-box tests for Geo::Address::Parser::Country
#
# Tests each public method strictly through its documented API.
# No knowledge of internals, %DIRECT, or step ordering is assumed.
# Locale stubs satisfy the constructor schema without depending on
# the real Locale::US / Locale::CA / Locale::AU distributions.

use strict;
use warnings;

use Test::Most tests => 42;

use_ok('Geo::Address::Parser::Country');

# ---------------------------------------------------------------------------
# Stub factories
# A black-box test still needs objects that satisfy 'can => new' so the
# constructor schema check passes.  The stubs are as thin as possible and
# represent only what the documented API requires us to supply.
# ---------------------------------------------------------------------------

sub _make_us {
	return bless {
		code2state => { TX => 'Texas', CA => 'California', NY => 'New York' },
		state2code => { TEXAS => 'TX', CALIFORNIA => 'CA', 'NEW YORK' => 'NY' },
	}, 'Unit::Stub::US';
}

sub _make_ca_en {
	return bless {
		code2province => { ON => 'Ontario', BC => 'British Columbia',
						   NL => 'Newfoundland and Labrador', NU => 'Nunavut' },
		province2code => { ONTARIO => 'ON', 'BRITISH COLUMBIA' => 'BC',
						   'NEWFOUNDLAND AND LABRADOR' => 'NL', NUNAVUT => 'NU' },
	}, 'Unit::Stub::CA';
}

sub _make_ca_fr {
	return bless {
		code2province => { QC => 'Quebec' },
		province2code => { QUEBEC => 'QC' },
	}, 'Unit::Stub::CA';
}

sub _make_au {
	return bless {
		code2state => { NSW => 'New South Wales', VIC => 'Victoria' },
		state2code => { 'NEW SOUTH WALES' => 'NSW', VICTORIA => 'VIC' },
	}, 'Unit::Stub::AU';
}

# Standard resolver with no optional GeoNames
sub _resolver {
	return Geo::Address::Parser::Country->new({
		us	=> _make_us(),
		ca_en => _make_ca_en(),
		ca_fr => _make_ca_fr(),
		au	=> _make_au(),
	});
}

# ---------------------------------------------------------------------------
# new() — documented API
#
# POD says: returns a blessed Geo::Address::Parser::Country object.
# Required args: us, ca_en, ca_fr, au (all objects with can('new')).
# Optional arg:  geonames (object with can('search')).
# ---------------------------------------------------------------------------

subtest 'new() - returns a blessed object of the correct class' => sub {
	plan tests => 2;
	my $r = _resolver();
	isa_ok $r, 'Geo::Address::Parser::Country';
	ok $r->can('resolve'), 'object can resolve()';
};

subtest 'new() - accepts a hashref of arguments' => sub {
	plan tests => 1;
	my $r;
	lives_ok { $r = Geo::Address::Parser::Country->new({
		us	=> _make_us(),
		ca_en => _make_ca_en(),
		ca_fr => _make_ca_fr(),
		au	=> _make_au(),
	}) } 'hashref constructor lives';
};

subtest 'new() - accepts a flat key/value list' => sub {
	plan tests => 1;
	my $r;
	lives_ok { $r = Geo::Address::Parser::Country->new(
		us	=> _make_us(),
		ca_en => _make_ca_en(),
		ca_fr => _make_ca_fr(),
		au	=> _make_au(),
	) } 'flat-list constructor lives';
};

subtest 'new() - optional geonames argument accepted without error' => sub {
	plan tests => 1;
	my $gn = bless {}, 'Unit::Stub::GeoNames';
	{
		no strict 'refs';
		*{'Unit::Stub::GeoNames::new'}	= sub { shift };
		*{'Unit::Stub::GeoNames::search'} = sub { [] };
	}
	lives_ok {
		Geo::Address::Parser::Country->new({
			us	   => _make_us(),
			ca_en	=> _make_ca_en(),
			ca_fr	=> _make_ca_fr(),
			au	   => _make_au(),
			geonames => $gn,
		});
	} 'optional geonames accepted';
};

# ---------------------------------------------------------------------------
# resolve() — return structure
#
# POD says the return value is always a hashref with four keys:
#   country  (string or undef)
#   place	(string, min length 1)
#   warnings (arrayref)
#   unknown  (boolean)
# ---------------------------------------------------------------------------

subtest 'resolve() - return value is a hashref' => sub {
	plan tests => 1;
	my $r   = _resolver();
	my $res = $r->resolve(component => 'England', place => 'London, England');
	ok ref($res) eq 'HASH', 'return value is a hashref';
};

subtest 'resolve() - return hashref always has all four documented keys' => sub {
	plan tests => 4;
	my $r   = _resolver();
	my $res = $r->resolve(component => 'England', place => 'London, England');
	ok exists $res->{country},  'country key present';
	ok exists $res->{place},	'place key present';
	ok exists $res->{warnings}, 'warnings key present';
	ok exists $res->{unknown},  'unknown key present';
};

subtest 'resolve() - warnings is always an arrayref' => sub {
	plan tests => 3;
	my $r = _resolver();

	my $res_known;
	lives_ok { $res_known = $r->resolve(component => 'England', place => 'London, England') }
		'resolve lives for known country';
	isa_ok $res_known->{warnings}, 'ARRAY', 'warnings for known country';

	local $SIG{__WARN__} = sub {};
	my $res_unknown = $r->resolve(component => 'Xyzzy', place => 'Nowhere, Xyzzy');
	isa_ok $res_unknown->{warnings}, 'ARRAY', 'warnings for unknown country';
};

subtest 'resolve() - place is always returned as a non-empty string' => sub {
	plan tests => 2;
	my $r = _resolver();

	my $res = $r->resolve(component => 'England', place => 'Ramsgate, Kent, England');
	ok defined($res->{place}),   'place is defined';
	ok length($res->{place}) > 0, 'place is non-empty';
};

subtest 'resolve() - unknown is 0 when country resolved, 1 when not' => sub {
	plan tests => 2;
	my $r = _resolver();

	my $res_known = $r->resolve(component => 'England', place => 'London, England');
	is $res_known->{unknown}, 0, 'unknown == 0 for resolved country';

	local $SIG{__WARN__} = sub {};
	my $res_unk = $r->resolve(component => 'Xyzzy', place => 'Nowhere, Xyzzy');
	is $res_unk->{unknown}, 1, 'unknown == 1 for unresolved country';
};

subtest 'resolve() - country is undef when resolution fails' => sub {
	plan tests => 1;
	my $r = _resolver();
	local $SIG{__WARN__} = sub {};
	my $res = $r->resolve(component => 'Xyzzy', place => 'Nowhere, Xyzzy');
	ok !defined $res->{country}, 'country is undef on failure';
};

# ---------------------------------------------------------------------------
# resolve() — documented examples from the POD
# ---------------------------------------------------------------------------

subtest 'resolve() - POD example: England -> United Kingdom' => sub {
	plan tests => 4;
	my $r   = _resolver();
	my $res = $r->resolve(
		component => 'England',
		place	 => 'Ramsgate, Kent, England',
	);
	is  $res->{country},  'United Kingdom',		 'country eq United Kingdom';
	is  $res->{place},	'Ramsgate, Kent, England', 'place unchanged';
	is_deeply $res->{warnings}, [],				  'no warnings';
	is  $res->{unknown},  0,						 'unknown == 0';
};

subtest 'resolve() - POD example: TX -> United States, USA appended to place' => sub {
	plan tests => 4;
	my $r   = _resolver();
	my $res = $r->resolve(
		component => 'TX',
		place	 => 'Houston, TX',
	);
	is   $res->{country}, 'United States', 'country eq United States';
	like $res->{place},   qr/USA$/,		 'USA appended to place';
	like $res->{warnings}[0], qr/United States/, 'warning mentions United States';
	is   $res->{unknown}, 0,			   'unknown == 0';
};

# ---------------------------------------------------------------------------
# resolve() — documented country variants
# ---------------------------------------------------------------------------

subtest 'resolve() - Scotland resolves to United Kingdom' => sub {
	plan tests => 2;
	my $r   = _resolver();
	my $res = $r->resolve(component => 'Scotland', place => 'Edinburgh, Scotland');
	is $res->{country}, 'United Kingdom', 'Scotland -> United Kingdom';
	is $res->{unknown}, 0,				'unknown == 0';
};

subtest 'resolve() - Wales resolves to United Kingdom' => sub {
	plan tests => 1;
	my $r   = _resolver();
	my $res = $r->resolve(component => 'Wales', place => 'Cardiff, Wales');
	is $res->{country}, 'United Kingdom', 'Wales -> United Kingdom';
};

subtest 'resolve() - Northern Ireland resolves to United Kingdom' => sub {
	plan tests => 1;
	my $r   = _resolver();
	my $res = $r->resolve(component => 'Northern Ireland', place => 'Belfast, Northern Ireland');
	is $res->{country}, 'United Kingdom', 'Northern Ireland -> United Kingdom';
};

subtest 'resolve() - UK resolves to United Kingdom' => sub {
	plan tests => 1;
	my $r   = _resolver();
	my $res = $r->resolve(component => 'UK', place => 'London, UK');
	is $res->{country}, 'United Kingdom', 'UK -> United Kingdom';
};

subtest 'resolve() - USA resolves to United States' => sub {
	plan tests => 2;
	my $r   = _resolver();
	my $res = $r->resolve(component => 'USA', place => 'Chicago, USA');
	is $res->{country}, 'United States', 'USA -> United States';
	is_deeply $res->{warnings}, [],	  'no warnings for USA';
};

subtest 'resolve() - United States resolves to United States' => sub {
	plan tests => 1;
	my $r   = _resolver();
	my $res = $r->resolve(
		component => 'United States',
		place	 => 'Boston, United States',
	);
	is $res->{country}, 'United States', 'United States -> United States';
};

subtest 'resolve() - Holland resolves to Netherlands' => sub {
	plan tests => 1;
	my $r   = _resolver();
	my $res = $r->resolve(component => 'Holland', place => 'Amsterdam, Holland');
	is $res->{country}, 'Netherlands', 'Holland -> Netherlands';
};

subtest 'resolve() - Deutschland resolves to Germany' => sub {
	plan tests => 1;
	my $r   = _resolver();
	my $res = $r->resolve(component => 'Deutschland', place => 'Berlin, Deutschland');
	is $res->{country}, 'Germany', 'Deutschland -> Germany';
};

subtest 'resolve() - Slovenija resolves to Slovenia' => sub {
	plan tests => 1;
	my $r   = _resolver();
	my $res = $r->resolve(component => 'Slovenija', place => 'Ljubljana, Slovenija');
	is $res->{country}, 'Slovenia', 'Slovenija -> Slovenia';
};

# ---------------------------------------------------------------------------
# resolve() — documented warning behaviour for ambiguous/malformed input
# ---------------------------------------------------------------------------

subtest 'resolve() - malformed Scot emits a warning' => sub {
	plan tests => 3;
	my $r   = _resolver();
	my $res = $r->resolve(component => 'Scot', place => 'Aberdeen, Scot');
	is  $res->{country}, 'United Kingdom',	'Scot -> United Kingdom';
	ok  scalar @{ $res->{warnings} } > 0,	 'at least one warning emitted';
	like $res->{warnings}[0], qr/Scotland/i,  'warning mentions Scotland';
};

subtest 'resolve() - Nova Scotia emits a missing-country warning' => sub {
	plan tests => 3;
	my $r   = _resolver();
	my $res = $r->resolve(
		component => 'Nova Scotia',
		place	 => 'Halifax, Nova Scotia',
	);
	is  $res->{country}, 'Canada',				  'Nova Scotia -> Canada';
	ok  scalar @{ $res->{warnings} } > 0,			'at least one warning';
	like $res->{warnings}[0], qr/Canada.*missing/i,  'warning notes missing Canada';
};

subtest 'resolve() - NL resolves to Canada (Newfoundland and Labrador, not Netherlands)' => sub {
	plan tests => 2;
	my $r   = _resolver();
	# NL was removed from %DIRECT where it mapped to Netherlands, because
	# that shadowed the Canadian province code for Newfoundland and Labrador.
	# It now resolves via Locale::CA to Canada.
	my $res = $r->resolve(component => 'NL', place => 'St. Johns, NL');
	is  $res->{country}, 'Canada',  'NL -> Canada';
	like $res->{warnings}[0], qr/Canada/, 'warning mentions Canada';
};

# ---------------------------------------------------------------------------
# resolve() — place string modification
#
# POD: when a US state, Canadian province, or Australian state is
# recognised, the country suffix is appended to place if not already present.
# ---------------------------------------------------------------------------

subtest 'resolve() - USA appended to place for US state code' => sub {
	plan tests => 2;
	my $r   = _resolver();
	my $res = $r->resolve(component => 'TX', place => 'Dallas, TX');
	like   $res->{place}, qr/USA$/,   'USA appended';
	unlike $res->{place}, qr/USA.*USA/, 'not appended twice';
};

subtest 'resolve() - USA not double-appended when already present' => sub {
	plan tests => 1;
	my $r   = _resolver();
	my $res = $r->resolve(component => 'CA', place => 'Los Angeles, CA, USA');
	unlike $res->{place}, qr/USA.*USA/, 'USA not duplicated';
};

subtest 'resolve() - Canada appended to place for Canadian province' => sub {
	plan tests => 2;
	my $r   = _resolver();
	my $res = $r->resolve(component => 'ON', place => 'Toronto, ON');
	like   $res->{place}, qr/Canada$/, 'Canada appended';
	unlike $res->{place}, qr/Canada.*Canada/, 'not appended twice';
};

subtest 'resolve() - Australia appended to place for Australian state' => sub {
	plan tests => 2;
	my $r   = _resolver();
	my $res = $r->resolve(component => 'NSW', place => 'Sydney, NSW');
	like   $res->{place}, qr/Australia$/, 'Australia appended';
	unlike $res->{place}, qr/Australia.*Australia/, 'not appended twice';
};

subtest 'resolve() - place unchanged when country suffix not needed' => sub {
	plan tests => 1;
	my $r   = _resolver();
	my $res = $r->resolve(component => 'England', place => 'Ramsgate, Kent, England');
	is $res->{place}, 'Ramsgate, Kent, England', 'place returned verbatim';
};

# ---------------------------------------------------------------------------
# resolve() — Locale::Object::Country fallback (step 8)
#
# Countries with standard English names not listed in the direct table
# should still resolve correctly via L::O::Country.
# ---------------------------------------------------------------------------

subtest 'resolve() - France resolves via Locale::Object::Country' => sub {
	plan tests => 3;
	my $r   = _resolver();
	my $res = $r->resolve(component => 'France', place => 'Paris, France');
	is  $res->{country}, 'France', 'France -> France';
	is  $res->{unknown}, 0,		'unknown == 0';
	is_deeply $res->{warnings}, [], 'no warnings';
};

subtest 'resolve() - Canada resolves via Locale::Object::Country' => sub {
	plan tests => 2;
	my $r   = _resolver();
	my $res = $r->resolve(component => 'Canada', place => 'Ottawa, Canada');
	is $res->{country}, 'Canada', 'Canada -> Canada';
	is $res->{unknown}, 0,		'unknown == 0';
};

subtest 'resolve() - Australia resolves via Locale::Object::Country' => sub {
	plan tests => 1;
	my $r   = _resolver();
	my $res = $r->resolve(component => 'Australia', place => 'Sydney, Australia');
	is $res->{country}, 'Australia', 'Australia -> Australia';
};

# ---------------------------------------------------------------------------
# resolve() — GeoNames fallback (step 9, documented as optional last resort)
# ---------------------------------------------------------------------------

subtest 'resolve() - GeoNames fallback used when all else fails' => sub {
	plan tests => 3;

	my $gn = bless {}, 'Unit::GN::Fallback';
	{
		no strict 'refs';
		*{'Unit::GN::Fallback::new'}	= sub { shift };
		*{'Unit::GN::Fallback::search'} = sub {
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

	local $SIG{__WARN__} = sub {};
	my $res = $r->resolve(component => 'Ruritania', place => 'Streslau, Ruritania');
	is  $res->{country}, 'Ruritania',		   'GeoNames country returned';
	is  $res->{unknown}, 0,					 'unknown == 0';
	ok  scalar @{ $res->{warnings} } > 0,	   'warning emitted for GeoNames result';
};

subtest 'resolve() - GeoNames not called when country already resolved' => sub {
	plan tests => 1;

	my $called = 0;
	my $gn = bless {}, 'Unit::GN::NotCalled';
	{
		no strict 'refs';
		*{'Unit::GN::NotCalled::new'}	= sub { shift };
		*{'Unit::GN::NotCalled::search'} = sub { $called++; [] };
	}

	my $r = Geo::Address::Parser::Country->new({
		us	   => _make_us(),
		ca_en	=> _make_ca_en(),
		ca_fr	=> _make_ca_fr(),
		au	   => _make_au(),
		geonames => $gn,
	});

	$r->resolve(component => 'England', place => 'London, England');
	is $called, 0, 'GeoNames search not called when country already known';
};

subtest 'resolve() - without geonames, unknown component yields unknown => 1' => sub {
	plan tests => 2;
	my $r = _resolver();	# no geonames
	local $SIG{__WARN__} = sub {};
	my $res = $r->resolve(component => 'Xyzzy', place => 'Nowhere, Xyzzy');
	is $res->{unknown}, 1,	   'unknown == 1';
	ok !defined $res->{country}, 'country undef';
};

# ---------------------------------------------------------------------------
# resolve() — component matching is case-insensitive (documented behaviour:
# the API accepts real-world messy data, so casing must not matter)
# ---------------------------------------------------------------------------

subtest 'resolve() - component matching is case-insensitive (ENGLAND)' => sub {
	plan tests => 1;
	my $r   = _resolver();
	my $res = $r->resolve(component => 'ENGLAND', place => 'London, ENGLAND');
	is $res->{country}, 'United Kingdom', 'ENGLAND (uppercase) -> United Kingdom';
};

subtest 'resolve() - component matching is case-insensitive (england)' => sub {
	plan tests => 1;
	my $r   = _resolver();
	my $res = $r->resolve(component => 'england', place => 'London, england');
	is $res->{country}, 'United Kingdom', 'england (lowercase) -> United Kingdom';
};

subtest 'resolve() - US state code case-insensitive (tx)' => sub {
	plan tests => 2;
	my $r   = _resolver();
	my $res = $r->resolve(component => 'tx', place => 'Dallas, tx');
	is  $res->{country}, 'United States', 'tx -> United States';
	like $res->{place},  qr/USA$/,		'USA appended';
};

# ---------------------------------------------------------------------------
# resolve() - warnings accumulate correctly (zero or more per call)
# ---------------------------------------------------------------------------

subtest 'resolve() - no warnings when standard country name supplied' => sub {
	plan tests => 1;
	my $r   = _resolver();
	my $res = $r->resolve(component => 'England', place => 'Bristol, England');
	is_deeply $res->{warnings}, [], 'empty warnings arrayref';
};

subtest 'resolve() - warnings arrayref non-empty for ambiguous input' => sub {
	plan tests => 1;
	my $r   = _resolver();
	my $res = $r->resolve(component => 'TX', place => 'Austin, TX');
	ok scalar @{ $res->{warnings} } > 0, 'at least one warning for state-only input';
};

subtest 'resolve() - each warning is a plain string' => sub {
	plan tests => 1;
	my $r   = _resolver();
	my $res = $r->resolve(component => 'TX', place => 'Austin, TX');
	ok !ref($res->{warnings}[0]), 'first warning is a plain scalar string';
};

done_testing();

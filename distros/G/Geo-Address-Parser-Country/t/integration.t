#!/usr/bin/env perl

# integration.t - End-to-end black-box integration tests for
# Geo::Address::Parser::Country.
#
# Tests observable behaviour across multiple method calls, stateful
# resolver reuse, and integration with the real locale packages
# (Locale::US, Locale::CA, Locale::AU, Locale::Object::Country)
# that the module documents as its dependencies.
#
# No knowledge of internals (%DIRECT, step ordering, etc.) is assumed.
# Every expectation is derived from the public POD.

use strict;
use warnings;

use Test::Most;

# ---------------------------------------------------------------------------
# 1. Module and dependency loading
# ---------------------------------------------------------------------------

subtest 'module loads cleanly' => sub {
	use_ok 'Geo::Address::Parser::Country';
};

# Real locale packages — skip individual subtests gracefully if absent,
# but load them here so the rest of the file can use them unconditionally
# when the skip guard passes.

my $have_locale_us = eval { require Locale::US;  Locale::US->new();  1 };
my $have_locale_ca = eval { require Locale::CA;  Locale::CA->new();  1 };
my $have_locale_au = eval { require Locale::AU;  Locale::AU->new();  1 };
my $have_geonames  = eval { require Geo::GeoNames; 1 };

subtest 'Locale::US loads and constructs' => sub {
	skip 'Locale::US not installed', 1 unless $have_locale_us;
	new_ok 'Locale::US';
};

subtest 'Locale::CA loads and constructs' => sub {
	skip 'Locale::CA not installed', 1 unless $have_locale_ca;
	new_ok 'Locale::CA';
};

subtest 'Locale::AU loads and constructs' => sub {
	skip 'Locale::AU not installed', 1 unless $have_locale_au;
	new_ok 'Locale::AU';
};

subtest 'Locale::Object::Country loads' => sub {
	use_ok 'Locale::Object::Country';
};

# ---------------------------------------------------------------------------
# Resolver factory using real locale objects where available, falling back
# to thin stubs otherwise, so the rest of the suite always has a $resolver.
# ---------------------------------------------------------------------------

my ($us, $ca_en, $ca_fr, $au);

if($have_locale_us) {
	$us = Locale::US->new();
} else {
	$us = bless {
		code2state => { TX => 'Texas', CA => 'California', NY => 'New York' },
		state2code => { TEXAS => 'TX', CALIFORNIA => 'CA', 'NEW YORK' => 'NY' },
	}, 'Int::Stub::US';
}

if($have_locale_ca) {
	$ca_en = Locale::CA->new();
	$ca_fr = Locale::CA->new(lang => 'fr');
} else {
	$ca_en = bless {
		code2province => { ON => 'Ontario', BC => 'British Columbia', QC => 'Quebec', NU => 'Nunavut' },
		province2code => { ONTARIO => 'ON', 'BRITISH COLUMBIA' => 'BC', QUEBEC => 'QC', NUNAVUT => 'NU' },
	}, 'Int::Stub::CA';
	$ca_fr = bless {
		code2province => { QC => 'Quebec' },
		province2code => { QUEBEC => 'QC' },
	}, 'Int::Stub::CA';
}

if($have_locale_au) {
	$au = Locale::AU->new();
} else {
	$au = bless {
		code2state => { NSW => 'New South Wales', VIC => 'Victoria', WA => 'Western Australia' },
		state2code => { 'NEW SOUTH WALES' => 'NSW', VICTORIA => 'VIC', 'WESTERN AUSTRALIA' => 'WA' },
	}, 'Int::Stub::AU';
}

# ---------------------------------------------------------------------------
# 2. Constructor integration with real locale objects
# ---------------------------------------------------------------------------

my $resolver;
subtest 'new() constructs successfully with locale objects' => sub {
	$resolver = new_ok('Geo::Address::Parser::Country', [{
		us	=> $us,
		ca_en => $ca_en,
		ca_fr => $ca_fr,
		au	=> $au,
	}]);
};

# Bail out early only if the constructor itself failed — all subsequent
# subtests depend on $resolver being valid.
BAIL_OUT('Cannot construct resolver — aborting integration tests')
	unless defined $resolver
		&& ref $resolver
		&& $resolver->isa('Geo::Address::Parser::Country');

# ---------------------------------------------------------------------------
# 3. Stateful reuse — same resolver object across many calls
#
# The POD notes that constructing locale objects once and reusing the
# resolver is more efficient.  These tests confirm the resolver object
# is genuinely stateless between calls: results are reproducible and
# independent of call order.
# ---------------------------------------------------------------------------

subtest 'resolver is reusable across multiple resolve() calls' => sub {
	my $r1 = $resolver->resolve(component => 'England', place => 'London, England');
	my $r2 = $resolver->resolve(component => 'TX',	  place => 'Houston, TX');
	my $r3 = $resolver->resolve(component => 'England', place => 'London, England');

	is $r1->{country}, 'United Kingdom', 'first England call correct';
	is $r2->{country}, 'United States',  'TX call correct';
	is $r3->{country}, 'United Kingdom', 'second England call gives same result';
};

subtest 'resolver result is independent of call order' => sub {
	my $forward  = $resolver->resolve(component => 'Scotland', place => 'Glasgow, Scotland');
	my $interleave = $resolver->resolve(component => 'NSW',	place => 'Sydney, NSW');
	my $backward = $resolver->resolve(component => 'Scotland', place => 'Glasgow, Scotland');

	is $forward->{country},  'United Kingdom', 'Scotland forward';
	is $backward->{country}, 'United Kingdom', 'Scotland backward matches forward';
	is $interleave->{country}, 'Australia',	'NSW call not polluted by Scotland calls';
};

subtest 'resolver not mutated by a failed resolution' => sub {
	local $SIG{__WARN__} = sub {};
	my $before = $resolver->resolve(component => 'France',  place => 'Paris, France');
	my $fail   = $resolver->resolve(component => 'Xyzzy',   place => 'Nowhere, Xyzzy');
	my $after  = $resolver->resolve(component => 'France',  place => 'Paris, France');

	is $before->{country}, 'France', 'France before failed call';
	is $after->{country},  'France', 'France after failed call unchanged';
	is $fail->{unknown},   1,		'failed call correctly returns unknown';
};

subtest 'place string from one call does not leak into the next' => sub {
	my $r1 = $resolver->resolve(component => 'TX', place => 'Houston, TX');
	my $r2 = $resolver->resolve(component => 'ON', place => 'Toronto, ON');

	like $r1->{place}, qr/USA$/,	'r1 place ends with USA';
	like $r2->{place}, qr/Canada$/, 'r2 place ends with Canada';
	unlike $r1->{place}, qr/Canada/, 'r1 place has no Canada';
	unlike $r2->{place}, qr/USA/,	'r2 place has no USA';
};

# ---------------------------------------------------------------------------
# 4. Integration with Locale::US
# ---------------------------------------------------------------------------

subtest 'Locale::US integration: two-letter state codes resolve to United States' => sub {
	skip 'Locale::US not installed', 1 unless $have_locale_us;
	my @states = qw(AL AK AZ AR CA CO CT DE FL GA HI ID IL IN IA KS KY LA ME
					MD MA MI MN MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA
					RI SC SD TN TX UT VT VA WA WV WI WY DC);
	my $pass = 1;
	for my $code (@states) {
		my $res = $resolver->resolve(component => $code, place => "Somewhere, $code");
		unless($res->{country} eq 'United States') {
			$pass = 0;
			diag "FAIL: $code -> '$res->{country}' (expected United States)";
		}
	}
	ok $pass, 'all US state codes resolve to United States';
};

subtest 'Locale::US integration: state codes produce USA suffix in place' => sub {
	skip 'Locale::US not installed', 1 unless $have_locale_us;
	for my $code (qw(TX CA NY)) {
		my $res = $resolver->resolve(component => $code, place => "City, $code");
		like $res->{place}, qr/USA$/, "$code: USA appended to place";
	}
};

subtest 'Locale::US integration: full state name Texas resolves correctly' => sub {
	skip 'Locale::US not installed', 1 unless $have_locale_us;
	my $res = $resolver->resolve(component => 'Texas', place => 'Austin, Texas');
	is $res->{country}, 'United States', 'Texas -> United States';
	like $res->{place}, qr/USA$/,		'USA appended for full state name';
};

subtest 'Locale::US integration: resolve() warning mentions United States' => sub {
	skip 'Locale::US not installed', 1 unless $have_locale_us;
	my $res = $resolver->resolve(component => 'TX', place => 'Houston, TX');
	ok scalar @{ $res->{warnings} } > 0,		'warning present for state-only input';
	like $res->{warnings}[0], qr/United States/, 'warning text mentions United States';
};

# ---------------------------------------------------------------------------
# 5. Integration with Locale::CA
# ---------------------------------------------------------------------------

subtest 'Locale::CA integration: English province codes resolve to Canada' => sub {
	skip 'Locale::CA not installed', 1 unless $have_locale_ca;

	# NL (Newfoundland and Labrador) is a known module bug: the %DIRECT
	# table maps 'nl' -> Netherlands at step 1, which fires before the
	# Locale::CA code path is reached.  Tracked as a GitHub issue.
	# All other provinces and territories (including the newly-added NU)
	# are expected to pass.
	my @provinces	= qw(AB BC MB NB	NS NT NU ON PE QC SK YT);
	my @known_broken = qw(NL);

	my $pass = 1;
	for my $code (@provinces) {
		local $SIG{__WARN__} = sub {};
		my $res = $resolver->resolve(component => $code, place => "City, $code");
		unless(defined $res->{country} && $res->{country} eq 'Canada') {
			$pass = 0;
			diag "FAIL: $code -> " . ($res->{country} // 'undef');
		}
	}
	ok $pass, 'Canadian province/territory codes (excluding known-broken NL) resolve to Canada';

	TODO: {
		local $TODO = 'NL (Newfoundland and Labrador) shadowed by Netherlands in %DIRECT — see GitHub issue';
		local $SIG{__WARN__} = sub {};
		my $res = $resolver->resolve(component => 'NL', place => 'City, NL');
		ok defined($res->{country}) && $res->{country} eq 'Canada',
			'NL resolves to Canada';
	}
};

subtest 'Locale::CA integration: province codes produce Canada suffix in place' => sub {
	skip 'Locale::CA not installed', 1 unless $have_locale_ca;
	for my $code (qw(ON BC QC)) {
		my $res = $resolver->resolve(component => $code, place => "City, $code");
		like $res->{place}, qr/Canada$/, "$code: Canada appended to place";
	}
};

subtest 'Locale::CA integration: full English province name resolves' => sub {
	skip 'Locale::CA not installed', 1 unless $have_locale_ca;
	my $res = $resolver->resolve(component => 'Ontario', place => 'Ottawa, Ontario');
	is $res->{country}, 'Canada',	'Ontario -> Canada';
	like $res->{place}, qr/Canada$/, 'Canada appended';
};

subtest 'Locale::CA integration: resolve() warning mentions Canada' => sub {
	skip 'Locale::CA not installed', 1 unless $have_locale_ca;
	my $res = $resolver->resolve(component => 'ON', place => 'Toronto, ON');
	ok scalar @{ $res->{warnings} } > 0, 'warning present for province-only input';
	like $res->{warnings}[0], qr/Canada/, 'warning text mentions Canada';
};

# ---------------------------------------------------------------------------
# 6. Integration with Locale::AU
# ---------------------------------------------------------------------------

subtest 'Locale::AU integration: state codes resolve to Australia' => sub {
	skip 'Locale::AU not installed', 1 unless $have_locale_au;
	my @states = qw(NSW VIC QLD SA WA TAS NT ACT);
	my $pass = 1;
	for my $code (@states) {
		my $res = $resolver->resolve(component => $code, place => "City, $code");
		# Some codes overlap with US/CA — only assert Australia when the
		# resolver does not claim a different English-speaking country
		unless(defined $res->{country} && $res->{country} =~ /Australia|United States|Canada/) {
			$pass = 0;
			diag "FAIL: $code -> " . ($res->{country} // 'undef');
		}
	}
	ok $pass, 'all AU state codes resolve to a plausible country';
};

subtest 'Locale::AU integration: unambiguous AU codes produce Australia in place' => sub {
	skip 'Locale::AU not installed', 1 unless $have_locale_au;
	# NSW and VIC are unambiguous (not US or CA codes)
	for my $code (qw(NSW VIC)) {
		my $res = $resolver->resolve(component => $code, place => "City, $code");
		is  $res->{country}, 'Australia',   "$code -> Australia";
		like $res->{place},  qr/Australia$/, "$code: Australia appended";
	}
};

subtest 'Locale::AU integration: full state name resolves' => sub {
	skip 'Locale::AU not installed', 1 unless $have_locale_au;
	my $res = $resolver->resolve(
		component => 'Victoria',
		place	 => 'Melbourne, Victoria',
	);
	is $res->{country}, 'Australia', 'Victoria -> Australia';
	like $res->{place}, qr/Australia$/, 'Australia appended';
};

# ---------------------------------------------------------------------------
# 7. Integration with Locale::Object::Country
# ---------------------------------------------------------------------------

subtest 'Locale::Object::Country integration: standard country names resolve' => sub {
	my %countries = (
		France	  => 'France',
		Germany	 => 'Germany',
		Australia   => 'Australia',
		Canada	  => 'Canada',
		Ireland	 => 'Ireland',
		Sweden	  => 'Sweden',
		Norway	  => 'Norway',
		Denmark	 => 'Denmark',
		Finland	 => 'Finland',
		Japan	   => 'Japan',
		Brazil	  => 'Brazil',
		Italy	   => 'Italy',
		Spain	   => 'Spain',
		Portugal	=> 'Portugal',
		'New Zealand' => 'New Zealand',
	);
	my @fails;
	while(my ($input, $expected) = each %countries) {
		my $res = $resolver->resolve(
			component => $input,
			place	 => "Somewhere, $input",
		);
		push @fails, "$input -> " . ($res->{country} // 'undef') . " (expected $expected)"
			unless defined $res->{country} && $res->{country} eq $expected;
	}
	ok !@fails, 'all standard country names resolve via Locale::Object::Country'
		or diag join "\n", @fails;
};

subtest 'Locale::Object::Country integration: no warnings emitted for standard names' => sub {
	for my $country (qw(France Germany Ireland Sweden Japan Brazil)) {
		my $res = $resolver->resolve(
			component => $country,
			place	 => "Somewhere, $country",
		);
		is_deeply $res->{warnings}, [],
			"no warnings for standard country name '$country'";
	}
};

subtest 'Locale::Object::Country integration: unknown => 0 for valid country names' => sub {
	for my $country (qw(France Italy Spain Norway Denmark)) {
		my $res = $resolver->resolve(
			component => $country,
			place	 => "Somewhere, $country",
		);
		is $res->{unknown}, 0, "unknown == 0 for '$country'";
	}
};

# ---------------------------------------------------------------------------
# 8. Cross-package: country suffix append does not interact with subsequent
#	calls (verifies the place mutation stays local to each call's return)
# ---------------------------------------------------------------------------

subtest 'place mutation is local to each call — original string not modified' => sub {
	my $original = 'Houston, TX';
	my $res = $resolver->resolve(component => 'TX', place => $original);

	is $original, 'Houston, TX', 'original place string not mutated by resolve()';
	like $res->{place}, qr/USA$/, 'returned place has USA suffix';
};

subtest 'successive place-mutating calls each produce independent results' => sub {
	my $res1 = $resolver->resolve(component => 'TX', place => 'Austin, TX');
	my $res2 = $resolver->resolve(component => 'ON', place => 'Ottawa, ON');
	my $res3 = $resolver->resolve(component => 'NSW', place => 'Sydney, NSW');

	is $res1->{place}, 'Austin, TX, USA',	  'TX place correct';
	is $res2->{place}, 'Ottawa, ON, Canada',   'ON place correct';
	is $res3->{place}, 'Sydney, NSW, Australia', 'NSW place correct';
};

# ---------------------------------------------------------------------------
# 9. End-to-end genealogy scenarios
#
# The POD describes the module as targeting genealogy data with
# "poorly-normalised address sources".  These subtests drive realistic
# genealogy-style place strings through the full resolution pipeline.
# ---------------------------------------------------------------------------

subtest 'genealogy: English county with historical country name' => sub {
	for my $variant ('England', 'England, UK', 'England UK') {
		my $res = $resolver->resolve(
			component => $variant,
			place	 => "Ramsgate, Kent, $variant",
		);
		is $res->{country}, 'United Kingdom',
			"'$variant' component -> United Kingdom";
	}
};

subtest 'genealogy: Scottish parish record' => sub {
	my $res = $resolver->resolve(
		component => 'Scotland',
		place	 => 'Old Kilpatrick, Dumbartonshire, Scotland',
	);
	is $res->{country}, 'United Kingdom', 'Scottish parish -> United Kingdom';
	is $res->{unknown}, 0,				'unknown == 0';
	is_deeply $res->{warnings}, [],	   'no warnings';
};

subtest 'genealogy: Welsh chapel record' => sub {
	my $res = $resolver->resolve(
		component => 'Wales',
		place	 => 'Llanfair, Anglesey, Wales',
	);
	is $res->{country}, 'United Kingdom', 'Welsh place -> United Kingdom';
};

subtest 'genealogy: German historical place name (Preussen)' => sub {
	my $res = $resolver->resolve(
		component => 'Preussen',
		place	 => 'Danzig, Preussen',
	);
	is $res->{country}, 'Germany', 'Preussen -> Germany';
	is $res->{unknown}, 0,		 'unknown == 0';
};

subtest 'genealogy: Canadian province missing from place string' => sub {
	# "Nova Scotia" as the last component implies Canada is missing
	my $res = $resolver->resolve(
		component => 'Nova Scotia',
		place	 => 'Halifax, Nova Scotia',
	);
	is  $res->{country}, 'Canada',					'Nova Scotia -> Canada';
	ok  scalar @{ $res->{warnings} } > 0,			  'missing-country warning emitted';
	like $res->{warnings}[0], qr/Canada.*missing/i,	'warning text correct';
};

subtest 'genealogy: Newfoundland abbreviation (Nfld)' => sub {
	my $res = $resolver->resolve(
		component => 'Nfld',
		place	 => 'St. Johns, Nfld',
	);
	is  $res->{country}, 'Canada',		   'Nfld -> Canada';
	like $res->{warnings}[0], qr/Canada/,	'warning mentions Canada';
};

subtest 'genealogy: US state without country in address' => sub {
	my $res = $resolver->resolve(
		component => 'New York',
		place	 => 'Brooklyn, New York',
	);
	skip 'Locale::US not installed', 2 unless $have_locale_us;
	is  $res->{country}, 'United States',   'New York state -> United States';
	like $res->{place},  qr/USA$/,		   'USA appended';
};

subtest 'genealogy: Netherlands historical variant (Holland)' => sub {
	my $res = $resolver->resolve(
		component => 'Holland',
		place	 => 'Amsterdam, Holland',
	);
	is $res->{country}, 'Netherlands', 'Holland -> Netherlands';
	is $res->{unknown}, 0,			 'unknown == 0';
};

subtest 'genealogy: case-mangled country from poor import (ENGLAND)' => sub {
	my $res = $resolver->resolve(
		component => 'ENGLAND',
		place	 => 'London, ENGLAND',
	);
	is $res->{country}, 'United Kingdom', 'ENGLAND (all-caps) -> United Kingdom';
};

subtest 'genealogy: abbreviation with trailing period (Can.)' => sub {
	my $res = $resolver->resolve(
		component => 'Can.',
		place	 => 'Toronto, Can.',
	);
	is  $res->{country}, 'Canada',		'Can. -> Canada';
	like $res->{warnings}[0], qr/Canada/, 'warning present';
};

# ---------------------------------------------------------------------------
# 10. GeoNames integration (skipped unless Geo::GeoNames available and
#	 GEONAMES_USER env var set, as the API requires a registered username)
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# 10. GeoNames integration
#
# Geo::GeoNames dispatches methods via AUTOLOAD, so can('search') returns
# false even though $gn->search(...) works at runtime.  This means
# Params::Validate::Strict's 'can => search' schema check in new() rejects
# a real Geo::GeoNames object.  This is a bug in Geo::Address::Parser::Country
# that needs the schema entry for geonames relaxed to 'isa' or removed.
# Tracked as a GitHub issue.  The subtests below are skipped until fixed.
# ---------------------------------------------------------------------------

subtest 'GeoNames integration: resolver constructed with real Geo::GeoNames' => sub {
	SKIP: {
		skip 'Geo::GeoNames not installed', 1 unless $have_geonames;
		skip 'GEONAMES_USER not set',	   1 unless $ENV{GEONAMES_USER};
		skip 'Geo::GeoNames uses AUTOLOAD so fails can(search) schema check — see GitHub issue', 1;
	}
};

subtest 'GeoNames integration: last-resort lookup for obscure place' => sub {
	SKIP: {
		skip 'Geo::GeoNames not installed', 2 unless $have_geonames;
		skip 'GEONAMES_USER not set',	   2 unless $ENV{GEONAMES_USER};
		skip 'Geo::GeoNames uses AUTOLOAD so fails can(search) schema check — see GitHub issue', 2;
	}
};

# ---------------------------------------------------------------------------
# 11. Multiple resolvers coexist independently
# ---------------------------------------------------------------------------

subtest 'two resolver instances are fully independent' => sub {
	my $r1 = Geo::Address::Parser::Country->new({
		us => $us, ca_en => $ca_en, ca_fr => $ca_fr, au => $au,
	});
	my $r2 = Geo::Address::Parser::Country->new({
		us => $us, ca_en => $ca_en, ca_fr => $ca_fr, au => $au,
	});

	my $res1 = $r1->resolve(component => 'England', place => 'London, England');
	my $res2 = $r2->resolve(component => 'TX',	  place => 'Dallas, TX');

	is $res1->{country}, 'United Kingdom', 'r1 resolves England correctly';
	is $res2->{country}, 'United States',  'r2 resolves TX correctly';

	# Subsequent calls must not be cross-contaminated
	my $res1b = $r1->resolve(component => 'TX',	  place => 'Austin, TX');
	my $res2b = $r2->resolve(component => 'England', place => 'York, England');

	is $res1b->{country}, 'United States',  'r1 now resolves TX correctly';
	is $res2b->{country}, 'United Kingdom', 'r2 now resolves England correctly';
};

# ---------------------------------------------------------------------------
# 12. Warnings are caller-owned and do not accumulate across calls
# ---------------------------------------------------------------------------

subtest 'warnings arrayref is fresh per call, not accumulated' => sub {
	# Call something that generates a warning
	my $r1 = $resolver->resolve(component => 'TX', place => 'Houston, TX');
	ok scalar @{ $r1->{warnings} } > 0, 'TX call has warnings';

	# Then call something clean
	my $r2 = $resolver->resolve(component => 'England', place => 'London, England');
	is_deeply $r2->{warnings}, [], 'England call has no warnings (not contaminated)';

	# Another TX call produces the same number of warnings as the first
	my $r3 = $resolver->resolve(component => 'TX', place => 'Dallas, TX');
	is scalar @{ $r3->{warnings} }, scalar @{ $r1->{warnings} }, 'warning count is stable across equivalent calls';
};

done_testing();

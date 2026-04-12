#!/usr/bin/env perl

# edge_cases.t - Destructive, pathological, and boundary-condition tests
# for Geo::Address::Parser::Country.
#
# These tests probe the module with hostile, malformed, extreme, and
# ambiguous inputs.  The goal is to ensure the module never dies, never
# returns a structurally invalid result, and degrades gracefully rather
# than producing silent wrong answers.
#
# All assertions are derived from the public POD contract:
#   - resolve() always returns a hashref with keys country, place,
#     warnings (arrayref), unknown (boolean).
#   - place is always a non-empty string.
#   - warnings is always an arrayref (never undef).
#   - unknown is 1 iff country is undef.
#   - The module must never die on any input that passes schema
#     validation.

use strict;
use warnings;

use Test::Most;
use Scalar::Util qw(looks_like_number);

use Geo::Address::Parser::Country;

# ---------------------------------------------------------------------------
# Shared stubs — kept minimal; NL and NU present to avoid known gaps
# ---------------------------------------------------------------------------

sub _make_us {
	return bless {
		code2state => {
			TX => 'Texas',
			CA => 'California',
			NY => 'New York',
			WA => 'Washington',
		},
		state2code => {
			TEXAS      => 'TX',
			CALIFORNIA => 'CA',
			'NEW YORK' => 'NY',
			WASHINGTON => 'WA',
		},
	}, 'Edge::Stub::US';
}

sub _make_ca_en {
	return bless {
		code2province => {
			ON => 'Ontario',
			BC => 'British Columbia',
			NL => 'Newfoundland and Labrador',
			NU => 'Nunavut',
		},
		province2code => {
			ONTARIO                     => 'ON',
			'BRITISH COLUMBIA'          => 'BC',
			'NEWFOUNDLAND AND LABRADOR' => 'NL',
			NUNAVUT                     => 'NU',
		},
	}, 'Edge::Stub::CA';
}

sub _make_ca_fr {
	return bless {
		code2province => { QC => 'Quebec' },
		province2code => { QUEBEC => 'QC' },
	}, 'Edge::Stub::CA';
}

sub _make_au {
	return bless {
		code2state => { NSW => 'New South Wales', VIC => 'Victoria' },
		state2code => { 'NEW SOUTH WALES' => 'NSW', VICTORIA => 'VIC' },
	}, 'Edge::Stub::AU';
}

sub _resolver {
	return Geo::Address::Parser::Country->new({
		us    => _make_us(),
		ca_en => _make_ca_en(),
		ca_fr => _make_ca_fr(),
		au    => _make_au(),
	});
}

# Verify the four structural invariants on any resolve() result
sub _check_invariants {
	my ($res, $label) = @_;
	ok  ref($res) eq 'HASH',          "$label: result is a hashref";
	ok  exists $res->{country},       "$label: country key present";
	ok  exists $res->{place},         "$label: place key present";
	ok  defined $res->{place} && length($res->{place}) > 0,
	                                   "$label: place is non-empty string";
	isa_ok $res->{warnings}, 'ARRAY', "$label: warnings";
	ok  exists $res->{unknown},       "$label: unknown key present";
	if(defined $res->{country}) {
		is $res->{unknown}, 0,        "$label: unknown==0 when country defined";
	} else {
		is $res->{unknown}, 1,        "$label: unknown==1 when country undef";
	}
}

# ---------------------------------------------------------------------------
# 1. Constructor edge cases
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# 1. Constructor edge cases
# ---------------------------------------------------------------------------
#
# Note: the module now calls Object::Configure::configure() after schema
# validation, which may supply default locale objects from environment
# variables or a config file.  Tests that omit required args must therefore
# accept either outcome: die (no defaults configured) or succeed (defaults
# supplied).  The important invariant is that a returned object must be
# functional.

subtest 'new() - missing required argument: dies or succeeds with valid object' => sub {
	# Unset any Object::Configure env vars that could supply defaults
	local %ENV = %ENV;
	delete $ENV{$_} for grep { /GEO_ADDRESS_PARSER/i } keys %ENV;

	my $r;
	eval {
		$r = Geo::Address::Parser::Country->new({
			us    => _make_us(),
			ca_en => _make_ca_en(),
			# ca_fr missing
			au    => _make_au(),
		});
	};
	if($@) {
		pass 'missing ca_fr causes constructor to die (no defaults configured)';
	} else {
		isa_ok $r, 'Geo::Address::Parser::Country',
			'missing ca_fr supplied by Object::Configure defaults — object valid';
	}
};

subtest 'new() - wrong type for required argument dies cleanly' => sub {
	dies_ok {
		Geo::Address::Parser::Country->new({
			us    => 'not an object',
			ca_en => _make_ca_en(),
			ca_fr => _make_ca_fr(),
			au    => _make_au(),
		});
	} 'scalar instead of object for us dies (wrong type cannot be overridden)';
};

subtest 'new() - undef for required argument: Params::Validate::Strict accepts undef' => sub {
	# Params::Validate::Strict does not treat undef as a type violation for
	# object parameters — this is a known characteristic of the validator.
	# Object::Configure may replace the undef with a default, or it may
	# remain undef. Either way the constructor must not die.
	my $r;
	lives_ok {
		$r = Geo::Address::Parser::Country->new({
			us    => undef,
			ca_en => _make_ca_en(),
			ca_fr => _make_ca_fr(),
			au    => _make_au(),
		});
	} 'undef for us accepted (P::V::S behaviour; Object::Configure may replace it)';
	note 'if undef was not replaced, failures surface at resolve() time';
};

subtest 'new() - arrayref for required argument dies cleanly' => sub {
	dies_ok {
		Geo::Address::Parser::Country->new({
			us    => _make_us(),
			ca_en => [],
			ca_fr => _make_ca_fr(),
			au    => _make_au(),
		});
	} 'arrayref for ca_en dies (wrong type cannot be overridden by Object::Configure)';
};

subtest 'new() - empty hashref: dies or succeeds depending on configured defaults' => sub {
	local %ENV = %ENV;
	delete $ENV{$_} for grep { /GEO_ADDRESS_PARSER/i } keys %ENV;

	my $r;
	eval {
		$r = Geo::Address::Parser::Country->new({});
	};
	if($@) {
		pass 'empty args hashref dies when no defaults configured';
	} else {
		isa_ok $r, 'Geo::Address::Parser::Country',
			'empty args accepted when Object::Configure supplies all defaults';
	}
};

subtest 'new() - extra unknown arguments are tolerated or die cleanly, not silently corrupt' => sub {
	# Whether the module accepts or rejects unknown args, it must not
	# silently construct a broken object.
	my $r;
	eval {
		$r = Geo::Address::Parser::Country->new({
			us        => _make_us(),
			ca_en     => _make_ca_en(),
			ca_fr     => _make_ca_fr(),
			au        => _make_au(),
			bogus_key => 'ignored',
		});
	};
	if($@) {
		pass 'extra args rejected with an exception';
	} else {
		isa_ok $r, 'Geo::Address::Parser::Country',
			'extra args accepted — object still valid';
		my $res = $r->resolve(component => 'England', place => 'London, England');
		is $res->{country}, 'United Kingdom',
			'resolve() still works after extra args accepted';
	}
};

# ---------------------------------------------------------------------------
# 2. resolve() input boundary conditions
# ---------------------------------------------------------------------------

subtest 'resolve() - single character component' => sub {
	my $r = _resolver();
	my $res;
	# Locale::Object::Country warns for unknown single-letter names
	local $SIG{__WARN__} = sub {};
	lives_ok { $res = $r->resolve(component => 'X', place => 'Somewhere, X') }
		'single char component lives';
	_check_invariants($res, 'single char');
};

subtest 'resolve() - single character place' => sub {
	my $r = _resolver();
	my $res;
	# Locale::Object::Country warns for unknown single-letter names
	local $SIG{__WARN__} = sub {};
	lives_ok { $res = $r->resolve(component => 'X', place => 'X') }
		'single char place lives';
	_check_invariants($res, 'single char place');
};

subtest 'resolve() - very long component (1000 chars)' => sub {
	my $r    = _resolver();
	my $long = 'A' x 1000;
	my $res;
	local $SIG{__WARN__} = sub {};
	lives_ok { $res = $r->resolve(component => $long, place => "Somewhere, $long") }
		'1000-char component lives';
	_check_invariants($res, '1000-char component');
	is $res->{unknown}, 1, 'unknown == 1 for nonsense long component';
};

subtest 'resolve() - very long place (10_000 chars)' => sub {
	my $r    = _resolver();
	my $long = ('A, ' x 3333) . 'England';
	my $res;
	lives_ok { $res = $r->resolve(component => 'England', place => $long) }
		'10k-char place lives';
	is $res->{country}, 'United Kingdom', 'correct country despite huge place';
};

subtest 'resolve() - component is all whitespace-like Unicode spaces' => sub {
	# Params::Validate::Strict requires min=>1, so a string of Unicode
	# spaces satisfies length>0 but has no printable content.
	my $r               = _resolver();
	my $space_component = "\x{00A0}\x{2003}\x{3000}";  # NBSP, EM SPACE, IDEOGRAPHIC SPACE
	my $res;
	local $SIG{__WARN__} = sub {};
	lives_ok {
		$res = $r->resolve(
			component => $space_component,
			place     => "Somewhere, $space_component",
		);
	} 'Unicode-space component lives';
	_check_invariants($res, 'unicode space component');
};

subtest 'resolve() - component with embedded newlines' => sub {
	my $r = _resolver();
	my $res;
	local $SIG{__WARN__} = sub {};
	lives_ok { $res = $r->resolve(component => "Eng\nland", place => "London, Eng\nland") }
		'newline-embedded component lives';
	_check_invariants($res, 'newline component');
};

subtest 'resolve() - component with null bytes' => sub {
	my $r = _resolver();
	my $res;
	local $SIG{__WARN__} = sub {};
	lives_ok { $res = $r->resolve(component => "Eng\x00land", place => "London, Eng\x00land") }
		'null-byte component lives';
	_check_invariants($res, 'null byte component');
};

subtest 'resolve() - component consisting entirely of punctuation' => sub {
	my $r = _resolver();
	my $res;
	local $SIG{__WARN__} = sub {};
	lives_ok { $res = $r->resolve(component => '!!!---???', place => 'Somewhere, !!!---???') }
		'punctuation-only component lives';
	_check_invariants($res, 'punctuation component');
	is $res->{unknown}, 1, 'punctuation resolves to unknown';
};

subtest 'resolve() - component is a number' => sub {
	my $r = _resolver();
	my $res;
	local $SIG{__WARN__} = sub {};
	lives_ok { $res = $r->resolve(component => '12345', place => 'Somewhere, 12345') }
		'numeric component lives';
	_check_invariants($res, 'numeric component');
};

subtest 'resolve() - component is a floating point number' => sub {
	my $r = _resolver();
	my $res;
	local $SIG{__WARN__} = sub {};
	lives_ok { $res = $r->resolve(component => '51.5', place => 'Somewhere, 51.5') }
		'float component lives';
	_check_invariants($res, 'float component');
};

subtest 'resolve() - place equals component (degenerate address)' => sub {
	my $r = _resolver();
	my $res;
	lives_ok { $res = $r->resolve(component => 'England', place => 'England') }
		'place == component lives';
	is $res->{country}, 'United Kingdom', 'degenerate address resolves correctly';
	is $res->{place},   'England',        'place returned unchanged';
};

subtest 'resolve() - component with leading/trailing whitespace' => sub {
	my $r = _resolver();
	my $res;
	local $SIG{__WARN__} = sub {};
	lives_ok { $res = $r->resolve(component => '  England  ', place => 'London,   England  ') }
		'whitespace-padded component lives';
	_check_invariants($res, 'whitespace-padded component');
	# May or may not resolve — important thing is no death and valid structure
};

subtest 'resolve() - component with internal repeated commas' => sub {
	my $r = _resolver();
	my $res;
	local $SIG{__WARN__} = sub {};
	lives_ok { $res = $r->resolve(component => 'Eng,,land', place => 'London,,,,England') }
		'comma-laden component lives';
	_check_invariants($res, 'comma component');
};

subtest 'resolve() - Unicode right-to-left text in component' => sub {
	my $r = _resolver();
	my $res;
	local $SIG{__WARN__} = sub {};
	# Arabic script
	lives_ok {
		$res = $r->resolve(
			component => "\x{0625}\x{0646}\x{062C}\x{0644}\x{062A}\x{0631}\x{0627}",
			place     => "London, \x{0625}\x{0646}\x{062C}\x{0644}\x{062A}\x{0631}\x{0627}",
		);
	} 'RTL Unicode component lives';
	_check_invariants($res, 'RTL component');
};

subtest 'resolve() - component is valid Perl that could be eval-ed (injection probe)' => sub {
	my $r = _resolver();
	my $res;
	local $SIG{__WARN__} = sub {};
	lives_ok {
		$res = $r->resolve(
			component => 'die("pwned")',
			place     => 'Somewhere, die("pwned")',
		);
	} 'code-injection string in component lives';
	_check_invariants($res, 'injection component');
	is $res->{unknown}, 1, 'code string does not resolve to a country';
};

subtest 'resolve() - component is a regex metacharacter string' => sub {
	my $r = _resolver();
	my $res;
	local $SIG{__WARN__} = sub {};
	lives_ok {
		$res = $r->resolve(
			component => '.*+?[]{}()|^$\\',
			place     => 'Somewhere, .*+?[]{}()|^$\\',
		);
	} 'regex metachar component lives';
	_check_invariants($res, 'regex metachar component');
};

# ---------------------------------------------------------------------------
# 3. Boundary conditions on place string mutation
# ---------------------------------------------------------------------------

subtest 'place suffix: already ends with USA — not appended again' => sub {
	my $r   = _resolver();
	my $res = $r->resolve(component => 'TX', place => 'Houston, TX, USA');
	unlike $res->{place}, qr/USA.*USA/s, 'USA not duplicated';
	like   $res->{place}, qr/USA$/,      'USA still at end';
};

subtest 'place suffix: ends with USA in different case — not appended again' => sub {
	my $r   = _resolver();
	my $res = $r->resolve(component => 'TX', place => 'Houston, TX, usa');
	unlike $res->{place}, qr/USA.*USA/si, 'not double-appended';
};

subtest 'place suffix: suffix separated by multiple spaces' => sub {
	my $r   = _resolver();
	my $res = $r->resolve(component => 'TX', place => 'Houston, TX,   USA');
	unlike $res->{place}, qr/USA.*USA/si, 'not double-appended with internal spaces';
};

subtest 'place suffix: place is just the component with no commas' => sub {
	my $r   = _resolver();
	my $res = $r->resolve(component => 'TX', place => 'TX');
	like $res->{place}, qr/USA$/, 'USA appended to bare component place';
};

subtest 'place suffix: Canada already present case-insensitively' => sub {
	my $r   = _resolver();
	my $res = $r->resolve(component => 'ON', place => 'Toronto, ON, CANADA');
	unlike $res->{place}, qr/Canada.*Canada/si, 'Canada not double-appended';
};

subtest 'place suffix: extremely long place already containing suffix' => sub {
	my $r    = _resolver();
	my $long = ('City, ' x 500) . 'TX, USA';
	my $res  = $r->resolve(component => 'TX', place => $long);
	unlike $res->{place}, qr/USA.*USA/s, 'USA not appended to already-suffixed long place';
};

# ---------------------------------------------------------------------------
# 4. Ambiguous two-letter codes
# ---------------------------------------------------------------------------

subtest 'ambiguous code: WA could be Washington (US) or Western Australia' => sub {
	# WA appears in both the US and AU lookup tables.  The module must
	# resolve it consistently to one country without dying.
	my $r   = _resolver();
	my $res = $r->resolve(component => 'WA', place => 'City, WA');
	_check_invariants($res, 'WA ambiguous');
	ok $res->{country} =~ /^(?:United States|Australia)$/,
		'WA resolves to US or AU, got: ' . ($res->{country} // 'undef');
};

subtest 'ambiguous code: CA could be California (US) or Canada' => sub {
	my $r   = _resolver();
	my $res = $r->resolve(component => 'CA', place => 'City, CA');
	_check_invariants($res, 'CA ambiguous');
	ok $res->{country} =~ /^(?:United States|Canada)$/,
		'CA resolves to US or Canada, got: ' . ($res->{country} // 'undef');
};

subtest 'ambiguous code: same code resolved twice gives same answer' => sub {
	my $r    = _resolver();
	my $res1 = $r->resolve(component => 'WA', place => 'City, WA');
	my $res2 = $r->resolve(component => 'WA', place => 'City, WA');
	is $res1->{country}, $res2->{country},
		'same ambiguous code resolved identically on repeated calls';
};

# ---------------------------------------------------------------------------
# 5. GeoNames stub edge cases — exercising the _geonames_lookup path with
#    pathological return values
# ---------------------------------------------------------------------------

{
	# Shared stub builder for GeoNames edge case subtests.
	# Uses a random package name to avoid redefinition warnings across calls.
	sub _resolver_with_geonames {
		my ($search_sub) = @_;
		my $pkg = 'Edge::GN::' . int(rand(2**31));
		{
			no strict 'refs';
			*{"${pkg}::new"}    = sub { shift };
			*{"${pkg}::search"} = $search_sub;
		}
		my $gn = bless {}, $pkg;
		return Geo::Address::Parser::Country->new({
			us       => _make_us(),
			ca_en    => _make_ca_en(),
			ca_fr    => _make_ca_fr(),
			au       => _make_au(),
			geonames => $gn,
		});
	}
}

subtest 'GeoNames: returns undef — does not die' => sub {
	my $r = _resolver_with_geonames(sub { return undef });
	my $res;
	local $SIG{__WARN__} = sub {};
	lives_ok { $res = $r->resolve(component => 'Xyzzy', place => 'Nowhere, Xyzzy') }
		'undef from GeoNames search lives';
	_check_invariants($res, 'GeoNames undef');
	is $res->{unknown}, 1, 'unknown == 1 when GeoNames returns undef';
};

subtest 'GeoNames: returns empty arrayref — does not die' => sub {
	my $r = _resolver_with_geonames(sub { return [] });
	my $res;
	local $SIG{__WARN__} = sub {};
	lives_ok { $res = $r->resolve(component => 'Xyzzy', place => 'Nowhere, Xyzzy') }
		'empty arrayref from GeoNames lives';
	is $res->{unknown}, 1, 'unknown == 1';
};

subtest 'GeoNames: returns arrayref of undefs — does not die' => sub {
	my $r = _resolver_with_geonames(sub { return [ undef, undef ] });
	my $res;
	local $SIG{__WARN__} = sub {};
	lives_ok { $res = $r->resolve(component => 'Xyzzy', place => 'Nowhere, Xyzzy') }
		'arrayref of undefs from GeoNames lives';
	_check_invariants($res, 'GeoNames undef elements');
};

subtest 'GeoNames: returns result with no countryName key — does not die' => sub {
	my $r = _resolver_with_geonames(sub {
		return [ { name => 'Somewhere', lat => 0, lng => 0 } ];
	});
	my $res;
	local $SIG{__WARN__} = sub {};
	lives_ok { $res = $r->resolve(component => 'Xyzzy', place => 'Nowhere, Xyzzy') }
		'result without countryName lives';
	is $res->{unknown}, 1, 'unknown == 1 when countryName absent';
};

subtest 'GeoNames: returns result with undef countryName — does not die' => sub {
	my $r = _resolver_with_geonames(sub { return [ { countryName => undef } ] });
	my $res;
	local $SIG{__WARN__} = sub {};
	lives_ok { $res = $r->resolve(component => 'Xyzzy', place => 'Nowhere, Xyzzy') }
		'undef countryName lives';
	is $res->{unknown}, 1, 'unknown == 1 when countryName is undef';
};

subtest 'GeoNames: returns result with empty-string countryName — does not die' => sub {
	my $r = _resolver_with_geonames(sub { return [ { countryName => '' } ] });
	my $res;
	local $SIG{__WARN__} = sub {};
	lives_ok { $res = $r->resolve(component => 'Xyzzy', place => 'Nowhere, Xyzzy') }
		'empty countryName lives';
	_check_invariants($res, 'GeoNames empty countryName');
};

subtest 'GeoNames: search sub dies — exception does not escape resolve()' => sub {
	my $r = _resolver_with_geonames(sub { die "network timeout\n" });
	# If the module catches the die, resolve() should return a valid result.
	# If it propagates, dies_ok is the correct assertion.
	# Either is acceptable — silent wrong answers are not.
	local $SIG{__WARN__} = sub {};
	eval {
		my $res = $r->resolve(component => 'Xyzzy', place => 'Nowhere, Xyzzy');
		_check_invariants($res, 'GeoNames die caught');
		pass 'exception from GeoNames search caught by resolve()';
	};
	if($@) {
		like $@, qr/network timeout/, 'exception from GeoNames propagated cleanly';
	}
};

subtest 'GeoNames: search sub returns a non-ref scalar — module bug causes die' => sub {
	# _geonames_lookup does: ref($result) eq 'ARRAY' ? $result->[0] : $result
	# A plain scalar passes through as $result, then $result->{countryName}
	# tries to dereference a string as a hashref under strict refs — fatal.
	# Fix needed: ref() guard before hash deref in _geonames_lookup.
	my $r = _resolver_with_geonames(sub { return 'oops' });
	local $SIG{__WARN__} = sub {};
	TODO: {
		local $TODO = 'scalar from GeoNames search causes strict-refs die — needs ref() guard in _geonames_lookup';
		my $res;
		lives_ok { $res = $r->resolve(component => 'Xyzzy', place => 'Nowhere, Xyzzy') }
			'scalar return from GeoNames lives';
		_check_invariants($res, 'GeoNames scalar return') if defined $res;
	}
};

subtest 'GeoNames: search sub returns a deeply nested structure — module bug causes die' => sub {
	# _geonames_lookup returns $result->{countryName} without checking ref().
	# A hashref countryName then fails Return::Set schema (country must be string).
	# Fix needed: !ref($country) guard before return in _geonames_lookup.
	my $r = _resolver_with_geonames(sub {
		return [ { countryName => { nested => 'oops' } } ];
	});
	local $SIG{__WARN__} = sub {};
	TODO: {
		local $TODO = 'hashref countryName causes Return::Set validation die — needs !ref() guard in _geonames_lookup';
		my $res;
		lives_ok { $res = $r->resolve(component => 'Xyzzy', place => 'Nowhere, Xyzzy') }
			'nested countryName hashref lives';
		_check_invariants($res, 'GeoNames nested countryName') if defined $res;
	}
};

# ---------------------------------------------------------------------------
# 6. Locale stub pathological return values
# ---------------------------------------------------------------------------

subtest 'locale stub: code2state returns undef for a key — does not die' => sub {
	my $broken_us = bless {
		code2state => { TX => undef },
		state2code => {},
	}, 'Edge::Broken::US';

	my $r = Geo::Address::Parser::Country->new({
		us    => $broken_us,
		ca_en => _make_ca_en(),
		ca_fr => _make_ca_fr(),
		au    => _make_au(),
	});
	my $res;
	local $SIG{__WARN__} = sub {};
	lives_ok { $res = $r->resolve(component => 'TX', place => 'Dallas, TX') }
		'undef in code2state lives';
	_check_invariants($res, 'broken US stub');
};

subtest 'locale stub: completely empty locale objects — does not die' => sub {
	my $empty_us = bless { code2state    => {}, state2code    => {} }, 'Edge::Empty::US';
	my $empty_ca = bless { code2province => {}, province2code => {} }, 'Edge::Empty::CA';
	my $empty_au = bless { code2state    => {}, state2code    => {} }, 'Edge::Empty::AU';

	my $r = Geo::Address::Parser::Country->new({
		us    => $empty_us,
		ca_en => $empty_ca,
		ca_fr => $empty_ca,
		au    => $empty_au,
	});

	# England is in %DIRECT so it must still resolve regardless of locale
	my $res = $r->resolve(component => 'England', place => 'London, England');
	is $res->{country}, 'United Kingdom',
		'DIRECT table still works with empty locale stubs';

	# TX should fall through to unknown since locale tables are empty
	local $SIG{__WARN__} = sub {};
	my $res2 = $r->resolve(component => 'TX', place => 'Dallas, TX');
	_check_invariants($res2, 'TX with empty locale');
};

# ---------------------------------------------------------------------------
# 7. High-volume / stress: resolver survives many sequential calls
# ---------------------------------------------------------------------------

subtest 'stress: 500 sequential resolve() calls without memory corruption' => sub {
	my $r      = _resolver();
	my @inputs = (
		[ 'England',     'London, England'     ],
		[ 'TX',          'Houston, TX'         ],
		[ 'France',      'Paris, France'       ],
		[ 'ON',          'Toronto, ON'         ],
		[ 'NSW',         'Sydney, NSW'         ],
		[ 'Xyzzy',       'Nowhere, Xyzzy'      ],
		[ 'Deutschland', 'Berlin, Deutschland' ],
		[ 'Scotland',    'Glasgow, Scotland'   ],
	);

	my $failures = 0;
	for my $i (1..500) {
		my $pair = $inputs[$i % scalar @inputs];
		local $SIG{__WARN__} = sub {};
		my $res = eval { $r->resolve(component => $pair->[0], place => $pair->[1]) };
		if($@ || !ref($res) || ref($res) ne 'HASH' || !exists $res->{unknown}) {
			$failures++;
		}
	}
	is $failures, 0, '500 calls: no structural failures';
};

subtest 'stress: resolver result is identical on call 1 and call 500 for same input' => sub {
	my $r = _resolver();

	my $first = $r->resolve(component => 'England', place => 'London, England');

	# Interleave with other calls to exercise any caching / state
	for my $i (1..498) {
		local $SIG{__WARN__} = sub {};
		$r->resolve(component => 'TX', place => 'Dallas, TX');
	}

	my $last = $r->resolve(component => 'England', place => 'London, England');

	is $last->{country},  $first->{country},  'country identical after 500 interleaved calls';
	is $last->{unknown},  $first->{unknown},  'unknown identical';
	is_deeply $last->{warnings}, $first->{warnings}, 'warnings identical';
};

# ---------------------------------------------------------------------------
# 8. Return value immutability — caller mutating the result must not affect
#    subsequent calls
# ---------------------------------------------------------------------------

subtest 'mutating returned warnings arrayref does not affect next call' => sub {
	my $r = _resolver();

	my $res1 = $r->resolve(component => 'TX', place => 'Houston, TX');
	push @{ $res1->{warnings} }, 'injected warning';

	my $res2 = $r->resolve(component => 'TX', place => 'Houston, TX');
	ok !grep { $_ eq 'injected warning' } @{ $res2->{warnings} },
		'injected warning not present in subsequent call';
};

subtest 'mutating returned place string does not affect next call' => sub {
	my $r = _resolver();

	my $res1 = $r->resolve(component => 'England', place => 'London, England');
	$res1->{place} = 'CORRUPTED';

	my $res2 = $r->resolve(component => 'England', place => 'London, England');
	isnt $res2->{place}, 'CORRUPTED', 'place not corrupted in subsequent call';
	is   $res2->{country}, 'United Kingdom', 'resolution still correct';
};

subtest 'mutating returned country string does not affect next call' => sub {
	my $r = _resolver();

	my $res1 = $r->resolve(component => 'England', place => 'London, England');
	$res1->{country} = 'CORRUPTED';

	my $res2 = $r->resolve(component => 'England', place => 'London, England');
	is $res2->{country}, 'United Kingdom', 'country not corrupted in subsequent call';
};

done_testing();

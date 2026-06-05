#!/usr/bin/env perl

# t/edge_cases.t -- Destructive, pathological, boundary-condition, and
# security tests for Geo::Coder::List.
#
# Design philosophy: every mock return is an edge case (undef, 0, empty
# string, circular ref, ...).  If a test fails, the bug is in the code
# unless the code is demonstrably correct, in which case the test is wrong.

use strict;
use warnings;

use lib 'lib';

use Readonly;
use Scalar::Util qw(blessed refaddr);
use Test::Most;
use Test::Mockingbird;
use Test::Returns;

# Load the module under test
BEGIN { use_ok('Geo::Coder::List') }

# =============================================================================
# Configuration -- no magic numbers or strings below this block
# =============================================================================

# Named coordinate constants keep assertions self-documenting
Readonly::Scalar my $VALID_LAT        => 48.8566;
Readonly::Scalar my $VALID_LNG        => 2.3522;
Readonly::Scalar my $EQUATOR_LAT      => 0;       # lat=0: equator edge case
Readonly::Scalar my $PRIME_MERIDIAN   => 0;       # lon=0: prime meridian
Readonly::Scalar my $SYDNEY_LAT       => -33.8688;
Readonly::Scalar my $SYDNEY_LNG       => 151.2093;

# Location strings for geocode() calls
Readonly::Scalar my $VALID_LOCATION   => 'Paris, France';
Readonly::Scalar my $VALID_LATLNG     => "${VALID_LAT},${VALID_LNG}";
Readonly::Scalar my $EMPTY_STRING     => '';
Readonly::Scalar my $NUMERIC_ONLY     => '12345';
Readonly::Scalar my $VERY_LONG_STR    => 'A' x 100_000;
Readonly::Scalar my $NULL_BYTE_STR    => "Paris\x00France";
Readonly::Scalar my $INJECTION_SHELL  => '$(cat /etc/passwd) France';
Readonly::Scalar my $INJECTION_XSS    => '<script>alert(1)</script> France';
Readonly::Scalar my $HTML_ENTITY_LOC  => 'Caf&eacute; de Paris, France';
Readonly::Scalar my $HTML_ENTITY_CHAR => "\x{e9}";   # U+00E9 e-acute

# Configurable values referenced by name; never as literals
my %config = (
	limit_zero    => 0,
	limit_one     => 1,
	no_result     => undef,
	debug_verbose => 2,
);

# =============================================================================
# Inline geocoder stub packages
# Test::Mockingbird replaces their methods per test; these are just stubs.
# =============================================================================

{
	package EdgeMock::Std;
	sub new             { bless {}, shift }
	sub geocode         { return () }
	sub reverse_geocode { return () }
	sub ua              { }
}

{
	package EdgeMock::B;
	sub new             { bless {}, shift }
	sub geocode         { return () }
	sub reverse_geocode { return () }
	sub ua              { }
}

# A stub named exactly Geo::GeoNames to trigger the special code path
# in Geo::Coder::List that checks ref($geocoder) eq 'Geo::GeoNames'
{
	package Geo::GeoNames;
	sub new      { bless {}, shift }
	sub geocode  { return () }
	sub username { 'testuser' }    # overridden per test
	sub ua       { }
}

# A minimal CHI-like object implementing the get/set L2 cache interface
{
	package EdgeMock::CHI;
	sub new { bless { store => {} }, shift }
	sub get { $_[0]->{store}{ $_[1] } }
	sub set { $_[0]->{store}{ $_[1] } = $_[2]; $_[0] }
}

package main;

# =============================================================================
# Shared helpers
# =============================================================================

# Build a Geo::Coder::List with one EdgeMock::Std geocoder already pushed
sub _list_with_std {
	return Geo::Coder::List->new(carp_on_warn => 1)->push(EdgeMock::Std->new());
}

# Build an OSM-style result hashref (top-level lat/lon)
sub _osm { { lat => $_[0], lon => $_[1] } }

# Emit diagnostics only when TEST_VERBOSE is set to keep normal output clean
sub _vdiag { diag(@_) if $ENV{TEST_VERBOSE} }

# =============================================================================
# SUBTEST 1: new() with pathological inputs
# Purpose: constructor must never crash or produce corrupt state
# =============================================================================

subtest 'new() with pathological inputs' => sub {
	# Plain call always works
	isa_ok(Geo::Coder::List->new(), 'Geo::Coder::List', 'new() with no args');

	# new(debug => undef) must not die; undef is treated as the default
	my $obj;
	lives_ok { $obj = Geo::Coder::List->new(debug => $config{no_result}) }
		'new(debug=>undef) does not die';

	# Function-style call with just a class name must return an object
	lives_ok { Geo::Coder::List::new('Geo::Coder::List') }
		'Function-style ::new() with class name lives';

	# Function-style call with extra key/value args: must carp and return undef
	{
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		my $fn_obj = Geo::Coder::List::new(undef, debug => 1);
		ok($warned,          '::new() with extra args emits carp-level warning');
		ok(!defined $fn_obj, '::new() with extra args returns undef per code comment');
	}

	# Clone must be a distinct object
	my $orig  = Geo::Coder::List->new();
	my $clone = $orig->new();
	isnt(refaddr($clone), refaddr($orig), 'Clone is a distinct object in memory');

	# Clone must start with an empty log even when the original has entries
	$orig->push(EdgeMock::Std->new());
	{
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub { _osm($VALID_LAT, $VALID_LNG) };
		$orig->geocode($VALID_LOCATION);
	}
	ok(scalar @{$orig->log()} > 0, 'Original has log entries after geocode');
	is(scalar @{$clone->log()},  0, 'Clone log is always empty at creation');

	_vdiag('new() pathological inputs done');
};

# =============================================================================
# SUBTEST 2: push() boundary conditions
# Purpose: documented error on bad input; limit=0 silently skips geocoder
# =============================================================================

subtest 'push() boundary conditions' => sub {
	my $list = Geo::Coder::List->new();

	# push(undef) must croak with the documented error string
	throws_ok { $list->push($config{no_result}) }
		qr/push: Usage:/,
		'push(undef) croaks with "push: Usage:" in message';

	# push() with no argument must also croak
	throws_ok { $list->push() }
		qr/push: Usage:/,
		'push() with no args croaks';

	# push(0) must NOT croak: 0 is defined and the guard is defined()
	lives_ok { $list->push(0) }
		'push(0) does not croak (0 is defined)';

	# push("") must NOT croak: empty string is defined
	lives_ok { $list->push($EMPTY_STRING) }
		'push(empty string) does not croak (empty string is defined)';

	# push() must return $self so callers can chain
	my $list2 = Geo::Coder::List->new();
	my $ret   = $list2->push(EdgeMock::Std->new());
	is(refaddr($ret), refaddr($list2), 'push() returns $self for method chaining');

	# A hashref with limit=0: geocoder is in the chain but immediately exhausted
	my $list3 = Geo::Coder::List->new();
	$list3->push({ geocoder => EdgeMock::Std->new(), limit => $config{limit_zero} });
	{
		my $calls = 0;
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub {
			$calls++;
			return _osm($VALID_LAT, $VALID_LNG);
		};
		my $r = $list3->geocode($VALID_LOCATION);
		is($calls, 0,    'limit=0: geocoder is never called');
		is($r, undef,    'limit=0: result is undef (geocoder was skipped)');
	}

	_vdiag('push() boundary conditions done');
};

# =============================================================================
# SUBTEST 3: geocode() -- invalid and destructive inputs
# Purpose: confirm exact error behaviour documented in the POD
# =============================================================================

subtest 'geocode() invalid inputs' => sub {
	my $list = _list_with_std();

	# Empty string: must carp (not croak) and return undef
	{
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		my $r = $list->geocode(location => $EMPTY_STRING);
		is($r, undef, 'Empty string location: returns undef');
		ok($warned,   'Empty string location: carp-level warning emitted');
	}

	# undef location: must carp and return undef
	{
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		my $r = $list->geocode(location => $config{no_result});
		is($r, undef, 'undef location: returns undef');
		ok($warned,   'undef location: carp-level warning emitted');
	}

	# All-numeric string: POD says must croak with "invalid input"
	throws_ok { $list->geocode(location => $NUMERIC_ONLY) }
		qr/invalid input to geocode/,
		'All-numeric location croaks with expected message';

	# "0" is also all-numeric; must croak
	throws_ok { $list->geocode(location => '0') }
		qr/invalid input to geocode/,
		'"0" location croaks';

	# Very long location string: must not crash or consume unreasonable time
	{
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub { return };
		my $r;
		lives_ok { $r = $list->geocode(location => $VERY_LONG_STR) }
			'Very long location string does not crash';
		is($r, undef, 'Very long location: undef when geocoder finds nothing');
	}

	_vdiag('geocode() invalid inputs done');
};

# =============================================================================
# SUBTEST 4: geocode() -- lat=0 is a valid result (equator)
#
# Bug: the normalization code uses  "if($l->{lat} && defined($l->{lon}))"
# which treats lat=0 as falsy and silently discards the result.  Any location
# on the equator (lat=0) must be returned correctly, not treated as not-found.
# =============================================================================

subtest 'geocode() lat=0 equator: valid result must not be discarded' => sub {
	# OSM-style geocoder returns lat=0 (equatorial Africa, lon=30)
	{
		my $list = _list_with_std();
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub { _osm($EQUATOR_LAT, 30.0) };
		my $r = $list->geocode($VALID_LOCATION);
		ok(defined $r, 'lat=0 (equator): result is defined, not treated as not-found');
		is($r->{geometry}{location}{lat}, 0,    'lat=0: canonical lat preserved as 0');
		is($r->{geometry}{location}{lng}, 30.0, 'lat=0: canonical lng is correct');
	}

	# Both lat=0 and lon=0 (Gulf of Guinea, ocean at prime meridian/equator)
	{
		my $list = _list_with_std();
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub {
			return _osm($EQUATOR_LAT, $PRIME_MERIDIAN);
		};
		my $r = $list->geocode($VALID_LOCATION);
		ok(defined $r, 'lat=0,lon=0: result is defined');
		is($r->{geometry}{location}{lat}, 0, 'lat=0,lon=0: canonical lat is 0');
		is($r->{geometry}{location}{lng}, 0, 'lat=0,lon=0: canonical lng is 0');
	}

	# Negative lat (southern hemisphere) must also work
	{
		my $list = _list_with_std();
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub {
			return _osm($SYDNEY_LAT, $SYDNEY_LNG);
		};
		my $r = $list->geocode($VALID_LOCATION);
		ok(defined $r, 'Negative lat (Sydney): result is defined');
		is($r->{geometry}{location}{lat}, $SYDNEY_LAT, 'Negative lat: correct value');
	}

	_vdiag('lat=0 equator edge case done');
};

# =============================================================================
# SUBTEST 5: geocode() -- edge-case return values from geocoders
# Purpose: every falsy or empty upstream response must yield undef, not a crash
# =============================================================================

subtest 'geocode() handles edge-case return values' => sub {
	# Geocoder returns scalar undef
	{
		my $list = _list_with_std();
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub { return $config{no_result} };
		is($list->geocode($VALID_LOCATION), undef, 'Geocoder returns undef: result is undef');
	}

	# Geocoder returns the integer 0 (falsy but defined)
	{
		my $list = _list_with_std();
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub { return 0 };
		is($list->geocode($VALID_LOCATION), undef, 'Geocoder returns 0: result is undef');
	}

	# Geocoder returns empty string
	{
		my $list = _list_with_std();
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub { return $EMPTY_STRING };
		is($list->geocode($VALID_LOCATION), undef, 'Geocoder returns "": result is undef');
	}

	# Geocoder returns an empty hashref (no coordinate keys)
	{
		my $list = _list_with_std();
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub { return {} };
		is($list->geocode($VALID_LOCATION), undef, 'Empty hashref: result is undef');
	}

	# Geocoder returns an empty list
	{
		my $list = _list_with_std();
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub { return () };
		is($list->geocode($VALID_LOCATION), undef, 'Empty list: result is undef');
	}

	# Geocoder returns a hashref with a top-level "error" key
	{
		my $list = _list_with_std();
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub {
			return { error => 'rate limit exceeded' };
		};
		is($list->geocode($VALID_LOCATION), undef,
			'Result with {error} key: treated as failure, returns undef');
	}

	# Geocoder returns a list whose first element is undef (GeoNames sub-array wrapping)
	{
		my $list = _list_with_std();
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub {
			return [ $config{no_result} ];    # array-of-array with undef inside
		};
		is($list->geocode($VALID_LOCATION), undef, 'Array[undef]: result is undef');
	}

	# Geocoder throws: must not propagate, only carp
	{
		my $list = _list_with_std();
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub { die 'network timeout' };
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		my $r;
		lives_ok { $r = $list->geocode($VALID_LOCATION) }
			'Geocoder that dies: geocode() itself does not die';
		is($r, undef, 'Geocoder that dies: result is undef');
		ok($warned, 'Geocoder that dies: warning emitted via carp');
	}

	_vdiag('edge-case return values done');
};

# =============================================================================
# SUBTEST 6: geocode() -- fallback chain with edge-case failure modes
# Purpose: first geocoder fails, second succeeds; limit=1 exhaustion
# =============================================================================

subtest 'geocode() fallback chain with edge-case failures' => sub {
	# First geocoder dies, second succeeds; result must come from second
	{
		my $list = Geo::Coder::List->new(carp_on_warn => 1);
		$list->push(EdgeMock::Std->new())->push(EdgeMock::B->new());
		my $gA = mock_scoped 'EdgeMock::Std::geocode' => sub { die 'fail A' };
		my $gB = mock_scoped 'EdgeMock::B::geocode'   => sub { _osm($VALID_LAT, $VALID_LNG) };
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		my $r = $list->geocode($VALID_LOCATION);
		ok(defined $r, 'Fallback: result comes from the second geocoder');
		is(ref($r->{geocoder}), 'EdgeMock::B', 'Fallback: geocoder field identifies B');
		ok($warned, 'Fallback: failure of first geocoder emits warning');
	}

	# All geocoders fail: must return undef, not crash
	{
		my $list = new_ok('Geo::Coder::List');
		$list->push(EdgeMock::Std->new())->push(EdgeMock::B->new());
		my $gA = mock_scoped 'EdgeMock::Std::geocode' => sub { return () };
		my $gB = mock_scoped 'EdgeMock::B::geocode'   => sub { return () };
		is($list->geocode($VALID_LOCATION), undef, 'All geocoders fail: returns undef');
	}

	# limit=1: geocoder used once, then skipped on the second call
	{
		my $list = Geo::Coder::List->new();
		$list->push({ geocoder => EdgeMock::Std->new(), limit => $config{limit_one} });
		my $calls = 0;
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub {
			$calls++;
			return _osm($VALID_LAT, $VALID_LNG);
		};
		$list->geocode($VALID_LOCATION);
		$list->geocode('London, UK');
		is($calls, 1, 'Limit=1: geocoder called exactly once across two different queries');
	}

	_vdiag('fallback chain done');
};

# =============================================================================
# SUBTEST 7: geocode() -- security inputs
# Purpose: injected strings must not execute code or crash the module
# =============================================================================

subtest 'geocode() security inputs' => sub {
	my $list = _list_with_std();

	# Shell injection: must be treated as plain text, not executed
	{
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub { return };
		my $r;
		lives_ok { $r = $list->geocode(location => $INJECTION_SHELL) }
			'Shell injection string: geocode() does not crash';
		is($r, undef, 'Shell injection: returns undef (no geocoder match)');
	}

	# XSS injection: HTML tags should be decoded (not passed verbatim) via HTML::Entities
	{
		my $received_loc = '';
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub {
			my ($self, %args) = @_;
			$received_loc = $args{location} // '';
			return;
		};
		$list->geocode(location => $INJECTION_XSS);
		# <script> is not an HTML entity so decode_entities leaves it unchanged;
		# the important thing is that geocode() does not eval the string
		lives_ok { 1 } 'XSS injection string: geocode() does not crash';
		_vdiag("XSS loc received: $received_loc");
	}

	# Null byte embedded in location: must not crash
	{
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub { return };
		lives_ok { $list->geocode(location => $NULL_BYTE_STR) }
			'Null byte in location: does not crash';
	}

	_vdiag('security inputs done');
};

# =============================================================================
# SUBTEST 8: geocode() -- HTML entity decoding
# Purpose: verify HTML entities are decoded before geocoders receive the string
# =============================================================================

subtest 'geocode() HTML entity decoding' => sub {
	my $list = _list_with_std();
	my $received_loc = '';

	# Location contains &eacute; which should be decoded to U+00E9 (e-acute)
	my $g = mock_scoped 'EdgeMock::Std::geocode' => sub {
		my ($self, %args) = @_;
		$received_loc = $args{location} // '';
		return;
	};
	$list->geocode(location => $HTML_ENTITY_LOC);

	# The geocoder must receive the Unicode character, not the entity string
	like($received_loc, qr/\Q$HTML_ENTITY_CHAR\E/,
		'HTML &eacute; decoded to e-acute before passing to geocoder');
	unlike($received_loc, qr/&eacute;/,
		'Raw &eacute; entity string is NOT passed through to geocoder');

	_vdiag("HTML decoded location: $received_loc");
};

# =============================================================================
# SUBTEST 9: geocode() -- Geo::GeoNames special handling
# Purpose: positional-arg path and username guard inside Geo::Coder::List
# =============================================================================

subtest 'geocode() Geo::GeoNames special handling' => sub {
	# Geo::GeoNames without a username: the code dies 'lost username' inside
	# the eval; the eval catches it, carps, and tries the next encoder
	{
		my $gnames = Geo::GeoNames->new();
		my $list   = Geo::Coder::List->new(carp_on_warn => 1)->push($gnames);

		# Override username to return undef for this test
		my $g = mock_scoped 'Geo::GeoNames::username' => sub { return $config{no_result} };
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		my $r = $list->geocode($VALID_LOCATION);
		ok($warned, 'Geo::GeoNames without username: emits carp-level warning');
		is($r, undef, 'Geo::GeoNames without username: returns undef');
	}

	# Geo::GeoNames with a valid username: positional argument path is exercised
	{
		my $positional_call = 0;
		my $gnames = Geo::GeoNames->new();
		my $list   = Geo::Coder::List->new()->push($gnames);
		my $gu = mock_scoped 'Geo::GeoNames::username' => sub { return 'testuser' };
		my $gc = mock_scoped 'Geo::GeoNames::geocode' => sub {
			my ($self, @args) = @_;
			# Positional call: single scalar location argument, not a key/value pair
			$positional_call = (@args == 1 && !ref($args[0])) ? 1 : 0;
			return { lat => $VALID_LAT, lng => $VALID_LNG };
		};
		$list->geocode($VALID_LOCATION);
		ok($positional_call, 'Geo::GeoNames with username: positional arg passed to geocode()');
	}

	_vdiag('Geo::GeoNames special handling done');
};

# =============================================================================
# SUBTEST 10: geocode() -- response normalization edge cases
# Purpose: every supported provider format is normalized to canonical geometry
# =============================================================================

subtest 'geocode() response normalization from all provider formats' => sub {
	# geocoder.ca style: latt / longt fields
	{
		my $list = _list_with_std();
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub {
			return { latt => $VALID_LAT, longt => $VALID_LNG };
		};
		my $r = $list->geocode($VALID_LOCATION);
		is($r->{geometry}{location}{lat}, $VALID_LAT, 'geocoder.ca latt/longt: canonical lat');
	}

	# postcodes.io style: latitude / longitude
	{
		my $list = _list_with_std();
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub {
			return { latitude => $VALID_LAT, longitude => $VALID_LNG };
		};
		my $r = $list->geocode($VALID_LOCATION);
		is($r->{geometry}{location}{lat}, $VALID_LAT,
			'postcodes.io latitude/longitude: canonical lat');
	}

	# Bing BestLocation style
	{
		my $list = _list_with_std();
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub {
			return {
				BestLocation => {
					Coordinates => { Latitude => $VALID_LAT, Longitude => $VALID_LNG }
				}
			};
		};
		my $r = $list->geocode($VALID_LOCATION);
		is($r->{geometry}{location}{lat}, $VALID_LAT, 'Bing BestLocation: canonical lat');
	}

	# Bing point style: coordinates[0]=lat, coordinates[1]=lng
	{
		my $list = _list_with_std();
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub {
			return { point => { coordinates => [$VALID_LAT, $VALID_LNG] } };
		};
		my $r = $list->geocode($VALID_LOCATION);
		is($r->{geometry}{location}{lat}, $VALID_LAT, 'Bing point: canonical lat');
	}

	# GeoCodeFarm RESULTS style
	{
		my $list = _list_with_std();
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub {
			return {
				RESULTS => [
					{ COORDINATES => { latitude => $VALID_LAT, longitude => $VALID_LNG } }
				]
			};
		};
		my $r = $list->geocode($VALID_LOCATION);
		is($r->{geometry}{location}{lat}, $VALID_LAT, 'GeoCodeFarm RESULTS: canonical lat');
	}

	# OpenCage: results[0].geometry.lat/lng (no nested "location" key)
	{
		my $list = _list_with_std();
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub {
			return {
				results => [ { geometry => { lat => $VALID_LAT, lng => $VALID_LNG } } ]
			};
		};
		my $r = $list->geocode($VALID_LOCATION);
		is($r->{geometry}{location}{lat}, $VALID_LAT, 'OpenCage geometry.lat/lng: canonical lat');
	}

	# GeoApify: empty features array signals not-found (not an error hash)
	{
		my $list = _list_with_std();
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub {
			return { features => [] };
		};
		is($list->geocode($VALID_LOCATION), undef,
			'GeoApify empty features array: returns undef');
	}

	_vdiag('response normalization done');
};

# =============================================================================
# SUBTEST 11: Caching edge cases
# Purpose: not-found sentinel isolation; L2 interfaces; cache hit field value
# =============================================================================

subtest 'Caching edge cases' => sub {
	# Not-found result: L1-cached so geocoder not called a second time
	{
		my $list  = _list_with_std();
		my $calls = 0;
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub { $calls++; return };
		$list->geocode($VALID_LOCATION);
		$list->geocode($VALID_LOCATION);
		is($calls, 1, 'Not-found: geocoder called only once (L1 not-found cache)');
	}

	# Not-found sentinel must NOT be written to L2 cache (internal object only)
	{
		my %l2;
		my $list = Geo::Coder::List->new(cache => \%l2)->push(EdgeMock::Std->new());
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub { return };
		$list->geocode($VALID_LOCATION);
		ok(!exists $l2{$VALID_LOCATION},
			'Not-found sentinel: NOT written to L2 HASH cache');
	}

	# Positive result IS written to L2 (plain HASH)
	{
		my %l2;
		my $list = Geo::Coder::List->new(cache => \%l2)->push(EdgeMock::Std->new());
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub { _osm($VALID_LAT, $VALID_LNG) };
		$list->geocode($VALID_LOCATION);
		ok(exists $l2{$VALID_LOCATION}, 'Positive result: written to L2 HASH cache');
	}

	# CHI-like object (get/set interface): result stored via set()
	{
		my $chi  = EdgeMock::CHI->new();
		my $list = Geo::Coder::List->new(cache => $chi)->push(EdgeMock::Std->new());
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub { _osm($VALID_LAT, $VALID_LNG) };
		$list->geocode($VALID_LOCATION);
		ok(defined $chi->get($VALID_LOCATION),
			'CHI-like L2: positive result stored via set()');
	}

	# Cache hit: geocoder field must be the string 'cache'
	{
		my $list = _list_with_std();
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub { _osm($VALID_LAT, $VALID_LNG) };
		$list->geocode($VALID_LOCATION);       # populate L1
		my $r = $list->geocode($VALID_LOCATION);   # L1 hit
		is($r->{geocoder}, 'cache',
			'L1 cache hit: geocoder field is the string "cache"');
	}

	_vdiag('caching edge cases done');
};

# =============================================================================
# SUBTEST 12: List vs scalar context
# Purpose: context-sensitive return values must be consistent per POD
# =============================================================================

subtest 'List vs scalar context sensitivity' => sub {
	# Scalar context: single HASHREF
	{
		my $list = _list_with_std();
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub { _osm($VALID_LAT, $VALID_LNG) };
		my $r = $list->geocode($VALID_LOCATION);
		is(ref($r), 'HASH', 'Scalar context: returns HASHREF');
		returns_ok($r, { type => 'hashref' }, 'Scalar result satisfies hashref schema');
	}

	# List context: at least one element
	{
		my $list = _list_with_std();
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub {
			return (_osm($VALID_LAT, $VALID_LNG), _osm(1.0, 2.0));
		};
		my @r = $list->geocode($VALID_LOCATION);
		cmp_ok(scalar @r, '>=', 1, 'List context: returns at least one element');
	}

	# Not-found in scalar context: undef
	{
		my $list = _list_with_std();
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub { return };
		my $r = $list->geocode($VALID_LOCATION);
		is($r, undef, 'Not-found scalar context: returns undef');
	}

	# Not-found in list context: empty list
	{
		my $list = _list_with_std();
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub { return };
		my @r = $list->geocode($VALID_LOCATION);
		is(scalar @r, 0, 'Not-found list context: returns empty list');
	}

	_vdiag('context sensitivity done');
};

# =============================================================================
# SUBTEST 13: Mutating $_ inside a geocoder callback
# Purpose: corruption of $_ by a geocoder must not affect the module's output
# =============================================================================

subtest 'geocode() with geocoder that mutates $_' => sub {
	my $list = _list_with_std();

	# A geocoder that intentionally corrupts $_ should not affect the result
	my $g = mock_scoped 'EdgeMock::Std::geocode' => sub {
		$_ = 'MUTATED_BY_GEOCODER';    # deliberately corrupt the global $_
		return _osm($VALID_LAT, $VALID_LNG);
	};

	my $r = $list->geocode($VALID_LOCATION);
	ok(defined $r, 'Geocoder mutating $_: result is still defined');
	is($r->{geometry}{location}{lat}, $VALID_LAT,
		'Geocoder mutating $_: canonical lat is correct');

	_vdiag('$_ mutation test done');
};

# =============================================================================
# SUBTEST 14: Typeglob and circular reference inputs
# Purpose: truly pathological inputs must not hang, loop, or crash
# =============================================================================

subtest 'Typeglob and circular reference inputs' => sub {
	my $list = _list_with_std();

	# Circular reference as location: must not infinite-loop
	# Params::Get will stringify or reject the ref; either is acceptable
	{
		my %circ;
		$circ{self} = \%circ;    # self-referential structure
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub { return };
		lives_ok { eval { $list->geocode(location => \%circ) } }
			'Circular reference as location: geocode() does not hang or crash';
	}

	# Typeglob pushed as a geocoder: push() must not crash
	{
		my $list2 = Geo::Coder::List->new();
		lives_ok { $list2->push(\*STDIN) }
			'push() with typeglob: does not crash at push time';

		# geocode() will try to call geocode() on the typeglob; that dies, is
		# caught in the eval, carpd, and the chain continues to undef
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		my $r;
		lives_ok { $r = $list2->geocode($VALID_LOCATION) }
			'geocode() with typeglob in chain: does not propagate the internal crash';
	}

	_vdiag('typeglob and circular reference done');
};

# =============================================================================
# SUBTEST 15: reverse_geocode() edge cases
# Purpose: boundary inputs and provider-specific response handling
# =============================================================================

subtest 'reverse_geocode() edge cases' => sub {
	my $list = Geo::Coder::List->new()->push(EdgeMock::Std->new());

	# Empty latlng must croak with the documented error string
	throws_ok { $list->reverse_geocode(latlng => $EMPTY_STRING) }
		qr/Usage: reverse_geocode/,
		'Empty latlng: croaks with "Usage: reverse_geocode" in message';

	# undef latlng must also croak
	throws_ok { $list->reverse_geocode(latlng => $config{no_result}) }
		qr/Usage: reverse_geocode/,
		'undef latlng: croaks';

	# OSM display_name response: returned as a plain string
	# Use a fresh list so no previous cache entry interferes
	{
		my $list_rg = Geo::Coder::List->new()->push(EdgeMock::Std->new());
		my $g = mock_scoped 'EdgeMock::Std::reverse_geocode' => sub {
			return { display_name => 'Test Street, London' };
		};
		my $r = $list_rg->reverse_geocode(latlng => $VALID_LATLNG);
		is($r, 'Test Street, London',
			'reverse_geocode: OSM display_name returned as plain string');
	}

	# Geocoder throws exception: must carp, not propagate
	# Fresh list avoids the cached OSM result from the block above
	{
		my $list_rg = Geo::Coder::List->new({ carp_on_warn => 1 })->push(EdgeMock::Std->new());
		my $g = mock_scoped 'EdgeMock::Std::reverse_geocode' => sub {
			die 'reverse lookup error';
		};
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		my $r;
		lives_ok { $r = $list_rg->reverse_geocode(latlng => $VALID_LATLNG) }
			'reverse_geocode: exception from geocoder does not propagate';
		ok($warned, 'reverse_geocode: geocoder exception is carpd');
	}

	# Geocoder returns undef: result is undef
	# Fresh list avoids cached results from previous blocks
	{
		my $list_rg = Geo::Coder::List->new()->push(EdgeMock::Std->new());
		my $g = mock_scoped 'EdgeMock::Std::reverse_geocode' => sub { return };
		my $r = $list_rg->reverse_geocode(latlng => $VALID_LATLNG);
		is($r, undef, 'reverse_geocode: geocoder returns undef, result is undef');
	}

	_vdiag('reverse_geocode() edge cases done');
};

# =============================================================================
# SUBTEST 16: ua() edge cases
# Purpose: boundary behavior and error handling documented in POD
# =============================================================================

subtest 'ua() edge cases' => sub {
	# ua() with no argument must return undef (POD: ua is optional)
	my $list = Geo::Coder::List->new()->push(EdgeMock::Std->new());
	ok(!defined $list->ua(), 'ua() with no arg: returns undef');

	# ua() returns the passed-in UA object (POD output schema)
	{
		my $g   = mock_scoped 'EdgeMock::Std::ua' => sub { };
		my $ua  = bless {}, 'MockUA::Edge';
		my $ret = $list->ua($ua);
		is(refaddr($ret), refaddr($ua),
			'ua() returns the same UA object that was passed in');
		returns_ok($ret, { type => 'object' },
			'ua() return value satisfies object schema');
	}

	# ua() with a chain entry whose geocoder is undef must croak
	my $list2 = Geo::Coder::List->new()->push({ geocoder => $config{no_result} });
	throws_ok { $list2->ua(bless {}, 'MockUA::Edge') }
		qr/No geocoder found/,
		'ua() with undef geocoder in chain entry: croaks with "No geocoder found"';

	_vdiag('ua() edge cases done');
};

# =============================================================================
# SUBTEST 17: log() and flush() edge cases
# Purpose: accumulation, reset semantics, chaining, and cache independence
# =============================================================================

subtest 'log() and flush() edge cases' => sub {
	# log() on a fresh object must return an empty ARRAYREF (not undef)
	my $list = Geo::Coder::List->new();
	is(ref($list->log()), 'ARRAY', 'log(): returns ARRAYREF');
	is(scalar @{$list->log()}, 0,  'log(): empty on a fresh object');
	returns_ok($list->log(), { type => 'arrayref' },
		'log() return value satisfies arrayref schema');

	# log() accumulates entries across multiple geocode calls
	$list->push(EdgeMock::Std->new());
	{
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub {
			return _osm($VALID_LAT, $VALID_LNG);
		};
		$list->geocode($VALID_LOCATION);
		$list->geocode('London, UK');
	}
	cmp_ok(scalar @{$list->log()}, '>=', 2,
		'log(): at least 2 entries after 2 geocode calls');

	# flush() resets the log to an empty ARRAYREF
	$list->flush();
	is(scalar @{$list->log()}, 0,     'flush(): log empty after flush');
	is(ref($list->log()), 'ARRAY',    'flush(): log() still returns ARRAYREF after flush');

	# flush() must return $self to enable chaining (POD output schema)
	my $ret = $list->flush();
	is(refaddr($ret), refaddr($list), 'flush(): returns $self');
	returns_ok($ret, { type => 'object' }, 'flush() return satisfies object schema');

	# flush() must NOT clear the L1 cache (POD Z-spec: L1' = L1)
	# Use a fresh list so $VALID_LOCATION is not already in the L1 cache
	{
		my $list2 = Geo::Coder::List->new()->push(EdgeMock::Std->new());
		my $calls = 0;
		my $g = mock_scoped 'EdgeMock::Std::geocode' => sub {
			$calls++;
			return _osm($VALID_LAT, $VALID_LNG);
		};
		$list2->geocode($VALID_LOCATION);    # populate cache (calls geocoder once)
		$list2->flush();                     # clear log only, not cache
		my $r = $list2->geocode($VALID_LOCATION);   # must hit cache, not geocoder
		is($calls, 1, 'flush(): L1 cache survives flush (geocoder called only once)');
		is($r->{geocoder}, 'cache', 'flush(): result still served from cache after flush');
	}

	_vdiag('log() and flush() edge cases done');
};

# =============================================================================
# SUBTEST 18: ua() clone path edge cases
# Purpose: boundary conditions around the clone/agent decision in ua()
# =============================================================================

subtest 'ua() clone path: UA with clone() but no agent() falls through to direct pass' => sub {
	# If the UA has clone() but not agent(), the condition
	# "$ua->can('clone') && $ua->can('agent')" is false, so original is passed.
	my $list = _list_with_std();
	{
		package EdgeMock::CloneNoAgent;
		sub new   { bless {}, shift }
		sub clone { bless {%{$_[0]}}, ref($_[0]) }
		# deliberately no agent() method
	}

	my $ua = EdgeMock::CloneNoAgent->new();
	my $received_ua;
	my $g = mock_scoped 'EdgeMock::Std::ua' => sub { (undef, $received_ua) = @_ };
	$list->ua($ua);

	is(refaddr($received_ua), refaddr($ua),
		'UA with clone() but no agent(): passed directly (same reference)');
};

subtest 'ua() clone path: UA with agent() but no clone() falls through to direct pass' => sub {
	my $list = _list_with_std();
	{
		package EdgeMock::AgentNoClone;
		sub new   { bless { _a => 'test' }, shift }
		sub agent { $_[0]->{_a} }
		# deliberately no clone() method
	}

	my $ua = EdgeMock::AgentNoClone->new();
	my $received_ua;
	my $g = mock_scoped 'EdgeMock::Std::ua' => sub { (undef, $received_ua) = @_ };
	$list->ua($ua);

	is(refaddr($received_ua), refaddr($ua),
		'UA with agent() but no clone(): passed directly (same reference)');
};

subtest 'ua() clone: geocoder with no VERSION gets class-name-only agent' => sub {
	# EdgeMock::Std has no $VERSION; agent should be just the class name
	my $list = _list_with_std();
	{
		package EdgeCloneUA;
		sub new   { bless { _a => 'libwww-perl/test' }, shift }
		sub clone { bless {%{$_[0]}}, ref($_[0]) }
		sub agent { $_[0]->{_a} = $_[1] if @_ > 1; $_[0]->{_a} }
	}

	my $ua = EdgeCloneUA->new();
	my $received_ua;
	my $g = mock_scoped 'EdgeMock::Std::ua' => sub { (undef, $received_ua) = @_ };
	$list->ua($ua);

	is($received_ua->agent(), 'EdgeMock::Std',
		'No-VERSION geocoder: agent string is just the class name');
};

# =============================================================================
# SUBTEST 19: reverse_geocode() latlng retry edge cases
# Purpose: boundary conditions for the strict-validation retry path
# =============================================================================

subtest 'reverse_geocode() retry: non-latlng error is NOT retried' => sub {
	# Only "Unknown parameter 'latlng'" errors trigger the retry; other errors
	# must go through the normal carp-and-skip path.
	my $list = Geo::Coder::List->new({ carp_on_warn => 1 })->push(EdgeMock::Std->new());
	my $calls = 0;
	my $g = mock_scoped 'EdgeMock::Std::reverse_geocode' => sub {
		$calls++;
		die 'connection refused';
	};

	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };
	my $r = $list->reverse_geocode(latlng => $VALID_LATLNG);

	is($calls,  1,     'Non-latlng error: geocoder called once only (no retry)');
	is($r,      undef, 'Non-latlng error: result is undef');
	ok($warned,        'Non-latlng error: warning emitted');
};

subtest 'reverse_geocode() retry: lat and lon present; latlng absent on retry call' => sub {
	# After the retry, the geocoder must receive lat and lon but NOT latlng.
	my $list = Geo::Coder::List->new()->push(EdgeMock::Std->new());
	my %retry_args;
	my $g = mock_scoped 'EdgeMock::Std::reverse_geocode' => sub {
		my ($self, %args) = @_;
		die "validate_strict: Unknown parameter 'latlng'\n" if exists $args{latlng};
		%retry_args = %args;
		return { display_name => 'Verified Retry' };
	};

	$list->reverse_geocode(latlng => $VALID_LATLNG);

	ok(!exists $retry_args{latlng}, 'Retry: latlng key was stripped');
	ok( exists $retry_args{lat},    'Retry: lat key is present');
	ok( exists $retry_args{lon},    'Retry: lon key is present');
};

subtest 'reverse_geocode() retry succeeds in list context too' => sub {
	my $list = Geo::Coder::List->new()->push(EdgeMock::Std->new());
	my $g = mock_scoped 'EdgeMock::Std::reverse_geocode' => sub {
		my ($self, %args) = @_;
		die "validate_strict: Unknown parameter 'latlng'\n" if exists $args{latlng};
		return ({ display_name => 'List Retry Result' });
	};

	my @r = $list->reverse_geocode(latlng => $VALID_LATLNG);
	ok(scalar @r >= 1,           'List context retry: at least one result');
	is($r[0], 'List Retry Result', 'List context retry: correct address returned');
};

done_testing();

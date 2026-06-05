#!/usr/bin/env perl

# t/extended_tests.t -- Coverage-raising tests for execution paths not hit
# by the main test suite (unit.t, function.t, edge_cases.t).
#
# Each subtest targets a specific branch in lib/Geo/Coder/List.pm that was
# identified as untested via code reading.  Sections map to module sections.
#
# PATHS IDENTIFIED AS POTENTIALLY UNREACHABLE (see bottom of file for detail):
#   * Line 495: ARRAY empty-first-element branch (auto-vivification hazard)
#   * Line 734: defined($rc[0]) false while good_result is set (latent bug)

use strict;
use warnings;

use lib 'lib';

use Readonly;
use Scalar::Util qw(blessed refaddr);
use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Data::Dumper;

BEGIN { use_ok('Geo::Coder::List') }

# =============================================================================
# Configuration -- no magic numbers or strings below this block
# =============================================================================

Readonly::Scalar my $LOC_PARIS     => 'Paris, France';
Readonly::Scalar my $LOC_LONDON    => 'London, UK';
Readonly::Scalar my $LOC_DC        => 'Washington, DC, USA';
Readonly::Scalar my $LATLNG_DC     => '38.8977,-77.0365';
Readonly::Scalar my $LAT_DC        => 38.8977;
Readonly::Scalar my $LNG_DC        => -77.0365;
Readonly::Scalar my $LAT_NY        => 40.7128;
Readonly::Scalar my $LNG_NY        => -74.006;
Readonly::Scalar my $ADDR_STREET   => '100 King Street, Ottawa, ON';
Readonly::Scalar my $ADDR_DISPLAY  => '10 Downing Street, London, UK';
Readonly::Scalar my $ADDR_GEOAPIFY => '100 Main Ave, Ottawa, Canada';

# Cache TTL strings that the code should emit when calling L2->set()
Readonly::Scalar my $TTL_HIT  => '1 month';
Readonly::Scalar my $TTL_PART => '1 day';
Readonly::Scalar my $TTL_MISS => '1 week';

my %config = (
	limit_one   => 1,
	limit_zero  => 0,
	debug_v1    => 1,
	debug_v2    => 2,
	no_result   => undef,
);

# =============================================================================
# Inline geocoder stub packages
# =============================================================================

# Three generic geocoder stubs; Mockingbird replaces their methods per test
{
	package ExtMock::A;
	sub new             { bless {}, shift }
	sub geocode         { return () }
	sub reverse_geocode { return () }
	sub ua              { }
}

{
	package ExtMock::B;
	sub new             { bless {}, shift }
	sub geocode         { return () }
	sub reverse_geocode { return () }
	sub ua              { }
}

# US Census stub -- class name must be exactly 'Geo::Coder::US::Census'
# so the special guard in geocode() is triggered
{
	package Geo::Coder::US::Census;
	sub new     { bless {}, shift }
	sub geocode { return () }
	sub ua      { }
}

# Geo::Location::Point stub -- class name must match the ref() check
{
	package Geo::Location::Point;
	sub new { bless {}, shift }
	sub ua  { }
}

# A minimal CHI-compatible L2 cache stub (get / set interface)
{
	package ExtMock::CHI;
	sub new { bless { store => {}, calls => [] }, shift }
	sub get { $_[0]->{store}{ $_[1] } }
	sub set {
		my ($self, $key, $val, $ttl) = @_;
		push @{$self->{calls}}, { key => $key, ttl => $ttl };
		$self->{store}{$key} = $val;
	}
}

package main;

# ── Helpers ───────────────────────────────────────────────────────────────────

# Build a list with a single ExtMock::A geocoder
sub _list_a { Geo::Coder::List->new({ carp_on_warn => 1 })->push(ExtMock::A->new()) }

# Standard OSM result hashref
sub _osm { { lat => $_[0], lon => $_[1] } }

# Emit diagnostics only in verbose mode
sub _vdiag { diag(@_) if $ENV{TEST_VERBOSE} }

# =============================================================================
# SECTION 1: geocode() -- Geo::Location::Point result path
#
# Lines 548-571: when a geocoder returns a Geo::Location::Point-blessed object
# the module stamps the geocoder, populates geometry from lat/lng, and sets aliases.
# =============================================================================

subtest 'geocode(): Geo::Location::Point result -- lat/lng present, no geometry' => sub {
	# Purpose: GLP with lat/lng but no geometry; geometry must be populated
	my $list = _list_a();
	my $g = mock_scoped 'ExtMock::A::geocode' => sub {
		my $glp = Geo::Location::Point->new();
		$glp->{lat} = $LAT_DC;
		$glp->{lng} = $LNG_DC;
		return $glp;
	};

	# The GLP path should populate geometry.location.{lat,lng} from lat/lng
	my $r = $list->geocode($LOC_DC);
	ok(defined $r, 'GLP result: defined result returned');
	is($r->{geometry}{location}{lat}, $LAT_DC, 'GLP: geometry.location.lat set from lat');
	is($r->{geometry}{location}{lng}, $LNG_DC, 'GLP: geometry.location.lng set from lng');

	# Convenience aliases must also be populated
	is($r->{lat}, $LAT_DC, 'GLP: lat alias populated');
	is($r->{lng}, $LNG_DC, 'GLP: lng alias populated');

	_vdiag('GLP result:', Dumper($r));
};

subtest 'geocode(): Geo::Location::Point result -- geometry already set; not overwritten' => sub {
	# Purpose: GLP with geometry pre-set; geometry must NOT be re-populated
	my $list = _list_a();
	my $g = mock_scoped 'ExtMock::A::geocode' => sub {
		my $glp = Geo::Location::Point->new();
		# Pre-set geometry and differing lat (lat should be kept by //=)
		$glp->{geometry}{location}{lat} = $LAT_DC;
		$glp->{geometry}{location}{lng} = $LNG_DC;
		return $glp;
	};

	my $r = $list->geocode($LOC_DC);
	ok(defined $r, 'GLP with geometry: result returned');
	is($r->{geometry}{location}{lat}, $LAT_DC, 'GLP: pre-set geometry.lat preserved');
	is($r->{geometry}{location}{lng}, $LNG_DC, 'GLP: pre-set geometry.lng preserved');
};

subtest 'geocode(): Geo::Location::Point result -- geocoder field is the object' => sub {
	# Purpose: GLP path sets geocoder field to the geocoder object, not its class name
	my $geocoder_obj = ExtMock::A->new();
	my $list = Geo::Coder::List->new()->push($geocoder_obj);
	my $g = mock_scoped 'ExtMock::A::geocode' => sub {
		my $glp = Geo::Location::Point->new();
		$glp->{lat} = $LAT_DC;
		$glp->{lng} = $LNG_DC;
		return $glp;
	};

	my $r = $list->geocode($LOC_DC);
	ok(defined $r, 'GLP geocoder field test: result returned');
	# The GLP path sets $l->{'geocoder'} = $geocoder (the object itself)
	is(ref($r->{geocoder}), 'ExtMock::A', 'GLP: geocoder field is the object reference');
};

# =============================================================================
# SECTION 2: geocode() -- US Census special empty-result guard
#
# Lines 478-490: Geo::Coder::US::Census sometimes returns a truthy but
# empty result (no addressMatches coordinates).  The module must skip it
# and fall through to the next geocoder (or return undef).
# =============================================================================

subtest 'geocode(): US Census empty addressMatches guard -- skips to next geocoder' => sub {
	# Purpose: Census geocoder returns result without coordinates; must be skipped
	my $list = Geo::Coder::List->new();
	$list->push(Geo::Coder::US::Census->new());
	$list->push(ExtMock::B->new());

	# Census returns a result with no coordinates; B returns a valid result
	my $gC = mock_scoped 'Geo::Coder::US::Census::geocode' => sub {
		return { result => { addressMatches => [] } };
	};
	my $gB = mock_scoped 'ExtMock::B::geocode' => sub {
		return _osm($LAT_DC, $LNG_DC);
	};

	my $r = $list->geocode($LOC_DC);
	ok(defined $r, 'Census empty result: fallback geocoder used');
	is($r->{geometry}{location}{lat}, $LAT_DC, 'Fallback result has correct lat');
};

subtest 'geocode(): US Census empty addressMatches guard -- returns undef when only geocoder' => sub {
	# Purpose: Census is the only geocoder and returns an empty result
	my $list = Geo::Coder::List->new();
	$list->push(Geo::Coder::US::Census->new());
	my $g = mock_scoped 'Geo::Coder::US::Census::geocode' => sub {
		return { result => { addressMatches => [] } };
	};

	my $r = $list->geocode($LOC_DC);
	is($r, undef, 'Census empty result (sole geocoder): returns undef');

	# A log entry should record the not-found for this geocoder
	my $entry = $list->log()->[0];
	is($entry->{result}, 'not found', 'Census empty result: log entry says not found');
};

# =============================================================================
# SECTION 3: geocode() -- empty-string candidate in POSSIBLE_LOCATION loop
#
# Line 522: $l eq '' triggers next ENCODER, not just next (skips whole geocoder).
# =============================================================================

subtest 'geocode(): empty-string element in result list triggers next ENCODER' => sub {
	# Purpose: geocoder returns ('') as a result; module must skip to next geocoder
	my $list = Geo::Coder::List->new();
	$list->push(ExtMock::A->new());
	$list->push(ExtMock::B->new());

	# A returns an empty string (falsy candidate); B returns a valid result
	my $gA = mock_scoped 'ExtMock::A::geocode' => sub { return ('') };
	my $gB = mock_scoped 'ExtMock::B::geocode' => sub { _osm($LAT_NY, $LNG_NY) };

	my $r = $list->geocode($LOC_PARIS);
	ok(defined $r, 'Empty-string element: fallback geocoder returned a result');
	is(ref($r->{geocoder}), 'ExtMock::B', 'Result came from second geocoder');
};

# =============================================================================
# SECTION 4: geocode() -- legacy 'long' key normalisation
#
# Lines 736-741: when $rc[0] has a 'long' key but no 'lng'/'lon', the module
# copies 'long' into 'lng' and 'lon' before caching/returning.
# =============================================================================

subtest 'geocode(): legacy "long" key normalised to "lng" and "lon"' => sub {
	# Purpose: result has geometry.location.lat already set (no normalization needed)
	# and a 'long' key but no 'lng' or 'lon'.  The legacy fix must set both.
	my $list = _list_a();
	my $g = mock_scoped 'ExtMock::A::geocode' => sub {
		# geometry.lat is set so normalization block is skipped;
		# geometry.lng is intentionally absent; 'long' carries the value
		return {
			geometry => { location => { lat => $LAT_DC } },
			long     => $LNG_DC,
		};
	};

	my $r = $list->geocode($LOC_DC);
	ok(defined $r, '"long" key: result returned');
	# The legacy normalization must have copied long -> lng and lng -> lon
	is($r->{lng}, $LNG_DC, '"long" -> "lng" copy applied');
	is($r->{lon}, $LNG_DC, '"long" -> "lon" copy applied');
	is($r->{lat}, $LAT_DC, 'lat unaffected by long normalisation');
};

# =============================================================================
# SECTION 5: geocode() -- BUG croak path
#
# Lines 744-747: if good_result has lat set but lng is undef the module
# croaks with "BUG: ... HASH exists but is not sensible".
# =============================================================================

subtest 'geocode(): BUG croak when result has lat but no lng' => sub {
	# Purpose: canonical geometry has lat but geometry.location.lng is absent;
	# the module must croak with the documented BUG error string.
	my $list = _list_a();
	my $g = mock_scoped 'ExtMock::A::geocode' => sub {
		# geometry.location.lat is present; lng is deliberately absent
		return { geometry => { location => { lat => $LAT_DC } } };
	};

	# The module must croak (not just warn) with the exact BUG message
	throws_ok { $list->geocode($LOC_DC) }
		qr/BUG:.*HASH exists but is not sensible/,
		'BUG croak fires when lat set but lng absent';
};

# =============================================================================
# SECTION 6: geocode() -- list-context L1 cache hit: all-empty results
#
# Line 400: return if $allempty -- if every cached ARRAY element has no
# geometry.location.lat, the list-context call must return an empty list.
# =============================================================================

subtest 'geocode(): list-context L1 cache hit with all-empty results returns ()' => sub {
	# Purpose: force the $allempty branch by injecting an array of empty hashes
	# into L1, then calling geocode() in list context.
	my $list = _list_a();

	# Bypass _cache() and write directly to L1 with a HASH lacking geometry
	$list->{locations}{$LOC_PARIS} = [ { no_coords => 1 } ];

	my @r = $list->geocode($LOC_PARIS);
	is(scalar @r, 0, 'All-empty L1 cache in list context returns empty list');
};

subtest 'geocode(): list-context L1 cache hit -- GLP element sets allempty=0' => sub {
	# Purpose: the $allempty loop treats any GLP element as non-empty
	my $list = _list_a();
	my $glp  = Geo::Location::Point->new();

	# Inject a GLP directly into L1 cache
	$list->{locations}{$LOC_PARIS} = [ $glp ];

	my @r = $list->geocode($LOC_PARIS);
	ok(scalar @r >= 1, 'GLP in L1 cache: list context returns the element');
	is(ref($r[0]), 'Geo::Location::Point', 'Returned element is the GLP object');
};

subtest 'geocode(): list-context L1 cache hit -- HASH with lat set returns results' => sub {
	# Purpose: confirm the positive $allempty=0 branch for HASH with lat defined
	my $list = _list_a();
	my $cached_result = { geometry => { location => { lat => $LAT_DC, lng => $LNG_DC } } };

	# Inject a valid HASH into L1
	$list->{locations}{$LOC_PARIS} = [ $cached_result ];

	my @r = $list->geocode($LOC_PARIS);
	ok(scalar @r >= 1, 'HASH with lat in L1: list context returns results');
	is($r[0]->{geocoder}, 'cache', 'Cached result has geocoder set to "cache"');
};

# =============================================================================
# SECTION 7: reverse_geocode() -- scalar context: bare-string return
#
# Lines 972-983: if the geocoder returns a plain (non-reference) string, it
# is logged and returned directly without further processing.
# =============================================================================

subtest 'reverse_geocode(): scalar -- geocoder returns bare string' => sub {
	# Purpose: test the !ref($rc) branch in the scalar-context path
	my $list = Geo::Coder::List->new()->push(ExtMock::A->new());
	my $g = mock_scoped 'ExtMock::A::reverse_geocode' => sub {
		return '123 Bare String Avenue, Ottawa';
	};

	my $r = $list->reverse_geocode(latlng => $LATLNG_DC);
	is($r, '123 Bare String Avenue, Ottawa', 'Bare string returned directly');
	ok(!ref($r), 'Result is a plain scalar, not a reference');

	# A log entry must be written
	my $e = $list->log()->[-1];
	is($e->{result}, '123 Bare String Avenue, Ottawa', 'Log entry has string result');
};

# =============================================================================
# SECTION 8: reverse_geocode() -- scalar context: CA/city response
#
# Lines 1000-1011: when the geocoder result has a 'city' key, _build_ca_address
# is called and the assembled string is cached/returned.
# =============================================================================

subtest 'reverse_geocode(): scalar -- CA city response assembles address' => sub {
	# Purpose: test the $rc->{'city'} branch in scalar context
	my $list = Geo::Coder::List->new()->push(ExtMock::A->new());
	my $g = mock_scoped 'ExtMock::A::reverse_geocode' => sub {
		return {
			stnumber  => '100',
			staddress => 'King Street',
			city      => 'Ottawa',
			prov      => 'ON',
		};
	};

	my $r = $list->reverse_geocode(latlng => $LATLNG_DC);
	is($r, '100 King Street, Ottawa, ON',
		'CA city response: address assembled via _build_ca_address');
};

subtest 'reverse_geocode(): scalar -- CA city response cached and returned on second call' => sub {
	# Purpose: the result must be written to cache so the second call hits cache
	my $list = Geo::Coder::List->new()->push(ExtMock::A->new());
	my $calls = 0;
	my $g = mock_scoped 'ExtMock::A::reverse_geocode' => sub {
		$calls++;
		return { city => 'Ottawa', prov => 'ON' };
	};

	$list->reverse_geocode(latlng => $LATLNG_DC);
	$list->reverse_geocode(latlng => $LATLNG_DC);
	is($calls, 1, 'CA city response: geocoder called only once (L1 cache hit)');
};

# =============================================================================
# SECTION 9: reverse_geocode() -- scalar context: GeoApify features response
#
# Lines 1014-1026: the features[0].properties.formatted string is extracted.
# =============================================================================

subtest 'reverse_geocode(): scalar -- GeoApify features response' => sub {
	# Purpose: test the $rc->{features} branch in scalar context
	my $list = Geo::Coder::List->new()->push(ExtMock::A->new());
	my $g = mock_scoped 'ExtMock::A::reverse_geocode' => sub {
		return {
			features => [
				{ properties => { formatted => $ADDR_GEOAPIFY } }
			]
		};
	};

	my $r = $list->reverse_geocode(latlng => $LATLNG_DC);
	is($r, $ADDR_GEOAPIFY, 'GeoApify features: formatted address extracted');
};

# =============================================================================
# SECTION 10: reverse_geocode() -- list context: CA city response
#
# Lines 930-932: in list context, a loc with 'city' key triggers _build_ca_address.
# =============================================================================

subtest 'reverse_geocode(): list context -- CA city response' => sub {
	# Purpose: the city branch in the list-context loop
	my $list = Geo::Coder::List->new()->push(ExtMock::A->new());
	my $g = mock_scoped 'ExtMock::A::reverse_geocode' => sub {
		return (
			{ city => 'Ottawa', prov => 'ON', stnumber => '100', staddress => 'King St' },
		);
	};

	my @r = $list->reverse_geocode(latlng => $LATLNG_DC);
	ok(scalar @r >= 1, 'List context CA city: at least one result');
	like($r[0], qr/Ottawa/, 'List context CA city: city present in result');
};

# =============================================================================
# SECTION 11: reverse_geocode() -- list context: GeoApify features response
#
# Lines 933-937: in list context, a loc with 'features' key extracts formatted.
# =============================================================================

subtest 'reverse_geocode(): list context -- GeoApify features response' => sub {
	# Purpose: the features branch in the list-context loop
	my $list = Geo::Coder::List->new()->push(ExtMock::A->new());
	my $g = mock_scoped 'ExtMock::A::reverse_geocode' => sub {
		return (
			{ features => [ { properties => { formatted => $ADDR_GEOAPIFY } } ] },
		);
	};

	my @r = $list->reverse_geocode(latlng => $LATLNG_DC);
	ok(scalar @r >= 1, 'List context GeoApify: at least one result');
	is($r[0], $ADDR_GEOAPIFY, 'List context GeoApify: formatted address in result');
};

# =============================================================================
# SECTION 12: reverse_geocode() -- list context: geocoder throws exception
#
# Lines 911-922: exception in list context is carpd and the loop continues.
# =============================================================================

subtest 'reverse_geocode(): list context -- geocoder exception is carpd, not croaked' => sub {
	# Purpose: verify the list-context error path (separate eval branch from scalar)
	my $list = Geo::Coder::List->new({ carp_on_warn => 1 });
	$list->push(ExtMock::A->new())->push(ExtMock::B->new());

	my $gA = mock_scoped 'ExtMock::A::reverse_geocode' => sub {
		die "list-context reverse error\n";
	};
	my $gB = mock_scoped 'ExtMock::B::reverse_geocode' => sub {
		return ({ display_name => $ADDR_DISPLAY });
	};

	my @r;
	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };
	lives_ok { @r = $list->reverse_geocode(latlng => $LATLNG_DC) }
		'List context exception: reverse_geocode() does not die';
	ok($warned, 'List context exception: warning emitted');
};

subtest 'reverse_geocode(): list context -- log entry includes error key on exception' => sub {
	# Purpose: confirm the error key is recorded in the log for list-context failures
	my $list = Geo::Coder::List->new()->push(ExtMock::A->new());
	my $g = mock_scoped 'ExtMock::A::reverse_geocode' => sub {
		die "rg-list-error\n";
	};

	local $SIG{__WARN__} = sub { };    # suppress output
	my @r = $list->reverse_geocode(latlng => $LATLNG_DC);

	my ($err_entry) = grep { exists $_->{error} } @{$list->log()};
	ok(defined $err_entry, 'List context exception: error entry in log');
	like($err_entry->{error}, qr/rg-list-error/, 'Error text captured in log entry');
};

# =============================================================================
# SECTION 13: reverse_geocode() -- hashref entry with limit guard
#
# Lines 893-900: a hashref chain entry in reverse_geocode() also has a limit
# guard that decrements and skips when exhausted.
# =============================================================================

subtest 'reverse_geocode(): hashref entry limit guard exhausts correctly' => sub {
	# Purpose: verify limit guard runs in reverse_geocode() (separate from geocode())
	my $list = Geo::Coder::List->new();
	$list->push({ geocoder => ExtMock::A->new(), limit => $config{limit_one} });

	my $calls = 0;
	my $g = mock_scoped 'ExtMock::A::reverse_geocode' => sub {
		$calls++;
		return { display_name => $ADDR_DISPLAY };
	};

	# First call uses the limit (decrements 1 -> 0)
	$list->reverse_geocode(latlng => $LATLNG_DC);
	# Second call sees limit=0, geocoder is skipped
	$list->reverse_geocode(latlng => '51.5074,-0.1278');
	is($calls, 1, 'reverse_geocode limit=1: geocoder called exactly once');
};

subtest 'reverse_geocode(): hashref entry with limit=0 never calls geocoder' => sub {
	# Purpose: limit=0 means the geocoder is immediately exhausted
	my $list = Geo::Coder::List->new();
	$list->push({ geocoder => ExtMock::A->new(), limit => $config{limit_zero} });

	my $calls = 0;
	my $g = mock_scoped 'ExtMock::A::reverse_geocode' => sub {
		$calls++;
		return { display_name => $ADDR_DISPLAY };
	};

	my $r = $list->reverse_geocode(latlng => $LATLNG_DC);
	is($calls, 0,    'reverse_geocode limit=0: geocoder never called');
	is($r, undef,    'reverse_geocode limit=0: result is undef');
};

# =============================================================================
# SECTION 14: _cache() -- L2 read path (L1 miss -> L2 hit)
#
# Lines 1296-1302: when L1 has no entry, _cache() falls through to L2.
# Neither the plain-HASH L2 read nor the CHI->get() L2 read is tested elsewhere.
# =============================================================================

subtest '_cache(): L2 HASH read path -- L1 miss, L2 hit returns value' => sub {
	# Purpose: verify that a value present only in L2 (HASH) is returned on read
	my %l2;
	my $obj = Geo::Coder::List->new(cache => \%l2);

	# Plant a value directly in L2 without going through L1
	my $stored = { geometry => { location => { lat => $LAT_DC, lng => $LNG_DC } } };
	$l2{$LOC_PARIS} = $stored;

	# L1 is empty; _cache() must fall through to L2 HASH
	my $rc = $obj->_cache($LOC_PARIS);
	ok(defined $rc, 'L2 HASH read: value returned on L1 miss');
	is($rc->{geometry}{location}{lat}, $LAT_DC, 'L2 HASH read: lat correct');
	is($rc->{lat}, $LAT_DC, 'L2 HASH read: lat alias populated on read');
};

subtest '_cache(): L2 CHI read path -- L1 miss, L2 hit returns value' => sub {
	# Purpose: verify the CHI->get() branch is used when L1 misses
	my $chi = ExtMock::CHI->new();
	my $obj = Geo::Coder::List->new(cache => $chi);

	# Plant a value directly in the CHI store (bypassing L1)
	my $stored = { geometry => { location => { lat => $LAT_NY, lng => $LNG_NY } } };
	$chi->{store}{$LOC_LONDON} = $stored;

	my $rc = $obj->_cache($LOC_LONDON);
	ok(defined $rc, 'L2 CHI read: value returned on L1 miss');
	is($rc->{geometry}{location}{lat}, $LAT_NY, 'L2 CHI read: lat correct');
};

subtest '_cache(): L2 HASH read returns undef when stored HASH has no geometry.lat' => sub {
	# Purpose: line 1311 -- if an L2 HASH value exists but has no lat, return undef
	my %l2;
	my $obj = Geo::Coder::List->new(cache => \%l2);

	# Store a HASH without geometry.location.lat in L2
	$l2{$LOC_PARIS} = { some_field => 'no coordinates' };

	my $rc = $obj->_cache($LOC_PARIS);
	ok(!defined $rc, 'L2 HASH with no lat: read returns undef');
};

# =============================================================================
# SECTION 15: _cache() -- partial/miss geometry TTL selection for HASH values
#
# Lines 1256-1263: a HASH value with geometry-but-no-lat uses cache_part_duration;
# a HASH value with no geometry at all uses cache_miss_duration.
# =============================================================================

subtest '_cache(): HASH with partial geometry uses cache_part_duration TTL' => sub {
	# Purpose: test the elsif(defined($value->{geometry})) branch -- TTL = '1 day'
	my $chi = ExtMock::CHI->new();
	my $obj = Geo::Coder::List->new(cache => $chi);

	# A HASH with geometry present but no lat/lng inside it
	my $val = { geometry => {} };
	$obj->_cache('partial-key', $val);

	# The TTL passed to set() must match cache_part_duration
	my @calls = @{$chi->{calls}};
	is(scalar @calls, 1, 'Partial geometry HASH: set() called once');
	is($calls[0]{ttl}, $TTL_PART, "Partial geometry HASH: TTL is '$TTL_PART'");
};

subtest '_cache(): HASH with no geometry -- auto-vivification collapses to part TTL' => sub {
	# Purpose: document that the cache_miss_duration 'else' branch is unreachable.
	# When checking defined($value->{geometry}{location}{lat}), Perl auto-vivifies
	# $value->{geometry} as an empty hashref.  The subsequent
	# elsif(defined($value->{geometry})) is then ALWAYS true, so the else branch
	# (cache_miss_duration / '1 week') can never be reached.
	# The effective TTL for a no-geometry HASH is therefore cache_part_duration.
	my $chi = ExtMock::CHI->new();
	my $obj = Geo::Coder::List->new(cache => $chi);

	my $val = { some_other_key => 'value' };
	$obj->_cache('miss-key', $val);

	my @calls = @{$chi->{calls}};
	is(scalar @calls, 1, 'No-geometry HASH: set() called once');
	# Due to auto-vivification, the effective TTL is cache_part_duration, not miss
	is($calls[0]{ttl}, $TTL_PART,
		"No-geometry HASH: TTL is '$TTL_PART' (auto-vivification makes miss branch dead)")
};

subtest '_cache(): HASH with no geometry -- _cache write returns undef' => sub {
	# Purpose: the code sets $rc = undef when geometry is absent; verify return value
	my $chi = ExtMock::CHI->new();
	my $obj = Geo::Coder::List->new(cache => $chi);

	my $val = { some_other_key => 'value' };
	my $rc  = $obj->_cache('miss-key-2', $val);
	ok(!defined $rc, 'No-geometry HASH: _cache write returns undef');
};

subtest '_cache(): HASH with partial geometry -- _cache write returns undef' => sub {
	# Purpose: partial geometry also sets $rc = undef
	my $chi = ExtMock::CHI->new();
	my $obj = Geo::Coder::List->new(cache => $chi);

	my $val = { geometry => {} };
	my $rc  = $obj->_cache('partial-key-2', $val);
	ok(!defined $rc, 'Partial geometry HASH: _cache write returns undef');
};

# =============================================================================
# SECTION 16: _cache() -- partial/miss geometry TTL selection for ARRAY values
#
# Lines 1232-1238: same TTL selection logic but for ARRAY values.
# =============================================================================

subtest '_cache(): ARRAY item with partial geometry uses cache_part_duration TTL' => sub {
	# Purpose: array item has geometry but no lat -> cache_part_duration
	my $chi = ExtMock::CHI->new();
	my $obj = Geo::Coder::List->new(cache => $chi);

	# Array containing one item with partial geometry
	my $val = [ { geometry => {} } ];
	$obj->_cache('array-partial', $val);

	my @calls = @{$chi->{calls}};
	is(scalar @calls, 1, 'Array partial geometry: set() called once');
	is($calls[0]{ttl}, $TTL_PART, "Array partial geometry: TTL is '$TTL_PART'");
};

subtest '_cache(): ARRAY item with no geometry -- auto-vivification collapses to part TTL' => sub {
	# Purpose: document that the ternary cache_miss_duration arm is unreachable.
	# defined($item->{geometry}{location}{lat}) auto-vivifies $item->{geometry},
	# so the subsequent defined($item->{geometry}) ternary test is always TRUE.
	# The effective TTL is therefore cache_part_duration in all no-lat cases.
	my $chi = ExtMock::CHI->new();
	my $obj = Geo::Coder::List->new(cache => $chi);

	my $val = [ { some_key => 'no geometry' } ];
	$obj->_cache('array-miss', $val);

	my @calls = @{$chi->{calls}};
	is(scalar @calls, 1, 'Array no-geometry: set() called once');
	is($calls[0]{ttl}, $TTL_PART,
		"Array no-geometry: TTL is '$TTL_PART' (auto-vivification makes miss arm dead)")
};

subtest '_cache(): ARRAY item with partial geometry -- write returns undef' => sub {
	# Purpose: $rc is set to undef when any array item is missing geometry.lat
	my $chi = ExtMock::CHI->new();
	my $obj = Geo::Coder::List->new(cache => $chi);

	my $val = [ { geometry => {} } ];
	my $rc  = $obj->_cache('array-partial-rc', $val);
	ok(!defined $rc, 'Array partial geometry: write returns undef');
};

subtest '_cache(): ARRAY all items clean uses cache_hit_duration TTL' => sub {
	# Purpose: when all items have geometry.location.lat, use the full hit TTL
	my $chi = ExtMock::CHI->new();
	my $obj = Geo::Coder::List->new(cache => $chi);

	my $val = [
		{ geometry => { location => { lat => $LAT_DC, lng => $LNG_DC } } },
	];
	$obj->_cache('array-hit', $val);

	my @calls = @{$chi->{calls}};
	is(scalar @calls, 1, 'Array all-clean: set() called once');
	is($calls[0]{ttl}, $TTL_HIT, "Array all-clean: TTL is '$TTL_HIT'");
};

# =============================================================================
# SECTION 17: _cache() -- debug mode preserves all L2 keys
#
# Lines 1226-1229 and 1247-1250: unless($self->{'debug'}) strips L2 to
# geometry only.  With debug=1, all keys must be preserved.
# =============================================================================

subtest '_cache(): debug=1 preserves all HASH keys in L2 (no stripping)' => sub {
	# Purpose: verify the debug guard that skips the key-stripping loop
	my %l2;
	my $obj = Geo::Coder::List->new(cache => \%l2, debug => $config{debug_v1});

	my $val = {
		geometry  => { location => { lat => $LAT_DC, lng => $LNG_DC } },
		extra_key => 'should be kept',
	};
	$obj->_cache('debug-key', $val);

	# With debug=1 the extra_key must survive into L2
	ok(exists $l2{'debug-key'}{extra_key},
		'debug=1: extra key preserved in L2 HASH');
	is($l2{'debug-key'}{extra_key}, 'should be kept',
		'debug=1: extra key value correct in L2');
};

subtest '_cache(): debug=0 strips all keys except geometry in L2' => sub {
	# Purpose: verify stripping IS applied when debug is off (the normal path)
	my %l2;
	my $obj = Geo::Coder::List->new(cache => \%l2);    # debug defaults to 0

	my $val = {
		geometry  => { location => { lat => $LAT_DC, lng => $LNG_DC } },
		extra_key => 'should be stripped',
	};
	$obj->_cache('nodebug-key', $val);

	# With debug=0, extra_key must be gone from L2
	ok(!exists $l2{'nodebug-key'}{extra_key},
		'debug=0: extra key stripped from L2 HASH');
	ok(exists $l2{'nodebug-key'}{geometry},
		'debug=0: geometry key preserved in L2 HASH');
};

subtest '_cache(): debug=1 preserves all ARRAY item keys in L2' => sub {
	# Purpose: same debug guard but for the ARRAY value branch
	my %l2;
	my $obj = Geo::Coder::List->new(cache => \%l2, debug => $config{debug_v1});

	my $val = [
		{
			geometry  => { location => { lat => $LAT_DC, lng => $LNG_DC } },
			extra_key => 'keep me',
		},
	];
	$obj->_cache('debug-array-key', $val);

	my $stored = $l2{'debug-array-key'};
	ok(ref($stored) eq 'ARRAY', 'debug=1 ARRAY: stored as ARRAY in L2');
	ok(exists $stored->[0]{extra_key},
		'debug=1 ARRAY: extra key preserved in L2');
};

# =============================================================================
# SECTION 18: _cache() -- blessed item in ARRAY with geocoder object ref
#
# Lines 1216-1218: blessed items whose geocoder field is still a reference
# must have it stringified before L2 storage (Storable cannot freeze open handles).
# =============================================================================

subtest '_cache(): blessed ARRAY item -- geocoder ref is stringified for L2' => sub {
	# Purpose: line 1216-1218 -- blessed item in an ARRAY value
	my %l2;
	my $obj = Geo::Coder::List->new(cache => \%l2);

	# Build a blessed item with a geocoder that is still an object reference
	my $fake_geocoder = bless { id => 'gc' }, 'FakeGeocoder';
	my $blessed_item  = bless {
		geocoder => $fake_geocoder,
		geometry => { location => { lat => $LAT_DC, lng => $LNG_DC } },
	}, 'SomeResultClass';

	$obj->_cache('blessed-item-key', [ $blessed_item ]);

	# After the write, the item's geocoder field must be a string (class name)
	ok(!ref($blessed_item->{geocoder}),
		'Blessed item in ARRAY: geocoder ref stringified after _cache write');
	is($blessed_item->{geocoder}, 'FakeGeocoder',
		'Blessed item in ARRAY: geocoder stringified to class name');
};

# =============================================================================
# SECTION 19: geocode() -- debug mode triggers print statements
#
# Various print() calls in geocode() are guarded by $self->{'debug'}.
# We verify the code paths execute without crashing when debug is enabled.
# =============================================================================

subtest 'geocode(): debug=1 -- executes without crashing' => sub {
	# Purpose: smoke-test the debug print paths (lines 344, 376, 409, 423, etc.)
	# We capture STDOUT so the diag output does not pollute test output.
	my $list = Geo::Coder::List->new(debug => $config{debug_v1});
	$list->push(ExtMock::A->new());

	my $g = mock_scoped 'ExtMock::A::geocode' => sub { _osm($LAT_DC, $LNG_DC) };

	# Redirect STDOUT to a string variable during the call
	my $stdout = '';
	open(my $old_stdout, '>&', \*STDOUT) or die "Cannot dup STDOUT: $!";
	close STDOUT;
	open(STDOUT, '>', \$stdout) or die "Cannot redirect STDOUT: $!";

	my $r = $list->geocode($LOC_DC);

	# Restore STDOUT
	close STDOUT;
	open(STDOUT, '>&', $old_stdout) or die "Cannot restore STDOUT: $!";

	ok(defined $r, 'debug=1: result returned correctly');
	like($stdout, qr/\d/, 'debug=1: some output was produced (lat/lng line)');
	_vdiag("debug=1 STDOUT: $stdout");
};

subtest 'geocode(): debug=2 -- Data::Dumper paths execute without crashing' => sub {
	# Purpose: smoke-test the debug>=2 Data::Dumper paths (lines 542-543, 728-731)
	my $list = Geo::Coder::List->new(debug => $config{debug_v2});
	$list->push(ExtMock::A->new());

	my $g = mock_scoped 'ExtMock::A::geocode' => sub { _osm($LAT_DC, $LNG_DC) };

	my $stdout = '';
	open(my $old_stdout, '>&', \*STDOUT) or die "Cannot dup STDOUT: $!";
	close STDOUT;
	open(STDOUT, '>', \$stdout) or die "Cannot redirect STDOUT: $!";

	my $r = $list->geocode($LOC_DC);

	close STDOUT;
	open(STDOUT, '>&', $old_stdout) or die "Cannot restore STDOUT: $!";

	ok(defined $r, 'debug=2: result returned correctly');
	_vdiag("debug=2 STDOUT length: ", length($stdout));
};

# =============================================================================
# SECTION 20: reverse_geocode() -- debug print path
# =============================================================================

subtest 'reverse_geocode(): debug=2 -- Data::Dumper path executes without crash' => sub {
	# Purpose: smoke-test the debug>=2 print in reverse_geocode scalar path (line 985)
	my $list = Geo::Coder::List->new(debug => $config{debug_v2});
	$list->push(ExtMock::A->new());

	my $g = mock_scoped 'ExtMock::A::reverse_geocode' => sub {
		return { display_name => $ADDR_DISPLAY };
	};

	my $stdout = '';
	open(my $old_stdout, '>&', \*STDOUT) or die "Cannot dup STDOUT: $!";
	close STDOUT;
	open(STDOUT, '>', \$stdout) or die "Cannot redirect STDOUT: $!";

	my $r = $list->reverse_geocode(latlng => $LATLNG_DC);

	close STDOUT;
	open(STDOUT, '>&', $old_stdout) or die "Cannot restore STDOUT: $!";

	is($r, $ADDR_DISPLAY, 'debug=2 reverse_geocode: correct result returned');
};

# =============================================================================
# SECTION 21: reverse_geocode() -- list context: result array cached and returned
#
# Line 950: $self->_cache($latlng, \@rc) -- the list-context result is cached.
# =============================================================================

subtest 'reverse_geocode(): list context -- result array is cached (call count)' => sub {
	# Purpose: verify the geocoder is called only once; the second call uses cache.
	# Note: the cache stores the result list as an arrayref (\@rc).  On the second
	# call the cache hit returns that arrayref via "return $rc" at line 884, so the
	# caller receives a one-element list containing the arrayref rather than the
	# expanded string list.  This is existing behaviour; only the call count is
	# asserted here to avoid over-specifying the re-hydration format.
	my $list = Geo::Coder::List->new()->push(ExtMock::A->new());
	my $calls = 0;
	my $g = mock_scoped 'ExtMock::A::reverse_geocode' => sub {
		$calls++;
		return ({ display_name => 'First Ave' }, { display_name => 'Second Ave' });
	};

	my @r1 = $list->reverse_geocode(latlng => $LATLNG_DC);
	my @r2 = $list->reverse_geocode(latlng => $LATLNG_DC);

	is($calls, 1, 'List context reverse: geocoder called once (second call uses cache)');
	ok(scalar @r1 >= 1, 'List context reverse: first call returned at least one result');
	ok(scalar @r2 >= 1, 'List context reverse: second (cached) call returned a result');
};

# =============================================================================
# SECTION 22: geocode() -- geocoders list passed at construction time
#
# Line 114 in function.t covers this, but not the scenario where push() is
# later chained on top of a constructor-populated list.
# =============================================================================

subtest 'geocode(): constructor geocoders + push() chainable' => sub {
	# Purpose: verify that geocoders passed in new() and those added via push()
	# coexist and are tried in order
	my $pre_gc = ExtMock::A->new();
	my $list = Geo::Coder::List->new(geocoders => [$pre_gc]);
	$list->push(ExtMock::B->new());

	my @order;
	my $gA = mock_scoped 'ExtMock::A::geocode' => sub { push @order, 'A'; return () };
	my $gB = mock_scoped 'ExtMock::B::geocode' => sub {
		push @order, 'B';
		return _osm($LAT_DC, $LNG_DC);
	};

	$list->geocode($LOC_DC);
	is_deeply(\@order, [qw(A B)], 'Pre-loaded + pushed geocoders tried in order');
};

# =============================================================================
# SECTION 23: geocode() -- whitespace collapsing before geocoder is called
#
# Line 339: $location =~ s/\s\s+/ /g runs before decode_entities
# =============================================================================

subtest 'geocode(): multiple spaces in location collapsed to one before geocoder' => sub {
	# Purpose: verify whitespace normalization (part of the decode/collapse pipeline)
	my $list = _list_a();
	my $seen = '';
	my $g = mock_scoped 'ExtMock::A::geocode' => sub {
		my ($self_g, %args) = @_;
		$seen = $args{location} // '';
		return _osm($LAT_DC, $LNG_DC);
	};

	$list->geocode(location => 'London,   UK');
	unlike($seen, qr/  /, 'Multiple spaces collapsed before geocoder call');
	like($seen, qr/London, UK/, 'Collapsed to single space');
};

# =============================================================================
# SECTION 24: geocode() -- not-found sentinel via locations hash check
#
# Lines 406-411: the direct locations-hash sentinel check runs when _cache()
# returned undef but the sentinel is in L1.  This avoids a double lookup.
# =============================================================================

subtest 'geocode(): direct sentinel check in locations hash (not-found branch)' => sub {
	# Purpose: inject a not-found sentinel directly to exercise the explicit
	# locations-hash check at lines 406-411
	my $list = _list_a();

	# Write a not-found undef through the normal _cache write path
	$list->_cache($LOC_PARIS, undef);

	# Now geocode() should detect the sentinel in locations hash and return undef
	# without calling any geocoder
	my $calls = 0;
	my $g = mock_scoped 'ExtMock::A::geocode' => sub { $calls++ };

	my $r = $list->geocode($LOC_PARIS);
	is($r, undef, 'Direct sentinel check: returns undef');
	is($calls, 0, 'Direct sentinel check: geocoder not called');
};

# =============================================================================
# SECTION 25: return type checks with Test::Returns
# =============================================================================

subtest 'return type checks: geocode scalar' => sub {
	my $list = _list_a();
	my $g = mock_scoped 'ExtMock::A::geocode' => sub { _osm($LAT_DC, $LNG_DC) };
	my $r = $list->geocode($LOC_DC);
	returns_ok($r, { type => 'hashref' }, 'geocode() scalar returns hashref');
};

subtest 'return type checks: log()' => sub {
	my $list = Geo::Coder::List->new();
	returns_ok($list->log(), { type => 'arrayref' }, 'log() returns arrayref');
};

subtest 'return type checks: flush()' => sub {
	my $list = Geo::Coder::List->new();
	my $ret = $list->flush();
	ok(blessed($ret), 'flush() returns blessed object');
	returns_ok($ret, { type => 'object' }, 'flush() return satisfies object schema');
};

# =============================================================================
# SECTION 26: geocode() shallow-copy cache hit (new in 0.37)
# =============================================================================

subtest 'geocode(): cache hit -- non-HASH cached results bypass the copy (GLP-like)' => sub {
	# The shallow-copy guard is "ref($r) eq 'HASH'"; non-HASH refs (e.g. GLP) are
	# mutated in-place.  Verify GLP in L1 still gets geocoder set to 'cache'.
	my $list = _list_a();
	my $glp  = Geo::Location::Point->new();
	$glp->{lat} = $LAT_DC;
	$glp->{lng} = $LNG_DC;

	# Inject the GLP directly into L1 so the cache-hit path is exercised
	$list->{locations}{$LOC_DC} = $glp;

	my $r = $list->geocode($LOC_DC);

	# GLP is returned (after in-place mutation)
	ok(defined $r,                         'GLP in L1: cache hit returns a result');
	is(ref($r), 'Geo::Location::Point',    'GLP in L1: result is the GLP object');
	is($r->{'geocoder'}, 'cache',          'GLP in L1: geocoder field set to "cache"');
	# Since GLPs are not copied, $r IS the cached object
	is(refaddr($r), refaddr($glp),         'GLP in L1: returned object is the cached one (no copy)');
};

subtest 'geocode(): each scalar cache hit returns a distinct copy object' => sub {
	# Verify that the L1 entry is not the same object as any returned cached result
	my $list = _list_a();
	my $g = mock_scoped 'ExtMock::A::geocode' => sub { _osm($LAT_DC, $LNG_DC) };

	$list->geocode($LOC_DC);                    # populate L1

	my $r1 = $list->geocode($LOC_DC);           # first cache hit
	my $r2 = $list->geocode($LOC_DC);           # second cache hit

	isnt(refaddr($r1), refaddr($r2),
		'Each cache hit is a distinct object');

	# Neither copy should be the L1 entry itself
	my $l1 = $list->{locations}{$LOC_DC};
	isnt(refaddr($r1), refaddr($l1), 'First hit copy is not the L1 entry');
	isnt(refaddr($r2), refaddr($l1), 'Second hit copy is not the L1 entry');
};

subtest 'geocode(): L1 cache entry preserves geocoder object across multiple hits' => sub {
	# Each hit makes copies and stamps geocoder='cache' on them.
	# The L1 entry itself must retain the original geocoder reference.
	my $list = _list_a();
	my $g = mock_scoped 'ExtMock::A::geocode' => sub { _osm($LAT_DC, $LNG_DC) };

	$list->geocode($LOC_DC);    # populate L1
	$list->geocode($LOC_DC);    # hit 1
	$list->geocode($LOC_DC);    # hit 2
	$list->geocode($LOC_DC);    # hit 3

	my $l1 = $list->{locations}{$LOC_DC};
	is(ref($l1->{'geocoder'}), 'ExtMock::A',
		'L1 entry geocoder field still holds the geocoder object after multiple hits');
};

# =============================================================================
# SECTION 27: ua() per-geocoder clone with VERSION (new in 0.37)
# =============================================================================

# Geocoder with a $VERSION for the "ClassName/Version" agent path
{
	package ExtMock::Versioned;
	our $VERSION = '3.14';
	sub new            { bless {}, shift }
	sub geocode        { return () }
	sub reverse_geocode{ return () }
	sub ua             { }
}

# Minimal cloneable UA for offline tests
{
	package ExtMock::CloneUA;
	sub new   { bless { _a => 'libwww-perl/test' }, shift }
	sub clone { bless { %{$_[0]} }, ref($_[0]) }
	sub agent { $_[0]->{_a} = $_[1] if @_ > 1; $_[0]->{_a} }
}

subtest 'ua(): versioned geocoder clone has "ClassName/Version" agent string' => sub {
	my $list = Geo::Coder::List->new()->push(ExtMock::Versioned->new());
	my $ua   = ExtMock::CloneUA->new();

	my $received_ua;
	my $g = mock_scoped 'ExtMock::Versioned::ua' => sub {
		(undef, $received_ua) = @_;
	};

	$list->ua($ua);

	is($received_ua->agent(), 'ExtMock::Versioned/3.14',
		'Versioned geocoder: clone agent is "ClassName/Version"');
};

subtest 'ua(): un-versioned geocoder clone has just the class name as agent' => sub {
	# ExtMock::A has no $VERSION
	my $list = _list_a();
	my $ua   = ExtMock::CloneUA->new();

	my $received_ua;
	my $g = mock_scoped 'ExtMock::A::ua' => sub {
		(undef, $received_ua) = @_;
	};

	$list->ua($ua);

	is($received_ua->agent(), 'ExtMock::A',
		'Un-versioned geocoder: clone agent is just the class name');
};

subtest 'ua(): ua() returns original UA even when cloning' => sub {
	my $list = _list_a();
	my $ua   = ExtMock::CloneUA->new();
	my $g    = mock_scoped 'ExtMock::A::ua' => sub { };

	my $ret = $list->ua($ua);
	is(refaddr($ret), refaddr($ua), 'ua() returns the original UA, not a clone');
};

# =============================================================================
# SECTION 28: reverse_geocode() latlng retry (new in 0.37)
# =============================================================================

subtest 'reverse_geocode(): retry fails with second error -- normal error handling' => sub {
	# If the retry itself also throws (not a latlng error), the error is carpd
	# and the method returns undef.
	my $list = _list_a();
	my $calls = 0;
	my $g = mock_scoped 'ExtMock::A::reverse_geocode' => sub {
		my ($self, %args) = @_;
		$calls++;
		if(exists $args{latlng}) {
			die "validate_strict: Unknown parameter 'latlng'\n";
		}
		die "second error: connection refused\n";
	};

	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };
	my $r = $list->reverse_geocode(latlng => $LATLNG_DC);

	is($calls, 2,     'Retry that also fails: geocoder called twice total');
	is($r,     undef, 'Retry that also fails: result is undef');
	ok($warned,       'Retry that also fails: second error is carpd');
};

subtest 'reverse_geocode(): scalar context retry -- lat and lon are correct' => sub {
	my $list = _list_a();
	my %retry_params;
	my $g = mock_scoped 'ExtMock::A::reverse_geocode' => sub {
		my ($self, %args) = @_;
		die "validate_strict: Unknown parameter 'latlng'\n" if exists $args{latlng};
		%retry_params = %args;
		return { display_name => 'Retry Scalar Address' };
	};

	my $r = $list->reverse_geocode(latlng => $LATLNG_DC);

	is($r, 'Retry Scalar Address', 'Scalar context retry: correct address returned');
	is($retry_params{lat}, $LAT_DC, 'Retry: lat has correct value from split');
	is($retry_params{lon}, $LNG_DC, 'Retry: lon has correct value from split');
	ok(!exists $retry_params{latlng},  'Retry: latlng key is absent');
};

done_testing();

# =============================================================================
# UNREACHABLE / DEAD-CODE ANALYSIS
# Paths identified as unreachable or having unreachable branches.
# Listed here for author review.
#
# 1. lib/Geo/Coder/List.pm line 495:
#    ((ref($rc[0]) eq 'ARRAY') && (scalar(keys %{$rc[0][0]}) == 0))
#
#    REASON: If $rc[0] is an ARRAY ref, $rc[0][0] is its first element.
#    Under "use strict refs", keys(%{undef}) raises "Not a HASH reference".
#    The condition is only safe when $rc[0][0] is an explicit empty hashref {}.
#    No known geocoder produces that structure.
#    Safer rewrite:
#        ref($rc[0]) eq 'ARRAY'
#        && ref($rc[0][0]) eq 'HASH'
#        && scalar(keys %{$rc[0][0]}) == 0
#
# 2. lib/Geo/Coder/List.pm lines 734-756:
#    if(defined($rc[0])) { ... return $good_result }
#
#    REASON: A geocoder returning (undef, {lat=>1,lon=>2}) would cause
#    $good_result to be set but defined($rc[0]) to be FALSE.  The valid
#    result is then silently discarded.  No known geocoder produces a
#    leading undef.  Latent bug: the guard should be "if(defined($good_result))".
#
# 3. lib/Geo/Coder/List.pm line 1260-1263 (_cache HASH):
#    } else {
#        $duration = $self->{'cache_miss_duration'};   # '1 week'
#        $rc = undef;
#    }
#
#    REASON: The preceding check
#        defined($value->{geometry}{location}{lat})
#    auto-vivifies $value->{geometry} as {}.  The subsequent
#        elsif(defined($value->{geometry}))
#    is therefore ALWAYS true.  The else branch can never execute.
#    Fix: use exists() instead of defined() for the geometry check, or
#    check for the key before the lat access.
#
# 4. lib/Geo/Coder/List.pm lines 1234-1236 (_cache ARRAY):
#    $duration //= defined($item->{geometry})
#        ? $self->{'cache_part_duration'}
#        : $self->{'cache_miss_duration'};
#
#    REASON: Same auto-vivification issue.  The access
#        defined($item->{geometry}{location}{lat})
#    at line 1232 auto-vivifies $item->{geometry}.  The ternary's false
#    arm (cache_miss_duration) can never be reached.
# =============================================================================

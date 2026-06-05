#!/usr/bin/env perl

# t/mutant_killers.t -- Mutant-killing tests derived from xt/mutant_20260604_014320.t
#
# Each subtest is named after the mutant ID it kills and asserts both the
# true AND false outcome of the condition being mutated, so an inverted or
# boundary-flipped condition will cause a test failure.

use strict;
use warnings;

use lib 'lib';

use Readonly;
use Scalar::Util qw(blessed refaddr);
use Test::Most;
use Test::Mockingbird;
use Test::Returns;

BEGIN { use_ok('Geo::Coder::List') }

# =============================================================================
# Configuration -- all magic values defined here
# =============================================================================

Readonly::Scalar my $LOC_PARIS    => 'Paris, France';
Readonly::Scalar my $LOC_LONDON   => 'London, UK';
Readonly::Scalar my $LOC_DC       => 'Washington, DC, USA';
Readonly::Scalar my $LATLNG_DC    => '38.8977,-77.0365';
Readonly::Scalar my $LAT_DC       => 38.8977;
Readonly::Scalar my $LNG_DC       => -77.0365;
Readonly::Scalar my $ADDR_DISPLAY => '10 Downing Street, London';

# Configurable test values
my %config = (
	limit_zero   => 0,
	limit_one    => 1,
	limit_two    => 2,
	debug_off    => 0,
	debug_v1     => 1,
	debug_v2     => 2,
	no_result    => undef,
	cache_str    => 'cache',
);

# =============================================================================
# Inline geocoder stubs -- Mockingbird replaces methods per test
# =============================================================================

{
	package Mutant::Geocoder::A;
	sub new             { bless {}, shift }
	sub geocode         { return () }
	sub reverse_geocode { return () }
	sub ua              { $_[0]->{_ua} = $_[1] if @_ > 1; $_[0]->{_ua} }
}

{
	package Mutant::Geocoder::B;
	sub new             { bless {}, shift }
	sub geocode         { return () }
	sub reverse_geocode { return () }
	sub ua              { }
}

# UA with clone() and agent() -- triggers the per-geocoder clone path in ua()
{
	package Mutant::CloneableUA;
	sub new   { bless { _a => 'libwww-perl/test' }, shift }
	sub clone { bless { %{$_[0]} }, ref($_[0]) }
	sub agent { $_[0]->{_a} = $_[1] if @_ > 1; $_[0]->{_a} }
}

# UA without clone() -- exercises the direct-pass fallback in ua()
{
	package Mutant::DirectUA;
	sub new { bless {}, shift }
	# deliberately no clone() or agent()
}

# Geo::Location::Point stub for the GLP cache-hit path
{
	package Geo::Location::Point;
	sub new { bless {}, shift }
}

package main;

# ── Helpers ───────────────────────────────────────────────────────────────────

# Build a list with one Mutant::Geocoder::A geocoder
sub _list_a { Geo::Coder::List->new()->push(Mutant::Geocoder::A->new()) }

# Standard OSM-style result hashref
sub _osm { { lat => $_[0], lon => $_[1] } }

# Diagnostic helper: emit detail only when TEST_VERBOSE is set
sub _vd { diag(@_) if $ENV{TEST_VERBOSE} }

# =============================================================================
# MUTANT: NUM_BOUNDARY_166_29_< -- new() function-style arg count boundary
#
# Source:  if(scalar keys %{$params} > 0)
# Kill:    0 keys must NOT trigger the carp; 1 key MUST trigger it.
#          A boundary flip to < or <= would either always carp or never carp.
# =============================================================================

subtest 'NUM_BOUNDARY_166: ::new() with 0 args does NOT carp' => sub {
	# No args: 0 keys, condition (> 0) is false, carp must NOT fire
	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };
	my $obj = Geo::Coder::List::new('Geo::Coder::List');
	is($warned, 0,           '0-key function call: no warning emitted');
	ok(defined $obj,         '0-key function call: returns an object');
};

subtest 'NUM_BOUNDARY_166: ::new() with args carps and returns undef' => sub {
	# 1 key: condition (> 0) is true, carp fires, undef returned
	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };
	my $obj = Geo::Coder::List::new(undef, debug => 1);
	ok($warned,          '1-key function call: warning emitted');
	ok(!defined $obj,    '1-key function call: returns undef');
	_vd('warned count:', $warned);
};

# =============================================================================
# MUTANT: COND_INV_366 / BOOL_NEGATE_377 -- cache hit scalar vs list context
#
# Source:  if(!wantarray) { ... result => $rc ... return $rc }
# Kill:    Scalar context must return a single hashref, not a list.
#          Inverting to unless(!wantarray) = if(wantarray) would return
#          the scalar path in list context and vice versa.
# =============================================================================

subtest 'COND_INV_366/BOOL_NEGATE_377: scalar cache hit returns one hashref' => sub {
	my $list = _list_a();
	my $g = mock_scoped 'Mutant::Geocoder::A::geocode' => sub { _osm($LAT_DC, $LNG_DC) };

	# Populate L1 cache with a live call
	$list->geocode($LOC_DC);
	# Second call: scalar cache hit
	my $r = $list->geocode($LOC_DC);

	# Must be a single HASH, not a list
	ok(defined $r,          'Scalar cache hit: result is defined');
	is(ref($r), 'HASH',     'Scalar cache hit: result is a HASH ref');
	is($r->{geocoder}, $config{cache_str},
		'Scalar cache hit: geocoder field is "cache"');

	# Log entry must have result key set (BOOL_NEGATE_377)
	my ($log_entry) = grep { ($_->{geocoder} // '') eq 'cache'
	                       && ($_->{wantarray} // 1) == 0 } @{$list->log()};
	ok(defined $log_entry,          'Log entry written for scalar cache hit');
	ok(exists $log_entry->{result}, 'Log entry has "result" key');
	_vd('log result:', $log_entry->{result});
};

subtest 'COND_INV_366: list cache hit returns array, not scalar' => sub {
	my $list = _list_a();
	my $g = mock_scoped 'Mutant::Geocoder::A::geocode' => sub { _osm($LAT_DC, $LNG_DC) };

	$list->geocode($LOC_DC);     # populate L1
	my @r = $list->geocode($LOC_DC);   # list cache hit

	# Must get an array back, not collapse to a scalar
	ok(scalar @r >= 1, 'List cache hit: returns at least one element');
	is($r[0]->{geocoder}, $config{cache_str}, 'List cache hit: geocoder is "cache"');
};

# =============================================================================
# MUTANT: COND_INV_394/BOOL_NEGATE_401 -- $allempty loop in list cache hit
#
# Source:  my $allempty = 1; ... return if $allempty; return @rc;
# Kill:    A list with valid geometry must be returned (allempty stays 0).
#          An all-empty list must return nothing (allempty = 1).
# =============================================================================

subtest 'COND_INV_394/BOOL_NEGATE_401: list hit with geometry returns results' => sub {
	# Valid geometry → $allempty becomes 0 → @rc returned, not empty list
	my $list = _list_a();
	# Plant a valid HASH directly into L1
	$list->{locations}{$LOC_PARIS} = [
		{ geometry => { location => { lat => $LAT_DC, lng => $LNG_DC } } }
	];

	my @r = $list->geocode($LOC_PARIS);
	ok(scalar @r >= 1, 'List cache hit with geometry: results returned');
	_vd('allempty=0 path: returned', scalar @r, 'result(s)');
};

subtest 'COND_INV_394/BOOL_NEGATE_401: list hit with no geometry returns empty' => sub {
	# No geometry in any element → $allempty stays 1 → return nothing
	my $list = _list_a();
	$list->{locations}{$LOC_PARIS} = [ { some_key => 'no coords' } ];

	my @r = $list->geocode($LOC_PARIS);
	is(scalar @r, 0, 'List cache hit with no geometry: empty list returned');
	_vd('allempty=1 path: correctly returned empty list');
};

# =============================================================================
# MUTANT: COND_INV_406/COND_INV_408/BOOL_NEGATE_410 -- not-found sentinel
#
# Source:  if(exists $self->{'locations'}{$location})
#          if(ref($stored) && ref($stored) eq _NOT_FOUND_CLASS)
#          return wantarray ? () : undef;
# Kill:    After a miss, the sentinel is stored and subsequent calls must
#          return undef without hitting the geocoder.
# =============================================================================

subtest 'COND_INV_406/408/BOOL_NEGATE_410: not-found sentinel avoids re-query' => sub {
	my $list  = _list_a();
	my $calls = 0;
	my $g = mock_scoped 'Mutant::Geocoder::A::geocode' => sub { $calls++; return () };

	# First call: miss, sentinel stored
	my $r1 = $list->geocode($LOC_PARIS);
	# Second call: sentinel should prevent geocoder call
	my $r2 = $list->geocode($LOC_PARIS);

	is($calls,  1,     'Sentinel path: geocoder called only once');
	is($r1, undef,     'First miss: returns undef');
	is($r2, undef,     'Second miss (sentinel): also undef');
	_vd('sentinel call count:', $calls);
};

subtest 'BOOL_NEGATE_410: not-found sentinel returns () in list context' => sub {
	my $list = _list_a();
	my $g = mock_scoped 'Mutant::Geocoder::A::geocode' => sub { return () };

	$list->geocode($LOC_PARIS);    # populate sentinel
	my @r = $list->geocode($LOC_PARIS);   # list context sentinel hit

	is(scalar @r, 0, 'Sentinel list context: empty list returned');
};

# =============================================================================
# MUTANT: COND_INV_422/NUM_BOUNDARY_424 -- limit guard in geocode()
#
# Source:  if(exists($geocoder->{'limit'}) && ...) { if($limit <= 0) { next } }
# Kill:    limit=0 must skip geocoder; limit=1 must use it exactly once.
#          Boundary flip <= to < means limit=0 would NOT skip (wrong).
# =============================================================================

subtest 'NUM_BOUNDARY_424: limit=0 means geocoder is skipped immediately' => sub {
	my $list = Geo::Coder::List->new();
	$list->push({ geocoder => Mutant::Geocoder::A->new(), limit => $config{limit_zero} });

	my $calls = 0;
	my $g = mock_scoped 'Mutant::Geocoder::A::geocode' => sub { $calls++; _osm($LAT_DC, $LNG_DC) };

	my $r = $list->geocode($LOC_DC);
	is($calls, 0,  'Limit=0: geocoder called zero times');
	is($r, undef,  'Limit=0: result is undef');
};

subtest 'NUM_BOUNDARY_424: limit=1 uses geocoder once then skips' => sub {
	my $list = Geo::Coder::List->new();
	$list->push({ geocoder => Mutant::Geocoder::A->new(), limit => $config{limit_one} });

	my $calls = 0;
	my $g = mock_scoped 'Mutant::Geocoder::A::geocode' => sub { $calls++; _osm($LAT_DC, $LNG_DC) };

	$list->geocode($LOC_DC);         # consumes limit (1 -> 0)
	$list->geocode($LOC_LONDON);     # limit=0: skip
	is($calls, 1, 'Limit=1: geocoder called exactly once');
};

# =============================================================================
# MUTANT: COND_INV_431/COND_INV_434 -- regex guard in geocode()
#
# Source:  if(my $regex = $geocoder->{'regex'}) { if($location !~ $regex) { next } }
# Kill:    Non-matching location must skip geocoder; matching must proceed.
# =============================================================================

subtest 'COND_INV_431/434: regex non-match skips geocoder' => sub {
	my $list = Geo::Coder::List->new();
	# Geocoder only handles USA locations
	$list->push({ regex => qr/USA$/, geocoder => Mutant::Geocoder::A->new() });

	my $calls = 0;
	my $g = mock_scoped 'Mutant::Geocoder::A::geocode' => sub { $calls++; _osm($LAT_DC, $LNG_DC) };

	# UK location does not match /USA$/
	my $r = $list->geocode($LOC_LONDON);
	is($calls, 0,  'Regex non-match: geocoder not called');
	is($r, undef,  'Regex non-match: result is undef');
};

subtest 'COND_INV_434: regex match allows geocoder to run' => sub {
	my $list = Geo::Coder::List->new();
	$list->push({ regex => qr/USA$/, geocoder => Mutant::Geocoder::A->new() });

	my $calls = 0;
	my $g = mock_scoped 'Mutant::Geocoder::A::geocode' => sub { $calls++; _osm($LAT_DC, $LNG_DC) };

	# USA location matches /USA$/
	my $r = $list->geocode($LOC_DC);
	is($calls, 1, 'Regex match: geocoder called once');
	ok(defined $r, 'Regex match: result returned');
};

# =============================================================================
# MUTANT: NUM_BOUNDARY_539 -- debug >= 2 print in POSSIBLE_LOCATION
#
# Source:  Data::Dumper->new([\$l])->Dump() if($self->{'debug'} >= 2)
# Kill:    debug=1 must NOT trigger the >= 2 dump; debug=2 MUST trigger it.
#          A boundary flip to > means debug=2 would not trigger.
# =============================================================================

subtest 'NUM_BOUNDARY_539: debug=1 does not trigger debug>=2 dump' => sub {
	# With debug=1, no Data::Dumper print for individual candidates
	my $list = Geo::Coder::List->new(debug => $config{debug_v1});
	$list->push(Mutant::Geocoder::A->new());
	my $g = mock_scoped 'Mutant::Geocoder::A::geocode' => sub { _osm($LAT_DC, $LNG_DC) };

	my $stdout = '';
	open(my $old_stdout, '>&', \*STDOUT) or die;
	close STDOUT;
	open(STDOUT, '>', \$stdout) or die;
	$list->geocode($LOC_DC);
	close STDOUT;
	open(STDOUT, '>&', $old_stdout) or die;

	# At debug=1, the candidate Dumper output should NOT appear
	unlike($stdout, qr/\$VAR/, 'debug=1: no Data::Dumper dump of candidates');
	_vd('debug=1 stdout length:', length($stdout));
};

subtest 'NUM_BOUNDARY_539: debug=2 triggers the dump' => sub {
	my $list = Geo::Coder::List->new(debug => $config{debug_v2});
	$list->push(Mutant::Geocoder::A->new());
	my $g = mock_scoped 'Mutant::Geocoder::A::geocode' => sub { _osm($LAT_DC, $LNG_DC) };

	my $stdout = '';
	open(my $old_stdout, '>&', \*STDOUT) or die;
	close STDOUT;
	open(STDOUT, '>', \$stdout) or die;
	$list->geocode($LOC_DC);
	close STDOUT;
	open(STDOUT, '>&', $old_stdout) or die;

	# At debug=2 the @rc Dumper dump fires (num-matches line)
	like($stdout, qr/Number of matches|VAR/, 'debug=2: dump-related output produced');
};

# =============================================================================
# MUTANT: COND_INV_544 -- bare scalar guard: "next unless ref($l)"
#
# Source:  next unless ref($l);
# Kill:    A geocoder returning 0 or "" must not crash the module; it should
#          skip that element and return undef.
#          Invert to "next if ref($l)" means all refs would be skipped.
# =============================================================================

subtest 'COND_INV_544: bare-integer result skipped; undef returned' => sub {
	my $list = _list_a();
	my $g = mock_scoped 'Mutant::Geocoder::A::geocode' => sub { return 0 };

	my $r = $list->geocode($LOC_DC);
	is($r, undef, 'Bare integer 0: module does not crash, returns undef');
};

subtest 'COND_INV_544: bare-string result skipped; undef returned' => sub {
	my $list = _list_a();
	my $g = mock_scoped 'Mutant::Geocoder::A::geocode' => sub { return 'some string' };

	my $r = $list->geocode($LOC_DC);
	is($r, undef, 'Bare string: module does not crash, returns undef');
};

subtest 'COND_INV_544: HASH ref result is NOT skipped; result returned' => sub {
	# Verify the inverse: a proper HASH ref must pass the guard
	my $list = _list_a();
	my $g = mock_scoped 'Mutant::Geocoder::A::geocode' => sub { _osm($LAT_DC, $LNG_DC) };

	my $r = $list->geocode($LOC_DC);
	ok(defined $r, 'HASH ref result: not skipped by bare-scalar guard');
};

# =============================================================================
# MUTANT: COND_INV_548 -- Geo::Location::Point branch
#
# Source:  if(ref($l) eq 'Geo::Location::Point')
# Kill:    A GLP object must be handled via the GLP path, not the HASH path.
#          Inverting condition would skip GLP handling for GLP objects.
# =============================================================================

subtest 'COND_INV_548: Geo::Location::Point result is handled via GLP path' => sub {
	my $list = _list_a();
	my $g = mock_scoped 'Mutant::Geocoder::A::geocode' => sub {
		# Return a blessed GLP with lat/lng
		my $glp = bless { lat => $LAT_DC, lng => $LNG_DC }, 'Geo::Location::Point';
		return $glp;
	};

	my $r = $list->geocode($LOC_DC);
	ok(defined $r,                     'GLP result: returned defined');
	is(ref($r), 'Geo::Location::Point', 'GLP result: type preserved as GLP');
	ok(defined $r->{geometry}{location}{lat},
		'GLP result: geometry.location.lat populated');
	is($r->{geometry}{location}{lat}, $LAT_DC, 'GLP result: lat correct');
};

# =============================================================================
# MUTANT: COND_INV_614 -- Bing "point" format
#
# Source:  elsif($l->{point}) { $lat = $l->{point}->{coordinates}[0]; ... }
# Kill:    point format must map coordinates[0]=lat, [1]=lng.
#          Inverting condition means point format would fall through to next branch.
# =============================================================================

subtest 'COND_INV_614: Bing point.coordinates format normalised correctly' => sub {
	my $list = _list_a();
	my $g = mock_scoped 'Mutant::Geocoder::A::geocode' => sub {
		return { point => { coordinates => [$LAT_DC, $LNG_DC] } };
	};

	my $r = $list->geocode($LOC_DC);
	ok(defined $r, 'Bing point: result returned');
	is($r->{geometry}{location}{lat}, $LAT_DC, 'Bing point: lat from coordinates[0]');
	is($r->{geometry}{location}{lng}, $LNG_DC, 'Bing point: lng from coordinates[1]');
};

# =============================================================================
# MUTANT: COND_INV_625 -- postcodes.io latitude/longitude format
#
# Source:  elsif(defined($l->{latitude})) { $lat = $l->{latitude}; ... }
# Kill:    latitude/longitude keys must map to canonical geometry.
# =============================================================================

subtest 'COND_INV_625: postcodes.io latitude/longitude normalised correctly' => sub {
	my $list = _list_a();
	my $g = mock_scoped 'Mutant::Geocoder::A::geocode' => sub {
		return { latitude => $LAT_DC, longitude => $LNG_DC };
	};

	my $r = $list->geocode($LOC_DC);
	ok(defined $r, 'latitude/longitude: result returned');
	is($r->{geometry}{location}{lat}, $LAT_DC, 'latitude/longitude: lat correct');
	is($r->{geometry}{location}{lng}, $LNG_DC, 'latitude/longitude: lng correct');
};

# =============================================================================
# MUTANT: COND_INV_652 -- GeoNames lat/lng branch (fallback after lat+lon fails)
#
# Source:  elsif(defined($l->{lat})) { $lat = $l->{lat}; $long = $l->{lng}; }
# Kill:    A result with lat + lng (but no lon) must use the GeoNames branch.
# =============================================================================

subtest 'COND_INV_652: GeoNames lat+lng format (no lon key) normalised correctly' => sub {
	my $list = _list_a();
	# No 'lon' key -- only 'lat' and 'lng'; forces the GeoNames fallback branch
	my $g = mock_scoped 'Mutant::Geocoder::A::geocode' => sub {
		return { lat => $LAT_DC, lng => $LNG_DC };
	};

	my $r = $list->geocode($LOC_DC);
	ok(defined $r, 'GeoNames lat/lng: result returned');
	is($r->{geometry}{location}{lat}, $LAT_DC, 'GeoNames lat/lng: lat correct');
	is($r->{geometry}{location}{lng}, $LNG_DC, 'GeoNames lat/lng: lng correct');
};

# =============================================================================
# MUTANT: COND_INV_685 -- coordinate assignment: if(defined($lat) && defined($long))
#
# Source:  if(defined($lat) && defined($long)) { populate geometry } else { delete }
# Kill:    When both lat+long are defined, geometry must be set.
#          When either is undef, geometry must be deleted (result not returned).
# =============================================================================

subtest 'COND_INV_685: both lat+long defined -> geometry populated' => sub {
	my $list = _list_a();
	my $g = mock_scoped 'Mutant::Geocoder::A::geocode' => sub {
		return { lat => $LAT_DC, lon => $LNG_DC };
	};

	my $r = $list->geocode($LOC_DC);
	ok(defined $r,                            'lat+long both defined: result returned');
	is($r->{geometry}{location}{lat}, $LAT_DC, 'lat+long: geometry.lat set');
	is($r->{geometry}{location}{lng}, $LNG_DC, 'lat+long: geometry.lng set');
};

subtest 'COND_INV_685: unrecognised format gives no coordinates -> undef returned' => sub {
	# When no branch extracts lat/long, $lat/$long stay undef -> geometry deleted
	my $list = _list_a();
	my $g = mock_scoped 'Mutant::Geocoder::A::geocode' => sub {
		return { completely_unknown => 'field' };
	};

	my $r = $list->geocode($LOC_DC);
	is($r, undef, 'Unextractable coordinates: result is undef');
};

# =============================================================================
# MUTANT: COND_INV_735 -- if(defined($rc[0])) result gate
#
# Source:  if(defined($rc[0])) { ... return $good_result }
# Kill:    A valid result must be returned when rc[0] is defined.
# =============================================================================

subtest 'COND_INV_735: valid result is returned when rc[0] is defined' => sub {
	my $list = _list_a();
	my $g = mock_scoped 'Mutant::Geocoder::A::geocode' => sub { _osm($LAT_DC, $LNG_DC) };

	my $r = $list->geocode($LOC_DC);
	ok(defined $r,                             'rc[0] defined: result returned');
	is($r->{geometry}{location}{lat}, $LAT_DC, 'rc[0] defined: lat correct');
};

# =============================================================================
# MUTANT: BOOL_NEGATE_762 / RETURN_UNDEF_762 -- end-of-geocode() no-match return
#
# Source:  return wantarray ? () : undef;
# Kill:    Empty geocoder chain must return undef in scalar context, () in list.
# =============================================================================

subtest 'BOOL_NEGATE_762: empty chain returns undef in scalar context' => sub {
	my $list = Geo::Coder::List->new();    # no geocoders
	my $r = $list->geocode($LOC_DC);
	is($r, undef, 'Empty chain scalar: returns undef, not false or 0');
};

subtest 'BOOL_NEGATE_762: empty chain returns () in list context' => sub {
	my $list = Geo::Coder::List->new();
	my @r = $list->geocode($LOC_DC);
	is(scalar @r, 0, 'Empty chain list: returns empty list');
};

subtest 'BOOL_NEGATE_762: all-miss chain returns undef, not 0 or false' => sub {
	my $list = _list_a();
	my $g = mock_scoped 'Mutant::Geocoder::A::geocode' => sub { return () };

	my $r = $list->geocode($LOC_DC);
	# Explicitly check for undef, not just falsiness -- negating the return
	# expression could produce 0 or '' which are also false but wrong
	ok(!defined $r, 'All-miss: returns undef (strictly undefined)');
};

# =============================================================================
# MUTANT: COND_INV_879/BOOL_NEGATE_820 -- ua() early return and clone condition
#
# Source:  return unless $ua   (line 820-ish)
#          if($ua->can('clone') && $ua->can('agent'))   (879-ish)
# Kill:    ua(undef) must return undef; ua(obj) must propagate;
#          cloneable UA triggers clone; non-cloneable passes through.
# =============================================================================

subtest 'BOOL_NEGATE_820: ua() with no argument returns undef' => sub {
	my $list = Geo::Coder::List->new()->push(Mutant::Geocoder::A->new());
	my $ret = $list->ua();    # no argument
	ok(!defined $ret, 'ua() with no arg returns undef');
};

subtest 'BOOL_NEGATE_820: ua() with a UA argument returns that UA' => sub {
	my $list = Geo::Coder::List->new()->push(Mutant::Geocoder::A->new());
	my $ua   = Mutant::DirectUA->new();
	my $mock = mock_scoped 'Mutant::Geocoder::A::ua' => sub { };

	my $ret = $list->ua($ua);
	is(refaddr($ret), refaddr($ua), 'ua() with arg returns the UA object');
};

subtest 'COND_INV_879/BOOL_NEGATE_880: cloneable UA -- geocoder gets a clone' => sub {
	# ua->can('clone') && ua->can('agent') must both be true for clone path
	my $list = Geo::Coder::List->new()->push(Mutant::Geocoder::A->new());
	my $ua   = Mutant::CloneableUA->new();

	my $received;
	my $mock = mock_scoped 'Mutant::Geocoder::A::ua' => sub { (undef, $received) = @_ };

	$list->ua($ua);

	isnt(refaddr($received), refaddr($ua), 'Cloneable UA: geocoder got a clone');
	like($received->agent(), qr/^Mutant::Geocoder::A/,
		'Cloneable UA: clone has class-based agent');
};

subtest 'COND_INV_889/890: non-cloneable UA is passed directly' => sub {
	# DirectUA has no clone() -- must fall through to direct pass
	my $list = Geo::Coder::List->new()->push(Mutant::Geocoder::A->new());
	my $ua   = Mutant::DirectUA->new();

	my $received;
	my $mock = mock_scoped 'Mutant::Geocoder::A::ua' => sub { (undef, $received) = @_ };

	$list->ua($ua);

	is(refaddr($received), refaddr($ua), 'Non-cloneable UA: same reference passed');
};

# =============================================================================
# MUTANT: NUM_BOUNDARY_892 / COND_INV_923 -- reverse_geocode() limit guard
#
# Source:  if($limit <= 0) { next }  and  if(ref($geocoder) eq 'HASH')
# Kill:    limit=0 in a hashref entry must be skipped; limit=1 used once.
# =============================================================================

subtest 'NUM_BOUNDARY_892: reverse_geocode skips hashref entry with limit=0' => sub {
	my $list = Geo::Coder::List->new();
	$list->push({ geocoder => Mutant::Geocoder::A->new(), limit => $config{limit_zero} });

	my $calls = 0;
	my $g = mock_scoped 'Mutant::Geocoder::A::reverse_geocode' => sub {
		$calls++;
		return { display_name => 'Test Address' };
	};

	my $r = $list->reverse_geocode(latlng => $LATLNG_DC);
	is($calls, 0,  'reverse_geocode limit=0: geocoder never called');
	is($r, undef,  'reverse_geocode limit=0: returns undef');
};

subtest 'COND_INV_923: hashref entry is unwrapped to expose the geocoder' => sub {
	# The geocoder inside a regex-hashref must still be called
	my $list = Geo::Coder::List->new();
	$list->push({ regex => qr/France/, geocoder => Mutant::Geocoder::A->new() });

	my $calls = 0;
	my $g = mock_scoped 'Mutant::Geocoder::A::reverse_geocode' => sub {
		$calls++;
		return { display_name => $ADDR_DISPLAY };
	};

	$list->reverse_geocode(latlng => $LATLNG_DC);
	# The geocoder has no regex restriction on reverse_geocode (lat/lng, not location)
	# But regardless, it must be unwrapped and called
	is($calls, 1, 'Hashref entry: geocoder unwrapped and called once');
};

# =============================================================================
# MUTANT: COND_INV_902 -- reverse_geocode() if(wantarray) context split
#
# Source:  if(wantarray) { ... list processing ... } else { ... scalar ... }
# Kill:    Scalar call must return a plain string; list call must return array.
#          Inversion swaps which path runs for each context.
# =============================================================================

subtest 'COND_INV_902: scalar context returns a plain string' => sub {
	my $list = Geo::Coder::List->new()->push(Mutant::Geocoder::A->new());
	my $g = mock_scoped 'Mutant::Geocoder::A::reverse_geocode' => sub {
		return { display_name => $ADDR_DISPLAY };
	};

	my $r = $list->reverse_geocode(latlng => $LATLNG_DC);
	ok(!ref($r),          'Scalar context: result is a plain string');
	is($r, $ADDR_DISPLAY, 'Scalar context: correct address returned');
};

subtest 'COND_INV_902: list context returns an array of strings' => sub {
	my $list = Geo::Coder::List->new()->push(Mutant::Geocoder::A->new());
	my $g = mock_scoped 'Mutant::Geocoder::A::reverse_geocode' => sub {
		return ( { display_name => 'First Ave' }, { display_name => 'Second Ave' } );
	};

	my @r = $list->reverse_geocode(latlng => $LATLNG_DC);
	ok(scalar @r >= 1,   'List context: at least one result');
	ok(!ref($r[0]),      'List context: element is a plain string');
	is($r[0], 'First Ave', 'List context: correct first address');
};

# =============================================================================
# MUTANT: BOOL_NEGATE_947 / RETURN_UNDEF_947 -- latlng retry in reverse_geocode
#
# Source:  if($@ =~ /Unknown parameter.*latlng|latlng.*[Uu]nknown/s)
# Kill:    Matching error triggers retry; non-matching error does not.
# =============================================================================

subtest 'BOOL_NEGATE_947: latlng-rejection error triggers retry without latlng' => sub {
	my $list = Geo::Coder::List->new()->push(Mutant::Geocoder::A->new());
	my %params_on_retry;
	my $g = mock_scoped 'Mutant::Geocoder::A::reverse_geocode' => sub {
		my ($self, %args) = @_;
		die "validate_strict: Unknown parameter 'latlng'\n" if exists $args{latlng};
		%params_on_retry = %args;
		return { display_name => 'Retried OK' };
	};

	my $r = $list->reverse_geocode(latlng => $LATLNG_DC);
	is($r, 'Retried OK',           'Latlng retry: result returned after retry');
	ok(!exists $params_on_retry{latlng}, 'Latlng retry: latlng absent on retry call');
	ok( exists $params_on_retry{lat},    'Latlng retry: lat present on retry');
	ok( exists $params_on_retry{lon},    'Latlng retry: lon present on retry');
};

subtest 'BOOL_NEGATE_947: non-latlng error is NOT retried (scalar)' => sub {
	my $list = Geo::Coder::List->new()->push(Mutant::Geocoder::A->new());
	my $calls = 0;
	my $g = mock_scoped 'Mutant::Geocoder::A::reverse_geocode' => sub {
		$calls++;
		die "network error\n";
	};

	local $SIG{__WARN__} = sub { };
	$list->reverse_geocode(latlng => $LATLNG_DC);
	is($calls, 1, 'Non-latlng error: called exactly once (no retry)');
};

# =============================================================================
# MUTANT: COND_INV_954 -- if($@) error handling in list reverse_geocode
#
# Source:  if($@) { carp; next }
# Kill:    An error after retry must still be caught and the geocoder skipped.
# =============================================================================

subtest 'COND_INV_954: error in list reverse_geocode is carpd and skipped' => sub {
	my $list = Geo::Coder::List->new({ carp_on_warn => 1 });
	$list->push(Mutant::Geocoder::A->new())->push(Mutant::Geocoder::B->new());

	my $gA = mock_scoped 'Mutant::Geocoder::A::reverse_geocode' => sub {
		die "simulated failure\n";
	};
	my $gB = mock_scoped 'Mutant::Geocoder::B::reverse_geocode' => sub {
		return ({ display_name => 'Fallback Address' });
	};

	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };
	my @r = $list->reverse_geocode(latlng => $LATLNG_DC);

	ok($warned,             'List rg error: warning emitted');
	ok(scalar @r >= 1,      'List rg error: fallback geocoder used');
	is($r[0], 'Fallback Address', 'List rg error: correct address from fallback');
};

# =============================================================================
# MUTANT: COND_INV_969/BOOL_NEGATE_978/RETURN_UNDEF_978 -- list context result extraction
#
# Source:  foreach my $loc (@locs) {
#            if(my $name = $loc->{'display_name'}) { push @rc, $name }
#            elsif($loc->{'city'}) { push @rc, _build_ca_address($loc) }
#            elsif($loc->{features}) { push @rc, formatted; last }
#          }
# Kill:    Each extraction branch must produce the correct string in @rc.
# =============================================================================

subtest 'COND_INV_969: display_name extracted in list context' => sub {
	my $list = Geo::Coder::List->new()->push(Mutant::Geocoder::A->new());
	my $g = mock_scoped 'Mutant::Geocoder::A::reverse_geocode' => sub {
		return ( { display_name => 'OSM Address A' }, { display_name => 'OSM Address B' } );
	};

	my @r = $list->reverse_geocode(latlng => $LATLNG_DC);
	ok(scalar @r >= 2, 'List display_name: multiple results extracted');
	is($r[0], 'OSM Address A', 'List display_name: first result correct');
	is($r[1], 'OSM Address B', 'List display_name: second result correct');
};

subtest 'BOOL_NEGATE_978/RETURN_UNDEF_978: GeoApify features extracted in list context' => sub {
	my $list = Geo::Coder::List->new()->push(Mutant::Geocoder::A->new());
	my $g = mock_scoped 'Mutant::Geocoder::A::reverse_geocode' => sub {
		return (
			{ features => [ { properties => { formatted => 'GeoApify Result' } } ] },
		);
	};

	my @r = $list->reverse_geocode(latlng => $LATLNG_DC);
	ok(scalar @r >= 1,         'List GeoApify: result extracted');
	is($r[0], 'GeoApify Result', 'List GeoApify: correct formatted string');
};

subtest 'BOOL_NEGATE_978: CA city response extracted in list context' => sub {
	my $list = Geo::Coder::List->new()->push(Mutant::Geocoder::A->new());
	my $g = mock_scoped 'Mutant::Geocoder::A::reverse_geocode' => sub {
		return ( { city => 'Ottawa', prov => 'ON', stnumber => '100', staddress => 'King St' } );
	};

	my @r = $list->reverse_geocode(latlng => $LATLNG_DC);
	ok(scalar @r >= 1, 'List CA city: at least one result');
	like($r[0], qr/Ottawa/, 'List CA city: city present in result');
};

# =============================================================================
# MUTANT: BOOL_NEGATE_993/RETURN_UNDEF_993 -- list context result caching
#
# Source:  $self->_cache($latlng, \@rc);  return @rc;
# Kill:    List result must be cached; second call must not hit geocoder.
# =============================================================================

subtest 'BOOL_NEGATE_993: list reverse_geocode result is cached' => sub {
	my $list = Geo::Coder::List->new()->push(Mutant::Geocoder::A->new());
	my $calls = 0;
	my $g = mock_scoped 'Mutant::Geocoder::A::reverse_geocode' => sub {
		$calls++;
		return ({ display_name => 'Cached Address' });
	};

	my @r1 = $list->reverse_geocode(latlng => $LATLNG_DC);
	my @r2 = $list->reverse_geocode(latlng => $LATLNG_DC);

	is($calls, 1, 'List rg caching: geocoder called only once');
	ok(scalar @r1 >= 1, 'First call returned a result');
};

# =============================================================================
# MUTANT: COND_INV_996 -- scalar vs list context branch in reverse_geocode
#
# Source:  } else {  (scalar context path)
# Kill:    Scalar context must return a plain string; switching contexts
#          would run the wrong processing branch.
# =============================================================================

subtest 'COND_INV_996: scalar context uses scalar path (bare-string passthrough)' => sub {
	# Scalar path has a special "if(!ref($rc))" bare-string branch (line ~1021)
	my $list = Geo::Coder::List->new()->push(Mutant::Geocoder::A->new());
	my $g = mock_scoped 'Mutant::Geocoder::A::reverse_geocode' => sub {
		return '123 Bare Street, London';    # bare string, not a hashref
	};

	my $r = $list->reverse_geocode(latlng => $LATLNG_DC);
	ok(!ref($r),                      'Scalar bare-string: plain string returned');
	is($r, '123 Bare Street, London', 'Scalar bare-string: correct value');
};

# =============================================================================
# MUTANT: BOOL_NEGATE_1007/RETURN_UNDEF_1007 -- scalar latlng retry
#
# Source:  if($@ =~ /Unknown parameter.*latlng|.../s)  (scalar context)
# Kill:    Same retry logic as list context but in scalar branch.
# =============================================================================

subtest 'BOOL_NEGATE_1007: scalar context latlng retry succeeds' => sub {
	my $list = Geo::Coder::List->new()->push(Mutant::Geocoder::A->new());
	my $g = mock_scoped 'Mutant::Geocoder::A::reverse_geocode' => sub {
		my ($self, %args) = @_;
		die "validate_strict: Unknown parameter 'latlng'\n" if exists $args{latlng};
		return { display_name => 'Scalar Retry OK' };
	};

	my $r = $list->reverse_geocode(latlng => $LATLNG_DC);
	is($r, 'Scalar Retry OK', 'Scalar latlng retry: address returned after retry');
};

# =============================================================================
# MUTANT: COND_INV_1010/BOOL_NEGATE_1021 -- scalar error handling and bare string
#
# Source:  if($@) { carp; next }  and  if(!ref($rc)) { return $rc }
# Kill:    Error must carp and skip; bare string must be returned directly.
# =============================================================================

subtest 'COND_INV_1010: scalar error is carpd and geocoder skipped' => sub {
	my $list = Geo::Coder::List->new({ carp_on_warn => 1 });
	$list->push(Mutant::Geocoder::A->new())->push(Mutant::Geocoder::B->new());

	my $gA = mock_scoped 'Mutant::Geocoder::A::reverse_geocode' => sub {
		die "simulated rg error\n";
	};
	my $gB = mock_scoped 'Mutant::Geocoder::B::reverse_geocode' => sub {
		return { display_name => 'Fallback OK' };
	};

	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };
	my $r = $list->reverse_geocode(latlng => $LATLNG_DC);

	ok($warned,        'Scalar rg error: warning emitted');
	is($r, 'Fallback OK', 'Scalar rg error: fallback geocoder used');
};

subtest 'BOOL_NEGATE_1021/RETURN_UNDEF_1021: bare string from geocoder returned directly' => sub {
	my $list = Geo::Coder::List->new()->push(Mutant::Geocoder::A->new());
	my $g = mock_scoped 'Mutant::Geocoder::A::reverse_geocode' => sub {
		return 'Direct Bare String Address';
	};

	my $r = $list->reverse_geocode(latlng => $LATLNG_DC);
	ok(!ref($r),                       'Bare string: not a reference');
	is($r, 'Direct Bare String Address', 'Bare string: value correct');
};

# =============================================================================
# MUTANT: BOOL_NEGATE_1021: GeoApify features response in scalar context
# =============================================================================

subtest 'reverse_geocode scalar: GeoApify features path returns formatted string' => sub {
	my $list = Geo::Coder::List->new()->push(Mutant::Geocoder::A->new());
	my $g = mock_scoped 'Mutant::Geocoder::A::reverse_geocode' => sub {
		return { features => [ { properties => { formatted => 'Apify Scalar Address' } } ] };
	};

	my $r = $list->reverse_geocode(latlng => $LATLNG_DC);
	is($r, 'Apify Scalar Address', 'Scalar GeoApify features: formatted string returned');
};

subtest 'reverse_geocode scalar: CA city response assembled correctly' => sub {
	my $list = Geo::Coder::List->new()->push(Mutant::Geocoder::A->new());
	my $g = mock_scoped 'Mutant::Geocoder::A::reverse_geocode' => sub {
		return { city => 'Ottawa', prov => 'ON', stnumber => '100', staddress => 'King St' };
	};

	my $r = $list->reverse_geocode(latlng => $LATLNG_DC);
	like($r, qr/Ottawa/, 'Scalar CA city: city in result');
	like($r, qr/ON/,     'Scalar CA city: province in result');
};

# =============================================================================
# MUTANT: COND_INV_1138/BOOL_NEGATE_1113/RETURN_UNDEF_1113 -- log() return
#
# Source:  return $self->{'log'} // []
# Kill:    log() must return an arrayref, never undef.
#          After flush(), log() must still return [] not undef.
# =============================================================================

subtest 'BOOL_NEGATE_1113: log() always returns an arrayref, never undef' => sub {
	my $list = Geo::Coder::List->new();
	my $log  = $list->log();

	ok(defined $log,         'log() is defined');
	is(ref($log), 'ARRAY',   'log() is an arrayref');
	is(scalar @{$log}, 0,    'log() is empty on fresh object');
	returns_ok($log, { type => 'arrayref' }, 'log() satisfies arrayref return schema');
};

subtest 'COND_INV_1138: log() returns arrayref even after flush sets log to []' => sub {
	my $list = Geo::Coder::List->new();
	$list->flush();   # sets {log} = []

	my $log = $list->log();
	ok(defined $log,       'log() after flush: defined');
	is(ref($log), 'ARRAY', 'log() after flush: arrayref');
};

subtest 'RETURN_UNDEF_1157: flush() returns $self (chainable, not undef)' => sub {
	my $list = Geo::Coder::List->new();
	my $ret  = $list->flush();
	ok(blessed($ret),                   'flush() returns a blessed object');
	is(refaddr($ret), refaddr($list),   'flush() returns $self');
	returns_ok($ret, { type => 'object' }, 'flush() return satisfies object schema');
};

# =============================================================================
# MUTANT: COND_INV_1212 -- _build_ca_address() us vs ca branch
#
# Source:  if(my $usa = $loc->{'usa'}) { ... US layout ... } else { ... CA layout ... }
# Kill:    US data must use US format; CA data must use CA format.
#          Inversion would run CA format for US data and vice versa.
# =============================================================================

subtest 'COND_INV_1212: US address (usa key) uses US format with USA suffix' => sub {
	my $r = Geo::Coder::List::_build_ca_address({
		usa => {
			usstnumber  => '9000',
			usstaddress => 'Rockville Pike',
			uscity      => 'Bethesda',
			state       => 'MD',
		},
	});
	# Must end with USA; must have number-space-street format
	like($r,   qr/USA$/,               'US address ends with USA');
	like($r,   qr/9000 Rockville Pike/, 'US address: number<space>street');
	like($r,   qr/Bethesda/,           'US address: city present');
	like($r,   qr/MD/,                 'US address: state present');
	unlike($r, qr/^,/,                 'US address: no leading comma');
};

subtest 'COND_INV_1212: CA address (no usa key) uses CA format, no USA suffix' => sub {
	my $r = Geo::Coder::List::_build_ca_address({
		stnumber  => '22',
		staddress => 'Main Street',
		city      => 'Ottawa',
		prov      => 'ON',
	});
	is($r, '22 Main Street, Ottawa, ON', 'CA format: number space street, city, province');
	unlike($r, qr/USA/, 'CA format: no USA in output');
};

# =============================================================================
# MUTANT: COND_INV_1222/COND_INV_1228 -- _build_ca_address() separator logic
#
# Source:  $name .= ($name ? ' ' : '') . ...  (space before street name)
#          $name .= ($name ? ', ' : '') . ...  (comma before city/state)
# Kill:    Number + street must have a space between them; no leading separator
#          when name starts empty.  Invert ($name ? ... ) corrupts separators.
# =============================================================================

subtest 'COND_INV_1222: US number+street joined with space (not empty)' => sub {
	my $r = Geo::Coder::List::_build_ca_address({
		usa => { usstnumber => '100', usstaddress => 'Main St' },
	});
	# With $name='100', separator = ($name ? ' ' : '') = ' '
	like($r, qr/100 Main St/, 'US: number space street (not "100, Main St")');
	unlike($r, qr/^,/,        'US: no leading comma');
};

subtest 'COND_INV_1222: US no-number case has no leading space' => sub {
	my $r = Geo::Coder::List::_build_ca_address({
		usa => { usstaddress => 'Broadway', uscity => 'NYC' },
	});
	# With $name='', separator = ($name ? ' ' : '') = ''
	like($r, qr/^Broadway/, 'US no-number: starts with street name directly');
};

subtest 'COND_INV_1228: CA number+street joined with space' => sub {
	my $r = Geo::Coder::List::_build_ca_address({
		stnumber  => '55',
		staddress => 'Elm Ave',
	});
	like($r, qr/55 Elm Ave/, 'CA: number space street');
};

# =============================================================================
# MUTANT: COND_INV_1243/COND_INV_1249 -- _cache() write-path detection
#
# Source:  if(scalar(@_)) { ... write path ... }
# Kill:    Calling _cache(key) (0 extra args) must read; _cache(key, val) writes.
#          Inversion would always write or always read.
# =============================================================================

subtest 'COND_INV_1243: _cache() with 1 arg reads; with 2 args writes' => sub {
	my $obj = Geo::Coder::List->new();
	my $val = { geometry => { location => { lat => $LAT_DC, lng => $LNG_DC } } };

	# Read on uncached key must return undef (read path taken)
	my $before = $obj->_cache($LOC_DC);
	ok(!defined $before, 'Read on uncached key: undef');

	# Write with value
	$obj->_cache($LOC_DC, $val);

	# Read on cached key must return the value (write path stored it)
	my $after = $obj->_cache($LOC_DC);
	ok(defined $after,                         'Read after write: defined');
	is($after->{geometry}{location}{lat}, $LAT_DC, 'Read after write: lat correct');
};

subtest 'COND_INV_1249: _cache() write with undef stores not-found sentinel' => sub {
	# Passing undef as value is the not-found write; read must return undef
	my $obj = Geo::Coder::List->new();
	$obj->_cache($LOC_DC, undef);

	# The L1 entry must exist (sentinel stored)
	ok(exists $obj->{locations}{$LOC_DC}, 'Undef write: sentinel exists in L1');

	# But reading must return undef (sentinel masked)
	my $r = $obj->_cache($LOC_DC);
	ok(!defined $r, 'Undef write: read returns undef (sentinel masked)');
};

# =============================================================================
# MUTANT: COND_INV_1265/COND_INV_1274/BOOL_NEGATE_1283 -- _cache() ARRAY processing
#
# Source:  if(blessed($item) && ref($item->{'geocoder'})) -> stringify geocoder
#          $item->{'geocoder'} = ref($item->{'geocoder'})  -> must be string
#          unless(defined($item->{geometry}{location}{lat})) -> partial TTL
# Kill:    Blessed item geocoder field must be stringified; partial geometry
#          sets $rc=undef; complete geometry uses hit TTL.
# =============================================================================

subtest 'COND_INV_1265: blessed ARRAY item geocoder ref is stringified' => sub {
	my %l2;
	my $obj = Geo::Coder::List->new(cache => \%l2);

	# Build a blessed item whose geocoder field is still an object ref
	my $fake_gc = bless {}, 'FakeGeocoderRef';
	my $item    = bless {
		geocoder => $fake_gc,
		geometry => { location => { lat => $LAT_DC, lng => $LNG_DC } },
	}, 'SomeResultClass';

	$obj->_cache($LOC_DC, [$item]);

	# After the write, the geocoder field must be the string class name
	ok(!ref($item->{geocoder}),
		'Blessed ARRAY item: geocoder ref stringified to class name');
	is($item->{geocoder}, 'FakeGeocoderRef',
		'Blessed ARRAY item: geocoder stringified correctly');
};

subtest 'BOOL_NEGATE_1283/RETURN_UNDEF_1283: ARRAY with partial geometry -> _cache returns undef' => sub {
	# Item has geometry but no lat: TTL = part_duration, $rc = undef
	my %l2;
	my $obj = Geo::Coder::List->new(cache => \%l2);
	my $val = [ { geometry => {} } ];    # geometry present but no lat

	my $rc = $obj->_cache($LOC_DC, $val);
	ok(!defined $rc, 'Partial geometry ARRAY: _cache write returns undef');
};

subtest 'COND_INV_1306/BOOL_NEGATE_1313/RETURN_UNDEF_1313: HASH partial geometry -> undef' => sub {
	# HASH with geometry but no lat: $rc = undef (partial TTL branch)
	my %l2;
	my $obj = Geo::Coder::List->new(cache => \%l2);
	my $val = { geometry => {} };   # partial geometry

	my $rc = $obj->_cache($LOC_DC, $val);
	ok(!defined $rc, 'Partial geometry HASH: _cache write returns undef');
};

subtest '_cache HASH with full geometry: _cache returns the value' => sub {
	# Positive case: full geometry -> $rc = $value (not undef)
	my %l2;
	my $obj = Geo::Coder::List->new(cache => \%l2);
	my $val = { geometry => { location => { lat => $LAT_DC, lng => $LNG_DC } } };

	my $rc = $obj->_cache($LOC_DC, $val);
	ok(defined $rc, 'Full geometry HASH: _cache write returns the value');
};

done_testing();

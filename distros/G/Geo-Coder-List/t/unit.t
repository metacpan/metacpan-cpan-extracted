#!/usr/bin/env perl

# t/unit.t - Black-box unit tests for Geo::Coder::List public API
#
# Tests are derived solely from the POD documentation.  No internal object
# state ($obj->{geocoders} etc.) is ever inspected; only the public interface
# is exercised.  Failures here indicate a contract breach between the code
# and its documentation.

use strict;
use warnings;

use lib 'lib';

use Data::Dumper;
use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Readonly;
use Scalar::Util qw(blessed refaddr);

BEGIN { use_ok('Geo::Coder::List') }

# ── Fixed test values ─────────────────────────────────────────────────────────

# Named coordinate constants keep assertions readable
Readonly::Scalar my $LAT_DC     => 38.8977;
Readonly::Scalar my $LNG_DC     => -77.0365;
Readonly::Scalar my $LAT_LONDON => 51.5074;
Readonly::Scalar my $LNG_LONDON => -0.1278;

# Location strings referenced across multiple subtests
Readonly::Scalar my $LOC_DC     => '1600 Pennsylvania Ave NW, Washington DC, USA';
Readonly::Scalar my $LOC_LONDON => '10 Downing St, London, UK';
Readonly::Scalar my $LOC_USA    => 'Silver Spring, MD, USA';
Readonly::Scalar my $LATLNG_DC  => "$LAT_DC,$LNG_DC";

# The exact string the code places in the 'geocoder' field for cache hits
Readonly::Scalar my $CACHE_STR  => 'cache';

# Test configuration table -- avoids literal numbers in test bodies
my %config = (
	debug_off  => 0,
	debug_on   => 1,
	limit_one  => 1,
);

# ── Minimal stub geocoder packages ───────────────────────────────────────────
# Three distinct classes so subtests can mock any subset independently.

package UnitMock::A;
sub new             { bless {}, shift }
sub geocode         { return () }
sub reverse_geocode { return () }
sub ua              { }

package UnitMock::B;
sub new             { bless {}, shift }
sub geocode         { return () }
sub reverse_geocode { return () }
sub ua              { }

package UnitMock::C;
sub new             { bless {}, shift }
sub geocode         { return () }
sub reverse_geocode { return () }
sub ua              { }

package main;

# ── Shared helpers ────────────────────────────────────────────────────────────

# Build an OSM-style result hashref (top-level lat/lon)
sub _osm { { lat => $_[0], lon => $_[1] } }

# Build a list with a single geocoder already pushed
sub _list_with {
	my ($geocoder, %extra) = @_;
	return Geo::Coder::List->new(%extra)->push($geocoder);
}

# =============================================================================
# new()
# POD contract: Creates Geo::Coder::List; accepts cache/debug; clones on instance call
# =============================================================================

subtest 'new: returns a Geo::Coder::List object' => sub {
	my $obj = Geo::Coder::List->new();
	isa_ok($obj, 'Geo::Coder::List', 'new() returns correct class');
	ok(blessed($obj),                 'new() returns a blessed reference');
	returns_ok($obj, { type => 'object' }, 'satisfies object return schema');
};

subtest 'new: accepts debug => N parameter without error' => sub {
	# POD: "Takes an optional argument debug; the higher the number the more debugging"
	my $obj = Geo::Coder::List->new(debug => 2);
	isa_ok($obj, 'Geo::Coder::List', 'new(debug=>2) returns correct class');
};

subtest 'new: accepts cache => HASHREF parameter' => sub {
	# POD: "cache which is a reference to a HASH or an object that supports get()/set()"
	my $obj = Geo::Coder::List->new(cache => {});
	isa_ok($obj, 'Geo::Coder::List', 'new(cache=>{}) returns correct class');
};

subtest 'new: calling new() on an instance returns a clone (distinct object)' => sub {
	# POD: "When called on an existing object it returns a clone merged with arguments"
	my $orig  = Geo::Coder::List->new(debug => $config{debug_off});
	my $clone = $orig->new(debug => $config{debug_on});
	isa_ok($clone, 'Geo::Coder::List', 'clone is a Geo::Coder::List');
	isnt(refaddr($clone), refaddr($orig), 'clone is a different object in memory');
};

subtest 'new: clone inherits geocoder chain from original' => sub {
	# POD clone: "returns a clone of that object merged with the supplied arguments"
	# -- the geocoder chain must persist into the clone
	my $orig  = Geo::Coder::List->new();
	$orig->push(UnitMock::A->new());
	my $clone = $orig->new();

	my $mock = mock_scoped 'UnitMock::A::geocode' => sub { _osm($LAT_DC, $LNG_DC) };
	my $r    = $clone->geocode($LOC_DC);
	ok(defined $r, 'clone resolves location using inherited geocoder');
};

subtest 'new: ::new() function-style with no args returns an object' => sub {
	# Edge case documented in code (FIXME comment) -- must not break
	my $obj = Geo::Coder::List::new();
	isa_ok($obj, 'Geo::Coder::List', '::new() returns Geo::Coder::List');
};

subtest 'new: ::new() with arguments carps and returns undef' => sub {
	# POD FIXME note: calling ::new() with args is unsupported -- must emit carp
	my $obj;
	warnings_like { $obj = Geo::Coder::List::new(undef, debug => 1) }
		qr/use ->new\(\) not ::new\(\)/,
		'::new() with args emits expected carp';
	ok(!defined $obj, '::new() with args returns undef');
};

# =============================================================================
# push()
# POD contract: Appends geocoder to chain; returns $self for chaining
# =============================================================================

subtest 'push: returns $self (enables method chaining per POD)' => sub {
	my $list = Geo::Coder::List->new();
	my $ret  = $list->push(UnitMock::A->new());
	is(refaddr($ret), refaddr($list), 'push() returns the list object itself');
	returns_ok($ret, { type => 'object' }, 'return satisfies object schema');
};

subtest 'push: consecutive pushes are tried in order (POD: "tried in the order pushed")' => sub {
	my $list = Geo::Coder::List->new();
	my @order;

	my $mock_a = mock_scoped 'UnitMock::A::geocode' => sub {
		push @order, 'A';
		return ();        # fail to trigger fallback
	};
	my $mock_b = mock_scoped 'UnitMock::B::geocode' => sub {
		push @order, 'B';
		return _osm($LAT_DC, $LNG_DC);
	};

	$list->push(UnitMock::A->new())->push(UnitMock::B->new());
	$list->geocode($LOC_DC);
	is_deeply(\@order, [qw(A B)], 'A tried before B as per push order');
};

subtest 'push: hashref with regex skips non-matching locations (POD: "restricts to locations matching")' => sub {
	my $list = Geo::Coder::List->new();
	$list->push({ regex => qr/USA$/, geocoder => UnitMock::A->new() });
	$list->push(UnitMock::B->new());

	my ($a_calls, $b_calls) = (0, 0);
	my $mock_a = mock_scoped 'UnitMock::A::geocode' => sub { $a_calls++; return () };
	my $mock_b = mock_scoped 'UnitMock::B::geocode' => sub {
		$b_calls++;
		return _osm($LAT_LONDON, $LNG_LONDON);
	};

	# UK location does not match /USA$/; only B should be called
	$list->geocode($LOC_LONDON);
	is($a_calls, 0, 'regex-guarded geocoder skipped for non-matching location');
	is($b_calls, 1, 'unrestricted geocoder still reached');
};

subtest 'push: hashref with limit exhausts and geocoder is then skipped (POD: "caps total queries")' => sub {
	my $list  = Geo::Coder::List->new();
	my $calls = 0;
	$list->push({ geocoder => UnitMock::A->new(), limit => $config{limit_one} });

	my $mock = mock_scoped 'UnitMock::A::geocode' => sub {
		$calls++;
		return _osm($LAT_DC, $LNG_DC);
	};

	$list->geocode($LOC_DC);    # first call uses the limit
	$list->geocode($LOC_USA);   # limit=0 now; geocoder must be skipped
	is($calls, 1, 'geocoder called exactly once when limit is 1');
};

subtest 'push: croaks with exact error when called with no argument' => sub {
	# POD input schema: geocoder is required
	my $list = Geo::Coder::List->new();
	throws_ok { $list->push() }
		qr/Usage: \(\$geocoder\)/,
		'push() with no arg throws expected error string';
};

# =============================================================================
# geocode()
# POD contract: resolves location; context-sensitive; geocoder field; caching
# =============================================================================

subtest 'geocode: croaks when called with no arguments' => sub {
	# POD input: location is required (enforced by Params::Get)
	my $list = Geo::Coder::List->new();
	throws_ok { $list->geocode() } qr/Usage:/i,
		'no-arg call throws error matching "Usage:"';
};

subtest 'geocode: carps for empty location string' => sub {
	# POD input: "Must contain at least one non-digit character"
	my $list = Geo::Coder::List->new(carp_on_warn => 1);
	warnings_like { $list->geocode(location => '') }
		qr/usage: geocode\(/i,
		'empty string emits carp with expected message';
};

subtest 'geocode: carps for undef location' => sub {
	my $list = Geo::Coder::List->new(carp_on_warn => 1);
	warnings_like { $list->geocode(location => undef) }
		qr/usage: geocode\(/i,
		'undef location emits carp with expected message';
};

subtest 'geocode: croaks for a numeric-only location string' => sub {
	# POD: location must contain at least one non-digit character
	my $list = Geo::Coder::List->new();
	throws_ok { $list->geocode('99999') }
		qr/invalid input to geocode/,
		'numeric-only string throws documented error';
};

subtest 'geocode: accepts a bare positional string (POD example form)' => sub {
	# POD example: geocode('London, UK')
	my $list = _list_with(UnitMock::A->new());
	my $mock = mock_scoped 'UnitMock::A::geocode' => sub { _osm($LAT_LONDON, $LNG_LONDON) };
	my $r    = $list->geocode($LOC_LONDON);
	ok(defined $r, 'positional string form resolves correctly');
};

subtest 'geocode: accepts named location => parameter (POD example form)' => sub {
	# POD example: geocode(location => 'Paris, France')
	my $list = _list_with(UnitMock::A->new());
	my $mock = mock_scoped 'UnitMock::A::geocode' => sub { _osm($LAT_DC, $LNG_DC) };
	my $r    = $list->geocode(location => $LOC_DC);
	ok(defined $r, 'named parameter form resolves correctly');
};

subtest 'geocode: scalar context returns HASHREF with canonical geometry structure' => sub {
	# POD output: {geometry => {location => {lat => Num, lng => Num}}, ...}
	my $list = _list_with(UnitMock::A->new());
	my $mock = mock_scoped 'UnitMock::A::geocode' => sub { _osm($LAT_DC, $LNG_DC) };

	my $r = $list->geocode($LOC_DC);

	is(ref($r),                        'HASH', 'scalar context returns HASHREF');
	ok(defined $r->{geometry},                 'geometry key present');
	ok(defined $r->{geometry}{location},       'geometry.location key present');
	is($r->{geometry}{location}{lat}, $LAT_DC, 'geometry.location.lat correct');
	is($r->{geometry}{location}{lng}, $LNG_DC, 'geometry.location.lng correct');

	diag(Dumper($r)) if $ENV{TEST_VERBOSE};
};

subtest 'geocode: result contains lat convenience alias (POD output schema)' => sub {
	my $list = _list_with(UnitMock::A->new());
	my $mock = mock_scoped 'UnitMock::A::geocode' => sub { _osm($LAT_DC, $LNG_DC) };
	my $r    = $list->geocode($LOC_DC);
	# POD: lat => Num  (convenience alias for geometry.location.lat)
	is($r->{lat}, $r->{geometry}{location}{lat},
		'lat alias equals geometry.location.lat');
};

subtest 'geocode: result contains lng convenience alias (POD output schema)' => sub {
	my $list = _list_with(UnitMock::A->new());
	my $mock = mock_scoped 'UnitMock::A::geocode' => sub { _osm($LAT_DC, $LNG_DC) };
	my $r    = $list->geocode($LOC_DC);
	# POD: lng => Num  (convenience alias for geometry.location.lng)
	is($r->{lng}, $r->{geometry}{location}{lng},
		'lng alias equals geometry.location.lng');
};

subtest 'geocode: result contains lon compatibility alias == lng (POD output schema)' => sub {
	my $list = _list_with(UnitMock::A->new());
	my $mock = mock_scoped 'UnitMock::A::geocode' => sub { _osm($LAT_DC, $LNG_DC) };
	my $r    = $list->geocode($LOC_DC);
	# POD: lon => Num  (compatibility alias for lng)
	is($r->{lon}, $r->{geometry}{location}{lng},
		'lon alias equals lng (compatibility alias)');
};

subtest 'geocode: geocoder field in result is the geocoder OBJECT (not a string)' => sub {
	# POD: "geocoder field holds the geocoder object that supplied the result"
	my $g    = UnitMock::A->new();
	my $list = _list_with($g);
	my $mock = mock_scoped 'UnitMock::A::geocode' => sub { _osm($LAT_DC, $LNG_DC) };

	my $r = $list->geocode($LOC_DC);
	is(ref($r->{geocoder}), 'UnitMock::A',
		'geocoder field is the geocoder object, not a plain string');
};

subtest 'geocode: geocoder field set to "cache" on cache hit (POD contract)' => sub {
	# POD: "it is set to the string 'cache' when the result was served from cache"
	my $list = _list_with(UnitMock::A->new());
	my $mock = mock_scoped 'UnitMock::A::geocode' => sub { _osm($LAT_DC, $LNG_DC) };

	$list->geocode($LOC_DC);            # populate L1 cache
	my $r2 = $list->geocode($LOC_DC);   # served from cache

	is($r2->{geocoder}, $CACHE_STR,
		"geocoder field is '$CACHE_STR' for a cache-served result");
};

subtest 'geocode: returns undef in scalar context when no geocoders configured' => sub {
	# Degenerate case: empty chain must not die
	my $list = Geo::Coder::List->new();
	my $r    = $list->geocode($LOC_DC);
	ok(!defined $r, 'returns undef with an empty geocoder chain');
};

subtest 'geocode: list context returns array of HASHREFs (POD: "all results from winning geocoder")' => sub {
	# POD: "In list context returns all results from the winning geocoder"
	my $list = _list_with(UnitMock::A->new());
	my $mock = mock_scoped 'UnitMock::A::geocode' => sub {
		return (_osm($LAT_DC, $LNG_DC), _osm($LAT_LONDON, $LNG_LONDON));
	};

	my @results = $list->geocode($LOC_DC);
	ok(scalar @results >= 1,       'list context returns at least one result');
	is(ref($results[0]), 'HASH',   'each element is a HASHREF');
	ok(defined $results[0]{geometry}{location}{lat},
		'first result has canonical lat');
};

subtest 'geocode: carps on geocoder error and falls back to next geocoder' => sub {
	# POD purpose: "trying each geocoder in turn; first successful result returned"
	my $list = Geo::Coder::List->new(carp_on_warn => 1);
	$list->push(UnitMock::A->new())->push(UnitMock::B->new());

	my $mock_a = mock_scoped 'UnitMock::A::geocode' => sub { die 'rate limit hit' };
	my $mock_b = mock_scoped 'UnitMock::B::geocode' => sub { _osm($LAT_DC, $LNG_DC) };

	my $r;
	warnings_like { $r = $list->geocode($LOC_DC) }
		qr/rate limit hit/, 'error from first geocoder is carped (not croaked)';

	ok(defined $r,                      'fallback geocoder result returned');
	is(ref($r->{geocoder}), 'UnitMock::B', 'result came from the fallback geocoder');
};

subtest 'geocode: collapses multiple consecutive spaces in location (POD normalisation)' => sub {
	# Code: $location =~ s/\s\s+/ /g  before passing to geocoders
	my $list     = _list_with(UnitMock::A->new());
	my $seen_loc = '';
	my $mock = mock_scoped 'UnitMock::A::geocode' => sub {
		my ($self_g, %args) = @_;
		$seen_loc = $args{location} // '';
		return ();
	};

	$list->geocode(location => 'London,   England,  UK');
	unlike($seen_loc, qr/  +/, 'multiple spaces collapsed before geocoder call');
};

subtest 'geocode: same location queried twice only calls backend once (L1 cache)' => sub {
	# POD Z-spec: "loc? in dom L1 => result! = L1(loc?)" (cache short-circuit)
	my $list  = _list_with(UnitMock::A->new());
	my $calls = 0;
	my $mock  = mock_scoped 'UnitMock::A::geocode' => sub {
		$calls++;
		return _osm($LAT_DC, $LNG_DC);
	};

	$list->geocode($LOC_DC);
	$list->geocode($LOC_DC);
	is($calls, 1, 'backend called only once for the same location (L1 cache)');
};

subtest 'geocode: result from cache carries lat/lng aliases too' => sub {
	# Cache-served results must have the same convenience aliases as live results
	my $list = _list_with(UnitMock::A->new());
	my $mock = mock_scoped 'UnitMock::A::geocode' => sub { _osm($LAT_DC, $LNG_DC) };

	$list->geocode($LOC_DC);            # populate cache
	my $r = $list->geocode($LOC_DC);    # cache hit

	is($r->{lat}, $LAT_DC, 'lat alias present on cached result');
	is($r->{lon}, $LNG_DC, 'lon alias present on cached result');
};

# =============================================================================
# ua()
# POD contract: Sets UA on every geocoder; returns the passed UA; no read accessor
# =============================================================================

subtest 'ua: returns undef when called with no argument (optional param)' => sub {
	# POD input schema: ua is optional; output schema implies no-arg => no UA to return
	my $list = Geo::Coder::List->new();
	ok(!defined $list->ua(), 'ua() with no arg returns undef');
};

subtest 'ua: returns the exact UA object that was passed in (POD output schema)' => sub {
	# POD output: "OBJECT - the same $ua that was passed in"
	my $list = _list_with(UnitMock::A->new());
	my $ua   = bless { id => 'unit_ua' }, 'FakeUA::Unit';
	my $mock = mock_scoped 'UnitMock::A::ua' => sub { };  # accept silently

	my $ret = $list->ua($ua);
	is($ret, $ua, 'ua() returns the same object that was passed in');
};

subtest 'ua: propagates UA to every geocoder in the chain (POD: "every geocoder")' => sub {
	# POD purpose: "Sets the...object on every geocoder in the chain"
	my $list = Geo::Coder::List->new();
	$list->push(UnitMock::A->new())->push(UnitMock::B->new());

	my @calls;
	my $mock_a = mock_scoped 'UnitMock::A::ua' => sub { push @calls, 'A' };
	my $mock_b = mock_scoped 'UnitMock::B::ua' => sub { push @calls, 'B' };

	$list->ua(bless {}, 'FakeUA::Unit');
	is_deeply(\@calls, [qw(A B)],
		'UA propagated to all geocoders in push order');
};

subtest 'ua: propagates through hashref-wrapped chain entries too' => sub {
	# Hashref entries (with regex/limit) also contain a geocoder that needs the UA
	my $list = Geo::Coder::List->new();
	$list->push({ regex => qr/.*/, geocoder => UnitMock::A->new() });

	my $received_ua = 0;
	my $mock = mock_scoped 'UnitMock::A::ua' => sub { $received_ua++ };

	$list->ua(bless {}, 'FakeUA::Unit');
	is($received_ua, 1, 'UA propagated into geocoder inside a hashref entry');
};

subtest 'ua: croaks with exact message when chain entry has undef geocoder' => sub {
	# Code guard: Carp::croak('No geocoder found') when geocoder is undef
	my $list = Geo::Coder::List->new();
	$list->push({ regex => qr/.*/, geocoder => undef });

	throws_ok { $list->ua(bless {}, 'FakeUA::Unit') }
		qr/No geocoder found/,
		'ua() croaks with documented error for undef geocoder entry';
};

# =============================================================================
# reverse_geocode()
# POD contract: coords => address; context-sensitive; caches; logs
# =============================================================================

subtest 'reverse_geocode: croaks when latlng is missing (required param)' => sub {
	my $list = Geo::Coder::List->new();
	throws_ok { $list->reverse_geocode() } qr/Usage:/i,
		'no-arg call throws error matching "Usage:"';
};

subtest 'reverse_geocode: scalar context returns a plain address string' => sub {
	# POD output: "SCALAR (address string) | undef"
	my $list = _list_with(UnitMock::A->new());
	my $mock = mock_scoped 'UnitMock::A::reverse_geocode' => sub {
		return { display_name => '10 Downing Street, London' };
	};

	my $addr = $list->reverse_geocode(latlng => $LATLNG_DC);
	ok(defined $addr,       'result is defined');
	ok(!ref($addr),         'result is a plain string (not a reference)');
	like($addr, qr/Downing/, 'result contains expected address text');
};

subtest 'reverse_geocode: returns undef when no geocoders are configured' => sub {
	my $list   = Geo::Coder::List->new();
	my $result = $list->reverse_geocode(latlng => $LATLNG_DC);
	ok(!defined $result, 'undef returned with empty geocoder chain');
};

subtest 'reverse_geocode: caches result; backend called only once per unique coords' => sub {
	# POD Z-spec: "latlng? in dom L1 => result! = L1(latlng?)"
	my $list  = _list_with(UnitMock::A->new());
	my $calls = 0;
	my $mock  = mock_scoped 'UnitMock::A::reverse_geocode' => sub {
		$calls++;
		return { display_name => 'Somewhere, London' };
	};

	$list->reverse_geocode(latlng => $LATLNG_DC);
	$list->reverse_geocode(latlng => $LATLNG_DC);
	is($calls, 1, 'backend called only once for the same coordinates');
};

subtest 'reverse_geocode: list context returns an array of address strings' => sub {
	# POD output: "ARRAY of SCALAR"
	my $list = _list_with(UnitMock::A->new());
	my $mock = mock_scoped 'UnitMock::A::reverse_geocode' => sub {
		return (
			{ display_name => 'First Street, London' },
			{ display_name => 'Second Street, London' },
		);
	};

	my @addrs = $list->reverse_geocode(latlng => $LATLNG_DC);
	ok(scalar @addrs >= 1, 'list context returns at least one address');
	ok(!ref($addrs[0]),    'each element is a plain scalar string');
	is($addrs[0], 'First Street, London', 'first address matches expected value');
};

subtest 'reverse_geocode: writes a log entry after each call' => sub {
	# POD: (shared log contract with geocode())
	my $list = _list_with(UnitMock::A->new());
	my $mock = mock_scoped 'UnitMock::A::reverse_geocode' => sub {
		return { display_name => 'A Road, Somewhere' };
	};

	my $before = scalar @{$list->log()};
	$list->reverse_geocode(latlng => $LATLNG_DC);
	my $after = scalar @{$list->log()};

	ok($after > $before, 'at least one log entry added by reverse_geocode');
};

subtest 'reverse_geocode: carps on geocoder error and continues' => sub {
	# Like geocode(), errors must be carpd, not croaked
	my $list = _list_with(UnitMock::A->new(), (carp_on_warn => 1));
	my $mock = mock_scoped 'UnitMock::A::reverse_geocode' => sub {
		die 'reverse lookup failed';
	};

	my $result;
	warnings_like { $result = $list->reverse_geocode(latlng => $LATLNG_DC) }
		qr/reverse lookup failed/, 'error from geocoder is carped';

	ok(!defined $result, 'returns undef when all geocoders fail');
};

# =============================================================================
# log()
# POD contract: returns ARRAYREF; entries have documented keys; accumulates
# =============================================================================

subtest 'log: returns an ARRAY ref on a fresh object' => sub {
	# POD output schema: ARRAYREF of HASHREF
	my $list = Geo::Coder::List->new();
	my $log  = $list->log();
	is(ref($log), 'ARRAY', 'log() returns ARRAY ref');
	is(scalar @{$log}, 0,  'log is empty on a fresh object');
	returns_ok($log, { type => 'arrayref' }, 'satisfies arrayref return schema');
};

subtest 'log: entries contain every key documented in the POD output schema' => sub {
	# POD: line, location, timetaken, geocoder, wantarray, result | error
	my $list = _list_with(UnitMock::A->new());
	my $mock = mock_scoped 'UnitMock::A::geocode' => sub { _osm($LAT_DC, $LNG_DC) };

	$list->geocode($LOC_DC);

	my $entry = $list->log()->[0];
	for my $key (qw(line location timetaken geocoder wantarray)) {
		ok(exists $entry->{$key},
			"log entry has documented key '$key'");
	}

	# Must have exactly one of result or error
	my $has_result = exists $entry->{result};
	my $has_error  = exists $entry->{error};
	ok($has_result || $has_error, 'entry has result OR error key');

	diag(Dumper($entry)) if $ENV{TEST_VERBOSE};
};

subtest 'log: geocoder key in entry holds the class name string' => sub {
	# Distinct from the result geocoder field (which is the object)
	my $list = _list_with(UnitMock::A->new());
	my $mock = mock_scoped 'UnitMock::A::geocode' => sub { _osm($LAT_DC, $LNG_DC) };

	$list->geocode($LOC_DC);

	my ($e) = grep { ($_->{geocoder} // '') eq 'UnitMock::A' } @{$list->log()};
	ok(defined $e, "log entry with geocoder == 'UnitMock::A' found");
	ok(!ref($e->{geocoder}), 'log geocoder value is a plain string, not an object ref');
};

subtest 'log: timetaken is a non-negative number' => sub {
	my $list = _list_with(UnitMock::A->new());
	my $mock = mock_scoped 'UnitMock::A::geocode' => sub { _osm($LAT_DC, $LNG_DC) };

	$list->geocode($LOC_DC);

	my $entry = $list->log()->[0];
	ok(defined $entry->{timetaken}, 'timetaken key present');
	ok($entry->{timetaken} >= 0,    'timetaken is non-negative');
};

subtest 'log: wantarray key reflects calling context (false for scalar context)' => sub {
	# POD: wantarray key
	my $list = _list_with(UnitMock::A->new());
	my $mock = mock_scoped 'UnitMock::A::geocode' => sub { _osm($LAT_DC, $LNG_DC) };

	my $r = $list->geocode($LOC_DC);     # scalar context

	my $entry = $list->log()->[0];
	ok(defined $entry->{wantarray},  'wantarray key is present');
	ok(!$entry->{wantarray},         'wantarray is false for scalar-context call');
};

subtest 'log: error key present when geocoder threw' => sub {
	# POD: entries have result OR error
	my $list = _list_with(UnitMock::A->new(), ( carp_on_warn => 1 ));
	my $mock = mock_scoped 'UnitMock::A::geocode' => sub { die 'boom' };

	warnings_like { $list->geocode($LOC_DC) } qr/boom/, 'error carped';

	my ($err_entry) = grep { exists $_->{error} } @{$list->log()};
	ok(defined $err_entry,                   'error entry present in log');
	like($err_entry->{error}, qr/boom/,      'error text captured in log');
};

subtest 'log: accumulates entries across multiple geocode calls' => sub {
	my $list = _list_with(UnitMock::A->new());
	my $mock = mock_scoped 'UnitMock::A::geocode' => sub { _osm($LAT_DC, $LNG_DC) };

	# Two distinct locations produce two log entries
	$list->geocode($LOC_DC);
	$list->geocode($LOC_LONDON);

	ok(scalar @{$list->log()} >= 2, 'at least two entries after two geocode calls');
};

# =============================================================================
# flush()
# POD contract: clears log; returns $self; does NOT affect cache
# =============================================================================

subtest 'flush: returns $self to allow method chaining (POD output schema)' => sub {
	# POD: "returns $self to allow chaining"
	my $list = Geo::Coder::List->new();
	my $ret  = $list->flush();
	is(refaddr($ret), refaddr($list), 'flush() returns the same list object');
	returns_ok($ret, { type => 'object' }, 'satisfies object return schema');
};

subtest 'flush: clears all log entries (POD Z-spec: log\' = empty sequence)' => sub {
	my $list = _list_with(UnitMock::A->new());
	my $mock = mock_scoped 'UnitMock::A::geocode' => sub { _osm($LAT_DC, $LNG_DC) };

	$list->geocode($LOC_DC);
	ok(scalar @{$list->log()} > 0, 'log has entries before flush');

	$list->flush();
	is(scalar @{$list->log()}, 0, 'log is empty after flush');
};

subtest 'flush: log() returns a valid ARRAY ref (not undef) after flush' => sub {
	# flush must leave log() in a consistent state
	my $list = Geo::Coder::List->new();
	$list->flush();
	is(ref($list->log()), 'ARRAY', 'log() returns ARRAY ref after flush');
};

subtest 'flush: does NOT clear the L1 cache (POD Z-spec: L1\' = L1)' => sub {
	# POD: flush only touches the log; cached geocode results must survive
	my $list  = _list_with(UnitMock::A->new());
	my $calls = 0;
	my $mock  = mock_scoped 'UnitMock::A::geocode' => sub {
		$calls++;
		return _osm($LAT_DC, $LNG_DC);
	};

	$list->geocode($LOC_DC);     # populates cache
	$list->flush();              # clears log only

	my $r = $list->geocode($LOC_DC);    # must hit cache, not backend
	is($calls, 1,           'backend not called again after flush');
	is($r->{geocoder}, $CACHE_STR, 'result still served from cache after flush');
};

# =============================================================================
# geocode() -- cache-hit shallow copy (new in 0.37)
# POD contract: "geocoder field is set to 'cache' when served from cache"
# Additional contract: the original caller variable must not be mutated.
# =============================================================================

subtest 'geocode: cache hit does not mutate the original result variable' => sub {
	# POD Z-spec: cached result has geocoder='cache'; live result retains its geocoder
	my $list = _list_with(UnitMock::A->new());
	my $mock = mock_scoped 'UnitMock::A::geocode' => sub { _osm($LAT_DC, $LNG_DC) };

	my $live   = $list->geocode($LOC_DC);   # live call: geocoder is UnitMock::A object
	my $cached = $list->geocode($LOC_DC);   # cache hit: geocoder should be 'cache'

	# Cache hit must NOT modify $live; geocoder field must still be the object
	is(ref($live->{geocoder}), 'UnitMock::A',
		'Original result: geocoder field is the geocoder object (not mutated)');
	is($cached->{geocoder}, $CACHE_STR,
		'Cache-hit result: geocoder field is the "cache" string');
};

# =============================================================================
# ua() -- per-geocoder clone with agent (new in 0.37)
# When the incoming UA supports clone() and agent(), each geocoder receives its
# own copy; ua() still returns the original UA (POD output schema).
# =============================================================================

subtest 'ua: with cloneable UA, returns the original UA (not a clone)' => sub {
	# Build a minimal cloneable UA inline so this test has no LWP dependency
	{
		package UnitFakeCloneUA;
		sub new   { bless { _agent => 'test/0' }, shift }
		sub clone { bless { %{$_[0]} }, ref($_[0]) }
		sub agent { $_[0]->{_agent} = $_[1] if @_ > 1; $_[0]->{_agent} }
	}

	my $list = _list_with(UnitMock::A->new());
	my $ua   = UnitFakeCloneUA->new();
	my $mock = mock_scoped 'UnitMock::A::ua' => sub { };   # accept silently

	my $ret = $list->ua($ua);
	is(refaddr($ret), refaddr($ua),
		'ua() returns the original UA object even when cloning for geocoders');
};

subtest 'ua: geocoder receives a UA whose agent matches its class name' => sub {
	{
		package UnitFakeCloneUA2;
		sub new   { bless { _agent => 'libwww-perl/x' }, shift }
		sub clone { bless { %{$_[0]} }, ref($_[0]) }
		sub agent { $_[0]->{_agent} = $_[1] if @_ > 1; $_[0]->{_agent} }
	}

	my $list = _list_with(UnitMock::A->new());
	my $ua   = UnitFakeCloneUA2->new();

	my $received_ua;
	my $mock = mock_scoped 'UnitMock::A::ua' => sub { (undef, $received_ua) = @_ };

	$list->ua($ua);

	like($received_ua->agent(), qr/^UnitMock::A/,
		'Geocoder UA agent string starts with the geocoder class name');
};

# =============================================================================
# reverse_geocode() -- strict-validation latlng retry (new in 0.37)
# If a backing geocoder rejects 'latlng' as unknown, the module retries
# without it; lat and lon from the coordinate split are still present.
# =============================================================================

subtest 'reverse_geocode: works with strict-validation geocoder that rejects latlng' => sub {
	my $list = _list_with(UnitMock::A->new());
	my $mock = mock_scoped 'UnitMock::A::reverse_geocode' => sub {
		my ($self, %args) = @_;
		# Strict geocoder: latlng is not a known parameter
		die "validate_strict: Unknown parameter 'latlng'\n" if exists $args{latlng};
		return { display_name => 'Strict Geocoder Address, London' };
	};

	my $r = $list->reverse_geocode(latlng => $LATLNG_DC);
	is($r, 'Strict Geocoder Address, London',
		'Strict-validation geocoder: address returned after latlng is stripped on retry');
};

# =============================================================================

subtest 'flush: enables chaining: flush()->geocode() works (POD example)' => sub {
	# POD example: $list->flush()->geocode('London, UK')
	my $list = _list_with(UnitMock::A->new());
	my $mock = mock_scoped 'UnitMock::A::geocode' => sub { _osm($LAT_DC, $LNG_DC) };

	my $r = $list->flush()->geocode($LOC_DC);
	ok(defined $r, 'geocode() works immediately after flush() in a chain');
};

done_testing();

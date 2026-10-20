#!/usr/bin/env perl

# t/function.t - White-box function-level tests for Geo::Coder::List
# Each public method and internal helper is tested in isolation.
# Test::Mockingbird is used to mock all geocoder backends.

use strict;
use warnings;

use lib 'lib';

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Test::Memory::Cycle;
use Readonly;
use Scalar::Util qw(blessed refaddr);
use Data::Dumper;

# The module under test
BEGIN { use_ok('Geo::Coder::List') }

# ── Fixed test values ─────────────────────────────────────────────────────────

# Coordinates used throughout; named to make assertions self-documenting
Readonly::Scalar my $LAT_DC     => 38.8977;
Readonly::Scalar my $LNG_DC     => -77.0365;
Readonly::Scalar my $LAT_NY     => 40.7128;
Readonly::Scalar my $LNG_NY     => -74.006;
Readonly::Scalar my $LAT_LONDON => 51.5074;
Readonly::Scalar my $LNG_LONDON => -0.1278;

# Location strings and a lat/lng string used across multiple subtests
Readonly::Scalar my $LOC_DC     => '1600 Pennsylvania Ave NW, Washington, DC';
Readonly::Scalar my $LOC_LONDON => '10 Downing St, London, UK';
Readonly::Scalar my $LOC_USA    => 'Silver Spring, MD, USA';
Readonly::Scalar my $LATLNG_DC  => "$LAT_DC,$LNG_DC";

# ── Minimal mock geocoder packages ───────────────────────────────────────────
# Three distinct stubs so individual subtests can mock any combination.
# Each provides geocode(), reverse_geocode(), and ua() as no-ops by default.

package MockGeocoder::Alpha;
sub new            { bless {}, shift }
sub geocode        { return () }
sub reverse_geocode{ return () }
sub ua             { $_[0]->{ua} = $_[1]; return $_[1] }

package MockGeocoder::Beta;
sub new            { bless {}, shift }
sub geocode        { return () }
sub reverse_geocode{ return () }
sub ua             { $_[0]->{ua} = $_[1]; return $_[1] }

package MockGeocoder::Gamma;
sub new            { bless {}, shift }
sub geocode        { return () }
sub reverse_geocode{ return () }
sub ua             { $_[0]->{ua} = $_[1]; return $_[1] }

# Geocoder with a $VERSION so the clone-agent test can verify "Class/Version" format
package MockGeocoder::WithVersion;
our $VERSION = '2.0';
sub new            { bless {}, shift }
sub geocode        { return () }
sub reverse_geocode{ return () }
sub ua             { $_[0]->{_ua} = $_[1] if @_ > 1; $_[0]->{_ua} }

# Minimal UA that supports clone() and agent() -- used to test the ua() clone path
# without a real LWP::UserAgent dependency in this offline test file
package FakeCloneableUA;
sub new   { bless { _agent => 'libwww-perl/test' }, shift }
sub clone { bless { %{$_[0]} }, ref($_[0]) }
sub agent {
	my ($self, $new) = @_;
	$self->{_agent} = $new if @_ > 1;
	return $self->{_agent};
}

package main;

# ── Helper: build a list with one geocoder already pushed ─────────────────────
sub _make_list {
	my ($geocoder, %opts) = @_;
	my $list = Geo::Coder::List->new(%opts);
	$list->push($geocoder);
	return $list;
}

# ── Helper: a canonical OSM-style result hash ─────────────────────────────────
sub _osm_result {
	my ($lat, $lng) = @_;
	return { lat => $lat, lon => $lng };
}

# =============================================================================
# new()
# =============================================================================

subtest 'new: returns a blessed Geo::Coder::List object' => sub {
	my $obj = Geo::Coder::List->new();
	isa_ok($obj, 'Geo::Coder::List', 'new() returns correct class');
	ok(blessed($obj), 'return value is a blessed reference');
	returns_ok($obj, { type => 'object' }, 'satisfies object schema');
};

subtest 'new: initialises geocoders, locations, and log to empty state' => sub {
	my $obj = Geo::Coder::List->new();
	# All three internal collections must exist and be empty
	is(ref($obj->{geocoders}), 'ARRAY', 'geocoders is ARRAY ref');
	is(scalar @{$obj->{geocoders}}, 0,   'geocoders starts empty');
	is(ref($obj->{log}),       'ARRAY', 'log is ARRAY ref');
	is(scalar @{$obj->{log}},       0,   'log starts empty');
	is(ref($obj->{locations}), 'HASH',  'locations is HASH ref');
};

subtest 'new: accepts and stores debug flag' => sub {
	my $obj = Geo::Coder::List->new(debug => 2);
	is($obj->{debug}, 2, 'debug level stored correctly');
	diag("debug=$obj->{debug}") if $ENV{TEST_VERBOSE};
};

subtest 'new: accepts cache option' => sub {
	my $l2  = {};
	my $obj = Geo::Coder::List->new(cache => $l2);
	is($obj->{cache}, $l2, 'cache reference stored on object');
};

subtest 'new: accepts geocoders list passed directly as constructor arg' => sub {
	# Callers may pre-populate the geocoder list without push()
	my $g   = MockGeocoder::Alpha->new();
	my $obj = Geo::Coder::List->new(geocoders => [$g]);
	is(scalar @{$obj->{geocoders}}, 1,  'one geocoder stored');
	is($obj->{geocoders}[0], $g,         'correct geocoder object stored');
};

subtest 'new: clones when called on an existing instance' => sub {
	my $orig = Geo::Coder::List->new(debug => 0);
	$orig->push(MockGeocoder::Alpha->new());
	# Clone inherits the geocoder list and overrides debug
	my $clone = $orig->new(debug => 3);
	isa_ok($clone, 'Geo::Coder::List', 'clone is Geo::Coder::List');
	isnt(refaddr($clone), refaddr($orig), 'clone is a different object');
	is($clone->{debug}, 3,               'clone has the overridden debug');
	is(scalar @{$clone->{geocoders}}, 1, 'clone inherited geocoder list');
};

subtest 'new: ::new() (function call) with no args still returns an object' => sub {
	# Edge case: the module supports this for backwards compatibility
	my $obj = Geo::Coder::List::new();
	isa_ok($obj, 'Geo::Coder::List', '::new() returns a Geo::Coder::List');
};

subtest 'new: ::new() with arguments carps and returns undef' => sub {
	# Calling ::new() as a function with args is not supported
	my $result;
	warnings_like {
		$result = Geo::Coder::List::new(undef, debug => 1);
	} qr/use ->new\(\) not ::new\(\)/, 'correct carp message emitted';
	ok(!defined($result), 'returns undef when called incorrectly');
};

subtest 'new: no circular references in fresh object' => sub {
	my $obj = Geo::Coder::List->new();
	memory_cycle_ok($obj, 'no circular refs in fresh object');
};

subtest 'new: cache_hit_duration and siblings default to expected values' => sub {
	my $obj = Geo::Coder::List->new();
	is($obj->{cache_hit_duration},  '1 month', 'cache_hit_duration default');
	is($obj->{cache_part_duration}, '1 day',   'cache_part_duration default');
	is($obj->{cache_miss_duration}, '1 week',  'cache_miss_duration default');
};

# =============================================================================
# push()
# =============================================================================

subtest 'push: returns $self for method chaining' => sub {
	my $list = Geo::Coder::List->new();
	my $ret  = $list->push(MockGeocoder::Alpha->new());
	is(refaddr($ret), refaddr($list), 'push() returns $self');
	returns_ok($ret, { type => 'object' }, 'return satisfies object schema');
};

subtest 'push: appends geocoders in order' => sub {
	my $list = Geo::Coder::List->new();
	my ($a, $b) = (MockGeocoder::Alpha->new(), MockGeocoder::Beta->new());
	$list->push($a)->push($b);
	is($list->{geocoders}[0], $a, 'first geocoder is Alpha');
	is($list->{geocoders}[1], $b, 'second geocoder is Beta');
};

subtest 'push: accepts a plain geocoder object' => sub {
	my $list = Geo::Coder::List->new();
	my $g    = MockGeocoder::Alpha->new();
	$list->push($g);
	is(ref($list->{geocoders}[0]), 'MockGeocoder::Alpha',
		'plain object stored directly');
};

subtest 'push: accepts a hashref entry with regex, geocoder, and limit' => sub {
	my $list  = Geo::Coder::List->new();
	my $entry = { regex => qr/USA$/, geocoder => MockGeocoder::Alpha->new(), limit => 50 };
	$list->push($entry);
	my $stored = $list->{geocoders}[0];
	is(ref($stored),       'HASH', 'hashref entry stored as HASH');
	ok(exists $stored->{regex},    'regex key present in stored entry');
	is($stored->{limit}, 50,       'limit value stored correctly');
};

subtest 'push: croaks with no argument' => sub {
	my $list = Geo::Coder::List->new();
	throws_ok { $list->push() }
		qr/Usage: \(\$geocoder/,
		'push() without argument throws expected error';
};

# =============================================================================
# geocode()
# =============================================================================

subtest 'geocode: croaks when called with no arguments' => sub {
	# Params::Get::get_params croaks when the required key is absent
	my $list = new_ok('Geo::Coder::List');
	throws_ok { $list->geocode() } qr/Usage:/i,
		'geocode() with no args croaks';
};

subtest 'geocode: carps for empty location string' => sub {
	my $list = Geo::Coder::List->new({ carp_on_warn => 1 });
	warnings_like { $list->geocode(location => '') }
		qr/usage: geocode\(/,
		'empty string location emits expected carp';
};

subtest 'geocode: carps for undef location' => sub {
	my $list = Geo::Coder::List->new({ carp_on_warn => 1 });
	warnings_like { $list->geocode(location => undef) }
		qr/usage: geocode\(/,
		'undef location emits expected carp';
};

subtest 'geocode: croaks for numeric-only input' => sub {
	my $list = Geo::Coder::List->new();
	throws_ok { $list->geocode('99999') }
		qr/invalid input to geocode/,
		'numeric-only location string croaks';
};

subtest 'geocode: returns undef when no geocoders are configured' => sub {
	my $list   = Geo::Coder::List->new();
	my $result = $list->geocode($LOC_LONDON);
	ok(!defined($result), 'returns undef with empty geocoder chain');
};

subtest 'geocode: successful scalar result has canonical geometry structure' => sub {
	my $list = _make_list(MockGeocoder::Alpha->new());
	my $mock = mock_scoped 'MockGeocoder::Alpha::geocode' => sub {
		return _osm_result($LAT_DC, $LNG_DC);
	};

	my $result = $list->geocode(location => $LOC_DC);

	ok(defined $result, 'geocode() returned a defined result');
	is($result->{geometry}{location}{lat}, $LAT_DC, 'geometry.location.lat correct');
	is($result->{geometry}{location}{lng}, $LNG_DC, 'geometry.location.lng correct');
	is($result->{lat},                     $LAT_DC, 'lat convenience alias correct');
	is($result->{lng},                     $LNG_DC, 'lng convenience alias correct');
	is($result->{lon},                     $LNG_DC, 'lon compatibility alias correct');
	diag('result: ', Dumper($result)) if $ENV{TEST_VERBOSE};
};

subtest 'geocode: geocoder field holds the geocoder object (not a string)' => sub {
	my $g    = MockGeocoder::Alpha->new();
	my $list = _make_list($g);
	my $mock = mock_scoped 'MockGeocoder::Alpha::geocode' => sub {
		return _osm_result($LAT_DC, $LNG_DC);
	};

	my $result = $list->geocode($LOC_DC);
	is(ref($result->{geocoder}), 'MockGeocoder::Alpha',
		'geocoder field is the geocoder object');
};

subtest 'geocode: falls back to second geocoder when first throws' => sub {
	my ($a, $b) = (MockGeocoder::Alpha->new(), MockGeocoder::Beta->new());
	my $list = Geo::Coder::List->new({ carp_on_warn => 1 });
	$list->push($a)->push($b);

	my $mock_a = mock_scoped 'MockGeocoder::Alpha::geocode' => sub {
		die 'rate limit exceeded';
	};
	my $mock_b = mock_scoped 'MockGeocoder::Beta::geocode' => sub {
		return _osm_result($LAT_DC, $LNG_DC);
	};

	my $result;
	warnings_like { $result = $list->geocode($LOC_DC) } qr/rate limit exceeded/, 'error from Alpha is carped';

	ok(defined $result, 'result obtained from Beta after Alpha failed');
	is(ref($result->{geocoder}), 'MockGeocoder::Beta',
		'result came from the fallback geocoder');
};

subtest 'geocode: respects regex filter, skips non-matching geocoder' => sub {
	my ($a, $b) = (MockGeocoder::Alpha->new(), MockGeocoder::Beta->new());
	my $list    = Geo::Coder::List->new();
	# Alpha only handles USA addresses
	$list->push({ regex => qr/USA$/, geocoder => $a });
	$list->push($b);

	my $alpha_calls = 0;
	my $beta_calls  = 0;

	my $mock_a = mock_scoped 'MockGeocoder::Alpha::geocode' => sub {
		$alpha_calls++;
		return _osm_result($LAT_NY, $LNG_NY);
	};
	my $mock_b = mock_scoped 'MockGeocoder::Beta::geocode' => sub {
		$beta_calls++;
		return _osm_result($LAT_LONDON, $LNG_LONDON);
	};

	# London does not match /USA$/; only Beta should be tried
	$list->geocode($LOC_LONDON);

	is($alpha_calls, 0, 'Alpha not called for non-USA location');
	is($beta_calls,  1, 'Beta called for non-USA location');
};

subtest 'geocode: respects per-geocoder limit' => sub {
	my $list = Geo::Coder::List->new();
	$list->push({ geocoder => MockGeocoder::Alpha->new(), limit => 1 });

	my $calls = 0;
	my $mock  = mock_scoped 'MockGeocoder::Alpha::geocode' => sub {
		$calls++;
		return _osm_result($LAT_DC, $LNG_DC);
	};

	# First call uses up the limit; second should not reach the geocoder
	$list->geocode($LOC_USA);
	$list->geocode('Baltimore, MD, USA');

	is($calls, 1, 'geocoder called exactly once when limit is 1');
};

subtest 'geocode: L1 cache hit on repeated scalar-context call' => sub {
	my $list  = _make_list(MockGeocoder::Alpha->new());
	my $calls = 0;
	my $mock  = mock_scoped 'MockGeocoder::Alpha::geocode' => sub {
		$calls++;
		return _osm_result($LAT_DC, $LNG_DC);
	};

	my $r1 = $list->geocode($LOC_DC);
	my $r2 = $list->geocode($LOC_DC);

	is($calls, 1,       'backend called only once for the same location');
	is($r2->{geocoder}, 'cache', 'second result flagged as from cache');
};

subtest 'geocode: not-found result cached to avoid re-querying backends' => sub {
	my $list  = _make_list(MockGeocoder::Alpha->new());
	my $calls = 0;
	my $mock  = mock_scoped 'MockGeocoder::Alpha::geocode' => sub {
		$calls++;
		return ();    # nothing found
	};

	$list->geocode($LOC_DC);    # misses
	$list->geocode($LOC_DC);    # should hit the not-found L1 cache

	is($calls, 1, 'backend not called again after not-found cached in L1');
};

subtest 'geocode: list context returns all results from winning geocoder' => sub {
	my $list = _make_list(MockGeocoder::Alpha->new());
	my $mock = mock_scoped 'MockGeocoder::Alpha::geocode' => sub {
		return (
			_osm_result($LAT_DC, $LNG_DC),
			_osm_result($LAT_NY, $LNG_NY),
		);
	};

	my @results = $list->geocode($LOC_DC);
	ok(scalar @results >= 1, 'list context returns at least one result');
	ok(defined $results[0]{lat}, 'first result has lat key');
};

subtest 'geocode: writes a log entry on success' => sub {
	my $list = _make_list(MockGeocoder::Alpha->new());
	my $mock = mock_scoped 'MockGeocoder::Alpha::geocode' => sub {
		return _osm_result($LAT_DC, $LNG_DC);
	};

	$list->geocode($LOC_DC);

	my $log = $list->log();
	ok(scalar @{$log} > 0, 'at least one log entry written');
	my $e = $log->[0];
	is($e->{location}, $LOC_DC,             'log entry has correct location');
	is($e->{geocoder}, 'MockGeocoder::Alpha','log entry has geocoder class name');
	ok(exists $e->{timetaken},              'log entry has timetaken key');
};

subtest 'geocode: writes a log entry recording the error on failure' => sub {
	my $list = _make_list(MockGeocoder::Alpha->new(), (carp_on_warn => 1));
	my $mock = mock_scoped 'MockGeocoder::Alpha::geocode' => sub {
		die 'simulated API error';
	};

	warnings_like { $list->geocode($LOC_DC) } qr/simulated API error/, 'error is carped';

	my ($err) = grep { exists $_->{error} } @{$list->log()};
	ok(defined $err,                        'error log entry was created');
	like($err->{error}, qr/simulated API error/, 'error text recorded in log');
};

subtest 'geocode: decodes HTML entities before passing location to geocoder' => sub {
	my $list          = _make_list(MockGeocoder::Alpha->new());
	my $seen_location = '';
	my $mock = mock_scoped 'MockGeocoder::Alpha::geocode' => sub {
		my ($self_inner, %args) = @_;
		$seen_location = $args{location} // '';
		return ();
	};

	$list->geocode(location => 'Caf&eacute; Road, London, UK');

	# decode_entities expands &eacute; to the Unicode character; the raw
	# entity code must not reach the geocoder backend
	unlike($seen_location, qr/&eacute;/,
		'HTML entity code not passed raw to geocoder');
	like($seen_location, qr/Caf.+Road/,
		'rest of the location string intact after entity decode');
};

subtest 'geocode: no circular references in result after successful call' => sub {
	my $list = _make_list(MockGeocoder::Alpha->new());
	my $mock = mock_scoped 'MockGeocoder::Alpha::geocode' => sub {
		return _osm_result($LAT_DC, $LNG_DC);
	};

	my $result = $list->geocode($LOC_DC);
	memory_cycle_ok($list,   'no cycles in list object after geocode');
	memory_cycle_ok($result, 'no cycles in returned result hash');
};

# =============================================================================
# ua()
# =============================================================================

subtest 'ua: returns undef when called with no UA argument' => sub {
	my $list = Geo::Coder::List->new();
	ok(!defined $list->ua(), 'ua() with no arg returns undef');
};

subtest 'ua: returns the UA object that was passed in' => sub {
	my $list = _make_list(MockGeocoder::Alpha->new());
	my $ua   = bless { id => 'fake' }, 'FakeUA';
	my $mock = mock_scoped 'MockGeocoder::Alpha::ua' => sub { };  # accept silently

	my $ret = $list->ua($ua);
	is($ret, $ua, 'ua() returns the passed UA object');
};

subtest 'ua: propagates UA to every geocoder in the chain in order' => sub {
	my ($a, $b) = (MockGeocoder::Alpha->new(), MockGeocoder::Beta->new());
	my $list    = Geo::Coder::List->new();
	$list->push($a)->push($b);

	my @order;
	my $mock_a = mock_scoped 'MockGeocoder::Alpha::ua' => sub { push @order, 'alpha' };
	my $mock_b = mock_scoped 'MockGeocoder::Beta::ua'  => sub { push @order, 'beta'  };

	$list->ua(bless {}, 'FakeUA');
	is_deeply(\@order, [qw(alpha beta)],
		'UA propagated to each geocoder in push order');
};

subtest 'ua: propagates through hashref chain entries' => sub {
	my $g    = MockGeocoder::Alpha->new();
	my $list = Geo::Coder::List->new();
	$list->push({ regex => qr/.*/, geocoder => $g });

	my $called = 0;
	my $mock   = mock_scoped 'MockGeocoder::Alpha::ua' => sub { $called++ };

	$list->ua(bless {}, 'FakeUA');
	is($called, 1, 'ua() called on geocoder inside a hashref entry');
};

subtest 'ua: croaks when a chain entry contains an undef geocoder' => sub {
	my $list = Geo::Coder::List->new();
	# Inject a malformed entry; no geocoder key
	push @{$list->{geocoders}}, { regex => qr/.*/, geocoder => undef };

	throws_ok { $list->ua(bless {}, 'FakeUA') }
		qr/No geocoder found/,
		'ua() croaks on a chain entry with undef geocoder';
};

# =============================================================================
# reverse_geocode()
# =============================================================================

subtest 'reverse_geocode: croaks when called with no latlng argument' => sub {
	my $list = Geo::Coder::List->new();
	throws_ok { $list->reverse_geocode() } qr/Usage:/i,
		'reverse_geocode() with no args croaks';
};

subtest 'reverse_geocode: returns OSM display_name in scalar context' => sub {
	my $list = _make_list(MockGeocoder::Alpha->new());
	my $mock = mock_scoped 'MockGeocoder::Alpha::reverse_geocode' => sub {
		return { display_name => '10 Downing Street, London' };
	};

	my $addr = $list->reverse_geocode(latlng => $LATLNG_DC);
	is($addr, '10 Downing Street, London', 'OSM display_name returned as address');
};

subtest 'reverse_geocode: returns undef when no geocoders are configured' => sub {
	my $list   = Geo::Coder::List->new();
	my $result = $list->reverse_geocode(latlng => $LATLNG_DC);
	ok(!defined $result, 'returns undef with empty geocoder chain');
};

subtest 'reverse_geocode: caches result and does not re-query on second call' => sub {
	my $list  = _make_list(MockGeocoder::Alpha->new());
	my $calls = 0;
	my $mock  = mock_scoped 'MockGeocoder::Alpha::reverse_geocode' => sub {
		$calls++;
		return { display_name => 'Somewhere Nice' };
	};

	my $a1 = $list->reverse_geocode(latlng => $LATLNG_DC);
	my $a2 = $list->reverse_geocode(latlng => $LATLNG_DC);

	is($calls, 1, 'backend called only once for the same latlng');
	is($a2, $a1,  'second call returns the same address');
};

subtest 'reverse_geocode: list context collects display_name from each result' => sub {
	my $list = _make_list(MockGeocoder::Alpha->new());
	my $mock = mock_scoped 'MockGeocoder::Alpha::reverse_geocode' => sub {
		return (
			{ display_name => 'Address One' },
			{ display_name => 'Address Two' },
		);
	};

	my @addrs = $list->reverse_geocode(latlng => $LATLNG_DC);
	ok(scalar @addrs >= 1, 'list context returns at least one address');
	is($addrs[0], 'Address One', 'first address correct');
};

subtest 'reverse_geocode: writes log entry on success' => sub {
	my $list = _make_list(MockGeocoder::Alpha->new());
	my $mock = mock_scoped 'MockGeocoder::Alpha::reverse_geocode' => sub {
		return { display_name => 'Test Address' };
	};

	$list->reverse_geocode(latlng => $LATLNG_DC);

	my $entries = $list->log();
	ok(scalar @{$entries} > 0, 'log entry written after reverse_geocode');
	ok(exists $entries->[0]{location}, 'log entry has location key');
};

# =============================================================================
# log()
# =============================================================================

subtest 'log: returns an arrayref on a fresh object' => sub {
	my $list = Geo::Coder::List->new();
	my $log  = $list->log();
	is(ref($log), 'ARRAY', 'log() returns ARRAY ref');
	is(scalar @{$log}, 0,  'log is empty on a fresh object');
	returns_ok($log, { type => 'arrayref' }, 'satisfies arrayref schema');
};

subtest 'log: returns a valid arrayref even immediately after flush' => sub {
	my $list = Geo::Coder::List->new();
	$list->flush();
	my $log = $list->log();
	is(ref($log), 'ARRAY', 'log() returns ARRAY ref after flush');
};

subtest 'log: entries have all expected keys on a successful geocode' => sub {
	my $list = _make_list(MockGeocoder::Alpha->new());
	my $mock = mock_scoped 'MockGeocoder::Alpha::geocode' => sub {
		return _osm_result($LAT_DC, $LNG_DC);
	};

	$list->geocode($LOC_DC);

	my $entry = $list->log()->[0];
	for my $key (qw(line location timetaken geocoder wantarray)) {
		ok(exists $entry->{$key}, "log entry has '$key' key");
	}
	diag(Dumper($entry)) if $ENV{TEST_VERBOSE};
};

# =============================================================================
# flush()
# =============================================================================

subtest 'flush: returns $self to allow chaining' => sub {
	my $list = Geo::Coder::List->new();
	my $ret  = $list->flush();
	is(refaddr($ret), refaddr($list), 'flush() returns $self');
	returns_ok($ret, { type => 'object' }, 'return satisfies object schema');
};

subtest 'flush: clears log entries' => sub {
	my $list = _make_list(MockGeocoder::Alpha->new());
	my $mock = mock_scoped 'MockGeocoder::Alpha::geocode' => sub {
		return _osm_result($LAT_DC, $LNG_DC);
	};

	$list->geocode($LOC_DC);
	ok(scalar @{$list->log()} > 0, 'log has entries before flush');

	$list->flush();
	is(scalar @{$list->log()}, 0, 'log is empty after flush');
};

subtest 'flush: does not invalidate the L1 cache' => sub {
	my $list  = _make_list(MockGeocoder::Alpha->new());
	my $calls = 0;
	my $mock  = mock_scoped 'MockGeocoder::Alpha::geocode' => sub {
		$calls++;
		return _osm_result($LAT_DC, $LNG_DC);
	};

	$list->geocode($LOC_DC);
	$list->flush();

	# After flush, the L1 cache must still hold the earlier result
	my $r = $list->geocode($LOC_DC);
	is($calls, 1,          'backend not re-called after flush');
	is($r->{geocoder}, 'cache', 'result served from L1 cache after flush');
};

# =============================================================================
# Response normalisation - tested via geocode() with provider-shaped mocks
# Each subtest sends the exact structure a real provider returns and asserts
# that geocode() maps it to the canonical geometry.location.{lat,lng} shape.
# =============================================================================

# Shared helper: run geocode() with a one-shot mocked geocoder and return result
sub _geocode_with_response {
	my ($response) = @_;
	my $list = _make_list(MockGeocoder::Alpha->new());
	my $mock = mock_scoped 'MockGeocoder::Alpha::geocode' => sub { $response };
	return $list->geocode($LOC_DC);
}

subtest 'normalise: already-canonical geometry.location.lat/lng passthrough' => sub {
	my $result = _geocode_with_response(
		{ geometry => { location => { lat => $LAT_DC, lng => $LNG_DC } } }
	);
	ok(defined $result, 'result returned');
	is($result->{geometry}{location}{lat}, $LAT_DC, 'lat preserved');
	is($result->{geometry}{location}{lng}, $LNG_DC, 'lng preserved');
};

subtest 'normalise: OSM/RandMcNally top-level lat/lon' => sub {
	my $result = _geocode_with_response({ lat => $LAT_DC, lon => $LNG_DC });
	ok(defined $result, 'result returned for OSM response');
	is($result->{geometry}{location}{lat}, $LAT_DC, 'lat mapped from top-level lat');
	is($result->{geometry}{location}{lng}, $LNG_DC, 'lng mapped from top-level lon');
	is($result->{lat},                     $LAT_DC, 'lat alias set');
	is($result->{lon},                     $LNG_DC, 'lon alias set');
};

subtest 'normalise: Bing BestLocation.Coordinates.{Latitude,Longitude}' => sub {
	my $result = _geocode_with_response({ BestLocation => { Coordinates => {
		Latitude => $LAT_DC, Longitude => $LNG_DC,
	} } });
	ok(defined $result,                            'result returned for Bing BestLocation');
	is($result->{geometry}{location}{lat}, $LAT_DC, 'lat from BestLocation.Coordinates');
};

subtest 'normalise: Bing point.coordinates [lat, lng]' => sub {
	# Bing point: coordinates[0]=lat, coordinates[1]=lng
	my $result = _geocode_with_response(
		{ point => { coordinates => [$LAT_DC, $LNG_DC] } }
	);
	ok(defined $result, 'result returned for Bing point response');
	is($result->{geometry}{location}{lat}, $LAT_DC, 'lat from point.coordinates[0]');
	is($result->{geometry}{location}{lng}, $LNG_DC, 'lng from point.coordinates[1]');
};

subtest 'normalise: geocoder.ca latt/longt fields' => sub {
	my $result = _geocode_with_response({ latt => $LAT_DC, longt => $LNG_DC });
	ok(defined $result,                            'result returned for geocoder.ca');
	is($result->{geometry}{location}{lat}, $LAT_DC, 'lat from latt');
	is($result->{geometry}{location}{lng}, $LNG_DC, 'lng from longt');
};

subtest 'normalise: postcodes.io latitude/longitude with local_type' => sub {
	my $result = _geocode_with_response(
		{ latitude => $LAT_DC, longitude => $LNG_DC, local_type => 'Village' }
	);
	ok(defined $result,                            'result returned for postcodes.io');
	is($result->{geometry}{location}{lat}, $LAT_DC, 'lat from latitude');
	# local_type should be downcased into the type field
	is($result->{type}, 'village', 'local_type downcased to type');
};

subtest 'normalise: HERE/Ovi properties.geoLatitude/geoLongitude' => sub {
	my $result = _geocode_with_response(
		{ properties => { geoLatitude => $LAT_DC, geoLongitude => $LNG_DC } }
	);
	ok(defined $result,                            'result returned for HERE/Ovi');
	is($result->{geometry}{location}{lat}, $LAT_DC, 'lat from properties.geoLatitude');
};

subtest 'normalise: DataScienceToolkit results[0].geometry.location.{lat,lng}' => sub {
	my $result = _geocode_with_response(
		{ results => [{ geometry => { location => { lat => $LAT_DC, lng => $LNG_DC } } }] }
	);
	ok(defined $result,                            'result for DataScienceToolkit');
	is($result->{geometry}{location}{lat}, $LAT_DC, 'lat from results[0].geometry.location');
};

subtest 'normalise: OpenCage results[0].geometry.{lat,lng} (no location subkey)' => sub {
	my $result = _geocode_with_response(
		{ results => [{ geometry => { lat => $LAT_DC, lng => $LNG_DC } }] }
	);
	ok(defined $result,                            'result for OpenCage');
	is($result->{geometry}{location}{lat}, $LAT_DC, 'lat from results[0].geometry.lat');
};

subtest 'normalise: GeoCodeFarm RESULTS[0].COORDINATES.{latitude,longitude}' => sub {
	my $result = _geocode_with_response(
		{ RESULTS => [{ COORDINATES => { latitude => $LAT_DC, longitude => $LNG_DC } }] }
	);
	ok(defined $result,                            'result for GeoCodeFarm');
	is($result->{geometry}{location}{lat}, $LAT_DC, 'lat from RESULTS.COORDINATES');
};

subtest 'normalise: US Census result.addressMatches.coordinates.{y=lat, x=lng}' => sub {
	my $result = _geocode_with_response(
		{ result => { addressMatches => [{ coordinates => { y => $LAT_DC, x => $LNG_DC } }] } }
	);
	ok(defined $result,                            'result for US Census');
	is($result->{geometry}{location}{lat}, $LAT_DC, 'lat from coordinates.y');
	is($result->{geometry}{location}{lng}, $LNG_DC, 'lng from coordinates.x');
};

subtest 'normalise: GeoNames top-level lat/lng (no lon key, avoids OSM branch)' => sub {
	# OSM branch fires on lat && defined(lon); GeoNames uses lng not lon,
	# so the fallback lat/lng branch must handle this case instead.
	my $result = _geocode_with_response({ lat => $LAT_DC, lng => $LNG_DC });
	ok(defined $result,                            'result for GeoNames');
	is($result->{geometry}{location}{lat}, $LAT_DC, 'lat extracted correctly');
	is($result->{geometry}{location}{lng}, $LNG_DC, 'lng extracted correctly');
};

subtest 'normalise: Mapbox features[0].center [lng, lat] (GeoJSON order)' => sub {
	# GeoJSON arrays are [longitude, latitude]; center[0]=lng, center[1]=lat
	my $result = _geocode_with_response(
		{ features => [{ center => [$LNG_DC, $LAT_DC] }] }
	);
	ok(defined $result,                            'result for Mapbox');
	is($result->{geometry}{location}{lat}, $LAT_DC, 'lat from center[1]');
	is($result->{geometry}{location}{lng}, $LNG_DC, 'lng from center[0]');
};

subtest 'normalise: GeoApify features[0].geometry.coordinates [lng, lat]' => sub {
	# GeoJSON: coordinates[0]=lng, coordinates[1]=lat
	my $result = _geocode_with_response(
		{ features => [{ geometry => { coordinates => [$LNG_DC, $LAT_DC] } }] }
	);
	ok(defined $result,                            'result for GeoApify with coordinates');
	is($result->{geometry}{location}{lat}, $LAT_DC, 'lat from coordinates[1]');
	is($result->{geometry}{location}{lng}, $LNG_DC, 'lng from coordinates[0]');
};

subtest 'normalise: GeoApify empty features signals not-found; geocode returns undef' => sub {
	# GeoApify emits a features array with no coords to signal not-found
	my $list = _make_list(MockGeocoder::Alpha->new());
	my $mock = mock_scoped 'MockGeocoder::Alpha::geocode' => sub {
		return { features => [{}] };
	};
	my $result = $list->geocode($LOC_DC);
	ok(!defined $result, 'geocode returns undef for GeoApify not-found response');
};

subtest 'normalise: geocoder.xyz standard.countryname lifted to address.country' => sub {
	my $result = _geocode_with_response({
		lat      => $LAT_DC,
		lon      => $LNG_DC,
		standard => { countryname => 'United States' },
	});
	ok(defined $result, 'result returned');
	is($result->{address}{country}, 'United States',
		'countryname hoisted from standard.countryname to address.country');
};

subtest 'normalise: geocode returns undef for completely unrecognised structure' => sub {
	my $list = _make_list(MockGeocoder::Alpha->new());
	my $mock = mock_scoped 'MockGeocoder::Alpha::geocode' => sub {
		return { totally_unknown_field => 'whatever' };
	};
	my $result = $list->geocode($LOC_DC);
	ok(!defined $result, 'geocode returns undef when no coordinate fields found');
};

# =============================================================================
# _build_ca_address() - internal helper (plain sub, no $self)
# =============================================================================

subtest '_build_ca_address: assembles US address with correct separators' => sub {
	# Street number + name: space; city/state/country: comma-space
	my $loc = {
		city => 'Bethesda',
		usa  => {
			usstnumber  => '9000',
			usstaddress => 'Rockville Pike',
			uscity      => 'Bethesda',
			state       => 'MD',
		},
	};
	my $result = Geo::Coder::List::_build_ca_address($loc);
	is($result, '9000 Rockville Pike, Bethesda, MD, USA',
		'US address format: number<space>street, city, state, USA');
};

subtest '_build_ca_address: US address without street number' => sub {
	my $loc = { city => 'Bethesda', usa => { uscity => 'Bethesda', state => 'MD' } };
	my $result = Geo::Coder::List::_build_ca_address($loc);
	# city and state should appear; no leading comma from missing number
	like($result,   qr/Bethesda/,  'city present in output');
	like($result,   qr/MD/,        'state present in output');
	like($result,   qr/USA$/,      'country always appended for US branch');
	unlike($result, qr/^,\s*/,     'no leading comma when number absent');
};

subtest '_build_ca_address: assembles Canadian address correctly' => sub {
	my $loc = {
		stnumber  => '22',
		staddress => 'Main Street',
		city      => 'Ottawa',
		prov      => 'ON',
	};
	my $result = Geo::Coder::List::_build_ca_address($loc);
	is($result, '22 Main Street, Ottawa, ON',
		'CA address: number<space>street, city, province');
};

subtest '_build_ca_address: returns empty string when no recognisable fields' => sub {
	my $result = Geo::Coder::List::_build_ca_address({ other => 'stuff' });
	ok(!$result, 'returns empty/false when no city or usa subhash present');
};

subtest '_build_ca_address: Canadian address without street number starts cleanly' => sub {
	my $loc    = { staddress => 'Elm Ave', city => 'Toronto', prov => 'ON' };
	my $result = Geo::Coder::List::_build_ca_address($loc);
	like($result,   qr/Elm Ave/,   'street address in output');
	unlike($result, qr/^\s*,/,     'no leading comma when number is absent');
};

subtest '_build_ca_address: does not clobber $_ in calling scope' => sub {
	local $_ = 'outer_sentinel';
	Geo::Coder::List::_build_ca_address({ stnumber => '1', city => 'X' });
	is($_, 'outer_sentinel', '$_ not modified by _build_ca_address');
};

# =============================================================================
# _cache() - internal helper
# =============================================================================

subtest '_cache: read on uncached key returns undef' => sub {
	my $obj = Geo::Coder::List->new();
	ok(!defined $obj->_cache('never-seen-key'), 'undef for uncached key');
};

subtest '_cache: write then read round-trips a hashref value' => sub {
	my $obj = Geo::Coder::List->new();
	my $val = { geometry => { location => { lat => $LAT_DC, lng => $LNG_DC } } };
	$obj->_cache('London, UK', $val);
	my $rc = $obj->_cache('London, UK');
	ok(defined $rc,                              'cached value retrieved');
	is($rc->{geometry}{location}{lat}, $LAT_DC, 'lat round-trips correctly');
};

subtest '_cache: write undef stores a not-found sentinel; read returns undef' => sub {
	my $obj = Geo::Coder::List->new();
	# Writing undef records "looked up; not found" so backends are not re-tried
	$obj->_cache('Nowhere, XX', undef);
	ok(exists $obj->{locations}{'Nowhere, XX'}, 'sentinel exists in L1');
	ok(!defined $obj->_cache('Nowhere, XX'),    'read of sentinel returns undef');
};

subtest '_cache: not-found sentinel is not propagated to L2 HASH cache' => sub {
	my $l2  = {};
	my $obj = Geo::Coder::List->new(cache => $l2);
	$obj->_cache('No Place', undef);
	ok(!exists $l2->{'No Place'}, 'sentinel not written to L2');
};

subtest '_cache: found result is written to L2 HASH cache' => sub {
	my $l2  = {};
	my $obj = Geo::Coder::List->new(cache => $l2);
	my $val = { geometry => { location => { lat => $LAT_DC, lng => $LNG_DC } } };
	$obj->_cache('Washington DC', $val);
	ok(exists $l2->{'Washington DC'}, 'found result written to L2');
};

subtest '_cache: populates lat/lng/lon aliases on read' => sub {
	my $obj = Geo::Coder::List->new();
	# Write directly to L1 to bypass the write path (testing read path only)
	$obj->{locations}{'mykey'} = {
		geometry => { location => { lat => $LAT_DC, lng => $LNG_DC } },
	};
	my $rc = $obj->_cache('mykey');
	is($rc->{lat}, $LAT_DC, 'lat alias populated on read');
	is($rc->{lng}, $LNG_DC, 'lng alias populated on read');
	is($rc->{lon}, $LNG_DC, 'lon alias (equals lng) populated on read');
};

subtest '_cache: L2 CHI object receives set() call with 1-month TTL for found result' => sub {
	# A minimal CHI-compatible stub that records calls to set()
	my @set_calls;
	my $l2 = bless { _data => {} }, 'FakeCHI::Hit';
	{
		no strict 'refs';
		*{'FakeCHI::Hit::get'} = sub { $_[0]->{_data}{$_[1]} };
		*{'FakeCHI::Hit::set'} = sub {
			my ($self, $key, $val, $ttl) = @_;
			push @set_calls, { key => $key, ttl => $ttl };
			$self->{_data}{$key} = $val;
		};
	}

	my $obj = Geo::Coder::List->new(cache => $l2);
	my $val = { geometry => { location => { lat => $LAT_DC, lng => $LNG_DC } } };
	$obj->_cache('DC', $val);

	is(scalar @set_calls, 1, 'set() called exactly once');
	like($set_calls[0]{ttl}, qr/month/i,
		'TTL for a confirmed location is 1 month');
};

# =============================================================================
# geocode() -- shallow-copy cache-hit behaviour (new in 0.37)
# Each cache hit returns a fresh copy; the original caller variable and the
# L1 cache entry are never mutated in place.
# =============================================================================

subtest 'geocode: cache hit returns a shallow copy; original variable not mutated' => sub {
	my $list = _make_list(MockGeocoder::Alpha->new());
	my $mock = mock_scoped 'MockGeocoder::Alpha::geocode' => sub {
		return _osm_result($LAT_DC, $LNG_DC);
	};

	# First call: live geocode stores the geocoder object in the result
	my $live = $list->geocode($LOC_DC);
	ok(defined $live, 'first call returned a result');

	# Second call: cache hit -- must NOT modify $live
	my $cached = $list->geocode($LOC_DC);

	is(ref($live->{'geocoder'}), 'MockGeocoder::Alpha',
		'Original variable: geocoder field still holds the geocoder object');
	is($cached->{'geocoder'}, 'cache',
		'Cache-hit copy: geocoder field is the string "cache"');
};

subtest 'geocode: each cache hit returns a distinct object (not the L1 entry itself)' => sub {
	my $list = _make_list(MockGeocoder::Alpha->new());
	my $mock = mock_scoped 'MockGeocoder::Alpha::geocode' => sub {
		return _osm_result($LAT_DC, $LNG_DC);
	};

	$list->geocode($LOC_DC);                    # populate L1

	my $r1 = $list->geocode($LOC_DC);           # first cache hit
	my $r2 = $list->geocode($LOC_DC);           # second cache hit

	isnt(refaddr($r1), refaddr($r2),
		'Consecutive cache hits return distinct copy objects');
	is($r1->{'geometry'}{'location'}{'lat'},
	   $r2->{'geometry'}{'location'}{'lat'},
	   'Both copies carry the same canonical lat');
};

subtest 'geocode: L1 cache entry retains original geocoder object after cache hits' => sub {
	my $list = _make_list(MockGeocoder::Alpha->new());
	my $mock = mock_scoped 'MockGeocoder::Alpha::geocode' => sub {
		return _osm_result($LAT_DC, $LNG_DC);
	};

	$list->geocode($LOC_DC);      # populate L1
	$list->geocode($LOC_DC);      # cache hit 1 -- must not mutate L1
	$list->geocode($LOC_DC);      # cache hit 2

	# Inspect L1 directly: the entry must still hold the live geocoder object
	my $l1 = $list->{'locations'}{$LOC_DC};
	is(ref($l1->{'geocoder'}), 'MockGeocoder::Alpha',
		'L1 cache entry geocoder field still holds the geocoder object (not mutated)');
};

# =============================================================================
# ua() -- per-geocoder clone with agent string (new in 0.37)
# When the incoming UA supports clone() and agent(), each geocoder receives
# a private clone whose agent string is set to "ClassName/Version".
# =============================================================================

subtest 'ua: with cloneable UA, geocoder receives a clone, not the original' => sub {
	my $list = _make_list(MockGeocoder::Alpha->new());
	my $ua   = FakeCloneableUA->new();

	my $received_ua;
	my $mock = mock_scoped 'MockGeocoder::Alpha::ua' => sub {
		(undef, $received_ua) = @_;
	};

	$list->ua($ua);

	ok(defined $received_ua, 'geocoder->ua() was called with a UA argument');
	isnt(refaddr($received_ua), refaddr($ua),
		'Geocoder received a clone, not the original UA reference');
};

subtest 'ua: clone agent string is the geocoder class name (no $VERSION)' => sub {
	# MockGeocoder::Alpha has no $VERSION, so agent = class name only
	my $list = _make_list(MockGeocoder::Alpha->new());
	my $ua   = FakeCloneableUA->new();

	my $received_ua;
	my $mock = mock_scoped 'MockGeocoder::Alpha::ua' => sub {
		(undef, $received_ua) = @_;
	};

	$list->ua($ua);
	like($received_ua->agent(), qr/^MockGeocoder::Alpha/,
		'Clone agent starts with geocoder class name when $VERSION is absent');
};

subtest 'ua: clone agent string is "ClassName/Version" when geocoder has $VERSION' => sub {
	my $list = Geo::Coder::List->new()->push(MockGeocoder::WithVersion->new());
	my $ua   = FakeCloneableUA->new();

	my $received_ua;
	my $mock = mock_scoped 'MockGeocoder::WithVersion::ua' => sub {
		(undef, $received_ua) = @_;
	};

	$list->ua($ua);
	is($received_ua->agent(), 'MockGeocoder::WithVersion/2.0',
		'Clone agent is "ClassName/Version" when geocoder has $VERSION');
};

subtest 'ua: original UA is returned even when clones are made' => sub {
	my $list = _make_list(MockGeocoder::Alpha->new());
	my $ua   = FakeCloneableUA->new();
	my $mock = mock_scoped 'MockGeocoder::Alpha::ua' => sub { };

	my $ret = $list->ua($ua);
	is(refaddr($ret), refaddr($ua),
		'ua() returns the original UA object, not a per-geocoder clone');
};

subtest 'ua: multiple geocoders each receive an independent clone' => sub {
	my ($a, $b) = (MockGeocoder::Alpha->new(), MockGeocoder::Beta->new());
	my $list    = Geo::Coder::List->new()->push($a)->push($b);
	my $ua      = FakeCloneableUA->new();

	my ($got_a, $got_b);
	my $mock_a = mock_scoped 'MockGeocoder::Alpha::ua' => sub { (undef, $got_a) = @_ };
	my $mock_b = mock_scoped 'MockGeocoder::Beta::ua'  => sub { (undef, $got_b) = @_ };

	$list->ua($ua);

	ok(defined $got_a && defined $got_b, 'both geocoders received a UA');
	isnt(refaddr($got_a), refaddr($got_b),
		'Each geocoder received a distinct clone');
	isnt(refaddr($got_a), refaddr($ua), 'Alpha clone is not the original');
	isnt(refaddr($got_b), refaddr($ua), 'Beta clone is not the original');
};

subtest 'ua: UA without clone() is passed directly (backward compatibility)' => sub {
	# FakeUA has no clone() method, so the new clone path must not fire
	my $list = _make_list(MockGeocoder::Alpha->new());
	my $ua   = bless { id => 'no-clone' }, 'FakeUA';

	my $received_ua;
	my $mock = mock_scoped 'MockGeocoder::Alpha::ua' => sub {
		(undef, $received_ua) = @_;
	};

	$list->ua($ua);
	is(refaddr($received_ua), refaddr($ua),
		'UA without clone() is passed as-is (same reference)');
};

# =============================================================================
# reverse_geocode() -- strict-validation latlng retry (new in 0.37)
# If a geocoder rejects 'latlng' as an unknown parameter, the call is retried
# without it; lat and lon are already present from the coordinate split.
# =============================================================================

subtest 'reverse_geocode: retries without latlng when geocoder rejects it as unknown' => sub {
	my $list = _make_list(MockGeocoder::Alpha->new());
	my %retry_params;
	my $mock = mock_scoped 'MockGeocoder::Alpha::reverse_geocode' => sub {
		my ($self, %args) = @_;
		# Simulate strict parameter validation rejecting 'latlng'
		die "validate_strict: Unknown parameter 'latlng'\n" if exists $args{latlng};
		%retry_params = %args;
		return { display_name => 'Test Address, London' };
	};

	my $r = $list->reverse_geocode(latlng => $LATLNG_DC);

	is($r, 'Test Address, London', 'Result returned after latlng-retry');
	ok(!exists $retry_params{latlng}, 'Retry call did not include latlng key');
	ok( exists $retry_params{lat},    'Retry call included lat');
	ok( exists $retry_params{lon},    'Retry call included lon');
};

subtest 'reverse_geocode: does not retry on non-latlng errors' => sub {
	my $list  = _make_list(MockGeocoder::Alpha->new(), (carp_on_warn => 1));
	my $calls = 0;
	my $mock = mock_scoped 'MockGeocoder::Alpha::reverse_geocode' => sub {
		$calls++;
		die 'network timeout';
	};

	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };
	my $r = $list->reverse_geocode(latlng => $LATLNG_DC);

	is($calls, 1,  'Non-latlng error: geocoder called exactly once (no retry)');
	is($r, undef,  'Non-latlng error: result is undef');
	ok($warned,    'Non-latlng error: warning emitted via carp');
};

subtest 'reverse_geocode: list context also retries without latlng on strict validation' => sub {
	my $list = _make_list(MockGeocoder::Alpha->new());
	my $mock = mock_scoped 'MockGeocoder::Alpha::reverse_geocode' => sub {
		my ($self, %args) = @_;
		die "validate_strict: Unknown parameter 'latlng'\n" if exists $args{latlng};
		return ({ display_name => 'List Retry Address' });
	};

	my @r = $list->reverse_geocode(latlng => $LATLNG_DC);
	ok(scalar @r >= 1,          'List context: at least one result after latlng-retry');
	is($r[0], 'List Retry Address', 'List context: correct address returned');
};

# =============================================================================

subtest '_cache: set() is not called on L2 for a not-found result' => sub {
	# Not-found sentinel is L1-only; it must not leak into the external L2 store
	my @set_calls;
	my $l2 = bless { _data => {} }, 'FakeCHI::Miss';
	{
		no strict 'refs';
		*{'FakeCHI::Miss::get'} = sub { $_[0]->{_data}{$_[1]} };
		*{'FakeCHI::Miss::set'} = sub {
			my ($self, $key, $val, $ttl) = @_;
			push @set_calls, { key => $key, ttl => $ttl };
		};
	}

	my $obj = Geo::Coder::List->new(cache => $l2);
	$obj->_cache('Nowhere', undef);

	is(scalar @set_calls, 0, 'set() not called on L2 for a not-found result');
};

# =============================================================================
# HOSTILE-CONDITION TESTS
#
# Everything below tries to break, bypass or corrupt the module: malformed
# and malicious input, backends and caches that fail mid-flight, results that
# are incomplete or oversized, and callers whose global state must survive a
# call.  Each subtest states the behaviour it insists on, not the behaviour the
# code happened to have.
# =============================================================================

# Messages the module is documented to produce; matched exactly so that a
# changed or missing guard is noticed
Readonly::Scalar my $MSG_PUSH_USAGE  => 'Geo::Coder::List::push: Usage: ($geocoder)';
Readonly::Scalar my $MSG_RG_USAGE    => 'Usage: reverse_geocode(latlng => $location)';
Readonly::Scalar my $MSG_INVALID     => 'Usage: Geo::Coder::List: invalid input to geocode(), ';
Readonly::Scalar my $MSG_NOT_A_LOC   => 'a reference is not a location';
Readonly::Scalar my $MSG_NO_GEOCODER => 'No geocoder found';

# Values a caller's globals hold before a call, to prove they hold them after
Readonly::Scalar my $OUTER_EVAL_ERROR => "outer error\n";
Readonly::Scalar my $OUTER_TOPIC      => 'outer topic';

# Sizes for resource-exhaustion tests: big enough to expose quadratic or
# recursive handling, small enough to run in well under a second
my %hostile = (
	many_results  => 10_000,
	long_location => 100_000,
	limit_one     => 1,
	limit_zero    => 0,
	limit_neg     => -1,
);

# The TTLs the module defaults to, by result quality
Readonly::Scalar my $TTL_HIT  => '1 month';
Readonly::Scalar my $TTL_PART => '1 day';
Readonly::Scalar my $TTL_MISS => '1 week';

# A CHI-like store that records every call and can be told to fail
{
	package Hostile::CHI;
	sub new { my ($class, %args) = @_; bless { data => {}, sets => [], gets => 0, %args }, $class }
	sub get {
		my ($self, $key) = @_;
		$self->{gets}++;
		die "cache get exploded\n" if $self->{die_on_get};
		return $self->{data}{$key};
	}
	sub set {
		my ($self, $key, $val, $ttl) = @_;
		die "cache set exploded\n" if $self->{die_on_set};
		push @{$self->{sets}}, { key => $key, val => $val, ttl => $ttl };
		$self->{data}{$key} = $val;
	}
}

# A logger that records what it is given instead of printing it
{
	package Hostile::Logger;
	sub new   { bless { debug => [], warn => [], error => [] }, shift }
	sub debug { my $self = shift; push @{$self->{debug}}, join('', @_) }
	sub warn  { my $self = shift; push @{$self->{warn}},  join('', @_) }
	sub error { my $self = shift; push @{$self->{error}}, join('', @_) }
}

# A list whose warnings and errors go to Carp rather than the configured
# logger, so that warnings_like and throws_ok can see them
sub _carping_list {
	my $list = Geo::Coder::List->new();
	delete $list->{logger};
	$list->push($_) for @_;
	return $list;
}

# Run a block with STDOUT captured, returning what it printed
sub _stdout_of {
	my $code = shift;
	my $out  = '';
	{
		local *STDOUT;
		open(STDOUT, '>', \$out) or die "cannot capture STDOUT: $!";
		$code->();
		close(STDOUT);
	}
	return $out;
}

# Count calls to a mock geocoder method while returning a fixed answer.  In
# scalar context a backend returns its first answer, or undef for none, as a
# real one would; returning the array would hand back its length.
sub _counting {
	my ($counter, @answer) = @_;
	return sub { ${$counter}++; return wantarray ? @answer : $answer[0] };
}

# =============================================================================
# _could_be_a_location() - internal helper
# =============================================================================

subtest '_could_be_a_location: accepts an ordinary place name' => sub {
	# Purpose: the baseline the negative tests below are measured against
	returns_ok(Geo::Coder::List::_could_be_a_location($LOC_LONDON),
		{ type => 'integer', min => 1, max => 1 }, 'place name is a location');
};

subtest '_could_be_a_location: refuses every kind of non-string' => sub {
	# Purpose: a reference must be refused however it would stringify; the
	# hole this guards is looking up 'HASH(0x...)' as if it were a place
	my %refs = (
		'array ref'  => [ $LOC_LONDON ],
		'hash ref'   => { location => $LOC_LONDON },
		'code ref'   => sub { $LOC_LONDON },
		'scalar ref' => \$LOC_LONDON,
		'object'     => bless({}, 'Some::Object'),
	);
	for my $name (sort keys %refs) {
		is(Geo::Coder::List::_could_be_a_location($refs{$name}), 0, "$name refused");
	}
};

subtest '_could_be_a_location: refuses undef, empty and digit-only strings' => sub {
	# Purpose: a digit string is what a numeric column holds when the wrong
	# column has been read; it must never reach a paid backend
	for my $bad (undef, '', '12345', '0') {
		is(Geo::Coder::List::_could_be_a_location($bad), 0,
			'refused: ' . (defined($bad) ? "'$bad'" : 'undef'));
	}
};

subtest '_could_be_a_location: the shared rule is consulted exactly once per call' => sub {
	# Strategy: replace the rule with a spy that accepts everything.  If the
	# module has its own private copy of the rule, digits are still refused;
	# if it asks the rule more than once, the spy count shows it.
	my $asked = 0;
	my $g = mock_scoped 'Geo::Location::Predicate::_valid_location' => sub { $asked++; return 1 };

	is(Geo::Coder::List::_could_be_a_location('12345'), 1, 'the rule, not a copy, decides');
	is($asked, 1, 'the rule was asked once');
};

# =============================================================================
# geocode() - hostile input
# =============================================================================

subtest 'geocode: HTML-entity-encoded digits cannot bypass the location rule' => sub {
	# Purpose: '&#49;&#50;&#51;' decodes to '123'.  The rule must be applied
	# to the decoded string, which is what would be sent to the backend.
	my $calls = 0;
	my $list  = _make_list(MockGeocoder::Alpha->new());
	my $m     = mock_scoped 'MockGeocoder::Alpha::geocode' => _counting(\$calls, _osm_result($LAT_DC, $LNG_DC));

	for my $encoded ('&#49;&#50;&#51;', '&#x31;&#x32;&#x33;') {
		throws_ok { $list->geocode($encoded) }
			qr/^\Q${MSG_INVALID}123\E/,
			"'$encoded' refused as the digits it decodes to";
	}
	is($calls, 0, 'the backend was never asked');
};

subtest 'geocode: references are refused with the documented message' => sub {
	# Purpose: whichever calling form is used, a reference must not reach a
	# geocoder.  A scalar ref is the one exception: it means its string.
	my $calls = 0;
	my $list  = _make_list(MockGeocoder::Alpha->new());
	my $m     = mock_scoped 'MockGeocoder::Alpha::geocode' => _counting(\$calls, _osm_result($LAT_DC, $LNG_DC));

	for my $ref ([ $LOC_LONDON ], { a => 1 }, sub { 1 }) {
		throws_ok { $list->geocode(location => $ref) }
			qr/^\Q$MSG_INVALID$MSG_NOT_A_LOC\E/,
			ref($ref) . ' ref refused';
	}
	throws_ok { $list->geocode(location => \'12345') }
		qr/^\Q${MSG_INVALID}12345\E/,
		'scalar ref to digits refused as the digits';
	is($calls, 0, 'the backend was never asked');
};

subtest 'geocode: markup and control characters reach the backend inert' => sub {
	# Purpose: the module is not an HTML sink, but it must pass hostile text
	# through unchanged rather than crash or half-decode it
	my $seen;
	my $list = _make_list(MockGeocoder::Alpha->new());
	my $m    = mock_scoped 'MockGeocoder::Alpha::geocode' => sub {
		my (undef, %args) = @_;
		$seen = $args{location};
		return _osm_result($LAT_DC, $LNG_DC);
	};

	my $hostile = "<script>alert(1)</script>\t'; DROP TABLE x; --, Paris";
	lives_ok { $list->geocode($hostile) } 'hostile string does not crash geocode()';
	is($seen, $hostile, 'backend received the string unchanged');
};

subtest 'geocode: every candidate in a wrapped result list is considered' => sub {
	# Purpose: Geo::GeoNames wraps results in arrays.  A usable candidate
	# that is not the first element of its array must not be thrown away,
	# and a wrapped empty hash must be a miss, not a crash.
	my $list = _make_list(MockGeocoder::Alpha->new());
	my $m    = mock_scoped 'MockGeocoder::Alpha::geocode' => sub {
		return [ { name => 'no coordinates' }, _osm_result($LAT_DC, $LNG_DC) ];
	};
	my $r = $list->geocode($LOC_DC);
	is($r->{lat}, $LAT_DC, 'the second element of the array answered');

	my @all = Geo::Coder::List->new()->push(MockGeocoder::Alpha->new())->geocode($LOC_LONDON);
	is(scalar(@all), 2, 'list context: both wrapped candidates returned');

	my $empty = _make_list(MockGeocoder::Beta->new());
	my $e = mock_scoped 'MockGeocoder::Beta::geocode' => sub { return [ {} ] };
	my $miss;
	lives_ok { $miss = $empty->geocode($LOC_DC) } 'a wrapped empty hash does not crash';
	ok(!defined($miss), 'and is not found');
};

subtest 'geocode: a very long location is collapsed and passed once' => sub {
	# Purpose: resource exhaustion - a huge input must be handled in one pass,
	# with whitespace runs collapsed, not rejected or truncated silently
	my ($calls, $seen) = (0, undef);
	my $list = _make_list(MockGeocoder::Alpha->new());
	my $m    = mock_scoped 'MockGeocoder::Alpha::geocode' => sub {
		my (undef, %args) = @_;
		$calls++;
		$seen = $args{location};
		return _osm_result($LAT_DC, $LNG_DC);
	};

	my $long = join('   ', ('Street') x ($hostile{long_location} / length('Street   ')));
	lives_ok { $list->geocode($long) } 'long location does not crash';
	is($calls, 1, 'backend asked exactly once');
	unlike($seen, qr/\s\s/, 'whitespace runs were collapsed before dispatch');
	diag('long location length sent: ', length($seen)) if $ENV{TEST_VERBOSE};
};

subtest 'geocode: an enormous result list is handled without loss' => sub {
	# Purpose: a misbehaving backend returning thousands of rows must not
	# break scalar context (first row) or list context (every row)
	my @rows = map { _osm_result($LAT_DC + $_ / 1e6, $LNG_DC) } 1 .. $hostile{many_results};
	my $list = _make_list(MockGeocoder::Alpha->new());
	my $m    = mock_scoped 'MockGeocoder::Alpha::geocode' => sub { return @rows };

	my $first = $list->geocode($LOC_DC);
	is($first->{lat}, $rows[0]{lat}, 'scalar context: the first row');

	my @all = Geo::Coder::List->new()->push(MockGeocoder::Alpha->new())->geocode($LOC_DC);
	is(scalar(@all), $hostile{many_results}, 'list context: every row');
};

# =============================================================================
# geocode() - backends failing mid-flight
# =============================================================================

subtest 'geocode: a backend dying with an exception object does not stop the chain' => sub {
	# Purpose: exception objects are common (HTTP::Exception, Throwable);
	# they must be logged, not stringified into a crash
	my $list = _carping_list(MockGeocoder::Alpha->new(), MockGeocoder::Beta->new());
	my $ma   = mock_scoped 'MockGeocoder::Alpha::geocode' => sub { die { code => 503 } };
	my $mb   = mock_scoped 'MockGeocoder::Beta::geocode'  => sub { _osm_result($LAT_NY, $LNG_NY) };

	my $r;
	warnings_like { $r = $list->geocode($LOC_DC) } [ qr/MockGeocoder::Alpha/ ],
		'the failure is reported once';
	is(ref($r->{geocoder}), 'MockGeocoder::Beta', 'the next geocoder answered');

	my ($err) = grep { exists $_->{error} } @{$list->log()};
	is(ref($err->{error}), 'HASH', 'the exception object is kept in the log');
	is($err->{error}{code}, 503, 'with its contents intact');
};

subtest 'geocode: a provider-level error key moves on to the next geocoder' => sub {
	# Purpose: { error => ... } is a refusal, not a result, however it looks
	my $list = Geo::Coder::List->new()->push(MockGeocoder::Alpha->new())->push(MockGeocoder::Beta->new());
	my $ma   = mock_scoped 'MockGeocoder::Alpha::geocode' => sub {
		return { error => 'OVER_QUERY_LIMIT', lat => $LAT_DC, lon => $LNG_DC };
	};
	my $mb   = mock_scoped 'MockGeocoder::Beta::geocode' => sub { _osm_result($LAT_NY, $LNG_NY) };

	my $r = $list->geocode($LOC_DC);
	is($r->{lat}, $LAT_NY, 'the erroring geocoder was not believed');
	ok((grep { ($_->{error} // '') eq 'OVER_QUERY_LIMIT' } @{$list->log()}), 'the error was logged');
};

subtest 'geocode: every geocoder failing returns undef and caches the miss' => sub {
	# Purpose: total failure is a clean undef, and a repeat call must not
	# hammer every backend again
	my $calls = 0;
	my $list  = _carping_list(MockGeocoder::Alpha->new());
	my $m     = mock_scoped 'MockGeocoder::Alpha::geocode' => sub { $calls++; die "down\n" };

	my $r;
	warnings_like { $r = $list->geocode($LOC_DC) } [ qr/down/ ], 'failure reported';
	ok(!defined($r), 'undef when nothing answered');

	$r = $list->geocode($LOC_DC);
	ok(!defined($r), 'still undef on repeat');
	is($calls, 1, 'the backend was not asked again');
};

# =============================================================================
# geocode() / reverse_geocode() - caller's globals
# =============================================================================

subtest "geocode: the caller's \$@ survives a failing backend" => sub {
	# Purpose: geocode() runs backends in eval; a caller inspecting $@ after
	# the call must see their own error, not the backend's
	my $list = Geo::Coder::List->new()->push(MockGeocoder::Alpha->new());
	my $m    = mock_scoped 'MockGeocoder::Alpha::geocode' => sub { die "backend broke\n" };

	local $SIG{__WARN__} = sub { };
	$@ = $OUTER_EVAL_ERROR;
	$list->geocode($LOC_DC);
	is($@, $OUTER_EVAL_ERROR, '$@ unchanged after geocode()');
};

subtest "reverse_geocode: the caller's \$@ survives a failing backend" => sub {
	my $list = Geo::Coder::List->new()->push(MockGeocoder::Alpha->new());
	my $m    = mock_scoped 'MockGeocoder::Alpha::reverse_geocode' => sub { die "backend broke\n" };

	local $SIG{__WARN__} = sub { };
	$@ = $OUTER_EVAL_ERROR;
	$list->reverse_geocode(latlng => $LATLNG_DC);
	is($@, $OUTER_EVAL_ERROR, '$@ unchanged after reverse_geocode()');
};

subtest "geocode: the caller's \$_ survives a call" => sub {
	# Purpose: the module uses grep and map internally; $_ must be localised
	my $list = Geo::Coder::List->new()->push(MockGeocoder::Alpha->new());
	my $m    = mock_scoped 'MockGeocoder::Alpha::geocode' => sub { (0, _osm_result($LAT_DC, $LNG_DC)) };

	local $_ = $OUTER_TOPIC;
	my @r = $list->geocode($LOC_DC);
	is($_, $OUTER_TOPIC, '$_ unchanged after list-context geocode()');
};

# =============================================================================
# geocode() - limits and regex routing
# =============================================================================

subtest 'geocode: a location outside the regex does not spend the limit' => sub {
	# Purpose: limit caps the queries a geocoder serves.  A location it is
	# never asked about is not a query and must not use up its allowance.
	my $calls = 0;
	my $entry = { regex => qr/USA$/, geocoder => MockGeocoder::Alpha->new(), limit => $hostile{limit_one} };
	my $list  = Geo::Coder::List->new()->push($entry);
	my $m     = mock_scoped 'MockGeocoder::Alpha::geocode' => _counting(\$calls, _osm_result($LAT_DC, $LNG_DC));

	$list->geocode($LOC_LONDON);
	is($entry->{limit}, $hostile{limit_one}, 'limit untouched by a non-matching location');

	my $r = $list->geocode($LOC_USA);
	ok(defined($r), 'the matching location is still served');
	is($calls, 1, 'and it was the only query');
};

subtest 'geocode: a zero or negative limit is never served' => sub {
	# Purpose: an exhausted or misconfigured limit must block the geocoder
	# outright, not wrap around or count up
	for my $limit ($hostile{limit_zero}, $hostile{limit_neg}) {
		my $calls = 0;
		my $list  = Geo::Coder::List->new()->push({ geocoder => MockGeocoder::Alpha->new(), limit => $limit });
		my $m     = mock_scoped 'MockGeocoder::Alpha::geocode' => _counting(\$calls, _osm_result($LAT_DC, $LNG_DC));

		ok(!defined($list->geocode($LOC_DC)), "limit $limit: no result");
		is($calls, 0, "limit $limit: backend never asked");
	}
};

# =============================================================================
# geocode() with an L2 cache - what the caller is given
# =============================================================================

subtest 'geocode: with an L2 cache the caller still gets the full result' => sub {
	# Purpose: L2 entries are stripped to geometry for storage.  That is the
	# store's business; the caller's result, and L1, must keep every field
	# and the geocoder object.
	my %l2;
	my $g    = MockGeocoder::Alpha->new();
	my $list = Geo::Coder::List->new(cache => \%l2)->push($g);
	my $m    = mock_scoped 'MockGeocoder::Alpha::geocode' => sub {
		return { lat => $LAT_DC, lon => $LNG_DC, display_name => 'The White House' };
	};

	my $r = $list->geocode($LOC_DC);
	is($r->{lat}, $LAT_DC, 'lat alias kept');
	is($r->{lng}, $LNG_DC, 'lng alias kept');
	is($r->{display_name}, 'The White House', 'provider field kept');
	is($r->{geocoder}, $g, 'geocoder object kept');

	is_deeply([ sort keys %{$l2{$LOC_DC}} ], [ 'geometry' ], 'L2 copy holds only geometry');
	is($list->{locations}{$LOC_DC}{display_name}, 'The White House', 'L1 entry not stripped');
	memory_cycle_ok($list, 'no cycles after a cached lookup');
};

subtest 'geocode: an L2 store that dies on get() is a miss, not a failure' => sub {
	# Purpose: the cache is an optimisation.  A store that is down must not
	# take geocoding down with it.
	my $chi  = Hostile::CHI->new(die_on_get => 1);
	my $list = Geo::Coder::List->new(cache => $chi);
	delete $list->{logger};
	$list->push(MockGeocoder::Alpha->new());
	my $m = mock_scoped 'MockGeocoder::Alpha::geocode' => sub { _osm_result($LAT_DC, $LNG_DC) };

	my $r;
	warnings_like { $r = $list->geocode($LOC_DC) } [ qr/cache get failed for '\Q$LOC_DC\E': cache get exploded/ ],
		'the failure is reported';
	is($r->{lat}, $LAT_DC, 'the geocoder answered anyway');
};

subtest 'geocode: an L2 store that dies on set() still returns the result' => sub {
	my $chi  = Hostile::CHI->new(die_on_set => 1);
	my $list = Geo::Coder::List->new(cache => $chi);
	delete $list->{logger};
	$list->push(MockGeocoder::Alpha->new());
	my $m = mock_scoped 'MockGeocoder::Alpha::geocode' => sub { _osm_result($LAT_DC, $LNG_DC) };

	my $r;
	warnings_like { $r = $list->geocode($LOC_DC) } [ qr/cache set failed for '\Q$LOC_DC\E': cache set exploded/ ],
		'the failure is reported';
	is($r->{lat}, $LAT_DC, 'the result found is not lost');
};

subtest 'geocode: a plain string in L2 is not returned as a result' => sub {
	# Purpose: a corrupted store, or a reverse_geocode() address under the
	# same key, must not come back from geocode() as if it were a hashref
	my $calls = 0;
	my $list  = Geo::Coder::List->new(cache => { $LOC_DC => 'not a result' })->push(MockGeocoder::Alpha->new());
	my $m     = mock_scoped 'MockGeocoder::Alpha::geocode' => _counting(\$calls, _osm_result($LAT_DC, $LNG_DC));

	my $r = $list->geocode($LOC_DC);
	is(ref($r), 'HASH', 'a hashref is returned');
	is($r->{lat}, $LAT_DC, 'from the geocoder');
	is($calls, 1, 'which was asked because the cache entry was unusable');
};

# =============================================================================
# new() - cloning
# =============================================================================

subtest 'new: pushing onto a clone leaves the original chain alone' => sub {
	# Purpose: a clone that shares the chain arrayref would make every push
	# onto it a push onto the original
	my $orig  = Geo::Coder::List->new()->push(MockGeocoder::Alpha->new());
	my $clone = $orig->new();
	$clone->push(MockGeocoder::Beta->new());

	is(scalar(@{$orig->{geocoders}}),  1, 'original chain unchanged');
	is(scalar(@{$clone->{geocoders}}), 2, 'clone chain extended');
};

subtest "new: spending a clone's limit leaves the original's alone" => sub {
	# Purpose: hashref entries hold mutable counters; sharing them would let
	# one object exhaust another's allowance
	my $orig = Geo::Coder::List->new()->push({ geocoder => MockGeocoder::Alpha->new(), limit => $hostile{limit_one} });
	my $clone = $orig->new();
	my $m = mock_scoped 'MockGeocoder::Alpha::geocode' => sub { _osm_result($LAT_DC, $LNG_DC) };

	$clone->geocode($LOC_DC);
	is($orig->{geocoders}[0]{limit}, $hostile{limit_one}, "original's limit unspent");
	is($clone->{geocoders}[0]{limit}, $hostile{limit_one} - 1, "clone's limit spent");
};

subtest 'new: a clone starts with an empty log' => sub {
	my $orig = Geo::Coder::List->new()->push(MockGeocoder::Alpha->new());
	my $m = mock_scoped 'MockGeocoder::Alpha::geocode' => sub { _osm_result($LAT_DC, $LNG_DC) };
	$orig->geocode($LOC_DC);

	my $clone = $orig->new();
	is(scalar(@{$clone->log()}), 0, 'clone log empty');
	ok(scalar(@{$orig->log()}) > 0, 'original log kept');
	memory_cycle_ok($clone, 'no cycles in a clone');
};

# =============================================================================
# push()
# =============================================================================

subtest 'push: undef croaks with the exact usage message' => sub {
	my $list = Geo::Coder::List->new();
	throws_ok { $list->push(undef) } qr/^\Q$MSG_PUSH_USAGE\E/, 'push(undef) croaks';
	is(scalar(@{$list->{geocoders}}), 0, 'nothing was added');
};

subtest 'push: a compiled regex survives being pushed' => sub {
	# Purpose: push() deliberately avoids Params::Get, which would stringify
	# qr//; the stored regex must be the very object passed in
	my $re   = qr/USA$/;
	my $list = Geo::Coder::List->new()->push({ regex => $re, geocoder => MockGeocoder::Alpha->new() });
	is(refaddr($list->{geocoders}[0]{regex}), refaddr($re), 'same Regexp object');
};

# =============================================================================
# reverse_geocode() - hostile input
# =============================================================================

subtest 'reverse_geocode: anything but a numeric pair croaks before any backend' => sub {
	# Purpose: a malformed latlng would be split into nonsense coordinates
	# and sent to every backend in the chain
	my $calls = 0;
	my $list  = _make_list(MockGeocoder::Alpha->new());
	my $m     = mock_scoped 'MockGeocoder::Alpha::reverse_geocode' => _counting(\$calls, { display_name => 'X' });

	my @bad = (
		'abc', '51.5', '51.5,', ',-0.1', '1,2,3', '51.5;-0.1', 'NaN,NaN',
		'1e5,2', "51.5,-0.1\n; rm -rf /", '51.5 -0.1', [ 51.5, -0.1 ],
	);
	for my $latlng (@bad) {
		throws_ok { $list->reverse_geocode(latlng => $latlng) }
			qr/^\Q$MSG_RG_USAGE\E/,
			'refused: ' . (ref($latlng) ? 'array ref' : "'$latlng'");
	}
	is($calls, 0, 'the backend was never asked');
};

subtest 'reverse_geocode: non-ASCII digits are not a numeric pair' => sub {
	# Purpose: \d matches Unicode digits unless told not to; a backend reads
	# none of them as numbers, so they must be refused like any other junk
	my $calls = 0;
	my $list  = _make_list(MockGeocoder::Alpha->new());
	my $m     = mock_scoped 'MockGeocoder::Alpha::reverse_geocode' => _counting(\$calls, { display_name => 'X' });

	# U+0665 U+0661 is Arabic-Indic 51; U+FF15 U+FF11 is fullwidth 51
	for my $latlng ("\x{665}\x{661},\x{660}", "\x{FF15}\x{FF11},0") {
		throws_ok { $list->reverse_geocode(latlng => $latlng) }
			qr/^\Q$MSG_RG_USAGE\E/, 'Unicode digits refused';
	}
	is($calls, 0, 'the backend was never asked');
};

subtest 'reverse_geocode: a numeric pair with spaces and signs is accepted' => sub {
	# Purpose: the guard must not be so strict that real input is refused
	my $list = _make_list(MockGeocoder::Alpha->new());
	my $m    = mock_scoped 'MockGeocoder::Alpha::reverse_geocode' => sub { { display_name => 'Here' } };

	is($list->reverse_geocode(latlng => " +$LAT_LONDON , $LNG_LONDON "), 'Here', 'accepted');
};

# =============================================================================
# reverse_geocode() - cache and context
# =============================================================================

subtest 'reverse_geocode: a list-context cache hit returns a list' => sub {
	# Purpose: list context caches an arrayref; handing that arrayref back as
	# the only element of the list is a different answer from the first call
	my $calls = 0;
	my $list  = _make_list(MockGeocoder::Alpha->new());
	my $m     = mock_scoped 'MockGeocoder::Alpha::reverse_geocode' =>
		_counting(\$calls, { display_name => 'One' }, { display_name => 'Two' });

	my @first  = $list->reverse_geocode(latlng => $LATLNG_DC);
	my @second = $list->reverse_geocode(latlng => $LATLNG_DC);
	is_deeply(\@second, \@first, 'cache hit returns the same list');
	is($calls, 1, 'from the cache');

	my $scalar = $list->reverse_geocode(latlng => $LATLNG_DC);
	is($scalar, 'One', 'scalar context after list context: the first address, not an arrayref');
};

subtest 'reverse_geocode: list context moves past a geocoder with no address' => sub {
	# Purpose: an empty answer is not an answer; the next geocoder may have one
	my $list = Geo::Coder::List->new()->push(MockGeocoder::Alpha->new())->push(MockGeocoder::Beta->new());
	my $ma   = mock_scoped 'MockGeocoder::Alpha::reverse_geocode' => sub { return () };
	my $mb   = mock_scoped 'MockGeocoder::Beta::reverse_geocode'  => sub { { display_name => 'From Beta' } };

	my @r = $list->reverse_geocode(latlng => $LATLNG_DC);
	is_deeply(\@r, [ 'From Beta' ], 'the second geocoder answered');
};

subtest 'reverse_geocode: list context with no address anywhere does not cache the miss as a hit' => sub {
	# Purpose: caching an empty arrayref would make the next call return an
	# arrayref from the cache instead of trying again
	my $calls = 0;
	my $list  = _make_list(MockGeocoder::Alpha->new());
	my $m     = mock_scoped 'MockGeocoder::Alpha::reverse_geocode' => _counting(\$calls);

	my @r = $list->reverse_geocode(latlng => $LATLNG_DC);
	is(scalar(@r), 0, 'nothing returned');
	my $s = $list->reverse_geocode(latlng => $LATLNG_DC);
	ok(!defined($s), 'scalar context: undef, not a cached arrayref');
	is($calls, 2, 'the backend was asked again');
};

subtest 'reverse_geocode: list context takes plain-string addresses and skips junk' => sub {
	# Purpose: scalar context already accepts a plain string as the address;
	# list context used to dereference it as a HASH and die
	my $list = _make_list(MockGeocoder::Alpha->new());
	my $m    = mock_scoped 'MockGeocoder::Alpha::reverse_geocode' => sub {
		return ('1 Main St', undef, '', [ 'not an address' ], { display_name => '2 High St' });
	};

	my @r;
	lives_ok { @r = $list->reverse_geocode(latlng => $LATLNG_DC) } 'mixed answers do not die';
	is_deeply(\@r, [ '1 Main St', '2 High St' ], 'strings and display_name kept; undef, empty and array refs skipped');
};

subtest 'reverse_geocode: a backend dying for another reason is not retried' => sub {
	# Purpose: the latlng retry is for one specific complaint; any other
	# error must be reported and the next geocoder tried
	my $alpha = 0;
	my $list  = _carping_list(MockGeocoder::Alpha->new(), MockGeocoder::Beta->new());
	my $ma    = mock_scoped 'MockGeocoder::Alpha::reverse_geocode' => sub { $alpha++; die "quota exceeded\n" };
	my $mb    = mock_scoped 'MockGeocoder::Beta::reverse_geocode'  => sub { { display_name => 'From Beta' } };

	my $r;
	warnings_like { $r = $list->reverse_geocode(latlng => $LATLNG_DC) } [ qr/quota exceeded/ ], 'reported';
	is($r, 'From Beta', 'the next geocoder answered');
	is($alpha, 1, 'the failing geocoder was asked once, not retried');
};

subtest 'reverse_geocode: a zero limit is never served' => sub {
	my $calls = 0;
	my $list  = Geo::Coder::List->new()->push({ geocoder => MockGeocoder::Alpha->new(), limit => $hostile{limit_zero} });
	my $m     = mock_scoped 'MockGeocoder::Alpha::reverse_geocode' => _counting(\$calls, { display_name => 'X' });

	ok(!defined($list->reverse_geocode(latlng => $LATLNG_DC)), 'no address');
	is($calls, 0, 'backend never asked');
};

# =============================================================================
# _cache() - the write path must not corrupt what it is given
# =============================================================================

subtest '_cache: writing a HASH to L2 does not strip the caller\'s copy' => sub {
	# Purpose: the returned value and L1 are the caller's; only the L2 copy
	# is reduced to geometry and has its geocoder turned into a class name
	my %l2;
	my $g   = MockGeocoder::Alpha->new();
	my $obj = Geo::Coder::List->new(cache => \%l2);
	my $val = { geometry => { location => { lat => $LAT_DC, lng => $LNG_DC } }, geocoder => $g, extra => 1 };

	my $rc = $obj->_cache($LOC_DC, $val);
	is($rc, $val, 'the value written is returned');
	is($val->{geocoder}, $g, 'caller keeps the geocoder object');
	is($val->{extra}, 1, 'caller keeps provider fields');
	is_deeply([ sort keys %{$l2{$LOC_DC}} ], [ 'geometry' ], 'L2 copy is stripped');
	isnt(refaddr($l2{$LOC_DC}), refaddr($val), 'L2 holds a copy, not the original');
};

subtest '_cache: writing an ARRAY to L2 leaves every caller item intact' => sub {
	my %l2;
	my $g     = MockGeocoder::Alpha->new();
	my $obj   = Geo::Coder::List->new(cache => \%l2);
	my @items = map { { geometry => { location => { lat => $_, lng => $LNG_DC } }, geocoder => $g, n => $_ } } (1, 2);

	$obj->_cache($LOC_DC, \@items);
	is($items[$_]{geocoder}, $g, "item $_ keeps its geocoder") for (0, 1);
	is($items[$_]{n}, $_ + 1, "item $_ keeps its fields") for (0, 1);
	ok(!exists $l2{$LOC_DC}[0]{n}, 'L2 items are stripped');
};

subtest '_cache: TTL depends on how much of a result there is' => sub {
	# Purpose: found, partial and missing results are cached for different
	# lengths of time, so a transient failure is retried soon and a place
	# that does not exist is not asked about every day
	my %cases = (
		found   => [ { geometry => { location => { lat => $LAT_DC, lng => $LNG_DC } } }, $TTL_HIT,  1 ],
		partial => [ { geometry => { location => {} } },                                  $TTL_PART, 0 ],
		missing => [ { name => 'no geometry at all' },                                     $TTL_MISS, 0 ],
	);
	for my $case (sort keys %cases) {
		my ($val, $ttl, $returned) = @{$cases{$case}};
		my $chi = Hostile::CHI->new();
		my $rc  = Geo::Coder::List->new(cache => $chi)->_cache($case, $val);
		is($chi->{sets}[0]{ttl}, $ttl, "$case: TTL $ttl");
		is(defined($rc) ? 1 : 0, $returned, "$case: " . ($returned ? 'value returned' : 'undef returned'));
	}
};

subtest '_cache: an ARRAY item with no geometry is a miss, not a partial result' => sub {
	my $chi = Hostile::CHI->new();
	Geo::Coder::List->new(cache => $chi)->_cache($LOC_DC, [ { name => 'no geometry' } ]);
	is($chi->{sets}[0]{ttl}, $TTL_MISS, "TTL $TTL_MISS");
};

subtest '_cache: the not-found sentinel never leaves L1 or reaches the caller' => sub {
	# Purpose: the sentinel is an implementation detail; an external store
	# must never see it and a read must report it as undef
	my $chi = Hostile::CHI->new();
	my $obj = Geo::Coder::List->new(cache => $chi);

	ok(!defined($obj->_cache($LOC_DC, undef)), 'write of undef returns undef');
	is(scalar(@{$chi->{sets}}), 0, 'L2 not written');
	ok(!defined($obj->_cache($LOC_DC)), 'read returns undef');
	is($chi->{gets}, 0, 'L1 answered without consulting L2');
};

subtest '_cache: an L2 entry with no latitude reads as a miss' => sub {
	# Purpose: a stale or truncated L2 entry must not be served as a result
	my $obj = Geo::Coder::List->new(cache => { $LOC_DC => { geometry => { location => {} } } });
	ok(!defined($obj->_cache($LOC_DC)), 'undef for a geometry with no lat');
};

# =============================================================================
# _l2_copy() and _has_lat() - internal helpers
# =============================================================================

subtest '_l2_copy: non-HASH values are returned as they are' => sub {
	# Purpose: strings and array-based objects have nothing to strip, and
	# dereferencing them as a HASH would die
	my $aref = [ 1, 2 ];
	my $aobj = bless [ 1 ], 'Array::Based';
	is(Geo::Coder::List::_l2_copy('An address', 0), 'An address', 'string unchanged');
	is(Geo::Coder::List::_l2_copy($aref, 0), $aref, 'array ref unchanged');
	is(Geo::Coder::List::_l2_copy($aobj, 0), $aobj, 'array-based object unchanged');
	ok(!defined(Geo::Coder::List::_l2_copy(undef, 0)), 'undef unchanged');
};

subtest '_l2_copy: a blessed result keeps its class and fields' => sub {
	# Purpose: an object's accessors may need fields other than geometry
	my $g    = MockGeocoder::Alpha->new();
	my $obj  = bless { lat => $LAT_DC, geocoder => $g }, 'Some::Point';
	my $copy = Geo::Coder::List::_l2_copy($obj, 0);
	isa_ok($copy, 'Some::Point');
	is($copy->{lat}, $LAT_DC, 'fields kept');
	is($copy->{geocoder}, 'MockGeocoder::Alpha', 'geocoder stringified in the copy');
	is($obj->{geocoder}, $g, 'original untouched');
};

subtest '_l2_copy: keep_all keeps provider fields' => sub {
	my $copy = Geo::Coder::List::_l2_copy({ geometry => {}, extra => 1, geocoder => 'cache' }, 1);
	is($copy->{extra}, 1, 'extra kept');
	is($copy->{geocoder}, 'cache', 'a geocoder that is already a string is left alone');
};

subtest '_has_lat: malformed structures answer 0 without dying or auto-vivifying' => sub {
	# Purpose: the check runs on data that may be shared with the caller;
	# it must not create keys in it or die on unexpected types
	my %cases = (
		'no geometry'           => {},
		'geometry is a string'  => { geometry => 'nowhere' },
		'geometry is an array'  => { geometry => [] },
		'location is a string'  => { geometry => { location => 'x' } },
		'location has no lat'   => { geometry => { location => {} } },
	);
	for my $name (sort keys %cases) {
		my $before = Dumper($cases{$name});
		my $rc;
		lives_ok { $rc = Geo::Coder::List::_has_lat($cases{$name}) } "$name: lives";
		is($rc, 0, "$name: 0");
		is(Dumper($cases{$name}), $before, "$name: structure unchanged");
	}
	is(Geo::Coder::List::_has_lat({ geometry => { location => { lat => 0 } } }), 1, 'lat 0 is a latitude');
};

# =============================================================================
# _warn(), _error(), _debug() - internal helpers
# =============================================================================

subtest '_warn: with no logger, carps the message' => sub {
	my $obj = Geo::Coder::List->new();
	delete $obj->{logger};
	warning_like { $obj->_warn('something ', 'odd') } qr/^something odd at /, 'carped';
};

subtest '_warn: with a logger, logs and does not carp' => sub {
	my $obj = Geo::Coder::List->new();
	$obj->{logger} = Hostile::Logger->new();
	warnings_are { $obj->_warn('something odd') } [], 'nothing carped';
	is_deeply($obj->{logger}{warn}, [ 'something odd' ], 'logged once');
};

subtest '_error: with no logger, croaks the exact message' => sub {
	my $obj = Geo::Coder::List->new();
	delete $obj->{logger};
	throws_ok { $obj->_error('fatal ', 'thing') } qr/^fatal thing at /, 'croaked';
};

subtest '_error: with a logger, logs and still dies' => sub {
	# Purpose: a logger must not turn a fatal error into a silent one
	my $obj = Geo::Coder::List->new();
	$obj->{logger} = Hostile::Logger->new();
	throws_ok { $obj->_error('fatal thing') } qr/^fatal thing/, 'died';
	is_deeply($obj->{logger}{error}, [ 'fatal thing' ], 'logged once');
};

subtest '_debug: prints only when debug is set, and always logs' => sub {
	my $obj = Geo::Coder::List->new(debug => 0);
	$obj->{logger} = Hostile::Logger->new();
	is(_stdout_of(sub { $obj->_debug('quiet') }), '', 'debug=0: nothing printed');
	is_deeply($obj->{logger}{debug}, [ 'quiet' ], 'debug=0: still logged');

	$obj->{debug} = 1;
	is(_stdout_of(sub { $obj->_debug('loud') }), "loud\n", 'debug=1: printed with a newline');
};

# =============================================================================
# ua(), log(), flush() - hostile state
# =============================================================================

subtest 'ua: a false UA changes nothing' => sub {
	# Purpose: ua(undef) or ua(0) must not wipe the geocoders' agents
	my $g    = MockGeocoder::Alpha->new();
	my $list = _make_list($g);
	$g->{ua} = 'original';
	for my $false (undef, 0, '') {
		ok(!defined($list->ua($false)), 'returns nothing');
	}
	is($g->{ua}, 'original', 'geocoder UA untouched');
};

subtest 'ua: a chain entry with no geocoder croaks with the exact message' => sub {
	my $list = Geo::Coder::List->new();
	push @{$list->{geocoders}}, { regex => qr/x/ };
	throws_ok { $list->ua(bless {}, 'Plain::UA') } qr/^\Q$MSG_NO_GEOCODER\E/, 'croaked';
};

subtest 'log: an object whose log has been removed still returns an arrayref' => sub {
	# Purpose: callers dereference log() unconditionally
	my $obj = Geo::Coder::List->new();
	delete $obj->{log};
	returns_ok($obj->log(), { type => 'arrayref' }, 'arrayref');
	is(scalar(@{$obj->log()}), 0, 'and it is empty');
};

subtest 'flush: repairs a corrupted log' => sub {
	my $obj = Geo::Coder::List->new();
	$obj->{log} = 'not an array';
	$obj->flush();
	is_deeply($obj->log(), [], 'log is an empty arrayref again');
};

done_testing();

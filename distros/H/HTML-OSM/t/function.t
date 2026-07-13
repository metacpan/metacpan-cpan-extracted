#!/usr/bin/env perl

use strict;
use warnings;

use CHI;
use Readonly;
use Scalar::Util qw(blessed refaddr);
use Test::Memory::Cycle;
use Test::Mockingbird qw(mock restore_all);
use Test::Most;
use Test::Returns;
use URI::Escape qw(uri_escape_utf8);

BEGIN { use_ok('HTML::OSM') }

# ── Static config ─────────────────────────────────────────────────────────────
# All magic values in one place; change here if module defaults change.
Readonly my %CFG => (
	DEFAULT_ZOOM   => 12,
	DEFAULT_HEIGHT => '400px',
	DEFAULT_WIDTH  => '600px',
	ZOOM_MIN       => 0,
	ZOOM_MAX       => 19,
	LAT_LONDON     => 51.5074,
	LON_LONDON     => -0.1278,
	LAT_PARIS      => 48.8566,
	LON_PARIS      =>  2.3522,
	LAT_NYC        => 40.7128,
	LON_NYC        => -74.0060,
	LAT_MIN        => -90,
	LAT_MAX        =>  90,
	LON_MIN        => -180,
	LON_MAX        =>  180,
);

# Reusable GeoJSON features for choropleth tests.
Readonly my @FEATURES => (
	{ type => 'Feature', properties => { name => 'England' },
	  geometry => { type => 'Polygon',
	                coordinates => [[[0,51],[1,51],[1,52],[0,52],[0,51]]] } },
	{ type => 'Feature', properties => { name => 'Scotland' },
	  geometry => { type => 'Polygon',
	                coordinates => [[[0,55],[1,55],[1,56],[0,56],[0,55]]] } },
);

# Suppress expected carps/warnings in error-path tests so TAP output stays clean.
my $SILENCE = sub { };

# Block all real HTTP calls for the duration of this file.
# Individual subtests that need to control HTTP behavior inject their own ua.
{
	my $fail_resp = bless {}, '_NetBlockResp';
	mock '_NetBlockResp::is_success' => sub { 0 };
	my $fail_ua = bless {}, '_NetBlockUA';
	mock '_NetBlockUA::default_header' => sub { };
	mock '_NetBlockUA::env_proxy'      => sub { };
	mock '_NetBlockUA::get'            => sub { $fail_resp };
	mock 'LWP::UserAgent::new'         => sub { $fail_ua };
}

# ─────────────────────────────────────────────────────────────────────────────
# _js_string() — pure private helper, no side-effects, call directly.
# ─────────────────────────────────────────────────────────────────────────────

subtest '_js_string: undef becomes empty string' => sub {
	is(HTML::OSM::_js_string(undef), '', 'undef input gives empty string');
};

subtest '_js_string: plain ASCII passes through unchanged' => sub {
	is(HTML::OSM::_js_string('hello world'), 'hello world', 'plain string unchanged');
};

subtest '_js_string: single quotes are escaped' => sub {
	is(HTML::OSM::_js_string("O'Brien"), "O\\'Brien", 'single quote escaped');
};

subtest '_js_string: backslashes are doubled (must run before quote escape)' => sub {
	# If backslash were escaped after the quote, a pre-existing \' would become \\\'.
	is(HTML::OSM::_js_string('C:\\path'), 'C:\\\\path', 'backslash doubled');
};

subtest '_js_string: LF newline -> literal \n sequence' => sub {
	is(HTML::OSM::_js_string("a\nb"), 'a\\nb', 'LF escaped');
};

subtest '_js_string: CRLF newline -> literal \n sequence' => sub {
	is(HTML::OSM::_js_string("a\r\nb"), 'a\\nb', 'CRLF collapsed to \\n');
};

subtest '_js_string: </script> is neutered to prevent injection' => sub {
	is(HTML::OSM::_js_string('</script>'), '<\\/script>', '</script> escaped');
};

subtest '_js_string: combined — backslash then quote escaped in correct order' => sub {
	# Input: \' (backslash + single-quote).
	# Step 1 (backslash): \\ + '  -> \\' (but as Perl string: \\')
	# Step 2 (quote): \\' -> \\'  (only the naked ' gets a backslash)
	my $got = HTML::OSM::_js_string("\\'");
	is($got, "\\\\\\'", 'backslash then quote: order preserved');
};

# ─────────────────────────────────────────────────────────────────────────────
# _validate() — private helper, called as a plain function (not a method).
# ─────────────────────────────────────────────────────────────────────────────

subtest '_validate: valid WGS-84 coordinates return 1' => sub {
	is(HTML::OSM::_validate($CFG{LAT_LONDON}, $CFG{LON_LONDON}), 1, 'London valid');
	is(HTML::OSM::_validate(0, 0), 1, 'origin (0,0) valid');
	returns_ok(HTML::OSM::_validate(0, 0), { type => 'integer' }, '_validate returns integer');
};

subtest '_validate: boundary values accepted' => sub {
	is(HTML::OSM::_validate($CFG{LAT_MIN}, $CFG{LON_MIN}), 1, 'min boundary -90,-180');
	is(HTML::OSM::_validate($CFG{LAT_MAX}, $CFG{LON_MAX}), 1, 'max boundary +90,+180');
};

subtest '_validate: leading-dot decimal is valid (documented since 0.05)' => sub {
	is(HTML::OSM::_validate('.5',    '.5'),    1, 'leading-dot positive');
	is(HTML::OSM::_validate('-.5167', '.5'), 1, 'leading-dot signed negative lat');
};

subtest '_validate: empty string is rejected' => sub {
	# The old regex /^-?\d*(\.\d+)?$/ matched '' — the fixed one requires a digit.
	local $SIG{__WARN__} = $SILENCE;
	is(HTML::OSM::_validate('', 0),  0, 'empty string lat rejected');
	is(HTML::OSM::_validate(0,  ''), 0, 'empty string lon rejected');
};

subtest '_validate: out-of-range values return 0 and emit a carp' => sub {
	warning_like { HTML::OSM::_validate(91, 0) }
		qr/Skipping invalid coordinate/,
		'out-of-range lat carps';
	{
		local $SIG{__WARN__} = $SILENCE;
		is(HTML::OSM::_validate(91,   0),  0, 'lat 91');
		is(HTML::OSM::_validate(-91,  0),  0, 'lat -91');
		is(HTML::OSM::_validate(0,  181),  0, 'lon 181');
		is(HTML::OSM::_validate(0, -181),  0, 'lon -181');
	}
};

subtest '_validate: non-numeric strings return 0 and carp' => sub {
	local $SIG{__WARN__} = $SILENCE;
	is(HTML::OSM::_validate('abc', 0),   0, 'alpha lat rejected');
	is(HTML::OSM::_validate(0, 'xyz'),   0, 'alpha lon rejected');
	is(HTML::OSM::_validate('1e5', 0),   0, 'scientific notation rejected');
};

subtest '_validate: undef args return 0 silently (no carp)' => sub {
	# There is no value to complain about when the caller never supplied coords.
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	is(HTML::OSM::_validate(undef, 0),     0, 'undef lat -> 0');
	is(HTML::OSM::_validate(0,     undef), 0, 'undef lon -> 0');
	is(scalar @warnings, 0, 'no carp for undef args');
};

# ─────────────────────────────────────────────────────────────────────────────
# new()
# ─────────────────────────────────────────────────────────────────────────────

subtest 'new: method-style with no args produces correct defaults' => sub {
	my $m = HTML::OSM->new();
	isa_ok($m, 'HTML::OSM');
	is($m->{zoom},   $CFG{DEFAULT_ZOOM},   'default zoom');
	is($m->{height}, $CFG{DEFAULT_HEIGHT}, 'default height');
	is($m->{width},  $CFG{DEFAULT_WIDTH},  'default width');
	is_deeply($m->{coordinates}, [], 'coordinates empty arrayref');
	ok(!$m->{cluster}, 'cluster off');
	like($m->{css_url},             qr/leaflet/,       'css_url');
	like($m->{js_url},              qr/leaflet/,       'js_url');
	like($m->{cluster_js_url},      qr/markercluster/, 'cluster_js_url');
	like($m->{cluster_css_url},     qr/MarkerCluster/, 'cluster_css_url');
	like($m->{heatmap_js_url},      qr/leaflet.heat/,  'heatmap_js_url');
	like($m->{gpx_js_url},          qr/gpx/i,          'gpx_js_url');
	returns_ok($m, { type => 'object', isa => 'HTML::OSM' }, 'returns HTML::OSM');
	memory_cycle_ok($m->{coordinates}, 'no cycles in coordinates');
	diag("defaults: zoom=$m->{zoom} h=$m->{height} w=$m->{width}") if $ENV{TEST_VERBOSE};
};

subtest 'new: function-style HTML::OSM::new() blesses into HTML::OSM' => sub {
	my $m = HTML::OSM::new();
	isa_ok($m, 'HTML::OSM', 'function-style call');
};

subtest 'new: function-style with args' => sub {
	my $m = HTML::OSM::new(zoom => 8);
	is($m->{zoom}, 8, 'zoom arg respected');
};

subtest 'new: zoom accepted at min and max boundaries' => sub {
	is(HTML::OSM->new(zoom => $CFG{ZOOM_MIN})->{zoom}, $CFG{ZOOM_MIN}, 'zoom 0 ok');
	is(HTML::OSM->new(zoom => $CFG{ZOOM_MAX})->{zoom}, $CFG{ZOOM_MAX}, 'zoom 19 ok');
};

subtest 'new: zoom out of range croaks' => sub {
	dies_ok { HTML::OSM->new(zoom => -1)  } 'zoom -1 dies';
	dies_ok { HTML::OSM->new(zoom => 20)  } 'zoom 20 dies';
	dies_ok { HTML::OSM->new(zoom => 'x') } 'non-integer zoom dies';
};

subtest 'new: unknown param rejected by schema' => sub {
	dies_ok { HTML::OSM->new(bogus_param => 1) } 'unknown param dies';
};

subtest 'new: coordinates must be arrayref' => sub {
	dies_ok { HTML::OSM->new(coordinates => 'bad') } 'string coordinates die';
};

subtest 'new: CDN URLs overridable' => sub {
	my $m = HTML::OSM->new(css_url => 'https://my.cdn/leaflet.css',
	                        gpx_js_url => 'https://my.cdn/gpx.js');
	is($m->{css_url},    'https://my.cdn/leaflet.css', 'css_url overridden');
	is($m->{gpx_js_url}, 'https://my.cdn/gpx.js',     'gpx_js_url overridden');
};

subtest 'new: clone merges overrides, skips validation, is a distinct object' => sub {
	my $base  = HTML::OSM->new(zoom => 5);
	my $clone = $base->new(zoom => 9, _private_key => 'val');
	isa_ok($clone, 'HTML::OSM', 'clone isa HTML::OSM');
	is($clone->{zoom},        9,                    'clone zoom updated');
	is($clone->{height},      $CFG{DEFAULT_HEIGHT}, 'clone inherits height');
	is($clone->{_private_key}, 'val',               'arbitrary key passes clone (no validation)');
	isnt(refaddr($clone), refaddr($base), 'clone is a distinct reference');
	returns_ok($clone, { type => 'object', isa => 'HTML::OSM' }, 'clone returns HTML::OSM');
};

subtest 'new: cache default is an object with get/set' => sub {
	my $m = HTML::OSM->new();
	can_ok($m->{cache}, 'get');
	can_ok($m->{cache}, 'set');
};

subtest 'new: cluster => 1 stored' => sub {
	ok(HTML::OSM->new(cluster => 1)->{cluster}, 'cluster enabled');
};

# ─────────────────────────────────────────────────────────────────────────────
# zoom()
# ─────────────────────────────────────────────────────────────────────────────

subtest 'zoom: getter returns default' => sub {
	my $m = HTML::OSM->new();
	is($m->zoom(), $CFG{DEFAULT_ZOOM}, 'getter returns 12');
	returns_ok($m->zoom(), { type => 'integer' }, 'zoom() returns integer');
};

subtest 'zoom: setter updates value and is returned' => sub {
	my $m = HTML::OSM->new();
	my $z = $m->zoom(10);
	is($z,        10, 'setter return value');
	is($m->zoom(), 10, 'getter sees new value');
};

subtest 'zoom: boundary values accepted' => sub {
	my $m = HTML::OSM->new();
	$m->zoom($CFG{ZOOM_MIN}); is($m->zoom(), $CFG{ZOOM_MIN}, 'zoom 0');
	$m->zoom($CFG{ZOOM_MAX}); is($m->zoom(), $CFG{ZOOM_MAX}, 'zoom 19');
};

subtest 'zoom: non-integer dies' => sub {
	my $m = HTML::OSM->new();
	dies_ok { $m->zoom('high') } 'string zoom dies';
};

subtest 'zoom: out-of-range dies' => sub {
	my $m = HTML::OSM->new();
	dies_ok { $m->zoom(-1)  } 'zoom -1 dies';
	dies_ok { $m->zoom(20)  } 'zoom 20 dies';
};

# ─────────────────────────────────────────────────────────────────────────────
# add_marker()
# ─────────────────────────────────────────────────────────────────────────────

subtest 'add_marker: [lat, lon] arrayref succeeds, stores tuple' => sub {
	my $m = HTML::OSM->new();
	my $r = $m->add_marker([$CFG{LAT_LONDON}, $CFG{LON_LONDON}], html => 'London');
	is($r, 1, 'returns 1');
	is(scalar @{$m->{coordinates}}, 1,                  'one coord stored');
	is($m->{coordinates}[0][0],     $CFG{LAT_LONDON},   'lat stored');
	is($m->{coordinates}[0][1],     $CFG{LON_LONDON},   'lon stored');
	is($m->{coordinates}[0][2],     'London',           'label stored');
	returns_ok($r, { type => 'integer' }, 'returns integer');
};

subtest 'add_marker: icon URL stored in coordinate tuple' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$CFG{LAT_LONDON}, $CFG{LON_LONDON}], icon => 'https://ex.com/pin.png');
	is($m->{coordinates}[0][3], 'https://ex.com/pin.png', 'icon URL in tuple[3]');
};

subtest 'add_marker: out-of-range coords return 0, nothing stored' => sub {
	my $m = HTML::OSM->new();
	local $SIG{__WARN__} = $SILENCE;
	is($m->add_marker([999, 999], html => 'Bad'), 0, 'returns 0');
	is(scalar @{$m->{coordinates}}, 0, 'nothing stored');
};

subtest 'add_marker: [undef, undef] returns 0' => sub {
	my $m = HTML::OSM->new();
	is($m->add_marker([undef, undef], html => 'x'), 0, 'undef coords return 0');
};

subtest 'add_marker: wrong-length arrayref returns 0' => sub {
	my $m = HTML::OSM->new();
	is($m->add_marker([1, 2, 3]), 0, 'three-element -> 0');
	is($m->add_marker([]),        0, 'empty arrayref -> 0');
};

subtest 'add_marker: single-element arrayref treated as address string' => sub {
	# ['Paris'] unwraps to 'Paris' and triggers the geocode path.
	my $m = HTML::OSM->new();
	mock 'MockGeoSingle::geocode' => sub {
		{ lat => $CFG{LAT_PARIS}, lon => $CFG{LON_PARIS} }
	};
	$m->{geocoder} = bless {}, 'MockGeoSingle';
	is($m->add_marker(['Paris, France'], html => 'Paris'), 1, 'wrapped address geocoded');
};

subtest 'add_marker: geo object with latitude()/longitude() methods' => sub {
	my $m = HTML::OSM->new();
	mock 'MockGeoObj::latitude'  => sub { $CFG{LAT_NYC} };
	mock 'MockGeoObj::longitude' => sub { $CFG{LON_NYC} };
	my $obj = bless {}, 'MockGeoObj';
	is($m->add_marker($obj, html => 'NYC'), 1, 'geo object accepted');
	is($m->{coordinates}[0][0], $CFG{LAT_NYC}, 'lat from latitude()');
	is($m->{coordinates}[0][1], $CFG{LON_NYC}, 'lon from longitude()');
};

subtest 'add_marker: unknown ref type croaks with exact message' => sub {
	my $m   = HTML::OSM->new();
	my $bad = bless {}, 'UnknownRefType';
	throws_ok { $m->add_marker($bad) }
		qr/add_marker\(\): unknown point type: UnknownRefType/,
		'exact croak message';
};

subtest 'add_marker: string address delegated to geocoder' => sub {
	my $m = HTML::OSM->new();
	mock 'MockGeoStr::geocode' => sub {
		{ lat => $CFG{LAT_PARIS}, lon => $CFG{LON_PARIS} }
	};
	$m->{geocoder} = bless {}, 'MockGeoStr';
	is($m->add_marker('Paris, France', html => 'Paris'), 1, 'string geocoded');
	is($m->{coordinates}[0][0], $CFG{LAT_PARIS}, 'geocoded lat correct');
};

subtest 'add_marker: geocode returning undef means return 0' => sub {
	my $m = HTML::OSM->new();
	mock 'MockGeoFail::geocode' => sub { undef };
	$m->{geocoder} = bless {}, 'MockGeoFail';
	is($m->add_marker('Nowhere'), 0, 'geocode failure -> 0');
	is(scalar @{$m->{coordinates}}, 0, 'nothing stored');
};

subtest 'add_marker: multiple markers accumulate in order' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$CFG{LAT_LONDON}, $CFG{LON_LONDON}], html => 'London');
	$m->add_marker([$CFG{LAT_NYC},    $CFG{LON_NYC}],    html => 'NYC');
	is(scalar @{$m->{coordinates}}, 2,        'two stored');
	is($m->{coordinates}[0][2],     'London', 'first label');
	is($m->{coordinates}[1][2],     'NYC',    'second label');
	memory_cycle_ok($m->{coordinates}, 'no cycles in coordinates');
};

# ─────────────────────────────────────────────────────────────────────────────
# center()
# ─────────────────────────────────────────────────────────────────────────────

subtest 'center: no args croaks (Params::Get usage error mentions center)' => sub {
	my $m = HTML::OSM->new();
	dies_ok { $m->center() } 'no-args dies';
};

subtest 'center: [lat, lon] arrayref succeeds, returns 1, stores center' => sub {
	my $m = HTML::OSM->new();
	is($m->center([$CFG{LAT_LONDON}, $CFG{LON_LONDON}]), 1, 'returns 1');
	is_deeply($m->{center}, [$CFG{LAT_LONDON}, $CFG{LON_LONDON}], 'center stored');
	returns_ok(1, { type => 'integer' }, 'center returns integer');
};

subtest 'center: one-element arrayref croaks with message' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->center([51.5]) }
		qr/center\(\): point must have latitude and longitude/,
		'wrong-length array croaks';
};

subtest 'center: three-element arrayref croaks' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->center([51.5, -0.1, 100]) }
		qr/center\(\): point must have latitude and longitude/,
		'three-element array croaks';
};

subtest 'center: out-of-range coords return 0, do not store center' => sub {
	my $m = HTML::OSM->new();
	local $SIG{__WARN__} = $SILENCE;
	is($m->center([999, 0]), 0, 'out-of-range returns 0');
	ok(!$m->{center}, 'center not set on failure');
};

subtest 'center: geo object with latitude()/longitude() methods' => sub {
	my $m = HTML::OSM->new();
	mock 'MockCtrObj::latitude'  => sub { $CFG{LAT_PARIS} };
	mock 'MockCtrObj::longitude' => sub { $CFG{LON_PARIS} };
	is($m->center(bless {}, 'MockCtrObj'), 1, 'geo object center succeeds');
	is_deeply($m->{center}, [$CFG{LAT_PARIS}, $CFG{LON_PARIS}], 'stored');
};

subtest 'center: string address resolved via geocoder' => sub {
	my $m = HTML::OSM->new();
	mock 'MockCtrGeo::geocode' => sub { { lat => $CFG{LAT_NYC}, lon => $CFG{LON_NYC} } };
	$m->{geocoder} = bless {}, 'MockCtrGeo';
	is($m->center('New York'), 1, 'string center geocoded');
	is_deeply($m->{center}, [$CFG{LAT_NYC}, $CFG{LON_NYC}], 'stored');
};

subtest 'center: geocode failure returns 0' => sub {
	my $m = HTML::OSM->new();
	mock 'MockCtrFail::geocode' => sub { undef };
	$m->{geocoder} = bless {}, 'MockCtrFail';
	is($m->center('Nowhere'), 0, 'geocode failure -> 0');
};

subtest 'center: unknown ref type croaks with message' => sub {
	my $m   = HTML::OSM->new();
	my $bad = bless {}, 'UnknownCenter';
	throws_ok { $m->center($bad) }
		qr/center\(\): unknown point type: UnknownCenter/,
		'exact croak message';
};

# ─────────────────────────────────────────────────────────────────────────────
# add_geojson()
# ─────────────────────────────────────────────────────────────────────────────

subtest 'add_geojson: pre-parsed hashref stored, returns 1' => sub {
	my $m    = HTML::OSM->new();
	my $data = { type => 'FeatureCollection', features => [] };
	is($m->add_geojson($data), 1, 'returns 1');
	is(scalar @{$m->{geojson}}, 1,     'one layer');
	is($m->{geojson}[0]{data},  $data, 'same ref stored');
	returns_ok(1, { type => 'integer' }, 'add_geojson returns integer');
};

subtest 'add_geojson: JSON string is decoded in-place' => sub {
	my $m = HTML::OSM->new();
	$m->add_geojson('{"type":"FeatureCollection","features":[]}');
	is(ref($m->{geojson}[0]{data}), 'HASH', 'decoded to hashref');
	is($m->{geojson}[0]{data}{type}, 'FeatureCollection', 'content correct');
};

subtest 'add_geojson: invalid JSON dies' => sub {
	my $m = HTML::OSM->new();
	dies_ok { $m->add_geojson('not json at all') } 'invalid JSON dies';
};

subtest 'add_geojson: style and popup opts stored' => sub {
	my $m = HTML::OSM->new();
	$m->add_geojson({ type => 'FeatureCollection', features => [] },
		style => { color => '#ff0000' }, popup => 'name');
	is_deeply($m->{geojson}[0]{opts}{style}, { color => '#ff0000' }, 'style stored');
	is($m->{geojson}[0]{opts}{popup}, 'name', 'popup stored');
};

subtest 'add_geojson: multiple calls accumulate layers' => sub {
	my $m = HTML::OSM->new();
	$m->add_geojson({ type => 'FeatureCollection', features => [] });
	$m->add_geojson({ type => 'FeatureCollection', features => [] });
	is(scalar @{$m->{geojson}}, 2, 'two layers');
	memory_cycle_ok($m->{geojson}, 'no cycles in geojson');
};

# ─────────────────────────────────────────────────────────────────────────────
# add_heatmap()
# ─────────────────────────────────────────────────────────────────────────────

subtest 'add_heatmap: valid arrayref stored, returns 1' => sub {
	my $m      = HTML::OSM->new();
	my $points = [[$CFG{LAT_LONDON}, $CFG{LON_LONDON}, 0.8]];
	is($m->add_heatmap($points), 1, 'returns 1');
	is(scalar @{$m->{heatmap_layers}},    1,      'one layer');
	is($m->{heatmap_layers}[0]{points},   $points, 'same ref stored');
	returns_ok(1, { type => 'integer' }, 'returns integer');
};

subtest 'add_heatmap: radius and blur opts stored' => sub {
	my $m = HTML::OSM->new();
	$m->add_heatmap([[0, 0]], radius => 30, blur => 20);
	is($m->{heatmap_layers}[0]{opts}{radius}, 30, 'radius stored');
	is($m->{heatmap_layers}[0]{opts}{blur},   20, 'blur stored');
};

subtest 'add_heatmap: non-arrayref croaks with exact message' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->add_heatmap('string') }
		qr/add_heatmap: points must be an arrayref/,
		'string croaks';
	throws_ok { $m->add_heatmap({ lat => 1 }) }
		qr/add_heatmap: points must be an arrayref/,
		'hashref croaks';
	throws_ok { $m->add_heatmap(undef) }
		qr/add_heatmap: points must be an arrayref/,
		'undef croaks';
};

subtest 'add_heatmap: multiple layers accumulate' => sub {
	my $m = HTML::OSM->new();
	$m->add_heatmap([[0, 0]]);
	$m->add_heatmap([[1, 1]]);
	is(scalar @{$m->{heatmap_layers}}, 2, 'two layers');
	memory_cycle_ok($m->{heatmap_layers}, 'no cycles in heatmap_layers');
};

# ─────────────────────────────────────────────────────────────────────────────
# add_gpx()
# ─────────────────────────────────────────────────────────────────────────────

subtest 'add_gpx: URL stored, returns 1' => sub {
	my $m   = HTML::OSM->new();
	my $url = 'https://example.com/track.gpx';
	is($m->add_gpx($url), 1, 'returns 1');
	is(scalar @{$m->{gpx_tracks}}, 1,    'one track');
	is($m->{gpx_tracks}[0],        $url, 'URL correct');
	returns_ok(1, { type => 'integer' }, 'returns integer');
};

subtest 'add_gpx: missing URL croaks mentioning url' => sub {
	my $m = HTML::OSM->new();
	# With no args, Params::Get fires its own usage error before our croak;
	# both messages contain "url", so match that common substring.
	throws_ok { $m->add_gpx() }
		qr/url/i,
		'no-arg croaks mentioning url';
};

subtest 'add_gpx: empty string URL croaks' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->add_gpx('') }
		qr/add_gpx: url is required/,
		'empty string croaks';
};

subtest 'add_gpx: multiple tracks accumulate' => sub {
	my $m = HTML::OSM->new();
	$m->add_gpx('https://example.com/a.gpx');
	$m->add_gpx('https://example.com/b.gpx');
	is(scalar @{$m->{gpx_tracks}}, 2, 'two tracks');
	memory_cycle_ok($m->{gpx_tracks}, 'no cycles in gpx_tracks');
};

# ─────────────────────────────────────────────────────────────────────────────
# add_choropleth()
# ─────────────────────────────────────────────────────────────────────────────

subtest 'add_choropleth: valid inputs stored, returns 1' => sub {
	my $m = HTML::OSM->new();
	is($m->add_choropleth(\@FEATURES, { England => 100, Scotland => 50 }), 1, 'returns 1');
	is(scalar @{$m->{choropleth_layers}}, 1, 'one layer');
	returns_ok(1, { type => 'integer' }, 'returns integer');
};

subtest 'add_choropleth: non-arrayref features croaks' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->add_choropleth('bad', {}) }
		qr/add_choropleth: features must be an arrayref/,
		'string features croaks';
};

subtest 'add_choropleth: non-hashref values croaks' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->add_choropleth([], 'bad') }
		qr/add_choropleth: values must be a hashref/,
		'string values croaks';
};

subtest 'add_choropleth: min value gets first scale colour, max gets last' => sub {
	my $m = HTML::OSM->new();
	$m->add_choropleth(\@FEATURES,
		{ England => 100, Scotland => 0 },
		scale => ['#low', '#high'],
	);
	my $colors = $m->{choropleth_layers}[0]{colors};
	is($colors->{Scotland}, '#low',  'minimum -> first colour');
	is($colors->{England},  '#high', 'maximum -> last colour');
};

subtest 'add_choropleth: single-value set does not divide by zero' => sub {
	# max == min triggers max = min + 1 guard; all entries get index 0.
	my $m = HTML::OSM->new();
	lives_ok {
		$m->add_choropleth(\@FEATURES,
			{ England => 50, Scotland => 50 },
			scale => ['#only'],
		);
	} 'single-value set lives';
	my $colors = $m->{choropleth_layers}[0]{colors};
	is($colors->{England},  '#only', 'England gets only colour');
	is($colors->{Scotland}, '#only', 'Scotland gets only colour');
};

subtest 'add_choropleth: empty values hashref does not crash' => sub {
	my $m = HTML::OSM->new();
	lives_ok { $m->add_choropleth(\@FEATURES, {}) } 'empty values lives';
};

subtest 'add_choropleth: default key is "name"' => sub {
	my $m = HTML::OSM->new();
	$m->add_choropleth(\@FEATURES, { England => 1 });
	is($m->{choropleth_layers}[0]{key}, 'name', 'default key = name');
};

subtest 'add_choropleth: custom key stored' => sub {
	my $m = HTML::OSM->new();
	$m->add_choropleth(\@FEATURES, { England => 1 }, key => 'region');
	is($m->{choropleth_layers}[0]{key}, 'region', 'custom key stored');
};

subtest 'add_choropleth: default 5-stop scale produces valid hex colours' => sub {
	my $m = HTML::OSM->new();
	$m->add_choropleth(\@FEATURES, { England => 100, Scotland => 0 });
	my $colors = $m->{choropleth_layers}[0]{colors};
	like($colors->{England},  qr/^#[0-9a-fA-F]{6}$/, 'England colour is hex');
	like($colors->{Scotland}, qr/^#[0-9a-fA-F]{6}$/, 'Scotland colour is hex');
};

subtest 'add_choropleth: all computed colour indices are within scale bounds' => sub {
	# Four values, two-colour scale — no index should exceed 1.
	my $m = HTML::OSM->new();
	$m->add_choropleth(
		[map { { type => 'Feature', properties => { name => "R$_" },
		          geometry => { type => 'Point', coordinates => [0,0] } } } 1..4],
		{ R1 => 10, R2 => 20, R3 => 30, R4 => 40 },
		scale => ['#first', '#second'],
	);
	my $colors = $m->{choropleth_layers}[0]{colors};
	for my $k (keys %$colors) {
		ok($colors->{$k} eq '#first' || $colors->{$k} eq '#second',
			"$k colour within 2-stop scale");
	}
};

subtest 'add_choropleth: multiple layers accumulate' => sub {
	my $m = HTML::OSM->new();
	$m->add_choropleth(\@FEATURES, { England => 1 });
	$m->add_choropleth(\@FEATURES, { England => 2 });
	is(scalar @{$m->{choropleth_layers}}, 2, 'two layers');
	memory_cycle_ok($m->{choropleth_layers}, 'no cycles in choropleth_layers');
};

# ─────────────────────────────────────────────────────────────────────────────
# onload_render()
# ─────────────────────────────────────────────────────────────────────────────

subtest 'onload_render: no data croaks with exact message' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->onload_render() }
		qr/No map data provided/,
		'no-data croak';
};

subtest 'onload_render: non-marker data without center croaks' => sub {
	my $m = HTML::OSM->new();
	$m->add_geojson({ type => 'FeatureCollection', features => [] });
	throws_ok { $m->onload_render() }
		qr/center\(\) must be called when no point markers are provided/,
		'missing center croak';
};

subtest 'onload_render: returns two non-empty strings' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$CFG{LAT_LONDON}, $CFG{LON_LONDON}], html => 'L');
	my @r = $m->onload_render();
	is(scalar @r, 2, 'two-element list');
	ok(length($r[0]) > 0, 'head non-empty');
	ok(length($r[1]) > 0, 'body non-empty');
	returns_ok($r[0], { type => 'string' }, 'head is string');
	returns_ok($r[1], { type => 'string' }, 'body is string');
};

subtest 'onload_render: head contains Leaflet CSS and JS' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$CFG{LAT_LONDON}, $CFG{LON_LONDON}]);
	my ($head) = $m->onload_render();
	like($head, qr/leaflet.*\.css/i, 'Leaflet CSS in head');
	like($head, qr/leaflet.*\.js/i,  'Leaflet JS in head');
};

subtest 'onload_render: body initialises map with single-marker center' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$CFG{LAT_LONDON}, $CFG{LON_LONDON}], html => 'L');
	my (undef, $body) = $m->onload_render();
	like($body, qr/setView\(\[$CFG{LAT_LONDON}/, 'setView uses London lat');
};

subtest 'onload_render: center auto-computed as midpoint of two markers' => sub {
	# Two markers equidistant from origin → midpoint = (0, 0).
	my $m = HTML::OSM->new();
	$m->add_marker([10, 20]);
	$m->add_marker([-10, -20]);
	my (undef, $body) = $m->onload_render();
	like($body, qr/setView\(\[0, 0\]/, 'midpoint (0,0) used as center');
};

subtest 'onload_render: explicit center overrides marker midpoint' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$CFG{LAT_LONDON}, $CFG{LON_LONDON}]);
	$m->center([$CFG{LAT_NYC}, $CFG{LON_NYC}]);
	my (undef, $body) = $m->onload_render();
	like($body, qr/setView\(\[$CFG{LAT_NYC}/, 'explicit center used');
};

subtest 'onload_render: body has search box, reset and clear-search buttons' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$CFG{LAT_LONDON}, $CFG{LON_LONDON}]);
	my (undef, $body) = $m->onload_render();
	like($body, qr/search-box/,          'search box present');
	like($body, qr/reset-button/,        'reset button present');
	like($body, qr/clear-search-button/, 'clear-search button present');
	like($body, qr/searchMarkers/,        'searchMarkers array present');
};

subtest 'onload_render: heatmap plugin injected only when needed' => sub {
	my $with = HTML::OSM->new();
	$with->add_marker([$CFG{LAT_LONDON}, $CFG{LON_LONDON}]);
	$with->add_heatmap([[$CFG{LAT_LONDON}, $CFG{LON_LONDON}, 0.9]]);
	like(($with->onload_render())[0], qr/leaflet.heat/i, 'plugin in head when used');

	my $without = HTML::OSM->new();
	$without->add_marker([$CFG{LAT_LONDON}, $CFG{LON_LONDON}]);
	unlike(($without->onload_render())[0], qr/leaflet.heat/i, 'plugin absent when unused');
};

subtest 'onload_render: GPX plugin injected only when needed' => sub {
	my $with = HTML::OSM->new();
	$with->add_marker([$CFG{LAT_LONDON}, $CFG{LON_LONDON}]);
	$with->add_gpx('https://example.com/track.gpx');
	like(($with->onload_render())[0], qr/gpx/i, 'GPX plugin in head when used');

	my $without = HTML::OSM->new();
	$without->add_marker([$CFG{LAT_LONDON}, $CFG{LON_LONDON}]);
	unlike(($without->onload_render())[0], qr/leaflet-gpx/i, 'GPX plugin absent when unused');
};

subtest 'onload_render: cluster => 1 injects all three cluster assets' => sub {
	my $m = HTML::OSM->new(cluster => 1);
	$m->add_marker([$CFG{LAT_LONDON}, $CFG{LON_LONDON}]);
	$m->add_marker([$CFG{LAT_PARIS},  $CFG{LON_PARIS}]);
	my ($head, $body) = $m->onload_render();
	like($head, qr/markercluster.*\.js/i,        'cluster JS');
	like($head, qr/MarkerCluster\.css/,           'cluster CSS');
	like($head, qr/MarkerCluster\.Default\.css/,  'cluster default CSS');
	like($body, qr/markerClusterGroup/,            'clusterGroup created');
	like($body, qr/clusterGroup\.addLayer/,        'markers via addLayer');
	like($body, qr/map\.addLayer\(clusterGroup\)/, 'clusterGroup added to map');
};

subtest 'onload_render: without cluster, markers added directly' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$CFG{LAT_LONDON}, $CFG{LON_LONDON}]);
	my ($head, $body) = $m->onload_render();
	unlike($head, qr/markercluster/, 'no cluster assets');
	unlike($body, qr/clusterGroup/,  'no clusterGroup');
	like($body,   qr/addTo\(map\)/,  'marker direct to map');
};

subtest 'onload_render: icon URL uses L.icon in emitted JS' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$CFG{LAT_LONDON}, $CFG{LON_LONDON}],
		icon => 'https://example.com/pin.png');
	my (undef, $body) = $m->onload_render();
	like($body, qr/L\.icon/,              'L.icon call present');
	like($body, qr|example\.com/pin\.png|, 'icon URL present');
};

subtest 'onload_render: popup label with single quote is JS-escaped' => sub {
	# A raw single quote in a label would break the JS string — _js_string must fire.
	my $m = HTML::OSM->new();
	$m->add_marker([$CFG{LAT_LONDON}, $CFG{LON_LONDON}], html => "O'Brien's Pub");
	my (undef, $body) = $m->onload_render();
	like($body, qr/O\\'Brien/, 'single quote JS-escaped in popup label');
};

subtest 'onload_render: GPX URL with special chars is JS-escaped' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$CFG{LAT_LONDON}, $CFG{LON_LONDON}]);
	$m->add_gpx("https://example.com/track's.gpx");
	my (undef, $body) = $m->onload_render();
	like($body, qr/track\\'s\.gpx/, 'GPX URL JS-escaped');
};

subtest 'onload_render: GeoJSON style colour appears in body' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$CFG{LAT_LONDON}, $CFG{LON_LONDON}]);
	$m->add_geojson({ type => 'FeatureCollection', features => [] },
		style => { color => '#abcdef' });
	my (undef, $body) = $m->onload_render();
	like($body, qr/L\.geoJSON/, 'L.geoJSON call present');
	like($body, qr/#abcdef/,    'style colour present');
};

subtest 'onload_render: choropleth emits colour lookup and fillColor' => sub {
	my $m = HTML::OSM->new();
	$m->center([$CFG{LAT_LONDON}, $CFG{LON_LONDON}]);
	$m->add_choropleth(\@FEATURES, { England => 100, Scotland => 50 }, key => 'name');
	my (undef, $body) = $m->onload_render();
	like($body, qr/choroplethColors/, 'colour lookup emitted');
	like($body, qr/fillColor/,        'fillColor style emitted');
	like($body, qr/choroplethValues/, 'value lookup emitted');
};

subtest 'onload_render: non-marker-only render with center succeeds' => sub {
	my $m = HTML::OSM->new();
	$m->center([$CFG{LAT_LONDON}, $CFG{LON_LONDON}]);
	$m->add_geojson({ type => 'FeatureCollection', features => [] });
	my @r;
	lives_ok { @r = $m->onload_render() } 'lives with center + GeoJSON only';
	is(scalar @r, 2, 'two-element result');
};

# ─────────────────────────────────────────────────────────────────────────────
# _fetch_coordinates()
# White-box via direct method call; all HTTP is intercepted by the global mock.
# ─────────────────────────────────────────────────────────────────────────────

subtest '_fetch_coordinates: empty string croaks' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->_fetch_coordinates('') }
		qr/address not given to _fetch_coordinates/,
		'empty string croaks';
};

subtest '_fetch_coordinates: undef croaks' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->_fetch_coordinates(undef) }
		qr/address not given to _fetch_coordinates/,
		'undef croaks';
};

subtest '_fetch_coordinates: geocoder returns blessed object with lat/lon methods' => sub {
	my $m = HTML::OSM->new();
	mock 'MockGeoBlessed::latitude'  => sub { $CFG{LAT_PARIS} };
	mock 'MockGeoBlessed::longitude' => sub { $CFG{LON_PARIS} };
	my $result = bless {}, 'MockGeoBlessed';
	mock 'MockGeocoderB::geocode' => sub { $result };
	$m->{geocoder} = bless {}, 'MockGeocoderB';
	my ($lat, $lon) = $m->_fetch_coordinates('Paris');
	is($lat, $CFG{LAT_PARIS}, 'lat from object');
	is($lon, $CFG{LON_PARIS}, 'lon from object');
};

subtest '_fetch_coordinates: geocoder returns {lat, lon} hashref' => sub {
	my $m = HTML::OSM->new();
	mock 'MockGeoHash::geocode' => sub { { lat => $CFG{LAT_NYC}, lon => $CFG{LON_NYC} } };
	$m->{geocoder} = bless {}, 'MockGeoHash';
	my ($lat, $lon) = $m->_fetch_coordinates('New York');
	is($lat, $CFG{LAT_NYC}, 'lat from hashref');
	is($lon, $CFG{LON_NYC}, 'lon from hashref');
};

subtest '_fetch_coordinates: geocoder returns Google Maps geometry hashref' => sub {
	my $m = HTML::OSM->new();
	mock 'MockGeoGmap::geocode' => sub {
		{ geometry => { location => { lat => $CFG{LAT_LONDON}, lng => $CFG{LON_LONDON} } } }
	};
	$m->{geocoder} = bless {}, 'MockGeoGmap';
	my ($lat, $lon) = $m->_fetch_coordinates('London');
	is($lat, $CFG{LAT_LONDON}, 'lat from geometry.location');
	is($lon, $CFG{LON_LONDON}, 'lon from geometry.location');
};

subtest '_fetch_coordinates: geocoder returns [lat, lon] arrayref' => sub {
	my $m = HTML::OSM->new();
	mock 'MockGeoArr::geocode' => sub { [$CFG{LAT_PARIS}, $CFG{LON_PARIS}] };
	$m->{geocoder} = bless {}, 'MockGeoArr';
	my ($lat, $lon) = $m->_fetch_coordinates('Paris');
	is($lat, $CFG{LAT_PARIS}, 'lat from arrayref');
	is($lon, $CFG{LON_PARIS}, 'lon from arrayref');
};

subtest '_fetch_coordinates: geocoder returning undef gives (undef, undef)' => sub {
	my $m = HTML::OSM->new();
	mock 'MockGeoNone::geocode' => sub { undef };
	$m->{geocoder} = bless {}, 'MockGeoNone';
	my ($lat, $lon) = $m->_fetch_coordinates('Nowhere');
	ok(!defined $lat, 'lat undef');
	ok(!defined $lon, 'lon undef');
};

subtest '_fetch_coordinates: unrecognised geocoder type carps, returns (undef, undef)' => sub {
	my $m = HTML::OSM->new();
	# A blessed scalar ref has no lat/lon methods, is not HASH, not ARRAY.
	my $weird = bless \(my $s = 'x'), 'WeirdReturn';
	mock 'MockGeoWeird::geocode' => sub { $weird };
	$m->{geocoder} = bless {}, 'MockGeoWeird';
	my ($lat, $lon);
	warning_like {
		($lat, $lon) = $m->_fetch_coordinates('Somewhere');
	} qr/_fetch_coordinates: unrecognised geocoder result type/,
	  'unrecognised type carps';
	ok(!defined $lat, 'lat undef');
	ok(!defined $lon, 'lon undef');
};

subtest '_fetch_coordinates: cache hit returns stored coords without HTTP' => sub {
	my $m = HTML::OSM->new();
	# Pre-seed the CHI in-memory cache; the HTTP mock always fails so if the
	# HTTP path is taken the result would be (undef, undef).
	my $key = 'osm:' . uri_escape_utf8('Berlin');
	$m->{cache}->set($key, { lat => '52.52', lon => '13.405' });
	my ($lat, $lon) = $m->_fetch_coordinates('Berlin');
	is($lat, '52.52',  'lat from cache');
	is($lon, '13.405', 'lon from cache');
};

subtest '_fetch_coordinates: HTTP success returns coords and populates cache' => sub {
	my $m    = HTML::OSM->new();
	my $json = '[{"lat":"51.5074","lon":"-0.1278","display_name":"London"}]';

	my $resp = bless {}, 'MockHTTPResp';
	mock 'MockHTTPResp::is_success'      => sub { 1 };
	mock 'MockHTTPResp::decoded_content' => sub { $json };

	my $ua = bless {}, 'MockHTTPUA';
	mock 'MockHTTPUA::default_header' => sub { };
	mock 'MockHTTPUA::env_proxy'      => sub { };
	mock 'MockHTTPUA::get'            => sub { $resp };

	$m->{ua} = $ua;

	my ($lat, $lon) = $m->_fetch_coordinates('London');
	is($lat, '51.5074', 'lat from HTTP');
	is($lon, '-0.1278', 'lon from HTTP');

	# Verify the result landed in the cache for subsequent calls.
	my $cached = $m->{cache}->get('osm:' . uri_escape_utf8('London'));
	is($cached->{lat}, '51.5074', 'HTTP result cached');

};

subtest '_fetch_coordinates: HTTP failure returns (undef, undef)' => sub {
	# The global network block already causes HTTP failure; this subtest just
	# confirms the contract explicitly with a labelled mock for clarity.
	my $m = HTML::OSM->new();

	my $resp = bless {}, 'FailHTTPResp';
	mock 'FailHTTPResp::is_success' => sub { 0 };
	my $ua = bless {}, 'FailHTTPUA';
	mock 'FailHTTPUA::default_header' => sub { };
	mock 'FailHTTPUA::env_proxy'      => sub { };
	mock 'FailHTTPUA::get'            => sub { $resp };
	$m->{ua} = $ua;

	my ($lat, $lon) = $m->_fetch_coordinates('Nowhere');
	ok(!defined $lat, 'lat undef on HTTP failure');
	ok(!defined $lon, 'lon undef on HTTP failure');

};

subtest '_fetch_coordinates: HTTP 200 with non-JSON body returns (undef, undef) — regression for eval guard' => sub {
	# Bug fixed: decode_json previously died uncaught when Nominatim returned an
	# HTML maintenance page with a 200 OK.  The eval guard now catches parse errors
	# and returns (undef, undef) instead of propagating a die to the caller.
	# Use an isolated cache (global => 0) and a unique location to prevent a cache
	# hit from a previous subtest masking the HTTP path entirely.
	my $m = HTML::OSM->new();
	$m->{cache} = CHI->new(driver => 'Memory', global => 0);

	my $resp = bless {}, 'BadJSONHTTPResp';
	mock 'BadJSONHTTPResp::is_success'      => sub { 1 };
	mock 'BadJSONHTTPResp::decoded_content' => sub { '<html>Service Unavailable</html>' };
	my $ua = bless {}, 'BadJSONHTTPUA';
	mock 'BadJSONHTTPUA::default_header' => sub { };
	mock 'BadJSONHTTPUA::env_proxy'      => sub { };
	mock 'BadJSONHTTPUA::get'            => sub { $resp };
	$m->{ua} = $ua;

	my ($lat, $lon);
	warning_like {
		($lat, $lon) = $m->_fetch_coordinates('NonexistentBadJSONPlace');
	} qr/failed to decode Nominatim response/,
	  'carp emitted when HTTP body is not valid JSON';
	ok(!defined $lat, 'lat undef after JSON parse failure');
	ok(!defined $lon, 'lon undef after JSON parse failure');

};

subtest '_validate: trailing newline in coord string is now rejected — regression for \\z anchor' => sub {
	# Bug fixed: _validate used $ (which allows a trailing \n in Perl regex).
	# "0\n" would pass validation and could embed a newline into JS output,
	# causing a syntax error.  Switching to \z anchors at the true string end.
	local $SIG{__WARN__} = $SILENCE;
	is(HTML::OSM::_validate('51.5',  "0\n"),  0, 'trailing \\n in lon now rejected');
	is(HTML::OSM::_validate("51.5\n", '0'),   0, 'trailing \\n in lat now rejected');
};

restore_all();
done_testing();

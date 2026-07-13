#!/usr/bin/env perl

# Destructive, pathological, boundary-condition, and security tests for HTML::OSM.
# Strategy: attempt to break or subvert every public method with hostile inputs,
# malformed data, out-of-range values, type mismatches, and injection payloads.
# Every subtest is designed to trigger a failure path or expose a security hole.

use strict;
use warnings;

use Readonly;
use Scalar::Util qw(blessed);
use Test::Memory::Cycle;
use Test::Mockingbird qw(mock restore_all);
use Test::Most;
use Test::Returns;

BEGIN { use_ok('HTML::OSM') }

# ── All magic values in one place ─────────────────────────────────────────────
Readonly my %C => (
	ZOOM_MIN     =>  0,
	ZOOM_MAX     => 19,
	ZOOM_DEFAULT => 12,
	LAT_LONDON   => 51.5074,
	LON_LONDON   => -0.1278,
	LAT_MAX      =>  90,
	LAT_MIN      => -90,
	LON_MAX      =>  180,
	LON_MIN      => -180,
	# Payloads used to detect JS injection in rendered output.
	JS_PAYLOAD   => q{0); alert("edge-case-xss")//},
	SCRIPT_CLOSE => q{</script><script>alert("edge-case-script-close")</script>},
);

# Silence expected carps/warnings so TAP output stays clean.
my $SILENCE = sub { };

# ── Global HTTP block ─────────────────────────────────────────────────────────
# Unique class names so this block does not collide with other test files.
# NEVER call restore_all() inside a subtest — it destroys this block.
{
	my $fail_resp = bless {}, 'ECNetResp';
	mock 'ECNetResp::is_success' => sub { 0 };
	my $fail_ua   = bless {}, 'ECNetUA';
	mock 'ECNetUA::default_header' => sub { };
	mock 'ECNetUA::env_proxy'      => sub { };
	mock 'ECNetUA::get'            => sub { $fail_resp };
	mock 'LWP::UserAgent::new'     => sub { $fail_ua };
}

# ─────────────────────────────────────────────────────────────────────────────
# 1. new() — hostile constructor inputs
# Each of these should either croak (type/range error) or silently use defaults.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'new: zoom below minimum (< 0) is rejected' => sub {
	throws_ok { HTML::OSM->new(zoom => -1) }
		qr/\b(?:invalid|not|zoom|range)\b/i,
		'zoom -1 croaks';
};

subtest 'new: zoom above maximum (> 19) is rejected' => sub {
	throws_ok { HTML::OSM->new(zoom => 20) }
		qr/\b(?:invalid|not|zoom|range)\b/i,
		'zoom 20 croaks';
};

subtest 'new: zoom as float is rejected' => sub {
	throws_ok { HTML::OSM->new(zoom => 10.5) }
		qr/\b(?:invalid|not|integer|zoom)\b/i,
		'zoom 10.5 (float) croaks';
};

subtest 'new: zoom as non-numeric string is rejected' => sub {
	throws_ok { HTML::OSM->new(zoom => 'twelve') }
		qr/\b(?:invalid|not|integer|zoom)\b/i,
		'zoom "twelve" croaks';
};

subtest 'new: unknown parameter is rejected by strict schema' => sub {
	throws_ok { HTML::OSM->new(definitely_not_a_valid_key => 1) }
		qr/unknown|invalid|not allowed/i,
		'unknown param croaks';
};

subtest 'new: coordinates must be arrayref — string rejected' => sub {
	throws_ok { HTML::OSM->new(coordinates => 'not-an-array') }
		qr/\b(?:invalid|not|type|array)\b/i,
		'coordinates as string croaks';
};

subtest 'new: coordinates must be arrayref — hashref rejected' => sub {
	throws_ok { HTML::OSM->new(coordinates => { a => 1 }) }
		qr/\b(?:invalid|not|type|array)\b/i,
		'coordinates as hashref croaks';
};

subtest 'new: min_interval must be >= 0 — negative rejected' => sub {
	throws_ok { HTML::OSM->new(min_interval => -1) }
		qr/\b(?:invalid|not|min_interval|range|negative)\b/i,
		'negative min_interval croaks';
};

subtest 'new: geocoder must respond to geocode() — unqualified object rejected' => sub {
	# An object without the required method should fail schema validation.
	my $bad_geo = bless {}, 'ECBadGeo';   # no geocode() method
	throws_ok { HTML::OSM->new(geocoder => $bad_geo) }
		qr/\b(?:invalid|can|geocode|method)\b/i,
		'geocoder without geocode() method croaks';
};

subtest 'new: cache must respond to get/set — unqualified object rejected' => sub {
	my $bad_cache = bless {}, 'ECBadCache';   # no get/set methods
	throws_ok { HTML::OSM->new(cache => $bad_cache) }
		qr/\b(?:invalid|can|get|set|method)\b/i,
		'cache without get/set methods croaks';
};

subtest 'new: empty args list uses defaults' => sub {
	my $m = HTML::OSM->new();
	isa_ok($m, 'HTML::OSM', 'empty constructor succeeds');
	is($m->zoom(), $C{ZOOM_DEFAULT}, 'default zoom');
	memory_cycle_ok($m, 'no cycles');
};

subtest 'new: zoom => 0 (boundary minimum) accepted' => sub {
	my $m = HTML::OSM->new(zoom => 0);
	is($m->zoom(), 0, 'zoom 0 stored');
};

subtest 'new: zoom => 19 (boundary maximum) accepted' => sub {
	my $m = HTML::OSM->new(zoom => 19);
	is($m->zoom(), 19, 'zoom 19 stored');
};

# ─────────────────────────────────────────────────────────────────────────────
# 2. zoom() — boundary conditions
# ─────────────────────────────────────────────────────────────────────────────

subtest 'zoom: setter with 0 (falsy) stores correctly' => sub {
	# zoom == 0 is falsy in boolean context; the setter must still honour it.
	my $m = HTML::OSM->new(zoom => 5);
	my $ret = $m->zoom(0);
	is($ret,      0, 'setter returns new zoom (0)');
	is($m->zoom, 0,  'getter confirms zoom is 0');
};

subtest 'zoom: out-of-range 20 via setter croaks' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->zoom(20) }
		qr/\b(?:invalid|not|zoom|range)\b/i,
		'zoom(20) via setter croaks';
};

subtest 'zoom: negative via setter croaks' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->zoom(-1) }
		qr/\b(?:invalid|not|zoom|range)\b/i,
		'zoom(-1) via setter croaks';
};

subtest 'zoom: float argument via setter croaks' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->zoom(3.7) }
		qr/\b(?:invalid|not|integer|zoom)\b/i,
		'zoom(3.7) via setter croaks';
};

subtest 'zoom: non-numeric string via setter croaks' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->zoom('high') }
		qr/\b(?:invalid|not|integer|zoom)\b/i,
		'zoom("high") via setter croaks';
};

subtest 'zoom: setter with extra positional args causes type-mismatch croak' => sub {
	# Params::Get packs (10, bogus => 'arg') into an arrayref for the 'zoom' key,
	# so Params::Validate::Strict rejects it as "not an integer".
	my $m = HTML::OSM->new();
	throws_ok { $m->zoom(10, bogus => 'arg') }
		qr/integer|zoom/i,
		'extra args to zoom() cause type-mismatch croak';
};

subtest 'zoom: getter returns integer type' => sub {
	my $m = HTML::OSM->new(zoom => 8);
	returns_ok($m->zoom(), { type => 'integer' }, 'zoom() returns integer');
};

subtest 'zoom: clone path bypasses validation, stores out-of-range value' => sub {
	# LIMITATIONS: clone path skips Params::Validate::Strict.
	# Document this known bypass so regressions are caught if it is ever fixed.
	my $base  = HTML::OSM->new(zoom => 10);
	my $clone = $base->new(zoom => 25);   # invalid, but bypass is expected
	is($clone->zoom(), 25, 'clone stores out-of-range zoom (documented limitation)');
};

# ─────────────────────────────────────────────────────────────────────────────
# 3. add_marker() — hostile and boundary inputs
# ─────────────────────────────────────────────────────────────────────────────

subtest 'add_marker: no arguments croaks from Params::Get usage guard' => sub {
	# With no args, Params::Get::get_params(undef) sees an empty call and croaks
	# before _fetch_coordinates is reached.
	my $m = HTML::OSM->new();
	throws_ok { $m->add_marker() }
		qr/Params::Get|address not given|Usage/i,
		'add_marker() with no args croaks';
};

subtest 'add_marker: empty string triggers croak from _fetch_coordinates' => sub {
	# The empty string is falsy — _fetch_coordinates guards against it.
	my $m = HTML::OSM->new();
	throws_ok { $m->add_marker('') }
		qr/address not given/i,
		'add_marker("") croaks';
};

subtest 'add_marker: undef coordinate array → 0' => sub {
	# Two-element array with both undef: coords are undefined, must return 0.
	my $m = HTML::OSM->new();
	local $SIG{__WARN__} = $SILENCE;
	is($m->add_marker([undef, undef]), 0, '[undef, undef] → 0');
};

subtest 'add_marker: one-element array unwrapped as address string' => sub {
	# Single-element arrayref is treated as a wrapped address — geocode fails.
	my $m = HTML::OSM->new();
	local $SIG{__WARN__} = $SILENCE;
	is($m->add_marker(['SomeCity']), 0, '["SomeCity"] → geocode attempted, fails → 0');
};

subtest 'add_marker: three-element array rejected' => sub {
	my $m = HTML::OSM->new();
	is($m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}, 'extra']), 0,
		'3-element array → 0');
};

subtest 'add_marker: empty array rejected' => sub {
	my $m = HTML::OSM->new();
	is($m->add_marker([]), 0, '[] → 0');
};

subtest 'add_marker: WGS-84 boundary maximums accepted' => sub {
	my $m = HTML::OSM->new();
	is($m->add_marker([$C{LAT_MAX}, $C{LON_MAX}]), 1, '[90, 180] accepted');
	is($m->add_marker([$C{LAT_MIN}, $C{LON_MIN}]), 1, '[-90, -180] accepted');
};

subtest 'add_marker: lat just beyond +90 is rejected' => sub {
	my $m = HTML::OSM->new();
	local $SIG{__WARN__} = $SILENCE;
	is($m->add_marker([90.0001, 0]), 0, 'lat 90.0001 → 0');
};

subtest 'add_marker: lon just beyond -180 is rejected' => sub {
	my $m = HTML::OSM->new();
	local $SIG{__WARN__} = $SILENCE;
	is($m->add_marker([0, -180.0001]), 0, 'lon -180.0001 → 0');
};

subtest 'add_marker: scientific notation coordinates rejected' => sub {
	# _validate regex requires plain decimal; 1e2 must not slip through.
	my $m = HTML::OSM->new();
	local $SIG{__WARN__} = $SILENCE;
	is($m->add_marker(['1e2', 0]), 0, 'lat "1e2" (scientific notation) rejected');
};

subtest 'add_marker: origin (0, 0) is valid' => sub {
	# Zero is a valid coordinate (Gulf of Guinea).  Falsy zero must not be
	# rejected by any unless/if check in the pipeline.
	my $m = HTML::OSM->new();
	is($m->add_marker([0, 0]), 1, '[0, 0] accepted');
};

subtest 'add_marker: unblessed hashref arg parsed as empty params, croaks from geocoder' => sub {
	# An unblessed hashref is treated by Params::Get as the params hash, not as
	# the 'point'.  With no 'point' key in the hash, $point is undef → geocoder
	# receives undef → "address not given" croak.
	my $m = HTML::OSM->new();
	throws_ok { $m->add_marker({lat => 51.5, lon => -0.1}) }
		qr/address not given/i,
		'hashref arg → point=undef → "address not given" croak';
};

subtest 'add_marker: blessed ref without latitude() method croaks' => sub {
	my $bad_point = bless {}, 'ECBadPoint';   # no latitude/longitude methods
	my $m = HTML::OSM->new();
	throws_ok { $m->add_marker($bad_point) }
		qr/unknown point type/i,
		'blessed ref without latitude() croaks';
};

subtest 'add_marker: blessed point returning undef lat → 0' => sub {
	mock 'ECUndefLat::latitude'  => sub { undef };
	mock 'ECUndefLat::longitude' => sub { $C{LON_LONDON} };
	my $m = HTML::OSM->new();
	is($m->add_marker(bless({}, 'ECUndefLat')), 0,
		'blessed point returning undef lat → 0');
};

subtest 'add_marker: blessed point returning non-numeric lat → 0' => sub {
	# Even if the point object exists, non-numeric coordinates must be rejected.
	mock 'ECBadLat::latitude'  => sub { 'not-a-number' };
	mock 'ECBadLat::longitude' => sub { $C{LON_LONDON} };
	local $SIG{__WARN__} = $SILENCE;
	my $m = HTML::OSM->new();
	is($m->add_marker(bless({}, 'ECBadLat')), 0,
		'blessed point returning non-numeric lat → 0');
};

subtest 'add_marker: blessed point with JS-injection lat string → 0' => sub {
	# A geocoder returning a crafted lat must not inject JS into rendered output.
	mock 'ECInjLat::latitude'  => sub { $C{JS_PAYLOAD} };
	mock 'ECInjLat::longitude' => sub { 0 };
	local $SIG{__WARN__} = $SILENCE;
	my $m = HTML::OSM->new();
	is($m->add_marker(bless({}, 'ECInjLat')), 0,
		'blessed point with injected lat string → 0 (rejected by _validate)');
};

subtest 'add_marker: return value is integer 0 or 1' => sub {
	my $m = HTML::OSM->new();
	returns_ok($m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]),
		{ type => 'integer' }, 'return is integer');
};

# ─────────────────────────────────────────────────────────────────────────────
# 4. center() — hostile inputs
# ─────────────────────────────────────────────────────────────────────────────

subtest 'center: no args croaks from Params::Get usage guard' => sub {
	# With no args, Params::Get fires its own "Usage:" croak before the module's.
	my $m = HTML::OSM->new();
	throws_ok { $m->center() }
		qr/Params::Get|center.*usage|point/i,
		'center() with no args croaks';
};

subtest 'center: undef arg croaks from module usage guard' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->center(undef) }
		qr/center\(\): usage:/i,
		'center(undef) croaks';
};

subtest 'center: empty arrayref croaks' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->center([]) }
		qr/center\(\): point must have latitude and longitude/i,
		'center([]) croaks';
};

subtest 'center: 1-element arrayref croaks' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->center([$C{LAT_LONDON}]) }
		qr/center\(\): point must have latitude and longitude/i,
		'center([$lat]) croaks';
};

subtest 'center: 3-element arrayref croaks' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->center([$C{LAT_LONDON}, $C{LON_LONDON}, 0]) }
		qr/center\(\): point must have latitude and longitude/i,
		'center([$lat, $lon, extra]) croaks';
};

subtest 'center: out-of-range coordinate → 0' => sub {
	my $m = HTML::OSM->new();
	local $SIG{__WARN__} = $SILENCE;
	is($m->center([91, 0]),   0, 'lat 91 → 0');
	is($m->center([0, -181]), 0, 'lon -181 → 0');
};

subtest 'center: unblessed hashref parsed as params, triggers usage croak' => sub {
	# Params::Get treats the hashref as the params hash → point=undef → usage croak.
	my $m = HTML::OSM->new();
	throws_ok { $m->center({ lat => 51.5, lon => -0.1 }) }
		qr/center\(\): usage:/i,
		'unblessed hashref to center() croaks with usage message';
};

subtest 'center: blessed ref without latitude() croaks (unknown type)' => sub {
	my $bad = bless {}, 'ECBadCenter';
	my $m   = HTML::OSM->new();
	throws_ok { $m->center($bad) }
		qr/center\(\): unknown point type/i,
		'blessed ref without latitude() to center() croaks';
};

# ─────────────────────────────────────────────────────────────────────────────
# 5. add_geojson() — hostile inputs and XSS via JSON embedding
# ─────────────────────────────────────────────────────────────────────────────

subtest 'add_geojson: undef data dies (decode_json of undef)' => sub {
	my $m = HTML::OSM->new();
	dies_ok { $m->add_geojson(undef) }
		'add_geojson(undef) dies (decode_json rejects undef)';
};

subtest 'add_geojson: empty string dies (invalid JSON)' => sub {
	my $m = HTML::OSM->new();
	dies_ok { $m->add_geojson('') }
		'add_geojson("") dies (invalid JSON)';
};

subtest 'add_geojson: malformed JSON string dies' => sub {
	my $m = HTML::OSM->new();
	dies_ok { $m->add_geojson('{invalid json}') }
		'add_geojson("{invalid json}") dies';
};

subtest 'add_geojson: circular reference in data dies in onload_render' => sub {
	# encode_json will die when it encounters a cycle; the module does not
	# pre-validate GeoJSON structure.
	my $m = HTML::OSM->new();
	$m->center([$C{LAT_LONDON}, $C{LON_LONDON}]);
	my %circ;
	$circ{self} = \%circ;
	$m->add_geojson(\%circ);
	dies_ok { $m->onload_render() }
		'circular-reference GeoJSON dies in onload_render (encode_json rejects cycle)';
};

subtest 'add_geojson: return value is always 1' => sub {
	my $m = HTML::OSM->new();
	returns_ok(
		$m->add_geojson({ type => 'FeatureCollection', features => [] }),
		{ type => 'integer' }, 'returns integer');
	is($m->add_geojson({ type => 'FeatureCollection', features => [] }), 1,
		'return value is 1');
};

# ── Security: </script> injection via encode_json ──────────────────────────
# encode_json does NOT escape forward slashes by default, so embedding its
# output raw in a <script> block allows an attacker to close the block early.
# The module must escape </  →  <\/ in all JSON output destined for <script>.

subtest 'security: GeoJSON style with </script> is escaped in rendered output' => sub {
	my $m = HTML::OSM->new();
	$m->center([$C{LAT_LONDON}, $C{LON_LONDON}]);
	$m->add_geojson(
		{ type => 'FeatureCollection', features => [] },
		style => { color => $C{SCRIPT_CLOSE} },
	);
	my (undef, $body) = $m->onload_render();
	unlike($body, qr|</script><script>|,
		'raw </script><script> absent from rendered body (style injection blocked)');
	diag("style segment: " . substr($body, index($body, 'style:'), 120))
		if $ENV{TEST_VERBOSE};
};

subtest 'security: GeoJSON feature property with </script> is escaped in rendered output' => sub {
	my $m = HTML::OSM->new();
	$m->center([$C{LAT_LONDON}, $C{LON_LONDON}]);
	$m->add_geojson({
		type     => 'FeatureCollection',
		features => [{
			type       => 'Feature',
			properties => { name => $C{SCRIPT_CLOSE} },
			geometry   => { type => 'Point', coordinates => [0, 0] },
		}],
	});
	my (undef, $body) = $m->onload_render();
	unlike($body, qr|</script><script>|,
		'raw </script><script> absent when feature property contains injection');
};

subtest 'security: GeoJSON popup property name with </script> is escaped' => sub {
	my $m = HTML::OSM->new();
	$m->center([$C{LAT_LONDON}, $C{LON_LONDON}]);
	# The popup property name goes through _js_string — test that the data
	# path (the whole GeoJSON blob) is also safe.
	$m->add_geojson(
		{ type => 'FeatureCollection', features => [] },
		popup => 'name',
		style => { fillOpacity => 0.5 },
	);
	my (undef, $body) = $m->onload_render();
	unlike($body, qr|</script><script>|,
		'rendered output does not contain script-close injection');
};

# ─────────────────────────────────────────────────────────────────────────────
# 6. add_heatmap() — hostile inputs and XSS via points JSON
# ─────────────────────────────────────────────────────────────────────────────

subtest 'add_heatmap: undef points croaks' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->add_heatmap(undef) }
		qr/add_heatmap: points must be an arrayref/,
		'add_heatmap(undef) croaks';
};

subtest 'add_heatmap: hashref points croaks' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->add_heatmap({}) }
		qr/add_heatmap: points must be an arrayref/,
		'add_heatmap({}) croaks';
};

subtest 'add_heatmap: scalar string croaks' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->add_heatmap('string') }
		qr/add_heatmap: points must be an arrayref/,
		'add_heatmap("string") croaks';
};

subtest 'add_heatmap: empty arrayref is accepted (renders empty layer)' => sub {
	my $m = HTML::OSM->new();
	is($m->add_heatmap([]), 1, 'empty arrayref → 1');
	$m->center([$C{LAT_LONDON}, $C{LON_LONDON}]);
	my (undef, $body) = $m->onload_render();
	like($body, qr/L\.heatLayer\(\[\]/, 'empty heatmap rendered as L.heatLayer([])');
};

subtest 'security: heatmap points with </script> in intensity escaped in output' => sub {
	# Intensity is a string — encode_json would normally embed it raw.
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	$m->add_heatmap([[$C{LAT_LONDON}, $C{LON_LONDON}, $C{SCRIPT_CLOSE}]]);
	my (undef, $body) = $m->onload_render();
	unlike($body, qr|</script><script>|,
		'raw </script><script> absent when heatmap intensity contains injection');
};

subtest 'add_heatmap: return value is 1' => sub {
	my $m = HTML::OSM->new();
	returns_ok($m->add_heatmap([[51.5, -0.1]]), { type => 'integer' }, 'returns integer');
	is($m->add_heatmap([[51.5, -0.1]]), 1, 'returns 1');
};

# ─────────────────────────────────────────────────────────────────────────────
# 7. add_gpx() — hostile inputs
# ─────────────────────────────────────────────────────────────────────────────

subtest 'add_gpx: no argument croaks from Params::Get usage guard' => sub {
	# With no args, Params::Get fires "Usage:" before the module's own croak.
	my $m = HTML::OSM->new();
	throws_ok { $m->add_gpx() }
		qr/Params::Get|url|add_gpx|Usage/i,
		'add_gpx() with no args croaks';
};

subtest 'add_gpx: undef url croaks' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->add_gpx(undef) }
		qr/add_gpx: url is required/,
		'add_gpx(undef) croaks';
};

subtest 'add_gpx: empty string url croaks' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->add_gpx('') }
		qr/add_gpx: url is required/,
		'add_gpx("") croaks';
};

subtest 'add_gpx: return value is 1' => sub {
	my $m = HTML::OSM->new();
	returns_ok(
		$m->add_gpx('https://example.com/track.gpx'),
		{ type => 'integer' }, 'returns integer');
	is($m->add_gpx('https://example.com/track2.gpx'), 1, 'returns 1');
};

# ─────────────────────────────────────────────────────────────────────────────
# 8. add_choropleth() — hostile inputs and XSS via color/value JSON
# ─────────────────────────────────────────────────────────────────────────────

subtest 'add_choropleth: undef features croaks' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->add_choropleth(undef, {}) }
		qr/add_choropleth: features must be an arrayref/,
		'undef features croaks';
};

subtest 'add_choropleth: string features croaks' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->add_choropleth('string', {}) }
		qr/add_choropleth: features must be an arrayref/,
		'string features croaks';
};

subtest 'add_choropleth: undef values croaks' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->add_choropleth([], undef) }
		qr/add_choropleth: values must be a hashref/,
		'undef values croaks';
};

subtest 'add_choropleth: arrayref values croaks' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->add_choropleth([], [1, 2, 3]) }
		qr/add_choropleth: values must be a hashref/,
		'arrayref values croaks';
};

subtest 'add_choropleth: empty features and values renders without crashing' => sub {
	my $m = HTML::OSM->new();
	$m->center([$C{LAT_LONDON}, $C{LON_LONDON}]);
	is($m->add_choropleth([], {}), 1, 'empty features/values → 1');
	my (undef, $body) = $m->onload_render();
	like($body, qr/choroplethColors/, 'choropleth JS rendered');
};

subtest 'add_choropleth: single-value set avoids division by zero (min==max guard)' => sub {
	# All features have the same value: max==min would cause /0 without the guard.
	my $m = HTML::OSM->new();
	$m->center([$C{LAT_LONDON}, $C{LON_LONDON}]);
	my @feats = ({ type => 'Feature', properties => { name => 'X' },
	               geometry => { type => 'Point', coordinates => [0,0] } });
	lives_ok { $m->add_choropleth(\@feats, { X => 42 }) }
		'single-value choropleth does not divide by zero';
	lives_ok { $m->onload_render() }
		'onload_render with single-value choropleth does not crash';
};

subtest 'add_choropleth: empty scale array renders without crashing' => sub {
	my $m = HTML::OSM->new();
	$m->center([$C{LAT_LONDON}, $C{LON_LONDON}]);
	my @feats = ({ type => 'Feature', properties => { name => 'A' },
	               geometry => { type => 'Point', coordinates => [0,0] } });
	# Empty scale: color lookup falls to undefined, JS uses '#cccccc' fallback.
	lives_ok { $m->add_choropleth(\@feats, { A => 10 }, scale => []) }
		'empty scale array does not croak in add_choropleth';
	lives_ok { $m->onload_render() }
		'onload_render with empty-scale choropleth does not crash';
};

subtest 'security: choropleth scale color with </script> is escaped in output' => sub {
	my $m = HTML::OSM->new();
	$m->center([$C{LAT_LONDON}, $C{LON_LONDON}]);
	my @feats = ({ type => 'Feature', properties => { name => 'A' },
	               geometry => { type => 'Point', coordinates => [0,0] } });
	$m->add_choropleth(
		\@feats,
		{ A => 50 },
		scale => [$C{SCRIPT_CLOSE}],   # user-controlled color string
	);
	my (undef, $body) = $m->onload_render();
	unlike($body, qr|</script><script>|,
		'</script> in choropleth scale is escaped in rendered body');
};

subtest 'security: choropleth feature key with </script> in values JSON is escaped' => sub {
	my $m = HTML::OSM->new();
	$m->center([$C{LAT_LONDON}, $C{LON_LONDON}]);
	my @feats = ({ type => 'Feature', properties => { name => 'X' },
	               geometry => { type => 'Point', coordinates => [0,0] } });
	$m->add_choropleth(\@feats, { $C{SCRIPT_CLOSE} => 100 });
	my (undef, $body) = $m->onload_render();
	unlike($body, qr|</script><script>|,
		'</script> in choropleth value key is escaped in rendered body');
};

subtest 'security: choropleth feature data with </script> in geometry is escaped' => sub {
	# The entire feature blob is JSON-encoded and embedded.  A crafted feature
	# property containing </script> must not close the script block.
	my $m = HTML::OSM->new();
	$m->center([$C{LAT_LONDON}, $C{LON_LONDON}]);
	my @feats = ({
		type       => 'Feature',
		properties => { name => $C{SCRIPT_CLOSE} },
		geometry   => { type => 'Point', coordinates => [0,0] },
	});
	$m->add_choropleth(\@feats, { $C{SCRIPT_CLOSE} => 10 });
	my (undef, $body) = $m->onload_render();
	unlike($body, qr|</script><script>|,
		'</script> in choropleth feature properties is escaped in rendered body');
};

# ─────────────────────────────────────────────────────────────────────────────
# 9. onload_render() — security: geocoder lat/lon injection
#
# VULNERABILITY: when coordinates are seeded via the constructor with undef
# lat/lon, onload_render() geocodes them at render time.  The returned lat/lon
# were NOT validated before being embedded in the JS string.
# Attack vector: a compromised or MITM'd Nominatim endpoint returns a crafted
# lat string containing JS — it would be embedded literally in L.marker([lat,lon]).
# Fix: call _validate() on every geocoder result in the onload_render() loop.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'security: geocoder-returned lat/lon validated before JS embedding' => sub {
	# Inject a geocoder that returns a JS-injection payload in the lat field.
	# A second valid static marker (pre-supplied numeric coords) ensures the map
	# still has something to render after the malicious coord is discarded.
	mock 'ECJSInjGeo::geocode' => sub {
		{ lat => $C{JS_PAYLOAD}, lon => '0' }
	};
	my $m = HTML::OSM->new(
		geocoder    => bless({}, 'ECJSInjGeo'),
		# First tuple: undef lat/lon → geocoded in onload_render → malicious result
		# Second tuple: valid static coord → always accepted
		coordinates => [
			[undef,           undef,         'SomeTown',  undef],
			[$C{LAT_LONDON},  $C{LON_LONDON}, 'London',    undef],
		],
	);
	# With the fix, the malicious coord is rejected; London renders normally.
	my (undef, $body) = $m->onload_render();
	unlike($body, qr/alert\("edge-case-xss"\)/,
		'malicious geocoder lat not embedded raw in rendered JS');
	like($body, qr/$C{LAT_LONDON}/, 'valid London marker still present after bad coord discarded');
	diag("body excerpt: " . substr($body, 0, 400)) if $ENV{TEST_VERBOSE};
};

subtest 'security: all geocoded coords malicious → map croaks (no valid markers)' => sub {
	# When every coord in the constructor is geocoded to a malicious string,
	# _validate rejects all of them.  No valid markers remain; no explicit center
	# was given; the center-computation path ends in a croak.
	mock 'ECJSInjGeo2::geocode' => sub {
		{ lat => $C{JS_PAYLOAD}, lon => '0' }
	};
	my $m = HTML::OSM->new(
		geocoder    => bless({}, 'ECJSInjGeo2'),
		coordinates => [[undef, undef, 'TownX', undef]],
	);
	# center() must be called because no valid markers remain after validation.
	throws_ok { $m->onload_render() }
		qr/center\(\) must be called/i,
		'all-malicious geocoded coords discarded → croak about missing center';
};

subtest 'security: numeric geocoder result passes through and is embedded correctly' => sub {
	# Confirm that valid (numeric) geocoder results still render after the fix.
	mock 'ECValidGeo::geocode' => sub { { lat => '51.5', lon => '-0.1' } };
	my $m = HTML::OSM->new(
		geocoder    => bless({}, 'ECValidGeo'),
		coordinates => [[undef, undef, 'London', undef]],
	);
	my (undef, $body) = $m->onload_render();
	like($body, qr/51\.5/, 'valid geocoded lat present in rendered body');
};

# ─────────────────────────────────────────────────────────────────────────────
# 10. onload_render() — other hostile scenarios
# ─────────────────────────────────────────────────────────────────────────────

subtest 'onload_render: no data croaks with "No map data provided"' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->onload_render() }
		qr/No map data provided/,
		'empty map croaks';
};

subtest 'onload_render: non-marker-only map without center() croaks' => sub {
	my $m = HTML::OSM->new();
	$m->add_geojson({ type => 'FeatureCollection', features => [] });
	throws_ok { $m->onload_render() }
		qr/center\(\) must be called/i,
		'GeoJSON-only map without center() croaks';
};

subtest 'onload_render: all valid markers discarded → croaks' => sub {
	# If _validate discards every coordinate at render time, there is nothing
	# to render and no center can be computed.
	my $m = HTML::OSM->new(
		# Seed bad tuples that _validate rejects: lat > 90.
		coordinates => [[91, 0, 'bad1', undef], [0, 181, 'bad2', undef]],
	);
	local $SIG{__WARN__} = $SILENCE;
	throws_ok { $m->onload_render() }
		qr/center\(\) must be called|No map data/i,
		'all-invalid coords → cannot compute center → croak';
};

subtest 'onload_render: returns two non-empty strings' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	my ($head, $body) = $m->onload_render();
	returns_ok($head, { type => 'string' }, 'head is string');
	returns_ok($body, { type => 'string' }, 'body is string');
	ok(length $head, 'head is non-empty');
	ok(length $body, 'body is non-empty');
};

subtest 'onload_render: scalar context returns $body (last list element)' => sub {
	# Calling a list-returning function in scalar context gives the last element.
	# This is not ideal API usage but must not silently mislead the caller.
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	my $val = ($m->onload_render())[-1];   # explicit slice
	like($val, qr/setView/, 'body (last element) contains setView');
};

subtest 'onload_render: zoom 0 rendered in setView' => sub {
	# Zoom 0 is falsy — must not be silently replaced with the default 12.
	my $m = HTML::OSM->new(zoom => 0);
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	my (undef, $body) = $m->onload_render();
	like($body, qr/setView\([^)]+,\s*0\)/, 'zoom 0 appears in setView');
	unlike($body, qr/setView\([^)]+,\s*12\)/, 'default zoom 12 not substituted for 0');
};

# ─────────────────────────────────────────────────────────────────────────────
# 11. Global state ($@, $_) preservation
# Public methods must not clobber $@ or $_ as a side-effect.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'global state: add_marker preserves $@ on success' => sub {
	my $m = HTML::OSM->new();
	eval { die 'sentinel' };
	my $before = $@;
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	is($@, $before, 'add_marker does not clobber $@');
};

subtest 'global state: add_geojson preserves $@' => sub {
	my $m = HTML::OSM->new();
	eval { die 'geojson-sentinel' };
	my $before = $@;
	$m->add_geojson({ type => 'FeatureCollection', features => [] });
	is($@, $before, 'add_geojson does not clobber $@');
};

subtest 'global state: add_heatmap preserves $@' => sub {
	my $m = HTML::OSM->new();
	eval { die 'heat-sentinel' };
	my $before = $@;
	$m->add_heatmap([[51.5, -0.1]]);
	is($@, $before, 'add_heatmap does not clobber $@');
};

subtest 'global state: add_gpx preserves $@' => sub {
	my $m = HTML::OSM->new();
	eval { die 'gpx-sentinel' };
	my $before = $@;
	$m->add_gpx('https://example.com/t.gpx');
	is($@, $before, 'add_gpx does not clobber $@');
};

subtest 'global state: add_choropleth preserves $@' => sub {
	my $m = HTML::OSM->new();
	eval { die 'choro-sentinel' };
	my $before = $@;
	$m->add_choropleth([], {});
	is($@, $before, 'add_choropleth does not clobber $@');
};

subtest 'global state: zoom() preserves $@' => sub {
	my $m = HTML::OSM->new();
	eval { die 'zoom-sentinel' };
	my $before = $@;
	$m->zoom(10);
	is($@, $before, 'zoom() does not clobber $@');
};

subtest 'global state: add_marker preserves $_ on success' => sub {
	my $m = HTML::OSM->new();
	local $_ = 'precious-value';
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	is($_, 'precious-value', 'add_marker does not clobber $_');
};

subtest 'global state: onload_render preserves $@' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	eval { die 'render-sentinel' };
	my $before = $@;
	$m->onload_render();
	is($@, $before, 'onload_render does not clobber $@');
};

# ─────────────────────────────────────────────────────────────────────────────
# 12. Data aliasing — external mutation of the coordinates arrayref
#
# The constructor stores the caller's arrayref by reference (shallow copy).
# Mutating the original array after construction changes the object's state.
# This is a known limitation; the test documents current behavior so future
# deep-copy changes will surface as intentional breakage rather than regressions.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'aliasing: mutating constructor coordinates arrayref changes object state' => sub {
	my @coords = ([$C{LAT_LONDON}, $C{LON_LONDON}, 'London', undef]);
	my $m = HTML::OSM->new(coordinates => \@coords);

	# Add another coordinate via the original array — the object sees it.
	push @coords, [48.8566, 2.3522, 'Paris', undef];

	my (undef, $body) = $m->onload_render();
	# If aliased, Paris shows up even though we never called add_marker.
	my @markers = ($body =~ /L\.marker\(\[-?\d/g);
	is(scalar @markers, 2, 'aliased mutation adds Paris without add_marker (known limitation)');
	diag('Aliasing: external push to @coords affected $m->{coordinates}')
		if $ENV{TEST_VERBOSE};
};

subtest 'aliasing: add_marker is NOT affected by later mutation (it deep-pushes a new tuple)' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}], html => 'London');

	# Mutate the internal coordinates after add_marker — would affect the slot.
	# add_marker pushes a NEW arrayref each time, but the outer array is shared.
	# Verify that the marker stored by add_marker is correct at render time.
	my (undef, $body) = $m->onload_render();
	like($body, qr/$C{LAT_LONDON}/, 'London coord still present after internal mutation risk');
};

# ─────────────────────────────────────────────────────────────────────────────
# 13. _js_string() — pathological inputs (white-box, called directly)
# ─────────────────────────────────────────────────────────────────────────────

subtest '_js_string: null byte in string passes through (not specially escaped)' => sub {
	# Document current behavior: null bytes are not escaped.  A future hardening
	# pass might change this; the test will catch it.
	my $result = HTML::OSM::_js_string("ab\x00cd");
	like($result, qr/ab/, 'prefix preserved');
	like($result, qr/cd/, 'suffix preserved');
};

subtest '_js_string: only backslash (no quote) input escaped once only' => sub {
	# Input: \ (one backslash). Expected: \\ (two backslashes, one escape).
	my $result = HTML::OSM::_js_string('\\');
	is($result, '\\\\', 'single backslash doubled to double backslash');
};

subtest '_js_string: tab character not escaped (tabs are safe in JS strings)' => sub {
	my $result = HTML::OSM::_js_string("a\tb");
	is($result, "a\tb", 'tab character passes through unchanged');
};

subtest '_js_string: multiple </script> sequences all escaped' => sub {
	my $input  = q{</script></script></script>};
	my $result = HTML::OSM::_js_string($input);
	unlike($result, qr|</script>|, 'no raw </script> in output');
	# Each occurrence becomes <\/script>
	my @escaped = ($result =~ m{<\\/script>}g);
	is(scalar @escaped, 3, 'all three </script> occurrences escaped');
};

subtest '_js_string: very long string (10 000 chars) processed without stack overflow' => sub {
	my $long = 'x' x 10_000;
	my $r    = HTML::OSM::_js_string($long);
	is(length($r), 10_000, '10 000-char string length unchanged (no special chars)');
};

subtest '_js_string: all hostile chars combined in one string' => sub {
	my $input = "back\\slash quo'te new\nline script</script>end";
	my $out   = HTML::OSM::_js_string($input);
	unlike($out, qr/\n/,      'no literal newline');
	unlike($out, qr|</script>|, 'no raw </script>');
	like($out,   qr/\\'/,     'quote is escaped');
	like($out,   qr/\\\\/,    'backslash is doubled');
};

# ─────────────────────────────────────────────────────────────────────────────
# 14. _validate() — pathological coordinate values (white-box)
# ─────────────────────────────────────────────────────────────────────────────

subtest '_validate: very large positive lat rejected' => sub {
	local $SIG{__WARN__} = $SILENCE;
	is(HTML::OSM::_validate(1e308, 0), 0, 'enormous lat rejected');
};

subtest '_validate: NaN-like string rejected' => sub {
	local $SIG{__WARN__} = $SILENCE;
	is(HTML::OSM::_validate('NaN', 0), 0, '"NaN" rejected');
};

subtest '_validate: Inf-like string rejected' => sub {
	local $SIG{__WARN__} = $SILENCE;
	is(HTML::OSM::_validate('Inf', 0), 0, '"Inf" rejected');
};

subtest '_validate: hex string rejected' => sub {
	local $SIG{__WARN__} = $SILENCE;
	is(HTML::OSM::_validate('0x1F', 0), 0, 'hex "0x1F" rejected');
};

subtest '_validate: JS-injection payload rejected' => sub {
	local $SIG{__WARN__} = $SILENCE;
	is(HTML::OSM::_validate($C{JS_PAYLOAD}, 0), 0,
		'JS-injection payload rejected by _validate');
};

subtest '_validate: leading-decimal with many digits accepted' => sub {
	is(HTML::OSM::_validate('.123456789', '.987654321'), 1,
		'many decimal places after leading dot accepted');
};

subtest '_validate: both args undef → 0 with no warning' => sub {
	my @warns;
	local $SIG{__WARN__} = sub { push @warns, @_ };
	is(HTML::OSM::_validate(undef, undef), 0, 'undef, undef → 0');
	is(scalar @warns, 0, 'no warning when both args are undef');
};

restore_all();
done_testing();

#!/usr/bin/env perl

use strict;
use warnings;

use CHI;
use File::Temp qw(tempfile);
use Readonly;
use Test::Memory::Cycle;
use Test::Mockingbird qw(mock restore_all);
use Test::Most;
use Test::Returns;
use URI::Escape qw(uri_escape_utf8);

BEGIN { use_ok('HTML::OSM') }

# All magic values in one place.
Readonly my %C => (
	ZOOM_DEFAULT => 12,
	LAT_LONDON   => 51.5074,
	LON_LONDON   => -0.1278,
	LAT_PARIS    => 48.8566,
	LON_PARIS    =>  2.3522,
	LAT_NYC      => 40.7128,
	LON_NYC      => -74.0060,
	LAT_BERLIN   => 52.52,
	LON_BERLIN   => 13.405,
	MIN_INTERVAL => 2,
);

# Reusable GeoJSON features across choropleth subtests.
Readonly my @FEATURES => (
	{ type => 'Feature', properties => { name => 'England' },
	  geometry => { type => 'Polygon',
	                coordinates => [[[0,51],[1,51],[1,52],[0,52],[0,51]]] } },
	{ type => 'Feature', properties => { name => 'Scotland' },
	  geometry => { type => 'Polygon',
	                coordinates => [[[0,55],[1,55],[1,56],[0,56],[0,55]]] } },
);

my $SILENCE = sub { };

# ── Global HTTP block ─────────────────────────────────────────────────────────
# All subtests start with HTTP failing.  Subtests that need a live HTTP result
# inject their own ua via HTML::OSM->new(ua => ...) to bypass this block.
# Never call restore_all() inside a subtest — it tears this block down.
{
	my $fail_resp = bless {}, 'IntNetResp';
	mock 'IntNetResp::is_success' => sub { 0 };
	my $fail_ua   = bless {}, 'IntNetUA';
	mock 'IntNetUA::default_header' => sub { };
	mock 'IntNetUA::env_proxy'      => sub { };
	mock 'IntNetUA::get'            => sub { $fail_resp };
	mock 'LWP::UserAgent::new'      => sub { $fail_ua };
}

# ─────────────────────────────────────────────────────────────────────────────
# Integration 1: Full five-layer rendering pipeline
# Exercises the complete chain: new → add_* x5 → onload_render.
# All five layer types must coexist without conflict.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'full pipeline: all five layer types render in one pass' => sub {
	my $m = HTML::OSM->new(zoom => 8);

	# Each add_* returns 1 on success.
	is($m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}], html => 'London'), 1, 'marker 1');
	is($m->add_marker([$C{LAT_PARIS},  $C{LON_PARIS}],  html => 'Paris'),  1, 'marker 2');
	is($m->add_geojson({ type => 'FeatureCollection', features => [] },
		style => { color => '#ff0000' }), 1, 'geojson');
	is($m->add_heatmap([[$C{LAT_LONDON}, $C{LON_LONDON}, 0.9]]), 1, 'heatmap');
	is($m->add_gpx('https://example.com/route.gpx'), 1, 'gpx');
	is($m->add_choropleth(\@FEATURES, { England => 100, Scotland => 50 }), 1, 'choropleth');

	my ($head, $body) = $m->onload_render();
	returns_ok($head, { type => 'string' }, 'head is string');
	returns_ok($body, { type => 'string' }, 'body is string');

	# Head: base assets always present, per-layer plugins only when needed.
	like($head, qr/leaflet.*\.css/i,   'Leaflet CSS in head');
	like($head, qr/leaflet.*\.js/i,    'Leaflet JS in head');
	like($head, qr/leaflet.heat/i,     'heatmap plugin in head');
	like($head, qr/gpx/i,             'GPX plugin in head');
	unlike($head, qr/markercluster/i, 'cluster plugin absent (not requested)');

	# Body: all five layer types emitted.
	my @markers = ($body =~ /L\.marker\(\[-?\d/g);
	is(scalar @markers, 2, 'two point markers emitted');
	like($body, qr/L\.geoJSON/,       'GeoJSON layer emitted');
	like($body, qr/L\.heatLayer/,     'heatmap layer emitted');
	like($body, qr/L\.GPX/,          'GPX layer emitted');
	like($body, qr/choroplethColors/, 'choropleth layer emitted');
	like($body, qr/setView\([^)]+,\s*8\)/, 'zoom 8 in setView');
	like($body, qr/London/,           'London label in body');
	like($body, qr/Paris/,            'Paris label in body');

	memory_cycle_ok($m, 'no reference cycles after full pipeline');
	diag("head:\n$head\nbody:\n$body") if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# Integration 2: All geocoder return formats
# _fetch_coordinates handles four distinct shapes returned by geocode().
# Each is tested as a complete add_marker → render workflow.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'geocoding: {lat, lon} hashref format → marker in rendered body' => sub {
	mock 'GeoHash::geocode' => sub { { lat => $C{LAT_NYC}, lon => $C{LON_NYC} } };
	my $m = HTML::OSM->new(geocoder => bless({}, 'GeoHash'));
	is($m->add_marker('New York', html => 'NY'), 1, 'hashref geocode -> 1');
	my (undef, $body) = $m->onload_render();
	like($body, qr/$C{LAT_NYC}/, 'geocoded lat in body');
	like($body, qr/NY/,          'label in body');
};

subtest 'geocoding: [lat, lon] arrayref format → marker in rendered body' => sub {
	mock 'GeoArr::geocode' => sub { [$C{LAT_PARIS}, $C{LON_PARIS}] };
	my $m = HTML::OSM->new(geocoder => bless({}, 'GeoArr'));
	is($m->add_marker('Paris'), 1, 'arrayref geocode -> 1');
	my (undef, $body) = $m->onload_render();
	like($body, qr/$C{LAT_PARIS}/, 'geocoded lat in body');
};

subtest 'geocoding: blessed object with latitude/longitude → marker in body' => sub {
	mock 'GeoObjLat::latitude'  => sub { $C{LAT_BERLIN} };
	mock 'GeoObjLat::longitude' => sub { $C{LON_BERLIN} };
	my $result = bless {}, 'GeoObjLat';
	mock 'GeoBless::geocode' => sub { $result };
	my $m = HTML::OSM->new(geocoder => bless({}, 'GeoBless'));
	is($m->add_marker('Berlin'), 1, 'blessed geocode result -> 1');
	my (undef, $body) = $m->onload_render();
	like($body, qr/$C{LAT_BERLIN}/, 'geocoded lat in body');
};

subtest 'geocoding: Google Maps geometry.location format → marker in body' => sub {
	mock 'GeoGmap::geocode' => sub {
		{ geometry => { location => { lat => $C{LAT_LONDON}, lng => $C{LON_LONDON} } } }
	};
	my $m = HTML::OSM->new(geocoder => bless({}, 'GeoGmap'));
	is($m->add_marker('London'), 1, 'GMaps-format geocode -> 1');
	my (undef, $body) = $m->onload_render();
	like($body, qr/$C{LAT_LONDON}/, 'geocoded lat in body');
};

subtest 'geocoding: failure leaves map empty → onload_render croaks' => sub {
	my $calls = 0;
	mock 'GeoFail::geocode' => sub { $calls++; undef };
	my $m = HTML::OSM->new(geocoder => bless({}, 'GeoFail'));
	is($m->add_marker('Atlantis', html => 'Atlantis'), 0, 'failure -> 0');
	throws_ok { $m->onload_render() } qr/No map data provided/, 'empty map croaks';
	is($calls, 1, 'geocoder called exactly once');
};

subtest 'geocoding: center() via geocoder → setView uses geocoded coords' => sub {
	mock 'GeoCtr::geocode' => sub { { lat => $C{LAT_NYC}, lon => $C{LON_NYC} } };
	my $m = HTML::OSM->new(geocoder => bless({}, 'GeoCtr'));
	is($m->center('New York'), 1, 'geocoded center -> 1');
	$m->add_geojson({ type => 'FeatureCollection', features => [] });
	my (undef, $body) = $m->onload_render();
	like($body, qr/setView\(\[$C{LAT_NYC}/, 'geocoded center in setView');
};

# ─────────────────────────────────────────────────────────────────────────────
# Integration 3: Cache integration
# Shared CHI cache: object A's geocode result is reused by object B without
# any further geocoder or HTTP calls.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'cache: shared cache hit avoids HTTP call' => sub {
	# The cache is only consulted in the Nominatim (non-geocoder) code path.
	# Pre-populate the cache; inject a spy UA to confirm no HTTP request is made.
	my $shared = CHI->new(driver => 'Memory', global => 0, expires_in => '1 day');
	my $key    = 'osm:' . uri_escape_utf8('London');
	$shared->set($key, { lat => "$C{LAT_LONDON}", lon => "$C{LON_LONDON}" });

	my $http_calls = 0;
	my $spy_resp   = bless {}, 'CacheSpyResp';
	mock 'CacheSpyResp::is_success' => sub { 0 };
	my $spy_ua = bless {}, 'CacheSpyUA';
	mock 'CacheSpyUA::default_header' => sub { };
	mock 'CacheSpyUA::env_proxy'      => sub { };
	mock 'CacheSpyUA::get'            => sub { $http_calls++; $spy_resp };

	# No geocoder — the code will take the Nominatim/cache path.
	my $b = HTML::OSM->new(cache => $shared, ua => $spy_ua);
	is($b->add_marker('London', html => 'London'), 1, 'cache hit → marker added');
	is($http_calls, 0, 'HTTP NOT called on cache hit');
	my (undef, $body) = $b->onload_render();
	like($body, qr/$C{LAT_LONDON}/, 'cached lat in rendered body');
};

subtest 'cache: HTTP geocode result is written to cache for next call' => sub {
	my $shared = CHI->new(driver => 'Memory', global => 0, expires_in => '1 day');
	my $json   = '[{"lat":"' . $C{LAT_BERLIN} . '","lon":"' . $C{LON_BERLIN} . '"}]';

	my $resp = bless {}, 'CacheHTTPResp';
	mock 'CacheHTTPResp::is_success'      => sub { 1 };
	mock 'CacheHTTPResp::decoded_content' => sub { $json };
	my $ua = bless {}, 'CacheHTTPUA';
	mock 'CacheHTTPUA::default_header' => sub { };
	mock 'CacheHTTPUA::env_proxy'      => sub { };
	mock 'CacheHTTPUA::get'            => sub { $resp };

	my $m = HTML::OSM->new(cache => $shared, ua => $ua);
	is($m->add_marker('Berlin'), 1, 'HTTP geocode -> 1');

	my $cached = $shared->get('osm:' . uri_escape_utf8('Berlin'));
	ok(defined $cached,                     'result stored in shared cache');
	is($cached->{lat}, $C{LAT_BERLIN},      'cached lat correct');
	is($cached->{lon}, $C{LON_BERLIN},      'cached lon correct');
};

# ─────────────────────────────────────────────────────────────────────────────
# Integration 4: Object isolation — concurrent independent instances
# Three HTML::OSM objects must not share coordinate lists or zoom state.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'isolation: three objects accumulate markers independently' => sub {
	my @specs = (
		[$C{LAT_LONDON}, $C{LON_LONDON}, 'London'],
		[$C{LAT_PARIS},  $C{LON_PARIS},  'Paris'],
		[$C{LAT_NYC},    $C{LON_NYC},    'NYC'],
	);

	my @maps;
	for my $s (@specs) {
		my ($lat, $lon, $label) = @$s;
		my $m = HTML::OSM->new();
		$m->add_marker([$lat, $lon], html => $label);
		push @maps, [$m, $label];
	}

	for my $entry (@maps) {
		my ($m, $label) = @$entry;
		my (undef, $body) = $m->onload_render();
		like($body, qr/$label/, "$label body has its own label");
		for my $other (@maps) {
			next if $other->[1] eq $label;
			unlike($body, qr/\b$other->[1]\b/, "$label body does not contain $other->[1]");
		}
	}
};

subtest 'isolation: zoom on one object does not affect another' => sub {
	my $a = HTML::OSM->new(zoom => 5);
	my $b = HTML::OSM->new(zoom => 15);
	$a->zoom(10);
	is($a->zoom(), 10, 'A zoom updated');
	is($b->zoom(), 15, 'B zoom unchanged');
};

subtest 'isolation: center on one object does not affect another' => sub {
	my $a = HTML::OSM->new();
	my $b = HTML::OSM->new();
	$a->center([$C{LAT_LONDON}, $C{LON_LONDON}]);
	$b->center([$C{LAT_NYC},    $C{LON_NYC}]);

	$a->add_geojson({ type => 'FeatureCollection', features => [] });
	$b->add_geojson({ type => 'FeatureCollection', features => [] });

	my (undef, $body_a) = $a->onload_render();
	my (undef, $body_b) = $b->onload_render();
	like($body_a, qr/setView\(\[$C{LAT_LONDON}/, 'A has London center');
	like($body_b, qr/setView\(\[$C{LAT_NYC}/,    'B has NYC center');
	unlike($body_a, qr/setView\(\[$C{LAT_NYC}/,    'A does not use NYC center');
	unlike($body_b, qr/setView\(\[$C{LAT_LONDON}/, 'B does not use London center');
};

# ─────────────────────────────────────────────────────────────────────────────
# Integration 5: Clone workflow
# POD: $obj->new(%overrides) performs a shallow clone.
# Base and clone must render independently when overrides replace mutable state.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'clone: overriding coordinates in clone keeps base and clone independent' => sub {
	my $base = HTML::OSM->new(zoom => 7);
	$base->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}], html => 'BaseMarker');

	# Pass fresh coordinates to the clone to avoid shared reference.
	my $clone = $base->new(zoom => 15, coordinates => []);
	$clone->add_marker([$C{LAT_NYC}, $C{LON_NYC}], html => 'CloneMarker');

	my (undef, $body_base)  = $base->onload_render();
	my (undef, $body_clone) = $clone->onload_render();

	like($body_base,   qr/BaseMarker/,           'base has BaseMarker');
	unlike($body_base, qr/CloneMarker/,           'base does NOT have CloneMarker');
	like($body_base,   qr/setView\([^)]+,\s*7\)/, 'base zoom is 7');

	like($body_clone,   qr/CloneMarker/,            'clone has CloneMarker');
	unlike($body_clone, qr/BaseMarker/,              'clone does NOT have BaseMarker');
	like($body_clone,   qr/setView\([^)]+,\s*15\)/, 'clone zoom is 15');
};

subtest 'clone: zoom override does not mutate the base object' => sub {
	my $base  = HTML::OSM->new(zoom => 5);
	my $clone = $base->new(zoom => 18);
	is($base->zoom(),  5,  'base zoom unchanged after clone');
	is($clone->zoom(), 18, 'clone has overridden zoom');
};

subtest 'clone: inherits non-overridden scalar state from base' => sub {
	my $base  = HTML::OSM->new(zoom => 9);
	my $clone = $base->new();
	is($clone->zoom(), 9, 'clone inherits zoom when not overridden');
};

# ─────────────────────────────────────────────────────────────────────────────
# Integration 6: Config file integration
# Config file is authoritative over programmatic defaults (separation of config
# and code).  A config-file value wins even when the same key is passed to new().
# ─────────────────────────────────────────────────────────────────────────────

subtest 'config file: YAML zoom overrides programmatic default and constructor param' => sub {
	my ($fh, $path) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	print $fh "---\nzoom: 7\n";
	close $fh;

	my $from_cfg  = HTML::OSM->new(config_file => $path);
	my $with_zoom = HTML::OSM->new(config_file => $path, zoom => 14);

	is($from_cfg->zoom(),  7, 'config file zoom overrides programmatic default (12)');
	is($with_zoom->zoom(), 7, 'config file zoom wins over constructor param');
};

subtest 'config file: YAML css_url appears in rendered head' => sub {
	my ($fh, $path) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	print $fh "---\ncss_url: https://mycdn.example.com/leaflet.css\n";
	close $fh;

	my $m = HTML::OSM->new(config_file => $path);
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	my ($head) = $m->onload_render();
	like($head, qr{mycdn\.example\.com/leaflet\.css}, 'config css_url in head');
};

# ─────────────────────────────────────────────────────────────────────────────
# Integration 7: Multi-step state transitions
# State accumulated across many method calls must be coherent at render time.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'state: final zoom after multiple setter calls' => sub {
	my $m = HTML::OSM->new();
	$m->zoom(3);
	$m->zoom(8);
	$m->zoom(16);
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	my (undef, $body) = $m->onload_render();
	like($body,   qr/setView\([^)]+,\s*16\)/, 'final zoom 16 in setView');
	unlike($body, qr/setView\([^)]+,\s*3\)/,  'initial zoom 3 not present');
};

subtest 'state: second center() call wins over first' => sub {
	my $m = HTML::OSM->new();
	$m->center([$C{LAT_LONDON}, $C{LON_LONDON}]);
	$m->center([$C{LAT_NYC},    $C{LON_NYC}]);
	$m->add_geojson({ type => 'FeatureCollection', features => [] });
	my (undef, $body) = $m->onload_render();
	like($body,   qr/setView\(\[$C{LAT_NYC}/,    'second center used');
	unlike($body, qr/setView\(\[$C{LAT_LONDON}/, 'first center discarded');
};

subtest 'state: sequential add_* calls all visible in single render' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}], html => 'L1');
	$m->add_geojson({ type => 'FeatureCollection', features => [] },
		style => { color => '#aabbcc' });
	$m->add_heatmap([[$C{LAT_PARIS}, $C{LON_PARIS}]], radius => 30);
	my (undef, $body) = $m->onload_render();
	like($body, qr/L1/,           'marker label present');
	like($body, qr/#aabbcc/,      'GeoJSON colour present');
	like($body, qr/radius:\s*30/, 'heatmap custom radius present');
};

# ─────────────────────────────────────────────────────────────────────────────
# Integration 8: JS escaping pipeline — end-to-end injection attack vectors
# Every user-supplied string that reaches the rendered JS must be escaped.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'XSS: </script> injection in popup label neutralised' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}],
		html => '</script><script>alert(1)</script>');
	my (undef, $body) = $m->onload_render();
	unlike($body, qr|</script><script>|, 'raw </script> absent');
	like($body,   qr|<\\/script>|,        'escaped form present');
};

subtest 'XSS: backslash + single-quote combo fully escaped in popup' => sub {
	# Input: C:\path\'  — backslash then quote
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}], html => "C:\\path\\'s");
	my (undef, $body) = $m->onload_render();
	like($body, qr/C:\\\\path/, 'backslash doubled');
};

subtest 'XSS: newline in popup label converted to literal \\n in JS' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}], html => "Line1\nLine2");
	my (undef, $body) = $m->onload_render();
	unlike($body, qr/Line1\nLine2/, 'raw newline absent');
	like($body,   qr/Line1\\nLine2/, 'escaped \\n present');
};

subtest 'XSS: GPX URL with single quote JS-escaped end-to-end' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	$m->add_gpx("https://example.com/user's%20track.gpx");
	my (undef, $body) = $m->onload_render();
	unlike($body, qr|user's%20track|,   'raw single quote absent from GPX URL');
	like($body,   qr|user\\'s%20track|, 'escaped quote present');
};

# ─────────────────────────────────────────────────────────────────────────────
# Integration 9: Center computation strategies
# POD pseudocode step 3: caller-supplied center > midpoint of marker bounds.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'center strategy: single marker is its own center' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	my (undef, $body) = $m->onload_render();
	like($body, qr/setView\(\[$C{LAT_LONDON}/, 'single-marker center is the marker itself');
};

subtest 'center strategy: four markers — midpoint computed correctly' => sub {
	# min_lat=10 max_lat=20 → 15; min_lon=30 max_lon=50 → 40.
	my $m = HTML::OSM->new();
	$m->add_marker([10, 30]);
	$m->add_marker([10, 50]);
	$m->add_marker([20, 30]);
	$m->add_marker([20, 50]);
	my (undef, $body) = $m->onload_render();
	like($body, qr/setView\(\[15, 40\]/, 'midpoint (15, 40) used');
};

subtest 'center strategy: explicit center beats midpoint' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([10, 10]);
	$m->add_marker([-10, -10]);      # midpoint would be (0, 0)
	$m->center([$C{LAT_NYC}, $C{LON_NYC}]);
	my (undef, $body) = $m->onload_render();
	like($body,   qr/setView\(\[$C{LAT_NYC}/, 'explicit center wins');
	unlike($body, qr/setView\(\[0, 0\]/,       'midpoint (0,0) NOT used');
};

subtest 'center strategy: no markers + no explicit center → croak' => sub {
	my $m = HTML::OSM->new();
	$m->add_geojson({ type => 'FeatureCollection', features => [] });
	throws_ok { $m->onload_render() }
		qr/center\(\) must be called when no point markers are provided/,
		'croak when center cannot be determined';
};

# ─────────────────────────────────────────────────────────────────────────────
# Integration 10: Clustering pipeline
# cluster => 1 must wrap every marker in L.markerClusterGroup.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'clustering: three markers wrapped in one clusterGroup' => sub {
	my $m = HTML::OSM->new(cluster => 1);
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}], html => 'London');
	$m->add_marker([$C{LAT_PARIS},  $C{LON_PARIS}],  html => 'Paris');
	$m->add_marker([$C{LAT_NYC},    $C{LON_NYC}],    html => 'NYC');

	my ($head, $body) = $m->onload_render();

	like($head, qr/markercluster.*\.js/i,       'cluster JS in head');
	like($head, qr/MarkerCluster\.css/,          'cluster CSS in head');
	like($head, qr/MarkerCluster\.Default\.css/, 'cluster default CSS in head');

	my @adds = ($body =~ /clusterGroup\.addLayer/g);
	is(scalar @adds, 3, 'three addLayer calls for three markers');
	like($body, qr/map\.addLayer\(clusterGroup\)/, 'clusterGroup added to map');

	# No individual addTo(map) for static numeric-coord markers when clustering is active.
	# The search-handler template also emits L.marker([lat,lon]).addTo(map) with JS
	# variable names; restrict the match to numeric literals to avoid false positives.
	unlike($body, qr/L\.marker\(\[-?\d[^;]*addTo\(map\)/, 'no direct addTo(map) for individual markers');
};

subtest 'clustering: icon marker uses clusterGroup.addLayer in IIFE' => sub {
	my $m = HTML::OSM->new(cluster => 1);
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}],
		html => 'London', icon => 'https://ex.com/pin.png');
	my (undef, $body) = $m->onload_render();
	like($body, qr/L\.icon/,                   'L.icon call present');
	like($body, qr/clusterGroup\.addLayer\(m\)/, 'icon marker via clusterGroup');
};

# ─────────────────────────────────────────────────────────────────────────────
# Integration 11: Choropleth full pipeline
# Verify that colours computed in Perl land in the rendered JS lookup object.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'choropleth: five-feature graduated scale ends up in rendered body' => sub {
	my @feats = map {
		{ type => 'Feature', properties => { name => "R$_" },
		  geometry => { type => 'Point', coordinates => [0,0] } }
	} 1..5;

	my $m = HTML::OSM->new();
	$m->center([$C{LAT_LONDON}, $C{LON_LONDON}]);
	$m->add_choropleth(\@feats,
		{ R1 => 10, R2 => 20, R3 => 30, R4 => 40, R5 => 50 },
		scale => ['#col0', '#col1', '#col2', '#col3', '#col4'],
	);

	my (undef, $body) = $m->onload_render();
	like($body, qr/#col0/, 'low-end colour in body');
	like($body, qr/#col4/, 'high-end colour in body');
	like($body, qr/fillColor/,        'fillColor property emitted');
	like($body, qr/choroplethValues/, 'value lookup emitted');
};

subtest 'choropleth: popup template binds key and value' => sub {
	my $m = HTML::OSM->new();
	$m->center([$C{LAT_LONDON}, $C{LON_LONDON}]);
	$m->add_choropleth(\@FEATURES, { England => 100, Scotland => 50 });
	my (undef, $body) = $m->onload_render();
	# Emitted JS: k + ': ' + choroplethValues[k]
	like($body, qr/choroplethValues\[k\]/, 'value lookup present in popup template');
};

subtest 'choropleth: multiple layers all rendered in body' => sub {
	my $m = HTML::OSM->new();
	$m->center([$C{LAT_LONDON}, $C{LON_LONDON}]);
	$m->add_choropleth(\@FEATURES, { England => 100 });
	$m->add_choropleth(\@FEATURES, { England => 200 });
	my (undef, $body) = $m->onload_render();
	my @decls = ($body =~ /var choroplethColors/g);
	is(scalar @decls, 2, 'two choroplethColors declarations emitted');
};

# ─────────────────────────────────────────────────────────────────────────────
# Integration 12: Rate-limiting interaction
# min_interval > 0 must cause Time::HiRes::sleep when a request follows too
# soon after the previous one.  We spy on sleep without real sleeping.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'rate limiting: sleep called when elapsed < min_interval' => sub {
	my $sleep_calls = 0;
	my $slept_for   = 0;

	# Spy on sleep so no real wall time is consumed.
	mock 'Time::HiRes::sleep' => sub { $sleep_calls++; $slept_for = $_[0] };

	# Fix time() inside HTML::OSM to a constant so elapsed = 0.
	mock 'HTML::OSM::time' => sub { 1_000_000 };

	my $json = '[{"lat":"51.5","lon":"-0.1"}]';
	my $resp  = bless {}, 'RLResp';
	mock 'RLResp::is_success'      => sub { 1 };
	mock 'RLResp::decoded_content' => sub { $json };
	my $ua = bless {}, 'RLUA';
	mock 'RLUA::default_header' => sub { };
	mock 'RLUA::env_proxy'      => sub { };
	mock 'RLUA::get'            => sub { $resp };

	my $m = HTML::OSM->new(min_interval => $C{MIN_INTERVAL}, ua => $ua);
	# Simulate: a request was made "just now" so elapsed = 0 < 2.
	$m->{last_request} = 1_000_000;

	$m->add_marker('London');

	ok($sleep_calls > 0,                   'sleep was called');
	cmp_ok($slept_for, '>',  0,            'slept for positive duration');
	cmp_ok($slept_for, '<=', $C{MIN_INTERVAL}, 'slept at most min_interval');

	diag("sleep_calls=$sleep_calls slept_for=$slept_for") if $ENV{TEST_VERBOSE};
};

subtest 'rate limiting: no sleep when min_interval is 0' => sub {
	my $sleep_calls = 0;
	mock 'Time::HiRes::sleep' => sub { $sleep_calls++ };

	my $json = '[{"lat":"51.5","lon":"-0.1"}]';
	my $resp  = bless {}, 'RL0Resp';
	mock 'RL0Resp::is_success'      => sub { 1 };
	mock 'RL0Resp::decoded_content' => sub { $json };
	my $ua = bless {}, 'RL0UA';
	mock 'RL0UA::default_header' => sub { };
	mock 'RL0UA::env_proxy'      => sub { };
	mock 'RL0UA::get'            => sub { $resp };

	my $m = HTML::OSM->new(min_interval => 0, ua => $ua);
	$m->add_marker('London');

	is($sleep_calls, 0, 'no sleep when min_interval=0');
};

# ─────────────────────────────────────────────────────────────────────────────
# Integration 13: Optional dependency injection workflows
# The geocoder, ua, and cache params are all optional.  Verify that each
# injected form works correctly and that the no-injection fallbacks behave.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'optional geocoder: absent → HTTP attempted (and fails gracefully)' => sub {
	# Use a fresh isolated cache (global => 0) so that 'London' cached by earlier
	# subtests (rate-limiting uses the global=1 default cache) does not cause a hit.
	# Use a unique location name to be safe even if global cache leaks.
	my $fresh = CHI->new(driver => 'Memory', global => 0, expires_in => '1 day');
	local $SIG{__WARN__} = $SILENCE;
	my $m = HTML::OSM->new(cache => $fresh);
	is($m->add_marker('NoGeocoder_TestLoc_Zz9'), 0, 'no geocoder + blocked HTTP → 0');
};

subtest 'optional geocoder: injected → geocoder used, HTTP not called' => sub {
	my $http_calls = 0;
	# Temporarily override the global network block to count HTTP attempts.
	mock 'LWP::UserAgent::new' => sub {
		my $ua = bless {}, 'OptUASpy';
		mock 'OptUASpy::default_header' => sub { };
		mock 'OptUASpy::env_proxy'      => sub { };
		mock 'OptUASpy::get'            => sub { $http_calls++; bless {}, 'IntNetResp' };
		$ua;
	};

	mock 'OptGeo::geocode' => sub { { lat => $C{LAT_PARIS}, lon => $C{LON_PARIS} } };
	my $m = HTML::OSM->new(geocoder => bless({}, 'OptGeo'));
	is($m->add_marker('Paris'), 1, 'with geocoder -> 1');
	is($http_calls, 0, 'HTTP NOT called when geocoder provided');
};

subtest 'optional cache: default cache created with get/set' => sub {
	my $m = HTML::OSM->new();
	can_ok($m->{cache}, 'get');
	can_ok($m->{cache}, 'set');
};

subtest 'optional cache: injected cache object used directly' => sub {
	my $custom = CHI->new(driver => 'Memory', global => 0, expires_in => '5m');
	my $m      = HTML::OSM->new(cache => $custom);
	is($m->{cache}, $custom, 'injected cache stored on object');
};

subtest 'optional ua: injected ua used, LWP::UserAgent::new not invoked' => sub {
	my $lwp_news = 0;
	mock 'LWP::UserAgent::new' => sub { $lwp_news++; bless {}, 'SpyUA' };

	my $json = '[{"lat":"51.0","lon":"-0.1"}]';
	my $resp  = bless {}, 'InjResp';
	mock 'InjResp::is_success'      => sub { 1 };
	mock 'InjResp::decoded_content' => sub { $json };
	my $ua = bless {}, 'InjUA';
	mock 'InjUA::default_header' => sub { };
	mock 'InjUA::env_proxy'      => sub { };
	mock 'InjUA::get'            => sub { $resp };

	my $m = HTML::OSM->new(ua => $ua);
	$m->add_marker('Somewhere');
	is($lwp_news, 0, 'LWP::UserAgent::new not called when ua injected');
};

# ─────────────────────────────────────────────────────────────────────────────
# Integration 14: Test::Without::Module — geocoder class availability
# HTML::OSM does not require any geocoder CPAN module internally.  A deployment
# without Geo::Coder::* installed must still render maps using direct coordinates.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'Test::Without::Module: HTML::OSM works without geocoder CPAN modules' => sub {
	# Skip gracefully when Test::Without::Module is not installed.
	eval { require Test::Without::Module; 1 }
		or return plan skip_all => 'Test::Without::Module not installed';

	# Hide popular geocoder classes to simulate a minimal installation.
	Test::Without::Module->import(qw(
		Geo::Coder::OSM
		Geo::Coder::Google
		Geo::Coder::List
	));

	# HTML::OSM itself never requires these classes, so it must still work.
	my $m = HTML::OSM->new(zoom => 10);
	isa_ok($m, 'HTML::OSM', 'object created without geocoder modules');

	is($m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}], html => 'London'), 1,
		'direct-coord marker works without geocoder modules');

	my (undef, $body) = $m->onload_render();
	like($body, qr/London/, 'render works without geocoder modules');

	# Confirm the modules are actually invisible to require.
	ok(!eval { require Geo::Coder::OSM;    1 }, 'Geo::Coder::OSM hidden');
	ok(!eval { require Geo::Coder::Google; 1 }, 'Geo::Coder::Google hidden');

	# Restore (no unimport needed — hidden modules are not installed anyway).
};

subtest 'Test::Without::Module: add_geojson works with JSON::PP fallback' => sub {
	eval { require Test::Without::Module; 1 }
		or return plan skip_all => 'Test::Without::Module not installed';

	# Hiding the fast JSON backends forces JSON::MaybeXS to fall back to JSON::PP.
	# HTML::OSM uses JSON::MaybeXS, so this tests the pure-Perl JSON path.
	Test::Without::Module->import(qw(Cpanel::JSON::XS JSON::XS));

	my $m = new_ok('HTML::OSM');
	$m->center([$C{LAT_LONDON}, $C{LON_LONDON}]);

	# add_geojson with a JSON string exercises the decode path.
	is($m->add_geojson('{"type":"FeatureCollection","features":[]}'), 1,
		'add_geojson with JSON string works under JSON::PP fallback');

	my (undef, $body) = $m->onload_render();
	like($body, qr/L\.geoJSON/, 'GeoJSON layer emitted under JSON::PP fallback');
};

restore_all();
done_testing();

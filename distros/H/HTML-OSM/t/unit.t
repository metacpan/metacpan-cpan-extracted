#!/usr/bin/env perl

use strict;
use warnings;

use File::Temp qw(tempfile);
use Readonly;
use Test::Memory::Cycle;
use Test::Mockingbird qw(mock restore_all);
use Test::Most;
use Test::Returns;

BEGIN { use_ok('HTML::OSM') }

# All magic values in one place so a module-default change is a one-line fix.
Readonly my %C => (
	ZOOM_DEFAULT => 12,
	ZOOM_MIN     => 0,
	ZOOM_MAX     => 19,
	HEIGHT_DEF   => '400px',
	WIDTH_DEF    => '600px',
	LAT_LONDON   => 51.5074,
	LON_LONDON   => -0.1278,
	LAT_PARIS    => 48.8566,
	LON_PARIS    =>  2.3522,
	LAT_NYC      => 40.7128,
	LON_NYC      => -74.0060,
);

# Reusable GeoJSON features shared across choropleth subtests.
Readonly my @FEATURES => (
	{ type => 'Feature', properties => { name => 'England' },
	  geometry => { type => 'Polygon',
	                coordinates => [[[0,51],[1,51],[1,52],[0,52],[0,51]]] } },
	{ type => 'Feature', properties => { name => 'Scotland' },
	  geometry => { type => 'Polygon',
	                coordinates => [[[0,55],[1,55],[1,56],[0,56],[0,55]]] } },
);

# Silence warnings in error-path tests so TAP output stays clean.
my $SILENCE = sub { };

# ── Global HTTP block ─────────────────────────────────────────────────────────
# Intercept LWP::UserAgent::new for the whole file so no subtest accidentally
# touches the network.  Per-subtest UA injection uses HTML::OSM->new(ua => …)
# which bypasses this.  Do NOT call restore_all() in individual subtests or
# this block will be torn down.
{
	my $fail_resp = bless {}, 'UnitNetResp';
	mock 'UnitNetResp::is_success' => sub { 0 };
	my $fail_ua = bless {}, 'UnitNetUA';
	mock 'UnitNetUA::default_header' => sub { };
	mock 'UnitNetUA::env_proxy'      => sub { };
	mock 'UnitNetUA::get'            => sub { $fail_resp };
	mock 'LWP::UserAgent::new'       => sub { $fail_ua };
}

# ─────────────────────────────────────────────────────────────────────────────
# new()
# POD contract: method-style, function-style, and clone-style all return an
# HTML::OSM object.  Schema validation rejects unknown or out-of-range params.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'new: method-style returns HTML::OSM' => sub {
	my $m = HTML::OSM->new();
	isa_ok($m, 'HTML::OSM');
	returns_ok($m, { type => 'object', isa => 'HTML::OSM' }, 'isa HTML::OSM');
	memory_cycle_ok($m, 'no reference cycles in new object');
};

subtest 'new: function-style HTML::OSM::new() returns HTML::OSM' => sub {
	my $m = HTML::OSM::new();
	isa_ok($m, 'HTML::OSM', 'function-style call');
};

subtest 'new: function-style with named args' => sub {
	my $m = HTML::OSM::new(zoom => 8);
	is($m->zoom(), 8, 'zoom arg reflected via public zoom() getter');
};

subtest 'new: default zoom is 12, accessible via zoom()' => sub {
	my $m = HTML::OSM->new();
	is($m->zoom(), $C{ZOOM_DEFAULT}, 'default zoom = 12');
};

subtest 'new: zoom min boundary (0) accepted' => sub {
	my $m = HTML::OSM->new(zoom => $C{ZOOM_MIN});
	is($m->zoom(), $C{ZOOM_MIN}, 'zoom 0 stored');
};

subtest 'new: zoom max boundary (19) accepted' => sub {
	my $m = HTML::OSM->new(zoom => $C{ZOOM_MAX});
	is($m->zoom(), $C{ZOOM_MAX}, 'zoom 19 stored');
};

subtest 'new: zoom out of range dies' => sub {
	dies_ok { HTML::OSM->new(zoom => -1)  } 'zoom -1 dies';
	dies_ok { HTML::OSM->new(zoom => 20)  } 'zoom 20 dies';
	dies_ok { HTML::OSM->new(zoom => 'x') } 'non-integer zoom dies';
};

subtest 'new: unknown param rejected by schema' => sub {
	dies_ok { HTML::OSM->new(no_such_param => 1) } 'unknown param dies';
};

subtest 'new: invalid coordinates param rejected' => sub {
	dies_ok { HTML::OSM->new(coordinates => 'string') } 'string coordinates die';
};

subtest 'new: CDN URL override appears in rendered head' => sub {
	my $m = HTML::OSM->new(css_url => 'https://my.cdn/leaflet.css');
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	my ($head) = $m->onload_render();
	like($head, qr{my\.cdn/leaflet\.css}, 'overridden css_url in rendered head');
};

subtest 'new: custom width and height appear in rendered CSS' => sub {
	my $m = HTML::OSM->new(width => '900px', height => '550px');
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	my ($head) = $m->onload_render();
	like($head, qr/900px/, 'custom width in rendered CSS');
	like($head, qr/550px/, 'custom height in rendered CSS');
};

subtest 'new: cluster => 1 causes cluster assets in rendered head' => sub {
	my $m = HTML::OSM->new(cluster => 1);
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	my ($head) = $m->onload_render();
	like($head, qr/markercluster/i, 'cluster JS present with cluster => 1');
};

subtest 'new: config_file YAML is loaded and overrides defaults' => sub {
	my ($fh, $path) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	print $fh "---\nzoom: 7\n";
	close $fh;
	my $m = HTML::OSM->new(config_file => $path);
	is($m->zoom(), 7, 'zoom loaded from YAML config file');
};

subtest 'new: clone via $obj->new() returns HTML::OSM with merged overrides' => sub {
	my $base  = HTML::OSM->new(zoom => 5);
	my $clone = $base->new(zoom => 15);
	isa_ok($clone, 'HTML::OSM', 'clone isa HTML::OSM');
	returns_ok($clone, { type => 'object', isa => 'HTML::OSM' }, 'clone return type');
	is($clone->zoom(), 15, 'clone has overridden zoom');
};

subtest 'new: clone inherits non-overridden state from original' => sub {
	my $base  = HTML::OSM->new(zoom => 5);
	my $clone = $base->new();
	is($clone->zoom(), 5, 'clone inherits zoom when not overridden');
};

subtest 'new: clone is a distinct object from the original' => sub {
	my $base  = HTML::OSM->new();
	my $clone = $base->new(zoom => 9);
	isnt("$clone", "$base", 'clone and base are different references');
};

# ─────────────────────────────────────────────────────────────────────────────
# zoom()
# POD: zoom([$level]) — getter returns current level; setter validates [0,19].
# ─────────────────────────────────────────────────────────────────────────────

subtest 'zoom: getter returns integer' => sub {
	my $m = HTML::OSM->new();
	my $z = $m->zoom();
	is($z, $C{ZOOM_DEFAULT}, 'getter returns default 12');
	returns_ok($z, { type => 'integer' }, 'return type is integer');
};

subtest 'zoom: setter changes level; getter reflects it' => sub {
	my $m = HTML::OSM->new();
	$m->zoom(10);
	is($m->zoom(), 10, 'getter sees updated zoom');
};

subtest 'zoom: setter return value equals the new zoom' => sub {
	my $m = HTML::OSM->new();
	my $ret = $m->zoom(7);
	is($ret, 7, 'setter returns the zoom level just set');
	returns_ok($ret, { type => 'integer' }, 'setter return type is integer');
};

subtest 'zoom: boundary 0 accepted' => sub {
	my $m = HTML::OSM->new();
	$m->zoom($C{ZOOM_MIN});
	is($m->zoom(), $C{ZOOM_MIN}, 'zoom 0 valid');
};

subtest 'zoom: boundary 19 accepted' => sub {
	my $m = HTML::OSM->new();
	$m->zoom($C{ZOOM_MAX});
	is($m->zoom(), $C{ZOOM_MAX}, 'zoom 19 valid');
};

subtest 'zoom: out-of-range dies' => sub {
	my $m = HTML::OSM->new();
	dies_ok { $m->zoom(-1) } 'zoom -1 dies';
	dies_ok { $m->zoom(20) } 'zoom 20 dies';
};

subtest 'zoom: non-integer dies' => sub {
	my $m = HTML::OSM->new();
	dies_ok { $m->zoom('high') } 'string zoom dies';
	dies_ok { $m->zoom(3.5)   } 'float zoom dies';
};

# Verify that zoom() actually drives the setView() call — not just stored internally.
subtest 'zoom: updated value appears in rendered setView' => sub {
	my $m = HTML::OSM->new();
	$m->zoom(15);
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	my (undef, $body) = $m->onload_render();
	like($body, qr/setView\([^)]+,\s*15\)/, 'zoom 15 in setView call');
};

# ─────────────────────────────────────────────────────────────────────────────
# add_marker()
# POD: returns 1 on success, 0 if the point cannot be resolved or is OOR.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'add_marker: [lat, lon] arrayref returns 1' => sub {
	my $m = HTML::OSM->new();
	my $r = $m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	is($r, 1, 'success -> 1');
	returns_ok($r, { type => 'integer' }, 'return type is integer');
};

subtest 'add_marker: html option accepted with arrayref' => sub {
	my $m = HTML::OSM->new();
	is($m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}], html => 'London'), 1, 'html option -> 1');
};

subtest 'add_marker: icon option accepted with arrayref' => sub {
	my $m = HTML::OSM->new();
	is($m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}], icon => 'https://ex.com/p.png'), 1,
		'icon option -> 1');
};

subtest 'add_marker: out-of-range coords return 0' => sub {
	my $m = HTML::OSM->new();
	local $SIG{__WARN__} = $SILENCE;
	my $r = $m->add_marker([999, 999]);
	is($r, 0, 'OOR -> 0');
	returns_ok($r, { type => 'integer' }, 'return type is integer');
};

subtest 'add_marker: [undef, undef] returns 0' => sub {
	my $m = HTML::OSM->new();
	is($m->add_marker([undef, undef]), 0, 'undef coords -> 0');
};

subtest 'add_marker: 3-element arrayref returns 0' => sub {
	my $m = HTML::OSM->new();
	is($m->add_marker([1, 2, 3]), 0, 'wrong-length -> 0');
};

subtest 'add_marker: empty arrayref returns 0' => sub {
	my $m = HTML::OSM->new();
	is($m->add_marker([]), 0, 'empty -> 0');
};

subtest 'add_marker: single-element arrayref treated as address, geocoder called' => sub {
	mock 'UnitSingleGeo::geocode' => sub { { lat => $C{LAT_PARIS}, lon => $C{LON_PARIS} } };
	my $m = HTML::OSM->new(geocoder => bless({}, 'UnitSingleGeo'));
	is($m->add_marker(['Paris, France']), 1, '["addr"] geocoded -> 1');
};

subtest 'add_marker: geo object with latitude/longitude methods returns 1' => sub {
	mock 'UnitGeoObj::latitude'  => sub { $C{LAT_NYC} };
	mock 'UnitGeoObj::longitude' => sub { $C{LON_NYC} };
	my $m = HTML::OSM->new();
	is($m->add_marker(bless({}, 'UnitGeoObj')), 1, 'geo object -> 1');
};

subtest 'add_marker: string address resolved by geocoder returns 1' => sub {
	mock 'UnitStrGeo::geocode' => sub { { lat => $C{LAT_PARIS}, lon => $C{LON_PARIS} } };
	my $m = HTML::OSM->new(geocoder => bless({}, 'UnitStrGeo'));
	is($m->add_marker('Paris, France', html => 'Paris'), 1, 'string address -> 1');
};

subtest 'add_marker: geocode failure returns 0' => sub {
	mock 'UnitGeoFail::geocode' => sub { undef };
	my $m = HTML::OSM->new(geocoder => bless({}, 'UnitGeoFail'));
	is($m->add_marker('Nowhere'), 0, 'geocode fail -> 0');
};

# POD MESSAGES: "add_marker(): unknown point type"
subtest 'add_marker: unknown ref type croaks with exact POD message' => sub {
	my $m   = HTML::OSM->new();
	my $bad = bless {}, 'UnitUnknownRef';
	throws_ok { $m->add_marker($bad) }
		qr/add_marker\(\): unknown point type: UnitUnknownRef/,
		'exact croak per POD MESSAGES table';
};

# Verify the markers actually appear in the rendered HTML (not just stored internally).
subtest 'add_marker: multiple markers appear in rendered body' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}], html => 'London');
	$m->add_marker([$C{LAT_PARIS},  $C{LON_PARIS}],  html => 'Paris');
	my (undef, $body) = $m->onload_render();
	like($body, qr/$C{LAT_LONDON}/, 'London lat in body');
	like($body, qr/$C{LAT_PARIS}/,  'Paris lat in body');
	# Match only markers with numeric coordinates — the search handler uses
	# variable names [lat, lon] not literals, so it won't match.
	my @calls = ($body =~ /L\.marker\(\[-?\d/g);
	is(scalar @calls, 2, 'exactly two L.marker calls with numeric coords emitted');
};

subtest 'add_marker: out-of-range marker does not appear in rendered body' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);      # valid — provides center
	{ local $SIG{__WARN__} = $SILENCE;
	  $m->add_marker([999, 999], html => 'ImpossiblePlace'); }
	my (undef, $body) = $m->onload_render();
	unlike($body, qr/ImpossiblePlace/, 'invalid label absent from body');
};

subtest 'add_marker: html popup label appears in bindPopup in rendered body' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}], html => 'My London Label');
	my (undef, $body) = $m->onload_render();
	like($body, qr/My London Label/, 'popup label in bindPopup');
};

subtest 'add_marker: icon URL triggers L.icon in rendered body' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}], icon => 'https://ex.com/pin.png');
	my (undef, $body) = $m->onload_render();
	like($body, qr/L\.icon/,                 'L.icon call present');
	like($body, qr|ex\.com/pin\.png|,        'icon URL present');
};

subtest 'add_marker: does not clobber $@ on success' => sub {
	my $m = HTML::OSM->new();
	eval { die 'sentinel' };
	my $before = $@;
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	is($@, $before, 'add_marker preserves $@');
};

# ─────────────────────────────────────────────────────────────────────────────
# center()
# POD: returns 1 on success, 0 if point cannot be resolved.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'center: [lat, lon] arrayref returns 1' => sub {
	my $m = HTML::OSM->new();
	my $r = $m->center([$C{LAT_LONDON}, $C{LON_LONDON}]);
	is($r, 1, 'success -> 1');
	returns_ok($r, { type => 'integer' }, 'return type is integer');
};

# POD MESSAGES: "center(): usage: point => [lat, lon]"
subtest 'center: no args dies mentioning center (POD MESSAGES)' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->center() } qr/center/i, 'no-arg croak mentions center';
};

# POD MESSAGES: "center(): point must have latitude & longitude"
subtest 'center: one-element arrayref croaks with exact POD message' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->center([51.5]) }
		qr/center\(\): point must have latitude and longitude/,
		'wrong-length croak per POD MESSAGES table';
};

subtest 'center: three-element arrayref croaks with exact POD message' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->center([51.5, -0.1, 0]) }
		qr/center\(\): point must have latitude and longitude/,
		'three-element croak per POD MESSAGES table';
};

subtest 'center: out-of-range coords return 0' => sub {
	my $m = HTML::OSM->new();
	local $SIG{__WARN__} = $SILENCE;
	my $r = $m->center([999, 0]);
	is($r, 0, 'OOR -> 0');
	returns_ok($r, { type => 'integer' }, 'return type is integer');
};

subtest 'center: geo object with latitude/longitude methods returns 1' => sub {
	mock 'UnitCtrObj::latitude'  => sub { $C{LAT_PARIS} };
	mock 'UnitCtrObj::longitude' => sub { $C{LON_PARIS} };
	my $m = HTML::OSM->new();
	is($m->center(bless({}, 'UnitCtrObj')), 1, 'geo object -> 1');
};

subtest 'center: string address via geocoder returns 1' => sub {
	mock 'UnitCtrGeo::geocode' => sub { { lat => $C{LAT_NYC}, lon => $C{LON_NYC} } };
	my $m = HTML::OSM->new(geocoder => bless({}, 'UnitCtrGeo'));
	is($m->center('New York'), 1, 'geocoded center -> 1');
};

subtest 'center: geocode failure returns 0' => sub {
	mock 'UnitCtrFail::geocode' => sub { undef };
	my $m = HTML::OSM->new(geocoder => bless({}, 'UnitCtrFail'));
	is($m->center('Nowhere'), 0, 'geocode fail -> 0');
};

# POD MESSAGES: "center(): unknown point type"
subtest 'center: unknown ref type croaks with exact POD message' => sub {
	my $m   = HTML::OSM->new();
	my $bad = bless {}, 'UnitCtrUnknown';
	throws_ok { $m->center($bad) }
		qr/center\(\): unknown point type: UnitCtrUnknown/,
		'exact croak per POD MESSAGES table';
};

# Verify that center() actually drives the setView() lat/lon in rendered output.
subtest 'center: set value appears in rendered setView lat' => sub {
	my $m = HTML::OSM->new();
	$m->center([$C{LAT_NYC}, $C{LON_NYC}]);
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	my (undef, $body) = $m->onload_render();
	like($body, qr/setView\(\[$C{LAT_NYC}/, 'explicit center lat in setView');
};

# POD PSEUDOCODE step 3: "caller-supplied > computed midpoint"
subtest 'center: explicit center overrides marker midpoint' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([10, 20]);
	$m->add_marker([-10, -20]);   # midpoint would be (0, 0)
	$m->center([$C{LAT_NYC}, $C{LON_NYC}]);
	my (undef, $body) = $m->onload_render();
	like($body,   qr/setView\(\[$C{LAT_NYC}/, 'explicit center wins');
	unlike($body, qr/setView\(\[0, 0\]/,      'midpoint NOT used');
};

# ─────────────────────────────────────────────────────────────────────────────
# add_geojson()
# POD: returns 1 on success; first arg may be hashref, arrayref, or JSON string.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'add_geojson: pre-parsed hashref returns 1' => sub {
	my $m = HTML::OSM->new();
	my $r = $m->add_geojson({ type => 'FeatureCollection', features => [] });
	is($r, 1, 'success -> 1');
	returns_ok($r, { type => 'integer' }, 'return type is integer');
};

subtest 'add_geojson: JSON string returns 1' => sub {
	my $m = HTML::OSM->new();
	is($m->add_geojson('{"type":"FeatureCollection","features":[]}'), 1, 'JSON string -> 1');
};

subtest 'add_geojson: invalid JSON dies' => sub {
	my $m = HTML::OSM->new();
	dies_ok { $m->add_geojson('not json') } 'malformed JSON dies';
};

subtest 'add_geojson: style colour appears in rendered body' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	$m->add_geojson({ type => 'FeatureCollection', features => [] },
		style => { color => '#abcdef' });
	my (undef, $body) = $m->onload_render();
	like($body, qr/#abcdef/,   'style colour in body');
	like($body, qr/L\.geoJSON/, 'L.geoJSON call in body');
};

subtest 'add_geojson: popup property name appears in rendered body' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	$m->add_geojson({ type => 'FeatureCollection', features => [] }, popup => 'region');
	my (undef, $body) = $m->onload_render();
	like($body, qr/region/, "popup property 'region' in body JS");
};

subtest 'add_geojson: multiple layers all rendered' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	$m->add_geojson({ type => 'FeatureCollection', features => [] }, style => { color => '#ff0000' });
	$m->add_geojson({ type => 'FeatureCollection', features => [] }, style => { color => '#0000ff' });
	my (undef, $body) = $m->onload_render();
	my @calls = ($body =~ /L\.geoJSON/g);
	is(scalar @calls, 2, 'two L.geoJSON calls emitted');
	like($body, qr/#ff0000/, 'first layer colour');
	like($body, qr/#0000ff/, 'second layer colour');
};

# ─────────────────────────────────────────────────────────────────────────────
# add_heatmap()
# POD: returns 1; croaks with exact message if points not arrayref.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'add_heatmap: arrayref of points returns 1' => sub {
	my $m = HTML::OSM->new();
	my $r = $m->add_heatmap([[$C{LAT_LONDON}, $C{LON_LONDON}, 0.8]]);
	is($r, 1, 'success -> 1');
	returns_ok($r, { type => 'integer' }, 'return type is integer');
};

# POD MESSAGES: "add_heatmap: points must be arrayref"
subtest 'add_heatmap: string croaks with exact POD message' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->add_heatmap('not an arrayref') }
		qr/add_heatmap: points must be an arrayref/,
		'string croak per POD MESSAGES table';
};

subtest 'add_heatmap: hashref croaks with exact POD message' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->add_heatmap({ a => 1 }) }
		qr/add_heatmap: points must be an arrayref/,
		'hashref croak per POD MESSAGES table';
};

subtest 'add_heatmap: undef croaks with exact POD message' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->add_heatmap(undef) }
		qr/add_heatmap: points must be an arrayref/,
		'undef croak per POD MESSAGES table';
};

# Verify that radius/blur opts are propagated to the rendered JS output.
subtest 'add_heatmap: default radius and blur appear in rendered body' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	$m->add_heatmap([[$C{LAT_LONDON}, $C{LON_LONDON}]]);
	my (undef, $body) = $m->onload_render();
	like($body, qr/L\.heatLayer/, 'L.heatLayer call present');
	like($body, qr/radius:\s*25/, 'default radius 25');
	like($body, qr/blur:\s*15/,   'default blur 15');
};

subtest 'add_heatmap: custom radius and blur appear in rendered body' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	$m->add_heatmap([[$C{LAT_LONDON}, $C{LON_LONDON}]], radius => 40, blur => 25);
	my (undef, $body) = $m->onload_render();
	like($body, qr/radius:\s*40/, 'custom radius 40');
	like($body, qr/blur:\s*25/,   'custom blur 25');
};

subtest 'add_heatmap: plugin injected in head only when layer present' => sub {
	my $with = HTML::OSM->new();
	$with->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	$with->add_heatmap([[$C{LAT_LONDON}, $C{LON_LONDON}]]);
	like(($with->onload_render())[0], qr/leaflet.heat/i, 'heatmap plugin in head when used');

	my $without = HTML::OSM->new();
	$without->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	unlike(($without->onload_render())[0], qr/leaflet.heat/i, 'no plugin in head when unused');
};

subtest 'add_heatmap: multiple layers all rendered' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	$m->add_heatmap([[$C{LAT_LONDON}, $C{LON_LONDON}]]);
	$m->add_heatmap([[$C{LAT_PARIS},  $C{LON_PARIS}]]);
	my (undef, $body) = $m->onload_render();
	my @calls = ($body =~ /L\.heatLayer/g);
	is(scalar @calls, 2, 'two L.heatLayer calls emitted');
};

# ─────────────────────────────────────────────────────────────────────────────
# add_gpx()
# POD: returns 1; croaks when url is missing or empty.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'add_gpx: URL string returns 1' => sub {
	my $m = HTML::OSM->new();
	my $r = $m->add_gpx('https://example.com/track.gpx');
	is($r, 1, 'success -> 1');
	returns_ok($r, { type => 'integer' }, 'return type is integer');
};

# Params::Get fires its usage error before our croak; both messages contain "url".
subtest 'add_gpx: no args dies mentioning url (POD MESSAGES)' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->add_gpx() } qr/url/i, 'no-arg croak mentions url';
};

# POD MESSAGES: "add_gpx: url required"
subtest 'add_gpx: empty string croaks with exact POD message' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->add_gpx('') }
		qr/add_gpx: url is required/,
		'empty string croak per POD MESSAGES table';
};

subtest 'add_gpx: URL appears in rendered body with L.GPX call' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	$m->add_gpx('https://example.com/route.gpx');
	my (undef, $body) = $m->onload_render();
	like($body, qr{example\.com/route\.gpx}, 'GPX URL in body');
	like($body, qr/L\.GPX/,                  'L.GPX constructor called');
	like($body, qr/fitBounds/,               'fitBounds called on load event');
};

subtest 'add_gpx: plugin injected in head only when track present' => sub {
	my $with = HTML::OSM->new();
	$with->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	$with->add_gpx('https://example.com/t.gpx');
	like(($with->onload_render())[0], qr/gpx/i, 'GPX plugin in head when used');

	my $without = HTML::OSM->new();
	$without->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	unlike(($without->onload_render())[0], qr/leaflet-gpx/i, 'no GPX plugin when unused');
};

subtest 'add_gpx: multiple tracks all rendered' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	$m->add_gpx('https://example.com/a.gpx');
	$m->add_gpx('https://example.com/b.gpx');
	my (undef, $body) = $m->onload_render();
	my @calls = ($body =~ /L\.GPX/g);
	is(scalar @calls, 2, 'two L.GPX calls emitted');
	like($body, qr{a\.gpx}, 'first track URL');
	like($body, qr{b\.gpx}, 'second track URL');
};

# ─────────────────────────────────────────────────────────────────────────────
# add_choropleth()
# POD: returns 1; colours pre-computed in Perl from scale array.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'add_choropleth: valid inputs return 1' => sub {
	my $m = HTML::OSM->new();
	my $r = $m->add_choropleth(\@FEATURES, { England => 100, Scotland => 50 });
	is($r, 1, 'success -> 1');
	returns_ok($r, { type => 'integer' }, 'return type is integer');
};

# POD MESSAGES: "add_choropleth: features must be arrayref"
subtest 'add_choropleth: non-arrayref features croaks with exact POD message' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->add_choropleth('bad', {}) }
		qr/add_choropleth: features must be an arrayref/,
		'exact croak per POD MESSAGES table';
};

# POD MESSAGES: "add_choropleth: values must be hashref"
subtest 'add_choropleth: non-hashref values croaks with exact POD message' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->add_choropleth([], 'bad') }
		qr/add_choropleth: values must be a hashref/,
		'exact croak per POD MESSAGES table';
};

subtest 'add_choropleth: single value does not divide by zero' => sub {
	my $m = HTML::OSM->new();
	lives_ok {
		$m->add_choropleth(\@FEATURES, { England => 50, Scotland => 50 }, scale => ['#only']);
	} 'equal values does not die (div-by-zero guard)';
};

subtest 'add_choropleth: empty values hashref does not die' => sub {
	my $m = HTML::OSM->new();
	lives_ok { $m->add_choropleth(\@FEATURES, {}) } 'empty values hashref lives';
};

subtest 'add_choropleth: default key "name" appears in rendered JS' => sub {
	my $m = HTML::OSM->new();
	$m->center([$C{LAT_LONDON}, $C{LON_LONDON}]);
	$m->add_choropleth(\@FEATURES, { England => 100 });
	my (undef, $body) = $m->onload_render();
	like($body, qr/'name'/, "default key 'name' in rendered JS property access");
};

subtest 'add_choropleth: custom key appears in rendered JS' => sub {
	my $m = HTML::OSM->new();
	$m->center([$C{LAT_LONDON}, $C{LON_LONDON}]);
	$m->add_choropleth(\@FEATURES, { England => 100 }, key => 'region');
	my (undef, $body) = $m->onload_render();
	like($body, qr/'region'/, "custom key 'region' in rendered JS property access");
};

subtest 'add_choropleth: choroplethColors and choroplethValues emitted in body' => sub {
	my $m = HTML::OSM->new();
	$m->center([$C{LAT_LONDON}, $C{LON_LONDON}]);
	$m->add_choropleth(\@FEATURES, { England => 100, Scotland => 50 });
	my (undef, $body) = $m->onload_render();
	like($body, qr/choroplethColors/, 'choroplethColors in body');
	like($body, qr/choroplethValues/, 'choroplethValues in body');
	like($body, qr/fillColor/,        'fillColor in body');
};

# The scale is applied in Perl before render: min-value entity gets scale[0],
# max-value entity gets scale[-1].  Verify through rendered HTML.
subtest 'add_choropleth: min gets first colour, max gets last colour in rendered body' => sub {
	my $m = HTML::OSM->new();
	$m->center([$C{LAT_LONDON}, $C{LON_LONDON}]);
	$m->add_choropleth(\@FEATURES,
		{ England => 100, Scotland => 0 },
		scale => ['#lowcolour', '#highcolour'],
	);
	my (undef, $body) = $m->onload_render();
	like($body, qr/#lowcolour/,  'minimum value gets first scale colour');
	like($body, qr/#highcolour/, 'maximum value gets last scale colour');
};

subtest 'add_choropleth: multiple layers all rendered' => sub {
	my $m = HTML::OSM->new();
	$m->center([$C{LAT_LONDON}, $C{LON_LONDON}]);
	$m->add_choropleth(\@FEATURES, { England => 100 });
	$m->add_choropleth(\@FEATURES, { England => 200 });
	my (undef, $body) = $m->onload_render();
	# Count var declarations (one per block) rather than all uses of the name.
	my @blocks = ($body =~ /var choroplethColors/g);
	is(scalar @blocks, 2, 'two choroplethColors declarations in body');
};

# ─────────────────────────────────────────────────────────────────────────────
# onload_render()
# POD: returns ($head, $body); croaks when no data or no center for non-markers.
# ─────────────────────────────────────────────────────────────────────────────

# POD MESSAGES: "No map data provided"
subtest 'onload_render: no data croaks with exact POD message' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->onload_render() }
		qr/No map data provided/,
		'exact croak per POD MESSAGES table';
};

# POD MESSAGES: "center() must be called when no point markers"
subtest 'onload_render: non-marker data without center croaks with exact POD message' => sub {
	my $m = HTML::OSM->new();
	$m->add_geojson({ type => 'FeatureCollection', features => [] });
	throws_ok { $m->onload_render() }
		qr/center\(\) must be called when no point markers are provided/,
		'exact croak per POD MESSAGES table';
};

subtest 'onload_render: returns two non-empty strings' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	my @r = $m->onload_render();
	is(scalar @r, 2, 'two-element list');
	ok(length($r[0]) > 0, 'head is non-empty');
	ok(length($r[1]) > 0, 'body is non-empty');
	returns_ok($r[0], { type => 'string' }, 'head return type is string');
	returns_ok($r[1], { type => 'string' }, 'body return type is string');
};

subtest 'onload_render: head contains Leaflet CSS link' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	my ($head) = $m->onload_render();
	like($head, qr/leaflet.*\.css/i, 'Leaflet CSS link in head');
};

subtest 'onload_render: head contains Leaflet JS script' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	my ($head) = $m->onload_render();
	like($head, qr/leaflet.*\.js/i, 'Leaflet JS script in head');
};

subtest 'onload_render: body contains OpenStreetMap tile layer URL' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	my (undef, $body) = $m->onload_render();
	like($body, qr/openstreetmap\.org/, 'OSM tile URL in body');
};

subtest 'onload_render: body contains map setView call' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	my (undef, $body) = $m->onload_render();
	like($body, qr/setView/, 'setView call in body');
};

# POD description: "A Nominatim-powered search box"
subtest 'onload_render: body contains search box input' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	my (undef, $body) = $m->onload_render();
	like($body, qr/search-box/,               'search-box element present');
	like($body, qr/Enter location/i,           'search box placeholder text present');
};

# POD description: "A 'Clear search markers' button"
subtest 'onload_render: body contains Clear search markers button' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	my (undef, $body) = $m->onload_render();
	like($body, qr/clear-search-button/,       'clear-search-button ID present');
	like($body, qr/Clear search markers/i,     'button label text present');
};

# POD description: "A 'Reset Map' button"
subtest 'onload_render: body contains Reset Map button' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	my (undef, $body) = $m->onload_render();
	like($body, qr/reset-button/,              'reset-button ID present');
	like($body, qr/Reset Map/i,                'reset button label text present');
};

subtest 'onload_render: body contains searchMarkers array' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	my (undef, $body) = $m->onload_render();
	like($body, qr/searchMarkers/, 'searchMarkers variable in body');
};

# Midpoint computation: two equidistant points → center at (0, 0).
subtest 'onload_render: center auto-computed as midpoint of marker bounds' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([10, 20]);
	$m->add_marker([-10, -20]);
	my (undef, $body) = $m->onload_render();
	like($body, qr/setView\(\[0, 0\]/, 'midpoint (0, 0) used as center');
};

subtest 'onload_render: cluster => 1 wraps markers in clusterGroup' => sub {
	my $m = HTML::OSM->new(cluster => 1);
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	$m->add_marker([$C{LAT_PARIS},  $C{LON_PARIS}]);
	my ($head, $body) = $m->onload_render();
	like($head, qr/markercluster/i,               'cluster JS in head');
	like($body, qr/markerClusterGroup/,            'markerClusterGroup created');
	like($body, qr/clusterGroup\.addLayer/,        'markers via addLayer');
	like($body, qr/map\.addLayer\(clusterGroup\)/, 'clusterGroup added to map');
};

subtest 'onload_render: without cluster, markers added directly to map' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	my ($head, $body) = $m->onload_render();
	unlike($head, qr/markercluster/, 'no cluster assets in head');
	unlike($body, qr/clusterGroup/,  'no clusterGroup in body');
	like($body,   qr/addTo\(map\)/,  'marker added directly to map');
};

# Popup labels with single quotes must be JS-escaped so they don't break the
# surrounding JS single-quoted string literal.
subtest 'onload_render: popup label with single quote is JS-escaped' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}], html => "O'Brien's Bar");
	my (undef, $body) = $m->onload_render();
	like($body,   qr/O\\'Brien/,           'single quote JS-escaped');
	unlike($body, qr/O'Brien(?!\\)/,       'unescaped quote absent from popup');
};

# GPX URLs with special characters must also pass through _js_string.
subtest 'onload_render: GPX URL with single quote is JS-escaped' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	$m->add_gpx("https://example.com/track's.gpx");
	my (undef, $body) = $m->onload_render();
	like($body, qr/track\\'s\.gpx/, 'GPX URL single-quote JS-escaped');
};

subtest 'onload_render: non-marker render with center provided succeeds' => sub {
	my $m = HTML::OSM->new();
	$m->center([$C{LAT_LONDON}, $C{LON_LONDON}]);
	$m->add_geojson({ type => 'FeatureCollection', features => [] });
	my @r;
	lives_ok { @r = $m->onload_render() } 'center + GeoJSON-only lives';
	is(scalar @r, 2, 'two-element result');
	like($r[1], qr/L\.geoJSON/, 'GeoJSON in body');
};

# ── Global state integrity ────────────────────────────────────────────────────
# None of the public methods should clobber $@ or $_ — callers depend on these.

subtest 'onload_render: does not clobber $_ on success' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	local $_ = 'do_not_touch';
	$m->onload_render();
	is($_, 'do_not_touch', 'onload_render preserves $_');
};

subtest 'zoom: does not clobber $@ on success' => sub {
	my $m = HTML::OSM->new();
	eval { die 'sentinel' };
	my $before = $@;
	$m->zoom(5);
	is($@, $before, 'zoom() preserves $@');
};

subtest 'add_geojson: does not clobber $@ on success' => sub {
	my $m = HTML::OSM->new();
	eval { die 'sentinel' };
	my $before = $@;
	$m->add_geojson({ type => 'FeatureCollection', features => [] });
	is($@, $before, 'add_geojson preserves $@');
};

restore_all();
done_testing();

#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use HTML::OSM;

local $SIG{__WARN__} = sub { };

my $london  = [51.5074, -0.1278];
my $paris   = [48.8566,  2.3522];

my @features = (
	{ type => 'Feature', properties => { name => 'England' },
	  geometry => { type => 'Polygon',
	                coordinates => [[[0,51],[1,51],[1,52],[0,52],[0,51]]] } },
	{ type => 'Feature', properties => { name => 'Scotland' },
	  geometry => { type => 'Polygon',
	                coordinates => [[[0,55],[1,55],[1,56],[0,56],[0,55]]] } },
);

# ── GeoJSON ───────────────────────────────────────────────────────────────────

subtest 'add_geojson stores layer' => sub {
	my $m = HTML::OSM->new();
	ok($m->add_geojson({ type => 'FeatureCollection', features => [] }),
		'add_geojson returns true');
	is(scalar @{$m->{geojson}}, 1, 'geojson layer stored');
};

subtest 'add_geojson accepts JSON string' => sub {
	my $m = HTML::OSM->new();
	ok($m->add_geojson('{"type":"FeatureCollection","features":[]}'),
		'add_geojson accepts a JSON string');
	is(scalar @{$m->{geojson}}, 1, 'geojson layer stored from string');
};

subtest 'onload_render emits L.geoJSON with style and popup' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker($london, html => 'London');
	$m->add_geojson(
		{ type => 'FeatureCollection', features => [] },
		style => { color => '#ff0000', weight => 2 },
		popup => 'name',
	);
	my ($head, $body) = $m->onload_render();
	like($body, qr/L\.geoJSON/,   'body contains L.geoJSON');
	like($body, qr/#ff0000/,       'body contains style colour');
	like($body, qr/'name'/,        'body references popup property');
};

subtest 'geojson renders without point markers when center is set' => sub {
	my $m = HTML::OSM->new();
	$m->center($london);
	$m->add_geojson({ type => 'FeatureCollection', features => [] });
	my ($head, $body) = $m->onload_render();
	like($body, qr/L\.geoJSON/, 'GeoJSON rendered without point markers');
};

subtest 'onload_render dies when geojson-only but no center' => sub {
	my $m = HTML::OSM->new();
	$m->add_geojson({ type => 'FeatureCollection', features => [] });
	dies_ok { $m->onload_render() } 'Dies when center not set and no markers';
};

subtest 'multiple geojson layers all rendered' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker($london, html => 'London');
	$m->add_geojson({ type => 'FeatureCollection', features => [] }, style => { color => '#ff0000' });
	$m->add_geojson({ type => 'FeatureCollection', features => [] }, style => { color => '#00ff00' });
	my ($head, $body) = $m->onload_render();
	my @calls = ($body =~ /L\.geoJSON/g);
	is(scalar @calls, 2, 'both geoJSON layers emitted');
};

# ── Heatmaps ──────────────────────────────────────────────────────────────────

subtest 'add_heatmap stores layer' => sub {
	my $m = HTML::OSM->new();
	ok($m->add_heatmap([[51.5, -0.1, 0.8], [51.6, -0.2, 0.5]]),
		'add_heatmap returns true');
	is(scalar @{$m->{heatmap_layers}}, 1, 'heatmap layer stored');
};

subtest 'add_heatmap rejects non-arrayref' => sub {
	my $m = HTML::OSM->new();
	dies_ok { $m->add_heatmap('not an arrayref') } 'Dies on non-arrayref points';
};

subtest 'onload_render emits L.heatLayer with options' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker($london, html => 'London');
	$m->add_heatmap([[51.5, -0.1, 0.8]], radius => 30, blur => 20);
	my ($head, $body) = $m->onload_render();
	like($head, qr/leaflet-heat/,  'head includes Leaflet.heat plugin');
	like($body, qr/L\.heatLayer/, 'body contains L.heatLayer');
	like($body, qr/radius: 30/,   'body passes radius option');
	like($body, qr/blur: 20/,     'body passes blur option');
};

subtest 'heatmap plugin omitted when not used' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker($london, html => 'London');
	my ($head) = $m->onload_render();
	unlike($head, qr/leaflet-heat/, 'head omits Leaflet.heat when no heatmap');
};

subtest 'heatmap default options applied' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker($london, html => 'London');
	$m->add_heatmap([[51.5, -0.1]]);
	my ($head, $body) = $m->onload_render();
	like($body, qr/radius: 25/, 'default radius 25 applied');
	like($body, qr/blur: 15/,   'default blur 15 applied');
};

# ── GPX ───────────────────────────────────────────────────────────────────────

subtest 'add_gpx stores track URL' => sub {
	my $m = HTML::OSM->new();
	ok($m->add_gpx('https://example.com/track.gpx'), 'add_gpx returns true');
	is(scalar @{$m->{gpx_tracks}}, 1, 'GPX track stored');
	is($m->{gpx_tracks}[0], 'https://example.com/track.gpx', 'GPX URL correct');
};

subtest 'add_gpx requires url' => sub {
	my $m = HTML::OSM->new();
	dies_ok { $m->add_gpx() } 'Dies when no URL given';
};

subtest 'onload_render emits L.GPX with fitBounds' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker($london, html => 'London');
	$m->add_gpx('https://example.com/track.gpx');
	my ($head, $body) = $m->onload_render();
	like($head, qr/leaflet-gpx/,              'head includes leaflet-gpx plugin');
	like($body, qr/new L\.GPX/,               'body contains new L.GPX');
	like($body, qr|example\.com/track\.gpx|,  'body includes GPX URL');
	like($body, qr/fitBounds/,                 'body includes fitBounds callback');
};

subtest 'gpx plugin omitted when not used' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker($london, html => 'London');
	my ($head) = $m->onload_render();
	unlike($head, qr/leaflet-gpx/, 'head omits leaflet-gpx when no GPX');
};

# ── Clustering ────────────────────────────────────────────────────────────────

subtest 'cluster defaults to off' => sub {
	my $m = HTML::OSM->new();
	ok(!$m->{cluster}, 'cluster off by default');
};

subtest 'cluster => 1 injects plugin assets and cluster group' => sub {
	my $m = HTML::OSM->new(cluster => 1);
	$m->add_marker($london, html => 'London');
	$m->add_marker($paris,  html => 'Paris');
	my ($head, $body) = $m->onload_render();
	like($head, qr/markercluster/,              'head includes markercluster JS');
	like($head, qr/MarkerCluster\.css/,         'head includes MarkerCluster CSS');
	like($head, qr/MarkerCluster\.Default\.css/,'head includes MarkerCluster.Default CSS');
	like($body, qr/markerClusterGroup/,          'body creates markerClusterGroup');
	like($body, qr/clusterGroup\.addLayer/,      'markers added via addLayer');
	like($body, qr/map\.addLayer\(clusterGroup\)/,'clusterGroup added to map');
};

subtest 'without clustering markers go directly to map' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker($london, html => 'London');
	my ($head, $body) = $m->onload_render();
	unlike($head, qr/markercluster/, 'head lacks markercluster when unused');
	unlike($body, qr/clusterGroup/,  'body lacks clusterGroup when unused');
	like($body,   qr/\.addTo\(map\)/,'marker added directly to map');
};

subtest 'cluster_js_url can be overridden' => sub {
	my $m = HTML::OSM->new(cluster => 1, cluster_js_url => 'https://my.cdn/cluster.js');
	$m->add_marker($london, html => 'London');
	my ($head) = $m->onload_render();
	like($head, qr|my\.cdn/cluster\.js|, 'custom cluster_js_url used');
};

# ── Choropleths ───────────────────────────────────────────────────────────────

subtest 'add_choropleth stores layer' => sub {
	my $m = HTML::OSM->new();
	ok($m->add_choropleth(\@features, { England => 100, Scotland => 50 }, key => 'name'),
		'add_choropleth returns true');
	is(scalar @{$m->{choropleth_layers}}, 1, 'choropleth layer stored');
};

subtest 'add_choropleth rejects bad inputs' => sub {
	my $m = HTML::OSM->new();
	dies_ok { $m->add_choropleth('not arrayref', {}) }      'Dies when features not arrayref';
	dies_ok { $m->add_choropleth([], 'not hashref') }        'Dies when values not hashref';
};

subtest 'add_choropleth pre-computes colours correctly' => sub {
	my $m = HTML::OSM->new();
	$m->add_choropleth(
		\@features,
		{ England => 100, Scotland => 0 },
		key   => 'name',
		scale => ['#111111', '#999999'],
	);
	my $layer = $m->{choropleth_layers}[0];
	is($layer->{colors}{Scotland}, '#111111', 'lowest value gets first scale colour');
	is($layer->{colors}{England},  '#999999', 'highest value gets last scale colour');
	is($layer->{key}, 'name', 'key stored');
};

subtest 'onload_render emits choropleth JS without extra plugin' => sub {
	my $m = HTML::OSM->new();
	$m->center([54.0, -2.0]);
	$m->add_choropleth(\@features, { England => 100, Scotland => 50 }, key => 'name');
	my ($head, $body) = $m->onload_render();
	like($body, qr/choroplethColors/,  'body contains choroplethColors lookup');
	like($body, qr/fillColor/,         'body contains fillColor style');
	like($body, qr/choroplethValues/,  'body contains choroplethValues for popups');
	unlike($head, qr/leaflet-heat|leaflet-gpx|markercluster/,
		'no extra plugin injected for choropleth');
};

subtest 'choropleth renders without point markers when center set' => sub {
	my $m = HTML::OSM->new();
	$m->center($london);
	$m->add_choropleth(\@features, { England => 100, Scotland => 50 });
	my ($head, $body) = $m->onload_render();
	like($body, qr/choroplethColors/, 'choropleth rendered without point markers');
};

# ── No-data guard ─────────────────────────────────────────────────────────────

subtest 'onload_render dies when object has no data of any kind' => sub {
	my $m = HTML::OSM->new();
	dies_ok { $m->onload_render() } 'Dies when no map data provided';
};

done_testing();

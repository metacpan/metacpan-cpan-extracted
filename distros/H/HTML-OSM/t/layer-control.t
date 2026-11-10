#!/usr/bin/env perl

# add_geojson(name => ..., show => ...): a named layer gets a checkbox in
# Leaflet's layer control, so the reader can hide and show it.  Layers that
# share a name share one checkbox; show => 0 starts a layer hidden; a layer
# with no name is drawn as before and makes no control.  Whether the checkbox
# really hides the layer can only be seen in a browser.

use strict;
use warnings;

use Test::Most;

use HTML::OSM;

my $LONDON = [51.5074, -0.1278];

sub square {
	my ($name, $lon, $lat) = @_;
	return {
		type       => 'Feature',
		properties => { name => $name },
		geometry   => {
			type        => 'Polygon',
			coordinates => [[[$lon, $lat], [$lon + 1, $lat], [$lon + 1, $lat + 1],
				[$lon, $lat + 1], [$lon, $lat]]],
		},
	};
}

sub collection { return { type => 'FeatureCollection', features => [ @_ ] } }

# The body of a map with one marker and the given add_geojson calls.
sub body_with {
	my $map = HTML::OSM->new(search => 0);
	$map->add_marker($LONDON, html => 'London');
	$map->add_geojson(@{$_}) for @_;
	my (undef, $body) = $map->onload_render();
	return $body;
}

subtest 'an unnamed layer is drawn as before, with no control' => sub {
	my $body = body_with([ collection(square('Kent', 0, 51)), popup => 'name' ]);
	like($body, qr/L\.geoJSON\(.*\)\.addTo\(map\);/, 'added straight to the map');
	unlike($body, qr/L\.control\.layers/, 'no layer control');
	unlike($body, qr/L\.layerGroup/,     'no group');
};

subtest 'a named layer gets a checkbox and is shown' => sub {
	my $body = body_with([ collection(square('Kent', 0, 51)), name => 'County boundaries' ]);
	like($body, qr/group = L\.layerGroup\(\[L\.geoJSON\(/, 'the layer is put in a group');
	like($body, qr/group\.addTo\(map\);/, 'shown when the map opens');
	like($body, qr/overlays\['County boundaries'\] = group;/, 'listed under its name');
	like($body, qr/L\.control\.layers\(null, overlays, \{ collapsed: false \}\)\.addTo\(map\);/,
		'one open layer control');
	unlike($body, qr/L\.geoJSON\([^\n]*\)\.addTo\(map\)/, 'not also added on its own');
	like($body, qr/\(function\(\) \{\s*var overlays = \{\};/, 'its variables are kept local');
};

subtest 'show => 0 starts it hidden' => sub {
	my $body = body_with([ collection(square('Kent', 0, 51)), name => 'Counties', show => 0 ]);
	like($body, qr/overlays\['Counties'\] = group;/, 'still listed');
	unlike($body, qr/group\.addTo\(map\)/, 'not on the map at first');
};

subtest 'the words false, no and off are false' => sub {
	for my $word (qw(false no off FALSE Off)) {
		my $body = body_with([ collection(), name => 'N', show => $word ]);
		unlike($body, qr/group\.addTo\(map\)/, "show => '$word' hides it");
	}
	for my $value (1, 'yes', 'true') {
		my $body = body_with([ collection(), name => 'N', show => $value ]);
		like($body, qr/group\.addTo\(map\)/, "show => '$value' shows it");
	}
};

subtest 'layers with the same name share one checkbox' => sub {
	my $body = body_with(
		[ collection(square('Kent', 0, 51)),   name => 'Counties', show => 0 ],
		[ collection(),                         name => 'Rivers' ],
		[ collection(square('Surrey', -1, 51)), name => 'Counties' ],
	);
	my @groups = $body =~ /group = L\.layerGroup\(\[(.*?)\]\);/g;
	is(scalar(@groups), 2, 'one group for each name');
	is(scalar(() = $groups[0] =~ /L\.geoJSON\(/g), 2, 'both Counties layers in the first');
	like($groups[0], qr/Kent.*Surrey/s, 'in the order they were added');
	my @labels = $body =~ /overlays\['([^']+)'\] = group;/g;
	is_deeply(\@labels, [ 'Counties', 'Rivers' ], 'names in the order they first appear');
	is(scalar(() = $body =~ /group\.addTo\(map\)/g), 2,
		'Counties is shown because one of its layers is, and Rivers too');
	is(scalar(() = $body =~ /L\.control\.layers/g), 1, 'one control for every name');
};

subtest 'named and unnamed layers together' => sub {
	my $body = body_with(
		[ collection(square('Kent', 0, 51)) ],
		[ collection(square('Surrey', -1, 51)), name => 'Counties' ],
	);
	is(scalar(() = $body =~ /L\.geoJSON\(/g), 2, 'both drawn');
	like($body, qr/L\.geoJSON\([^\n]*Kent[^\n]*\)\.addTo\(map\);/, 'the unnamed one on its own');
	like($body, qr/L\.layerGroup\(\[L\.geoJSON\([^\n]*Surrey/, 'the named one in its group');
};

subtest 'show is ignored without a name' => sub {
	my $body = body_with([ collection(), show => 0 ]);
	like($body, qr/L\.geoJSON\(.*\)\.addTo\(map\);/, 'drawn, since nothing could turn it on');
	unlike($body, qr/L\.control\.layers/, 'no control');
};

subtest 'the name is escaped as HTML and as JavaScript' => sub {
	my $body = body_with([ collection(), name => q{<img src=x onerror=alert(1)>'s & </script>} ]);
	like($body, qr/overlays\['&lt;img src=x onerror=alert\(1\)&gt;\\'s &amp; &lt;\/script&gt;'\]/,
		'HTML entities, then the quote escaped');
	unlike($body, qr/<img/, 'no tag reaches the page');
	unlike($body, qr{</script>.*</script>}s, 'the script is not ended early');
	my $other = body_with([ collection(), name => "a\nb\\c" ]);
	like($other, qr/overlays\['a\\nb\\\\c'\]/, 'newline and backslash escaped');
};

subtest 'popup and style still apply to a named layer' => sub {
	my $body = body_with([ collection(square('Kent', 0, 51)),
		name => 'Counties', popup => 'name', style => { color => '#555555', fill => \0 } ]);
	like($body, qr/L\.layerGroup\(\[L\.geoJSON\([^\n]*style: \{[^\n]*"color":"#555555"/, 'style');
	like($body, qr/L\.layerGroup\(\[L\.geoJSON\([^\n]*bindPopup/, 'popup');
};

subtest 'a GeoJSON-only map with a centre' => sub {
	my $map = HTML::OSM->new(search => 0);
	$map->center($LONDON);
	$map->add_geojson(collection(square('Kent', 0, 51)), name => 'Counties', show => 0);
	my (undef, $body) = $map->onload_render();
	like($body, qr/L\.control\.layers/, 'the control is drawn');
	is(scalar(() = $body =~ /<script\b/g), 1, 'still one script in the body');
};

subtest 'bad names and shows are refused' => sub {
	my $map = HTML::OSM->new();
	throws_ok { $map->add_geojson(collection(), name => '') }
		qr/^add_geojson: name must be a string/, 'an empty name';
	throws_ok { $map->add_geojson(collection(), name => [ 'x' ]) }
		qr/^add_geojson: name must be a string/, 'a reference';
	throws_ok { $map->add_geojson(collection(), name => 'x', show => {}) }
		qr/^add_geojson: show must not be a reference/, 'a reference for show';
	ok(!exists $map->{geojson}, 'nothing was stored');
	lives_ok { $map->add_geojson(collection(), name => 0) } 'the name 0 is text';
};

subtest 'a bad name that skipped the check draws the layer unnamed' => sub {
	my $map = HTML::OSM->new(search => 0);
	$map->add_marker($LONDON);
	$map->add_geojson(collection(), name => 'ok');
	$map->{geojson}[0]{opts}{name} = [ 'from a clone' ];
	my (undef, $body) = $map->onload_render();
	unlike($body, qr/L\.control\.layers/, 'no control');
	like($body, qr/L\.geoJSON\(.*\)\.addTo\(map\);/, 'drawn on its own');
};

subtest 'the nonce is still on the one script' => sub {
	my $map = HTML::OSM->new(search => 0, nonce => 'abc123');
	$map->add_marker($LONDON);
	$map->add_geojson(collection(), name => 'Counties');
	my (undef, $body) = $map->onload_render();
	my @tags = $body =~ /(<script\b[^>]*>)/g;
	is(scalar(@tags), 1, 'one script');
	like($tags[0], qr/nonce="abc123"/, 'with the nonce');
};

done_testing();

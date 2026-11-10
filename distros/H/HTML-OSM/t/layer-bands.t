#!/usr/bin/env perl

# add_geojson(bands => ...): a feature property holding a list of colours, each
# drawn as a line of its own along a polygon's outline, side by side.  Whether
# the lines really sit side by side can only be seen in a browser; here the
# script that draws them is checked.

use strict;
use warnings;

use Test::Most;

use HTML::OSM;

my $LONDON = [51.5074, -0.1278];

sub square {
	my ($name, $lon, $lat, @colours) = @_;
	return {
		type       => 'Feature',
		properties => { name => $name, (@colours ? (colours => [ @colours ]) : ()) },
		geometry   => {
			type        => 'Polygon',
			coordinates => [[[$lon, $lat], [$lon + 1, $lat], [$lon + 1, $lat + 1],
				[$lon, $lat + 1], [$lon, $lat]]],
		},
	};
}

sub collection { return { type => 'FeatureCollection', features => [ @_ ] } }

sub body_with {
	my $map = HTML::OSM->new(search => 0, nonce => 'n0nce');
	$map->add_marker($LONDON);
	$map->add_geojson(@{$_}) for @_;
	my (undef, $body) = $map->onload_render();
	return $body;
}

subtest 'a layer without bands is drawn as before' => sub {
	my $body = body_with([ collection(square('Kent', 0, 51, '#d73027')) ]);
	unlike($body, qr/bandLayer|bandInside/, 'no band script');
	like($body, qr/L\.geoJSON\(.*\)\.addTo\(map\);/, 'drawn as a plain layer');
};

subtest 'an unnamed banded layer' => sub {
	my $body = body_with([ collection(square('Kent', 0, 51, '#d73027', '#4575b4')),
		bands => 'colours', style => { weight => 2, fill => \0 }, popup => 'name' ]);
	like($body, qr/\(function\(\) \{\s*function bandInside\(/, 'its functions are kept local');
	like($body, qr/bandLayer\(\{[^\n]*"#d73027","#4575b4"[^\n]*\}, \{[^\n]*"weight":2[^\n]*\}, function\(f,l\)\{[^\n]*bindPopup[^\n]*\}, 'colours'\)\.addTo\(map\);/,
		'given the data, the style, the popup and the property');
	is(scalar(() = $body =~ /function bandLayer\(/g), 1, 'the script is written once');
	is(scalar(() = $body =~ /<script\b/g), 1, 'still one script in the body');
};

subtest 'no style and no popup' => sub {
	my $body = body_with([ collection(square('Kent', 0, 51, '#d73027')), bands => 'colours' ]);
	like($body, qr/bandLayer\(\{[^\n]*\}, null, null, 'colours'\)\.addTo\(map\);/, 'both are null');
};

subtest 'a named banded layer goes in its group' => sub {
	my $body = body_with(
		[ collection(square('Kent', 0, 51, '#d73027', '#4575b4')), bands => 'colours', name => 'Counties' ],
		[ collection(square('Surrey', -1, 51)), name => 'Counties' ],
	);
	like($body, qr/group = L\.layerGroup\(\[bandLayer\([^\n]*'colours'\), L\.geoJSON\(/,
		'beside a plain layer of the same name');
	is(scalar(() = $body =~ /function bandLayer\(/g), 1, 'the script is written once');
	like($body, qr/var overlays = \{\};.*function bandLayer\(.*group = L\.layerGroup/s,
		'inside the function that makes the groups');
	like($body, qr/L\.control\.layers/, 'with its checkbox');
};

subtest 'with a key as well' => sub {
	my %key  = (entries => [ { label => 'Busy', colour => '#d73027' } ]);
	my $body = body_with([ collection(square('Kent', 0, 51, '#d73027')), bands => 'colours', key => \%key ]);
	like($body, qr/function layerKey\(.*function bandLayer\(.*layerKey\(bandLayer\(/s,
		'an unnamed layer has both scripts, and the key is given the banded layer');
	$body = body_with([ collection(square('Kent', 0, 51, '#d73027')),
		bands => 'colours', key => \%key, name => 'Counties' ]);
	like($body, qr/function layerKey\(.*function bandLayer\(.*layerKey\(group, /s, 'and so has a named one');
};

subtest 'the script draws what the documentation says' => sub {
	my $body = body_with([ collection(square('Kent', 0, 51, '#d73027', '#4575b4')), bands => 'colours' ]);
	like($body, qr{/\^#\[0-9a-fA-F\]\{6\}\$/\.test\(c\)}, 'only #rrggbb is taken as a colour');
	like($body, qr/base\.setStyle\(\{ color: cols\[0\], opacity: 0, weight: 2 \* cols\.length \* width \}\)/,
		'the polygon itself is not seen, and takes clicks over every line');
	like($body, qr/for\(var j = cols\.length - 1; j >= 0; j--\) \{\s*inside\.push\(bandInside\(base, style \|\| \{\}, cols\[j\], 2 \* \(j \+ 1\) \* width\)\);/,
		'every colour, the first too, is a line cut to the inside, the widest drawn first');
	like($body, qr/if\(!\(base instanceof L\.Polygon\)\) \{\s*base\.setStyle\(\{ color: cols\[0\] \}\);/,
		'a line or point takes the first colour');
	like($body, qr/opts\.interactive = false;/, 'which lets a click through to the outline');
	like($body, qr/setAttribute\('clip-path', 'url\(#' \+ id \+ '-clip\)'\)/, 'cut by a clip path');
	like($body, qr/if\(!svg\) \{ return; \}/, 'left uncut where there is no SVG');
	unlike($body, qr/innerHTML/, 'nothing is written as HTML');
};

subtest 'the property name is escaped' => sub {
	my $body = body_with([ collection(), bands => q{a'b\\c</script>} ]);
	like($body, qr/, 'a\\'b\\\\c[^']*'\)\.addTo\(map\)/, 'quote and backslash escaped');
	is(scalar(() = $body =~ m{</script>}g), 1, 'the script is not ended early');
};

subtest 'a bad bands is refused' => sub {
	my $map = HTML::OSM->new();
	throws_ok { $map->add_geojson(collection(), bands => '') }
		qr/^add_geojson: bands must be a string/, 'empty';
	throws_ok { $map->add_geojson(collection(), bands => [ 'colours' ]) }
		qr/^add_geojson: bands must be a string/, 'a reference';
	ok(!exists $map->{geojson}, 'nothing was stored');
};

subtest 'a bad bands that skipped the check draws the layer plain' => sub {
	my $map = HTML::OSM->new(search => 0);
	$map->add_marker($LONDON);
	$map->add_geojson(collection(), bands => 'colours');
	$map->{geojson}[0]{opts}{bands} = [ 'from a clone' ];
	my (undef, $body) = $map->onload_render();
	unlike($body, qr/bandLayer/, 'no band script');
	like($body, qr/L\.geoJSON\(.*\)\.addTo\(map\);/, 'drawn on its own');
};

done_testing();

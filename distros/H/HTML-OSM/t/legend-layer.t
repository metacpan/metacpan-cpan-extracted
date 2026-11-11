#!/usr/bin/env perl

# legend => [ { ..., unless_layer => 'Name' } ]: a marker key entry listed
# only while the named GeoJSON layer is hidden, for when that layer's own key
# shows the same colours.  Whether it really comes and goes with the checkbox
# can only be seen in a browser; here the script that does it is checked.

use strict;
use warnings;

use JSON::PP ();
use Test::Most;

use HTML::OSM;

my $LONDON = [51.5074, -0.1278];

sub collection { return { type => 'FeatureCollection', features => [] } }

sub body_with {
	my ($legend, @layers) = @_;
	my $map = HTML::OSM->new(search => 0, legend => $legend);
	$map->add_marker($LONDON, group => 'busy');
	$map->add_geojson(collection(), @{$_}) for @layers;
	my (undef, $body) = $map->onload_render();
	return $body;
}

sub js_value {
	my ($body, $name) = @_;
	my ($json) = $body =~ /var \Q$name\E = (.*?);\n/ or return;
	return JSON::PP->new->allow_nonref->decode($json =~ s{<\\/}{</}gr);
}

my @LEGEND = (
	{ label => 'Busy',  colour => '#d73027', group => 'busy', unless_layer => 'Counties' },
	{ label => 'Large', colour => '#3388ff', radius => 20 },
);

subtest 'an entry waits on its layer being hidden' => sub {
	my $body = body_with(\@LEGEND, [ name => 'Counties' ]);
	is_deeply(js_value($body, 'legendEntries'), [
		{ label => 'Busy',  colour => '#d73027', group => 'busy', unless_layer => 'Counties' },
		{ label => 'Large', colour => '#3388ff', radius => 20 },
	], 'the entry carries its layer; another entry is as before');
	is_deeply(js_value($body, 'layerShown'), { Counties => JSON::PP::true }, 'the layer starts shown');
	like($body, qr/if\(e\.unless_layer !== undefined && layerShown\[e\.unless_layer\]\) \{ waiting\+\+; return; \}/,
		'so the entry is left out');
	like($body, qr/map\.on\('overlayadd', function\(e\) \{ layerShown\[e\.name\] = true; drawLegend\(\); \}\);/,
		'ticking the layer leaves it out again');
	like($body, qr/map\.on\('overlayremove', function\(e\) \{ layerShown\[e\.name\] = false; drawLegend\(\); \}\);/,
		'and unticking it brings the entry back');
};

subtest 'which layers start shown' => sub {
	is_deeply(js_value(body_with(\@LEGEND, [ name => 'Counties', show => 0 ]), 'layerShown'), {},
		'a layer that starts hidden is not shown');
	is_deeply(js_value(body_with(\@LEGEND, [ name => 'Counties', show => 0 ], [ name => 'Counties' ]), 'layerShown'),
		{ Counties => JSON::PP::true }, 'shown when any layer of the name is');
	is_deeply(js_value(body_with(\@LEGEND, [ name => 'Counties', show => 'off' ], [ name => 'Rivers' ], []), 'layerShown'),
		{ Rivers => JSON::PP::true }, 'each name by itself; a layer with no name has no checkbox');
	is_deeply(js_value(body_with(\@LEGEND), 'layerShown'), {}, 'no layers at all');
};

subtest 'a key with nothing left to list is not drawn' => sub {
	my $body = body_with([ $LEGEND[0] ], [ name => 'Counties' ]);
	like($body, qr/div\.style\.display = \(waiting && waiting === legendEntries\.length\) \? 'none' : '';/,
		'hidden when every entry waits on a shown layer');
};

subtest 'the name is compared as the layer control reports it' => sub {
	my $name = q{Town & <b>County</b>};
	my $body = body_with([ { label => 'Busy', unless_layer => $name } ], [ name => $name ]);
	my $entries = js_value($body, 'legendEntries');
	my ($label) = $body =~ /overlays\['(.*?)'\] = group;/;
	is($entries->[0]{unless_layer}, $label, 'escaped as the layer\'s label is');
	is_deeply([ keys %{ js_value($body, 'layerShown') } ], [ $label ], 'and so is the list of layers shown');
	unlike($body, qr/<b>County/, 'no markup reaches the page');
};

subtest 'a bad unless_layer is refused' => sub {
	throws_ok { HTML::OSM->new(legend => [ { label => 'a', unless_layer => '' } ]) }
		qr/legend entry 1: unless_layer must be a layer's name/, 'empty';
	throws_ok { HTML::OSM->new(legend => [ { label => 'a', unless_layer => [ 'x' ] } ]) }
		qr/legend entry 1: unless_layer must be a layer's name/, 'a reference';
};

subtest 'a map with no such entry is unchanged in what it lists' => sub {
	my $body = body_with([ { label => 'Busy', colour => '#d73027', group => 'busy' } ], [ name => 'Counties' ]);
	is_deeply(js_value($body, 'legendEntries'), [ { label => 'Busy', colour => '#d73027', group => 'busy' } ],
		'no unless_layer is added');
};

done_testing();

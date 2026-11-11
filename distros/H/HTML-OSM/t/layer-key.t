#!/usr/bin/env perl

# add_geojson(key => ...): a key to a layer's colours, a line of each colour
# beside its label, shown while the layer is and hidden when the reader
# unticks it.  Whether it really hides can only be seen in a browser; here the
# script that does it is checked.

use strict;
use warnings;

use JSON::PP ();
use Test::Most;

use HTML::OSM;

my $LONDON = [51.5074, -0.1278];

sub collection { return { type => 'FeatureCollection', features => [] } }

my %KEY = (
	title   => 'Population',
	entries => [
		{ label => '100,000 or more', colour => '#D73027' },
		{ label => 'under 100,000',   colour => '#1a9850' },
	],
);

sub body_with {
	my $map = HTML::OSM->new(search => 0, nonce => 'n0nce');
	$map->add_marker($LONDON);
	$map->add_geojson(collection(), @{$_}) for @_;
	my (undef, $body) = $map->onload_render();
	return $body;
}

# The keys passed to layerKey(), decoded, with what each was given for.
sub keys_in {
	my $body = shift;
	return map { [ $_->[0], JSON::PP->new->decode($_->[1] =~ s{<\\/}{</}gr) ] }
		map { [ /\A(\w+|L\.geoJSON\(.*?\)\.addTo\(map\)), (\{.*\})\z/s ] }
		$body =~ /layerKey\(((?:group|L\.geoJSON).*?)\);\n/g;
}

subtest 'a named layer with a key' => sub {
	my $body = body_with([ name => 'Counties', key => \%KEY ]);
	my @keys = keys_in($body);
	is(scalar(@keys), 1, 'one key');
	is($keys[0][0], 'group', 'for the layer\'s group, so it follows the checkbox');
	is_deeply($keys[0][1], {
		title    => 'Population',
		position => 'bottomright',
		shape    => 'line',
		entries  => [
			{ label => '100,000 or more', colour => '#d73027' },
			{ label => 'under 100,000',   colour => '#1a9850' },
		],
	}, 'its entries in order, colours in lower case, bottom right by default');
	is(scalar(() = $body =~ /function layerKey\(/g), 1, 'the function written once');
	like($body, qr/\(function\(\) \{\s*var overlays = \{\};\s*var group;\s*function layerKey/,
		'inside the layers\' own function, not the page\'s scope');
	like($body, qr/map\.on\('overlayadd', function\(e\) \{ if\(e\.layer === layer\) \{ key\.addTo\(map\); \} \}\);/,
		'shown when the layer is ticked');
	like($body, qr/map\.on\('overlayremove', function\(e\) \{ if\(e\.layer === layer\) \{ key\.remove\(\); \} \}\);/,
		'and hidden when it is unticked');
	like($body, qr/if\(map\.hasLayer\(layer\)\) \{ key\.addTo\(map\); \}/, 'shown at first only if the layer is');
	like($body, qr/swatch\.style\.borderTop = '3px solid ' \+ e\.colour;/, 'a line, as an outline is drawn');
	is(scalar(() = $body =~ /<script\b/g), 1, 'still one script');
};

subtest 'layers sharing a name share the first key' => sub {
	my $body = body_with(
		[ name => 'Counties' ],
		[ name => 'Counties', key => \%KEY ],
		[ name => 'Counties', key => { entries => [ { label => 'other', colour => '#000' } ] } ],
		[ name => 'Rivers' ],
	);
	my @keys = keys_in($body);
	is(scalar(@keys), 1, 'one key for Counties, none for Rivers');
	is($keys[0][1]{title}, 'Population', 'the first key given for the name');
};

subtest 'an unnamed layer\'s key always shows' => sub {
	my $body = body_with([ key => { %KEY, position => 'topleft' } ]);
	my @keys = keys_in($body);
	is(scalar(@keys), 1, 'one key');
	like($keys[0][0], qr/\AL\.geoJSON\(.*\)\.addTo\(map\)\z/, 'for the layer itself, added to the map');
	is($keys[0][1]{position}, 'topleft', 'where it was asked for');
	unlike($body, qr/L\.control\.layers/, 'no layer control');
	like($body, qr/\(function\(\) \{\s*function layerKey/, 'its function kept local too');
};

subtest 'no key, no function' => sub {
	my $body = body_with([ name => 'Counties' ], []);
	unlike($body, qr/layerKey/, 'nothing written');
};

subtest 'text reaches the page as text' => sub {
	my $body = body_with([ name => 'C', key => {
		title   => '<b>Pop</b></script>',
		entries => [ { label => q{</script><script>alert(1)</script>'"}, colour => '#abc' } ],
	} ]);
	unlike($body, qr{</script>.*</script>}s, 'the script is not ended early');
	unlike($body, qr/innerHTML/, 'no innerHTML');
	like($body, qr/title\.textContent = k\.title;/, 'the title by textContent');
	like($body, qr/createTextNode\(e\.label\)/, 'the labels as text nodes');
	my ($key) = keys_in($body);
	is($key->[1]{entries}[0]{label}, q{</script><script>alert(1)</script>'"}, 'the label kept as written');
};

subtest 'a bad key is refused' => sub {
	my $map = HTML::OSM->new();
	my @bad = (
		[ []                                               => qr/key must be a hashref/ ],
		[ {}                                               => qr/key entries must be a non-empty arrayref/ ],
		[ { entries => [] }                                => qr/key entries must be a non-empty arrayref/ ],
		[ { entries => [ 'x' ] }                           => qr/key entry 1 is not a hashref/ ],
		[ { entries => [ { colour => '#fff' } ] }          => qr/key entry 1: label is required/ ],
		[ { entries => [ { label => 'a' } ] }              => qr/key entry 1: invalid colour: undef/ ],
		[ { entries => [ { label => 'a', colour => 'red' } ] } => qr/key entry 1: invalid colour: red/ ],
		[ { entries => [ { label => 'a', colour => '#fff;x' } ] } => qr/invalid colour/ ],
		[ { %KEY, position => 'middle' }                   => qr/key position must be one of topright, topleft, bottomright, bottomleft/ ],
		[ { %KEY, title => [] }                            => qr/key title must be text/ ],
		[ { %KEY, shape => 'circle' }                    => qr/key shape must be one of line, box/ ],
		[ { %KEY, shape => [] }                          => qr/key shape must be one of line, box/ ],
	);
	for my $case (@bad) {
		throws_ok { $map->add_geojson(collection(), name => 'C', key => $case->[0]) }
			qr/^add_geojson: /, 'refused';
		throws_ok { $map->add_geojson(collection(), key => $case->[0]) } $case->[1], 'saying why';
	}
	ok(!exists $map->{geojson}, 'nothing was stored');
	lives_ok { $map->add_geojson(collection(), key => { %KEY, title => '' }) } 'an empty title is no title';
	is($map->{geojson}[0]{opts}{key}{title}, undef, 'and left out');
	is_deeply($KEY{entries}[0], { label => '100,000 or more', colour => '#D73027' }, 'the caller\'s key is not changed');
};

subtest 'a key of filled boxes' => sub {
	my $body = body_with([ name => 'Counties', key => { %KEY, shape => 'box' } ]);
	my ($key) = keys_in($body);
	is($key->[1]{shape}, 'box', 'the shape is passed to the script');
	like($body, qr/if\(k\.shape === 'box'\) \{[^}]*swatch\.style\.background = e\.colour;/s,
		'which fills a box with the colour');
	like($body, qr/\} else \{[^}]*swatch\.style\.borderTop = '3px solid ' \+ e\.colour;/s,
		'and otherwise draws a line, as before');
};

done_testing();

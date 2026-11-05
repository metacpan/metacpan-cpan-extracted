#!/usr/bin/env perl

# Tests for the scale bar (scale) and the key (legend, legend_title,
# legend_position, legend_empty, and the group option of the marker methods)

use strict;
use warnings;

use Readonly;
use Test::Most;
use Test::Mockingbird;
use HTML::OSM;

Readonly my %C => (
	LAT_A  => 51.5074,
	LON_A  => -0.1278,
	LAT_B  => 48.8566,
	LON_B  => 2.3522,
	RADIUS => 12,
);

# Block accidental network calls
mock 'LWP::UserAgent::new' => sub {
	return bless {}, 'LEG::FailUA';
};
{
	package LEG::FailUA;
	sub get { die 'network access blocked in t/legend.t' }
	sub default_header { }
	sub env_proxy { }
}

# The body of a map with one marker, made with %args
sub body_of {
	my (%args) = @_;
	my $markers = delete $args{markers} // sub { $_[0]->add_marker([ $C{LAT_A}, $C{LON_A} ], html => 'A') };

	my $map = HTML::OSM->new(%args);
	$markers->($map);
	my (undef, $body) = $map->onload_render();
	return $body;
}

# The warnings a block gives
sub warnings_of(&) {
	my ($code) = @_;
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };
	$code->();
	return @warnings;
}

# The key's entries, groups and points, as the script declares them
sub legend_parts {
	my ($body) = @_;
	my ($entries) = $body =~ /var legendEntries = (.*?);\n/;
	my ($groups)  = $body =~ /var legendGroups = (.*?);\n/;
	my ($points)  = $body =~ /var legendPoints = (.*?);\n/;
	return {
		entries => defined($entries) ? JSON::MaybeXS::decode_json($entries) : undef,
		groups  => defined($groups)  ? JSON::MaybeXS::decode_json($groups)  : undef,
		points  => $points,
	};
}

subtest 'by default there is neither a scale bar nor a key' => sub {
	my $body = body_of();
	unlike($body, qr/L\.control\.scale/, 'no scale bar');
	unlike($body, qr/legendEntries/, 'no key');
};

subtest 'scale => 1 adds the scale bar' => sub {
	my $body = body_of(scale => 1);
	like($body, qr/L\.control\.scale\(\)\.addTo\(map\);/, 'the scale bar is added to the map');
	unlike(body_of(scale => 0), qr/L\.control\.scale/, 'scale => 0 leaves it out');

	my $map = HTML::OSM->new()->new(scale => 'off');
	$map->add_marker([ $C{LAT_A}, $C{LON_A} ]);
	unlike(($map->onload_render())[1], qr/L\.control\.scale/, "a clone's 'off' counts as off, as search's does");
};

subtest 'the key lists its entries, with the groups and where their markers are' => sub {
	my $body = body_of(
		legend => [
			{ label => 'England', colour => '#E41A1C', group => 'en' },
			{ label => 'France',  colour => '#377eb8', group => 'fr' },
			{ label => 'Big',     radius => $C{RADIUS} },
		],
		markers => sub {
			my $map = shift;
			$map->add_marker([ $C{LAT_A}, $C{LON_A} ], html => 'London', group => 'en');
			$map->add_circle_marker([ $C{LAT_B}, $C{LON_B} ], html => 'Paris', group => 'fr');
			$map->add_marker([ $C{LAT_B}, $C{LON_A} ], html => 'No group');
		},
	);
	my $parts = legend_parts($body);

	is_deeply($parts->{entries}, [
		{ label => 'England', colour => '#e41a1c', group => 'en' },
		{ label => 'France',  colour => '#377eb8', group => 'fr' },
		{ label => 'Big',     colour => '#3388ff', radius => "$C{RADIUS}" },
	], 'each entry, its colour lower-cased or defaulted, and a radius only where given');
	is_deeply($parts->{groups}, [ 'en', 'fr' ], 'the groups the markers named, in the order they were first seen');
	is($parts->{points}, "[[$C{LAT_A},$C{LON_A},0],[$C{LAT_B},$C{LON_B},1]]",
		'each grouped marker, pin or circle, by where it is and its group; an ungrouped one is not listed');

	like($body, qr/L\.control\(\{ position: 'topright' \}\)/, 'in the top right corner by default');
	like($body, qr/map\.on\('moveend', drawLegend\)/, 'drawn again after every move and zoom');
	like($body, qr/bounds\.contains/, 'listing what is inside the view');
	is(scalar(() = $body =~ /<script>/g), 1, 'still one script block, which Database::BI relies on');
};

subtest 'legend_position, legend_title and legend_empty' => sub {
	for my $position (qw(topright topleft bottomright bottomleft)) {
		like(body_of(legend => [ { label => 'x' } ], legend_position => $position),
			qr/L\.control\(\{ position: '$position' \}\)/, "$position is a corner");
	}
	my $body = body_of(legend => [ { label => 'x' } ], legend_title => "It's", legend_empty => 'Rien ici');
	like($body, qr/var legendTitle = 'It\\'s';/, 'the title is a JavaScript string');
	like($body, qr/var legendEmpty = 'Rien ici';/, 'and so is the text for an empty view');
	like(body_of(legend => [ { label => 'x' } ]), qr/var legendEmpty = 'Nothing in this view';/,
		'which says so in English by default');
};

subtest 'text in the key cannot become markup' => sub {
	my $body = body_of(
		legend       => [ { label => '</script><script>alert(1)</script>', group => '</script>' } ],
		legend_title => '</script><b>',
		markers      => sub { $_[0]->add_marker([ $C{LAT_A}, $C{LON_A} ], group => '</script>') },
	);
	is(scalar(() = $body =~ m{</script>}g), 1, 'the only </script> is the one that ends the block');
	like($body, qr/createTextNode\(e\.label\)/, 'labels are written as text');
	like($body, qr/textContent = legendTitle/, 'and so is the title');
	unlike($body, qr/innerHTML/, 'nothing is written as HTML');
};

subtest 'an empty key draws nothing' => sub {
	unlike(body_of(legend => []), qr/legendEntries/, 'no entries, no key');
};

subtest 'new() refuses a key it cannot draw' => sub {
	my @bad = (
		[ [ 'x' ],                                     qr/\Anew\(\): legend entry 1 is not a hashref/ ],
		[ [ { colour => '#fff' } ],                    qr/\Anew\(\): legend entry 1: label is required/ ],
		[ [ { label => '' } ],                         qr/\Anew\(\): legend entry 1: label is required/ ],
		[ [ { label => 'a' }, { label => 'b', colour => 'red' } ], qr/\Anew\(\): legend entry 2: invalid colour: red/ ],
		[ [ { label => 'a', radius => -1 } ],          qr/\Anew\(\): legend entry 1: radius must be a positive number/ ],
		[ [ { label => 'a', radius => 'big' } ],       qr/\Anew\(\): legend entry 1: radius must be a positive number/ ],
		[ [ { label => 'a', group => [] } ],           qr/\Anew\(\): legend entry 1: group must be a string/ ],
	);
	for my $case (@bad) {
		throws_ok { HTML::OSM->new(legend => $case->[0]) } $case->[1], "refused: $case->[1]";
	}
	throws_ok { HTML::OSM->new(legend_position => 'middle') } qr/\Anew\(\): invalid legend_position: middle/,
		'a position that is not a corner';
	lives_ok { HTML::OSM->new(legend => [ { label => 0 } ]) } 'a label of 0 is a label';
};

subtest 'a marker method refuses a group that is not a string' => sub {
	my $map = HTML::OSM->new();
	throws_ok { $map->add_marker([ $C{LAT_A}, $C{LON_A} ], group => {}) }
		qr/\Aadd_marker\(\): group must be a string/, 'add_marker';
	throws_ok { $map->add_circle_marker([ $C{LAT_A}, $C{LON_A} ], group => []) }
		qr/\Aadd_circle_marker\(\): group must be a string/, 'add_circle_marker';
	ok($map->add_marker([ $C{LAT_A}, $C{LON_A} ], group => 7), 'a number is a group');
	is($map->{coordinates}[0][4], '7', 'kept as text');
	ok($map->add_marker([ $C{LAT_B}, $C{LON_B} ]), 'a marker without one');
	is(scalar @{ $map->{coordinates}[1] }, 4, 'keeps the shape it always had');
};

subtest 'values from a clone are checked again when drawn' => sub {
	my $map = HTML::OSM->new()->new(
		legend          => [ { label => 'good' }, { colour => '#fff' }, 'nonsense', { label => 'bad', colour => 'red' } ],
		legend_position => 'middle',
	);
	$map->add_marker([ $C{LAT_A}, $C{LON_A} ]);
	push @{ $map->{coordinates} }, [ $C{LAT_B}, $C{LON_B}, 'x', undef, { not => 'a group' } ];

	my $body;
	my @warnings = warnings_of { (undef, $body) = $map->onload_render() };
	is_deeply(legend_parts($body)->{entries}, [ { label => 'good', colour => '#3388ff' } ], 'only the usable entry is drawn');
	like($body, qr/position: 'topright'/, 'an unknown position falls back to the top right');
	is(legend_parts($body)->{points}, '[]', 'a group that is not a string is dropped');
	is(scalar(grep { /leaving it out of the key/ } @warnings), 3, 'each bad entry is reported');
	is(scalar(grep { /invalid legend_position 'middle', using topright/ } @warnings), 1, 'and the position');

	my $not_a_list = HTML::OSM->new()->new(legend => 'x');
	$not_a_list->add_marker([ $C{LAT_A}, $C{LON_A} ]);
	my @w = warnings_of { (undef, $body) = $not_a_list->onload_render() };
	unlike($body, qr/legendEntries/, 'a legend that is not a list draws no key');
	is(scalar(grep { /legend must be an arrayref/ } @w), 1, 'and says why');
};

subtest 'fit => 1 opens the map on every marker' => sub {
	my $two = sub {
		my $map = shift;
		$map->add_marker([ $C{LAT_A}, $C{LON_A} ]);
		$map->add_circle_marker([ $C{LAT_B}, $C{LON_B} ]);
	};
	my $fit = qr/map\.fitBounds\(\[\[$C{LAT_B}, $C{LON_A}\], \[$C{LAT_A}, $C{LON_B}\]\], \{ padding: \[30, 30\], maxZoom: 7 \}\);/;

	my $body = body_of(fit => 1, zoom => 7, markers => $two);
	is(scalar(() = $body =~ /$fit/g), 2, 'the view is fitted to the pins and circles, zooming in no further than zoom, on load and on reset');
	like($body, qr/addEventListener\('click', function\(\) \{\s*map\.fitBounds/, 'reset fits them again');

	$body = body_of(zoom => 7, markers => $two);
	unlike($body, qr/fitBounds/, 'without fit the map opens at zoom around the midpoint, as before');
	like($body, qr/addEventListener\('click', function\(\) \{\s*map\.setView/, 'and reset goes back there');

	unlike(body_of(fit => 1, markers => sub { $two->($_[0]); $_[0]->center([ $C{LAT_A}, $C{LON_A} ]) }),
		qr/fitBounds/, 'a centre the caller set wins');

	my $map = HTML::OSM->new()->new(fit => 'no');
	$two->($map);
	unlike(($map->onload_render())[1], qr/fitBounds/, "a clone's 'no' counts as off");
};

restore_all();

done_testing();

#!/usr/bin/perl
# The categorical colour schemes, and the one definition of them.
#
# A chart draws its categories with the scheme's hex colours, inlined into the
# page by the snippet.  A map - or a legend, or a static renderer - colours the
# same categories in Perl, where there is no d3 to ask, so HTML::D3 keeps the
# palettes itself: categorical_schemes(), palette() and colour_at() read the same
# definition the chart snippets build their JS arrays from.  These tests hold
# that definition to the charts, and hold every chart to the definition.
#
# The names and the number of colours each scheme has are D3's, from the
# categorical directory of d3-scale-chromatic 3.x - the module d3 v7, which
# _head() loads, bundles:
# https://github.com/d3/d3-scale-chromatic/tree/main/src/categorical
# The colours are not written out here: they are read from palette(), because
# what this file checks is that a chart emits exactly what palette() hands a
# map.  t/d3-schemes.t is what checks palette() against d3 itself, when Node and
# d3 are installed.

use strict;
use warnings;

use Test::Most;

use_ok('HTML::D3');

# scheme => the d3 scheme it transcribes (for the messages), and how many colours
# d3 gives it.
my %D3_CATEGORICAL = (
	category10 => { d3 => 'd3.schemeCategory10', colours => 10 },
	tableau10  => { d3 => 'd3.schemeTableau10',  colours => 10 },
	set2       => { d3 => 'd3.schemeSet2',       colours =>  8 },
	set3       => { d3 => 'd3.schemeSet3',       colours => 12 },
	paired     => { d3 => 'd3.schemePaired',     colours => 12 },
);

# The scheme a chart draws with when it is not told which one to use.
my $DEFAULT_SCHEME = 'tableau10';
my $DEFAULT_COLOURS = _js_colours($DEFAULT_SCHEME);

my $chart = HTML::D3->new(title => 'Palette');

# ─────────────────────────────────────────────────────────────────────────────
# The vocabulary Perl is given.
# ─────────────────────────────────────────────────────────────────────────────

is_deeply(HTML::D3->categorical_schemes(), [sort keys %D3_CATEGORICAL],
	q{'categorical_schemes() lists the schemes D3 publishes, sorted alphabetically});

for my $scheme (sort keys %D3_CATEGORICAL) {
	my $colours = HTML::D3->palette($scheme);
	isa_ok($colours, 'ARRAY', "palette('$scheme')");
	is(scalar(@$colours), $D3_CATEGORICAL{$scheme}{'colours'},
		"palette('$scheme') has the $D3_CATEGORICAL{$scheme}{'colours'} colours D3 gives it");

	my @malformed = grep { !/^#[0-9a-f]{6}$/ } @$colours;
	is_deeply(\@malformed, [], "every colour of '$scheme' is a #rrggbb string")
		or diag(explain(\@malformed));

	my %seen;
	my @repeated = grep { $seen{$_}++ } @$colours;
	is_deeply(\@repeated, [], "no colour is repeated within '$scheme'")
		or diag(explain(\@repeated));
}

# The palette is handed out as a copy: a caller that sorts it, pads it or pushes
# a colour of its own onto it must not change what the next caller sees.
my $handed_out = HTML::D3->palette('set2');
push @$handed_out, '#000000';
is(scalar @{HTML::D3->palette('set2')}, $D3_CATEGORICAL{set2}{'colours'},
	'palette() hands out a copy, so a caller cannot add a colour to the scheme');

# The accessors are documented as class methods; they also have to work on an
# object, since that is how a caller holding a chart will reach for them.
is_deeply($chart->palette('set3'), HTML::D3->palette('set3'),
	'the class and an instance report the same palette');

# ─────────────────────────────────────────────────────────────────────────────
# The assignment: d3.scaleOrdinal cycles the palette in index order, and that is
# what makes category 3 in a map the colour category 3 had in the chart.
# ─────────────────────────────────────────────────────────────────────────────

for my $scheme (sort keys %D3_CATEGORICAL) {
	my $colours = HTML::D3->palette($scheme);
	my $count   = scalar(@$colours);

	is(HTML::D3->colour_at($scheme, 0), $colours->[0],
		"colour_at('$scheme', 0) is the first colour of the scheme");
	is(HTML::D3->colour_at($scheme, $count - 1), $colours->[-1],
		"colour_at('$scheme', $count - 1) is the last");
	is(HTML::D3->colour_at($scheme, $count), $colours->[0],
		"colour_at('$scheme', $count) wraps to the first, as a d3 ordinal scale does");
	is(HTML::D3->colour_at($scheme, 3 * $count + 2), $colours->[2],
		"colour_at('$scheme', ...) keeps wrapping, however far past the end");
}

# ─────────────────────────────────────────────────────────────────────────────
# The documented errors.  A misspelt scheme is refused rather than answered with
# the default scheme's colours: a map asking for 'Set2' wants to hear that it
# asked for the wrong thing, not to be silently coloured as if it had not.
# ─────────────────────────────────────────────────────────────────────────────

throws_ok { HTML::D3->palette('Set2') } qr/\QUnknown scheme: Set2\E/,
	'palette() dies on a scheme name that is not one';
throws_ok { HTML::D3->palette(undef) } qr/\QUnknown scheme: \E/,
	'palette() dies on no scheme at all';
throws_ok { HTML::D3->colour_at('nonsense', 0) } qr/\QUnknown scheme: nonsense\E/,
	'colour_at() dies on an unknown scheme';
throws_ok { HTML::D3->colour_at('set2', -1) } qr/^Colour index must be a non-negative integer/,
	'colour_at() dies on a negative index';
throws_ok { HTML::D3->colour_at('set2', 1.5) } qr/^Colour index must be a non-negative integer/,
	'colour_at() dies on a fractional index';
throws_ok { HTML::D3->colour_at('set2') } qr/^Colour index must be a non-negative integer/,
	'colour_at() dies when no index is given';

# ─────────────────────────────────────────────────────────────────────────────
# The charts draw with the definition.
#
# Every snippet that takes a scheme is rendered once per scheme the API names,
# and the JS it emits has to name that scheme in its lookup - the same one a map
# is handed - and, where it draws the colours directly, to hold the scheme's hex
# array exactly as palette() reports it.  That is what makes "the same data, the
# same scheme=" true for a chart and a map.
# ─────────────────────────────────────────────────────────────────────────────

my @PIE_DATA     = (['A', 1], ['B', 2], ['C', 3]);
my @STACKED_DATA = ({ cat => 'x', seg => 's', val => 1 });
my @TREEMAP_DATA = ({ path => 'a/b', value => 1 });
my @SERIES_DATA  = ({ name => 'A', data => [{ label => 'x', value => 1 }] });
my @SCATTER_DATA = ([1, 2, {}, { series => 's' }]);
my @BINNED_DATA  = ({ label => 'a', count => 3 });

subtest 'each snippet draws the scheme it is given with that scheme' => sub {
	for my $scheme (sort keys %D3_CATEGORICAL) {
		my $d3      = $D3_CATEGORICAL{$scheme}{'d3'};
		my $colours = _js_colours($scheme);

		my $pie = $chart->render_pie_chart_snippet(\@PIE_DATA, { color_scheme => $scheme })->{html};
		like($pie, qr/SCHEMES\['\Q$scheme\E'\]/, "pie chart looks '$scheme' up by name");
		like($pie, qr/\Q$colours\E/, "pie chart inlines the hex colours of $d3");

		my $stacked = $chart->render_stacked_bar_snippet(\@STACKED_DATA, { scheme => $scheme })->{html};
		like($stacked, qr/SCHEMES\['\Q$scheme\E'\]/, "stacked bar looks '$scheme' up by name");

		my $treemap = $chart->render_treemap_snippet(\@TREEMAP_DATA, { scheme => $scheme })->{html};
		like($treemap, qr/SCHEMES\['\Q$scheme\E'\]/, "treemap looks '$scheme' up by name");

		my $multi = $chart->render_multi_series_line_chart_snippet(\@SERIES_DATA, { scheme => $scheme })->{html};
		like($multi, qr/scaleOrdinal\(\Q$colours\E\)/, "multi-series line chart draws '$scheme' with its hex array");

		my $scatter = $chart->render_scatter_chart_snippet(\@SCATTER_DATA, { colour_by_series => 1, scheme => $scheme })->{html};
		like($scatter, qr/scaleOrdinal\(\Q$colours\E\)/, "scatter chart draws '$scheme' with its hex array");

		# The binned histogram fills its bars with the scheme's first colour:
		# colour_at($scheme, 0), the colour a map shading the first category by
		# hand uses, so the histogram and the map start from the same one.
		my $histogram = $chart->render_histogram_snippet(\@BINNED_DATA, { binned => 1, scheme => $scheme })->{html};
		like($histogram, qr/\Q$colours\E\[0\]/, "binned histogram fills with the first colour of '$scheme'");
	}
};

# The lookup table is generated from the definition, so a scheme added to the
# vocabulary reaches every snippet that offers one rather than the snippets
# somebody remembered to edit.  Its values are the colours palette() returns, as
# literals: the browser is not asked to look up a d3.scheme* expression, which
# could change under the page.
subtest 'the table the snippets draw from holds every scheme, with its hex colours' => sub {
	my $pie = $chart->render_pie_chart_snippet(\@PIE_DATA)->{html};

	my ($table) = $pie =~ /SCHEMES = \{([^}]*)\}/;
	ok(defined($table), 'the pie snippet looks its colours up in a SCHEMES table');

	my %emitted;
	$emitted{$1} = $2 while(defined($table) && $table =~ /(\w+):\s*(\[[^\]]*\])/g);
	is_deeply(\%emitted, { map { $_ => _js_colours($_) } keys %D3_CATEGORICAL },
		'and every scheme is in it, as the hex array palette() hands out')
		or diag(explain(\%emitted));

	unlike($pie, qr/d3\.scheme/,
		'and no scheme is emitted as a d3.scheme* expression');
};

# An unknown scheme is drawn with the documented default.  The capitalisation
# this replaced produced d3.schemeNonsense, an undefined function in the
# browser, so the fallback is asserted to be the default and nothing invented.
subtest 'an unknown scheme falls back to the default, and reads no d3.scheme' => sub {
	my %renders = (
		'pie chart' => sub { $chart->render_pie_chart_snippet(\@PIE_DATA, { color_scheme => $_[0] })->{html} },
		'stacked bar' => sub { $chart->render_stacked_bar_snippet(\@STACKED_DATA, { scheme => $_[0] })->{html} },
		'treemap' => sub { $chart->render_treemap_snippet(\@TREEMAP_DATA, { scheme => $_[0] })->{html} },
		'multi-series line chart' => sub { $chart->render_multi_series_line_chart_snippet(\@SERIES_DATA, { scheme => $_[0] })->{html} },
		'scatter chart' => sub { $chart->render_scatter_chart_snippet(\@SCATTER_DATA, { colour_by_series => 1, scheme => $_[0] })->{html} },
		'binned histogram' => sub { $chart->render_histogram_snippet(\@BINNED_DATA, { binned => 1, scheme => $_[0] })->{html} },
	);

	for my $name (sort keys %renders) {
		my $html = $renders{$name}->('nonsense');
		like($html, qr/\Q$DEFAULT_COLOURS\E/, "$name with an unknown scheme draws the default palette");
		unlike($html, qr/d3\.scheme/, "$name with an unknown scheme reads no D3 palette");
	}

	# Being asked for is not a way into the vocabulary: looking a name up must
	# not plant an entry for it - an entry with no expression in it - which
	# would then be published by categorical_schemes() and drawn from.
	is_deeply(HTML::D3->categorical_schemes(), [sort keys %D3_CATEGORICAL],
		'an unknown scheme is not added to the vocabulary by being asked for')
		or diag(explain(HTML::D3->categorical_schemes()));
};

# ─────────────────────────────────────────────────────────────────────────────
# The page does not ask d3 for a palette.
#
# A chart that drew with d3.schemeCategory10 would change colour when d3 did,
# and would disagree with a map shading the same categories from palette().
# Every colour is inlined from the definition instead, so the module's code has
# to hold no d3.scheme* expression at all.  Prose is not code - a comment or POD
# naming the scheme a palette transcribes is stripped before the count.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'the module reads no palette from d3' => sub {
	my %written;
	my $code = _module_code();
	$written{$1}++ while $code =~ /(d3\.scheme\w*)/g;

	is_deeply(\%written, {},
		'every chart inlines its colours from the definition, and reads no d3.scheme* palette')
		or diag(explain(\%written));
};

done_testing();

# A scheme's colours as the JS array a snippet inlines, built from palette() -
# the same accessor a map calls - so an assertion here is that the chart emits
# the colours the API hands out.
sub _js_colours
{
	my ($scheme) = @_;

	return '[' . join(', ', map { "'$_'" } @{HTML::D3->palette($scheme)}) . ']';
}

# The module's code: its POD and its comments removed, so that a sentence about
# a scheme - or a hex colour in a comment - is not mistaken for a definition.
sub _module_code
{
	my $path = $INC{'HTML/D3.pm'} or die 'HTML::D3 is not loaded';
	open(my $fh, '<', $path) or die "Can't read $path: $!";
	my $source = do { local $/; <$fh> };
	close($fh);

	$source =~ s/^=\w+.*?^=cut\s*$//msg;	# POD blocks
	$source =~ s/^\s*#.*$//mg;		# comments

	return $source;
}

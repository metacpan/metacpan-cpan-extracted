#!/usr/bin/env perl
# The categorical colour schemes, and the one definition of them.
#
# A chart draws its categories with d3.scheme*, in the browser.  A map - or a
# legend, or a static renderer - colours the same categories in Perl, where
# there is no d3 to ask, so HTML::D3 keeps the palettes itself:
# categorical_schemes(), palette() and colour_at() read the same definition that
# the chart snippets build their JS lookup from.  These tests hold that
# definition to D3's published schemes, and hold every chart to the definition.
#
# The names, the D3 expressions and the number of colours each scheme has are
# D3's, from the categorical directory of d3-scale-chromatic 3.x - the module
# d3 v7, which _head() loads, bundles:
# https://github.com/d3/d3-scale-chromatic/tree/main/src/categorical
# They are written out here rather than read back from the module, so that this
# file is an oracle rather than an echo: swap one palette for another, or draw a
# chart with a scheme nobody asked for, and it fails.

use strict;
use warnings;

use Test::Most;

use_ok('HTML::D3');

# scheme => the D3 expression a chart must draw it with, and how many colours D3
# gives it.
my %D3_CATEGORICAL = (
	category10 => { js => 'd3.schemeCategory10', colours => 10 },
	tableau10  => { js => 'd3.schemeTableau10',  colours => 10 },
	set2       => { js => 'd3.schemeSet2',       colours =>  8 },
	set3       => { js => 'd3.schemeSet3',       colours => 12 },
	paired     => { js => 'd3.schemePaired',     colours => 12 },
);

# The scheme a chart draws with when it is not told which one to use.
my $DEFAULT_SCHEME = 'tableau10';
my $DEFAULT_JS     = $D3_CATEGORICAL{$DEFAULT_SCHEME}{'js'};

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
# and the JS it emits has to name that scheme's D3 expression - the same one a
# map is handed - and to look it up under the name the caller passed.  That is
# what makes "the same data, the same scheme=" true for a chart and a map.
# ─────────────────────────────────────────────────────────────────────────────

my @PIE_DATA     = (['A', 1], ['B', 2], ['C', 3]);
my @STACKED_DATA = ({ cat => 'x', seg => 's', val => 1 });
my @TREEMAP_DATA = ({ path => 'a/b', value => 1 });
my @SERIES_DATA  = ({ name => 'A', data => [{ label => 'x', value => 1 }] });
my @SCATTER_DATA = ([1, 2, {}, { series => 's' }]);
my @BINNED_DATA  = ({ label => 'a', count => 3 });

subtest 'each snippet draws the scheme it is given with that scheme' => sub {
	for my $scheme (sort keys %D3_CATEGORICAL) {
		my $js = $D3_CATEGORICAL{$scheme}{'js'};

		my $pie = $chart->render_pie_chart_snippet(\@PIE_DATA, { color_scheme => $scheme })->{html};
		like($pie, qr/\Q$js\E/, "pie chart draws '$scheme' with $js");
		like($pie, qr/SCHEMES\['\Q$scheme\E'\]/, "pie chart looks '$scheme' up by name");

		my $stacked = $chart->render_stacked_bar_snippet(\@STACKED_DATA, { scheme => $scheme })->{html};
		like($stacked, qr/\Q$js\E/, "stacked bar draws '$scheme' with $js");
		like($stacked, qr/SCHEMES\['\Q$scheme\E'\]/, "stacked bar looks '$scheme' up by name");

		my $treemap = $chart->render_treemap_snippet(\@TREEMAP_DATA, { scheme => $scheme })->{html};
		like($treemap, qr/\Q$js\E/, "treemap draws '$scheme' with $js");
		like($treemap, qr/SCHEMES\['\Q$scheme\E'\]/, "treemap looks '$scheme' up by name");

		my $multi = $chart->render_multi_series_line_chart_snippet(\@SERIES_DATA, { scheme => $scheme })->{html};
		like($multi, qr/scaleOrdinal\(\Q$js\E\)/, "multi-series line chart draws '$scheme' with $js");

		my $scatter = $chart->render_scatter_chart_snippet(\@SCATTER_DATA, { colour_by_series => 1, scheme => $scheme })->{html};
		like($scatter, qr/scaleOrdinal\(\Q$js\E\)/, "scatter chart draws '$scheme' with $js");

		# The binned histogram fills its bars with the scheme's first colour:
		# colour_at($scheme, 0), the colour a map shading the first category by
		# hand uses, so the histogram and the map start from the same one.
		my $histogram = $chart->render_histogram_snippet(\@BINNED_DATA, { binned => 1, scheme => $scheme })->{html};
		like($histogram, qr/\Q$js\E\[0\]/, "binned histogram fills with the first colour of '$scheme'");
	}
};

# The lookup table is generated from the definition, so a scheme added to the
# vocabulary reaches every snippet that offers one rather than the snippets
# somebody remembered to edit.
subtest 'the table the snippets draw from holds every scheme, correctly paired' => sub {
	my $pie = $chart->render_pie_chart_snippet(\@PIE_DATA)->{html};

	my ($table) = $pie =~ /SCHEMES = \{([^}]*)\}/;
	ok(defined($table), 'the pie snippet looks its colours up in a SCHEMES table');

	my %emitted = defined($table) ? ($table =~ /(\w+):\s*(d3\.scheme\w+)/g) : ();
	is_deeply(\%emitted, { map { $_ => $D3_CATEGORICAL{$_}{'js'} } keys %D3_CATEGORICAL },
		'and every scheme is in it, paired with that scheme\'s D3 expression')
		or diag(explain(\%emitted));
};

# An unknown scheme is drawn with the documented default.  The capitalisation
# this replaced produced d3.schemeNonsense, an undefined function in the
# browser, so the fallback is asserted to be the default and nothing invented.
subtest 'an unknown scheme falls back to the default, and invents no d3.scheme' => sub {
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
		like($html, qr/\Q$DEFAULT_JS\E/, "$name with an unknown scheme draws the default scheme");
		unlike($html, qr/d3\.scheme(?!Category10|Tableau10|Set2|Set3|Paired)/,
			"$name with an unknown scheme names no scheme outside the vocabulary");
	}

	# Being asked for is not a way into the vocabulary: looking a name up must
	# not plant an entry for it - an entry with no expression in it - which
	# would then be published by categorical_schemes() and drawn from.
	is_deeply(HTML::D3->categorical_schemes(), [sort keys %D3_CATEGORICAL],
		'an unknown scheme is not added to the vocabulary by being asked for')
		or diag(explain(HTML::D3->categorical_schemes()));
};

# ─────────────────────────────────────────────────────────────────────────────
# No palette is written down anywhere else.
#
# The schemes are a definition, not a convention: each one's D3 expression is
# written once, in the table at the top of the module, and every chart reads it
# from there - a snippet with a scheme option, a full-page chart that has always
# drawn category10, whatever is added tomorrow.  So the module's *code* has to
# hold each of the five expressions exactly once and no sixth: a second copy is
# a palette that a change to the first one leaves behind, which is the drift
# this file exists to catch.  Prose is not code - a sentence about a scheme, or
# a hex colour in a comment, is stripped before the count.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'each scheme is written down once, and only the five are written' => sub {
	my %written;
	my $code = _module_code();
	$written{$1}++ while $code =~ /(d3\.scheme\w+)/g;

	is_deeply(\%written, { map { $_->{'js'} => 1 } values %D3_CATEGORICAL },
		"each published scheme is the module's only mention of that expression")
		or diag(explain(\%written));
};

done_testing();

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

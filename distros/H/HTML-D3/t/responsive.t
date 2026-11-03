#!/usr/bin/env perl

# A responsive chart's <svg> gets a viewBox and width="100%", and no height:
# the height follows the viewBox's proportions.  Up to 0.27 it also had
# height="auto", which is not a valid value for the SVG height attribute;
# Chromium logged "Expected length, "auto"" for every chart and ignored it.
#
# Every method that takes the responsive option is drawn here both ways, per
# call and from the object, and every <svg> it writes is checked: in responsive
# mode no height at all, otherwise a height and width that are lengths.

use warnings;
use strict;

use HTML::D3;
use Test::Most;

my $pairs  = [ [ 'January', 1000 ], [ 'February', 1200 ], [ 'March', 950 ] ];
my $points = [ [ 1, 2 ], [ 2, 4 ], [ 3, 3 ] ];

# method => data it draws
my %DRAW = (
	render_pie_chart_snippet            => $pairs,
	render_bar_chart_snippet            => $pairs,
	render_line_chart_snippet           => $pairs,
	render_zoomable_line_chart_snippet  => $pairs,
	render_scatter_chart_snippet        => $points,
	render_heatmap_snippet              => [ [ 'a', 'x', 1 ], [ 'b', 'x', 2 ], [ 'a', 'y', 3 ] ],
	render_multi_series_line_chart_snippet => [
		{ name => 'North', data => [ { label => 'Jan', value => 1 }, { label => 'Feb', value => 2 } ] },
		{ name => 'South', data => [ { label => 'Jan', value => 3 }, { label => 'Feb', value => 1 } ] },
	],
	render_stacked_bar_snippet => [
		{ cat => 'A', seg => 'x', val => 1 }, { cat => 'A', seg => 'y', val => 2 },
		{ cat => 'B', seg => 'x', val => 3 },
	],
	render_combo_snippet => [
		{ x => 'Jan', bar_val => 1, line_val => 2 }, { x => 'Feb', bar_val => 3, line_val => 1 },
	],
	render_treemap_snippet => [ { path => 'Root/A', value => 3 }, { path => 'Root/B', value => 5 } ],
	render_histogram_snippet => [ 1, 2, 2, 3, 3, 3, 4, 5 ],
	# Pre-binned counts are drawn by a code path of their own.
	'render_histogram_snippet binned' => [
		{ label => '[0,10)', count => 3 }, { label => '[10,20)', count => 5, lo => 10, hi => 20 },
	],
);

# _svg_tags($html) -> the opening <svg ...> tags in $html
sub _svg_tags { return $_[0] =~ /(<svg\b[^>]*>)/g }

for my $name (sort keys %DRAW) {
	my ($method, $binned) = split / /, $name;
	my %extra = $binned ? (binned => 1) : ();
	for my $how ('per call', 'from the object') {
		my $chart = HTML::D3->new(width => 640, height => 400,
			($how eq 'from the object' ? (responsive => 1) : ()));
		my $opts = { %extra, ($how eq 'per call' ? (responsive => 1) : ()) };
		my $html = $chart->$method($DRAW{$name}, (%$opts ? $opts : ()))->{html};
		my @svg = _svg_tags($html);
		ok(scalar(@svg), "$name ($how) writes an <svg>") or next;
		my ($chart_svg) = grep { /viewBox=/ } @svg;
		ok($chart_svg, "$name ($how): responsive, it has a viewBox") or next;
		like($chart_svg, qr/\bwidth="100%"/, '  and width="100%"');
		unlike($chart_svg, qr/\sheight=/, '  and no height, which follows the viewBox');
		unlike($html, qr/height="auto"/, '  nor height="auto" anywhere');
	}

	my $html = HTML::D3->new(width => 640, height => 400)->$method($DRAW{$name}, (%extra ? {%extra} : ()))->{html};
	for my $svg (_svg_tags($html)) {
		for my $attr (qw(width height)) {
			my ($v) = $svg =~ /\s$attr="([^"]*)"/ or next;
			like($v, qr/\A\d+(?:\.\d+)?(?:px|%)?\z/, "$name (fixed): $attr=\"$v\" is a length");
		}
	}
}

done_testing();

#!/usr/bin/env perl

# Text in a tooltip or a legend entry.
#
# A tooltip is markup -- its bold and its line breaks -- so it is set with
# .html(), and the text in it is the caller's: labels, series names, category
# and segment names, often read from a data file.  Before 0.29 the stacked bar,
# combo and treemap snippets, the line chart snippets, the full-page line
# charts with tooltips and the pie snippet's legend put that text in as it
# was, so a label holding <img src=x onerror=...> ran when the chart was
# hovered or, for the pie legend, drawn.
#
# Each method's script must define esc() and pass every piece of caller text
# through it.  The browser is not run here: each case names the escaped form
# its script must hold and the raw form it must not.

use strict;
use warnings;

use Test::Most;

use_ok('HTML::D3');

my $chart = HTML::D3->new(width => 600, height => 400);

my @series = ({ name => 'S', data => [ { label => 'A', value => 1 } ] });

my @cases = (
	[ 'render_stacked_bar_snippet', [ [ { cat => 'A', seg => 's', val => 1 } ] ],
		[ qr/esc\(d\.data\.cat\)/, qr/esc\(seg\)/ ],
		[ qr/"<b>"\+d\.data\.cat\+/, qr/\+seg\+": "/ ] ],
	[ 'render_combo_snippet', [ [ { x => 'A', bar_val => 1, line_val => 2 } ] ],
		[ qr/esc\(d\.x\)/, qr/esc\(barLabel\)/, qr/esc\(lineLabel\)/ ],
		[ qr/"<b>"\+d\.x\+/, qr/\+barLabel\+/, qr/\+lineLabel\+/ ] ],
	[ 'render_treemap_snippet', [ [ { path => 'R/A', value => 1 } ] ],
		[ qr/esc\(name\)/ ],
		[ qr/"<b>"\+name\+/ ] ],
	[ 'render_line_chart_snippet', [ [ [ 'A', 1, { k => 'v' } ] ] ],
		[ qr/\$\{esc\(d\.label\)\}/, qr/\$\{esc\(d\.value\)\}/, qr/\$\{esc\(k\)\}/, qr/\$\{esc\(v\)\}/ ],
		[ qr/\$\{d\.label\}/, qr/\$\{k\}/, qr/\$\{v\}/ ] ],
	[ 'render_zoomable_line_chart_snippet', [ [ [ 'A', 1, { k => 'v' } ] ] ],
		[ qr/\$\{esc\(d\.label\)\}/, qr/\$\{esc\(d\.value\)\}/, qr/\$\{esc\(k\)\}/, qr/\$\{esc\(v\)\}/ ],
		[ qr/\$\{d\.label\}/, qr/\$\{k\}/, qr/\$\{v\}/ ] ],
	[ 'render_line_chart_with_tooltips', [ [ [ 'A', 1 ] ] ],
		[ qr/\$\{esc\(d\.label\)\}/, qr/\$\{esc\(d\.value\)\}/ ],
		[ qr/\$\{d\.label\}/, qr/\$\{d\.value\}/ ] ],
	(map {
		[ $_, [ \@series ],
			[ qr/\$\{esc\(series\.name\)\}/, qr/\$\{esc\(d\.label\)\}/, qr/\$\{esc\(d\.value\)\}/ ],
			[ qr/\$\{series\.name\}/, qr/\$\{d\.label\}/, qr/\$\{d\.value\}/ ] ]
	} qw(render_multi_series_line_chart_with_tooltips
	     render_multi_series_line_chart_with_animated_tooltips
	     render_multi_series_line_chart_with_legends
	     render_multi_series_line_chart_with_interactive_legends)),
	[ 'render_multi_series_line_chart_snippet', [ \@series ],
		[ qr/esc\(d\.label\)/, qr/esc\(s\.name\)/, qr/esc\(d\.value\)/ ],
		[ qr/\+d\.value\+/ ] ],
	[ 'render_pie_chart_snippet', [ [ [ 'A', 1 ] ], { legend => 1, separator => ':' } ],
		[ qr/esc\(d\.data\.label\) \+ ' ' \+ esc\(':'\)/ ],
		[ qr/' ' \+ d\.data\.label \+/ ] ],
);

for my $case (@cases) {
	my ($method, $args, $want, $never) = @$case;
	subtest $method => sub {
		my $out  = $chart->$method(@$args);
		my $html = ref($out) ? $out->{html} : $out;
		like($html, qr/function esc\(s\)/, 'defines esc()');
		like($html, $_, "escapes: $_") for @$want;
		unlike($html, $_, "never raw: $_") for @$never;
	};
}

subtest 'esc() covers the characters markup needs' => sub {
	my $html = $chart->render_combo_snippet([ { x => 'A', bar_val => 1, line_val => 2 } ])->{html};
	my ($esc) = $html =~ /(function esc\(s\) \{[^\n]*\})/;
	ok($esc, 'found');
	like($esc, qr/&amp;/, '&');
	like($esc, qr/&lt;/,  '<');
	like($esc, qr/&gt;/,  '>');
	like($esc, qr/&quot;/, '"');
};

done_testing();

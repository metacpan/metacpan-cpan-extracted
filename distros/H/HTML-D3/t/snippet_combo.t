#!/usr/bin/env perl

use warnings;
use strict;

use Test::Most tests => 36;
use_ok('HTML::D3');

my $chart = HTML::D3->new(width => 900, height => 500, title => 'Combo Chart Test');
isa_ok($chart, 'HTML::D3', 'chart object created');

my @data = (
	{ x => 'Q1', bar_val => 1200, line_val => 38.5 },
	{ x => 'Q2', bar_val => 1500, line_val => 41.2 },
	{ x => 'Q3', bar_val => 1100, line_val => 36.0 },
	{ x => 'Q4', bar_val => 1800, line_val => 44.8 },
);

# ── Basic return shape ────────────────────────────────────────────────────────
my $fragment;
lives_ok { $fragment = $chart->render_combo_snippet(\@data) } 'Renders without error';
is(ref($fragment), 'HASH', 'Returns a hash reference');
is($fragment->{svg_id}, 'combo_chart', 'svg_id is "combo_chart"');

my $html = $fragment->{html};
like($html, qr/<svg id="combo_chart"/, 'SVG element has correct id');
like($html, qr/id="combo_chart_tip"/, 'Tooltip div present');
like($html, qr/d3\.scaleBand/, 'Uses d3.scaleBand for X axis');
like($html, qr/d3\.scaleLinear/, 'Uses d3.scaleLinear for Y axes');
like($html, qr/axisRight/, 'Has right Y axis (axisRight)');
like($html, qr/axisLeft/,  'Has left Y axis (axisLeft)');
like($html, qr/cc-bar/, 'Has bar class');
like($html, qr/cc-dot/, 'Has dot class for line series');
like($html, qr/Q1/, 'X category Q1 in output');
like($html, qr/1800/, 'Bar value 1800 in data');
unlike($html, qr/<!DOCTYPE/i, 'No DOCTYPE (snippet)');
unlike($html, qr/<html/i,     'No <html> wrapper');
unlike($html, qr{https://d3js\.org}, 'No CDN tag');

# ── id opt ────────────────────────────────────────────────────────────────────
my $custom = $chart->render_combo_snippet(\@data, { id => 'mycombo' });
is($custom->{svg_id}, 'mycombo', 'id opt overrides svg_id');
like($custom->{html}, qr/id="mycombo"/, 'Custom id in SVG element');

# ── custom cols ───────────────────────────────────────────────────────────────
my @custom_data = (
	{ period => 'Jan', revenue => 500, margin => 0.2 },
	{ period => 'Feb', revenue => 600, margin => 0.25 },
);
my $custom_cols = $chart->render_combo_snippet(\@custom_data, {
	x_col => 'period', bar_col => 'revenue', line_col => 'margin',
	bar_label => 'Revenue', line_label => 'Margin',
})->{html};
like($custom_cols, qr/Revenue/, 'bar_label appears in output');
like($custom_cols, qr/Margin/,  'line_label appears in output');

# ── custom colours ────────────────────────────────────────────────────────────
my $colored = $chart->render_combo_snippet(\@data, {
	bar_color => '#1a48c8', line_color => '#e87722',
})->{html};
like($colored, qr/#1a48c8/, 'bar_color applied');
like($colored, qr/#e87722/, 'line_color applied');

# ── tooltip </b> safety ───────────────────────────────────────────────────────
unlike($html, qr{</b>}, 'No raw </b> inside script (html-tidy safety)');
like($html, qr{<\\/b>}, 'Has escaped <\\/b> in tooltip');

# ── responsive opt ────────────────────────────────────────────────────────────
my $resp  = $chart->render_combo_snippet(\@data, { responsive => 1 })->{html};
like($resp, qr/viewBox=/, 'responsive opt produces viewBox');
my $fixed = $chart->render_combo_snippet(\@data)->{html};
like($fixed, qr/width="900"/, 'Default: fixed pixel width');

# ── validation errors ─────────────────────────────────────────────────────────
throws_ok { $chart->render_combo_snippet('not-an-arrayref') }
	qr/Data must be an array of hashes/, 'Dies on non-arrayref';
throws_ok { $chart->render_combo_snippet([ 'scalar' ]) }
	qr/Each data point must be a hash reference/, 'Dies on non-hashref row';
throws_ok { $chart->render_combo_snippet([ { x => 'Q1', bar_val => 'abc', line_val => 1 } ]) }
	qr/Bar value must be numeric/, 'Dies on non-numeric bar value';
throws_ok { $chart->render_combo_snippet([ { x => 'Q1', bar_val => 1, line_val => 'abc' } ]) }
	qr/Line value must be numeric/, 'Dies on non-numeric line value';

# ── scheme (0.29) ─────────────────────────────────────────────────────────────
subtest 'scheme gives the bars its first colour and the line its second' => sub {
	my $h = $chart->render_combo_snippet(\@data, { scheme => 'set2' })->{html};
	is(HTML::D3->colour_at('set2', 0), '#66c2a5', 'set2 first colour');
	like($h, qr/var barColor\s*=\s*"#66c2a5"/,  'bars take colour_at(set2, 0)');
	like($h, qr/var lineColor\s*=\s*"#fc8d62"/, 'line takes colour_at(set2, 1)');
};

subtest 'an explicit colour beats the scheme' => sub {
	my $h = $chart->render_combo_snippet(\@data, { scheme => 'set2', bar_color => 'black' })->{html};
	like($h, qr/var barColor\s*=\s*"black"/,    'bar_color wins');
	like($h, qr/var lineColor\s*=\s*"#fc8d62"/, 'the line still takes the scheme');
	$h = $chart->render_combo_snippet(\@data, { scheme => 'set2', line_color => '#123456' })->{html};
	like($h, qr/var barColor\s*=\s*"#66c2a5"/,  'the bars still take the scheme');
	like($h, qr/var lineColor\s*=\s*"#123456"/, 'line_color wins');
};

subtest 'a name that is not a scheme leaves the defaults' => sub {
	for my $bad ('Blues', 'nope', q{set2"];alert(1)//}, ['set2']) {
		my $h = $chart->render_combo_snippet(\@data, { scheme => $bad })->{html};
		like($h, qr/var barColor\s*=\s*"steelblue"/, 'bars steelblue');
		like($h, qr/var lineColor\s*=\s*"#e15759"/,  'line #e15759');
		unlike($h, qr/alert\(1\)/, 'the name is nowhere in the page');
	}
};

subtest 'tooltip text is escaped' => sub {
	my $h = $chart->render_combo_snippet(\@data)->{html};
	like($h, qr/function esc\(s\)/, 'esc() defined');
	is(() = $h =~ /\.html\("<b>"\+esc\(d\.x\)\+[^;]*esc\(barLabel\)[^;]*esc\(lineLabel\)/g, 2,
		'both tooltips escape the category and the labels');
};

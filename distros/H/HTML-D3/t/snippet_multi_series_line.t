#!/usr/bin/env perl

use warnings;
use strict;

use Test::Most tests => 40;
use_ok('HTML::D3');

my $chart = HTML::D3->new(width => 800, height => 600, title => 'Multi Series Test');

# Two series that deliberately do not share the same label set: the X domain
# must be the union of both, in first-seen order.
my @series = (
	{
		name => 'North',
		data => [
			{ label => 'January',  value => 1_000 },
			{ label => 'February', value => 1_200 },
		],
	},
	{
		name => 'South',
		data => [
			{ label => 'January', value => 500 },
			{ label => 'March',   value => 750 },
		],
	},
);

isa_ok($chart, 'HTML::D3', 'chart object created');

# ── Basic return shape ────────────────────────────────────────────────────────
my $fragment;
lives_ok { $fragment = $chart->render_multi_series_line_chart_snippet(\@series) }
	'Renders without error';
is(ref($fragment), 'HASH', 'Returns a hash reference');
is($fragment->{svg_id}, 'chart', 'svg_id is "chart"');

my $html = $fragment->{html};
like($html, qr/<svg id="chart"/, 'SVG element has id="chart"');
like($html, qr/id="chart_tip"/, 'Tooltip div present');
like($html, qr/var series = /, 'Series data embedded as JSON');
like($html, qr/"name":"North"/, 'First series name present in JSON');
like($html, qr/"value":1000/, 'First series value present in JSON');
like($html, qr/d3\.scalePoint/, 'Uses d3.scalePoint for the X axis');
like($html, qr/d3\.line\(\)/,   'Uses d3.line() for the paths');
like($html, qr/msl-line/,       'Line class present');
like($html, qr/Array\.from\(new Set\(series\.flatMap/,
	'X domain is the union of every series\' labels');
like($html, qr/d3\.schemeTableau10/, 'Default scheme is tableau10');
unlike($html, qr/<!DOCTYPE/i, 'No DOCTYPE (snippet)');
unlike($html, qr/<html/i,     'No <html> wrapper');
unlike($html, qr/<head/i,     'No <head> element');
unlike($html, qr/<body/i,     'No <body> element');
unlike($html, qr{https://d3js\.org}, 'No D3 CDN tag');
like($html, qr/function esc\(/, 'XSS escape function present');
ok(utf8::is_utf8($html) || $html !~ /[^\x00-\x7f]/, 'Returns Perl character string');

# ── opts ──────────────────────────────────────────────────────────────────────
my $opts_html = $chart->render_multi_series_line_chart_snippet(\@series, {
	x_label    => 'Month',
	y_label    => 'Sales',
	scheme     => 'category10',
	id         => 'ms',
	responsive => 1,
})->{html};
like($opts_html, qr/Month/,       'x_label embedded');
like($opts_html, qr/Sales/,       'y_label embedded');
like($opts_html, qr/d3\.schemeCategory10/, 'scheme opt selects the D3 scheme');
like($opts_html, qr/<svg id="ms"/, 'id opt overrides the svg id');
like($opts_html, qr/viewBox=/,    'responsive opt produces a viewBox');
like($opts_html, qr/msl-axis-label/, 'Axis label class present');

# ── animated => 1 ─────────────────────────────────────────────────────────────
my $anim_html = $chart->render_multi_series_line_chart_snippet(\@series, { animated => 1 })->{html};
like($anim_html, qr/stroke-dashoffset/,      'animated: dash-offset technique present');
like($anim_html, qr/prefers-reduced-motion/, 'animated: reduced-motion guard present');
unlike($html, qr/prefers-reduced-motion/,    'Default: no animation code');

# ── one line (and one dot set) per series ─────────────────────────────────────
like($html, qr/series\.forEach\(function\(s,i\)\{/, 'Paths are emitted per series');
like($html, qr/\.attr\("class","msl-line"\)/,       'Line path class set');
like($html, qr/\.attr\("class","msl-dot msl-dot-"/, 'Dots are bound per series');

# ── interactive legend ────────────────────────────────────────────────────────
like($html, qr/msl-leg-item/, 'Clickable legend rows present');
like($html, qr/\.style\("opacity", vis \? 0 : 1\)/, 'Legend click toggles series opacity');

# ── validation errors ─────────────────────────────────────────────────────────
throws_ok { $chart->render_multi_series_line_chart_snippet('not an array') }
	qr/Data must be an array of series/, 'Non-arrayref data dies';
throws_ok { $chart->render_multi_series_line_chart_snippet(['not_hash']) }
	qr/Each series must be a hashref with name and data/, 'Non-hashref series dies';
throws_ok { $chart->render_multi_series_line_chart_snippet([{ name => 'A' }]) }
	qr/Each series must be a hashref with name and data/, 'Series without data dies';
throws_ok { $chart->render_multi_series_line_chart_snippet([{ data => [] }]) }
	qr/Each series must be a hashref with name and data/, 'Series without name dies';

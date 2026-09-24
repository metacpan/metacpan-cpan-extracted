#!/usr/bin/env perl

use warnings;
use strict;

use Test::Most tests => 32;
use_ok('HTML::D3');

my $chart = HTML::D3->new(
	width  => 800,
	height => 600,
	title  => 'Scatter Test',
);

my @data = (
	[10, 20],
	[30, 40],
	[50, 15],
	[70, 55],
);

isa_ok($chart, 'HTML::D3', 'chart object created');

# ── Basic return shape ────────────────────────────────────────────────────────
my $fragment;
lives_ok { $fragment = $chart->render_scatter_chart_snippet(\@data) } 'Renders without error';
is(ref($fragment), 'HASH', 'Returns a hash reference');
is($fragment->{svg_id}, 'scatter_chart', 'svg_id is "scatter_chart"');

my $html = $fragment->{html};
like($html, qr/<svg id="scatter_chart"/, 'SVG element has id="scatter_chart"');
like($html, qr/d3\.scaleLinear/,         'Uses d3.scaleLinear for axes');
like($html, qr/sc-circle/,              'Circle class present');
like($html, qr/mouseover/,              'Mouseover handler present');
like($html, qr/function esc\(/,         'XSS escape function present');
unlike($html, qr/<!DOCTYPE/i,           'No DOCTYPE (snippet)');
unlike($html, qr/<html/i,               'No <html> wrapper');
unlike($html, qr/<head/i,               'No <head> element');
unlike($html, qr/<body/i,               'No <body> element');
unlike($html, qr{https://d3js\.org},    'No D3 CDN tag');
ok(utf8::is_utf8($html) || $html !~ /[^\x00-\x7f]/, 'Returns Perl character string');

# ── Data embedding ────────────────────────────────────────────────────────────
like($html, qr/"x":10/, 'First point x=10 in JSON');
like($html, qr/"y":20/, 'First point y=20 in JSON');

# ── x_label and y_label ──────────────────────────────────────────────────────
my $labels_html = $chart->render_scatter_chart_snippet(\@data, {
	x_label => 'Time (s)', y_label => 'Speed',
})->{html};
like($labels_html, qr/Time \(s\)/, 'x_label text embedded');
like($labels_html, qr/Speed/,      'y_label text embedded');

# ── animated => 1 ────────────────────────────────────────────────────────────
my $anim_html = $chart->render_scatter_chart_snippet(\@data, { animated => 1 })->{html};
like($anim_html, qr/prefers-reduced-motion/, 'animated: reduced-motion guard present');
like($anim_html, qr/opacity.*0/,             'animated: circles start at opacity 0');

# ── id opt ────────────────────────────────────────────────────────────────────
my $id_html = $chart->render_scatter_chart_snippet(\@data, { id => 'my_scatter' })->{html};
like($id_html, qr/<svg id="my_scatter"/,   'Custom id in SVG element');
like($id_html, qr/id="my_scatter_tip"/,   'Tooltip id derived from custom id');

# ── extra tooltip data ────────────────────────────────────────────────────────
my $extra_html = $chart->render_scatter_chart_snippet(
	[[10, 20, { label => 'Point A' }]]
)->{html};
like($extra_html, qr/d\.extra/, 'Extra tooltip rendering code present');

# ── responsive opt ────────────────────────────────────────────────────────────
my $resp_html = $chart->render_scatter_chart_snippet(\@data, { responsive => 1 })->{html};
like($resp_html, qr/viewBox/, 'responsive: viewBox present');
unlike($resp_html, qr/style="border/, 'responsive: no fixed border style');

# ── error conditions ──────────────────────────────────────────────────────────
throws_ok { $chart->render_scatter_chart_snippet('not an array') }
    qr/Data must be an array of arrays/, 'Non-arrayref data dies';

throws_ok { $chart->render_scatter_chart_snippet(['not_arr']) }
    qr/Each data point must be an array reference/, 'Non-arrayref element dies';

throws_ok { $chart->render_scatter_chart_snippet([[42]]) }
    qr/Each data point must have at least 2 elements/, 'Short point dies';

throws_ok { $chart->render_scatter_chart_snippet([['x', 20]]) }
    qr/X value must be numeric/, 'Non-numeric X dies';

throws_ok { $chart->render_scatter_chart_snippet([[10, 'y']]) }
    qr/Y value must be numeric/, 'Non-numeric Y dies';

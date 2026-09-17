#!/usr/bin/env perl

use warnings;
use strict;

use Test::Most tests => 30;
use_ok('HTML::D3');

my $chart = HTML::D3->new(
	width  => 800,
	height => 600,
	title  => 'Pie Snippet Test',
);

my @data = (['Apples', 40], ['Oranges', 30], ['Bananas', 30]);

isa_ok($chart, 'HTML::D3', 'Chart object is created');
is($chart->{width},  800,           'Width is set correctly');
is($chart->{height}, 600,           'Height is set correctly');
is($chart->{title},  'Pie Snippet Test','Title is set correctly');

# ── Basic return shape ────────────────────────────────────────────────────────
my $fragment;
lives_ok { $fragment = $chart->render_pie_chart_snippet(\@data) } 'Renders without error';
is(ref($fragment), 'HASH', 'Returns a hash reference');
is($fragment->{svg_id}, 'pie_chart', 'svg_id is "pie_chart"');

my $html = $fragment->{html};
like($html, qr/<svg id="pie_chart"/, 'SVG element has id="pie_chart"');
like($html, qr/d3\.pie\(\)/,     'Contains d3.pie()');
unlike($html, qr/<!DOCTYPE/i,       'No DOCTYPE (snippet)');
unlike($html, qr/<html/i,           'No <html> wrapper');
unlike($html, qr/<head/i,           'No <head> element');
unlike($html, qr/<body/i,           'No <body> element');
unlike($html, qr{https://d3js\.org/d3\.v7}, 'No D3 CDN tag — caller loads D3');
like($html, qr/schemeTableau10/, 'Default colour scheme is tableau10');

# ── animated => 1 ─────────────────────────────────────────────────────────────
my $anim = $chart->render_pie_chart_snippet(\@data, { animated => 1 });
like($anim->{html}, qr/initialDrawDone/,        'animated: initialDrawDone guard present');
like($anim->{html}, qr/attrTween/,              'animated: attrTween present');
like($anim->{html}, qr/prefers-reduced-motion/, 'animated: prefers-reduced-motion check present');

# ── animated => 0 must not have animation markers ────────────────────────────
unlike($html, qr/attrTween/,      'non-animated: no attrTween');
unlike($html, qr/initialDrawDone/,'non-animated: no initialDrawDone');

# ── donut => 1 ────────────────────────────────────────────────────────────────
my $donut = $chart->render_pie_chart_snippet(\@data, { donut => 1 });
like($donut->{html}, qr/innerRadius/, 'donut: innerRadius > 0 present');

# ── max_slices ────────────────────────────────────────────────────────────────
my $big = $chart->render_pie_chart_snippet(
	[['A',50],['B',30],['C',20],['D',10],['E',5]], { max_slices => 3 }
);
my @labels = ($big->{html} =~ /"label":"([^"]+)"/g);
is(scalar(@labels), 3,       'max_slices => 3 produces exactly 3 slices in data');
ok((grep { $_ eq 'Other' } @labels), '"Other" slice present');

# ── zero-value slice omitted ──────────────────────────────────────────────────
my $zero = $chart->render_pie_chart_snippet([['Zero',0],['Pos',50]]);
unlike($zero->{html}, qr/"label":"Zero"/, 'Zero-value slice omitted from data');

# ── negative value converted to absolute ─────────────────────────────────────
my $neg = $chart->render_pie_chart_snippet([['Neg',-20],['Pos',80]]);
like($neg->{html}, qr/"value":20/, 'Negative value converted to absolute');

# ── separator option ──────────────────────────────────────────────────────────
# The separator is interpolated into a JavaScript string literal in the D3
# legend builder.  Verify the JS source contains the right string literal.
like($html, qr/d\.data\.label \+ ' \/ '/, 'Default separator / present in legend JS');

my $colon_frag = $chart->render_pie_chart_snippet(\@data, { separator => ':' });
like($colon_frag->{html}, qr/d\.data\.label \+ ' : '/, 'Custom separator : present in legend JS');
unlike($colon_frag->{html}, qr/d\.data\.label \+ ' \/ '/, 'Default separator / absent when overridden');

# ── error handling ────────────────────────────────────────────────────────────
throws_ok {
	$chart->render_pie_chart_snippet('Invalid data');
} qr/Data must be an array of arrays/, 'Dies on invalid data';

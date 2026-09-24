#!/usr/bin/env perl

use warnings;
use strict;

use Test::Most tests => 42;
use_ok('HTML::D3');

my $chart = HTML::D3->new(
	width  => 800,
	height => 500,
	title  => 'Bar Snippet Test',
);

my @data = (
	['Alpha', 300],
	['Beta',  150],
	['Gamma', 450],
	['Delta', 200],
);

isa_ok($chart, 'HTML::D3', 'chart object created');

# ── Basic return shape ────────────────────────────────────────────────────────
my $fragment;
lives_ok { $fragment = $chart->render_bar_chart_snippet(\@data) } 'Renders without error';
is(ref($fragment), 'HASH', 'Returns a hash reference');
is($fragment->{svg_id}, 'bar_chart', 'svg_id is "bar_chart"');

my $html = $fragment->{html};
like($html, qr/<svg id="bar_chart"/,   'SVG element has id="bar_chart"');
like($html, qr/id="bar_chart_tip"/,   'Tooltip div present');
like($html, qr/d3\.scaleBand/,        'Uses d3.scaleBand for category axis');
like($html, qr/d3\.scaleLinear/,      'Uses d3.scaleLinear for value axis');
like($html, qr/Alpha/,                'Label Alpha in output');
like($html, qr/450/,                  'Value 450 in output');
unlike($html, qr/<!DOCTYPE/i,         'No DOCTYPE (snippet)');
unlike($html, qr/<html/i,             'No <html> wrapper');
unlike($html, qr/<head/i,             'No <head> element');
unlike($html, qr/<body/i,             'No <body> element');
unlike($html, qr{https://d3js\.org},  'No D3 CDN tag — caller loads D3');
ok(utf8::is_utf8($html) || $html !~ /[^\x00-\x7f]/, 'Returns Perl character string');

# ── orientation => horizontal ─────────────────────────────────────────────────
my $horiz = $chart->render_bar_chart_snippet(\@data, { orientation => 'horizontal' })->{html};
like($horiz, qr/d3\.scaleBand/,   'Horizontal: scaleBand present');
like($horiz, qr/d3\.scaleLinear/, 'Horizontal: scaleLinear present');

# ── sort_bars => value ────────────────────────────────────────────────────────
my $sorted = $chart->render_bar_chart_snippet(\@data, { sort_bars => 'value' })->{html};
my $gamma_idx = index($sorted, '"label":"Gamma"');
my $alpha_idx = index($sorted, '"label":"Alpha"');
ok($gamma_idx < $alpha_idx, 'sort_bars value: Gamma (450) before Alpha (300)');

# ── sort_bars => label ────────────────────────────────────────────────────────
my $alpha_sorted = $chart->render_bar_chart_snippet(\@data, { sort_bars => 'label' })->{html};
my $a_idx = index($alpha_sorted, '"label":"Alpha"');
my $b_idx = index($alpha_sorted, '"label":"Beta"');
ok($a_idx < $b_idx, 'sort_bars label: Alpha before Beta');

# ── max_bars collapses tail ───────────────────────────────────────────────────
# sort desc: Gamma(450), Alpha(300), Delta(200), Beta(150)
# max_bars => 2 keeps top-2: Gamma and Alpha; Delta and Beta become "Other"
my $maxed = $chart->render_bar_chart_snippet(\@data, { sort_bars => 'value', max_bars => 2 })->{html};
like($maxed,   qr/"label":"Other"/, 'max_bars: Other bar present');
unlike($maxed, qr/"label":"Beta"/,  'max_bars: Beta collapsed (4th highest)');

# ── color => categorical ──────────────────────────────────────────────────────
my $cat = $chart->render_bar_chart_snippet(\@data, { color => 'categorical' })->{html};
like($cat, qr/schemeTableau10/, 'categorical: Tableau-10 palette used');

# ── show_values => 1 ─────────────────────────────────────────────────────────
my $vals = $chart->render_bar_chart_snippet(\@data, { show_values => 1 })->{html};
like($vals, qr/selectAll\(["']\.bc-val-text["']\)/, 'show_values: selectAll .bc-val-text present');

# ── animated => 1 ────────────────────────────────────────────────────────────
my $anim = $chart->render_bar_chart_snippet(\@data, { animated => 1 })->{html};
like($anim, qr/prefers-reduced-motion/, 'animated: reduced-motion guard present');
like($anim, qr/transition\(\)/,          'animated: D3 transition present');

# ── x_label and value_label ──────────────────────────────────────────────────
my $xl = $chart->render_bar_chart_snippet(\@data, { x_label => 'Category' })->{html};
like($xl, qr/Category/, 'x_label text embedded');

my $vl = $chart->render_bar_chart_snippet(\@data, { value_label => 'Sales' })->{html};
like($vl, qr/Sales/, 'value_label text embedded');

# ── x-axis label rotation for >8 bars ────────────────────────────────────────
my @many = map { ["L$_", $_ * 10] } 1 .. 10;
my $rotated = $chart->render_bar_chart_snippet(\@many)->{html};
like($rotated, qr/rotate\(-45\)/, 'Rotate: x-labels rotated for >8 bars');

# ── extra hashref in tooltip ─────────────────────────────────────────────────
my $extra_html = $chart->render_bar_chart_snippet([['A', 100, { note => 'info' }]])->{html};
like($extra_html, qr/d\.extra/, 'Extra: tooltip extra rendering code present');

# ── negative values become positive ──────────────────────────────────────────
my $neg = $chart->render_bar_chart_snippet([['Neg', -50]])->{html};
like($neg,   qr/50/,  'Negative: absolute value in output');
unlike($neg, qr/-50/, 'Negative: minus sign absent');

# ── undef value silently skipped ─────────────────────────────────────────────
my $undef_html;
lives_ok { $undef_html = $chart->render_bar_chart_snippet([['A', undef], ['B', 5]])->{html} }
    'undef value silently skipped, no exception';
like($undef_html, qr/"label":"B"/, 'B present after undef skip');
unlike($undef_html, qr/"label":"A"/, 'A absent (skipped)');

# ── error conditions ──────────────────────────────────────────────────────────
throws_ok { $chart->render_bar_chart_snippet('not an array') }
    qr/Data must be an array of arrays/, 'Non-arrayref data dies';

throws_ok { $chart->render_bar_chart_snippet([['ok', 1], 'bad']) }
    qr/Each data point must be an array reference/, 'Non-arrayref element dies';

throws_ok { $chart->render_bar_chart_snippet([['only one']]) }
    qr/Each data point must have at least 2 elements/, 'Short element dies';

throws_ok { $chart->render_bar_chart_snippet([['A', 'hello']]) }
    qr/Value must be numeric/, 'Non-numeric value dies';

throws_ok { $chart->render_bar_chart_snippet(\@data, { orientation => 'diagonal' }) }
    qr/orientation must be/, 'Invalid orientation dies';

throws_ok { $chart->render_bar_chart_snippet(\@data, { sort_bars => 'random' }) }
    qr/sort_bars must be/, 'Invalid sort_bars dies';

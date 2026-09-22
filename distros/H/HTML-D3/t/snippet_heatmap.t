#!/usr/bin/env perl

use warnings;
use strict;

use Test::Most tests => 33;
use_ok('HTML::D3');

my $chart = HTML::D3->new(
	width  => 800,
	height => 600,
	title  => 'Heatmap Test',
);

my @triples = (
	['Jan', 'North', 100],
	['Jan', 'South',  50],
	['Feb', 'North',  80],
	['Feb', 'South',  30],
);

isa_ok($chart, 'HTML::D3', 'chart object created');

# ── Basic return shape ────────────────────────────────────────────────────────
my $fragment;
lives_ok { $fragment = $chart->render_heatmap_snippet(\@triples) } 'Renders without error';
is(ref($fragment), 'HASH', 'Returns a hash reference');
is($fragment->{svg_id}, 'heatmap', 'svg_id is "heatmap"');

my $html = $fragment->{html};
like($html, qr/<svg id="heatmap"/,   'SVG element has id="heatmap"');
like($html, qr/scaleSequential/, 'Uses d3.scaleSequential');
like($html, qr/interpolateYlOrRd/,   'Default color scheme is YlOrRd');
unlike($html, qr/<!DOCTYPE/i,        'No DOCTYPE (snippet)');
unlike($html, qr/<html/i,            'No <html> wrapper');
unlike($html, qr/<head/i,            'No <head> element');
unlike($html, qr/<body/i,            'No <body> element');
unlike($html, qr{https://d3js\.org}, 'No D3 CDN tag — caller loads D3');

# ── legend on by default ──────────────────────────────────────────────────────
like($html, qr/linearGradient/, 'Legend present by default (linearGradient)');

# ── legend => 0 suppresses legend ────────────────────────────────────────────
my $no_leg = $chart->render_heatmap_snippet(\@triples, { legend => 0 });
unlike($no_leg->{html}, qr/linearGradient/, 'legend => 0 suppresses legend');

# ── animated => 1 ────────────────────────────────────────────────────────────
my $anim = $chart->render_heatmap_snippet(\@triples, { animated => 1 });
like($anim->{html}, qr/prefers-reduced-motion/, 'animated: prefers-reduced-motion check present');

# ── color_scheme options ──────────────────────────────────────────────────────
for my $scheme (qw(Blues Greens Purples RdPu YlGnBu)) {
	my $f = $chart->render_heatmap_snippet(\@triples, { color_scheme => $scheme });
	like($f->{html}, qr/interpolate\Q$scheme\E/, "color_scheme '$scheme' emits d3.interpolate$scheme");
}

# ── undef values are silently skipped ────────────────────────────────────────
my @with_undef = (['Mar', 'North', undef], ['Mar', 'South', 20]);
my $f_undef;
lives_ok { $f_undef = $chart->render_heatmap_snippet(\@with_undef) }
    'Renders with undef triple without error';
like($f_undef->{html}, qr/"x":"Mar"/, 'Non-undef x value appears in output');
like($f_undef->{html}, qr/"y":"South"/, 'Non-undef y value appears in output');

# ── error conditions ──────────────────────────────────────────────────────────
throws_ok { $chart->render_heatmap_snippet('not an array') }
    qr/Data must be an array of arrays/, 'Non-arrayref data dies correctly';

throws_ok { $chart->render_heatmap_snippet(['not_an_array_element']) }
    qr/Each data point must be an array reference/, 'Non-arrayref element dies correctly';

throws_ok { $chart->render_heatmap_snippet([['Jan', 'North']]) }
    qr/Each data point must have at least 3 elements/, 'Short triple dies correctly';

throws_ok { $chart->render_heatmap_snippet([['Jan']]) }
    qr/Each data point must have at least 3 elements/, 'Two-element triple dies correctly';

throws_ok { $chart->render_heatmap_snippet([['Jan', 'North', 'bad']]) }
    qr/Value must be numeric/, 'Non-numeric value dies correctly';

throws_ok { $chart->render_heatmap_snippet(\@triples, { color_scheme => 'Viridis' }) }
    qr/Unknown color_scheme: Viridis/, 'Unknown color_scheme dies correctly';

throws_ok { $chart->render_heatmap_snippet(\@triples, { cell_padding => 9 }) }
    qr/cell_padding must be between 0 and 8/, 'cell_padding out of range dies correctly';

# ── all-zero values render without degenerate scale ──────────────────────────
my @zeros = (['A', 'X', 0], ['B', 'Y', 0]);
my $f_zeros;
lives_ok { $f_zeros = $chart->render_heatmap_snippet(\@zeros) }
	'All-zero values render without error (degenerate domain fallback)';
ok(length($f_zeros->{html}) > 0, 'All-zero output is non-empty');

#!/usr/bin/env perl

use warnings;
use strict;

use Test::Most tests => 34;
use_ok('HTML::D3');

my $chart = HTML::D3->new(width => 700, height => 400, title => 'Histogram Test');
isa_ok($chart, 'HTML::D3', 'chart object created');

my @values = (12, 24, 36, 18, 42, 30, 15, 27, 39, 21, 33, 45, 9, 48, 6, 3, 51, 44, 28, 17);

# ── Basic return shape ────────────────────────────────────────────────────────
my $fragment;
lives_ok { $fragment = $chart->render_histogram_snippet(\@values) } 'Renders without error';
is(ref($fragment), 'HASH', 'Returns a hash reference');
is($fragment->{svg_id}, 'histogram', 'svg_id is "histogram"');

my $html = $fragment->{html};
like($html, qr/<svg id="histogram"/, 'SVG element has correct id');
like($html, qr/id="histogram_tip"/, 'Tooltip div present');
like($html, qr/d3\.bin\(\)/, 'Uses d3.bin()');
like($html, qr/d3\.scaleLinear/, 'Uses d3.scaleLinear for axes');
like($html, qr/hg-bar/, 'Has hg-bar class');
like($html, qr/var numBins = 20;/, 'Default 20 bins');
unlike($html, qr/Math\.log2/, 'Default bins mode does not use Sturges');
unlike($html, qr/<!DOCTYPE/i, 'No DOCTYPE (snippet)');
unlike($html, qr/<html/i,     'No <html> wrapper');
unlike($html, qr{https://d3js\.org}, 'No CDN tag');

# ── auto bins (Sturges) ───────────────────────────────────────────────────────
my $auto_bins = $chart->render_histogram_snippet(\@values, { bins => undef })->{html};
like($auto_bins, qr/Math\.log2/, 'bins => undef uses Sturges rule');
unlike($auto_bins, qr/var numBins = 20;/, 'auto mode does not hard-code 20');

# ── custom bins count ─────────────────────────────────────────────────────────
my $custom_bins = $chart->render_histogram_snippet(\@values, { bins => 10 })->{html};
like($custom_bins, qr/var numBins = 10;/, 'Custom bins count reflected in output');

# ── x_label opt ───────────────────────────────────────────────────────────────
my $with_label = $chart->render_histogram_snippet(\@values, { x_label => 'Amount' })->{html};
like($with_label, qr/Amount/, 'x_label text appears in output');
like($with_label, qr/hg-axis-label/, 'hg-axis-label class present in output');
my $no_label = $chart->render_histogram_snippet(\@values)->{html};
unlike($no_label, qr/\.attr\("class","hg-axis-label"\)/, 'No axis label JS when x_label omitted');

# ── custom color ──────────────────────────────────────────────────────────────
my $colored = $chart->render_histogram_snippet(\@values, { color => '#1a48c8' })->{html};
like($colored, qr/#1a48c8/, 'Custom color applied');

# ── id opt ────────────────────────────────────────────────────────────────────
my $custom = $chart->render_histogram_snippet(\@values, { id => 'myhist' });
is($custom->{svg_id}, 'myhist', 'id opt overrides svg_id');
like($custom->{html}, qr/id="myhist"/, 'Custom id in SVG element');
like($custom->{html}, qr/id="myhist_tip"/, 'Custom tip id derived from id opt');

# ── tooltip </b> safety ───────────────────────────────────────────────────────
unlike($html, qr{</b>}, 'No raw </b> inside script (html-tidy safety)');
like($html, qr{<\\/b>}, 'Has escaped <\\/b> in tooltip');

# ── responsive opt ────────────────────────────────────────────────────────────
my $resp  = $chart->render_histogram_snippet(\@values, { responsive => 1 })->{html};
like($resp, qr/viewBox=/, 'responsive opt produces viewBox');
my $fixed = $chart->render_histogram_snippet(\@values)->{html};
like($fixed, qr/width="700"/, 'Default: fixed pixel width');

# ── validation errors ─────────────────────────────────────────────────────────
throws_ok { $chart->render_histogram_snippet('not-an-arrayref') }
	qr/Data must be an array of numeric values/, 'Dies on non-arrayref';
throws_ok { $chart->render_histogram_snippet([ 1, 2, 'abc', 4 ]) }
	qr/Each value must be numeric/, 'Dies on non-numeric value';
throws_ok { $chart->render_histogram_snippet(\@values, { bins => 0 }) }
	qr/bins must be a positive integer/, 'Dies on bins => 0';
throws_ok { $chart->render_histogram_snippet(\@values, { bins => -5 }) }
	qr/bins must be a positive integer/, 'Dies on negative bins';
throws_ok { $chart->render_histogram_snippet(\@values, { bins => 'auto' }) }
	qr/bins must be a positive integer/, 'Dies on non-numeric bins string';

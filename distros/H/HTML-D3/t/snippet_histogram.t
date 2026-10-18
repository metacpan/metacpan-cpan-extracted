#!/usr/bin/env perl

use warnings;
use strict;

use Test::Most tests => 60;
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

# ── pre-binned input (binned => 1) ───────────────────────────────────────────
# The caller owns the binning: the supplied labels and counts are drawn as-is
# and d3.bin() is never called.
my @bins = (
	{ label => '[0,10)',  count => 3 },
	{ label => '[10,20)', count => 5, lo => 10, hi => 20 },
);
my $binned;
lives_ok { $binned = $chart->render_histogram_snippet(\@bins, { binned => 1 }) }
	'Pre-binned input renders without error';
is(ref($binned), 'HASH', 'Pre-binned returns a hash reference');
is($binned->{svg_id}, 'histogram', 'Pre-binned svg_id is "histogram"');
like($binned->{html}, qr/"label":"\[0,10\)"/, 'Supplied bin label embedded in JSON');
like($binned->{html}, qr/"count":5/, 'Supplied bin count embedded in JSON');
unlike($binned->{html}, qr/d3\.bin\(\)/, 'Pre-binned path never calls d3.bin()');
like($binned->{html}, qr/d3\.scaleBand/, 'Pre-binned bars use a band scale');
like($binned->{html}, qr/esc\(d\.label\)/, 'Pre-binned tooltip escapes the bin label');
unlike($binned->{html}, qr{</b>}, 'Pre-binned fragment has no raw </b>');

# Labels derived from lo/hi when the caller omits them.
my $derived = $chart->render_histogram_snippet(
	[{ lo => 0, hi => 10, count => 1 }, { lo => 10, hi => 20, count => 2 }],
	{ binned => 1 }
)->{html};
like($derived, qr/"label":"\[0,10\)"/,  'Label derived from lo/hi for the first bin');
like($derived, qr/"label":"\[10,20\)"/, 'Label derived from lo/hi for the second bin');

# Bar fill: explicit colour wins, otherwise the first colour of the scheme.
like(
	$chart->render_histogram_snippet(\@bins, { binned => 1, color => '#abcdef' })->{html},
	qr/"#abcdef"/, 'Explicit color opt fills the pre-binned bars'
);
like(
	$chart->render_histogram_snippet(\@bins, { binned => 1, scheme => 'category10' })->{html},
	qr/\['#1f77b4', '#ff7f0e'[^\]]*\]\[0\]/, 'scheme opt supplies the bar fill when color is absent'
);
like(
	$chart->render_histogram_snippet(\@bins, { binned => 1, color => '#abcdef', scheme => 'category10' })->{html},
	qr/"#abcdef"/, 'Explicit color wins over scheme'
);

# The remaining opts apply to the pre-binned path too.
my $binned_opts = $chart->render_histogram_snippet(\@bins, {
	binned => 1, x_label => 'Bucket', id => 'mybins', responsive => 1,
});
is($binned_opts->{svg_id}, 'mybins', 'id opt honoured for pre-binned input');
like($binned_opts->{html}, qr/Bucket/, 'x_label honoured for pre-binned input');
like($binned_opts->{html}, qr/viewBox=/, 'responsive opt honoured for pre-binned input');
lives_ok { $chart->render_histogram_snippet(\@bins, { binned => 1, bins => 0 }) }
	'bins is ignored (not validated) when binned is set';

# ── pre-binned validation errors ──────────────────────────────────────────────
throws_ok { $chart->render_histogram_snippet([], { binned => 1 }) }
	qr/Data must contain at least one bin/, 'Dies on empty pre-binned data';
throws_ok { $chart->render_histogram_snippet([1, 2], { binned => 1 }) }
	qr/Each pre-binned entry must be a hash reference/, 'Dies on non-hashref bin';
throws_ok { $chart->render_histogram_snippet([{ label => 'a' }], { binned => 1 }) }
	qr/Bin count must be numeric/, 'Dies when a bin has no count';
throws_ok { $chart->render_histogram_snippet([{ label => 'a', count => 'many' }], { binned => 1 }) }
	qr/Bin count must be numeric/, 'Dies on non-numeric count';
throws_ok { $chart->render_histogram_snippet([{ label => 'a', count => -1 }], { binned => 1 }) }
	qr/Bin count must not be negative/, 'Dies on negative count';
throws_ok { $chart->render_histogram_snippet([{ count => 1 }], { binned => 1 }) }
	qr/Each pre-binned entry must have a label or numeric lo and hi/,
	'Dies when a bin has neither label nor lo/hi';
throws_ok { $chart->render_histogram_snippet([{ lo => 0, count => 1 }], { binned => 1 }) }
	qr/Each pre-binned entry must have a label or numeric lo and hi/,
	'Dies when only lo is supplied without a label';
throws_ok { $chart->render_histogram_snippet('not an arrayref', { binned => 1 }) }
	qr/Data must be an array of numeric values/,
	'Dies on non-arrayref even in binned mode';

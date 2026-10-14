#!/usr/bin/env perl

use warnings;
use strict;

use Test::Most tests => 34;
use_ok('HTML::D3');

my $chart = HTML::D3->new(width => 800, height => 500, title => 'Treemap Test');
isa_ok($chart, 'HTML::D3', 'chart object created');

my @flat_data = (
	{ path => 'Root/A/X', value => 420 },
	{ path => 'Root/A/Y', value => 180 },
	{ path => 'Root/B/Z', value => 300 },
	{ path => 'Root/B/W', value => 100 },
);

my $nested_data = {
	name => 'Root',
	children => [
		{ name => 'A', children => [
			{ name => 'X', value => 420 },
			{ name => 'Y', value => 180 },
		]},
		{ name => 'B', children => [
			{ name => 'Z', value => 300 },
			{ name => 'W', value => 100 },
		]},
	],
};

# ── Flat path format ──────────────────────────────────────────────────────────
my $fragment;
lives_ok { $fragment = $chart->render_treemap_snippet(\@flat_data) } 'Flat format renders without error';
is(ref($fragment), 'HASH', 'Returns a hash reference (flat)');
is($fragment->{svg_id}, 'treemap', 'svg_id is "treemap"');

my $html = $fragment->{html};
like($html, qr/<svg id="treemap"/, 'SVG element has correct id (flat)');
like($html, qr/id="treemap_tip"/, 'Tooltip div present (flat)');
like($html, qr/d3\.treemap\(\)/, 'Uses d3.treemap()');
like($html, qr/d3\.stratify\(\)/, 'Flat format uses d3.stratify()');
like($html, qr/SCHEMES/, 'Contains SCHEMES colour map');
like($html, qr/schemeTableau10/, 'Default tableau10 scheme');
like($html, qr/treemapSquarify/, 'Uses treemapSquarify tiling');
unlike($html, qr/d3\.hierarchy\(raw/, 'Flat format does not use d3.hierarchy(raw)');
unlike($html, qr/<!DOCTYPE/i, 'No DOCTYPE (snippet)');
unlike($html, qr/<html/i,     'No <html> wrapper');
unlike($html, qr{https://d3js\.org}, 'No CDN tag');

# ── Nested hashref format ──────────────────────────────────────────────────────
my $nested_frag;
lives_ok { $nested_frag = $chart->render_treemap_snippet($nested_data) } 'Nested format renders without error';
is(ref($nested_frag), 'HASH', 'Returns a hash reference (nested)');
my $nested_html = $nested_frag->{html};
like($nested_html, qr/d3\.hierarchy\(rawData\)/, 'Nested format uses d3.hierarchy()');
unlike($nested_html, qr/d3\.stratify\(\)/, 'Nested format does not use d3.stratify()');

# ── id opt ────────────────────────────────────────────────────────────────────
my $custom = $chart->render_treemap_snippet(\@flat_data, { id => 'mytm' });
is($custom->{svg_id}, 'mytm', 'id opt overrides svg_id');
like($custom->{html}, qr/id="mytm"/, 'Custom id in SVG element');

# ── scheme opt ────────────────────────────────────────────────────────────────
my $set3 = $chart->render_treemap_snippet(\@flat_data, { scheme => 'set3' })->{html};
like($set3, qr/SCHEMES\['set3'\]/, 'scheme opt reflected in JS lookup');

# ── label opt ─────────────────────────────────────────────────────────────────
my $with_labels = $chart->render_treemap_snippet(\@flat_data, { label => 1 })->{html};
like($with_labels, qr/cell\.append\("text"\)/, 'label => 1 emits text append');
my $no_labels = $chart->render_treemap_snippet(\@flat_data, { label => 0 })->{html};
unlike($no_labels, qr/cell\.append\("text"\)/, 'label => 0 omits text append');

# ── custom path_sep ───────────────────────────────────────────────────────────
my @dot_data = (
	{ path => 'Root.A.X', value => 100 },
	{ path => 'Root.B.Y', value => 200 },
);
my $dot_sep = $chart->render_treemap_snippet(\@dot_data, { path_sep => '.' })->{html};
like($dot_sep, qr/var sep = "\."/, 'Custom path_sep dot reflected in JS');

# ── tooltip </b> safety ───────────────────────────────────────────────────────
unlike($html, qr{</b>}, 'No raw </b> inside script (html-tidy safety)');
like($html, qr{<\\/b>}, 'Has escaped <\\/b> in tooltip');

# ── responsive opt ────────────────────────────────────────────────────────────
my $resp  = $chart->render_treemap_snippet(\@flat_data, { responsive => 1 })->{html};
like($resp, qr/viewBox=/, 'responsive opt produces viewBox');
my $fixed = $chart->render_treemap_snippet(\@flat_data)->{html};
like($fixed, qr/width="800"/, 'Default: fixed pixel width');

# ── validation errors ─────────────────────────────────────────────────────────
throws_ok { $chart->render_treemap_snippet('not-ref') }
	qr/Data must be an array of hashes or a hash tree/, 'Dies on plain scalar';
throws_ok { $chart->render_treemap_snippet([1,2,3]) }
	qr/Each flat row must be a hash reference/, 'Dies on non-hashref flat row';
throws_ok { $chart->render_treemap_snippet([ { value => 10 } ]) }
	qr/Each flat row must have a 'path' key/, 'Dies on missing path key';
throws_ok { $chart->render_treemap_snippet([ { path => 'A/B', value => 'bad' } ]) }
	qr/Each flat row must have a numeric 'value' key/, 'Dies on non-numeric value';

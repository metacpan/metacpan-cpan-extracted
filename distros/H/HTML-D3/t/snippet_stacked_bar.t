#!/usr/bin/env perl

use warnings;
use strict;

use Test::Most tests => 41;
use_ok('HTML::D3');

my $chart = HTML::D3->new(width => 900, height => 500, title => 'Stacked Bar Test');
isa_ok($chart, 'HTML::D3', 'chart object created');

my @data = (
	{ cat => 'East',  seg => 'Widgets', val => 1200 },
	{ cat => 'East',  seg => 'Gizmos',  val =>  500 },
	{ cat => 'West',  seg => 'Widgets', val =>  800 },
	{ cat => 'West',  seg => 'Gizmos',  val =>  700 },
	{ cat => 'North', seg => 'Widgets', val =>  600 },
	{ cat => 'North', seg => 'Gizmos',  val =>  400 },
);

# ── Basic return shape ────────────────────────────────────────────────────────
my $fragment;
lives_ok { $fragment = $chart->render_stacked_bar_snippet(\@data) } 'Renders without error';
is(ref($fragment), 'HASH', 'Returns a hash reference');
is($fragment->{svg_id}, 'stacked_bar', 'svg_id is "stacked_bar"');

my $html = $fragment->{html};
like($html, qr/<svg id="stacked_bar"/, 'SVG element has correct id');
like($html, qr/id="stacked_bar_tip"/, 'Tooltip div present');
like($html, qr/d3\.stack\(\)/, 'Uses d3.stack()');
like($html, qr/d3\.scaleBand/, 'Uses d3.scaleBand for category axis');
like($html, qr/d3\.scaleLinear/, 'Uses d3.scaleLinear for value axis');
like($html, qr/SCHEMES/, 'Contains SCHEMES colour map');
like($html, qr/schemeTableau10/, 'Uses default tableau10 scheme');
like($html, qr/East/, 'Category East in output');
like($html, qr/Widgets/, 'Segment Widgets in output');
unlike($html, qr/<!DOCTYPE/i, 'No DOCTYPE (snippet)');
unlike($html, qr/<html/i,     'No <html> wrapper');
unlike($html, qr/<head/i,     'No <head> element');
unlike($html, qr{https://d3js\.org}, 'No CDN tag');

# ── id opt ────────────────────────────────────────────────────────────────────
my $custom = $chart->render_stacked_bar_snippet(\@data, { id => 'mysb' });
is($custom->{svg_id}, 'mysb', 'id opt overrides svg_id');
like($custom->{html}, qr/id="mysb"/, 'Custom id appears in SVG element');
like($custom->{html}, qr/id="mysb_tip"/, 'Custom tip id derived from id opt');

# ── orient => h ───────────────────────────────────────────────────────────────
my $horiz = $chart->render_stacked_bar_snippet(\@data, { orient => 'h' });
like($horiz->{html}, qr/axisBottom/, 'Horizontal: axisBottom present');
like($horiz->{html}, qr/axisLeft/,   'Horizontal: axisLeft present');

# ── scheme opt ────────────────────────────────────────────────────────────────
my $set2 = $chart->render_stacked_bar_snippet(\@data, { scheme => 'set2' })->{html};
like($set2, qr/SCHEMES\['set2'\]/, 'scheme opt reflected in JS colour lookup');

# ── sort => label ─────────────────────────────────────────────────────────────
my $sorted_label = $chart->render_stacked_bar_snippet(\@data, { sort => 'label' })->{html};
my $east_idx  = index($sorted_label, '"East"');
my $north_idx = index($sorted_label, '"North"');
my $west_idx  = index($sorted_label, '"West"');
ok($east_idx  < $north_idx, 'sort label: East before North');
ok($north_idx < $west_idx,  'sort label: North before West');

# ── sort => value ─────────────────────────────────────────────────────────────
my $sorted_value = $chart->render_stacked_bar_snippet(\@data, { sort => 'value' })->{html};
my $east_v  = index($sorted_value, '"East"');
my $west_v  = index($sorted_value, '"West"');
my $north_v = index($sorted_value, '"North"');
ok($east_v < $west_v,  'sort value: East (1700 total) before West (1500)');
ok($west_v < $north_v, 'sort value: West (1500) before North (1000)');

# ── x_label opt ───────────────────────────────────────────────────────────────
my $with_label = $chart->render_stacked_bar_snippet(\@data, { x_label => 'Region' })->{html};
like($with_label, qr/Region/, 'x_label text appears in output');
like($with_label, qr/sb-axis-label/, 'sb-axis-label class used for x_label');

# ── interactive legend present ────────────────────────────────────────────────
like($html, qr/sb-legend-item/, 'Interactive legend items present');
like($html, qr/on\("click"/, 'Click handler for legend toggle');

# ── tooltip </b> safety ───────────────────────────────────────────────────────
unlike($html, qr{</b>}, 'No raw </b> inside script (html-tidy safety)');
like($html, qr{<\\/b>}, 'Has escaped <\\/b> in tooltip');

# ── responsive opt ────────────────────────────────────────────────────────────
my $resp = $chart->render_stacked_bar_snippet(\@data, { responsive => 1 })->{html};
like($resp, qr/viewBox=/, 'responsive opt produces viewBox');
my $fixed = $chart->render_stacked_bar_snippet(\@data)->{html};
like($fixed, qr/width="900"/, 'Default: fixed pixel width');

# ── validation errors ─────────────────────────────────────────────────────────
throws_ok { $chart->render_stacked_bar_snippet('not-an-arrayref') }
	qr/Data must be an array of hashes/, 'Dies on non-arrayref';
throws_ok { $chart->render_stacked_bar_snippet([ 'scalar' ]) }
	qr/Each data point must be a hash reference/, 'Dies on non-hashref row';
throws_ok { $chart->render_stacked_bar_snippet([ { cat=>'A', seg=>'B', val=>'not-a-number' } ]) }
	qr/Value must be numeric/, 'Dies on non-numeric value';
throws_ok { $chart->render_stacked_bar_snippet(\@data, { orient => 'x' }) }
	qr/orient must be 'v' or 'h'/, "Dies on invalid orient";
throws_ok { $chart->render_stacked_bar_snippet(\@data, { sort => 'desc' }) }
	qr/sort must be 'value' or 'label'/, "Dies on invalid sort";

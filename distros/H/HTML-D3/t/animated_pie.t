#!/usr/bin/env perl

use warnings;
use strict;

use HTML::D3;
use Test::Needs 'Test::HTML::T5';
use Test::Most tests => 19;

Test::HTML::T5->import();

my $chart = HTML::D3->new(
	width  => 800,
	height => 600,
	title  => 'Animated Pie Test',
);

isa_ok($chart, 'HTML::D3', 'Chart object is created');

is($chart->{width},  800,               'Width is set correctly');
is($chart->{height}, 600,               'Height is set correctly');
is($chart->{title},  'Animated Pie Test','Title is set correctly');

my $data = [
	['Apples',  40],
	['Oranges', 30],
	['Bananas', 30],
];

my $html;
lives_ok { $html = $chart->render_animated_pie_chart($data) } 'Animated pie chart renders without error';
like($html, qr/<svg id="chart"/, 'HTML contains SVG element');
like($html, qr/Apples/,          'HTML contains data label');
like($html, qr/40/,              'HTML contains data value');

like($html, qr/<html/,                    'Output contains <html> tag');
like($html, qr/Animated Pie Test<\/h1>/, 'Title is included in h1');
html_tidy_ok($html, 'Output is valid HTML');
like($html, qr/d3\.pie\(\)/,              'd3.pie() present');
like($html, qr/d3\.schemeCategory10/,    'd3.schemeCategory10 colours present');
like($html, qr/attrTween/,               'attrTween animation present');
like($html, qr/d3\.interpolate/,          'd3.interpolate used for tween');

throws_ok {
	$chart->render_animated_pie_chart('Invalid data');
} qr/Data must be an array of arrays/, 'Dies on invalid data';

# ── separator option ──────────────────────────────────────────────────────────
# The separator is interpolated into a JavaScript template literal, not next to
# static label/value strings.  Verify the JS source contains the right character.
like($html, qr/d\.data\.label} \/ \$\{d\.data\.value}/, 'Default separator / present in legend JS');

my $colon_html = $chart->render_animated_pie_chart($data, { separator => ':' });
like($colon_html, qr/d\.data\.label} : \$\{d\.data\.value}/, 'Custom separator : present in legend JS');
unlike($colon_html, qr/d\.data\.label} \/ /, 'Default separator / absent when overridden');

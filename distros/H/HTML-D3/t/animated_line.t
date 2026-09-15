#!/usr/bin/env perl

use warnings;
use strict;

use HTML::D3;
use Test::Needs 'Test::HTML::T5';
use Test::Most tests => 14;

Test::HTML::T5->import();

my $chart = HTML::D3->new(
	width  => 800,
	height => 600,
	title  => 'Animated Line Test',
);

isa_ok($chart, 'HTML::D3', 'Chart object is created');

is($chart->{width},  800,                 'Width is set correctly');
is($chart->{height}, 600,                 'Height is set correctly');
is($chart->{title},  'Animated Line Test','Title is set correctly');

my $data = [
	['January',  1000],
	['February', 1200],
	['March',     950],
];

my $html;
lives_ok { $html = $chart->render_animated_line_chart($data) } 'Animated line chart renders without error';
like($html, qr/<svg id="chart"/, 'HTML contains SVG element for chart');
like($html, qr/January/,         'HTML contains data label');
like($html, qr/1000/,            'HTML contains data value');

like($html, qr/<html/,                   'Output contains <html> tag');
like($html, qr/Animated Line Test<\/h1>/,'Title is included in h1');
html_tidy_ok($html, 'Output is valid HTML');
like($html, qr/stroke-dashoffset/,       'stroke-dashoffset animation present');
like($html, qr/d3\.easeLinear/,          'd3.easeLinear easing present');

throws_ok {
	$chart->render_animated_line_chart('Invalid data');
} qr/Data must be an array of arrays/, 'Dies on invalid data';

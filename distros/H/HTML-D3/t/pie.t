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
	title  => 'Pie Chart Test',
);

isa_ok($chart, 'HTML::D3', 'Chart object is created');

is($chart->{width},  800,             'Width is set correctly');
is($chart->{height}, 600,             'Height is set correctly');
is($chart->{title},  'Pie Chart Test','Title is set correctly');

my $data = [
	['Apples',  40],
	['Oranges', 30],
	['Bananas', 30],
];

my $html;
lives_ok { $html = $chart->render_pie_chart($data) } 'Pie chart renders without error';
like($html, qr/<svg id="chart"/, 'HTML contains SVG element');
like($html, qr/Apples/,          'HTML contains data label');
like($html, qr/40/,              'HTML contains data value');

like($html, qr/<html/,                 'Output contains <html> tag');
like($html, qr/Pie Chart Test<\/h1>/, 'Title is included in h1');
html_tidy_ok($html, 'Output is valid HTML');
like($html, qr/d3\.pie\(\)/,          'd3.pie() present');
like($html, qr/d3\.schemeCategory10/, 'd3.schemeCategory10 colours present');

throws_ok {
	$chart->render_pie_chart('Invalid data');
} qr/Data must be an array of arrays/, 'Dies on invalid data';

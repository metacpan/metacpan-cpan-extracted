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
	title  => 'Animated Bar Test',
);

isa_ok($chart, 'HTML::D3', 'Chart object is created');

is($chart->{width},  800,                'Width is set correctly');
is($chart->{height}, 600,                'Height is set correctly');
is($chart->{title},  'Animated Bar Test','Title is set correctly');

my $data = [
	['Label 1', 10],
	['Label 2', 20],
	['Label 3', 30],
];

my $html;
lives_ok { $html = $chart->render_animated_bar_chart($data) } 'Animated bar chart renders without error';
like($html, qr/<svg id="chart"/, 'HTML contains SVG element for chart');
like($html, qr/Label 1/,         'HTML contains data label');
like($html, qr/10/,              'HTML contains data value');

like($html, qr/<html/,               'Output contains <html> tag');
like($html, qr/Animated Bar Test<\/h1>/, 'Title is included in h1');
html_tidy_ok($html, 'Output is valid HTML');
like($html, qr/\.transition\(\)/,    'D3 transition call present');
like($html, qr/\.duration\(\d+\)/,   'D3 duration call present');

throws_ok {
	$chart->render_animated_bar_chart('Invalid data');
} qr/Data must be an array of arrays/, 'Dies on invalid data';

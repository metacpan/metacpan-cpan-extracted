#!/usr/bin/env perl

use warnings;
use strict;

use HTML::D3;
use Test::HTML::T5;
use Test::Most tests => 12;

# Test object creation
my $chart = HTML::D3->new(
	width  => 1024,
	height => 768,
	title  => 'Test Chart'
);
isa_ok($chart, 'HTML::D3', 'Chart object is created');

# Check default values
is($chart->{width}, 1024, 'Width is set correctly');
is($chart->{height}, 768, 'Height is set correctly');
is($chart->{title}, 'Test Chart', 'Title is set correctly');

# Test bar chart rendering
my $data = [
	['Label 1', 10],
	['Label 2', 20],
	['Label 3', 30]
];

my $html;
lives_ok { $html = $chart->render_bar_chart($data) } 'Bar chart renders without error';
like($html, qr/<svg id="chart"/, 'HTML contains SVG element for chart');
like($html, qr/Label 1/, 'HTML contains data label');
like($html, qr/10/, 'HTML contains data value');

like($html, qr/<html/, 'Output contains <html> tag for HTML format');
like($html, qr/Test Chart<\/h1>/, 'Title is included');
html_tidy_ok($html, 'Output is valid HTML');

# Test for invalid data
throws_ok {
	$chart->render_bar_chart('Invalid data');
} qr/Data must be an array of arrays/, 'Dies on invalid data';

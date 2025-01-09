#!/usr/bin/env perl

use warnings;
use strict;

use HTML::D3;
use Test::HTML::T5;
use Test::Most tests => 14;

# Test object creation
my $chart = HTML::D3->new(
	width => 800,
	height => 600,
	title  => 'Monthly Revenue Trends by Product (With Animated Tooltips)',
);

my $data = [
	{
		name => 'Product A',
		data => [
			{ label => 'January', value => 1000 },
			{ label => 'February', value => 1200 },
			{ label => 'March', value => 950 },
		],
	}, {
		name => 'Product B',
		data => [
			{ label => 'January', value => 800 },
			{ label => 'February', value => 1150 },
			{ label => 'March', value => 1000 },
		],
	}
];

isa_ok($chart, 'HTML::D3', 'Chart object is created');

# Check default values
is($chart->{width}, 800, 'Width is set correctly');
is($chart->{height}, 600, 'Height is set correctly');
is($chart->{title}, 'Monthly Revenue Trends by Product (With Animated Tooltips)', 'Title is set correctly');

# Test chart rendering
my $html;
lives_ok { $html = $chart->render_multi_series_line_chart_with_animated_tooltips($data) } 'Animated tooltip chart renders without error';
like($html, qr/<svg id="chart"/, 'HTML contains SVG element for chart');
like($html, qr/January/, 'HTML contains data label');
like($html, qr/1000/, 'HTML contains data value');

like($html, qr/<html/, 'Output contains <html> tag for HTML format');
html_tidy_ok($html, 'Output is valid HTML');
like($html, qr/Monthly Revenue .+<\/h1>/, 'Title is included');
like($html, qr/transform: /, 'Animation included');
like($html, qr/<div class="tooltip" id="tooltip">/, 'Tooltips included');

# Test for invalid data
throws_ok {
	$chart->render_multi_series_line_chart_with_animated_tooltips('Invalid data');
} qr/Data must be an array of hashes/, 'Dies on invalid data';

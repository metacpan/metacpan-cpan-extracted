#!/usr/bin/env perl

use warnings;
use strict;

use HTML::D3;
use Test::Most tests => 15;

my $chart = HTML::D3->new(
	width  => 800,
	height => 600,
	title  => 'Pie Snippet Test',
);

isa_ok($chart, 'HTML::D3', 'Chart object is created');

is($chart->{width},  800,               'Width is set correctly');
is($chart->{height}, 600,               'Height is set correctly');
is($chart->{title},  'Pie Snippet Test','Title is set correctly');

my $data = [
	['Apples',  40],
	['Oranges', 30],
	['Bananas', 30],
];

my $fragment;
lives_ok { $fragment = $chart->render_pie_chart_snippet($data) } 'Pie snippet renders without error';

is(ref($fragment), 'HASH',    'Returns a hash reference');
is($fragment->{svg_id}, 'chart', 'svg_id key is "chart"');

my $html = $fragment->{html};
like($html, qr/<svg id="chart"/, 'Fragment contains SVG element');
like($html, qr/d3\.pie\(\)/,     'Fragment contains d3.pie()');

unlike($html, qr/<!DOCTYPE/i,                    'Fragment has no DOCTYPE');
unlike($html, qr/<html/i,                        'Fragment has no <html> wrapper');
unlike($html, qr/<head/i,                        'Fragment has no <head> element');
unlike($html, qr/<body/i,                        'Fragment has no <body> element');
unlike($html, qr{https://d3js\.org/d3\.v7\.min\.js}, 'Fragment has no D3 CDN tag — caller\'s responsibility');

throws_ok {
	$chart->render_pie_chart_snippet('Invalid data');
} qr/Data must be an array of arrays/, 'Dies on invalid data';

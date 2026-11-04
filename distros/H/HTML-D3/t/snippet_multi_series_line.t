#!/usr/bin/env perl

use warnings;
use strict;

use Test::Most tests => 44;
use_ok('HTML::D3');

my $chart = HTML::D3->new(width => 800, height => 600, title => 'Multi Series Test');

# Two series that deliberately do not share the same label set: the X domain
# must be the union of both, in first-seen order.
my @series = (
	{
		name => 'North',
		data => [
			{ label => 'January',  value => 1_000 },
			{ label => 'February', value => 1_200 },
		],
	},
	{
		name => 'South',
		data => [
			{ label => 'January', value => 500 },
			{ label => 'March',   value => 750 },
		],
	},
);

isa_ok($chart, 'HTML::D3', 'chart object created');

# ── Basic return shape ────────────────────────────────────────────────────────
my $fragment;
lives_ok { $fragment = $chart->render_multi_series_line_chart_snippet(\@series) }
	'Renders without error';
is(ref($fragment), 'HASH', 'Returns a hash reference');
is($fragment->{svg_id}, 'chart', 'svg_id is "chart"');

my $html = $fragment->{html};
like($html, qr/<svg id="chart"/, 'SVG element has id="chart"');
like($html, qr/id="chart_tip"/, 'Tooltip div present');
like($html, qr/var series = /, 'Series data embedded as JSON');
like($html, qr/"name":"North"/, 'First series name present in JSON');
like($html, qr/"value":1000/, 'First series value present in JSON');
like($html, qr/d3\.scalePoint/, 'Uses d3.scalePoint for the X axis');
like($html, qr/d3\.line\(\)/,   'Uses d3.line() for the paths');
like($html, qr/msl-line/,       'Line class present');
like($html, qr/var allLabels = \["January","February","March"\];/,
	'X domain is the union of every series\' labels, in first-seen order');
like($html, qr/scaleOrdinal\(\['#4e79a7', '#f28e2c'/, 'Default scheme is tableau10');
unlike($html, qr/<!DOCTYPE/i, 'No DOCTYPE (snippet)');
unlike($html, qr/<html/i,     'No <html> wrapper');
unlike($html, qr/<head/i,     'No <head> element');
unlike($html, qr/<body/i,     'No <body> element');
unlike($html, qr{https://d3js\.org}, 'No D3 CDN tag');
like($html, qr/function esc\(/, 'XSS escape function present');
ok(utf8::is_utf8($html) || $html !~ /[^\x00-\x7f]/, 'Returns Perl character string');

# ── opts ──────────────────────────────────────────────────────────────────────
my $opts_html = $chart->render_multi_series_line_chart_snippet(\@series, {
	x_label    => 'Month',
	y_label    => 'Sales',
	scheme     => 'category10',
	id         => 'ms',
	responsive => 1,
})->{html};
like($opts_html, qr/Month/,       'x_label embedded');
like($opts_html, qr/Sales/,       'y_label embedded');
like($opts_html, qr/scaleOrdinal\(\['#1f77b4', '#ff7f0e'/, 'scheme opt inlines the category10 colours');
like($opts_html, qr/<svg id="ms"/, 'id opt overrides the svg id');
like($opts_html, qr/viewBox=/,    'responsive opt produces a viewBox');
like($opts_html, qr/msl-axis-label/, 'Axis label class present');

# ── animated => 1 ─────────────────────────────────────────────────────────────
my $anim_html = $chart->render_multi_series_line_chart_snippet(\@series, { animated => 1 })->{html};
like($anim_html, qr/stroke-dashoffset/,      'animated: dash-offset technique present');
like($anim_html, qr/prefers-reduced-motion/, 'animated: reduced-motion guard present');
unlike($html, qr/prefers-reduced-motion/,    'Default: no animation code');

# ── one line (and one dot set) per series ─────────────────────────────────────
like($html, qr/series\.forEach\(function\(s,i\)\{/, 'Paths are emitted per series');
like($html, qr/\.attr\("class","msl-line"\)/,       'Line path class set');
like($html, qr/\.attr\("class","msl-dot msl-dot-"/, 'Dots are bound per series');

# ── interactive legend ────────────────────────────────────────────────────────
like($html, qr/msl-leg-item/, 'Clickable legend rows present');
like($html, qr/\.style\("opacity", vis \? 0 : 1\)/, 'Legend click toggles series opacity');

# ── validation errors ─────────────────────────────────────────────────────────
throws_ok { $chart->render_multi_series_line_chart_snippet('not an array') }
	qr/Data must be an array of series/, 'Non-arrayref data dies';
throws_ok { $chart->render_multi_series_line_chart_snippet(['not_hash']) }
	qr/Each series must be a hashref with name and data/, 'Non-hashref series dies';
throws_ok { $chart->render_multi_series_line_chart_snippet([{ name => 'A' }]) }
	qr/Each series must be a hashref with name and data/, 'Series without data dies';
throws_ok { $chart->render_multi_series_line_chart_snippet([{ data => [] }]) }
	qr/Each series must be a hashref with name and data/, 'Series without name dies';

# ── x_order (0.29) ────────────────────────────────────────────────────────────
sub domain_of {
	my ($h) = @_;
	my ($json) = $h =~ /var allLabels = (\[.*?\]);/;
	return defined $json ? JSON::PP->new->decode($json) : undef;
}
sub points_of {
	my ($h, $name) = @_;
	my ($json) = $h =~ /var series = (\[.*\]);/;
	my ($s) = grep { $_->{name} eq $name } @{ JSON::PP->new->decode($json) };
	return [ map { $_->{label} } @{ $s->{data} } ];
}
use JSON::PP ();

my @dated = (
	{ name => 'North', data => [ { label => '2025-01-19', value => 2 }, { label => '2025-01-15', value => 1 } ] },
	{ name => 'South', data => [ { label => '2025-01-16', value => 3 } ] },
	{ name => 'East',  data => [ { label => '2025-01-20', value => 4 }, { label => '2025-01-17', value => 5 } ] },
);

subtest 'auto sorts ISO dates, and each line follows the axis' => sub {
	my $h = $chart->render_multi_series_line_chart_snippet(\@dated)->{html};
	is_deeply(domain_of($h), [qw(2025-01-15 2025-01-16 2025-01-17 2025-01-19 2025-01-20)], 'dates in order');
	is_deeply(points_of($h, 'North'), [qw(2025-01-15 2025-01-19)], 'North drawn left to right');
	is_deeply(points_of($h, 'East'),  [qw(2025-01-17 2025-01-20)], 'East drawn left to right');
	is($dated[0]{data}[0]{label}, '2025-01-19', 'the caller\'s series are not reordered');
	like($h, qr/xScale\(d\.label == null \? "" : String\(d\.label\)\)/, 'labels looked up as strings');
};

subtest 'auto sorts numbers numerically' => sub {
	my $h = $chart->render_multi_series_line_chart_snippet([
		{ name => 'A', data => [ { label => 10, value => 1 }, { label => 9, value => 2 } ] },
		{ name => 'B', data => [ { label => '1.5', value => 3 }, { label => 100, value => 4 } ] },
	])->{html};
	is_deeply(domain_of($h), [ '1.5', '9', '10', '100' ], 'numeric order, as strings');
};

subtest 'auto keeps other labels in the order they are met' => sub {
	my $h = $chart->render_multi_series_line_chart_snippet(\@series)->{html};
	is_deeply(domain_of($h), [qw(January February March)], 'months in the caller\'s order');
	my $mixed = $chart->render_multi_series_line_chart_snippet([
		{ name => 'A', data => [ { label => '2025-01-02', value => 1 }, { label => 'later', value => 2 }, { label => '2025-01-01', value => 3 } ] },
	])->{html};
	is_deeply(domain_of($mixed), [qw(2025-01-02 later 2025-01-01)], 'one non-date label: no sorting');
	is_deeply(points_of($mixed, 'A'), [qw(2025-01-02 later 2025-01-01)], 'and no reordering of points');
};

subtest 'x_order data and sort' => sub {
	my $h = $chart->render_multi_series_line_chart_snippet(\@dated, { x_order => 'data' })->{html};
	is_deeply(domain_of($h), [qw(2025-01-19 2025-01-15 2025-01-16 2025-01-20 2025-01-17)], 'data: as met');
	is_deeply(points_of($h, 'North'), [qw(2025-01-19 2025-01-15)], 'data: points as given');
	$h = $chart->render_multi_series_line_chart_snippet(\@series, { x_order => 'sort' })->{html};
	is_deeply(domain_of($h), [qw(February January March)], 'sort: strings sorted');
	throws_ok { $chart->render_multi_series_line_chart_snippet(\@series, { x_order => 'random' }) }
		qr/Unknown x_order: random/, 'anything else dies';
};

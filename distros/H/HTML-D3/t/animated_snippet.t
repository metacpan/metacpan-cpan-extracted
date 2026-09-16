#!/usr/bin/env perl

use warnings;
use strict;

use HTML::D3;
use Test::Most tests => 18;

my $chart = HTML::D3->new(
	width  => 800,
	height => 600,
	title  => 'Animated Snippet Test',
);

my $data = [
	['January',  1000],
	['February', 1200],
	['March',     950],
	['April',    1100],
];

# ── 1. Backward compatibility: no opts ──────────────────────────────────────

my $plain;
lives_ok { $plain = $chart->render_zoomable_line_chart_snippet($data) }
	'No-opts call renders without error';

is(ref($plain), 'HASH', 'No-opts: returns hashref');
is($plain->{svg_id}, 'chart', 'No-opts: svg_id is chart');
unlike($plain->{html}, qr/stroke-dashoffset/, 'No-opts: no stroke-dashoffset');
unlike($plain->{html}, qr/initialDrawDone/,   'No-opts: no initialDrawDone guard');
unlike($plain->{html}, qr/<!DOCTYPE/i,        'No-opts: no DOCTYPE (still a snippet)');

# ── 2. Backward compatibility: animated => 0 explicitly ─────────────────────

my $nonanim;
lives_ok { $nonanim = $chart->render_zoomable_line_chart_snippet($data, { animated => 0 }) }
	'animated=>0 call renders without error';
unlike($nonanim->{html}, qr/stroke-dashoffset/, 'animated=>0: no stroke-dashoffset');

# ── 3. Animated mode ─────────────────────────────────────────────────────────

my $anim;
lives_ok { $anim = $chart->render_zoomable_line_chart_snippet($data, { animated => 1 }) }
	'animated=>1 call renders without error';

is(ref($anim), 'HASH', 'Animated: returns hashref');
is($anim->{svg_id}, 'chart', 'Animated: svg_id is chart');

my $html = $anim->{html};
like($html, qr/stroke-dashoffset/,         'Animated: stroke-dashoffset present');
like($html, qr/initialDrawDone/,           'Animated: initialDrawDone guard present');
like($html, qr/prefers-reduced-motion/,    'Animated: prefers-reduced-motion check present');
like($html, qr/d3\.easeLinear/,            'Animated: d3.easeLinear present');
unlike($html, qr/<!DOCTYPE/i,             'Animated: no DOCTYPE (still a snippet)');

# ── 4. Error handling unchanged ──────────────────────────────────────────────

throws_ok {
	$chart->render_zoomable_line_chart_snippet('bad');
} qr/Data must be an array of arrays/, 'Dies on invalid data';

throws_ok {
	$chart->render_zoomable_line_chart_snippet('bad', { animated => 1 });
} qr/Data must be an array of arrays/, 'Dies on invalid data with animated flag';

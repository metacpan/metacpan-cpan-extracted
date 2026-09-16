#!/usr/bin/env perl
# Black-box unit tests for HTML::D3.
#
# Every test is derived from the public API as documented in the module POD.
# The exhaustive ledger at the top enumerates every documented error message
# and return state; each is deleted as the corresponding condition is verified.
# The ledger must be empty at the end -- any remaining key is an untested
# documented behaviour and causes an explicit fail().
#
# Test::Mockingbird is used to isolate the object constructor from external
# config-file side-effects (Object::Configure::configure) so that default
# values always come from new() itself.

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Readonly;

use_ok('HTML::D3');

# ─────────────────────────────────────────────────────────────────────────────
# Shared fixtures -- Readonly prevents accidental mutation across subtests.
# ─────────────────────────────────────────────────────────────────────────────

Readonly my $DEFAULT_WIDTH  => 800;
Readonly my $DEFAULT_HEIGHT => 600;
Readonly my $DEFAULT_TITLE  => 'Chart';
Readonly my $D3_CDN         => 'https://d3js.org/d3.v7.min.js';
Readonly my $SVG_ID         => 'chart';

# Exact die() strings the module promises -- changing them breaks the API.
Readonly my $ERR_NOT_OPTIONAL   => 'Data is not optional';
Readonly my $ERR_ARRAY_OF_ARRAY => 'Data must be an array of arrays';
Readonly my $ERR_ARRAY_OF_HASH  => 'Data must be an array of hashes';

# Minimal valid data for simple (array-of-arrays) render methods.
Readonly my @SIMPLE_DATA => (
	['January',  1_000],
	['February', 1_200],
	['March',      950],
);

# Extra tooltip data: one annotated and one plain point.
Readonly my @EXTRA_DATA => (
	['January',  1_000, { Region => 'North', SKU => 'X1' }],
	['February', 1_200],
);

# Valid data for multi-series methods.
Readonly my @MULTI_DATA => (
	{
		name => 'Series A',
		data => [
			{ label => 'January',  value => 1_000 },
			{ label => 'February', value => 1_200 },
		],
	},
	{
		name => 'Series B',
		data => [
			{ label => 'January',  value =>   500 },
			{ label => 'February', value =>   750 },
		],
	},
);

# ─────────────────────────────────────────────────────────────────────────────
# Exhaustive API Contract Ledger
#
# Each key names a documented condition (error, return type, or output feature).
# delete() it exactly when the corresponding assertion passes.
# At end-of-file, remaining keys are reported as untested failures.
# ─────────────────────────────────────────────────────────────────────────────

my %LEDGER = (
	# new()
	'new: returns blessed HTML::D3 object'             => 1,
	'new: default width 800'                           => 1,
	'new: default height 600'                          => 1,
	'new: default title Chart'                         => 1,
	'new: custom width applied'                        => 1,
	'new: custom height applied'                       => 1,
	'new: custom title applied'                        => 1,
	'new: accepts hashref args'                        => 1,
	'new: clone inherits parent width'                 => 1,
	'new: clone inherits parent height'                => 1,
	'new: clone override applies'                      => 1,
	'new: clone is distinct object'                    => 1,

	# render_bar_chart
	'bar: die data not optional'                       => 1,
	'bar: die non-array (string)'                      => 1,
	'bar: die non-array (hashref)'                     => 1,
	'bar: returns string'                              => 1,
	'bar: DOCTYPE present'                             => 1,
	'bar: D3 CDN loaded'                               => 1,
	'bar: SVG element present'                         => 1,
	'bar: title in h1'                                 => 1,
	'bar: data label in JSON'                          => 1,
	'bar: d3.scaleBand present'                        => 1,

	# render_animated_bar_chart
	'anim-bar: die data not optional'                  => 1,
	'anim-bar: die non-array (string)'                 => 1,
	'anim-bar: die non-array (hashref)'                => 1,
	'anim-bar: returns string'                         => 1,
	'anim-bar: DOCTYPE present'                        => 1,
	'anim-bar: D3 CDN loaded'                          => 1,
	'anim-bar: SVG element present'                    => 1,
	'anim-bar: d3.scaleBand present'                   => 1,
	'anim-bar: transition present'                     => 1,
	'anim-bar: stagger delay present'                  => 1,

	# render_pie_chart
	'pie: die data not optional'                       => 1,
	'pie: die non-array (string)'                      => 1,
	'pie: die non-array (hashref)'                     => 1,
	'pie: returns string'                              => 1,
	'pie: DOCTYPE present'                             => 1,
	'pie: D3 CDN loaded'                               => 1,
	'pie: SVG element present'                         => 1,
	'pie: d3.pie present'                              => 1,
	'pie: d3.schemeCategory10 present'                 => 1,

	# render_animated_pie_chart
	'anim-pie: die data not optional'                  => 1,
	'anim-pie: die non-array'                          => 1,
	'anim-pie: returns string'                         => 1,
	'anim-pie: DOCTYPE present'                        => 1,
	'anim-pie: D3 CDN loaded'                          => 1,
	'anim-pie: SVG element present'                    => 1,
	'anim-pie: attrTween present'                      => 1,
	'anim-pie: d3.interpolate present'                 => 1,
	'anim-pie: labels fade in with opacity'            => 1,

	# render_pie_chart_snippet
	'pie-snip: die non-array'                          => 1,
	'pie-snip: returns hashref'                        => 1,
	'pie-snip: svg_id is pie_chart'                    => 1,
	'pie-snip: html is string'                         => 1,
	'pie-snip: no DOCTYPE'                             => 1,
	'pie-snip: no html wrapper'                        => 1,
	'pie-snip: SVG element present'                    => 1,
	'pie-snip: d3.pie present'                         => 1,
	'pie-snip: tableau10 default scheme'               => 1,
	'pie-snip: animated attrTween present'             => 1,
	'pie-snip: animated initialDrawDone present'       => 1,
	'pie-snip: animated prefers-reduced-motion'        => 1,
	'pie-snip: donut innerRadius present'              => 1,
	'pie-snip: zero slice omitted'                     => 1,
	'pie-snip: negative value absolutised'             => 1,

	# render_animated_line_chart
	'anim-line: die non-array'                         => 1,
	'anim-line: returns string'                        => 1,
	'anim-line: DOCTYPE present'                       => 1,
	'anim-line: D3 CDN loaded'                         => 1,
	'anim-line: SVG element present'                   => 1,
	'anim-line: d3.easeLinear present'                 => 1,
	'anim-line: stroke-dashoffset present'             => 1,
	'anim-line: circles fade in with opacity'          => 1,

	# render_line_chart
	'line: die non-array'                              => 1,
	'line: returns string'                             => 1,
	'line: DOCTYPE present'                            => 1,
	'line: D3 CDN loaded'                              => 1,
	'line: SVG element present'                        => 1,
	'line: d3.scalePoint present'                      => 1,
	'line: d3.line present'                            => 1,

	# render_line_chart_with_tooltips
	'tooltips: die non-array'                          => 1,
	'tooltips: returns string'                         => 1,
	'tooltips: DOCTYPE present'                        => 1,
	'tooltips: tooltip div present'                    => 1,
	'tooltips: mouseover handler present'              => 1,
	'tooltips: no raw </b>'                            => 1,
	'tooltips: escaped <\/b> present'                  => 1,

	# render_line_chart_snippet
	'snippet: die non-array'                           => 1,
	'snippet: returns hashref'                         => 1,
	'snippet: svg_id is chart'                         => 1,
	'snippet: html is string'                          => 1,
	'snippet: no DOCTYPE'                              => 1,
	'snippet: no html wrapper'                         => 1,
	'snippet: no body wrapper'                         => 1,
	'snippet: no head closing'                         => 1,
	'snippet: SVG element present'                     => 1,
	'snippet: tooltip div present'                     => 1,
	'snippet: mouseover present'                       => 1,
	'snippet: no raw </b>'                             => 1,
	'snippet: escaped <\/b> present'                   => 1,
	'snippet: extra hashref serialised as d.extra'     => 1,
	'snippet: extra key appears in JSON'               => 1,
	'snippet: Object.entries(d.extra) in mouseover'    => 1,
	'snippet: non-hashref third element ignored'       => 1,
	'snippet: exactly one extra in data'               => 1,

	# render_zoomable_line_chart_snippet (plain)
	'zoom: die non-array'                              => 1,
	'zoom: returns hashref'                            => 1,
	'zoom: svg_id is chart'                            => 1,
	'zoom: html is string'                             => 1,
	'zoom: no DOCTYPE'                                 => 1,
	'zoom: no html wrapper'                            => 1,
	'zoom: d3.brushX present'                          => 1,
	'zoom: Reset zoom button present'                  => 1,
	'zoom: allData declared'                           => 1,
	'zoom: currentData declared'                       => 1,
	'zoom: zoomed.length < 2 guard'                    => 1,
	'zoom: reset restores allData.slice'               => 1,
	'zoom: no raw </b>'                                => 1,
	'zoom: escaped <\/b> present'                      => 1,
	'zoom: extra data serialised'                      => 1,
	'zoom: Object.entries(d.extra) present'            => 1,

	# render_zoomable_line_chart_snippet (animated => 1)
	'zoom-anim: no stroke-dashoffset when not animated' => 1,
	'zoom-anim: stroke-dashoffset present'             => 1,
	'zoom-anim: initialDrawDone guard present'         => 1,
	'zoom-anim: prefers-reduced-motion check present'  => 1,
	'zoom-anim: d3.easeLinear present'                 => 1,
	'zoom-anim: no DOCTYPE (still snippet)'            => 1,
	'zoom-anim: svg_id unchanged'                      => 1,

	# render_multi_series_line_chart_with_tooltips
	'ms-tt: die non-array'                             => 1,
	'ms-tt: returns string'                            => 1,
	'ms-tt: DOCTYPE present'                           => 1,
	'ms-tt: tooltip div present'                       => 1,
	'ms-tt: series name in output'                     => 1,
	'ms-tt: no raw </b>'                               => 1,
	'ms-tt: escaped <\/b> present'                     => 1,

	# render_multi_series_line_chart_with_animated_tooltips
	'ms-anim: die non-array'                           => 1,
	'ms-anim: returns string'                          => 1,
	'ms-anim: DOCTYPE present'                         => 1,
	'ms-anim: translateY animation present'            => 1,
	'ms-anim: no raw </b>'                             => 1,
	'ms-anim: escaped <\/b> present'                   => 1,

	# render_multi_series_line_chart_with_legends
	'ms-leg: die non-array'                            => 1,
	'ms-leg: returns string'                           => 1,
	'ms-leg: DOCTYPE present'                          => 1,
	'ms-leg: legend CSS class in stylesheet'           => 1,
	'ms-leg: series name in output'                    => 1,
	'ms-leg: no raw </b>'                              => 1,
	'ms-leg: escaped <\/b> present'                    => 1,

	# render_multi_series_line_chart_with_interactive_legends
	'ms-int: die non-array'                            => 1,
	'ms-int: returns string'                           => 1,
	'ms-int: DOCTYPE present'                          => 1,
	'ms-int: isVisible variable present'               => 1,
	'ms-int: isVisible ? 0 : 1 toggle present'         => 1,
	'ms-int: legend CSS class in stylesheet'           => 1,
	'ms-int: no raw </b>'                              => 1,
	'ms-int: escaped <\/b> present'                    => 1,
);

# Marks a ledger entry as verified.  Calling with an unknown key catches typos.
sub mark {
	my ($key) = @_;
	exists $LEDGER{$key}
		? delete $LEDGER{$key}
		: fail("BUG: unknown ledger key '$key'");
}

# ─────────────────────────────────────────────────────────────────────────────
# new()
# ─────────────────────────────────────────────────────────────────────────────

subtest 'new() -- default values' => sub {
	# Mock Object::Configure so no config file on the test runner's machine
	# can interfere with the default-value assertions.
	mock('Object::Configure::configure' => sub { $_[1] });

	my $chart = new_ok('HTML::D3');

	isa_ok($chart, 'HTML::D3', 'constructor returns a blessed HTML::D3 object');
	mark('new: returns blessed HTML::D3 object');

	is($chart->{width},  $DEFAULT_WIDTH,  'default width is 800');
	mark('new: default width 800');

	is($chart->{height}, $DEFAULT_HEIGHT, 'default height is 600');
	mark('new: default height 600');

	is($chart->{title},  $DEFAULT_TITLE,  'default title is "Chart"');
	mark('new: default title Chart');

	restore('Object::Configure::configure');

	diag('new() object: ' . join(', ', map { "$_=$chart->{$_}" } sort keys %$chart))
		if $ENV{TEST_VERBOSE};
};

subtest 'new() -- custom flat-hash arguments' => sub {
	my $chart = HTML::D3->new(width => 1_024, height => 768, title => 'Sales');

	is($chart->{width},  1_024,   'custom width stored');
	mark('new: custom width applied');

	is($chart->{height}, 768,     'custom height stored');
	mark('new: custom height applied');

	is($chart->{title},  'Sales', 'custom title stored');
	mark('new: custom title applied');
};

subtest 'new() -- hashref arguments' => sub {
	# The POD documents that new() accepts both flat-hash and hashref calling styles.
	my $chart = HTML::D3->new({ width => 640, height => 480, title => 'Ref' });

	is($chart->{width},  640,   'hashref width stored');
	is($chart->{height}, 480,   'hashref height stored');
	is($chart->{title},  'Ref', 'hashref title stored');
	mark('new: accepts hashref args');
};

subtest 'new() -- cloning: called on a blessed object' => sub {
	# The POD documents that calling ->new() on an existing object returns a
	# new, independent object that inherits the caller's fields and applies
	# any overrides passed.
	my $orig  = HTML::D3->new(width => 400, height => 300, title => 'Original');
	my $clone = $orig->new(title => 'Clone');

	isa_ok($clone, 'HTML::D3', 'clone is a blessed HTML::D3 object');

	is($clone->{width},  400,     'clone inherits width from parent');
	mark('new: clone inherits parent width');

	is($clone->{height}, 300,     'clone inherits height from parent');
	mark('new: clone inherits parent height');

	is($clone->{title},  'Clone', 'clone title overridden');
	mark('new: clone override applies');

	isnt("$clone", "$orig", 'clone is a distinct object reference');
	mark('new: clone is distinct object');
};

# ─────────────────────────────────────────────────────────────────────────────
# render_bar_chart()
# ─────────────────────────────────────────────────────────────────────────────

subtest 'render_bar_chart() -- validation errors' => sub {
	my $chart = HTML::D3->new();

	throws_ok(
		sub { $chart->render_bar_chart(undef) },
		qr/\Q$ERR_NOT_OPTIONAL\E/,
		'undef data dies with exact "Data is not optional" message',
	);
	mark('bar: die data not optional');

	throws_ok(
		sub { $chart->render_bar_chart('a string') },
		qr/\Q$ERR_ARRAY_OF_ARRAY\E/,
		'string data dies with exact "Data must be an array of arrays" message',
	);
	mark('bar: die non-array (string)');

	throws_ok(
		sub { $chart->render_bar_chart({ key => 'val' }) },
		qr/\Q$ERR_ARRAY_OF_ARRAY\E/,
		'hashref data dies with exact "Data must be an array of arrays" message',
	);
	mark('bar: die non-array (hashref)');
};

subtest 'render_bar_chart() -- output content' => sub {
	my $chart = HTML::D3->new(width => 800, height => 600, title => 'Bar Test');
	my $html  = $chart->render_bar_chart(\@SIMPLE_DATA);

	returns_ok($html, { type => 'string' }, 'return value is a plain string scalar');
	mark('bar: returns string');

	like($html, qr/<!DOCTYPE html>/i, 'HTML5 DOCTYPE present');
	mark('bar: DOCTYPE present');

	like($html, qr/\Q$D3_CDN\E/, 'D3 CDN URL present in output');
	mark('bar: D3 CDN loaded');

	like($html, qr/<svg id="$SVG_ID"/, 'SVG element with id="chart" present');
	mark('bar: SVG element present');

	like($html, qr/Bar Test<\/h1>/, 'object title appears in h1');
	mark('bar: title in h1');

	like($html, qr/January/, 'first data label appears in serialised JSON');
	mark('bar: data label in JSON');

	like($html, qr/d3\.scaleBand/, 'bar chart uses d3.scaleBand for x-axis');
	mark('bar: d3.scaleBand present');

	diag('render_bar_chart output length: ' . length($html)) if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# render_animated_bar_chart()
# ─────────────────────────────────────────────────────────────────────────────

subtest 'render_animated_bar_chart() -- validation errors' => sub {
	my $chart = HTML::D3->new();

	throws_ok(
		sub { $chart->render_animated_bar_chart(undef) },
		qr/\Q$ERR_NOT_OPTIONAL\E/,
		'undef data dies with "Data is not optional"',
	);
	mark('anim-bar: die data not optional');

	throws_ok(
		sub { $chart->render_animated_bar_chart('a string') },
		qr/\Q$ERR_ARRAY_OF_ARRAY\E/,
		'string data dies with "Data must be an array of arrays"',
	);
	mark('anim-bar: die non-array (string)');

	throws_ok(
		sub { $chart->render_animated_bar_chart({ key => 'val' }) },
		qr/\Q$ERR_ARRAY_OF_ARRAY\E/,
		'hashref data dies with "Data must be an array of arrays"',
	);
	mark('anim-bar: die non-array (hashref)');
};

subtest 'render_animated_bar_chart() -- output content' => sub {
	my $chart = HTML::D3->new(width => 800, height => 600, title => 'Anim Bar');
	my $html  = $chart->render_animated_bar_chart(\@SIMPLE_DATA);

	returns_ok($html, { type => 'string' }, 'return value is a plain string scalar');
	mark('anim-bar: returns string');

	like($html, qr/<!DOCTYPE html>/i, 'HTML5 DOCTYPE present');
	mark('anim-bar: DOCTYPE present');

	like($html, qr/\Q$D3_CDN\E/, 'D3 CDN URL present');
	mark('anim-bar: D3 CDN loaded');

	like($html, qr/<svg id="$SVG_ID"/, 'SVG element present');
	mark('anim-bar: SVG element present');

	like($html, qr/d3\.scaleBand/, 'uses d3.scaleBand for x-axis');
	mark('anim-bar: d3.scaleBand present');

	like($html, qr/\.transition\(\)/, 'D3 transition() present for animation');
	mark('anim-bar: transition present');

	like($html, qr/\.delay\(/, 'per-bar stagger delay present');
	mark('anim-bar: stagger delay present');

	diag('render_animated_bar_chart output length: ' . length($html)) if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# render_pie_chart()
# ─────────────────────────────────────────────────────────────────────────────

subtest 'render_pie_chart() -- validation errors' => sub {
	my $chart = HTML::D3->new();

	throws_ok(
		sub { $chart->render_pie_chart(undef) },
		qr/\Q$ERR_NOT_OPTIONAL\E/,
		'undef data dies with "Data is not optional"',
	);
	mark('pie: die data not optional');

	throws_ok(
		sub { $chart->render_pie_chart('a string') },
		qr/\Q$ERR_ARRAY_OF_ARRAY\E/,
		'string data dies with "Data must be an array of arrays"',
	);
	mark('pie: die non-array (string)');

	throws_ok(
		sub { $chart->render_pie_chart({ key => 'val' }) },
		qr/\Q$ERR_ARRAY_OF_ARRAY\E/,
		'hashref data dies with "Data must be an array of arrays"',
	);
	mark('pie: die non-array (hashref)');
};

subtest 'render_pie_chart() -- output content' => sub {
	my $chart = HTML::D3->new(width => 800, height => 600, title => 'Pie Test');
	my $html  = $chart->render_pie_chart(\@SIMPLE_DATA);

	returns_ok($html, { type => 'string' }, 'return value is a plain string scalar');
	mark('pie: returns string');

	like($html, qr/<!DOCTYPE html>/i, 'HTML5 DOCTYPE present');
	mark('pie: DOCTYPE present');

	like($html, qr/\Q$D3_CDN\E/, 'D3 CDN URL present');
	mark('pie: D3 CDN loaded');

	like($html, qr/<svg id="$SVG_ID"/, 'SVG element present');
	mark('pie: SVG element present');

	like($html, qr/d3\.pie\(\)/, 'd3.pie() generator present');
	mark('pie: d3.pie present');

	like($html, qr/d3\.schemeCategory10/, 'd3.schemeCategory10 colour scheme present');
	mark('pie: d3.schemeCategory10 present');

	diag('render_pie_chart output length: ' . length($html)) if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# render_animated_pie_chart()
# ─────────────────────────────────────────────────────────────────────────────

subtest 'render_animated_pie_chart() -- validation errors' => sub {
	my $chart = HTML::D3->new();

	throws_ok(
		sub { $chart->render_animated_pie_chart(undef) },
		qr/\Q$ERR_NOT_OPTIONAL\E/,
		'undef data dies with "Data is not optional"',
	);
	mark('anim-pie: die data not optional');

	throws_ok(
		sub { $chart->render_animated_pie_chart('bad') },
		qr/\Q$ERR_ARRAY_OF_ARRAY\E/,
		'non-array data dies',
	);
	mark('anim-pie: die non-array');
};

subtest 'render_animated_pie_chart() -- output content' => sub {
	my $chart = HTML::D3->new(width => 800, height => 600, title => 'Anim Pie');
	my $html  = $chart->render_animated_pie_chart(\@SIMPLE_DATA);

	returns_ok($html, { type => 'string' }, 'return value is a plain string scalar');
	mark('anim-pie: returns string');

	like($html, qr/<!DOCTYPE html>/i, 'HTML5 DOCTYPE present');
	mark('anim-pie: DOCTYPE present');

	like($html, qr/\Q$D3_CDN\E/, 'D3 CDN URL present');
	mark('anim-pie: D3 CDN loaded');

	like($html, qr/<svg id="$SVG_ID"/, 'SVG element present');
	mark('anim-pie: SVG element present');

	like($html, qr/attrTween/, 'attrTween animation present');
	mark('anim-pie: attrTween present');

	like($html, qr/d3\.interpolate/, 'd3.interpolate used for slice tween');
	mark('anim-pie: d3.interpolate present');

	like($html, qr/\.attr\("opacity",\s*0\)/, 'labels start at opacity 0 for fade-in');
	mark('anim-pie: labels fade in with opacity');

	diag('render_animated_pie_chart output length: ' . length($html)) if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# render_pie_chart_snippet()
# ─────────────────────────────────────────────────────────────────────────────

subtest 'render_pie_chart_snippet() -- validation errors' => sub {
	throws_ok(
		sub { HTML::D3->new()->render_pie_chart_snippet('bad') },
		qr/\Q$ERR_ARRAY_OF_ARRAY\E/,
		'non-array data dies',
	);
	mark('pie-snip: die non-array');
};

subtest 'render_pie_chart_snippet() -- return structure' => sub {
	my $fragment = HTML::D3->new()->render_pie_chart_snippet(\@SIMPLE_DATA);

	returns_ok($fragment, { type => 'hashref' }, 'return value is a hashref');
	mark('pie-snip: returns hashref');

	is($fragment->{svg_id}, 'pie_chart', 'svg_id is "pie_chart"');
	mark('pie-snip: svg_id is pie_chart');

	returns_ok($fragment->{html}, { type => 'string' }, 'html value is a string');
	mark('pie-snip: html is string');
};

subtest 'render_pie_chart_snippet() -- page-shell absent and D3 primitives' => sub {
	my $html = HTML::D3->new()->render_pie_chart_snippet(\@SIMPLE_DATA)->{html};

	unlike($html, qr/<!DOCTYPE/i, 'no DOCTYPE in fragment');
	mark('pie-snip: no DOCTYPE');

	unlike($html, qr/<html/i, 'no <html> element in fragment');
	mark('pie-snip: no html wrapper');

	like($html, qr/<svg id="pie_chart"/, 'SVG element present with id="pie_chart"');
	mark('pie-snip: SVG element present');

	like($html, qr/d3\.pie\(\)/, 'd3.pie() present in fragment');
	mark('pie-snip: d3.pie present');

	like($html, qr/schemeTableau10/, 'default colour scheme is tableau10');
	mark('pie-snip: tableau10 default scheme');
};

subtest 'render_pie_chart_snippet() -- opts: animated => 1' => sub {
	my $html = HTML::D3->new()->render_pie_chart_snippet(\@SIMPLE_DATA, { animated => 1 })->{html};

	like($html, qr/attrTween/, 'attrTween present when animated');
	mark('pie-snip: animated attrTween present');

	like($html, qr/initialDrawDone/, 'initialDrawDone guard present when animated');
	mark('pie-snip: animated initialDrawDone present');

	like($html, qr/prefers-reduced-motion/, 'prefers-reduced-motion check present when animated');
	mark('pie-snip: animated prefers-reduced-motion');
};

subtest 'render_pie_chart_snippet() -- opts: donut => 1' => sub {
	my $html = HTML::D3->new()->render_pie_chart_snippet(\@SIMPLE_DATA, { donut => 1 })->{html};

	like($html, qr/innerRadius/, 'innerRadius > 0 present when donut mode');
	mark('pie-snip: donut innerRadius present');
};

subtest 'render_pie_chart_snippet() -- zero and negative value normalisation' => sub {
	my $html = HTML::D3->new()
		->render_pie_chart_snippet([['Zero', 0], ['Pos', 50]])->{html};
	unlike($html, qr/"label":"Zero"/, 'zero-value slice omitted from emitted data');
	mark('pie-snip: zero slice omitted');

	my $html2 = HTML::D3->new()
		->render_pie_chart_snippet([['Neg', -20], ['Pos', 80]])->{html};
	like($html2, qr/"value":20/, 'negative value converted to its absolute value');
	mark('pie-snip: negative value absolutised');
};

# ─────────────────────────────────────────────────────────────────────────────
# render_animated_line_chart()
# ─────────────────────────────────────────────────────────────────────────────

subtest 'render_animated_line_chart() -- validation errors' => sub {
	throws_ok(
		sub { HTML::D3->new()->render_animated_line_chart('bad') },
		qr/\Q$ERR_ARRAY_OF_ARRAY\E/,
		'non-array data dies',
	);
	mark('anim-line: die non-array');
};

subtest 'render_animated_line_chart() -- output content' => sub {
	my $chart = HTML::D3->new(width => 800, height => 600, title => 'Anim Line');
	my $html  = $chart->render_animated_line_chart(\@SIMPLE_DATA);

	returns_ok($html, { type => 'string' }, 'return value is a plain string scalar');
	mark('anim-line: returns string');

	like($html, qr/<!DOCTYPE html>/i, 'HTML5 DOCTYPE present');
	mark('anim-line: DOCTYPE present');

	like($html, qr/\Q$D3_CDN\E/, 'D3 CDN URL present');
	mark('anim-line: D3 CDN loaded');

	like($html, qr/<svg id="$SVG_ID"/, 'SVG element present');
	mark('anim-line: SVG element present');

	like($html, qr/d3\.easeLinear/, 'd3.easeLinear easing present');
	mark('anim-line: d3.easeLinear present');

	like($html, qr/stroke-dashoffset/, 'stroke-dashoffset animation present');
	mark('anim-line: stroke-dashoffset present');

	like($html, qr/\.attr\("opacity",\s*0\)/, 'circles start with opacity 0');
	mark('anim-line: circles fade in with opacity');

	diag('render_animated_line_chart output length: ' . length($html)) if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# render_line_chart()
# ─────────────────────────────────────────────────────────────────────────────

subtest 'render_line_chart() -- validation errors' => sub {
	throws_ok(
		sub { HTML::D3->new()->render_line_chart('bad') },
		qr/\Q$ERR_ARRAY_OF_ARRAY\E/,
		'non-array data dies',
	);
	mark('line: die non-array');
};

subtest 'render_line_chart() -- output content' => sub {
	my $chart = HTML::D3->new(title => 'Line Test');
	my $html  = $chart->render_line_chart(\@SIMPLE_DATA);

	returns_ok($html, { type => 'string' }, 'return value is a plain string scalar');
	mark('line: returns string');

	like($html, qr/<!DOCTYPE html>/i, 'HTML5 DOCTYPE present');
	mark('line: DOCTYPE present');

	like($html, qr/\Q$D3_CDN\E/, 'D3 CDN URL present');
	mark('line: D3 CDN loaded');

	like($html, qr/<svg id="$SVG_ID"/, 'SVG element present');
	mark('line: SVG element present');

	like($html, qr/d3\.scalePoint/, 'line chart uses d3.scalePoint for x-axis');
	mark('line: d3.scalePoint present');

	like($html, qr/d3\.line\(\)/, 'line chart uses d3.line() for path generation');
	mark('line: d3.line present');
};

# ─────────────────────────────────────────────────────────────────────────────
# render_line_chart_with_tooltips()
# ─────────────────────────────────────────────────────────────────────────────

subtest 'render_line_chart_with_tooltips() -- validation errors' => sub {
	throws_ok(
		sub { HTML::D3->new()->render_line_chart_with_tooltips('bad') },
		qr/\Q$ERR_ARRAY_OF_ARRAY\E/,
		'non-array data dies',
	);
	mark('tooltips: die non-array');
};

subtest 'render_line_chart_with_tooltips() -- output content' => sub {
	my $html = HTML::D3->new(title => 'Tooltip Test')
	                   ->render_line_chart_with_tooltips(\@SIMPLE_DATA);

	returns_ok($html, { type => 'string' }, 'return value is a plain string scalar');
	mark('tooltips: returns string');

	like($html, qr/<!DOCTYPE html>/i, 'HTML5 DOCTYPE present');
	mark('tooltips: DOCTYPE present');

	like($html, qr/<div class="tooltip" id="tooltip">/, 'tooltip div present');
	mark('tooltips: tooltip div present');

	like($html, qr/mouseover/, 'mouseover handler present');
	mark('tooltips: mouseover handler present');

	# The POD formally specifies that "</b>" must NOT appear inside <script>.
	# html-tidy rejects the "<" + "/" + letter sequence; the module must
	# emit "<\/b>" (with backslash) to satisfy it.
	unlike($html, qr{</b>},   'raw </b> absent (html-tidy compliance)');
	mark('tooltips: no raw </b>');

	like($html, qr{<\\/b>}, 'escaped <\/b> present in tooltip JS strings');
	mark('tooltips: escaped <\/b> present');
};

# ─────────────────────────────────────────────────────────────────────────────
# render_line_chart_snippet()
# ─────────────────────────────────────────────────────────────────────────────

subtest 'render_line_chart_snippet() -- validation errors' => sub {
	throws_ok(
		sub { HTML::D3->new()->render_line_chart_snippet('bad') },
		qr/\Q$ERR_ARRAY_OF_ARRAY\E/,
		'non-array data dies',
	);
	mark('snippet: die non-array');
};

subtest 'render_line_chart_snippet() -- return structure' => sub {
	# The POD specifies a hashref with exactly svg_id and html keys.
	my $frag = HTML::D3->new()->render_line_chart_snippet(\@SIMPLE_DATA);

	returns_ok($frag, { type => 'hashref' }, 'return value is a hash reference');
	mark('snippet: returns hashref');

	is($frag->{svg_id}, $SVG_ID, 'svg_id value is "chart"');
	mark('snippet: svg_id is chart');

	returns_ok($frag->{html}, { type => 'string' }, 'html value is a string scalar');
	mark('snippet: html is string');
};

subtest 'render_line_chart_snippet() -- fragment must contain no page-shell' => sub {
	# POD: "no <!DOCTYPE>, <html>, <head>, or <body> wrapper"
	my $html = HTML::D3->new()->render_line_chart_snippet(\@SIMPLE_DATA)->{html};

	unlike($html, qr/<!DOCTYPE/i,    'fragment has no DOCTYPE');
	mark('snippet: no DOCTYPE');

	unlike($html, qr/<html/i,        'fragment has no <html> element');
	mark('snippet: no html wrapper');

	unlike($html, qr/<body/i,        'fragment has no <body> element');
	mark('snippet: no body wrapper');

	unlike($html, qr{</head>}i,      'fragment has no </head>');
	mark('snippet: no head closing');
};

subtest 'render_line_chart_snippet() -- content and html-tidy safety' => sub {
	my $html = HTML::D3->new(width => 800, height => 600)
	                   ->render_line_chart_snippet(\@SIMPLE_DATA)
	                   ->{html};

	like($html, qr/<svg id="$SVG_ID"/, 'SVG element present');
	mark('snippet: SVG element present');

	like($html, qr/<div class="tooltip"/, 'tooltip div present in fragment');
	mark('snippet: tooltip div present');

	like($html, qr/mouseover/, 'mouseover handler present');
	mark('snippet: mouseover present');

	unlike($html, qr{</b>},   'raw </b> absent from fragment JavaScript');
	mark('snippet: no raw </b>');

	like($html, qr{<\\/b>}, 'escaped <\/b> present');
	mark('snippet: escaped <\/b> present');
};

subtest 'render_line_chart_snippet() -- optional third element (extra tooltip data)' => sub {
	# POD specifies an optional third element per data pair: a hashref of extra
	# key/value rows shown in the tooltip.  A non-hashref third element is silently
	# ignored.

	# --- annotated point ---
	my $html_extra = HTML::D3->new()->render_line_chart_snippet(\@EXTRA_DATA)->{html};

	like($html_extra, qr/"extra":\{/, '"extra" object present in D3 JSON binding');
	mark('snippet: extra hashref serialised as d.extra');

	like($html_extra, qr/Region/, 'extra key "Region" appears in serialised JSON');
	mark('snippet: extra key appears in JSON');

	like($html_extra, qr/Object\.entries\(d\.extra\)/,
		'd.extra iterated with Object.entries in mouseover handler');
	mark('snippet: Object.entries(d.extra) in mouseover');

	# Only the first data point has extra data; verify exactly one occurrence.
	my @extra_hits = ($html_extra =~ m{"extra":\{}g);
	is(scalar @extra_hits, 1, 'exactly one data point carries the extra object');
	mark('snippet: exactly one extra in data');

	# --- non-hashref third element must be silently ignored ---
	my @plain = (['Jan', 100, 'not-a-ref'], ['Feb', 200]);
	my $html_plain = HTML::D3->new()->render_line_chart_snippet(\@plain)->{html};
	unlike($html_plain, qr/"extra"/, 'non-hashref third element produces no extra key');
	mark('snippet: non-hashref third element ignored');
};

# ─────────────────────────────────────────────────────────────────────────────
# render_zoomable_line_chart_snippet()
# ─────────────────────────────────────────────────────────────────────────────

subtest 'render_zoomable_line_chart_snippet() -- validation errors' => sub {
	throws_ok(
		sub { HTML::D3->new()->render_zoomable_line_chart_snippet('bad') },
		qr/\Q$ERR_ARRAY_OF_ARRAY\E/,
		'non-array data dies',
	);
	mark('zoom: die non-array');
};

subtest 'render_zoomable_line_chart_snippet() -- return structure' => sub {
	my $frag = HTML::D3->new()->render_zoomable_line_chart_snippet(\@SIMPLE_DATA);

	returns_ok($frag, { type => 'hashref' }, 'return value is a hash reference');
	mark('zoom: returns hashref');

	is($frag->{svg_id}, $SVG_ID, 'svg_id is "chart"');
	mark('zoom: svg_id is chart');

	returns_ok($frag->{html}, { type => 'string' }, 'html value is a string scalar');
	mark('zoom: html is string');
};

subtest 'render_zoomable_line_chart_snippet() -- page-shell absent' => sub {
	my $html = HTML::D3->new()->render_zoomable_line_chart_snippet(\@SIMPLE_DATA)->{html};

	unlike($html, qr/<!DOCTYPE/i, 'fragment has no DOCTYPE');
	mark('zoom: no DOCTYPE');

	unlike($html, qr/<html/i, 'fragment has no <html> wrapper');
	mark('zoom: no html wrapper');
};

subtest 'render_zoomable_line_chart_snippet() -- brush-to-zoom JavaScript features' => sub {
	# The POD specifies: d3.brushX, allData, currentData, Reset zoom button,
	# zoomed.length < 2 guard, and reset restoring allData.slice().
	my $html = HTML::D3->new(width => 800, height => 600)
	                   ->render_zoomable_line_chart_snippet(\@SIMPLE_DATA)
	                   ->{html};

	like($html, qr/d3\.brushX\(\)/, 'd3.brushX() present for brush selection');
	mark('zoom: d3.brushX present');

	like($html, qr/Reset zoom/, 'Reset zoom button text present');
	mark('zoom: Reset zoom button present');

	like($html, qr/const allData\s*=/, 'allData constant declared');
	mark('zoom: allData declared');

	like($html, qr/let\s+currentData\s*=/, 'currentData variable declared');
	mark('zoom: currentData declared');

	like($html, qr/zoomed\.length < 2/, 'single-point zoom guard present');
	mark('zoom: zoomed.length < 2 guard');

	like($html, qr/currentData = allData\.slice\(\)/,
		'Reset click handler restores currentData from allData.slice()');
	mark('zoom: reset restores allData.slice');

	unlike($html, qr{</b>},   'raw </b> absent from fragment JavaScript');
	mark('zoom: no raw </b>');

	like($html, qr{<\\/b>}, 'escaped <\/b> present');
	mark('zoom: escaped <\/b> present');

	diag('zoomable snippet length: ' . length($html)) if $ENV{TEST_VERBOSE};
};

subtest 'render_zoomable_line_chart_snippet() -- animated => 0 (no animation markup)' => sub {
	my $html = HTML::D3->new()->render_zoomable_line_chart_snippet(\@SIMPLE_DATA)->{html};

	unlike($html, qr/stroke-dashoffset/, 'stroke-dashoffset absent when animated omitted');
	mark('zoom-anim: no stroke-dashoffset when not animated');
};

subtest 'render_zoomable_line_chart_snippet() -- animated => 1' => sub {
	# When animated => 1, the emitted JS must include the stroke-dashoffset
	# draw-on technique, the initialDrawDone guard, the prefers-reduced-motion
	# check, and d3.easeLinear.  Return shape must be unchanged.
	my $frag = HTML::D3->new(width => 800, height => 600)
	                   ->render_zoomable_line_chart_snippet(\@SIMPLE_DATA, { animated => 1 });
	my $html = $frag->{html};

	like($html, qr/stroke-dashoffset/, 'stroke-dashoffset animation technique present');
	mark('zoom-anim: stroke-dashoffset present');

	like($html, qr/initialDrawDone/, 'initialDrawDone guard present');
	mark('zoom-anim: initialDrawDone guard present');

	like($html, qr/prefers-reduced-motion/, 'prefers-reduced-motion check present');
	mark('zoom-anim: prefers-reduced-motion check present');

	like($html, qr/d3\.easeLinear/, 'd3.easeLinear present');
	mark('zoom-anim: d3.easeLinear present');

	unlike($html, qr/<!DOCTYPE/i, 'fragment still has no DOCTYPE');
	mark('zoom-anim: no DOCTYPE (still snippet)');

	is($frag->{svg_id}, $SVG_ID, 'svg_id is still "chart" with animated flag');
	mark('zoom-anim: svg_id unchanged');

	diag('animated zoomable snippet length: ' . length($html)) if $ENV{TEST_VERBOSE};
};

subtest 'render_zoomable_line_chart_snippet() -- extra tooltip data' => sub {
	my $html = HTML::D3->new()->render_zoomable_line_chart_snippet(\@EXTRA_DATA)->{html};

	like($html, qr/"extra":\{/, '"extra" object present in JSON data binding');
	mark('zoom: extra data serialised');

	like($html, qr/Object\.entries\(d\.extra\)/,
		'd.extra iterated in mouseover handler');
	mark('zoom: Object.entries(d.extra) present');
};

# ─────────────────────────────────────────────────────────────────────────────
# render_multi_series_line_chart_with_tooltips()
# ─────────────────────────────────────────────────────────────────────────────

subtest 'render_multi_series_line_chart_with_tooltips() -- validation' => sub {
	throws_ok(
		sub { HTML::D3->new()->render_multi_series_line_chart_with_tooltips('bad') },
		qr/\Q$ERR_ARRAY_OF_HASH\E/,
		'non-array data dies with correct message',
	);
	mark('ms-tt: die non-array');
};

subtest 'render_multi_series_line_chart_with_tooltips() -- output' => sub {
	my $html = HTML::D3->new(title => 'Multi TT')
	                   ->render_multi_series_line_chart_with_tooltips(\@MULTI_DATA);

	returns_ok($html, { type => 'string' }, 'return value is a plain string');
	mark('ms-tt: returns string');

	like($html, qr/<!DOCTYPE html>/i, 'HTML5 DOCTYPE present');
	mark('ms-tt: DOCTYPE present');

	like($html, qr/<div class="tooltip" id="tooltip">/, 'tooltip div present');
	mark('ms-tt: tooltip div present');

	like($html, qr/Series A/, 'first series name present in output');
	mark('ms-tt: series name in output');

	unlike($html, qr{</b>},   'raw </b> absent');
	mark('ms-tt: no raw </b>');

	like($html, qr{<\\/b>}, 'escaped <\/b> present');
	mark('ms-tt: escaped <\/b> present');
};

# ─────────────────────────────────────────────────────────────────────────────
# render_multi_series_line_chart_with_animated_tooltips()
# ─────────────────────────────────────────────────────────────────────────────

subtest 'render_multi_series_line_chart_with_animated_tooltips() -- validation' => sub {
	throws_ok(
		sub { HTML::D3->new()->render_multi_series_line_chart_with_animated_tooltips('bad') },
		qr/\Q$ERR_ARRAY_OF_HASH\E/,
		'non-array data dies',
	);
	mark('ms-anim: die non-array');
};

subtest 'render_multi_series_line_chart_with_animated_tooltips() -- output' => sub {
	my $html = HTML::D3->new(title => 'Animated')
	                   ->render_multi_series_line_chart_with_animated_tooltips(\@MULTI_DATA);

	returns_ok($html, { type => 'string' }, 'return value is a plain string');
	mark('ms-anim: returns string');

	like($html, qr/<!DOCTYPE html>/i, 'HTML5 DOCTYPE present');
	mark('ms-anim: DOCTYPE present');

	# POD specifies a CSS translateY slide-in animation on the tooltip.
	like($html, qr/translateY/, 'CSS translateY animation present');
	mark('ms-anim: translateY animation present');

	unlike($html, qr{</b>},   'raw </b> absent');
	mark('ms-anim: no raw </b>');

	like($html, qr{<\\/b>}, 'escaped <\/b> present');
	mark('ms-anim: escaped <\/b> present');
};

# ─────────────────────────────────────────────────────────────────────────────
# render_multi_series_line_chart_with_legends()
# ─────────────────────────────────────────────────────────────────────────────

subtest 'render_multi_series_line_chart_with_legends() -- validation' => sub {
	throws_ok(
		sub { HTML::D3->new()->render_multi_series_line_chart_with_legends('bad') },
		qr/\Q$ERR_ARRAY_OF_HASH\E/,
		'non-array data dies',
	);
	mark('ms-leg: die non-array');
};

subtest 'render_multi_series_line_chart_with_legends() -- output' => sub {
	my $html = HTML::D3->new(title => 'Legends')
	                   ->render_multi_series_line_chart_with_legends(\@MULTI_DATA);

	returns_ok($html, { type => 'string' }, 'return value is a plain string');
	mark('ms-leg: returns string');

	like($html, qr/<!DOCTYPE html>/i, 'HTML5 DOCTYPE present');
	mark('ms-leg: DOCTYPE present');

	# POD specifies a .legend CSS class defined in the stylesheet.
	like($html, qr/\.legend\s*\{/, '.legend CSS class defined in <style> block');
	mark('ms-leg: legend CSS class in stylesheet');

	like($html, qr/Series A/, 'series name present in output');
	mark('ms-leg: series name in output');

	unlike($html, qr{</b>},   'raw </b> absent');
	mark('ms-leg: no raw </b>');

	like($html, qr{<\\/b>}, 'escaped <\/b> present');
	mark('ms-leg: escaped <\/b> present');
};

# ─────────────────────────────────────────────────────────────────────────────
# render_multi_series_line_chart_with_interactive_legends()
# ─────────────────────────────────────────────────────────────────────────────

subtest 'render_multi_series_line_chart_with_interactive_legends() -- validation' => sub {
	throws_ok(
		sub { HTML::D3->new()->render_multi_series_line_chart_with_interactive_legends('bad') },
		qr/\Q$ERR_ARRAY_OF_HASH\E/,
		'non-array data dies',
	);
	mark('ms-int: die non-array');
};

subtest 'render_multi_series_line_chart_with_interactive_legends() -- output' => sub {
	my $html = HTML::D3->new(title => 'Interactive')
	                   ->render_multi_series_line_chart_with_interactive_legends(\@MULTI_DATA);

	returns_ok($html, { type => 'string' }, 'return value is a plain string');
	mark('ms-int: returns string');

	like($html, qr/<!DOCTYPE html>/i, 'HTML5 DOCTYPE present');
	mark('ms-int: DOCTYPE present');

	# POD: "isVisible variable tracks current visibility state"
	like($html, qr/isVisible/, 'isVisible variable declared in legend click handler');
	mark('ms-int: isVisible variable present');

	# POD: "opacity toggled by isVisible ? 0 : 1"
	like($html, qr/isVisible\s*\?\s*0\s*:\s*1/, 'isVisible ? 0 : 1 opacity toggle present');
	mark('ms-int: isVisible ? 0 : 1 toggle present');

	like($html, qr/\.legend\s*\{/, '.legend CSS class defined in <style> block');
	mark('ms-int: legend CSS class in stylesheet');

	unlike($html, qr{</b>},   'raw </b> absent');
	mark('ms-int: no raw </b>');

	like($html, qr{<\\/b>}, 'escaped <\/b> present');
	mark('ms-int: escaped <\/b> present');
};

# ─────────────────────────────────────────────────────────────────────────────
# Ledger check -- every documented condition must have been exercised.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'API contract ledger -- all documented conditions exercised' => sub {
	if(keys %LEDGER) {
		for my $untested (sort keys %LEDGER) {
			fail("UNTESTED documented condition: $untested");
		}
	} else {
		pass('All documented conditions were covered by the test suite');
	}
};

done_testing();

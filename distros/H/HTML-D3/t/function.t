#!/usr/bin/env perl
# White-box function tests for HTML::D3.
#
# Strategy: every public method and both private helpers are tested in isolation.
# We mock internal helpers (via Test::Mockingbird) to verify that callers
# delegate to them rather than inlining equivalent logic.  For actual HTML
# output we test real (unmocked) calls so that the assertions remain meaningful.
# Memory-cycle checks (Test::Memory::Cycle) guard against objects or returned
# hashrefs containing circular references that the GC cannot reclaim.

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Test::Memory::Cycle;
use Scalar::Util qw(refaddr);
use Readonly;

use_ok('HTML::D3');

# ---------------------------------------------------------------------------
# Shared fixtures -- one place to change labels/values if data shape evolves
# ---------------------------------------------------------------------------
Readonly my @SIMPLE_DATA => (
	['January',  1_000],
	['February', 1_200],
	['March',      950],
);

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

Readonly my %EXTRA_ROW => (Region => 'North', SKU => 'X1');

# Two categorical axes x two rows -- enough variation to exercise x/y label sets.
Readonly my @HEATMAP_DATA => (
	['Jan', 'North', 100],
	['Jan', 'South',  50],
	['Feb', 'North',  80],
	['Feb', 'South',  30],
);

Readonly my $DEFAULT_WIDTH  => 800;
Readonly my $DEFAULT_HEIGHT => 600;
Readonly my $DEFAULT_TITLE  => 'Chart';
Readonly my $CDN_URL        => 'https://d3js.org/d3.v7.min.js';

# Exact die() strings the module promises -- if these change, the API has changed.
Readonly my $ERR_NOT_OPTIONAL        => 'Data is not optional';
Readonly my $ERR_ARRAY_OF_ARRAY      => 'Data must be an array of arrays';
Readonly my $ERR_ARRAY_OF_HASH       => 'Data must be an array of hashes';
Readonly my $ERR_EACH_POINT_ARRAYREF => 'Each data point must be an array reference';
Readonly my $ERR_EACH_POINT_3_ELEMS  => 'Each data point must have at least 3 elements';
Readonly my $ERR_VALUE_NUMERIC       => 'Value must be numeric';
Readonly my $ERR_CELL_PADDING_RANGE  => 'cell_padding must be between 0 and 8';
Readonly my $ERR_EACH_POINT_2_ELEMS  => 'Each data point must have at least 2 elements';
Readonly my $ERR_ORIENTATION         => "orientation must be 'vertical' or 'horizontal'";
Readonly my $ERR_SORT_BARS           => "sort_bars must be 'value', 'label', or 'none'";

Readonly my @BAR_DATA => (
	['Alpha',   300],
	['Beta',    150],
	['Gamma',   450],
	['Delta',   200],
);

# ---------------------------------------------------------------------------
# new()
# ---------------------------------------------------------------------------

subtest 'new - defaults applied when no args given' => sub {
	# Mocking Params::Get and Object::Configure isolates the constructor from
	# external config files, so defaults are guaranteed to come from new() itself.
	mock('Params::Get::get_params'       => sub { {} });
	mock('Object::Configure::configure'  => sub { $_[1] });	# transparent pass-through

	my $chart = new_ok('HTML::D3');

	isa_ok($chart, 'HTML::D3', 'new() returns an HTML::D3 object');
	is($chart->{width},  $DEFAULT_WIDTH,  'default width applied');
	is($chart->{height}, $DEFAULT_HEIGHT, 'default height applied');
	is($chart->{title},  $DEFAULT_TITLE,  'default title applied');

	restore('Params::Get::get_params');
	restore('Object::Configure::configure');
};

subtest 'new - custom args stored verbatim (flat hash)' => sub {
	my $chart = HTML::D3->new(width => 1_024, height => 768, title => 'My Chart');

	is($chart->{width},  1_024,      'custom width stored');
	is($chart->{height}, 768,        'custom height stored');
	is($chart->{title},  'My Chart', 'custom title stored');
};

subtest 'new - custom args stored verbatim (hashref)' => sub {
	# Params::Get normalises both calling conventions; the hashref form must work.
	my $chart = HTML::D3->new({ width => 640, height => 480, title => 'Ref Chart' });

	is($chart->{width},  640,         'hashref width stored');
	is($chart->{height}, 480,         'hashref height stored');
	is($chart->{title},  'Ref Chart', 'hashref title stored');
};

subtest 'new - cloning an existing object merges new args' => sub {
	# Calling ->new() on a blessed object must return a NEW, independent object
	# that inherits the caller's fields but applies overrides.
	my $orig  = HTML::D3->new(width => 400, height => 300, title => 'Original');
	my $clone = $orig->new(title => 'Clone');

	isa_ok($clone, 'HTML::D3', 'clone is an HTML::D3 object');
	is($clone->{width},  400,     'clone inherits width from original');
	is($clone->{height}, 300,     'clone inherits height from original');
	is($clone->{title},  'Clone', 'clone uses the overridden title');
	isnt(refaddr($orig), refaddr($clone), 'clone is a distinct object, not the same ref');
};

subtest 'new - no circular references in returned object' => sub {
	my $chart = HTML::D3->new(width => 100, height => 100, title => 'Cycle Test');
	memory_cycle_ok($chart, 'blessed object has no circular references');
};

# ---------------------------------------------------------------------------
# Private helpers: _preamble and _head
# ---------------------------------------------------------------------------

subtest '_preamble - emits HTML5 doctype and opening html element' => sub {
	# _preamble is a static helper: it ignores $self and returns a fixed string.
	my $chart  = HTML::D3->new();
	my $output = $chart->_preamble();

	returns_ok($output, { type => 'string' }, '_preamble returns a string scalar');
	like($output, qr/<!DOCTYPE html>/i,    '_preamble emits DOCTYPE');
	like($output, qr/<html\s+lang="en">/i, '_preamble sets lang="en" on html element');
};

subtest '_head - emits head element with title, charset, viewport, and D3 CDN' => sub {
	# _head reads $self->{title} to populate the page <title> tag.
	my $chart  = HTML::D3->new(title => 'Head Title Test');
	my $output = $chart->_head();

	returns_ok($output, { type => 'string' }, '_head returns a string scalar');
	like($output, qr/<head>/i,          '_head emits opening head tag');
	like($output, qr{</head>}i,         '_head emits closing head tag');
	like($output, qr/Head Title Test/,  '_head inserts the object title');
	like($output, qr/\Q$CDN_URL\E/,     '_head loads D3 from the expected CDN URL');
	like($output, qr/charset="UTF-8"/i, '_head declares UTF-8 charset');
	like($output, qr/viewport/,         '_head includes viewport meta tag');

	diag('_head output: ' . $output) if $ENV{TEST_VERBOSE};
};

# ---------------------------------------------------------------------------
# render_bar_chart
# ---------------------------------------------------------------------------

subtest 'render_bar_chart - validation: dies with exact messages' => sub {
	my $chart = HTML::D3->new();

	# bar chart is the only method that distinguishes undef from wrong type.
	throws_ok(
		sub { $chart->render_bar_chart(undef) },
		qr/\Q$ERR_NOT_OPTIONAL\E/,
		'dies with exact message when data is undef',
	);
	throws_ok(
		sub { $chart->render_bar_chart('a string') },
		qr/\Q$ERR_ARRAY_OF_ARRAY\E/,
		'dies on scalar data',
	);
	throws_ok(
		sub { $chart->render_bar_chart({ key => 'val' }) },
		qr/\Q$ERR_ARRAY_OF_ARRAY\E/,
		'dies on hashref data',
	);
};

subtest 'render_bar_chart - output structure and content' => sub {
	my $chart = HTML::D3->new(width => 800, height => 600, title => 'Bar Test');
	my $html  = $chart->render_bar_chart(\@SIMPLE_DATA);

	returns_ok($html, { type => 'string' }, 'returns a string scalar');
	like($html, qr/<!DOCTYPE html>/i,  'output includes DOCTYPE');
	like($html, qr/<html/i,            'output contains html element');
	like($html, qr/<body/i,            'output contains body element');
	like($html, qr/<svg id="chart"/,   'SVG element present with correct id');
	like($html, qr/Bar Test<\/h1>/,    'title rendered inside h1');
	like($html, qr/January/,           'first data label present in JSON');
	like($html, qr/1000/,              'first data value present in JSON');
	like($html, qr/d3\.scaleBand/,     'uses d3.scaleBand for bar-chart x-axis');

	diag('render_bar_chart length: ' . length($html)) if $ENV{TEST_VERBOSE};
};

subtest 'render_bar_chart - delegates to _preamble and _head (not inlined)' => sub {
	# White-box: ensure the method calls the shared helpers rather than
	# duplicating DOCTYPE/head logic inline.
	my ($preamble_calls, $head_calls) = (0, 0);
	my $orig_preamble = HTML::D3->can('_preamble');
	my $orig_head     = HTML::D3->can('_head');

	mock('HTML::D3::_preamble', sub { $preamble_calls++; $orig_preamble->(@_) });
	mock('HTML::D3::_head',     sub { $head_calls++;     $orig_head->(@_) });

	HTML::D3->new()->render_bar_chart(\@SIMPLE_DATA);

	is($preamble_calls, 1, '_preamble called exactly once');
	is($head_calls,     1, '_head called exactly once');

	restore('HTML::D3::_preamble');
	restore('HTML::D3::_head');
};

# ---------------------------------------------------------------------------
# render_animated_bar_chart
# ---------------------------------------------------------------------------

subtest 'render_animated_bar_chart - validation: dies with exact messages' => sub {
	my $chart = HTML::D3->new();

	throws_ok(
		sub { $chart->render_animated_bar_chart(undef) },
		qr/\Q$ERR_NOT_OPTIONAL\E/,
		'dies with exact message when data is undef',
	);
	throws_ok(
		sub { $chart->render_animated_bar_chart('a string') },
		qr/\Q$ERR_ARRAY_OF_ARRAY\E/,
		'dies on scalar data',
	);
	throws_ok(
		sub { $chart->render_animated_bar_chart({ key => 'val' }) },
		qr/\Q$ERR_ARRAY_OF_ARRAY\E/,
		'dies on hashref data',
	);
};

subtest 'render_animated_bar_chart - output structure and animation features' => sub {
	my $chart = HTML::D3->new(width => 800, height => 600, title => 'Anim Bar Test');
	my $html  = $chart->render_animated_bar_chart(\@SIMPLE_DATA);

	returns_ok($html, { type => 'string' }, 'returns a string scalar');
	like($html, qr/<!DOCTYPE html>/i,  'output includes DOCTYPE');
	like($html, qr/<html/i,            'output contains html element');
	like($html, qr/<body/i,            'output contains body element');
	like($html, qr/<svg id="chart"/,   'SVG element present with correct id');
	like($html, qr/Anim Bar Test<\/h1>/, 'title rendered inside h1');
	like($html, qr/d3\.scaleBand/,     'uses d3.scaleBand for x-axis');
	like($html, qr/\.transition\(\)/, 'D3 transition() call present');
	like($html, qr/\.duration\(\d+\)/, 'D3 duration() call present');
	like($html, qr/\.delay\(/,         'per-bar stagger delay present');

	diag('render_animated_bar_chart length: ' . length($html)) if $ENV{TEST_VERBOSE};
};

subtest 'render_animated_bar_chart - delegates to _preamble and _head' => sub {
	my ($preamble_calls, $head_calls) = (0, 0);
	my $orig_preamble = HTML::D3->can('_preamble');
	my $orig_head     = HTML::D3->can('_head');

	mock('HTML::D3::_preamble', sub { $preamble_calls++; $orig_preamble->(@_) });
	mock('HTML::D3::_head',     sub { $head_calls++;     $orig_head->(@_) });

	HTML::D3->new()->render_animated_bar_chart(\@SIMPLE_DATA);

	is($preamble_calls, 1, '_preamble called exactly once');
	is($head_calls,     1, '_head called exactly once');

	restore('HTML::D3::_preamble');
	restore('HTML::D3::_head');
};

# ---------------------------------------------------------------------------
# render_line_chart
# ---------------------------------------------------------------------------

subtest 'render_line_chart - validation' => sub {
	my $chart = HTML::D3->new();
	throws_ok(
		sub { $chart->render_line_chart('not an array') },
		qr/\Q$ERR_ARRAY_OF_ARRAY\E/,
		'dies on non-array data',
	);
};

subtest 'render_line_chart - output structure and D3 idioms' => sub {
	my $chart = HTML::D3->new(title => 'Line Test');
	my $html  = $chart->render_line_chart(\@SIMPLE_DATA);

	returns_ok($html, { type => 'string' }, 'returns a string scalar');
	like($html, qr/<!DOCTYPE html>/i, 'output includes DOCTYPE');
	like($html, qr/<svg id="chart"/, 'SVG element present with correct id');
	like($html, qr/January/,         'data label present');
	like($html, qr/1000/,            'data value present');
	like($html, qr/d3\.scalePoint/,  'uses d3.scalePoint (not scaleBand) for x-axis');
	like($html, qr/d3\.line\(\)/,    'uses d3.line() to draw the path');
};

subtest 'render_line_chart - delegates to _preamble and _head' => sub {
	my ($preamble_calls, $head_calls) = (0, 0);
	my $orig_preamble = HTML::D3->can('_preamble');
	my $orig_head     = HTML::D3->can('_head');

	mock('HTML::D3::_preamble', sub { $preamble_calls++; $orig_preamble->(@_) });
	mock('HTML::D3::_head',     sub { $head_calls++;     $orig_head->(@_) });

	HTML::D3->new()->render_line_chart(\@SIMPLE_DATA);

	is($preamble_calls, 1, '_preamble called exactly once');
	is($head_calls,     1, '_head called exactly once');

	restore('HTML::D3::_preamble');
	restore('HTML::D3::_head');
};

# ---------------------------------------------------------------------------
# render_animated_line_chart
# ---------------------------------------------------------------------------

subtest 'render_animated_line_chart - validation' => sub {
	my $chart = HTML::D3->new();
	throws_ok(
		sub { $chart->render_animated_line_chart('bad') },
		qr/\Q$ERR_ARRAY_OF_ARRAY\E/,
		'dies on non-array data',
	);
	throws_ok(
		sub { $chart->render_animated_line_chart({ key => 'val' }) },
		qr/\Q$ERR_ARRAY_OF_ARRAY\E/,
		'dies on hashref data',
	);
};

subtest 'render_animated_line_chart - output structure and animation features' => sub {
	my $chart = HTML::D3->new(width => 800, height => 600, title => 'Anim Line Test');
	my $html  = $chart->render_animated_line_chart(\@SIMPLE_DATA);

	returns_ok($html, { type => 'string' }, 'returns a string scalar');
	like($html, qr/<!DOCTYPE html>/i,       'output includes DOCTYPE');
	like($html, qr/<svg id="chart"/,        'SVG element present with correct id');
	like($html, qr/Anim Line Test<\/h1>/,   'title rendered inside h1');
	like($html, qr/d3\.scalePoint/,         'uses d3.scalePoint for x-axis');
	like($html, qr/d3\.line\(\)/,           'd3.line() generator present');
	like($html, qr/stroke-dashoffset/,      'stroke-dashoffset animation present');
	like($html, qr/d3\.easeLinear/,         'd3.easeLinear easing present');
	# Circles must start transparent and transition to opaque.
	like($html, qr/\.attr\("opacity",\s*0\)/, 'circles start with opacity 0');

	diag('render_animated_line_chart length: ' . length($html)) if $ENV{TEST_VERBOSE};
};

subtest 'render_animated_line_chart - delegates to _preamble and _head' => sub {
	my ($preamble_calls, $head_calls) = (0, 0);
	my $orig_preamble = HTML::D3->can('_preamble');
	my $orig_head     = HTML::D3->can('_head');

	mock('HTML::D3::_preamble', sub { $preamble_calls++; $orig_preamble->(@_) });
	mock('HTML::D3::_head',     sub { $head_calls++;     $orig_head->(@_) });

	HTML::D3->new()->render_animated_line_chart(\@SIMPLE_DATA);

	is($preamble_calls, 1, '_preamble called exactly once');
	is($head_calls,     1, '_head called exactly once');

	restore('HTML::D3::_preamble');
	restore('HTML::D3::_head');
};

# ---------------------------------------------------------------------------
# render_pie_chart
# ---------------------------------------------------------------------------

subtest 'render_pie_chart - validation: dies with exact messages' => sub {
	my $chart = HTML::D3->new();

	throws_ok(
		sub { $chart->render_pie_chart(undef) },
		qr/\Q$ERR_NOT_OPTIONAL\E/,
		'dies with exact message when data is undef',
	);
	throws_ok(
		sub { $chart->render_pie_chart('a string') },
		qr/\Q$ERR_ARRAY_OF_ARRAY\E/,
		'dies on scalar data',
	);
	throws_ok(
		sub { $chart->render_pie_chart({ key => 'val' }) },
		qr/\Q$ERR_ARRAY_OF_ARRAY\E/,
		'dies on hashref data',
	);
};

subtest 'render_pie_chart - output structure and content' => sub {
	my $chart = HTML::D3->new(width => 800, height => 600, title => 'Pie Test');
	my $html  = $chart->render_pie_chart(\@SIMPLE_DATA);

	returns_ok($html, { type => 'string' }, 'returns a string scalar');
	like($html, qr/<!DOCTYPE html>/i,  'output includes DOCTYPE');
	like($html, qr/<html/i,            'output contains html element');
	like($html, qr/<svg id="chart"/,   'SVG element present with correct id');
	like($html, qr/Pie Test<\/h1>/,    'title rendered inside h1');
	like($html, qr/January/,           'first data label present in JSON');
	like($html, qr/d3\.pie\(\)/,       'd3.pie() generator present');
	like($html, qr/d3\.arc\(\)/,       'd3.arc() path generator present');
	like($html, qr/d3\.schemeCategory10/, 'd3.schemeCategory10 colour scheme used');
	like($html, qr/d3\.scaleOrdinal/, 'd3.scaleOrdinal maps labels to colours');

	diag('render_pie_chart length: ' . length($html)) if $ENV{TEST_VERBOSE};
};

subtest 'render_pie_chart - delegates to _preamble and _head' => sub {
	my ($preamble_calls, $head_calls) = (0, 0);
	my $orig_preamble = HTML::D3->can('_preamble');
	my $orig_head     = HTML::D3->can('_head');

	mock('HTML::D3::_preamble', sub { $preamble_calls++; $orig_preamble->(@_) });
	mock('HTML::D3::_head',     sub { $head_calls++;     $orig_head->(@_) });

	HTML::D3->new()->render_pie_chart(\@SIMPLE_DATA);

	is($preamble_calls, 1, '_preamble called exactly once');
	is($head_calls,     1, '_head called exactly once');

	restore('HTML::D3::_preamble');
	restore('HTML::D3::_head');
};

# ---------------------------------------------------------------------------
# render_animated_pie_chart
# ---------------------------------------------------------------------------

subtest 'render_animated_pie_chart - validation: dies with exact messages' => sub {
	my $chart = HTML::D3->new();

	throws_ok(
		sub { $chart->render_animated_pie_chart(undef) },
		qr/\Q$ERR_NOT_OPTIONAL\E/,
		'dies with exact message when data is undef',
	);
	throws_ok(
		sub { $chart->render_animated_pie_chart('a string') },
		qr/\Q$ERR_ARRAY_OF_ARRAY\E/,
		'dies on scalar data',
	);
};

subtest 'render_animated_pie_chart - output structure and animation features' => sub {
	my $chart = HTML::D3->new(width => 800, height => 600, title => 'Anim Pie Test');
	my $html  = $chart->render_animated_pie_chart(\@SIMPLE_DATA);

	returns_ok($html, { type => 'string' }, 'returns a string scalar');
	like($html, qr/<!DOCTYPE html>/i,    'output includes DOCTYPE');
	like($html, qr/<svg id="chart"/,     'SVG element present');
	like($html, qr/d3\.pie\(\)/,         'd3.pie() present');
	like($html, qr/d3\.schemeCategory10/,'d3.schemeCategory10 present');
	like($html, qr/attrTween/,           'attrTween animation present');
	like($html, qr/d3\.interpolate/,      'd3.interpolate used for tween');
	# Labels must start transparent and fade in after slices finish.
	like($html, qr/\.attr\("opacity",\s*0\)/, 'labels start with opacity 0');

	diag('render_animated_pie_chart length: ' . length($html)) if $ENV{TEST_VERBOSE};
};

subtest 'render_animated_pie_chart - delegates to _preamble and _head' => sub {
	my ($preamble_calls, $head_calls) = (0, 0);
	my $orig_preamble = HTML::D3->can('_preamble');
	my $orig_head     = HTML::D3->can('_head');

	mock('HTML::D3::_preamble', sub { $preamble_calls++; $orig_preamble->(@_) });
	mock('HTML::D3::_head',     sub { $head_calls++;     $orig_head->(@_) });

	HTML::D3->new()->render_animated_pie_chart(\@SIMPLE_DATA);

	is($preamble_calls, 1, '_preamble called exactly once');
	is($head_calls,     1, '_head called exactly once');

	restore('HTML::D3::_preamble');
	restore('HTML::D3::_head');
};

# ---------------------------------------------------------------------------
# render_pie_chart_snippet
# ---------------------------------------------------------------------------

subtest 'render_pie_chart_snippet - validation' => sub {
	my $chart = HTML::D3->new();
	throws_ok(
		sub { $chart->render_pie_chart_snippet('bad') },
		qr/\Q$ERR_ARRAY_OF_ARRAY\E/,
		'dies on non-array data',
	);
};

subtest 'render_pie_chart_snippet - return structure' => sub {
	my $chart    = HTML::D3->new();
	my $fragment = $chart->render_pie_chart_snippet(\@SIMPLE_DATA);

	returns_ok($fragment, { type => 'hashref' }, 'returns a hashref');
	is($fragment->{svg_id}, 'pie_chart', 'svg_id is "pie_chart"');
	ok(defined($fragment->{html}), 'html key is present');
	returns_ok($fragment->{html}, { type => 'string' }, 'html value is a string');
};

subtest 'render_pie_chart_snippet - fragment must not contain page-shell elements' => sub {
	my $html = HTML::D3->new()->render_pie_chart_snippet(\@SIMPLE_DATA)->{html};

	unlike($html, qr/<!DOCTYPE/i,                 'no DOCTYPE in fragment');
	unlike($html, qr/<html/i,                     'no <html> element in fragment');
	unlike($html, qr/<head/i,                     'no <head> element in fragment');
	unlike($html, qr/<body/i,                     'no <body> element in fragment');
	unlike($html, qr{https://d3js\.org/d3\.v7},   'no D3 CDN tag — caller loads D3');
	like($html,   qr/<svg id="pie_chart"/,         'SVG element has id="pie_chart"');
	like($html,   qr/d3\.pie\(\)/,                 'd3.pie() present in fragment');
};

subtest 'render_pie_chart_snippet - no circular references in returned hashref' => sub {
	my $fragment = HTML::D3->new()->render_pie_chart_snippet(\@SIMPLE_DATA);
	memory_cycle_ok($fragment, 'returned hashref has no circular references');
};

subtest 'render_pie_chart_snippet - default colour scheme is tableau10 not category10' => sub {
	# The snippet intentionally diverges from the full-page methods (which use
	# schemeCategory10) to provide a visually distinct default palette.
	my $html = HTML::D3->new()->render_pie_chart_snippet(\@SIMPLE_DATA)->{html};

	# The selected scheme appears as SCHEMES['<name>'] in the const color = ... line.
	like($html, qr/SCHEMES\['tableau10'\]/, 'tableau10 key used in scaleOrdinal call');
};

subtest 'render_pie_chart_snippet - animated => 1 enables attrTween fan animation' => sub {
	# 0.14 feature: slices fan in from arc-length 0 using attrTween +
	# d3.easeBackOut.overshoot, with a staggered 800 ms transition per slice.
	# Respects prefers-reduced-motion; guarded by initialDrawDone so that
	# subsequent redraws never re-animate.
	my $html = HTML::D3->new()->render_pie_chart_snippet(\@SIMPLE_DATA, { animated => 1 })->{html};

	like($html, qr/attrTween/,              'attrTween fan animation present');
	like($html, qr/initialDrawDone/,        'initialDrawDone guard prevents re-animation');
	like($html, qr/prefers-reduced-motion/, 'prefers-reduced-motion guard present');
};

subtest 'render_pie_chart_snippet - animated => 0 omits all animation code' => sub {
	# Passing animated => 0 must produce the same non-animated output as the default.
	my $html = HTML::D3->new()->render_pie_chart_snippet(\@SIMPLE_DATA, { animated => 0 })->{html};

	unlike($html, qr/attrTween/,       'no attrTween when animated => 0');
	unlike($html, qr/initialDrawDone/, 'no initialDrawDone guard when animated => 0');
};

subtest 'render_pie_chart_snippet - donut => 1 sets a non-zero inner radius' => sub {
	# A non-zero innerRadius on the arc generator converts the pie into a donut.
	my $html = HTML::D3->new()->render_pie_chart_snippet(\@SIMPLE_DATA, { donut => 1 })->{html};

	like($html, qr/innerRadius/, 'innerRadius set in arc generator for donut mode');
};

subtest 'render_pie_chart_snippet - sort_slices => value sorts descending by value' => sub {
	# When sort_slices is 'value', slices must appear in the JSON binding with the
	# highest value first so that larger slices are always rendered before smaller ones.
	my @unsorted = (['Low', 10], ['High', 90], ['Mid', 50]);
	my $html = HTML::D3->new()->render_pie_chart_snippet(
		\@unsorted, { sort_slices => 'value' }
	)->{html};

	my $high_pos = index($html, '"label":"High"');
	my $low_pos  = index($html, '"label":"Low"');
	ok($high_pos != -1,          '"High" slice present in data JSON');
	ok($low_pos  != -1,          '"Low" slice present in data JSON');
	ok($high_pos < $low_pos,     'highest-value slice appears before lowest in sorted JSON');
};

subtest 'render_pie_chart_snippet - max_slices collapses tail into Other slice' => sub {
	# max_slices => N keeps the top (N-1) slices by value and merges the rest into
	# a synthetic "Other" slice, so the chart never shows more than N wedges.
	my @many = (['A', 50], ['B', 30], ['C', 20], ['D', 10], ['E', 5]);
	my $html  = HTML::D3->new()->render_pie_chart_snippet(\@many, { max_slices => 3 })->{html};

	my @labels = ($html =~ /"label":"([^"]+)"/g);
	is(scalar @labels, 3,                 'exactly 3 slices in JSON after collapse');
	ok((grep { $_ eq 'Other' } @labels), '"Other" synthetic slice present');
};

subtest 'render_pie_chart_snippet - zero-value slice silently omitted' => sub {
	# A zero-value slice contributes nothing to the pie; including it would leave a
	# zero-angle wedge that is invisible but still iterates D3 arc path generation.
	my $html = HTML::D3->new()->render_pie_chart_snippet(
		[['Zero', 0], ['Pos', 50]]
	)->{html};

	unlike($html, qr/"label":"Zero"/, 'zero-value slice omitted from JSON data binding');
};

subtest 'render_pie_chart_snippet - negative value converted to absolute value' => sub {
	# Negative values are silently converted to their absolute counterpart; the
	# sign carries no meaning in a proportion chart.
	my $html = HTML::D3->new()->render_pie_chart_snippet(
		[['Neg', -20], ['Pos', 80]]
	)->{html};

	like($html, qr/"value":20/, 'negative value stored as its absolute value in JSON');
};

subtest 'render_pie_chart_snippet - legend => 0 suppresses legend panel' => sub {
	# By default the snippet renders an HTML legend panel with colour swatches beside
	# the SVG.  Passing legend => 0 must omit the legend div and the D3 JS that
	# populates it.  The CSS class definitions (.bi-pie-legend etc.) remain in the
	# <style> block regardless -- only the functional elements are suppressed.
	my $html_legend    = HTML::D3->new()->render_pie_chart_snippet(\@SIMPLE_DATA)->{html};
	my $html_no_legend = HTML::D3->new()->render_pie_chart_snippet(\@SIMPLE_DATA, { legend => 0 })->{html};

	like($html_legend, qr/selectAll\(".bi-pie-legend-entry"\)/,
		'default output includes legend-entry JS (.selectAll call)');
	unlike($html_no_legend, qr/selectAll\(".bi-pie-legend-entry"\)/,
		'legend => 0 suppresses D3 JS that populates legend entries');
	unlike($html_no_legend, qr/id="pie_chart_legend"/,
		'legend => 0 suppresses the legend container div');
};

subtest 'render_pie_chart_snippet - color_scheme => category10 selects schemeCategory10' => sub {
	# The SCHEMES JS object maps scheme name strings to D3 colour arrays; the Perl
	# colour_scheme opt is interpolated as the lookup key in the scaleOrdinal call.
	my $html = HTML::D3->new()->render_pie_chart_snippet(
		\@SIMPLE_DATA, { color_scheme => 'category10' }
	)->{html};

	like($html, qr/SCHEMES\['category10'\]/, 'category10 key used in scaleOrdinal call');
};

subtest 'render_pie_chart_snippet - extra tooltip data from optional third element' => sub {
	# An optional HashRef third element per data point is serialised as d.extra
	# and appended as additional rows in the mouseover tooltip.
	my @with_extra = (['Apples', 40, { Origin => 'NZ' }], ['Oranges', 30]);
	my $html = HTML::D3->new()->render_pie_chart_snippet(\@with_extra)->{html};

	like($html, qr/"extra":\{/, '"extra" object present in D3 data JSON');
	like($html, qr/Origin/,     'extra key "Origin" serialised into JSON');
};

subtest 'render_pie_chart_snippet - no circular references with opts' => sub {
	my $fragment = HTML::D3->new()->render_pie_chart_snippet(
		\@SIMPLE_DATA, { animated => 1, donut => 1, legend => 1 }
	);
	memory_cycle_ok($fragment, 'snippet hashref with combined opts has no circular references');
};

subtest 'render_pie_chart - separator default is /' => sub {
	# The separator is interpolated into a JS template literal.  The literal
	# string "${d.data.label} / ${d.data.value}" must appear in the JS source.
	my $html = HTML::D3->new(width => 800, height => 600)->render_pie_chart(\@SIMPLE_DATA);
	like($html, qr/d\.data\.label} \/ \$\{d\.data\.value}/, 'default separator / in legend JS');
};

subtest 'render_pie_chart - custom separator appears in legend' => sub {
	my $html = HTML::D3->new(width => 800, height => 600)
		->render_pie_chart(\@SIMPLE_DATA, { separator => ':' });
	like($html,   qr/d\.data\.label} : \$\{d\.data\.value}/, 'custom separator : in legend JS');
	unlike($html, qr/d\.data\.label} \/ /,                   'default / absent when overridden');
};

subtest 'render_animated_pie_chart - separator default is /' => sub {
	my $html = HTML::D3->new(width => 800, height => 600)->render_animated_pie_chart(\@SIMPLE_DATA);
	like($html, qr/d\.data\.label} \/ \$\{d\.data\.value}/, 'default separator / in animated legend JS');
};

subtest 'render_animated_pie_chart - custom separator appears in legend' => sub {
	my $html = HTML::D3->new(width => 800, height => 600)
		->render_animated_pie_chart(\@SIMPLE_DATA, { separator => ':' });
	like($html,   qr/d\.data\.label} : \$\{d\.data\.value}/, 'custom separator : in animated legend JS');
	unlike($html, qr/d\.data\.label} \/ /,                   'default / absent when overridden');
};

subtest 'render_pie_chart_snippet - separator default is /' => sub {
	# The separator is interpolated into a JS string concatenation.
	# The literal ' / ' must appear between d.data.label and fmt() in the source.
	my $html = HTML::D3->new(width => 800, height => 600)
		->render_pie_chart_snippet(\@SIMPLE_DATA)->{html};
	like($html, qr/d\.data\.label \+ ' \/ '/, 'default separator / in snippet legend JS');
};

subtest 'render_pie_chart_snippet - custom separator appears in legend entry' => sub {
	my $html = HTML::D3->new(width => 800, height => 600)
		->render_pie_chart_snippet(\@SIMPLE_DATA, { separator => '|' })->{html};
	like($html,   qr/d\.data\.label \+ ' \| '/, 'custom separator | in snippet legend JS');
	unlike($html, qr/d\.data\.label \+ ' \/ '/, 'default / absent when overridden');
};

# ---------------------------------------------------------------------------
# render_heatmap_snippet
# ---------------------------------------------------------------------------

subtest 'render_heatmap_snippet - validation: all documented error conditions' => sub {
	# Each of the six errors has a distinct trigger; test every branch so that
	# a future refactor cannot silently drop one without breaking this test.
	my $chart = HTML::D3->new();

	throws_ok(
		sub { $chart->render_heatmap_snippet('not an arrayref') },
		qr/\Q$ERR_ARRAY_OF_ARRAY\E/,
		'dies when data argument is not an arrayref',
	);
	throws_ok(
		sub { $chart->render_heatmap_snippet(['scalar_element']) },
		qr/\Q$ERR_EACH_POINT_ARRAYREF\E/,
		'dies when a triple element is a scalar, not an arrayref',
	);
	throws_ok(
		sub { $chart->render_heatmap_snippet([['Jan', 'North']]) },
		qr/\Q$ERR_EACH_POINT_3_ELEMS\E/,
		'dies when a triple has only two elements',
	);
	throws_ok(
		sub { $chart->render_heatmap_snippet([['Jan']]) },
		qr/\Q$ERR_EACH_POINT_3_ELEMS\E/,
		'dies when a triple has only one element',
	);
	throws_ok(
		sub { $chart->render_heatmap_snippet([['Jan', 'North', 'not_a_number']]) },
		qr/\Q$ERR_VALUE_NUMERIC\E/,
		'dies when defined value is not numeric',
	);
	throws_ok(
		sub { $chart->render_heatmap_snippet(\@HEATMAP_DATA, { color_scheme => 'Viridis' }) },
		qr/Unknown color_scheme: Viridis/,
		'dies on unsupported color_scheme with the scheme name embedded in message',
	);
	throws_ok(
		sub { $chart->render_heatmap_snippet(\@HEATMAP_DATA, { cell_padding => 9 }) },
		qr/\Q$ERR_CELL_PADDING_RANGE\E/,
		'dies when cell_padding exceeds the maximum of 8',
	);
	throws_ok(
		sub { $chart->render_heatmap_snippet(\@HEATMAP_DATA, { cell_padding => -1 }) },
		qr/\Q$ERR_CELL_PADDING_RANGE\E/,
		'dies when cell_padding is negative (below the minimum of 0)',
	);
};

subtest 'render_heatmap_snippet - return structure' => sub {
	my $chart    = HTML::D3->new(width => 800, height => 600);
	my $fragment = $chart->render_heatmap_snippet(\@HEATMAP_DATA);

	returns_ok($fragment, { type => 'hashref' }, 'returns a hashref');
	is($fragment->{svg_id}, 'heatmap', 'svg_id is always "heatmap"');
	ok(defined($fragment->{html}),          'html key is present');
	returns_ok($fragment->{html}, { type => 'string' }, 'html value is a scalar string');
	ok(length($fragment->{html}) > 0,       'html value is non-empty');

	diag('heatmap_snippet html length: ' . length($fragment->{html})) if $ENV{TEST_VERBOSE};
};

subtest 'render_heatmap_snippet - fragment must not contain page-shell elements' => sub {
	# The fragment is embedded in an existing layout; a full page wrapper would
	# break the host document's HTML structure.
	my $html = HTML::D3->new()->render_heatmap_snippet(\@HEATMAP_DATA)->{html};

	unlike($html, qr/<!DOCTYPE/i,               'no DOCTYPE in fragment');
	unlike($html, qr/<html/i,                   'no <html> element in fragment');
	unlike($html, qr/<head/i,                   'no <head> element in fragment');
	unlike($html, qr/<body/i,                   'no <body> element in fragment');
	unlike($html, qr{https://d3js\.org/d3\.v7}, 'no D3 CDN tag -- caller loads D3');
	like($html,   qr/<svg id="heatmap"/,        'SVG element has id="heatmap"');
};

subtest 'render_heatmap_snippet - uses d3.scaleSequential with default YlOrRd scheme' => sub {
	# scaleSequential maps the continuous [0, max] domain to a gradient colour;
	# scaleBand maps the categorical x/y label sets to pixel positions.
	my $html = HTML::D3->new(width => 800, height => 600)
	                   ->render_heatmap_snippet(\@HEATMAP_DATA)->{html};

	like($html, qr/scaleSequential/,   'd3.scaleSequential present');
	like($html, qr/interpolateYlOrRd/, 'default interpolator is YlOrRd');
	like($html, qr/scaleBand/,         'd3.scaleBand present for categorical axes');
};

subtest 'render_heatmap_snippet - each supported color_scheme emits its d3.interpolate counterpart' => sub {
	# The mapping is one-to-one: scheme name -> d3.interpolate<Name>.
	# If the map in the module is wrong for any entry this test catches it.
	my %scheme_to_interp = (
		YlOrRd  => 'interpolateYlOrRd',
		Blues   => 'interpolateBlues',
		Greens  => 'interpolateGreens',
		Purples => 'interpolatePurples',
		RdPu    => 'interpolateRdPu',
		YlGnBu  => 'interpolateYlGnBu',
	);
	my $chart = HTML::D3->new(width => 800, height => 600);
	for my $scheme (sort keys %scheme_to_interp) {
		my $interp = $scheme_to_interp{$scheme};
		my $html   = $chart->render_heatmap_snippet(\@HEATMAP_DATA, { color_scheme => $scheme })->{html};
		like($html, qr/\Q$interp\E/, "color_scheme '$scheme' emits d3.$interp");
	}
};

subtest 'render_heatmap_snippet - legend on by default; legend => 0 omits legend JS block' => sub {
	# The legend JS block is generated Perl-side: when legend => 0, the string
	# "linearGradient" is entirely absent from the HTML source, not merely
	# behind a JS runtime check.  This is intentional and testable.
	my $html_default = HTML::D3->new(width => 800, height => 600)
	                           ->render_heatmap_snippet(\@HEATMAP_DATA)->{html};
	my $html_no_leg  = HTML::D3->new(width => 800, height => 600)
	                           ->render_heatmap_snippet(\@HEATMAP_DATA, { legend => 0 })->{html};

	like($html_default,  qr/linearGradient/,  'legend default: linearGradient block present');
	unlike($html_no_leg, qr/linearGradient/,  'legend => 0: linearGradient entirely absent from source');
};

subtest 'render_heatmap_snippet - animated => 1 emits row-stagger fade with prefers-reduced-motion guard' => sub {
	# The animation fades cell groups in from opacity 0, staggered by row index
	# (yMap.get(d.y) * 50 ms).  It must check prefers-reduced-motion and skip
	# the transition when the user has requested reduced motion.
	my $html = HTML::D3->new(width => 800, height => 600)
	                   ->render_heatmap_snippet(\@HEATMAP_DATA, { animated => 1 })->{html};

	like($html, qr/prefers-reduced-motion/,    'prefers-reduced-motion guard present');
	like($html, qr/yMap\.get\(d\.y\)/,         'row-index stagger uses yMap row position');
	like($html, qr/\.attr\("opacity",\s*0\)/,  'cells start at opacity 0 before transition');
	like($html, qr/noAnim/,                    'noAnim flag computed from media query');

	diag('animated heatmap html length: ' . length($html)) if $ENV{TEST_VERBOSE};
};

subtest 'render_heatmap_snippet - animated => 0 omits animation code entirely' => sub {
	# The animation block is Perl-side conditional, so its code is never present
	# when animated => 0 (or when opts are omitted).
	my $html_plain = HTML::D3->new()->render_heatmap_snippet(\@HEATMAP_DATA)->{html};
	my $html_off   = HTML::D3->new()->render_heatmap_snippet(\@HEATMAP_DATA, { animated => 0 })->{html};

	unlike($html_plain, qr/prefers-reduced-motion/, 'no animation code when opts omitted');
	unlike($html_off,   qr/prefers-reduced-motion/, 'no animation code when animated => 0');
	unlike($html_off,   qr/noAnim/,                 'noAnim variable absent when animated => 0');
};

subtest 'render_heatmap_snippet - undef values silently skipped; defined siblings retained' => sub {
	# undef at position [2] drops the entire triple from @triples before JSON
	# encoding.  The sibling triple in the same call must still appear.
	my @mixed = (['Mar', 'East', undef], ['Mar', 'West', 77]);
	my $html  = HTML::D3->new()->render_heatmap_snippet(\@mixed)->{html};

	like($html,   qr/"v":77/,         'non-undef value appears in JSON data');
	unlike($html, qr/"y":"East"/,     'undef triple silently skipped: East not in JSON');
};

subtest 'render_heatmap_snippet - duplicate (x,y) pair: Perl passes both; JS deduplicates via gridMap' => sub {
	# Perl does not deduplicate at encode time -- it serialises all non-undef
	# triples into JSON so the caller can see both entries arrive in the browser.
	# The JS gridMap.set overwrites the first entry with the second (last write
	# wins), which is the documented API contract.
	my @dupes = (['Jan', 'North', 10], ['Jan', 'North', 99]);
	my $html  = HTML::D3->new()->render_heatmap_snippet(\@dupes)->{html};

	like($html, qr/"v":10/,          'first duplicate value present in JSON (Perl passes all)');
	like($html, qr/"v":99/,          'second duplicate value present in JSON');
	like($html, qr/gridMap\.set/,    'gridMap.set present -- JS last-write-wins deduplication mechanism');
};

subtest 'render_heatmap_snippet - all-zero values use degenerate-domain fallback [0, 1]' => sub {
	# When all values are zero, d3.scaleSequential([0, 0]) is degenerate and
	# returns a constant colour.  The JS guards with "maxV === 0 ? [0, 1] : [0, maxV]"
	# so the scale always has a non-trivial domain.
	my @zeros = (['A', 'X', 0], ['B', 'Y', 0]);
	my $html;
	lives_ok(
		sub { $html = HTML::D3->new()->render_heatmap_snippet(\@zeros)->{html} },
		'all-zero data renders without error',
	);
	like($html, qr/\[0,\s*1\]/,  'fallback domain literal [0, 1] present in JS scale call');
};

subtest 'render_heatmap_snippet - val_label: default "Value", custom label embedded in JS' => sub {
	# val_label is embedded as the JS variable valLabelStr and shown in the
	# tooltip.  Testing this confirms the Perl escaping path is exercised.
	my $html_def = HTML::D3->new()->render_heatmap_snippet(\@HEATMAP_DATA)->{html};
	like($html_def, qr/valLabelStr = "Value"/, 'default val_label is "Value"');

	my $html_cus = HTML::D3->new()->render_heatmap_snippet(
		\@HEATMAP_DATA, { val_label => 'Revenue' }
	)->{html};
	like($html_cus, qr/valLabelStr = "Revenue"/, 'custom val_label embedded in JS');
};

subtest 'render_heatmap_snippet - x_label and y_label embedded as JS string vars' => sub {
	# Labels are Perl-escaped and embedded as xLabelStr / yLabelStr.  The JS
	# then guards rendering with "if (xLabelStr)" so empty strings suppress axes.
	my $html = HTML::D3->new(width => 900, height => 500)->render_heatmap_snippet(
		\@HEATMAP_DATA, { x_label => 'Month', y_label => 'Region' }
	)->{html};

	like($html, qr/xLabelStr = "Month"/,  'x_label "Month" embedded as xLabelStr');
	like($html, qr/yLabelStr = "Region"/, 'y_label "Region" embedded as yLabelStr');
};

subtest 'render_heatmap_snippet - no circular references in returned hashref' => sub {
	my $fragment = HTML::D3->new()->render_heatmap_snippet(\@HEATMAP_DATA);
	memory_cycle_ok($fragment, 'basic heatmap hashref has no circular references');
};

subtest 'render_heatmap_snippet - no circular references with combined opts' => sub {
	# Verify the more complex code paths (animated + legend + custom labels) also
	# stay cycle-free; a hashref holding a reference back to itself would fail here.
	my $fragment = HTML::D3->new(width => 900, height => 500)->render_heatmap_snippet(
		\@HEATMAP_DATA,
		{
			animated     => 1,
			legend       => 1,
			color_scheme => 'Blues',
			show_values  => 1,
			x_label      => 'Month',
			y_label      => 'Region',
		},
	);
	memory_cycle_ok($fragment, 'heatmap hashref with combined opts has no circular references');
};

# ---------------------------------------------------------------------------
# render_line_chart_with_tooltips
# ---------------------------------------------------------------------------

subtest 'render_line_chart_with_tooltips - validation' => sub {
	my $chart = HTML::D3->new();
	throws_ok(
		sub { $chart->render_line_chart_with_tooltips('bad') },
		qr/\Q$ERR_ARRAY_OF_ARRAY\E/,
		'dies on non-array data',
	);
};

subtest 'render_line_chart_with_tooltips - output and html-tidy safety' => sub {
	# This method inlines its own <head> (known inconsistency) rather than
	# calling _head().  We verify the tooltip-specific features are present and
	# that the html-tidy </letter fix is applied correctly.
	my $chart = HTML::D3->new(title => 'Tooltip Test');
	my $html  = $chart->render_line_chart_with_tooltips(\@SIMPLE_DATA);

	returns_ok($html, { type => 'string' }, 'returns a string scalar');
	like($html, qr/<!DOCTYPE html>/i,                    'contains DOCTYPE');
	like($html, qr/<svg id="chart"/,                     'SVG element present');
	like($html, qr/class="tooltip"/,                     'tooltip CSS class defined');
	like($html, qr/<div class="tooltip" id="tooltip">/,  'tooltip div present');
	like($html, qr/mouseover/,                           'mouseover handler present');
	like($html, qr/transition:\s*opacity/,               'tooltip fade-in transition present');

	# html-tidy rejects </letter inside <script>; the module must use <\/b>.
	# qr{} compiles a regex object; m{} without =~ would match $_ instead of $html.
	unlike($html, qr{</b>},   'raw </b> is absent from script content');
	like($html,   qr{<\\/b>}, 'escaped <\/b> is present in JS tooltip strings');
};

# ---------------------------------------------------------------------------
# render_line_chart_snippet
# ---------------------------------------------------------------------------

subtest 'render_line_chart_snippet - validation' => sub {
	my $chart = HTML::D3->new();
	throws_ok(
		sub { $chart->render_line_chart_snippet('bad') },
		qr/\Q$ERR_ARRAY_OF_ARRAY\E/,
		'dies on non-array data',
	);
};

subtest 'render_line_chart_snippet - return structure' => sub {
	my $chart    = HTML::D3->new();
	my $fragment = $chart->render_line_chart_snippet(\@SIMPLE_DATA);

	returns_ok($fragment, { type => 'hashref' }, 'returns a hashref (not a plain string)');
	ok(exists $fragment->{svg_id}, 'hashref has svg_id key');
	ok(exists $fragment->{html},   'hashref has html key');
	is($fragment->{svg_id}, 'chart', 'svg_id value is "chart"');
	returns_ok($fragment->{html}, { type => 'string' }, 'html value is a string scalar');
};

subtest 'render_line_chart_snippet - fragment must not contain page-shell elements' => sub {
	# The fragment is for embedding in an existing layout; a full page wrapper
	# would break the host document's HTML structure.
	my $html = HTML::D3->new()->render_line_chart_snippet(\@SIMPLE_DATA)->{html};

	unlike($html, qr/<!DOCTYPE/i, 'fragment has no DOCTYPE');
	unlike($html, qr/<html/i,     'fragment has no <html> wrapper');
	unlike($html, qr/<body/i,     'fragment has no <body> wrapper');
	unlike($html, qr{<\/head>}i,  'fragment has no </head>');
};

subtest 'render_line_chart_snippet - content and html-tidy safety' => sub {
	my $html = HTML::D3->new(width => 800, height => 600)
	                   ->render_line_chart_snippet(\@SIMPLE_DATA)
	                   ->{html};

	like($html, qr/<svg id="chart"/,      'SVG element present with correct id');
	like($html, qr/January/,              'data label present in JSON binding');
	like($html, qr/1000/,                 'data value present in JSON binding');
	like($html, qr/class="tooltip"/,      'tooltip style block present');
	like($html, qr/<div class="tooltip"/, 'tooltip div present');
	like($html, qr/mouseover/,            'mouseover handler present');
	unlike($html, qr{</b>},              'raw </b> absent from script content');
	like($html,   qr{<\\/b>},            'escaped <\/b> present in JS tooltip strings');
};

subtest 'render_line_chart_snippet - optional third element as extra tooltip data' => sub {
	# A hashref third element must be serialised as d.extra in the D3 binding
	# and iterated in the mouseover handler.  A non-hashref third element must
	# be silently ignored (not promoted to extra).
	my @with_extra    = (['January', 1_000, \%EXTRA_ROW], ['February', 1_200]);
	my @without_extra = (['January', 1_000, 'not a ref'], ['February', 1_200]);

	my $html_extra = HTML::D3->new()->render_line_chart_snippet(\@with_extra)->{html};

	like($html_extra, qr/"extra":\{/,                  '"extra" object present in D3 data');
	like($html_extra, qr/Region/,                      'extra key "Region" serialised');
	like($html_extra, qr/Object\.entries\(d\.extra\)/, 'd.extra iterated in mouseover');

	my $html_plain = HTML::D3->new()->render_line_chart_snippet(\@without_extra)->{html};
	unlike($html_plain, qr/"extra"/, 'non-hashref third element produces no extra key');

	# Exactly one data point should carry extra when only one pair has it.
	my @extra_hits = ($html_extra =~ m{"extra":\{}g);
	is(scalar @extra_hits, 1, 'exactly one data point carries the extra key');
};

subtest 'render_line_chart_snippet - no circular references in returned hashref' => sub {
	my $fragment = HTML::D3->new()->render_line_chart_snippet(\@SIMPLE_DATA);
	memory_cycle_ok($fragment, 'snippet hashref has no circular references');
};

# ---------------------------------------------------------------------------
# render_zoomable_line_chart_snippet
# ---------------------------------------------------------------------------

subtest 'render_zoomable_line_chart_snippet - validation' => sub {
	my $chart = HTML::D3->new();
	throws_ok(
		sub { $chart->render_zoomable_line_chart_snippet('bad') },
		qr/\Q$ERR_ARRAY_OF_ARRAY\E/,
		'dies on non-array data',
	);
};

subtest 'render_zoomable_line_chart_snippet - return structure' => sub {
	my $fragment = HTML::D3->new()->render_zoomable_line_chart_snippet(\@SIMPLE_DATA);

	returns_ok($fragment, { type => 'hashref' }, 'returns a hashref');
	is($fragment->{svg_id}, 'chart', 'svg_id value is "chart"');
	returns_ok($fragment->{html}, { type => 'string' }, 'html value is a string scalar');
};

subtest 'render_zoomable_line_chart_snippet - brush-to-zoom JavaScript features' => sub {
	my $html = HTML::D3->new(width => 800, height => 600)
	                   ->render_zoomable_line_chart_snippet(\@SIMPLE_DATA)
	                   ->{html};

	# Page-shell elements must be absent -- it is a fragment.
	unlike($html, qr/<!DOCTYPE/i, 'fragment has no DOCTYPE');
	unlike($html, qr/<html/i,     'fragment has no <html> wrapper');

	# Core zoom features.
	like($html, qr/d3\.brushX\(\)/,                    'd3.brushX used for brush-to-zoom');
	like($html, qr/\.brush\s*\./,                      'brush CSS class defined in stylesheet');
	like($html, qr/Reset zoom/,                        'Reset zoom button present');
	like($html, qr/const allData\s*=/,                 'original dataset stored in allData');
	like($html, qr/let\s+currentData\s*=/,             'current view tracked in currentData');
	like($html, qr/currentData = allData\.slice\(\)/,  'reset restores full allData');
	like($html, qr/zoomed\.length < 2/,                'single-point zoom is guarded');

	# The brush must sit below circles in z-order; verify the append order.
	my $brush_pos   = index($html, 'brushGroup');
	my $circles_pos = index($html, 'circle.pt');
	ok($brush_pos < $circles_pos, 'brush appended before circles (correct z-order)');

	# html-tidy safety.
	unlike($html, qr{</b>},   'raw </b> absent from script content');
	like($html,   qr{<\\/b>}, 'escaped <\/b> present in JS tooltip strings');

	diag('zoomable snippet length: ' . length($html)) if $ENV{TEST_VERBOSE};
};

subtest 'render_zoomable_line_chart_snippet - extra tooltip data' => sub {
	my @with_extra = (['Jan', 100, { City => 'London' }], ['Feb', 200]);
	my $html = HTML::D3->new()->render_zoomable_line_chart_snippet(\@with_extra)->{html};

	like($html, qr/"extra":\{/,                  '"extra" object present in D3 data');
	like($html, qr/Object\.entries\(d\.extra\)/, 'd.extra iterated in mouseover handler');
};

subtest 'render_zoomable_line_chart_snippet - no circular references' => sub {
	my $fragment = HTML::D3->new()->render_zoomable_line_chart_snippet(\@SIMPLE_DATA);
	memory_cycle_ok($fragment, 'zoomable snippet hashref has no circular references');
};

subtest 'render_zoomable_line_chart_snippet - animated => 1 enables stroke-dashoffset draw animation' => sub {
	# 0.13 feature: the line traces itself left-to-right on the initial page load.
	# Subsequent zoom/reset redraws must NOT re-animate (guarded by initialDrawDone).
	# The animation must be skipped entirely when prefers-reduced-motion is set.
	my $html = HTML::D3->new(width => 800, height => 600)
	                   ->render_zoomable_line_chart_snippet(\@SIMPLE_DATA, { animated => 1 })
	                   ->{html};

	like($html, qr/stroke-dashoffset/,      'stroke-dashoffset animation present');
	like($html, qr/d3\.easeLinear/,         'd3.easeLinear easing used for line draw');
	like($html, qr/initialDrawDone/,        'initialDrawDone guard prevents re-animation on zoom/reset');
	like($html, qr/prefers-reduced-motion/, 'prefers-reduced-motion media-query guard present');

	diag('animated zoomable HTML length: ' . length($html)) if $ENV{TEST_VERBOSE};
};

subtest 'render_zoomable_line_chart_snippet - animated => 0 omits animation code' => sub {
	# animated => 0 must be identical in effect to omitting the opts argument entirely
	# (backward-compatible: no new keys injected into the non-animated output).
	my $html_no_opts  = HTML::D3->new()->render_zoomable_line_chart_snippet(\@SIMPLE_DATA)->{html};
	my $html_anim_off = HTML::D3->new()->render_zoomable_line_chart_snippet(\@SIMPLE_DATA, { animated => 0 })->{html};

	unlike($html_no_opts,  qr/stroke-dashoffset/, 'no stroke-dashoffset when opts omitted');
	unlike($html_anim_off, qr/stroke-dashoffset/, 'no stroke-dashoffset when animated => 0');
	unlike($html_anim_off, qr/initialDrawDone/,   'no initialDrawDone guard when animated => 0');
};

subtest 'render_zoomable_line_chart_snippet - animated => 1 no circular references' => sub {
	my $fragment = HTML::D3->new()->render_zoomable_line_chart_snippet(\@SIMPLE_DATA, { animated => 1 });
	memory_cycle_ok($fragment, 'animated zoomable hashref has no circular references');
};

# ---------------------------------------------------------------------------
# Multi-series methods
# All four share the same data shape and the same "array of hashes" validation.
# ---------------------------------------------------------------------------

subtest 'render_multi_series_line_chart_with_tooltips' => sub {
	my $chart = HTML::D3->new(title => 'Multi Tooltip');

	throws_ok(
		sub { $chart->render_multi_series_line_chart_with_tooltips('bad') },
		qr/\Q$ERR_ARRAY_OF_HASH\E/,
		'dies on non-array data with correct message',
	);

	my $html = $chart->render_multi_series_line_chart_with_tooltips(\@MULTI_DATA);

	returns_ok($html, { type => 'string' }, 'returns a string scalar');
	like($html, qr/<!DOCTYPE html>/i,                    'contains DOCTYPE');
	like($html, qr/<svg id="chart"/,                     'SVG element present');
	like($html, qr/<div class="tooltip" id="tooltip">/,  'tooltip div present');
	like($html, qr/Series A/,                            'first series name present');
	like($html, qr/1000/,                                'data value present');
	unlike($html, qr{</b>},                              'raw </b> absent');
};

subtest 'render_multi_series_line_chart_with_animated_tooltips' => sub {
	my $chart = HTML::D3->new(title => 'Animated');

	throws_ok(
		sub { $chart->render_multi_series_line_chart_with_animated_tooltips('bad') },
		qr/\Q$ERR_ARRAY_OF_HASH\E/,
		'dies on non-array data',
	);

	my $html = $chart->render_multi_series_line_chart_with_animated_tooltips(\@MULTI_DATA);

	returns_ok($html, { type => 'string' }, 'returns a string scalar');
	like($html, qr/<!DOCTYPE html>/i,     'contains DOCTYPE');
	like($html, qr/translateY/,           'CSS translateY animation present');
	like($html, qr/<div class="tooltip"/, 'tooltip div present');
	unlike($html, qr{</b>},              'raw </b> absent');
};

subtest 'render_multi_series_line_chart_with_legends' => sub {
	my $chart = HTML::D3->new(title => 'Legends');

	throws_ok(
		sub { $chart->render_multi_series_line_chart_with_legends('bad') },
		qr/\Q$ERR_ARRAY_OF_HASH\E/,
		'dies on non-array data',
	);

	my $html = $chart->render_multi_series_line_chart_with_legends(\@MULTI_DATA);

	returns_ok($html, { type => 'string' }, 'returns a string scalar');
	like($html, qr/<!DOCTYPE html>/i,     'contains DOCTYPE');
	like($html, qr/\.legend\s*\{/,       'legend CSS class defined in stylesheet');
	like($html, qr/Series A/,            'first series name appears in legend area');
	unlike($html, qr{</b>},              'raw </b> absent');
};

subtest 'render_multi_series_line_chart_with_interactive_legends' => sub {
	my $chart = HTML::D3->new(title => 'Interactive Legends');

	throws_ok(
		sub { $chart->render_multi_series_line_chart_with_interactive_legends('bad') },
		qr/\Q$ERR_ARRAY_OF_HASH\E/,
		'dies on non-array data',
	);

	my $html = $chart->render_multi_series_line_chart_with_interactive_legends(\@MULTI_DATA);

	returns_ok($html, { type => 'string' }, 'returns a string scalar');
	like($html, qr/<!DOCTYPE html>/i,  'contains DOCTYPE');
	like($html, qr/isVisible/,    'visibility-toggle variable present');
	# The legend click handler must toggle opacity based on current visibility.
	like($html, qr/isVisible\s*\?\s*0\s*:\s*1/, 'opacity toggled based on isVisible');
	like($html, qr/\.legend\s*\{/, 'legend CSS class defined in stylesheet');
	unlike($html, qr{</b>}, 'raw </b> absent');
};

# ---------------------------------------------------------------------------
# render_bar_chart_snippet
# ---------------------------------------------------------------------------

subtest 'render_bar_chart_snippet - validation: all documented error conditions' => sub {
	my $chart = HTML::D3->new(width => 600, height => 400);

	# Non-arrayref data
	throws_ok(
		sub { $chart->render_bar_chart_snippet('not an array') },
		qr/\Q$ERR_ARRAY_OF_ARRAY\E/,
		'non-arrayref data dies with correct message',
	);

	# Element that is not an arrayref
	throws_ok(
		sub { $chart->render_bar_chart_snippet(['scalar_element']) },
		qr/\Q$ERR_EACH_POINT_ARRAYREF\E/,
		'non-arrayref element dies with correct message',
	);

	# Element with only one item
	throws_ok(
		sub { $chart->render_bar_chart_snippet([['only_one']]) },
		qr/\Q$ERR_EACH_POINT_2_ELEMS\E/,
		'single-element data point dies with correct message',
	);

	# Non-numeric value
	throws_ok(
		sub { $chart->render_bar_chart_snippet([['A', 'not_a_number']]) },
		qr/\Q$ERR_VALUE_NUMERIC\E/,
		'non-numeric value dies with correct message',
	);

	# Invalid orientation
	throws_ok(
		sub { $chart->render_bar_chart_snippet(\@BAR_DATA, { orientation => 'diagonal' }) },
		qr/\Q$ERR_ORIENTATION\E/,
		'invalid orientation dies with correct message',
	);

	# Invalid sort_bars
	throws_ok(
		sub { $chart->render_bar_chart_snippet(\@BAR_DATA, { sort_bars => 'random' }) },
		qr/\Q$ERR_SORT_BARS\E/,
		'invalid sort_bars dies with correct message',
	);
};

subtest 'render_bar_chart_snippet - return structure' => sub {
	my $chart  = HTML::D3->new(width => 600, height => 400);
	my $result = $chart->render_bar_chart_snippet(\@BAR_DATA);

	returns_ok($result, { type => 'hashref' }, 'returns a hashref');
	is($result->{svg_id}, 'bar_chart',  'svg_id is "bar_chart"');
	ok(defined $result->{html} && length($result->{html}) > 0, 'html field is a non-empty string');
};

subtest 'render_bar_chart_snippet - fragment must not contain page-shell elements' => sub {
	my $html = HTML::D3->new()->render_bar_chart_snippet(\@BAR_DATA)->{html};

	unlike($html, qr/<!DOCTYPE/i,        'no DOCTYPE in snippet');
	unlike($html, qr/<html/i,            'no <html> element');
	unlike($html, qr/<head/i,            'no <head> element');
	unlike($html, qr/<body/i,            'no <body> element');
	unlike($html, qr{https://d3js\.org}, 'no D3 CDN tag — caller loads D3');
};

subtest 'render_bar_chart_snippet - default vertical orientation uses x-axis scaleBand' => sub {
	# Vertical: x is the category (scaleBand), y is the value (scaleLinear)
	my $html = HTML::D3->new()->render_bar_chart_snippet(\@BAR_DATA)->{html};

	like($html, qr/xScale\s*=\s*d3\.scaleBand/,   'xScale is d3.scaleBand (vertical)');
	like($html, qr/yScale\s*=\s*d3\.scaleLinear/, 'yScale is d3.scaleLinear (vertical)');
	like($html, qr/bc-x-axis/,                    'x-axis class bc-x-axis present');
	like($html, qr/bc-y-axis/,                    'y-axis class bc-y-axis present');
};

subtest 'render_bar_chart_snippet - horizontal orientation uses y-axis scaleBand' => sub {
	# Horizontal flips axes: y is the category (scaleBand), x is the value (scaleLinear)
	my $html = HTML::D3->new()->render_bar_chart_snippet(\@BAR_DATA, { orientation => 'horizontal' })->{html};

	like($html, qr/yScale\s*=\s*d3\.scaleBand/,   'yScale is d3.scaleBand (horizontal)');
	like($html, qr/xScale\s*=\s*d3\.scaleLinear/, 'xScale is d3.scaleLinear (horizontal)');
};

subtest 'render_bar_chart_snippet - default color is steelblue' => sub {
	my $html = HTML::D3->new()->render_bar_chart_snippet(\@BAR_DATA)->{html};

	like($html, qr/steelblue/, 'default fill color steelblue is present');
	unlike($html, qr/schemeTableau10/, 'schemeTableau10 absent for solid-color chart');
};

subtest 'render_bar_chart_snippet - color => categorical emits Tableau-10 palette' => sub {
	my $html = HTML::D3->new()->render_bar_chart_snippet(\@BAR_DATA, { color => 'categorical' })->{html};

	like($html, qr/schemeTableau10/,   'schemeTableau10 present for categorical coloring');
	like($html, qr/d3\.scaleOrdinal/, 'd3.scaleOrdinal present for categorical coloring');
};

subtest 'render_bar_chart_snippet - sort_bars => value sorts JSON data descending by value' => sub {
	# Perl sorts @bars before encoding JSON, so the first data item in the
	# serialised array must have the highest value (Gamma = 450 in @BAR_DATA).
	my $html = HTML::D3->new()->render_bar_chart_snippet(\@BAR_DATA, { sort_bars => 'value' })->{html};

	# Gamma (450) must appear before Alpha (300) in the serialised data array.
	my ($gamma_pos) = $html =~ /("label":"Gamma")/g;
	ok(defined $gamma_pos, 'Gamma present after value sort');

	# JSON order reflects the Perl-side sort; highest value label comes first in the string.
	like($html, qr/"label":"Gamma".*"label":"Alpha"/s, 'Gamma (highest) precedes Alpha in sorted JSON');
};

subtest 'render_bar_chart_snippet - sort_bars => label sorts JSON alphabetically' => sub {
	my $html = HTML::D3->new()->render_bar_chart_snippet(\@BAR_DATA, { sort_bars => 'label' })->{html};

	# Alpha < Beta < Delta < Gamma alphabetically
	like($html, qr/"label":"Alpha".*"label":"Beta"/s,  'Alpha precedes Beta in label-sorted JSON');
	like($html, qr/"label":"Beta".*"label":"Delta"/s,  'Beta precedes Delta in label-sorted JSON');
	like($html, qr/"label":"Delta".*"label":"Gamma"/s, 'Delta precedes Gamma in label-sorted JSON');
};

subtest 'render_bar_chart_snippet - max_bars collapses tail into Other slice' => sub {
	# With max_bars => 2 and sort_bars => value, Alpha (300) and Beta (150) are
	# the tail after the top 2 (Gamma=450, Delta=200); they collapse to "Other".
	my $html = HTML::D3->new()->render_bar_chart_snippet(
		\@BAR_DATA,
		{ max_bars => 2, sort_bars => 'value' },
	)->{html};

	like($html, qr/"label":"Other"/, '"Other" label appears in JSON when max_bars exceeded');
	like($html, qr/"label":"Gamma"/, 'top bar Gamma still present');
	unlike($html, qr/"label":"Beta"/, 'Beta collapsed into Other');
};

subtest 'render_bar_chart_snippet - show_values => 1 emits bc-val-text block' => sub {
	my $html = HTML::D3->new()->render_bar_chart_snippet(\@BAR_DATA, { show_values => 1 })->{html};

	like($html, qr/bc-val-text/, 'bc-val-text class present when show_values => 1');
	like($html, qr/toLocaleString/, 'toLocaleString call present in value label');
};

subtest 'render_bar_chart_snippet - show_values => 0 (default) omits bc-val-text D3 block' => sub {
	# The CSS class .bc-val-text is always defined in <style>; what must be absent
	# when show_values is off is the D3 selectAll call that actually creates the
	# text elements — that is the Perl-side conditional block.
	my $html_default = HTML::D3->new()->render_bar_chart_snippet(\@BAR_DATA)->{html};
	my $html_off     = HTML::D3->new()->render_bar_chart_snippet(\@BAR_DATA, { show_values => 0 })->{html};

	unlike($html_default, qr/selectAll\(["']\.bc-val-text["']\)/, 'D3 bc-val-text selectAll absent by default');
	unlike($html_off,     qr/selectAll\(["']\.bc-val-text["']\)/, 'D3 bc-val-text selectAll absent when show_values => 0');
};

subtest 'render_bar_chart_snippet - animated => 1 emits transition with prefers-reduced-motion guard' => sub {
	my $html = HTML::D3->new()->render_bar_chart_snippet(\@BAR_DATA, { animated => 1 })->{html};

	like($html, qr/prefers-reduced-motion/, 'prefers-reduced-motion media-query guard present');
	like($html, qr/\.transition\(\)/,       'd3 .transition() present for bar animation');
	like($html, qr/\.duration\(800\)/,      '800 ms duration present');
	like($html, qr/noAnim/,                 'noAnim variable gate present');
};

subtest 'render_bar_chart_snippet - animated => 0 (default) omits animation code' => sub {
	my $html_default = HTML::D3->new()->render_bar_chart_snippet(\@BAR_DATA)->{html};
	my $html_off     = HTML::D3->new()->render_bar_chart_snippet(\@BAR_DATA, { animated => 0 })->{html};

	unlike($html_default, qr/prefers-reduced-motion/, 'no prefers-reduced-motion by default');
	unlike($html_off,     qr/prefers-reduced-motion/, 'no prefers-reduced-motion when animated => 0');
};

subtest 'render_bar_chart_snippet - undef value silently skipped; defined sibling retained' => sub {
	my @with_undef = (['Present', 99], ['Missing', undef], ['Also', 42]);
	my $html;
	lives_ok { $html = HTML::D3->new()->render_bar_chart_snippet(\@with_undef)->{html} }
		'renders without error when one value is undef';

	like($html,   qr/"label":"Present"/, 'defined entry Present is in JSON');
	like($html,   qr/"label":"Also"/,    'defined entry Also is in JSON');
	unlike($html, qr/"label":"Missing"/, 'undef entry Missing is absent from JSON');
};

subtest 'render_bar_chart_snippet - negative value silently absolutised' => sub {
	my @neg = (['Loss', -250]);
	my $html = HTML::D3->new()->render_bar_chart_snippet(\@neg)->{html};

	# The encoded value must be 250 (positive), not -250
	like($html,   qr/"value":250/,  'negative value encoded as its absolute value (250)');
	unlike($html, qr/"value":-250/, 'negative sign absent from encoded value');
};

subtest 'render_bar_chart_snippet - extra hashref supplies additional tooltip data' => sub {
	my @with_extra = (['Widget', 500, { Region => 'EMEA', SKU => 'W-001' }]);
	my $html = HTML::D3->new()->render_bar_chart_snippet(\@with_extra)->{html};

	like($html, qr/"extra":/,  '"extra" key serialised in JSON data');
	like($html, qr/d\.extra/,  'd.extra accessed in mouseover handler');
	like($html, qr/Object\.entries/, 'Object.entries loop iterates extra fields');
};

subtest 'render_bar_chart_snippet - rotate labels when more than 8 vertical bars' => sub {
	# rotate(-45) is emitted only for vertical orientation with > 8 bars
	my @many = map { ["Item$_", $_ * 10] } 1..9;
	my $html = HTML::D3->new()->render_bar_chart_snippet(\@many)->{html};

	like($html, qr/rotate\(-45\)/, 'x-axis labels rotated -45° when > 8 vertical bars');

	# Fewer than 9 bars must NOT rotate
	my $html_few = HTML::D3->new()->render_bar_chart_snippet(\@BAR_DATA)->{html};
	unlike($html_few, qr/rotate\(-45\)/, 'labels not rotated when 4 bars (≤ 8)');
};

subtest 'render_bar_chart_snippet - x_label appears in output when provided' => sub {
	my $html = HTML::D3->new()->render_bar_chart_snippet(\@BAR_DATA, { x_label => 'Category Axis' })->{html};

	like($html, qr/Category Axis/, 'x_label text present in generated HTML');

	# Default (empty x_label) must produce no label text node
	my $html_no = HTML::D3->new()->render_bar_chart_snippet(\@BAR_DATA)->{html};
	unlike($html_no, qr/Category Axis/, 'no stray label when x_label not set');
};

subtest 'render_bar_chart_snippet - value_label embedded in JS as valLabel' => sub {
	my $html_default = HTML::D3->new()->render_bar_chart_snippet(\@BAR_DATA)->{html};
	like($html_default, qr/var valLabel\s*=\s*"Value"/, 'default value_label is "Value"');

	my $html_custom = HTML::D3->new()->render_bar_chart_snippet(\@BAR_DATA, { value_label => 'Amount' })->{html};
	like($html_custom, qr/var valLabel\s*=\s*"Amount"/, 'custom value_label "Amount" embedded correctly');
};

subtest 'render_bar_chart_snippet - no circular references in returned hashref' => sub {
	my $result = HTML::D3->new()->render_bar_chart_snippet(\@BAR_DATA);
	memory_cycle_ok($result, 'no circular references in basic result hashref');
};

subtest 'render_bar_chart_snippet - no circular references with combined opts' => sub {
	my $result = HTML::D3->new()->render_bar_chart_snippet(
		\@BAR_DATA,
		{
			orientation  => 'horizontal',
			sort_bars    => 'value',
			max_bars     => 3,
			color        => 'categorical',
			show_values  => 1,
			animated     => 1,
			value_label  => 'Qty',
			x_label      => 'Units',
		},
	);
	memory_cycle_ok($result, 'no circular references with all opts combined');
};

# ---------------------------------------------------------------------------
# render_pie_chart_snippet -- XSS (esc function)
# ---------------------------------------------------------------------------

subtest 'render_pie_chart_snippet - esc() function present in output' => sub {
	my $html = HTML::D3->new()->render_pie_chart_snippet(
		[['Alpha', 300], ['Beta', 150]],
	)->{html};
	like($html, qr/function esc\(/, 'esc() helper present in pie snippet output');
};

# ---------------------------------------------------------------------------
# id opt -- all five snippet methods honour the id override
# ---------------------------------------------------------------------------

subtest 'id opt - render_pie_chart_snippet custom id' => sub {
	my $res = HTML::D3->new()->render_pie_chart_snippet(
		[['A', 1], ['B', 2]], { id => 'my_pie' },
	);
	is($res->{svg_id}, 'my_pie', 'svg_id set to custom value');
	like($res->{html}, qr/id="my_pie"/, 'custom id present in SVG element');
};

subtest 'id opt - render_heatmap_snippet custom id' => sub {
	my $res = HTML::D3->new()->render_heatmap_snippet(\@HEATMAP_DATA, { id => 'my_heat' });
	is($res->{svg_id}, 'my_heat', 'svg_id set to custom value');
	like($res->{html}, qr/id="my_heat"/, 'custom id present in SVG element');
};

subtest 'id opt - render_bar_chart_snippet custom id' => sub {
	my $res = HTML::D3->new()->render_bar_chart_snippet(\@BAR_DATA, { id => 'my_bar' });
	is($res->{svg_id}, 'my_bar', 'svg_id set to custom value');
	like($res->{html}, qr/id="my_bar"/, 'custom id present in SVG element');
};

subtest 'id opt - render_line_chart_snippet custom id' => sub {
	my $res = HTML::D3->new()->render_line_chart_snippet(\@SIMPLE_DATA, { id => 'my_line' });
	is($res->{svg_id}, 'my_line', 'svg_id set to custom value');
	like($res->{html}, qr/id="my_line"/, 'custom id present in SVG element');
};

subtest 'id opt - render_zoomable_line_chart_snippet custom id' => sub {
	my $res = HTML::D3->new()->render_zoomable_line_chart_snippet(\@SIMPLE_DATA, { id => 'my_zoom' });
	is($res->{svg_id}, 'my_zoom', 'svg_id set to custom value');
	like($res->{html}, qr/id="my_zoom"/, 'custom id present in SVG element');
};

# ---------------------------------------------------------------------------
# responsive opt
# ---------------------------------------------------------------------------

subtest 'responsive opt - snippet per-call override' => sub {
	my $chart    = HTML::D3->new();
	my $def_html = $chart->render_bar_chart_snippet(\@BAR_DATA)->{html};
	unlike($def_html, qr/viewBox/, 'no viewBox by default in bar snippet');

	my $resp_html = $chart->render_bar_chart_snippet(\@BAR_DATA, { responsive => 1 })->{html};
	like($resp_html, qr/viewBox/, 'viewBox present when responsive => 1');
};

subtest 'responsive opt - per-call on heatmap snippet' => sub {
	my $html = HTML::D3->new()->render_heatmap_snippet(\@HEATMAP_DATA, { responsive => 1 })->{html};
	like($html, qr/viewBox/, 'viewBox present in responsive heatmap snippet');
};

subtest 'responsive opt - constructor sets full-page default' => sub {
	my $chart = HTML::D3->new(responsive => 1);
	my $html  = $chart->render_bar_chart(\@SIMPLE_DATA);
	like($html, qr/viewBox/, 'viewBox present in full-page render when constructor responsive');
};

subtest 'responsive opt - constructor applies to snippet unless overridden' => sub {
	my $chart = HTML::D3->new(responsive => 1);
	my $html  = $chart->render_bar_chart_snippet(\@BAR_DATA)->{html};
	like($html, qr/viewBox/, 'constructor responsive => 1 propagates to snippet');

	# Per-call responsive => 0 overrides constructor setting
	my $html_off = $chart->render_bar_chart_snippet(\@BAR_DATA, { responsive => 0 })->{html};
	unlike($html_off, qr/viewBox/, 'per-call responsive => 0 overrides constructor');
};

# ---------------------------------------------------------------------------
# render_scatter_chart_snippet
# ---------------------------------------------------------------------------

subtest 'render_scatter_chart_snippet - validation: documented error conditions' => sub {
	my $chart = HTML::D3->new();

	throws_ok(
		sub { $chart->render_scatter_chart_snippet('not an array') },
		qr/Data must be an array of arrays/,
		'non-arrayref data dies',
	);

	throws_ok(
		sub { $chart->render_scatter_chart_snippet(['scalar']) },
		qr/Each data point must be an array reference/,
		'non-arrayref element dies',
	);

	throws_ok(
		sub { $chart->render_scatter_chart_snippet([[99]]) },
		qr/Each data point must have at least 2 elements/,
		'single-element point dies',
	);

	throws_ok(
		sub { $chart->render_scatter_chart_snippet([['not_num', 5]]) },
		qr/X value must be numeric/,
		'non-numeric X dies',
	);

	throws_ok(
		sub { $chart->render_scatter_chart_snippet([[5, 'not_num']]) },
		qr/Y value must be numeric/,
		'non-numeric Y dies',
	);
};

subtest 'render_scatter_chart_snippet - return structure' => sub {
	my $chart  = HTML::D3->new(width => 600, height => 400);
	Readonly my @SC_DATA => ([10, 20], [30, 40], [50, 15]);
	my $result = $chart->render_scatter_chart_snippet(\@SC_DATA);

	returns_ok($result, { type => 'hashref' }, 'returns a hashref');
	is($result->{svg_id}, 'scatter_chart', 'svg_id is "scatter_chart"');
	ok(defined $result->{html} && length($result->{html}) > 0, 'html is non-empty');
};

subtest 'render_scatter_chart_snippet - fragment has no page-shell elements' => sub {
	Readonly my @SC_DATA => ([10, 20], [30, 40]);
	my $html = HTML::D3->new()->render_scatter_chart_snippet(\@SC_DATA)->{html};

	unlike($html, qr/<!DOCTYPE/i,        'no DOCTYPE');
	unlike($html, qr/<html/i,            'no html wrapper');
	unlike($html, qr/<head/i,            'no head element');
	unlike($html, qr/<body/i,            'no body element');
	unlike($html, qr{https://d3js\.org}, 'no D3 CDN tag');
};

subtest 'render_scatter_chart_snippet - key JS patterns' => sub {
	Readonly my @SC_DATA => ([10, 20], [30, 40], [50, 60]);
	my $html = HTML::D3->new()->render_scatter_chart_snippet(\@SC_DATA)->{html};

	like($html, qr/d3\.scaleLinear/, 'd3.scaleLinear present');
	like($html, qr/sc-circle/,       'sc-circle class present');
	like($html, qr/function esc\(/, 'esc() XSS helper present');
	like($html, qr/mouseover/,       'mouseover handler present');
};

subtest 'render_scatter_chart_snippet - animated => 1 code paths' => sub {
	Readonly my @SC_DATA => ([1, 2], [3, 4]);
	my $html = HTML::D3->new()->render_scatter_chart_snippet(\@SC_DATA, { animated => 1 })->{html};
	like($html, qr/prefers-reduced-motion/, 'prefers-reduced-motion guard present');
	like($html, qr/opacity.*0/,             'circles start at opacity 0');
};

subtest 'render_scatter_chart_snippet - x_label and y_label' => sub {
	Readonly my @SC_DATA => ([1, 2], [3, 4]);
	my $html = HTML::D3->new()->render_scatter_chart_snippet(\@SC_DATA, {
		x_label => 'Time (s)', y_label => 'Velocity',
	})->{html};
	like($html, qr/Time \(s\)/, 'x_label present');
	like($html, qr/Velocity/,   'y_label present');
};

subtest 'render_scatter_chart_snippet - extra hashref in tooltip' => sub {
	my $html = HTML::D3->new()->render_scatter_chart_snippet(
		[[10, 20, { label => 'Alpha' }]],
	)->{html};
	like($html, qr/d\.extra/, 'd.extra rendering code present');
};

subtest 'render_scatter_chart_snippet - id opt and responsive opt' => sub {
	Readonly my @SC_DATA => ([1, 2], [3, 4]);

	my $id_res  = HTML::D3->new()->render_scatter_chart_snippet(\@SC_DATA, { id => 'sc2' });
	is($id_res->{svg_id}, 'sc2', 'custom id in svg_id');
	like($id_res->{html}, qr/id="sc2"/, 'custom id in SVG element');

	my $resp_html = HTML::D3->new()->render_scatter_chart_snippet(\@SC_DATA, { responsive => 1 })->{html};
	like($resp_html, qr/viewBox/, 'viewBox present when responsive');
};

subtest 'render_scatter_chart_snippet - no circular references' => sub {
	Readonly my @SC_DATA => ([1, 2], [3, 4], [5, 6]);
	my $result = HTML::D3->new()->render_scatter_chart_snippet(\@SC_DATA);
	memory_cycle_ok($result, 'no circular refs in scatter snippet result');
};

# ---------------------------------------------------------------------------
# render_table_snippet
# ---------------------------------------------------------------------------

Readonly my @TABLE_HEADERS => ('Name', 'Value', 'Category');
Readonly my @TABLE_ROWS    => (['Alpha', 300, 'A'], ['Beta', 150, 'B']);

subtest 'render_table_snippet - validation: documented error conditions' => sub {
	my $chart = HTML::D3->new();

	throws_ok(
		sub { $chart->render_table_snippet('not an array') },
		qr/Data must be an array of arrays/,
		'non-arrayref data dies',
	);

	throws_ok(
		sub { $chart->render_table_snippet([]) },
		qr/Data must have at least one row/,
		'empty data dies',
	);

	throws_ok(
		sub { $chart->render_table_snippet(['not_a_row']) },
		qr/Each row must be an array reference/,
		'non-arrayref header row dies',
	);

	throws_ok(
		sub { $chart->render_table_snippet([['H1', 'H2'], 'bad_row']) },
		qr/Each row must be an array reference/,
		'non-arrayref data row dies',
	);
};

subtest 'render_table_snippet - return structure' => sub {
	my $data   = [[@TABLE_HEADERS], @TABLE_ROWS];
	my $result = HTML::D3->new()->render_table_snippet($data);

	returns_ok($result, { type => 'hashref' }, 'returns a hashref');
	is($result->{table_id}, 'data_table', 'table_id is "data_table"');
	ok(!exists $result->{svg_id}, 'no svg_id key');
	ok(defined $result->{html} && length($result->{html}) > 0, 'html is non-empty');
};

subtest 'render_table_snippet - fragment has no page-shell elements' => sub {
	my $html = HTML::D3->new()->render_table_snippet([[@TABLE_HEADERS], @TABLE_ROWS])->{html};

	unlike($html, qr/<!DOCTYPE/i, 'no DOCTYPE');
	unlike($html, qr/<html/i,     'no html wrapper');
	unlike($html, qr/<head/i,     'no head element');
	unlike($html, qr/<body/i,     'no body element');
};

subtest 'render_table_snippet - sortable default and override' => sub {
	my $data = [[@TABLE_HEADERS], @TABLE_ROWS];
	my $html_on  = HTML::D3->new()->render_table_snippet($data)->{html};
	like($html_on, qr/dt-sortable/, 'dt-sortable class present by default');
	like($html_on, qr/d3\.select/,  'd3.select present when sortable');

	my $html_off = HTML::D3->new()->render_table_snippet($data, { sortable => 0 })->{html};
	unlike($html_off, qr/dt-sortable/, 'dt-sortable class absent when sortable => 0');
};

subtest 'render_table_snippet - caption opt' => sub {
	my $html = HTML::D3->new()->render_table_snippet(
		[[@TABLE_HEADERS], @TABLE_ROWS], { caption => 'Q1 Report' },
	)->{html};
	like($html, qr/<caption>Q1 Report<\/caption>/, 'caption element present');
};

subtest 'render_table_snippet - id opt changes table_id and element id' => sub {
	my $result = HTML::D3->new()->render_table_snippet(
		[[@TABLE_HEADERS], @TABLE_ROWS], { id => 'custom_tbl' },
	);
	is($result->{table_id}, 'custom_tbl', 'table_id set to custom value');
	like($result->{html}, qr/id="custom_tbl"/, 'custom id in table element');
};

subtest 'render_table_snippet - XSS escaping in headers and cells' => sub {
	my $html = HTML::D3->new()->render_table_snippet([
		['Col<b>Header</b>', 'Val'],
		['<em>cell</em>', '&amp;data'],
	])->{html};
	like($html, qr/Col&lt;b&gt;Header&lt;\/b&gt;/, 'HTML tags in header escaped');
	like($html, qr/&lt;em&gt;cell&lt;\/em&gt;/,    'HTML tags in cell escaped');
	unlike($html, qr/<th[^>]*>Col<b>/,              'raw HTML tags absent from th');
};

subtest 'render_table_snippet - no circular references' => sub {
	my $result = HTML::D3->new()->render_table_snippet([[@TABLE_HEADERS], @TABLE_ROWS]);
	memory_cycle_ok($result, 'no circular refs in table snippet result');
};

# ---------------------------------------------------------------------------

done_testing();

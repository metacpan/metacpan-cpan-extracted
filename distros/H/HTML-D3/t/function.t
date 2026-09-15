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

Readonly my $DEFAULT_WIDTH  => 800;
Readonly my $DEFAULT_HEIGHT => 600;
Readonly my $DEFAULT_TITLE  => 'Chart';
Readonly my $CDN_URL        => 'https://d3js.org/d3.v7.min.js';

# Exact die() strings the module promises -- if these change, the API has changed.
Readonly my $ERR_NOT_OPTIONAL   => 'Data is not optional';
Readonly my $ERR_ARRAY_OF_ARRAY => 'Data must be an array of arrays';
Readonly my $ERR_ARRAY_OF_HASH  => 'Data must be an array of hashes';

# ---------------------------------------------------------------------------
# new()
# ---------------------------------------------------------------------------

subtest 'new - defaults applied when no args given' => sub {
	# Mocking Params::Get and Object::Configure isolates the constructor from
	# external config files, so defaults are guaranteed to come from new() itself.
	mock('Params::Get::get_params'       => sub { {} });
	mock('Object::Configure::configure'  => sub { $_[1] });	# transparent pass-through

	my $chart = HTML::D3->new();

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
	is($fragment->{svg_id}, 'chart', 'svg_id is "chart"');
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
	like($html,   qr/<svg id="chart"/,             'SVG element present');
	like($html,   qr/d3\.pie\(\)/,                 'd3.pie() present in fragment');
};

subtest 'render_pie_chart_snippet - no circular references in returned hashref' => sub {
	my $fragment = HTML::D3->new()->render_pie_chart_snippet(\@SIMPLE_DATA);
	memory_cycle_ok($fragment, 'returned hashref has no circular references');
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
	like($html, qr/isVisible/,         'visibility-toggle variable present');
	# The legend click handler must toggle opacity based on current visibility.
	like($html, qr/isVisible\s*\?\s*0\s*:\s*1/, 'opacity toggled based on isVisible');
	like($html, qr/\.legend\s*\{/,              'legend CSS class defined in stylesheet');
	unlike($html, qr{</b>},                     'raw </b> absent');
};

# ---------------------------------------------------------------------------

done_testing();

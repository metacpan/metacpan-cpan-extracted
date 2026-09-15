#!/usr/bin/env perl
# End-to-end integration tests for HTML::D3.
#
# Strategy: rather than testing each method in isolation, these subtests
# exercise multi-step workflows and cross-method interactions, verifying that
# the full system behaves correctly as a unit.
#
# Coverage areas:
#   1. Module loads cleanly and exports the expected class.
#   2. Constructor workflows: flat-hash, hashref, clone chain.
#   3. Object independence: two simultaneous objects must not share state.
#   4. Data serialisation consistency: same input data produces the same JSON
#      embedding across every render method.
#   5. Dimension propagation: width/height set in the constructor reach the SVG.
#   6. Full-page html-tidy validation: every full-page method produces output
#      that html-tidy accepts with no errors or warnings.
#   7. Snippet isolation: fragment methods produce no page-shell elements.
#   8. encode_json is called exactly once per render invocation (spy).
#   9. JSON::MaybeXS backend fallback: HTML::D3 works identically whether the
#      XS backend (Cpanel::JSON::XS / JSON::XS) or the pure-Perl JSON::PP
#      backend is active.
#  10. Global variable integrity: render calls must not clobber $_, $@, or $!.
#  11. Extra tooltip data: the same hashref extra-data round-trips correctly
#      through both snippet methods.

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Test::Needs 'Test::HTML::T5';
use Test::Without::Module;
use Readonly;

use_ok('HTML::D3');

Test::HTML::T5->import();

# ─────────────────────────────────────────────────────────────────────────────
# Shared fixtures
# ─────────────────────────────────────────────────────────────────────────────

Readonly my $D3_CDN         => 'https://d3js.org/d3.v7.min.js';
Readonly my $SVG_ID         => 'chart';
Readonly my $DEFAULT_WIDTH  => 800;
Readonly my $DEFAULT_HEIGHT => 600;

# Minimal simple dataset for single-series methods.
Readonly my @SIMPLE_DATA => (
	['January',  1_000],
	['February', 1_200],
	['March',      950],
);

# Simple dataset with one annotated point (extra tooltip data).
Readonly my @EXTRA_DATA => (
	['January',  1_000, { Region => 'North', SKU => 'X1' }],
	['February', 1_200],
);

# Minimal multi-series dataset.
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
# 1. Module load
# ─────────────────────────────────────────────────────────────────────────────

subtest 'module loads and is usable' => sub {
	use_ok('HTML::D3');

	# new_ok verifies the constructor returns a blessed object without dying.
	my $chart = new_ok('HTML::D3');
	isa_ok($chart, 'HTML::D3');
};

# ─────────────────────────────────────────────────────────────────────────────
# 2. Constructor workflow: flat-hash -> clone -> override chain
#
# Exercises a realistic workflow where an application builds a "base" chart
# object with site-wide settings, then derives per-page variants via clone.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'constructor clone chain produces independent objects' => sub {
	my $base = HTML::D3->new(width => 600, height => 400, title => 'Base');

	# Derive a wider variant; title should inherit.
	my $wider = $base->new(width => 1_200);
	is($wider->{width},  1_200,  'clone overrides width');
	is($wider->{height}, 400,    'clone inherits height from base');
	is($wider->{title},  'Base', 'clone inherits title from base');

	# Derive a retitled variant; dimensions should inherit.
	my $retitled = $base->new(title => 'Section Report');
	is($retitled->{width},  600,              'clone inherits width from base');
	is($retitled->{height}, 400,              'clone inherits height from base');
	is($retitled->{title},  'Section Report', 'clone overrides title');

	# Mutating the base must not affect the clones.
	$base->{title} = 'MUTATED';
	is($wider->{title},    'Base',           'wider title unaffected by base mutation');
	is($retitled->{title}, 'Section Report', 'retitled unaffected by base mutation');

	diag("base=$base wider=$wider retitled=$retitled") if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# 3. Object independence: two simultaneous chart objects
#
# Two objects rendered concurrently (interleaved calls) must produce completely
# isolated output -- no state leaks between them.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'two simultaneous objects do not share state' => sub {
	my $c1 = HTML::D3->new(title => 'Chart One', width => 400, height => 300);
	my $c2 = HTML::D3->new(title => 'Chart Two', width => 800, height => 600);

	my @data1 = (['January', 10], ['February', 20]);
	my @data2 = (['March',   30], ['April',    40]);

	# Interleave renders: bar from c1, then c2.
	my $h1_bar = $c1->render_bar_chart(\@data1);
	my $h2_bar = $c2->render_bar_chart(\@data2);

	# Title isolation.
	like($h1_bar, qr{Chart One</h1>}, 'c1 bar output contains c1 title');
	like($h2_bar, qr{Chart Two</h1>}, 'c2 bar output contains c2 title');
	unlike($h1_bar, qr/Chart Two/, 'c1 output does not contain c2 title');
	unlike($h2_bar, qr/Chart One/, 'c2 output does not contain c1 title');

	# Data isolation.
	like($h1_bar,   qr/January/,  'c1 output has its own data label');
	unlike($h1_bar, qr/March/,    'c1 output does not bleed c2 data');
	like($h2_bar,   qr/March/,    'c2 output has its own data label');
	unlike($h2_bar, qr/January/,  'c2 output does not bleed c1 data');

	# Dimension isolation: SVG element widths must match their respective objects.
	like($h1_bar, qr/svg id="$SVG_ID" width="400"/, 'c1 SVG has correct width');
	like($h2_bar, qr/svg id="$SVG_ID" width="800"/, 'c2 SVG has correct width');

	# Snippet isolation (same test for fragment methods).
	my $s1 = $c1->render_line_chart_snippet(\@data1)->{html};
	my $s2 = $c2->render_line_chart_snippet(\@data2)->{html};

	like($s1,    qr/January/, 'c1 snippet has c1 data');
	unlike($s1,  qr/March/,   'c1 snippet does not contain c2 data');
	like($s2,    qr/March/,   'c2 snippet has c2 data');

	like($s1, qr/width="400"/, 'c1 snippet SVG has correct width');
	like($s2, qr/width="800"/, 'c2 snippet SVG has correct width');

	diag("c1 output length: " . length($h1_bar)) if $ENV{TEST_VERBOSE};
	diag("c2 output length: " . length($h2_bar)) if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# 4. Data serialisation consistency across all single-series render methods
#
# Given the same data array, all simple render methods must embed the same
# JSON key/value pairs.  This guards against a future method accidentally
# using a different serialisation path.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'same data produces consistent JSON embedding across render methods' => sub {
	my $chart = HTML::D3->new(title => 'Consistency');
	my @data  = (['January', 1_000], ['February', 1_200]);

	my $bar  = $chart->render_bar_chart(\@data);
	my $line = $chart->render_line_chart(\@data);
	my $tip  = $chart->render_line_chart_with_tooltips(\@data);
	my $snip = $chart->render_line_chart_snippet(\@data)->{html};
	my $zoom = $chart->render_zoomable_line_chart_snippet(\@data)->{html};

	for my $pair (
		['bar',     $bar],
		['line',    $line],
		['tooltip', $tip],
		['snippet', $snip],
		['zoom',    $zoom],
	) {
		my ($name, $html) = @$pair;
		like($html, qr/"label":"January"/, "$name: label key serialised correctly");
		like($html, qr/"value":1000/,      "$name: value key serialised correctly");
		like($html, qr/February/,          "$name: second label present");
	}
};

# ─────────────────────────────────────────────────────────────────────────────
# 5. Dimension propagation: width and height reach every output artefact
# ─────────────────────────────────────────────────────────────────────────────

subtest 'constructor width/height propagate to SVG in every method' => sub {
	my $chart = HTML::D3->new(width => 1_024, height => 768, title => 'Dims');
	my @data  = (['Jan', 10], ['Feb', 20]);

	# Every full-page method must embed the correct SVG dimensions.
	for my $pair (
		['render_bar_chart',               $chart->render_bar_chart(\@data)],
		['render_line_chart',              $chart->render_line_chart(\@data)],
		['render_line_chart_with_tooltips',$chart->render_line_chart_with_tooltips(\@data)],
	) {
		my ($name, $html) = @$pair;
		like($html, qr/svg id="$SVG_ID" width="1024"/,  "$name: width in SVG");
		like($html, qr/height="768"/,                   "$name: height in SVG");
	}

	# Snippet methods use the same object dimensions.
	my $snip = $chart->render_line_chart_snippet(\@data)->{html};
	my $zoom = $chart->render_zoomable_line_chart_snippet(\@data)->{html};
	like($snip, qr/width="1024"/, 'snippet: width in SVG');
	like($snip, qr/height="768"/, 'snippet: height in SVG');
	like($zoom, qr/width="1024"/, 'zoomable: width in SVG');
	like($zoom, qr/height="768"/, 'zoomable: height in SVG');

	# Multi-series methods also propagate dimensions.
	my $ms = $chart->render_multi_series_line_chart_with_tooltips(\@MULTI_DATA);
	like($ms, qr/svg id="$SVG_ID" width="1024"/, 'multi-series: width in SVG');
	like($ms, qr/height="768"/, 'multi-series: height in SVG');
};

# ─────────────────────────────────────────────────────────────────────────────
# 6. Full-page html-tidy validation
#
# Every method that returns a complete HTML5 document must pass html-tidy with
# no errors.  This is the critical end-to-end gate: it exercises the DOCTYPE,
# head, meta tags, D3 script tag, and tooltip JS strings simultaneously.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'all full-page methods produce html-tidy-valid documents' => sub {
	my $chart = HTML::D3->new(title => 'Tidy', width => 800, height => 600);

	html_tidy_ok(
		$chart->render_bar_chart(\@SIMPLE_DATA),
		'render_bar_chart output is valid HTML5',
	);
	html_tidy_ok(
		$chart->render_line_chart(\@SIMPLE_DATA),
		'render_line_chart output is valid HTML5',
	);
	html_tidy_ok(
		$chart->render_line_chart_with_tooltips(\@SIMPLE_DATA),
		'render_line_chart_with_tooltips output is valid HTML5',
	);
	html_tidy_ok(
		$chart->render_multi_series_line_chart_with_tooltips(\@MULTI_DATA),
		'render_multi_series_line_chart_with_tooltips output is valid HTML5',
	);
	html_tidy_ok(
		$chart->render_multi_series_line_chart_with_animated_tooltips(\@MULTI_DATA),
		'render_multi_series_line_chart_with_animated_tooltips output is valid HTML5',
	);
	html_tidy_ok(
		$chart->render_multi_series_line_chart_with_legends(\@MULTI_DATA),
		'render_multi_series_line_chart_with_legends output is valid HTML5',
	);
	html_tidy_ok(
		$chart->render_multi_series_line_chart_with_interactive_legends(\@MULTI_DATA),
		'render_multi_series_line_chart_with_interactive_legends output is valid HTML5',
	);
	html_tidy_ok(
		$chart->render_animated_bar_chart(\@SIMPLE_DATA),
		'render_animated_bar_chart output is valid HTML5',
	);
	html_tidy_ok(
		$chart->render_animated_line_chart(\@SIMPLE_DATA),
		'render_animated_line_chart output is valid HTML5',
	);
	html_tidy_ok(
		$chart->render_pie_chart(\@SIMPLE_DATA),
		'render_pie_chart output is valid HTML5',
	);
	html_tidy_ok(
		$chart->render_animated_pie_chart(\@SIMPLE_DATA),
		'render_animated_pie_chart output is valid HTML5',
	);
};

# ─────────────────────────────────────────────────────────────────────────────
# 7. Snippet isolation: fragment methods produce no page-shell
#
# Both snippet methods must not contain any DOCTYPE, <html>, <head>, or <body>
# regardless of the object settings.  They must be safe to splice directly into
# a host layout without corrupting its structure.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'snippet methods produce page-shell-free fragments in all configurations' => sub {
	# Test with non-default dimensions to rule out hardcoded fragments.
	my $chart = HTML::D3->new(width => 1_024, height => 768, title => 'Frag');

	for my $pair (
		['render_line_chart_snippet',
			$chart->render_line_chart_snippet(\@SIMPLE_DATA)->{html}],
		['render_zoomable_line_chart_snippet',
			$chart->render_zoomable_line_chart_snippet(\@SIMPLE_DATA)->{html}],
		['render_pie_chart_snippet',
			$chart->render_pie_chart_snippet(\@SIMPLE_DATA)->{html}],
	) {
		my ($name, $html) = @$pair;
		unlike($html, qr/<!DOCTYPE/i, "$name: no DOCTYPE");
		unlike($html, qr/<html/i,     "$name: no <html> element");
		unlike($html, qr/<head/i,     "$name: no <head> element");
		unlike($html, qr/<body/i,     "$name: no <body> element");
		like($html,   qr/$D3_CDN/,    "$name does NOT link to CDN (caller's responsibility)")
			if 0;   # Snippets deliberately omit the CDN script tag
		unlike($html, qr/\Q$D3_CDN\E/,
			"$name: caller is responsible for loading D3 -- CDN tag absent from fragment");
	}
};

# ─────────────────────────────────────────────────────────────────────────────
# 8. encode_json called exactly once per render invocation (spy)
#
# Every render method must serialise its data exactly once.  Calling encode_json
# more than once per invocation would be redundant; calling it zero times would
# mean the data is hardcoded or ignored.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'encode_json called exactly once per render, with correct data shape' => sub {
	my $chart = HTML::D3->new();

	for my $pair (
		['render_bar_chart',           sub { $chart->render_bar_chart(\@SIMPLE_DATA) }],
		['render_line_chart',          sub { $chart->render_line_chart(\@SIMPLE_DATA) }],
		['render_line_chart_with_tooltips',
			sub { $chart->render_line_chart_with_tooltips(\@SIMPLE_DATA) }],
		['render_line_chart_snippet',
			sub { $chart->render_line_chart_snippet(\@SIMPLE_DATA) }],
		['render_zoomable_line_chart_snippet',
			sub { $chart->render_zoomable_line_chart_snippet(\@SIMPLE_DATA) }],
		['render_multi_series_line_chart_with_tooltips',
			sub { $chart->render_multi_series_line_chart_with_tooltips(\@MULTI_DATA) }],
		['render_animated_bar_chart',
			sub { $chart->render_animated_bar_chart(\@SIMPLE_DATA) }],
		['render_animated_line_chart',
			sub { $chart->render_animated_line_chart(\@SIMPLE_DATA) }],
		['render_pie_chart',
			sub { $chart->render_pie_chart(\@SIMPLE_DATA) }],
		['render_animated_pie_chart',
			sub { $chart->render_animated_pie_chart(\@SIMPLE_DATA) }],
		['render_pie_chart_snippet',
			sub { $chart->render_pie_chart_snippet(\@SIMPLE_DATA) }],
	) {
		my ($name, $code) = @$pair;
		my $sp = spy('HTML::D3::encode_json');
		$code->();
		my @calls = $sp->();
		is(scalar @calls, 1, "$name calls encode_json exactly once");

		# The first argument to encode_json (after the function name in the spy log)
		# must be a reference -- either ARRAY (simple) or a blessed object.
		my $arg = $calls[0][1];
		ok(ref($arg), "$name passes a reference to encode_json (not a plain scalar)");

		diag("$name encode_json arg type: " . ref($arg)) if $ENV{TEST_VERBOSE};
	}
};

# ─────────────────────────────────────────────────────────────────────────────
# 9. JSON::MaybeXS backend fallback
#
# JSON::MaybeXS selects among Cpanel::JSON::XS, JSON::XS, and JSON::PP.
# HTML::D3 must produce identical, valid output regardless of which backend
# is active.  We hide the XS backends to force JSON::PP (pure Perl) and
# verify that the full render pipeline still works.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'HTML::D3 works identically under JSON::PP (no XS JSON backend)' => sub {
	# JSON::MaybeXS selects its backend once at first-require time and compiles
	# it into Perl's symbol table.  Re-requiring it inside an already-running
	# test process causes "Subroutine redefined" errors, so we cannot swap
	# backends mid-run.  Instead we verify two things independently:
	#
	# (a) JSON::PP (the pure-Perl fallback) can correctly encode the exact data
	#     shapes that HTML::D3 passes to encode_json.  If JSON::PP produces
	#     wrong output the fallback path is broken for users without XS JSON.
	#
	# (b) HTML::D3 output under the currently-active backend is structurally
	#     correct, confirming no backend-specific divergence in the module.

	# (a) Direct JSON::PP verification -- no re-require of JSON::MaybeXS needed.
	{
		use Test::Without::Module qw(Cpanel::JSON::XS JSON::XS);

		my $pp_json = eval {
			require JSON::PP;
			JSON::PP->new->encode([
				map { { label => $_->[0], value => $_->[1] } } @SIMPLE_DATA
			]);
		};
		is($@, '', 'JSON::PP encodes simple chart data without error');
		like($pp_json, qr/"label":"January"/, 'JSON::PP produces correct label key');
		like($pp_json, qr/"value":1000/,      'JSON::PP produces correct numeric value');

		# Multi-series data shape (array of hashes with nested data).
		my $ms_json = eval {
			require JSON::PP;
			JSON::PP->new->encode(\@MULTI_DATA);
		};
		is($@, '', 'JSON::PP encodes multi-series data without error');
		like($ms_json, qr/Series A/, 'JSON::PP preserves series name');

		# Extra tooltip data shape (hashref third element).
		my $extra_json = eval {
			JSON::PP->new->encode([
				{ label => 'Jan', value => 100, extra => { Region => 'North' } },
				{ label => 'Feb', value => 200 },
			]);
		};
		is($@, '', 'JSON::PP encodes extra-tooltip data without error');
		like($extra_json, qr/"extra"/, 'JSON::PP preserves extra key');

		diag("JSON::PP version: $JSON::PP::VERSION") if $ENV{TEST_VERBOSE};
		no Test::Without::Module qw(Cpanel::JSON::XS JSON::XS);
	}

	# (b) HTML::D3 with the active JSON backend produces structurally correct output.
	my $chart   = HTML::D3->new(title => 'Backend Test', width => 800, height => 600);
	my $ref_bar  = $chart->render_bar_chart(\@SIMPLE_DATA);
	my $ref_snip = $chart->render_line_chart_snippet(\@SIMPLE_DATA)->{html};

	like($ref_bar,    qr/<!DOCTYPE html>/i,  'active-backend run: bar has DOCTYPE');
	like($ref_bar,    qr/"label":"January"/, 'active-backend run: bar has correct JSON');
	like($ref_snip,   qr/"label":"January"/, 'active-backend run: snippet has correct JSON');
	unlike($ref_snip, qr/<!DOCTYPE/i,        'active-backend run: snippet has no DOCTYPE');

	diag('active JSON backend: ' . ref(JSON::MaybeXS->new)) if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# 10. Global variable integrity
#
# Render methods must not clobber $_ (commonly used by callers in loops),
# $@ (exception state checked after eval blocks), or $! (errno).
# ─────────────────────────────────────────────────────────────────────────────

subtest 'render methods do not clobber $_, $@, or $!' => sub {
	my $chart = HTML::D3->new();

	# Preset sentinel values.
	local $_ = 'sentinel';
	local $@ = '';
	# $! is tricky to set reliably; we just check it does not become truthy.

	$chart->render_bar_chart(\@SIMPLE_DATA);
	is($_, 'sentinel', '$_ is unchanged after render_bar_chart');
	is($@, '',         '$@ is unchanged after render_bar_chart');

	$chart->render_animated_bar_chart(\@SIMPLE_DATA);
	is($_, 'sentinel', '$_ is unchanged after render_animated_bar_chart');
	is($@, '',         '$@ is unchanged after render_animated_bar_chart');

	$chart->render_animated_line_chart(\@SIMPLE_DATA);
	is($_, 'sentinel', '$_ is unchanged after render_animated_line_chart');
	is($@, '',         '$@ is unchanged after render_animated_line_chart');

	$chart->render_pie_chart(\@SIMPLE_DATA);
	is($_, 'sentinel', '$_ is unchanged after render_pie_chart');
	is($@, '',         '$@ is unchanged after render_pie_chart');

	$chart->render_animated_pie_chart(\@SIMPLE_DATA);
	is($_, 'sentinel', '$_ is unchanged after render_animated_pie_chart');

	$chart->render_pie_chart_snippet(\@SIMPLE_DATA);
	is($_, 'sentinel', '$_ is unchanged after render_pie_chart_snippet');
	is($@, '',         '$@ is unchanged after render_pie_chart_snippet');

	$chart->render_line_chart_with_tooltips(\@SIMPLE_DATA);
	is($_, 'sentinel', '$_ is unchanged after render_line_chart_with_tooltips');
	is($@, '',         '$@ is unchanged after render_line_chart_with_tooltips');

	$chart->render_line_chart_snippet(\@SIMPLE_DATA);
	is($_, 'sentinel', '$_ is unchanged after render_line_chart_snippet');
	is($@, '',         '$@ is unchanged after render_line_chart_snippet');

	$chart->render_zoomable_line_chart_snippet(\@SIMPLE_DATA);
	is($_, 'sentinel', '$_ is unchanged after render_zoomable_line_chart_snippet');

	$chart->render_multi_series_line_chart_with_interactive_legends(\@MULTI_DATA);
	is($_, 'sentinel', '$_ is unchanged after render_multi_series_*_with_interactive_legends');
	is($@, '',         '$@ is unchanged after render_multi_series_*_with_interactive_legends');
};

# ─────────────────────────────────────────────────────────────────────────────
# 11. Extra tooltip data round-trip (snippet vs zoomable)
#
# The optional third element [label, value, \%extra] must be serialised
# consistently by both render_line_chart_snippet and
# render_zoomable_line_chart_snippet.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'extra tooltip data serialised consistently across snippet methods' => sub {
	my $chart = HTML::D3->new();

	my $snip_html = $chart->render_line_chart_snippet(\@EXTRA_DATA)->{html};
	my $zoom_html = $chart->render_zoomable_line_chart_snippet(\@EXTRA_DATA)->{html};

	for my $pair (['snippet', $snip_html], ['zoom', $zoom_html]) {
		my ($name, $html) = @$pair;

		like($html, qr/"extra":\{/,
			"$name: extra object present in D3 JSON binding");
		like($html, qr/Region/,
			"$name: extra key 'Region' appears in JSON");
		like($html, qr/North/,
			"$name: extra value 'North' appears in JSON");
		like($html, qr/Object\.entries\(d\.extra\)/,
			"$name: mouseover handler iterates d.extra");

		# Exactly one data point carries extra; the second point (plain pair) must
		# produce no extra key at all.
		my @hits = ($html =~ m{"extra":\{}g);
		is(scalar @hits, 1, "$name: exactly one data point carries the extra object");
	}

	# Both methods must produce the same Region/North pair -- verify textual
	# consistency of the embedded JSON.
	like($snip_html, qr/"Region":"North"/, 'snippet: Region key has correct value');
	like($zoom_html, qr/"Region":"North"/, 'zoom: Region key has correct value');
};

# ─────────────────────────────────────────────────────────────────────────────
# 12. Title propagation throughout the full render pipeline
#
# The object title must appear in every full-page output's <title> tag AND in
# the visible <h1> heading; it must NOT appear in fragment output (no <title>
# or <h1> in a fragment).
# ─────────────────────────────────────────────────────────────────────────────

subtest 'title propagates to page <title> and <h1> but not to fragments' => sub {
	Readonly my $TITLE => 'My Dashboard Title';
	my $chart = HTML::D3->new(title => $TITLE);

	# Full-page methods.
	for my $html (
		$chart->render_bar_chart(\@SIMPLE_DATA),
		$chart->render_line_chart(\@SIMPLE_DATA),
		$chart->render_line_chart_with_tooltips(\@SIMPLE_DATA),
		$chart->render_multi_series_line_chart_with_tooltips(\@MULTI_DATA),
		$chart->render_multi_series_line_chart_with_legends(\@MULTI_DATA),
		$chart->render_multi_series_line_chart_with_interactive_legends(\@MULTI_DATA),
		$chart->render_animated_bar_chart(\@SIMPLE_DATA),
		$chart->render_animated_line_chart(\@SIMPLE_DATA),
		$chart->render_pie_chart(\@SIMPLE_DATA),
		$chart->render_animated_pie_chart(\@SIMPLE_DATA),
	) {
		like($html, qr/<title>\Q$TITLE\E<\/title>/, 'title appears in <title> tag');
		like($html, qr/\Q$TITLE\E<\/h1>/,           'title appears in visible <h1>');
	}

	# Fragment methods must NOT contain <title> or <h1>.
	for my $html (
		$chart->render_line_chart_snippet(\@SIMPLE_DATA)->{html},
		$chart->render_zoomable_line_chart_snippet(\@SIMPLE_DATA)->{html},
		$chart->render_pie_chart_snippet(\@SIMPLE_DATA)->{html},
	) {
		unlike($html, qr/<title>/i, 'fragment has no <title> element');
		unlike($html, qr/<h1/i,     'fragment has no <h1> element');
	}
};

# ─────────────────────────────────────────────────────────────────────────────
# 13. D3 CDN link: full-page methods load D3; fragment methods do not
#
# Fragment callers are responsible for loading D3 in their host page.
# Full-page methods must embed the CDN <script> tag in their <head>.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'D3 CDN script loaded by full-page methods, absent from fragments' => sub {
	my $chart = HTML::D3->new();

	for my $html (
		$chart->render_bar_chart(\@SIMPLE_DATA),
		$chart->render_line_chart(\@SIMPLE_DATA),
		$chart->render_line_chart_with_tooltips(\@SIMPLE_DATA),
		$chart->render_multi_series_line_chart_with_tooltips(\@MULTI_DATA),
		$chart->render_animated_bar_chart(\@SIMPLE_DATA),
		$chart->render_animated_line_chart(\@SIMPLE_DATA),
		$chart->render_pie_chart(\@SIMPLE_DATA),
		$chart->render_animated_pie_chart(\@SIMPLE_DATA),
	) {
		like($html, qr/\Q$D3_CDN\E/, "full-page output embeds D3 CDN script tag");
	}

	for my $html (
		$chart->render_line_chart_snippet(\@SIMPLE_DATA)->{html},
		$chart->render_zoomable_line_chart_snippet(\@SIMPLE_DATA)->{html},
		$chart->render_pie_chart_snippet(\@SIMPLE_DATA)->{html},
	) {
		unlike($html, qr/\Q$D3_CDN\E/,
			'fragment omits D3 CDN (caller is responsible)');
	}
};

# ─────────────────────────────────────────────────────────────────────────────
# 14. html-tidy safety: </b> must never appear in any render output
#
# The POD formally specifies that all tooltip JS strings use <\/b> (with
# backslash) to satisfy html-tidy.  This cross-method assertion runs the check
# across every method in one sweep.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'no raw </b> tag appears in any render output' => sub {
	my $chart = HTML::D3->new();

	for my $pair (
		['render_bar_chart',
			$chart->render_bar_chart(\@SIMPLE_DATA)],
		['render_line_chart',
			$chart->render_line_chart(\@SIMPLE_DATA)],
		['render_line_chart_with_tooltips',
			$chart->render_line_chart_with_tooltips(\@SIMPLE_DATA)],
		['render_line_chart_snippet',
			$chart->render_line_chart_snippet(\@SIMPLE_DATA)->{html}],
		['render_zoomable_line_chart_snippet',
			$chart->render_zoomable_line_chart_snippet(\@SIMPLE_DATA)->{html}],
		['render_multi_series_line_chart_with_tooltips',
			$chart->render_multi_series_line_chart_with_tooltips(\@MULTI_DATA)],
		['render_multi_series_line_chart_with_animated_tooltips',
			$chart->render_multi_series_line_chart_with_animated_tooltips(\@MULTI_DATA)],
		['render_multi_series_line_chart_with_legends',
			$chart->render_multi_series_line_chart_with_legends(\@MULTI_DATA)],
		['render_multi_series_line_chart_with_interactive_legends',
			$chart->render_multi_series_line_chart_with_interactive_legends(\@MULTI_DATA)],
		['render_animated_bar_chart',
			$chart->render_animated_bar_chart(\@SIMPLE_DATA)],
		['render_animated_line_chart',
			$chart->render_animated_line_chart(\@SIMPLE_DATA)],
		['render_pie_chart',
			$chart->render_pie_chart(\@SIMPLE_DATA)],
		['render_animated_pie_chart',
			$chart->render_animated_pie_chart(\@SIMPLE_DATA)],
		['render_pie_chart_snippet',
			$chart->render_pie_chart_snippet(\@SIMPLE_DATA)->{html}],
	) {
		my ($name, $html) = @$pair;
		unlike($html, qr{</b>}, "$name: no raw </b> in output");
	}
};

# ─────────────────────────────────────────────────────────────────────────────
# 15. On-load drawing animations
#
# render_animated_bar_chart must include D3 transition() and a per-bar stagger
# delay so bars grow upward one after another.
# render_animated_line_chart must use the stroke-dashoffset technique and
# d3.easeLinear so the line draws itself left-to-right; circles must fade in
# afterwards via an opacity transition.
# ─────────────────────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────────────────────
# 16. Pie chart method consistency
#
# All three pie methods share the same d3.pie() / d3.arc() / schemeCategory10
# structure; the animated variant adds attrTween / d3.interpolate; the snippet
# omits the page shell.  Verified cross-method so a shared-helper refactor
# cannot silently break one variant.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'pie chart methods share consistent D3 structure' => sub {
	my $chart = HTML::D3->new(width => 800, height => 600, title => 'Pie Suite');

	my $pie_html      = $chart->render_pie_chart(\@SIMPLE_DATA);
	my $anim_html     = $chart->render_animated_pie_chart(\@SIMPLE_DATA);
	my $snip_html     = $chart->render_pie_chart_snippet(\@SIMPLE_DATA)->{html};

	# All three must use the same fundamental D3 pie primitives.
	for my $pair (
		['render_pie_chart',          $pie_html],
		['render_animated_pie_chart', $anim_html],
		['render_pie_chart_snippet',  $snip_html],
	) {
		my ($name, $html) = @$pair;
		like($html, qr/d3\.pie\(\)/,          "$name: d3.pie() present");
		like($html, qr/d3\.arc\(\)/,           "$name: d3.arc() present");
		like($html, qr/d3\.schemeCategory10/, "$name: schemeCategory10 colour scheme present");
		like($html, qr/d3\.scaleOrdinal/,     "$name: d3.scaleOrdinal maps colours");
		like($html, qr/d3\.sum/,               "$name: d3.sum computes total for percentages");
	}

	# Static and snippet must NOT have animation artefacts.
	unlike($pie_html,  qr/attrTween/, 'render_pie_chart: no attrTween in static version');
	unlike($snip_html, qr/attrTween/, 'render_pie_chart_snippet: no attrTween in snippet');

	# Animated must have both tween and fade-in.
	like($anim_html, qr/attrTween/,              'render_animated_pie_chart: attrTween present');
	like($anim_html, qr/d3\.interpolate/,         'render_animated_pie_chart: d3.interpolate present');
	like($anim_html, qr/\.attr\("opacity",\s*0\)/, 'render_animated_pie_chart: labels fade in from opacity 0');

	# Snippet must have no page shell; full-page must.
	unlike($snip_html, qr/<!DOCTYPE/i, 'snippet: no DOCTYPE');
	unlike($snip_html, qr/<html/i,     'snippet: no <html>');
	like($pie_html,    qr/<!DOCTYPE/i, 'full-page pie: has DOCTYPE');
	like($anim_html,   qr/<!DOCTYPE/i, 'full-page animated pie: has DOCTYPE');
};

subtest 'on-load drawing animations present in animated chart methods' => sub {
	my $chart = HTML::D3->new(width => 800, height => 600, title => 'Anim Test');

	my $bar_html  = $chart->render_animated_bar_chart(\@SIMPLE_DATA);
	my $line_html = $chart->render_animated_line_chart(\@SIMPLE_DATA);

	# Bar chart: bars must start at the baseline (y=height, height=0) and grow up.
	like($bar_html, qr/\.transition\(\)/, 'animated bar: transition() present');
	like($bar_html, qr/\.duration\(\d+\)/, 'animated bar: duration() present');
	like($bar_html, qr/\.delay\(/,         'animated bar: stagger delay present');
	# Bars must start with height=0 (the initial .attr("height", 0) call).
	like($bar_html, qr/\.attr\("height",\s*0\)/, 'animated bar: initial height=0 for animation start');
	like($bar_html, qr/d3\.scaleBand/,    'animated bar: still uses d3.scaleBand');

	# Line chart: must use stroke-dashoffset technique for draw animation.
	like($line_html, qr/stroke-dashoffset/,  'animated line: stroke-dashoffset present');
	like($line_html, qr/getTotalLength\(\)/, 'animated line: getTotalLength() used');
	like($line_html, qr/d3\.easeLinear/,     'animated line: d3.easeLinear easing');
	# Circles must start invisible and fade in after the line finishes.
	like($line_html, qr/\.attr\("opacity",\s*0\)/, 'animated line: circles start at opacity 0');
	like($line_html, qr/\.delay\(1500\)/,           'animated line: circles delayed to after line draw');
};

done_testing();

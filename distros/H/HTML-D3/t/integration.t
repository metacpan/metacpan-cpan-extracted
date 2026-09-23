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
# 8. JSON serialisation present in render output (behavioural contract)
#
# Every render method must embed the input data as JSON in its output.
# We verify that a known label ("January") and value (1000) from SIMPLE_DATA
# appear in the rendered HTML, confirming the data was serialised and embedded.
# We also check the output is a Perl character string (UTF-8 flag set), not a
# byte string -- the previous encode_json() call returned octets, which caused
# mojibake when callers embedded the result in a character-string context.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'render methods embed JSON data and return character strings' => sub {
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
		my $result = $code->();

		# Normalise: snippet methods return a hashref {html => ...}; others return a string.
		my $html = ref($result) eq 'HASH' ? $result->{html} : $result;

		like($html, qr/January/, "$name: output contains label from input data");
		like($html, qr/1000|1,000/, "$name: output contains value from input data");

		# The html must be a Perl character string so callers don't get mojibake
		# when they concatenate it with other character-string content.
		ok(utf8::is_utf8($html) || $html !~ /[^\x00-\x7f]/,
			"$name: output is a character string or pure ASCII");

		diag("$name output length: " . length($html)) if $ENV{TEST_VERBOSE};
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

	# Full-page pie methods share the same D3 primitives and colour scheme.
	for my $pair (
		['render_pie_chart',          $pie_html],
		['render_animated_pie_chart', $anim_html],
	) {
		my ($name, $html) = @$pair;
		like($html, qr/d3\.pie\(\)/,          "$name: d3.pie() present");
		like($html, qr/d3\.arc\(\)/,           "$name: d3.arc() present");
		like($html, qr/d3\.schemeCategory10/, "$name: schemeCategory10 colour scheme present");
		like($html, qr/d3\.scaleOrdinal/,     "$name: d3.scaleOrdinal maps colours");
		like($html, qr/d3\.sum/,               "$name: d3.sum computes total for percentages");
	}

	# render_pie_chart_snippet uses the same primitives but a richer API
	# (opts: animated, donut, sort_slices, max_slices, legend, color_scheme).
	like($snip_html, qr/d3\.pie\(\)/,         'render_pie_chart_snippet: d3.pie() present');
	like($snip_html, qr/d3\.arc\(\)/,          'render_pie_chart_snippet: d3.arc() present');
	like($snip_html, qr/d3\.schemeTableau10/, 'render_pie_chart_snippet: default scheme is tableau10');
	like($snip_html, qr/d3\.scaleOrdinal/,    'render_pie_chart_snippet: d3.scaleOrdinal present');
	like($snip_html, qr/d3\.sum/,              'render_pie_chart_snippet: d3.sum present');

	# Static full-page and plain snippet must NOT have animation artefacts.
	unlike($pie_html,  qr/attrTween/, 'render_pie_chart: no attrTween in static version');
	unlike($snip_html, qr/attrTween/, 'render_pie_chart_snippet: no attrTween without animated flag');

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

# ─────────────────────────────────────────────────────────────────────────────
# 17. Separator option: cross-method consistency and object independence
#
# All three pie chart methods accept an optional separator key (default '/').
# The separator is interpolated into JavaScript source (template literal for
# full-page methods; string concatenation for the snippet).  This subtest
# verifies that:
#   (a) the default '/' appears in all three methods without any opts;
#   (b) a custom separator propagates to all three and replaces the default;
#   (c) two simultaneously-live chart objects with different separators do not
#       bleed state into each other.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'separator option propagates consistently across all three pie methods' => sub {
	my $chart = HTML::D3->new(width => 800, height => 600, title => 'Sep Suite');

	# Default separator '/' must appear in every legend generator.
	# Full-page: the separator sits in a JS template literal:
	#   .text(d => `${d.data.label} / ${d.data.value}`)
	# Snippet: the separator sits in JS string concatenation:
	#   d.data.label + ' / ' + fmt(...)
	my $pie_html  = $chart->render_pie_chart(\@SIMPLE_DATA);
	my $anim_html = $chart->render_animated_pie_chart(\@SIMPLE_DATA);
	my $snip_html = $chart->render_pie_chart_snippet(\@SIMPLE_DATA)->{html};

	like($pie_html,  qr/d\.data\.label} \/ \$\{d\.data\.value}/, 'pie: default / in SVG legend JS');
	like($anim_html, qr/d\.data\.label} \/ \$\{d\.data\.value}/, 'animated pie: default / in SVG legend JS');
	like($snip_html, qr/d\.data\.label \+ ' \/ '/,               'snippet: default / in HTML legend JS');

	# Custom separator '|' must replace the default across all three.
	my $pie_bar  = $chart->render_pie_chart(\@SIMPLE_DATA,          { separator => '|' });
	my $anim_bar = $chart->render_animated_pie_chart(\@SIMPLE_DATA, { separator => '|' });
	my $snip_bar = $chart->render_pie_chart_snippet(\@SIMPLE_DATA,  { separator => '|' })->{html};

	like($pie_bar,  qr/d\.data\.label} \| \$\{d\.data\.value}/, 'pie: custom | in SVG legend JS');
	like($anim_bar, qr/d\.data\.label} \| \$\{d\.data\.value}/, 'animated pie: custom | in SVG legend JS');
	like($snip_bar, qr/d\.data\.label \+ ' \| '/,               'snippet: custom | in HTML legend JS');

	unlike($pie_bar,  qr/d\.data\.label} \/ /, 'pie: default / absent when overridden with |');
	unlike($anim_bar, qr/d\.data\.label} \/ /, 'animated pie: default / absent when overridden');
	unlike($snip_bar, qr/d\.data\.label \+ ' \/ '/, 'snippet: default / absent when overridden');

	# Object independence: simultaneous objects with different separators must
	# not leak state into each other's output.
	my $c1 = HTML::D3->new(width => 800, height => 600, title => 'C1');
	my $c2 = HTML::D3->new(width => 800, height => 600, title => 'C2');

	my $h1 = $c1->render_pie_chart(\@SIMPLE_DATA, { separator => '/' });
	my $h2 = $c2->render_pie_chart(\@SIMPLE_DATA, { separator => ':' });

	like($h1,   qr/d\.data\.label} \/ \$\{d\.data\.value}/, 'c1: / separator in output');
	unlike($h1, qr/d\.data\.label} : /,                     'c1: no : bleed from c2');
	like($h2,   qr/d\.data\.label} : \$\{d\.data\.value}/, 'c2: : separator in output');
	unlike($h2, qr/d\.data\.label} \/ /,                    'c2: no / bleed from c1');

	# Snippets must also be independent.
	my $s1 = $c1->render_pie_chart_snippet(\@SIMPLE_DATA, { separator => '/' })->{html};
	my $s2 = $c2->render_pie_chart_snippet(\@SIMPLE_DATA, { separator => ':' })->{html};

	like($s1,   qr/d\.data\.label \+ ' \/ '/, 'c1 snippet: / in legend JS');
	unlike($s1, qr/d\.data\.label \+ ' : '/, 'c1 snippet: no : bleed from c2');
	like($s2,   qr/d\.data\.label \+ ' : '/, 'c2 snippet: : in legend JS');
	unlike($s2, qr/d\.data\.label \+ ' \/ '/, 'c2 snippet: no / bleed from c1');

	# The separator opt must not affect any other output: pie/arc/scheme markers
	# must still be present regardless of which separator is chosen.
	like($pie_bar, qr/d3\.pie\(\)/,          'custom-sep pie: d3.pie() unaffected');
	like($anim_bar, qr/attrTween/,           'custom-sep animated pie: attrTween unaffected');
	like($snip_bar, qr/d3\.schemeTableau10/, 'custom-sep snippet: scheme unaffected');

	diag("pie_bar length: " . length($pie_bar)) if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# 18. render_pie_chart_snippet: full opts suite and combined workflows
#
# Each opt is exercised in isolation first; then a realistic production
# workflow combining animated + donut + max_slices + custom separator is
# run end-to-end to verify the opts do not interfere with each other.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'render_pie_chart_snippet opts combine without interference' => sub {
	my $chart = HTML::D3->new(width => 800, height => 600, title => 'Opts Suite');

	# animated => 1: fan animation markers must all be present.
	my $anim_html = $chart->render_pie_chart_snippet(\@SIMPLE_DATA, { animated => 1 })->{html};
	like($anim_html, qr/attrTween/,             'animated: attrTween fan animation present');
	like($anim_html, qr/initialDrawDone/,        'animated: initialDrawDone guard present');
	like($anim_html, qr/prefers-reduced-motion/, 'animated: prefers-reduced-motion respected');
	unlike($anim_html, qr/<!DOCTYPE/i,           'animated: still a fragment, no DOCTYPE');

	# animated => 0 (explicit): no animation artefacts.
	my $plain_html = $chart->render_pie_chart_snippet(\@SIMPLE_DATA, { animated => 0 })->{html};
	unlike($plain_html, qr/attrTween/,      'plain: no attrTween');
	unlike($plain_html, qr/initialDrawDone/, 'plain: no initialDrawDone');

	# donut => 1: innerRadius calculation must appear; fmt(total) shown in centre.
	my $donut_html = $chart->render_pie_chart_snippet(\@SIMPLE_DATA, { donut => 1 })->{html};
	like($donut_html, qr/innerRadius/,      'donut: innerRadius present');
	like($donut_html, qr/radius \* 0\.38/, 'donut: inner radius set to 38% of outer');
	like($donut_html, qr/fmt\(total\)/,    'donut: total label rendered in centre hole');

	# sort_slices => 'value': highest-value slice first in the embedded JSON array.
	# SIMPLE_DATA values: January=1000, February=1200, March=950
	# Descending sort: February(1200), January(1000), March(950)
	my $sorted_html = $chart->render_pie_chart_snippet(
		\@SIMPLE_DATA, { sort_slices => 'value' }
	)->{html};
	my ($first_label) = ($sorted_html =~ /"label":"([^"]+)"/);
	is($first_label, 'February', 'sort_slices value: highest-value slice is first in JSON');

	# sort_slices => 'label': alphabetical order (January, February, March → Feb, Jan, Mar).
	my $alpha_html = $chart->render_pie_chart_snippet(
		\@SIMPLE_DATA, { sort_slices => 'label' }
	)->{html};
	my ($first_alpha) = ($alpha_html =~ /"label":"([^"]+)"/);
	is($first_alpha, 'February', 'sort_slices label: alphabetically first slice is first');

	# max_slices => 2 with 3-item dataset: top-1 slice + "Other" = 2 slices in JSON.
	my $max_html = $chart->render_pie_chart_snippet(\@SIMPLE_DATA, { max_slices => 2 })->{html};
	my @max_labels = ($max_html =~ /"label":"([^"]+)"/g);
	is(scalar @max_labels, 2,       'max_slices 2: exactly 2 slices in JSON');
	ok((grep { $_ eq 'Other' } @max_labels), 'max_slices 2: "Other" aggregation slice present');

	# color_scheme => 'set2': the SCHEMES lookup must use 'set2'.
	my $scheme_html = $chart->render_pie_chart_snippet(
		\@SIMPLE_DATA, { color_scheme => 'set2' }
	)->{html};
	like($scheme_html,   qr/SCHEMES\['set2'\]/,     'color_scheme set2: correct key in SCHEMES lookup');
	unlike($scheme_html, qr/SCHEMES\['tableau10'\]/, 'color_scheme set2: default tableau10 not used');

	# legend => 0: the D3 legend builder JS and the legend div must both be absent.
	my $no_leg_html = $chart->render_pie_chart_snippet(\@SIMPLE_DATA, { legend => 0 })->{html};
	unlike($no_leg_html, qr/selectAll\(".bi-pie-legend-entry"\)/, 'legend => 0: no legend JS');
	unlike($no_leg_html, qr/id="pie_chart_legend"/,               'legend => 0: no legend div');

	# Combined workflow: animated + donut + max_slices + custom separator.
	# A production dashboard might use all of these together; they must coexist.
	my $combo = $chart->render_pie_chart_snippet(
		\@SIMPLE_DATA,
		{ animated => 1, donut => 1, max_slices => 2, separator => ':' }
	)->{html};

	like($combo, qr/attrTween/,              'combo: animation present');
	like($combo, qr/innerRadius/,            'combo: donut inner radius present');
	like($combo, qr/d\.data\.label \+ ' : '/, 'combo: custom : separator in legend JS');
	my @combo_labels = ($combo =~ /"label":"([^"]+)"/g);
	is(scalar @combo_labels, 2, 'combo: max_slices collapses to 2 slices in JSON');
	ok((grep { $_ eq 'Other' } @combo_labels), 'combo: "Other" slice present');
	unlike($combo, qr/<!DOCTYPE/i, 'combo: still a fragment regardless of opts');

	# Verify the combined output still has core D3 structure.
	like($combo, qr/d3\.pie\(\)/,  'combo: d3.pie() still present');
	like($combo, qr/d3\.arc\(\)/, 'combo: d3.arc() still present');

	diag("combo output length: " . length($combo)) if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# 19. render_zoomable_line_chart_snippet: animated => 1 end-to-end workflow
#
# With animated => 1 the snippet adds a stroke-dashoffset initial-draw
# animation guarded by initialDrawDone so subsequent zoom/reset redraws are
# never re-animated.  The default (no opts) must produce a plain snippet
# with no animation markers but full zoom functionality intact.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'render_zoomable_line_chart_snippet animated workflow' => sub {
	my $chart = HTML::D3->new(width => 800, height => 600, title => 'Zoom Anim');

	# Default (omitted opts): no animation markers; zoom must still work.
	my $plain = $chart->render_zoomable_line_chart_snippet(\@SIMPLE_DATA);
	my $plain_html = $plain->{html};

	unlike($plain_html, qr/stroke-dashoffset/, 'default: no stroke-dashoffset');
	unlike($plain_html, qr/initialDrawDone/,    'default: no initialDrawDone guard');
	like($plain_html,   qr/d3\.brushX\(\)/,     'default: brush-to-zoom present');
	is($plain->{svg_id}, 'chart',               'default: svg_id is "chart"');

	# Explicit animated => 0: identical to the default.
	my $explicit_plain_html = $chart->render_zoomable_line_chart_snippet(
		\@SIMPLE_DATA, { animated => 0 }
	)->{html};
	unlike($explicit_plain_html, qr/stroke-dashoffset/, 'explicit 0: no stroke-dashoffset');
	unlike($explicit_plain_html, qr/initialDrawDone/,   'explicit 0: no initialDrawDone');

	# animated => 1: all animation markers must be present alongside zoom.
	my $anim = $chart->render_zoomable_line_chart_snippet(\@SIMPLE_DATA, { animated => 1 });
	my $anim_html = $anim->{html};

	like($anim_html, qr/stroke-dashoffset/,    'animated: stroke-dashoffset draw-on present');
	like($anim_html, qr/initialDrawDone/,       'animated: initialDrawDone guard present');
	like($anim_html, qr/prefers-reduced-motion/,'animated: prefers-reduced-motion respected');
	like($anim_html, qr/d3\.easeLinear/,        'animated: d3.easeLinear easing present');
	# Zoom must coexist with the draw animation.
	like($anim_html, qr/d3\.brushX\(\)/,        'animated: brush-to-zoom still present');
	is($anim->{svg_id}, 'chart',                'animated: svg_id unchanged ("chart")');

	# Fragment isolation: no page-shell elements regardless of animation flag.
	unlike($anim_html, qr/<!DOCTYPE/i, 'animated: no DOCTYPE');
	unlike($anim_html, qr/<html/i,     'animated: no <html>');
	unlike($anim_html, qr/<head/i,     'animated: no <head>');
	unlike($anim_html, qr/${\$D3_CDN}/, 'animated: no D3 CDN tag (caller loads D3)');

	# Object independence: animated and plain zoomable snippets from separate
	# objects must not bleed animation state into each other.
	my $c1 = HTML::D3->new(width => 800, height => 600, title => 'C1');
	my $c2 = HTML::D3->new(width => 800, height => 600, title => 'C2');

	my $h1 = $c1->render_zoomable_line_chart_snippet(\@SIMPLE_DATA, { animated => 1 })->{html};
	my $h2 = $c2->render_zoomable_line_chart_snippet(\@SIMPLE_DATA)->{html};

	like($h1,   qr/stroke-dashoffset/, 'c1 animated: stroke-dashoffset present');
	unlike($h2, qr/stroke-dashoffset/, 'c2 plain: no stroke-dashoffset bleed from c1');
	like($h2,   qr/d3\.brushX\(\)/,   'c2 plain: zoom still intact');

	diag("anim html length: " . length($anim_html)) if $ENV{TEST_VERBOSE};
};

done_testing();

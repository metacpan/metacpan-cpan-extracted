#!/usr/bin/env perl

# Tests focused on the features added today:
#   * the new "p" argument to plt() (1-D = one subplot with overlays,
#     2-D = one subplot per inner array) and the plt( ... ) list form;
#   * the simplified "plot" data form  data => [ \@x, \@y ]  (single line);
#   * a scalar "set.options" applying to every line of array data.
#
# Two complementary layers are used:
#   1. Deterministic checks on the GENERATED PYTHON (execute => 0). This is
#      matplotlib-version independent, so it is where the new logic is pinned
#      down precisely. These run even without matplotlib installed.
#   2. End-to-end RENDER checks: actually run the script through matplotlib and
#      confirm the resulting file is a good SVG (see is_valid_svg below). These
#      are skipped if matplotlib is unavailable.

require 5.010;
use strict;
use warnings FATAL => 'all';
use feature 'say';
use File::Temp qw(tempfile tempdir);
use File::Spec;
use Matplotlib::Simple;
use Test::More;

# ----------------------------------------------------------------------------
# Dependency discovery (python3 is needed for the SVG well-formedness check and
# for the render layer; matplotlib only for the render layer).
# ----------------------------------------------------------------------------
my $python_version_raw = qx/python3 --version 2>&1/;
my $python_available = ( $? == 0 && $python_version_raw =~ m/Python\s+3\.\d+/i ) ? 1 : 0;

my $mpl_available = 0;
my $mpl_version   = '';
if ($python_available) {
	my $raw = qx/python3 -c "import matplotlib; print(matplotlib.__version__)" 2>&1/;
	if ( $? == 0 && $raw =~ m/^\s*(\d+)\.(\d+)\.\d+/ ) {
		# the module documents a 3.10+ requirement; render only when satisfied
		$mpl_available = ( $1 > 3 || ( $1 == 3 && $2 >= 10 ) ) ? 1 : 0;
		( $mpl_version = $raw ) =~ s/^\s+|\s+$//g;
	}
}
diag( $python_available ? "python3: $python_version_raw" : 'python3 not found' );
diag( $mpl_available ? "matplotlib: $mpl_version (render layer ON)"
	: 'matplotlib >= 3.10 not found (render layer SKIPPED)' );

# ----------------------------------------------------------------------------
# SVG validation.
#
# Matplotlib emits byte-for-byte different SVGs across versions, so hashing the
# output is brittle.  Instead we ask: is this a *good* SVG?  We answer in two
# stages: cheap structural regexes, then an authoritative well-formedness parse
# using python's stdlib xml.etree.ElementTree (already required at runtime).
# svg_problem() returns '' when the file is good, otherwise a human-readable
# reason, so test failures say *why* the SVG is bad.
# ----------------------------------------------------------------------------
sub file2string {
	my $file = shift;
	open my $fh, '<', $file or return '';
	local $/;
	return <$fh>;
}

sub xml_wellformed_problem {    # '' if good, else reason. Needs python3.
	my ($file) = @_;
	return '' unless $python_available;
	my $py = <<'PY';
import sys, xml.etree.ElementTree as ET
try:
    root = ET.parse(sys.argv[1]).getroot()
except Exception as e:
    print("not well-formed XML: %s" % e); sys.exit(0)
tag = root.tag.split('}', 1)[1] if root.tag.startswith('{') else root.tag
if tag != 'svg':
    print("root element is <%s>, not <svg>" % tag); sys.exit(0)
if sum(1 for _ in root.iter()) < 2:
    print("svg has no child elements (empty figure)"); sys.exit(0)
print("OK")
PY
	my ( $tfh, $tname ) = tempfile( SUFFIX => '.py', UNLINK => 1 );
	print {$tfh} $py;
	close $tfh;
	my $out = qx/python3 "$tname" "$file" 2>&1/;
	$out =~ s/\s+\z//;
	return $out eq 'OK' ? '' : ( $out eq '' ? 'python validation produced no output' : $out );
}

sub svg_problem {    # '' if the file is a good SVG, else the reason it is not
	my ($file) = @_;
	return 'file does not exist'                unless -e $file;
	return 'not a plain file'                   unless -f $file;
	my $size = -s $file;
	return 'file is empty'                      unless $size;
	return "implausibly small ($size bytes)"    if $size < 200;
	my $c = file2string($file);
	return 'no <svg> root carrying the SVG namespace'
		unless $c =~ m{<svg\b[^>]*\bxmlns\s*=\s*(['"])http://www\.w3\.org/2000/svg\1}s;
	return 'no closing </svg> tag (file truncated?)'
		unless $c =~ m{</svg>\s*\z};
	return 'no drawing content (<path>/<g>/<image>/<rect>/<use>)'
		unless $c =~ m{<(?:path|g|image|rect|use)\b};
	my $xml = xml_wellformed_problem($file);
	return $xml if $xml;
	return '';
}

sub is_valid_svg { return svg_problem( $_[0] ) eq '' }    # boolean convenience

sub has_provenance {    # the module embeds <dc:title> provenance metadata
	my $c = file2string( $_[0] );
	return $c =~ m{<dc:title>.+</dc:title>}s ? 1 : 0;
}

# ----------------------------------------------------------------------------
# Helpers for the deterministic (generated-python) layer.
# ----------------------------------------------------------------------------
sub gen_py {    # run plt with execute => 0, return the generated python as text
	my @args = @_;
	my $pyfile =
		( @args == 1 && ref $args[0] eq 'HASH' )
		? plt( { %{ $args[0] }, execute => 0 } )    # back-compatible hashref form
		: plt( @args, execute => 0 );               # list form
	return file2string($pyfile);
}

sub count_matches {    # number of (possibly overlapping-free) matches of $re
	my ( $text, $re ) = @_;
	my $n = () = $text =~ /$re/g;
	return $n;
}

# small dependency-free replacements for Test::Exception
sub dies_like {
	my ( $code, $re, $name ) = @_;
	my $lived = eval { $code->(); 1 };
	if ($lived) { return ok( 0, "$name (did not die)" ) }
	return like( $@, $re, $name );
}

sub lives_ok_t {
	my ( $code, $name ) = @_;
	my $lived = eval { $code->(); 1 };
	diag("died unexpectedly: $@") unless $lived;
	return ok( $lived, $name );
}

my $TMP = tempdir( CLEANUP => 1 );
sub outfile { File::Spec->catfile( $TMP, $_[0] ) }

# ============================================================================
# LAYER 1 - deterministic generated-python checks (no matplotlib needed)
# ============================================================================

# --- the "p" argument, 1-D: an array of hashes => ONE subplot with overlays ---
{
	my $py = gen_py(
		p => [
			{ 'plot.type' => 'plot', data => [ [ 1 .. 3 ], [ 1 .. 3 ] ], 'set.options' => 'color = "red"' },
			{ 'plot.type' => 'plot', data => [ [ 1 .. 3 ], [ 3, 2, 1 ] ], 'set.options' => 'color = "blue"' },
		],
		'output.file' => outfile('p1d.svg'),
	);
	is( count_matches( $py, qr/^ax0\.plot\(/m ), 2,
		'p (1-D): both plots are drawn on a single axis (ax0)' );
	unlike( $py, qr/\bax1\b/,
		'p (1-D): no second axis is created (it is one subplot)' );
	like( $py, qr/color = "red"/,  'p (1-D): first plot keeps its set.options' );
	like( $py, qr/color = "blue"/, 'p (1-D): the additional plot keeps its set.options' );
}

# --- the "p" argument, 2-D: an array of arrays => one subplot per inner array ---
{
	my $py = gen_py(
		p => [
			[ { 'plot.type' => 'plot', data => [ [ 1 .. 3 ], [ 1 .. 3 ] ] } ],
			[ { 'plot.type' => 'plot', data => [ [ 1 .. 3 ], [ 3, 2, 1 ] ] } ],
		],
		ncol          => 2,
		'output.file' => outfile('p2d.svg'),
	);
	like( $py, qr/^ax0\.plot\(/m, 'p (2-D): first subplot draws on ax0' );
	like( $py, qr/^ax1\.plot\(/m, 'p (2-D): second subplot draws on ax1' );
	like( $py, qr/plt\.subplots\(\s*1\s*,\s*2\b/,
		'p (2-D) with ncol => 2: a 1x2 grid of subplots is created' );
}

# --- a 2-D "p" with a single inner array is still one subplot ---
{
	my $py = gen_py(
		p => [ [ { 'plot.type' => 'plot', data => [ [ 1 .. 3 ], [ 1 .. 3 ] ] } ] ],
		'output.file' => outfile('p2d1.svg'),
	);
	like( $py,   qr/^ax0\.plot\(/m, 'p (2-D, one inner array): draws on ax0' );
	unlike( $py, qr/\bax1\b/,       'p (2-D, one inner array): no ax1' );
}

# --- overlays inside a 2-D subplot (inner array with two hashes) ---
{
	my $py = gen_py(
		p => [
			[
				{ 'plot.type' => 'plot', data => [ [ 1 .. 3 ], [ 1 .. 3 ] ], 'set.options' => 'color = "red"' },
				{ 'plot.type' => 'plot', data => [ [ 1 .. 3 ], [ 3, 2, 1 ] ], 'set.options' => 'color = "blue"' },
			],
			[ { 'plot.type' => 'plot', data => [ [ 1 .. 3 ], [ 2, 2, 2 ] ] } ],
		],
		ncol          => 2,
		'output.file' => outfile('p2d_overlay.svg'),
	);
	is( count_matches( $py, qr/^ax0\.plot\(/m ), 2,
		'p (2-D): first subplot has two overlaid plots' );
	is( count_matches( $py, qr/^ax1\.plot\(/m ), 1,
		'p (2-D): second subplot has one plot' );
}

# --- simplified single-line data:  data => [ \@x, \@y ] ---
{
	my $py = gen_py(
		'plot.type'   => 'plot',
		data          => [ [ 5 .. 9 ], [ 5 .. 9 ] ],
		'output.file' => outfile('single.svg'),
	);
	is( count_matches( $py, qr/^ax0\.plot\(/m ), 1,
		'simplified data => [ \@x, \@y ] produces exactly one line' );
	like( $py, qr/^x = \[5,6,7,8,9\]$/m, 'simplified data: x array written verbatim' );
	like( $py, qr/^y = \[5,6,7,8,9\]$/m, 'simplified data: y array written verbatim' );
}

# --- the simplified form must NOT be confused with the multi-line array form ---
{
	my $multi = gen_py(
		'plot.type'   => 'plot',
		data          => [ [ [ 1 .. 3 ], [ 1 .. 3 ] ], [ [ 1 .. 3 ], [ 3, 2, 1 ] ] ],
		'output.file' => outfile('multi.svg'),
	);
	is( count_matches( $multi, qr/^ax0\.plot\(/m ), 2,
		'multi-line array form still produces two lines (not mistaken for one)' );

	# the tricky case: 2-element data whose members are 2-element numeric arrays
	# must read as a SINGLE line (x=[1,2], y=[3,4]), not two lines.
	my $amb = gen_py(
		'plot.type'   => 'plot',
		data          => [ [ 1, 2 ], [ 3, 4 ] ],
		'output.file' => outfile('amb.svg'),
	);
	is( count_matches( $amb, qr/^ax0\.plot\(/m ), 1,
		'ambiguous [ [1,2],[3,4] ] reads as a single line' );
	like( $amb, qr/^x = \[1,2\]$/m, 'ambiguous case: x is [1,2]' );
	like( $amb, qr/^y = \[3,4\]$/m, 'ambiguous case: y is [3,4]' );
}

# --- scalar set.options on the single-line form (today's request) ---
{
	my $py = gen_py(
		'plot.type'   => 'plot',
		'show.legend' => 0,
		data          => [ [ 1 .. 5 ], [ 1 .. 5 ] ],
		'set.options' => 'color = "red"',
		'output.file' => outfile('scalar1.svg'),
	);
	like( $py, qr/^ax0\.plot\(x, y , color = "red"\)/m,
		'scalar set.options is applied to the single line' );
}

# --- scalar set.options applies to EVERY line of multi-line array data ---
{
	my $py = gen_py(
		'plot.type'   => 'plot',
		data          => [ [ [ 1 .. 3 ], [ 1 .. 3 ] ], [ [ 1 .. 3 ], [ 3, 2, 1 ] ] ],
		'set.options' => 'linewidth = 2',
		'output.file' => outfile('scalarN.svg'),
	);
	is( count_matches( $py, qr/linewidth = 2/ ), 2,
		'scalar set.options is applied to all lines of array data' );
}

# --- array set.options is positional (one per line) ---
{
	my $py = gen_py(
		'plot.type'   => 'plot',
		data          => [ [ [ 1 .. 3 ], [ 1 .. 3 ] ], [ [ 1 .. 3 ], [ 3, 2, 1 ] ] ],
		'set.options' => [ 'color = "red"', 'color = "blue"' ],
		'output.file' => outfile('arropt.svg'),
	);
	like( $py, qr/color = "red"/,  'array set.options: first line styled' );
	like( $py, qr/color = "blue"/, 'array set.options: second line styled' );
}

# --- backward compatibility: plt({ ... }) hashref and plt( ... ) list ---
{
	my $hashref = gen_py(
		{
			'plot.type'   => 'plot',
			data          => { A => [ [ 1 .. 3 ], [ 1 .. 3 ] ] },
			'output.file' => outfile('bc_hash.svg'),
			execute       => 0,
		}
	);
	# gen_py already adds execute => 0; calling with a single hashref must still work
	like( $hashref, qr/label = 'A'/, 'hashref call: labeled hash data still works' );

	my $list = gen_py(
		'plot.type'   => 'plot',
		data          => { A => [ [ 1 .. 3 ], [ 1 .. 3 ] ] },
		'output.file' => outfile('bc_list.svg'),
	);
	like( $list, qr/label = 'A'/, 'list call: labeled hash data still works' );
}

#
# LAYER 2 - error handling for today's features (no matplotlib needed)
#
dies_like(
	sub {
		plt(
			p => [
				{ 'plot.type' => 'plot', data => [ [ 1, 2 ], [ 1, 2 ] ] },
				[ { 'plot.type' => 'plot', data => [ [ 1, 2 ], [ 1, 2 ] ] } ],
			],
			'output.file' => outfile('e.svg'),
		);
	},
	qr/\bnot a mix\b/,
	'p dies when hashes and arrays are mixed'
);

for my $clash (qw(plot.type data plots add)) {
	dies_like(
		sub {
			plt(
				p => [ { 'plot.type' => 'plot', data => [ [ 1, 2 ], [ 1, 2 ] ] } ],
				$clash         => ( $clash eq 'plot.type' ? 'plot' : [ 1, 2 ] ),
				'output.file'  => outfile('e.svg'),
			);
		},
		qr/cannot be combined with "p"/,
		qq{p dies when combined with "$clash"}
	);
}

dies_like(
	sub { plt( p => [], 'output.file' => outfile('e.svg') ) },
	qr/"p" is empty/,
	'p dies when empty'
);

dies_like(
	sub { plt( p => { foo => 1 }, 'output.file' => outfile('e.svg') ) },
	qr/"p" must be an ARRAY reference/,
	'p dies when not an array reference'
);

dies_like(
	sub {
		plt(
			p             => [ [] ],                # 2-D with an empty inner array
			'output.file' => outfile('e.svg'),
		);
	},
	qr/empty array/,
	'p dies on an empty inner (subplot) array'
);

dies_like(
	sub { plt( 'output.file' ) },                   # odd number of arguments
	qr/odd number of arguments/,
	'plt dies on an odd number of list arguments'
);

dies_like(
	sub {
		plt(
			'plot.type'   => 'plot',
			data          => [ [ 1, 2 ], [ 3, 4 ] ],
			'set.options' => { A => 'color = "red"' },    # hash options + array data
			'output.file' => outfile('e.svg'),
		);
	},
	qr/set\.options.*must be a scalar.*or an array/s,
	'set.options dies when a hash is given with array data'
);

dies_like(
	sub {
		plt(
			'plot.type'   => 'plot',
			data          => [ [ [ 1, 2 ], [ 1, 2 ] ] ],            # one line
			'set.options' => [ 'a', 'b', 'c' ],                     # more options than lines
			'output.file' => outfile('e.svg'),
		);
	},
	qr/sets for options/,
	'set.options dies when there are more option sets than data lines'
);

dies_like(
	sub {
		Matplotlib::Simple::boxplot(
			p             => [ { data => [ [ 1, 2 ], [ 1, 2 ] ] } ],
			'output.file' => outfile('e.svg'),
		);
	},
	qr/"p" is meant for the subroutine "plt"/,
	'single-plot wrappers reject the "p" argument'
);

# ============================================================================
# LAYER 3 - render real SVGs for today's features and validate them
# ============================================================================
SKIP: {
	skip 'matplotlib >= 3.10 not available; skipping render layer', 1
		unless $mpl_available;

	# Each case renders to its own file, then is checked with svg_problem so a
	# failure reports the specific reason the SVG is not good.
	my @cases = (
		[
			'p_1d_overlay',
			p => [
				{ 'plot.type' => 'plot', data => [ [ 1 .. 5 ], [ 1 .. 5 ] ], 'set.options' => 'color = "red"' },
				{ 'plot.type' => 'plot', data => [ [ 1 .. 5 ], [ 5, 4, 3, 2, 1 ] ], 'set.options' => 'color = "blue"' },
			],
		],
		[
			'p_2d_subplots',
			p => [
				[ { 'plot.type' => 'plot', data => [ [ 1 .. 5 ], [ 1 .. 5 ] ] } ],
				[ { 'plot.type' => 'violinplot', data => { A => [ 1 .. 9 ] } } ],
			],
			ncol => 2,
		],
		[
			'simplified_single_line',
			'plot.type' => 'plot',
			data        => [ [ 5 .. 9 ], [ 5 .. 9 ] ],
		],
		[
			'scalar_setoptions',
			'plot.type'   => 'plot',
			'show.legend' => 0,
			data          => [ [ 1 .. 9 ], [ 1 .. 9 ] ],
			'set.options' => 'color = "red"',
		],
	);

	for my $case (@cases) {
		my ( $name, @args ) = @{$case};
		my $svg = outfile("$name.svg");
		lives_ok_t(
			sub { plt( @args, 'output.file' => $svg, execute => 1 ) },
			"render '$name' runs through matplotlib without dying"
		);
		my $why = svg_problem($svg);
		is( $why, '', "render '$name' produced a good SVG"
			. ( $why eq '' ? '' : " ($why)" ) );
		ok( has_provenance($svg), "render '$name' embedded provenance metadata" );
	}

	# the scalar set.options should actually reach matplotlib: a red stroke must
	# appear in the rendered output (version-independent: matplotlib renders
	# color="red" as stroke: #ff0000).
	my $red = outfile('scalar_setoptions.svg');
	like( file2string($red), qr/stroke:\s*#ff0000/i,
		'scalar set.options reaches matplotlib (red stroke present in SVG)' );
}

done_testing();

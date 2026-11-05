#!/usr/bin/env perl

# Breadth coverage for Matplotlib::Simple: drive every plot type (through both
# its wrapper and plt), the major per-type options, the several data shapes, and
# the subplot/twinx/add machinery. The bulk runs with execute => 0, so the Perl
# helper logic that builds the Python is exercised even without matplotlib; a
# final render layer (skipped without matplotlib >= 3.10) confirms a
# representative plot of each type produces a good SVG.

require 5.010;
use strict;
use warnings FATAL => 'all';
use feature 'say';
use File::Temp qw(tempfile tempdir);
use File::Spec;
use Capture::Tiny 'capture';
use Matplotlib::Simple;
# The interpreter the module itself runs: "python3", or on MSWin32 the first of
# python, py -3 and python3 that is Python 3. Asking the module, rather than
# naming python3 here, is what lets a Windows smoker that has Python test the
# module with it instead of skipping; the list is empty when there is none.
my @PY = Matplotlib::Simple::Matplotlib::python_command();
my $PY = join ' ', @PY;
use Test::More;

# ----------------------------------------------------------------------------
# Dependency discovery.
# ----------------------------------------------------------------------------
my $python_version_raw = ( scalar @PY ? do { no warnings 'exec'; qx/$PY --version 2>&1/ } // '' : '' );    # 'exec': see t/16.creator.t
my $python_available = ( $? == 0 && $python_version_raw =~ m/Python\s+3\.\d+/i ) ? 1 : 0;
my $mpl_available = 0;
my $mpl_version   = '';
if ($python_available) {
	my $raw = qx/$PY -c "import matplotlib; print(matplotlib.__version__)" 2>&1/;
	if ( $? == 0 && $raw =~ m/^\s*(\d+)\.(\d+)\.\d+/ ) {
		$mpl_available = ( $1 > 3 || ( $1 == 3 && $2 >= 10 ) ) ? 1 : 0;
		( $mpl_version = $raw ) =~ s/^\s+|\s+$//g;
	}
}
# matplotlib_venn is an optional dependency, needed only by venn_proportional_area
my $venn_available = 0;
if ($python_available) {
	qx/$PY -c "import matplotlib_venn" 2>&1/;
	$venn_available = ( $? == 0 ) ? 1 : 0;
}
diag( $python_available ? "$PY: $python_version_raw" : 'no Python 3 interpreter found' );
diag( $mpl_available ? "matplotlib: $mpl_version (render layer ON)"
	: 'matplotlib >= 3.10 not found (render layer SKIPPED)' );
diag( $venn_available ? 'matplotlib_venn: found'
	: 'matplotlib_venn not found (venn_proportional_area render SKIPPED)' );

# ----------------------------------------------------------------------------
# SVG validation (structural regexes + python well-formedness parse).
# ----------------------------------------------------------------------------
sub file2string {
	my $file = shift;
	open my $fh, '<', $file or return '';
	local $/;
	return <$fh>;
}

sub xml_wellformed_problem {
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
	my $out = qx/$PY "$tname" "$file" 2>&1/;
	$out =~ s/\s+\z//;
	return $out eq 'OK' ? '' : ( $out eq '' ? 'python validation produced no output' : $out );
}

sub svg_problem {
	my ($file) = @_;
	return 'file does not exist'             unless -e $file;
	my $size = -s $file;
	return 'file is empty'                   unless $size;
	return "implausibly small ($size bytes)" if $size < 200;
	my $c = file2string($file);
	return 'no <svg> root carrying the SVG namespace'
		unless $c =~ m{<svg\b[^>]*\bxmlns\s*=\s*(['"])http://www\.w3\.org/2000/svg\1}s;
	return 'no closing </svg> tag (file truncated?)' unless $c =~ m{</svg>\s*\z};
	return 'no drawing content'                      unless $c =~ m{<(?:path|g|image|rect|use)\b};
	my $xml = xml_wellformed_problem($file);
	return $xml if $xml;
	return '';
}

# ----------------------------------------------------------------------------
# Deterministic (generated-python) helpers.
# ----------------------------------------------------------------------------
sub gen_py {    # run plt with execute => 0, return the generated python as text
	my @args = @_;
	my $pyfile =
		( @args == 1 && ref $args[0] eq 'HASH' )
		? plt( { %{ $args[0] }, execute => 0 } )
		: plt( @args, execute => 0 );
	return file2string($pyfile);
}

sub count_matches {
	my ( $text, $re ) = @_;
	my $n = () = $text =~ /$re/g;
	return $n;
}

sub dies_like {
	# Match the exception's message, not the whole exception.
	#
	# The module loads Devel::Confess, which appends a stack trace in which
	# every frame prints its own arguments -- and one of this frame's arguments
	# is $re itself.  Matching "$@" therefore matches the pattern against a copy
	# of the pattern, and every assertion here passes whatever the code does.
	# The trace begins at the first tab-indented line.
	my ( $code, $re, $name ) = @_;
	my $lived = eval { $code->(); 1 };
	return ok( 0, "$name (did not die)" ) if $lived;
	my $message = "$@";
	$message =~ s/\n\t.*\z//s;
	return like( $message, $re, $name );
}

sub lives_ok_t {
	my ( $code, $name ) = @_;
	my $lived = eval { $code->(); 1 };
	diag("died unexpectedly: $@") unless $lived;
	return ok( $lived, $name );
}

my $TMP = tempdir( CLEANUP => 1 );
sub outfile { File::Spec->catfile( $TMP, $_[0] ) }

# ----------------------------------------------------------------------------
# Shared data.
# ----------------------------------------------------------------------------
my @xw = map { $_ / 10 } 1 .. 30;                  # 0.1 .. 3.0
my @yv = map { 2 - 1 / $_ } @xw;
my @t  = map { $_ / 5 } 0 .. 24;                   # 0 .. 4.8
my @g1 = ( 1, 2, 2, 3, 3, 3, 4, 4, 4, 4, 5, 5, 6 );
my @g2 = ( 2, 3, 3, 4, 4, 5, 5, 5, 6, 6, 7 );
my @cx = map { $_ } 1 .. 30;

sub jitter { map { $_ + ( rand() - 0.5 ) } @_ }
sub wide_lines {    # a set of 3 similar (x,y) replicate lines for "wide"
	return [ map { [ [@xw], [ jitter(@yv) ] ] } 1 .. 3 ];
}

my %matrix = (      # symmetric-ish matrix for colored_table
	H => { H => 432, C => 411, N => 386 },
	C => { H => 411, C => 346, N => 305 },
	N => { H => 386, C => 305, N => 167 },
);

# ============================================================================
# 1. Every plot type emits its matplotlib call (execute => 0).
#    Each case is exercised through plt(); the type-specific token pins the
#    correct helper/dispatch branch.
# ============================================================================
my @type_cases = (
	[ 'bar',        qr/\.bar\(/,        plot_type => 'bar',      data => { A => 1, B => 2, C => 3 } ],
	[ 'barh',       qr/\.barh\(/,       plot_type => 'barh',     data => { A => 1, B => 2, C => 3 } ],
	[ 'boxplot',    qr/\.boxplot\(/,    plot_type => 'boxplot',  data => { A => [@g1], B => [@g2] } ],
	[ 'violinplot', qr/\.violinplot\(/, plot_type => 'violinplot', data => { A => [@g1], B => [@g2] } ],
	[ 'hist',       qr/\.hist\(/,       plot_type => 'hist',     data => { A => [@g1], B => [@g2] } ],
	[ 'hist2d',     qr/\.hist2d\(/,     plot_type => 'hist2d',   data => { X => [@xw], Y => [@yv] } ],
	[ 'hexbin',     qr/\.hexbin\(/,     plot_type => 'hexbin',   data => { X => [@xw], Y => [@yv] } ],
	[ 'pie',        qr/\.pie\(/,        plot_type => 'pie',      data => { A => 10, B => 20, C => 30 } ],
	[ 'plot',       qr/\.plot\(/,       plot_type => 'plot',     data => { L => [ [@xw], [@yv] ] } ],
	[ 'scatter',    qr/\.scatter\(/,    plot_type => 'scatter',  data => { A => [@xw], B => [@yv], Z => [@cx] }, color_key => 'Z' ],
	[ 'imshow',     qr/\.imshow\(/,     plot_type => 'imshow',   data => [ [ 1, 2, 3 ], [ 4, 5, 6 ] ] ],
	[ 'colored_table', qr/table_cmap/,  plot_type => 'colored_table', data => { %matrix } ],
	[ 'wide',       qr/base_x = np\.linspace/, plot_type => 'wide', data => wide_lines(), color => 'red' ],
);
for my $case (@type_cases) {
	my ( $name, $re, @args ) = @{$case};
	my $py = gen_py( @args, output_file => outfile("type.$name.svg") );
	like( $py, $re, "plt plot_type => '$name' emits its matplotlib call" );
}

# ============================================================================
# 2. Every exported wrapper works and dispatches to the right helper.
# ============================================================================
{
	my %wrapper_call = (
		bar        => sub { bar(@_) },
		barh       => sub { barh(@_) },
		boxplot    => sub { boxplot(@_) },
		violinplot => sub { violinplot(@_) },
		violin     => sub { violin(@_) },
		hist       => sub { hist(@_) },
		hist2d     => sub { hist2d(@_) },
		hexbin     => sub { hexbin(@_) },
		pie        => sub { pie(@_) },
		plot       => sub { plot(@_) },
		scatter    => sub { scatter(@_) },
		imshow     => sub { imshow(@_) },
		colored_table => sub { colored_table(@_) },
		wide       => sub { wide(@_) },
	);
	my %wrapper_data = (
		bar        => { data => { A => 1, B => 2 } },
		barh       => { data => { A => 1, B => 2 } },
		boxplot    => { data => { A => [@g1] } },
		violinplot => { data => { A => [@g1] } },
		violin     => { data => [@g1] },
		hist       => { data => { A => [@g1] } },
		hist2d     => { data => { X => [@xw], Y => [@yv] } },
		hexbin     => { data => { X => [@xw], Y => [@yv] } },
		pie        => { data => { A => 10, B => 20 } },
		plot       => { data => { L => [ [@xw], [@yv] ] } },
		scatter    => { data => { A => [@xw], B => [@yv], Z => [@cx] }, color_key => 'Z' },
		imshow     => { data => [ [ 1, 2 ], [ 3, 4 ] ] },
		colored_table => { data => { %matrix } },
		wide       => { data => wide_lines(), color => 'red' },
	);
	for my $w ( sort keys %wrapper_call ) {
		lives_ok_t(
			sub {
				$wrapper_call{$w}->(
					%{ $wrapper_data{$w} },
					execute       => 0,
					output_file => outfile("wrap.$w.svg"),
				);
			},
			"wrapper $w() dispatches without dying"
		);
	}
}

# ============================================================================
# 3. Data-shape variants.
# ============================================================================
{
	# single distribution as a bare array (boxplot/hist/violin)
	like( gen_py( plot_type => 'hist',    data => [@g1], output_file => outfile('arr.hist.svg') ),
		qr/\.hist\(/, 'hist accepts a bare array (single distribution)' );
	like( gen_py( plot_type => 'boxplot', data => [@g1], output_file => outfile('arr.box.svg') ),
		qr/\.boxplot\(/, 'boxplot accepts a bare array' );
	like( gen_py( plot_type => 'violin',  data => [@g1], output_file => outfile('arr.vio.svg') ),
		qr/\.violinplot\(/, 'violin accepts a bare array' );

	# plot: simplified single line data => [ \@x, \@y ]
	is( count_matches(
			gen_py( plot_type => 'plot', data => [ [ 5 .. 9 ], [ 5 .. 9 ] ], output_file => outfile('one.line.svg') ),
			qr/^ax0\.plot\(/m ),
		1, 'plot: [ \@x, \@y ] is a single line' );

	# plot: multi-line array data
	is( count_matches(
			gen_py( plot_type => 'plot', data => [ [ [ 1 .. 3 ], [ 1 .. 3 ] ], [ [ 1 .. 3 ], [ 3, 2, 1 ] ] ], output_file => outfile('multi.line.svg') ),
			qr/^ax0\.plot\(/m ),
		2, 'plot: array of lines makes multiple lines' );

	# scatter: multiple sets (hash of hashes)
	like(
		gen_py(
			plot_type => 'scatter',
			data        => {
				S1 => { A => [@xw], B => [@yv] },
				S2 => { A => [ jitter(@xw) ], B => [ jitter(@yv) ] },
			},
			output_file => outfile('scatter.multi.svg'),
		),
		qr/\.scatter\(/, 'scatter accepts multiple sets (hash of hashes)'
	);

	# scatter: one point per set (hash of hashes of numbers), colored on one
	# scale; 0.61 and 0.83 are the smallest and largest R2 of the three sets
	{
		my %points = (
			catboost   => { MAE => 0.41, MSE => 0.30, R2 => 0.83 },
			elasticnet => { MAE => 0.60, MSE => 0.55, R2 => 0.61 },
			lightgbm   => { MAE => 0.45, MSE => 0.33, R2 => 0.80 },
		);
		my $py = gen_py(
			plot_type     => 'scatter',
			data          => \%points,
			set_options => { lightgbm => 'marker = "^", vmin = 0' },
			output_file => outfile('scatter.points.svg'),
		);
		is( count_matches( $py, qr/^x = \[0\.\d+\]$/m ), 3, 'scatter: a set of numbers is drawn as one point' );
		like( $py, qr/c = z, cmap = 'gist_rainbow', vmin = 0\.61, vmax = 0\.83 , label = 'catboost'/,
			'scatter: every set is colored on the range of all sets' );
		like( $py, qr/cmap = 'gist_rainbow' , marker = "\^", vmin = 0, label = 'lightgbm'/,
			"scatter: a set's own vmin replaces the shared range" );
		like( $py, qr/label = 'catboost', marker = 'o'\)/, 'scatter: the first colored set takes the first marker' );
		# lightgbm names "^" itself, so elasticnet skips it and takes the next
		like( $py, qr/label = 'elasticnet', marker = 's'\)/, 'scatter: the next set takes the next marker' );
		is( count_matches( $py, qr/marker = /), 3, 'scatter: a set naming its own marker is given no second one' );
		unlike( gen_py( plot_type => 'scatter', data => { A => { x => 1, y => 2 }, B => { x => 2, y => 1 } }, output_file => outfile('scatter.plain.svg') ),
			qr/marker/, 'scatter: sets told apart by color are given no marker' );
		is( ref $points{catboost}{MAE}, '', 'scatter: the caller\'s numbers are not wrapped in place' );
		dies_like( sub { gen_py( plot_type => 'scatter', data => { A => { x => 1, y => [ 1, 2 ] } }, output_file => outfile('e.svg') ) },
			qr/"x" of set "A" must be an array of numbers, not a scalar/, 'scatter: a set mixing numbers and arrays is refused' );
	}

	# imshow: string data with a stringmap
	like(
		gen_py(
			plot_type => 'imshow',
			data        => [ [ 'H', 'E' ], [ 'C', 'H' ] ],
			stringmap   => { H => 'helix', E => 'strand', C => 'coil' },
			output_file => outfile('imshow.str.svg'),
		),
		qr/\.imshow\(/, 'imshow accepts a string map'
	);
}

# ============================================================================
# 4. Colorbar options (hist2d exposes the full set).
# ============================================================================
{
	my $py = gen_py(
		plot_type       => 'hist2d',
		data            => { X => [@xw], Y => [@yv] },
		cblabel         => 'counts',
		cbdrawedges     => 1,
		cborientation   => 'horizontal',
		cbpad           => 0.02,
		cmap            => 'terrain',
		vmin            => 0,
		vmax            => 10,
		output_file     => outfile('cb.opts.svg'),
	);
	like( $py, qr/colorbar\(/,        'hist2d draws a colorbar' );
	like( $py, qr/terrain/,           'hist2d honors cmap' );

	# cb_logscale switches to a log norm
	like( gen_py( plot_type => 'hist2d', data => { X => [@xw], Y => [@yv] }, cb_logscale => 1, output_file => outfile('cb.log.svg') ),
		qr/LogNorm/, 'hist2d cb_logscale uses LogNorm' );

	# show_colorbar => 0 suppresses it
	unlike( gen_py( plot_type => 'hist2d', data => { X => [@xw], Y => [@yv] }, show_colorbar => 0, output_file => outfile('cb.off.svg') ),
		qr/colorbar\(/, 'hist2d show_colorbar => 0 suppresses the colorbar' );

	# key_order flips the axes
	lives_ok_t( sub {
		plt( plot_type => 'hexbin', data => { X => [@xw], Y => [@yv] }, key_order => [ 'Y', 'X' ], execute => 0, output_file => outfile('keyorder.svg') );
	}, 'hexbin honors key_order' );
}

# ============================================================================
# 5. Titles / labels / legend / axis options.
# ============================================================================
{
	my $py = gen_py(
		plot_type     => 'plot',
		data          => { L => [ [@xw], [@yv] ] },
		title         => 'My Title',
		xlabel        => 'the x',
		ylabel        => 'the y',
		show_legend => 0,
		output_file => outfile('labels.svg'),
	);
	like( $py, qr/set_title\('My Title'\)/, 'title becomes set_title' );
	like( $py, qr/set_xlabel\(/,            'xlabel becomes set_xlabel' );
	like( $py, qr/set_ylabel\(/,            'ylabel becomes set_ylabel' );

	# hlines and set_xlim pass through as plt-method strings
	like(
		gen_py(
			plot_type     => 'plot',
			data          => { L => [ [@xw], [@yv] ] },
			hlines        => "1, $xw[0], $xw[-1], linestyles = 'dashed'",
			set_xlim      => "$xw[0], $xw[-1]",
			show_legend => 0,
			output_file => outfile('hlines.svg'),
		),
		qr/hlines\(/, 'hlines passes through to matplotlib'
	);
}

# ============================================================================
# 6. set_options (scalar / array / per-key hash) and logscale.
# ============================================================================
{
	# scalar set_options on a single line
	like( gen_py( plot_type => 'plot', show_legend => 0, data => [ [ 1 .. 5 ], [ 1 .. 5 ] ], set_options => 'color = "red"', output_file => outfile('so.scalar.svg') ),
		qr/color = "red"/, 'scalar set_options applied to a single line' );

	# scalar set_options broadcast to every line of array data
	is( count_matches(
			gen_py( plot_type => 'plot', data => [ [ [ 1 .. 3 ], [ 1 .. 3 ] ], [ [ 1 .. 3 ], [ 3, 2, 1 ] ] ], set_options => 'linewidth = 2', output_file => outfile('so.broadcast.svg') ),
			qr/linewidth = 2/ ),
		2, 'scalar set_options broadcast to all array lines' );

	# array set_options is positional
	my $pos = gen_py( plot_type => 'plot', data => [ [ [ 1 .. 3 ], [ 1 .. 3 ] ], [ [ 1 .. 3 ], [ 3, 2, 1 ] ] ], set_options => [ 'color = "red"', 'color = "blue"' ], output_file => outfile('so.array.svg') );
	like( $pos, qr/color = "red"/,  'array set_options: first line' );
	like( $pos, qr/color = "blue"/, 'array set_options: second line' );

	# per-key hash set_options on hash data
	like(
		gen_py( plot_type => 'plot', data => { sinL => [ [@t], [ map { sin $_ } @t ] ] }, set_options => { sinL => 'color = "green"' }, show_legend => 0, output_file => outfile('so.hash.svg') ),
		qr/color = "green"/, 'per-key hash set_options applied'
	);

	# logscale on both axes
	like(
		gen_py( plot_type => 'scatter', data => { A => [@xw], B => [@yv], Z => [@cx] }, color_key => 'Z', logscale => [ 'x', 'y' ], output_file => outfile('logscale.svg') ),
		qr/set_[xy]scale\(\s*["']log["']/, 'logscale => [x,y] sets a log scale'
	);
}

# ============================================================================
# 7. add-overlays on a single plot, and twinx.
# ============================================================================
{
	# scatter with an overlaid line via "add"; the overlay draws on the same axis
	my $py = gen_py(
		plot_type => 'scatter',
		data        => { A => [@xw], B => [@yv], Z => [@cx] },
		color_key   => 'Z',
		add         => [
			{ plot_type => 'plot', show_legend => 0, data => { over => [ [@xw], [@yv] ] } },
		],
		output_file => outfile('add.svg'),
	);
	like( $py, qr/\.scatter\(/, 'add: base scatter present' );
	like( $py, qr/\.plot\(/,    'add: overlaid line present on the same axis' );

	# twinx: second line on a twinned y-axis (array form + twinx_args)
	my $tw = gen_py(
		plot_type     => 'plot',
		data          => [ [ [@t], [ map { sin $_ } @t ] ], [ [@t], [ map { exp $_ } @t ] ] ],
		set_options => [ 'color = "blue"', 'color = "red"' ],
		twinx_args    => { 1 => { ylabel => '"exp", color="red"' } },
		output_file => outfile('twinx.svg'),
	);
	like( $tw, qr/twinx\(\)/, 'twinx_args creates a twinned axis' );
}

# ============================================================================
# 8. Subplots (plots array): grid, suptitle, sharex/sharey.
# ============================================================================
{
	my $py = gen_py(
		suptitle => 'Grid',
		sharex   => 1,
		sharey   => 1,
		ncols    => 2,
		plots    => [
			{ plot_type => 'hist',    data => { A => [@g1] }, title => 'a' },
			{ plot_type => 'boxplot', data => { B => [@g2] }, title => 'b' },
		],
		output_file => outfile('grid.svg'),
	);
	like( $py, qr/plt\.subplots\(\s*1\s*,\s*2\b/, 'plots array + ncols=2 makes a 1x2 grid' );
	like( $py, qr/suptitle\(/,                    'suptitle emitted for the figure' );
	like( $py, qr/sharex\s*=\s*1/,                'sharex passed to subplots' );
	# Which axis a subplot lands on is the point here, so the pattern takes the
	# hist call at the start of its line or after an "=": hist's call is
	# assigned to the (counts, edges, patches) tuple its height range is
	# reported from. Either alternative keeps "ax1" from matching in "max1".
	like( $py, qr/(?:^|= )ax0\.hist\(/m,          'first subplot on ax0' );
	like( $py, qr/ax1\.boxplot\(/,                'second subplot on ax1' );
}

# ============================================================================
# 9. The "p" interface under the new (one-element-per-subplot) semantics.
#    (t-p-interface.t covers this exhaustively; these keep it wired here too.)
# ============================================================================
{
	# flat: two hashes => two subplots (auto grid)
	my $flat = gen_py(
		p => [ { plot_type => 'hist', data => { A => [@g1] } }, { plot_type => 'hist', data => { B => [@g2] } } ],
		output_file => outfile('p.flat.svg'),
	);
	like( $flat, qr/(?:^|= )ax0\.hist\(/m, 'p flat: subplot 0 on ax0' );
	like( $flat, qr/(?:^|= )ax1\.hist\(/m, 'p flat: subplot 1 on ax1' );

	# mixed: an inner array is one subplot with overlays
	my $mixed = gen_py(
		p => [
			{ plot_type => 'hist', data => { A => [@g1] } },
			[ { plot_type => 'hist', data => { B => [@g2] } }, { plot_type => 'hist', data => { C => [@g1] } } ],
		],
		ncols         => 1,
		output_file => outfile('p.mixed.svg'),
	);
	is( count_matches( $mixed, qr/(?:^|= )ax1\.hist\(/m ), 2, 'p mixed: inner array overlays two plots on ax1' );
	like( $mixed, qr/plt\.subplots\(\s*2\s*,\s*1\b/, 'p mixed: ncols=1 derives a 2x1 grid' );
}

# ============================================================================
# 9a. hist reports the range of its bin heights on STDOUT.
#
#     The heights are matplotlib's and not this module's: nothing here bins the
#     data, so the range can only be read out of what hist() returns as the
#     figure is drawn, and printed back by plt() from the script's captured
#     STDOUT. Twelve 0s, a 1 and a 2 in three bins stand 12, 1, 1 high, so the
#     range is [1, 12]; 1 .. 8 in two bins is [4, 4].
# ============================================================================
{
	my @spec = (
		p => [
			{ plot_type => 'hist', data => { A => [ (0) x 12, 1, 2 ] }, bins => 3 },
			{ plot_type => 'hist', data => { B => [ 1 .. 8 ] },         bins => 2 },
		],
		ncols => 1,
	);
	my $py = gen_py( @spec, output_file => outfile('hist.range.svg') );
	like( $py, qr/^hist_counts0 = \[\]$/m,            'ax0 opens a list of bin heights' );
	like( $py, qr/^hist_counts0 \+= list\(hist_n\)$/m, 'ax0 keeps what hist returned' );
	like( $py, qr/^\tprint\(f'plot 0 hist range = /m, 'ax0 prints its range' );
	like( $py, qr/^\tprint\(f'plot 1 hist range = /m, 'ax1 prints its own range' );

	# The counts are printed and nothing else: the figure must not change
	# because the range is reported, so nothing may hand them to matplotlib.
	is( count_matches( $py, qr/^.*\bax\d+\.\w+\(.*hist_counts/m ), 0,
		'the bin heights are never passed to matplotlib' );

	SKIP: {
		skip 'matplotlib >= 3.10 not available; skipping the executed range report', 2
			unless $mpl_available;
		# capture, because the report arrives on the suite's own STDOUT.
		my ($stdout) = capture {
			plt( @spec, output_file => outfile('hist.range.run.svg'), execute => 1 );
		};
		like( $stdout, qr/^plot 0 hist range = \[1, 12\]$/m, 'ax0 reports [1, 12]' );
		like( $stdout, qr/^plot 1 hist range = \[4, 4\]$/m,  'ax1 reports [4, 4]' );
	}
}

# ============================================================================
# 10. Error branches specific to the helpers.
# ============================================================================
dies_like( sub { plt( plot_type => 'nope', data => { A => 1 }, output_file => outfile('e.svg') ) },
	qr/\Q"nope" isn't a defined plot_type\E/, 'unknown plot_type dies' );

dies_like( sub { plt( plot_type => 'imshow', data => { A => [ 0, 1 ], B => [ 0, 3 ] }, output_file => outfile('e.svg') ) },
	qr/./, 'imshow rejects a hash (needs a 2-D array)' );

dies_like( sub { plt( data => { A => 1 }, plot_type => 'bar', orientation => 'sideways', output_file => outfile('e.svg') ) },
	qr/./, 'bar rejects an undefined option value' );

dies_like( sub { plt( plot_type => 'bar', output_file => outfile('e.svg') ) },
	qr/./, 'bar without data dies' );

# ============================================================================
# 12. Additional cold branches: alternate forms of the richer features.
# ============================================================================
{
	# wide: hash form with a per-key color hash (array form covered above)
	lives_ok_t( sub {
		plt( plot_type => 'wide',
			data  => { Clinical => wide_lines(), HGI => wide_lines() },
			color => { Clinical => 'blue', HGI => 'green' },
			execute => 0, output_file => outfile('wide.hash.svg') );
	}, 'wide accepts a hash of labelled line-sets with a color hash' );

	# twinx: hash form with twinx_args keyed by the twinned label
	lives_ok_t( sub {
		plt( plot_type => 'plot',
			data => { sin => [ [@t], [ map { sin $_ } @t ] ], expo => [ [@t], [ map { exp $_ } @t ] ] },
			set_options => { sin => 'color = "blue"', expo => 'color = "red"' },
			twinx_args    => { expo => { ylabel => '"exp", color="red"' } },
			execute => 0, output_file => outfile('twinx.hash.svg') );
	}, 'twinx hash form twins on the named key' );

	# grouped bar (hash of hashes) with a single scalar color applied to all
	lives_ok_t( sub {
		plt( plot_type => 'bar',
			data  => { G1 => { A => 1, B => 2 }, G2 => { A => 3, B => 4 } },
			color => 'green',
			execute => 0, output_file => outfile('bar.grouped.svg') );
	}, 'grouped bar (hash of hashes) with a scalar color' );

	# stacked barh
	lives_ok_t( sub {
		plt( plot_type => 'barh', stacked => 1,
			data => { G1 => { A => 1, B => 2 }, G2 => { A => 3, B => 4 } },
			execute => 0, output_file => outfile('barh.stacked.svg') );
	}, 'stacked barh' );

	# colored_table with the full label/mirror/number option set
	lives_ok_t( sub {
		plt( plot_type => 'colored_table',
			data          => { %matrix },
			cblabel       => 'energy',
			col_labels    => [ 'H', 'C', 'N' ],
			row_labels    => [ 'H', 'C', 'N' ],
			mirror        => 1,
			show_numbers=> 1,
			undef_color => 'white',
			execute => 0, output_file => outfile('ctable.full.svg') );
	}, 'colored_table honors labels, mirror, show_numbers, undef_color' );

	# multiple-set scatter with per-set set_options and text annotations
	lives_ok_t( sub {
		plt( plot_type => 'scatter',
			data => {
				X => { A => [@xw], B => [@yv] },
				W => { A => [ jitter(@xw) ], B => [ jitter(@yv) ] },
			},
			set_options => { X => 'marker = "."', W => 'marker = "d"' },
			text          => [ '0.5, 1, "note"' ],
			execute => 0, output_file => outfile('scatter.opts.svg') );
	}, 'multi-set scatter with per-set options and text' );

	# a shared colorbar across two hist2d subplots
	lives_ok_t( sub {
		plt( ncols => 2, shared_colorbar => [ 0, 1 ],
			plots => [
				{ plot_type => 'hist2d', data => { X => [@xw], Y => [@yv] } },
				{ plot_type => 'hist2d', data => { X => [@xw], Y => [@yv] } },
			],
			execute => 0, output_file => outfile('shared.cb.svg') );
	}, 'shared_colorbar across subplots' );

	# imshow with figure scaling and colorbar padding
	lives_ok_t( sub {
		plt( plot_type => 'imshow',
			data   => [ [ 1, 2, 3 ], [ 4, 5, 6 ] ],
			scale  => 1.5, scalex => 1.2, scaley => 1.1, cbpad => 0.02,
			execute => 0, output_file => outfile('imshow.scaled.svg') );
	}, 'imshow honors scale/scalex/scaley/cbpad' );

	# hist with an explicit bins array and legend off
	lives_ok_t( sub {
		plt( plot_type => 'hist',
			data => { A => [@g1] }, bins => [ 0, 2, 4, 6, 8 ], show_legend => 0,
			execute => 0, output_file => outfile('hist.bins.svg') );
	}, 'hist accepts an explicit bins array' );
}

# ============================================================================
# 11. Render layer: one plot of each type through matplotlib, validated.
# ============================================================================
SKIP: {
	skip 'matplotlib >= 3.10 not available; skipping render layer', 1
		unless $mpl_available;

	my @render = (
		[ 'bar',        plot_type => 'bar',      data => { A => 1, B => 2, C => 3 } ],
		[ 'barh',       plot_type => 'barh',     data => { A => 1, B => 2, C => 3 } ],
		[ 'boxplot',    plot_type => 'boxplot',  data => { A => [@g1], B => [@g2] } ],
		[ 'violinplot', plot_type => 'violinplot', data => { A => [@g1], B => [@g2] } ],
		[ 'hist',       plot_type => 'hist',     data => { A => [@g1], B => [@g2] } ],
		[ 'hist2d',     plot_type => 'hist2d',   data => { X => [@xw], Y => [@yv] } ],
		[ 'hexbin',     plot_type => 'hexbin',   data => { X => [@xw], Y => [@yv] } ],
		[ 'pie',        plot_type => 'pie',      data => { A => 10, B => 20, C => 30 } ],
		[ 'plot',       plot_type => 'plot',     data => { L => [ [@xw], [@yv] ] }, show_legend => 0 ],
		[ 'scatter',    plot_type => 'scatter',  data => { A => [@xw], B => [@yv], Z => [@cx] }, color_key => 'Z' ],
		[ 'imshow',     plot_type => 'imshow',   data => [ [ 1, 2, 3 ], [ 4, 5, 6 ] ] ],
		[ 'colored_table', plot_type => 'colored_table', data => { %matrix } ],
		[ 'wide',       plot_type => 'wide',     data => wide_lines(), color => 'red' ],
	);
	for my $case (@render) {
		my ( $name, @args ) = @{$case};
		my $svg = outfile("render.$name.svg");
		lives_ok_t( sub { plt( @args, output_file => $svg, execute => 1 ) },
			"render '$name' runs through matplotlib" );
		my $why = svg_problem($svg);
		is( $why, '', "render '$name' produced a good SVG" . ( $why eq '' ? '' : " ($why)" ) );
	}
}

# ============================================================================
# 12. "wide": the summary must describe the runs it was given.
#
#     Two properties of np.interp used to be taken on trust.  It needs its
#     sample points ascending, so a run whose x descends silently summarised to
#     a flat line; and it holds the end values flat outside them, so a run that
#     stopped short of the group's x range contributed an invented horizontal
#     line to the mean and the standard deviation.  The three runs below are
#     the same straight line y = 2x + 1 entered three ways -- ascending,
#     descending, and covering only the first half of the range -- so a correct
#     summary is that line with a zero-width ribbon, and either bug moves the
#     mean away from it.
# ============================================================================
{
	my @asc  = 0 .. 10;
	my @desc = reverse 0 .. 10;
	my @half = 0 .. 5;
	my $line = sub { [ map { 2 * $_ + 1 } @{ $_[0] } ] };
	my @runs = (
		[ [@asc],  $line->( \@asc ) ],
		[ [@desc], $line->( \@desc ) ],
		[ [@half], $line->( \@half ) ],
	);

	my $py = gen_py( plot_type => 'wide', data => [@runs], color => 'red',
		output_file => outfile('wide.guards.svg') );
	like( $py, qr/np\.argsort\(x, kind = 'stable'\)/,
		'wide: each run is sorted by x before it is interpolated' );
	like( $py, qr/np\.interp\(base_x, x, y, left = np\.nan, right = np\.nan\)/,
		'wide: a run contributes nothing outside its own x range' );

	SKIP: {
		skip 'matplotlib >= 3.10 not available; skipping the wide summary check', 2
			unless $mpl_available;
		# Run the generated script and read the summary back out of it: the
		# arrays are module-level names, so exec'ing the file exposes them.
		my $check = <<'CHECK_PY';
import sys, numpy as np
g = {}
exec(open(sys.argv[1], encoding='utf-8').read(), g)
bx, mean, sd = g['base_x'], g['mean_ys'], g['std']
print('%.6e %.6e' % (np.max(np.abs(mean - (2 * bx + 1))), np.max(np.abs(sd))))
CHECK_PY
		my ( $cfh, $cname ) = tempfile( SUFFIX => '.py', UNLINK => 1 );
		print {$cfh} $check;
		close $cfh;
		my $pyfile = plt( plot_type => 'wide', data => [@runs], color => 'red',
			execute => 0, output_file => outfile('wide.summary.svg') );
		my $said = qx/$PY "$cname" "$pyfile" 2>&1/;
		my ( $mean_err, $sd_max ) = $said =~ m/^([\d.e+-]+)\s+([\d.e+-]+)/;
		$mean_err = defined $mean_err ? $mean_err : 'nan';
		$sd_max   = defined $sd_max   ? $sd_max   : 'nan';
		# 1e-9 is far above the ~1e-15 double rounding of a linear interpolation
		# and far below the ~1 unit error either bug produced
		cmp_ok( $mean_err, '<', 1e-9, 'wide: the mean tracks the line the runs describe' )
			or diag("python said: $said");
		cmp_ok( $sd_max, '<', 1e-9, 'wide: identical runs give a zero-width ribbon' )
			or diag("python said: $said");
	}
}

# ============================================================================
# 13. "wide": malformed runs die naming the group, not deep inside the writer.
# ============================================================================
{
	my $wide = sub {
		my (%args) = @_;
		return sub {
			plt( plot_type => 'wide', %args,
				execute => 0, output_file => outfile('wide.dies.svg') );
		};
	};
	dies_like( $wide->( data => { A => [ [@xw], [@yv] ] } ),
		qr/run 0 of group "A" must be/,
		'wide: a lone [x,y] pair where a group belongs dies naming the group' );
	dies_like( $wide->( data => { A => [] } ),
		qr/group "A" holds no runs/,
		'wide: an empty group dies naming the group' );
	dies_like( $wide->( data => [ [ [ 1, 2, 3 ], [ 1, 2 ] ] ] ),
		qr/3 x values but 2 y values/,
		'wide: mismatched x and y lengths die with both counts' );
	dies_like( $wide->( data => [ [ [ 1, 2 ], [ 'a', 'b' ] ] ] ),
		qr/non-numeric y value/,
		'wide: non-numeric data dies before it reaches python' );
	dies_like( $wide->( data => { A => wide_lines() }, color => 'red' ),
		qr/"color" must be a HASH/,
		'wide: hash data with a single color dies clearly' );
	dies_like( $wide->( data => wide_lines(), color => { A => 'red' } ),
		qr/"color" must be a single color/,
		'wide: array data with a color hash dies clearly' );
}

done_testing();

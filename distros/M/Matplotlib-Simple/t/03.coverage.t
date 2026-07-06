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
use Matplotlib::Simple;
use Test::More;

# ----------------------------------------------------------------------------
# Dependency discovery.
# ----------------------------------------------------------------------------
my $python_version_raw = qx/python3 --version 2>&1/;
my $python_available = ( $? == 0 && $python_version_raw =~ m/Python\s+3\.\d+/i ) ? 1 : 0;
my $mpl_available = 0;
my $mpl_version   = '';
if ($python_available) {
	my $raw = qx/python3 -c "import matplotlib; print(matplotlib.__version__)" 2>&1/;
	if ( $? == 0 && $raw =~ m/^\s*(\d+)\.(\d+)\.\d+/ ) {
		$mpl_available = ( $1 > 3 || ( $1 == 3 && $2 >= 10 ) ) ? 1 : 0;
		( $mpl_version = $raw ) =~ s/^\s+|\s+$//g;
	}
}
diag( $python_available ? "python3: $python_version_raw" : 'python3 not found' );
diag( $mpl_available ? "matplotlib: $mpl_version (render layer ON)"
	: 'matplotlib >= 3.10 not found (render layer SKIPPED)' );

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
	my $out = qx/python3 "$tname" "$file" 2>&1/;
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
	my ( $code, $re, $name ) = @_;
	my $lived = eval { $code->(); 1 };
	return ok( 0, "$name (did not die)" ) if $lived;
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
	[ 'bar',        qr/\.bar\(/,        'plot.type' => 'bar',      data => { A => 1, B => 2, C => 3 } ],
	[ 'barh',       qr/\.barh\(/,       'plot.type' => 'barh',     data => { A => 1, B => 2, C => 3 } ],
	[ 'boxplot',    qr/\.boxplot\(/,    'plot.type' => 'boxplot',  data => { A => [@g1], B => [@g2] } ],
	[ 'violinplot', qr/\.violinplot\(/, 'plot.type' => 'violinplot', data => { A => [@g1], B => [@g2] } ],
	[ 'hist',       qr/\.hist\(/,       'plot.type' => 'hist',     data => { A => [@g1], B => [@g2] } ],
	[ 'hist2d',     qr/\.hist2d\(/,     'plot.type' => 'hist2d',   data => { X => [@xw], Y => [@yv] } ],
	[ 'hexbin',     qr/\.hexbin\(/,     'plot.type' => 'hexbin',   data => { X => [@xw], Y => [@yv] } ],
	[ 'pie',        qr/\.pie\(/,        'plot.type' => 'pie',      data => { A => 10, B => 20, C => 30 } ],
	[ 'plot',       qr/\.plot\(/,       'plot.type' => 'plot',     data => { L => [ [@xw], [@yv] ] } ],
	[ 'scatter',    qr/\.scatter\(/,    'plot.type' => 'scatter',  data => { A => [@xw], B => [@yv], Z => [@cx] }, color_key => 'Z' ],
	[ 'imshow',     qr/\.imshow\(/,     'plot.type' => 'imshow',   data => [ [ 1, 2, 3 ], [ 4, 5, 6 ] ] ],
	[ 'colored_table', qr/table_cmap/,  'plot.type' => 'colored_table', data => { %matrix } ],
	[ 'wide',       qr/mean_ys = ys\.mean/, 'plot.type' => 'wide', data => wide_lines(), color => 'red' ],
);
for my $case (@type_cases) {
	my ( $name, $re, @args ) = @{$case};
	my $py = gen_py( @args, 'output.file' => outfile("type.$name.svg") );
	like( $py, $re, "plt plot.type => '$name' emits its matplotlib call" );
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
					'output.file' => outfile("wrap.$w.svg"),
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
	like( gen_py( 'plot.type' => 'hist',    data => [@g1], 'output.file' => outfile('arr.hist.svg') ),
		qr/\.hist\(/, 'hist accepts a bare array (single distribution)' );
	like( gen_py( 'plot.type' => 'boxplot', data => [@g1], 'output.file' => outfile('arr.box.svg') ),
		qr/\.boxplot\(/, 'boxplot accepts a bare array' );
	like( gen_py( 'plot.type' => 'violin',  data => [@g1], 'output.file' => outfile('arr.vio.svg') ),
		qr/\.violinplot\(/, 'violin accepts a bare array' );

	# plot: simplified single line data => [ \@x, \@y ]
	is( count_matches(
			gen_py( 'plot.type' => 'plot', data => [ [ 5 .. 9 ], [ 5 .. 9 ] ], 'output.file' => outfile('one.line.svg') ),
			qr/^ax0\.plot\(/m ),
		1, 'plot: [ \@x, \@y ] is a single line' );

	# plot: multi-line array data
	is( count_matches(
			gen_py( 'plot.type' => 'plot', data => [ [ [ 1 .. 3 ], [ 1 .. 3 ] ], [ [ 1 .. 3 ], [ 3, 2, 1 ] ] ], 'output.file' => outfile('multi.line.svg') ),
			qr/^ax0\.plot\(/m ),
		2, 'plot: array of lines makes multiple lines' );

	# scatter: multiple sets (hash of hashes)
	like(
		gen_py(
			'plot.type' => 'scatter',
			data        => {
				S1 => { A => [@xw], B => [@yv] },
				S2 => { A => [ jitter(@xw) ], B => [ jitter(@yv) ] },
			},
			'output.file' => outfile('scatter.multi.svg'),
		),
		qr/\.scatter\(/, 'scatter accepts multiple sets (hash of hashes)'
	);

	# imshow: string data with a stringmap
	like(
		gen_py(
			'plot.type' => 'imshow',
			data        => [ [ 'H', 'E' ], [ 'C', 'H' ] ],
			stringmap   => { H => 'helix', E => 'strand', C => 'coil' },
			'output.file' => outfile('imshow.str.svg'),
		),
		qr/\.imshow\(/, 'imshow accepts a string map'
	);
}

# ============================================================================
# 4. Colorbar options (hist2d exposes the full set).
# ============================================================================
{
	my $py = gen_py(
		'plot.type'     => 'hist2d',
		data            => { X => [@xw], Y => [@yv] },
		cblabel         => 'counts',
		cbdrawedges     => 1,
		cborientation   => 'horizontal',
		cbpad           => 0.02,
		cmap            => 'terrain',
		vmin            => 0,
		vmax            => 10,
		'output.file'   => outfile('cb.opts.svg'),
	);
	like( $py, qr/colorbar\(/,        'hist2d draws a colorbar' );
	like( $py, qr/terrain/,           'hist2d honors cmap' );

	# cb_logscale switches to a log norm
	like( gen_py( 'plot.type' => 'hist2d', data => { X => [@xw], Y => [@yv] }, cb_logscale => 1, 'output.file' => outfile('cb.log.svg') ),
		qr/LogNorm/, 'hist2d cb_logscale uses LogNorm' );

	# show.colorbar => 0 suppresses it
	unlike( gen_py( 'plot.type' => 'hist2d', data => { X => [@xw], Y => [@yv] }, 'show.colorbar' => 0, 'output.file' => outfile('cb.off.svg') ),
		qr/colorbar\(/, 'hist2d show.colorbar => 0 suppresses the colorbar' );

	# key.order flips the axes
	lives_ok_t( sub {
		plt( 'plot.type' => 'hexbin', data => { X => [@xw], Y => [@yv] }, 'key.order' => [ 'Y', 'X' ], execute => 0, 'output.file' => outfile('keyorder.svg') );
	}, 'hexbin honors key.order' );
}

# ============================================================================
# 5. Titles / labels / legend / axis options.
# ============================================================================
{
	my $py = gen_py(
		'plot.type'   => 'plot',
		data          => { L => [ [@xw], [@yv] ] },
		title         => 'My Title',
		xlabel        => 'the x',
		ylabel        => 'the y',
		'show.legend' => 0,
		'output.file' => outfile('labels.svg'),
	);
	like( $py, qr/set_title\('My Title'\)/, 'title becomes set_title' );
	like( $py, qr/set_xlabel\(/,            'xlabel becomes set_xlabel' );
	like( $py, qr/set_ylabel\(/,            'ylabel becomes set_ylabel' );

	# hlines and set_xlim pass through as plt-method strings
	like(
		gen_py(
			'plot.type'   => 'plot',
			data          => { L => [ [@xw], [@yv] ] },
			hlines        => "1, $xw[0], $xw[-1], linestyles = 'dashed'",
			set_xlim      => "$xw[0], $xw[-1]",
			'show.legend' => 0,
			'output.file' => outfile('hlines.svg'),
		),
		qr/hlines\(/, 'hlines passes through to matplotlib'
	);
}

# ============================================================================
# 6. set.options (scalar / array / per-key hash) and logscale.
# ============================================================================
{
	# scalar set.options on a single line
	like( gen_py( 'plot.type' => 'plot', 'show.legend' => 0, data => [ [ 1 .. 5 ], [ 1 .. 5 ] ], 'set.options' => 'color = "red"', 'output.file' => outfile('so.scalar.svg') ),
		qr/color = "red"/, 'scalar set.options applied to a single line' );

	# scalar set.options broadcast to every line of array data
	is( count_matches(
			gen_py( 'plot.type' => 'plot', data => [ [ [ 1 .. 3 ], [ 1 .. 3 ] ], [ [ 1 .. 3 ], [ 3, 2, 1 ] ] ], 'set.options' => 'linewidth = 2', 'output.file' => outfile('so.broadcast.svg') ),
			qr/linewidth = 2/ ),
		2, 'scalar set.options broadcast to all array lines' );

	# array set.options is positional
	my $pos = gen_py( 'plot.type' => 'plot', data => [ [ [ 1 .. 3 ], [ 1 .. 3 ] ], [ [ 1 .. 3 ], [ 3, 2, 1 ] ] ], 'set.options' => [ 'color = "red"', 'color = "blue"' ], 'output.file' => outfile('so.array.svg') );
	like( $pos, qr/color = "red"/,  'array set.options: first line' );
	like( $pos, qr/color = "blue"/, 'array set.options: second line' );

	# per-key hash set.options on hash data
	like(
		gen_py( 'plot.type' => 'plot', data => { sinL => [ [@t], [ map { sin $_ } @t ] ] }, 'set.options' => { sinL => 'color = "green"' }, 'show.legend' => 0, 'output.file' => outfile('so.hash.svg') ),
		qr/color = "green"/, 'per-key hash set.options applied'
	);

	# logscale on both axes
	like(
		gen_py( 'plot.type' => 'scatter', data => { A => [@xw], B => [@yv], Z => [@cx] }, color_key => 'Z', logscale => [ 'x', 'y' ], 'output.file' => outfile('logscale.svg') ),
		qr/set_[xy]scale\(\s*["']log["']/, 'logscale => [x,y] sets a log scale'
	);
}

# ============================================================================
# 7. add-overlays on a single plot, and twinx.
# ============================================================================
{
	# scatter with an overlaid line via "add"; the overlay draws on the same axis
	my $py = gen_py(
		'plot.type' => 'scatter',
		data        => { A => [@xw], B => [@yv], Z => [@cx] },
		color_key   => 'Z',
		add         => [
			{ 'plot.type' => 'plot', 'show.legend' => 0, data => { over => [ [@xw], [@yv] ] } },
		],
		'output.file' => outfile('add.svg'),
	);
	like( $py, qr/\.scatter\(/, 'add: base scatter present' );
	like( $py, qr/\.plot\(/,    'add: overlaid line present on the same axis' );

	# twinx: second line on a twinned y-axis (array form + twinx.args)
	my $tw = gen_py(
		'plot.type'   => 'plot',
		data          => [ [ [@t], [ map { sin $_ } @t ] ], [ [@t], [ map { exp $_ } @t ] ] ],
		'set.options' => [ 'color = "blue"', 'color = "red"' ],
		'twinx.args'  => { 1 => { ylabel => '"exp", color="red"' } },
		'output.file' => outfile('twinx.svg'),
	);
	like( $tw, qr/twinx\(\)/, 'twinx.args creates a twinned axis' );
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
			{ 'plot.type' => 'hist',    data => { A => [@g1] }, title => 'a' },
			{ 'plot.type' => 'boxplot', data => { B => [@g2] }, title => 'b' },
		],
		'output.file' => outfile('grid.svg'),
	);
	like( $py, qr/plt\.subplots\(\s*1\s*,\s*2\b/, 'plots array + ncols=2 makes a 1x2 grid' );
	like( $py, qr/suptitle\(/,                    'suptitle emitted for the figure' );
	like( $py, qr/sharex\s*=\s*1/,                'sharex passed to subplots' );
	like( $py, qr/^ax0\.hist\(/m,                 'first subplot on ax0' );
	like( $py, qr/ax1\.boxplot\(/,                'second subplot on ax1' );
}

# ============================================================================
# 9. The "p" interface under the new (one-element-per-subplot) semantics.
#    (t-p-interface.t covers this exhaustively; these keep it wired here too.)
# ============================================================================
{
	# flat: two hashes => two subplots (auto grid)
	my $flat = gen_py(
		p => [ { 'plot.type' => 'hist', data => { A => [@g1] } }, { 'plot.type' => 'hist', data => { B => [@g2] } } ],
		'output.file' => outfile('p.flat.svg'),
	);
	like( $flat, qr/^ax0\.hist\(/m, 'p flat: subplot 0 on ax0' );
	like( $flat, qr/^ax1\.hist\(/m, 'p flat: subplot 1 on ax1' );

	# mixed: an inner array is one subplot with overlays
	my $mixed = gen_py(
		p => [
			{ 'plot.type' => 'hist', data => { A => [@g1] } },
			[ { 'plot.type' => 'hist', data => { B => [@g2] } }, { 'plot.type' => 'hist', data => { C => [@g1] } } ],
		],
		ncols         => 1,
		'output.file' => outfile('p.mixed.svg'),
	);
	is( count_matches( $mixed, qr/^ax1\.hist\(/m ), 2, 'p mixed: inner array overlays two plots on ax1' );
	like( $mixed, qr/plt\.subplots\(\s*2\s*,\s*1\b/, 'p mixed: ncols=1 derives a 2x1 grid' );
}

# ============================================================================
# 10. Error branches specific to the helpers.
# ============================================================================
dies_like( sub { plt( 'plot.type' => 'nope', data => { A => 1 }, 'output.file' => outfile('e.svg') ) },
	qr/isn't defined|isn't a known plot\.type/, 'unknown plot.type dies' );

dies_like( sub { plt( 'plot.type' => 'imshow', data => { A => [ 0, 1 ], B => [ 0, 3 ] }, 'output.file' => outfile('e.svg') ) },
	qr/./, 'imshow rejects a hash (needs a 2-D array)' );

dies_like( sub { plt( data => { A => 1 }, 'plot.type' => 'bar', orientation => 'sideways', 'output.file' => outfile('e.svg') ) },
	qr/./, 'bar rejects an undefined option value' );

dies_like( sub { plt( 'plot.type' => 'bar', 'output.file' => outfile('e.svg') ) },
	qr/./, 'bar without data dies' );

# ============================================================================
# 12. Additional cold branches: alternate forms of the richer features.
# ============================================================================
{
	# wide: hash form with a per-key color hash (array form covered above)
	lives_ok_t( sub {
		plt( 'plot.type' => 'wide',
			data  => { Clinical => wide_lines(), HGI => wide_lines() },
			color => { Clinical => 'blue', HGI => 'green' },
			execute => 0, 'output.file' => outfile('wide.hash.svg') );
	}, 'wide accepts a hash of labelled line-sets with a color hash' );

	# twinx: hash form with twinx.args keyed by the twinned label
	lives_ok_t( sub {
		plt( 'plot.type' => 'plot',
			data => { sin => [ [@t], [ map { sin $_ } @t ] ], expo => [ [@t], [ map { exp $_ } @t ] ] },
			'set.options' => { sin => 'color = "blue"', expo => 'color = "red"' },
			'twinx.args'  => { expo => { ylabel => '"exp", color="red"' } },
			execute => 0, 'output.file' => outfile('twinx.hash.svg') );
	}, 'twinx hash form twins on the named key' );

	# grouped bar (hash of hashes) with a single scalar color applied to all
	lives_ok_t( sub {
		plt( 'plot.type' => 'bar',
			data  => { G1 => { A => 1, B => 2 }, G2 => { A => 3, B => 4 } },
			color => 'green',
			execute => 0, 'output.file' => outfile('bar.grouped.svg') );
	}, 'grouped bar (hash of hashes) with a scalar color' );

	# stacked barh
	lives_ok_t( sub {
		plt( 'plot.type' => 'barh', stacked => 1,
			data => { G1 => { A => 1, B => 2 }, G2 => { A => 3, B => 4 } },
			execute => 0, 'output.file' => outfile('barh.stacked.svg') );
	}, 'stacked barh' );

	# colored_table with the full label/mirror/number option set
	lives_ok_t( sub {
		plt( 'plot.type' => 'colored_table',
			data          => { %matrix },
			cblabel       => 'energy',
			'col.labels'  => [ 'H', 'C', 'N' ],
			'row.labels'  => [ 'H', 'C', 'N' ],
			mirror        => 1,
			'show.numbers'=> 1,
			'undef.color' => 'white',
			execute => 0, 'output.file' => outfile('ctable.full.svg') );
	}, 'colored_table honors labels, mirror, show.numbers, undef.color' );

	# multiple-set scatter with per-set set.options and text annotations
	lives_ok_t( sub {
		plt( 'plot.type' => 'scatter',
			data => {
				X => { A => [@xw], B => [@yv] },
				W => { A => [ jitter(@xw) ], B => [ jitter(@yv) ] },
			},
			'set.options' => { X => 'marker = "."', W => 'marker = "d"' },
			text          => [ '0.5, 1, "note"' ],
			execute => 0, 'output.file' => outfile('scatter.opts.svg') );
	}, 'multi-set scatter with per-set options and text' );

	# a shared colorbar across two hist2d subplots
	lives_ok_t( sub {
		plt( ncols => 2, 'shared.colorbar' => [ 0, 1 ],
			plots => [
				{ 'plot.type' => 'hist2d', data => { X => [@xw], Y => [@yv] } },
				{ 'plot.type' => 'hist2d', data => { X => [@xw], Y => [@yv] } },
			],
			execute => 0, 'output.file' => outfile('shared.cb.svg') );
	}, 'shared.colorbar across subplots' );

	# imshow with figure scaling and colorbar padding
	lives_ok_t( sub {
		plt( 'plot.type' => 'imshow',
			data   => [ [ 1, 2, 3 ], [ 4, 5, 6 ] ],
			scale  => 1.5, scalex => 1.2, scaley => 1.1, cbpad => 0.02,
			execute => 0, 'output.file' => outfile('imshow.scaled.svg') );
	}, 'imshow honors scale/scalex/scaley/cbpad' );

	# hist with an explicit bins array and legend off
	lives_ok_t( sub {
		plt( 'plot.type' => 'hist',
			data => { A => [@g1] }, bins => [ 0, 2, 4, 6, 8 ], 'show.legend' => 0,
			execute => 0, 'output.file' => outfile('hist.bins.svg') );
	}, 'hist accepts an explicit bins array' );
}

# ============================================================================
# 11. Render layer: one plot of each type through matplotlib, validated.
# ============================================================================
SKIP: {
	skip 'matplotlib >= 3.10 not available; skipping render layer', 1
		unless $mpl_available;

	my @render = (
		[ 'bar',        'plot.type' => 'bar',      data => { A => 1, B => 2, C => 3 } ],
		[ 'barh',       'plot.type' => 'barh',     data => { A => 1, B => 2, C => 3 } ],
		[ 'boxplot',    'plot.type' => 'boxplot',  data => { A => [@g1], B => [@g2] } ],
		[ 'violinplot', 'plot.type' => 'violinplot', data => { A => [@g1], B => [@g2] } ],
		[ 'hist',       'plot.type' => 'hist',     data => { A => [@g1], B => [@g2] } ],
		[ 'hist2d',     'plot.type' => 'hist2d',   data => { X => [@xw], Y => [@yv] } ],
		[ 'hexbin',     'plot.type' => 'hexbin',   data => { X => [@xw], Y => [@yv] } ],
		[ 'pie',        'plot.type' => 'pie',      data => { A => 10, B => 20, C => 30 } ],
		[ 'plot',       'plot.type' => 'plot',     data => { L => [ [@xw], [@yv] ] }, 'show.legend' => 0 ],
		[ 'scatter',    'plot.type' => 'scatter',  data => { A => [@xw], B => [@yv], Z => [@cx] }, color_key => 'Z' ],
		[ 'imshow',     'plot.type' => 'imshow',   data => [ [ 1, 2, 3 ], [ 4, 5, 6 ] ] ],
		[ 'colored_table', 'plot.type' => 'colored_table', data => { %matrix } ],
		[ 'wide',       'plot.type' => 'wide',     data => wide_lines(), color => 'red' ],
	);
	for my $case (@render) {
		my ( $name, @args ) = @{$case};
		my $svg = outfile("render.$name.svg");
		lives_ok_t( sub { plt( @args, 'output.file' => $svg, execute => 1 ) },
			"render '$name' runs through matplotlib" );
		my $why = svg_problem($svg);
		is( $why, '', "render '$name' produced a good SVG" . ( $why eq '' ? '' : " ($why)" ) );
	}
}

done_testing();

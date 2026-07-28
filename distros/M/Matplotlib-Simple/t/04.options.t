#!/usr/bin/env perl
#
# The option contract of every plot type.
#
# t/03.coverage.t exercises each plot type and its richer features; this file
# asks a narrower question about every option the documentation advertises:
#
#   1. is it accepted at all?                       (a rejected option dies)
#   2. does it actually reach the generated python? (an ignored option is a lie)
#   3. is it rejected by the plot types that do NOT list it?
#
# Question 1 is the one that matters most: because an option is validated
# against a per-plot-type list, an option that is documented but missing from
# that list does not degrade gracefully -- it dies, and it dies for everyone who
# copies the documentation.  Options in this position have shipped before
# (`whiskers` documented for boxplot but only implemented for violin;
# `log` documented for violin and hist, which only accept `logscale`), so the
# whole advertised surface is enumerated here rather than sampled.
#
# Question 2 catches the mirror image: an option on the accepted list that no
# helper ever reads, which is silently ignored instead of refused.
#
# Known-broken cases are marked TODO rather than deleted, so that the suite
# records them without failing, and reports "unexpectedly succeeded" the moment
# one is fixed.
#
require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Temp 'tempdir';
use File::Spec;
use Capture::Tiny 'capture';
use Matplotlib::Simple;
use Test::More;

our $TODO;

# ----------------------------------------------------------------------------
# Helpers.
# ----------------------------------------------------------------------------
my $TMP = tempdir( CLEANUP => 1 );
my $seq = 0;

sub file2string {
	my ($file) = @_;
	open my $fh, '<', $file or die "can't read $file: $!";
	local $/;
	my $text = <$fh>;
	close $fh;
	return defined $text ? $text : '';
}

# Build one figure with execute => 0 and hand back the generated python.  The
# module chatters on STDOUT for some plot types (hist2d prints its density
# range), so the call is captured to keep the TAP stream clean.
sub gen_py {
	my (%spec) = @_;
	$spec{'output.file'} = File::Spec->catfile( $TMP, 'opt' . $seq++ . '.svg' );
	$spec{execute} = 0;
	my ( $out, $err, $pyfile ) = capture { plt( \%spec ) };
	return defined $pyfile && -e $pyfile ? file2string($pyfile) : '';
}

# Build a figure, returning ($ok, $error_or_python).
sub try_py {
	my (%spec) = @_;
	my $py = '';
	my $lived = eval { $py = gen_py(%spec); 1 };
	return $lived ? ( 1, $py ) : ( 0, $@ );
}

# ----------------------------------------------------------------------------
# Minimal valid data for each plot type.
# ----------------------------------------------------------------------------
my @g1 = ( 1, 2, 2, 3, 3, 3, 4, 4, 4, 4, 5, 5, 6 );
my @g2 = ( 2, 3, 3, 4, 4, 5, 5, 5, 6, 6, 7 );
my @cx = map { $_ }            1 .. 40;
my @cy = map { $_ % 7 }        1 .. 40;
my @xs = map { $_ }            1 .. 10;

my %grid;    # a 2-D array for imshow
my @grid = map { my $i = $_; [ map { $i * $_ } 1 .. 8 ] } 1 .. 8;

my %runs = (    # replicate lines for "wide"
	A => [ map { my $n = $_; [ [@xs], [ map { $_ + $n } @xs ] ] } 1 .. 3 ],
	B => [ map { my $n = $_; [ [@xs], [ map { $_ - $n } @xs ] ] } 1 .. 3 ],
);

# Deliberately incomplete: with rows and columns taken from the outer keys
# (C, H), the cell H/C has no value, which is what exercises the undefined-cell
# branch -- "undef.color", "mirror" and "default_undefined" all hang off it.
my %matrix = (
	H => { H => 432 },
	C => { H => 411, C => 346 },
);

my %DATA = (
	bar           => { A => 1, B => 2, C => 3 },
	barh          => { A => 1, B => 2, C => 3 },
	grouped       => { 1941 => [ 1, 2 ], 1942 => [ 3, 4 ] },
	boxplot       => { A => [@g1], B => [@g2] },
	violinplot    => { A => [@g1], B => [@g2] },
	colored_table => \%matrix,
	hexbin        => { X => [@cx], Y => [@cy] },
	hist          => { A => [@g1], B => [@g2] },
	hist2d        => { X => [@cx], Y => [@cy] },
	imshow        => \@grid,
	pie           => { A => 1, B => 2, C => 3 },
	plot          => {
		A => [ [@xs], [@xs] ],
		B => [ [@xs], [ reverse @xs ] ],
	},
	scatter       => { X => [@cx], Y => [@cy], Z => [ map { $_ % 3 } @cx ] },
	venn_proportional_area => {
		Left  => [qw(a b c d)],
		Right => [qw(c d e)],
	},
	wide          => \%runs,
);

# ----------------------------------------------------------------------------
# The advertised option surface.
#
# Each case is [ option => value ], optionally with:
#   want        => qr//  the option must leave this mark on the generated python
#   want_not    => qr//  ... or must remove this one
#   data        => ref   use this instead of the plot type's default data
#   with        => {}    extra options the case needs to be meaningful
#   todo        => '..'  the option is not accepted yet: expected to fail
#   todo_effect => '..'  it is accepted but ignored: the effect check fails
#
# The two TODO fields are deliberately separate.  An option that is refused and
# an option that is accepted-then-ignored are different bugs, and marking the
# whole case TODO for either one would make the other assertion report
# "unexpectedly succeeded" -- which reads like a fix that has not happened.
# ----------------------------------------------------------------------------
my %OPTIONS = (
	bar => [
		{ opt => 'color',       val => 'red' },
		{ opt => 'color',       val => [ 'red', 'gray' ],  data => $DATA{grouped} },
		{ opt => 'color',       val => { A => 'red', B => 'green', C => 'blue' } },
		{ opt => 'edgecolor',   val => 'black' },
		{ opt => 'key.order',   val => [qw(C B A)] },
		{ opt => 'label',       val => [ 'UK', 'US' ],     data => $DATA{grouped} },
		{ opt => 'linewidth',   val => 2, with => { edgecolor => 'black' } },
		{ opt => 'log',         val => 'True' },
		{ opt => 'logscale',    val => 1 },
		{ opt => 'stacked',     val => 1,                  data => $DATA{grouped} },
		{ opt => 'width',       val => 0.4 },
		{ opt => 'yerr',        val => { A => [ 1, 2 ], B => [ 1, 2 ], C => [ 1, 2 ] } },
		{ opt => 'yerr',        val => 1 },
	],
	barh => [
		{ opt => 'xerr',        val => { A => [ 1, 2 ], B => [ 1, 2 ], C => [ 1, 2 ] } },
		{ opt => 'stacked',     val => 1,                  data => $DATA{grouped} },
	],
	boxplot => [
		{ opt => 'color',       val => 'pink' },
		{ opt => 'colors',      val => { A => 'orange', B => 'purple' } },
		{ opt => 'key.order',   val => [qw(B A)] },
		{ opt => 'logscale',    val => ['y'],   want => qr/set_yscale\("log"\)/ },
		{ opt => 'notch',       val => 'True',  want => qr/notch = True/ },
		{ opt => 'orientation', val => 'horizontal', want => qr/orientation = 'horizontal'/ },
		{ opt => 'showcaps',    val => 'False', want => qr/showcaps = False/ },
		{ opt => 'showfliers',  val => 'False', want => qr/showfliers = False/ },
		{ opt => 'showmeans',   val => 'False', want => qr/showmeans = False/ },
	],
	violinplot => [
		{ opt => 'color',       val => 'red' },
		{ opt => 'colors',      val => { A => 'yellow', B => 'purple' } },
		{ opt => 'key.order',   val => [qw(B A)] },
		{ opt => 'logscale',    val => ['y'],   want => qr/set_yscale\("log"\)/ },
		{ opt => 'orientation', val => 'horizontal', want => qr/orientation = 'horizontal'/ },
		{ opt => 'whiskers',    val => 0,       want_not => qr/\.vlines\(/ },
		# read by violin_helper, but absent from its accepted-option list
		{ opt => 'medians',     val => 0, todo => 'medians is read but not an accepted option' },
		{ opt => 'edgecolor',   val => 'red', todo => 'edgecolor is read but not an accepted option' },
	],
	colored_table => [
		{ opt => 'cb_logscale',  val => 1,      want => qr/LogNorm/ },
		{ opt => 'cb_min',       val => 100,    want => qr/vmin = 100/ },
		{ opt => 'cb_max',       val => 500,    want => qr/vmax = 500/ },
		{ opt => 'cblabel',      val => 'kJ/mol', want => qr/label = 'kJ\/mol'/ },
		{ opt => 'cmap',         val => 'viridis', want => qr/viridis/ },
		{ opt => 'col.labels',   val => [qw(H C)] },
		{ opt => 'colorbar.on',  val => 0,      want_not => qr/fig\.colorbar/ },
		{ opt => 'mirror',       val => 1 },
		{ opt => 'row.labels',   val => [qw(H C)] },
		{ opt => 'show.numbers', val => 1,      want => qr/cellText/ },
		{ opt => 'undef.color',  val => 'white', want => qr/set_bad\("white"\)/ },
		# defaulted, but the line that consumed it is commented out
		{ opt => 'default_undefined', val => 0, want_not => qr/np\.nan/,
		  todo_effect => 'default_undefined never replaces the missing cells' },
	],
	hexbin => [
		{ opt => 'cb_logscale',    val => 1,    want => qr/LogNorm/ },
		{ opt => 'cblabel',        val => 'counts', want => qr/label = cblabel/ },
		{ opt => 'cmap',           val => 'jet', want => qr/jet/ },
		{ opt => 'key.order',      val => [qw(Y X)] },
		{ opt => 'marginals',      val => 1,    want => qr/marginals/ },
		{ opt => 'mincnt',         val => 2,    want => qr/mincnt/ },
		{ opt => 'vmin',           val => 0,    want => qr/vmin/ },
		{ opt => 'vmax',           val => 25,   want => qr/vmax/ },
		{ opt => 'xbins',          val => 9 },
		{ opt => 'ybins',          val => 9 },
		{ opt => 'xscale.hexbin',  val => 'log', want => qr/xscale/ },
		{ opt => 'yscale.hexbin',  val => 'log', want => qr/yscale/ },
		{ opt => 'colorbar.on',    val => 0,    want_not => qr/colorbar/,
		  todo_effect => 'hexbin draws its colorbar regardless of colorbar.on' },
	],
	hist => [
		{ opt => 'alpha',       val => 0.25,   want => qr/alpha = 0\.25/ },
		{ opt => 'bins',        val => 5,      want => qr/bins = 5/ },
		{ opt => 'bins',        val => [ 0, 2, 4, 6, 8 ], want => qr/bins = \[0,2,4,6,8\]/ },
		{ opt => 'bins',        val => { A => 5, B => 3 } },
		{ opt => 'color',       val => { A => 'orange', B => 'black' }, want => qr/color = 'orange'/ },
		{ opt => 'color',       val => 'red' },
		{ opt => 'logscale',    val => ['y'],  want => qr/set_yscale\("log"\)/ },
		{ opt => 'orientation', val => 'horizontal', want => qr/orientation/ },
		{ opt => 'show.legend', val => 0,      want_not => qr/label = 'A'/ },
	],
	hist2d => [
		{ opt => 'cb_logscale',   val => 1,     want => qr/LogNorm/ },
		{ opt => 'cblabel',       val => 'n',   want => qr/label = 'n'/ },
		{ opt => 'cmap',          val => 'terrain', want => qr/terrain/ },
		{ opt => 'cmin',          val => 1,     want => qr/cmin/ },
		{ opt => 'cmax',          val => 20,    want => qr/cmax/ },
		{ opt => 'density',       val => 'True', want => qr/density/ },
		{ opt => 'key.order',     val => [qw(Y X)] },
		{ opt => 'logscale',      val => ['x'], want => qr/set_xscale\("log"\)/ },
		{ opt => 'show.colorbar', val => 0,     want_not => qr/colorbar/ },
		{ opt => 'vmin',          val => 0 },
		{ opt => 'vmax',          val => 20 },
		{ opt => 'xbins',         val => 9 },
		{ opt => 'ybins',         val => 9 },
		{ opt => 'xmin',          val => 0,  with => { xmax => 40, ymin => 0, ymax => 10 } },
	],
	imshow => [
		{ opt => 'cblabel',       val => 'value', want => qr/label = 'value'/ },
		{ opt => 'cbdrawedges',   val => 1,     want => qr/drawedges/ },
		{ opt => 'cblocation',    val => 'left', want => qr/location = 'left'/ },
		{ opt => 'cborientation', val => 'horizontal', want => qr/orientation = 'horizontal'/ },
		{ opt => 'cbpad',         val => 0.01,  want => qr/pad = 0\.01/ },
		{ opt => 'cmap',          val => 'coolwarm', want => qr/coolwarm/ },
		{ opt => 'colorbar.on',   val => 0,     want_not => qr/fig\.colorbar/ },
		{ opt => 'vmin',          val => 0,     want => qr/vmin = 0/ },
		{ opt => 'vmax',          val => 10,    want => qr/vmax = 10/ },
		{ opt => 'stringmap',     val => { H => 'helix', T => 'turn' },
		  data => [ [ 'H', 'T' ], [ 'T', 'H' ] ], want => qr/ListedColormap/ },
	],
	pie => [
		{ opt => 'autopct',       val => '%1.1f%%', want => qr/autopct/ },
		{ opt => 'labeldistance', val => 0.6,   want => qr/labeldistance/ },
		{ opt => 'pctdistance',   val => 1.25,  want => qr/pctdistance/ },
		# read by pie_helper, but absent from its accepted-option list
		{ opt => 'key.order',     val => [qw(C B A)],
		  todo => 'key.order is read but not an accepted option' },
	],
	plot => [
		{ opt => 'key.order',   val => [qw(B A)] },
		{ opt => 'logscale',    val => [ 'x', 'y' ], want => qr/set_yscale\("log"\)/ },
		{ opt => 'set.options', val => 'linewidth = 2', want => qr/linewidth = 2/ },
		{ opt => 'set.options', val => { A => 'color = "red"' }, want => qr/color = "red"/ },
		{ opt => 'show.legend', val => 0 },
		{ opt => 'twinx',       val => 'B',    want => qr/twinx\(\)/ },
		{ opt => 'twinx.args',  val => { B => { ylabel => 'other' } },
		  with => { twinx => 'B' }, want => qr/twinx\(\)/ },
	],
	scatter => [
		{ opt => 'cmap',        val => 'viridis', want => qr/viridis/ },
		{ opt => 'color_key',   val => 'Z',    want => qr/c = z/ },
		{ opt => 'keys',        val => [qw(Y X Z)] },
		{ opt => 'logscale',    val => ['y'], want => qr/set_yscale\("log"\)/ },
		{ opt => 'set.options', val => 'marker = "v"', want => qr/marker = "v"/ },
		{ opt => 'cbpad',       val => 0.1,   want => qr/pad = 0\.1/ },
		{ opt => 'cbdrawedges', val => 1,     want => qr/drawedges/ },
	],
	venn_proportional_area => [
		{ opt => 'alpha',      val => 0.5,    want => qr/alpha=0\.5/ },
		{ opt => 'key.order',  val => [qw(Right Left)] },
		{ opt => 'set_colors', val => [qw(skyblue salmon)], want => qr/set_colors=\("skyblue","salmon"\)/ },
	],
	wide => [
		{ opt => 'color',       val => { A => 'blue', B => 'green' }, want => qr/'blue'/ },
		{ opt => 'color',       val => 'red', data => $DATA{wide}{A}, want => qr/'red'/ },
		{ opt => 'show.legend', val => 0,     want_not => qr/label = 'A'/ },
	],
);

# ============================================================================
# 1. Every advertised option is accepted, and leaves its mark.
# ============================================================================
foreach my $type ( sort keys %OPTIONS ) {
	foreach my $case ( @{ $OPTIONS{$type} } ) {
		my $opt   = $case->{opt};
		my $data  = exists $case->{data} ? $case->{data} : $DATA{$type};
		my $label = "$type: $opt";
		$label .= ' (' . ref( $case->{val} ) . ')' if ref $case->{val};

		my ( $ok, $result ) = try_py(
			'plot.type' => $type,
			data        => $data,
			%{ $case->{with} || {} },
			$opt        => $case->{val},
		);
		{
			local $TODO = $case->{todo} if defined $case->{todo};
			if ( !ok( $ok, "$label is accepted" ) ) {
				my ($first) = grep { /\S/ } split /\n/, $result;
				diag("  died: $first") if defined $first && !defined $case->{todo};
			}
		}
		next unless $ok;
		local $TODO = $case->{todo_effect} if defined $case->{todo_effect};
		like( $result, $case->{want}, "$label reaches the generated python" )
			if defined $case->{want};
		unlike( $result, $case->{want_not}, "$label changes the generated python" )
			if defined $case->{want_not};
	}
}

# ============================================================================
# 2. An option belonging to another plot type is refused, not ignored.
#
#    Each of these has been documented for the wrong plot type at some point;
#    the boundary is asserted so that the documentation cannot drift back.
# ============================================================================
my @NOT_ACCEPTED = (
	[ 'boxplot',    'whiskers',    0,       'whiskers belongs to violin' ],
	[ 'violinplot', 'log',         1,       'violin takes logscale, not log' ],
	[ 'hist',       'log',         1,       'hist takes logscale, not log' ],
	[ 'wide',       'logscale',    ['y'],   'wide has no logscale' ],
	[ 'wide',       'key.order',   ['A'],   'wide has no key.order' ],
	[ 'boxplot',    'bins',        5,       'bins belongs to hist' ],
	[ 'pie',        'stacked',     1,       'stacked belongs to bar' ],
	[ 'plot',       'notch',       'True',  'notch belongs to boxplot' ],
);
foreach my $case (@NOT_ACCEPTED) {
	my ( $type, $opt, $val, $why ) = @{$case};
	my ( $ok, $result ) = try_py(
		'plot.type' => $type,
		data        => $DATA{$type},
		$opt        => $val,
	);
	if ($ok) {
		ok( 0, "$type: $opt is refused ($why)" );
	} else {
		like( $result, qr/aren't defined|not recognized|are accepted/,
			"$type: $opt is refused with the list of accepted options ($why)" );
	}
}

# An option that belongs to no plot type at all must die for every type.
foreach my $type ( sort keys %DATA ) {
	next if $type eq 'grouped';    # not a plot type, just a data shape
	my ( $ok, $result ) = try_py(
		'plot.type'      => $type,
		data             => $DATA{$type},
		'not.an.option'  => 1,
	);
	ok( !$ok, "$type: an unknown option dies" );
}

# ============================================================================
# 3. Scalar-versus-array-reference confusion is caught, not miscompiled.
#
#    `logscale` is an array of axis names everywhere except bar, where it is a
#    scalar.  Passing the wrong one used to reach `@{ ... }` and die with a
#    strict-refs message from inside the module rather than a diagnosis.
# ============================================================================
foreach my $type (qw(boxplot violinplot hist scatter plot)) {
	my ( $ok, $result ) = try_py(
		'plot.type' => $type,
		data        => $DATA{$type},
		logscale    => 1,          # should be ['y']
	);
	ok( !$ok, "$type: a scalar logscale is rejected rather than silently ignored" );
}
{
	my ( $ok ) = try_py(
		'plot.type' => 'bar',
		data        => $DATA{bar},
		logscale    => 1,          # bar's logscale really is a scalar
	);
	ok( $ok, 'bar: a scalar logscale is correct for bar' );
}

# ============================================================================
# 4. Data-shape contracts, including the counts that the helpers insist on.
# ============================================================================
my @SHAPES = (
	[ 'hist',    [ 0 .. 9 ],                   1, 'hist accepts a bare array' ],
	[ 'boxplot', [ 0 .. 9 ],                   1, 'boxplot accepts a bare array' ],
	[ 'violinplot', [ 0 .. 9 ],                1, 'violin accepts a bare array' ],
	[ 'imshow',  { A => { B => 1 } },          0, 'imshow rejects a hash' ],
	[ 'scatter', [ 1 .. 5 ],                   0, 'scatter rejects an array' ],
	[ 'scatter', { A => [1], B => [2], C => [3], D => [4] }, 0,
		'scatter rejects 4 keys' ],
	[ 'scatter', { A => [1] },                 0, 'scatter rejects 1 key' ],
	[ 'hexbin',  { A => [ 1 .. 5 ], B => [ 1 .. 5 ], C => [ 1 .. 5 ] }, 0,
		'hexbin rejects 3 keys' ],
	[ 'venn_proportional_area', { A => ['a'], B => ['b'], C => ['c'], D => ['d'] }, 0,
		'venn rejects 4 sets' ],
	[ 'venn_proportional_area', { A => ['a'] }, 0, 'venn rejects 1 set' ],
	[ 'wide',    { A => 1 },                    0, 'wide rejects a scalar group' ],
);
foreach my $case (@SHAPES) {
	my ( $type, $data, $should_live, $name ) = @{$case};
	my ($ok) = try_py( 'plot.type' => $type, data => $data );
	is( $ok ? 1 : 0, $should_live, $name );
}

# ============================================================================
# 5. Errors that name the thing that is wrong.
#
#    These messages are the module's user interface when a call is wrong, so
#    they are pinned: a colour hash that misses a key, a colour column that is
#    not in the data, and string data with no map must each say so.
# ============================================================================
my @MESSAGES = (
	[   'boxplot colors missing a key',
		{ 'plot.type' => 'boxplot', data => $DATA{boxplot}, colors => { A => 'red' } },
		qr/no defined color/,
	],
	[   'violin colors missing a key',
		{ 'plot.type' => 'violinplot', data => $DATA{violinplot}, colors => { A => 'red' } },
		qr/no defined color/,
	],
	[   'scatter color_key that is not in the data',
		{ 'plot.type' => 'scatter', data => { X => [ 1 .. 5 ], Y => [ 1 .. 5 ] },
		  color_key => 'Nope' },
		qr/Nope/,
	],
	[   'scatter multi-set color_key that is not in every set',
		{ 'plot.type' => 'scatter',
		  data => { S => { A => [ 1 .. 5 ], B => [ 1 .. 5 ], C => [ 1 .. 5 ] } },
		  color_key => 'Missing' },
		qr/Missing/,
	],
	[   'imshow string data with no stringmap',
		{ 'plot.type' => 'imshow', data => [ [ 'H', 'T' ], [ 'T', 'H' ] ] },
		qr/translate strings/,
	],
	[   'hist non-numeric data',
		{ 'plot.type' => 'hist', data => { A => [ 1, 'x', 3 ] } },
		qr/non-numeric/,
	],
	[   'boxplot non-numeric data',
		{ 'plot.type' => 'boxplot', data => { A => [ 1, 'x', 3 ] } },
		qr/non-numeric/,
	],
	[   'venn with a non-array set',
		{ 'plot.type' => 'venn_proportional_area', data => { A => 'a', B => 'b' } },
		qr/array reference/,
	],
	[   'key.order that does not match the data',
		{ 'plot.type' => 'venn_proportional_area', data => $DATA{venn_proportional_area},
		  'key.order' => ['Left'] },
		qr/key\.order/,
	],
	[   'unknown plot.type',
		{ 'plot.type' => 'nonesuch', data => { A => 1 } },
		qr/nonesuch/,
	],
);
foreach my $case (@MESSAGES) {
	my ( $name, $spec, $re ) = @{$case};
	my ( $ok, $result ) = try_py( %{$spec} );
	if ($ok) {
		ok( 0, "$name dies (it did not)" );
	} else {
		like( $result, $re, "$name dies with a message naming the problem" );
	}
}

done_testing();

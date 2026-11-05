#!/usr/bin/env perl
#
# The fixes of 0.315, one or more tests each.
#
# Each block below names the bug it pins down.  They came out of a read of the
# whole of lib/Matplotlib/Simple.pm, and each was reproduced against 0.314
# before it was fixed.  Every block has at least one assertion that fails on
# 0.314; the nine that pass there -- a linear colored_table, a comma in a
# suptitle, "bins => 'auto'", a wide group's own color and the like -- guard
# behaviour the fixes had to leave alone.
#
# Most of this is execute => 0 and reads the generated python as text, so it
# runs everywhere, including a Windows smoker with no python.  Three kinds of
# test need more, and skip without it:
#
#  - parses_ok needs python3, as in t/06.escaping.and.validation.t;
#  - run_py needs python3 and matplotlib, because it runs the generated script
#    with a few lines of its own appended, to read back a value matplotlib
#    computed (a whisker, a norm) rather than trusting the text that asked
#    for it.
#
require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Temp 'tempdir';
use File::Spec;
use Capture::Tiny 'capture';
use Storable 'dclone';
use Matplotlib::Simple;
# The interpreter the module itself runs: "python3", or on MSWin32 the first of
# python, py -3 and python3 that is Python 3. Asking the module, rather than
# naming python3 here, is what lets a Windows smoker that has Python test the
# module with it instead of skipping; the list is empty when there is none.
my @PY = Matplotlib::Simple::Matplotlib::python_command();
my $PY = join ' ', @PY;
use Test::More;

my $TMP = tempdir( CLEANUP => 1 );
my $seq = 0;

my $python_raw = ( scalar @PY ? do { no warnings 'exec'; qx/$PY --version 2>&1/ } // '' : '' );    # 'exec': see t/16.creator.t
my $python_available = ( $? == 0 && $python_raw =~ m/Python\s+3\.\d+/i ) ? 1 : 0;
my $mpl_available = 0;
if ($python_available) {
	# 3.10 is the floor t/01 and t/03 gate on. The generated figure passes
	# layout = "constrained", which matplotlib refuses before 3.5, so an older
	# one (3.0, under an HPC cluster's system python3.6) must skip these checks, not fail them.
	my $raw = qx/$PY -c "import matplotlib; print(matplotlib.__version__)" 2>&1/;
	if ( $? == 0 && $raw =~ m/^\s*(\d+)\.(\d+)/ ) {
		$mpl_available = ( $1 > 3 || ( $1 == 3 && $2 >= 10 ) ) ? 1 : 0;
	}
}
diag( $python_available ? "Python 3 found as \"$PY\" (parser gate ON)" : 'no Python 3 (parser gate skipped)' );
diag( $mpl_available ? 'matplotlib >= 3.10 found (render checks ON)' : 'no matplotlib >= 3.10 (render checks skipped)' );

my $PARSE = q{import ast, sys; ast.parse(open(sys.argv[1], encoding='utf-8').read())};

sub out_file { return File::Spec->catfile( $TMP, 'gen' . $seq++ . '.svg' ) }

sub slurp {
	my ($file) = @_;
	open my $in, '<:encoding(UTF-8)', $file or die "can't read $file: $!";
	local $/;
	my $text = <$in>;
	close $in;
	return $text;
}

# Build one figure with execute => 0 and return the generated python as text.
sub gen {
	my (%spec) = @_;
	$spec{output_file} = out_file();
	$spec{execute} = 0;
	my ( $out, $err, $pyfile ) = capture { plt( \%spec ) };
	return ( slurp($pyfile), $pyfile );
}

# As in t/06.escaping.and.validation.t, which explains why: only the message,
# never the Devel::Confess trace that follows it, is matched.
sub dies_with {
	my ( $spec, $like, $name ) = @_;
	my ( $out, $err, $file ) = capture { eval { gen( %{$spec} ) } };
	my $died = $@;
	return ok( 0, "$name (did not die)" ) unless length $died;
	my $message = "$died";
	$message =~ s/\n\t.*\z//s;
	if ( !like( $message, $like, $name ) ) {
		diag("  died: $message");
	}
	return;
}

# The result is taken inside the capture block: "$@" read after capture()
# returns can still hold an earlier test's error.
sub lives {
	my ( $spec, $name ) = @_;
	my ( @r, $died );
	capture { $died = eval { @r = gen( %{$spec} ); 1 } ? '' : "$@" };
	$died =~ s/\n\t.*\z//s;
	ok( !length $died, $name ) or diag("  died: $died");
	return @r;
}

sub parses_ok {
	my ( $pyfile, $name ) = @_;
	SKIP: {
		skip( 'no Python 3 interpreter found', 1 ) unless $python_available;
		my ( $out, $err, $status ) = capture {
			system( @PY, '-c', $PARSE, $pyfile );
		};
		ok( $status == 0, $name ) or diag( '  ' . ( $err . $out ) );
	}
	return;
}

# Run a generated script with $tail appended, returning what it printed. The
# caller has already skipped unless matplotlib is present.
sub run_py {
	my ( $pyfile, $tail ) = @_;
	my $script = File::Spec->catfile( $TMP, 'run' . $seq++ . '.py' );
	open my $o, '>:encoding(UTF-8)', $script or die "can't write $script: $!";
	print {$o} slurp($pyfile), "\n", $tail, "\n";
	close $o or die "can't close $script: $!";
	local $ENV{MPLBACKEND} = 'Agg';
	my ( $out, $err, $status ) = capture { system( @PY, $script ) };
	diag("  python: $err") if $status != 0;
	return $out;
}

# ----------------------------------------------------------------------------
# 1. violin whiskers were read off unsorted data.
# ----------------------------------------------------------------------------
{
	# q1 = 3.5, q3 = 8.5: the lower whisker runs to the smallest value, 1, and
	# the upper one to the fence, 8.5 + 1.5 * 5 = 16. On 0.314 the lower one
	# came back as 3.5, since vals[0] was 10, and was not drawn.
	my ( $py, $file ) = gen(
		plot_type => 'violin',
		data        => { A => [ 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 100 ] }
	);
	SKIP: {
		skip( 'matplotlib >= 3.10 not found', 1 ) unless $mpl_available;
		my $out = run_py( $file, 'print("W", whiskers.tolist())' );
		like( $out, qr/^W \[\[1\.0, 16\.0\]\]$/m, 'violin: whiskers are computed from the sorted data' );
	}

# ----------------------------------------------------------------------------
# 2. violin "points" was set to the size of the smallest group.
# ----------------------------------------------------------------------------
	unlike( $py, qr/points\s*=/, 'violin: the density is evaluated at matplotlib\'s default number of points' );
}

# ----------------------------------------------------------------------------
# 3. colored_table's cells ignored "cb_logscale".
# ----------------------------------------------------------------------------
{
	my %table = ( A => { A => 1, B => 10 }, B => { A => 100, B => 1000 } );
	my ( $py, $file ) = gen( plot_type => 'colored_table', data => \%table, cb_logscale => 1 );
	like( $py, qr/^norm = colors\.LogNorm\(vmin = 1, vmax = 1000\)$/m, 'colored_table: the cells are colored through a LogNorm' );
	like( $py, qr/imshow\(d, cmap=table_cmap, norm=norm\)/, 'colored_table: the colorbar is drawn from the same norm' );
	SKIP: {
		skip( 'matplotlib >= 3.10 not found', 1 ) unless $mpl_available;
		my $out = run_py( $file, 'print("N", type(norm).__name__, round(float(norm(10)), 3), round(float(norm(100)), 3), img.norm is norm)' );
		like( $out, qr/^N LogNorm 0\.333 0\.667 True$/m, 'colored_table: 10 and 100 sit a third and two thirds up the log scale' );
	}
	# LogNorm autoscaled past a 0 cell when it was left to itself; the
	# explicit bounds have to do the same, or python raises on vmin = 0.
	my ($py0) = gen( plot_type => 'colored_table', data => { A => { A => 0, B => 10 }, B => { A => 100, B => 1000 } }, cb_logscale => 1 );
	like( $py0, qr/LogNorm\(vmin = 10, vmax = 1000\)/, 'colored_table: a log scale starts at the smallest positive cell' );
	dies_with(
		{ plot_type => 'colored_table', data => \%table, cb_logscale => 1, cb_min => 0 },
		qr/"cb_logscale" cannot start at "cb_min" = 0/,
		'colored_table: a log scale refuses cb_min = 0'
	);
	my ($pylin) = gen( plot_type => 'colored_table', data => \%table );
	like( $pylin, qr/^norm = plt\.Normalize\(1, 1000\)$/m, 'colored_table: without cb_logscale the norm is linear' );
}

# ----------------------------------------------------------------------------
# 4. hist colors other than plain names were written bare.
# 5. a hist "color" given as one color was dropped.
# ----------------------------------------------------------------------------
{
	my %two = ( A => [ 1, 2, 2, 3 ], B => [ 2, 3, 3, 4 ] );
	my ( $py, $file ) = gen( plot_type => 'hist', data => \%two, color => { A => '#ff0000', B => 'tab:blue' } );
	like( $py, qr/color = '#ff0000'/, 'hist: a hex color per set is quoted' );
	like( $py, qr/color = 'tab:blue'/, 'hist: a tab: color per set is quoted' );
	parses_ok( $file, 'hist: per-set hex colors parse' );

	($py) = gen( plot_type => 'hist', data => \%two, color => { A => '0.5', B => 'red' } );
	like( $py, qr/color = '0\.5'/, 'hist: a grayscale color is a string, not a number' );

	($py) = gen( plot_type => 'hist', data => [ 1, 2, 2, 3 ], color => 'red' );
	like( $py, qr/\.hist\(d, [^\n]*color = 'red'/, 'hist: one color for every set reaches hist()' );
	($py) = gen( plot_type => 'hist', data => [ 1, 2, 2, 3 ], color => '#00ff00' );
	like( $py, qr/color = '#00ff00'/, 'hist: one hex color for every set is quoted' );
	dies_with(
		{ plot_type => 'hist', data => \%two, color => [ 'red', 'blue' ] },
		qr/"color" for hist_helper is one color for every set, or a hash/,
		'hist: an array of colors is refused, naming the hash form'
	);

	($py) = gen( plot_type => 'hist', data => [ 1, 2, 2, 3 ], bins => 'auto' );
	like( $py, qr/bins = 'auto'/, 'hist: a named bins strategy is quoted' );
	($py) = gen( plot_type => 'hist', data => [ 1, 2, 2, 3 ], bins => 7 );
	like( $py, qr/bins = 7\b/, 'hist: a number of bins is not' );
}

# ----------------------------------------------------------------------------
# 6. plt({ ... }) wrote into the caller's hashes.
# ----------------------------------------------------------------------------
{
	my %single = (
		output_file => out_file(),
		execute       => 0,
		plot_type     => 'plot',
		title         => 'T',
		xlabel        => 'x',
		data          => { A => [ [ 1, 2 ], [ 3, 4 ] ] },
		add           => [ { data => { B => [ [ 1, 2 ], [ 4, 3 ] ] } } ],
		twinx         => 'A',
		twinx_args    => { A => { set_ylabel => 'right' } },
	);
	my $before = dclone( \%single );
	my ( $o1, $e1, $f1 ) = capture { plt( \%single ) };
	is_deeply( \%single, $before, 'plt: a single plot leaves the caller\'s hash as it was' );
	my ( $o2, $e2, $f2 ) = capture { plt( \%single ) };
	my ( $t1, $t2 ) = ( slurp($f1), slurp($f2) );
	is( $t2, $t1, 'plt: the same hash drawn twice writes the same script' );
	my @plots = ( $t2 =~ m/\.plot\(x/g );
	is( scalar @plots, 2, 'plt: the "add" overlay is still drawn the second time' );

	my %multi = (
		output_file => out_file(),
		execute       => 0,
		plots         => [
			# An imshow, not the hist this was: since 0.317 a subplot in
			# "shared_colorbar" must be one that draws a colorbar.
			{ plot_type => 'imshow', data => [ [ 1, 2 ], [ 3, 4 ] ], title => 'i' },
			{ plot_type => 'imshow', data => [ [ 1, 2 ], [ 3, 4 ] ], add => [ { plot_type => 'plot', data => [ [ 0, 1 ], [ 0, 1 ] ] } ] },
			{ plot_type => 'hist', data => [ 1, 2, 2, 3 ], title => 'h' },
			{ plot_type => 'bar', data => { A => { x => 1, y => 2 }, B => { x => 3, y => 4 } } },
		],
		ncols             => 4,
		shared_colorbar => [ 0, 1 ],
	);
	$before = dclone( \%multi );
	capture { plt( \%multi ) };
	is_deeply( \%multi, $before, 'plt: subplots, their "add" graphs and their data are left as they were' );

	# normalise_p pushed the rest of an inner array onto the base plot's own
	# "add", which the shallow copy shared with the caller.
	my @own_add = ( { data => { C => [ [ 1, 2 ], [ 1, 2 ] ] } } );
	my %base = ( plot_type => 'plot', data => { A => [ [ 1, 2 ], [ 3, 4 ] ] }, add => \@own_add );
	capture { plt( output_file => out_file(), execute => 0, p => [ [ \%base, { data => { B => [ [ 1, 2 ], [ 4, 3 ] ] } } ] ] ) };
	is( scalar @own_add, 1, 'plt: "p" leaves the base plot\'s own "add" array as it was' );
}

# ----------------------------------------------------------------------------
# 7. imshow translated strings in the caller's own rows.
# ----------------------------------------------------------------------------
{
	my @rows = ( [ 'H', 'E' ], [ 'E', 'H' ] );
	my $before = dclone( \@rows );
	gen( plot_type => 'imshow', data => \@rows, stringmap => { H => 'helix', E => 'strand' } );
	is_deeply( \@rows, $before, 'imshow: string data is translated in a copy' );
	dies_with(
		{ plot_type => 'imshow', data => [ [ 'H', 'E' ], [ 'H', 'X' ] ], stringmap => { H => 'helix', E => 'strand' } },
		qr/the above values of "data" are not keys of "stringmap"/,
		'imshow: a string missing from stringmap is refused, not drawn blank'
	);
}

# ----------------------------------------------------------------------------
# 8. non-numeric values that reached the script as bare python names.
# ----------------------------------------------------------------------------
dies_with(
	{ plot_type => 'plot', data => { A => [ [ 1, 2 ], [ 'a', 3 ] ] } },
	qr/set "A" axis 1 has the above non-numeric values/,
	'plot: a string in hash data is refused, as it is in array data'
);
dies_with(
	{ plot_type => 'colored_table', data => { A => { A => 1, B => 'NA' }, B => { A => 2, B => 3 } } },
	qr/the above cells are not numbers/,
	'colored_table: a string cell is refused'
);
dies_with(
	{ plot_type => 'scatter', data => { x => [ 1, 'two' ], y => [ 1, 2 ] } },
	qr/"x" is undefined or not a number/,
	'scatter: a string x value is refused'
);
dies_with(
	{ plot_type => 'scatter', data => { x => [ 1, 2 ], y => [ 1, 2 ], z => [ 1, 'hot' ] } },
	qr/"z" is undefined or not a number/,
	'scatter: a string in the color axis is refused'
);
dies_with(
	{ plot_type => 'scatter', data => { S => { x => [ 1, 2 ], y => [ 'a', 2 ] } } },
	qr/"y" of set "S" is undefined or not a number/,
	'scatter: a string in a set of a multi-set scatter is refused'
);
dies_with(
	{ plot_type => 'hexbin', data => { x => [ 1, 'b' ], y => [ 1, 2 ] } },
	qr/"x" is undefined or not a number at the above indices/,
	'hexbin: a string point is refused'
);
dies_with(
	{ plot_type => 'hexbin', data => { x => [ 1, 2 ], y => [ 1, undef ] } },
	qr/"y" is undefined or not a number at the above indices/,
	'hexbin: an undefined point is refused'
);

# ----------------------------------------------------------------------------
# 9. scatter's color key leaked from one set to the next.
# ----------------------------------------------------------------------------
{
	my ( $py, $file ) = lives(
		{
			plot_type => 'scatter',
			data        => {
				A => { x => [ 1, 2 ], y => [ 1, 2 ], z => [ 1, 2 ] },
				B => { x => [ 1, 2 ], y => [ 2, 1 ] }
			}
		},
		'scatter: a set of x and y may follow a set with a color axis'
	);
	SKIP: {
		skip( 'the figure died', 3 ) unless defined $py;
		like( $py, qr/c = z/, 'scatter: the set with a color axis is colored' );
		like( $py, qr/ax0\.scatter\(x, y, label = 'B'/, 'scatter: the set without one is drawn plainly' );
		like( $py, qr/plt\.colorbar\(im, label = 'z'\)/, 'scatter: the colorbar is labelled with the color key' );
	}
}

# ----------------------------------------------------------------------------
# 11. a backslash in text went through as a python escape.
# ----------------------------------------------------------------------------
{
	my ( $py, $file ) = gen( plot_type => 'bar', data => { A => 1 }, suptitle => 'dir C:\new' );
	like( $py, qr/plt\.suptitle\('dir C:\\\\new'\)/, 'suptitle: a backslash is escaped' );
	parses_ok( $file, 'suptitle: a backslash parses' );
	($py) = gen( plot_type => 'bar', data => { A => 1 }, title => '$\alpha$' );
	like( $py, qr/ax0\.set_title\('\$\\\\alpha\$'\)/, 'title: mathtext keeps its backslash' );
	($py) = gen( plot_type => 'bar', data => { A => 1 }, suptitle => 'Counts, by book' );
	like( $py, qr/plt\.suptitle\('Counts, by book'\)/, 'suptitle: text with a comma is still quoted, as before' );
	($py) = gen( plot_type => 'bar', data => { A => 1 }, suptitle => "'already', fontsize = 20" );
	like( $py, qr/plt\.suptitle\('already', fontsize = 20\)/, 'suptitle: python of the caller\'s own is left alone' );

	# A figure of several subplots had its top-level suptitle quoted by
	# print_type alone, which left "Two groups: mean." bare.
	my $multi;
	( $multi, $file ) = gen(
		plots    => [ { plot_type => 'bar', data => { A => 1 } }, { plot_type => 'bar', data => { B => 2 } } ],
		ncols    => 2,
		suptitle => 'Two groups: mean.'
	);
	like( $multi, qr/plt\.suptitle\('Two groups: mean\.'\)/, 'suptitle: a multi-plot figure\'s suptitle is quoted' );
	parses_ok( $file, 'suptitle: a multi-plot figure\'s suptitle parses' );
}

# ----------------------------------------------------------------------------
# The smaller fixes.
# ----------------------------------------------------------------------------
{
	# bar filled the holes of a grouped plot with 0 in the caller's arrays.
	my %groups = ( A => [ 1, undef ], B => [ 3, 4 ] );
	my $before = dclone( \%groups );
	my ($py) = gen( plot_type => 'bar', data => \%groups );
	is_deeply( \%groups, $before, 'bar: a missing value is drawn as 0 without writing 0 into the caller\'s array' );
	like( $py, qr/ax0\.bar\(\[[^\]]*\], \[1,3\]/, 'bar: the first series is drawn' );
	like( $py, qr/ax0\.bar\(\[[^\]]*\], \[0,4\]/, 'bar: the missing value is drawn as 0' );

	# The label array the caller gave a hash-of-hashes plot was overwritten.
	my @label = ( 'one', 'two' );
	capture { plt( output_file => out_file(), execute => 0, plot_type => 'bar', data => { A => { x => 1, y => 2 } }, label => \@label ) };
	is_deeply( \@label, [ 'one', 'two' ], 'bar: the caller\'s label array is not overwritten' );
}
{
	# hexbin passed vmin/vmax beside a LogNorm, which matplotlib refuses.
	my ( $py, $file ) = gen( plot_type => 'hexbin', data => { x => [ 1 .. 20 ], y => [ map { $_ % 7 } 1 .. 20 ] }, cb_logscale => 1, vmin => 1, vmax => 5 );
	like( $py, qr/norm = LogNorm\(vmin = 1, vmax = 5\)/, 'hexbin: vmin and vmax go to the LogNorm' );
	unlike( $py, qr/\), vmin =/, 'hexbin: and not beside it' );
	SKIP: {
		skip( 'matplotlib >= 3.10 not found', 1 ) unless $mpl_available;
		my $out = run_py( $file, 'print("V", im0.norm.vmin, im0.norm.vmax)' );
		like( $out, qr/^V 1\.0 5\.0$/m, 'hexbin: the log-scaled figure renders with those bounds' );
	}
	dies_with(
		{ plot_type => 'hexbin', data => { x => [ 1, 2 ], y => [ 1, 2 ] }, vmin => 'low' },
		qr/"vmin" must be a number for hexbin_helper/,
		'hexbin: a non-numeric vmin is refused'
	);
	# The diagnostics before the die went to STDOUT. plt directly, not gen,
	# whose own capture would swallow them.
	my ( $out, $err ) = capture { eval { plt( output_file => out_file(), execute => 0, plot_type => 'hexbin', data => { x => [ 1, 2, 3 ], y => [ 1, 2 ] } ) } };
	unlike( $out, qr/points\./, 'hexbin: a length mismatch is reported on STDERR, not STDOUT' );
	like( $err, qr/"x" has 3 points\./, 'hexbin: and it is reported' );
}
{
	# wide drew its groups in hash order, all in the one default blue.
	my $run = [ [ [ 1, 2, 3 ], [ 1, 2, 3 ] ] ];
	my ($py) = gen( plot_type => 'wide', data => { Zeta => $run, Alpha => $run, Mu => $run } );
	my @labels = ( $py =~ m/label = '(\w+)'/g );
	is_deeply( \@labels, [qw(Alpha Mu Zeta)], 'wide: groups are drawn in sorted order' );
	my @colors = ( $py =~ m/ax0\.plot\(base_x, mean_ys, '(\w+)'/g );
	is_deeply( \@colors, [qw(C0 C1 C2)], 'wide: uncolored groups take successive colors of the default cycle' );
	($py) = gen( plot_type => 'wide', data => { A => $run, B => $run }, color => { A => 'red' } );
	like( $py, qr/mean_ys, 'red', label = 'A'/, 'wide: a group\'s own color still wins' );
}

done_testing();

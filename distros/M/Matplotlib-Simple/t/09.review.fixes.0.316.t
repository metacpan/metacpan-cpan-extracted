#!/usr/bin/env perl
#
# The fixes of 0.316, one block each.
#
# They came out of a read of the whole of lib/Matplotlib/Simple.pm, as those
# of t/07.review.fixes.t did, and each was reproduced against 0.315 before it
# was fixed. Every block has at least one assertion that fails on 0.315; the
# twelve that pass there -- no plt.sca() where there is no pyplot option, an
# imshow of numeric strings and a figure drawn through "p" both generated
# without dying, the caller's imshow rows left alone, a ylim and an xscale
# script that parse though they fail when run, a lone word and a list holding
# a word still quoted, and the four Python values a subplot already wrote bare
# -- guard behaviour the fixes had to keep.
#
# Most of this is execute => 0 and reads the generated python as text, so it
# runs everywhere, including a Windows smoker with no python.  As in
# t/07.review.fixes.t, parses_ok needs python3 and run_py needs python3 and
# matplotlib, and each skips without them.
#
require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Temp 'tempdir';
use File::Spec;
use Capture::Tiny 'capture';
use Storable 'dclone';
use JSON::MaybeXS;
use MIME::Base64;
use Matplotlib::Simple;
# The interpreter the module itself runs; see t/07.review.fixes.t.
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

# Only the message, never the Devel::Confess trace that follows it, is matched.
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

# The number of lines on each axes of the figure, in the order fig.axes holds
# them: the subplots in order, then any twin.
my $LINES_PER_AXES = 'print("L", [len(a.lines) for a in fig.axes])';

# ----------------------------------------------------------------------------
# 1. A pyplot option given to one subplot was drawn on another.
# ----------------------------------------------------------------------------
{
	# plt.axhline acts on the current axes, which after plt.subplots is the
	# last subplot: subplot 0's line was drawn on subplot 1, and "L [1, 2]"
	# came back. Each subplot has one line of its own, so "L [2, 1]" is
	# subplot 0 with its axhline.
	my ( $py, $file ) = gen(
		ncols => 2,
		plots => [
			{ plot_type => 'plot', data => { A => [ [ 1, 2, 3 ], [ 1, 2, 3 ] ] }, axhline => 2 },
			{ plot_type => 'plot', data => { B => [ [ 1, 2, 3 ], [ 3, 2, 1 ] ] } },
		],
	);
	like( $py, qr/^plt\.sca\(ax0\).*\n^plt\.axhline\(2\)/m, 'subplot: its own axes is made current before its pyplot options' );
	SKIP: {
		skip( 'matplotlib >= 3.10 not found', 1 ) unless $mpl_available;
		like( run_py( $file, $LINES_PER_AXES ), qr/^L \[2, 1\]$/m, 'subplot: an axhline given to subplot 0 is drawn on subplot 0' );
	}
	# A single plot's twinx() leaves the twin current, so its axhline went to
	# the twin: "L [1, 2]". ax0 holds A and the axhline, the twin holds B.
	( $py, $file ) = gen(
		plot_type => 'plot',
		data        => { A => [ [ 1, 2, 3 ], [ 1, 2, 3 ] ], B => [ [ 1, 2, 3 ], [ 30, 20, 10 ] ] },
		twinx       => 'B',
		axhline     => 2,
	);
	SKIP: {
		skip( 'matplotlib >= 3.10 not found', 1 ) unless $mpl_available;
		like( run_py( $file, $LINES_PER_AXES ), qr/^L \[2, 1\]$/m, 'single plot: an axhline is drawn on the plot, not on its twinx' );
	}
	($py) = gen( plot_type => 'plot', data => { A => [ [ 1, 2 ], [ 1, 2 ] ] } );
	unlike( $py, qr/plt\.sca/, 'single plot: no plt.sca() is written when there is no pyplot option' );
}

# ----------------------------------------------------------------------------
# 2. imshow sent numbers held as strings to numpy as text.
# ----------------------------------------------------------------------------
{
	# Rows split from lines of a file, the usual way to read a matrix in: each
	# value is a string. JSON wrote them as "1", "2", ... and imshow died with
	# "Image data of dtype <U1 cannot be converted to float".
	my @rows = map { [ split ' ' ] } ( '1 2 3', '4 5 6' );
	my $before = dclone( \@rows );
	my ( $py, $file ) = lives( { plot_type => 'imshow', data => \@rows }, 'imshow: rows of numeric strings are accepted' );
	my ($b64) = $py =~ m/^d_b64 = '([^']*)'$/m;
	is( ( defined $b64 ? decode_base64($b64) : '' ), '[[1,2,3],[4,5,6]]', 'imshow: numeric strings reach python as JSON numbers' );
	is_deeply( \@rows, $before, "imshow: the caller's rows are left as they were given" );
	SKIP: {
		skip( 'matplotlib >= 3.10 not found', 1 ) unless $mpl_available;
		like( run_py( $file, 'print("I", im0.get_array().max())' ), qr/^I 6$/m, 'imshow: the image is drawn from the numbers' );
	}
}

# ----------------------------------------------------------------------------
# 3. "p" handed the caller's own overlay hashes to the helpers.
# ----------------------------------------------------------------------------
{
	# An overlay as the 2nd hash of an inner array, an "add" graph of that
	# subplot's base plot, and an "add" graph of a plain-hash subplot: all
	# three came back with "plot_type", "alpha" and "show_legend" added, and
	# their array "data" rewrapped as { A => [...] }.
	my @p = (
		[ { plot_type => 'hist', data => [ 1, 2, 3 ], add => [ { data => [ 7, 8 ] } ] }, { data => [ 4, 5, 6 ] } ],
		{ plot_type => 'hist', data => [ 1, 2 ], add => [ { data => [ 3, 4 ] } ] },
	);
	my $before = dclone( \@p );
	lives( { p => \@p }, 'p: a figure with overlays is drawn' );
	is_deeply( \@p, $before, "p: the caller's subplot and overlay hashes are left as they were given" );
}

# ----------------------------------------------------------------------------
# 4. A multi-set scatter whose "keys" named only x and y lost its y.
# ----------------------------------------------------------------------------
{
	# Three inner keys and keys => [a, b]: "c" is the color. The y key was
	# popped off "keys" to be the color instead, and the helper died as "Use
	# of uninitialized value $keys[1] in hash element".
	my ( $py, $file ) = lives(
		{
			plot_type => 'scatter',
			data        => { S => { a => [ 1, 2 ], b => [ 3, 4 ], c => [ 5, 6 ] }, T => { a => [1], b => [2], c => [9] } },
			keys        => [ 'a', 'b' ],
		},
		'scatter: "keys" may name only x and y of three inner keys'
	);
	like( $py // '', qr/^x = \[1,2\]\ny = \[3,4\]\nz = \[5,6\]$/m, 'scatter: x and y are the keys named, and the color the one left out' );
	like( $py // '', qr/^plt\.colorbar\(im, label = 'c'\)$/m, 'scatter: the colorbar is labelled with the key left out' );
	parses_ok( $file, 'scatter: the script parses' ) if defined $file;
	dies_with(
		{ plot_type => 'scatter', data => { S => { a => [ 1, 2 ], b => [ 3, 4 ], c => [ 5, 6 ] } }, keys => ['a'] },
		qr/scatter_helper set "S" needs one key for x and one for y, but "keys" and "color_key" leave the 1 above/,
		'scatter: a "keys" that leaves no y is refused by name'
	);
}

# ----------------------------------------------------------------------------
# 5. A single plot quoted an argument list of numbers into a string.
# ----------------------------------------------------------------------------
{
	# plt.ylim('0, 10') died as "ValueError: too many values to unpack".
	my ( $py, $file ) = gen( plot_type => 'plot', data => { A => [ [ 1, 2, 3 ], [ 1, 2, 3 ] ] }, ylim => '0, 10' );
	like( $py, qr/^plt\.ylim\(0, 10\)#\d+$/m, 'single plot: "ylim => \'0, 10\'" is written as an argument list' );
	parses_ok( $file, 'single plot: the ylim script parses' );
	SKIP: {
		skip( 'matplotlib >= 3.10 not found', 1 ) unless $mpl_available;
		like( run_py( $file, 'print("Y", tuple(float(v) for v in ax0.get_ylim()))' ), qr/^Y \(0\.0, 10\.0\)$/m, 'single plot: the y axis runs from 0 to 10' );
	}
	($py) = gen( plot_type => 'plot', data => { A => [ [ 1, 2, 3 ], [ 1, 2, 3 ] ] }, ylim => 'None, 10' );
	like( $py, qr/^plt\.ylim\(None, 10\)#\d+$/m, 'single plot: None is a bare value in an argument list' );
	# The quoting of a lone word, pinned in t/06.escaping.and.validation.t, is
	# what the fix had to leave alone; a list holding a word is still text.
	($py) = gen( plot_type => 'plot', data => { A => [ [ 1, 2, 3 ], [ 1, 2, 3 ] ] }, xscale => 'log', ylim => '0, top' );
	like( $py, qr/^plt\.xscale\('log'\)#\d+$/m, 'single plot: a lone word is still quoted' );
	like( $py, qr/^plt\.ylim\('0, top'\)#\d+$/m, 'single plot: a list holding a word is still quoted' );
}

# ----------------------------------------------------------------------------
# 6. A subplot wrote its pyplot options unquoted.
# ----------------------------------------------------------------------------
{
	# plt.xscale(log) raised "NameError: name 'log' is not defined". The
	# second subplot has no options of its own and stays linear.
	my @xy = ( data => { A => [ [ 1, 2, 3 ], [ 1, 2, 3 ] ] } );
	my ( $py, $file ) = gen(
		plots => [ { plot_type => 'plot', @xy, xscale => 'log' }, { plot_type => 'plot', @xy } ],
		ncols => 2
	);
	like( $py, qr/^plt\.xscale\('log'\) #line\d+$/m, 'subplot: "xscale => \'log\'" is quoted' );
	parses_ok( $file, 'subplot: the xscale script parses' );
	SKIP: {
		skip( 'matplotlib >= 3.10 not found', 1 ) unless $mpl_available;
		like( run_py( $file, 'print("S", [a.get_xscale() for a in fig.axes])' ), qr/^S \['log', 'linear'\]$/m, 'subplot: only the first subplot is on a log scale' );
	}
	# Python values a subplot always wrote bare, and must still: a bracketed
	# group, a lone True, a call, and an argument list holding a quote.
	($py) = gen(
		plots => [
			{ plot_type => 'plot', @xy, ylim => '(0, 10)', grid => 'True', axvline => 'float(2)', axhline => ['y = 1, color = "red"'] },
			{ plot_type => 'plot', @xy }
		],
		ncols => 2
	);
	like( $py, qr/^plt\.ylim\(\(0, 10\)\) #line\d+$/m, 'subplot: a bracketed group is still bare' );
	like( $py, qr/^plt\.grid\(True\) #line\d+$/m, 'subplot: a lone True is still bare' );
	like( $py, qr/^plt\.axvline\(float\(2\)\) #line\d+$/m, 'subplot: a call is still bare' );
	like( $py, qr/^plt\.axhline\(y = 1, color = "red"\) #line\d+$/m, 'subplot: an argument list holding a quote is still bare' );
	# The same three were quoted into strings at a single plot. There
	# plt.ylim('(0, 10)') died as "ValueError: too many values to unpack",
	# and plt.axvline('float(2)') ran, taking the text "float(2)" as its x.
	( $py, $file ) = gen( plot_type => 'plot', @xy, ylim => '(0, 10)', grid => 'True', axvline => 'float(2)' );
	like( $py, qr/^plt\.ylim\(\(0, 10\)\)#\d+$/m, 'single plot: a bracketed group is bare' );
	like( $py, qr/^plt\.grid\(True\)#\d+$/m, 'single plot: a lone True is bare' );
	like( $py, qr/^plt\.axvline\(float\(2\)\)#\d+$/m, 'single plot: a call is bare' );
	SKIP: {
		skip( 'matplotlib >= 3.10 not found', 1 ) unless $mpl_available;
		like( run_py( $file, 'print("Y", tuple(float(v) for v in ax0.get_ylim()))' ), qr/^Y \(0\.0, 10\.0\)$/m, 'single plot: the y axis runs from 0 to 10' );
	}
}

done_testing();

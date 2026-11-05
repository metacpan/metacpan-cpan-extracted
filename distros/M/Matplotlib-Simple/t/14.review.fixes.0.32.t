#!/usr/bin/env perl
#
# The fixes of 0.32, one block each, in the form of t/12.review.fixes.0.319.t.
#
# They came out of an outside review of 0.32 as it stood on 2026-10-14, and
# each was reproduced against the module before it was fixed. Blocks that also
# check behaviour the fix had to keep -- python of the caller's own in a title
# still passing through, a label still defaulting to the data key -- say so
# where they do it.
#
# Most of this is execute => 0 and reads the generated python as text, so it
# runs everywhere, including a Windows smoker with no python. parses_ok needs
# python3 and run_py needs python3 and matplotlib >= 3.10, and each skips
# without them.
#
require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Temp 'tempdir';
use File::Spec;
use Capture::Tiny 'capture';
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
	# one must skip these checks, not fail them.
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

# ----------------------------------------------------------------------------
# 1. "show" was tested for Perl truth, so "show => 'False'" showed the figure.
# ----------------------------------------------------------------------------
{
	my ( $out, $err, $file ) = capture { eval { plt( plot_type => 'bar', data => { A => 1 }, show => 'False', execute => 0 ) } };
	like( "$@", qr/either "show" or "output_file" must be defined/, 'show => "False" does not stand in for "output_file"' );
	my ($py) = gen( plot_type => 'bar', data => { A => 1 }, show => 'False' );
	unlike( $py, qr/plt\.show\(\)/, 'show => "False" writes no plt.show()' );
	# kept: a true "show" still shows
	($py) = gen( plot_type => 'bar', data => { A => 1 }, show => 'True' );
	like( $py, qr/^plt\.show\(\)/m, 'show => "True" writes plt.show()' );
	dies_with( { plot_type => 'bar', data => { A => 1 }, show => 'yes' }, qr/"show" is True or False/, 'show => "yes" is refused by name' );
}

# ----------------------------------------------------------------------------
# 2. scatter, hexbin and hist2d wrote the data key over "set_xlabel".
# ----------------------------------------------------------------------------
{
	my %xy = ( X => [ 1, 2, 3 ], Y => [ 3, 2, 1 ] );
	foreach my $type ( 'scatter', 'hexbin', 'hist2d' ) {
		my ($py) = gen( plot_type => $type, data => {%xy}, set_xlabel => 'Custom x', set_ylabel => 'Custom y' );
		like( $py, qr/set_xlabel\('Custom x'\)/, "$type: set_xlabel is the caller's" );
		like( $py, qr/set_ylabel\('Custom y'\)/, "$type: set_ylabel is the caller's" );
		unlike( $py, qr/set_xlabel\('X'\)/, "$type: and the data key is not written over it" );
		# kept: with no label given, the axes are labelled by the keys
		($py) = gen( plot_type => $type, data => {%xy} );
		like( $py, qr/set_xlabel\('X'\).*\n(?:.*\n)*.*set_ylabel\('Y'\)/, "$type: the keys label the axes by default" );
	}
	my ($py) = gen( plot_type => 'scatter', data => { A => {%xy}, B => {%xy} }, set_xlabel => 'Custom x' );
	like( $py, qr/set_xlabel\('Custom x'\)/, 'scatter with several sets: set_xlabel is the caller\'s' );
}

# ----------------------------------------------------------------------------
# 3. Prose opening with a quote was taken for python.
# ----------------------------------------------------------------------------
{
	my ( $py, $file ) = gen( plot_type => 'bar', data => { A => 1 }, title => "'Tis the season", xlabel => '"A" vs "B"' );
	like( $py, qr/set_title\('\\'Tis the season'\)/, 'a leading apostrophe in prose is quoted' );
	like( $py, qr/set_xlabel\('"A" vs "B"'\)/,       'a string literal followed by more prose is quoted' );
	parses_ok( $file, 'the prose titles parse' );
	# kept: a literal that closes, alone or before a comma, is the caller's python
	($py) = gen( plot_type => 'bar', data => { A => 1 }, title => "'Counts, by book'", xlabel => q{"a, b", fontsize = 20}, ylabel => 'r"$\it{anno}$"' );
	like( $py, qr/set_title\('Counts, by book'\)/,           'a whole literal is left alone' );
	like( $py, qr/set_xlabel\("a, b", fontsize = 20\)/,      'a literal before a comma is left alone' );
	like( $py, qr/set_ylabel\(r"\$\\it\{anno\}\$"\)/,       'a raw string literal is left alone' );
}

# ----------------------------------------------------------------------------
# 4. hist2d on a log scale had one bin fewer than it asked for.
# ----------------------------------------------------------------------------
{
	my %h2 = ( plot_type => 'hist2d', data => { X => [ 1, 2, 3 ], Y => [ 3, 2, 1 ] } );
	my ( $py, $file ) = gen( %h2, logscale => ['x'], xbins => 4, ybins => 5 );
	like( $py, qr/^xbins = np\.logspace\(np\.log10\(1\), np\.log10\(3\), 5\)$/m, 'a log axis has xbins + 1 edges' );
	like( $py, qr/^ybins = np\.linspace\(1, 3, 6\)$/m,                          'and so has the linear axis beside it' );
	( $py, $file ) = gen( %h2, logscale => ['x'], xbins => 1 );
	like( $py, qr/np\.log10\(3\), 2\)$/m, 'xbins => 1 is two edges' );
	SKIP: {
		skip( 'no matplotlib >= 3.10', 1 ) unless $mpl_available;
		like( run_py( $file, 'print("bins", hist2d_n.shape)' ), qr/^bins \(1, 15\)$/m, 'and draws one bin, where it died in np.max' );
	}
	($py) = gen( %h2, logscale => [] );
	like( $py, qr/hist2d\(x, y , \(15, 15\)/, 'logscale => [] is a linear plot, given the bin counts' );
}

# ----------------------------------------------------------------------------
# 5. "data" of the wrong shape died inside a helper, and an "add" graph's was
# never checked.
# ----------------------------------------------------------------------------
{
	foreach my $type ( 'bar', 'barh', 'pie', 'colored_table' ) {
		dies_with( { plot_type => $type, data => [ 1, 2 ] }, qr/^plt: "data" must be a hash for $type, not an ARRAY reference/, "$type: an array is refused by name" );
	}
	foreach my $type ( 'hexbin', 'hist2d' ) {
		dies_with( { plot_type => $type, data => [ 1, 2 ] }, qr/^plt: "data" must be a hash of arrays for $type/, "$type: an array is refused by name" );
	}
	foreach my $type ( 'boxplot', 'violin', 'violinplot', 'hist', 'hexbin', 'hist2d' ) {
		dies_with( { plot_type => $type, data => { A => 1, B => [ 1, 2 ] } }, qr/^plt: each key of "data" is an array of values for $type, but "A" is not/, "$type: a key that is not an array is named" );
	}
	dies_with( { plot_type => 'boxplot', data => 'x' }, qr/must be an array of values, or a hash of them, for boxplot, not "x"/, 'boxplot: a string is refused by name' );
	dies_with( { plot_type => 'hist', data => [] }, qr/^plt: "data" is an empty array/, 'hist: an empty array is refused' );
	dies_with( { plots => [ { plot_type => 'bar', data => { A => 1 } }, { plot_type => 'pie', data => [1] } ], ncols => 2 },
		qr/^plt: "data" at subplot 1 must be a hash for pie/, 'a subplot is named' );
	dies_with( { plot_type => 'violin', data => { A => [ 1, 2, 3 ] }, add => [ { data => {} } ] },
		qr/^plt: "data" for an "add" graph is an empty hash/, 'an "add" graph with empty data is refused' );
	dies_with( { plot_type => 'violin', data => { A => [ 1, 2, 3 ] }, add => [ { plot_type => 'boxplot' } ] },
		qr/^plt: "data" for an "add" graph is not defined/, 'an "add" graph with no data is refused' );
	dies_with( { plots => [ { plot_type => 'plot', data => { A => [ [ 1, 2 ], [ 1, 2 ] ] }, add => [ { plot_type => 'bar', data => [1] } ] } ] },
		qr/^plt: "data" for an "add" graph at subplot 0 must be a hash for bar/, 'an "add" graph at a subplot is named' );
	# kept: an array is still one set for the types that take one
	lives( { plot_type => 'boxplot', data => [ 1, 2, 3 ] }, 'boxplot: an array is one set' );
}

# ----------------------------------------------------------------------------
# 6. A "df" with no complete row made an empty "data".
# ----------------------------------------------------------------------------
{
	my %no_v = ( name => [ 'a', 'b' ], v => [ undef, undef ], g => [ 'p', 'q' ], t => [ 1, 2 ] );
	foreach my $type ( 'bar', 'barh', 'pie' ) {
		dies_with( { plot_type => $type, df => {%no_v}, x => 'name', y => 'v' }, qr/^plt: no row of "df" has a value in both "name" and "v"/, "$type: the columns are named" );
	}
	dies_with( { plot_type => 'plot', df => {%no_v}, x => 't', y => 'v', by => 'g' }, qr/^plt: no row of "df" has a value in every one of "t", "v", "g"/, 'plot with "by": the columns are named' );
	dies_with( { plot_type => 'hist', df => {%no_v}, x => 'v', by => 'g' }, qr/^plt: no row of "df" has a value in both "v" and "g"/, 'hist with "by": the columns are named' );
	dies_with( { plot_type => 'hist', df => {%no_v}, x => 'v' }, qr/^plt: no row of "df" has a value in "v"/, 'hist: the column is named' );
	dies_with( { plot_type => 'scatter', df => { a => [ 1, 2 ], b => [ 1, 2 ], g => [ undef, undef ] }, x => 'a', y => 'b', by => 'g' },
		qr/^plt: no row of "df" has a value in every one of "a", "b", "g"/, 'scatter with "by": "by" is named too' );
}

# ----------------------------------------------------------------------------
# 7. Tables sharing a colorbar were scaled by cells they did not draw.
# ----------------------------------------------------------------------------
{
	my ($py) = gen(
		plots => [
			{ plot_type => 'colored_table', data => { A => { A => 1, B => 100 }, B => { A => 2, B => 3 } }, col_labels => ['A'] },
			{ plot_type => 'colored_table', data => { A => { A => 5, B => 4 }, B => { A => 6, B => 2 } }, default_undefined => -50 },
		],
		ncols           => 2,
		shared_colorbar => [ 0, 1 ],
	);
	my @norms = $py =~ m/^norm = plt\.Normalize\((.*)\)$/mg;
	is_deeply( \@norms, [ '1, 6', '1, 6' ], 'the 100 that "col_labels" leaves out, and an unused "default_undefined", are not in the scale' );
	# kept: a "default_undefined" that fills a cell is part of the scale
	($py) = gen(
		plots => [
			{ plot_type => 'colored_table', data => { A => { A => 1 }, B => { B => 3 } }, default_undefined => 0 },
			{ plot_type => 'colored_table', data => { A => { A => 5 } } },
		],
		ncols           => 2,
		shared_colorbar => [ 0, 1 ],
	);
	@norms = $py =~ m/^norm = plt\.Normalize\((.*)\)$/mg;
	is_deeply( \@norms, [ '0, 5', '0, 5' ], 'a "default_undefined" that fills a cell is in the scale' );
}

# ----------------------------------------------------------------------------
# 8. "supxlabel" and "supylabel" were written as given.
# ----------------------------------------------------------------------------
{
	my ( $py, $file ) = gen( plot_type => 'bar', data => { A => 1 }, supxlabel => 'Time', supylabel => "Bob's count" );
	like( $py, qr/^fig\.supxlabel\('Time'\)/m,          'a single plot: supxlabel is quoted' );
	like( $py, qr/^fig\.supylabel\('Bob\\'s count'\)/m, 'and supylabel' );
	parses_ok( $file, 'the single plot parses' );
	( $py, $file ) = gen( plots => [ { plot_type => 'bar', data => { A => 1 } }, { plot_type => 'bar', data => { A => 2 } } ], ncols => 2, supxlabel => 'Time' );
	like( $py, qr/^fig\.supxlabel\('Time'\)/m, 'a figure of subplots: supxlabel is quoted' );
	parses_ok( $file, 'the figure of subplots parses' );
}

done_testing();

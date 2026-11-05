#!/usr/bin/env perl
#
# The fixes of 0.317, one block each.
#
# They came out of a read of the whole of lib/Matplotlib/Simple.pm, as those
# of t/07.review.fixes.t and t/09.review.fixes.0.316.t did, and each was
# reproduced against the module as it stood before it was fixed. Blocks that
# also check behaviour the fix had to keep -- a subplot pair that shares a
# colorbar still drawing it once, "log => 'True'" still setting the log scale --
# say so where they do it.
#
# Most of this is execute => 0 and reads the generated python as text, so it
# runs everywhere, including a Windows smoker with no python. As in
# t/09.review.fixes.0.316.t, parses_ok needs python3 and run_py needs python3
# and matplotlib >= 3.10, and each skips without them.
#
require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Temp 'tempdir';
use File::Spec;
use Capture::Tiny 'capture';
use JSON::MaybeXS;
use MIME::Base64;
use Encode 'encode_utf8';
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

# The value of a variable that write_data wrote, decoded as python would.
sub b64_var {
	my ( $py, $name ) = @_;
	my ($b64) = $py =~ m/^\Q$name\E_b64 = '([^']*)'$/m;
	return undef unless defined $b64;
	return JSON::MaybeXS->new->utf8->decode( decode_base64($b64) );
}

# ----------------------------------------------------------------------------
# 1. "log => 'False'" turned the log scale on.
# ----------------------------------------------------------------------------
{
	my %bar = ( plot_type => 'bar', data => { A => 1, B => 2 } );
	my ($py) = gen( %bar, log => 'False' );
	unlike( $py, qr/log = True/, 'log => "False": no log scale (the string is true in Perl)' );
	($py) = gen( %bar, log => 0 );
	unlike( $py, qr/log = True/, 'log => 0: no log scale' );
	# kept: the documented form still works
	($py) = gen( %bar, log => 'True' );
	like( $py, qr/log = True/, 'log => "True": log scale, as documented' );
	($py) = gen( %bar, log => 1 );
	like( $py, qr/log = True/, 'log => 1: log scale' );
	dies_with( { %bar, log => 'maybe' }, qr/"log" is True or False/, 'log => "maybe" is refused by name' );
}

# ----------------------------------------------------------------------------
# 2. colored_table took its columns from the outer keys.
# ----------------------------------------------------------------------------
{
	# The POD's own "Entering data" example. The table drew columns C and H,
	# lost every Br and Cl value, and left the C column empty.
	my ($py, $file) = gen(
		plot_type => 'colored_table',
		data        => {
			H => { H => 432, Cl => 427, Br => 363 },
			C => { H => 413, Cl => 339, Br => 276 },
		},
	);
	like( $py, qr/colLabels = \['Br','Cl','H'\]/, 'the columns are the inner keys' );
	like( $py, qr/rowLabels=\['C','H'\]/,         'the rows are the outer keys' );
	like( $py, qr/^d\.append\(\[276,339,413\]\)$/m, 'row C holds its Br, Cl and H values' );
	like( $py, qr/^d\.append\(\[363,427,432\]\)$/m, 'row H holds its Br, Cl and H values' );
	parses_ok( $file, 'the table script parses' );
	# mirror: square, and a given cell is not overwritten by its reflection
	($py) = gen(
		plot_type => 'colored_table',
		mirror      => 1,
		data        => { A => { A => 1, B => 2 }, B => { A => 3 } },
	);
	like( $py, qr/colLabels = \['A','B'\]/, 'mirror: the columns are every key' );
	like( $py, qr/^d\.append\(\[1,2\]\)$/m, 'mirror: row A is A/A and A/B as given' );
	like( $py, qr/^d\.append\(\[3,np\.nan\]\)$/m, 'mirror: B/A keeps the 3 it was given rather than the reflected 2' );
	dies_with(
		{ plot_type => 'colored_table', data => { A => { A => 1 }, B => { B => 2 } }, row_labels => ['a'] },
		qr/"row_labels" has 1 labels, but the table has 2 rows/,
		'a row_labels of the wrong length is refused by name'
	);
	dies_with(
		{ plot_type => 'colored_table', data => { A => [ 1, 2 ] } },
		qr/row "A" of "data" is a ARRAY reference/,
		'a row that is not a hash is refused by name'
	);
}

# ----------------------------------------------------------------------------
# 3. shared_colorbar gave subplots keywords their helpers refused.
# ----------------------------------------------------------------------------
{
	my @imshow = ( plot_type => 'imshow', data => [ [ 1, 2 ], [ 3, 4 ] ] );
	dies_with(
		{ ncols => 2, shared_colorbar => [ 0, 1 ], plots => [ { plot_type => 'plot', data => { A => [ [ 1, 2 ], [ 3, 4 ] ] } }, {@imshow} ] },
		qr/"shared_colorbar" lists subplot 0 \("plot"\), but only these plot types draw a colorbar/,
		'a plot in shared_colorbar is refused, naming it; it died over "colorbar_on"'
	);
	# kept: two imshows still share one colorbar, and no cbpad is passed
	my ( $py, $file ) = lives( { ncols => 2, shared_colorbar => [ 0, 1 ], plots => [ {@imshow}, {@imshow} ] }, 'two imshows share a colorbar' );
	my @colorbars = $py =~ m/(fig\.colorbar\([^\n]*)/g;
	is( scalar @colorbars, 1, 'two imshows: one colorbar' );
	like( $colorbars[0] // '', qr/ax = \[ax0,ax1\]/, 'two imshows: the colorbar spans both' );
	unlike( $py, qr/pad = /, 'no cbpad is written when none was given' );
	# scatter accepted shared_colorbar and colorbar_on, and ignored both
	my @scatter = ( plot_type => 'scatter', data => { x => [ 1, 2 ], y => [ 3, 4 ], z => [ 5, 6 ] } );
	($py) = lives( { ncols => 2, shared_colorbar => [ 0, 1 ], plots => [ {@scatter}, {@scatter} ] }, 'two scatters share a colorbar' );
	@colorbars = $py =~ m/(fig\.colorbar\([^\n]*)/g;
	is( scalar @colorbars, 1, 'two scatters: one colorbar, not one each' );
	like( $colorbars[0] // '', qr/ax = \[ax0,ax1\]/, 'two scatters: the colorbar spans both' );
}

# ----------------------------------------------------------------------------
# 4. A shared_colorbar index could name an empty cell of the grid.
# ----------------------------------------------------------------------------
{
	my @imshow = ( plot_type => 'imshow', data => [ [ 1, 2 ], [ 3, 4 ] ] );
	dies_with(
		{ ncols => 2, nrows => 2, shared_colorbar => [ 0, 3 ], plots => [ {@imshow}, {@imshow}, {@imshow} ] },
		qr/the max "shared_colorbar" index 3 > than the max index of plots, 2/,
		'an index past the last plot is refused; no colorbar was drawn at all'
	);
}

# ----------------------------------------------------------------------------
# 5. NaN and infinity passed looks_like_number and broke the script.
# ----------------------------------------------------------------------------
{
	my ( $py, $file ) = gen( plot_type => 'plot', data => { A => [ [ 1, 2, 3 ], [ 1, 'NaN' + 0, 3 ] ] } );
	like( $py, qr/^y = \[1,float\('nan'\),3\]$/m, 'plot: a Perl NaN is written as float("nan"), not NaN' );
	parses_ok( $file, 'plot with NaN parses' );
	($py, $file) = gen( plot_type => 'imshow', data => [ [ 1, 'nan' ], [ 3, 'inf' ] ] );
	like( $py, qr/^d = np\.asarray\(d, dtype = float\)$/m, 'imshow: the data is converted to floats' );
	like( $py, qr/vmax = 3\b/, 'imshow: the color scale ends at the largest finite value, not at Inf' );
	is_deeply( b64_var( $py, 'd' ), [ [ 1, 'nan' ], [ 3, 'inf' ] ], 'imshow: NaN and inf travel as strings numpy reads, not as JSON null' );
	($py) = gen( plot_type => 'boxplot', data => { A => [ 1, 2, 'nan', 3 ] } );
	like( $py, qr/'A \(3\)'/, 'boxplot: NaN is left out, as undef is' );
	($py) = gen( plot_type => 'colored_table', data => { A => { A => 1, B => 'nan' }, B => { A => 2, B => 3 } } );
	like( $py, qr/^d\.append\(\[1,float\('nan'\)\]\)$/m, 'colored_table: a NaN cell is written as float("nan")' );
	dies_with( { plot_type => 'pie',    data => { A => 1, B => 'inf' } },       qr/"B" is not a finite number/, 'pie: an infinite wedge is refused' );
	dies_with( { plot_type => 'hist',   data => { A => [ 1, 'inf' ] } },         qr/infinite values, which hist_helper cannot bin/, 'hist: an infinity is refused' );
	dies_with( { plot_type => 'violin', data => { A => [ 1, 2, 'inf' ] } },      qr/infinite values, which violin_helper cannot draw/, 'violin: an infinity is refused' );
	SKIP: {
		skip( 'no matplotlib >= 3.10', 1 ) unless $mpl_available;
		($py, $file) = gen( plot_type => 'imshow', data => [ [ 1, 'nan' ], [ 3, 4 ] ] );
		like( run_py( $file, 'print("OK")' ), qr/^OK$/m, 'imshow with NaN runs; it died "Image data of dtype object"' );
	}
}

# ----------------------------------------------------------------------------
# 6. A native Latin-1 title was decoded as UTF-8 and became U+FFFD.
# ----------------------------------------------------------------------------
{
	my ($py) = gen( plot_type => 'bar', data => { A => 1 }, title => "Temperature (\xb0C)", ylabel => chr(176) . 'C' );
	like( $py, qr/set_title\('Temperature \(\x{b0}C\)'\)/, 'the degree sign of a title survives' );
	like( $py, qr/set_ylabel\('\x{b0}C'\)/,                 'the degree sign of a ylabel survives' );
	unlike( $py, qr/\x{fffd}/, 'no replacement character anywhere' );
	# kept: raw UTF-8 bytes in a title are still decoded (t/utf8.mojibake.t)
	($py) = gen( plot_type => 'bar', data => { A => 1 }, title => encode_utf8("\x{394}G") );
	like( $py, qr/set_title\('\x{394}G'\)/, 'a title in raw UTF-8 bytes is still decoded' );
}

# ----------------------------------------------------------------------------
# 7. Data keys in raw UTF-8 bytes came out as mojibake.
# ----------------------------------------------------------------------------
{
	my ( $rho, $tau ) = ( encode_utf8("\x{3c1}"), encode_utf8("\x{3c4}") );
	my ($py) = gen( plot_type => 'bar', data => { $rho => 1, $tau => 2 } );
	is_deeply( b64_var( $py, 'labels' ), [ "\x{3c1}", "\x{3c4}" ], 'bar: labels from raw-byte keys are the Greek letters' );
	($py) = gen( plot_type => 'boxplot', data => { $rho => [ 1, 2, 3 ] } );
	like( $py, qr/\['\x{3c1} \(3\)'\]/, 'boxplot: a tick label from a raw-byte key is the Greek letter' );
	($py) = gen( plot_type => 'plot', data => { $rho => [ [ 1, 2 ], [ 3, 4 ] ] } );
	like( $py, qr/label = '\x{3c1}'/, 'plot: a legend label from a raw-byte key is the Greek letter' );
}

# ----------------------------------------------------------------------------
# 8. An array of titles was written as "ARRAY(0x...)".
# ----------------------------------------------------------------------------
{
	my ($py) = gen( plot_type => 'plot', data => { A => [ [ 1, 2 ], [ 3, 4 ] ] }, set_title => [ 'First', 'Second' ] );
	like( $py, qr/set_title\('First'\).*set_title\('Second'\)/s, 'each title is written' );
	unlike( $py, qr/ARRAY\(0x/, 'no stringified array reference' );
	($py) = gen( ncols => 2, plots => [ { plot_type => 'bar', data => { A => 1 }, set_title => [ 'One', 'Two' ] }, { plot_type => 'bar', data => { A => 2 } } ] );
	like( $py, qr/ax0\.set_title\('One'\).*ax0\.set_title\('Two'\)/s, 'at a subplot too' );
}

# ----------------------------------------------------------------------------
# 9. imshow with a stringmap and a horizontal colorbar died.
# ----------------------------------------------------------------------------
{
	my %spec = (
		plot_type     => 'imshow',
		data          => [ [ 'H', 'E' ], [ 'E', 'C' ] ],
		stringmap     => { H => 'helix', E => 'strand', C => 'coil' },
		cborientation => 'horizontal',
	);
	my ( $py, $file ) = gen(%spec);
	like( $py, qr/^cbar\.set_ticklabels\(\['coil','strand','helix'\]\)$/m, 'the labels go through the colorbar, not its y axis' );
	SKIP: {
		skip( 'no matplotlib >= 3.10', 1 ) unless $mpl_available;
		like( run_py( $file, 'print("T", [t.get_text() for t in cbar.ax.get_xticklabels()])' ),
			qr/^T \['coil', 'strand', 'helix'\]$/m, 'a horizontal colorbar is labelled along x' );
	}
}

# ----------------------------------------------------------------------------
# 10. Documented options that were accepted and ignored.
# ----------------------------------------------------------------------------
{
	my ($py) = gen( plot_type => 'colored_table', data => { A => { A => 1 } }, cborientation => 'horizontal', cbpad => 0.2 );
	like( $py, qr/fig\.colorbar\(img, orientation = 'horizontal', pad = 0\.2\)/, 'colored_table: the colorbar options are written' );
	($py) = gen( plot_type => 'violin', data => { A => [ 1, 2, 3 ] }, edgecolor => 'red' );
	like( $py, qr/pc\.set_edgecolor\('red'\)/, 'violin: edgecolor is used' );
	unlike( $py, qr/set_edgecolor\('black'\)/, 'violin: and black is not' );
	my @scatter = ( plot_type => 'scatter', data => { x => [ 1, 2 ], y => [ 3, 4 ], z => [ 5, 6 ] } );
	($py) = gen( @scatter, colorbar_on => 0, cblabel => 'my label' );
	unlike( $py, qr/colorbar\(/, 'scatter: colorbar_on => 0 draws no colorbar' );
	($py) = gen( @scatter, cblabel => 'my label', cblocation => 'top' );
	like( $py, qr/fig\.colorbar\(im, label = 'my label' , location = 'top'\)/, 'scatter: cblabel and cblocation are used' );
	# kept: the default label is the color key
	($py) = gen(@scatter);
	like( $py, qr/fig\.colorbar\(im, label = 'z' \)/, 'scatter: the colorbar is still labelled with the color key' );
}

# ----------------------------------------------------------------------------
# 11. A mistyped keyword in twinx_args was dropped.
# ----------------------------------------------------------------------------
{
	dies_with(
		{ plot_type => 'plot', data => { A => [ [ 1, 2 ], [ 3, 4 ] ], B => [ [ 1, 2 ], [ 5, 6 ] ] }, twinx_args => { B => { ylable => 'oops' } } },
		qr/"ylable" isn't defined in plot_helper "twinx_args" for "B", perhaps you meant one of these defined keywords: \(ylabel/,
		'a typo in twinx_args is refused, with a suggestion'
	);
	my ($py) = lives( { plot_type => 'plot', data => { A => [ [ 1, 2 ], [ 3, 4 ] ], B => [ [ 1, 2 ], [ 5, 6 ] ] }, twinx_args => { B => { set_ylabel => 'ok' } } }, 'a correct twinx_args is taken' );
	# "twinx_ax0" since 0.319, when the twinned lines of an axes came to share
	# one twin; it was "twinx_ax0_<n>", one per line.
	like( $py // '', qr/twinx_ax0\.set_ylabel\('ok'\)/, 'and written on the twin' );
}

# ----------------------------------------------------------------------------
# 12. A single-set scatter whose keys name x and y of three was not colored.
# ----------------------------------------------------------------------------
{
	my ($py) = gen( plot_type => 'scatter', data => { a => [ 1, 2 ], b => [ 3, 4 ], c => [ 5, 6 ] }, keys => [ 'a', 'b' ] );
	like( $py, qr/^z = \[5,6\]$/m, 'the key left out of "keys" is the color' );
	like( $py, qr/scatter\(x, y, c = z/, 'and the points are colored by it' );
}

# ----------------------------------------------------------------------------
# 13. A word for sharex/sharey was written unquoted.
# ----------------------------------------------------------------------------
{
	my @plots = ( ncols => 2, plots => [ { plot_type => 'bar', data => { A => 1 } }, { plot_type => 'bar', data => { A => 2 } } ] );
	my ( $py, $file ) = gen( @plots, sharey => 'row', sharex => 1 );
	like( $py, qr/sharex = 1, sharey = 'row'/, 'sharey => "row" is quoted; sharex => 1 is left a number' );
	parses_ok( $file, 'the shared-axes script parses' );
	($py) = gen( @plots, sharex => 'True' );
	like( $py, qr/sharex = True, sharey = 0/, 'sharex => "True" is True, and sharey is 0 by default' );
	dies_with( { @plots, sharex => 'rows' }, qr/"sharex" is True or False/, 'a word matplotlib does not take is refused' );
}

# ----------------------------------------------------------------------------
# 14. bar refused error bars given as an array.
# ----------------------------------------------------------------------------
{
	my %bar = ( plot_type => 'bar', data => { A => 1, B => 2 } );
	my ($py) = gen( %bar, yerr => [ 0.1, 0.2 ] );
	like( $py, qr/yerr = \[0\.1,0\.2\]/, 'one error per bar' );
	($py) = gen( %bar, yerr => [ [ 0.1, 0.2 ], [ 0.3, 0.4 ] ] );
	like( $py, qr/yerr = \[\[0\.1,0\.2\],\[0\.3,0\.4\]\]/, 'lower and upper errors' );
	($py) = gen( %bar, yerr => { A => 0.5, B => [ 1, 2 ] } );
	like( $py, qr/yerr = \[\[0\.5,1\],\[0\.5,2\]\]/, 'a hash value of one number is symmetric' );
	# kept: the documented hash of pairs
	($py) = gen( %bar, yerr => { A => [ 1, 2 ], B => [ 3, 4 ] } );
	like( $py, qr/yerr = \[\[1,3\],\[2,4\]\]/, 'a hash of [ lower, upper ] pairs, as before' );
	dies_with( { %bar, yerr => [0.1] },          qr/"yerr" has 1 values in a row, but barplot_helper has 2 bars/, 'an array of the wrong length is refused' );
	dies_with( { %bar, yerr => { A => 1 } },     qr/the above keys have no "yerr"/,                                'a hash missing a key is refused by name' );
	dies_with( { %bar, yerr => 'x' },            qr/"yerr" must be numeric/,                                       'a word is refused' );
	dies_with( { %bar, linewidth => 'thick' },   qr/"linewidth" must be numeric/,                                  'a linewidth word is refused' );
}

# ----------------------------------------------------------------------------
# 15. Numeric options written into the script without a check.
# ----------------------------------------------------------------------------
{
	my @hist2d = ( plot_type => 'hist2d', data => { A => [ 1, 2, 3 ], B => [ 4, 5, 6 ] } );
	dies_with( { @hist2d, vmin => 'low' }, qr/"vmin" must be numeric for hist2d_helper/, 'hist2d: vmin must be a number' );
	dies_with( { @hist2d, cmax => 'lots' }, qr/"cmax" must be numeric for hist2d_helper/, 'hist2d: cmax must be a number' );
	my ($py) = gen( @hist2d, density => 1 );
	like( $py, qr/density = True/, 'hist2d: density => 1 is True' );
	dies_with( { plot_type => 'pie', data => { A => 1 }, labeldistance => 'far' }, qr/"labeldistance" must be numeric/, 'pie: labeldistance must be a number' );
	dies_with( { plot_type => 'hist', data => { A => [ 1, 2 ] }, alpha => 'half' }, qr/"alpha" must be numeric/, 'hist: alpha must be a number' );
	dies_with( { plot_type => 'venn_proportional_area', data => { A => [1], B => [2] }, alpha => 'half' }, qr/"alpha" must be numeric/, 'venn: alpha must be a number' );
}

# ----------------------------------------------------------------------------
# 16. A bad grid size or subplot died with a raw Perl error.
# ----------------------------------------------------------------------------
{
	dies_with( { ncols => 'two', plots => [ { plot_type => 'bar', data => { A => 1 } } ] }, qr/"ncols" = "two" must be a whole number of at least 1/, 'ncols => "two" is refused by name' );
	dies_with( { ncols => 'two', p => [ { plot_type => 'bar', data => { A => 1 } } ] },     qr/"ncols" = "two" must be a whole number/, 'and through "p"' );
	dies_with( { plots => [ [ 1, 2 ] ] }, qr/"plots" holds one HASH reference per subplot, but index 0 is not one/, 'a subplot that is not a hash is refused by name' );
}

# ----------------------------------------------------------------------------
# 17. A hist overlay reported two ranges; a single plot drew its legend twice.
# ----------------------------------------------------------------------------
{
	my ( $py, $file ) = gen(
		ncols => 2,
		plots => [
			{ plot_type => 'hist', data => { A => [ 1, 1, 2 ] }, add => [ { data => { B => [ 5, 5, 5, 5 ] } } ] },
			{ plot_type => 'bar',  data => { A => 1 } },
		],
	);
	my @starts  = $py =~ m/^(hist_counts0 = \[\])$/mg;
	my @reports = $py =~ m/(hist range)/g;
	is( scalar @starts,  1, 'the overlay and the plot share one list of bin heights' );
	is( scalar @reports, 1, 'and one range is reported' );
	SKIP: {
		skip( 'no matplotlib >= 3.10', 1 ) unless $mpl_available;
		like( run_py( $file, '' ), qr/^plot 0 hist range = \[0, 4\]$/m, 'the range includes the overlay\'s tallest bin' );
	}
	($py) = gen( plot_type => 'plot', data => { A => [ [ 1, 2 ], [ 3, 4 ] ] }, legend => "loc = 'upper left'" );
	my @legends = $py =~ m/(\.legend\()/g;
	is( scalar @legends, 1, 'a single plot writes its legend once' );
	like( $py, qr/^\tax0\.legend\(loc = 'upper left'\)$/m, 'inside the check for labels' );
}

# ----------------------------------------------------------------------------
# 18. cb_min, cb_max and cb_logscale were accepted and not read.
# ----------------------------------------------------------------------------
{
	my @scatter = ( plot_type => 'scatter', data => { x => [ 1, 2, 3 ], y => [ 1, 2, 3 ], z => [ 1, 10, 100 ] } );
	my ( $py, $file ) = gen( @scatter, cb_min => 5, cb_max => 50 );
	like( $py, qr/c = z, cmap = 'gist_rainbow', vmin = 5, vmax = 50 /, 'scatter: cb_min and cb_max set the ends of the scale' );
	($py) = gen( @scatter, cb_logscale => 1 );
	like( $py, qr/c = z, cmap = 'gist_rainbow', norm = LogNorm\(vmin = 1, vmax = 100\)/, 'scatter: cb_logscale colors through a LogNorm' );
	like( $py, qr/^from matplotlib\.colors import LogNorm$/m, 'scatter: and imports it' );
	($py) = gen( plot_type => 'scatter', cb_logscale => 1, data => { a => { x => [ 1, 2 ], y => [ 1, 2 ], z => [ 1, 10 ] }, b => { x => [3], y => [3], z => [100] } } );
	my @norms = $py =~ m/(norm = LogNorm\(vmin = 1, vmax = 100\))/g;
	is( scalar @norms, 2, 'scatter of several sets: one log scale over every set' );
	# kept: a scatter with none of them draws as before
	($py) = gen(@scatter);
	like( $py, qr/c = z, cmap = 'gist_rainbow' \)/, 'scatter: no scale is written unless one is asked for' );

	($py, $file) = gen( plot_type => 'imshow', data => [ [ 1, 2 ], [ 3, 40 ] ], cb_min => 2, cb_max => 30 );
	like( $py, qr/imshow\(d, aspect = 'auto' , vmin = 2, vmax = 30\)/, 'imshow: cb_min and cb_max are vmin and vmax' );
	($py) = gen( plot_type => 'imshow', data => [ [ 0, 2 ], [ 3, 40 ] ], cb_logscale => 1 );
	like( $py, qr/norm = LogNorm\(vmin = 2, vmax = 40\)/, 'imshow: a log scale starts at the smallest value above 0' );
	dies_with( { plot_type => 'imshow', data => [ [ 1, 2 ] ], cb_min => 1, vmin => 2 }, qr/"cb_min" and "vmin" both set the same end/, 'imshow: cb_min and vmin together are refused' );
	dies_with( { plot_type => 'imshow', data => [ [ 1, 2 ] ], vmin => 'low' }, qr/"vmin" must be numeric for imshow_helper/, 'imshow: vmin must be a number' );
	dies_with( { @scatter, cb_min => 'low' }, qr/"cb_min" must be numeric for scatter_helper/, 'scatter: cb_min must be a number' );
	dies_with(
		{ plot_type => 'imshow', data => [ [ 'H', 'E' ] ], stringmap => { H => 'helix', E => 'strand' }, cb_logscale => 1 },
		qr/"cb_logscale" means nothing for imshow_helper with a "stringmap"/,
		'imshow: a log scale of categories is refused'
	);
	dies_with( { plot_type => 'imshow', data => [ [ 0, -1 ] ], cb_logscale => 1 }, qr/"cb_logscale" needs a color value above 0/, 'imshow: a log scale with nothing above 0 is refused' );
	($py) = gen( plot_type => 'imshow', data => [ [ 'nan', 'nan' ] ] );
	unlike( $py, qr/vmin|vmax/, 'imshow: with no finite value the scale is left to matplotlib, not "vmin = inf"' );

	my %xy = ( x => [ 1 .. 20 ], y => [ map { $_ % 7 } 1 .. 20 ] );
	($py) = gen( plot_type => 'hexbin', data => {%xy}, cb_max => 3 );
	like( $py, qr/hexbin\(x, y .*, vmax = 3\)/, 'hexbin: cb_max is vmax' );
	($py) = gen( plot_type => 'hist2d', data => {%xy}, cb_min => 1, cb_logscale => 1 );
	like( $py, qr/norm = LogNorm\(vmin = 1\)/, 'hist2d: cb_min goes to the LogNorm, as vmin does' );
	SKIP: {
		skip( 'no matplotlib >= 3.10', 1 ) unless $mpl_available;
		($py, $file) = gen( @scatter, cb_logscale => 1, cb_max => 50 );
		like( run_py( $file, 'print("N", type(im.norm).__name__, im.norm.vmin, im.norm.vmax)' ), qr/^N LogNorm 1\.0 50\.0$/m, 'scatter: the drawn scale is the LogNorm asked for' );
	}
}

# ----------------------------------------------------------------------------
# 19. hist and violin accepted colorbar_on and drew no colorbar.
# ----------------------------------------------------------------------------
{
	dies_with( { plot_type => 'hist',   data => { A => [ 1, 2 ] }, colorbar_on => 0 }, qr/"colorbar_on" isn't defined for plot_type "hist"/,   'hist refuses colorbar_on' );
	dies_with( { plot_type => 'violin', data => { A => [ 1, 2 ] }, colorbar_on => 0 }, qr/"colorbar_on" isn't defined for plot_type "violin"/, 'violin refuses colorbar_on' );
}

# ----------------------------------------------------------------------------
# 20. Every plot type accepted "shared_colorbar" inside a subplot.
# ----------------------------------------------------------------------------
{
	my @bar = ( plot_type => 'bar', data => { A => 1 } );
	dies_with(
		{ ncols => 2, plots => [ { @bar, shared_colorbar => [ 0, 1 ] }, {@bar} ] },
		qr/"shared_colorbar" isn't defined for plot_type "bar"/,
		'a bar subplot refuses shared_colorbar, which it ignored'
	);
	# kept: it is still a figure-wide option of plt, and a single plot is
	# still warned about it rather than refused
	my @imshow = ( plot_type => 'imshow', data => [ [ 1, 2 ] ] );
	lives( { ncols => 2, shared_colorbar => [ 0, 1 ], plots => [ {@imshow}, {@imshow} ] }, 'shared_colorbar is still taken by plt' );
	my $warned = '';
	{
		local $SIG{__WARN__} = sub { $warned .= $_[0] };
		lives( { @bar, shared_colorbar => [ 0, 1 ] }, 'a single plot is still given shared_colorbar without dying' );
	}
	like( $warned, qr/shared colorbars make no sense/, 'and is warned that it means nothing there' );
}

done_testing();

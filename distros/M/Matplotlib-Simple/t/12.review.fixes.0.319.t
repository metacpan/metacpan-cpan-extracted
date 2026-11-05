#!/usr/bin/env perl
#
# The fixes of 0.319, one block each.
#
# They came out of a read of the whole of lib/Matplotlib/Simple.pm, as those
# of t/07.review.fixes.t, t/09.review.fixes.0.316.t and
# t/10.review.fixes.0.317.t did, and each was reproduced against the module as
# it stood before it was fixed. Blocks that also check behaviour the fix had to
# keep -- python of the caller's own in a title still passing through, a
# single twinned line still drawn on a twin -- say so where they do it.
#
# Most of this is execute => 0 and reads the generated python as text, so it
# runs everywhere, including a Windows smoker with no python. As in
# t/10.review.fixes.0.317.t, parses_ok needs python3 and run_py needs python3
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

my %two_lines = ( T => [ [ 1, 2, 3 ], [ 1, 2, 3 ] ], P => [ [ 1, 2, 3 ], [ 900, 950, 1000 ] ], H => [ [ 1, 2, 3 ], [ 10, 50, 90 ] ] );

# ----------------------------------------------------------------------------
# 1. A whole number with leading zeros was a SyntaxError.
# ----------------------------------------------------------------------------
{
	my ( $py, $file ) = gen( plot_type => 'bar', data => { A => '-007', B => '0010', C => '00.5', D => '000' } );
	like( $py, qr/^vals = \[-7,10,00\.5,0\]$/m, 'leading zeros are dropped from whole numbers, and a float is left alone' );
	parses_ok( $file, 'the bar script with zero-padded values parses' );
	($py) = gen( plots => [ { plot_type => 'bar', data => { A => 1 } }, { plot_type => 'bar', data => { A => 2 } } ], ncols => '02' );
	like( $py, qr/plt\.subplots\(1, 2, /, 'ncols => "02" is written as 2' );
}

# ----------------------------------------------------------------------------
# 2. Prose with an apostrophe or a comma, and an empty title.
# ----------------------------------------------------------------------------
{
	my ( $py, $file ) = gen( plot_type => 'bar', data => { A => 1 }, xlabel => "Bob's data", ylabel => 'Counts, by book', title => '' );
	like( $py, qr/set_xlabel\('Bob\\'s data'\)/,  'an apostrophe in prose is quoted, not left bare' );
	like( $py, qr/set_ylabel\('Counts, by book'\)/, 'a comma in prose is quoted' );
	like( $py, qr/set_title\(''\)/,                'an empty title is an empty string, not no argument' );
	parses_ok( $file, 'the prose labels parse' );
	# kept: python of the caller's own is left as it was written
	($py) = gen( plot_type => 'bar', data => { A => 1 }, xlabel => 'r"$\it{anno}$"', set_title => q{label = "x", loc = "left"}, ylabel => "'a, b', fontsize = 20" );
	like( $py, qr/set_xlabel\(r"\$\\it\{anno\}\$"\)/,          'a raw string literal is left alone' );
	like( $py, qr/set_title\(label = "x", loc = "left"\)/, 'keyword arguments are left alone' );
	like( $py, qr/set_ylabel\('a, b', fontsize = 20\)/,      'a quoted label with an option after it is left alone' );
}

# ----------------------------------------------------------------------------
# 3. A NUL in text was written into the script as it stood.
# ----------------------------------------------------------------------------
{
	my ( $py, $file ) = gen( plot_type => 'bar', data => { A => 1 }, title => "x\0y" );
	like( $py, qr/set_title\('x\\x00y'\)/, 'a NUL is written as \x00' );
	parses_ok( $file, 'a title holding a NUL parses' );
}

# ----------------------------------------------------------------------------
# 4. "width" was ignored by a simple bar plot, and not checked when stacked.
# ----------------------------------------------------------------------------
{
	my ($py) = gen( plot_type => 'bar', data => { A => 1, B => 2 }, width => 0.3 );
	like( $py, qr/ax0\.bar\(labels, vals .*width = 0\.3/, 'bar: width reaches the bars' );
	($py) = gen( plot_type => 'barh', data => { A => 1, B => 2 }, width => 0.3 );
	like( $py, qr/ax0\.barh\(labels, vals .*height = 0\.3/, 'barh: width is matplotlib\'s height' );
	dies_with( { plot_type => 'bar', data => { A => [ 1, 2 ], B => [ 3, 4 ] }, stacked => 1, width => 'wide' },
		qr/"width" must be numeric/, 'a word for width is refused by name' );
	dies_with( { plot_type => 'bar', data => { A => 1 }, width => 'inf' }, qr/"width" must be a finite number/, 'an infinite width is refused' );
	($py) = gen( plot_type => 'bar', data => { A => [ 1, 2 ], B => [ 3, 4 ] }, stacked => 1, width => '0.50' );
	like( $py, qr/width = 0\.50 /, 'kept: a stacked plot still takes width' );
}

# ----------------------------------------------------------------------------
# 5. An "edgecolor" hash was dropped.
# ----------------------------------------------------------------------------
{
	my ($py) = gen( plot_type => 'bar', data => { A => 1, B => 2 }, edgecolor => { B => 'blue', A => 'red' } );
	like( $py, qr/edgecolor = \['red','blue'\]/, 'an edgecolor hash is one color per bar, in key order' );
	dies_with( { plot_type => 'bar', data => { A => 1, B => 2 }, edgecolor => { A => 'red' } },
		qr/no color defined in "edgecolor"/, 'a bar left out of the edgecolor hash is named' );
	dies_with( { plot_type => 'bar', data => { A => [ 1, 2 ], B => [ 3, 4 ] }, edgecolor => { A => 'red', B => 'blue' } },
		qr/"edgecolor" is a HASH, which is keyed by bar/, 'a grouped plot refuses an edgecolor hash by name' );
}

# ----------------------------------------------------------------------------
# 6. A "color" hash for boxplot or violin was written as 'HASH(0x...)'.
# ----------------------------------------------------------------------------
{
	foreach my $type ( 'boxplot', 'violin' ) {
		dies_with( { plot_type => $type, data => { A => [ 1, 2, 3 ] }, color => { A => 'red' } },
			qr/"color" is one color for every .* "colors"/, "$type: a color hash is refused, pointing to \"colors\"" );
	}
}

# ----------------------------------------------------------------------------
# 7. Inner keys differing only in case came out in hash order.
# ----------------------------------------------------------------------------
{
	my ($py) = gen( plot_type => 'bar', data => { A => { a => 1, A => 2 }, B => { a => 3, A => 4 } } );
	like( $py, qr/label = 'A'.*\n.*label = 'a'/, '"A" is drawn before "a" every time' );
}

# ----------------------------------------------------------------------------
# 8. "stacked" was compared with "==".
# ----------------------------------------------------------------------------
{
	my %grouped = ( plot_type => 'bar', data => { A => [ 1, 2 ], B => [ 3, 4 ] } );
	my ($py) = gen( %grouped, stacked => 'True' );
	like( $py, qr/bottom = \[/, 'stacked => "True" stacks' );
	($py) = gen( %grouped, stacked => 'False' );
	unlike( $py, qr/bottom = \[/, 'stacked => "False" does not' );
	dies_with( { %grouped, stacked => 'maybe' }, qr/"stacked" is True or False/, 'stacked => "maybe" is refused by name' );
}

# ----------------------------------------------------------------------------
# 9. Grouped bars with nothing in them.
# ----------------------------------------------------------------------------
{
	dies_with( { plot_type => 'bar', data => { A => [], B => [] } }, qr/every key of "data" holds an empty array/, 'all-empty groups are refused by name' );
}

# ----------------------------------------------------------------------------
# 10. boxplot's switches were written as given.
# ----------------------------------------------------------------------------
{
	my ( $py, $file ) = gen( plot_type => 'boxplot', data => { A => [ 1, 2, 3 ] }, notch => 'false', showmeans => 0 );
	like( $py, qr/showmeans = False, notch = False/, '"false" and 0 are False' );
	parses_ok( $file, 'the boxplot with lower-case false parses' );
	dies_with( { plot_type => 'boxplot', data => { A => [ 1, 2, 3 ] }, notch => 'maybe' }, qr/"notch" is True or False/, 'notch => "maybe" is refused' );
}

# ----------------------------------------------------------------------------
# 11. Twinned series each got a twin of their own, and were in no legend.
# ----------------------------------------------------------------------------
{
	my ( $py, $file ) = gen( plot_type => 'plot', data => \%two_lines, twinx => { P => 1, H => 1 } );
	my $n_twins = () = $py =~ m/\.twinx\(\)/g;
	is( $n_twins, 1, 'two twinned series share one twin' );
	like( $py, qr/twinx_ax0\.plot\(x, y ,label = 'H'/, 'H is on the twin' );
	like( $py, qr/twinx_ax0\.plot\(x, y ,label = 'P'/, 'and so is P' );
	like( $py, qr/twinx_ax0\.legend\(handles, labels\)/, 'one legend, on the twin, with both axes\' lines' );
	parses_ok( $file, 'the twinned script parses' );
	SKIP: {
		skip( 'needs matplotlib >= 3.10', 2 ) unless $mpl_available;
		my $out = run_py( $file, 'print(len(fig.axes)); print(sorted(t.get_text() for t in twinx_ax0.get_legend().get_texts()))' );
		like( $out, qr/^2$/m, 'the figure has two axes, not three' );
		like( $out, qr/\['H', 'P', 'T'\]/, 'the legend lists every series' );
	}
	# with "twinx_args": still one legend, rather than a second over the first
	($py) = gen( plot_type => 'plot', data => \%two_lines, twinx => 'P', twinx_args => { P => { set_ylabel => 'hPa' } } );
	my $n_legends = () = $py =~ m/\.legend\(/g;
	is( $n_legends, 1, 'twinx_args draws no second legend' );
	like( $py, qr/twinx_ax0\.set_ylabel\('hPa'\)/, 'kept: twinx_args still reaches the twin' );
	# the array form, too
	($py) = gen( plot_type => 'plot', data => [ [ [ 1, 2 ], [ 3, 4 ] ], [ [ 1, 2 ], [ 5, 6 ] ], [ [ 1, 2 ], [ 7, 8 ] ] ], twinx => [ 1, 2 ] );
	$n_twins = () = $py =~ m/\.twinx\(\)/g;
	is( $n_twins, 1, 'array data: two twinned lines share one twin' );
}

# ----------------------------------------------------------------------------
# 12. A twinx index past the last line was ignored.
# ----------------------------------------------------------------------------
{
	my @lines = ( [ [ 1, 2 ], [ 3, 4 ] ], [ [ 1, 2 ], [ 5, 6 ] ] );
	dies_with( { plot_type => 'plot', data => [@lines], twinx => 5 }, qr/names line 5, but "data" has 2 lines/, 'twinx => 5 of 2 lines is refused' );
	dies_with( { plot_type => 'plot', data => [@lines], twinx_args => { 7 => { set_ylabel => 'x' } } }, qr/names line 7/, 'a twinx_args index past the end is refused' );
}

# ----------------------------------------------------------------------------
# 13. hist: an orientation hash, and set names that are not sets.
# ----------------------------------------------------------------------------
{
	my %hist = ( plot_type => 'hist', data => { A => [ 1, 2, 3 ], B => [ 2, 3, 4 ] } );
	dies_with( { %hist, orientation => { A => 'horizontal' } }, qr/"orientation" is one of .* for every set/, 'an orientation hash is refused' );
	dies_with( { %hist, color => { A => 'red', b => 'blue' } }, qr/keys of "color" are not sets of "data"/, 'a color for a set that does not exist is refused' );
	dies_with( { %hist, bins => { C => 5 } }, qr/keys of "bins" are not sets of "data"/, 'and so are bins' );
	my ($py) = gen( %hist, key_order => [ 'B', 'A' ] );
	like( $py, qr/label = 'B'.*\n(?:.*\n)*.*label = 'A'/, 'hist takes key_order' );
}

# ----------------------------------------------------------------------------
# 14. Numbers that looks_like_number takes but Python does not.
# ----------------------------------------------------------------------------
{
	my ($py) = gen( plot_type => 'hexbin', data => { X => [ 1, 2, 3 ], Y => [ 1, 2, 3 ] }, vmax => 'inf' );
	like( $py, qr/vmax = float\('inf'\)/, 'hexbin: vmax => "inf" is float(\'inf\'), not a bare name' );
	($py) = gen( plot_type => 'hist2d', data => { X => [ 1, 2, 3 ], Y => [ 1, 2, 3 ] }, cb_logscale => 1, vmax => 'inf' );
	like( $py, qr/LogNorm\(vmax = float\('inf'\)\)/, 'hist2d: a log scale\'s vmax => "inf" too' );
	($py) = gen( plot_type => 'hist', data => { A => [ 1, 2 ] }, alpha => 'nan' );
	like( $py, qr/alpha = float\('nan'\)/, 'hist: alpha => "nan" too' );
	dies_with( { plot_type => 'colored_table', data => { A => { A => 1, B => 2 } }, cb_max => 'inf' }, qr/"cb_max" = inf must be a finite number/, 'colored_table: an infinite end is refused' );
	dies_with( { plot_type => 'bar', data => { A => 1 }, scale => 'inf' }, qr/"scale" must be a finite number above 0/, 'an infinite scale is refused' );
	dies_with( { plot_type => 'hexbin', data => { X => [ 1, 2 ], Y => [ 1, 2 ] }, cb_logscale => 1, vmin => 0 }, qr/cannot start at "vmin" = 0/, 'hexbin: a log scale from 0 is refused' );
}

# ----------------------------------------------------------------------------
# 15. hist2d's range ends were never checked.
# ----------------------------------------------------------------------------
{
	my %h2 = ( plot_type => 'hist2d', data => { X => [ 0, 1, 2 ], Y => [ 1, 2, 3 ] } );
	dies_with( { %h2, xmin => 'a' }, qr/"xmin" must be numeric/, 'xmin => "a" is refused by name' );
	dies_with( { %h2, logscale => ['x'] }, qr/puts x on a log scale, which cannot start at 0/, 'a log axis reaching 0 is refused' );
	dies_with( { plot_type => 'hist2d', data => { X => [ 'nan', 'nan' ], Y => [ 1, 2 ] } }, qr/"X" has no finite value/, 'a column with no finite value is refused' );
	dies_with( { %h2, xmin => 5, xmax => 1 }, qr/"xmin" = 5 is above "xmax" = 1/, 'a backwards range is refused' );
	my ( $py, $file ) = gen( %h2, xmin => '-01', logscale => ['y'] );
	like( $py, qr/range = \[\(-1, 2\), \(1, 3\)\]/, 'the range is written through py_num' );
	parses_ok( $file, 'the hist2d script parses' );
	dies_with( { %h2, xbins => -3 }, qr/"xbins" must be a whole number of at least 1/, 'a negative bin count is refused' );
}

# ----------------------------------------------------------------------------
# 16. colored_table's switches were tested for Perl truth, or with ">".
# ----------------------------------------------------------------------------
{
	my %table = ( plot_type => 'colored_table', data => { A => { B => 1 }, B => { C => 2 } } );
	my ($py) = gen( %table, mirror => 'True', show_numbers => 'False', colorbar_on => 'False' );
	like( $py, qr/colLabels = \['A','B','C'\]/, 'mirror => "True" mirrors' );
	unlike( $py, qr/cellText/, 'show_numbers => "False" shows none' );
	unlike( $py, qr/fig\.colorbar/, 'colorbar_on => "False" draws none' );
}

# ----------------------------------------------------------------------------
# 17. A single plot and "plots" both given.
# ----------------------------------------------------------------------------
{
	my @plots = ( { plot_type => 'bar', data => { A => 1 } } );
	dies_with( { plot_type => 'bar', data => { A => 1 }, plots => [@plots] }, qr/"plot_type" and "data" belong to a single plot/, 'a single plot beside "plots" is refused' );
	dies_with( { plot_type => 'bar', plots => [@plots] }, qr/"plot_type" belongs to a single plot/, 'so is half of one' );
}

# ----------------------------------------------------------------------------
# 18. Keywords at the top of a figure of several subplots.
# ----------------------------------------------------------------------------
{
	my %fig = ( ncols => 2, plots => [ { plot_type => 'bar', data => { A => 1 } }, { plot_type => 'bar', data => { A => 2 }, title => 'second' } ] );
	dies_with( { %fig, title => 'TOP' }, qr/"title" acts on one subplot.*"suptitle"/, 'a top-level title is refused, pointing to suptitle' );
	dies_with( { %fig, xscale => 'log' }, qr/"xscale" acts on one subplot/, 'so is xscale' );
	dies_with( { %fig, color => 'red' }, qr/"color" belongs to one subplot/, 'a plot option is refused' );
	dies_with( { %fig, set_xlabel => 'Q' }, qr/"set_xlabel" belongs to one subplot/, 'so is an axes method' );
	dies_with( { %fig, add => [ { plot_type => 'plot', data => { B => [ [1], [1] ] } } ] }, qr/"add" belongs to one subplot/, 'so is "add"' );
	dies_with( { %fig, cbpad => 0.1 }, qr/"cbpad" at the top of a figure only places a "shared_colorbar"/, 'cbpad without shared_colorbar is refused' );
	# kept: figure-wide options
	my ($py) = lives( { %fig, suptitle => 'All', set_figwidth => 12, sharey => 1 }, 'suptitle, a fig. method and sharey are still taken' );
	like( $py // '', qr/plt\.suptitle\('All'\)/, 'and suptitle is written' );
	like( $py // '', qr/set_title\('second'\)/, 'and the subplot keeps its own title' );
}

# ----------------------------------------------------------------------------
# 19. venn_proportional_area options of the wrong shape.
# ----------------------------------------------------------------------------
{
	my %venn = ( plot_type => 'venn_proportional_area', data => { A => [ 1, 2 ], B => [ 2, 3 ] } );
	dies_with( { %venn, key_order => [ 'A', 'A' ] }, qr/"key_order" names "A" more than once/, 'a repeated key is refused' );
	dies_with( { %venn, key_order => 'A' }, qr/"key_order" is an array of keys of "data"/, 'a string key_order is refused' );
	dies_with( { %venn, set_colors => 'red' }, qr/"set_colors" is an array of one color per set .* 2 sets/, 'a string set_colors is refused' );
	dies_with( { %venn, set_colors => ['red'] }, qr/"set_colors" is an array of one color per set/, 'one color for two sets is refused' );
	dies_with( { plot_type => 'venn_proportional_area', data => [ 1, 2 ] }, qr/takes a hash of sets/, 'array data is refused' );
}

# ----------------------------------------------------------------------------
# 20. "add" holding something other than hashes.
# ----------------------------------------------------------------------------
{
	dies_with( { plot_type => 'bar', data => { A => 1 }, add => [1] }, qr/"add" holds one HASH reference per graph, but index 0/, 'a single plot' );
	dies_with( { plots => [ { plot_type => 'bar', data => { A => 1 }, add => [ {}, 'x' ] } ] }, qr/"add" at subplot 0 holds one HASH reference per graph, but index 1/, 'a subplot' );
	dies_with( { plots => [ { plot_type => 'bar', data => { A => 1 }, add => { plot_type => 'bar' } } ] }, qr/"add" at subplot 0 must be an array/, 'a hash for "add" at a subplot' );
}

# ----------------------------------------------------------------------------
# 21. sharex and sharey on a single plot.
# ----------------------------------------------------------------------------
{
	my ( $out, $err, $file ) = capture { plt( plot_type => 'bar', data => { A => 1 }, sharex => 1, output_file => out_file(), execute => 0 ) };
	like( $err, qr/"sharex" shares an axis between subplots, but there is only 1 plot/, 'a single plot warns' );
	unlike( slurp($file), qr/\.sharex\(/, 'and writes no ax0.sharex(1)' );
}

# ----------------------------------------------------------------------------
# 22. "execute" was compared with "==".
# ----------------------------------------------------------------------------
{
	my $died = '';
	capture { $died = eval { plt( plot_type => 'bar', data => { A => 1 }, output_file => out_file(), execute => 'yes' ); 1 } ? '' : "$@" };
	like( $died, qr/"execute" is True or False/, 'execute => "yes" is refused by name' );
	my ( $out, $err, $file ) = capture { plt( plot_type => 'bar', data => { A => 1 }, output_file => out_file(), execute => 'False' ) };
	like( slurp($file), qr/^plt\.close\(\)$/m, 'execute => "False" writes the script without running it' );
	# A file called "0" is a file like any other. Not run, so nothing is written.
	( $out, $err, $file ) = capture { plt( plot_type => 'bar', data => { A => 1 }, output_file => '0', execute => 0 ) };
	ok( -e $file, 'output_file => "0" is taken' );
}

# ----------------------------------------------------------------------------
# 23. scatter: labels, show_legend, set order and set_options.
# ----------------------------------------------------------------------------
{
	my %sets = ( plot_type => 'scatter', data => { A => { x => [ 1, 2 ], y => [ 3, 4 ] }, B => { x => [ 2, 3 ], y => [ 1, 1 ] } } );
	my ( $py, $file ) = gen( %sets, set_options => { A => 'label="first"' } );
	unlike( $py, qr/label = 'A'/, 'a set\'s own label is not doubled' );
	like( $py, qr/ax0\.scatter\(x, y, label="first"\)/, 'it is used as given' );
	parses_ok( $file, 'the scatter with its own label parses' );
	($py) = gen( %sets, show_legend => 0 );
	unlike( $py, qr/label = /, 'show_legend => 0 labels nothing' );
	($py) = gen( %sets, key_order => [ 'B', 'A' ] );
	like( $py, qr/label = 'B'.*\n(?:.*\n)*.*label = 'A'/, 'key_order orders the sets' );
	dies_with( { %sets, set_options => 'color="red"' }, qr/"set_options" is a hash of one string of options per set/, 'a string set_options for several sets is refused' );
	dies_with( { plot_type => 'scatter', data => { x => [ 1, 2 ], y => [ 3, 4 ] }, set_options => { x => 'a' } }, qr/"set_options" is one string of options/, 'a hash set_options for one set is refused' );
	dies_with( { plot_type => 'scatter', data => { x => [ 1, 2, 3 ], y => [ 3, 4 ] } }, qr/must all have the same number of values, but "x" has 3, "y" has 2/, 'x and y of different lengths are refused' );
	dies_with( { %sets, data => { A => { x => [ 1, 2 ], y => [ 3, 4 ], z => [1] } } }, qr/the axes of set "A" must all have the same number/, 'a short color axis is refused' );
}

# ----------------------------------------------------------------------------
# 24. Subplots sharing a colorbar each had a color scale of their own.
# ----------------------------------------------------------------------------
{
	my ( $py, $file ) = gen(
		ncols           => 2,
		shared_colorbar => [ 0, 1 ],
		plots           => [
			{ plot_type => 'scatter', data => { x => [ 1, 2 ], y => [ 1, 2 ], z => [ 1, 2 ] } },
			{ plot_type => 'scatter', data => { x => [ 1, 2 ], y => [ 1, 2 ], z => [ 10, 20 ] } },
		],
	);
	like( $py, qr/m\.set_clim\(shared_lo, shared_hi\)/, 'the subplots are put on one scale' );
	parses_ok( $file, 'the shared-scale script parses' );
	SKIP: {
		skip( 'needs matplotlib >= 3.10', 1 ) unless $mpl_available;
		my $out = run_py( $file, 'print([tuple(m.get_clim()) for a in fig.axes[:2] for m in a.collections])' );
		like( $out, qr/\[\(1\.0, 20\.0\), \(1\.0, 20\.0\)\]/, 'both scatters run from 1 to 20' );
	}
	($py) = gen(
		ncols           => 2,
		shared_colorbar => [ 0, 1 ],
		plots           => [
			{ plot_type => 'colored_table', data => { A => { A => 1, B => 2 } } },
			{ plot_type => 'colored_table', data => { A => { A => 10, B => 20 } } },
		],
	);
	my $n_norms = () = $py =~ m/plt\.Normalize\(1, 20\)/g;
	is( $n_norms, 2, 'two tables sharing a colorbar share one scale' );
}

# ----------------------------------------------------------------------------
# 25. wide: a non-finite x.
# ----------------------------------------------------------------------------
{
	dies_with( { plot_type => 'wide', data => [ [ [ 'inf', 2 ], [ 1, 2 ] ] ] }, qr/x value\(s\) that are not finite: "inf"/, 'an infinite x is refused' );
	dies_with( { plot_type => 'wide', data => [ [ [ 1, 2 ], [ 1, '-inf' ] ] ] }, qr/infinite y value\(s\)/, 'an infinite y is refused' );
}

# ----------------------------------------------------------------------------
# 26. df: groups out of numeric order, an undefined row, an empty table.
# ----------------------------------------------------------------------------
{
	my @rows = map { { g => $_ % 2 ? 10 : 2, v => $_, w => $_ * 2 } } 1 .. 6;
	my ($py) = gen( plot_type => 'hist', df => [@rows], x => 'v', by => 'g' );
	like( $py, qr/label = '2'.*\n(?:.*\n)*.*label = '10'/, 'hist: groups by "by" in numeric order' );
	($py) = gen( plot_type => 'scatter', df => [@rows], x => 'v', y => 'w', by => 'g' );
	like( $py, qr/label = '2'.*\n(?:.*\n)*.*label = '10'/, 'scatter: groups by "by" in numeric order' );
	# plt, not gen: gen captures STDERR, and with it the warning
	my ( $out, $err, $file ) = capture { plt( plot_type => 'bar', df => [ undef, [ 'a', 1 ], [ 'b', 2 ] ], x => 0, y => 1, output_file => out_file(), execute => 0 ) };
	like( slurp($file), qr/^vals = \[1,2\]$/m, 'an undefined row of an array of arrays is a row with no values' );
	like( $err, qr/left out 1 of 3 rows/, 'and is counted as left out' );
	( $out, $err, $file ) = capture { plt( plot_type => 'bar', df => [ undef, { n => 'a', v => 1 } ], x => 'n', y => 'v', output_file => out_file(), execute => 0 ) };
	like( slurp($file), qr/^vals = \[1\]$/m, 'so is one of an array of hashes' );
	dies_with( { plot_type => 'colored_table', df => { r1 => {}, r2 => {} } }, qr/has no columns to put in the table/, 'an empty hash of hashes is refused by the intended message' );
}

# ----------------------------------------------------------------------------
# 27. Values matplotlib refused from inside itself.
# ----------------------------------------------------------------------------
{
	dies_with( { plot_type => 'pie', data => { A => 1, B => -1 } }, qr/cannot size a wedge below 0/, 'pie: a negative wedge' );
	dies_with( { plot_type => 'pie', data => { A => 0, B => 0 } }, qr/every wedge of pie_helper is 0/, 'pie: no pie at all' );
	dies_with( { plot_type => 'imshow', data => [ [ 1, 2, 3 ], [ 4, 5 ] ] }, qr/rows of "data" have different lengths \(3, 2\)/, 'imshow: a ragged image' );
	dies_with( { plot_type => 'imshow', data => [ [ 1, undef ], [ 3, 4 ] ] }, qr/undefined cell, and "data" has them at \[0\]\[1\]/, 'imshow: an undefined cell is named' );
}

# ----------------------------------------------------------------------------
# 28. Ordering options of the wrong shape, and violin's switches.
# ----------------------------------------------------------------------------
{
	dies_with( { plot_type => 'bar', data => { A => 1, B => 2 }, key_order => [] }, qr/"key_order" is an empty array/, 'an empty key_order is refused' );
	dies_with( { plot_type => 'bar', data => { A => 1, B => 2 }, key_order => [ 'A', 'B', 'A' ] }, qr/names "A" more than once/, 'a bar drawn twice is refused' );
	dies_with( { plot_type => 'violin', data => { A => [ 1, 2, 3 ] }, medians => 'yes' }, qr/"medians" is True or False/, 'violin: medians => "yes" is refused' );
	my ($py) = gen( plot_type => 'violin', data => { A => [ 1, 2, 3 ] }, medians => 'False', whiskers => 'False' );
	like( $py, qr/showmedians = False/, 'violin: medians => "False" is False' );
	unlike( $py, qr/adjacent_values/, 'violin: whiskers => "False" draws none' );
}

# ----------------------------------------------------------------------------
# 29. imshow's first stringmap category reached JSON::XS as the string "0".
#
# Reported from HitList's conda install on 2026-10-05, whose perl had JSON::XS
# 4.04 and, when this distribution was tested, no Cpanel::JSON::XS, so
# JSON::MaybeXS used JSON::XS: test 47 of t/10.review.fixes.0.317.t and
# t/01.all.tests.t died as "Image data of dtype <U21 cannot be converted to
# float". It was first put down to numpy 2.5.3, which the same install
# brought; with numpy 2.5.3 it passes under Cpanel::JSON::XS 4.43 and JSON::PP
# 4.16, and fails under JSON::XS 4.04.
#
# Each backend JSON::MaybeXS would choose is tried that is installed.
# JSON::MaybeXS->new builds an object of the class in $JSON_Class, which it
# reads at each call, so a local class there is the backend write_data uses;
# a backend is skipped if that stops being so. JSON::XS before 3.0 is skipped
# because JSON::MaybeXS never chooses it.
# ----------------------------------------------------------------------------
foreach my $backend ( [ 'Cpanel::JSON::XS', 0 ], [ 'JSON::XS', 3.0 ], [ 'JSON::PP', 0 ] ) {
	my ( $class, $min_version ) = @{$backend};
	SKIP: {
		skip( "no $class $min_version", 2 ) unless eval "require $class; $class->VERSION($min_version); 1";
		local $JSON::MaybeXS::JSON_Class = $class;
		skip( 'JSON::MaybeXS no longer reads $JSON_Class in new()', 2 ) unless JSON::MaybeXS->new->isa($class);
		my ( $py, $file ) = gen(
			plot_type => 'imshow',
			data      => [ [ 'H', 'E' ], [ 'E', 'C' ] ],
			stringmap => { H => 'helix', E => 'strand', C => 'coil' },
		);
		my ($b64) = $py =~ m/^d_b64 = '([^']*)'$/m;
		is( decode_base64( $b64 // '' ), '[[2,1],[1,0]]', "imshow: $class writes every category as a number" );
		SKIP: {
			skip( 'no matplotlib >= 3.10', 1 ) unless $mpl_available;
			like( run_py( $file, 'print("A", im0.get_array().dtype.kind)' ), qr/^A [iuf]$/m, "imshow: and draws them as numbers under $class" );
		}
	}
}

done_testing();

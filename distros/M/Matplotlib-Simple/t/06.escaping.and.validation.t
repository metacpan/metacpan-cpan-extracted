#!/usr/bin/env perl
#
# Text that is data, and data that is wrong.
#
# Two classes of bug, both fixed in 0.3132, both invisible to the other test
# files because every one of them plots keys named "A" and "B".
#
# 1. Anything the caller names -- a data key, a tick label, a member of a venn
#    set -- is written into the generated python as text.  It used to be
#    written into a double-quoted literal by hand, '["' . join('","', @keys)
#    . '"]', which a key holding a double quote turns into a SyntaxError and a
#    key holding a backslash turns into something worse: python reads the "\a"
#    of '$\alpha$' as a bell character, so the label is silently wrong and the
#    script still parses.  py_str/py_list now escape all of it.
#
# 2. Data that cannot be drawn used to reach matplotlib, or reach perl's own
#    runtime, rather than being refused here: a non-numeric bar height became
#    the bare python name "abc", a "key_order" naming a key that "data" does
#    not have died as "Use of uninitialized value in join or string", and a
#    logscale of "xy" emitted ax.set_xyscale("log").  Every one of these now
#    dies naming the key, the option and the plot type.
#
# Section 7 adds a third, from 0.319: a keyword spelled the pre-0.319 way, with
# a dot, is refused with the name it has now.
#
# The python parser gate is the same as t/05.generated.python.t's and is
# skipped the same way when python3 is absent; everything else here is
# execute => 0 and runs everywhere, which is the part a Windows smoker sees.
#
require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Temp 'tempdir';
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

my $TMP = tempdir( CLEANUP => 1 );
my $seq = 0;

my $python_raw = ( scalar @PY ? do { no warnings 'exec'; qx/$PY --version 2>&1/ } // '' : '' );    # 'exec': see t/16.creator.t
my $python_available = ( $? == 0 && $python_raw =~ m/Python\s+3\.\d+/i ) ? 1 : 0;
diag( $python_available ? "Python 3 found as \"$PY\" (parser gate ON)" : 'no Python 3 (parser gate skipped)' );

my $PARSE = q{import ast, sys; ast.parse(open(sys.argv[1], encoding='utf-8').read())};

# Build one figure with execute => 0 and return the generated python as text.
sub gen {
	my (%spec) = @_;
	$spec{output_file} = File::Spec->catfile( $TMP, 'gen' . $seq++ . '.svg' );
	$spec{execute} = 0;
	my ( $out, $err, $pyfile ) = capture { plt( \%spec ) };
	open my $in, '<:encoding(UTF-8)', $pyfile or die "can't read $pyfile: $!";
	local $/;
	my $text = <$in>;
	close $in;
	return ( $text, $pyfile );
}

# Whether the figure this spec describes dies, and with what.
#
# The message alone, not the whole exception: the module loads Devel::Confess,
# whose stack trace prints every frame's arguments, and one of this frame's
# arguments is $like itself.  Matching "$@" matches the pattern against a copy
# of the pattern, so every assertion of this shape passes whatever the code
# does -- which is how the first draft of this file came to hold ten tests that
# could not fail.  t/03.coverage.t's dies_like has said so since 0.312, and
# t/04.options.t was fixed for it in 0.313.  The trace begins at the first
# tab-indented line.
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

my @g1 = ( 1, 2, 2, 3, 3, 3, 4, 4, 5 );
my @g2 = ( 2, 3, 3, 4, 4, 5, 5, 6, 7 );
my @xs = 1 .. 10;
my @cx = 1 .. 30;
my @cy = map { $_ % 5 } 1 .. 30;

# ----------------------------------------------------------------------------
# 1. A data key is text, and text has to be escaped.
#
#    One key per case holds a double quote; the whole script has to parse, and
#    the label has to arrive with the quote still in it.
# ----------------------------------------------------------------------------
my $QUOTED = 'say "hi"';
my %ESCAPE = (    # plot type => the spec that puts $QUOTED on an axis
	bar           => { data => { $QUOTED => [ 1, 2 ], B => [ 3, 4 ] } },    # grouped: tick labels
	boxplot       => { data => { $QUOTED => [@g1] } },
	violin        => { data => { $QUOTED => [@g1] } },
	colored_table => { data => { $QUOTED => { $QUOTED => 1 } } },
	pie           => { data => { $QUOTED => 1, B => 2 } },
	hist          => { data => { $QUOTED => [@g1] } },
	plot          => { data => { $QUOTED => [ [@xs], [@xs] ] } },
	scatter       => { data => { Set1 => { X => [@cx], Y => [@cy] } } },
	venn_proportional_area =>
	 { data => { $QUOTED => [qw(a b c)], Other => [qw(b c d)] } },
);
foreach my $type ( sort keys %ESCAPE ) {
	my ( $py, $file ) = gen( plot_type => $type, %{ $ESCAPE{$type} } );
	parses_ok( $file, "$type: a data key holding a double quote parses" );
	unlike( $py, qr/"say "hi""/, "$type: the quote is not left bare in a literal" );
}

# A backslash is the silent one: "$\alpha$" is mathtext, and a python
# double-quoted literal reads its "\a" as a bell.  The escaped form is what
# matplotlib has to receive.
{
	my ( $py, $file ) = gen(
		plot_type => 'boxplot',
		data        => { '$\alpha$' => [@g1] }
	);
	parses_ok( $file, 'boxplot: a mathtext key parses' );
	like( $py, qr/\$\\\\alpha\$/, 'boxplot: the backslash of a mathtext key is escaped' );
}

# venn writes its set *members*, not only its labels.
{
	my ( $py, $file ) = gen(
		plot_type => 'venn_proportional_area',
		data        => { Left => [ 'a"b', 'c' ], Right => [ 'c', 'd' ] }
	);
	parses_ok( $file, 'venn: a set member holding a double quote parses' );
}

# imshow's cblabel is prose, and was the one colorbar label written without
# py_str: an apostrophe closed the literal early.
{
	my ( $py, $file ) = gen(
		plot_type => 'imshow',
		data        => [ [ 1, 2 ], [ 3, 4 ] ],
		cblabel     => "Farmer's yield"
	);
	parses_ok( $file, 'imshow: an apostrophe in cblabel parses' );
}

# ----------------------------------------------------------------------------
# 2. imshow's string data: one category, and more categories than the default
#    property cycle has colors.
# ----------------------------------------------------------------------------
{
	my ( $py, $file ) = gen(
		plot_type => 'imshow',
		data        => [ [ 'H', 'H' ], [ 'H', 'H' ] ],
		stringmap   => { H => 'Alpha helix' }
	);
	parses_ok( $file, 'imshow: a single string category parses' );
	like( $py, qr/ticks = \[0\]/, 'imshow: one category puts its one tick at 0' );
}
{	# two categories: the formula this replaced returned 0.5 for both of them,
	# so the colorbar carried two ticks in the same place
	my ( $py, $file ) = gen(
		plot_type => 'imshow',
		data        => [ [ 'H', 'E' ], [ 'E', 'H' ] ],
		stringmap   => { H => 'Alpha helix', E => 'Beta sheet' }
	);
	my ($ticks) = $py =~ m/ticks = \[([^\]]*)\]/;
	my @ticks = split /,/, ( $ticks // '' );
	is( scalar @ticks, 2, 'imshow: two categories put one tick each' );
	isnt( $ticks[0], $ticks[1], 'imshow: ... and not both in the same place' );
}
{
	my @cats = ( 'A' .. 'K' );    # 11, and the property cycle holds 10
	my ( $py, $file ) = gen(
		plot_type => 'imshow',
		data        => [ [@cats], [@cats] ],
		stringmap   => { map { $_ => "cat $_" } @cats }
	);
	parses_ok( $file, 'imshow: 11 string categories parse' );
	like( $py, qr/resampled\(11\)/, 'imshow: past the property cycle, a colormap supplies the colors' );
}

# ----------------------------------------------------------------------------
# 3. Data that cannot be drawn is refused here, naming the key.
# ----------------------------------------------------------------------------
dies_with( { plot_type => 'bar', data => { A => 'abc', B => 2 } },
	qr/"A" are not numbers/, 'bar: a non-numeric height is refused, naming the key' );
dies_with( { plot_type => 'pie', data => { A => 'abc', B => 2 } },
	qr/"A" is not a number/, 'pie: a non-numeric wedge is refused, naming the key' );
dies_with( { plot_type => 'bar', data => { A => undef, B => 2 } },
	qr/"A" has an undefined value/, 'bar: an undefined height is refused, naming the key' );
dies_with( { plot_type => 'bar', data => { A => [ 1, 2, 3 ], B => [ 4, 5 ] } },
	qr/different numbers of values/, 'bar: a short group is refused' );
dies_with( { plot_type => 'violin', data => { A => [@g1], B => [ undef, 'NA' ] } },
	qr/"B" has no numeric values/, 'violin: a group with nothing numeric in it is refused' );
dies_with( { plot_type => 'imshow', data => [] },
	qr/no data to draw/, 'imshow: an empty image is refused' );
dies_with( { plot_type => 'colored_table', data => { A => { B => undef } } },
	qr/nothing to color by/, 'colored_table: a table with no numbers is refused' );

# "key_order" (and the options shaped like it) naming a key "data" has not.
my %KEY_ORDER = (
	bar      => [ { A => 1, B => 2 }, 'key_order', [qw(A C)] ],
	pie      => [ { A => 1, B => 2 }, 'key_order', [qw(A C)] ],
	boxplot  => [ { A => [@g1] }, 'key_order', [qw(A C)] ],
	violin   => [ { A => [@g1] }, 'key_order', [qw(A C)] ],
	plot     => [ { A => [ [@xs], [@xs] ] }, 'key_order', [qw(A C)] ],
	hexbin   => [ { X => [@cx], Y => [@cy] }, 'key_order', [qw(X Z)] ],
	hist2d   => [ { X => [@cx], Y => [@cy] }, 'key_order', [qw(X Z)] ],
	scatter  => [ { X => [@cx], Y => [@cy] }, 'keys', [qw(X Z)] ],
	venn_proportional_area =>
	 [ { L => [qw(a b)], R => [qw(b c)] }, 'key_order', [qw(L X)] ],
	colored_table => [ { A => { A => 1 } }, 'col_labels', [qw(A C)] ],
);
foreach my $type ( sort keys %KEY_ORDER ) {
	my ( $data, $option, $order ) = @{ $KEY_ORDER{$type} };
	dies_with(
		{ plot_type => $type, data => $data, $option => $order },
		qr/named in "\Q$option\E" but are not keys of "data"/,
		"$type: \"$option\" naming a key that data has not is refused"
	);
}

# ----------------------------------------------------------------------------
# 4. logscale takes an array of axis names, and only "x" and "y".
# ----------------------------------------------------------------------------
# colored_table is not in this list: it does not accept "logscale" at all.
foreach my $type (qw(boxplot hist hist2d plot scatter violin)) {
	my %data = (
		boxplot       => { A => [@g1], B => [@g2] },
		hist          => { A => [@g1] },
		# Y above 0: @cy holds 0, and a log axis of hist2d is binned from
		# log10 of its lowest value, which since 0.319 is refused by name
		# rather than written into a script that dies on it.
		hist2d        => { X => [@cx], Y => [ map { $_ + 1 } @cy ] },
		plot          => { A => [ [@xs], [@xs] ] },
		scatter       => { X => [@cx], Y => [@cy] },
		violin        => { A => [@g1] },
	);
	dies_with( { plot_type => $type, data => $data{$type}, logscale => ['xy'] },
		qr/only "x" and "y" are allowed in "logscale"/, "$type: logscale => ['xy'] is refused" );
	dies_with( { plot_type => $type, data => $data{$type}, logscale => 'y' },
		qr/must be an array of axis names/, "$type: a scalar logscale is refused" );
	my ($py) = gen( plot_type => $type, data => $data{$type}, logscale => ['y'] );
	like( $py, qr/set_yscale\("log"\)/, "$type: logscale => ['y'] still reaches the script" );
}

# A single plot used to hand its pyplot-wide options to two passes: the first
# wrote them unquoted, the second quoted them, and both lines ended up in the
# script, so "xscale => 'log'" left a plt.xscale(log) that raised NameError
# before the correct line below it could run.
{
	my ( $py, $file ) = gen( plot_type => 'bar', data => { A => 1, B => 2 }, xscale => 'log' );
	my $n = () = $py =~ /plt\.xscale\(/g;
	is( $n, 1, 'single plot: a pyplot option is written once' );
	like( $py, qr/plt\.xscale\('log'\)/, 'single plot: ... and quoted' );
	parses_ok( $file, 'single plot: a pyplot option parses' );
}

# ----------------------------------------------------------------------------
# 5. Options that were accepted and then ignored.
# ----------------------------------------------------------------------------
{
	my ($py) = gen(
		plot_type     => 'colored_table',
		data          => { H => { H => 432 }, C => { H => 411, C => 346 } },
		colorbar_on => 0,
		cblabel       => 'counts'
	);
	unlike( $py, qr/colorbar/, 'colored_table: colorbar_on => 0 wins over cblabel' );
}
foreach my $type (qw(hexbin hist2d)) {
	my ($py) = gen(
		plot_type     => $type,
		data          => { X => [@cx], Y => [@cy] },
		colorbar_on => 0
	);
	unlike( $py, qr/colorbar/, "$type: colorbar_on => 0 draws no colorbar" );
}
{
	my ($py) = gen(
		plot_type          => 'colored_table',
		data               => { H => { H => 432 }, C => { H => 411, C => 346 } },
		default_undefined  => 0
	);
	unlike( $py, qr/np\.nan/, 'colored_table: default_undefined replaces the missing cells' );
}
{	# per-set bin edges: the whole-plot form has always taken an array
	my ($py) = gen(
		plot_type => 'hist',
		data        => { A => [@g1], B => [@g2] },
		bins        => { A => [ 0, 2, 4, 6, 8 ], B => 3 }
	);
	like( $py, qr/bins = \[0,2,4,6,8\]/, 'hist: a per-set array of bin edges reaches the script' );
	unlike( $py, qr/ARRAY\(0x/, 'hist: a per-set array is not stringified into the script' );
}
{	# the inner keys of a hash of hashes are the series, so they can be colored
	my ($py) = gen(
		plot_type => 'bar',
		data        => { 1941 => { North => 1, South => 2 }, 1942 => { North => 3, South => 4 } },
		color       => { North => 'red', South => 'blue' }
	);
	like( $py, qr/color = 'red'/,  'bar: a color hash colors the series it names' );
	like( $py, qr/color = 'blue'/, 'bar: ... every one of them' );
}
dies_with(
	{ plot_type => 'bar', data => { A => [ 1, 2 ], B => [ 3, 4 ] }, color => { A => 'red' } },
	qr/series have no names to key it by/,
	'bar: a color hash against a hash of arrays is refused rather than ignored'
);
{	# "title" is a Text attribute of the axes, not a method: colored_table
	# wrote "ax0.title('..')" of its own, on top of the "ax0.set_title('..')"
	# that plt writes for every plot type, and died as
	# "TypeError: 'Text' object is not callable" when the script ran
	my ($py) = gen(
		plot_type => 'colored_table',
		data        => { H => { H => 432 }, C => { H => 411, C => 346 } },
		title       => 'a title'
	);
	unlike( $py, qr/^ax\d*\.title\(/m, 'colored_table: a title is not called as a method' );
	like( $py, qr/set_title/, 'colored_table: ... it is set with set_title' );
}
# twinx names its lines by data key when "data" is a hash of sets, and by
# index when it is an array of lines.  Each form used to ignore the other's
# shape without a word, drawing no second axis and reporting nothing.
dies_with(
	{ plot_type => 'plot', data => { A => [ [@xs], [@xs] ] }, twinx => ['A'] },
	qr/not a ARRAY reference/,
	'plot: twinx as an array against hash data is refused rather than ignored'
);
dies_with(
	{ plot_type => 'plot', data => [ [ [@xs], [@xs] ] ], twinx => { 0 => 1 } },
	qr/not a HASH reference/,
	'plot: twinx as a hash against array data is refused rather than ignored'
);
dies_with(
	{
		plots             => [
			{ plot_type => 'hexbin', data => { X => [@cx], Y => [@cy] } },
			{ plot_type => 'hexbin', data => { X => [@cx], Y => [@cy] } }
		],
		ncols             => 2,
		shared_colorbar => []
	},
	qr/"shared_colorbar" is an empty array/,
	'shared_colorbar: an empty array is refused'
);

dies_with(
	{
		plots             => [
			{ plot_type => 'hexbin', data => { X => [@cx], Y => [@cy] } },
			{ plot_type => 'hexbin', data => { X => [@cx], Y => [@cy] } }
		],
		ncols             => 2,
		shared_colorbar => [ 0, 'one' ]
	},
	qr/not 0-based subplot indices/,
	'shared_colorbar: an entry that is not an index is refused'
);

# colored_table has no "logscale": the loop that read one could never run, and
# the option has to stay refused now that the loop is gone.
dies_with(
	{ plot_type => 'colored_table', data => { A => { A => 1 } }, logscale => ['y'] },
	qr/"logscale" isn't defined for plot_type "colored_table"/,
	'colored_table: logscale is not one of its options'
);

# "key_order" at a pie: accepted, and it orders the wedges.  The documentation
# used to say the option was not accepted at all.
{
	my ($py) = gen( plot_type => 'pie', data => { A => 1, B => 2, C => 3 },
		key_order => [qw(C A)] );
	like( $py, qr/vals = \[3,1\]/, 'pie: key_order picks the wedges and their order' );
}

# ----------------------------------------------------------------------------
# 6. The caller's data is the caller's.
#
#    boxplot and violin drop the undefined and non-numeric elements before
#    plotting, and used to write the shortened list back into the array the
#    caller passed in.
# ----------------------------------------------------------------------------
# boxplot drops the undefined elements and refuses the non-numeric ones;
# violin drops both.  Each gets data it accepts, and has to leave it alone.
my %DROPS = (
	boxplot => [ 1, 2, undef, 4 ],
	violin  => [ 1, 2, undef, 'NA', 4 ],
);
foreach my $type ( sort keys %DROPS ) {
	my @vals = @{ $DROPS{$type} };
	my $n    = scalar @vals;
	gen( plot_type => $type, data => { A => \@vals } );
	is( scalar @vals, $n, "$type: the caller's array still holds every element it did" );
}

# ----------------------------------------------------------------------------
# 7. A keyword in its pre-0.319 dotted spelling is refused by name.
#
#    The rename was a hard break, so a script written for 0.318 has to be told
#    what each old keyword is called now. "plot.type" and "output.file" are
#    asserted at the top level because they used to reach plt's "either ...
#    must be defined" checks first, which name only the new spelling; the
#    nested cases, because a subplot, an "add" graph and a "p" entry are each
#    reached by a different branch.
# ----------------------------------------------------------------------------
my $SVG = File::Spec->catfile( $TMP, 'dotted.svg' );
my @DOTTED = (
	[ 'plot.type at the top',
		{ 'plot.type' => 'bar', output_file => $SVG, data => { A => 1 } },
		qr/"plot\.type" is now "plot_type"/ ],
	[ 'output.file at the top',
		{ plot_type => 'bar', 'output.file' => $SVG, data => { A => 1 } },
		qr/"output\.file" is now "output_file"/ ],
	[ 'a plot option at the top',
		{ plot_type => 'bar', output_file => $SVG, data => { A => 1 }, 'key.order' => ['A'] },
		qr/"key\.order" is now "key_order"/ ],
	[ 'in a subplot',
		{ output_file => $SVG, plots => [ { plot_type => 'bar', data => { A => 1 } }, { 'plot.type' => 'bar', data => { A => 1 } } ] },
		qr/"plot\.type" is now "plot_type" at subplot 1/ ],
	[ 'in an "add" graph of a subplot',
		{ output_file => $SVG, plots => [ { plot_type => 'plot', data => { A => [ [1], [1] ] }, add => [ { plot_type => 'plot', data => { B => [ [1], [1] ] }, 'show.legend' => 0 } ] } ] },
		qr/"show\.legend" is now "show_legend" in "add" graph 0 at subplot 0/ ],
	[ 'in a "p" entry',
		{ output_file => $SVG, p => [ [ { 'plot.type' => 'hist', data => { A => [1] } } ] ] },
		qr/"plot\.type" is now "plot_type" at "p" entry 0/ ],
);
foreach my $case (@DOTTED) {
	my ( $where, $spec, $like ) = @{$case};
	my ( $out, $err ) = capture { eval { plt( { %{$spec}, execute => 0 } ) } };
	my $died = "$@";
	$died =~ s/\n\t.*\z//s;
	like( $died, $like, "a dotted keyword $where is refused with its new name" );
}
{
	my ( $out, $err ) = capture {
		eval { plt( { 'plot.type' => 'bar', 'output.file' => $SVG, data => { A => 1 }, execute => 0 } ) }
	};
	my $died = "$@";
	like( $died, qr/"output\.file" is now "output_file".*"plot\.type" is now "plot_type"/s,
		'every dotted keyword is named in the one message, not only the first' );
}

done_testing();

#!/usr/bin/env perl
#
# The generated python must be syntactically valid python.
#
# This module's real output is a python script, and a code generator can emit
# something that parses as neither python nor an error message.  Since 0.313
# the failure at least surfaces as "python3 /tmp/xxxx.py unexpectedly returned
# exit value 1" with python's own traceback printed above it; before that,
# autodie threw from inside capture() and the traceback was discarded entirely.
# Either way the caller is reading a traceback to work out which option was at
# fault, which is a worse place to find out than a failing test here.
#
# Parsing every generated script with python's own parser is a cheap gate for
# that whole class of bug.  It needs python3 but not matplotlib, so it still
# runs where the render layer in t/03.coverage.t has to be skipped, and it is
# fast enough to cover every plot type and every text option at once.
#
# The specific trap that motivated this file: title/label text was auto-quoted
# only when it contained no comma, apostrophe or double quote.  Anything else
# was passed through verbatim -- deliberately, so that mathtext such as
# 'r"$\it{anno}$"' survives -- with the consequence that a plain-English label
# containing a comma was emitted as bare python and the script would not parse.
# Since 0.319 only text that opens as python does -- with a string literal or
# a keyword argument -- is passed through, and section 4 checks the prose.
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

our $TODO;

# ----------------------------------------------------------------------------
# python3 discovery.  Without it there is nothing here to check.
# ----------------------------------------------------------------------------
my $python_raw = ( scalar @PY ? do { no warnings 'exec'; qx/$PY --version 2>&1/ } // '' : '' );    # 'exec': see t/16.creator.t
my $python_available = ( $? == 0 && $python_raw =~ m/Python\s+3\.\d+/i ) ? 1 : 0;
if ($python_available) {
	( my $v = $python_raw ) =~ s/^\s+|\s+$//g;
	diag("$v (parser gate ON)");
} else {
	plan skip_all => 'no Python 3 interpreter found, so generated python cannot be parsed';
}

# ----------------------------------------------------------------------------
# Helpers.
# ----------------------------------------------------------------------------
my $TMP = tempdir( CLEANUP => 1 );
my $seq = 0;

# Ask python to parse the file and say nothing if it is happy.  ast.parse is
# used rather than py_compile so that no __pycache__ is left behind.
my $PARSE = q{import ast, sys; ast.parse(open(sys.argv[1], encoding='utf-8').read())};

sub slurp {
	my ($path) = @_;
	open my $in, '<', $path or die "can't read $path: $!";
	local $/;
	my $text = <$in>;
	close $in;
	return defined $text ? $text : '';
}

sub parses_ok {
	my ( $pyfile, $name ) = @_;
	my ( $out, $err, $status ) = capture {
		system( @PY, '-c', $PARSE, $pyfile );
	};
	my $ok = ( $status == 0 ) ? 1 : 0;
	if ( !ok( $ok, $name ) && !defined $TODO ) {
		my @lines = grep { /\S/ } split /\n/, ( $err . $out );
		@lines = @lines[ $#lines - 2 .. $#lines ] if @lines > 3;
		diag("  $_") foreach @lines;
	}
	return $ok;
}

# Build one figure with execute => 0 and return the path of the python it wrote.
sub gen {
	my (%spec) = @_;
	$spec{output_file} = File::Spec->catfile( $TMP, 'gen' . $seq++ . '.svg' );
	$spec{execute} = 0;
	my ( $out, $err, $pyfile ) = capture { plt( \%spec ) };
	return $pyfile;
}

# ----------------------------------------------------------------------------
# Data.
# ----------------------------------------------------------------------------
my @g1 = ( 1, 2, 2, 3, 3, 3, 4, 4, 5 );
my @g2 = ( 2, 3, 3, 4, 4, 5, 5, 6, 7 );
my @cx = 1 .. 30;
my @cy = map { $_ % 5 } 1 .. 30;
my @xs = 1 .. 10;
my @grid = map { my $i = $_; [ map { $i * $_ } 1 .. 6 ] } 1 .. 6;

my %SPEC = (    # one minimal, valid spec per plot type
	bar           => { data => { A => 1, B => 2 } },
	barh          => { data => { A => 1, B => 2 } },
	boxplot       => { data => { A => [@g1], B => [@g2] } },
	colored_table => { data => { H => { H => 432 }, C => { H => 411, C => 346 } } },
	hexbin        => { data => { X => [@cx], Y => [@cy] } },
	hist          => { data => { A => [@g1], B => [@g2] } },
	hist2d        => { data => { X => [@cx], Y => [@cy] } },
	imshow        => { data => \@grid },
	pie           => { data => { A => 1, B => 2 } },
	plot          => { data => { A => [ [@xs], [@xs] ] } },
	scatter       => { data => { X => [@cx], Y => [@cy] } },
	venn_proportional_area =>
		{ data => { Left => [qw(a b c)], Right => [qw(b c d)] } },
	violinplot    => { data => { A => [@g1], B => [@g2] } },
	wide          => { data => { A => [ map { my $n = $_; [ [@xs], [ map { $_ + $n } @xs ] ] } 1 .. 3 ] } },
);

# ============================================================================
# 1. Every plot type, on its own, generates parseable python.
# ============================================================================
foreach my $type ( sort keys %SPEC ) {
	parses_ok( gen( plot_type => $type, %{ $SPEC{$type} } ),
		"$type: generated python parses" );
}

# ============================================================================
# 2. Every plot type carrying the common text options still parses.
#
#    Labels are the options most likely to inject raw text into the python, so
#    each type is re-generated with the whole set attached.
# ============================================================================
foreach my $type ( sort keys %SPEC ) {
	parses_ok(
		gen(
			plot_type => $type,
			%{ $SPEC{$type} },
			title    => 'a title',
			xlabel   => 'an x label',
			ylabel   => 'a y label',
			suptitle => 'a figure title',
		),
		"$type: generated python parses with title/xlabel/ylabel/suptitle"
	);
}

# ============================================================================
# 3. The text-quoting contract.
#
#    Plain text is quoted for you; text that already carries python quoting is
#    passed through.  Both must parse.
# ============================================================================
my @TEXT_OK = (
	[ 'plain text',                'a plain title' ],
	[ 'colon',                     'Two groups: mean and s.d.' ],
	[ 'text pre-quoted by hand',   '"Two groups, mean and s.d."' ],
	[ 'apostrophe, double-quoted', '"war\'s end"' ],
	[ 'mathtext raw string',       'r"$\it{anno}$ $\it{domini}$"' ],
	[ 'utf8 text',                 'Ζεύς' ],
	[ 'utf8 text with a comma',    '"Ζεύς, πατήρ"' ],
	[ 'percent sign',              '100% of the total' ],
	[ 'backslash',                 'C:\\path' ],
);
foreach my $case (@TEXT_OK) {
	my ( $name, $text ) = @{$case};
	foreach my $opt (qw(title xlabel ylabel suptitle set_title)) {
		parses_ok( gen( plot_type => 'bar', data => { A => 1 }, $opt => $text ),
			"$opt: $name parses" );
	}
}

# Quoting text yourself works with either kind of quote for the axes options...
foreach my $opt (qw(title xlabel ylabel suptitle set_title)) {
	parses_ok( gen( plot_type => 'bar', data => { A => 1 }, $opt => '"a, b"' ),
		"$opt: double-quoted text with a comma parses" );
}
foreach my $opt (qw(title xlabel ylabel set_title)) {
	parses_ok( gen( plot_type => 'bar', data => { A => 1 }, $opt => "'a, b'" ),
		"$opt: single-quoted text with a comma parses" );
}

# ... and for suptitle, which used to be emitted twice: once by the per-subplot
# pass (correctly, passing the text through) and again by the figure-level pass,
# which ran its own quoting heuristic over it and added a second pair of quotes:
#
#     plt.suptitle('a, b')     <- the subplot pass
#     plt.suptitle(''a, b'')   <- the figure pass, and a SyntaxError
#
# A single plot now hands the figure-wide and pyplot-wide options to one pass
# only, and that pass leaves text that already carries a quote alone.
foreach my $quoted ( "'a, b'", '"a, b"' ) {
	parses_ok( gen( plot_type => 'bar', data => { A => 1 }, suptitle => $quoted ),
		"suptitle: text with a comma quoted as $quoted parses" );
}
{
	my $py = slurp( gen( plot_type => 'bar', data => { A => 1 }, suptitle => 'plain' ) );
	my $n = () = $py =~ /plt\.suptitle\(/g;
	is( $n, 1, 'suptitle is emitted exactly once' );
}

# ============================================================================
# 4. Text that has to quote itself.
#
#    A comma or an apostrophe suppressed the automatic quoting, so unquoted
#    prose of that shape could not parse.  These were TODO, as the
#    reproduction for the trap, until 0.319 quoted such prose.
# ============================================================================
my @TEXT_TRAP = (
	[ 'bare comma',      'Two groups, mean and s.d.' ],
	[ 'bare apostrophe', "war's end" ],
	[ 'bare quote',      'the "big" one' ],
);
foreach my $case (@TEXT_TRAP) {
	my ( $name, $text ) = @{$case};
	parses_ok( gen( plot_type => 'bar', data => { A => 1 }, title => $text ),
		"title: $name parses without the caller quoting it" );
}

# ============================================================================
# 5. Composite figures: the layout machinery must not break the syntax either.
# ============================================================================
{
	my %h = ( plot_type => 'hist', data => { A => [@g1] } );
	my %b = ( plot_type => 'bar',  data => { A => 1, B => 2 } );

	parses_ok( gen( plots => [ \%h, \%b ], ncols => 2 ),
		'plots: a 1x2 grid parses' );
	parses_ok( gen( plots => [ \%h, \%b, \%h ], ncols => 2, nrows => 2, suptitle => 'four cells' ),
		'plots: a 2x2 grid with an empty cell parses' );
	parses_ok( gen( p => [ \%h, [ \%h, \%h ], \%b ] ),
		'p: overlaid and single subplots parse' );
	parses_ok(
		gen(
			plot_type => 'bar',
			data        => { A => 1, B => 2, C => 3 },
			add         => [ { plot_type => 'plot', data => [ [ 0, 1, 2 ], [ 1, 2, 3 ] ] } ],
		),
		'add: an overlaid line on a bar chart parses'
	);
	parses_ok(
		gen(
			plot_type    => 'plot',
			data         => { A => [ [@xs], [@xs] ], B => [ [@xs], [ map { $_ * 100 } @xs ] ] },
			twinx        => 'B',
			twinx_args => { B => { ylabel => 'right axis' } },
		),
		'twinx: a twinned second y-axis parses'
	);
	parses_ok(
		gen(
			ncols             => 2,
			shared_colorbar => [ 0, 1 ],
			plots             => [
				{ plot_type => 'imshow', data => \@grid },
				{ plot_type => 'imshow', data => \@grid },
			],
		),
		'shared_colorbar: two imshow panels parse'
	);
	parses_ok(
		gen(
			ncols => 2,
			plots => [
				{ plot_type => 'violinplot', data => { A => [@g1] } },
				{ plot_type => 'pie',        data => { A => 1, B => 2 } },
			],
		),
		'plots: mixed plot types in one figure parse'
	);
}

# ============================================================================
# 6. Data that carries characters python would choke on.
#
#    Keys become labels and tick text, so a key with a quote or a comma in it
#    travels the same path as a title.  Keys are written through the JSON/base64
#    channel or interpolated directly depending on the plot type, which is
#    exactly the distinction worth pinning.
# ============================================================================
parses_ok( gen( plot_type => 'bar', data => { 'a, b' => 1, 'c' => 2 } ),
	'bar: a comma in a data key parses' );
parses_ok( gen( plot_type => 'hist', data => { 'a-b' => [@g1] } ),
	'hist: a hyphen in a data key parses' );
parses_ok( gen( plot_type => 'boxplot', data => { 'Ζεύς' => [@g1] } ),
	'boxplot: a utf8 data key parses' );
parses_ok( gen( plot_type => 'pie', data => { '50%' => 1, 'rest' => 2 } ),
	'pie: a percent sign in a data key parses' );
parses_ok( gen( plot_type => 'venn_proportional_area',
		data => { 'Set A' => [ 'a b', 'c' ], 'Set B' => [ 'c', 'd' ] } ),
	'venn: spaces in set names and members parse' );
parses_ok( gen( plot_type => 'imshow', data => [ [ ' ', 'G' ], [ 'S', 'H' ] ],
		stringmap => { ' ' => 'loop', G => '3-helix', S => 'bend', H => 'helix' } ),
	'imshow: a space as a stringmap key parses' );

# An apostrophe in a key is the sharpest case of this: a key becomes a legend
# label, a colorbar label or an axis label, each of which used to be pasted
# straight between single quotes, so "Farmer's" closed the literal early and
# the script would not parse.
parses_ok( gen( plot_type => 'wide',
		data => { "Farmer's" => [ map { my $n = $_; [ [@xs], [ map { $_ + $n } @xs ] ] } 1 .. 3 ] } ),
	"wide: an apostrophe in a group name parses" );
parses_ok( gen( plot_type => 'plot', data => { "Farmer's" => [ [@xs], [@xs] ] } ),
	"plot: an apostrophe in a data key parses" );
parses_ok( gen( plot_type => 'hist', data => { "O'Brien" => [@g1], "O'Neill" => [@g2] } ),
	"hist: an apostrophe in a data key parses" );    # 2 keys, so a legend is drawn
parses_ok( gen( plot_type => 'scatter', data => { "Bob's x" => [@cx], "Bob's y" => [@cy] } ),
	"scatter: an apostrophe in the keys that become axis labels parses" );
parses_ok( gen( plot_type => 'scatter',
		data => { "d'x" => [@cx], "d'y" => [@cy], "d'z" => [@cy] }, color_key => "d'z" ),
	"scatter: an apostrophe in the colorbar key parses" );
parses_ok( gen( plot_type => 'hist2d', data => { "a'x" => [@cx], "a'y" => [@cy] },
		cblabel => "count's" ),
	"hist2d: an apostrophe in a cblabel parses" );

# ============================================================================
# 7. Numbers that are not plain integers.
# ============================================================================
parses_ok( gen( plot_type => 'bar', data => { A => 1e-7, B => 2.5e10 } ),
	'bar: exponent-notation values parse' );
parses_ok( gen( plot_type => 'bar', data => { A => -1, B => 0 } ),
	'bar: negative and zero values parse' );
parses_ok( gen( plot_type => 'plot',
		data => { A => [ [ map { $_ / 3 } 1 .. 9 ], [ map { -$_ / 7 } 1 .. 9 ] ] } ),
	'plot: long decimals parse' );

done_testing();

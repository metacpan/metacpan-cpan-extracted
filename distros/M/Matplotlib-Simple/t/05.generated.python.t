#!/usr/bin/env perl
#
# The generated python must be syntactically valid python.
#
# This module's real output is a python script, and a code generator can emit
# something that parses as neither python nor an error message: the failure
# surfaces as "python3 /tmp/xxxx.py failed" with the traceback discarded, which
# tells the caller nothing about which option was at fault.
#
# Parsing every generated script with python's own parser is a cheap gate for
# that whole class of bug.  It needs python3 but not matplotlib, so it still
# runs where the render layer in t/03.coverage.t has to be skipped, and it is
# fast enough to cover every plot type and every text option at once.
#
# The specific trap that motivated this file: title/label text is auto-quoted
# only when it contains no comma, apostrophe or double quote.  Anything else is
# passed through verbatim -- deliberately, so that mathtext such as
# 'r"$\it{anno}$"' survives -- with the consequence that a plain-English label
# containing a comma is emitted as bare python and the script will not parse.
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
# python3 discovery.  Without it there is nothing here to check.
# ----------------------------------------------------------------------------
my $python_raw = qx/python3 --version 2>&1/;
my $python_available = ( $? == 0 && $python_raw =~ m/Python\s+3\.\d+/i ) ? 1 : 0;
if ($python_available) {
	( my $v = $python_raw ) =~ s/^\s+|\s+$//g;
	diag("$v (parser gate ON)");
} else {
	plan skip_all => 'python3 not found, so generated python cannot be parsed';
}

# ----------------------------------------------------------------------------
# Helpers.
# ----------------------------------------------------------------------------
my $TMP = tempdir( CLEANUP => 1 );
my $seq = 0;

# Ask python to parse the file and say nothing if it is happy.  ast.parse is
# used rather than py_compile so that no __pycache__ is left behind.
my $PARSE = 'import ast, sys; ast.parse(open(sys.argv[1], encoding="utf-8").read())';

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
		system( 'python3', '-c', $PARSE, $pyfile );
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
	$spec{'output.file'} = File::Spec->catfile( $TMP, 'gen' . $seq++ . '.svg' );
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
	parses_ok( gen( 'plot.type' => $type, %{ $SPEC{$type} } ),
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
			'plot.type' => $type,
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
		parses_ok( gen( 'plot.type' => 'bar', data => { A => 1 }, $opt => $text ),
			"$opt: $name parses" );
	}
}

# Quoting text yourself works with either kind of quote for the axes options...
foreach my $opt (qw(title xlabel ylabel suptitle set_title)) {
	parses_ok( gen( 'plot.type' => 'bar', data => { A => 1 }, $opt => '"a, b"' ),
		"$opt: double-quoted text with a comma parses" );
}
foreach my $opt (qw(title xlabel ylabel set_title)) {
	parses_ok( gen( 'plot.type' => 'bar', data => { A => 1 }, $opt => "'a, b'" ),
		"$opt: single-quoted text with a comma parses" );
}

# ... but not for suptitle, which is emitted twice: once by the per-subplot pass
# (correctly, passing the text through) and again by the figure-level pass, which
# runs its own quoting heuristic over it and adds a second pair of quotes:
#
#     plt.suptitle('a, b')     <- the subplot pass
#     plt.suptitle(''a, b'')   <- the figure pass, and a SyntaxError
#
# Double quotes survive both passes, which is why the documented advice is to use
# double quotes; the duplicate emission itself is the underlying bug.
{
	local $TODO = 'suptitle is emitted twice and the second pass re-quotes it';
	parses_ok( gen( 'plot.type' => 'bar', data => { A => 1 }, suptitle => "'a, b'" ),
		'suptitle: single-quoted text with a comma parses' );
}
{
	my $py = slurp( gen( 'plot.type' => 'bar', data => { A => 1 }, suptitle => 'plain' ) );
	my $n = () = $py =~ /plt\.suptitle\(/g;
	local $TODO = 'the subplot pass and the figure pass both emit suptitle';
	is( $n, 1, 'suptitle is emitted exactly once' );
}

# ============================================================================
# 4. Text that has to quote itself.
#
#    A comma or an apostrophe suppresses the automatic quoting, so unquoted
#    prose of that shape cannot parse.  These are TODO rather than deleted:
#    they are the reproduction for the trap, and the day the generator escapes
#    its text properly they will start passing and say so.
# ============================================================================
my @TEXT_TRAP = (
	[ 'bare comma',      'Two groups, mean and s.d.' ],
	[ 'bare apostrophe', "war's end" ],
	[ 'bare quote',      'the "big" one' ],
);
foreach my $case (@TEXT_TRAP) {
	my ( $name, $text ) = @{$case};
	local $TODO = 'text with a comma, apostrophe or quote is not escaped, so it must be quoted by the caller';
	parses_ok( gen( 'plot.type' => 'bar', data => { A => 1 }, title => $text ),
		"title: $name parses without the caller quoting it" );
}

# ============================================================================
# 5. Composite figures: the layout machinery must not break the syntax either.
# ============================================================================
{
	my %h = ( 'plot.type' => 'hist', data => { A => [@g1] } );
	my %b = ( 'plot.type' => 'bar',  data => { A => 1, B => 2 } );

	parses_ok( gen( plots => [ \%h, \%b ], ncols => 2 ),
		'plots: a 1x2 grid parses' );
	parses_ok( gen( plots => [ \%h, \%b, \%h ], ncols => 2, nrows => 2, suptitle => 'four cells' ),
		'plots: a 2x2 grid with an empty cell parses' );
	parses_ok( gen( p => [ \%h, [ \%h, \%h ], \%b ] ),
		'p: overlaid and single subplots parse' );
	parses_ok(
		gen(
			'plot.type' => 'bar',
			data        => { A => 1, B => 2, C => 3 },
			add         => [ { 'plot.type' => 'plot', data => [ [ 0, 1, 2 ], [ 1, 2, 3 ] ] } ],
		),
		'add: an overlaid line on a bar chart parses'
	);
	parses_ok(
		gen(
			'plot.type'  => 'plot',
			data         => { A => [ [@xs], [@xs] ], B => [ [@xs], [ map { $_ * 100 } @xs ] ] },
			twinx        => 'B',
			'twinx.args' => { B => { ylabel => 'right axis' } },
		),
		'twinx: a twinned second y-axis parses'
	);
	parses_ok(
		gen(
			ncols             => 2,
			'shared.colorbar' => [ 0, 1 ],
			plots             => [
				{ 'plot.type' => 'imshow', data => \@grid },
				{ 'plot.type' => 'imshow', data => \@grid },
			],
		),
		'shared.colorbar: two imshow panels parse'
	);
	parses_ok(
		gen(
			ncols => 2,
			plots => [
				{ 'plot.type' => 'violinplot', data => { A => [@g1] } },
				{ 'plot.type' => 'pie',        data => { A => 1, B => 2 } },
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
parses_ok( gen( 'plot.type' => 'bar', data => { 'a, b' => 1, 'c' => 2 } ),
	'bar: a comma in a data key parses' );
parses_ok( gen( 'plot.type' => 'hist', data => { 'a-b' => [@g1] } ),
	'hist: a hyphen in a data key parses' );
parses_ok( gen( 'plot.type' => 'boxplot', data => { 'Ζεύς' => [@g1] } ),
	'boxplot: a utf8 data key parses' );
parses_ok( gen( 'plot.type' => 'pie', data => { '50%' => 1, 'rest' => 2 } ),
	'pie: a percent sign in a data key parses' );
parses_ok( gen( 'plot.type' => 'venn_proportional_area',
		data => { 'Set A' => [ 'a b', 'c' ], 'Set B' => [ 'c', 'd' ] } ),
	'venn: spaces in set names and members parse' );
parses_ok( gen( 'plot.type' => 'imshow', data => [ [ ' ', 'G' ], [ 'S', 'H' ] ],
		stringmap => { ' ' => 'loop', G => '3-helix', S => 'bend', H => 'helix' } ),
	'imshow: a space as a stringmap key parses' );

# ============================================================================
# 7. Numbers that are not plain integers.
# ============================================================================
parses_ok( gen( 'plot.type' => 'bar', data => { A => 1e-7, B => 2.5e10 } ),
	'bar: exponent-notation values parse' );
parses_ok( gen( 'plot.type' => 'bar', data => { A => -1, B => 0 } ),
	'bar: negative and zero values parse' );
parses_ok( gen( 'plot.type' => 'plot',
		data => { A => [ [ map { $_ / 3 } 1 .. 9 ], [ map { -$_ / 7 } 1 .. 9 ] ] } ),
	'plot: long decimals parse' );

done_testing();

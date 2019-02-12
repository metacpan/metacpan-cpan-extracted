#!perl
use 5.010001;
use strict;
use warnings FATAL => 'all';

use Logic::TruthTable;

use Test::More tests => 1;
use Test::Output;

my %col_mins = (
	w0 => [8, 12, 14, 15],
	w1 => [6, 9, 11, 14],
);
my %col_dcs = (
	w0 => [1..5, 9, 13],
	w1 => [0..4, 8, 12],
);

my $ttable = Logic::TruthTable->new(
	width => 4,
	functions => [qw(w1 w0)],
	vars => [qw(a1 a0 b1 b0)],
	columns => [{
		minterms => $col_mins{w1},
		dontcares => $col_dcs{w1},
	},
	{
		minterms => $col_mins{w0},
		dontcares => $col_dcs{w0},
	},
	],
);

#
# The variable that contains __DATA__,
# and an output routine for stdout_is().
#
my $data;
sub csvwrite
{
	$ttable->export_csv(write_handle => \*STDOUT, dc => 'X');
}

#
# Read in the __DATA__, and compare it
# to the table's CSV output.
#
{ local $/ = undef; $data = <DATA>; }

stdout_is(\&csvwrite, $data, "Error writing CSV.");

__DATA__
a1,a0,b1,b0,,w1,w0
0,0,0,0,,X,0
0,0,0,1,,X,X
0,0,1,0,,X,X
0,0,1,1,,X,X
0,1,0,0,,X,X
0,1,0,1,,0,X
0,1,1,0,,1,0
0,1,1,1,,0,0
1,0,0,0,,X,1
1,0,0,1,,1,X
1,0,1,0,,0,0
1,0,1,1,,1,0
1,1,0,0,,X,1
1,1,0,1,,0,X
1,1,1,0,,1,1
1,1,1,1,,0,1

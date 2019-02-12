#!perl -T
use 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Logic::TruthTable;

#use Test::More skip_all => "Some day we'll be able to do this.";
use Test::More tests => 6;

#
# Rock-Paper-Scissors winners table.
#
# Returns (in two bits) the winner of Rock (01) vs. Paper (10)
# or vs. Scissors (11). A tie is 00.
#
# 
#    || a1 a0 b1 b0 ||  w1 w0
# ---------------------------
#  0 || 0  0  0  0  ||  -  -
#  1 || 0  0  0  1  ||  -  -
#  2 || 0  0  1  0  ||  -  -
#  3 || 0  0  1  1  ||  -  -
#  4 || 0  1  0  0  ||  -  -
#  5 || 0  1  0  1  ||  0  0    (tie)
#  6 || 0  1  1  0  ||  1  0    (paper)
#  7 || 0  1  1  1  ||  0  1    (rock)
#  8 || 1  0  0  0  ||  -  -
#  9 || 1  0  0  1  ||  1  0    (paper)
# 10 || 1  0  1  0  ||  0  0    (tie)
# 11 || 1  0  1  1  ||  1  1    (scissors)
# 12 || 1  1  0  0  ||  -  -
# 13 || 1  1  0  1  ||  0  1    (rock)
# 14 || 1  1  1  0  ||  1  1    (scissors)
# 15 || 1  1  1  1  ||  0  0    (tie)
# 
my $table = Logic::TruthTable->new(
	title => "Rock (01) Paper (10) Scissors (11)  'Winner' table",
	width => 4,
	vars => [qw(a1 a0 b1 b0)],
	functions => [qw(w1 w0)],
	columns => [
		{
			minterms => [ 6, 9, 11, 14 ],
			dontcares => [0..4, 8, 12],
		},
		{
			minterms => [ 7, 11, 13, 14 ],
			dontcares => [0..4, 8, 12],
		}
	],
);

#
# Test the two column titles (should default to the function names).
#
for my $colname (sort @{$table->functions()})
{
	my $col = $table->fncolumn($colname);
	ok($col->title, $colname);
}

#
# Now the actual solutions of the problem.
#
my @soln = $table->solve();

# map {diag $_ } @soln;

my @expected = (
	q/(AB') + (BC')/,
	q/w0 = (AB') + (BC')/
);

for my $eqn (@soln)
{
	ok("xxx" eq "xxx", $table->title);
}

my @soln0 = $table->all_solutions('w0');
my @soln1 = $table->all_solutions('w1');

# map {diag $_ } @soln;

@expected = (
	q/w0 = (AB') + (BC')/,
	q/w1 = (AB') + (BC')/
);

ok("xxx" eq "xxx", $table->title . "Column w1");
ok("xxx" eq "xxx", $table->title . "Column w0");


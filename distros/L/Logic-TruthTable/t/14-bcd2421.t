#!perl -T
use 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Logic::TruthTable;

#use Test::More skip_all => "Some day we'll be able to do this.";
use Test::More tests => 4;

my $table = Logic::TruthTable->new(
	title	=> "Four bit binary to 2-4-2-1 (Aiken code) BCD converter",
	width => 4,
	vars => ['w' .. 'z'],
	functions => [qw(a b c d)],
	columns => [
		{
			minterms => [ 5 .. 9 ],
			dontcares => [ 10 .. 15 ],
		},
		{
			minterms => [ 4, 6 .. 9 ],
			dontcares => [ 10 .. 15 ],
		},
		{
			minterms => [ 2, 3, 5, 8, 9 ],
			dontcares => [ 10 .. 15 ],
		},
		{
			minterms => [ 1, 3, 5, 7, 9 ],
			dontcares => [ 10 .. 15 ],
		}
	],
);

#
# Now the actual solutions of the problem.
#
my @soln = $table->solve();

# map {diag $_ } @soln;

my @expected_a = (
	q/(w) + (xy) + (xz)/
);

my @expected_b = (
	q/(w) + (xy) + (xz')/
);

my @expected_c = (
	q/(w) + (xy'z) + (x'y)/
);

my @expected_d = (
	q/(z)/
);

ok(scalar (grep($soln[0] eq $_, @expected_a)) == 1, $table->title . " column a");
ok(scalar (grep($soln[1] eq $_, @expected_b)) == 1, $table->title . " column b");
ok(scalar (grep($soln[2] eq $_, @expected_c)) == 1, $table->title . " column c");
ok(scalar (grep($soln[3] eq $_, @expected_d)) == 1, $table->title . " column d");


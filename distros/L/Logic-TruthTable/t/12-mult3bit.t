#!perl -T
use 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Logic::TruthTable;
use Logic::TruthTable::Util qw(:all);

use Test::More tests => 6;

my(@c5, @c4, @c3, @c2, @c1, @c0);

#
# Use the Espresso algorithm if it's available.
#
eval { require Algorithm::Espresso };
my $algorithm = ($@)? 'QuineMcCluskey': 'Espresso';

for my $avar (0 .. 7)
{
	for my $bvar (0 .. 7)
	{
		my $idx = ($avar << 3) | $bvar;
		my $cvar = ($avar * $bvar) & 0xff;

		push_minterm_columns($idx, $cvar,
			\@c5, \@c4, \@c3, \@c2, \@c1, \@c0);
	}
}

my $table = Logic::TruthTable->new(
	title => "3-bit by 3-bit binary multiplier",
	width => 6,
	algorithm => $algorithm,
	vars => [qw(a2 a1 a0 b2 b1 b0)],
	functions => [qw(c5 c4 c3 c2 c1 c0)],
	columns => [
		{
			minterms => [@c5],
		},
		{
			minterms => [@c4],
		},
		{
			minterms => [@c3],
		},
		{
			minterms => [@c2],
		},
		{
			minterms => [@c1],
		},
		{
			minterms => [@c0],
		},
	],
);

#diag "Now Solve it.";

my %fnsoln = $table->fnsolve();

my %expect = (
	c5 => [q/(a2a1a0b2b0) + (a2a1b2b1) + (a2a0b2b1b0)/],
	c4 => [q/(a2a1a0b1b0) + (a2a1b2'b1b0) + (a2a1'a0'b2) + (a2a1'b2b1') + (a2a1'b2b0') + (a2a0'b2b1') + (a2b2b1'b0') + (a2'a1a0b2b1)/,
		q/(a2a1b2'b1b0) + (a2a1'a0'b2) + (a2a1'b2b1') + (a2a1'b2b0') + (a2a0'b2b1') + (a2b2b1'b0') + (a2'a1a0b2b1) + (a1a0b2b1b0)/],
	c3 => [
q/(a2a1a0b2b0') + (a2a1'a0b2b1'b0) + (a2a1'b2'b1) + (a2a1'b1b0') + (a2a0'b2b1b0) + (a2b2'b1b0') + (a2'a1a0b2'b1b0) + (a2'a1a0'b2) + (a2'a1b2b1') + (a1a0'b2b1')/,
q/(a2a1'a0b2b1'b0) + (a2a1'a0'b1) + (a2a1'b2'b1) + (a2a0b1b0') + (a2b2'b1b0') + (a2'a1a0b2'b1b0) + (a2'a1a0'b2) + (a2'a1b2b1') + (a1a0'b2b0) + (a1b2b1'b0')/,
q/(a2a1'a0b2b1'b0) + (a2a1'a0'b1) + (a2a1'b2'b1) + (a2a1'b1b0') + (a2a0b1b0') + (a2b2'b1b0') + (a2'a1a0b2'b1b0) + (a2'a1a0'b2) + (a2'a1b2b1') + (a1a0'b2b1')/,
q/(a2a1'a0b2b1'b0) + (a2a1'a0'b1) + (a2a1'b2'b1) + (a2a1'b1b0') + (a2b2'b1b0') + (a2'a1a0b2'b1b0) + (a2'a1a0'b2) + (a2'a1b2b1') + (a1a0'b2b0) + (a1b2b1'b0')/,
q/(a2a1'a0b2b1'b0) + (a2a1'b2'b1) + (a2a1'b1b0') + (a2b2'b1b0') + (a2'a1a0b2'b1b0) + (a2'a1a0'b2) + (a2'a1b2b1') + (a1a0'b2b1') + (a1a0'b2b0) + (a1b2b1'b0')/,
],
	c2 => [q/(a2a1'a0'b0) + (a2a0b2'b0) + (a2a0'b1'b0) + (a2'a1a0'b1) + (a2'a0b2b0) + (a1a0'b1b0') + (a1b2'b1b0') + (a1'a0b2b0') + (a0b2b1'b0')/],
	c1 => [q/(a1a0'b0) + (a1b1'b0) + (a1'a0b1) + (a0b1b0')/],
	c0 => [q/(a0b0)/],
);

for my $colname (@{$table->functions()})
{
	my $eqn = $fnsoln{$colname};
	my @expected = @{$expect{$colname}};

	ok(scalar (grep($eqn eq $_, @expected)) == 1,
		$table->title . " (column $colname): returned " . $eqn);
}

#my $lookfor = "c4";
#diag "Column $lookfor:";
#diag join("\n", sort $table->all_solutions($lookfor));


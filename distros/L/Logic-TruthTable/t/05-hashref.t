#!perl -T
use 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

use Logic::TruthTable;

my $table = Logic::TruthTable->new(
	width => 3,
	title => 'Random Minterms',
	vars => [qw(a2 a1 a0 )],
	functions => ['f0'],
	columns => [
		{
			minterms => [2, 4, 5, 6],
		},
	],
);

my @soln = $table->solve();

#map {diag $_ } @soln;

my @expected = (
	q/(a2a1') + (a1a0')/
);

for my $eqn (@soln)
{
	ok(scalar (grep($eqn eq $_, @expected)) == 1,
			$table->title . q(: returned ) . $eqn);
}

my %fnsoln = $table->fnsolve();

for my $fn (keys %fnsoln)
{
	my $eqn = $fnsoln{$fn};

	ok(scalar (grep($eqn eq $_, @expected)) == 1,
			$table->title . q(: returned ) . $eqn);
}

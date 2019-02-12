#!perl -T
use 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

use Logic::TruthTable;

#
# If we don't have Algorithm::Espresso installed, then this
# test file isn't doing anything.
#
SKIP: {
	eval { require Algorithm::Espresso };
	skip  "Algorithm::Espresso is not installed", 2 if $@;

	my $q1 = Algorithm::Espresso->new(
		width=>3, 
		minterms => [2, 4, 5, 6],
		title => "Column 0",
	);

	my $table = Logic::TruthTable->new(
		width => 3,
		functions => ['f0'],
		columns => [$q1 ],
		title => 'Random Minterms',
	);

	my @soln = $table->solve();

	#map {diag $_ } @soln;

	my @expected = (
		q/(AB') + (BC')/
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
}

#!perl -T
use 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Logic::TruthTable;
use Logic::TruthTable::Util qw(:all);

use Test::More tests => 8;

#
# If we don't have Algorithm::Espresso installed, then this test
# file would take too long to finish. Skip if that's the case.
#
SKIP: {
	eval { require Algorithm::Espresso };
	skip  "Algorithm::Espresso is not installed", 8 if $@;

	my(@c7, @c6, @c5, @c4, @c3, @c2, @c1, @c0);

	for my $avar (0 .. 15)
	{
		for my $bvar (0 .. 15)
		{
			my $idx = ($avar << 4) | $bvar;
			my $cvar = ($avar * $bvar) & 0xff;

			push_minterm_columns($idx, $cvar,
				\@c7, \@c6, \@c5, \@c4, \@c3, \@c2, \@c1, \@c0);
		}
	}

	my $table = Logic::TruthTable->new(
		title => "4-bit by 4-bit binary multiplier.",
		width => 8,
		algorithm => 'Espresso',
		vars => [qw(a3 a2 a1 a0 b3 b2 b1 b0)],
		functions => [qw(c7 c6 c5 c4 c3 c2 c1 c0)],
		columns => [
			{
				minterms => [@c7],
			},
			{
				minterms => [@c6],
			},
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
		c7 => [q/(AB') + (BC')/,
			q/w0 = (AB') + (BC')/],
		c6 => [q/(AB') + (BC')/,
			q/w0 = (AB') + (BC')/],
		c5 => [q/(AB') + (BC')/,
			q/w0 = (AB') + (BC')/],
		c4 => [q/(AB') + (BC')/,
			q/w0 = (AB') + (BC')/],
		c3 => [q/(AB') + (BC')/,
			q/w0 = (AB') + (BC')/],
		c2 => [q/(AB') + (BC')/,
			q/w0 = (AB') + (BC')/],
		c1 => [q/(AB') + (BC')/,
			q/w0 = (AB') + (BC')/],
		c0 => [q/(AB') + (BC')/,
			q/w0 = (AB') + (BC')/],
	);

	for my $colname (@{$table->functions()})
	{
		my $eqn = $fnsoln{$colname};
		my @expected = @{$expect{$colname}};

		ok(scalar (grep($eqn eq $_, @expected)) == 1,
			$table->title . " (column $colname): returned " . $eqn);
	}
}

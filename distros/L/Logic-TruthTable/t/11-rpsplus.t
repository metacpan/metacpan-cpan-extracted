#!perl -T
use 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Logic::TruthTable;
use Logic::TruthTable::Util qw(:all);

#use Test::More skip_all => "Some day we'll be able to do this.";
use Test::More tests => 3;

#
# Rock-Paper-Scissors-Spock-Lizard winners table.
#
# We're using all three bits, so this will actually be
# a Rock Paper Scissors Spock Lizard Something Something table.
#
# Rock => 1
# Paper => 2
# Scissors => 3
# Spock => 4
# Lizard => 5
# Throw6 => 6
# Throw7 => 7
#
my $width = 3;
my $last = (1 << $width) - 1;
my(@w2, @w1, @w0, @dontcares);

for my $player_a (1 .. $last)
{
	for my $player_b (1 .. $last)
	{
		my $idx = ($player_a << 3) | $player_b;

		#
		# The winner is a three-bit value, so split
		# the result across three columns.
		#
		my $result = rps_winner($player_a, $player_b);
		push_minterm_columns($idx, $result, \@w2, \@w1, \@w0);
	}
}

#
# Zero isn't a throw number, so put these cases in the don't-care list.
#
push @dontcares, 0;

for my $player (1 .. $last)
{
	push @dontcares, ($player << 3);
	push @dontcares, $player;
}

#diag "Now create the table";

my $table = Logic::TruthTable->new(
	title => "Rock (001) Paper (010) Scissors (011) Spock (100) Lizard (101) 'Winner' table.",
	width => 2 * $width,
	vars => [qw(a2 a1 a0 b2 b1 b0)],
	functions => [qw(w2 w1 w0)],
	columns => [
		{
			minterms => [@w2],
			dontcares => [@dontcares],
		},
		{
			minterms => [@w1],
			dontcares => [@dontcares],
		},
		{
			minterms => [@w0],
			dontcares => [@dontcares],
		},
	],
);

my %expect = (
	w2 => [q/(a2a1b1') + (a2a1'b1) + (a2a0b0') + (a2a0'b0) + (a2b2')/],
	w1 => [ q/(a2b1b2') + (a2'b1b2) + (a1a0b0') + (a1a0'b0) + (a1b1')/,
		q/(a2a1b2') + (a2'a1b2) + (a1a0b0') + (a1a0'b0) + (a1b1')/],
	w0 => [q/(a2a0b2') + (a2'a0b2) + (a1a0b1') + (a1'a0b1) + (a0b0')/],
	
);

my %fnsoln = $table->fnsolve();

for my $colname (@{$table->functions()})
{
	my $eqn = $fnsoln{$colname};
	my @expected = @{$expect{$colname}};

	ok(scalar (grep($eqn eq $_, @expected)) == 1,
		$table->title . " (column $colname): returned " . $eqn);
}

#my $lookfor = "w2";
#diag "Column $lookfor:";
#diag join("\n", sort $table->all_solutions($lookfor));

sub rps_winner
{
	my($player_a, $player_b) = @_;

	my $d = $player_a - $player_b;

	return 0 if ($d == 0);

	#
	# Any odd integer (at least as large as the number
	# of possible throws) will do.
	#
	$d += 255 if ($d < 0);

	return $player_a if ($d % 3 == 1);
	return $player_a;
}

#!/bin/perl

use strict;
use warnings;
use Logic::TruthTable;
use Logic::TruthTable::Util qw(:all);

my($throw_count) = @ARGV;

my $tt = extended_rps_winner_table($throw_count);

#
# We may not have the faster algorthm installed, and the
# truth table may be very large, so save the table as a
# file for Logic Friday, and exit.
#
$tt->export_csv(dc => 'X', write_handle => \*STDOUT);
exit(0);

#
# Create an extended Rock Paper Scissors 'winners' table.
# Given two throws, return which of the two throws wins.
# For example, if the two throws in a game of
# Rock Paper Scissors Spock Lizard are Paper and Lizard, the
# output columns would indicate Lizard (eats Paper).
#
# For a three-value comparison table, see extended_rps_cmp_table() below.
#
# Throws are numbered from 1 (Rock) onward, with Tie being 0.
#
# Returns the Logic::TruthTable object.
#
sub extended_rps_winner_table
{
	my($n) = @_;
	my @dontcares;

	#
	# If you raise this limit, you'll need to change
	# the statements that create the @vars_a, @vars_b,
	# and @fns variables.
	#
	die "Throw count of 1023 or less please" unless ($n <= 1023);
	die "Not an odd number!" unless ($n % 2 == 1);

	# We don't know how many columns of output or input
	# we will need for our problem. But since the vars,
	# functions, and columns attributes are all array
	# references, these can be created programatically:
	#
	# How many binary columns do we need represent a throw?
	# For example, Rock-Paper-Scissors-Spock-Lizard
	# are five types of throws that can be represented
	# in three bits. Three bits gives a range of 0 .. 7,
	# so we have to don't-care not just 0, but 6 and 7
	# as well.
	#
	my $w = length(sprintf("%b", $n));
	my $r = (1 << $w) - 1;

	#
	# Make an empty array of output terms.
	#
	my @aterms;
	push @aterms, [] for (0 .. $w-1);

	#
	# Now, all the possible combinations of player A vs. player B.
	#
	for my $player_a (0 .. $r)
	{
		for my $player_b (0 .. $r)
		{
			my $row = ($player_a << $w) + $player_b;

			if ($player_b == 0 or $player_a == 0 or
				$player_a > $n or $player_b > $n)
			{
				push @dontcares, $row;
			}
			else
			{
				push_minterm_columns($row,
					rpswinner($player_a, $player_b, $r),
					@aterms);
			}
		}
	}

	#
	# Let's create the table's columns.
	#
	my @columns;

	for my $idx (0 .. $w-1)
	{
		push @columns, {dontcares => [@dontcares],
				minterms => [@{$aterms[$idx]}], };
	}

	#
	# And the variable and function names.
	# (We are assuming fewer than 1024 choices here.)
	#
	my @vars_a = reverse(('a0' .. 'a9')[0 .. $w-1]);
	my @vars_b = reverse(('b0' .. 'b9')[0 .. $w-1]);
	my @fns = reverse(('w0' .. 'w9')[0 .. $w-1]);

	my $tt = Logic::TruthTable->new(
		title => "$n-throw Rock Paper Scissors winner table",
		width =>  2 * $w,
		vars => [@vars_a, @vars_b],
		functions => [@fns],
		columns => [@columns],
	);

	return $tt;
}

sub extended_rps_cmp_table
{
	my($n) = @_;
	my @dontcares;

	#
	# If you raise this limit, you'll need to change
	# the statements that create the @vars_a and
	# @vars_b variables.
	#
	die "Throw count of 1023 or less please" unless ($n <= 1023);
	die "Not an odd number!" unless ($n % 2 == 1);

	# We don't know how many columns of input
	# we will need for our problem. But since the vars
	# and columns attributes are all array
	# references, these can be created programatically:
	#
	# How many binary columns do we need represent a throw?
	# For example, Rock-Paper-Scissors-Spock-Lizard
	# are five types of throws that can be represented
	# in three bits. Three bits gives a range of 0 .. 7,
	# so we have to don't-care not just 0, but 6 and 7
	# as well.
	#
	my $w = length(sprintf("%b", $n));
	my $r = (1 << $w) - 1;

	#
	# For example, a Rock-Paper-Scissors
	# comparison table:
	#
	# The two columns of output.
	# Player A  Player B | A wins  B wins
	#   0  0     0  0    |  d       d
	#   0  0     0  1    |  d       d
	#   0  0     1  0    |  d       d
	#   0  0     1  1    |  d       d
	#   0  1     0  0    |  d       d
	#   0  1     0  1    |  0       0  Rock v Rock
	#   0  1     1  0    |  0       1  Rock v Paper
	#   0  1     1  1    |  1       0  Rock v Scissors
	#   1  0     0  0    |  d       d
	#   1  0     0  1    |  1       0  Paper v Rock
	#   1  0     1  0    |  0       0  Paper v Paper
	#   1  0     1  1    |  0       1  Paper v Scissors
	#   1  1     0  0    |  d       d
	#   1  1     0  1    |  0       1  Scissors v Rock
	#   1  1     1  0    |  1       0  Scissors v Paper
	#   1  1     1  1    |  0       0  Scissors v Scissors
	#
	# Combining the output columns gives us values
	# of 2 (A wins), 1 (B wins), and 0 (Tie). Changing
	# that to 1, -1, and 0 is fairly straightforward.
	# (A math way would be (x * (3*x - 5))/2, but a
	# ternary operator is probably simpler.)
	#
	my(@awins, @bwins);

	#
	# Now, all the possible combinations of player A vs. player B.
	#
	for my $player_a (0 .. $r)
	{
		for my $player_b (0 .. $r)
		{
			my $row = ($player_a << $w) + $player_b;

			if ($player_b == 0 or $player_a == 0 or
				$player_a > $n or $player_b > $n)
			{
				push @dontcares, $row;
			}
			elsif (rpswinner($player_a, $player_b, $r) == $player_a)
			{
				push @awins, $row;
			}
			else
			{
				push @bwins, $row;
			}
		}
	}

	#
	# And the variable and function names.
	# (We are assuming fewer than 1024 choices here.)
	#
	my @vars_a = reverse(('a0' .. 'a9')[0 .. $w-1]);
	my @vars_b = reverse(('b0' .. 'b9')[0 .. $w-1]);

	my $tt = Logic::TruthTable->new(
		title => "$n-throw Rock Paper Scissors comparison",
		width =>  2 * $w,
		vars => [@vars_a, @vars_b],
		functions => [qw(c1 c0)],
		columns => [
			{
				dontcares => [@dontcares],
				minterms => [@awins],
			},
			{
				dontcares => [@dontcares],
				minterms => [@bwins],
			},
			],
	);

	return $tt;
}

#
# 'Winner' function for an extended Rock Paper Scissors game.
#
sub rpswinner
{
	my($player_a, $player_b, $r) = @_;

	return 0 if ($player_a == $player_b);	# Tie, of course.

	my $val = $player_a - $player_b + $r;

	return $player_a if ($val % 3 == 1);
	return $player_b;
}



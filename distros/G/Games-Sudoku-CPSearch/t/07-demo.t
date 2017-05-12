#!perl -T

use Test::More tests => 1;
use Games::Sudoku::CPSearch;

my $puzzle = <<PUZZLE;
4.....8.5
.3.......
...7.....
.2.....6.
....8.4..
....1....
...6.3.7.
5..2.....
1.4......
PUZZLE

$puzzle =~ s/\s//g;

my $solved = <<SOLVED;
417369825
632158947
958724316
825437169
791586432
346912758
289643571
573291684
164875293
SOLVED

$solved =~ s/\s//g;

my $sudoku = Games::Sudoku::CPSearch->new();
my $success = 0;
if (defined $sudoku->set_puzzle($puzzle)) {
	if ($sudoku->solve() eq $solved) {
		$success = 1;
	}
}

is($success, 1);

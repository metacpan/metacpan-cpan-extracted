#!perl -T

use Test::More tests => 1;
use Games::Sudoku::CPSearch;

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
my $verified = $sudoku->_verify($solved);
is($verified, 1);

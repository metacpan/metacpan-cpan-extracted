#!perl -T

use Test::More tests => 1;
use Games::Sudoku::CPSearch;

my $easy_unsolved = "..3.2.6..9..3.5..1..18.64....81.29..7.......8..67.82....26.95..8..2.3..9..5.1.3..";
my $easy_solved = "483921657967345821251876493548132976729564138136798245372689514814253769695417382";

my $o = Games::Sudoku::CPSearch->new();
$o->set_puzzle($easy_unsolved);
$o->solve();
is($o->solution(), $easy_solved);

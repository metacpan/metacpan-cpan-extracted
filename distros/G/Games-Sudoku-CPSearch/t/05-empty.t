#!perl -T

use Test::More tests => 1;
use Games::Sudoku::CPSearch;

my $empty = ".................................................................................";

my $oempty = Games::Sudoku::CPSearch->new();
$oempty->set_puzzle($empty);
$oempty->solve();
is($oempty->_verify($oempty->solution()),1);

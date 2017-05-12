package main;

use strict;
use warnings;

use Test::More 0.88;

require_ok 'Games::Sudoku::General'
    or BAIL_OUT 'Can not continue: unable to load Games::Sudoku::General';

isa_ok Games::Sudoku::General->new(), 'Games::Sudoku::General'
    or BAIL_OUT 'Can not continue: unable to instantiate Games::Sudoku::General';

done_testing;

1;

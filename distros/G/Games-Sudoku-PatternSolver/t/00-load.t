#!/usr/bin/env perl

use warnings;
use strict;
use Test::More tests => 4;

BEGIN {
    use_ok( 'Games::Sudoku::PatternSolver' );
    use_ok( 'Games::Sudoku::PatternSolver::Generator' );
    use_ok( 'Games::Sudoku::PatternSolver::CPLogic' );
    use_ok( 'Games::Sudoku::PatternSolver::PlayerIF' );
}

diag( "Using Games::Sudoku::PatternSolver::*" );

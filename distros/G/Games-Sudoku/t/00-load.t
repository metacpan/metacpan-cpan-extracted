#!/usr/bin/env perl

use warnings;
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Games::Sudoku::Kubedoku' );
}

diag( "Using Games::Sudoku::Kubedoku" );

# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Games::Sudoku::OO::Board' ); }

my $object = Games::Sudoku::OO::Board->new ();
isa_ok ($object, 'Games::Sudoku::OO::Board');



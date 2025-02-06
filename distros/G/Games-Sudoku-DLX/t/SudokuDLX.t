#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 6;

use Games::Sudoku::DLX qw( solve_sudoku );

my $tests = [
    {
        puzzle => [
            [ 0, 2, 0, 0, 7, 0, 0, 0, 0 ],
            [ 0, 0, 1, 0, 0, 0, 8, 4, 0 ],
            [ 0, 0, 0, 5, 0, 0, 1, 0, 0 ],
            [ 9, 0, 0, 0, 1, 0, 7, 6, 4 ],
            [ 5, 0, 0, 0, 6, 0, 0, 0, 0 ],
            [ 4, 0, 0, 0, 9, 0, 0, 3, 0 ],
            [ 0, 0, 7, 9, 0, 0, 0, 0, 0 ],
            [ 0, 3, 0, 4, 0, 0, 0, 5, 0 ],
            [ 0, 0, 0, 0, 0, 0, 0, 0, 8 ],
        ],
        regions => [ [1,9], [9,1], [3,3], ],
        solutions => 1,
        message => "Puzzle 1 has 1 solution",
    },
    {
        puzzle => [
            [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ],
            [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ],
            [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ],
            [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ],
            [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ],
            [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ],
            [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ],
            [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ],
            [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ],
        ],
        regions => [ [1,9], [9,1], [3,3], ],
        solutions => 0,
        message => "Puzzle 2 has no solutions",
    },
    {
        puzzle => [
            [ 0, 4, 0, 0, 2, 0 ],
            [ 0, 0, 0, 0, 0, 6 ],
            [ 1, 0, 0, 0, 0, 0 ],
            [ 5, 0, 0, 6, 0, 0 ],
            [ 0, 0, 0, 1, 0, 3 ],
            [ 0, 0, 0, 0, 0, 2 ],
        ],
        regions => [ [1,6], [6,1], [2,3], [3,2], ],
        solutions => 1,
        message => "Puzzle FPLS(6) has 1 solution",
    },
    {
        puzzle => [
            [ 0, 4, 0, 0, 2, 0 ],
            [ 0, 0, 0, 0, 0, 6 ],
            [ 1, 0, 0, 0, 0, 0 ],
            [ 5, 0, 0, 6, 0, 0 ],
            [ 0, 0, 0, 1, 0, 3 ],
            [ 0, 0, 0, 0, 0, 2 ],
        ],
        regions => [ [1,6], [6,1], [2,3], ],
        solutions => 12,
        message => "Puzzle SPLS(2,3) has 12 solution",
    },
];

for my $test (@$tests) {
    my $solutions = solve_sudoku(
        puzzle  => $test->{puzzle},
        regions => $test->{regions},
    );
    ok(@$solutions == $test->{solutions}, $test->{message});
}

# Test 3: Invalid region size
my $nine_zeros = [
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
];
my $invalid_regions = [ [2,5] ];
eval {
    solve_sudoku(
        puzzle  => $nine_zeros,
        regions => $invalid_regions,
    );
};
like($@, qr/Invalid region size/, 'Puzzle 3 has invalid region size');

# Test 4: Invalid cell value
my $invalid_cell_puzzle = [
    [0, 2, 0, 0, 7, 0, 0, 0, 0],
    [0, 0, 1, 0, 0, 0, 8, 4, 0],
    [0, 0, 0, 5, 0, 0, 1, 0, 0],
    [9, 0, 0, 0, 1, 0, 7, 6, 4],
    [5, 0, 0, 0, 6, 0, 0, 0, 0],
    [4, 0, 0, 0, 9, 0, 0, 3, 10], # Invalid cell value 10
    [0, 0, 7, 9, 0, 0, 0, 0, 0],
    [0, 3, 0, 4, 0, 0, 0, 5, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 8],
];
my $sudoku_regions = [ [1,9], [9,1], [3,3] ];
eval {
    solve_sudoku(
        puzzle  => $invalid_cell_puzzle,
        regions => $sudoku_regions,
    );
};
like($@, qr/Invalid cell value/, 'Puzzle 4 has invalid cell value');

1;

__END__

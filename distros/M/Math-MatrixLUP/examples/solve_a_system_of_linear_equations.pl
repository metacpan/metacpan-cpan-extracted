#!/usr/bin/perl

# Solve a system of linear equations.

use 5.010;
use strict;
use warnings;

use lib qw(../lib);
use Math::MatrixLUP;
use Math::AnyNum qw(:overload);

#<<<
my $A = Math::MatrixLUP->new([
    [2, -1,  5,  1],
    [3,  2,  2, -6],
    [1,  3,  3, -1],
    [5, -2, -3,  3],
]);
#>>>

my $solution = $A->solve([-3, -32, -47, 49]);

say "Determinant: ", $A->det;
say "Solution: [", join(', ', @$solution), "]\n";
say $A * Math::MatrixLUP->column($solution);

print "\nA^(-1) = ";
say $A->inv;

__END__
Determinant: 684
Solution: [2, -12, -4, 1]

[
  [-3],
  [-32],
  [-47],
  [49]
]

A^(-1) = [
  [4/171, 11/171, 10/171, 8/57],
  [-55/342, -23/342, 119/342, 2/57],
  [107/684, -5/684, 11/684, -7/114],
  [7/684, -109/684, 103/684, 7/114]
]

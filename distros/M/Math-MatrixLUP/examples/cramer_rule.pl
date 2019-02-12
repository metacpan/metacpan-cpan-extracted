#!/usr/bin/perl

# Cramer's rule for solving a system of linear equations.

# See also:
#   https://rosettacode.org/wiki/Cramer%27s_rule
#   https://en.wikipedia.org/wiki/Cramer%27s_rule

use 5.010;
use strict;
use warnings;

use lib qw(../lib);
use Math::MatrixLUP;

sub cramers_rule {
    my ($A, $terms) = @_;

    my @solutions;
    my $det = $A->determinant;

    foreach my $i (0 .. $#{$A}) {
        my $Ai = $A->set_column($i, $terms);
        push @solutions, $Ai->determinant / $det;
    }

    return @solutions;
}

my $matrix = Math::MatrixLUP->new([
    [2, -1,  5,  1],
    [3,  2,  2, -6],
    [1,  3,  3, -1],
    [5, -2, -3,  3],
]);

my $free_terms = [-3, -32, -47, 49];
my ($w, $x, $y, $z) = cramers_rule($matrix, $free_terms);

print "w = $w\n";
print "x = $x\n";
print "y = $y\n";
print "z = $z\n";

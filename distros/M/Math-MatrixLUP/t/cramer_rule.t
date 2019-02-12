#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 4;

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

#<<<
my $A = Math::MatrixLUP->new([
    [2, -1,  5,  1],
    [3,  2,  2, -6],
    [1,  3,  3, -1],
    [5, -2, -3,  3],
]);
#>>>

my $free_terms = [-3, -32, -47, 49];
my ($w, $x, $y, $z) = cramers_rule($A, $free_terms);

is("$w", 2);
is("$x", -12);
is("$y", -4);
is("$z", 1);

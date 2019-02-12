#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Math::AnyNum };
    plan skip_all => "Math::AnyNum is not installed"
      if $@;
    plan skip_all => "Math::AnyNum >= 0.30 is needed"
      if $Math::AnyNum::VERSION < 0.30;
}

plan tests => 5;

use Math::MatrixLUP;
use Math::AnyNum qw(:overload);

#<<<
my $A = Math::MatrixLUP->new([ # base test case
      [  1,  2,  -1,  -4 ],
      [  2,  3,  -1, -11 ],
      [ -2,  0,  -3,  22 ],
    ]);

is_deeply([@{$A->rref}], [
     [1,     0,     0,    -8],
     [0,     1,     0,     1],
     [0,     0,     1,    -2],
]);

my $B = Math::MatrixLUP->new([ # mix of number styles
        [  3,   0,   -3,    1],
        [1/2, 3/2,   -3,   -2],
        [1/5, 4/5, -8/5, 3/10]
    ]);

is_deeply([@{$B->rref}], [
     [1,     0,     0, -41/2],
     [0,     1,     0, -217/6],
     [0,     0,     1, -125/6],
]);

my $C = Math::MatrixLUP->new([ # degenerate case
      [ 1,  2,  3,  4,  3,  1],
      [ 2,  4,  6,  2,  6,  2],
      [ 3,  6, 18,  9,  9, -6],
      [ 4,  8, 12, 10, 12,  4],
      [ 5, 10, 24, 11, 15, -4],
    ]);

is_deeply([@{$C->rref}], [
     [1,     2,     0,     0,     3,     4],
     [0,     0,     1,     0,     0,    -1],
     [0,     0,     0,     1,     0,     0],
     [0,     0,     0,     0,     0,     0],
     [0,     0,     0,     0,     0,     0],
]);
#>>>

sub gauss_jordan_solve {
    my ($matrix, $column_vector) = @_;
    [map { $_->[-1] } $matrix->concat($column_vector)->rref->rows];
}

{
#<<<
    my $A = Math::MatrixLUP->new([
        [1, 0, 0, 0, 0, 0],
        [1, 63/100, 39/100, 1/4, 4/25, 1/10],
        [1, 63/50, 79/50, 99/50, 249/100, 313/100],
        [1, 47/25, 71/20, 67/10, 631/50, 119/5],
        [1, 251/100, 158/25, 397/25, 399/10, 2507/25],
        [1, 157/50, 987/100, 3101/100, 9741/100, 15301/50]
    ]);

    my $vector = Math::MatrixLUP->column([-1/100, 61/100, 91/100, 99/100, 3/5, 1/50]);
    my $solution = gauss_jordan_solve($A, $vector);

    is_deeply($solution, [
                             -1/100,
          655870882787/409205648497,
         -660131804286/409205648497,
          509663229635/409205648497,
         -200915766608/409205648497,
           26909648324/409205648497,
    ]);
#>>>
}

sub gauss_jordan_invert {
    my ($matrix) = @_;

    my $n = scalar(@$matrix);
    my $I = Math::MatrixLUP->identity($n);

    Math::MatrixLUP->new([map { [@{$_}[$n .. $#{$_}]] } $matrix->concat($I)->rref->rows]);
}

{
#<<<
    my $A = Math::MatrixLUP->new([
        [-1, -2, 3, 2],
        [-4, -1, 6, 2],
        [ 7, -8, 9, 1],
        [ 1, -2, 1, 3],
    ]);

    is_deeply($A->invert->as_array, gauss_jordan_invert($A)->as_array);
#>>>
}

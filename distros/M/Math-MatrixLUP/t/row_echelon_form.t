#!perl -T

use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 2;

use Math::MatrixLUP;

#<<<
my $A = Math::MatrixLUP->new([
    [2, -1,  5,  1],
    [3,  2,  2, -6],
    [1,  3,  3, -1],
    [5, -2, -3,  3],
]);
#>>>

my $vector        = [-3, -32, -47, 49];
my $column_vector = Math::MatrixLUP->column($vector);

my $B = $A->concat($column_vector);

my $rref = $B->rref;
my $res  = Math::MatrixLUP->identity(4)->concat(Math::MatrixLUP->column([2, -12, -4, 1]));

is_deeply([@$rref], [@$res]);

my $solution = $A->concat(Math::MatrixLUP->new([[-3], [-32], [-47], [49]]))->rref->transpose->[-1];

is(join(', ', @$solution), "2, -12, -4, 1");

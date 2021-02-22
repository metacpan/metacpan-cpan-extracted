#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Math::AnyNum };
    plan skip_all => "Math::AnyNum is not installed"
      if $@;
    plan skip_all => "Math::AnyNum >= 0.38 is needed"
      if ($Math::AnyNum::VERSION < 0.38);
}

plan tests => 71;

use Math::MatrixLUP;
use Math::AnyNum qw(:overload);

{
#<<<
    my $A = Math::MatrixLUP->new([
        [1, 2],
        [3, 4],
    ]);

    my $B = Math::MatrixLUP->new([
        [-3, -8, 3],
        [-2,  1, 4],
    ]);

    is_deeply(($A * $B)->as_array, [
        [-7,  -6,  11],
        [-17, -20,  25],
    ]);
#>>>
}

{
#<<<
    my $A = Math::MatrixLUP->new([
          [1, 2],
          [3, 4],
          [5, 6],
          [7, 8]
    ]);

    my $B = Math::MatrixLUP->new([
          [1, 2, 3],
          [4, 5, 6]
    ]);

    is_deeply($A->mul($B)->as_array, [
        [ 9,  12,  15],
        [19,  26,  33],
        [29,  40,  51],
        [39,  54,  69],
    ]);
#>>>
}

{
#<<<

    my $A = Math::MatrixLUP->new([
        [1,  1,  1,   1],
        [2,  4,  8,  16],
        [3,  9, 27,  81],
        [4, 16, 64, 256],
    ]);

    my $B = Math::MatrixLUP->new([
        [  4  , -3  ,  4/3,  -1/4 ],
        [-13/3, 19/4, -7/3,  11/24],
        [  3/2, -2  ,  7/6,  -1/4 ],
        [ -1/6,  1/4, -1/6,   1/24],
    ]);

    is_deeply(($A*$B)->as_array, Math::MatrixLUP->I(4)->as_array);
#>>>
}

{
#<<<
    my $A = Math::MatrixLUP->new([
        [2, 9, 4],
        [7, 5, 3],
        [6, 1, 8],
    ]);
#>>>

    is($A->det, -360);
}

{
#<<<
    my $A = Math::MatrixLUP->new([
        [  0,  1,  2,  3,  4 ],
        [  5,  6,  7,  8,  9 ],
        [ 10, 11, 12, 13, 14 ],
        [ 15, 16, 17, 18, 19 ],
        [ 20, 21, 22, 23, 24 ]
    ]);

    is($A->det, 0);
    is_deeply(($A**(-1))->as_array, $A->inv->as_array);
#>>>
}

{
#<<<
    my $A = Math::MatrixLUP->new([
        [1, 2, 0],
        [0, 3, 1],
        [1, 0, 0],
    ]);

    is_deeply($A->pow(8)->as_array, [
        [1291,  9580,  2930],
        [1465, 10871,  3325],
        [395,  2930,   896],
    ]);

    is_deeply($A->pow(9)->as_array, [
        [4221, 31322,  9580],
        [4790, 35543, 10871],
        [1291,  9580,  2930],
    ]);

    is_deeply(($A**10)->as_array, [
        [13801, 102408,  31322],
        [15661, 116209,  35543],
        [4221,  31322,   9580],
    ]);

    is_deeply(($A**-10)->as_array, $A->inv->pow(10)->as_array);
    is_deeply(($A**-10)->as_array, $A->pow(10)->inv->as_array);
#>>>
}

{
#<<<
    my $A = Math::MatrixLUP->new([
        [1, 1],
        [1, 0]
    ]);

    my $B = $A**100;
    is($B->[1][1] + $B->[1][0], $B->[0][0]);
    is($B->[0][0] - $B->[0][1], $B->[1][1]);
    is($B->[0][1], 354224848179261915075);
#>>>
}

{
    my $A = Math::MatrixLUP->new([[3, 1, 4], [1, 5, 9]]);
    my $B = Math::MatrixLUP->new([[2, 7, 1], [8, 2, 2]]);

    is_deeply(($A + $B)->as_array, [[5, 8,  5], [9,  7, 11]]);
    is_deeply(($A - $B)->as_array, [[1, -6, 3], [-7, 3, 7]]);

    is_deeply(($A + 42)->as_array, [[45,  43,  46],  [43,  47,  51]]);
    is_deeply(($A - 42)->as_array, [[-39, -41, -38], [-41, -37, -33]]);
    is_deeply(($A * 42)->as_array, [[126, 42,  168], [42,  210, 378]]);
    is_deeply(($A / 42)->as_array, [[1 / 14, 1 / 42, 2 / 21], [1 / 42, 5 / 42, 3 / 14]]);
    is_deeply(($A % 3)->as_array,  [[0, 1, 1], [1, 2, 0]]);

    is_deeply(($A & 12)->as_array, [[0,  0,  4],  [0,  4,  8]]);
    is_deeply(($A | 3)->as_array,  [[3,  3,  7],  [3,  7,  11]]);
    is_deeply(($A ^ 42)->as_array, [[41, 43, 46], [43, 47, 35]]);
    is_deeply(($A << 3)->as_array, [[24, 8,  32], [8,  40, 72]]);
    is_deeply(($A >> 2)->as_array, [[0,  0,  1],  [0,  1,  2]]);

#<<<
    is_deeply($A->map(sub{my ($i, $j) = @_; $_ * $B->[$i][$j] })->as_array, [[6, 7, 4], [8, 10, 18]]);
    is_deeply($A->map(sub{my ($i, $j) = @_; $_ / $B->[$i][$j] })->as_array, [[3/2, 1/7, 4], [1/8, 5/2, 9/2]]);
    is_deeply($A->map(sub{my ($i, $j) = @_; $_ ** $B->[$i][$j] })->as_array, [[9, 1, 4], [1, 25, 81]]);
#>>>
}

{
#<<<
    my $A = Math::MatrixLUP->new([
        [2, -1,  5,  1],
        [3,  2,  2, -6],
        [1,  3,  3, -1],
        [5, -2, -3,  3],
    ]);

    my $B = Math::MatrixLUP->new([
        [1,  1,  1,   1],
        [2,  4,  8,  16],
        [3,  9, 27,  81],
        [4, 16, 64, 256],
    ]);

    is_deeply(($A/$B)->as_array, ($A*$B->inv)->as_array);
    is_deeply(($B/$A)->as_array, ($B*$A->inv)->as_array);

    is_deeply(('42' / $A)->as_array, ($A->inv*42)->as_array);
    is_deeply(('13' / $B)->as_array, ('13'*('1'/$B))->as_array);

    is_deeply(('42' - $A)->as_array, (-$A + 42)->as_array);
    is_deeply(('13' - $B)->as_array, (-$B + 13)->as_array);
    is_deeply(('-42' - $A)->as_array, ($A->neg - 42)->as_array);
#>>>
}

{
#<<<
    my $A = Math::MatrixLUP->new([
        [1, 1],
        [1, 0],
    ]);

    my $mod = 123456789;

    my $x1 = $A->powmod(10000000, $mod);
    my $x2 = $A->powmod(-10000000, $mod);

    is_deeply($x1->as_array, [
        [10217497, 90624903],
        [90624903, 43049383],
    ]);

    is_deeply($x2->as_array, [
        [43049383, 32831886],
        [32831886, 10217497],
    ]);

    my $r = (($x1*$x2) % $mod);

    is_deeply($r->as_array, [
        [1, 0],
        [0, 1],
    ]);

    is_deeply((($x2*$x1) % $mod)->as_array, $r->as_array);
#>>>
}

{
#<<<
    my $A = Math::MatrixLUP->new([
        [2, 9, 4],
        [7, 5, 3],
        [6, 1, 8],
    ]);

    my $mod = 1234567;

    my $x1 = $A->powmod(42, $mod);
    my $x2 = $A->powmod(-42, $mod);

    is_deeply($x1->as_array, [
        [912772, 934000, 934000],
        [934000, 912772, 934000],
        [934000, 934000, 912772],
    ]);

    is_deeply($x2->as_array, [
        [19620, 12234, 12234],
        [12234, 19620, 12234],
        [12234, 12234, 19620],
    ]);

    my $r = (($x1*$x2) % $mod);

    is_deeply($r->as_array, [
        [1, 0, 0],
        [0, 1, 0],
        [0, 0, 1],
    ]);

    is_deeply((($x2*$x1) % $mod)->as_array, $r->as_array);
#>>>
}

{
    my $A = Math::MatrixLUP->new([[2, -1, 5, 1], [3, 2, 2, -6], [1, 3, 3, -1], [5, -2, -3, 3],]);

    my $det = $A->determinant;                  # 684
    my $sol = $A->solve([-3, -32, -47, 49]);    # [2, -12, -4, 1]
    my $inv = $A->invert;

    is($det, 684);
    is_deeply($sol, [2, -12, -4, 1]);

    is_deeply(
              $inv->as_array,
              [[4 / 171,   11 / 171,   10 / 171,  8 / 57],
               [-55 / 342, -23 / 342,  119 / 342, 2 / 57],
               [107 / 684, -5 / 684,   11 / 684,  -7 / 114],
               [7 / 684,   -109 / 684, 103 / 684, 7 / 114]
              ]
             );

    is_deeply($A->mul($A)->as_array, [[11, 9, 20, 6], [-16, 19, 43, -29], [9, 16, 23, -23], [16, -24, 3, 29]]);

    is_deeply($A->pow(3)->as_array, ($A * $A * $A)->as_array);

    is_deeply(($A**3)->as_array, [[99, 55, 115, -45], [-77, 241, 174, -260], [-26, 138, 215, -179], [108, -113, -46, 244],]);

    is_deeply($A->map(sub { 2 * $_ })->as_array, [[4, -2, 10, 2], [6, 4, 4, -12], [2, 6, 6, -2], [10, -4, -6, 6]]);

    is_deeply($A->transpose->as_array, [[2, 3, 1, 5], [-1, 2, 3, -2], [5, 2, 3, -3], [1, -6, -1, 3]]);

    is_deeply(Math::MatrixLUP->new([[1, 2, 3, 4]])->transpose->as_array, [[1], [2], [3], [4],]);

    is_deeply($inv->floor->as_array, [[0, 0, 0, 0], [-1, -1, 0, 0], [0, -1, 0, -1], [0, -1, 0, 0]]);

    is_deeply($inv->ceil->as_array, [[1, 1, 1, 1], [0, 0, 1, 1], [1, 0, 1, 0], [1, 0, 1, 1]]);

    is_deeply($A->mod($A + 1)->as_array, [[10, -1, 10, 10], [4, -1, 4, 4], [9, -1, 9, 9], [6, -1, 6, 6]]);

    is_deeply(Math::MatrixLUP::mod(3, $A)->as_array, [[2, 8, 4, 8], [5, 1, 1, 5], [6, 8, 0, 6], [1, 1, 5, 0]]);

    is_deeply(Math::MatrixLUP::mod(2, $A)->as_array, [[1, 7, 2, 7], [4, 0, 2, 4], [5, 7, 2, 5], [0, 0, 2, -1]]);

    is_deeply(($A % 2)->as_array, [[0, 1, 1, 1], [1, 0, 0, 0], [1, 1, 1, 1], [1, 0, 1, 1]]);

    is_deeply(Math::MatrixLUP::div(4, $A)->as_array, ($A->inv * 4)->as_array);

    is_deeply(
              Math::MatrixLUP::div(4, $A)->as_array,
              [[16 / 171,   44 / 171,   40 / 171,  32 / 57],
               [-110 / 171, -46 / 171,  238 / 171, 8 / 57],
               [107 / 171,  -5 / 171,   11 / 171,  -14 / 57],
               [7 / 171,    -109 / 171, 103 / 171, 14 / 57]
              ]
             );
}

{
    is_deeply(Math::MatrixLUP->row([1, 2, 3, 4])->as_array, [[1, 2, 3, 4]]);

    is_deeply(Math::MatrixLUP->column([1, 2, 3, 4])->as_array, [[1], [2], [3], [4],]);

    is_deeply(Math::MatrixLUP->diagonal([1, 2, 3, 4])->as_array, [[1, 0, 0, 0], [0, 2, 0, 0], [0, 0, 3, 0], [0, 0, 0, 4]]);

    is_deeply(Math::MatrixLUP->scalar(4, 3)->as_array, [[3, 0, 0, 0], [0, 3, 0, 0], [0, 0, 3, 0], [0, 0, 0, 3]]);

    is_deeply(Math::MatrixLUP->scalar(0, 42)->as_array, []);

    is_deeply(Math::MatrixLUP->zero(4, 3)->as_array, [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]]);

    is_deeply(Math::MatrixLUP->zero(4, 0)->as_array, [[], [], [], [],]);

    is_deeply(Math::MatrixLUP->zero(0, 3)->as_array, []);

    is_deeply(Math::MatrixLUP::I(5)->as_array,
              [[1, 0, 0, 0, 0], [0, 1, 0, 0, 0], [0, 0, 1, 0, 0], [0, 0, 0, 1, 0], [0, 0, 0, 0, 1]]);

    is(Math::MatrixLUP->new([])->det, 1);
}

#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 118;

use Math::MatrixLUP;

{
#<<<
    my $A = Math::MatrixLUP->new([
        [1,  1,   1,   1],
        [2,  4,   8,  16],
        [3,  9,  27,  81],
        [4, 16,  64, 256],
        [5, 25, 125, 625],
    ]);
#>>>

    is($A->transpose, ~$A);

#<<<
    is_deeply($A->transpose->as_array, [
        [1,  2,  3,   4,   5],
        [1,  4,  9,  16,  25],
        [1,  8, 27,  64, 125],
        [1, 16, 81, 256, 625],
    ]);
#>>>

    is(~$A <=> $A,           1);
    is($A <=> $A->transpose, -1);
}

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

    ok($A != $B);
    ok($B != $A);

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
          [7, 8],
    ]);

    do {
      my ($row_size, $col_size) = $A->size;
        is($row_size, 4);
        is($col_size, 2);
    };

    ok($A == $A);
    is($A, $A);

    my $B = Math::MatrixLUP->new([
          [1, 2, 3],
          [4, 5, 6],
    ]);

    is($A <=> $B, -1);
    is($B <=> $A, 1);
    is($A <=> $A, 0);
    is($B <=> $B, 0);

    ok($A < $B);
    ok($B > $A);

    ok(!($A > $B));
    ok(!($B < $A));

    ok(!($B <= $A));
    ok(!($A >= $B));

    ok($A <= $A);
    ok($A <= $B);
    ok($B >= $A);

    is_deeply($A->mul($B)->as_array, [
        [ 9,  12,  15],
        [19,  26,  33],
        [29,  40,  51],
        [39,  54,  69],
    ]);
#>>>
}

{
    my $A = Math::MatrixLUP->new([
          [1, 2],
          [3, 4],
          [5, 6],
          [7, 8],
    ]);

    is_deeply(($A+4)->as_array, [
          [1+4, 2+4],
          [3+4, 4+4],
          [5+4, 6+4],
          [7+4, 8+4],
    ]);

    is_deeply(($A-4)->as_array, [
          [1-4, 2-4],
          [3-4, 4-4],
          [5-4, 6-4],
          [7-4, 8-4],
    ]);

    is_deeply(($A*4)->as_array, [
          [1*4, 2*4],
          [3*4, 4*4],
          [5*4, 6*4],
          [7*4, 8*4],
    ]);

    is_deeply(($A/4)->as_array, [
          [1/4, 2/4],
          [3/4, 4/4],
          [5/4, 6/4],
          [7/4, 8/4],
    ]);

    is_deeply(($A%5)->as_array, [
          [1%5, 2%5],
          [3%5, 4%5],
          [5%5, 6%5],
          [7%5, 8%5],
    ]);
}

{
    my $A = Math::MatrixLUP->new([
          [1, 2],
          [3, 4],
          [5, 6],
          [7, 8],
    ]);

    is_deeply((4+$A)->as_array, [
          [1+4, 2+4],
          [3+4, 4+4],
          [5+4, 6+4],
          [7+4, 8+4],
    ]);

    is_deeply((4-$A)->as_array, [
          [4-1, 4-2],
          [4-3, 4-4],
          [4-5, 4-6],
          [4-7, 4-8],
    ]);

    is_deeply((4*$A)->as_array, [
          [1*4, 2*4],
          [3*4, 4*4],
          [5*4, 6*4],
          [7*4, 8*4],
    ]);
}

{
    my $A = Math::MatrixLUP->new([
        [2, 9, 4],
        [7, 5, 3],
        [6, 1, 8],
    ]);

    is_deeply((4/$A)->as_array, (4 * $A**(-1))->as_array);
    is_deeply((5%$A)->as_array, (5 - $A * (5/$A)->floor)->as_array);
}

{
    my $A = Math::MatrixLUP->new([
          [1, 2],
          [-3, -4],
          [5, -6],
          [7, -8],
    ]);

    is_deeply(abs($A)->as_array, [
          [1, 2],
          [3, 4],
          [5, 6],
          [7, 8],
    ]);
}

{
    my $A = Math::MatrixLUP->new([
          [2.3, -3.8],
          [4.9, -2.3],
          [1.2, 4],
          [7.11, -9],
    ]);

    is_deeply($A->floor->as_array, [
          [2, -4],
          [4, -3],
          [1, 4],
          [7, -9],
    ]);

    is_deeply($A->ceil->as_array, [
          [3, -3],
          [5, -2],
          [2, 4],
          [8, -9],
    ]);
}


{
    my $A = Math::MatrixLUP->from_rows(
          [1, 2],
          [-3, -4],
          [5, -6],
          [7, -8],
    );

    is_deeply($A->as_array, [
          [1, 2],
          [-3, -4],
          [5, -6],
          [7, -8],
    ]);
}

{
    my $A = Math::MatrixLUP->from_columns(
          [1, 2],
          [-3, -4],
          [5, -6],
          [7, -8],
    );

    is_deeply($A->as_array, [
        [1, -3, 5, 7],
        [2, -4, -6, -8],
    ]);
}

{
#<<<
    my $A = Math::MatrixLUP->new([
        [2, 9, 4],
        [7, 5, 3],
        [6, 1, 8],
    ]);
#>>>

    is_deeply($A->diagonal,      [2, 5, 8]);
    is_deeply($A->anti_diagonal, [4, 5, 6]);

    is_deeply($A->row(0),    [2, 9, 4]);
    is_deeply($A->column(0), [2, 7, 6]);

    is_deeply($A->row(1),    [7, 5, 3]);
    is_deeply($A->column(1), [9, 5, 1]);

    is_deeply($A->row(-1),    [6, 1, 8]);
    is_deeply($A->column(-1), [4, 3, 8]);

    my @cols = $A->columns;
    my @rows = $A->rows;

    foreach my $i(0..$#cols) {
        is_deeply($cols[$i], $A->column($i));
    }

    foreach my $i(0..$#rows) {
        is_deeply($rows[$i], $A->row($i));
    }

    is($A->det, -360);
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
#>>>
}

{
    my $A = Math::MatrixLUP->new([[3, 1, 4], [1, 5, 9]]);
    my $B = Math::MatrixLUP->new([[2, 7, 1], [8, 2, 2]]);

    ok($A == $A);
    ok($B != $A);

    ok(!($A == $B));

    is_deeply(($A + $B)->as_array, [[5, 8,  5], [9,  7, 11]]);
    is_deeply(($A - $B)->as_array, [[1, -6, 3], [-7, 3, 7]]);

    is_deeply(($A >> $B)->as_array, [[0,  0,   2], [0,   1,  2]]);
    is_deeply(($A << $B)->as_array, [[12, 128, 8], [256, 20, 36]]);

    is_deeply(($B >> $A)->as_array, [[0,  3,  0],  [4,  0,  0]]);
    is_deeply(($B << $A)->as_array, [[16, 14, 16], [16, 64, 1024]]);

    is_deeply(($A + 42)->as_array, [[45,     43,     46],     [43,     47,     51]]);
    is_deeply(($A - 42)->as_array, [[-39,    -41,    -38],    [-41,    -37,    -33]]);
    is_deeply(($A * 42)->as_array, [[126,    42,     168],    [42,     210,    378]]);
    is_deeply(($A / 42)->as_array, [[1 / 14, 1 / 42, 2 / 21], [1 / 42, 5 / 42, 3 / 14]]);
    is_deeply(($A % 3)->as_array,  [[0,      1,      1],      [1,      2,      0]]);

    is_deeply((42 + $A)->as_array, [[45,  43, 46],  [43, 47,  51]]);
    is_deeply((42 - $A)->as_array, [[39,  41, 38],  [41, 37,  33]]);
    is_deeply((42 * $A)->as_array, [[126, 42, 168], [42, 210, 378]]);

    is_deeply(($A & 12)->as_array, [[0,  0,  4],  [0,  4,  8]]);
    is_deeply(($A | 3)->as_array,  [[3,  3,  7],  [3,  7,  11]]);
    is_deeply(($A ^ 42)->as_array, [[41, 43, 46], [43, 47, 35]]);
    is_deeply(($A << 3)->as_array, [[24, 8,  32], [8,  40, 72]]);
    is_deeply(($A >> 2)->as_array, [[0,  0,  1],  [0,  1,  2]]);

    is_deeply((12 & $A)->as_array, [[0,  0,  4],  [0,  4,  8]]);
    is_deeply((3 | $A)->as_array,  [[3,  3,  7],  [3,  7,  11]]);
    is_deeply((42 ^ $A)->as_array, [[41, 43, 46], [43, 47, 35]]);

#<<<
    is_deeply($A->map(sub{my ($i, $j) = @_; $_ * $B->[$i][$j] })->as_array, [[6, 7, 4], [8, 10, 18]]);
    is_deeply($A->map(sub{my ($i, $j) = @_; $_ / $B->[$i][$j] })->as_array, [[3/2, 1/7, 4], [1/8, 5/2, 9/2]]);
    is_deeply($A->map(sub{my ($i, $j) = @_; $_ ** $B->[$i][$j] })->as_array, [[9, 1, 4], [1, 25, 81]]);
#>>>
}

{    # Tests for empty matrices
    my $A = Math::MatrixLUP->new([]);
    my $B = Math::MatrixLUP->new([]);

    is($A->det, 1);
    is_deeply($A->inv->as_array, []);
    is_deeply($A->solve([]), []);

    is_deeply(($A + $B)->as_array,  []);
    is_deeply(($A - $B)->as_array,  []);
    is_deeply(($A * $B)->as_array,  []);
    is_deeply(($A / $B)->as_array,  []);
    is_deeply(($A**3)->as_array,    []);
    is_deeply(($A**(-1))->as_array, []);
}

{
    my $A = Math::MatrixLUP->new([]);

    my ($row_size, $col_size) = $A->size;

    is($row_size, 0);
    is($col_size, 0);
}

{
    my $A = Math::MatrixLUP->build(
        5, 6,
        sub {
            my ($i, $j) = @_;
            $i**$j;
        }
    );

    ok($A == $A);
    ok(!($A != $A));
    is($A <=> $A, 0);

#<<<
    is_deeply($A->as_array, [
        [1, 0,  0,  0,   0,    0],
        [1, 1,  1,  1,   1,    1],
        [1, 2,  4,  8,  16,   32],
        [1, 3,  9, 27,  81,  243],
        [1, 4, 16, 64, 256, 1024],
    ]);
#>>>
}

{
    my $A = Math::MatrixLUP->diagonal([42, 43, 44]);

#<<<
    is_deeply($A->as_array, [
        [42, 0, 0],
        [0, 43, 0],
        [0, 0, 44],
    ]);
#>>>
}

{
    my $A = Math::MatrixLUP->anti_diagonal([42, 43, 44]);

#<<<
    is_deeply($A->as_array, [
        [0, 0, 42],
        [0, 43, 0],
        [44, 0, 0],
    ]);
#>>>
}

{
    my $A = Math::MatrixLUP->new([[1, 2, 3], [4, 5, 6]]);
    my $B = Math::MatrixLUP->new([[1, 2, 3], [4, 5, 7]]);

    ok($A < $B);
    ok($B > $A);

    ok(!($A > $B));
    ok(!($B < $A));

    ok($A <= $B);
    ok($B >= $A);

    ok(!($B <= $A));
    ok(!($A >= $B));

    ok($A >= $A);
    ok($B <= $B);

    is($A <=> $B, -1);
    is($B <=> $A, 1);

    ok($A != $B);
    ok(!($A == $B));
}

{
    my @M;
    foreach my $n (0 .. 10) {

        # Build a nXn Redheffer matrix
        my $A = Math::MatrixLUP->build(
            $n,
            sub {
                my ($i, $j) = @_;
                ($j == 0 or ($j + 1) % ($i + 1) == 0) ? 1 : 0;
            }
        );

        push @M, $A->det;
    }

    is(join(', ', @M), "1, 1, 0, -1, -1, -2, -1, -2, -2, -2, -1");    # Mertens function
}

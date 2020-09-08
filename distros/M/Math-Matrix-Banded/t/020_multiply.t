#!perl -T
use 5.014;
use Test::More;

sub multiply_vector {
    my $matrix = Math::Matrix::Banded->new(N => 7);
    my $a      = [
        [2, 3, 0, 0, 0, 0 ,0],
        [4, 9, 7, 0, 0, 0, 0],
        [7, 5, 4, 1, 0, 0, 0],
        [0, 1, 6, 8, 4, 0, 0],
        [0, 0, 1, 3, 8, 7, 0],
        [0, 0, 0, 5, 6, 4, 1],
        [0, 0, 0, 0, 1, 3, 8],
    ];

    for (my $i=0;$i<@$a;$i++) {
        for (my $j=0;$j<@{$a->[$i]};$j++) {
            if ($a->[$i]->[$j] != 0) {
                $matrix->element($i, $j, $a->[$i]->[$j]);
            }
        }
    }

    is($matrix->m_below, 2, 'm_below = 2');
    is($matrix->m_above, 1, 'm_above = 1');
    is($matrix->element(4, 5), 7, 'element (4, 5) = 7');
    is_deeply(
        $matrix->multiply_vector([1, 0, 0, 0, 0, 0, 0]),
        [2, 4, 7, 0, 0, 0, 0],
        'extract column',
    );
    is_deeply(
        $matrix->multiply_vector([0, 1, 0, 0, 0, 0, 0]),
        [3, 9, 5, 1, 0, 0, 0],
        'extract column',
    );
    is_deeply(
        $matrix->multiply_vector([0, 0, 1, 0, 0, 0, 0]),
        [0, 7, 4, 6, 1, 0, 0],
        'extract column',
    );
    is_deeply(
        $matrix->multiply_vector([0, 0, 0, 1, 0, 0, 0]),
        [0, 0, 1, 8, 3, 5, 0],
        'extract column',
    );
    is_deeply(
        $matrix->multiply_vector([0, 0, 0, 0, 1, 0, 0]),
        [0, 0, 0, 4, 8, 6, 1],
        'extract column',
    );
    is_deeply(
        $matrix->multiply_vector([0, 0, 0, 0, 0, 1, 0]),
        [0, 0, 0, 0, 7, 4, 3],
        'extract column',
    );
    is_deeply(
        $matrix->multiply_vector([0, 0, 0, 0, 0, 0, 1]),
        [0, 0, 0, 0, 0, 1, 8],
        'extract column',
    );
    is_deeply(
        $matrix->multiply_vector([0, -1, 3, 4, -2, 6, 9]),
        [-3, 12, 11, 41, 41, 41, 88],
        'multiply example vector',
    );
}

sub multiply_matrix {
    my ($A, $B, $C);
    my ($a, $b, $c);
    my $target;

    $A = Math::Matrix::Banded->new(N => 7);
    $a = [
        [2, 3, 0, 0, 0, 0 ,0],
        [4, 9, 7, 0, 0, 0, 0],
        [7, 5, 4, 1, 0, 0, 0],
        [0, 1, 6, 8, 4, 0, 0],
        [0, 0, 1, 3, 8, 7, 0],
        [0, 0, 0, 5, 6, 4, 1],
        [0, 0, 0, 0, 1, 3, 8],
    ];

    for (my $i=0;$i<@$a;$i++) {
        for (my $j=0;$j<@{$a->[$i]};$j++) {
            if ($a->[$i]->[$j] != 0) {
                $A->element($i, $j, $a->[$i]->[$j]);
            }
        }
    }

    $B = Math::Matrix::Banded->new(N => 7);
    $b = [
        [1, 0, 0, 0, 0, 0, 0],
        [0, 1, 0, 0, 0, 0, 0],
        [0, 0, 1, 0, 0, 0, 0],
        [0, 0, 0, 1, 0, 0, 0],
        [0, 0, 0, 0, 1, 0, 0],
        [0, 0, 0, 0, 0, 1, 0],
        [0, 0, 0, 0, 0, 0, 1],
    ];

    for (my $i=0;$i<@$b;$i++) {
        for (my $j=0;$j<@{$b->[$i]};$j++) {
            if ($b->[$i]->[$j] != 0) {
                $B->element($i, $j, $b->[$i]->[$j]);
            }
        }
    }

    $C = $A->multiply_matrix($B);
    for (my $i=0;$i<$A->N;$i++) {
        for (my $j=0;$j<$A->N;$j++) {
            ok(
                abs($C->element($i, $j) - $A->element($i, $j)) < 1e-6,
                "element ($i, $j)",
            );
        }
    }

    $B = Math::Matrix::Banded->new(N => 7);
    $b = [
        [ 3,  5, -1,  6,  0,  0,  0],
        [-2,  0,  2,  4,  7,  0,  0],
        [ 0,  3,  5, -2, -1,  3,  0],
        [ 0,  0,  1, -1,  0,  4,  5],
        [ 0,  0,  0,  2,  3,  1,  6],
        [ 0,  0,  0,  0,  1,  9,  4],
        [ 0,  0,  0,  0,  0,  2,  1],
    ];

    for (my $i=0;$i<@$b;$i++) {
        for (my $j=0;$j<@{$b->[$i]};$j++) {
            if ($b->[$i]->[$j] != 0) {
                $B->element($i, $j, $b->[$i]->[$j]);
            }
        }
    }

    $C = $A->multiply_matrix($B);
    $target = [
        [ 0, 10,  4, 24, 21,  0,  0],
        [-6, 41, 49, 46, 56, 21,  0],
        [11, 47, 24, 53, 31, 16,  5],
        [-2, 18, 40, -8, 13, 54, 64],
        [ 0,  3,  8, 11, 30, 86, 91],
        [ 0,  0,  5,  7, 22, 64, 78],
        [ 0,  0,  0,  2,  6, 44, 26],
    ];
    for (my $i=0;$i<@{$target};$i++) {
        for (my $j=0;$j<@{$target->[$i]};$j++) {
            ok(
                abs($C->element($i, $j) - $target->[$i]->[$j]) < 1e-6,
                "element ($i, $j)",
            );
        }
    }
}

require_ok('Math::Matrix::Banded');
multiply_vector;
multiply_matrix;
done_testing;

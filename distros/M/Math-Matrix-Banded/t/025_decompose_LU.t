#!perl -T
use 5.014;
use Test::More;

sub decompose_LU {
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

    is($matrix->decompose_LU, 1, 'decompose_LU without error');
    my $L = $matrix->L;
    is($L->N, $matrix->N, 'L->N matches source matrix');
    is($L->m_below, $matrix->m_below, 'L->m_below matches source matrix');
    is($L->m_above, 0, 'L->m_above vanishes');
    my $U = $matrix->U;
    is($U->N, $matrix->N, 'U->N matches source matrix');
    is($U->m_below, 0, 'U->m_below vanishes');
    is($U->m_above, $matrix->m_above, 'U->m_above matches source matrix');

    for (my $j=0;$j<$matrix->N;$j++) {
        my $col = $L->multiply_vector($U->column($j));
        for (my $i=0;$i<$matrix->N;$i++) {
            ok(
                abs($col->[$i] - $matrix->element($i, $j)) < 1e-6,
                "element ($i, $j)",
            );
        }
    }
}

sub recover_factors {
    my ($A, $B, $C);
    my ($a, $b, $c);
    my $target;

    $A = Math::Matrix::Banded->new(N => 7);
    $a = [
        [1, 0, 0, 0, 0, 0, 0],
        [2, 1, 0, 0, 0, 0, 0],
        [0, 4, 1, 0, 0, 0, 0],
        [0, 0, 5, 1, 0, 0, 0],
        [0, 0, 0, 3, 1, 0, 0],
        [0, 0, 0, 0,-1, 1, 0],
        [0, 0, 0, 0, 0, 6, 1],
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
        [2, 4, 6, 7, 0, 0, 0],
        [0, 1, 3, 5, 2, 0, 0],
        [0, 0, 4, 5, 6, 4, 0],
        [0, 0, 0, 6, 3, 5, 1],
        [0, 0, 0, 0, 4, 3, 9],
        [0, 0, 0, 0, 0, 8, 8],
        [0, 0, 0, 0, 0, 0, 4],
    ];

    for (my $i=0;$i<@$b;$i++) {
        for (my $j=0;$j<@{$b->[$i]};$j++) {
            if ($b->[$i]->[$j] != 0) {
                $B->element($i, $j, $b->[$i]->[$j]);
            }
        }
    }

    $C = $A->multiply_matrix($B);
    $C->decompose_LU;
    for (my $i=0;$i<$A->N;$i++) {
        for (my $j=0;$j<$A->N;$j++) {
            ok(
                abs($C->L->element($i, $j) - $A->element($i, $j)) < 1e-6,
                "recovered A element ($i, $j)",
            );
        }
    }
    for (my $i=0;$i<$B->N;$i++) {
        for (my $j=0;$j<$B->N;$j++) {
            ok(
                abs($C->U->element($i, $j) - $B->element($i, $j)) < 1e-6,
                "recovered B element ($i, $j)",
            );
        }
    }
}

sub book_keeping {
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

    ok(!$matrix->has_L, 'L not set');
    ok(!$matrix->has_U, 'U not set');
    ok(!$matrix->has_permutation, 'permutation not set');
    $matrix->L;
    ok($matrix->has_L, 'L set after accessing it');
    ok(!$matrix->has_U, 'U not set');
    ok(!$matrix->has_permutation, 'permutation not set');
    $matrix->U;
    ok($matrix->has_L, 'L set');
    ok($matrix->has_U, 'U set after accessing it');
    ok(!$matrix->has_permutation, 'permutation not set');
    $matrix->permutation;
    ok($matrix->has_L, 'L set');
    ok($matrix->has_U, 'U set');
    ok($matrix->has_permutation, 'permutation set after accessing it');
    $matrix->decompose_LU;
    ok(!$matrix->has_L, 'L cleared after redecomposition');
    ok(!$matrix->has_U, 'U cleared after redecomposition');
    ok(!$matrix->has_permutation, 'permutation cleared after redecomp.');
}

require_ok('Math::Matrix::Banded');
decompose_LU;
recover_factors;
book_keeping;
done_testing;

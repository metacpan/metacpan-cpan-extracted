#!perl -T
use 5.014;
use Test::More;

sub solve_LU {
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
    my $v_list = [
        [1, 0, 0, 0, 0, 0, 0],
        [7, 5, 4, 1, 0, 0, 0],
        [0, 0, 1, 8, 3, 5, 0],
        [0, 0, 0, 0, 0, 0, 0],
    ];
    foreach (@$v_list) {
        my $b = $matrix->multiply_vector($_);
        my $x = $matrix->solve_LU($b);

        for (my $i=0;$i<@$_;$i++) {
            ok(
                abs($_->[$i] - $x->[$i]) < 1e-6,
                sprintf(
                    'component %d is %.3f',
                    $i,
                    $_->[$i],
                )
            );
        }
    }
}

require_ok('Math::Matrix::Banded');
solve_LU;
done_testing;

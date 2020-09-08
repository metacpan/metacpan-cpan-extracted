#!perl -T
use 5.014;
use Test::More;

sub preset_m {
    my $matrix = Math::Matrix::Banded->new(
        N       => 7,
        m_below => 2,
        m_above => 1,
    );

    $matrix->element(0, 0, 3);
    is($matrix->element(0, 0), 3, 'element (0, 0)');
    $matrix->element(1, 0, 4);
    is($matrix->element(1, 0), 4, 'element (1, 0)');
    $matrix->element(2, 1, 2);
    is($matrix->element(2, 1), 2, 'element (2, 1)');
    is($matrix->element(6, 0), 0, 'element (6, 0), out of band');
    is($matrix->element(0, 6), 0, 'element (0, 6), out of band');
}

sub adapted_m {
    my $matrix = Math::Matrix::Banded->new(
        N => 7,
    );

    $matrix->element(0, 0, 3);
    is($matrix->element(0, 0), 3, 'element (0, 0)');
    $matrix->element(1, 0, 4);
    is($matrix->element(1, 0), 4, 'element (1, 0)');
    $matrix->element(2, 1, 2);
    is($matrix->element(2, 1), 2, 'element (2, 1)');
    $matrix->element(2, 3, 5);
    is($matrix->element(2, 3), 5, 'element (2, 3)');
    is($matrix->element(6, 0), 0, 'element (6, 0), out of band');
    is($matrix->element(0, 6), 0, 'element (0, 6), out of band');
}

sub retrieve_row {
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
    for (my $i=0;$i<@$a;$i++) {
        is_deeply(
            $matrix->row($i),
            $a->[$i],
            'retrieve row',
        );
    }
}

sub retrieve_column {
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
    for (my $j=0;$j<@$a;$j++) {
        is_deeply(
            $matrix->column($j),
            [map { $_->[$j] } @$a],
            'retrieve column',
        );
    }
}

sub symmetric {
    my $matrix = Math::Matrix::Banded->new(
        N         => 7,
        symmetric => 1,
    );
    my $a      = [
        [2, 0, 0, 0, 0, 0 ,0],
        [4, 9, 0, 0, 0, 0, 0],
        [7, 5, 4, 0, 0, 0, 0],
        [0, 1, 6, 8, 0, 0, 0],
        [0, 0, 1, 3, 8, 0, 0],
        [0, 0, 0, 5, 6, 4, 0],
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
    is($matrix->m_above, 2, 'm_above = 2');
    is($matrix->element(2, 1), 5, 'element (2, 1) = 5');
    is($matrix->element(2, 3), 6, 'element (2, 3) = 6');
    for (my $i=0;$i<$matrix->N;$i++) {
        for (my $j=0;$j<$i;$j++) {
            is(
                $matrix->element($i, $j), $matrix->element($j, $i),
                "symmetric ($i, $j)",
            );
        }
    }
}

require_ok('Math::Matrix::Banded');
preset_m;
adapted_m;
retrieve_row;
retrieve_column;
symmetric;
done_testing;

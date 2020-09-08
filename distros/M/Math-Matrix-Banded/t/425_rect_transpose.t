#!perl -T
use 5.014;
use Test::More;

sub _fill_matrix {
    my ($matrix, $rows) = @_;

    for (my $i=0;$i<@$rows;$i++) {
        for (my $j=0;$j<@{$rows->[$i]};$j++) {
            if ($rows->[$i]->[$j] != 0) {
                $matrix->element($i, $j, $rows->[$i]->[$j]);
            }
        }
    }
}

sub _non_decreasing_offset {
    my ($matrix) = @_;

    my $min_offset = 0;
    for (my $i=0;$i<$matrix->M;$i++) {
        # this is not part of the interface, but I want to check
        # internal consistency
        my $cur_offset = $matrix->_data->[$i]->[0];
        ok(
            !defined($cur_offset) || $cur_offset >= $min_offset,
            "$i: offset $cur_offset >= $min_offset",
        );
        $min_offset = $cur_offset if (($cur_offset // 0) > $min_offset);
    }
}

sub _non_decreasing_band_end {
    my ($matrix) = @_;

    my $min_end = 0;
    for (my $i=0;$i<$matrix->M;$i++) {
        # this is not part of the interface, but I want to check
        # internal consistency
        my $this_row = $matrix->_data->[$i];
        my $cur_end  = defined($this_row->[0])
            ? $this_row->[0] + @{$this_row->[1]}
            : undef;
        ok(
            !defined($cur_end) || $cur_end >= $min_end,
            "$i: end $cur_end >= $min_end",
        );
        $min_end = $cur_end if (($cur_end // 0) > $min_end);
    }
}

sub _internal_storage {
    my ($matrix, $template) = @_;

    for (my $i=0;$i<@$template;$i++) {
        my $tpl_row = $template->[$i];
        next if (!defined($tpl_row));

        is_deeply(
            $matrix->_data->[$i],
            $tpl_row,
            "row $i internal representation correct",
        );
    }
}

sub transpose {
    my $matrix;
    my $transpose;

    $matrix = Math::Matrix::Banded->new(
        M => 1,
        N => 4,
    );
    $transpose = $matrix->transpose;
    is($transpose->M, 4, 'M = 4');
    is($transpose->N, 1, 'N = 1');

    $matrix = Math::Matrix::Banded->new(
        M => 1,
        N => 4,
    );
    _fill_matrix(
        $matrix,
        [
            [1, 2, 3, 4],
        ],
    );
    _internal_storage(
        $matrix,
        [
            [0, [1, 2, 3, 4]],
        ],
    );
    $transpose = $matrix->transpose;
    is($transpose->M, 4, 'M = 4');
    is($transpose->N, 1, 'N = 1');
    _internal_storage(
        $matrix->transpose,
        [
            [0, [1]],
            [0, [2]],
            [0, [3]],
            [0, [4]],
        ],
    );

    $matrix = Math::Matrix::Banded->new(
        M => 4,
        N => 4,
    );
    _fill_matrix(
        $matrix,
        [
            [1, 0, 0, 0],
            [0, 2, 0, 0],
            [0, 0, 3, 0],
            [0, 0, 0, 4],
        ],
    );
    _internal_storage(
        $matrix,
        [
            [0, [1]],
            [1, [2]],
            [2, [3]],
            [3, [4]],
        ],
    );
    $transpose = $matrix->transpose;
    is($transpose->M, 4, 'M = 4');
    is($transpose->N, 4, 'N = 4');
    _internal_storage(
        $matrix->transpose,
        [
            [0, [1]],
            [1, [2]],
            [2, [3]],
            [3, [4]],
        ],
    );

    $matrix = Math::Matrix::Banded->new(
        M => 4,
        N => 4,
    );
    _fill_matrix(
        $matrix,
        [
            [1, 2, 0, 0],
            [3, 4, 5, 0],
            [0, 6, 7, 8],
            [0, 0, 9, 0],
        ],
    );
    _internal_storage(
        $matrix,
        [
            [0, [1, 2]],
            [0, [3, 4, 5]],
            [1, [6, 7, 8]],
            [2, [9, 0]],
        ],
    );
    $transpose = $matrix->transpose;
    is($transpose->M, 4, 'M = 4');
    is($transpose->N, 4, 'N = 4');
    _internal_storage(
        $matrix->transpose,
        [
            [0, [1, 3]],
            [0, [2, 4, 6]],
            [1, [5, 7, 9]],
            [2, [8, 0]],
        ],
    );

    $matrix = Math::Matrix::Banded->new(
        M => 4,
        N => 6,
    );
    _fill_matrix(
        $matrix,
        [
            [1, 2, 0, 0, 0, 0],
            [3, 4, 5, 0, 0, 0],
            [0, 0, 6, 7, 8, 0],
            [0, 0, 0, 0, 0, 9],
        ],
    );
    _internal_storage(
        $matrix,
        [
            [0, [1, 2]],
            [0, [3, 4, 5]],
            [2, [6, 7, 8]],
            [5, [9]],
        ],
    );
    $transpose = $matrix->transpose;
    is($transpose->M, 6, 'M = 6');
    is($transpose->N, 4, 'N = 4');
    _internal_storage(
        $matrix->transpose,
        [
            [0, [1, 3]],
            [0, [2, 4]],
            [1, [5, 6]],
            [2, [7]],
            [2, [8]],
            [3, [9]],
        ],
    );
}

sub AAt {
    my $matrix;
    my $target;
    my $C;

    $matrix = Math::Matrix::Banded->new(
        M => 1,
        N => 4,
    );
    $C = $matrix->AAt;
    is($C->N, 1, 'N = 1');
    is($C->symmetric, 1, 'symmetric');
    $target = [[0]];
    for (my $i=0;$i<@{$target};$i++) {
        for (my $j=0;$j<@{$target->[$i]};$j++) {
            ok(
                abs($C->element($i, $j) - $target->[$i]->[$j]) < 1e-6,
                sprintf(
                    "element ($i, $j) = %.3f",
                    $target->[$i]->[$j],
                ),
            );
        }
    }

    $matrix = Math::Matrix::Banded->new(
        M => 1,
        N => 4,
    );
    _fill_matrix(
        $matrix,
        [
            [1, 2, 3, 4],
        ],
    );
    $C = $matrix->AAt;
    is($C->N, 1, 'N = 1');
    is($C->symmetric, 1, 'symmetric');
    $target = [[30]];
    for (my $i=0;$i<@{$target};$i++) {
        for (my $j=0;$j<@{$target->[$i]};$j++) {
            ok(
                abs($C->element($i, $j) - $target->[$i]->[$j]) < 1e-6,
                sprintf(
                    "element ($i, $j) = %.3f",
                    $target->[$i]->[$j],
                ),
            );
        }
    }

    $C = $matrix->AtA;
    is($C->N, 4, 'N = 4');
    is($C->symmetric, 1, 'symmetric');
    $target = [
        [1, 2,  3,  4],
        [2, 4,  6,  8],
        [3, 6,  9, 12],
        [4, 8, 12, 16],
    ];
    for (my $i=0;$i<@{$target};$i++) {
        for (my $j=0;$j<@{$target->[$i]};$j++) {
            ok(
                abs($C->element($i, $j) - $target->[$i]->[$j]) < 1e-6,
                sprintf(
                    "element ($i, $j) = %.3f",
                    $target->[$i]->[$j],
                ),
            );
        }
    }

    $matrix = Math::Matrix::Banded->new(
        M => 2,
        N => 4,
    );
    _fill_matrix(
        $matrix,
        [
            [1,  2,  3, 0],
            [0, -1, -2, 3],
        ],
    );
    $C = $matrix->AAt;
    is($C->N, 2, 'N = 2');
    is($C->symmetric, 1, 'symmetric');
    $target = [
        [14, -8],
        [-8, 14],
    ];
    for (my $i=0;$i<@{$target};$i++) {
        for (my $j=0;$j<@{$target->[$i]};$j++) {
            ok(
                abs($C->element($i, $j) - $target->[$i]->[$j]) < 1e-6,
                sprintf(
                    "element ($i, $j) = %.3f",
                    $target->[$i]->[$j],
                ),
            );
        }
    }

    $C = $matrix->AtA;
    is($C->N, 4, 'N = 4');
    is($C->symmetric, 1, 'symmetric');
    $target = [
        [1,  2,  3,  0],
        [2,  5,  8, -3],
        [3,  8, 13, -6],
        [0, -3, -6,  9],
    ];
    for (my $i=0;$i<@{$target};$i++) {
        for (my $j=0;$j<@{$target->[$i]};$j++) {
            ok(
                abs($C->element($i, $j) - $target->[$i]->[$j]) < 1e-6,
                sprintf(
                    "element ($i, $j) = %.3f",
                    $target->[$i]->[$j],
                ),
            );
        }
    }

    $matrix = Math::Matrix::Banded->new(
        M => 2,
        N => 4,
    );
    _fill_matrix(
        $matrix,
        [
            [1, 2,  0, 0],
            [0, 0, -2, 3],
        ],
    );
    $C = $matrix->AAt;
    is($C->N, 2, 'N = 2');
    is($C->symmetric, 1, 'symmetric');
    is($C->m_below, 0, 'm_below = 0');
    is($C->m_above, 0, 'm_above = 0');
    $target = [
        [5,  0],
        [0, 13],
    ];
    for (my $i=0;$i<@{$target};$i++) {
        for (my $j=0;$j<@{$target->[$i]};$j++) {
            ok(
                abs($C->element($i, $j) - $target->[$i]->[$j]) < 1e-6,
                sprintf(
                    "element ($i, $j) = %.3f",
                    $target->[$i]->[$j],
                ),
            );
        }
    }

    $C = $matrix->AtA;
    is($C->N, 4, 'N = 4');
    is($C->symmetric, 1, 'symmetric');
    is($C->m_below, 1, 'm_below = 1');
    is($C->m_above, 1, 'm_above = 1');
    $target = [
        [1,  2,  0,  0],
        [2,  4,  0,  0],
        [0,  0,  4, -6],
        [0,  0, -6,  9],
    ];
    for (my $i=0;$i<@{$target};$i++) {
        for (my $j=0;$j<@{$target->[$i]};$j++) {
            ok(
                abs($C->element($i, $j) - $target->[$i]->[$j]) < 1e-6,
                sprintf(
                    "element ($i, $j) = %.3f",
                    $target->[$i]->[$j],
                ),
            );
        }
    }

    $matrix = Math::Matrix::Banded->new(
        M => 2,
        N => 4,
    );
    _fill_matrix(
        $matrix,
        [
            [1, 2, 0, 0],
            [0, 0, 0, 0],
        ],
    );
    $C = $matrix->AAt;
    is($C->N, 2, 'N = 2');
    is($C->symmetric, 1, 'symmetric');
    is($C->m_below, 0, 'm_below = 0');
    is($C->m_above, 0, 'm_above = 0');
    $target = [
        [5, 0],
        [0, 0],
    ];
    for (my $i=0;$i<@{$target};$i++) {
        for (my $j=0;$j<@{$target->[$i]};$j++) {
            ok(
                abs($C->element($i, $j) - $target->[$i]->[$j]) < 1e-6,
                sprintf(
                    "element ($i, $j) = %.3f",
                    $target->[$i]->[$j],
                ),
            );
        }
    }
}


require_ok('Math::Matrix::Banded');
transpose;
AAt;
done_testing;

#!perl -T
use 5.014;
use Test::More;

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

sub adapted_offset {
    my $matrix = Math::Matrix::Banded->new(
        M => 9,
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
    is($matrix->element(6, 0), 0, 'element (6, 0) out of band');
    is($matrix->element(0, 6), 0, 'element (0, 6) out of band');
}

sub maintain_band_structure {
    my $matrix;

    $matrix = Math::Matrix::Banded->new(
        M => 9,
        N => 7,
    );

    _non_decreasing_offset($matrix);
    _non_decreasing_band_end($matrix);
    $matrix->element(0, 0, 3);
    is($matrix->element(0, 0), 3, 'element (0, 0)');
    $matrix->element(1, 0, 4);
    is($matrix->element(1, 0), 4, 'element (1, 0)');
    $matrix->element(2, 1, 2);
    is($matrix->element(2, 1), 2, 'element (2, 1)');
    $matrix->element(2, 3, 5);
    is($matrix->element(2, 3), 5, 'element (2, 3)');
    is($matrix->element(6, 0), 0, 'element (6, 0) out of band');
    is($matrix->element(0, 6), 0, 'element (0, 6) out of band');
    ok(!defined($matrix->_data->[3]->[0]), 'row 3 still untouched');

    _non_decreasing_offset($matrix);
    _non_decreasing_band_end($matrix);
    $matrix->element(6, 4, 7);
    _non_decreasing_offset($matrix);
    _non_decreasing_band_end($matrix);
    $matrix->element(8, 0, 5);
    _non_decreasing_offset($matrix);
    _non_decreasing_band_end($matrix);
    $matrix->element(5, 2, 9);
    _non_decreasing_offset($matrix);
    _non_decreasing_band_end($matrix);

    $matrix = Math::Matrix::Banded->new(
        M => 9,
        N => 7,
    );
    $matrix->element(0, 3, 5);
    _internal_storage(
        $matrix,
        [
            [3, [5]],
            [undef, []],
        ],
    );
    _non_decreasing_offset($matrix);
    _non_decreasing_band_end($matrix);

    $matrix->element(2, 2, 6);
    _internal_storage(
        $matrix,
        [
            [2, [0, 5]],
            [2, [0, 0]],
            [2, [6, 0]],
            [undef, []],
        ],
    );
    _non_decreasing_offset($matrix);
    _non_decreasing_band_end($matrix);

    $matrix->element(4, 2, 7);
    _internal_storage(
        $matrix,
        [
            [2, [0, 5]],
            [2, [0, 0]],
            [2, [6, 0]],
            [2, [0, 0]],
            [2, [7, 0]],
            [undef, []],
        ],
    );
    _non_decreasing_offset($matrix);
    _non_decreasing_band_end($matrix);

    $matrix->element(3, 4, 8);
    _internal_storage(
        $matrix,
        [
            [2, [0, 5]],
            [2, [0, 0]],
            [2, [6, 0]],
            [2, [0, 0, 8]],
            [2, [7, 0, 0]],
            [undef, []],
        ],
    );
    _non_decreasing_offset($matrix);
    _non_decreasing_band_end($matrix);

    $matrix->element(3, 1, 9);
    _internal_storage(
        $matrix,
        [
            [1, [0, 0, 5]],
            [1, [0, 0, 0]],
            [1, [0, 6, 0]],
            [1, [9, 0, 0, 8]],
            [2, [7, 0, 0]],
            [undef, []],
        ],
    );
    _non_decreasing_offset($matrix);
    _non_decreasing_band_end($matrix);

    $matrix->element(6, 6, 0);
    _internal_storage(
        $matrix,
        [
            [1, [0, 0, 5]],
            [1, [0, 0, 0]],
            [1, [0, 6, 0]],
            [1, [9, 0, 0, 8]],
            [2, [7, 0, 0]],
            [6, []],
            [6, [0]],
            [undef, []],
        ],
    );
    _non_decreasing_offset($matrix);
    _non_decreasing_band_end($matrix);

    $matrix->element(6, 5, 1);
    _internal_storage(
        $matrix,
        [
            [1, [0, 0, 5]],
            [1, [0, 0, 0]],
            [1, [0, 6, 0]],
            [1, [9, 0, 0, 8]],
            [2, [7, 0, 0]],
            [5, []],
            [5, [1, 0]],
            [undef, []],
        ],
    );
    _non_decreasing_offset($matrix);
    _non_decreasing_band_end($matrix);

    $matrix->element(4, 5, 2);
    _internal_storage(
        $matrix,
        [
            [1, [0, 0, 5]],
            [1, [0, 0, 0]],
            [1, [0, 6, 0]],
            [1, [9, 0, 0, 8]],
            [2, [7, 0, 0, 2]],
            [5, [0]],
            [5, [1, 0]],
            [undef, []],
        ],
    );
    _non_decreasing_offset($matrix);
    _non_decreasing_band_end($matrix);
}

sub retrieve_row {
    my $matrix = Math::Matrix::Banded->new(
        M => 9,
        N => 7,
    );
    my $a      = [
        [2, 3, 0, 0, 0, 0 ,0],
        [4, 9, 7, 0, 0, 0, 0],
        [7, 5, 4, 1, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0],
        [0, 1, 6, 8, 4, 0, 0],
        [0, 0, 1, 3, 8, 7, 0],
        [0, 0, 0, 5, 6, 4, 1],
        [0, 0, 0, 0, 1, 3, 8],
        [0, 0, 0, 0, 0, 0, 0],
    ];

    for (my $i=0;$i<@$a;$i++) {
        for (my $j=0;$j<@{$a->[$i]};$j++) {
            if ($a->[$i]->[$j] != 0) {
                $matrix->element($i, $j, $a->[$i]->[$j]);
            }
        }
    }

    is($matrix->element(5, 5), 7, 'element (5, 5) = 7');
    for (my $i=0;$i<@$a;$i++) {
        is_deeply(
            $matrix->row($i),
            $a->[$i],
            'retrieve row',
        );
    }
}

sub retrieve_column {
    my $matrix = Math::Matrix::Banded->new(
        M => 9,
        N => 7,
    );
    my $a      = [
        [2, 3, 0, 0, 0, 0 ,0],
        [4, 9, 7, 0, 0, 0, 0],
        [7, 5, 4, 1, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0],
        [0, 1, 6, 8, 4, 0, 0],
        [0, 0, 1, 3, 8, 7, 0],
        [0, 0, 0, 5, 6, 4, 1],
        [0, 0, 0, 0, 1, 3, 8],
        [0, 0, 0, 0, 0, 0, 0],
    ];

    for (my $i=0;$i<@$a;$i++) {
        for (my $j=0;$j<@{$a->[$i]};$j++) {
            if ($a->[$i]->[$j] != 0) {
                $matrix->element($i, $j, $a->[$i]->[$j]);
            }
        }
    }

    is($matrix->element(5, 5), 7, 'element (5, 5) = 7');
    for (my $j=0;$j<@{$a->[0]};$j++) {
        is_deeply(
            $matrix->column($j),
            [map { $_->[$j] } @$a],
            'retrieve column',
        );
    }
}

require_ok('Math::Matrix::Banded');
adapted_offset;
maintain_band_structure;
retrieve_row;
retrieve_column;
done_testing;

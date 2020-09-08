#!/usr/bin/perl
use 5.014;

use Math::Matrix::Banded::Rectangular;
use List::Util (
    'min',
    'max',
);

sub construct_banded {
    my ($M, $N, $m_below, $m_above) = @_;

    my $matrix = Math::Matrix::Banded::Rectangular->new(
        M => $M,
        N => $N,
    );

    for (my $i=0;$i<$N;$i++) {
        my $j_min = max(0, $i - $m_below);
        my $j_max = min($N - 1, $i + $m_above);
        for (my $j=$j_min;$j<=$j_max;$j++) {
            $matrix->element($i, $j, rand(2) - 1);
        }
    }

    return $matrix;
}

say time();
my $M = construct_banded(100000, 100000, 2, 2);
say time();
$M->transpose;
say time();

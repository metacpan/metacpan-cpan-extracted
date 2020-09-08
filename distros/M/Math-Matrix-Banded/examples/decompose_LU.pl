#!/usr/bin/perl
use 5.014;

use Math::Matrix::Banded;

sub construct_decomposable {
    my ($N, $m_below, $m_above) = @_;

    my $L = Math::Matrix::Banded->new(
        N       => $N,
        m_below => $m_below,
        m_above => 0,
    );
    $L->fill_random;
    for (my $i=0;$i<$N;$i++) {
        $L->element($i, $i, 1);
    }

    my $U = Math::Matrix::Banded->new(
        N       => $N,
        m_below => 0,
        m_above => $m_above,
    );
    $U->fill_random;
    #say $L->as_string, "\n\n";
    #say $U->as_string, "\n\n";

    return $L->multiply_matrix($U);
}

say time();
my $M = construct_decomposable(100000, 2, 2);
$M->decompose_LU;
say time();
#say $M->L->as_string, "\n\n";
#say $M->U->as_string;

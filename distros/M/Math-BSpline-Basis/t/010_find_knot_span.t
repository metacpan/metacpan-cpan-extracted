use 5.014;
use warnings;
use Test::More 0.98;

sub bezier {
    my $bspline;
    my $target;

    $bspline = Math::BSpline::Basis->new(
        degree         => 2,
        knot_vector    => [0, 0, 0, 1, 1, 1],
    );

    $target = [
        [-0.1, 2],
        [   0, 2],
        [ 0.1, 2],
        [ 0.5, 2],
        [ 0.9, 2],
        [   1, 2],
        [ 1.1, 2],
    ];

    foreach (@$target) {
        is(
            $bspline->find_knot_span($_->[0]),
            $_->[1],
            sprintf(
                'u = %.3f has knot span %d',
                @$_,
            ),
        );
    }
}

sub uniform {
    my $bspline;
    my $target;

    $bspline = Math::BSpline::Basis->new(
        degree      => 4,
        knot_vector => [0, 0, 0, 0, 0, 0.25, 0.5, 0.75, 1, 1, 1, 1, 1],
    );

    $target = [
        [-0.1, 4],
        [   0, 4],
        [ 0.1, 4],
        [0.24, 4],
        [0.25, 5],
        [0.26, 5],
        [0.49, 5],
        [0.50, 6],
        [0.51, 6],
        [0.74, 6],
        [0.75, 7],
        [0.76, 7],
        [ 0.9, 7],
        [   1, 7],
        [ 1.1, 7],
    ];

    foreach (@$target) {
        is(
            $bspline->find_knot_span($_->[0]),
            $_->[1],
            sprintf(
                'u = %.3f has knot span %d',
                @$_,
            ),
        );
    }
}

sub degenerate {
    my $bspline;
    my $target;

    $bspline = Math::BSpline::Basis->new(
        degree      => 4,
        knot_vector => [
            0, 0, 0, 0, 0,
            0.25, 0.25,
            0.5,
            0.75,
            1, 1, 1, 1, 1,
        ],
    );

    $target = [
        [-0.1, 4],
        [   0, 4],
        [ 0.1, 4],
        [0.24, 4],
        [0.25, 6],
        [0.26, 6],
        [0.49, 6],
        [0.50, 7],
        [0.51, 7],
        [0.74, 7],
        [0.75, 8],
        [0.76, 8],
        [ 0.9, 8],
        [   1, 8],
        [ 1.1, 8],
    ];

    foreach (@$target) {
        is(
            $bspline->find_knot_span($_->[0]),
            $_->[1],
            sprintf(
                'u = %.3f has knot span %d',
                @$_,
            ),
        );
    }

    $bspline = Math::BSpline::Basis->new(
        degree      => 4,
        knot_vector => [
            0, 0, 0, 0, 0,
            0.25, 0.25, 0.25, 0.25,
            0.5,
            0.75,
            1, 1, 1, 1, 1,
        ],
    );

    $target = [
        [-0.1,  4],
        [   0,  4],
        [ 0.1,  4],
        [0.24,  4],
        [0.25,  8],
        [0.26,  8],
        [0.49,  8],
        [0.50,  9],
        [0.51,  9],
        [0.74,  9],
        [0.75, 10],
        [0.76, 10],
        [ 0.9, 10],
        [   1, 10],
        [ 1.1, 10],
    ];

    foreach (@$target) {
        is(
            $bspline->find_knot_span($_->[0]),
            $_->[1],
            sprintf(
                'u = %.3f has knot span %d',
                @$_,
            ),
        );
    }
}

sub non_normalized {
    my $bspline;
    my $target;

    $bspline = Math::BSpline::Basis->new(
        degree      => 4,
        knot_vector => [
            -12.3, -12.3, -12.3, -12.3, -12.3,
            -4, 0, 13.9,
            22.7, 22.7, 22.7, 22.7, 22.7,
        ],
    );

    $target = [
        [-12.4, 4],
        [-12.3, 4],
        [ -8.0, 4],
        [ -4.1, 4],
        [ -4.0, 5],
        [ -3.9, 5],
        [ -0.1, 5],
        [  0.0, 6],
        [  0.1, 6],
        [  6.5, 6],
        [ 13.8, 6],
        [ 13.9, 7],
        [ 14.0, 7],
        [ 22.6, 7],
        [ 22.7, 7],
        [ 22.8, 7],
    ];

    foreach (@$target) {
        is(
            $bspline->find_knot_span($_->[0]),
            $_->[1],
            sprintf(
                'u = %.3f has knot span %d',
                @$_,
            ),
        );
    }
}

use_ok('Math::BSpline::Basis');
bezier;
uniform;
degenerate;
non_normalized;
done_testing;

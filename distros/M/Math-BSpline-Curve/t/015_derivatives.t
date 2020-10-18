use 5.014;
use warnings;
use Test::More 0.98;

sub is_close {
    my ($x, $y, $desc) = @_;

    ok(abs($x - $y) < 1e-9, $desc);
}

sub explicit01 {
    my $curve;
    my $template;

    $curve = Math::BSpline::Curve->new(
        degree         => 2,
        knot_vector    => [
            0, 0, 0, 1, 2, 3, 4, 4, 5, 5, 5,
        ],
        control_points => [
            [-6, -1],
            [-4, 14],
            [12, 11],
            [3, 1],
            [2, -5],
            [5, -7],
            [8, -3],
        ],
    );

    $template = [
        [
            2.5,
            [
                [
                    1/8 * 12 + 3/4 * 3 + 1/8 * 2,
                    1/8 * 11 + 3/4 * 1 + 1/8 * (-5),
                ],
                [
                    (-1/2) * 12 + 0 * 3 + 1/2 * 2,
                    (-1/2) * 11 + 0 * 1 + 1/2 * (-5),
                ],
            ],
        ],
    ];

    foreach (@$template) {
        my ($u, $v) = @$_;
        my $d = $curve->evaluate_derivatives($u, scalar(@$v) - 1);
        is(
            scalar(@$d),
            scalar(@$v),
            sprintf(
                'got %d derivatives',
                scalar(@$v) - 1,
            )
        );
        for (my $i=0;$i<@$v;$i++) {
            my $this_v = $v->[$i];
            my $this_d = $d->[$i];
            is(
                scalar(@$this_d),
                scalar(@$this_v),
                sprintf(
                    'point has %d components',
                    scalar(@$this_v),
                )
            );

            for (my $j=0;$j<@$this_v;$j++) {
                is_close(
                    $this_d->[$j],
                    $this_v->[$j],
                    sprintf(
                        '%.9f is close %.9f',
                        $this_d->[$j],
                        $this_v->[$j],
                    ),
                );
            }
        }
    }
}

sub _check_derivative_curves {
    my ($curve, $k) = @_;
    my $d_curves    = [$curve];

    $k //= $curve->degree;
    for (my $i=1;$i<=$k;$i++) {
        my $last_d_curve = $d_curves->[-1];
        my $this_d_curve = $last_d_curve->derivative;
        ok(defined($this_d_curve), 'defined');
        isa_ok($this_d_curve, 'Math::BSpline::Curve');

        my $tpl_p = $last_d_curve->degree - 1;
        is($this_d_curve->degree, $tpl_p, "degree is $tpl_p");

        my $last_U = $last_d_curve->knot_vector;
        my $tpl_U  = [@$last_U[1..($#$last_U-1)]];
        is_deeply(
            $this_d_curve->knot_vector,
            $tpl_U,
            'knot vector as constructed from above',
        );

        push(@$d_curves, $this_d_curve);
    }

    return $d_curves;
}

sub _scan_point_vs_curve {
    my ($d_curves, $u_list) = @_;
    my $k                   = $#$d_curves;

    foreach my $u (@$u_list) {
        my $d = $d_curves->[0]->evaluate_derivatives($u, $k);
        is(
            scalar(@$d),
            $k + 1,
            sprintf(
                'got %d derivatives',
                $k,
            )
        );
        my $v = [map { $_->evaluate($u) } @$d_curves];

        for (my $i=0;$i<@$v;$i++) {
            my $this_v = $v->[$i];
            my $this_d = $d->[$i];
            is(
                scalar(@$this_v),
                2,
                sprintf(
                    'spline point has %d components',
                    2,
                ),
            );
            is(
                scalar(@$this_d),
                2,
                sprintf(
                    'direct point has %d components',
                    2,
                ),
            );

            for (my $j=0;$j<@$this_v;$j++) {
                is_close(
                    $this_d->[$j],
                    $this_v->[$j],
                    sprintf(
                        '%.9f is close %.9f',
                        $this_d->[$j],
                        $this_v->[$j],
                    ),
                );
            }
        }
    }
}

sub point_vs_spline01 {
    my $curve;
    my $d_curves;

    $curve = Math::BSpline::Curve->new(
        degree         => 3,
        knot_vector    => [
            0, 0, 0, 0, 1, 1, 1, 1,
        ],
        control_points => [
            [-6, -1],
            [-4, 14],
            [12, 11],
            [3, 1],
        ],
    );
    $d_curves = _check_derivative_curves($curve);
    _scan_point_vs_curve($d_curves, [0, 0.2, 0.4, 0.6, 0.8, 1]);

    $curve = Math::BSpline::Curve->new(
        degree         => 5,
        knot_vector    => [
            0, 0, 0, 0, 0, 0,
            0.1, 0.2, 0.5, 0.5, 0.8,
            1, 1, 1, 1, 1, 1,
        ],
        control_points => [
            [-6,  -1],
            [-5,  14],
            [-4,  16],
            [-3,  11],
            [-2,   8],
            [-1,   0],
            [-2,  -5],
            [-3,  -7],
            [-4,  -5],
            [-5,   0],
            [-6,   6],
        ],
    );
    # We have a double knot, hence the spline is 5 - 2 = 3 times
    # continuously differentiable at that knot. Since internally
    # discontinuous splines are not supported by
    # Math::BSpline::Basis, calculating higher derivatives would
    # produce wrong results.
    $d_curves = _check_derivative_curves($curve, 3);
    _scan_point_vs_curve($d_curves, [0, 0.2, 0.4, 0.6, 0.8, 1]);
}

use_ok('Math::BSpline::Curve');
explicit01;
point_vs_spline01;
done_testing;

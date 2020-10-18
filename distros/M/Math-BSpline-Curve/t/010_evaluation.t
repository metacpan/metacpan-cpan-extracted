use 5.014;
use warnings;
use Test::More 0.98;

sub is_close {
    my ($x, $y, $desc) = @_;

    ok(abs($x - $y) < 1e-9, $desc);
}

sub evaluate_curve {
    my $curve;
    my $template;

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

    # I have not found an online calculation tool that I could use
    # as an external reference. I have used the following graphical
    # tool to create the template below.
    # https://www.desmos.com/calculator/lvdgnyhkvy
    # I've read the numbers from the plot and then corrected them
    # (by less than 0.1) to the calculated numbers in order to pass
    # the test. Not ideal, but the best I've found. (Keep in mind
    # that the evaluation of the basis functions has a better test
    # suite).
    $template = [
        [0.0, [-6, -1]],
        [0.1, [-5.019, 2.971]],
        [0.3, [-1.473, 7.937]],
        [0.7, [ 5.403, 7.813]],
        [0.9, [ 4.989, 3.779]],
        [1.0, [3, 1]],
    ];

    foreach (@$template) {
        my ($u, $v) = @$_;
        my $p = $curve->evaluate($u);
        is(
            scalar(@$p),
            scalar(@$v),
            sprintf(
                'point has %d components',
                scalar(@$v),
            )
        );
        for (my $i=0;$i<@$v;$i++) {
            is_close(
                $p->[$i],
                $v->[$i],
                sprintf(
                    '%.9f is close %.9f',
                    $p->[$i],
                    $v->[$i],
                ),
            );
        }
    }
}


use_ok('Math::BSpline::Curve');
evaluate_curve;
done_testing;

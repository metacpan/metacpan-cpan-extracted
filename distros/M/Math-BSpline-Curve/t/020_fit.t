use 5.014;
use warnings;
use Test::More 0.98;

use constant PI => 3.14159265358979;

sub is_close {
    my ($x, $y, $desc) = @_;

    ok(abs($x - $y) < 1e-9, $desc);
}

sub is_near {
    my ($x, $y, $threshold, $desc) = @_;

    ok(abs($x - $y) < $threshold, $desc);
}

# This is really just a prove of concept to show that the result is
# not ridiculously off. It does not prove that nothing is wrong.
sub poc01 {
    my $curve;
    my $template;

    $curve = Math::BSpline::Curve->fit(
        degree           => 3,
        n_control_points => 50,
        points           => [
            map { [$_, cos($_) * exp(-0.1) * $_] }
            map { (15.0 / 199) * $_ }
            (0..199)
        ],
    );

    # print for gsl
    # for (my $i=$curve->degree;$i<@{$curve->knot_vector}-$curve->degree;$i++) {
    #     printf(
    #         qq{  gsl_vector_set(break_points, %d, %.13f);\n},
    #         $i - $curve->degree,
    #         $curve->knot_vector->[$i],
    #     );
    # }

    for (my $x=0;$x<=1;$x+=0.05) {
        my $point = $curve->evaluate($x);
        is_near(
            cos($point->[0]) * exp(-0.1) * $point->[0],
            $point->[1],
            0.12,
            sprintf(
                'phi = %.4f, x = %.4f',
                $x,
                $point->[0],
            )
        )
    }
}


# This is really just a prove of concept to show that the result is
# not ridiculously off. It does not prove that nothing is wrong.
sub poc02 {
    my $curve;
    my $template;

    $curve = Math::BSpline::Curve->fit(
        degree           => 3,
        n_control_points => 50,
        points           => [
            map { [cos($_), sin($_)] }
            map { (2 * PI) * $_/ 200 }
            (0..199),
        ],
    );

    # print for gsl
    # for (my $i=$curve->degree;$i<@{$curve->knot_vector}-$curve->degree;$i++) {
    #     printf(
    #         qq{  gsl_vector_set(break_points, %d, %.13f);\n},
    #         $i - $curve->degree,
    #         $curve->knot_vector->[$i],
    #     );
    # }

    for (my $x=0;$x<=1;$x+=0.05) {
        my $point = $curve->evaluate($x);
        is_near(
            sqrt($point->[0]**2 + $point->[1]**2),
            1,
            1e-5,
            sprintf(
                '%.2f: %.4f ~ %.4f',
                $x,
                $point->[0]**2 + $point->[1]**2,
                1,
            )
        );

        my $psi = atan2($point->[1], $point->[0]) / (2*PI);
        $psi += 1 if (0.5 - $x < 1e-6 and $psi < 0);
        is_near(
            $psi,
            $x,
            1e-2,
            sprintf(
                '%.2f: %.4f ~ %.4f',
                $x,
                $psi,
                $x,
            )
        );
    }
}


# This is really just a prove of concept to show that the result is
# not ridiculously off. It does not prove that nothing is wrong.
sub poc03 {
    my $curve;
    my $template;

    $curve = Math::BSpline::Curve->fit(
        degree           => 3,
        n_control_points => 20,
        points           => [
            map { [cos($_), sin($_)] }
            map { (2 * PI) * $_/ 200 }
            (0..199),
        ],
        phi              => [
            map { $_/ 200 }
            (0..199),
        ],
    );

    # print for gsl
    # for (my $i=$curve->degree;$i<@{$curve->knot_vector}-$curve->degree;$i++) {
    #     printf(
    #         qq{  gsl_vector_set(break_points, %d, %.13f);\n},
    #         $i - $curve->degree,
    #         $curve->knot_vector->[$i],
    #     );
    # }

    foreach my $x (map { $_/ 200 } (0..199)) {
        my $point = $curve->evaluate($x);
        is_near(
            sqrt($point->[0]**2 + $point->[1]**2),
            1,
            1e-4,
            sprintf(
                '%.2f: %.4f ~ %.4f',
                $x,
                $point->[0]**2 + $point->[1]**2,
                1,
            )
        );

        my $psi = atan2($point->[1], $point->[0]) / (2*PI);
        $psi += 1 if (0.5 - $x < 1e-6 and $psi < 0);
        is_near(
            $psi,
            $x,
            1e-4,
            sprintf(
                '%.2f: %.4f ~ %.4f',
                $x,
                $psi,
                $x,
            )
        );
    }
}


use_ok('Math::BSpline::Curve');
poc01;
poc02;
poc03;
done_testing;

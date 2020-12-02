package Math::BSpline::Curve::Role::Approximation;
$Math::BSpline::Curve::Role::Approximation::VERSION = '0.002';
# ABSTRACT: fitting a B-spline curve to a point set

use 5.014;
use warnings;

use Moo::Role;
use List::Util 1.26 ('sum0');
use Scalar::Util 1.26 ('blessed');
use Ref::Util 0.010 ('is_plain_arrayref');
use Module::Runtime 0.012 ('require_module');
use Math::BSpline::Basis 0.001;
use Math::Matrix::Banded 0.004;

requires (
    'new',
);


sub fit {
    my ($class, @args) = @_;

    # We support both a hash and a hashref as args.
    my $args = @args == 1 ? $args[0] : {@args};
    $args ||= {};

    foreach ('degree', 'n_control_points', 'points') {
        if (!exists($args->{$_})) {
            $Math::BSpline::Curve::logger->error(
                "Missing required arguments: $_",
            );
            return undef;
        }
    }

    my $apr = $class->_fit_approximate_unbounded($args);
    if ($apr) {
        return $class->new(
            degree         => $args->{degree},
            knot_vector    => $apr->{knot_vector},
            control_points => $apr->{control_points},
        );
    }
    else {
        return undef;
    }
}


sub calculate_parameters {
    my ($class, $points, $lengths, $total_length) = @_;

    # We support omission of $lengths/$total_length or only of
    # $total_length.
    ($lengths, $total_length) = $class->_fit_calculate_lengths($points)
        if (!$lengths);
    $total_length //= sum0(@$lengths);

    my $phi      = [0];
    my $cur_phi  = 0;
    for (my $i=1;$i<@$points-1;$i++) {
        $cur_phi += $lengths->[$i-1] / $total_length;
        push(@$phi, $cur_phi);
    }
    push(@$phi, 1);

    return $phi;
}


sub _fit_approximate_unbounded {
    my ($class, $args) = @_;

    my $phi = $args->{phi} // $class->calculate_parameters(
        $args->{points},
    );
    my $U = $args->{knot_vector} // $class->_fit_calculate_knot_vector(
        $args->{degree},
        $args->{n_control_points} - 1,
        $phi,
    );

    # We have not constructed the curve object, yet. Hence, we need
    # construct our own basis.
    my $basis = Math::BSpline::Basis->new(
        degree      => $args->{degree},
        knot_vector => $U,
    );

    my $Nt = $class->_fit_calculate_Nt(
        $basis,
        $phi,
    );
    my $NtN    = $Nt->AAt;
    my $result = $NtN->decompose_LU;
    if (!$result) {
        $Math::BSpline::Curve::logger->errorf("Fit failed");
        return undef;
    }

    my $R = $class->_fit_calculate_R(
        $Nt,
        $args->{points},
    );
    return undef if (!defined($R));

    my $Pc = [map { $NtN->solve_LU($_) } @$R];
    my $P  = $class->_fit_calculate_control_points(
        $Pc,
        $args->{vector_class},
    );
    return undef if (!defined($P));

    return {
        knot_vector    => $U,
        control_points => $P,
    };
}


sub _fit_calculate_lengths {
    my ($class, $points) = @_;

    my $lengths      = [];
    my $total_length = 0;
    my $prv_point    = $points->[0];
    if (is_plain_arrayref($prv_point)) {
        my $dim = scalar(@$prv_point);
        for (my $i=1;$i<@$points;$i++) {
            my $cur_point  = $points->[$i];
            my $cur_dist   = [
                map { $cur_point->[$_] - $prv_point->[$_] } (0..($dim-1)),
            ];
            my $cur_length = sqrt(
                sum0(
                    map { $cur_dist->[$_]**2 } (0..($dim-1)),
                ),
            );

            push(@$lengths, $cur_length);
            $total_length += $cur_length;

            $prv_point = $cur_point;
        }
    }
    elsif ($prv_point->isa('Math::GSL::Vector')) {
        for (my $i=1;$i<@$points;$i++) {
            my $cur_point  = $points->[$i];
            my $cur_dist   = $cur_point - $prv_point;
            my $cur_length = $cur_dist->norm(2);

            push(@$lengths, $cur_length);
            $total_length += $cur_length;

            $prv_point = $cur_point;
        }
    }
    elsif ($prv_point->isa('Math::MatrixReal')) {
        for (my $i=1;$i<@$points;$i++) {
            my $cur_point  = $points->[$i];
            my $cur_dist   = $cur_point - $prv_point;
            my $cur_length = $cur_dist->norm_p(2);

            push(@$lengths, $cur_length);
            $total_length += $cur_length;

            $prv_point = $cur_point;
        }
    }
    elsif ($prv_point->isa('Math::Vector::Real')) {
        for (my $i=1;$i<@$points;$i++) {
            my $cur_point  = $points->[$i];
            my $cur_dist   = $cur_point - $prv_point;
            my $cur_length = abs($cur_dist);

            push(@$lengths, $cur_length);
            $total_length += $cur_length;

            $prv_point = $cur_point;
        }
    }
    elsif ($prv_point->isa('Math::VectorReal')) {
        for (my $i=1;$i<@$points;$i++) {
            my $cur_point  = $points->[$i];
            my $cur_dist   = $cur_point - $prv_point;
            my $cur_length = $cur_dist->length;

            push(@$lengths, $cur_length);
            $total_length += $cur_length;

            $prv_point = $cur_point;
        }
    }
    else {
        # We assume that * is overloaded as dot product
        for (my $i=1;$i<@$points;$i++) {
            my $cur_point  = $points->[$i];
            my $cur_dist   = $cur_point - $prv_point;
            my $cur_length = sqrt($cur_dist * $cur_dist);

            push(@$lengths, $cur_length);
            $total_length += $cur_length;

            $prv_point = $cur_point;
        }
    }

    return($lengths, $total_length);
}


sub _fit_calculate_knot_vector {
    my ($class, $p, $n, $phi) = @_;
    my $m                     = @$phi + 1;

    my $U    = [map { 0 } (0..$p)];
    my $step = ($m + 1) / ($n - $p + 1);
    for (my $j=1;$j<=$n-$p;$j++) {
        my $i = int($j * $step);
        my $t = $j * $step - $i;
        push(
            @$U,
            (1 - $t) * $phi->[$i - 1] + $t * $phi->[$i],
        )
    }
    push(@$U, map { 1 } (0..$p));

    return $U;
}


sub _fit_calculate_Nt {
    my ($class, $basis, $phi) = @_;
    my $p                     = $basis->degree;
    my $U                     = $basis->knot_vector;
    my $n                     = (@$U - 1) - $p - 1;

    my $Nt = Math::Matrix::Banded->new(
        M => $n + 1,
        N => @$phi,
    );
    for (my $j=0;$j<@$phi;$j++) {
        my $u   = $phi->[$j];
        my $s   = $basis->find_knot_span($u);
        my $Nip = $basis->evaluate_basis_functions($s, $u);
        for (my $i=0;$i<@$Nip;$i++) {
            $Nt->element($s - $p + $i, $j, $Nip->[$i]);
        }
    }

    return $Nt;
}


sub _fit_calculate_R_plain_arrayref {
    my ($class, $Nt, $points) = @_;

    # Because a plain arrayref does not overload scalar
    # multiplication we need to first split the array of points into
    # d (dimension of points) arrays of single numbers.
    my $dim       = scalar(@{$points->[0]});
    my $cmp_lists = [
        map { [] } (1..$dim),
    ];
    for (my $i=0;$i<@$points;$i++) {
        my $v = $points->[$i];
        for (my $j=0;$j<$dim;$j++) {
            push(@{$cmp_lists->[$j]}, $v->[$j]);
        }
    }

    my $R_cmp_lists = [
        map { $Nt->multiply_vector($_) } @$cmp_lists,
    ];

    my $R = [];
    for (my $i=0;$i<@{$R_cmp_lists->[0]};$i++) {
        my $components = [map { $R_cmp_lists->[$_]->[$i]} (0..($dim-1))];
        for (my $l=0;$l<$dim;$l++) {
            $R->[$l] //= [];
            $R->[$l]->[$i] = $components->[$l];
        }
    }

    return $R;
}


sub _fit_calculate_R_math_gsl_vector {
    my ($class, $Nt, $points) = @_;

    # We can do the matrix multiplication for all dimensions in
    # one go because multiply_vector only does addition and scalar
    # multiplication, so if these are overloaded it can treat a
    # vector object just like a number.
    my $R_vec = $Nt->multiply_vector($points);
    my $R     = [];
    for (my $i=0;$i<@$R_vec;$i++) {
        my $components = [$R_vec->[$i]->as_list];
        for (my $l=0;$l<@$components;$l++) {
            $R->[$l] //= [];
            $R->[$l]->[$i] = $components->[$l];
        }
    }

    return $R;
}


sub _fit_calculate_R {
    my ($class, $Nt, $points) = @_;

    # If the points are let's say 3-dimensional vectors, then we
    # want to return three array references with the x, y, and z
    # components of each point.

    my $v0 = $points->[0];
    if (is_plain_arrayref($v0)) {
        return $class->_fit_calculate_R_plain_arrayref($Nt, $points);
    }
    elsif ($v0->isa('Math::GSL::Vector')) {
        return $class->_fit_calculate_R_math_gsl_vector($Nt, $points);
    }
    # elsif ($v0->isa('Math::MatrixReal')) {
    #     return $class->_fit_calculate_R_math_matrixreal($Nt, $points);
    # }
    # elsif ($v0->isa('Math::Vector::Real')) {
    #     return $class->_fit_calculate_R_math_vector_real($Nt, $points);
    # }
    # elsif ($v0->isa('Math::VectorReal')) {
    #     return $class->_fit_calculate_R_math_vectorreal($Nt, $points);
    # }
    else {
        $Math::BSpline::Curve::logger->errorf(
            "Unsupported vector class: %s",
            blessed($v0) // 'undef',
        );
        return undef;
    }
}


sub _fit_calculate_control_points_plain_arrayref {
    my ($class, $Pc) = @_;

    my $P = [];
    for (my $i=0;$i<@{$Pc->[0]};$i++) {
        push(
            @$P,
            [map { $_->[$i] } @$Pc],
        );
    }

    return $P;
}


sub _fit_calculate_control_points_math_gsl_vector {
    my ($class, $Pc) = @_;

    require_module('Math::GSL::Vector');

    my $P = [];
    for (my $i=0;$i<@{$Pc->[0]};$i++) {
        push(
            @$P,
            Math::GSL::Vector->new([map { $_->[$i] } @$Pc]),
        );
    }

    return $P;
}


sub _fit_calculate_control_points_math_matrixreal {
    my ($class, $Pc) = @_;

    require_module('Math::MatrixReal');

    my $P = [];
    for (my $i=0;$i<@{$Pc->[0]};$i++) {
        push(
            @$P,
            Math::MatrixReal->new_from_cols(
                [
                    [map { $_->[$i] } @$Pc],
                ],
            ),
        );
    }

    return $P;
}


sub _fit_calculate_control_points {
    my ($class, $Pc, $vtc) = @_;

    if (!$vtc) {
        return $class->_fit_calculate_control_points_plain_arrayref($Pc);
    }
    elsif ($vtc eq 'Math::GSL::Vector') {
        return $class->_fit_calculate_control_points_math_gsl_vector($Pc);
    }
    # elsif ($vtc eq 'Math::MatrixReal') {
    #     return $class->_fit_calculate_control_points_math_matrixreal($Pc);
    # }
    # elsif ($vtc eq 'Math::Vector::Real') {
    #     return $class->_fit_calculate_control_points_math_vector_real($Pc);
    # }
    # elsif ($vtc eq 'Math::VectorReal') {
    #     return $class->_fit_calculate_control_points_math_vectorreal($Pc);
    # }
    else {
        $Math::BSpline::Curve::logger->errorf(
            "Unsupported vector class: %s",
            $vtc,
        );
        return undef;
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Math::BSpline::Curve::Role::Approximation - fitting a B-spline curve to a point set

=head1 VERSION

version 0.002

=head1 AUTHOR

Lutz Gehlen <perl@lutzgehlen.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Lutz Gehlen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

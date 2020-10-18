package Math::BSpline::Curve;
$Math::BSpline::Curve::VERSION = '0.001';
use 5.014;
use warnings;

# ABSTRACT: B-spline curves

use Moo 2.002005;
use List::Util 1.26 ('min');
use Ref::Util 0.010 (
    'is_plain_arrayref',
);
use Math::BSpline::Basis 0.001;
use Math::Matrix::Banded 0.004;


has '_degree' => (
    is       => 'ro',
    required => 1,
    init_arg => 'degree',
);



has '_knot_vector' => (
    is        => 'ro',
    init_arg  => 'knot_vector',
    predicate => 1,
);



has 'control_points' => (
    is      => 'lazy',
    builder => sub { return [] },
);



has 'basis' => (
    is      => 'lazy',
    handles => [
        'degree',
        'knot_vector',
    ],
    builder => sub {
        my ($self) = @_;

        return Math::BSpline::Basis->new(
            degree      => $self->_degree,
            (
                $self->_has_knot_vector
                    ? (knot_vector => $self->_knot_vector)
                    : (),
            ),
        )
    }
);



sub evaluate {
    my ($self, $u) = @_;
    my $basis      = $self->basis;

    my $p   = $self->degree;
    my $P   = $self->control_points;
    my $s   = $basis->find_knot_span($u);
    my $Nip = $basis->evaluate_basis_functions($s, $u);

    return undef if (!@$P);
    my $value;
    if (is_plain_arrayref($P->[0])) {
        # The control points are plain arrayrefs, hence we have no
        # overloaded scalar multiplication at our disposal and have
        # to manipulate the components individually.
        my $dim = scalar(@{$P->[0]});
        $value = [map { 0 } (1..$dim)];
        for (my $i=0;$i<=$p;$i++) {
            my $c      = $Nip->[$i];
            my $this_P = $P->[$s-$p+$i];
            for (my $j=0;$j<$dim;$j++) {
                $value->[$j] += $c * $this_P->[$j];
            }
        }
    }
    else {
        # We use the first control point to initialize the value in
        # order to support all objects that overload addition and
        # scalar multiplication.
        $value = 0 * $P->[0];
        for (my $i=0;$i<=$p;$i++) {
            $value += $Nip->[$i] * $P->[$s-$p+$i];
        }
    }

    return $value;
}



sub evaluate_derivatives {
    my ($self, $u, $d) = @_;
    my $basis          = $self->basis;

    my $p = $self->degree;
    my $P = $self->control_points;
    my $s = $basis->find_knot_span($u);
    my $D = $basis->evaluate_basis_derivatives($s, $u, min($d, $p));

    return undef if (!@$P);
    my $value = [];
    if (is_plain_arrayref($P->[0])) {
        # The control points are plain arrayrefs, hence we have no
        # overloaded scalar multiplication at our disposal and have
        # to manipulate the components individually.
        my $dim = scalar(@{$P->[0]});
        for (my $k=0;$k<=$d;$k++) {
            $value->[$k] = [map { 0 } (1..$dim)];

            if ($k <= $p) {
                for (my $i=0;$i<=$p;$i++) {
                    my $c      = $D->[$k]->[$i];
                    my $this_P = $P->[$s-$p+$i];
                    for (my $j=0;$j<$dim;$j++) {
                        $value->[$k]->[$j] += $c * $this_P->[$j];
                    }
                }
            }
        }
    }
    else {
        # We use the first control point to initialize the value in
        # order to support all objects that overload addition and
        # scalar multiplication.
        for (my $k=0;$k<=$d;$k++) {
            $value->[$k] = 0 * $P->[0];

            if ($k <= $p) {
                for (my $i=0;$i<=$p;$i++) {
                    $value->[$k] += $D->[$k]->[$i] * $P->[$s-$p+$i];
                }
            }
        }
    }

    return $value;
}


sub derivative {
    my ($self) = @_;
    my $p      = $self->degree;
    my $P      = $self->control_points;
    my $U      = $self->knot_vector;

    return undef if (!@$P);

    my $q = $p - 1;
    my $V = [@$U[1..($#$U-1)]];
    my $Q = [];
    if (is_plain_arrayref($P->[0])) {
        # The control points are plain arrayrefs, hence we have no
        # overloaded scalar multiplication at our disposal and have
        # to manipulate the components individually.
        my $dim = scalar(@{$P->[0]});
        for (my $i=0;$i<@$P-1;$i++) {
            my $c = $p / ($U->[$i+$p+1] - $U->[$i+1]);
            $Q->[$i] = [];
            for (my $j=0;$j<$dim;$j++) {
                $Q->[$i]->[$j] = $c * ($P->[$i+1]->[$j] - $P->[$i]->[$j]);
            }
        }
    }
    else {
        for (my $i=0;$i<@$P-1;$i++) {
            my $c = $p / ($U->[$i+$p+1] - $U->[$i+1]);
            $Q->[$i] = $c * ($P->[$i+1] - $P->[$i]);
        }
    }

    return Math::BSpline::Curve->new(
        degree         => $q,
        knot_vector    => $V,
        control_points => $Q,
    );
}


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Math::BSpline::Curve - B-spline curves

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Math::BSpline::Curve;

    my $c = Math::BSpline::Curve->new(
        degree         => 3,
        knot_vector    => [0, 0, 0, 0, 1, 1, 1, 1],
        control_points => [
            [1,  2],
            [2,  3],
            [3,  0],
            [2, -1],
        ],
    );

    my $p = $curve->evaluate(0.3);
    my $d = $curve->evaluate_derivatives(0.3, 3);

    my $dc = $curve->derivative;
    my $v  = $dc->evaluate(0.3);

=head1 DESCRIPTION

A B-spline curve of degree p is a curve built upon B-spline basis
functions of degree p and a set of control points. The well-known
Bezier curves are a special case of B-spline curves. For more
information on B-spline basis functions see
L<Math::BSpline::Basis|Math::BSpline::Basis>.

=head1 CONSTRUCTORS

=head3 new

    $curve = Math::BSpline::Curve->new(
        degree         => 3,
        knot_vector    => [0, 0, 0, 0, 1, 1, 1, 1],
        control_points => [
            [1,  2],
            [2,  3],
            [3,  0],
            [2, -1],
        ],
    );

B<Parameters:>

=over 4

=item degree (mandatory)

The degree of the B-splines.

=item knot_vector

The knot vector as array reference. This module only supports
clamped knot vectors. It must be a sequence of non-decreasing
numbers with p+1 copies of the same number at the beginning and p+1
copies of the same number at the end. In order to achieve a valid
knot vector, some automatic trimming is applied by
L<Math::BSpline::Basis|Math::BSpline::Basis> on a copy of the knot
vector while the original value remains unchanged. In particular,
the knot vector is clamped, sorted, and the multiplicity of internal
breakpoints is limited to p. However, no fool-proof validation is
performed, specifically, the knot vector is not validated against
undefined or non-numeric values. For a full discussion of knot
vector munging see L<Math::BSpline::Basis|Math::BSpline::Basis>.

If not specified at all, the knot vector defaults to [0,...,0,
1,...,1] with p+1 copies each. This results in a Bezier curve of
degree p.

=item control_points

The list of control points as array reference. If the knot vector
contains numbers u_0,...,u_m then you should provide control points
P_0,...,P_n with n = m - p - 1. This is currently not enforced, but
it might be in a future release.

A control point can either be an array reference to the coordinates
of the control points or an object that overloads addition (+) and
scalar multiplication (*). Most vector and matrix classes do
this. Whatever you choose, all control points should be of the same
type.

=back

=head1 ATTRIBUTES

=head3 degree

The degree of the spline curve. Must be set at construction and
cannot be modified afterwards.

=head3 knot_vector

An array reference to the knot vector of the B-splines. Can only be
set at construction. Defaults to [0,...,0, 1,...,1] resulting in a
Bezier curve.

=head3 control_points

An array reference to the control points for the B-spline curve. Can
only be set at construction.

=head3 basis

The corresponding L<Math::BSpline::Basis|Math::BSpline::Basis>
object used to evaluate the curve. You typically do not need to care
about this.

=head1 METHODS

=head2 evaluate

  $p = $curve->evaluate($u)

Evaluates the spline curve at the given position. The returned
object or array reference is of the same type as the control points.

=head2 evaluate_derivatives

  $d = $curve->evaluate_derivatives($u, $k)

Returns an array reference containing the point and all derivatives
up to and including C<$k> at C<$u>. The returned objects or array
references are of the same type as the control points.

=head2 derivative

  $curve->derivative

The derivative of a B-spline curve of degree p is a B-spline curve
of degree p-1. This method returns a Math::BSpline::Curve object
representing this derivative.

CAVEAT: L<Math::BSpline::Basis|Math::BSpline::Basis> and therefore
also Math::BSpline::Curve only support B-splines that are internally
continuous. If your curve is of degree p and if it has an internal
knot u_i of multiplicity p then the derivative is discontinuous at
u_i. In this case, the derivative method will not fail, but return a
continuous B-spline curve, which is B<not> the correct
derivative. This behavior might change in a future release.

=head1 ACKNOWLEDGEMENTS

This implementation is based on the theory and algorithms presented
in the NURBS book.

=over 4

=item [1] Piegl, L., Tiller, W.: The NURBS book, 2nd
Edition. Springer, 1997.

=back

=head1 AUTHOR

Lutz Gehlen <perl@lutzgehlen.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Lutz Gehlen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

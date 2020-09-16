package Math::BSpline::Basis;
$Math::BSpline::Basis::VERSION = '0.001';
use 5.014;
use warnings;

# ABSTRACT: B-spline basis functions

use Moo 2.002005;
use List::Util 1.26 ('min');
use Ref::Util 0.010 (
    'is_ref',
    'is_plain_hashref',
    'is_blessed_hashref',
    'is_plain_arrayref',
);


around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    my $munged_args;

    if (@args == 1) {
        if (!is_ref($args[0])) {
            # We do not understand this and dispatch to Moo (if this
            # is what $orig does, the docu is very sparse).
            return $class->$orig(@args);
        }
        elsif (
            is_plain_hashref($args[0])
            or
            is_blessed_hashref($args[0])
        ) {
            # I am trying to stay as close to Moo's default behavior
            # as I can, this is the only reason why I am supporing
            # hashrefs at all. And since Moo apparently accepts
            # blessed references, I do the same. However, I make a
            # copy, blessed or not.
            #
            # The ugly test is due to an announced change in the
            # behavior of Ref::Util. is_hashref is going to behave
            # like is_plain_hashref does now.  However, the planned
            # replacement called is_any_hashref is not there. So the
            # only future-safe implementation seems to be to use
            # both explicit functions.
            $munged_args = {%{$args[0]}};
        }
        else {
            # We do not understand this and dispatch to Moo (if this
            # is what $orig does, the docu is very sparse).
            return $class->$orig(@args);
        }
    }
    elsif (@args % 2 == 1) {
        # We do not understand this and dispatch to Moo (if this
        # is what $orig does, the docu is very sparse).
        return $class->$orig(@args);
    }
    else {
        $munged_args = {@args};
    }

    if (exists($munged_args->{knot_vector})) {
        # degree is mandatory, so we only deal with the case when it
        # is there. Otherwise we just let Moo do its job.
        if (exists($munged_args->{degree})) {
            # We do not perform any type validation etc, if the
            # attributes are there, we use them assuming that they
            # are valid.
            my $p           = $munged_args->{degree};
            my $U           = $munged_args->{knot_vector};
            my $is_modified = 0;

            # deal with empty array
            if (!defined($U) or !is_plain_arrayref($U) or @$U == 0) {
                $U = [
                    (map { 0 } (0..$p)),
                    (map { 1 } (0..$p)),
                ];
                $is_modified = 1;
            }

            # deal with unsorted
            for (my $i=1;$i<@$U;$i++) {
                if ($U->[$i] < $U->[$i-1]) {
                    $U           = [sort { $a <=> $b } @$U];
                    $is_modified = 1;
                    last;
                }
            }

            # deal with first breakpoint
            for (my $i=1;$i<=$p;$i++) {
                if ($i == @$U or $U->[$i] != $U->[$i-1]) {
                    $U = [@$U] if (!$is_modified);
                    unshift(@$U, $U->[0]);
                    $is_modified = 1;
                }
            }

            # deal with last breakpoint
            if ($U->[-1] == $U->[0]) {
                $U = [@$U] if (!$is_modified);
                push(@$U, $U->[0] + 1);
            }
            for (my $i=-2;$i>=-1-$p;$i--) {
                if ($U->[$i] != $U->[$i+1]) {
                    $U = [@$U] if (!$is_modified);
                    push(@$U, $U->[-1]);
                    $is_modified = 1;
                }
            }

            # deal with excess multiplicity
            for (my $i=$p+1;$i<@$U-1;$i++) {
                while ($i<@$U-1 and $U->[$i] == $U->[$i-$p]) {
                    $U = [@$U] if (!$is_modified);
                    splice(@$U, $i, 1);
                    $is_modified = 1;
                }
            }

            $munged_args->{knot_vector} = $U if ($is_modified);
        }
    }

    return $class->$orig($munged_args);
};



has 'degree' => (
    is       => 'ro',
    required => 1,
);



has 'knot_vector' => (
    is      => 'lazy',
    builder => sub {
        my ($self) = @_;
        my $p      = $self->degree;

        return [
            (map { 0 } (0..$p)),
            (map { 1 } (0..$p)),
        ]
    }
);



# I use the same variable names as in the NURBS book, although some
# of them are very generic. The use of $p, $U, $P, and $n is
# consistent throughout the relevant chapters of the book.
sub find_knot_span {
    my ($self, $u) = @_;
    my $p          = $self->degree;
    my $U          = $self->knot_vector;
    my $n          = (@$U - 1) - $p - 1;

    # We expect $u in [$U->[$p], $U->[$n+1]]. We only support
    # values outside this range for rounding errors, do not assume
    # that the result makes sense otherwise.
    return $n if ($u >= $U->[$n+1]);
    return $p if ($u <= $U->[$p]);

    # binary search
    my $low  = $p;
    my $high = $n + 1;
    my $mid  = int(($low + $high) / 2);
    while ($u < $U->[$mid] or $u >= $U->[$mid+1]) {
        if ($u < $U->[$mid]) { $high = $mid }
        else                 { $low  = $mid }
        $mid = int(($low + $high) / 2);
    }

    return $mid;
}



# The variable names are inspired by the theory as laid out in the
# NURBS book. We want to calculate N_{i,p}, that inspires $N and
# $p. U is the knot vector, left and right are inspired by the
# terms in the formulas used in the theoretical derivation.
sub evaluate_basis_functions {
    my ($self, $i, $u) = @_;
    my $p              = $self->degree;
    my $U              = $self->knot_vector;
    my $n              = (@$U - 1) - $p - 1;

    if ($u < $U->[$p] or $u > $U->[$n+1]) {
        return [map { 0 } (0..$p)];
    }

    my $N     = [1];
    my $left  = [];
    my $right = [];
    for (my $j=1;$j<=$p;$j++) {
        $left->[$j]  = $u - $U->[$i+1-$j];
        $right->[$j] = $U->[$i+$j] - $u;
        my $saved = 0;
        for (my $r=0;$r<$j;$r++) {
            my $temp = $N->[$r] / ($right->[$r+1] + $left->[$j-$r]);
            $N->[$r] = $saved + $right->[$r+1] * $temp;
            $saved   = $left->[$j-$r] * $temp;
        }
        $N->[$j] = $saved;
    }

    return $N;
}



sub evaluate_basis_derivatives {
    my ($self, $i, $u, $d) = @_;
    my $p                  = $self->degree;
    my $U                  = $self->knot_vector;
    my $n                  = (@$U - 1) - $p - 1;
    my $result             = [];

    $d = min($d, $p);

    if ($u < $U->[$p] or $u > $U->[$n+1]) {
        for (my $k=0;$k<=$d;$k++) {
            push(@$result, [map { 0 } (0..$p)]);
        }
        return $result;
    }

    my $ndu   = [[1]];
    my $left  = [];
    my $right = [];
    for (my $j=1;$j<=$p;$j++) {
        $left->[$j]  = $u - $U->[$i+1-$j];
        $right->[$j] = $U->[$i+$j] - $u;
        my $saved = 0;
        for (my $r=0;$r<$j;$r++) {
            $ndu->[$j]->[$r] = $right->[$r+1] + $left->[$j-$r];
            my $temp = $ndu->[$r]->[$j-1] / $ndu->[$j]->[$r];
            $ndu->[$r]->[$j] = $saved + $right->[$r+1] * $temp;
            $saved           = $left->[$j-$r] * $temp;
        }
        $ndu->[$j]->[$j] = $saved;
    }

    # $result->[0] holds the function values (0th derivatives)
    for (my $j=0;$j<=$p;$j++) {
        $result->[0]->[$j] = $ndu->[$j]->[$p];
    }

    for (my $r=0;$r<=$p;$r++) {
        my $a         = [[1]];
        my ($l1, $l2) = (0, 1);  # alternating indices to address $a

        # compute $result->[$k] (kth derivative)
        for (my $k=1;$k<=$d;$k++) {
            my $sum = 0;
            my $rk  = $r - $k;
            my $pk  = $p - $k;
            if ($rk >= 0) {
                $a->[$l2]->[0] = $a->[$l1]->[0] / $ndu->[$pk+1]->[$rk];
                $sum = $a->[$l2]->[0] * $ndu->[$rk]->[$pk];
            }

            my $j_min = $rk >= -1      ? 1      : -$rk;
            my $j_max = $r  <= $pk + 1 ? $k - 1 : $p - $r;
            for (my $j=$j_min;$j<=$j_max;$j++) {
                $a->[$l2]->[$j] = ($a->[$l1]->[$j] - $a->[$l1]->[$j-1])
                    / $ndu->[$pk+1]->[$rk+$j];
                $sum += $a->[$l2]->[$j] * $ndu->[$rk+$j]->[$pk];
            }

            if ($r <= $pk) {
                $a->[$l2]->[$k] = -$a->[$l1]->[$k-1]
                    / $ndu->[$pk+1]->[$r];
                $sum += $a->[$l2]->[$k] * $ndu->[$r]->[$pk];
            }

            $result->[$k]->[$r] = $sum;
            ($l1, $l2) = ($l2, $l1);
        }
    }

    my $multiplicity = $p;
    for (my $k=1;$k<=$d;$k++) {
        for (my $j=0;$j<=$p;$j++) {
            $result->[$k]->[$j] *= $multiplicity;
        }
        $multiplicity *= ($p - $k);
    }

    return $result;
}


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Math::BSpline::Basis - B-spline basis functions

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Math::BSpline::Basis;

    my $bspline = Math::BSpline::Basis->new(
        degree      => 3,
        knot_vector => [0, 0, 0, 0, 1, 1, 1, 1],
    );
    my $P = [-1, 2, 5, -3];

    my $u = 0.6;
    my $s = $bspline->find_knot_span($u);
    my $N = $bspline->evaluate_basis_functions($s, $u);

    my $value = 0;
    my $p     = $bspline->degree;
    for (my $i=0;$i<=$p;$i++) {
        $value += $N->[$i] * $P->[$s-$p+$i];
    }

    my $D = $bspline->evaluate_basis_derivatives($s, $u, 3);

=head1 DESCRIPTION

=head2 Introduction

A spline S of degree p is a piecewise polynomial function from a
real interval [a, b] to the real numbers. This means that given a
strictly increasing sequence of breakpoints a = u_0 < u_1 < ... <
u_m = b, S is a polynomial function of degree less or equal to p on
each interval [u_i, u_{i+1}].

At the breakpoints u_i, S can be discontinuous or continuously
differentiable to a certain degree. If we specify minimum continuity
conditions for each breakpoint then the set of splines of degree p
satisfying these conditions forms a real vector space.

Given the degree, sequence of breakpoints, and continuity
conditions, one can define a certain set of splines with convenient
properties (local support, partition of unity etc) that form a basis
of the above vector space. These are called basis splines or
B-splines.

It turns out that the breakpoints and continuity conditions can be
neatly specified in one go by defining a non-decreasing sequence of
knots (also called knot vector) a = u_0 <= u_1 <= ... <= u_m =
b. Note the difference to the breakpoints above: while the
breakpoints are distinct, the knots only need to be
non-decreasing. The breakpoints correspond to the set of distinct
knots and the continuity conditions are encoded in the multiplicity
of breakpoints. If a breakpoint has multiplicity k then the
B-splines are p-k times continuously differentiable at this
breakpoint.

=head2 B-Spline Support in Math::BSpline::Basis

As discussed above, a degree p and a knot vector U determine a
vector space of splines and a basis of B-splines for this vector
space. This module allows you to evaluate the non-zero basis
functions and derivatives at a given position u in [a, b].

An important property of B-splines is that on a given knot span
[u_i, u_{i+1}[ only a small number of B-splines is non-zero. This
property is called local support. More specifically, the B-spline
function N_{i,p} is equal to 0 outside the interval [u_i,
u_{i+p+1}]. This implies that on a given knot span [u_i, u_{i+1}[,
at most the p+1 B-splines N_{i-p,p},...,N_{p,p} can be non-zero.

Hence, the first step in evaluating B-splines at a given position is
to determine the knot span the position falls into. After that, it
is possible to evaluate specifically the non-zero basis functions.

    my $u = 0.6;
    my $s = $bspline->find_knot_span($u);
    my $N = $bspline->evaluate_basis_functions($s, $u);

Special attention has to be given to the first and the last
breakpoint. A knot vector is called clamped (or non-periodic or
open) if the first and the last breakpoint each have multiplicity
p+1. This corresponds to no continuity restrictions at the
boundaries of the interval [a, b]. This module only supports clamped
knot vectors.

For a clamped knot vector of length m+1 (u_0,...,u_m), the dimension
of the vector space of splines is n+1 with n = m - p - 1, hence we
have basis splines N_{0,p},...,N_{n,p}. In order to form a B-spline
function as a linear combination of the basis splines, we need n+1
so-called control points P_0,...,P_n. (The control points can also
be vectors, which results in a B-spline curve.) In order to evaluate
the resulting B-spline function (or curve) at a given position u we
need to evaluate the non-vanishing basis functions as described
above and then form the linear combination making sure that we get
the indexing right:

    my $u = 0.6;
    my $s = $bspline->find_knot_span($u);
    my $N = $bspline->evaluate_basis_functions($s, $u);

    my $value = 0;
    for (my $i=0;$i<=$p;$i++) {
        $value += $N->[$i] * $P->[$s-$p+$i];
    }

=head1 CONSTRUCTORS

=head3 new

    $bspline = Math::BSpline::Basis->new(
        degree      => 3,
        knot_vector => [0, 0, 0, 0, 1, 1, 1, 1],
    );

B<Parameters:>

=over 4

=item degree (mandatory)

The degree of the B-splines.

=item knot_vector

The knot vector as array reference. A full clamped knot vector must
be a sequence of non-decreasing numbers with p+1 copies of the same
number at the beginning and p+1 copies of the same number at the
end. In order to achieve a valid knot vector, some automatic
trimming is applied on a copy of the knot vector while the original
value remains unchanged. However, no fool-proof validation is
performed, specifically, the knot vector is not validated against
undefined or non-numeric values.

=over 4

=item sorting

In order to protect against decreasing knot values (e.g. due to
rounding errors in upstream calculations) the knot vector is sorted.

=item clamping

Mostly to relieve the user of this task, the knot vector is extended
on both ends, such that the first p+1 values are identical and the
last p+1 values are identical.

=item breakpoint multiplicity

The multiplicity of the first and last breakpoint is limited to p+1,
the multiplicity of each internal breakpoint is limited to p. It
generally does not make sense to increase breakpoint multiplicity
any further.

=back

If not specified at all, the knot vector defaults to [0,...,0,
1,...,1] with p+1 copies each. This results in a Bezier spline of
degree p.

=back

=head1 ATTRIBUTES

=head3 degree

The degree of the B-splines. Must be set at construction and cannot
be modified afterwards.

=head3 knot_vector

The knot vector of the B-splines. Can only set at
construction. Defaults to [0,...,0, 1,...,1] resulting in a Bezier
spline.

=head1 METHODS

=head3 find_knot_span

  $s = $bspline->find_knot_span($u)

If the knot vector is (u_0,...u_m) then this method returns the
index s such that u_s <= u < u_{s+1}. A special case is u = u_m. In
this case, the method returns s such that u_s < u <= u_{s+1}, i.e. u
is the B<upper> boundary of the knot span.

Outside of [u_p, u_{m-p}], all basis functions vanish. This is
supported by L<evaluate_basis_functions|evaluate_basis_functions>
and L<evaluate_basis_derivatives|evaluate_basis_derivatives>. This
method returns p for u < u_p and m-p-1 for u > u_{m-p}. If you use
the return value exclusively for feeding it into
L<evaluate_basis_functions|evaluate_basis_functions>
or L<evaluate_basis_derivatives|evaluate_basis_derivatives> then you
do not need to care about this.

=head3 evaluate_basis_functions

    $P = [-1, 2, 5, -3];
    $u = 0.6;
    $s = $bspline->find_knot_span($u);
    $N = $bspline->evaluate_basis_functions($s, $u);

    $value = 0;
    $p     = $bspline->degree;
    for (my $i=0;$i<=$p;$i++) {
        $value += $N->[$i] * $P->[$s-$p+$i];
    }

Expects a knot span index s as returned by
L<find_knot_span|find_knot_span> and a parameter value u and returns
the values of the p+1 (potentially) non-vanishing B-splines
N_{s-p,p},...,N_{p,p} as an array reference.

=head3 evaluate_basis_derivatives

    $P = [-1, 2, 5, -3];
    $u = 0.6;
    $d = 3;
    $s = $bspline->find_knot_span($u);
    $D = $bspline->evaluate_basis_derivatives($s, $u, $d);

    $value = [];
    $p     = $bspline->degree;
    for (my $k=0;$k<=$d;$k++) {
        $value->[$k] = 0;

        if ($k <= $p) {
            for (my $i=0;$i<=$p;$i++) {
                $value->[$k] += $D->[$k]->[$i] * $P->[$s-$p+$i];
            }
        }
    }

=head1 ACKNOWLEDGEMENTS

This implementation is based on the theory and algorithms presented
in the NURBS book [1] and (to a much lesser degree) on the theory
presented in [2].

=over 4

=item [1] Piegl, L., Tiller, W.: The NURBS book, 2nd
Edition. Springer, 1997.

=item [2] de Boor, C.: A Practical Guide to Splines, Revised
Edition. Springer 2001.

=back

=head1 AUTHOR

Lutz Gehlen <perl@lutzgehlen.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Lutz Gehlen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

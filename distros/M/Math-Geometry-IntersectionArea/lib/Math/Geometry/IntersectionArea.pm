package Math::Geometry::IntersectionArea;

our $VERSION = '0.01';

use strict;
use warnings;
use Carp;
use 5.010;
use Math::Vector::Real;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(intersection_area_circle_rectangle
                    intersection_area_circle_polygon);

sub _ia2_circle_segment { # ia2 = intersection area * 2
    my ($r2, $a, $b) = @_;

    # finds the oriented area of the intersection of the circle of
    # radius sqrt(r2) centered on the origin O and the
    # triangle(O,a,b).

    # Cases:
    #
    # 0:  /-----\
    #    /       \
    #    | x---x |
    #
    #
    # 1:  /-----\
    #    /       \ x---x
    #    |       |
    #
    #
    # 2:         /-----\
    #     x---x /       \
    #           |       |
    #
    #
    # 3:  x---x
    #
    #    /-----\
    #
    #
    # 4:  /-----\
    #    /       \
    #  x-|-------|-x
    #
    #
    # 5:  /-----\
    #    /       \
    #  x-|---x   |
    #
    #
    # 6:  /-----\
    #    /       \
    #    |   x---|-x
    #

    # The two points where the segment intersects the circle are found
    # solving the following cuadratic equation:
    #
    #   norm(a + alfa * ab) = d
    #
    #
    # The coeficientes c2, c1, c0 are deduced from the formula
    # above such that:
    #
    #   c2 * alfa**2 + 2 * c1 * alfa + c0 = 0
    #
    # And then the clasical formula for quadratic equation solved is
    # used:
    #
    #   alfa0 = 1/c2 + (-$c1 + sqrt($c1*$c1 - 4 * $c0 * $c2))
    #   alfa1 = 1/c2 + (-$c1 - sqrt($c1*$c1 - 4 * $c0 * $c2))

    my $ab = $b - $a;
    my $c2 = $ab->norm2 or return 0; # a and b are the same point
    my $c1 = $a * $ab;
    my $c0 = $a->norm2 - $r2;
    my $discriminant = $c1 * $c1 - $c0 * $c2;
    if ($discriminant > 0) { # otherwise case 3
        my $inv_c2 = 1/$c2;
        my $sqrt_discriminant = sqrt($discriminant);
        my $alfa0 = $inv_c2 * (-$c1 - $sqrt_discriminant);
        my $alfa1 = $inv_c2 * (-$c1 + $sqrt_discriminant);
        if ($alfa0 < 1 and $alfa1 > 0) { # otherwise cases 1 and 2
            # cases 0, 4, 5 and 6
            my $beta = 0;
            my ($p0, $p1);
            if ($alfa0 > 0) {
                $p0 = $a + $alfa0 * $ab;
                $beta += atan2($a, $p0);
            }
            else {
                $p0 = $a;
            }
            if ($alfa1 <= 1) {
                $p1 = $a + $alfa1 * $ab;
                $beta += atan2($p1, $b);
            }
            else {
                $p1 = $b;
            }
            return $p0->[0] * $p1->[1] - $p0->[1] * $p1->[0] + $beta * $r2;
        }
    }

    # else the sector is fully contained inside the triangle (cases 1, 2 and 3)
    return atan2($a, $b) * $r2
}

sub intersection_area_circle_rectangle {
    @_ == 4 or croak 'Usage: intersection_area_circle_rectangle($o, $r, $v0, $v1)';
    my $O = V(@{shift()}); # accept plain array refs as vectors
    my $r = shift;
    my ($a, $c) = Math::Vector::Real->box($_[0] - $O, $_[1] - $O);

    # fast check:
    return 0 if ($a->[0] >=  $r or $c->[0] <= -$r or
                 $a->[1] >=  $r or $c->[1] <= -$r);

    my $b = V($a->[0], $c->[1]);
    my $d = V($c->[0], $a->[1]);
    my $r2 = $r * $r;
    abs(0.5 * (_ia2_circle_segment($r2, $a, $b) +
               _ia2_circle_segment($r2, $b, $c) +
               _ia2_circle_segment($r2, $c, $d) +
               _ia2_circle_segment($r2, $d, $a)));
}

sub intersection_area_circle_polygon {
    @_ > 4 or return 0;
    my $O = V(@{shift()}); # accept plain array refs as vectors
    my $r = shift;

    # fast check:
    my ($v0, $v1) = Math::Vector::Real->box(@_);
    $v0 -= $O;
    $v1 -= $O;
    return 0 if ($v0->[0] >= $r or $v1->[0] <= -$r or
                 $v0->[1] >= $r or $v1->[1] <= -$r);

    my $A = 0;
    my $r2 = $r * $r;
    my $last = $_[-1] - $O;
    for (@_) {
        my $p = $_ - $O;
        $A += _ia2_circle_segment($r2, $last, $p);
        $last = $p;
    }
    return abs(0.5 * $A);
}

1;

__END__

=head1 NAME

Math::Geometry::IntersectionArea - Calculate area of geometric shapes intersection

=head1 SYNOPSIS

  use Math::Geometry::IntersectionArea qw(intersection_area_circle_rectangle);

  my $area = intersection_area_circle_rectangle([1,4], 2, [0, 1], [5, 5]);


=head1 DESCRIPTION

This module provides functions to calculate the area of the
intersection of several combinations of geometric shapes.

Geometric coordinates are defined with bidimensional vectors from the
class L<Math::Vector::Real>. Alternatively, for convenience, all the
subroutines accept also raw array references (e.g. C<[1,3]>).

Well, currently only intersections between circles and polygons are
supported. If you need to calculate the intersection between other
combinations of geometric shapes these are your options:

1) Convince me to extend the module with the functionality you need.

2) Extend it yourself and send me a patch for inclusion (though, it
would be highly advisable to discuss the matter first).

In any case, don't hesitate to get in touch with me. I love
geometrical problems :-)

=head2 EXPORTABLE SUBS

=over 4

=item intersection_area_circle_polygon($o, $r, @p)

Returns the area of the intersection between the circle of radius
C<$r> centered in C<$o> and the polygon delimited by the list of
points in C<@p>.

=item intersection_area_rectangle($o, $r, $v0, $v1)

Return the area of the intersection between the circle of radius C<$r>
with center in C<$o> and the axis-aligned rectangle defined by its two
corners C<$v0> and C<$v1>.

=back

=head1 SEE ALSO

L<Math::Vector::Real>, L<Math::Vector::Real::XS>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Salvador Fandiño E<lt>sfandino@yahoo.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

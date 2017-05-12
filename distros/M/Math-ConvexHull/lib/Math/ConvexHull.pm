package Math::ConvexHull;
use 5.006;
use strict;
use warnings;

use constant PI => 3.1415926535897932384626433832795;

require Exporter;

our $VERSION = '1.04';


our @ISA = qw(Exporter);

our @EXPORT_OK = qw(
        convex_hull
);

our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );


sub convex_hull {
        my $points = shift;
        
        my $start_index = _find_start_point($points); # O(n)

        my $angles_points = _calculate_angles($points, $start_index); # O(n)
        my $start = splice(@$angles_points, $start_index, 1);

        @$angles_points =
                        sort {
                                $a->[0] <=> $b->[0] ||
                                $a->[1][0] <=> $b->[1][0] ||
                                $a->[1][1] <=> $b->[1][1]
                        }
                        @$angles_points;             # O(n*log(n))

        unshift @$angles_points, $start;

        # remove duplicates (O(n))
        # At the same time, drop the angle
        my $prev = $angles_points->[0][1];
        my @hull;
        push @hull, $prev;
        for my $r (@$angles_points) {
                my $p = $r->[1];
                push @hull, $p
                        if (   $p->[0]+1e-15 <= $prev->[0] || $p->[0]-1e-15 >= $prev->[0]
                            || $p->[1]+1e-15 <= $prev->[1] || $p->[1]-1e-15 >= $prev->[1]);
                $prev = $p;
        }

        # copy of the reference point as sentinel to stop loop
        unshift @hull, $hull[0];

        my $n_in_hull = 2;
        # O(n)
        for (my $i = 3; $i < @hull; ++$i) {
                while (
                        _ccw(
                                $hull[$n_in_hull-1],
                                $hull[$n_in_hull],
                                $hull[$i]
                        ) <= 0
                ) {
                        if ($n_in_hull == 2) {
                                ($hull[$i], $hull[$n_in_hull]) = (@hull[$n_in_hull, $i]);
                                ++$i;
                        }
                        else {
                                --$n_in_hull;
                        }
                }
                ++$n_in_hull;
                ($hull[$i], $hull[$n_in_hull]) = (@hull[$n_in_hull, $i]);
        }

        # return points in hull
        return [@hull[1..$n_in_hull]];
}

sub _ccw {
        my $p1 = shift;
        my $p2 = shift;
        my $p3 = shift;
        
        return(
                ($p2->[0] - $p1->[0])*($p3->[1] - $p1->[1])
                -
                ($p2->[1] - $p1->[1])*($p3->[0] - $p1->[0])
        );
}

sub _calculate_angles {
        my $points = shift;
        my $start  = shift;

        my $s_x = $points->[$start]->[0];
        my $s_y = $points->[$start]->[1];

        my $angles = [];
        
        my $p_no = 0;
        foreach my $p (@$points) {
                my $angle;
                if ($p_no == $start) {
                        $angle = 0;
                }
                else {
                        my $x_diff = $p->[0] - $s_x;
                        my $y_diff = $p->[1] - $s_y;

                        $angle = atan2($y_diff, $x_diff);
                        $angle = PI-$angle if $angle < 0;
                }

                push @$angles, [$angle, $p];
                $p_no++;
        }

        return $angles;
}



# Returns the index of the starting point.
sub _find_start_point {
        my $points = shift;
        
        # Looking for the lowest, then leftmost point.
        
        my $s_point = 0;

        for (my $i = 1; $i < @$points; $i++) {
                my ($p0, $p1)   = @{ $points->[$i] };
                my ($sp0, $sp1) = @{ $points->[$s_point] };
                if (
                        $p1 <= $sp1 and
                        $p1 < $sp1 ||
                        $p0 < $sp0
                ) {
                        $s_point = $i;
                }
        }

        return $s_point;
}



1;
__END__

=head1 NAME

Math::ConvexHull - Calculate convex hulls using Graham's scan (n*log(n))

=head1 SYNOPSIS

  use Math::ConvexHull qw/convex_hull/;
  $hull_array_ref = convex_hull(\@points);

=head1 DESCRIPTION

C<Math::ConvexHull> is a simple module that calculates convex hulls from a set
of points in 2D space. It is a straightforward implementation of the algorithm
known as Graham's scan which, with complexity of O(n*log(n)), is the fastest
known method of finding the convex hull of an arbitrary set of points.
There are some methods of eliminating points that cannot be part of the
convex hull. These may or may not be implemented in a future version.

The implementation cannot deal with duplicate points. Therefore, points
which are very, very close (think floating point close) to the
previous point are dropped since version 1.02 of the module.
However, if you pass in randomly ordered data which contains duplicate points,
this safety measure might not help you. In that case, you will have to
remove duplicates yourself.

=head2 EXPORT

None by default, but you may choose to have the C<convex_hull()> subroutine
exported to your namespace using standard Exporter semantics.

=head2 convex_hull() subroutine

C<Math::ConvexHull> implements exactly one public subroutine which, surprisingly,
is called C<convex_hull()>. C<convex_hull()> expects an array reference to an array
of points and returns an array reference to an array of points in the convex
hull.

In this context, a point is considered to be a reference to an
array containing an x and a y coordinate. So an example use of
C<convex_hull()> would be:

  use Data::Dumper;
  use Math::ConvexHull qw/convex_hull/;
  
  print Dumper convex_hull(
  [
    [0,0],     [1,0],
    [0.2,0.9], [0.2,0.5],
    [0,1],     [1,1],
  ]
  );
  
  # Prints out the points [0,0], [1,0], [0,1], [1,1].

Please note that C<convex_hull()> does not return I<copies> of the points but
instead returns the same array references that were passed in.

=head1 SEE ALSO

New versions of this module can be found on http://steffen-mueller.net or CPAN.

After implementing the algorithm from my CS notes, I found the exact same
implementation in the German translation of
Orwant et al, "Mastering Algorithms with Perl". Their code reads better than
mine, so if you looked at the module sources and don't understand
what's going on, I suggest you have a look at the book.

In early 2011, much of the module was rewritten to use the formulation of
the algorithm that was shown on the Wikipedia article on Graham's scan at
the time. This takes care of issues with including collinear points in the
hull.

L<http://en.wikipedia.org/wiki/Graham_scan>

One of these days, somebody should implement Chan's algorithm instead...

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003-2011 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

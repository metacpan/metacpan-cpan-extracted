package Game::Battleship::Grid;
$Game::Battleship::Grid::VERSION = '0.0601';
our $AUTHORITY = 'cpan:GENE';

use Carp;
use Game::Battleship::Craft;
use Moo;
use Types::Standard qw( ArrayRef Int );

has dimension => (
    is      => 'ro',
    isa     => ArrayRef[Int],
    default => sub { [ 9, 9 ] },
);

has fleet => (
    is  => 'ro',
    isa => ArrayRef,
);

# Place the array reference of craft on the grid.
sub BUILD {
    my $self = shift;

    # Initialize the matrix.
    for my $i (0 .. $self->dimension->[0]) {
        for my $j (0 .. $self->dimension->[1]) {
            $self->{matrix}[$i][$j] = '.';
        }
    }

    # Place the fleet on the grid.
    for my $craft (@{ $self->{fleet} }) {
        my ($ok, $x0, $y0, $x1, $y1, $orient);

        if (defined $craft->position) {
            ($x0, $y0) = ($craft->position->[0], $craft->position->[1]);

            # Set the craft orientation and tail coordinates.
            ($orient, $x1, $y1) = _tail_coordinates(
                $x0, $y0,
                $craft->points - 1
            );
        }
        else {
# XXX This looping is needlessly brutish. refactoring please
            while (not $ok) {
                # Grab a random coordinate that we haven't seen.
                $x0 = int(rand($self->dimension->[0] + 1));
                $y0 = int(rand($self->dimension->[1] + 1));

                # Set the craft orientation and tail coordinates.
                ($orient, $x1, $y1) = _tail_coordinates(
                    $x0, $y0,
                    $craft->points - 1
                );

                # If the craft is not placed off the grid and it does
                # not collide with another craft, then we are ok to
                # move on.
# XXX regex constraint rules here?
                if ($x1 <= $self->dimension->[0] &&
                    $y1 <= $self->dimension->[1]
                ) {
                    # For each craft (except the current one) that has
                    # a position, do the craft share a common point?
                    my $collide = 0;

                    for (@{ $self->{fleet} }) {
                        # Ships can't be the same.
                        if ($craft->name ne $_->name) {
                            # Ships can't intersect.
                            if (defined $_->position &&
                                _segment_intersection(
                                    $x0, $y0,
                                    $x1, $y1,
                                    @{ $_->position->[0] },
                                    @{ $_->position->[1] }
                                )
                            ) {
                                $collide = 1;
                                last;
                            }
                        }
                    }

                    $ok = 1 unless $collide;
                }
            }

            # Set the craft position.
            $craft->{position} = [[$x0, $y0], [$x1, $y1]];
        }
#warn "$craft->{name}: [$x0, $y0], [$x1, $y1], $craft->{points}\n";

        # Add the craft to the grid.
        for my $n (0 .. $craft->points - 1) {
            if ($orient) {
                $self->{matrix}[$x0 + $n][$y0] = $craft->{id};
            }
            else {
                $self->{matrix}[$x0][$y0 + $n] = $craft->{id};
            }
        }
    }
}

sub _tail_coordinates {
    # Get the coordinates of the end of the segment based on a given
    # span.
    my ($x0, $y0, $span) = @_;

    # Set orientation to 0 (vertical) or 1 (horizontal).
    my $orient = int rand 2;

    my ($x1, $y1) = ($x0, $y0);

    if ($orient) {
        $x1 += $span;
    }
    else {
        $y1 += $span;
    }

    return $orient, $x1, $y1;
}

sub _segment_intersection {
    # 0 - Intersection doesn't exist.
    # 1 - Intersection exists.
# NOTE: In Battleship, we only care about yes/no, but the
#       original code can tell much more:
    # 0 (was 2) - line segments are parallel
    # 0 (was 3) - line segments are collinear but do not overlap.
    # 4 - line segments are collinear and share an end point.
    # 5 - line segments are collinear and overlap.

    croak "segment_intersection needs 4 points\n" unless @_ == 8;
    my(
        $x0, $y0,  $x1, $y1,  # AB segment 1
        $x2, $y2,  $x3, $y3   # CD segment 2
    ) = @_;
#warn "[$x0, $y0]-[$x1, $y1], [$x2, $y2]-[$x3, $y3]\n";

    my $xba = $x1 - $x0;
    my $yba = $y1 - $y0;
    my $xdc = $x3 - $x2;
    my $ydc = $y3 - $y2;
    my $xca = $x2 - $x0;
    my $yca = $y2 - $y0;

    my $delta = $xba * $ydc - $yba * $xdc;
    my $t1 = $xca * $ydc - $yca * $xdc;
    my $t2 = $xca * $yba - $yca * $xba;

    if ($delta != 0) {
        my $u = $t1 / $delta;
        my $v = $t2 / $delta;

        # Two segments intersect (including at end points).
        return ($u <= 1 && $u >= 0 && $v <= 1 && $v >= 0) ? 1 : 0;
    }
    else {
        # AB & CD are parallel.
        return 0 if $t1 != 0 && $t2 != 0;
# NOTE:  We just care about yes/no, so this is the old way:
#        return 2 if $t1 != 0 && $t2 != 0;

        # When AB & CD are collinear...
        my ($a, $b, $c, $d);

        # If AB isn't a vertical line segment, project to x-axis.
        if ($x0 != $x1) {
            # < is min, > is max
            $a = $x0 < $x1 ? $x0 : $x1;
            $b = $x0 > $x1 ? $x0 : $x1;
            $c = $x2 < $x3 ? $x2 : $x3;
            $d = $x2 > $x3 ? $x2 : $x3;

            if ($d < $a || $c > $b) {
# NOTE:  We just care about yes/no.  The old way returns 3:
                return 0;#3;
            }
            elsif ($d == $a || $c == $b) {
                return 4;
            }
            else {
                return 5;
            }
        }
        # If AB is a vertical line segment, project to y-axis.
        else {
            # < is min, > is max
            $a = $y0 < $y1 ? $y0 : $y1;
            $b = $y0 > $y1 ? $y0 : $y1;
            $c = $y2 < $y3 ? $y2 : $y3;
            $d = $y2 > $y3 ? $y2 : $y3;

            if ($d < $a || $c > $b) {
# NOTE:  We just care about yes/no.  The old way returns 3:
                return 0;#3;
            }
            elsif ($d == $a || $c == $b) {
                return 4;
            }
            else {
                return 5;
            }
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Game::Battleship::Grid

=head1 VERSION

version 0.0601

=head1 SYNOPSIS

  use Game::Battleship::Grid;
  my $grid = Game::Battleship::Grid->new(
      fleet => \@fleet,
      dimension => [$width, $height],
  );

=head1 DESCRIPTION

A C<Game::Battleship::Grid> object represents a Battleship playing
surface complete with fleet position references and line intersection
collision detection.

=head1 NAME

Game::Battleship::Grid - A Battleship grid class

=head1 PUBLIC METHODS

=head2 B<new> %ARGUMENTS

=over 4

=item * fleet => [$CRAFT_1, $CRAFT_2, ... $CRAFT_N]

Optional array reference of an unlimited number of
C<Game::Battleship::Craft> objects.

If provided, the fleet will be placed on the grid with random but
non-overlapping positions.

Naturally, it is required that the combined sizes of the ships be
less than the area of the grid.

=item * dimension => [$WIDTH, $HEIGHT]

Optional array reference with the grid height and width values.

If not provided, the standard ten by ten playing surface is used.

=back

=head2 B<BUILD>

Setup

=head1 PRIVATE FUNCTIONS

=over 4

=item B<_tail_coordinates> @COORDINATES, $SPAN

  ($orientation, $x1, $y1) = _tail_coordinates($x0, $y0, $span);

Return a vector for the craft.  That is, hand back the vertical or
horizontal line segment orientation and the tail coordinates based on
the head coordinates and the length of the segment (i.e. the craft).

=item B<_segment_intersection> @COORDINATES

  $intersect = _segment_intersection(
      p_x0, p_y0,  p_x1, p_y1,
      q_x0, q_y0,  q_x1, q_y1
  );

Return zero if there is no intersection (or touching or overlap).

Each pair of values define a coordinate and each pair of coordinates
define a line segment.

=back

=head1 TO DO

Allow diagonal craft placement.

Allow placement restriction rules (e.g. not on edges, not adjacent,
etc.) as an arrayref of boundary equations or regular expressions.

Allow some type of interactive craft re-positioning.

Allow > 2D playing spaces.

=head1 SEE ALSO

L<Game::Battleship>,
L<Game::Battleship::Craft>

Segment intersection:

C<http://www.meca.ucl.ac.be/~wu/FSA2716/Exercise1.htm>

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

See L<Game::Battleship>.

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

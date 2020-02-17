# -*- Perl -*-
#
# raycast field-of-view and related routines (see also the *.xs file)

package Game::RaycastFOV;

our $VERSION = '1.00';

use strict;
use warnings;
use Exporter 'import';
use Math::Trig ':pi';
require XSLoader;

our @EXPORT_OK =
  qw(bypair cached_circle circle line raycast swing_circle %circle_points);

XSLoader::load('Game::RaycastFOV', $VERSION);

# precomputed via swing_circle(). only up to 11 due to 80x24 terminal.
# can be added to or changed as desired by caller. one could for example
# have a 0 radius that only fills in the compass directions adjacent or
# other shapes suitable to the need at hand
#
# NOTE these may change to be more efficient at doing a minimally
# complete raycast instead of the complete exterior circle (which
# probably creates more raycasts than may be necessary)
our %circle_points = (
    1 => [ 1, 0, 1, 1, 0, 1, -1, 1, -1, 0, -1, -1, 0, -1, 1, -1 ],
    2 => [
        2,  0, 2,  1,  1,  1,  1,  2,  0, 2,  -1, 2,  -1, 1,  -2, 1,
        -2, 0, -2, -1, -1, -1, -1, -2, 0, -2, 1,  -2, 1,  -1, 2,  -1
    ],
    3 => [
        3,  0,  3,  1,  2,  1,  2,  2,  1,  2,  1,  3,  0,  3,  -1, 3,
        -1, 2,  -2, 2,  -2, 1,  -3, 1,  -3, 0,  -3, -1, -2, -1, -2, -2,
        -1, -2, -1, -3, 0,  -3, 1,  -3, 1,  -2, 2,  -2, 2,  -1, 3,  -1
    ],
    4 => [
        4,  0,  4,  1,  4,  2,  3,  2,  3,  3,  2,  3,  2,  4,  1,  4,
        0,  4,  -1, 4,  -2, 4,  -2, 3,  -3, 3,  -3, 2,  -4, 2,  -4, 1,
        -4, 0,  -4, -1, -4, -2, -3, -2, -3, -3, -2, -3, -2, -4, -1, -4,
        0,  -4, 1,  -4, 2,  -4, 2,  -3, 3,  -3, 3,  -2, 4,  -2, 4,  -1
    ],
    5 => [
        5,  0,  5,  1,  5,  2,  4,  2,  4,  3,  3,  3,  3,  4,  2,  4,
        2,  5,  1,  5,  0,  5,  -1, 5,  -2, 5,  -2, 4,  -3, 4,  -3, 3,
        -4, 3,  -4, 2,  -5, 2,  -5, 1,  -5, 0,  -5, -1, -5, -2, -4, -2,
        -4, -3, -3, -3, -3, -4, -2, -4, -2, -5, -1, -5, 0,  -5, 1,  -5,
        2,  -5, 2,  -4, 3,  -4, 3,  -3, 4,  -3, 4,  -2, 5,  -2, 5,  -1
    ],
    6 => [
        6,  0,  6,  1,  6,  2,  5,  2,  5,  3,  5,  4,  4,  4,  4,  5,
        3,  5,  2,  5,  2,  6,  1,  6,  0,  6,  -1, 6,  -2, 6,  -2, 5,
        -3, 5,  -4, 5,  -4, 4,  -5, 4,  -5, 3,  -5, 2,  -6, 2,  -6, 1,
        -6, 0,  -6, -1, -6, -2, -5, -2, -5, -3, -5, -4, -4, -4, -4, -5,
        -3, -5, -2, -5, -2, -6, -1, -6, 0,  -6, 1,  -6, 2,  -6, 2,  -5,
        3,  -5, 4,  -5, 4,  -4, 5,  -4, 5,  -3, 5,  -2, 6,  -2, 6,  -1
    ],
    7 => [
        7,  0,  7,  1,  7,  2,  6,  2,  6,  3,  6,  4,  5,  4,  5,  5,
        4,  5,  4,  6,  3,  6,  2,  6,  2,  7,  1,  7,  0,  7,  -1, 7,
        -2, 7,  -2, 6,  -3, 6,  -4, 6,  -4, 5,  -5, 5,  -5, 4,  -6, 4,
        -6, 3,  -6, 2,  -7, 2,  -7, 1,  -7, 0,  -7, -1, -7, -2, -6, -2,
        -6, -3, -6, -4, -5, -4, -5, -5, -4, -5, -4, -6, -3, -6, -2, -6,
        -2, -7, -1, -7, 0,  -7, 1,  -7, 2,  -7, 2,  -6, 3,  -6, 4,  -6,
        4,  -5, 5,  -5, 5,  -4, 6,  -4, 6,  -3, 6,  -2, 7,  -2, 7,  -1
    ],
    8 => [
        8,  0,  8,  1,  8,  2,  7,  2,  7,  3,  7,  4,  6,  4,  6,  5,
        6,  6,  5,  6,  4,  6,  4,  7,  3,  7,  2,  7,  2,  8,  1,  8,
        0,  8,  -1, 8,  -2, 8,  -2, 7,  -3, 7,  -4, 7,  -4, 6,  -5, 6,
        -6, 6,  -6, 5,  -6, 4,  -7, 4,  -7, 3,  -7, 2,  -8, 2,  -8, 1,
        -8, 0,  -8, -1, -8, -2, -7, -2, -7, -3, -7, -4, -6, -4, -6, -5,
        -6, -6, -5, -6, -4, -6, -4, -7, -3, -7, -2, -7, -2, -8, -1, -8,
        0,  -8, 1,  -8, 2,  -8, 2,  -7, 3,  -7, 4,  -7, 4,  -6, 5,  -6,
        6,  -6, 6,  -5, 6,  -4, 7,  -4, 7,  -3, 7,  -2, 8,  -2, 8,  -1
    ],
    9 => [
        9,  0,  9,  1,  9,  2,  9,  3,  8,  3,  8,  4,  8,  5,  7,  5,
        7,  6,  6,  6,  6,  7,  5,  7,  5,  8,  4,  8,  3,  8,  3,  9,
        2,  9,  1,  9,  0,  9,  -1, 9,  -2, 9,  -3, 9,  -3, 8,  -4, 8,
        -5, 8,  -5, 7,  -6, 7,  -6, 6,  -7, 6,  -7, 5,  -8, 5,  -8, 4,
        -8, 3,  -9, 3,  -9, 2,  -9, 1,  -9, 0,  -9, -1, -9, -2, -9, -3,
        -8, -3, -8, -4, -8, -5, -7, -5, -7, -6, -6, -6, -6, -7, -5, -7,
        -5, -8, -4, -8, -3, -8, -3, -9, -2, -9, -1, -9, 0,  -9, 1,  -9,
        2,  -9, 3,  -9, 3,  -8, 4,  -8, 5,  -8, 5,  -7, 6,  -7, 6,  -6,
        7,  -6, 7,  -5, 8,  -5, 8,  -4, 8,  -3, 9,  -3, 9,  -2, 9,  -1
    ],
    10 => [
        10,  0,   10,  1,   10,  2,   10,  3,   9,   3,   9,   4,   9,   5,
        8,   5,   8,   6,   7,   6,   7,   7,   6,   7,   6,   8,   5,   8,
        5,   9,   4,   9,   3,   9,   3,   10,  2,   10,  1,   10,  0,   10,
        -1,  10,  -2,  10,  -3,  10,  -3,  9,   -4,  9,   -5,  9,   -5,  8,
        -6,  8,   -6,  7,   -7,  7,   -7,  6,   -8,  6,   -8,  5,   -9,  5,
        -9,  4,   -9,  3,   -10, 3,   -10, 2,   -10, 1,   -10, 0,   -10, -1,
        -10, -2,  -10, -3,  -9,  -3,  -9,  -4,  -9,  -5,  -8,  -5,  -8,  -6,
        -7,  -6,  -7,  -7,  -6,  -7,  -6,  -8,  -5,  -8,  -5,  -9,  -4,  -9,
        -3,  -9,  -3,  -10, -2,  -10, -1,  -10, 0,   -10, 1,   -10, 2,   -10,
        3,   -10, 3,   -9,  4,   -9,  5,   -9,  5,   -8,  6,   -8,  6,   -7,
        7,   -7,  7,   -6,  8,   -6,  8,   -5,  9,   -5,  9,   -4,  9,   -3,
        10,  -3,  10,  -2,  10,  -1
    ],
    11 => [
        11,  0,   11,  1,   11,  2,   11,  3,   10,  3,   10,  4,   10,  5,
        9,   5,   9,   6,   9,   7,   8,   7,   8,   8,   7,   8,   7,   9,
        6,   9,   5,   9,   5,   10,  4,   10,  3,   10,  3,   11,  2,   11,
        1,   11,  0,   11,  -1,  11,  -2,  11,  -3,  11,  -3,  10,  -4,  10,
        -5,  10,  -5,  9,   -6,  9,   -7,  9,   -7,  8,   -8,  8,   -8,  7,
        -9,  7,   -9,  6,   -9,  5,   -10, 5,   -10, 4,   -10, 3,   -11, 3,
        -11, 2,   -11, 1,   -11, 0,   -11, -1,  -11, -2,  -11, -3,  -10, -3,
        -10, -4,  -10, -5,  -9,  -5,  -9,  -6,  -9,  -7,  -8,  -7,  -8,  -8,
        -7,  -8,  -7,  -9,  -6,  -9,  -5,  -9,  -5,  -10, -4,  -10, -3,  -10,
        -3,  -11, -2,  -11, -1,  -11, 0,   -11, 1,   -11, 2,   -11, 3,   -11,
        3,   -10, 4,   -10, 5,   -10, 5,   -9,  6,   -9,  7,   -9,  7,   -8,
        8,   -8,  8,   -7,  9,   -7,  9,   -6,  9,   -5,  10,  -5,  10,  -4,
        10,  -3,  11,  -3,  11,  -2,  11,  -1
    ]
);

# the lack of checks are for speed, use at your own risk
sub cached_circle (&$$$) {
    my ($callback, $x, $y, $radius) = @_;
    bypair(sub { $callback->($x + $_[0], $y + $_[1]) },
        @{ $circle_points{$radius} });
}

sub raycast {
    my ($circle_cb, $line_cb, $x, $y, @rest) = @_;
    $circle_cb->(
        sub { line($line_cb, $x, $y, $_[0], $_[1]) },
        $x, $y, @rest
    );
}

sub swing_circle (&$$$$) {
    my ($callback, $x, $y, $radius, $swing) = @_;
    my $angle = 0;
    my $rf    = 0.5 + int $radius;
    my %seen;
    while ($angle < pi2) {
        my $nx = $x + int($rf * cos $angle);
        my $ny = $y + int($rf * sin $angle);
        $callback->($nx, $ny) unless $seen{ $nx . ',' . $ny }++;
        $angle += $swing;
    }
}

1;
__END__

=head1 NAME

Game::RaycastFOV - raycast field-of-view and related routines

=head1 SYNOPSIS

  use Game::RaycastFOV qw(bypair circle line);

  bypair( { my ($x,$y) = @_; ... } $x1, $y1, $x2, $y2, ...);

  # Bresenham in XS
  circle( { my ($cx,$cy) = @_; ... } $x, $y, $radius);
  line(   { my ($lx,$ly) = @_; ... } $x0, $y0, $x1, $y1);

  raycast( \&circle, sub { ... }, $x, $y, ...);

  # alternative (faster, slower) circle constructions
  cached_circle( { my ($cx,$cy) ... } $x, $y, $radius)
  swing_circle(  { my ($cx,$cy) ... } $x, $y, $radius, $swing);

=head1 DESCRIPTION

This module contains various subroutines for fast integer calculation of
lines and circles (and a slow one, too) that help perform Field Of View
(FOV) calculations to show what cells are visible from a given cell via
raycasting out from that cell. Raycasting visits adjacent squares lots
especially as the FOV grows so will benefit from caching and more
closed-in than open level layouts.

=head2 Raycast Explained in One Thousand Words or Less

         .#.##
       .##.#####                 #
      #.##..##...                #.
     .##.#.##.#...               #.
     #####..#.####             # #.
    .#.#.#.###.##..            #.#.##
    ####....#.##...            #....#
    ##...#.@#....##              #.@#
    #..#.###....#.#              ###..
    .##.#####..#...                 #..
     .##...####.##                   ##.#
     ....#.###.#..                      .
      ###.###.#..
       .######.#
         ....#

=head1 FUNCTIONS

=over 4

=item B<bypair> I<callback> I<...>

Utility function for slicing up an arbitrary list pairwise. Sort of like
C<pairwise> of L<List::Util> only in a void context, and that returning
the value C<-1> from the I<callback> subroutine will abort the
processing of subsequent items in the input list.

=item B<cached_circle> I<callback> I<x> I<y> I<radius>

This routine looks up the I<radius> in the C<%circle_points> variable
(which can be modified by users of this module) to obtain a pre-computed
list of circle points that are fed to the I<callback> as is done for the
B<circle> call.

Will silently do nothing if the I<radius> is not found in the cache.
This is by design so that B<cached_circle> is fast.

NOTE these cached points may change without notice; applications should
if necessary set their own specific sets of points to use.

=item B<circle> I<callback> I<x> I<y> I<radius>

Bresenham circle via fast integer math. Note that this may not produce a
completely filled-in FOV at various radius. Also note that this call
will produce duplicate values for various points, especially for small
I<radius>.

=item B<line> I<callback> I<x0> I<y0> I<x1> I<y1>

Bresenham line via fast integer math. Returning the value C<-1> from the
I<callback> subroutine will abort the processing of the line at the
given point.

=item B<raycast> I<circle-fn> I<point-fn> I<x> I<y> I<...>

Given a I<circle-fn> such as B<circle> or B<swing_circle>, the
B<raycast> calls B<line> between I<x> and I<y> and the points returned
by the circle function; B<line> in turn will call the user-supplied
B<point-fn> to handle what should happen at each raycasted point.
Additional arguments I<...> will be passed to the I<circle-fn> following
I<x> and I<y> (the center of the circle. L</"EXAMPLES"> may be of more help?

=item B<swing_circle> I<callback> I<x0> I<y0> I<radius> I<swing>

Constructs points around the given I<radius> by rotating a ray by
I<swing> radians over a complete circle. Smaller I<swing> values will
result in a more complete circle at the cost of additional CPU and
memory use.

B<cached_circle> uses values pre-computed from this call but only for
specific I<radius>.

=back

=head1 EXAMPLES

See also the C<eg/> directory of this module's distribution.

L<https://github.com/thrig/ministry-of-silly-vaults/> has a FOV
subdirectory with example scripts.

  use Game::RaycastFOV qw(circle raycast swing_circle);
  use Math::Trig 'deg2rad';

  # to only draw within the map area
  our $MAX_X = 79;
  our $MAX_Y = 23;

  # assuming a rows/columns array-of-arrays with characters
  our @map = ( ... );
  sub plot { ... }
  my ($x, $y, $radius) = ...;

  raycast(
    \&circle, sub {
      my ($lx, $ly) = @_;
      # whoops line has wandered outside of map
      return -1 if $lx < 0 or $lx > $MAX_X
                or $ly < 0 or $ly > $MAX_Y;
      # may instead build up a string to print to terminal
      my $ch = $map[$ly][$lx];
      plot($lx, $ly, $ch);
      # abort the line if FOV is blocked
      return -1 if $ch eq '#';
    }, $x, $y, $radius
  );

  # or instead using swing_circle
  raycast(
    \&swing_circle, sub {
      my ($lx, $ly) = @_;
      return -1 if $lx < 0 or $lx > $MAX_X
                or $ly < 0 or $ly > $MAX_Y;
      my $ch = $map[$ly][$lx];
      plot($lx, $ly, $ch);
      return -1 if $ch eq '#';
    }, $x, $y, $radius, deg2rad(5)      # different arguments!
  );

The B<plot> routine should cache whether something has been printed to
the given cell to avoid repeated terminal or display updates.

=head1 BUGS

or patches might best be applied towards

L<https://github.com/thrig/Game-RaycastFOV>

=head1 SEE ALSO

L<List::Util>, L<NetHack::FOV>

L<https://github.com/thrig/ministry-of-silly-vaults/>

There are other FOV algorithms and implementations to be found on
the Internet.

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jeremy.mates at gmail.com> >>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Jeremy Mates.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

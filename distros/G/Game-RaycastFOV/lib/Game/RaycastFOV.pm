# -*- Perl -*-
#
# raycast and shadowcast field-of-view and related routines (see also
# the *.xs file)

package Game::RaycastFOV;

our $VERSION = '2.02';

use strict;
use warnings;
use Math::Trig ':pi';

require XSLoader;

use base qw(Exporter);
our @EXPORT_OK =
  qw(bypair bypairall cached_circle circle line raycast shadowcast sub_circle swing_circle %circle_points);

XSLoader::load( 'Game::RaycastFOV', $VERSION );

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
        9,  0,  9,  1,  9,  2,  9,  3,  8,  3,  8,  4,  8,  5,  7,  5,  7,  6,
        6,  6,  6,  7,  5,  7,  5,  8,  4,  8,  3,  8,  3,  9,  2,  9,  1,  9,
        0,  9,  -1, 9,  -2, 9,  -3, 9,  -3, 8,  -4, 8,  -5, 8,  -5, 7,  -6, 7,
        -6, 6,  -7, 6,  -7, 5,  -8, 5,  -8, 4,  -8, 3,  -9, 3,  -9, 2,  -9, 1,
        -9, 0,  -9, -1, -9, -2, -9, -3, -8, -3, -8, -4, -8, -5, -7, -5, -7, -6,
        -6, -6, -6, -7, -5, -7, -5, -8, -4, -8, -3, -8, -3, -9, -2, -9, -1, -9,
        0,  -9, 1,  -9, 2,  -9, 3,  -9, 3,  -8, 4,  -8, 5,  -8, 5,  -7, 6,  -7,
        6,  -6, 7,  -6, 7,  -5, 8,  -5, 8,  -4, 8,  -3, 9,  -3, 9,  -2, 9,  -1
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
    my ( $callback, $x, $y, $radius ) = @_;
    # process all the points on the assumption that the callback will
    # abort say line drawing should that wander outside a level map
    bypairall( sub { $callback->( $x + $_[0], $y + $_[1] ) },
        @{ $circle_points{$radius} } );
}

sub raycast {
    my ( $circle_cb, $line_cb, $x, $y, @rest ) = @_;
    $circle_cb->( sub { line( $line_cb, $x, $y, $_[0], $_[1] ) }, $x, $y, @rest );
}

# http://www.roguebasin.com/index.php?title=FOV_using_recursive_shadowcasting
# or in particular the Java and Ruby implementations
sub shadowcast {
    my ( $startx, $starty, $radius, $bcb, $lcb, $rcb ) = @_;
    $lcb->( $startx, $starty, 0, 0 );
    for my $mult (
        [ 1,  0,  0,  1 ],
        [ 0,  1,  1,  0 ],
        [ 0,  -1, 1,  0 ],
        [ -1, 0,  0,  1 ],
        [ -1, 0,  0,  -1 ],
        [ 0,  -1, -1, 0 ],
        [ 0,  1,  -1, 0 ],
        [ 1,  0,  0,  -1 ]
    ) {
        _shadowcast( $startx, $starty, $radius, $bcb, $lcb, $rcb, 1, 1.0, 0.0, @$mult );
    }
}

sub _shadowcast {
    my ( $startx, $starty, $radius, $bcb, $lcb, $rcb, $row, $light_start,
        $light_end, $xx, $xy, $yx, $yy )
      = @_;
    my $blocked   = 0;
    my $new_start = 0.0;
    for my $j ( $row .. $radius ) {
        my $dy = -$j;
        for my $dx ( $dy .. 0 ) {
            my $rslope = ( $dx + 0.5 ) / ( $dy - 0.5 );
            my $lslope = ( $dx - 0.5 ) / ( $dy + 0.5 );
            if    ( $light_start < $rslope ) { next }
            elsif ( $light_end > $lslope )   { last }
            my $curx = $startx + $dx * $xx + $dy * $xy;
            my $cury = $starty + $dx * $yx + $dy * $yy;
            $lcb->( $curx, $cury, $dx, $dy ) if $rcb->( $dx, $dy );
            if ($blocked) {
                if ( $bcb->( $curx, $cury, $dx, $dy ) ) {
                    $new_start = $rslope;
                    next;
                } else {
                    $blocked     = 0;
                    $light_start = $new_start;
                }
            } else {
                if ( $bcb->( $curx, $cury, $dx, $dy ) and $j < $radius ) {
                    $blocked = 1;
                    _shadowcast(
                        $startx, $starty, $radius,      $bcb,    $lcb,
                        $rcb,    $j + 1,  $light_start, $lslope, $xx,
                        $xy,     $yx,     $yy
                    ) unless $light_start < $lslope;
                    $new_start = $rslope;
                }
            }
        }
        last if $blocked;
    }
}

sub swing_circle(&$$$$) {
    push @_, 0, pi2;
    goto &sub_circle;
}

# for reference; converted to XS in version 2.02 with the following
# matching and updated code not being quite so stupid about rounding
# ints and thus not needing a plus 0.5 fudge factor
#sub swing_circle (&$$$$) {
#    my ( $callback, $x, $y, $radius, $swing ) = @_;
#    my $angle = 0;
#    my %seen;
#    while ( $angle < pi2 ) {
#        my $nx = $x + sprintf( "%.0f", $radius * cos $angle );
#        my $ny = $y + sprintf( "%.0f", $radius * sin $angle );
#        $callback->( $nx, $ny ) unless $seen{ $nx . ',' . $ny }++;
#        $angle += $swing;
#    }
#}

1;
__END__

=head1 NAME

Game::RaycastFOV - raycast field-of-view and related routines

=head1 SYNOPSIS

  use Game::RaycastFOV qw(
    bypair circle line
    cached_circle swing_circle
    raycast shadowcast
  );

  # mostly internal utility routine
  bypair( { my ($x,$y) = @_; ... } $x1, $y1, $x2, $y2, ... );

  # Bresenham in XS
  circle( { my ($cx,$cy) = @_; ... } $x, $y, $radius );
  line(   { my ($lx,$ly) = @_; ... } $x, $y, $x1, $y1 );

  # fast, slower circle constructions
  cached_circle( { my ($cx,$cy) ... } $x, $y, $radius );
  swing_circle(  { my ($cx,$cy) ... } $x, $y, $radius, $swing );

  # complicated, see docs and examples
  raycast( \&circle, sub { ... }, $x, $y, ... );
  shadowcast( ... );

=head1 DESCRIPTION

This module contains various subroutines that perform fast calculation
of lines and circles; these in turn help with Field Of View (FOV)
calculations. Raycasting and shadowcasting FOV calls are provided.

Speed is favored over error checking; the XS code may not work for large
integer values; etc.

=head2 Raycasting Explained in One Thousand Words or Less

         .#.##
       .##.#####                 #
      #.##..##...                #.
     .##.#.##.#...               #.
     #####..#.####             # #.
    .#.#.#.###.##..            #.#.##
    ####....#.##...            #....#
    ##...#.@#T...##              #.@#
    #..#.###....#.#              ###..
    .##.#####..#...                 #..
     .##...####.##                   ##.#
     ....#.###.#..                      .
      ###.###.#..
       .######.#
         ....#

Will our plucky hero stumble into that Troll unseen? Tune in next week!

=head1 FUNCTIONS

=over 4

=item B<bypair> I<callback> I<...>

Utility function for slicing up an arbitrary list pairwise. Sort of like
C<pairwise> of L<List::Util> only in a void context, and that returning
the value C<-1> from the I<callback> subroutine will abort the
processing of subsequent items.

=item B<bypairall> I<callback> I<...>

Like B<bypair> but does not include code to abort processing the list.

Since v1.01.

=item B<cached_circle> I<callback> I<x> I<y> I<radius>

This routine looks up the I<radius> in the C<%circle_points> variable
(which is available for export and can be modified as need be) to obtain
a pre-computed list of circle points (calculated by B<swing_circle>)
that are fed to the I<callback> as is done for the B<circle> call.

Will silently do nothing if the I<radius> is not found in the cache.
This is by design so that B<cached_circle> is fast.

The cached points might (but are unlikely to) change without notice;
calling code if paranoid should set specific sets of points to use or
require a specific version of this module.

=item B<circle> I<callback> I<x> I<y> I<radius>

Bresenham circle. Note that this may not produce a completely filled-in
FOV at various radius.

Since version 2.02 only unique points are passed to the I<callback>.

=item B<line> I<callback> I<x0> I<y0> I<x1> I<y1>

Bresenham line. Returning the value C<-1> from the I<callback>
subroutine will abort the processing of the line at the given point.

=item B<raycast> I<circle-fn> I<point-fn> I<x> I<y> I<...>

Given a I<circle-fn> such as B<circle> or B<swing_circle> and the center
of a circle given by I<x> and I<y>, the B<raycast> calls B<line> between
I<x>,I<y> and the points returned by the circle function; B<line> in
turn will call the user-supplied B<point-fn> to handle what should
happen at each raycasted point. Additional arguments I<...> will be
passed to the I<circle-fn> following I<x> and I<y>.

L</"EXAMPLES"> may be of more help than the above text.

=item B<shadowcast> I<x> I<y> I<radius> I<blockcb> I<litcb> I<radiuscb>

Performs a shadowcast FOV calculation of the given I<radius> around the
point I<x>, I<y>. Callbacks:

=over 4

=item *

I<blockcb> is called with I<newx>, I<newy> (the point shadowcasting has
reached), I<deltax>, and I<deltay> (the delta from the origin for the
point). It return a boolean indicating whether that coordinate is
blocked on the level map (e.g. by a wall, a large monster, or maybe the
angle from the starting point is no good, etc).

The I<deltax> and I<deltay> values are only passed in module version
2.02 or higher.

=item *

I<litcb> is called with I<newx>, I<newy>, I<deltax>, and I<deltay> and
should do whatever needs to be done to present that point as visible.

=item *

I<radiuscb> is passed I<deltax>, I<deltay>, and I<radius> and must
return true if the deltas are within the radius. This allows for
different FOV shapes. The delta values could be negative so will need to
be run through C<abs> or C<** 2> to determine the distance.

=back

B<The callbacks may be called with points outside of a level map>.

=item B<sub_circle> I<callback> I<x0> I<y0> I<radius> I<swing> I<start-angle> I<max-angle>

Finds points around the given I<radius> by rotating a ray by I<swing>
radians starting from I<start-angle> and ending at I<max-angle>. Smaller
I<swing> values will result in a more complete circle at the cost of
additional CPU and memory use. Each unique point is passed to the
I<callback> function:

  sub_circle( sub { my ($newx, $newy) = @_; ... }, ... );

Has limited to no error checking; the caller should ensure that the
I<swing> value is positive, etc.

Since version 2.02.

=item B<swing_circle> I<callback> I<x0> I<y0> I<radius> I<swing>

Calls B<sub_circle> with a starting angle of C<0> and a max angle of
C<pi * 2>.

Prior to version 2.02 used distinct code.

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
  # something that updates the @map
  sub plot { ... }
  # where the FOV happens and how big it is
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

The B<plot> routine may need to cache whether something has been printed
to the given cell as B<raycast> likes to revisit cells a lot, especially
those close to the origin that are clear of FOV-blocking obstacles.

=head1 BUGS

or patches might best be applied towards

L<https://github.com/thrig/Game-RaycastFOV>

=head1 SEE ALSO

L<Game::Xomb> uses modified code from this module.

L<NetHack::FOV>

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

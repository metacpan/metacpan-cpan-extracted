# -*- Perl -*-
#
# a numeric grid of weights plus some related functions
#
# run perldoc(1) on this file for additional documentation

package Game::DijkstraMap;

use 5.010000;
use strict;
use warnings;

use Carp qw(croak);
use List::Util qw(shuffle);
use Moo;
use namespace::clean;
use Scalar::Util qw(looks_like_number);

our $VERSION = '0.04';

has max_cost => ( is => 'rw', default => sub { ~0 } );
has min_cost => ( is => 'rw', default => sub { 0 } );
has bad_cost => ( is => 'rw', default => sub { -1 } );
has costfn   => (
    is      => 'rw',
    default => sub {
        return sub {
            my ( $self, $c ) = @_;
            if ( $c eq '#' ) { return $self->bad_cost }
            if ( $c eq 'x' ) { return $self->min_cost }
            return $self->max_cost;
        };
    },
);
has dimap => ( is => 'rw', );
has iters => ( is => 'rwp', default => sub { 0 } );

sub map {
    my ( $self, $map ) = @_;
    my $dimap = [];
    croak "no valid map supplied"
      if !defined $map
      or ref $map ne 'ARRAY'
      or !defined $map->[0]
      or ref $map->[0] ne 'ARRAY';
    my $cols = @{ $map->[0] };
    for my $r ( 0 .. $#$map ) {
        croak "unexpected column count at row $r" if @{ $map->[$r] } != $cols;
        for my $c ( 0 .. $cols - 1 ) {
            $dimap->[$r][$c] = $self->costfn->( $self, $map->[$r][$c] );
        }
    }
    $self->normalize_costs($dimap);
    $self->dimap($dimap);
    return $self;
}

sub next {
    my ( $self, $r, $c ) = @_;
    my $dimap = $self->dimap;
    croak "cannot pathfind on unset map" if !defined $dimap;
    my $maxrow = $#$dimap;
    my $maxcol = $#{ $dimap->[0] };
    croak "row $r out of bounds" if $r > $maxrow or $r < 0;
    croak "col $c out of bounds" if $c > $maxcol or $c < 0;
    my @adj;
    my $value = $dimap->[$r][$c];
    return @adj if $value <= $self->min_cost;

    for my $i ( -1, 1 ) {
        my $x = $c + $i;
        push @adj, [ [ $r, $x ], $dimap->[$r][$x] ] if $x >= 0 and $x <= $maxcol;
        for my $j ( -1 .. 1 ) {
            $x = $r + $i;
            my $y = $c + $j;
            push @adj, [ [ $x, $y ], $dimap->[$x][$y] ]
              if $x >= 0
              and $x <= $maxrow
              and $y >= 0
              and $y <= $maxcol;
        }
    }
    my $badcost = $self->bad_cost;
    return grep { $_->[1] < $value and $_->[1] != $badcost } @adj;
}

sub next_best {
    my ( $self, $r, $c, $method ) = @_;
    $method //= 'next';
    my @ret = sort { $a->[1] <=> $b->[1] } shuffle $self->$method( $r, $c );
    return $ret[0]->[0];
}

# next() but only in square directions or "orthogonal" (but diagonals
# are orthogonal to one another) or in the "cardinal directions" (NSEW)
# but that term also seems unsatisfactory
sub next_sq {
    my ( $self, $r, $c ) = @_;
    my $dimap = $self->dimap;
    croak "cannot pathfind on unset map" if !defined $dimap;
    my $maxrow = $#$dimap;
    my $maxcol = $#{ $dimap->[0] };
    croak "row $r out of bounds" if $r > $maxrow or $r < 0;
    croak "col $c out of bounds" if $c > $maxcol or $c < 0;
    my @adj;
    my $value = $dimap->[$r][$c];
    return @adj if $value <= $self->min_cost;

    if ( $c > 0 ) {
        push @adj, [ [ $r, $c - 1 ], $dimap->[$r][ $c - 1 ] ];
    }
    if ( $c < $maxcol ) {
        push @adj, [ [ $r, $c + 1 ], $dimap->[$r][ $c + 1 ] ];
    }
    if ( $r > 0 ) {
        push @adj, [ [ $r - 1, $c ], $dimap->[ $r - 1 ][$c] ];
    }
    if ( $r < $maxrow ) {
        push @adj, [ [ $r + 1, $c ], $dimap->[ $r + 1 ][$c] ];
    }

    my $badcost = $self->bad_cost;
    return grep { $_->[1] < $value and $_->[1] != $badcost } @adj;
}

sub normalize_costs {
    my ( $self, $dimap ) = @_;
    my $badcost = $self->bad_cost;
    my $maxcost = $self->max_cost;
    my $iters   = 0;
    while (1) {
        my $stable = 1;
        $iters++;
        my $maxrow = $#$dimap;
        my $maxcol = $#{ $dimap->[0] };
        for my $r ( 0 .. $maxrow ) {
            for my $c ( 0 .. $maxcol ) {
                my $value = $dimap->[$r][$c];
                next if $value == $badcost;
                my $min = $maxcost;
                my $tmp;
                if ( $c > 0 ) {
                    $tmp = $dimap->[$r][ $c - 1 ];
                    $min = $tmp if $tmp != $badcost and $tmp < $min;
                }
                if ( $c < $maxcol ) {
                    $tmp = $dimap->[$r][ $c + 1 ];
                    $min = $tmp if $tmp != $badcost and $tmp < $min;
                }
                if ( $r > 0 ) {
                    $tmp = $dimap->[ $r - 1 ][$c];
                    $min = $tmp if $tmp != $badcost and $tmp < $min;
                }
                if ( $r < $maxrow ) {
                    $tmp = $dimap->[ $r + 1 ][$c];
                    $min = $tmp if $tmp != $badcost and $tmp < $min;
                }
                if ( $value > $min + 2 ) {
                    $dimap->[$r][$c] = $min + 1;
                    $stable = 0;
                }
            }
        }
        last if $stable;
    }
    $self->_set_iters($iters);
    return $self;
}

sub path_best {
    my ( $self, $r, $c, $method ) = @_;
    my @path;
    while ( my $next = $self->next_best( $r, $c, $method ) ) {
        push @path, $next;
        ( $r, $c ) = @$next;
    }
    return \@path;
}

sub recalc {
    my ($self) = @_;
    my $dimap = $self->dimap;
    croak "cannot recalc unset map" if !defined $dimap;
    my $maxcost = $self->max_cost;
    my $mincost = $self->min_cost;
    my $maxcol  = $#{ $dimap->[0] };
    for my $r ( 0 .. $#$dimap ) {
        for my $c ( 0 .. $maxcol ) {
            $dimap->[$r][$c] = $maxcost if $dimap->[$r][$c] > $mincost;
        }
    }
    $self->normalize_costs($dimap);
    $self->dimap($dimap);
    return $self;
}

sub str2map {
    my ( $self_or_class, $str, $lf ) = @_;
    croak "no string given" if !defined $str;
    $lf //= $/;
    my @map;
    for my $line ( split $lf, $str ) {
        push @map, [ split //, $line ];
    }
    return \@map;
}

sub update {
    my $self  = shift;
    my $dimap = $self->dimap;
    croak "cannot update unset map" if !defined $dimap;
    my $maxrow = $#$dimap;
    my $maxcol = $#{ $dimap->[0] };
    for my $ref (@_) {
        my ( $r, $c ) = ( $ref->[0], $ref->[1] );
        croak "row $r out of bounds" if $r > $maxrow or $r < 0;
        croak "col $c out of bounds" if $c > $maxcol or $c < 0;
        croak "value must be a number" unless looks_like_number $ref->[2];
        $dimap->[$r][$c] = int $ref->[2];
    }
    $self->dimap($dimap);
    return $self;
}

1;
__END__

=head1 NAME

Game::DijkstraMap - a numeric grid of weights plus some related functions

=head1 SYNOPSIS

  use Game::DijkstraMap;
  my $dm = Game::DijkstraMap->new;

  # x is where the player is (the goal) and the rest are
  # considered as walls or floor tiles (see the costfn)
  my $level = Game::DijkstraMap->str2map(<<'EOM');
  #########
  #.h.....#
  #.#####'#
  #.#####x#
  #########
  EOM

  # create the dijkstra map
  $dm->map($level);

  # path finding is now possible
  $dm->next( 1, 2 );  # [[1,3], 6]
  $dm->next( 1, 6 );  # [[1,7], 2], [[2,7], 1]

  $dm->next_sq( 1, 6 );  # [[1,7], 2]

  $dm->next_best( 1, 6 );             # 2,7
  $dm->next_best( 1, 6, 'next_sq' );  # 1,7

  $dm->path_best( 1, 1 );
  $dm->path_best( 1, 1, 'next_sq' );

  # change the open door ' to a closed one
  $dm->update( [ 2, 7, -1 ] );
  $dm->recalc;

  $dm->next( 1, 7 );  # nowhere better to move to

=head1 DESCRIPTION

This module implements code described by "The Incredible Power of
Dijkstra Maps" article. Such maps have various uses in roguelikes or
other games. This implementation may not be fast but should allow quick
prototyping of map-building and path-finding exercises.

L<http://www.roguebasin.com/index.php?title=The_Incredible_Power_of_Dijkstra_Maps>

The L</CONSIDERATIONS> section describes what this module does in
more detail.

=head1 CONSTRUCTOR

The B<new> method accepts the L</ATTRIBUTES> in the usual L<Moo>
fashion.

=head1 ATTRIBUTES

=over 4

=item B<max_cost>

Cost for non-goal non-wall points. A large number by default. These
points should be reduced to appropriate weights (steps from the nearest
goal point) by B<normalize_costs>.

=item B<min_cost>

Cost for points that are goals (there can be multiple goals on a grid).
Zero by default.

=item B<bad_cost>

Cost for cells through which motion is illegal (walls, typically, though
a map for cats may also treat water as impassable). C<-1> by default,
and ignored when updating the map. This value for optimization purposes
is assumed to be lower than B<min_cost>.

=item B<costfn>

A code reference called with the object and each cell of the I<map>
passed to B<map>. This function must convert the contents of the cell
into suitable cost numbers for the Dijkstra Map. Defaults to a function
that assigns B<bad_cost> to C<#> (walls), B<min_cost> to C<x> (goals),
and otherwise B<max_cost> for what is assumed to be floor tiles.

If the I<map> is instead a grid of objects, there may need to be a
suitable method call in those objects that returns the cost of what the
cell contains that a custom B<costfn> then calls.

=item B<dimap>

The Dijkstra Map, presently an array reference of array references of
integer values. Do not change this reference unless you know what you
are doing. It can also be assigned to directly, for better or worse.

Most method calls will fail if this is not set; be sure to load a level
map first with the B<map> method (or manually).

=item B<iters>

This is set after the B<map> and B<recalc> method calls and indicates
how many iterations it took B<normalize_costs> to stabilize the map.

=back

=head1 METHODS

These methods will throw exceptions if something goes awry (especially
when given known bad input, or when B<dimap> has not been set).

=over 4

=item B<map> I<map>

Accepts a level map (an array reference of array references, or a 2D
grid) and uses the B<costfn> to convert the objects in that I<map> to
the internal Dijkstra Map that is held in the B<dimap> attribute.

Returns the object so can be chained with other calls.

=item B<next> I<row> I<col>

Returns the adjacent points with lower values than the given cell. Both
square and diagonal moves are considered. The return format is a
(possibly empty) list of array references in the form of
C<[[row,col],value],...> in no order that should be relied on.

L</THE DREADED DIAGONAL> has a longer discussion of such moves.

=item B<next_best> I<row> I<col> [ I<next-method> ]

Calls B<next> (or the method named by the optional I<next-method>
argument) and returns only the coordinate of a best move as an array
reference (or C<undef> if there is no such move). The coordinates are
shuffled and then sorted by value to avoid bias from the order in which
the adjacent coordinates are iterated over internally.

=item B<next_sq> I<row> I<col>

Like B<next> but only considers non-diagonal moves.

=item B<normalize_costs> I<dimap>

Mostly an internal routine called by B<map> or B<update> that reduces
B<max_cost> cells as appropriate relative to the connected
B<min_cost> cells. Changes the B<iters> attribute.

=item B<path_best> I<row> I<col> [ I<next-method> ]

Finds a best path to a goal via repeated calls to B<next> or optionally
some other method such as C<next_sq>. Returns the path as an array
reference of array references (a reference to a list of points).

=item B<recalc>

Resets the weights of all non-wall non-goal cells and then calls
B<normalize_costs>. See below for a discussion of B<update> and
B<recalc>.

Returns the object so can be chained with other calls.

=item B<str2map> I<string> [ I<split-with> ]

Utility method that converts string maps to a form suitable to be passed
to the B<map> method. Without the optional I<split-with> argument the
string will be split into lines using C<$/>.

=item B<update> I<[row, col, value]> ..

Updates the given row and column with the given value for each array
reference passed. Does not recalculate the weights; see below for a
longer discussion.

Returns the object so can be chained with other calls.

=back

=head1 CONSIDERATIONS

Given the map where C<h> represents a hound, C<@> our doomed yet somehow
still optimistic hero, C<'> an open door, and so forth,

    012345678
  -+--------- turn 1
  0|#########
  1|#h......#
  2|#.#####'#
  3|#.#####@#
  4|#########

A Dijkstra Map with the player as the only goal would be the following
grid of integers that outline the corridor leading to the player

     0  1  2  3  4  5  6  7  8
  -+--------------------------
  0|-1|-1|-1|-1|-1|-1|-1|-1|-1
  1|-1| 8| 7| 6| 5| 4| 3| 2|-1
  2|-1| 9|-1|-1|-1|-1|-1| 1|-1
  3|-1|10|-1|-1|-1|-1|-1| 0|-1
  4|-1|-1|-1|-1|-1|-1|-1|-1|-1

which allows the hound to move towards the player by trotting down the
positive integers, or to flee by going the other way. This map may need
to be updated when the player moves or changes the map; for example the
player could close the door:

  ######### turn 2
  #..h....#
  #.#####+#
  #.#####@#
  #########

This change can be handled in various ways. A door may be as a wall to a
hound, so updated to be one

  $map->update( [ 2, 7, $map->bad_cost ] );

results in the map

     0  1  2  3  4  5  6  7  8
  -+--------------------------
  0|-1|-1|-1|-1|-1|-1|-1|-1|-1
  1|-1| 8| 7| 6| 5| 4| 3| 2|-1
  2|-1| 9|-1|-1|-1|-1|-1|-1|-1
  3|-1|10|-1|-1|-1|-1|-1| 0|-1
  4|-1|-1|-1|-1|-1|-1|-1|-1|-1

and a hound waiting outside the door, ready to spring (or maybe it gets
bored and wanders off, depending on the monster AI and how much patience
our hero has). The situation could also be handled by not updating the
map and code outside of this module handling the hound/closed door
interaction.

The B<recalc> method may be necessary where due to the closed door there
is a new and longer path around to the player that should be followed:

  #########      turn 2 (door was closed on turn 1)
  #....h..#
  #.#####+#########
  #.#####@........#
  #.#############.#
  #...............#
  #################

  $map->update(...)           # case 1
  $map->update(...)->recalc;  # case 2

Case 1 would have the hound move to the door while case 2 would instead
cause the hound to move around the long way. If the door after case 2 is
opened and only an B<update> is done, the new shorter route would only
be considered by monsters directly adjacent to the now open door (weight
path 34, 1, 0 and also 33, 1, 0 if diagonal moves are permitted) and not
those at 32, 31, etc. along the longer route; for those to see the
change of the door another B<recalc> would need to be done.

=head1 THE DREADED DIAGONAL

Treatment of diagonal moves varies. Brogue and POWDER by default
deny the player the ability to move to the lower right cell

  ####
  #..#
  #.@#
  ###.

while Angband or Dungeon Crawl Stone Soup allow the move. POWDER does
not allow the player to move diagonally to the upper left cell (unless
polymorphed) while all the others mentioned would. Also the best square
to move to could be occupied by another monster, magically conjured
flames, etc. This is why B<next> and B<next_sq> are fairly generic;
B<next_best> may not return an ideal move given other considerations.

=head1 GRID BUGS

=head2 Reporting Bugs

Please report any bugs or feature requests to
C<bug-game-dijkstramap at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-DijkstraMap>.

Patches might best be applied towards:

L<https://github.com/thrig/Game-DijkstraMap>

=head2 Known Issues

New code that is not much battle-tested.

B<normalize_costs> is not very good with long and mostly unconnected
corridors; this could be improved on by considering adjacent unseen
cells after a cell changes in addition to full map iterations.

=head1 SEE ALSO

There are various other graph and path finding modules on CPAN that may
be more suitable to the task at hand.

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

=cut

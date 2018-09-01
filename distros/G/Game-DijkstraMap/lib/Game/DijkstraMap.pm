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
use Moo;
use namespace::clean;
use Scalar::Util qw(looks_like_number);

our $VERSION = '0.01';

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
has dimap => ( is => 'rwp', );
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
    $self->_set_dimap($dimap);
    return $self;
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

sub update {
    my $self  = shift;
    my $dimap = $self->dimap;
    croak "cannot update unset map" if !defined $dimap;
    my $maxrow = $#$dimap;
    my $maxcol = $#{ $dimap->[0] };
    for my $ref (@_) {
        croak "row $ref->[0] out of bounds" if $ref->[0] > $maxrow or $ref->[0] < 0;
        croak "col $ref->[1] out of bounds" if $ref->[1] > $maxcol or $ref->[1] < 0;
        croak "value must be a number" unless looks_like_number $ref->[2];
        $dimap->[ $ref->[0] ][ $ref->[1] ] = int $ref->[2];
    }
    $self->normalize_costs($dimap);
    $self->_set_dimap($dimap);
    return $self;
}

1;
__END__

=head1 NAME

Game::DijkstraMap - a numeric grid of weights plus some related functions

=head1 SYNOPSIS

  use Game::DijkstraMap;
  my $map = Game::DijkstraMap->new;
  $map->map( [[ ... ]] );
  my $dimap = $map->dimap;

  $map->update( [ 0, 1, -1 ] );

=head1 DESCRIPTION

This module implements what the author of the "The Incredible Power of
Dijkstra Maps" article (see below) calls Dijkstra Maps. Such maps have
various uses in roguelikes or other games. This implementation may not
be particularly fast but should allow quick prototyping of map-building
and path-finding exercises.

=head1 CONSTRUCTOR

The B<new> method accepts any of the L</ATTRIBUTES>.

=head1 ATTRIBUTES

=over 4

=item B<max_cost>

Cost for non-goal non-wall points. A large number by default. These
points should be reduced by B<normalize_costs> if all goes well.

=item B<min_cost>

Cost for points that are goals. Zero by default.

=item B<bad_cost>

Cost for cells through which motion is illegal (walls, typically). C<-1>
by default, and ignored when updating the map.

=item B<costfn>

A code reference called with the object and the contents of the map
passed to B<map>. This function must convert those items into suitable
cost numbers for the internal Dijkstra Map. Defaults to a function that
assigns B<bad_cost> to C<#> and B<min_cost> to C<x>, otherwise
B<max_cost>.

=item B<dimap>

Accessor for the Dijkstra Map, presently an array reference of array
references. Do not change this reference unless you know what you
are doing.

=item B<iters>

This is set after B<map> or B<update> calls and indicates how many
iterations it took the B<normalize_costs> method to stabilize the map.

=back

=head1 METHODS

These return the object so can be chained with other calls. These
methods will throw exceptions if something goes awry (especially when
given known bad input).

=over 4

=item B<map> I<map>

Accepts a level map (an array reference of array references, or a 2D
grid) and uses the B<costfn> to convert the objects in that I<map> to
the internal Dijkstra Map that is held in the B<dimap> attribute.

=item B<normalize_costs> I<dimap>

Mostly an internal routine called by B<map> or B<update> that reduces
B<max_cost> cells as appropriate relative to the connected
B<min_cost> cells.

=item B<update> I<[row, col, value]> ..

Updates the given row and column with the given value for each array
reference passed then updates the Dijkstra Map.

=back

=head1 BUGS

=head2 Reporting Bugs

Please report any bugs or feature requests to
C<bug-game-dijkstramap at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-DijkstraMap>.

Patches might best be applied towards:

L<https://github.com/thrig/Game-DijkstraMap>

=head2 Known Issues

New code. In particular the B<update> method will need a different
interface or an attribute to handle two different possibilities, see the
commentary in the test code. Also need to add path finding (routes) and
next cell (steps along routes) methods.

=head1 SEE ALSO

The code in this module is based on the following article (as of
August 2018):

L<http://www.roguebasin.com/index.php?title=The_Incredible_Power_of_Dijkstra_Maps>

There are various other graph and pathfinding modules on CPAN that may
be more suitable to the task at hand.

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

=cut

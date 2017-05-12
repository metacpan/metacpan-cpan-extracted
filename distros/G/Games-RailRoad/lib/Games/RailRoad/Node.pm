# 
# This file is part of Games-RailRoad
# 
# This software is copyright (c) 2008 by Jerome Quelin.
# 
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# 
use 5.010;
use strict;
use warnings;

package Games::RailRoad::Node;
BEGIN {
  $Games::RailRoad::Node::VERSION = '1.101330';
}
# ABSTRACT: a node object

use Moose;
use MooseX::Has::Sugar;
use MooseX::SemiAffordanceAccessor;
use UNIVERSAL::require;


# -- attributes


has position => ( ro, isa=>'Games::RailRoad::Vector', required );


# -- constructor & initializers


# provided by moose


# -- public methods


sub connect {
    my ($self, $dir) = @_;

    # check if the node can be extended in the wanted $dir.
    my $map = $self->_transform_map;
    return unless exists $map->{$dir};

    # rebless the object in its new class.
    $map->{$dir}->require;
    bless $self, $map->{$dir};

    # initialize switch if needed.
    # FIXME: shouldn't it be it GRN:Switch:_init with an inconditional
    #        call to _init?
    if ( $self->isa('Games::RailRoad::Node::Switch')
        && not defined $self->_switch ) {
        $self->_switch(0);
    }
}



sub connectable {
    my ($self, $dir) = @_;
    my $map = $self->_transform_map;
    return exists $map->{$dir};
}



sub connections {
    my ($self) = @_;
    my $pkg = ref $self;
    return () if $pkg eq 'Games::RailRoad::Node';
    $pkg =~ s/^.*:://;
    return map { lc $_ } split /_/, $pkg;
}



sub delete {
    my ($self, $canvas) = @_;
    my $pos = $self->position;
    $canvas->delete("$pos");
}



sub draw {
    my ($self, $canvas, $tilelen) = @_;
    $self->delete($canvas);

    my $class = ref $self;
    $class =~ s/^.*:://;
    return if $class eq 'Node'; # naked node
    $self->_draw_segment(lc($_), $canvas, $tilelen)
        foreach split /_/, $class;
}



sub next_dir {
    my ($self, $from) = @_;
    # each node class is defining a _next_map() method that returns a
    # hashref of {from=>to}
    return $self->_next_map->{$from};
}



sub switch {}


# -- private methods

#
# $node->_draw_segment( $segment, $canvas, $tilelen )
#
# draw $segment of $node (at the correct col / row) on $canvas, assuming
# a square length of $tilelen. $segment can be one of nw, n, ne, w, e,
# sw, s, se.
#
sub _draw_segment {
    my ($self, $segment, $canvas, $tilelen) = @_;

    my $pos  = $self->position;
    my $col1 = $pos->posx;
    my $row1 = $pos->posy;
    my ($col2, $row2) = ($col1, $row1);

    # since each node is overlapping with the surrounding ones, we just
    # need to draw half of the segments.
    return unless $segment ~~ [ qw{ e sw s se } ];
    my $move = Games::RailRoad::Vector->new_dir($segment);
    my $end  = $pos + $move;

    # create the line.
    my $tags = [ "$pos", "$pos-$end" ];
    $canvas->createLine(
        $tilelen * $pos->posx, $tilelen * $pos->posy,
        $tilelen * $end->posx, $tilelen * $end->posy,
        -tags=>$tags
    );

    # add some fancy drawing
    my $div    = 3;
    my $radius = 1;
    foreach my $i ( 0 .. $div ) {
        my $x = $tilelen * ( $pos->posx + $move->posx * $i / $div );
        my $y = $tilelen * ( $pos->posy + $move->posy * $i / $div );
        $canvas->createOval(
            $x-$radius, $y-$radius,
            $x+$radius, $y+$radius,
            -fill => 'brown',
            -tags => $tags,
        );
    }

}


#
# my $map = $node->_transform_map;
#
# return a hashref, which keys are the directions where the node can be
# extended, and the values are the new class of the node after being
# extended.
#
sub _transform_map {
    my $prefix = 'Games::RailRoad::Node::';
    return {
        'e'  => $prefix . 'Half::E',
        'n'  => $prefix . 'Half::N',
        'ne' => $prefix . 'Half::NE',
        'nw' => $prefix . 'Half::NW',
        's'  => $prefix . 'Half::S',
        'se' => $prefix . 'Half::SE',
        'sw' => $prefix . 'Half::SW',
        'w'  => $prefix . 'Half::W',
    };
}



1;


=pod

=head1 NAME

Games::RailRoad::Node - a node object

=head1 VERSION

version 1.101330

=head1 DESCRIPTION

This module provides a node object. This is the base class for the
following classes:

=over 4

=item *

L<Games::RailRoad::Node::Half> is a node with only one segment, from the
center to one of the 8 extremities of a square.

=item *

L<Games::RailRoad::Node::Straight> is a node with two segments, linking
two of the 8 extremities of a square.

=item *

L<Games::RailRoad::Node::Switch> is a node with three segments, linking
three of the 8 extremities of a square through the center. The I<active>
segment taken by a train riding this node can switch between two of the
segments.

=item *

L<Games::RailRoad::Node::Cross> is a node with four segments: two
straight lines crossing in the center of the square.

=back

Each of those classes also has subclasses, one for each configuration
allowed. They are named after each of the existing extremity of the
square linked (in uppercase), sorted and separated by underscore (C<_>).
For example: L<Games::RailRoad::Node::Switch::N_S_SE>.

Note that each segment coming out of a node belongs to 2 different
(adjacent) nodes.

=head1 ATTRIBUTES

=head2 position

The node position (a L<Games::RailRoad::Vector>).

=head1 METHODS

=head2 my $node = Games::RailRoad::Node->new( \%opts );

Create a new node object. One can pass a hash reference with the
available attributes.

=head2 $node->connect( $dir );

Try to extend C<$node> in the wanted C<$dir>. Return undef if it isn't
possible. In practice, note that the object will change of base class.

C<$dir> should be one of C<nw>, C<n>, C<ne>, C<w>, C<e>, C<sw>, C<s>,
C<se>. Of course, other values are accepted but won't result in a node
extension.

=head2 $node->connectable( $dir );

Return true if C<$node> can be connected to the wanted C<$dir>. Return
false otherwise.

C<$dir> should be one of C<nw>, C<n>, C<ne>, C<w>, C<e>, C<sw>, C<s>,
C<se>. Of course, other values are accepted but will always return
false.

=head2 my @dirs = $node->connections;

Return a list of dirs in which the node is connected.

=head2 $node->delete( $canvas );

Request C<$node> to remove itself from C<$canvas>.

=head2 $node->draw( $canvas, $tilelen );

Request C<$node> to draw itself on C<$canvas>, assuming that each square
has a length of C<$tilelen>. Note that this method calls the C<delete()>
method first.

=head2 my $to = $node->next_dir( $from );

When C<$node> is reached by a train, this method will return the next
direction to head to, assuming the train was coming from C<$from>.

Note that the method can return undef if there's no such C<$from>
configured, or if the node is a dead-end.

=head2 $node->switch;

Request a node to change its exit, if possible. This is a no-op for most
nodes, except C<Games::Railroad::Node::Switch::*>.

=head1 AUTHOR

  Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__



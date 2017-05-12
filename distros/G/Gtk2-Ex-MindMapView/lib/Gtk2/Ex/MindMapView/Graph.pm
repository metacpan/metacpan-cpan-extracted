package Gtk2::Ex::MindMapView::Graph;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use Graph::Directed;


# $graph = Gtk2::Ex::MindMapView::Graph->new();

sub new
{
    my $class = shift(@_);

    my $self = {};

    bless $self, $class;

    $self->{graph} = Graph::Directed->new(refvertexed=>1);

    $self->{root}  = undef;

    return $self;
}


# $graph->add($item);
# $graph->add($predecessor_item, $item);

sub add
{
    my ($self, $predecessor_item, $item) = @_;

    if (!defined $item)
    {
	if (defined $self->{root})
	{
	    croak "A root has already been defined. " .
		  "Use set_root to change the root.\n";
	}

	$self->{root} = $predecessor_item;

	$self->{graph}->add_vertex($predecessor_item);

	return;
    }

    $self->{graph}->add_edge($predecessor_item, $item);
}


# $root = $graph->get_root();

sub get_root
{
    my $self = shift(@_);

    return $self->{root};
}


# $boolean = $graph->has_item($item);

sub has_item
{
    my ($self, $item) = @_;

    return $self->{graph}->has_vertex($item);
}


# $num_items = $graph->num_items();

sub num_items
{
    my $self = shift(@_);

    my $num_items = $self->{graph}->vertices();

    return $num_items;
}


# @predecessors = $graph->predecessors($item);

sub predecessors
{
    my ($self, $item) = @_;

    return $self->{graph}->predecessors($item);
}


# $graph->remove($item);
# $graph->remove($predecessor_item, $item);

sub remove
{
    my ($self, $predecessor_item, $item) = @_;

    my $graph = $self->{graph};

    my @successors = $graph->successors($item);

    if (scalar @successors > 0)
    {
	croak "You must remove the successors of this item " .
	      "prior to removing this item.\n"; 
    }

    if (!defined $item)
    {
	if ($predecessor_item != $self->{root})
	{
	    croak "You must pass in both the predecessor and " .
		  "the item you wish to remove.\n";
	}

	$graph->delete_vertex($predecessor_item);

	$self->{root} = undef;

	return;
    }

    $graph->delete_edge($predecessor_item, $item);

    my @predecessors = $graph->predecessors($item);

    if (scalar @predecessors == 0)
    {
	$graph->delete_vertex($item);
    }
}


# @successors = $graph->successors($item);

sub successors
{
    my ($self, $item) = @_;

    return $self->{graph}->successors($item);
}


# $graph->set_root($item);

sub set_root
{
    my ($self, $item) = @_;

    my $graph = $self->{graph};

    my $new_graph = Graph::Directed->new(refvertexed=>1);

    $new_graph->add_vertex($item);

    _set_root($self, $new_graph, $item, undef);

    $self->{graph} = $new_graph;

    $self->{root} = $item;
}


# $graph->traverse_BFS($item, $callack);

sub traverse_BFS
{
    my ($self, $item, $callback) = @_;

    my @pairs = ();

    _traverse_pairs($self, \@pairs, 0, $item);

    my @sorted_pairs = sort { ($a->[0] <=> $b->[0]) ||
			      ($a->[1] <=> $b->[1]) } @pairs;

    foreach my $pair_ref (@sorted_pairs)
    {
	&$callback($pair_ref->[1]);
    }
}


# $graph->traverse_DFS($item, $callback)

sub traverse_DFS
{
    my ($self, $item, $callback) = @_;

    &$callback($item);

    my @successors = $self->{graph}->successors($item);

    foreach my $successor_item (@successors)
    {
	$self->traverse_DFS($successor_item, $callback);
    }
}


# $graph->traverse_postorder_edge($predecessor_item, $item, $callback);

sub traverse_postorder_edge
{
    my ($self, $predecessor_item, $item, $callback) = @_;

    my @successors = $self->{graph}->successors($item);

    foreach my $successor_item (@successors)
    {
	traverse_postorder_edge($self, $item, $successor_item, $callback);
    }

    &$callback($predecessor_item, $item);
}


# $graph->traverse_preorder_edge($predecessor_item, $item, $callback);

sub traverse_preorder_edge
{
    my ($self, $predecessor_item, $item, $callback) = @_;

    &$callback($predecessor_item, $item);

    my @successors = $self->{graph}->successors($item);

    foreach my $successor_item (@successors)
    {
	traverse_preorder_edge($self, $item, $successor_item, $callback);
    }
}


sub _set_root
{
    my ($self, $new_graph, $item, $verboten_item) = @_;

    my @successors = $self->{graph}->successors($item);

    foreach my $successor_item (@successors)
    {
	next if ((defined $verboten_item) && ($successor_item == $verboten_item));

	$self->traverse_preorder_edge($item, $successor_item,
			     sub { $new_graph->add_edge($_[0], $_[1]); }); 
    }

    my @predecessors = $self->{graph}->predecessors($item);

    foreach my $predecessor_item (@predecessors)
    {
	$new_graph->add_edge($item, $predecessor_item);

	_set_root($self, $new_graph, $predecessor_item, $item);
    }
}


sub _traverse_pairs
{
    my ($self, $pairs_ref, $level, $item) = @_;

    push @{$pairs_ref}, [$level, $item];

    my @successors = $self->{graph}->successors($item);

    foreach my $successor_item (@successors)
    {
	_traverse_pairs($self, $pairs_ref, $level + 1, $successor_item);
    }

}



1; # Magic true value required at end of module
__END__

=head1 NAME

Gtk2::Ex::MindMapView::Graph - Manages a directed graph.


=head1 VERSION

This document describes Gtk2::Ex::MindMapView::Graph


=head1 SYNOPSIS

use Gtk2::Ex::MindMapView::Graph;

  
=head1 DESCRIPTION

This is internal to Gtk2::Ex::MindMapView. It's a wrapper around
Jarkko Heitaniemi's nice Graph module. This module is instantiated by
Gtk2::Ex::MindMapView.

=head1 INTERFACE 

=over

=item C<Gtk2::Ex::MindMapView::Graph-E<gt>new()>

Create a Gtk2::Ex::MindMapView::Graph.

=item C<add ($item)>

Add a root Gtk2::Ex::MindMapView::Item to the graph. Only one of these
may be added, or you will get an error.

=item C<add ($predecessor_item, $item)>

Add a Gtk2::Ex::MindMapView::Item to the graph. Attach the item to the
predecessor item.

=item C<get_root()>

Return the root item of the graph.

=item C<has_item($item)>

Return true if the graph contains the item.

=item C<num_items($item)>

Return the number of items in the graph.

=item C<predecessors($item)>

Return the predecessor items of a given Gtk2::Ex::MindMapView::Item.

=item C<remove ($item)>

Remove a Gtk2::Ex::MindMapView::Item from the graph. Attach any
successor items that the item may have had to the items predecessor.

=item C<set_root ($item)>

Change the root item in the graph. An new graph is created with the
new root.

=item C<successors ($item)>

Return the successor items of a given Gtk2::Ex::MindMapView::Item.

=item C<traverse_DFS ($item, $callback)>

Perform a depth-first traversal of the graph, repeatedly calling the
callback.

The traversal algorithm given in Graph.pm returns items in an
unpredictable order which causes the items in the mind map to be
placed differently each time the map is redrawn. So we use our own
method that returns items in the same order. Need to do something
about all these traversal routines.

=item C<traverse_BFS ($item, $callback)>

Perform a breadth-first traversal of the graph, repeatedly calling the
callback.

The traversal algorithm given in Graph.pm returns items in an
unpredictable order which causes the items in the mind map to be
placed differently each time the map is redrawn. So we use our own
method that returns items in the same order. Need to do something
about all these traversal routines.

=item C<traverse_preorder_edge($predecessor_item, $item, $callback)>

Perform a depth first traversal and pass back the predecessor item as
well as the item to the callback. Need to do something about all these
traversal routines.

=item C<traverse_postorder_edge($predecessor_item, $item, $callback)>

Perform a depth first traversal and pass back the predecessor item as
well as the item to the callback. Need to do something about all these
traversal routines.

=back

=head1 DIAGNOSTICS

=over

=item C<A root has already been defined. Use set_root to change the root>

The C<add()> method may only be used to set the root when the first
Gtk2::Ex::MindMapView::Item is added to the graph.

=item C<You must remove the successors of this item prior to removing this item.> 

The C<remove()> method will only remove items that have no successor
items.

=item C<You must pass in both the predecessor and the item you wish to remove.>

The C<remove()> method tries to remove an edge from the graph. You
need to specify the predecessor item because each
Gtk2::Ex::MindMapView::Item may have more that one predecessor.

=back

=head1 AUTHOR

James Muir  C<< <hemlock@vtlink.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, James Muir C<< <hemlock@vtlink.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

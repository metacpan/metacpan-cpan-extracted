package Graph::Layout::Aesthetic::Force;
use 5.006001;
use strict;
use warnings;
use Carp;

# To load the force XS code as long
# (as I don't split them off in a separate module)
use Graph::Layout::Aesthetic;

our $VERSION = '0.01';

our %registered;

sub register {
    my ($force, $name) = @_;
    $name = $force->name if !defined $name;
    croak "A force named $name already exists" if $registered{$name};
    $registered{$name} = $force;
}

sub name {
    my $class = ref($_[0]) || $_[0];
    return $class if $class =~ s/\AGraph::Layout::Aesthetic::Force:://;
    $class =~ s/.*:://s;
    return $class;
}

sub name2force {
    my $name = shift;
    if (!$registered{$name}) {
        my $module = "Graph/Layout/Aesthetic/Force/$name.pm";
        require $module;
        "Graph::Layout::Aesthetic::Force::$name"->import;
    }
    return $registered{$name} ||
        croak "Found no Graph::Layout::Aesthetic::Force named $name"
}

1;
__END__

=head1 NAME

Graph::Layout::Aesthetic::Force - Base class for graph layout aesthetic forces

=head1 SYNOPSIS

  # This module is normally used as base class for particular force modules:
  package Whatever;
  use base qw(Graph::Layout::Aesthetic::Force);

  sub name {
      return "Whatever";
  }

  $force = some_new_force_object();
  $force->register($name);
  $force->register;

  $old_private_data = $force->_private_data;
  $old_private_data = $force->_private_data($new_private_data);
  $old_user_data    = $force->user_data;
  $old_user_data    = $force->user_data($new_user_data);

or

  Graph::Layout::Aesthetic::Force::name2force($name);

=head1 DESCRIPTION

Graph::Layout::Aesthetic::Force is a base class for the aesthetic forces
used by the L<Graph::Layout::Aesthetic|Graph::Layout::Aesthetic> package.
Each force represents one aspect the graph should be optimized for, concepts
like "Nodes should be not too close together" or "edges should not be too
long". This works by passing the current configuration to the
L<aesth_gradient|"aesth_gradient"> function in the force module, which then
returns a "force" for each node corresponding to how much it would like to
move that node in that direction to improve the target aesthetic.

The combination of all forces will then determine the direction and size of
the step that's applied to all nodes. The step sizes get restricted by a scalar
that's called the "temperature". Since initial step sizes can be big, they
don't necessarily improve on the target aesthetics since a step can reach far
beyond the minimum for an aesthetic in the given direction (this is intentional
so that a state will be able to escape from a local minimum). But as the
temperature lowers and the steps get smaller, the steps will more and more tend
to optimize the target aesthetic.

The L<Graph::Layout::Aesthetic|Graph::Layout::Aesthetic> package comes with a
number of predefined aesthetics, these being:

=over

=item L<Graph::Layout::Aesthetic::Force::Centripetal|Graph::Layout::Aesthetic::Force::Centripetal>

Repulsion from the centroid of the current configuration, magnitude 1/d

=item L<Graph::Layout::Aesthetic::Force::MinEdgeLength|Graph::Layout::Aesthetic::Force::MinEdgeLength>

Nodes connected to each other by an edge attract each other with force d**2

=item L<Graph::Layout::Aesthetic::Force::NodeRepulsion|Graph::Layout::Aesthetic::Force::NodeRepulsion>

Nodes repel each other with a force 1/d

=item L<Graph::Layout::Aesthetic::Force::NodeEdgeRepulsion|Graph::Layout::Aesthetic::Force::NodeEdgeRepulsion>

Nodes repel from the nearest point on the line through an edge
if that point is between the endpoints of the edge. Magnitude 1/d.

=item L<Graph::Layout::Aesthetic::Force::MinEdgeIntersect|Graph::Layout::Aesthetic::Force::MinEdgeIntersect>

Crossed edge midpoints repel each other with a constant magnitude of 1.
Only works in 2 dimensions.

=item L<Graph::Layout::Aesthetic::Force::MinEdgeIntersect2|Graph::Layout::Aesthetic::Force::MinEdgeIntersect2>

Crossed edge midpoints repel each other with a force d.
Only works in 2 dimensions.

=item L<Graph::Layout::Aesthetic::Force::ParentLeft|Graph::Layout::Aesthetic::Force::ParentLeft>

This is mainly meant for DAGs (Directed Acyclic Graphs). If a node
gets placed to the left of it's parent (position on the first coordinate, the
x-axis) plus 5, it wants to move to the other side with a force d**2.

=item L<Graph::Layout::Aesthetic::Force::MinLevelVariance|Graph::Layout::Aesthetic::Force::MinLevelVariance>

This is again mainly meant for DAGs (Directed Acyclic Graphs). Each node gets
assigned a level (its distance from the leafs). Then it tries to give all nodes
with the same level at the same distance from the left (position on the first
coordinate, the x-axis). The force is d**3 (d is how much the node is to the
left or the right from the average position of all nodes of its own level).

=back

The main role of this module is to function as base class for particular forces
that are written as L<XS|perlxs> extension modules. It has a default DESTROY
method that frees an assumed underlying C structure, so don't use this as a
baseclass for pure perl modules. However, see
L<Graph::Layout::Aesthetic::Force::Perl|Graph::Layout::Aesthetic::Force::Perl>
for how to write forces in perl. On the other hand, if you want to write your
own standalone force packages based on XS code, then you'll need to look at
L<Graph::Layout::Aesthetic::Include|Graph::Layout::Aesthetic::Include> to
get the right definitions of the C level datastructures.

A typical derived class should normally have a module file that loads the
L<XS|perlxs> object and creates one standard instance of the force which it
then L<registers|"register"> with Graph::Layout::Aesthetic::Force.

The L<XS|perlxs> object should have a constructor that encapsulates a
struct aglo_force (see include/aglo.h) with 3 callback function pointers:

=over

=item aesth_setup

Called once when a force is added to a state (see
L<Graph::Layout::Aesthetic::add_force|Graph::Layout::Aesthetic/add_force>).
It should do any necessary preparation for later
L<aesth_gradient|"aesth_gradient"> (e.g. L<Graph::Layout::Aesthetic::Force::MinLevelVariance|Graph::Layout::Aesthetic::Force::MinLevelVariance> uses it to
calculate the levels of each node in a graph so they don't have to be
recalculated every time). It should return a pointer that will be passed to
every L<aesth_gradient|"aesth_gradient"> call and later to
L<aesth_cleanup|"aesth_cleanup"> for any needed cleanup. This for example can
be used to set up scratch memory that will be needed during calculations.

=item aesth_cleanup

This gets called when a forced gets detached from a state, and should do any
needed cleanup, for example cleaning up the scratch memory allocated by
L<aesth_setup|"aesth_setup">

=item aesth_gradient

The actual workhorse of the aesthetic force. It will be passed the current
state, the pointer returned by L<aesth_setup|"aesth_setup"> and a gradient
pointer which is to be filled in with the aesthetic force. The gradient
pointer is already initialized with zeros.

=back

=head1 METHODS

=over

=item X<register>$force->register

=item $force->register($name)

The Graph::Layout::Aesthetic::Force module holds a mapping from names
to forces. This method registers such a force. The name will be $name, unless
that is undefined or not given, in which case it is determined by calling 
the L<name|"name"> method on the given $force. The force corresponding to a 
given name can be looked up using L<name2force|"name2force"> after this call. 
A given name can only be registered once.

=item X<name>$force->name

This methods should return the "official" name for a given force. If it's not
overridden in the subclass, it defaults to the last component of the class the
force belongs to.

=item X<name2force>Graph::Layout::Aesthetic::Force::name2force($name)

This looks up $name in the name to force mapping of this module. If found,
it directly returns the corresponding force. If not, it tries to
L<require|perlfunc/require> Graph::Layout::Aesthetic::Force::$name and
tries again. If still not found, it throws an exception.

This method gets used by L<Graph::Layout::Aesthetic|Graph::Layout::Aesthetic>
to load forces on demand.

=item X<private_data>$old_private_data = $force->_private_data

Every force object is associated with one scalar of private data (default
undef). This is perl data meant for the implementer of a force class, and 
should normally not be manipulated by the user (see
L<user_data|"user_data"> for that).

This method returns that private data.

Don't confuse this with the closure data returned by
L<aesth_setup|"aesth_setup">. That one is associated with a force/state
combination and normally only exists as long as a certain force is associated
with a certain state, while this one is associated with the force itself.

=item $old_private_data = $force->_private_data($new_private_data)

Sets new private data, returns the old value.

=item X<user_data>$old_user_data = $force->user_data

Every force object is associated with one scalar of user data (default
undef). This is perl data meant for the enduser of a force class,
and should normally not be manipulated inside the force class
(see L<private_data|"private_data"> for that).

This method returns that user data.

=item $old_user_data = $force->user_data($new_user_data)

Sets new user data, returns the old value.

=back

=head1 EXPORTS

None.

=head1 SEE ALSO

L<Graph::Layout::Aesthetic>,
L<Graph::Layout::Aesthetic::Force::Perl>,
L<Graph::Layout::Aesthetic::Force::Centripetal>,
L<Graph::Layout::Aesthetic::Force::MinEdgeLength>,
L<Graph::Layout::Aesthetic::Force::NodeRepulsion>,
L<Graph::Layout::Aesthetic::Force::MinEdgeIntersect>,
L<Graph::Layout::Aesthetic::Force::MinLevelVariance>,
L<Graph::Layout::Aesthetic::Force::ParentLeft>,
L<Graph::Layout::Aesthetic::Force::MinEdgeIntersect2>,
L<Graph::Layout::Aesthetic::Force::NodeEdgeRepulsion>,
L<Graph::Layout::Aesthetic::Include>

=head1 AUTHOR

Ton Hospel, E<lt>Graph-Layout-Aesthetic@ton.iguana.beE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ton Hospel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

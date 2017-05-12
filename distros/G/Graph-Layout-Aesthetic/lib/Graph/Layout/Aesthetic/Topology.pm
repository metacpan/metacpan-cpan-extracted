package Graph::Layout::Aesthetic::Topology;
use 5.006001;
use strict;
use warnings;
use Carp;

# We need this to load our xs code
use Graph::Layout::Aesthetic;

our $VERSION = '0.02';

sub from_graph {
    my ($class, $graph, %params) = @_;

    my $literal   = delete $params{literal};
    my $attribute = exists $params{id_attribute} ? 
        delete $params{id_attribute} : "layout_id";

    croak "Unknown parameter ", join(", ", keys %params) if %params;

    my $num;

    # Set up a mapping from vertices to numbers
    my $nr = 0;
    if (ref($attribute)) {
        $num = $attribute;
        %$num = ();
        $num->{$_} = $nr++ for $graph->vertices;
    } else {
        $num = {};
        if (defined($attribute)) {
            $graph->set_vertex_attribute($_, $attribute, $num->{$_} = $nr++) 
                for $graph->vertices;
        } else {
            $num->{$_} = $nr++ for $graph->vertices;
        }
    }
    $nr == keys %$num || croak "Duplicate vertex identifiers";

    my $topo = $class->new_vertices($nr);

    # Enter edges
    if ($literal) {
        for my $edge ($graph->edges) {
            $topo->add_edge($num->{$edge->[0]}, $num->{$edge->[1]});
        }
    } else {
        my (%seen, $f, $t);
        for my $edge ($graph->edges) {
            $f = $num->{$edge->[0]};
            $t = $num->{$edge->[1]};
            if ($f != $t && !$seen{$f}{$t} && !$seen{$t}{$f}) {
                $seen{$f}{$t} = 1;
                $topo->add_edge($f, $t);
            }
        }
    }
    $topo->finish;

    return $topo;
}

1;
__END__

=head1 NAME

Graph::Layout::Aesthetic::Topology - Graph topology for use by Graph::Layout::Aesthetic

=head1 SYNOPSIS

  use Graph::Layout::Aesthetic::Topology;
  $topology = Graph::Layout::Aesthetic::Topology->from_graph($graph, %options);
  # Where %options can be:
  #  literal   => $boolean
  #  id_attribute => $name

  $topology = Graph::Layout::Aesthetic::Topology->new_vertices($nr_vertices);
  $topology->add_edge($from, $to ?,$forward?);
  $topology->finish;

  $nr_vertices   = $topology->nr_vertices;
  @vertices      = $topology->neighbors($vertex);
  @vertices      = $topology->forward_neighbors($vertex);
  @edges         = $topology->edges;
  @vertex_levels = $topology->levels;
  $boolean	 = $topology->finished;

  $old_private_data = $topology->_private_data;
  $old_private_data = $topology->_private_data($new_private_data);
  $old_user_data    = $topology->user_data;
  $old_user_data    = $topology->user_data($new_user_data);

=head1 DESCRIPTION

A Graph::Layout::Aesthetic::Topology objects represents a directed graph
topology and is used by Graph::Layout::Aesthetic as a simple and quickly 
accessible datastructure representing the graph that has to be laid out. 
Vertices are simply represented as consecutive numbers starting with 0.
Edges may not go from a vertex to itself since that may confuse some aesthetic 
forces.

=head1 EXAMPLE

Set up a simple triangle:

  use Graph::Layout::Aesthetic::Topology;

  # Create an empty graph with 3 vertices
  my $topology = Graph::Layout::Aesthetic::Topology->new_vertices(3);

  # Add the edges
  $topology->add_edge(0, 1);
  $topology->add_edge(1, 2);
  $topology->add_edge(2, 0);

  # Say we are done
  $topology->finish;

  # Now we have something that could be passed to Graph::Layout::Aesthetic->new

=head1 METHODS

=over

=item X<from_graph>$topology = Graph::Layout::Aesthetic::Topology->from_graph($graph, %options)

Creates a new L<finished|"finish"> Graph::Layout::Aesthetic::Topology from
a standard L<Graph|Graph> object $graph. It does this by first
L<creating|"new_vertices"> a Graph::Layout::Aesthetic::Topology object with the
right number of vertices and then L<enumerating all edges|Graph::Base/edges>
in $graph and L<adding these to the topology|"add_edge"> if the edge hasn't
been seen yet in either direction and doesn't start and end on the same vertex.

The resulting $topology will then probably be passed to a
L<Graph::Layout::Aesthetic|Graph::Layout::Aesthetic> constructor.

You can give key/value pairs as options. Currently supported are:

=over

=item X<from_graph_attribute>id_attribute => $name

If you don't give this attribute, it will behave as if you gave it the string
C<"layout_id"> (the same default as for the 
L<Graph::Layout::Aesthetic coordinates_to_graph method|Graph::Layout::Aesthetic/coordinates_to_graph method>).

If you give this attribute an undefined value, it will do no tracking
of graph vertices to topology vertices.

If you give it a hash reference, it will empty the hash and then add a key
for each vertex in $graph with as value the number of the corresponding vertex
in $topology.

If you give it a string, it will use that string as an attribute name for each
vertex in $graph and set that attribute to the vertex number in $topology.

You'll probably want to use this options in some form so you'll know which 
vertex in the result corresponds to which vertex in your $graph.

=item X<from_graph_literal>literal => $boolean

If you give a true value here, the filtering of $graph->edges for duplicates
and self-edges is not done. Every edge is simply passed on to
L<add_edge|"add_edge">.

=back

=item X<new_vertices>$topology = Graph::Layout::Aesthetic::Topology->new_vertices($nr_vertices)

Creates a new L<unfinished|"finish"> Graph::Layout::Aesthetic::Topology object
representing a graph with $nr_vertices vertices. After this you will probably
start L<adding edges|"add_edge"> and L<finish|"finish"> the graph before
passing it to a L<Graph::Layout::Aesthetic|Graph::Layout::Aesthetic>
constructor.

=item X<add_edge>$topology->add_edge($from, $to ?,$forward?)

Register an edge running from vertex $from to vertex $to if $forward is not
given or true, a vertex from $to to $from otherwise. You can only add edges
as long as the topology is L<unfinished|"finish">.

It's possible to add an edge more than once or both in the forward and 
backward direction. All of these will be seen as different edges and be used
as such in the aesthetic force calculations.

=item X<finish>$topology->finish

Finishing a Graph::Layout::Aesthetic::Topology object makes it conceptually
read-only. You won't be able to L<add edges|"add_edge"> anymore.
L<Graph::Layout::Aesthetic|Graph::Layout::Aesthetic> constructors will only
accept finished Graph::Layout::Aesthetic::Topology objects since they may
internally cache information based on the topology of a given moment, and they
don't want that cached information to suddenly become invalid because the
topology got changed.

You can only finish a Graph::Layout::Aesthetic::Topology object once.

=item X<nr_vertices>$nr_vertices = $topology->nr_vertices

Returns the number of vertices in $topology.

=item X<neighbors>@vertices = $topology->neighbors($vertex)

Returns all direct neighbors of $vertex, following edges in any direction.

=item X<forward_neighbors>@vertices = $topology->forward_neighbors($vertex)

Returns all direct neighbors of $vertex, following edges in the forward
direction only.

=item X<edges>@edges = $topology->edges

Returns all forward edges in $topology as a list of anonymous array references.
Each such reference is to a two element array containing the $from and $to
vertex for that edge.

=item X<levels>@vertex_levels = $topology->levels

Returns a level number for each vertex (list element n represents the level
of vertex n). Levels basically correspond to distance from leafs (only 
following edges in the forward direction). These levels are used by some forces
like L<Graph::Layout::Aesthetic::Force::MinLevelVariance|Graph::Layout::Aesthetic::Force::MinLevelVariance>.

Levels are only calculated once for a given topology and then cached. The call
will croak if the $topology hasn't been L<finished|"finish"> yet.

=item X<finished>$boolean = $topology->finished

Returns true if $topology has been L<finished|"finish">, false otherwise.

=item X<private_data>$old_private_data = $topology->_private_data

Every topology object is associated with one scalar of private data (default
undef). This is perl data meant for the implementer of a Topology class, and 
should normally not be manipulated by the user (see
L<user_data|"user_data"> for that).

This method returns that private data.

=item $old_private_data = $topology->_private_data($new_private_data)

Sets new private data, returns the old value.

=item X<user_data>$old_user_data = $topology->user_data

Every topology object is associated with one scalar of user data (default
undef). This is perl data meant for the enduser of a topology class,
and should normally not be manipulated inside the topology class
(see L<private_data|"private_data"> for that).

This method returns that user data.

=item $old_user_data = $topology->user_data($new_user_data)

Sets new user data, returns the old value.

=back

=head1 EXPORT

None.

=head1 SEE ALSO

L<Graph>,
L<Graph::Layout::Aesthetic>

=head1 BUGS

Not threadsafe. Different object may have method calls going on at the same 
time, but any specific object should only have at most one call active.

=head1 AUTHOR

Ton Hospel, E<lt>Graph-Layout-Aesthetic@ton.iguana.beE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ton Hospel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

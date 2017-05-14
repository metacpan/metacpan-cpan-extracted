package Graph::Simple;

#ABSTRACT: simple and intuitive interface for manipulating graph


use Moo;
use Carp 'croak';

# graphs are represented with adjency lists
has _adjencies => (
    is      => 'rw',
    default => sub { {} },
);

# if weights are provided, stored for each edge(u,v)
has _weights => (
    is      => 'rw',
    default => sub { {} },
);


has is_weighted => (
    is      => 'ro',
    default => sub {0},
);


has is_directed => (
    is      => 'ro',
    default => sub {0},
);


sub vertices {
    my $self = shift;
    return keys %{ $self->_adjencies };
}


sub add_edge {
    my ( $self, $u, $v, $weight ) = @_;

    $self->_add_edge( $u, $v, $weight );

    # if the graph is not directed, adding u,v adds v,u
    $self->_add_edge( $v, $u, $weight ) if !$self->is_directed;

    return "$u,$v";
}

sub _add_edge {
    my ( $self, $u, $v, $weight ) = @_;
    $weight ||= 0;

    $self->_adjencies->{$u} ||= [];
    push @{ $self->_adjencies->{$u} }, $v;

    $self->_weights->{$u}->{$v} = $weight
      if $self->is_weighted;
}


sub delete_edge {
    my ( $self, $u, $v ) = @_;

    $self->_delete_edge( $u, $v );
    $self->_delete_edge( $v, $u ) if !$self->is_directed;
}

sub _delete_edge {
    my ( $self, $u, $v ) = @_;

    my @neighbors = $self->neighbors($u);
    my @new;
    foreach my $e (@neighbors) {
        push @new, $e if $e ne $v;
    }
    $self->_adjencies->{$u} = \@new;
}


sub neighbors {
    my ( $self, $v ) = @_;

    croak "Unknown vertex '$v'"
      if !grep {/^$v$/} $self->vertices;

    return @{ $self->_adjencies->{$v} };
}


sub weight {
    my ( $self, $u, $v, $w ) = @_;
    if ( @_ == 3 ) {
        return $self->_weights->{$u}->{$v};
    }
    else {
        $self->_weights->{$u}->{$v} = $w;
    }
}


sub is_adjacent {
    my ( $self, $u, $v ) = @_;
    return grep {/^$v$/} @{ $self->_adjencies->{$u} };
}


sub breadth_first_search {
    my ( $self, $v, %options ) = @_;

    my @queue   = ($v);
    my $parents = {};
    my $states  = { $v => 'grey' };

    my $cb_vertex_discovered = $options{cb_vertex_discovered} || sub {
    };

    my $cb_vertex_processed = $options{cb_vertex_processed} || sub {
    };

    my $cb_edge_discovered = $options{cb_edge_discovered} || sub {
    };

    while ( my $vertex = shift(@queue) ) {
        $cb_vertex_discovered->($vertex);

        foreach my $n ( $self->neighbors($vertex) ) {
            my $state = $states->{$n} || 'white';
            next if $state eq 'black';

            if ( $state eq 'grey' ) {
                $cb_edge_discovered->( $vertex, $n );
                next;
            }

            push @queue, $n;
            $states->{$n}  = 'grey';
            $parents->{$n} = $vertex;
        }

        $states->{$vertex} = 'black';
        $cb_vertex_processed->($vertex);
    }

    return $parents;
}


sub depth_first_search {
    my ( $self, $start, %options ) = @_;

    # init phase of the DFS traversal
    my $states ||= {};
    my $cb_vd = $options{cb_vertex_discovered} || sub { };
    my $cb_vp = $options{cb_vertex_processed}  || sub { };
    my $cb_ed = $options{cb_edge_discovered}   || sub { };
    foreach my $v ( $self->vertices ) {
        $states->{$v} = 'unknown';
    }

    # DFS traversal is recursively done on each new vertex
    $self->_dfs_visit(
        $start, $states,
        {   cb_vertex_discovered => $cb_vd,
            cb_vertex_processed  => $cb_vp,
            cb_edge_discovered   => $cb_ed,
        }
    );
}

sub _dfs_visit {
    my ( $self, $vertex, $states, $callbacks ) = @_;

    $states->{$vertex} = 'discovered';
    $callbacks->{cb_vertex_discovered}->($vertex);

    foreach my $n ( $self->neighbors($vertex) ) {

        $callbacks->{cb_edge_discovered}->( $vertex, $n );
        my $state = $states->{$n};

        if ( $state eq 'unknown' ) {
            $self->_dfs_visit( $n, $states, $callbacks );
        }
    }

    $callbacks->{cb_vertex_processed}->($vertex);
    $states->{$vertex} = 'processed';
}


sub prim {
    my ( $self, $start ) = @_;
    my $spanning_tree =
      Graph::Simple->new( is_weighted => 0, is_directed => 0 );

    my %non_tree_vertices = map { $_ => 1 } $self->vertices;
    my %tree_vertices = ( $start => 1 );

    my $current = $start;
    while ( keys %non_tree_vertices ) {
        delete $non_tree_vertices{$current};

        # select the edge of minimum weight between a tree and a nontree vertex
        my $min_weight;
        my $new_edge;
        foreach my $u ( keys %tree_vertices ) {

            foreach my $v ( $self->neighbors($u) ) {
                next if exists $tree_vertices{$v};

                my $w = $self->weight( $u, $v );

                # print " - $u, $v weights $w\n";

                $min_weight = $w if !defined $min_weight;
                if ( $w <= $min_weight ) {
                    $new_edge = [ $u, $v ];
                    $min_weight = $w;
                }
            }
        }

        # Adding $v to the spanning tree
        my ( $u, $v ) = @$new_edge;

        # print "Minimum vertex is $u -> $v\n";
        $spanning_tree->add_edge( $u, $v );
        delete $non_tree_vertices{$v};
        $tree_vertices{$v} = 1;
    }

    return $spanning_tree;
}


sub dijkstra {
    my ( $self, $vertex ) = @_;
    my $spanning_tree = Graph::Simple->new;

    my %distances = ( $vertex => 0 );
    my %non_tree_vertices = map { $_ => 1 } $self->vertices;
    my %tree_vertices = ( $vertex => 1 );

    my $current = $vertex;
    while ( keys %non_tree_vertices ) {
        delete $non_tree_vertices{$current};

        # select the edge of minimum weight between a tree and a nontree vertex
        my $min_dist;
        my $new_edge;
        foreach my $u ( keys %tree_vertices ) {

            foreach my $v ( $self->neighbors($u) ) {
                next if exists $tree_vertices{$v};

                my $w = $self->weight( $u, $v );
                my $distance = $distances{$u} + $w;

                $min_dist = $distance if !defined $min_dist;
                if ( $distance <= $min_dist ) {
                    $new_edge      = [ $u, $v ];
                    $min_dist      = $distance;
                    $distances{$v} = $distance;
                }
            }
        }

        # Adding $v to the spanning tree
        my ( $u, $v ) = @$new_edge;
        $spanning_tree->add_edge( $u, $v );
        delete $non_tree_vertices{$v};
        $tree_vertices{$v} = 1;
    }

    return { spanning_tree => $spanning_tree, distances => \%distances };
}


sub shortest_path {
    my ( $self, $source, $destination ) = @_;
    my $dijkstra = $self->dijkstra($source);

    my $mst = $dijkstra->{spanning_tree};

 # we build a reverse path, starting from the destination, and backtracking the
 # source each step with the neighbors of the vertex in the spanning tree
    my @reverse_path;
    my $current = $destination;

    while ( $current ne $source ) {
        push @reverse_path, $current;

        foreach my $n ( $mst->neighbors($current) ) {
            if ( $n eq $source ) {
                push @reverse_path, $n;
                return reverse @reverse_path;
            }
            else {
                $current = $n;
            }
        }
    }

    return reverse @reverse_path;
}

1;


=pod

=head1 NAME

Graph::Simple - simple and intuitive interface for manipulating graph

=head1 VERSION

version 0.04

=head1 DESCRIPTION

In computer science, a graph is an abstract data type that is meant to implement
the graph and hypergraph concepts from mathematics.

A graph data structure consists of a finite (and possibly mutable) set of
ordered pairs, called I<edges>, of certain entities called I<vertices>.
As in mathematics, an edge (x,y) is said to point or go from x to y.

A graph data structure may also associate to each edge some edge value, such as
a symbolic label or a numeric attribute (cost, capacity, length, etc.) most
oftenly refered to as the I<weight> of the edge. 

See L<Wikipedia|http://en.wikipedia.org/wiki/Graph_(abstract_data_type)> for
more details about the theory.

This class provides an easy to use and intuitive API for manipulating graphs in
Perl. It's a native Perl implementation based on L<Moo>.

=head1 ATTRIBUTES

=head2 is_weighted

Boolean flag to tell if the graph is weighted

=head2 is_directed

Boolean flag to tell if the graph is directed

=head1 METHODS

=head2 vertices

Return the array of vertices

    my @vertices = $g->vertices;

=head2 add_edge

Adds a new edge to the graph, and add the corresponding vertices.
Note that on undirected graphs, adding u,v also adds v,u.

    $g->add_edge("Foo", "Bar");

On weighted graph, it's possible to pass the weight of the edge as a third
argument

    $g->add_edge("Foo", "Bar", 3);

=head2 delete_edge

    $g->delete_edge(x, y)

Removes the edge from x to y, if it is there.

=head2 neighbors

    my @neighbors = $g->neighbors('u');

Lists all vertices y such that there is an edge from x to y.

=head2 weight

Accessor to the weight of the edge. If called with two arguments, return the
value previously set, with three arguments, set the weight:

    # reader
    my $w = $g->weight('u', 'v');

    # setter
    $g->weight('u', 'v', 42);

=head2 is_adjacent

    $g->is_adjacent(x, y)

Tests whether there is an edge from node x to node y.

=head2 breadth_first_search

Performs a BFS traversal on the graph, returns the parents hash produced.

Callbacks can be given to trigger code when edges or vertices are
discovered/processed.

    $g->breadth_first_search($vertex, 
        cb_vertex_discovered => sub { print "discovered vertex @_" },
        cb_vertex_processed => sub { print "processed vertex @_" },
        cb_edge_discovered => sub { print "new edge: @_" });

=head2 depth_first_search

Performs a DFS traversal on the graph, returns the parents hash produced.

Callbacks can be given to trigger code when edges or vertices are
discovered/processed.

    $g->breadth_first_search('Foo',
        cb_vertex_discovered => sub { print "discovered vertex @_" },
        cb_vertex_processed  => sub { print "processed vertex @_" },
        cb_edge_discovered   => sub { print "new edge: @_" },
    );

=head2 prim

Implementation of the Prim algorithm to grow a Minimum Spanning Tree of the
graph.

Return the tree produced (as a C<Graph::Simple> object).

    my $mst = $g->prim('Foo');

=head2 dijkstra

Implementation of the Dijkstra algorithm to find all possible shortest paths from
a vertex C<$s> to all other vertices of the graph.

The return value of this method is a hashref containing the following entries:

=over 4

=item spanning_tree

A L<Graph::Simple> object representing the minimum spanning tree produced by the
Dijkstra traversal.

=item distances

An hashref containing for each vertices the distance between that vertex and the
source vertex.

=back

    my $dijkstra = $g->dijkstra('E');

=head2 shortest_path

Return the shortest path between two vertices as a list of vertices.

    my @path = $g->shortest_path('A', 'E');
    # eg: ( 'A', 'D', 'F', 'E' )

Note that internally, this method uses the spanning tree produced by the
Dijkstra algorithm to compute the shortest path.

=head1 SYNOPSYS

    my $g = Graph::Simple->new ( is_directed => 1, is_weighted => 1);

    $g->add_edge( 'Al',  'Bob', 2 );
    $g->add_edge( 'Al',  'Jim', 3 );
    $g->add_edge( 'Joe',  'Jim', 3 );
    
    $g->neighbors('Al');

=head1 SEE ALSO

This distribution has been written because when I looked on CPAN for an easy to
use and lightweight interface for manipulating graphs in Perl, I dind't find
something that fitted my expectations.

Other distributions exist though:

=over 4

=item L<Graph>

A rather feature-rich implementation but with a complex API.

=item L<Graph::Fast>

Less features than Graph but presumably faster. Appears to
be unmaintained since 2010 though.

=item L<Graph::Boost>

Perl bindings to the C++ graph library Boost. Certainly the fastest
implementation but depends on C++, obviously.

=back

=head1 AUTHOR

Alexis Sukrieh <sukria@sukria.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

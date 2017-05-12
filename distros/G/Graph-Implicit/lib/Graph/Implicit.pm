use strict;
use warnings;
package Graph::Implicit;
our $VERSION = '0.03';

use Heap::Fibonacci::Fast;
use List::MoreUtils qw/apply/;

=head1 NAME

Graph::Implicit - graph algorithms for implicitly specified graphs

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  my $graph = Graph::Implicit->new(sub {
      my $tile = shift;
      map { [$_, $_->intrinsic_cost] }
          $tile->grep_adjacent(sub { $_[0]->is_walkable })
  });
  my @reachable_vertices = $graph->vertices(current_tile());
  my @reachable_edges = $graph->edges(current_tile());
  my ($sssp_predecessors, $dest_vertex) = $graph->dijkstra(
      current_tile(),
      sub { is_target($_[0]) ? 'q' : 0 },
  );
  my @sssp_path = $graph->make_path($sssp_predecessors, $dest_vertex);

=head1 DESCRIPTION

This module implements several graph algorithms (for directed, weighted graphs)
that can run without having to specify the actual graph. This module models a
graph as an arbitrary coderef that maps vertices onto a list of adjacent
vertices and weights for the edges to those vertices. Vertices can be
represented by any string (or stringifyable piece of data), and don't need to
be specified ahead of time; the algorithms will just figure it out. This allows
objects to generally just work (they get stringified to
C<"Class=HASH(0xdeadbeef)">).

Some caveats: working with complicated data structures which need deep
comparisons generally need additional help: C<[0, 1, 2] ne [0, 1, 2]>, since
those become different references. Also, since the graph isn't specified at
all, each method that is called on one needs a vertex to start traversing the
graph from, and any vertices not reachable from that vertex won't be found. A
few algorithms are also not able to be implemented as efficiently as possible,
since the entire graph isn't known ahead of time; for instance, finding all the
edges of the graph requires actually doing a graph traversal, rather than just
reading them out of the data structure, like you would do in an explicit graph
representation.

=cut

=head1 CONSTRUCTOR

=head2 new(CODEREF)

The constructor takes a single argument, a coderef. This coderef should take
something representing a vertex, and return a list of arrayrefs, one for each
adjacent vertex, which have the vertex as the first element and the weight of
the edge to that vertex as the second element. For example, if the graph has
three elements A, B, and C, and there is an edge of weight 1 from B to A and an
edge of weight 2 from B to C, then the coderef should return C<["A", 1], ["C",
2]> when called with C<"B"> as its argument.

=cut

sub new {
    my $class = shift;
    my $edge_calculator = shift;
    return bless $edge_calculator, $class;
}

=head1 METHODS

=cut

# generic information

=head2 vertices(VERTEX)

Returns a list of all vertices reachable from the given vertex.

=cut

sub vertices {
    my $self = shift;
    my ($start) = @_;
    my @vertices;
    $self->dfs($start, sub { push @vertices, $_[1] });
    return @vertices;
}

=head2 edges(VERTEX)

Returns a list of all edges reachable from the given vertex.

=cut

# XXX: probably pretty inefficient... can we do better?
sub edges {
    my $self = shift;
    my ($start) = @_;
    map { my $v = $_; map { [$v, $_] } $self->neighbors($v) }
        $self->vertices($start);
}

=head2 neighbors(VERTEX)

Returns a list of neighbors (without weights) of the given vertex.

=cut

sub neighbors {
    my $self = shift;
    my ($from) = @_;
    return map { $$_[0] } $self->($from);
}

# traversal

sub _traversal {
    my $self = shift;
    my ($start, $code, $create, $notempty, $insert, $remove) = @_;
    my $bag = $create->();
    my %marked;
    my %pred;
    $pred{$start} = undef;
    $insert->($bag, [undef, $start], 0);
    while ($notempty->($bag)) {
        my ($pred, $vertex) = @{ $remove->($bag) };
        if (not exists $marked{$vertex}) {
            $code->($pred, $vertex) if $code;
            $pred{$vertex} = $pred if defined wantarray;
            $marked{$vertex} = 1;
            $insert->($bag, [$vertex, $$_[0]], $$_[1]) for $self->($vertex);
        }
    }
    return \%pred;
}

=head2 bfs(VERTEX[, CODEREF])

Does a breadth-first search of the graph, starting at the given vertex. It runs
the given coderef (if it exists) on each vertex, as they are encountered.
Returns a hashref, whose keys are the encountered vertices, and whose values
are the predecessor in the breadth-first search tree.

=cut

sub bfs {
    my $self = shift;
    my ($start, $code) = @_;
    return $self->_traversal($start, $code,
                             sub { [] },
                             sub { @{ $_[0] } },
                             sub { push @{ $_[0] }, $_[1] },
                             sub { shift @{ $_[0] } });
}

=head2 dfs(VERTEX[, CODEREF])

Does a depth-first search of the graph, starting at the given vertex. It runs
the given coderef (if it exists) on each vertex, as they are encountered.
Returns a hashref, whose keys are the encountered vertices, and whose values
are the predecessor in the depth-first search tree.

=cut

sub dfs {
    my $self = shift;
    my ($start, $code) = @_;
    return $self->_traversal($start, $code,
                             sub { [] },
                             sub { @{ $_[0] } },
                             sub { push @{ $_[0] }, $_[1] },
                             sub { pop @{ $_[0] } });
}

#sub iddfs {
#}

# minimum spanning tree

#sub boruvka {
#}

# XXX: this algo only works in its current form for undirected graphs with
# unique edge weights
#sub prim {
    #my $self = shift;
    #my ($start, $code) = @_;
    #return $self->_traversal($start, $code,
                             #sub { Heap::Fibonacci::Fast->new },
                             #sub { $_[0]->count },
                             #sub { $_[0]->key_insert($_[2], $_[1]) },
                             #sub { $_[0]->extract_top });
#}

#sub kruskal {
#}

# single source shortest path

=head2 dijkstra(VERTEX[, CODEREF])

Runs the Dijkstra single source shortest path algorithm, starting from the
given vertex. It also takes a single coderef as an argument, which is called on
each vertex as it is encountered - this coderef is expected to return a score
for the vertex. If the returned score is C<'q'>, then the search terminates
immediately, otherwise it keeps track of the vertex with the highest score.
This returns two items: a predicate hashref like the return value of L</bfs>
and L</dfs>, and the vertex which was scored highest by the scorer coderef
(or the vertex that returned C<'q'>).

=cut

sub dijkstra {
    my $self = shift;
    my ($from, $scorer) = @_;
    return $self->astar($from, sub { 0 }, $scorer);
}

=head2 astar(VERTEX, CODEREF[, CODEREF])

Runs the A* single source shortest path algorithm. Similar to L</dijkstra>, but
takes an additional coderef parameter (before the scorer coderef), for the
heuristic function that the A* algorithm requires.

=cut

sub astar {
    my $self = shift;
    my ($from, $heuristic, $scorer) = @_;

    my $pq = Heap::Fibonacci::Fast->new;
    my %neighbors;
    my ($max_vert, $max_score) = (undef, 0);
    my %dist = ($from => 0);
    my %pred = ($from => undef);
    $pq->key_insert(0, $from);
    while ($pq->count) {
        my $cost = $pq->top_key;
        my $vertex = $pq->extract_top;
        if ($scorer) {
            my $score = $scorer->($vertex);
            return (\%pred, $vertex) if $score eq 'q';
            ($max_vert, $max_score) = ($vertex, $score)
                if ($score > $max_score);
        }
        $neighbors{$vertex} = [$self->($vertex)]
            unless exists $neighbors{$vertex};
        for my $neighbor (@{ $neighbors{$vertex} }) {
            my ($vert_n, $weight_n) = @{ $neighbor };
            my $dist = $cost + $weight_n + $heuristic->($vertex, $vert_n);
            if (!defined $dist{$vert_n} || $dist < $dist{$vert_n}) {
                $dist{$vert_n} = $dist;
                $pred{$vert_n} = $vertex;
                $pq->key_insert($dist, $vert_n);
            }
        }
    }
    return \%pred, $max_vert;
}

#sub bellman_ford {
#}

# all pairs shortest path

#sub johnson {
#}

#sub floyd_warshall {
#}

# non-trivial graph properties

=head2 is_bipartite(VERTEX)

Returns whether or not the reachable part of the graph from the given vertex is
bipartite.

=cut

sub is_bipartite {
    my $self = shift;
    my ($from) = @_;
    my $ret = 1;
    BIPARTITE: {
        my %colors = ($from => 0);
        no warnings 'exiting';
        $self->bfs($from, sub {
            my $vertex = $_[1];
            apply {
                last BIPARTITE if $colors{$vertex} == $colors{$_};
                $colors{$_} = not $colors{$vertex};
            } $self->neighbors($vertex)
        });
        return 1;
    }
    return 0;
}

# sorting

#sub topological_sort {
#}

# misc utility functions

=head2 make_path(HASHREF, VERTEX)

Takes a predecessor hashref and an ending vertex, and returns the list of
vertices traversed to get from the start vertex to the given ending vertex.

=cut

sub make_path {
    my $self = shift;
    my ($pred, $end) = @_;
    my @path;
    while (defined $end) {
        push @path, $end;
        $end = $pred->{$end};
    }
    return reverse @path;
}

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-graph-implicit at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Implicit>.

=head1 TODO

=over

=item dijkstra/astar and bfs/dfs should have more similar interfaces - right now bfs/dfs just call a coderef and do nothing with it, while dijkstra/astar use the coderef to search for a vertex

=item Several more graph algorithms need implementations

=item Returning two values from dijkstra and astar is kind of ugly, need to make this better

=back

=head1 SEE ALSO

L<Graph>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Graph::Implicit

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Graph-Implicit>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Graph-Implicit>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Graph-Implicit>

=item * Search CPAN

L<http://search.cpan.org/dist/Graph-Implicit>

=back

=head1 AUTHOR

  Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;
package Graph::MaxFlow;

require Exporter;
use Graph;
use Carp 'carp';

@ISA = qw(Exporter);
@EXPORT_OK = qw(max_flow);

$VERSION = '0.03';

use strict;
use warnings;

# Edmonds-Karp algorithm to find the maximum flow in $g between
# $source and $sink
sub max_flow {
    my ($g, $source, $sink) = @_;

    if ($g->is_undirected) {
        carp "Graph must be directed";
        return;
    }

    if ($g->vertices < 2) {
        carp "Graph must have at least 2 vertices";
        return;
    }

    my $resid = init_flow($g);

    while (1) {
        # find the shortest augmenting path between $source and $sink
        my $path = shortest_path($g, $resid, $source, $sink);
        last unless @$path;

        # find min weight in path
        my $min;
        for my $i (0..$#$path - 1) {
            my $weight = residual_capacity($g, $resid, $path->[$i], $path->[$i+1]);
            $min = $weight if !defined $min || $weight < $min;
        }

        # update the flow network
        for my $i (0..$#$path - 1) {
            add_edge_weight($resid, $path->[$i], $path->[$i+1], $min);
            add_edge_weight($resid, $path->[$i+1], $path->[$i], -$min);
        }

    }

    # convert the residual flow graph into a copy of the original
    # graph, but with the edge weights set to the flow
    my $flow = $g->copy_graph;
    for my $e ($flow->edges) {
        my ($u, $v) = @$e;
        my $weight = $resid->get_edge_weight($u, $v);
        $flow->set_edge_weight($u, $v, $weight > 0 ? $weight : 0);
    }

    return $flow;
}

# init the flow so that f(u,v) = 0 for all edges
sub init_flow {
    my $g = shift;
    my $flow = new Graph;

    for my $e ($g->edges) {
            $flow->add_weighted_edge($e->[0], $e->[1], 0);
            $flow->add_weighted_edge($e->[1], $e->[0], 0);
    }

    return $flow;
}

# do a breadth-first search over edges with positive residual capacity
sub shortest_path {
    my ($g, $flow, $from, $to) = @_;

    my %parent;
    my @next;

    $parent{$from} = undef;
    $next[0] = $from;
    my $found = 0;

    # loop until we either reach $to or run out of nodes in the @next queue
    while (@next) {
        my $u = shift @next;
        if ($u eq $to) {
            $found = 1;
            last;
        }

        for my $v ($g->neighbors($u)) {
            next if exists $parent{$v};
            next unless residual_capacity($g, $flow, $u, $v) > 0;
            $parent{$v} = $u;
            push @next, $v;
        }
    }

    # reconstruct path
    my @path;
    if ($found) {
        my $u = $to;
        while (defined $parent{$u}) {
            unshift @path, $u;
            $u = $parent{$u};
        }
        unshift @path, $from;
    }

    return \@path;
}

# add $delta to the weight of the edge ($u, $v)
sub add_edge_weight {
    my ($g, $u, $v, $delta) = @_;

    my $weight = $g->get_edge_weight($u, $v);
    $g->set_edge_weight($u, $v, $weight + $delta);
}

# returns the residual capacity between $u and $v
sub residual_capacity {
    my ($g, $flow, $u, $v) = @_;

    if ($g->has_edge($u, $v)) {
        return $g->get_edge_weight($u, $v) - $flow->get_edge_weight($u, $v);
    } else {
        return -$flow->get_edge_weight($u, $v);
    }
}


1;

=head1 NAME

Graph::MaxFlow - compute maximum flow between 2 vertices in a graph

=head1 SYNOPSIS

  use Graph::MaxFlow qw(max_flow);

  my $g = new Graph;
  # construct graph
  my $flow = max_flow($g, "source", "sink");

=head1 DESCRIPTION

Computes the maximum flow in a graph, represented using Jarkko
Hietaniemi's Graph.pm module.

=head1 FUNCTIONS

This module provides the following function:

=over 4

=item max_flow($g, $s, $t)

Computes the maximum flow in the graph $g between vertices $s and $t
using the Edmonds-Karp algorithm.  $g must be a Graph.pm object, and
must be a directed graph where the edge weights indicate the capacity
of each edge.  The edge weights must be nonnegative.  $s and $t must
be vertices in the graph.  The graph $g must be connected, and for
every vertex v besides $s and $t there must be a path from $s to $t
that passes through v.

The return value is a new directed graph which has the same vertices
and edges as $g, but where the edge weights have been adjusted to
indicate the flow along each edge.

=back

=head1 AUTHOR

Walt Mankowski, E<lt>waltman@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Walt Mankowski

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 ACKNOWLEDGEMENTS

The algorithms are adapted from Introduction to Algorithms, Second
Edition, Cormen-Leiserson-Rivest-Stein, MIT Press.

=cut

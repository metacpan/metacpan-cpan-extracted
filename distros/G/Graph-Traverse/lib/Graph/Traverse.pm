package Graph::Traverse 0.02 {

    use warnings;
    use strict;

    use parent 'Graph';
    use Carp;

    sub traverse {
        # Use as: $graph->search( START_VERTEX, [OPTS])
        #
        # Traverses edges from the start vertex (or verticess) [either
        # a scalar with a single vertex's name, or an array of vertex
        # names, may be passed], finding adjacent vertices using the
        # 'next' function (by default, 'successors'), until either a
        # maximum accumulated edge weight ('max' option, if given) is
        # exceeded (by default using the 'weight' attribute, or
        # specify an 'attribute'), or until a callback function ('cb')
        # returns a nonzero value.  Default is to return the list of
        # vertices encountered in the search; use option 'weights' to
        # return a list of vertex=>weight_value.
        #
        # Use option 'hash=>1' to return a hash where keys are vertex
        # names, and values are a hash containing the 'path' to that
        # vertex from the starting vertex, the 'weight' at that
        # vertex, and 'terminal' the value of the callback function
        # returned for that vertex (if nonzero, further nodes on that
        # branch are not searched).  Note that as we traverse the
        # graph, we may encounter the same vertex several times, but
        # only the shortest path (lowest weight) will be retained in
        # the final hash.
         
        my ($self, $vertex, $opts) = @_;
        carp "Must pass starting vertex" unless defined $vertex;

        my $cb_check = $opts->{cb} if defined $opts;

        my $return_weights = (defined $opts && $opts->{weights});
        my $return_hash = (defined $opts && $opts->{hash});
        my $save_paths = ($return_hash) ? [] : undef;

        # If option 'attribute' is defined, we accumulate weights from each edge.
        # Define 'max' to terminate when a maximum weight is achieved.
        # Define 'vertex' to accumulate vertex weights rather than edge weights.
        # Define 'incr' to change the default weight value from 1.
        my $attr = (defined $opts) ? ($opts->{attribute} // 'weight') : 'weight';
        my $max_weight = $opts->{max} if defined $opts;
        my $add_vertex = $opts->{vertex} if defined $opts;
        my $incr = (defined $opts) ? ($opts->{default} // 1) : 1;  # default weight for each edge

        # Use a method that will return a list of adjacent vertices.
        # Other useful values are 'predecessors' and 'neighbors'.
        my $next = (defined $opts ? ($opts->{next}) : undef) // 'successors'; 

        my (%todo, %path, %weight);
        foreach my $s (@{ref $vertex ? $vertex : [$vertex]}) {
            $todo{$s} = $s;
            $path{$s} = [$s];
            $weight{$s} = 0;
        }
        my %terminal;
        my %seen;
        my %init = %todo;
        while (keys %todo) {
            my @todo = values %todo;
            for my $t (@todo) {
                $seen{$t} = delete $todo{$t};
                for my $s ($self->$next($t)) {
                    next unless $self->has_vertex($s);
                    my $newvalue;
                    if (defined $attr) {
                        if ($add_vertex) { # Add vertex attribute value
                            $newvalue = $weight{$t} + ($self->get_vertex_attribute($s, $attr) // $incr);
                        } else {           # Add edge attribute value (default 'weight', default value 1)
                            # Note, if our search function is 'predecessors' or 'neighbors' we
                            # may find nodes in reverse direction, but we want the edge attributes
                            # in either case
                            $newvalue = $weight{$t} + ($self->get_edge_attribute($t, $s, $attr) //
                                                      $self->get_edge_attribute($s, $t, $attr) //
                                                      $incr);
                        }
                    } else {
                        $newvalue = $weight{$t} + $incr;
                    }
                    # If callback function returns nonzero, do not traverse beyond this node.
                    if (defined $cb_check) {
                        if ($terminal{$s} = &$cb_check($self, $s, $newvalue, $opts)) {
                            $seen{$s} = $s;
                        }
                    }
                    # Do not save vertices beyond a defined maximum weight
                    next if (defined $max_weight) && ($newvalue > $max_weight);
                    # Always save the found vertices.  As we traverse,
                    # we may later encounter shortcuts which we must
                    # discard before the final return (see below).
                    if (defined $save_paths) {
                        my $this_node = { vertex => $s,
                                          path => [@{$path{$t}}, $s],
                                          weight => $newvalue };
                        $this_node->{terminal} = $terminal{$s} if exists $terminal{$s};
                        push @{$save_paths}, $this_node;
                    }
                    # Only save new paths, and shorter-than-previously-found paths.
                    if ((!defined $path{$s}) || ($newvalue < $weight{$s} )) {
                        # If new path is shorter than we previously
                        # found, then retrace all paths from this
                        # vertex onward.
                        delete $seen{$s} if (defined $weight{$s} && $newvalue < $weight{$s});
                        $weight{$s} = $newvalue;
                        $path{$s} = [@{$path{$t}}, $s];
                    }
                    # If callback function returns nonzero, do not
                    # traverse beyond this node.  NOTE: In the case of
                    # multiple paths to the following node, the above
                    # does track the shortest path to the node, but
                    # the caller will not receive every combination of
                    # paths *through* the node.
                    next if ($terminal{$s});
                    $todo{$s} = $s unless exists $seen{$s};
                }
            }
        }
        for my $v (keys %init) {
            delete $seen{$v};
            delete $weight{$v};
        }
        # return $save_paths if defined $return_all;
        if ($return_hash) {
            # Scan list of found vertices, overwriting higher-valued
            # (longer) paths with lower (shorter) ones which were
            # found later.
            my $ret = {};
            foreach my $v (@{$save_paths}) {
                $ret->{$v->{vertex}} = $v if (!defined $ret->{$v->{vertex}} || ($ret->{$v->{vertex}}->{weight} > $v->{weight}));
            }
            return $ret;
        }
        return $return_weights ? (%weight) : (values %seen);
    }

    if (Graph->can('traverse')) {
        carp ('Graph already has a traverse method.');
    } else {
        no warnings 'redefine', 'once'; ## no critic
        *Graph::traverse = \&traverse;
    }

};

1;

__END__

=encoding utf-8

=head1 NAME

Graph::Traverse - A traverse() method for the Graph module.

=head1 SYNOPSIS

    use Graph;
    use Graph::Traverse;

    my $g = Graph->new();
    $g->add_path(qw(A B1 B2 C));
    $g->add_path(qw(A D1 D2 C));

    my $vertices = $g->traverse('A');
    # $vertices now is ['B', 'C', 'D'] or some combination thereof

    my $paths = $g->traverse('A', {hash => 1});
    # $paths contains a hash like this:
    # { 'B1' => { 'vertex' => 'B1',
    #             'path' => ['A', 'B1'],
    #             'weight' => 1 },
    #   'B2' => { 'vertex' => 'B2',
    #             'path' => ['A', 'B1', 'B2'],
    #             'weight' => 2 },
    #   'D1' => { 'vertex' => 'D1',
    #             'path' => ['A', 'D1'],
    #             'weight' => 1 },
    #   'D2' => { 'vertex' => 'D2',
    #             'path' => ['A', 'D1', 'D2'],
    #             'weight' => 2 },
    #   'C' =>  { 'vertex' => 'C',
    #             'path' => ['A', 'D1', 'D2', 'C'],
    #             'weight' => 3 }
    # }

=head1 METHODS

The only method resides in the Graph package (not Graph::Traverse)
so that any descendant of Graph can call it.

=head2 traverse ( START_VERTEX, [ \{OPTS} ] );

=head2 traverse ( \[START_VERTICES] , [ \{OPTS} ] );

Traverses edges from the start vertex (or vertices) [either a single
vertex's name, or an array of vertex names, may be passed], finding
adjacent vertices using the 'next' function (by default,
'successors'), until either a maximum accumulated edge weight ('max'
option, if given) is exceeded (by default using the 'weight'
attribute, or specify an 'attribute'), or until a callback function
('cb') returns a nonzero value.  By default, the return value is the
list of vertices encountered in the search.

Note that as we traverse the graph, we may encounter the same vertex
several times, but only the shortest path (lowest weight) will be
retained.

The following options are available:

=over 8

=item hash

Use with a nonzero value to return a hash where keys are vertex names, and
values are as follows:

=over 4

=item vertex

The current (found) vertex.

=item path

The path from the starting vertex (or one of the starting vertices) to
the current vertex.

=item weight

The accumulated weight from the starting vertex.  By default, each
edge's 'weight' attribute is used; see options 'attribute' and
'vertex'.

=item terminal

If the 'cb' option is provided, this is the value that the function
returned at this vertex.

=back

=item attribute

The edge (or vertex) attribute to use as each edge's (vertex's) weight.

=item max

A maximum weight, above which the traversal will terminate.  If
undefined, the traversal continues either until there are no more
vertices to search (e.g., no further successors), or until the
callback function (if any) returns a nonzero value.

=item default

The default weight value for an edge (or vertex).

=item vertex

If this option is true, accumulate the weight of each successive
vertex, rather than the weights of the edges.

=item cb

A callback function which is called for each discovered vertex.  It is
called as follows:

    &$callback($self, $vertex, $weight, $opts))

Where the arguments are: the Graph object itself; the name of the
current vertex; the accumulated weight at that vertex; and the options
hash as passed to traverse().

If the callback function returns a nonzero value, the successors (or
whatever vertices might be returned by the 'next' function) beyond the
current vertex are not searched.  The callback's value at each vertex
will be saved in the returned hash, if any.

Note that multiple paths to a given vertex may cause multiple
callbacks with varying weights.

=item weights

Use option 'weights', with a nonzero value, to obtain a returned list
of vertex=>weight_value.

=item next

The name of a Graph method to find adjacent vertices.  By default,
'successors' is used; alternate useful values include 'predecessors'
and 'neighbors'.

=back

=head1 AUTHOR

William Lindley E<lt>wlindley@wlindley.comE<gt>

=head1 COPYRIGHT

Copyright 2019, William Lindley

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Graph>

=cut

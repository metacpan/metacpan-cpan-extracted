package Graph::Weighted;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: A weighted graph implementation

our $VERSION = '0.9';

use warnings;
use strict;

use parent qw( Graph );

use Carp qw( croak );
use Readonly;

Readonly my $WEIGHT => 'weight';


sub populate {
    my ($self, $data, $attr) = @_;

    # Set the default attribute.
    $attr ||= $WEIGHT;

    # What type of data are we given?
    my $data_ref = ref $data;

    if ($data_ref eq 'ARRAY' || $data_ref eq 'Math::Matrix') {
        my $vertex = 0; # Initial vertex id.
        for my $neighbors (@$data) {
            $self->_from_array($vertex, $neighbors, $attr);
            $vertex++; # Move on to the next vertex...
        }
    }
    elsif ($data_ref eq 'Math::MatrixReal') {
        my $vertex = 0;
        for my $neighbors (@{ $data->[0] }) {
            $self->_from_array($vertex, $neighbors, $attr);
            $vertex++;
        }
    }
    elsif ($data_ref eq 'HASH') {
        for my $vertex (keys %$data) {
            for my $entry ( keys %{ $data->{$vertex} } ) {
                if ( $entry eq 'label' ) {
                    my $label = delete $data->{$vertex}{$entry};
                    $self->set_vertex_attribute($vertex, $entry, $label);
                }
            }
            $self->_from_hash(
                $vertex, $data->{$vertex}, $attr
            );
        }
    }
    else {
        croak "Unknown data type: $data\n";
    }
}

sub _from_array {
    my ($self, $vertex, $neighbors, $attr) = @_;

    # Initial vertex weight
    my $vertex_weight = 0;

    # Make nodes and edges.
    for my $n (0 .. @$neighbors - 1) {
        my $w = $neighbors->[$n]; # Weight of the edge to the neighbor.
        next unless $w; # TODO Skip zero weight nodes if requested?

        # Add a node-node edge to the graph.
        $self->add_edge($vertex, $n);

        $self->set_edge_attribute($vertex, $n, $attr, $w);

        # Tally the weight of the vertex.
        $vertex_weight += $w;
    }

    # Set the weight of the graph node.
    $self->set_vertex_attribute($vertex, $attr, $vertex_weight);
}

sub _from_hash {
    my ($self, $vertex, $neighbors, $attr) = @_;

    # Initial vertex weight
    my $vertex_weight = 0;

    # Handle terminal nodes.
    if (ref $neighbors) {
        # Make nodes and edges.
        for my $n (keys %$neighbors) {
            my $w = $neighbors->{$n}; # Weight of the edge to the neighbor.

            # Add a node-node edge to the graph.
            $self->add_edge($vertex, $n);

            $self->set_edge_attribute($vertex, $n, $attr, $w);

            # Tally the weight of the vertex.
            $vertex_weight += $w;
        }
    }
    else {
        $vertex_weight = $neighbors;
    }

    # Set the weight of the graph node.
    $self->set_vertex_attribute($vertex, $attr, $vertex_weight);
}


sub get_cost {
    my ($self, $v, $attr) = @_;
    croak 'ERROR: No vertex given to get_cost()' unless defined $v;

    # Default to weight.
    $attr ||= $WEIGHT;

    # Return the edge attribute if given a list.
    return $self->get_edge_attribute(@$v, $attr) || 0 if ref $v eq 'ARRAY';

    # Return the vertex attribute if given a scalar.
    return $self->get_vertex_attribute($v, $attr) || 0;
}


sub vertex_span {
    my ($self, $attr) = @_;

    # Get the cost of each vertex
    my $mass = {};
    for my $vertex ( $self->vertices ) {
        $mass->{$vertex} = $self->get_cost($vertex, $attr);
    }

    # Find the smallest & biggest costs
    my ($smallest, $biggest);
    for my $vertex ( keys %$mass ) {
        my $current = $mass->{$vertex};
        if ( !defined $smallest || $smallest > $current ) {
            $smallest = $current;
        }
        if ( !defined $biggest || $biggest < $current ) {
            $biggest = $current;
        }
    }

    # Collect the lightest & heaviest vertices
    my ($lightest, $heaviest) = ([], []);
    for my $vertex ( keys %$mass ) {
        push @$lightest, $vertex if $mass->{$vertex} == $smallest;
        push @$heaviest, $vertex if $mass->{$vertex} == $biggest;
    }

    return $lightest, $heaviest;
}


sub edge_span {
    my ($self, $attr) = @_;

    # Get the cost of each edge
    my $mass = {};
    for my $edge ( $self->edges ) {
        $mass->{ $edge->[0] . '_' . $edge->[1] } = $self->get_cost($edge, $attr);
    }

    # Find the smallest & biggest costs
    my ($smallest, $biggest);
    for my $edge ( keys %$mass ) {
        my $current = $mass->{$edge};
        if ( !defined $smallest || $smallest > $current ) {
            $smallest = $current;
        }
        if ( !defined $biggest || $biggest < $current ) {
            $biggest = $current;
        }
    }

    # Collect the lightest & heaviest edges
    my ($lightest, $heaviest) = ([], []);
    for my $edge ( sort keys %$mass ) {
        my $arrayref = [ split /_/, $edge ];
        push @$lightest, $arrayref if $mass->{$edge} == $smallest;
        push @$heaviest, $arrayref if $mass->{$edge} == $biggest;
    }

    return $lightest, $heaviest;
}



sub path_cost {
    my ($self, $path, $attr) = @_;

    return unless $self->has_path( @$path );

    my $path_cost = 0;

    for my $i ( 0 .. @$path - 2 ) {
        $path_cost += $self->get_cost( [ $path->[$i], $path->[ $i + 1 ] ], $attr );
    }

    return $path_cost;
}


sub dump {
    my $self = shift;
    my $attr = shift || 'weight';

    for my $vertex ( sort { $a <=> $b } $self->vertices ) {
        my $label = $self->get_vertex_attribute($vertex, 'label');
        printf "%svertex: %s %s=%.2f\n",
            ( $label ? "$label " : '' ),
            $vertex,
            $attr,
            $self->get_cost( $vertex, $attr );
        for my $successor ( sort { $a <=> $b } $self->successors($vertex) ) {
            printf "\tedge to: %s %s=%.2f\n",
                $successor,
                $attr,
                $self->get_cost( [ $vertex, $successor ], $attr );
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graph::Weighted - A weighted graph implementation

=head1 VERSION

version 0.9

=head1 SYNOPSIS

 use Graph::Weighted;

 my $gw = Graph::Weighted->new;
 $gw->populate(
    [ [ 0,1,2,0,0 ], # Vertex 0 with 2 edges of weight 3
      [ 1,0,3,0,0 ], #    "   1      2 "               4
      [ 2,3,0,0,0 ], #    "   2      2 "               5
      [ 0,0,1,0,0 ], #    "   3      1 "               1
      [ 0,0,0,0,0 ], #    "   4      0 "               0
    ]
 );
 $gw->dump();

 my ( $lightest, $heaviest ) = $gw->vertex_span;
 ( $lightest, $heaviest ) = $gw->edge_span;

 my $weight = $gw->path_cost( \@vertices );

 my $attr = 'probability';
 $gw = Graph::Weighted->new;
 $gw->populate(
    {
        0 => { label => 'A', 1=>0.4, 3=>0.6 },
        1 => { label => 'B', 0=>0.3, 2=>0.7 },
        2 => { label => 'C', 0=>0.5, 2=>0.5 },
        3 => { label => 'D', 0=>0.2, 1=>0.8 },
    },
    $attr
 );
 $gw->dump($attr);

=head1 DESCRIPTION

A C<Graph::Weighted> object is a subclass of the L<Graph> module with attribute
handling.  As such, all of the L<Graph> methods may be used, with the addition
of custom weighting.

=head1 METHODS

=head2 new()

  my $gw = Graph::Weighted->new;

Return a new C<Graph::Weighted> object.

Please see L<Graph/Constructors> for the possible constructor arguments.

=head2 populate()

  $gw->populate($matrix);
  $gw->populate($matrix, $attribute);
  $gw->populate(\@vectors);
  $gw->populate(\@vectors, $attribute);
  $gw->populate(\%data_points);
  $gw->populate(\%data_points, $attribute);

Populate a graph with weighted nodes.

The data can be an arrayref of numeric vectors, a C<Math::Matrix> object, a
C<Math::MatrixReal> object, or a hashref of edge values.

Data given as a hash reference may also contain multiple node labels.  Also, the
keys need not be numeric, just unique.

The optional C<attribute> argument is a string with the default "weight."

=head2 get_cost()

  $c = $gw->get_cost($vertex);
  $c = $gw->get_cost($vertex, $attribute);
  $c = $gw->get_cost(\@edge);
  $c = $gw->get_cost(\@edge, $attribute);

Return the named attribute value for the vertex or edge.  If no attribute name
is given, the string "weight" is used.

=head2 vertex_span()

 ($lightest, $heaviest) = $gw->vertex_span();
 ($lightest, $heaviest) = $gw->vertex_span($attr);

Return the lightest and heaviest vertices as array references.

=head2 edge_span()

 ($lightest, $heaviest) = $gw->edge_span();
 ($lightest, $heaviest) = $gw->edge_span($attr);

Return the lightest and heaviest edges as array references.

=head2 path_cost()

 $c = $gw->path_cost(\@vertices);
 $c = $gw->path_cost(\@vertices, $attr);

Return the summed weight (or cost attribute) of the path edges.

For the cost of the shortest path, please see C<path_length> under
L<Graph/"All-Pairs Shortest Paths (APSP)">.

=head2 dump()

  $gw->dump()
  $gw->dump($attr)

Print out the graph showing vertices, edges and costs.

=head1 EXAMPLES

=head2 Shortest Paths

  my $g = Graph::Weighted->new();
  $g->populate({
    A => { B => 4, C => 2 },
    B => { C => 5, D => 10 },
    C => { E => 3 },
    D => { F => 11 },
    E => { D => 4 },
    F => { },
  });
  my @path = $g->SP_Dijkstra( 'A', 'F' ); # A->C->E->D->F
  print 'Dijkstra: ', join( '->', @path ), "\n";

  $g = Graph::Weighted->new();
  $g->populate({
    S => { A =>  7, B => 6 },
    A => { C => -3, T => 9 },
    B => { A =>  8, C => 5, T => -4 },
    C => { B => -5 },
    T => { },
  });
  @path = $g->SP_Bellman_Ford( 'S', 'T' ); # S->A->C->B->T
  print 'Bellman-Ford: ', join( '->', @path ), "\n";

  $g = Graph::Weighted->new();
  $g->populate({
    1 => { 2 => 8, 4 => 1 },
    2 => { 3 => 1 },
    3 => { 1 => 4 },
    4 => { 2 => 2, 3 => 9 },
  });
  my $apsp = $g->APSP_Floyd_Warshall();
  @path = $apsp->path_vertices( 1, 3 ); # 1->4->2->3
  print 'Floyd-Warshall: ', join( '->', @path ), "\n";

=head2 Minimum Spanning Trees

  my $g = Graph::Weighted->new( undirected => 1 );
  $g->populate({
        A => { B => 4, F => 2 },
        B => { C => 6, F => 5 },
        C => { F => 1 },
        D => { },
  });

  my @path = $g->MST_Kruskal; # A=B,A=F,C=F
  print 'Kruskal: ', join( '->', @path ), "\n";

  @path = $g->MST_Prim; # same
  print 'Prim: ', join( '->', @path ), "\n";

=head1 SEE ALSO

L<Graph>, the parent of this module

L<Graph::Easy::Weighted>, the sibling

The F<eg/*> and F<t/*> file sources

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

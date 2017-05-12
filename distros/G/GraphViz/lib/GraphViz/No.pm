package GraphViz::No;

use strict;
use warnings;
use GraphViz;

our @ISA = qw(GraphViz);

our $VERSION = '2.24';

=head1 NAME

GraphViz::No - subclass of GraphViz with no nodes

=head1 SYNOPSIS

  use GraphViz::No;

  my $g = GraphViz::No->new();
  # methods as for GraphViz

=head1 DESCRIPTION

Graphs produced by GraphViz are occasionally huge, making it hard to
observe the structure. This subclass removes the nodes, so that only
the edges are visible. This allows the structure to stand out.

=head1 METHODS

As for GraphViz.

=cut

sub add_node_munge {
    my $self = shift;
    my $node = shift;

    $node->{label}  = '';
    $node->{height} = 0;
    $node->{width}  = 0;
    $node->{style}  = 'invis';
}

sub add_edge_munge {
    my $self = shift;
    my $edge = shift;

    $edge->{color} = rand() . "," . "1,1";
}

=head1 AUTHOR

Leon Brocard E<lt>F<acme@astray.com>E<gt>

=head1 COPYRIGHT

Copyright (C) 2000-1, Leon Brocard

This module is free software; you can redistribute it or modify it under the Perl License,
a copy of which is available at L<http://dev.perl.org/licenses/>.

=cut

1;

package Graph::Reader::LoadClassHierarchy;

use strict;
use warnings;
use Graph;

=head1 NAME

Graph::Reader::LoadClassHierarchy - load Graphs from class hierarchies

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  use Graph;
  use Graph::Reader::LoadClassHierarchy;

  my $reader = Graph::Reader::LoadClassHierarchy->new;
  my $graph  = $reader->read_graph('Foo::Bar');

=head1 DESCRIPTION

B<Graph::Reader::LoadClassHierarchy> is a class for loading a class hierarchy
into a directed graph.

=head1 METHODS

=head2 new

  my $reader = Graph::Reader::LoadClassHierarchy->new;

Constructor - generate a new reader instance. Doesn't take any arguments.

=cut

sub new {
    my ($class) = @_;

    my $self = bless {}, $class;
    return $self;
}

=head2 read_graph

  my $graph = $reader->read_graph( $class_name );

Builds a graph with the class hierarchy of I<$class_name>.

=cut

sub read_graph {
    my ($self, $class_name) = @_;

    my $graph = Graph->new;

    $graph->add_vertex($class_name);
    $self->_read_graph($graph, $class_name);

    return $graph;
}

sub _read_graph {
    my ($self, $graph, $class_name) = @_;

    my @superclasses;
    {
        no strict 'refs';
        @superclasses = @{ $class_name . '::ISA' };
    }

    for my $superclass (@superclasses) {
        $graph->add_vertex($superclass);
        $graph->add_edge( $class_name => $superclass );

        $self->_read_graph($graph, $superclass);
    }
}

=head1 AUTHOR

Florian Ragwitz E<lt>rafl@debian.orgE<gt>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-graph-reader-loadclasshierarchy at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Reader-LoadClassHierarchy>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Graph::Reader::LoadClassHierarchy

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Graph-Reader-LoadClassHierarchy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Graph-Reader-LoadClassHierarchy>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Graph-Reader-LoadClassHierarchy>

=item * Search CPAN

L<http://search.cpan.org/dist/Graph-Reader-LoadClassHierarchy>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Florian Ragwitz, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Graph::Reader::LoadClassHierarchy

#
# Graph::Writer::HTK - perl module for writing a Graph as an HTK lattice
#
package Graph::Writer::HTK;
$Graph::Writer::HTK::VERSION = '2.09';
use 5.006;
use strict;
use warnings;

#=======================================================================
#=======================================================================

use parent 'Graph::Writer';

my @graph_attributes = qw(base lmname lmscale wdpenalty);

my %node_attributes =
(
    'W' => [ 'WORD', 'label' ],
    't' => [ 'time' ],
    'v' => [ 'var' ],
    'L' => [ 'L' ],
);

my %edge_attributes =
(
    'W' => [ 'WORD', 'label' ],
    'v' => [ 'var' ],
    'd' => [ 'div' ],
    'a' => [ 'acoustic' ],
    'n' => [ 'ngram' ],
    'l' => [ 'language', 'weight' ],
);

#=======================================================================
#
# _write_graph
#
# dump the graph out as an HTK lattice to the given filehandle.
#
#=======================================================================
sub _write_graph
{
    my $self  = shift;
    my $graph = shift;
    my $FILE  = shift;

    my $nvertices;
    my $nedges;
    my $v;
    my $from;
    my $to;
    my %v2n;
    my $node_num;
    my $edge_num;


    print $FILE "VERSION=1.0\n";
    print $FILE "N=",int($graph->vertices),"  L=",int($graph->edges),"\n";

    $node_num = 0;
    foreach $v (sort $graph->vertices)
    {
        $v2n{$v} = $node_num;
        print $FILE "I=$node_num";
        foreach my $field (keys %node_attributes)
        {
            foreach my $attr (@{ $node_attributes{$field} })
            {
                if ($graph->has_vertex_attribute($v, $attr))
                {
                    print $FILE "  $field=",
                                $graph->get_vertex_attribute($v, $attr);
                    last;
                }
            }
        }
        print $FILE "\n";
        ++$node_num;
    }

    $edge_num = 0;
    foreach my $edge (sort _by_vertex $graph->edges)
    {
        ($from, $to) = @$edge;
        print $FILE "J=$edge_num  S=", $v2n{$from}, "  E=", $v2n{$to};
        foreach my $field (keys %edge_attributes)
        {
            foreach my $attr (@{ $edge_attributes{$field} })
            {
                if ($graph->has_edge_attribute($from, $to, $attr))
                {
                    print $FILE "  $field=",
                                $graph->get_vertex_attribute($from, $to, $attr);
                    last;
                }
            }
        }
        print $FILE "\n";
        ++$edge_num;
    }

    return 1;
}


sub _by_vertex
{
    return $a->[0].$a->[1] cmp $b->[0].$b->[1];
}


1;

__END__

=head1 NAME

Graph::Writer::HTK - write a perl Graph out as an HTK lattice file

=head1 SYNOPSIS

  use Graph::Writer::HTK;

  $writer = Graph::Reader::HTK->new();
  $reader->write_graph($graph, 'mylattice.lat');

=head1 DESCRIPTION

This module will write a directed graph to a file
in the L<HTK|http://htk.eng.cam.ac.uk> lattice format.
The graph must be an instance of the L<Graph> class.

=head1 SEE ALSO

=over 4

=item L<Graph>

Jarkko Hietaniemi's Graph class and others, used for representing
and manipulating directed graphs. Available from CPAN.
Also described / used in the chapter on directed graph algorithms
in the B<Algorithms in Perl> book from O'Reilly.

=item L<Graph::Writer>

The base-class for this module, which defines the public methods,
and describes the ideas behind Graph reader and writer modules.

=item L<Graph::Reader::HTK>

A class which will read a perl Graph from an HTK lattice file.

=back

=head1 REPOSITORY

L<https://github.com/neilb/Graph-ReadWrite>

=head1 AUTHOR

Neil Bowers E<lt>neil@bowers.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2000-2012, Neil Bowers. All rights reserved.
Copyright (c) 2000, Canon Research Centre Europe. All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


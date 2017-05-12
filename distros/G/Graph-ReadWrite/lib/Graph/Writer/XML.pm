#
# Graph::Writer::XML - write a directed graph out as XML
#
package Graph::Writer::XML;
$Graph::Writer::XML::VERSION = '2.09';
use 5.006;
use strict;
use warnings;

use parent 'Graph::Writer';
use XML::Writer;


#=======================================================================
#
# _write_graph() - perform the writing of the graph
#
# This is invoked from the public write_graph() method,
# and is where the actual writing of the graph happens.
#
# Basically we start a graph element then:
#	[] dump out any attributes of the graph
#	[] dump out all vertices, with any attributes of each vertex
#	[] dump out all edges, with any attributes of each edge
# And then close the graph element. Ta da!
#
#=======================================================================
sub _write_graph
{
    my $self  = shift;
    my $graph = shift;
    my $FILE  = shift;

    my $v;
    my $from;
    my $to;
    my $aref;
    my $xmlwriter;


    $xmlwriter = XML::Writer->new(OUTPUT      => $FILE,
                                  DATA_MODE   => 1,
                                  DATA_INDENT => 2);
    $xmlwriter->setOutput($FILE);

    $xmlwriter->startTag('graph');

    #-------------------------------------------------------------------
    # dump out attributes of the graph, if it has any
    #-------------------------------------------------------------------
    $aref = $graph->get_graph_attributes();
    foreach my $attr (keys %{ $aref })
    {
	$xmlwriter->emptyTag('attribute', 
				'name' => $attr,
				'value' => $aref->{$attr});
    }

    #-------------------------------------------------------------------
    # dump out vertices of the graph, including any attributes
    #-------------------------------------------------------------------
    foreach $v (sort $graph->vertices)
    {
	$aref = $graph->get_vertex_attributes($v);

	if (keys(%{ $aref }) > 0)
	{
	    $xmlwriter->startTag('node', 'id' => $v);

	    foreach my $attr (keys %{ $aref })
	    {
		$xmlwriter->emptyTag('attribute', 
					'name' => $attr,
					'value' => $aref->{$attr});
	    }

	    $xmlwriter->endTag('node');
	}
	else
	{
	    $xmlwriter->emptyTag('node', 'id' => $v);
	}
    }

    #-------------------------------------------------------------------
    # dump out edges of the graph, including any attributes
    #-------------------------------------------------------------------
    foreach my $edge (sort _by_vertex $graph->edges)
    {
	($from, $to) = @$edge;
	$aref = $graph->get_edge_attributes($from, $to);
	if (keys(%{ $aref }) > 0)
	{
	    $xmlwriter->startTag('edge', 'from' => $from, 'to' => $to);

	    foreach my $attr (keys %{ $aref })
	    {
		$xmlwriter->emptyTag('attribute', 
					'name' => $attr,
					'value' => $aref->{$attr});
	    }

	    $xmlwriter->endTag('edge');
	}
	else
	{
	    $xmlwriter->emptyTag('edge', 'from' => $from, 'to' => $to);
	}
    }

    $xmlwriter->endTag('graph');
    $xmlwriter->end();

    return 1;
}

sub _by_vertex
{
    return $a->[0].$a->[1] cmp $b->[0].$b->[1];
}

1;

__END__

=head1 NAME

Graph::Writer::XML - write out directed graph as XML

=head1 SYNOPSIS

    use Graph;
    use Graph::Writer::XML;

    $graph = Graph->new();
    # add edges and nodes to the graph

    $writer = Graph::Writer::XML->new();
    $writer->write_graph($graph, 'mygraph.xml');

=head1 DESCRIPTION

B<Graph::Writer::XML> is a class for writing out a directed graph
in a simple XML format.
The graph must be an instance of the Graph class, which is
actually a set of classes developed by Jarkko Hietaniemi.

The XML format is designed to support the Graph classes:
it can be used to represent a single graph with a collection
of nodes, and edges between those nodes.
The graph, nodes, and edges can all have attributes specified,
where an attribute is a (name,value) pair, with the value being scalar.

=head1 METHODS

=head2 new()

Constructor - generate a new writer instance.

    $writer = Graph::Writer::XML->new();

This doesn't take any arguments.

=head2 write_graph()

Write a specific graph to a named file:

    $writer->write_graph($graph, $file);

The C<$file> argument can either be a filename,
or a filehandle for a previously opened file.

=head1 KNOWN BUGS

Attribute values must be scalar. If they're not, well,
you're on your own.

=head1 SEE ALSO

=over 4

=item L<XML::Writer>

The perl module used to actually write out the XML.
It handles entities etc.

=item L<Graph>

Jarkko Hietaniemi's modules for representing directed graphs,
available from CPAN under modules/by-module/Graph/

=item Algorithms in Perl

The O'Reilly book which has a chapter on directed graphs,
which is based around Jarkko's modules.

=item L<Graph::Writer>

The base-class for Graph::Writer::XML

=back

=head1 REPOSITORY

L<https://github.com/neilb/Graph-ReadWrite>

=head1 AUTHOR

Neil Bowers E<lt>neil@bowers.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2001-2012, Neil Bowers. All rights reserved.
Copyright (c) 2001, Canon Research Centre Europe. All rights reserved.

This script is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


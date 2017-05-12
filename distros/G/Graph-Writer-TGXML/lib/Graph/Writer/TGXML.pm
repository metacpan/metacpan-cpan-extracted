#
# Graph::Writer::TGXML - write a directed graph out as TouchGraph LinkBrowser XML
#
# $Id$
#
package Graph::Writer::TGXML;

use strict;
use warnings;

use Graph::Writer;
use XML::Writer;

use vars qw(@ISA $VERSION);
$VERSION = 0.01;
@ISA = qw(Graph::Writer);


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
#    my %attributes;
    my $xmlwriter;


    $xmlwriter = XML::Writer->new(OUTPUT      => $FILE,
                                  DATA_MODE   => 1,
                                  DATA_INDENT => 2);
    $xmlwriter->setOutput($FILE);

    $xmlwriter->startTag('TOUCHGRAPH_LB', version => '1.20');

    $xmlwriter->startTag('NODESET');

    #-------------------------------------------------------------------
    # dump out vertices of the graph, including any attributes
    #-------------------------------------------------------------------
    foreach $v ($graph->vertices)
    {
        my $attributes = $graph->get_vertex_attributes($v) || {};

#        print ">$v<\n";

        $xmlwriter->startTag('NODE', 'nodeID' => $v);
        $xmlwriter->emptyTag('NODE_LOCATION', 
                             x => 633,
                             y => 30,
                             visible => 'true' );
        $xmlwriter->emptyTag('NODE_LABEL',
                             label => $attributes->{label} || $v,
                             shape => 2,
                             backColor => 'FFFFFF',
                             textColor => '000000',
                             fontSize => 16 );

        $xmlwriter->emptyTag('NODE_URL',
                             url => $attributes->{URL} || '',
                             urlIsLocal  => 'false',
                             urlIsXML =>'false' );

        $attributes->{tooltip} ||= '';
        $attributes->{tooltip} =~ s/\\74/</g;
        $attributes->{tooltip} =~ s/\\76/>/g;
        $xmlwriter->emptyTag('NODE_HINT',
                             hint => $attributes->{tooltip} || '',
                             width => 400,
                             height => -1,
                             isHTML => 'false' );
        $xmlwriter->endTag('NODE');
    }

    $xmlwriter->endTag('NODESET');

    #-------------------------------------------------------------------
    # dump out edges of the graph, including any attributes
    #-------------------------------------------------------------------

    $xmlwriter->startTag('EDGESET');

    my @edges = $graph->edges;
    while (@edges)
    {
        ($from, $to) = splice(@edges, 0, 2);
#        my $attributes = $graph->get_edge_attributes($from, $to);

        $xmlwriter->emptyTag('EDGE',
                             fromID => $from,
                             toID => $to,
                             type => 1,
                             length => 40,
                             visible => 'true',
                             color => 'A0A0A0' );

    }

    $xmlwriter->endTag('EDGESET');

    $xmlwriter->endTag('TOUCHGRAPH_LB');
    $xmlwriter->end();

    return 1;
}

1;

__END__

=head1 NAME

Graph::Writer::TGXML - write out directed graph as TouchGraph LinkBrowser XML

=head1 SYNOPSIS

    use Graph;
    use Graph::Writer::TGXML;
    
    $graph = Graph->new();
    # add edges and nodes to the graph
    
    $writer = Graph::Writer::TGXML->new();
    $writer->write_graph($graph, 'mygraph.xml');

=head1 DESCRIPTION

B<Graph::Writer::TGXML> is a class for writing out a directed graph
in a format suitable for use with TouchGraph's LinkBrowser.
The graph must be an instance of the Graph class, which is
actually a set of classes developed by Jarkko Hietaniemi.

The XML format contains Nodes and Edges. For nodes, the label, URL and 
tooltip attributes are used, for label, url and hint respectively. For
edges, no attributes are currently used.

=head1 METHODS

=head2 new()

Constructor - generate a new writer instance.

    $writer = Graph::Writer::TGXML->new();

This doesn't take any arguments.

=head2 write_graph()

Write a specific graph to a named file:

    $writer->write_graph($graph, $file);

The C<$file> argument can either be a filename,
or a filehandle for a previously opened file.

=head1 KNOWN BUGS

=head1 TODO

Allow users to supply colours, node locations, hint box sizes, and edge lengths.

=head1 SEE ALSO

=over 4

=item XML::Writer

The perl module used to actually write out the XML.
It handles entities etc.

=item Graph

Jarkko Hietaniemi's modules for representing directed graphs,
available from CPAN under modules/by-module/Graph/

=item Algorithms in Perl

The O'Reilly book which has a chapter on directed graphs,
which is based around Jarkko's modules.

=item Graph::Writer

The base-class for Graph::Writer::XML

=item TouchGraph

A java software to navigate through directed graphs. L<http://www.touchgraph.com>

=back

=head1 AUTHOR

Jess Robinson E<lt>jrobinson@desert-island.demon.co.ukE<gt>

=head1 COPYRIGHT

Copyright (c) 2004, 2005, Jess Robinson. All rights reserved.

This script is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


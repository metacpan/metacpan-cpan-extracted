#
# Graph::Writer::daVinci - write a directed graph out in daVinci format
#
package Graph::Writer::daVinci;
$Graph::Writer::daVinci::VERSION = '2.09';
use 5.006;
use strict;
use warnings;

use parent 'Graph::Writer';

#-----------------------------------------------------------------------
# List of valid daVinci attributes for the entire graph, per node,
# and per edge. You can set other attributes, but they won't get
# written out.
#-----------------------------------------------------------------------
my %valid_attributes =
(
    node  => [qw(OBJECT FONTFAMILY FONTSTYLE COLOR CCOLOR _GO _CGO
		ICONFILE CICONFILE HIDDEN BORDER)],

    edge  => [qw(EDGECOLOR EDGEPATTERN _DIR HEAD)],
);

#=======================================================================
#
# _write_graph()
#
# The private method which actually does the writing out in
# daVinci format.
#
# This is called from the public method, write_graph(), which is
# found in Graph::Writer.
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
    my $gn;
    my $aref;
    my @keys;
    my (@nodes, @edges);
    my %done = ();
    my $node;


    @nodes = sort $graph->source_vertices;
    if (@nodes == 0)
    {
        die "expecting source vertices!\n";
    }

    print $FILE "[\n";
    while (@nodes > 0)
    {
        $node = shift @nodes;
        $self->_dump_node($graph, $FILE, $node, \%done, 1);
        print $FILE ",\n" if @nodes > 0;
    }
    print $FILE "\n]\n";

    return 1;

    #-------------------------------------------------------------------
    # Generate a list of edges, along with any attributes
    #-------------------------------------------------------------------
    print $FILE "\n  /* list of edges */\n";
    @edges = sort _by_vertex $graph->edges;
    for (my $i = 0; $i < @edges; $i++)
    {
        ($from, $to) = @{ $edges[$i] };
        print $FILE "  $from -> $to";
        $aref = $graph->get_graph_attributes($from, $to);
        @keys = grep(exists $aref->{$_}, @{$valid_attributes{'edge'}});
        if (@keys > 0)
        {
            print $FILE " [", join(',',
                        map { "$_ = \"".$aref->{$_}."\"" } @keys), "]";
        }
        print $FILE ", " if $i < @edges - 1;
    }

    return 1;
}


sub _by_vertex
{
    return $a->[0].$a->[1] cmp $b->[0].$b->[1];
}


#=======================================================================
#
# _dump_node
#
# Write out a node, using a reference if we've already written it.
# If there are any outgoing edges, we dump them out, recursively
# calling ourself to dump the nodes at the other end of each edge.
#
#=======================================================================
sub _dump_node
{
    my    ($self, $graph, $FILE, $node, $doneref, $depth) = @_;
    my    $aref;
    my    @keys;
    my    @children;
    my    $child;
    local $_;


    if (exists $doneref->{$node})
    {
        print $FILE ' ' x (2 * $depth), "r(\"Node $node\")";
    }
    else
    {
        print $FILE ' ' x (2 * $depth), "l(\"Node $node\", n(\"\"";
        $aref = $graph->get_vertex_attributes($node);
        @keys = grep(exists $aref->{$_}, @{$valid_attributes{'node'}});
        if (@keys > 0)
        {
            print $FILE ", [", join(', ',
                        map { "a(\"$_\", \"".$aref->{$_}."\")" } @keys), "]";
        }
        else
        {
            print $FILE ", []";
        }

        $doneref->{$node} = 1;

        @children = sort $graph->successors($node);
        if (@children == 0)
        {
            print $FILE ", []";
        }
        else
        {
            print $FILE ",\n", ' ' x (2 * $depth + 1), "[\n";
            while (@children > 0)
            {
                $child = shift @children;
                print $FILE ' ' x (2 * $depth + 2),
                            "l(\"Edge ${node}->$child\", e(\"\", [";

                # write out any attributes of the edge
                $aref = $graph->get_edge_attributes($node, $child);
                @keys = grep(exists $aref->{$_}, @{$valid_attributes{'edge'}});
                if (@keys > 0)
                {
                    print $FILE join(', ',
                                map { "a(\"$_\", \"".$aref->{$_}."\")" } @keys);
                }

                print $FILE "],\n";
                $self->_dump_node($graph, $FILE, $child, $doneref, $depth+2);
                print $FILE "))";
                print $FILE ",\n" if @children > 0;
            }
            print $FILE ' ' x (2 * $depth + 1), "]";
        }
        print $FILE "))";
    }
}

1;

__END__

=head1 NAME

Graph::Writer::daVinci - write out directed graph in daVinci format

=head1 SYNOPSIS

  use Graph;
  use Graph::Writer::daVinci;

  $graph = Graph->new();
  # add edges and nodes to the graph

  $writer = Graph::Writer::daVinci->new();
  $writer->write_graph($graph, 'mygraph.davinci');

=head1 DESCRIPTION

B<Graph::Writer::daVinci> is a class for writing out a directed graph
in the file format used by the I<daVinci> tool.
The graph must be an instance of the Graph class, which is
actually a set of classes developed by Jarkko Hietaniemi.

=head1 METHODS

=head2 new()

Constructor - generate a new writer instance.

  $writer = Graph::Writer::daVinci->new();

This doesn't take any arguments.

=head2 write_graph()

Write a specific graph to a named file:

  $writer->write_graph($graph, $file);

The C<$file> argument can either be a filename,
or a filehandle for a previously opened file.

=head1 SEE ALSO

=over 4

=item http://www.b-novative.de/

The home page for the daVinci.

=item L<Graph>

Jarkko Hietaniemi's modules for representing directed graphs,
available from CPAN under modules/by-module/Graph/

=item Algorithms in Perl

The O'Reilly book which has a chapter on directed graphs,
which is based around Jarkko's modules.

=item L<Graph::Writer>

The base-class for Graph::Writer::daVinci

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


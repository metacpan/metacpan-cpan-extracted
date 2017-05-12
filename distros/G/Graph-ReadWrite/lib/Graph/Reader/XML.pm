#
# Graph::Reader::XML - perl class for reading directed graphs from XML
#
package Graph::Reader::XML;
$Graph::Reader::XML::VERSION = '2.09';
use 5.006;
use strict;
use warnings;

use parent 'Graph::Reader';
use Carp;
use XML::Parser;


#=======================================================================
#
# _init()
#
# initialisation private method, invoked by the constructor.
# First call the superclass initialiser, then create an
# instance of XML::Parser, which does most of the work for us.
#
#=======================================================================
sub _init
{
    my $self = shift;

    $self->SUPER::_init();

    #-------------------------------------------------------------------
    # use closures to associate the $self reference with the handler
    # function which will get invoked by the XML::Parser
    #-------------------------------------------------------------------
    $self->{PARSER} = XML::Parser->new(Handlers =>
	{
	    Start => sub { handle_start($self, @_); },
	    End   => sub { handle_end($self, @_); },
	});
}

#=======================================================================
#
# _read_graph
#
# private method where the business is done. Just invoke the
# parse method on the XML::Parser instance. The real business is
# done in the handle_start() and handle_end() "methods", which
# are invoked by the XML parser.
#
#=======================================================================
sub _read_graph
{
    my $self  = shift;
    my $graph = shift;
    my $FILE  = shift;


    $self->{CONTEXT} = [];
    $self->{GRAPH}   = $graph;
    $self->{PARSER}->parse($FILE);

    return 1;
}

#=======================================================================
#
# handle_start
#
# XML parser handler for the start of an element.
#
#=======================================================================
sub handle_start
{
    my ($self, $p, $el, %attr) = @_;
    my $graph = $self->{GRAPH};


    if ($el eq 'attribute')
    {
        if (exists $attr{name} && exists $attr{value})
        {
            $self->set_attribute($attr{name}, $attr{value});
        }
        else
        {
            carp "attribute should have name and value - ignoring\n";
        }
    }
    elsif ($el eq 'node')
    {
        $graph->add_vertex($attr{id});
        push(@{$self->{CONTEXT}}, [$el, $attr{id}]);
    }
    elsif ($el eq 'edge')
    {
        $graph->add_edge($attr{from}, $attr{to});
        push(@{$self->{CONTEXT}}, [$el, $attr{from}, $attr{to}]);
    }
    elsif ($el eq 'graph')
    {
        push(@{$self->{CONTEXT}}, [$el]);
    }
    else
    {
        carp "unknown element \"$el\"\n";
    }
}

#=======================================================================
#
# handle_end
#
# XML parser handler for the end of an element.
#
#=======================================================================
sub handle_end
{
    my ($self, $p, $el) = @_;

    if ($el eq 'node' || $el eq 'edge' || $el eq 'graph')
    {
	pop(@{$self->{CONTEXT}});
    }
}

#=======================================================================
#
# set_attribute
#
# Performs the actual setting of an attribute. Looks at the saved
# context to determine what we're setting an attribute of, and sets
# it on the Graph instance.
#
#=======================================================================
sub set_attribute
{
    my ($self, $name, $value) = @_;


    if (@{$self->{CONTEXT}} == 0)
    {
        carp "attribute element with no context - ignoring!\n";
        return;
    }

    my $graph = $self->{GRAPH};
    my ($el, @args) = @{ (@{$self->{CONTEXT}})[-1] };

    if ($el eq 'node')
    {
        $graph->set_vertex_attribute($args[0], $name, $value);
    }
    elsif ($el eq 'edge')
    {
        $graph->set_edge_attribute($args[0], $args[1], $name, $value);
    }
    elsif ($el eq 'graph')
    {
        $graph->set_graph_attribute($name, $value);
    }
    else
    {
        carp "unexpected context for attribute\n";
    }
}

1;

=head1 NAME

Graph::Reader::XML - class for reading a Graph instance from XML

=head1 SYNOPSIS

  use Graph::Reader::XML;
  use Graph;

  $reader = Graph::Reader::XML->new();
  $graph = $reader->read_graph('mygraph.xml');

=head1 DESCRIPTION

B<Graph::Reader::XML> is a perl class used to read a directed graph
stored as XML, and return an instance of the B<Graph> class.

The XML format is designed to support the Graph classes:
it can be used to represent a single graph with a collection
of nodes, and edges between those nodes.
The graph, nodes, and edges can all have attributes specified,

B<Graph::Reader::XML> is a subclass of B<Graph::Reader>,
which defines the generic interface for Graph reader classes.

=head1 METHODS

=head2 new()

Constructor - generate a new reader instance.

  $reader = Graph::Reader::XML->new();

This doesn't take any arguments.

=head2 read_graph()

Read a graph from a file:

  $graph = $reader->read_graph( $file );

The C<$file> argument can be either a filename
or a filehandle of a previously opened file.

=head1 KNOWN BUGS

Attribute values must be scalar. If they're not,
well, you're on your own.

=head1 SEE ALSO

=over 4

=item Graph::Reader

The base class for B<Graph::Reader::XML>.

=item Graph::Writer::XML

Used to serialise a Graph instance as XML.

=item Graph

Jarkko Hietaniemi's classes for representing directed graphs.

=back

=head1 REPOSITORY

L<https://github.com/neilb/Graph-ReadWrite>

=head1 AUTHOR

Neil Bowers E<lt>neil@bowers.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2001-2012, Neil Bowers. All rights reserved.
Copyright (c) 2001, Canon Research Centre Europe. All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


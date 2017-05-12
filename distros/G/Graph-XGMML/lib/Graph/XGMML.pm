package Graph::XGMML;

=pod

=head1 NAME

Graph::XGMML - Simple Graph.pm-like interface for generating XGMML graphs

=head1 SYNOPSIS

  use Graph::XGMML;
  
  my $output = '';
  my $graph  = Graph::XGMML->new(
      directed => 1,
      OUTPUT   => \$output,
  );
  $graph->add_node('foo');
  $graph->add_node('bar');
  $graph->add_edge('foo', 'bar');
  $graph->end;

=head1 DESCRIPTION

To produce useful diagrams on extremely large graphs, sometimes it is necesary
to move beyond simple graphing tools to applications specifically designed for
rendering very large graphs, many of which were designed for biology
applications (such as my favourite Cytoscape).

B<Graph::XGMML> is a module that can be used to generate export files for
arbitrarily large graphs in B<eXtensible Graph Modelling Markup Language>,
so that the graphs can be imported into these specialised tools.

The API is intentionally designed to appear similar to more popular modules
such as L<Graph>, L<Graph::Easy> and L<GraphViz>.

=head1 METHODS

=cut

use 5.008005;
use strict;
use warnings;
use XML::Writer ();

our $VERSION = '0.01';

=pod

=head2 new

  # Quick constructor to write to a file
  $graph  = Graph::XGMML->new(
      directed => 1,
      OUTPUT   => IO::File->new('file', 'w'),
  );
  
  # Anonymous constructor
  $graph = Graph::XGMML->new(
      directed => 1,
  );

The C<new> constructor is used to create a graph writer.

It takes a single optional boolean C<directed> parameter, which indicates if
the graphs you will be generating will be directed or undirected.

If any additional parameters are passed to C<new>, the constructor will make an
additional call to the C<start> method to start writing the document header and
to open the root C<graph> node, passing it the extra parameters.

Returns a new B<Graph::XGMML> object, or throws an exception (dies) on error.

=cut

sub new {
	my $class = shift;
	my %param = @_;

	# Extract non-writer param
	my $directed = delete($param{directed}) ? 1 : 0;

	# Create the object
	my $self = bless {
		writer   => undef,
		started  => 0,
		directed => $directed,
	}, $class;

	# If we have any params, autostart
	if ( %param ) {
		$self->start( %param );
	}

	return $self;
}

=pod

=head2 start

The C<start> method allows you to explicitly start the document writing, if the
original constructor was produced without additional parameters.

Any parameters are passed directly to the underlying L<XML::Writer> constructor
which produces the object that will be used to generate the XML.

Returns true if the document is started successfully, or throws an exception
(dies) on error.

=cut

sub start {
	my $self = shift;
	$self->{writer} = XML::Writer->new( @_ );
	unless ( $self->{writer} ) {
		die("Failed to create XML::Writer object");
	}
	$self->{writer}->xmlDecl('UTF-8');
	$self->{writer}->doctype(
		'graph',
		'-//John Punin//DTD graph description//EN',
		'http://www.cs.rpi.edu/~puninj/XGMML/xgmml.dtd',
	);
	$self->{writer}->startTag('graph',
		directed => $self->{directed},
	);
	$self->{started} = 1;
	return 1;
}

=pod

=head2 add_node

  # Add a simple node
  $graph->add_node( 'name' );
  
  # Add optional tag attributes
  $graph->add_node( 'name',
      label  => 'Tag Label',
      weight => 100,
  );

The C<add_node> method is used to add a new node to the graph.

Because the B<Graph::XGMML> object doesn't remember its state as it produces
the graph, you must specify all nodes in the graph explicitly.

The first parameter is the identifier for the node. Any additional parameters
will be treated XGMML C<node> element tag pairs.

Returns true or throws an exception (dies) on error.

=cut

sub add_node {
	my $self = shift;
	my $name = shift;
	$self->{writer}->startTag('node',
		id     => $name,
		label  => $name,
		@_,
	);
	$self->{writer}->endTag('node');
	return 1;
}

=pod

=head2 add_vertex

The C<add_vertex> method is an alias to C<add_node>, provided for increased
compatibility with the L<Graph> API.

It takes the same parameters as C<add_node>.

=cut

sub add_vertex {
	shift->add_node(@_);
}

=pod

=head2 add_edge

  # Add a simple edge
  $graph->add_edge( 'foo' => 'bar' );
  
  # Add with optional attributes
  $graph->add_edge( 'foo' => 'bar',
      weight => 1,
  );

The c<add_edge> method adds an edge to the graph.

The first two parameters are the source and target of the edge. Any additional
parameters should be a set of key/value pairs of edge attributes.

Returns true or throws an exception (dies) on error.

=cut

sub add_edge {
	my $self = shift;
	$self->{writer}->emptyTag('edge',
		source => shift,
		target => shift,
		@_,
	);
	return 1;
}

=pod

=head2 end

  # Explicitly terminate the document
  $graph->end;

The C<end> method is used to indicate that the graph is completed that the XML
should be terminated.

If you do not call it yourself, it will be called for you at C<DESTROY>-time.

=cut

sub end {
	my $self = shift;
	$self->{writer}->endTag('graph');
	$self->{writer}->end;
	$self->{started} = 0;
	delete $self->{writer};
	return 1;
}

sub DESTROY {
	if ( $_[0]->{started} ) {
		$_[0]->end;
	}
}

1;

=pod

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-XGMML>

For other issues, contact the maintainer.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Graph>, L<Graph::Easy>, L<GraphViz>

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

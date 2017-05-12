package Graph::Undirected::Components;
use strict;
use warnings;

#use Data::Dump qw(dump);

BEGIN
{
	use Exporter ();
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = '0.31';
	@ISA         = qw(Exporter);
	@EXPORT      = qw();
	@EXPORT_OK   = qw();
	%EXPORT_TAGS = ();
}

# A list is used to hold info about each vertex. The constants
# are the indices into the list.

# VI_PARENT holds the parent vertex of the vertex.
use constant VI_PARENT => 0;

# VI_TIME holds the last access time of the vertex. The access time of a
# root vertex is always greater than all the vertices pointing to it,
#  except the root vertex itself.
use constant VI_TIME => 1;

# For each root vertex VI_SIZE holds the number of vertices pointing to
# it, include itself.
use constant VI_SIZE => 2;

# For each root VI_MIN holds the lexographical min of all the vertices pointing
# to it, including itself.
use constant VI_MIN => 3;

#01234567890123456789012345678901234567891234
#Computes components of an undirected graph.

=head1 NAME

C<Graph::Undirected::Components> - Computes components of an undirected graph.

=head1 SYNOPSIS

  use Data::Dump qw(dump);
  use Graph::Undirected::Components;
  my $componenter = Graph::Undirected::Components->new();
  my $vertices = 10;
  for (my $i = 0; $i < $vertices; $i++)
  {
    $componenter->add_edge (int rand $vertices, int rand $vertices);
  }
  dump $componenter->connected_components ();

=head1 DESCRIPTION

C<Graph::Undirected::Components> computes the components of an undirected
graph using a disjoint set data structure, so the memory used is bounded
by the number of vertices only.

=head1 CONSTRUCTOR

=head2 C<new>

The method C<new> creates an instance of the C<Graph::Undirected::Components>
class; it takes no parameters.

=cut

sub new
{

	# get the object type and create it.
	my ($Class, %Parameters) = @_;
	my $Self = bless({}, ref($Class) || $Class);

	# return the object.
	return $Self->clear();
}

sub clear
{

	# get the object type and create it.
	my $Self = $_[0];

	# set the hash to hold the vertex info (root, size, time).
	$Self->{vertices} = {};

	# keep track of the total vertices and the approximate number of bytes they use.
	$Self->{totalVertices} = 0;
	$Self->{totalSize}     = 0;

	# used to log the last time a vertex was accessed.
	$Self->{counter} = 0;

	# return the object.
	return $Self;
}

=head1 METHODS

=head2 C<add_edge (vertexA, vertexB)>

The method C<add_edge> updates the components of the graph using the edge
C<(vertexA, vertexB)>.

=over

=item vertexA, vertexB

The vertices of the edge C<(vertexA, vertexB)> are Perl strings. If only C<vertexA>
is defined, then the edge C<(vertexA, vertexA)> is added to the graph. The method always returns
undef.

=back

=cut

sub add_edge
{

	# if no edge, return undef now.
	return undef if @_ < 2;

	# get the object.
	my $Self = $_[0];

	# force a loop edge if one node.
	$_[2] = $_[1] if @_ < 3;

	# update the access time of the first node.
	{
		my $vertexInfoX = $Self->get_vertex_info($_[1], 1);
		$vertexInfoX->[VI_TIME] = $Self->{counter}++;
	}

	# update the access time of the second node if different.
	if ($_[1] ne $_[2])
	{
		my $vertexInfoY = $Self->get_vertex_info($_[2], 1);
		$vertexInfoY->[VI_TIME] = $Self->{counter}++;
	}

	# get the info about the roots of the two vertices.
	my $rootOfVertexInfoX = $Self->get_root_vertex_info($_[1]);
	my $rootOfVertexInfoY = $Self->get_root_vertex_info($_[2]);

	# if the vertices have the same root, return now.
	if ($rootOfVertexInfoX == $rootOfVertexInfoY)
	{

		# update the access time of the root.
		$rootOfVertexInfoX->[VI_TIME] = $Self->{counter}++;

		return undef;
	}

	my ($newRoot, $otherRoot);
	if ($rootOfVertexInfoX->[VI_SIZE] > $rootOfVertexInfoY->[VI_SIZE])
	{

		# at this point, the vertices with root X is larger, so point Y to X.
		$rootOfVertexInfoY->[VI_PARENT] = $rootOfVertexInfoX->[VI_PARENT];

		# update the access time of the root.
		$rootOfVertexInfoX->[VI_TIME] = $Self->{counter}++;

		# update the size of the X root.
		$rootOfVertexInfoX->[VI_SIZE] += $rootOfVertexInfoY->[VI_SIZE];

		# set the min vertex for $rootOfVertexInfoX
		$rootOfVertexInfoX->[VI_MIN] = $rootOfVertexInfoY->[VI_MIN] if $rootOfVertexInfoY->[VI_MIN] lt $rootOfVertexInfoX->[VI_MIN];

		# Y is no longer a root, so truncate the array of vertex info.
		$#$rootOfVertexInfoY = 1;
	}
	else
	{

		# at this point, the vertices with root Y is larger (or equal), so point X to Y.
		$rootOfVertexInfoX->[VI_PARENT] = $rootOfVertexInfoY->[VI_PARENT];

		# update the access time of the root.
		$rootOfVertexInfoY->[VI_TIME] = $Self->{counter}++;

		# update the size of the Y root.
		$rootOfVertexInfoY->[VI_SIZE] += $rootOfVertexInfoX->[VI_SIZE];

		# set the min vertex for $rootOfVertexInfoY
		$rootOfVertexInfoY->[VI_MIN] = $rootOfVertexInfoX->[VI_MIN] if $rootOfVertexInfoX->[VI_MIN] lt $rootOfVertexInfoY->[VI_MIN];

		# X is no longer a root, so truncate the array of vertex info.
		$#$rootOfVertexInfoX = 1;
	}

	return undef;
}

=head2 C<getSizeBytes>

The method C<getSizeBytes> returns the aggregate byte length of all the vertices currently in
the graph.

=cut

sub getSizeBytes
{
  return $_[0]->{totalSize};
}


=head2 C<getSizeVertices>

The method C<getSizeVertices> returns the total number of vertices currently in
the graph.

=cut

sub getSizeVertices
{
  return $_[0]->{totalVertices};
}

# returns the vertex info for the root vertex of the vertex.
sub get_root_vertex_info    # ($Vertex)
{

	# get the object.
	my $Self = $_[0];

	# get the info for the vertex.
	my $vertexInfo = $Self->get_vertex_info($_[1], 0);

	# if the parent of $Vertex is $Vertex, then $Vertex is the root.
	return $vertexInfo if ($vertexInfo->[VI_PARENT] eq $_[1]);

	# make the stack.
	my @stack;

	# put the vertex info on the stack.
	push @stack, $vertexInfo;

	# will hold the root of the node.
	my $rootOfVertex;

	while (!defined($rootOfVertex))
	{

		# get the vertex info.
		my $vertexInfo = $stack[-1];

		# get the parent vertex info.
		my $vertexInfoOfParent = $Self->get_vertex_info($stack[-1]->[VI_PARENT], 0);

		# if we found the root, store it and exit the loop.
		if ($vertexInfoOfParent->[VI_PARENT] eq $stack[-1]->[VI_PARENT])
		{
			$rootOfVertex = $vertexInfoOfParent;
			last;
		}

		# push the parent vertex onto the stack.
		push @stack, $vertexInfoOfParent;
	}

	# set the parent of each vertex on the stack to the root.
	for (my $i = 0 ; $i < @stack ; $i++)
	{
		my $vertexInfo = $stack[$i];
		$vertexInfo->[VI_PARENT] = $rootOfVertex->[VI_PARENT];
		delete $vertexInfo->[VI_MIN];
		delete $vertexInfo->[VI_SIZE];
	}

	# return the root of the vertex.
	return $rootOfVertex;
}

# returns the info about the vertex as an array reference
# [root, time, size, min-vertex]
# 0 - root is the root of the vertex
# 1 - time is a counter of when the vertex was last referenced
# size is the number of vertices in the component, it is only define if the vertex is a root
# min-vertex holds the lexographically minimum vertex in the component
sub get_vertex_info    # ($Vertex)
{

	# get the object.
	my ($Self, $Vertex, $Create) = @_;

	# get the hash that holds the info on each vertex.
	my $vertices = $Self->{vertices};

	# if the vertex exists return it.
	return $vertices->{$Vertex} if exists $vertices->{$Vertex};

	# if not allowed to create the vertex then die.
	# confess __LINE__ . ": vertex $Vertex does not exist.\n" unless $Create;

	# the vertex does not exist, so make it and return $Vertex as root.
	$vertices->{$Vertex}            = [];
	$vertices->{$Vertex}[VI_PARENT] = $Vertex;
	$vertices->{$Vertex}[VI_TIME]   = $Self->{counter}++;
	$vertices->{$Vertex}[VI_SIZE]   = 1;
	$vertices->{$Vertex}[VI_MIN]    = $Vertex;
	++$Self->{totalVertices};
	{
		use bytes;
		$Self->{totalSize} += bytes::length($Vertex);
	}
	return $vertices->{$Vertex};
}

=head2 C<connected_components>

The method C<connected_components> returns the components of the graph.
In list context C<connected_components> returns the vertices of the connected components
as a list of array references; in scalar context the list is returned as an array reference.
No specific ordering is applied to
the list of components or the vertices inside the lists.

=cut

sub connected_components
{

	# get the object.
	my $Self = $_[0];

	# get the hash of just the nodes.
	my $components = $Self->connected_components_as_hash();

	# return the components as an array or array reference.
	return (values %$components) if (wantarray);
	return [ values %$components ];
}

=head2 C<get_vertexCompIdPairs (PercentageToKeep)>

The method C<get_vertexCompIdPairs> returns an array reference of pairs of
the form C<[vertex,component-id]>. The parameter C<PercentageToKeep>
sets the percentage of most recently used vertices that are
retained in the graph. This method is used by
L<Graph::Undirected::Components::External> to potentially speedup the
computation of the components.

=cut

sub get_vertexCompIdPairs
{

	# get the object.
	my ($Self, $PercentageToKeep) = @_;

	# get the percentage of nodes to keep.
	$PercentageToKeep = 0 unless defined $PercentageToKeep;
	$PercentageToKeep = abs $PercentageToKeep;
	$PercentageToKeep = 1 if $PercentageToKeep > 1;

	# compute the number of vertices to purge.
	my $verticesToKeep = $Self->{totalVertices};
	$verticesToKeep = int($verticesToKeep * $PercentageToKeep);

	# get the hash of vertices.
	my $vertices = $Self->{vertices};

	# to create list of purged list need the vertices sorted by last
	# access time, so create a list of pairs [vertex, time, compId].
	my @vertexCompId;
	while (my ($vertex, $vertexInfo) = each %$vertices)
	{

		# for each vertex create the pair [vertex, time].
		push @vertexCompId, [ $vertex, $Self->get_root_vertex_info($vertex)->[VI_MIN], $vertexInfo->[VI_TIME] ];
	}

	# reset all the data structures for the object.
	$Self->clear();

	# sort @vertexCompId by time descendingly.
	@vertexCompId = sort { $b->[2] <=> $a->[2] } @vertexCompId;

	# truncate the time from each vertexCompId array.
	foreach my $vertexCompId (@vertexCompId)
	{
		$#$vertexCompId -= 1;
	}

	# add the first $verticesToKeep to the object.
	for (my $i = 0 ; $i < $verticesToKeep ; $i++)
	{
		$Self->add_edge($vertexCompId[$i]->[0], $vertexCompId[$i]->[1]);
	}

	# return the components.
	return \@vertexCompId;
}

# returns the components in a hash with the key of each component
# being the lexographical min of the vertices.
sub connected_components_as_hash
{

	# get the object.
	my $Self = $_[0];

	# get the hash of vertex info.
	my $vertices = $Self->{vertices};

	# get the hash to hold the components.
	my %components;

	while (my ($vertex, undef) = each %$vertices)
	{

		# for each vertex get its root vertex.
		my $rootOfVertexInfo = $Self->get_root_vertex_info($vertex);

		# get the min vertex of the root.
		my $minVertexOfComponent = $rootOfVertexInfo->[VI_MIN];

		# store the node in a list keyed on the $minVertexOfComponent.
		$components{$minVertexOfComponent} = [] unless exists $components{$minVertexOfComponent};
		push @{ $components{$minVertexOfComponent} }, $vertex;
	}

	# return the components.
	return \%components;
}

# used for testing.
sub test_isRootMinForEachComponent
{

	# get the object.
	my $Self = $_[0];

	# get the hash of vertex info.
	my $vertices = $Self->{vertices};

	# get the hash to hold the components.
	my %components;

	while (my ($vertex, undef) = each %$vertices)
	{

		# for each vertex get its root vertex.
		my $rootOfVertexInfo = $Self->get_root_vertex_info($vertex);

		# return false if the min vertex is greater.
		return 0 if $rootOfVertexInfo->[VI_MIN] gt $vertex;
	}

	# return the true.
	return 1;
}

# used for testing.
sub test_areRootsCorrect
{

	# get the object.
	my $Self = $_[0];

	# get the hash of the components.
	my $hashForComponents = $Self->connected_components_as_hash();

	# get the hash to hold the components.
	my %components;

	while (my ($minVertex, $listOfComponents) = each %$hashForComponents)
	{

		# there should be no empty component lists.
		unless ($listOfComponents)
		{
			die "empty component list.\n";
		}

		# get the root vertex (not necessarily the min).
		my $rootOfVertexInfo = $Self->get_root_vertex_info($listOfComponents->[0]);

		# the time of the root should not be less than all the nodes.
		foreach my $vertex (@$listOfComponents)
		{
			my $vertexInfo = $Self->{vertices}{$vertex};
			if ($rootOfVertexInfo->[VI_TIME] < $vertexInfo->[VI_TIME])
			{
				die "access time of root is $rootOfVertexInfo->[VI_TIME] < $vertexInfo->[VI_TIME] the vertex.\n";
			}
		}

		# compare the size of the component list to the size in the root vertex info.
		if ($rootOfVertexInfo->[VI_SIZE] != scalar(@$listOfComponents))
		{
			my $realSize = scalar(@$listOfComponents);
			warn "component sizes $rootOfVertexInfo->[VI_SIZE] != $realSize do not match.\n";
			return 0;
		}

	}

	# return the true.
	return 1;
}

=head1 INSTALLATION

Use L<CPAN> to install the module and all its prerequisites:

  perl -MCPAN -e shell
  cpan[1]> install Graph::Undirected::Components

=head1 BUGS

Please email bugs reports or feature requests to C<bug-graph-undirected-components@rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Undirected-Components>.  The author
will be notified and you can be automatically notified of progress on the bug fix or feature request.

=head1 AUTHOR

 Jeff Kubina<jeff.kubina@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2009 Jeff Kubina. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 KEYWORDS

connected components, network, undirected graph

=head1 SEE ALSO

L<Graph>

=begin html

<a href="http://en.wikipedia.org/wiki/Connected_component_%28graph_theory%29">connected component</a>,
<a href="http://en.wikipedia.org/wiki/Disjoint-set_data_structure">disjoint set data structure</a>,
<a href="http://en.wikipedia.org/wiki/Graph_(mathematics)">graph</a>,
<a href="http://en.wikipedia.org/wiki/Network_theory">network</a>,

=end html

=cut

1;

# The preceding line will help the module return a true value

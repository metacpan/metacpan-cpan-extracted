############################################################################
# Convert between Graph::Easy and Graph.
#
#############################################################################

package Graph::Convert;

use 5.008001;
use Graph::Easy;
use Graph;

$VERSION = '0.09';

use strict;

#############################################################################
# conversion

sub _add_basics
  {
  # Add the graph and class attributes from $in to $out
  # Add all the nodes
  # Add the groups as pseudo_attributes to the graph (so we can recover them)
  my ($self, $in, $out) = @_;

  # add the graph attributes
  my $att = $in->{att};

  for my $class (keys %$att)
    {
    my $c = $att->{$class};
    for my $attr (keys %$c)
      {
      $out->set_graph_attribute($class.'_'.$attr, $c->{$attr});
      }
    }

  # add all nodes (sorted by ID so we can workaround the bug in Graph
  # for undirected graphs)
  for my $n (sort { $a->{id} <=> $b->{id} } $in->nodes())
    {
    # the node name is unique, so we can use it as the "vertex id"
    $out->add_vertex($n->{name});
    my $attr = $n->raw_attributes();
    # store also the node's group
    my $ng = $n->group();
    if (defined $ng)
      {
      $attr->{group} = $ng->name();
      }
    $out->set_vertex_attributes($n->{name}, $attr);
    }

  # add all groups as a special attribute list
  for my $g ($in->groups())
    {
    my $attr = $g->raw_attributes();
    # "group_" is already used by the class attribute
    my $prefix = 'grp_' . $g->id() . '_';
    # store the group name, too
    $out->set_graph_attribute($prefix.'name', $g->name());
    my $group_group = $g->group();
    if (defined $group_group)
      {
      $out->set_graph_attribute($prefix.'group', $group_group->name());
      }
    for my $k (keys %$attr)
      {
      $out->set_graph_attribute($prefix.$k, $attr->{$k});
      }
    }

  $out;
  }

#############################################################################
# from Graph::Easy to Graph:

sub as_graph
  {
  # convert a Graph::Easy object to a Graph object
  my ($self, $in, $opt) = @_;

  $self->error(
    "as_graph needs a Graph::Easy object, but got '". ref($in). "'" )
   unless ref($in) && $in->isa('Graph::Easy');
  
  $opt = {} unless defined $opt;
  $opt->{undirected} = 1 if $in->attribute('type') eq 'undirected';

  return $self->as_multiedged_graph($in, $opt) unless $in->is_simple();

  my $out = Graph->new( %$opt ); 

  $self->_add_basics($in,$out);

  # add all edges
  for my $e ($in->edges())
    {
    my $from = $e->{from}->{name}; my $to = $e->{to}->{name};
    if ($opt->{undirected})
      {
      # swap the arguments to avoid creating a spurious edge
      ($from,$to) = ($to,$from) if $e->{to}->{id} < $e->{from}->{id};
      }
    my $edge = $out->add_edge($from,$to);
    my $attr = $e->raw_attributes();
    $out->set_edge_attributes($from, $to, $attr);
    }

  $out;
  }

sub as_undirected_graph
  {
  # convert a Graph::Easy object to an undirected Graph object
  my ($self, $in, $opt) = @_;

  $opt->{undirected} = 1;
  $self->as_graph($in,$opt);
  }

sub as_multiedged_graph
  {
  my ($self, $in, $opt) = @_;

  $self->error(
    "as_multiedged_graph needs a Graph::Easy object, but got '". ref($in). "'" )
   unless ref($in) && $in->isa('Graph::Easy');

  $opt = {} unless defined $opt; 
  $opt->{multiedged} = 1;
  my $out = Graph->new( %$opt );

  $self->_add_basics($in,$out);

  # add all edges
  for my $e ($in->edges())
    {
    # Adding an edge more than once will result in a new ID
    my $from = $e->{from}->{name}; my $to = $e->{to}->{name};
    if ($opt->{undirected})
      {
      # swap the arguments to avoid creating a spurious edge
      ($from,$to) = ($to,$from) if $e->{to}->{id} < $e->{from}->{id};
      }
    my $id = $out->add_edge_get_id($from,$to);
    my $attr = $e->raw_attributes();
    $out->set_edge_attributes_by_id($from, $to, $id, $attr);
    }

  $out;
  }

#############################################################################
# from Graph to Graph::Easy:

sub as_graph_easy
  {
  # convert a Graph object to a Graph::Easy object
  my ($self,$in) = @_;
 
  $self->error(
    "as_graph_easy needs a Graph object, but got '". ref($in). "'" )
   unless ref($in) && $in->isa('Graph');
 
  my $out = Graph::Easy->new(); 

  my $group_ids = {};
  # restore the graph attributes (and create all the group objects)
  my $att = $in->get_graph_attributes();
  for my $key (keys %$att)
    {
    if ($key =~ /^grp_([0-9]+)_([A-Za-z_-]+)/)
      {
      my ($id,$a) = ($1,$2);
      # create the group unless we already created it
      if (!exists $group_ids->{$id})
        {
        my $group_name = $att->{"grp_${id}_name"} || 'unknown group name';
        $group_ids->{$id} = $out->add_group( $group_name );
        }
      my $grp = $group_ids->{$id};
      # set the attribute on the appropriate group object
      $grp->set_attribute($a, $att->{$key}) unless $a eq 'name';
      }
    next unless $key =~ /^((graph|(node|edge|group))(\.\w+)?)_(.+)/;

    my $class = $1; my $name = $5;

    $out->set_attribute($1,$5, $att->{$key});
    }

  for my $n ($in->vertices())
    {
    my $node = $out->add_node($n);
    my $attr = $in->get_vertex_attributes($n);
    $node->set_attributes($attr);
    }

  if ($in->is_multiedged())
    {
    # for multiedged graphs:
    for my $e ($in->unique_edges())
      {
      # get all the IDs in case of the edge existing more than once:
      my @ids = $in->get_multiedge_ids($e->[0], $e->[1]);
      for my $id (@ids)
        {
        my $edge = $out->add_edge($e->[0],$e->[1]);
        my $attr = $in->get_edge_attributes_by_id($e->[0], $e->[1], $id);
        $edge->set_attributes($attr);
        }
      }
    }
  else
    {
    # for simple graphs
    for my $e ($in->edges())
      {
      my $edge = $out->add_edge($e->[0],$e->[1]);
      my $attr = $in->get_edge_attributes($e->[0], $e->[1]);
      $edge->set_attributes($attr);
      }
    }
  $out->set_attribute('type','undirected') if $in->is_undirected();

  $out;
  }

1;
__END__

=head1 NAME

Graph::Convert - Convert between graph formats: Graph and Graph::Easy

=head1 SYNOPSIS

	use Graph::Convert;
	
	my $graph_easy = Graph::Easy->new();
	$graph_easy->add_edge ('Bonn', 'Berlin');
	$graph_easy->add_edge ('Berlin', 'Berlin');

	# from "Graph::Easy" to "Graph"
	my $graph = Graph::Convert->as_graph ( $graph_easy );
	
	# and back to "Graph::Easy"
	my $ge = Graph::Convert->as_graph_easy ( $graph );

	print $ge->as_ascii( );

	# Outputs something like:

	#                +----+
	#                v    |
	# +------+     +--------+
	# | Bonn | --> | Berlin |
	# +------+     +--------+

=head1 DESCRIPTION

C<Graph::Convert> lets you convert graphs between the graph formats
from L<Graph> and L<Graph::Easy>.

It takes a graph object in either format, and converts it to the desired
output format. It handles simple graphs (directed or undirected) as well
as multi-edged graphs, and also carries the attributes over.

This enables you to use all the layout and formatting capabilities
of C<Graph::Easy> on C<Graph> objects, as well as using the extensive
graph algorithms and manipulations of C<Graph> on C<Graph::Easy> objects.

X<graph>
X<easy>
X<graph-easy>
X<conversion>
X<convert>

=head2 Graph vs. Graph::Easy

Both C<Graph> and C<Graph::Easy> represent graphs, e.g. vertices (or nodes)
connected by edges. These graphs can have (arbitrary) attributes attached
to the graph, nodes or edges.

Both formats can serialize the graph by creating a text-representation,
but unlike C<Graph::Easy>, C<Graph> is not able to create the graph back
from the string form.

There are, however, some slight differences between these two packages:

=over 12

=item Graph

C<Graph> has different representations for multi-edges and simple graphs,
making it somewhat complicated to switch between these two.

It does have an extensive set of algorithms to manipulate the graph, but no
layout capabilities.

C<Graph> does not support the notion of subgraphs (or "groups" as they are
called in C<Graph::Easy>). While you could assign some sort of group attribute
to nodes, this would have no special meaning to the Graph module.

=item Graph::Easy

C<Graph::Easy> uses the same representation for multi-edged and simple graphs,
but has only basic operations to manipulate the graph and its contents.

It has, however, a build-in layouter which can lay out the graph on a
grid, as well the ability to output Graphviz and VCG/GDL code. This enables
output of ASCII, HTML, SVG and all the formats that graphviz supports, like
PDF or PNG.

C<Graph::Easy> supports subgraphs (aka groups).

In addition, C<Graph::Easy> supports class attributes. By setting the
attribute for a class and putting objects (nodes/edges etc) into
the proper class, it is easier to manipulate attributes for many
objects at once.

=back

=head1 METHODS

C<Graph::Convert> supports the following methods:

=head2 as_graph()

	use Graph::Convert;

	my $graph_easy = Graph::Easy->new( );
	$graph_easy->add_edge('A','B');
	my $graph = Graph::Convert->as_graph( $graph_easy );

	my $undirected_graph = 
	   Graph::Convert->as_graph( $graph_easy, { undirected => 1 } );

Converts the given L<Graph::Easy> object into a L<Graph> object.

This routine creates either a simple or a multiedged graph, depending
on whether the input L<Graph::Easy> object is a simple graph or not.

If you want to force the output to be a multiedged graph object, use
L<as_multiedged_graph>.

Forcing the output to be a simple graph when the input is multi-edged
is not supported, as that would require to drop arbitrary edges from
the input.

The optional parameter is an hash ref with options that is passed
to C<< Graph->new() >>.

Directed and undirected input graphs result automatically in the appropritate
type of C<Graph> object being created, but you can force the creation
of an undirected graph by either passing C<< { undirected => 1 } >> as
option or use L<as_undirected_graph()>.

=head2 as_undirected_graph()

	use Graph::Convert;

	my $graph_easy = Graph::Easy->new( );
	$graph_easy->add_edge('A','B');
	my $graph = Graph::Convert->as_undirected_graph( $graph_easy );

Converts the given L<Graph::Easy> object into an undirected L<Graph>
object, regardless whether the input graph is a directed graph or not.

=head2 as_multiedged_graph()

	use Graph::Convert;

	my $graph_easy = Graph::Easy->new( );
	$graph_easy->add_edge('A','B');
	my $graph = Graph::Convert->as_multiedged_graph( $graph_easy );

Converts the given L<Graph::Easy> object into a multi-edged L<Graph>
object, even if the input graph is a simple graph (meaning there
is only one edge going from node A to node B).

To create a multi-edged undirected graph, pass in C<< { undirected => 1 } >>
as option:

	use Graph::Convert;

	my $graph_easy = Graph::Easy->new( );
	$graph_easy->add_edge('A','B');
	my $graph = Graph::Convert->as_multiedged_graph( $graph_easy, 
		{ undirected => 1 } );

=head2 as_graph_easy()

	use Graph::Convert;

	my $graph = Graph->new( );
	$graph_easy->add_edge('A','B');
	my $graph_easy = Graph::Convert->as_graph_easy( $graph_easy );

Converts the given L<Graph> object into a L<Graph::Easy> object.

This routine handles simple (directed or undirected) as well as multi-edged
graphs automatically.

Multi-vertexed graphs are not supported e.g. each node must exist only once
in the input graph.

=head1 SEE ALSO

L<Graph>, L<Graph::Easy> and L<Graph::Easy::Manual>.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL version 2 or later.

See the LICENSE file for a copy of the GPL 2.

X<gpl>
X<license>

=head1 AUTHOR

Copyright (C) 2006 - 2007 by Tels L<http://bloodgate.com>

X<tels>

=cut

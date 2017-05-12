=head1 NAME

Graph::Layouter - lay out graph onto an abstract plane

=cut


package Graph::Layouter;

use strict;
use Carp qw (croak);

use vars qw ($VERSION @ISA @EXPORT_OK);

# $Id: Layouter.pm,v 1.3 2006/02/11 17:11:39 pasky Exp $
$VERSION = 0.03;


=head1 SYNOPSIS

  my $graph = new Graph;
  ...

  use Graph::Layouter qw(layout);
  my $layouted = layout($graph);

  use Graph::Layouter;
  my $layouted = Graph::Layouter->layout($graph);
  ...
  $layouted->layout();

=cut


use base qw (Graph);

require Exporter;
push @ISA, 'Exporter';

@EXPORT_OK = qw (layout);


=head1 DESCRIPTION

This module provides an abstract class for various algorithms of graph nodes
positioning at a virtual surface. That is, if you have a graph stuffed into a
C<Graph> object, C<Graph::Layouter> will take it and assign each node in the
graph virtual coordinates in a plane.

C<Graph::Layouter> does not do anything besides assigning the coordinates ---
you will need to have the nodes and edges laid out to some real plane on your
own, or use a bundled C<Graph::Renderer> modules family.

This module contains only the abstract class, you will probably want to get an
instance of some particular layouting algorithm instead;
C<Graph::Layouter::Spring> is bundled with this distribution. The general
interface for all the subclasses is described below, but be sure consult also
the particular class' documentation for remarks, special notes and specific
extensions.


=head2 Interface

=over 4

=cut


use Graph;


=item B<layout()>

This subroutine is the only entry point of this module, taking a given graph
and laying it out appropriately. The subroutine can be called in several ways:

=over 4

=item I<Functional interface>

The subroutine can be called as a function (it is not automatically exported,
but you can import it on your own if you really want; see the synopsis above).
It takes one parameter, the C<Graph> class (or any descendant) instance. It
will set the layout back into the graph and return its parameter back for
convenience.

=item I<Class constructor interface>

The subroutine can be called as a class constructor, like C<$g =
Graph::Layouter->layout($graph)>. It will take the C<$graph>, do stuff on it
and returns reference to C<$graph> back, however reblessed to a
C<Graph::Layouter> instance.

In human language this means that after the call C<$graph> will still be the
original object, only with some more attributes attached, whereas C<$g> will be
a C<Graph::Layouter> instance; however any changes to C<$g> will be propagated
to C<$graph> and vice versa.

=item I<Class method interface>

When you already got a C<Graph::Layouter> instance, you can call this
subroutine as C<$g->layout()>. It will relayout an already layouted graph.

=back

=cut

sub layout {
	my $graph = shift;

	croak "You want to use some subclass instead!";
	$graph;
}


# Make sure the appropriate attributes are set up on all the nodes.
#
# This is a private device for subclasses, which are expected to call this in
# layout, when they are just about to start doing the work. Note that some
# subclasses might want to set the attributes to a different initial value or
# so.
sub _layout_prepare($) {
	my $graph = shift;

	foreach my $vertex ($graph->vertices) {
		$graph->set_vertex_attribute($vertex, 'layout_pos1', 0);
		$graph->set_vertex_attribute($vertex, 'layout_pos2', 0);
		$graph->set_vertex_attribute($vertex, 'layout_force1', 0);
		$graph->set_vertex_attribute($vertex, 'layout_force2', 0);
	}

	$graph;
}

# Calculate the bounding coordinate values (min/max extremes in a given
# dimension) and store them into global graph attributes.
#
# This is a private device for subclasses, which are expected to call this in
# layout, when they are already done with the work.
sub _layout_calc_bounds($) {
	my $graph = shift;

	# Make sure Perl does not emit a metric ton of warnings blab when
	# counting with infinity numbers. Blah.

	local $^W = 0;

	my ($minx, $maxx, $miny, $maxy) = ('Infinity', -'Infinity', 'Infinity', -'Infinity');

	foreach my $vertex ($graph->vertices) {
		my @pos = ($graph->get_vertex_attribute($vertex, 'layout_pos1'),
		           $graph->get_vertex_attribute($vertex, 'layout_pos2'));
		$maxx = $pos[0] if $pos[0] > $maxx;
		$minx = $pos[0] if $pos[0] < $minx;
		$maxy = $pos[1] if $pos[1] > $maxy;
		$miny = $pos[1] if $pos[1] < $miny;
	}

	$graph->set_graph_attribute('layout_min1', $minx);
	$graph->set_graph_attribute('layout_max1', $maxx);
	$graph->set_graph_attribute('layout_min2', $miny);
	$graph->set_graph_attribute('layout_max2', $maxy);
	$graph;
}


=back

=head2 Data encoding

The layouting function saves the layout data (coordinates of nodes) back to the
C<Graph> object, in a form of vertex attributes - C<layout_pos1> and
C<layout_pos2> (C<pos1> is the x dimension, C<pos2> the y dimension; it is
planned to make it possible to layout in three or unlimited number of
dimensions space).

We also provide C<layout_min1>, C<layout_max1> as well as C<layout_min2>,
C<layout_max2> global graph attributes, containing the extreme values in the
respective dimensions. This is usually needed to properly map the virtual
coordinates to some physical points.

If you intend to use C<Graph> attributes in conjunction with the
C<Graph::Layouter>, you are advised not to infrige the C<layout_> namespace. If
you are writing a C<Graph::Layouter> subclass, you are advised to put your
attributes to a C<layout__subclassname_> namespace.


=head1 SEE ALSO

C<Graph>, C<Graph::Renderer>


=head1 BUGS

Some more universal layout calling interface (hash parameters) is missing.


=head1 COPYRIGHT

Copyright 2004 by Petr Baudis E<lt>pasky@ucw.czE<gt>.

This code is distributed under the same copyright terms as
Perl itself.


=head1 VERSION

Version 0.03

$Id: Layouter.pm,v 1.3 2006/02/11 17:11:39 pasky Exp $

=cut

1;

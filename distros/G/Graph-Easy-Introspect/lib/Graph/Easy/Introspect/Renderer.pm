package Graph::Easy::Introspect::Renderer ;

use strict ;
use warnings ;

our $VERSION = '0.01' ;

# ------------------------------------------------------------------------------

sub new
{
my ($class) = @_ ;

return bless {}, $class ;
}

# ------------------------------------------------------------------------------

sub draw_box
{
my ($self, $x, $y, $w, $h, $text) = @_ ;

printf STDERR "draw_box         x=%-3d y=%-3d w=%-3d h=%-3d text=%s\n",
	$x, $y, $w, $h, $text // '' ;
}

# ------------------------------------------------------------------------------

sub draw_rounded_box
{
my ($self, $x, $y, $w, $h, $text) = @_ ;

printf STDERR "draw_rounded_box x=%-3d y=%-3d w=%-3d h=%-3d text=%s\n",
	$x, $y, $w, $h, $text // '' ;
}

# ------------------------------------------------------------------------------

sub draw_diamond
{
my ($self, $x, $y, $w, $h, $text) = @_ ;

printf STDERR "draw_diamond     x=%-3d y=%-3d w=%-3d h=%-3d text=%s\n",
	$x, $y, $w, $h, $text // '' ;
}

# ------------------------------------------------------------------------------

sub draw_circle
{
my ($self, $x, $y, $w, $h, $text) = @_ ;

printf STDERR "draw_circle      x=%-3d y=%-3d w=%-3d h=%-3d text=%s\n",
	$x, $y, $w, $h, $text // '' ;
}

# ------------------------------------------------------------------------------

sub draw_point
{
my ($self, $x, $y) = @_ ;

printf STDERR "draw_point       x=%-3d y=%-3d\n", $x, $y ;
}

# ------------------------------------------------------------------------------

sub draw_invisible
{
my ($self, $x, $y, $w, $h) = @_ ;

printf STDERR "draw_invisible   x=%-3d y=%-3d w=%-3d h=%-3d\n", $x, $y, $w, $h ;
}

# ------------------------------------------------------------------------------

sub draw_arrow
{
my ($self, $start_style, $end_style, $points) = @_ ;

my $pts = join ' -> ', map { "($_->{char_x},$_->{char_y})" } @$points ;

printf STDERR "draw_arrow       start=%-6s end=%-6s  %s\n",
	$start_style, $end_style, $pts ;
}

# ------------------------------------------------------------------------------

sub draw_self_loop
{
my ($self, $x, $y, $w, $h, $side) = @_ ;

printf STDERR "draw_self_loop   x=%-3d y=%-3d w=%-3d h=%-3d side=%s\n",
	$x, $y, $w, $h, $side // 'unknown' ;
}

# ------------------------------------------------------------------------------

sub draw_edge_label
{
my ($self, $x, $y, $text) = @_ ;

printf STDERR "draw_edge_label  x=%-3d y=%-3d text=%s\n", $x, $y, $text // '' ;
}

# ------------------------------------------------------------------------------

sub draw_group
{
my ($self, $x, $y, $w, $h, $text) = @_ ;

printf STDERR "draw_group       x=%-3d y=%-3d w=%-3d h=%-3d text=%s\n",
	$x, $y, $w, $h, $text // '' ;
}

# ------------------------------------------------------------------------------

sub draw_graph_label
{
my ($self, $x, $y, $total_w, $text) = @_ ;

printf STDERR "draw_graph_label x=%-3d y=%-3d total_w=%-3d text=%s\n",
	$x, $y, $total_w, $text // '' ;
}

1 ;

__END__

=pod

=head1 NAME

Graph::Easy::Introspect::Renderer - Base renderer class for Graph::Easy AST output

=head1 SYNOPSIS

  use Graph::Easy::Introspect::Renderer;

  my $r = Graph::Easy::Introspect::Renderer->new;

Subclassing:

  package My::Renderer;
  use parent 'Graph::Easy::Introspect::Renderer';

  sub draw_box
  {
  my ($self, $x, $y, $w, $h, $text) = @_;
  # real output here
  }

=head1 DESCRIPTION

Base class for renderers that consume the AST produced by C<Graph::Easy::Introspect>.

The default implementation of every drawing method prints its name and
arguments to STDERR. This makes the base class immediately useful for
verifying what a graph produces without writing any real rendering code.

To build a real renderer, subclass this module and override whichever
methods are relevant. Unoverridden methods continue to print to STDERR,
making it easy to discover which calls are being made during development.

All coordinate arguments are in character space as provided by the AST.
See L<Graph::Easy::Introspect> for the definition of character space.

=head1 METHODS

=head2 new

  my $r = Graph::Easy::Introspect::Renderer->new;

Constructs a renderer instance. The base class holds no state; subclasses
may use the blessed hashref for their own purposes.

=head2 draw_box($x, $y, $w, $h, $text)

Draw a rectangular node. C<$x> and C<$y> are the character-space top-left
corner of the box. C<$w> and C<$h> are the rendered width and height in
character columns and rows. C<$text> is the display label.

=head2 draw_rounded_box($x, $y, $w, $h, $text)

Draw a node with rounded corners. Arguments identical to C<draw_box>.

=head2 draw_diamond($x, $y, $w, $h, $text)

Draw a diamond-shaped node. Arguments identical to C<draw_box>.

=head2 draw_circle($x, $y, $w, $h, $text)

Draw a circle or ellipse node. Arguments identical to C<draw_box>.

=head2 draw_point($x, $y)

Draw a point node. No border and no label; only a position is needed.

=head2 draw_invisible($x, $y, $w, $h)

Called for nodes with shape C<invisible>. The node occupies layout space
but nothing is drawn.

=head2 draw_arrow($start_style, $end_style, \@points)

Draw a routed edge as a polyline.

C<$start_style> and C<$end_style> each take one of the values C<'none'>
or C<'arrow'>. For a directed edge C<$end_style> is C<'arrow'> and
C<$start_style> is C<'none'>. For a bidirectional edge both are C<'arrow'>.
For an undirected edge both are C<'none'>.

C<\@points> is an arrayref of waypoint hashrefs in path order from source to
target, forming a rectilinear polyline in character space. Each waypoint has
C<char_x> and C<char_y>. Corner waypoints additionally carry C<type> (e.g.
C<N_W>, C<S_E>) to identify the bend direction. The first waypoint is the
from-node face attachment point; the last is the to-node face attachment
point. HOR and VER segments are implicit between consecutive waypoints and
contribute no entries of their own.

=head2 draw_self_loop($x, $y, $w, $h, $side)

Draw a self-loop anchored to a node. C<$x>, C<$y>, C<$w>, C<$h> are the
character-space box of the node. C<$side> is the face the loop exits and
re-enters: one of C<'left'>, C<'right'>, C<'top'>, C<'bottom'>, or
C<'unknown'>.

=head2 draw_edge_label($x, $y, $text)

Draw a floating edge label. C<$x> and C<$y> are the character-space
position of the label cell as determined by Graph::Easy's layout.

=head2 draw_group($x, $y, $w, $h, $text)

Draw the border of a node group. C<$x>, C<$y>, C<$w>, C<$h> are the
character-space extent of the group boundary including its border cells.
C<$text> is the group label.

=head2 draw_graph_label($x, $y, $total_w, $text)

Draw the graph-level title. C<$x> and C<$y> are the character-space
top-left of the label area. C<$total_w> is the total character width of
the rendered output, available for centering. C<$text> is the label string.

=head1 SEE ALSO

L<Graph::Easy::Introspect>, the C<graph_easy_render> script.

=head1 AUTHOR

Nadim Khemir E<lt>nadim.khemir@gmail.comE<gt>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

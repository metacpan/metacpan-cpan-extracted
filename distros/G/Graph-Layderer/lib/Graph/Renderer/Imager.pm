=head1 NAME

Graph::Renderer::Imager - graph rendering interface for Imager

=cut


package Graph::Renderer::Imager;

use strict;
use Carp qw (croak);

use vars qw ($VERSION @ISA @EXPORT_OK);

# $Id: Imager.pm,v 1.5 2006/02/11 17:11:39 pasky Exp $
$VERSION = 0.03;


=head1 SYNOPSIS

  use Graph::Renderer::Imager;
  Graph::Renderer::Imager::render($graph, $img);

=cut


use base qw (Graph::Renderer);

require Exporter;
push @ISA, 'Exporter';

@EXPORT_OK = qw (render);


=head1 DESCRIPTION

This module provides graph drawing through the C<Imager> module. It takes an
C<Imager> object as the second parameter; it is best when the image has 4
channels.

=cut


use Graph;
use Imager;


=head2 Global attributes

=over 4

=item B<renderer_vertex_font>

This can be either full path to the font or an C<Imager::Font> object
reference.

=back


=head2 Vertex attributes

=over 4

=item B<renderer_vertex_font>

This can be either full path to the font or an C<Imager::Font> object
reference.

=back


=cut

# TODO : _This_ should be all adjustable!

my $border_size = 50;
my $node_radius = 5;
my $edge_threshold = 0;
my $show_edges = 1;

sub render {
	my ($graph, $image) = @_;
	my ($width, $height) = ($image->getwidth(), $image->getheight());

	$width -= $border_size * 3;
	$height -= $border_size * 2;

	my $labelcolor = Imager::Color->new(0x00, 0x00, 0x00);
	my $nodecolor = Imager::Color->new(0xff, 0xff, 0x00);
	my $edgecolor = Imager::Color->new(0x66, 0x66, 0xff);

	my $minx = $graph->get_graph_attribute('layout_min1');
	my $maxx = $graph->get_graph_attribute('layout_max1');
	my $miny = $graph->get_graph_attribute('layout_min2');
	my $maxy = $graph->get_graph_attribute('layout_max2');

	my $maxw = Graph::Renderer::_max_weight($graph);

	my $gfont = _get_Imager_Font($graph->get_graph_attribute('renderer_vertex_font'));

	my @edges = $graph->edges;
	foreach my $edge (@edges) {
		my ($v1, $v2) = @$edge;
		my $weight = $graph->get_edge_attribute(@$edge, 'weight');
		$weight ||= 1; # TODO : configurable

		next if $weight < $edge_threshold;
		next unless $show_edges;

		my $v1posx = $graph->get_vertex_attribute($v1, 'layout_pos1');
		my $v1posy = $graph->get_vertex_attribute($v1, 'layout_pos2');
		my $v2posx = $graph->get_vertex_attribute($v2, 'layout_pos1');
		my $v2posy = $graph->get_vertex_attribute($v2, 'layout_pos2');

		my $x1 = Graph::Renderer::_transpose_coord($v1posx, $minx, $maxx, $width) + $border_size;
		my $y1 = Graph::Renderer::_transpose_coord($v1posy, $miny, $maxy, $height) + $border_size;
		my $x2 = Graph::Renderer::_transpose_coord($v2posx, $minx, $maxx, $width) + $border_size;
		my $y2 = Graph::Renderer::_transpose_coord($v2posy, $miny, $maxy, $height) + $border_size;

		my @rgba = $edgecolor->rgba;
		# This was the original line, but it makes sense only when we
		# can change thickness...
		#$rgba[3] = 102 + 153 * $edge->{weight} / $g->{max_weight};
		# ...so we do this instead, adjusting the saturation:
		foreach my $i (0 .. 1) {
			$rgba[$i] = 0xee;
			$rgba[$i] -= 0xee * (log($weight + 1) / log($maxw + 1));
		}
		my $adgecolor = Imager::Color->new(@rgba);

		#$image->setThickness(log($edge->{weight} + 1) * 0.5 + 1);

		$image->line(color => $adgecolor, x1 => $x1, y1 => $y1,
		             x2 => $x2, y2 => $y2, aa => 1);
	}

	#$image->setThickness(2);
	foreach my $vertex ($graph->vertices) {
		my $posx = $graph->get_vertex_attribute($vertex, 'layout_pos1');
		my $posy = $graph->get_vertex_attribute($vertex, 'layout_pos2');

		my $x = Graph::Renderer::_transpose_coord($posx, $minx, $maxx, $width) + $border_size;
		my $y = Graph::Renderer::_transpose_coord($posy, $miny, $maxy, $height) + $border_size;

		$image->circle(color => $edgecolor, x => $x, y => $y, r => $node_radius, filled => 1, aa => 1);
		$image->circle(color => $nodecolor, x => $x, y => $y, r => $node_radius - 2, filled => 1, aa => 1);

		my $title = $graph->get_vertex_attribute($vertex, 'renderer_vertex_title');
		$title = $vertex unless defined $title;

		my $font = _get_Imager_Font($graph->get_vertex_attribute($vertex, 'renderer_vertex_font'));
		$font ||= $gfont;

		$image->string(font => $font,
		               x => $x + $node_radius, y => $y - $node_radius,
		               color => $labelcolor, aa => 1, size => 10,
			       string => $title);
	}

	$image;
}

sub _get_Imager_Font($) {
	my $gfont = shift;

	# Emergency fallback. Hope for at least something.
	$gfont = '/usr/X11/lib/X11/fonts/TTF/luxisr.ttf' unless (defined $gfont);

	return $gfont if (defined ref $gfont and ref $gfont eq 'Imager::Font');

	return Imager::Font->new(file => $gfont);
}


=head1 SEE ALSO

C<Graph>, C<Graph::Renderer>


=head1 BUGS

The object-oriented interface is missing as well as some more universal render
calling interface (hash parameters). Also, some real rendering attributes
(ie. color settings) are missing.


=head1 COPYRIGHT

Copyright 2004 by Petr Baudis E<lt>pasky@ucw.czE<gt>.

This code is distributed under the same copyright terms as
Perl itself.


=head1 VERSION

Version 0.03

$Id: Imager.pm,v 1.5 2006/02/11 17:11:39 pasky Exp $

=cut

1;

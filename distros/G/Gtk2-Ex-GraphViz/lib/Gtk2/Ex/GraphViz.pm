package Gtk2::Ex::GraphViz;

our $VERSION = '0.01';

use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Data::Dumper;
use GraphViz;
use Gtk2;
use XML::Simple;
use Math::Geometry::Planar;
use GD;
use GD::Polyline;
use Carp;

sub new {
	my ($class, $graph) = @_;
	my $self  = {};
	bless ($self, $class);
	$self->_set_graph($graph);
	return $self;
}

sub get_widget {
	my ($self) = @_;
	my $vbox = Gtk2::VBox->new(FALSE, 0);
	$vbox->pack_start ($self->{eventbox}, FALSE, FALSE, 0);
	my $hbox = Gtk2::HBox->new(FALSE, 0);
	$hbox->pack_start ($vbox, FALSE, FALSE, 0);
	return $hbox;
}

sub signal_connect {
	my ($self, $signal, $callback) = @_;
	my $allowedsignals = [
		'mouse-enter-node',
		'mouse-exit-node',
		'mouse-enter-edge',
		'mouse-exit-edge',
	];
	my %hash = map { $_ => 1 } @$allowedsignals;
	unless ($hash{$signal}) {
		my $str = "Warning !! No such signal $signal. Allowed signals are\n";
		$str .= join "\n", @$allowedsignals;
		warn $str."\n";
	}		
	$self->{signals}->{$signal} = $callback;
}

sub _set_graph {
	my ($self, $graph) = @_;
	my $pngimage = GD::Image->newFromPngData($graph->as_png);
	my $svgdata = XMLin($graph->as_svg);
	my (@bounds) = split ' ', $svgdata->{viewBox};
	my $width  = $bounds[2] - $bounds[0];
	my $height = $bounds[3] - $bounds[3];
	$self->{pngimage} = $pngimage;
	$self->{svgdata} = $svgdata;
	$self->{node}->{polygons} = _extract_node_polygons($svgdata);
	$self->{node}->{ellipses} = _extract_node_ellipses($svgdata);
	$self->{edge}->{edges}    = _extract_edge_coords($svgdata);
	my $loader = Gtk2::Gdk::PixbufLoader->new;
	$loader->write ($pngimage->png);
	$loader->close;
	my $image = Gtk2::Image->new_from_pixbuf($loader->get_pixbuf);

	my $eventbox = Gtk2::EventBox->new;
	$eventbox->add($image);

	my ($ratiox, $ratioy);
	$eventbox->signal_connect('realize' => 
		sub {
			my @imageallocatedsize = $image->allocation->values;
			$ratiox = $imageallocatedsize[2]/$width;
			$ratioy = $imageallocatedsize[2]/$width;
			$self->{ratiox} = $ratiox;
			$self->{ratioy} = $ratioy;
		}
	);
	$eventbox->add_events ('pointer-motion-mask');
	$eventbox->signal_connect ('motion-notify-event' => 
		sub {
			my ($widget, $event) = @_;
			#my $r = $self->{eventbox}->allocation;
			#print $r->x."  ".$r->y."  ".$r->width."  ".$r->height." \n";
			my ($x, $y) = ($event->x, $event->y);
			$x = int($x/$ratiox);
			$y = int($y/$ratioy);
			return if $self->_check_inside_node($x, $y);
			return if $self->_check_on_edge($x, $y);
		}
	);
	$self->{eventbox} = $eventbox;
}


sub _inside_ellipse {
	my ($x0, $y0, $a, $b, $x, $y) = @_;
	return TRUE if
		($b*$b*($x-$x0)*($x-$x0) + $a*$a*($y-$y0)*($y-$y0) <= $a*$a*$b*$b);
	return FALSE;
}

sub _highlight_edge {
	my ($self, $line) = @_;
	my $polyline = new GD::Polyline;
	my ($ratiox, $ratioy) = ($self->{ratiox}, $self->{ratioy});
	foreach my $bit (@$line) {
		$polyline->addPt($bit->[0]*$ratiox, $bit->[1]*$ratioy);
	}
	my $im = $self->{pngimage}->clone;	
	$im->setThickness(3);
	my $white = $im->colorAllocate(255,0,0);
	my $eventbox = $self->{eventbox};
	my @children = $eventbox->get_children;
	foreach my $child (@children) {
		$eventbox->remove($child);
	}
	my $spline  = $polyline->toSpline(); 
	$im->polydraw($spline, $white);
	my $loader = Gtk2::Gdk::PixbufLoader->new;
	$loader->write ($im->png);
	$loader->close;
	my $image = Gtk2::Image->new_from_pixbuf($loader->get_pixbuf);
	$eventbox->add($image);
	$eventbox->show_all;
	$self->{HIGHLIGHTED} = 1;
}

sub _co_linear {
	my ($p1, $p2, $a) = @_;
	my ($x1, $y1) = @$p1;
	my ($x2, $y2) = @$p2;
	my ($xa, $ya) = @$a;
	return FALSE if ($x1 >	$xa && $x2 >  $xa);
	return FALSE if ($x1 <	$xa && $x2 <  $xa);
	return FALSE if ($y1 >	$ya && $y2 >  $ya);
	return FALSE if ($y1 <	$ya && $y2 <  $ya);
	if (abs($x1-$x2) < 5) {
		return TRUE if abs($x1-$xa) < 5;
		return FALSE; #else
	}
	if (abs($y1-$y2) < 5) {
		return TRUE if abs($y1-$ya) < 5;
		return FALSE; #else
	}
	return FALSE if $y1 == $ya;

	return TRUE if ( 
		abs(($x1-$x2)/($y1-$y2) - ($x1-$xa)/($y1-$ya)) < 1
	);
	return FALSE;
}

sub _check_on_edge {
	my ($self, $x, $y) = @_;
	my $edges = $self->{edge}->{edges};
	my $edgename;
	foreach my $key (keys %$edges) {
		if (_check_on_polyline($edges->{$key}, [$x, $y])) {
			$edgename = $key;
			last;
		}
	}
	if ($edgename) {
		$self->_highlight_edge($edges->{$edgename});
		&{$self->{signals}->{'mouse-enter-edge'}}($self, $x, $y, $edgename)
			if $self->{signals}->{'mouse-enter-edge'};
		return TRUE;
	} else {
		if ($self->{HIGHLIGHTED}) {
			my $eventbox = $self->{eventbox};
			my @children = $eventbox->get_children;
			foreach my $child (@children) {
				$eventbox->remove($child);
			}
			my $loader = Gtk2::Gdk::PixbufLoader->new;
			$loader->write ($self->{pngimage}->png);
			$loader->close;
			my $image = Gtk2::Image->new_from_pixbuf($loader->get_pixbuf);
			$eventbox->add($image);
			$eventbox->show_all;			
			&{$self->{signals}->{'mouse-exit-edge'}}($self, $x, $y)
				if $self->{signals}->{'mouse-exit-edge'};
		}
		$self->{HIGHLIGHTED} = 0;
		return FALSE;
	}	
}

sub _check_on_polyline {
	my ($polyline, $p) = @_;
	foreach my $i (0..$#{@$polyline}-1) {			
		return TRUE	if _co_linear($polyline->[$i], $polyline->[$i+1], $p);
	}
	return FALSE;
}

sub _check_inside_node {
	my ($self, $x, $y) = @_;
	my $nodename;
	my $nodeshape;
	my $polygons = $self->{node}->{polygons};
	foreach my $key (%$polygons) {
		if ($polygons->{$key} && $polygons->{$key}->isinside([$x,$y])) {
			$nodename = $key;
			$nodeshape = 'polygon';
			last;
		}
	}
	my $ellipses = $self->{node}->{ellipses};
	foreach my $key (keys %$ellipses) {
		if (_inside_ellipse(@{$ellipses->{$key}}, $x, $y)){
			$nodename = $key;
			$nodeshape = 'ellipse';
			last;
		}
	}

	if ($nodename) {
		$self->_highlight_polygon($polygons->{$nodename}->{points})
			if $nodeshape eq 'polygon';
		$self->_highlight_ellipse($ellipses->{$nodename})
			if $nodeshape eq 'ellipse';
		&{$self->{signals}->{'mouse-enter-node'}}($self, $x, $y, $nodename)
			if $self->{signals}->{'mouse-enter-node'};
		return TRUE;
	} else {
		if ($self->{HIGHLIGHTED}) {
			my $eventbox = $self->{eventbox};
			my @children = $eventbox->get_children;
			foreach my $child (@children) {
				$eventbox->remove($child);
			}
			my $loader = Gtk2::Gdk::PixbufLoader->new;
			$loader->write ($self->{pngimage}->png);
			$loader->close;
			my $image = Gtk2::Image->new_from_pixbuf($loader->get_pixbuf);
			$eventbox->add($image);
			$eventbox->show_all;			
			&{$self->{signals}->{'mouse-exit-node'}}($self, $x, $y)
				if $self->{signals}->{'mouse-exit-node'};
		}
		$self->{HIGHLIGHTED} = 0;
		return FALSE;
	}	
}

sub _highlight_ellipse {
	my ($self, $ellipse) = @_;
	my $eventbox = $self->{eventbox};
	my @children = $eventbox->get_children;
	foreach my $child (@children) {
		$eventbox->remove($child);
	}
	my $im = $self->{pngimage}->clone;	
	$im->setThickness(3);
	my $white = $im->colorAllocate(255,0,0);
	my ($ratiox, $ratioy) = ($self->{ratiox}, $self->{ratioy});
	my ($cx, $cy, $w, $h) = @$ellipse;
		$cx = int($cx*$ratiox);
		$cy = int($cy*$ratioy);
		$w  = int( $w*$ratiox);
		$h  = int( $h*$ratioy);
	$im->ellipse($cx,$cy,2*$w,2*$h,$white);
	my $loader = Gtk2::Gdk::PixbufLoader->new;
	$loader->write ($im->png);
	$loader->close;
	my $image = Gtk2::Image->new_from_pixbuf($loader->get_pixbuf);
	$eventbox->add($image);
	$eventbox->show_all;
	$self->{HIGHLIGHTED} = 1;
}

sub _highlight_polygon {
	my ($self, $rect) = @_;
	my $eventbox = $self->{eventbox};
	my @children = $eventbox->get_children;
	foreach my $child (@children) {
		$eventbox->remove($child);
	}
	my $im = $self->{pngimage}->clone;	
	$im->setThickness(3);
	my $polygon = GD::Polygon->new;
	my ($ratiox, $ratioy) = ($self->{ratiox}, $self->{ratioy});
	foreach my $point (@$rect) {
		my $x = int($point->[0]*$ratiox);
		my $y = int($point->[1]*$ratioy);
		$polygon->addPt($x, $y);
	}
	my $white = $im->colorAllocate(255,0,0);
	$im->openPolygon($polygon,$white);
	my $loader = Gtk2::Gdk::PixbufLoader->new;
	$loader->write ($im->png);
	$loader->close;
	my $image = Gtk2::Image->new_from_pixbuf($loader->get_pixbuf);
	$eventbox->add($image);
	$eventbox->show_all;
	$self->{HIGHLIGHTED} = 1;
}

sub _extract_node_polygons {
	my ($svgdata) = @_;
	my $shapes = $svgdata->{g}->{g};
	my $result;
	foreach my $key (keys %$shapes) {
		next unless $shapes->{$key}->{class} eq 'node';
		if ($shapes->{$key}->{polygon}) {
			my $str = $shapes->{$key}->{polygon}->{points};
			my @coords = split ' ', $str;
			my @thispoly;
			foreach my $coord (@coords) {
				my ($x, $y) = split ',', $coord;
				push @thispoly, [$x, $y];
			}
			my $polygon = Math::Geometry::Planar->new;
			$polygon->points(\@thispoly);
			$result->{$key} = $polygon;
		}			
	}
	return $result;
}

sub _extract_node_ellipses {
	my ($svgdata) = @_;
	my $shapes = $svgdata->{g}->{g};
	my $result;
	foreach my $key (keys %$shapes) {
		next unless $shapes->{$key}->{class} eq 'node';
		if ($shapes->{$key}->{ellipse}) {
			my $ellipse = $shapes->{$key}->{ellipse};
			my @thisellipse;
			push @thisellipse, $ellipse->{cx};
			push @thisellipse, $ellipse->{cy};
			push @thisellipse, $ellipse->{rx};
			push @thisellipse, $ellipse->{ry};
			$result->{$key} = \@thisellipse;
		}			
	}
	return $result;
}

sub _extract_edge_coords {
	my ($svgdata) = @_;
	my $shapes = $svgdata->{g}->{g};
	my $result;
	foreach my $key (keys %$shapes) {
		next unless $shapes->{$key}->{class} eq 'edge';
		my $str = $shapes->{$key}->{path}->{d};
		$str =~ s/M/ /;
		$str =~ s/C/ /;
		my @coords = split ' ', $str;
		my @thisline;
		foreach my $coord (@coords) {
			my ($x, $y) = split ',', $coord;
			push @thisline, [$x, $y];
		}
		$result->{$key} = \@thisline;		
	}
	return $result;
}

1;

__END__

=head1 NAME

Gtk2::Ex::GraphViz - A Gtk2 wrapper to the GraphViz.pm module.

=head1 DESCRIPTION

GraphViz can be used to produce good-looking network graphs. Wrapping with Gtk2
allows those images to respond to events such as C<mouse-over>, C<clicked> etc.

By implementing callbacks to the respective C<signals>, you can create fairly 
B<interactive> network graphs. For example, when the user double-clicks a node,
you can open up a widget that contains information on that node.

=head1 SYNOPSIS

	use GraphViz;
	use Gtk2::Ex::GraphViz;
	my $g = GraphViz->new; # First do all the work in GraphViz.pm
	$g->add_node('London', shape => 'box', fillcolor =>'lightblue', style =>'filled',);
	$g->add_node('Paris', label => 'City of\nlurve', );
	$g->add_edge('London' => 'Paris');
	# Now the actual Gtk2::Ex::GraphViz portion takes over
	my $graphviz = Gtk2::Ex::GraphViz->new($g);
	$graphviz->signal_connect ('mouse-enter-node' => 
		sub {
			my ($self, $x, $y, $nodename) = @_;
			my $nodetitle = $graphviz->{svgdata}->{g}->{g}->{$nodename}->{title};
			print "Node : $nodetitle : $x, $y\n";
		}
	);


=head1 METHODS

=head2 new;

The constructor accepts a GraphViz object as the first argument. 

	my $g = GraphViz->new; # First do all the work in GraphViz.pm
	my $graphviz = Gtk2::Ex::GraphViz->new($g);

=head2 get_widget;

Returns the widget that can be added to any container and presented in a window.

=head2 signal_connect($signal, $callback);

See the SIGNALS section to see the supported signals.

=head1 SIGNALS

=head2 mouse-enter-node;

=head2 mouse-exit-node;

=head2 mouse-enter-edge;

=head2 mouse-exit-edge;

=head1 SEE ALSO

GraphViz

=head1 COPYRIGHT & LICENSE

Copyright 2005 Ofey Aikon, All Rights Reserved.

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Library General Public License for more
details.

You should have received a copy of the GNU Library General Public License along
with this library; if not, write to the Free Software Foundation, Inc., 59
Temple Place - Suite 330, Boston, MA  02111-1307  USA.

=cut

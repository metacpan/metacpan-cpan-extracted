package Gtk2::Ex::TreeMap;

our $VERSION = '0.02';

use strict;
use warnings;
use Data::Dumper;
use Glib qw /TRUE FALSE/;
use GD;
use Gtk2 -init;

sub new {
	my ($class, $size) = @_;
	my $self  = {};
	$self->{tree} = undef;
	$self->{rectangles} = undef;
	$self->{eventbox} = undef;
	$self->{selected} = undef;
	$self->{size} = $size;
	$self->{image} = new GD::Image(@$size);
	$self->{signals} = {};
	bless ($self, $class);
	return $self;
}

sub signal_connect {
	my ($self, $event, $callback) = @_;
	$self->{signals}->{$event} = $callback;
}

sub draw_map_simple {
	my ($self, $list) = @_;
	my $tree = {};
	$tree->{Node} = [];
	my $color = 120;
	my $count = 0;
	my $color_incr = (255-120)/($#{@$list}+1);
	foreach my $element (@$list) {
		push @{$tree->{Node}}, { size => $element, color => "0,0,$color", description => $count++ };
		$color += $color_incr;
	}
	$self->draw_map($tree);
}

sub draw_map {
	my ($self, $tree) = @_;
	_purify_tree($tree);
	$self->{tree} = $tree;
	my $rectangle = [0, 0, $self->{size}->[0], $self->{size}->[1]];
	$self->_build_rectangles($rectangle, $tree);
	$self->_paint_rectangles($tree);
	$self->_build_event_box;
}

sub get_image {
	my ($self) = @_;
	return $self->{eventbox};
}

sub _purify_tree {
	my ($data) = @_;
	if (!$data->{Node}) {
		# This is the child node
		# Fill in the size, color information if missing.
		$data->{size} = 0 unless $data->{size};
		$data->{color} = '0,0,0' unless $data->{color};		
		return $data;
	} else {
		my @list;
		foreach my $child (@{$data->{Node}}) {
			push @list, _purify_tree($child);
		}
		my $temp = _aggregate_size(\@list);
		$data->{size} = $temp->{size};
		$data->{color} = $temp->{color};
		@{$data->{Node}} = reverse sort { $a->{size} <=> $b->{size} } @{$data->{Node}};
		return _aggregate_size(\@list);
	}
}

sub _aggregate_size {
	my ($data) = @_;
	my $size = 0;
	foreach my $element (@$data) {
		$size += $element->{size};
	}
	return { size => $size, color => '0,0,0'};
}

sub _build_rectangles {
	my ($self, $size, $tree) = @_;
	return unless exists($tree->{Node});
	my $values = [];	
	foreach my $element (@{$tree->{Node}}) {
		push @$values, $element->{size} if ($element->{size});
	}
	my $rectangles = [];
	my $width = abs($size->[2] - $size->[0]);
	my $height = abs($size->[3] - $size->[1]);
	if ($width > $height) {
		$self->_draw_squarified($size, $values, $rectangles, 'horizontal');
	} else {
		$self->_draw_squarified($size, $values, $rectangles, 'vertical');
	}
	if ($#{@$rectangles} > 0) {
		$tree->{rectangles} = $rectangles;
		my $count = 0;
		foreach my $child (@{$tree->{Node}}) {
			$self->_build_rectangles($rectangles->[$count++], $child);
		}
	}
}

sub _paint_rectangles {
	my ($self, $tree) = @_;
	return unless exists($tree->{rectangles});
	my $image = $self->{image};
	my $black = $image->colorAllocate(0,0,0); 
	my $count = 0;
	foreach my $rect(@{$tree->{rectangles}}) {
		$image->rectangle(@$rect, $black);
		my $middle_x = ($rect->[0] + $rect->[2])/2;
		my $middle_y = ($rect->[1] + $rect->[3])/2;
		#my $colorlist = [int(rand()*255),int(rand()*255),int(rand()*255)];
		my $colorstring = $tree->{Node}->[$count++]->{color};
		my @colorlist = split /,/, $colorstring;
		my $color = $image->colorResolve(@colorlist);
		$image->fill($middle_x, $middle_y, $color);
	}
	foreach my $child (@{$tree->{Node}}) {
		$self->_paint_rectangles($child);
	}
}

sub _build_event_box {
	my ($self) = @_;
	my $loader = Gtk2::Gdk::PixbufLoader->new;
	$loader->write ($self->{image}->png);
	$loader->close;
	my $image = Gtk2::Image->new_from_pixbuf($loader->get_pixbuf);
	my $eventbox = Gtk2::EventBox->new;
	$eventbox->add ($image);
	$eventbox->add_events (['pointer-motion-mask', 'pointer-motion-hint-mask']);
	$eventbox->signal_connect ('size-allocate' => 
		sub {
			my ($widget, $event) = @_;
			my @imageallocatedsize = $eventbox->allocation->values;
			$self->{imageallocatedsize} = \@imageallocatedsize;			
			return 0;
		}
	);
	$eventbox->signal_connect ('motion-notify-event' => 
		sub {
			my ($widget, $event) = @_;
			my ($x, $y) = ($event->x, $event->y);
			$x -= ($self->{imageallocatedsize}->[2] - $self->{size}->[0])/2;
			$y -= ($self->{imageallocatedsize}->[3] - $self->{size}->[1])/2;
			my $path = [];
			$self->_get_path_at_pos($self->{tree}, $path, $x, $y);
			if ($#{@$path} >= 0) {
				my @clonepath = @$path;
				my $chosen_rectangle = $self->_get_rectangle_at_path(\@clonepath, $self->{tree});
				$self->_highlight_rectangle($chosen_rectangle);
				@clonepath = @$path;
				my $chosen_node = $self->_get_node_at_path(\@clonepath, $self->{tree});				
				if ($self->{signals}->{'mouse-over'}) {
					my @clonepath = @$path;
					&{$self->{signals}->{'mouse-over'}}($x, $y, \@clonepath, $chosen_node)
				}
			}
		}
	);
	$self->{eventbox} = $eventbox;
}

sub _highlight_rectangle {
	my ($self, $rect) = @_;
	my $eventbox = $self->{eventbox};
	my @children = $eventbox->get_children;
	foreach my $child (@children) {
		$eventbox->remove($child);
	}
	my $im = $self->{image}->clone;	
	my $white = $im->colorAllocate(255,255,255);
	$im->rectangle(@$rect, $white);
	my $loader = Gtk2::Gdk::PixbufLoader->new;
	$loader->write ($im->png);
	$loader->close;
	my $image = Gtk2::Image->new_from_pixbuf($loader->get_pixbuf);
	$eventbox->add($image);
	$eventbox->show_all;
}



sub _get_path_at_pos {
	my ($self, $tree, $path, $x, $y) = @_;
	my $count = 0;
	foreach my $rect(@{$tree->{rectangles}}) {
		if ($x > $rect->[0] and $x < $rect->[2] and $y > $rect->[1] and $y < $rect->[3]) {
			push @$path, $count;
			$self->_get_path_at_pos($tree->{Node}->[$count], $path, $x, $y);
		}
		$count++;
	}	
}

sub _get_node_at_path {
	my ($self, $path, $tree) = @_;
	if ($#{@$path} == 0) {
		return $tree->{Node}->[$path->[0]];
	}
	my $child = $tree->{Node}->[$path->[0]];
	shift @$path;
	$self->_get_node_at_path($path, $child);
}

sub _get_rectangle_at_path {
	my ($self, $path, $tree) = @_;
	if ($#{@$path} == 0) {
		return $tree->{rectangles}->[$path->[0]];
	}
	my $child = $tree->{Node}->[$path->[0]];
	shift @$path;
	$self->_get_rectangle_at_path($path, $child);
}

sub _draw_squarified {
	my ($self, $rect, $values, $rectangles, $direction) = @_;
	if ($#{@$values} == 0) {
		push @$rectangles, $rect;
		return;
	}
	my $sum = 0;
	foreach my $x (@$values) {
		$sum += $x;
	}
	my $best_aspect_ratio = 0;
	my $best_rectangles;
	my $width = abs($rect->[2] - $rect->[0]);
	my $height = abs($rect->[3] - $rect->[1]);
	my ($x1, $y1, $x2, $y2);
	if ($direction eq 'horizontal') {
		for (my $i=0; $i<=$#{@$values}; $i++) {
			($x1, $y1) = ($rect->[0], $rect->[1]);
			my @temp;
			my $localsum = 0;
			for (my $j=0; $j<=$i; $j++) {
				$localsum += $values->[$j];
			}
			$x2 = int($x1 + $width*$localsum/$sum);
			for (my $j=0; $j<=$i; $j++) {
				$y2 = int($y1 + $height*$values->[$j]/$localsum);
				push @temp, [$x1, $y1, $x2, $y2];
				$y1 = $y2;
			}
			my $aspect_ratio = _calc_best_aspect_ratio(\@temp);
			if ($aspect_ratio >= $best_aspect_ratio) {
				$best_aspect_ratio = $aspect_ratio;
				$best_rectangles = \@temp;
			} else {
				foreach my $rect(@$best_rectangles) {
					push @$rectangles, $rect;
				}
				my ($x1, $y1, $x2, $y2) = ($best_rectangles->[$i-1]->[2], $rect->[1], $rect->[2], $rect->[3]);
				for (my $j=0; $j<$i; $j++) {
					shift @$values;					
				}
				$self->_draw_squarified([$x1, $y1, $x2, $y2], $values, $rectangles, 'vertical');
				return;
			}
		}
		foreach my $rect(@$best_rectangles) {
			push @$rectangles, $rect;
		}
	} elsif ($direction eq 'vertical') {
		for (my $i=0; $i<=$#{@$values}; $i++) {
			($x1, $y1) = ($rect->[0], $rect->[1]);
			my @temp;
			my $localsum = 0;
			for (my $j=0; $j<=$i; $j++) {
				$localsum += $values->[$j];
			}
			$y2 = int($y1 + $height*$localsum/$sum);
			for (my $j=0; $j<=$i; $j++) {
				$x2 = int($x1 + $width*$values->[$j]/$localsum);
				push @temp, [$x1, $y1, $x2, $y2];
				$x1 = $x2;
			}
			my $aspect_ratio = _calc_best_aspect_ratio(\@temp);
			if ($aspect_ratio >= $best_aspect_ratio) {
				$best_aspect_ratio = $aspect_ratio;
				$best_rectangles = \@temp;
			} else {
				foreach my $rect(@$best_rectangles) {
					push @$rectangles, $rect;
				}
				my ($x1, $y1, $x2, $y2) = ($rect->[0], $best_rectangles->[$i-1]->[3], $rect->[2], $rect->[3]);
				for (my $j=0; $j<$i; $j++) {
					shift @$values;					
				}				
				$self->_draw_squarified([$x1, $y1, $x2, $y2], $values, $rectangles, 'horizontal');
				return;
			}
		}
		foreach my $rect(@$best_rectangles) {
			push @$rectangles, $rect;
		}
	}	
}

sub _calc_best_aspect_ratio {
	my ($rectangles) = @_;
	my @aspect;
	foreach my $r (@$rectangles) {
		if ($r->[1] == $r->[3] or $r->[0] == $r->[2]) {
			return 0;
		}
		my $l = abs ( ($r->[0] - $r->[2])/($r->[1] - $r->[3]) );
		my $h = abs ( ($r->[1] - $r->[3])/($r->[0] - $r->[2]) );
		push @aspect, $l < $h ? $l : $h;
	}
	return min(@aspect);
}

sub min {
	my (@values) = @_;
	my $min = $values[0];
	foreach my $x (@values) {
		$min = $x if ($x < $min);
	}
	return $min;
}

1;

__END__

=head1 NAME

Gtk2::Ex::TreeMap - Implementation of TreeMap.

=head1 SYNOPSIS

	use Gtk2::Ex::TreeMap;
	my $values = [6,6,4,3,2,2,1];
	my $treemap = Gtk2::Ex::TreeMap->new([600,400]);
	$treemap->draw_map_simple($values);
	my $window = Gtk2::Window->new;
	$window->signal_connect(destroy => sub { Gtk2->main_quit; });
	$window->add($treemap->get_image);
	$window->show_all;
	Gtk2->main;

=head1 DESCRIPTION

Treemap is a space-constrained visualization of hierarchical structures. 
It is very effective in showing attributes of leaf nodes using size and 
color coding. http://www.cs.umd.edu/hcil/treemap/

The popular treemaps are;

	http://www.marumushi.com/apps/newsmap/newsmap.cfm
	http://codecubed.com/map.html the del.icio.us most popular treemap
	http://www.smartmoney.com/marketmap/

This module implements the TreeMap functionality in pure perl. Currently I have
implemented only the B<Squarified TreeMap> algorithm. Details of this algorithm can 
be found at http://www.win.tue.nl/~vanwijk/stm.pdf
This algorithm was chosen because it produces aesthetically pleasing rectangles.

All the drawing is done using C<GD>. But C<Gtk2> adds plenty of life, bells and whistles
to the otherwise passive TreeMap png image.

=head1 METHODS

=head2 Gtk2::Ex::TreeMap->new([$width, $height]);

Just a plain old constructor. Accepts two arguments, C<$width> and C<$height> of the TreeMap.

	my $treemap = Gtk2::Ex::TreeMap->new([600,400]);

=head2 Gtk2::Ex::TreeMap->draw_map_simple($values);

Use this API to quickly build a treemap from a flat list of values. The colors of the 
rectangles are chosen internally. If you want to do anything serious, like specify colors, 
description etc, then use the C<draw_map($tree)> api.

	my $values = [6,6,4,3,2,2,1];
	$treemap->draw_map_simple($values);

=head2 Gtk2::Ex::TreeMap->draw_map($tree);

This is the api that you will use most of the time. This one accepts a hierarchical tree 
structure as its input. I have chosen the tree format that is used by the XML::Simple module.
This approach so that the tree can be easily constructed from an xml document.

Here is an example definition of the XML

	<Node>
		<Node>
			<Node size="9" color="0,0,80" description="0 0"/>
			<Node size="7" color="0,120,80" description="0 1"/>
			<Node>
				<Node size="9" color="0,0,100" description="0 2 0"/>
				<Node size="9" color="0,0,110" description="0 2 1"/>
				<Node>
					<Node size="8" color="0,0,100" description="0 2 2 0"/>
					<Node size="2" color="0,0,110" description="0 2 2 1"/>
				</Node>
			</Node>
		</Node>
		<Node>
			<Node size="7" color="0,170,200" description="1 0"/>
			<Node size="5" color="0,170,210" description="1 1"/>
			<Node size="9" color="0,170,220" description="1 2"/>
		</Node>
	</Node>	

Now read this string using XML::Simple to derive the tree.

	my $tree = XMLin($xmlstr, ForceArray => 1);
	$treemap->draw_map($tree);

B<Note: It is very important to use the C<ForceArray> option. Else you will end up with
a variety of errors.>

=head2 Gtk2::Ex::TreeMap->get_image

Returns the TreeMap image as a C<Gtk2::Image> wrapped in a C<Gtk2::EventBox>. You can add this
to your own Gtk2 container

	my $window = Gtk2::Window->new;
	$window->add($treemap->get_image);
	$window->show_all;
	Gtk2->main;

=head1 TODO

  * Implement callback for mouse-over and clicked events
  * Implement popup box as a default option
  * Implement text in the rectangles
  * The boxes should probably be drawn with a black border
  * Build a new example using WWW::Google::News perhaps !
  * Once the module is done, may be I'll split it into a two; a pure GD module which 
    will be "used" by a Gtk2 module. That way, non-Gtk2 folks can use it, of course 
    without the popups and callbacks and all those bells and whistles.
  * More tests, more documentation.

=head1 AUTHOR

Ofey Aikon, C<< <ofey_aikon at gmail dot com> >>

=head1 ACKNOWLEDGEMENTS

To the wonderful gtk-perl list.

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

__END__
## @class Gtk2::Ex::Geo::Overlay
# @todo Implement select linestring
# @brief A geocanvas widget
# @author Copyright (c) Ari Jolma
# @author This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.8.5 or,
# at your option, any later version of Perl 5 you may have available.
package Gtk2::Ex::Geo::Overlay;

use strict;
use POSIX;
use Scalar::Util qw(blessed);
use Carp;
use Glib qw/TRUE FALSE/;
use Geo::OGC::Geometry;

use vars qw / $EDIT_SNAP_DISTANCE /;

our $VERSION = '0.62'; # same as Geo.pm

=pod

=head1 NAME

Gtk2::Ex::Geo::Overlay - A Gtk2 widget for a visual overlay of geospatial data

The <a href="http://geoinformatics.aalto.fi/doc/Geoinformatica/html/">
documentation of Gtk2::Ex::Geo</a> is written in doxygen format.

=cut

$EDIT_SNAP_DISTANCE = 5;

use Glib::Object::Subclass
    Gtk2::ScrolledWindow::,
    signals => {
	update_layers => {},  # sent just before the layers are rendered
	new_selection => {},  # sent after the user has changed the selection
	drawing_changed => {},# sent after the user has changed the drawing
	zoomed_in => {},      # deprecated
	extent_changed => {}, # deprecated
	motion_notify => {},  # the mouse has a new location on the map
	map_updated => {},    # deprecated
	pixmap_ready => {},   # sent just after pixmap is ready, but selection and drawing 
	                      # haven't been rendered, connect to this for annotations
    },
    properties => 
    [
     Glib::ParamSpec->double 
     (
      'zoom_factor', 'Zoom factor', 
      'Zoom multiplier when user presses + or -',
      0.1, 1000, 1.2, [qw/readable writable/]
      ),
     Glib::ParamSpec->double 
     (
      'step', 'Step', 
      'One step when scrolling is window width/height divided by step',
      1, 100, 8, [qw/readable writable/]
      ),
     ]
    ;

## @ignore
sub INIT_INSTANCE {
    my $self = shift;

    $self->{image} = Gtk2::Image->new;
    $self->{image}->set_size_request(0, 0);
    $self->{image}->signal_connect(size_allocate => \&size_allocate, $self);

    $self->{event_box} = Gtk2::EventBox->new;

    $self->{event_box}->add($self->{image});

    $self->{event_box}->signal_connect(button_press_event => \&button_press_event, $self);
    $self->{event_box}->signal_connect(button_release_event => \&button_release_event, $self);

    $self->{event_box}->add_events('pointer-motion-mask');
    $self->{event_box}->signal_connect(motion_notify_event => \&motion_notify, $self);

    $self->signal_connect(key_press_event => \&key_press_event, $self);
    $self->signal_connect(key_release_event => \&key_release_event, $self);

    $self->{selecting} = '';
    $self->{rubberband_geometry} = '';
    $self->{rubberband_mode} = '';
        
    # why do I need to set these two?
    $self->{zoom_factor} = 1.2;
    $self->{step} = 8;

    $self->{offset} = [0, 0];
    $self->{bg_color} = [255, 255, 255, 255];
    $self->{selection_color} = [255*257, 178*257, 0];
    $self->{selection_style} = 'GDK_LINE_SOLID';
    $self->{drawing_color} = [0, 65535, 0];
    $self->{show_selection} = 1;

    $self->{layers} = [];
}

## @method
# @brief Attempt to delete all widgets within this widget.
sub close {
    my $self = shift;
    while (my($key, $widget) = each %$self) {
	$widget->destroy if blessed($widget) and $widget->isa("Gtk2::Widget");
	delete $self->{$key};
    }
}

## @ignore
sub size_allocate {
    my($image, $allocation, $self) = @_;
    my @old_v = (0, 0);
    @old_v = @{$self->{viewport_size}} if $self->{viewport_size};
    my @v = $allocation->values;
    @{$self->{viewport_size}} = @v[2..3];
    $self->render() if $v[2] != $old_v[0] or $v[3] != $old_v[1];
    return 0;
}

## @method my_inits
# @brief call after new
# @todo merge into new
sub my_inits {
    my($self, %params) = @_;
    $self->{inited} = 1;

    $self->get_hscrollbar()->signal_connect(value_changed => \&value_changed, $self);
    $self->get_vscrollbar()->signal_connect(value_changed => \&value_changed, $self);
    
    $self->add_with_viewport($self->{event_box});

    for (keys %params) {
	if ($_ eq 'bg_color' or $_ eq 'offset') {
	    @{$self->{$_}} = @{$params{$_}};
	    next;
	}
	$self->{$_} = $params{$_};
    }
}

## @method add_layer($layer, $do_not_zoom_to)
# @brief Add a layer to the list and by default zoom to it.
# Always zooms to the first layer added.
sub add_layer {
    my($self, $layer, $do_not_zoom_to) = @_;

    return unless blessed($layer) and $layer->isa('Gtk2::Ex::Geo::Layer');

    push @{$self->{layers}}, $layer;

    # MUST zoom to if this is the first layer
    $do_not_zoom_to = 0 unless $self->{first_added};

    $self->my_inits unless $self->{inited};
    unless ($do_not_zoom_to) {
	$self->zoom_to($layer) if $self->{viewport_size};
    }
    $self->{first_added} = 1;
    return $#{$self->{layers}};
}

## @method layer_count()
# @brief Get the number of layers in the list.
sub layer_count {
    my($self) = @_;
    my $count = @{$self->{layers}};
    return $count;
}

## @method layer_count($layer)
# @brief Return true if given layer object is in the list.
sub has_layer {
    my($self, $layer) = @_;
    for (@{$self->{layers}}) {
	next unless ref($_) eq ref($layer);
	return 1 if ref($_) eq ref($layer);
    }
    return 0;
}

## @method layer_count($name)
# @brief Get the index of the given layer in the list.
sub index_of_layer {
    my($self, $name) = @_;
    my $i = $#{$self->{layers}};
    for my $layer (@{$self->{layers}}) {
	return $i if $layer->name() eq $name;
	$i--;
    }
    return undef;
}

## @method get_layer_by_index($index)
sub get_layer_by_index {
    my($self, $index) = @_;
    return unless $index >= 0 and $index <= $#{$self->{layers}};
    return $self->{layers}->[$#{$self->{layers}} - $index];
}

## @method get_layer_by_name($name)
sub get_layer_by_name {
    my($self, $name) = @_;
    for my $layer (@{$self->{layers}}) {
	return $layer if $layer->name() eq $name;
    }
}

## @method remove_layer_by_index($index)
sub remove_layer_by_index {
    my($self, $index) = @_;
    my $n = $#{$self->{layers}};
    return 0 unless $index >= 0 and $index <= $n;
    splice(@{$self->{layers}}, $n-$index, 1);
    return 1;
}

## @method remove_layer_by_name($index)
sub remove_layer_by_name {
    my($self, $name) = @_;
    for my $index (0..$#{$self->{layers}}) {
	if ($self->{layers}->[$index]->name() eq $name) {
	    splice(@{$self->{layers}}, $index, 1);
	    return 1;
	}
    }    
    return 0;
}

## @method zoom_to($layer)
# @brief Tries to set the given bounding box as the world.

## @method zoom_to($minx, $miny, $maxx, $maxy)
# @brief Tries to set the given bounding box as the world.
sub zoom_to {
    my $self = shift;

    # up left (minX, maxY) is fixed, adjust maxX or minY
    delete $self->{zoom_stack};

    my @vp1 = $self->get_viewport;

    my @bounds; # minX, minY, maxX, maxY

    if (@_ == 1) {
	my $layer = shift;
	return unless $self->{layers} and @{$self->{layers}};
	eval {
	    @bounds = $layer->world();
	};
	@bounds = (0,0,1,1) unless @bounds;
	$self->{offset} = [0, 0];
    } elsif (@_ == 5) {
	my($minX, $maxY, $pixel_size, @offset) = @_;
	$pixel_size = 1 if $pixel_size <= 0;
	$self->{pixel_size} = $pixel_size;
	@bounds = ($minX,
		   $maxY-$pixel_size*$self->{viewport_size}->[1],
		   $minX+$pixel_size*$self->{viewport_size}->[0],
		   $maxY);
	$self->{offset} = [@offset];
    } else {
	@bounds = @_;
	$self->{offset} = [0, 0];
    }

    # sanity check
    $bounds[2] = $bounds[0]+1 if $bounds[2] <= $bounds[0];
    $bounds[3] = $bounds[1]+1 if $bounds[3] <= $bounds[1];

    my($w, $h) = @{$self->{viewport_size}};
    @{$self->{canvas_size}} = @{$self->{viewport_size}};
    $self->{pixel_size} = max(($bounds[2]-$bounds[0])/$w,($bounds[3]-$bounds[1])/$h);
    push @{$self->{zoom_stack}}, [@{$self->{offset}}, $self->{pixel_size}];

    $self->{minX} = $bounds[0];
    $self->{maxY} = $bounds[3];
    $self->{maxX} = $bounds[0]+$self->{pixel_size}*$w;
    $self->{minY} = $bounds[3]-$self->{pixel_size}*$h;

    $self->render() if $self->{first_added};

    my @vp2 = $self->get_viewport;
    if (!@vp1 or ($vp2[0] >= $vp1[0] and $vp2[1] >= $vp1[1] and $vp2[2] <= $vp1[2] and $vp2[3] <= $vp1[3])) {
	$self->signal_emit('zoomed-in');
    } else {
	$self->signal_emit('extent-changed');
    }
}

## @method get_world()
# @brief Get the total area of the canvas.
# @return (min_x, min_y, max_x, max_y)
sub get_world {
    my $self = shift;
    return ($self->{minX}, $self->{minY}, $self->{maxX}, $self->{maxY});
}

## @method get_viewport()
# @brief Get the visible area of the canvas.
# @return (min_x, min_y, max_x, max_y)
sub get_viewport {
    my $self = shift;
    return () unless defined $self->{minX};
    my $minX = $self->{minX}+$self->{offset}[0]*$self->{pixel_size};
    my $maxY = $self->{maxY}-$self->{offset}[1]*$self->{pixel_size};
    return ( $minX, $maxY-$self->{viewport_size}->[1]*$self->{pixel_size},
	     $minX+$self->{viewport_size}->[0]*$self->{pixel_size}, $maxY );
}

## @method get_viewport_of_selection()
# @brief Get the visible area of the canvas.
# @return (min_x, min_y, max_x, max_y)
sub get_viewport_of_selection {
    my $self = shift;
    return unless $self->{selection};
    my $e = $self->{selection}->Envelope;
    my $ll = $e->PointN(1);
    my $ur = $e->PointN(3);
    return ($ll->X, $ll->Y, $ur->X, $ur->Y);
}

## @method size()
# @brief The size of the viewport in pixels (height, width)
sub size {
    my $self = shift;
    return ($self->{viewport_size}->[1], $self->{viewport_size}->[0]);
}

## @method zoom_to_all()
# @brief Sets the world as the bounding box for all layers
sub zoom_to_all {
    my($self) = @_;
    return unless $self->{layers} and @{$self->{layers}};
    my @size;
    for my $layer (@{$self->{layers}}) {
	my @s;
	eval {
	    @s = $layer->world();
	};
	next unless @s;
	if (@size) {
	    $size[0] = min($size[0], $s[0]);
	    $size[1] = min($size[1], $s[1]);
	    $size[2] = max($size[2], $s[2]);
	    $size[3] = max($size[3], $s[3]);
	} else {
	    @size = @s;
	}
    }
    $self->zoom_to(@size) if @size;
}

## @ignore
sub value_changed {
    my(undef, $self) = @_;
    push @{$self->{zoom_stack}}, [@{$self->{offset}}, $self->{pixel_size}];
    $self->{offset} = [$self->get_hadjustment()->value(), $self->get_vadjustment()->value()];
    $self->signal_emit('extent-changed'); 
    $self->render();
    return 1;
}

## @method get_focus()
# @deprecated use get_viewport_of_selection or get_viewport
# @returns the visible area or the selection, if one exists, as ($minx, $miny, $maxx, $maxy).
sub get_focus {
    my($self) = @_;
    if ($self->{selection}) {
	my $e = $self->{selection}->Envelope;
	my $ll = $e->PointN(1);
	my $ur = $e->PointN(3);
	return ($ll->X, $ll->Y, $ur->X, $ur->Y);
    } else {
	my $minX = $self->{minX}+$self->{offset}[0]*$self->{pixel_size};
	my $maxY = $self->{maxY}-$self->{offset}[1]*$self->{pixel_size};
	return ($minX, $maxY-$self->{viewport_size}->[1]*$self->{pixel_size},
		$minX+$self->{viewport_size}->[0]*$self->{pixel_size}, $maxY);
    }
}

{
    package Gtk2::Ex::Geo::PseudoOverlay;
    sub round {
	return int($_[0] + .5 * ($_[0] <=> 0));
    }
    sub new {
	my($class, $minX, $maxY, $pixel_size) = @_;	
	my $self = { minX => $minX,
		     maxY => $maxY,
		     pixel_size => $pixel_size
	};
	bless($self, $class); 
    }
    sub point2pixmap_pixel {
	my($self, @p) = @_;
	return (round(($p[0] - $self->{minX})/$self->{pixel_size} - 0.5),
		round(($self->{maxY} - $p[1])/$self->{pixel_size} - 0.5));
    }
    package Gtk2::Ex::Geo::Canvas;
    our @ISA = qw(Gtk2::Gdk::Pixbuf);
 
    sub new {
	my($class, $layers, 
	   $minX, $maxY, $pixel_size, $w_offset, $h_offset,
	   $width, $height,
	   $bg_r, $bg_g, $bg_b, $bg_a, $overlay) = @_;
	
	return unless defined $minX;

	$overlay = Gtk2::Ex::Geo::PseudoOverlay->new($minX, $maxY, $pixel_size) unless $overlay;
	
	my @viewport = ($minX+$pixel_size*$w_offset, 0, 0, $maxY-$pixel_size*$h_offset);
	$viewport[2] = $viewport[0]+$pixel_size*$width;
	$viewport[1] = $viewport[3]-$pixel_size*$height;
	
	my $pb = &Gtk2::Ex::Geo::gtk2_ex_geo_pixbuf_create($width, $height,
							   $viewport[0], $viewport[3],
							   $pixel_size, 
							   $bg_r, $bg_g, $bg_b, $bg_a);
	
	my $surface = &Gtk2::Ex::Geo::gtk2_ex_geo_pixbuf_get_cairo_surface($pb);
	my $cr = Cairo::Context->create($surface);
	
	for my $layer (@$layers) {
	    $layer->render($pb, $cr, $overlay, \@viewport);
	}
	
	undef $cr;
	undef $surface;
	my $self = &Gtk2::Ex::Geo::gtk2_ex_geo_pixbuf_get_pixbuf($pb);
	&Gtk2::Ex::Geo::gtk2_ex_geo_pixbuf_destroy($pb); # does not delete the real pixbuf
	
	bless($self, $class); 
    }
}

package Gtk2::Ex::Geo::Overlay;

## @method render(%params)
# @brief Render the layers on the canvas.
# Each layer's render method is called:
# @code
# $layer->render($pixbuf_struct, $cairo_context, $self, \@viewport);
# @endcode
# If named parameter filename is set, the generated pixbuf is saved to it:
# @code
# $pixbuf->save($params{filename}, $params{type});
# @endcode
# The generated pixmap that is shown is annotated with selection and
# user defined annotation function.
sub render {
    my $self = shift;
    my %opt = @_;

    my $size = $self->{viewport_size};
    return unless $size->[0];

    $self->signal_emit('update-layers');

    my @tmp = ($self->{minX}, $self->{maxY}, $self->{pixel_size}, @{$self->{offset}});
    $self->{pixbuf} = Gtk2::Ex::Geo::Canvas->new
	($self->{layers}, @tmp, @{$size}, @{$self->{bg_color}}[0..3], $self);

    return unless $self->{pixbuf};

    if ($opt{filename}) {
	my $filename = $opt{filename};
	delete $opt{filename};
	my $type = $opt{type};
	delete $opt{type};
	# other options...
	$self->{pixbuf}->save($filename, $type);
	return;
    }

    $self->update_image();

    $self->{old_hadj} = $self->get_hscrollbar->get_adjustment; # prevents a warning
    $self->get_hscrollbar->set_adjustment
	(Gtk2::Adjustment->new($self->{offset}[0], 0, $self->{canvas_size}[0], $size->[0]/20,
			       $size->[0], $size->[0]));

    $self->{old_vadj} = $self->get_vscrollbar->get_adjustment; # prevents a warning
    $self->get_vscrollbar->set_adjustment
	(Gtk2::Adjustment->new($self->{offset}[1], 0, $self->{canvas_size}[1], $size->[1]/20,
			       $size->[1], $size->[1]));

    $self->signal_emit ('map-updated');

}

## @method render_geometry($gc, $geom)
# @brief Render a geometry on the overlay.
#
# @note this should be called annotate or made detect the context (gdk vs cairo)
# Call update_image after you are finished with drawing on the pixmap.
# @param gc A gdk graphics context (Gtk2::Gdk::GC object)
# @param geom A Geo::OGC::Geometry object.
sub render_geometry {
    my($self, $gc, $geom, %param) = @_;
    if ($geom->isa('Geo::OGC::GeometryCollection')) 
    {
	for my $g ($geom->NumGeometries) {
	    $self->render_geometry($gc, $g, %param);
	}
	return;
    } 
    elsif ($geom->isa('Geo::OGC::Point')) 
    {
	my @p = $self->point2pixmap_pixel($geom->X, $geom->Y);
	$self->{pixmap}->draw_line($gc, $p[0]-4, $p[1], $p[0]+4, $p[1]);
	$self->{pixmap}->draw_line($gc, $p[0], $p[1]-4, $p[0], $p[1]+4);
    } 
    elsif ($geom->isa('Geo::OGC::LineString')) 
    {
	my @points;
	for my $p ($geom->NumPoints) {
	    push @points, $self->point2pixmap_pixel($p->X, $p->Y);
	}
	$self->{pixmap}->draw_lines($gc, @points);
	if ($param{enhance_vertices}) {
	    my $pm = $self->{pixmap};
	    for (my $i = 0; $i < $#points; $i+=2) {
		my $x = $points[$i];
		my $y = $points[$i+1];
		$pm->draw_line($gc, $x-4, $y, $x+4, $y);
		$pm->draw_line($gc, $x, $y-4, $x, $y+4);
	    }
	}
    }
    elsif ($geom->isa('Geo::OGC::Polygon')) 
    {
	$self->render_geometry($gc, $geom->ExteriorRing, %param);
	for my $i (0..$geom->NumInteriorRing-1) {
	    $self->render_geometry($gc, $geom->InteriorRingN($i), %param);
	}
    }
}

## @method update_image($annotations, $user_param)
# @param annotations A subroutine for user annotations. Called like
# this: $annotations->($overlay, $pixmap, $gc, $user_param).
# @param user_param User parameter for the annotations.
# @brief Updates the image on the screen to show the changes in pixmap.
sub update_image {
    my($self, $annotations, $user_param) = @_;
    return unless $self->{pixbuf};
    $self->{image}->set_from_pixbuf(undef);
    $self->{pixmap} = $self->{pixbuf}->render_pixmap_and_mask(0);
    my $gc = Gtk2::Gdk::GC->new($self->{pixmap});
    $self->{pixmap}->draw_line($gc, 0, 0, 0, 0); # strange bug, the first line is not drawn
    $self->signal_emit('pixmap_ready');
    my $first = 1;
    if ($self->{drawing}) {
	$gc->set_rgb_fg_color(Gtk2::Gdk::Color->new(@{$self->{drawing_color}}));
	my $style = 'GDK_LINE_SOLID';
	$gc->set_line_attributes(2, $style, 'GDK_CAP_NOT_LAST', 'GDK_JOIN_MITER');
	$self->render_geometry($gc, $self->{drawing}, enhance_vertices => 1);
    }
    if ($self->{selection} and $self->{show_selection}) {
	$gc->set_rgb_fg_color(Gtk2::Gdk::Color->new(@{$self->{selection_color}}));
	my $style = $self->{selection_style};
	$style = 'GDK_LINE_SOLID';
	$gc->set_line_attributes(2, $style, 'GDK_CAP_NOT_LAST', 'GDK_JOIN_MITER');
	$self->render_geometry($gc, $self->{selection});
    }
    $annotations->($self, $self->{pixmap}, $gc, $user_param) if $annotations;
    $self->{image}->set_from_pixmap($self->{pixmap}, undef);
}

## @method zoom($w_offset, $h_offset, $pixel_size)
# @brief Select a part of the world into the visible area.
sub zoom {
    my($self, $w_offset, $h_offset, $pixel_size, $zoomed_in, $not_to_stack) = @_;

    push @{$self->{zoom_stack}}, [@{$self->{offset}}, $self->{pixel_size}] unless $not_to_stack;

    $self->{offset} = [$w_offset, $h_offset];
    
    # sanity check
    $pixel_size = 1 if $pixel_size <= 0;
    $self->{pixel_size} = $pixel_size;

    my $w = ($self->{maxX}-$self->{minX})/$self->{pixel_size};
    my $h = ($self->{maxY}-$self->{minY})/$self->{pixel_size};

    $self->{canvas_size} = [$w, $h];

    $self->render();
    if ($zoomed_in) {
	$self->signal_emit('zoomed-in');
    } else {
	$self->signal_emit('extent-changed');
    }
}

## @ignore
sub _zoom { 
    my($self, $in, $event, $center_x, $center_y, $zoomed_in) = @_;

    return unless $self->{layers} and @{$self->{layers}};

    my @old_offset = @{$self->{offset}};

    # the center point should stay where it is unless center is defined
    $center_x = $self->{minX} + 
	($self->{offset}[0]+$self->{viewport_size}->[0]/2)*$self->{pixel_size} unless defined $center_x;
    $center_y = $self->{maxY} - 
	($self->{offset}[1]+$self->{viewport_size}->[1]/2)*$self->{pixel_size} unless defined $center_y;

    $self->{pixel_size} = $in ? 
	$self->{pixel_size} / $self->{zoom_factor} : 
	$self->{pixel_size} * $self->{zoom_factor};

    $self->{offset} = 
	[int(($center_x - $self->{minX})/$self->{pixel_size} - $self->{viewport_size}->[0]/2),
	 int(($self->{maxY} - $center_y)/$self->{pixel_size} - $self->{viewport_size}->[1]/2)];

    $self->zoom(@{$self->{offset}}, $self->{pixel_size}, $zoomed_in);

    for (0, 1) {
	$self->{event_coordinates}->[$_] += $self->{offset}[$_] - $old_offset[$_];
    }
}

## @method zoom_in($event, $center_x, $center_y)
# @brief Zooms in an amount determined by the zoom_factor.
sub zoom_in { 
    my($self, $event, $center_x, $center_y) = @_;
    $self->_zoom(1, $event, $center_x, $center_y, 1);
}

## @method zoom_out($event, $center_x, $center_y)
# @brief Zooms out an amount determined by the zoom_factor.
# Note: : may enlarge the world.
sub zoom_out { 
    my($self, $event, $center_x, $center_y) = @_;
    if ($self->{offset}[0] == 0 and $self->{offset}[1] == 0) {
	my $dx = ($self->{maxX}-$self->{minX})*$self->{zoom_factor}/6.0;
	my $dy = ($self->{maxY}-$self->{minY})*$self->{zoom_factor}/6.0;
	$self->zoom_to($self->{minX}-$dx, $self->{minY}-$dy, $self->{maxX}+$dx, $self->{maxY}+$dy);
    } else {
	$self->_zoom(0, $event, $center_x, $center_y);
    }
}

## @method pan($w_move, $h_move, $event)
# @brief Pans the viewport.
sub pan {
    my($self, $w_move, $h_move, $event) = @_;

    $w_move = floor($w_move);
    $h_move = floor($h_move);
    
    $self->{event_coordinates}[0] += $w_move;
    $self->{event_coordinates}[1] += $h_move;

    push @{$self->{zoom_stack}}, [@{$self->{offset}}, $self->{pixel_size}];
    $self->{offset} = [$self->{offset}[0] + $w_move, $self->{offset}[1] + $h_move];
	
    $self->render();
    
    $self->signal_emit('extent-changed');
}

## @method key_press_event($event)
# @brief Handling of key press events.
#
# Tied to key_press_event and key_release_event. Ties "+" to zoom_in,
# "-" to zoom_out,and arrow keysto pan. Also ties "Enter" to finishing
# making a selection. Records press and release of "Ctrl" to object
# attribute "_control_down".
sub key_press_event {
    my($self, $event) = @_;

    return 0 unless $self->{layers} and @{$self->{layers}};
    
    my $key = $event->keyval;
    #print STDERR "key=$key\n";
    if ($key == $Gtk2::Gdk::Keysyms{plus}) {	    
	$self->zoom_in($event); # , $self->event_pixel2point());
    } elsif ($key == $Gtk2::Gdk::Keysyms{minus}) {
	$self->zoom_out($event); # , $self->event_pixel2point());	
    } elsif ($key == $Gtk2::Gdk::Keysyms{Right}) {
	$self->pan($self->{viewport_size}->[0]/$self->{step}, 0, $event);
    } elsif ($key == $Gtk2::Gdk::Keysyms{Left}) {
	$self->pan(-$self->{viewport_size}->[0]/$self->{step}, 0, $event);
    } elsif ($key == $Gtk2::Gdk::Keysyms{Up}) {
	$self->pan(0, -$self->{viewport_size}->[1]/$self->{step}, $event);
    } elsif ($key == $Gtk2::Gdk::Keysyms{Down}) {
	$self->pan(0, $self->{viewport_size}->[1]/$self->{step}, $event);
    } elsif ($key == $Gtk2::Gdk::Keysyms{Escape}) {
	$self->delete_rubberband;
    } elsif ($key == $Gtk2::Gdk::Keysyms{Return}) {
	if ($self->draw_mode and $self->{path}) {
	    if ($self->{rubberband_geometry} eq 'polygon') {
		if (@{$self->{path}} > 2) {
		    my $geom = new Geo::OGC::Polygon;
		    my $r = new Geo::OGC::LinearRing;
		    # exterior is ccw
		    for my $p (@{$self->{path}}) {
			$r->AddPoint(Geo::OGC::Point->new($self->event_pixel2point(@$p)));
		    }
		    $r->Close;
		    $geom->ExteriorRing($r);
		    $self->add_to_selection($geom);
		}
	    } elsif ($self->{rubberband_geometry} eq 'path') {
		if (@{$self->{path}} > 1) {
		    my $geom = new Geo::OGC::LineString;
		    for my $p (@{$self->{path}}) {
			$geom->AddPoint(Geo::OGC::Point->new($self->event_pixel2point(@$p)));
		    }
		    $self->add_to_selection($geom);
		}
	    }
	}
	$self->delete_rubberband;

    } elsif ($key == $Gtk2::Gdk::Keysyms{Insert}) {

	if ($self->{rubberband_mode} eq 'edit' and $self->{drawing}) {
	    
	    # find the closest point in drawing
	    my @p = $self->event_pixel2point(@{$self->{event_coordinates}});
	    my @r = $self->{drawing}->ClosestPoint(@p);
	    my $d = pop @r;
	    if (@r and $d/$self->{pixel_size} < $EDIT_SNAP_DISTANCE) {
		$self->{drawing}->AddVertex(@r);
		$self->signal_emit('drawing-changed');
		$self->update_image;
	    }
	}
	
    } elsif ($key == $Gtk2::Gdk::Keysyms{Delete}) {

	if ($self->{rubberband_mode} eq 'edit' and $self->{drawing}) {
	    
	    # find the closest vertex in drawing
	    my @p = $self->event_pixel2point(@{$self->{event_coordinates}});
	    my @r = $self->{drawing}->ClosestVertex(@p);
	    my $d = pop @r;
	    if (@r and $d/$self->{pixel_size} < $EDIT_SNAP_DISTANCE) {
		$self->{drawing}->DeleteVertex(@r);
		$self->signal_emit('drawing-changed');
		$self->update_image;
	    }	    
	}

    } elsif (($key == $Gtk2::Gdk::Keysyms{Control_L} or $key == $Gtk2::Gdk::Keysyms{Control_R}) and
	     $self->draw_mode) {
	$self->{_control_down} = 1;
    } elsif (($key == $Gtk2::Gdk::Keysyms{Shift_L} or $key == $Gtk2::Gdk::Keysyms{Shift_R}) and
	     $self->draw_mode and
	     ($self->{drawing} and $self->{drawing}->LastPolygon)) {
	$self->{_shift_down} = 1;
    }
    return 0;
}

## @ignore
sub draw_mode {
    my($self) = @_;
    return ($self->{rubberband_mode} eq 'select' or $self->{rubberband_mode} eq 'draw');
}

## @method key_release_event($event)
# @brief Handling of key release events.
#
# Unsets object attribute "_control_down" if "Ctrl" released.
sub key_release_event {
    my($self, $event) = @_;
    my $key = $event->keyval;
    if ($key == $Gtk2::Gdk::Keysyms{Control_L} or $key == $Gtk2::Gdk::Keysyms{Control_R}) {
	$self->{_control_down} = 0;
    } elsif ($key == $Gtk2::Gdk::Keysyms{Shift_L} or $key == $Gtk2::Gdk::Keysyms{Shift_R}) {
	$self->{_shift_down} = 0;
    }
}

sub add_to_selection {
    my($self, $geom) = @_;
    my $store = ($self->{rubberband_mode} eq 'select') ? 'selection' : 'drawing';
    if ($self->{_control_down}) {
	
	# create first a multi something, then fall back to collection if need be

	unless ($self->{$store} and $self->{$store}->isa('Geo::OGC::GeometryCollection')) {
	    my $coll = Geo::OGC::GeometryCollection->new;
	    $coll->AddGeometry($self->{$store}) if $self->{$store};
	    $self->{$store} = $coll;
	}
	$self->{$store}->AddGeometry($geom) if $geom;
    } elsif ($self->{_shift_down}) {
	my $polygon = $self->{$store}->LastPolygon;
	if ($polygon and $geom->isa('Geo::OGC::Polygon')) {
	    $geom = $geom->ExteriorRing;
	    # exterior is ccw, interior is cw
	    $geom->Rotate;
	    $polygon->AddInteriorRing($geom);
	}
    } else {
	$self->{$store} = $geom;
    }
    $self->signal_emit('new_selection') if $self->{rubberband_mode} eq 'select';
    $self->signal_emit('drawing-changed') if $self->{rubberband_mode} eq 'draw';
}

## @method button_press_event()
# @brief Pops up a context menu or (optionally) does rubberbanding.
sub button_press_event {
    my(undef, $event, $self) = @_;

    return 0 unless $self->{layers} and @{$self->{layers}};
    $self->grab_focus;

    my $handled = 0;

    if ($event->button == 3 and $self->{menu}) {

	$self->delete_rubberband if $self->{path};
	my $menu = Gtk2::Menu->new;
	for (my $i =0; $i < @{$self->{menu}}; $i+=2) {
	    my $name = $self->{menu_item_setup}->($self->{menu}->[$i], $self);
	    my $item;
	    unless ($self->{menu}->[$i+1]) {
		$item = Gtk2::SeparatorMenuItem->new();
	    } else {
		$item = Gtk2::MenuItem->new($name);
		$item->signal_connect(activate => $self->{menu}->[$i+1], $self);
	    }
	    $item->show;
	    $menu->append ($item);
	}
	$menu->popup(undef, undef, undef, undef, $event->button, $event->time);
	$handled = 1;
	
    } elsif ($event->button == 1) {

	push @{$self->{path}}, [$event->x, $event->y];

	unless ($self->{rubberband_mode} eq 'edit') {
	    $self->{rubberband_gc} = Gtk2::Gdk::GC->new($self->{pixmap});
	    $self->{rubberband_gc}->copy($self->style->fg_gc($self->state));
	    $self->{rubberband_gc}->set_function('invert');
	}

	if ($self->{rubberband_mode} eq 'edit' and $self->{drawing}) {
	    # find the closest point in drawing
	    my @p = $self->event_pixel2point($event->x, $event->y);
	    my @q = $self->{drawing}->ClosestVertex(@p);
	    my $d = pop @q;
	    $self->{drawing_edit} = \@q if $d/$self->{pixel_size} < $EDIT_SNAP_DISTANCE;
	} elsif ($self->draw_mode and !($self->{_control_down} or $self->{_shift_down}) and
		 !($self->{rubberband_geometry} eq 'polygon' or $self->{rubberband_geometry} eq 'path')
	    )
	{
	    if ($self->{rubberband_mode} eq 'select') {
		delete $self->{selection};
		#$self->signal_emit('new_selection');
	    } elsif ($self->{rubberband_mode} eq 'draw') {
		delete $self->{drawing};
		#$self->signal_emit('drawing-changed');
	    }
	}

	$handled = 1;

    }

    return $handled;
}

## @method motion_notify()
# @brief Updates the rubberband if rubberbanding.
# @todo Use more visible rubberband, there's no need to use XOR.
sub motion_notify {
    my(undef, $event, $self) = @_;

    return 0 unless $self->{layers} and @{$self->{layers}};

    @{$self->{event_coordinates}} = ($event->x, $event->y);

    unless ($self->{path}) {
	$self->signal_emit('motion-notify');
	return 0; # not handled
    }

    my $pm = $self->{pixmap};
    my $rgc = $self->{rubberband_gc};
    my @begin = @{$self->{path}[0]};
    my @end = @{$self->{event_coordinates}};
    my $w = $end[0] - $begin[0];
    my $h = $end[1] - $begin[1];
    my @rb = @{$self->{rubberband}} if $self->{rubberband};
    
    if ($self->{drawing_edit}) {
	
	$pm = $self->{pixmap} = $self->{pixbuf}->render_pixmap_and_mask(0);
	my @wend = $self->event_pixel2point(@end);
	my @p = @{$self->{drawing_edit}};
	my @q = $self->{drawing}->VertexAt(@p);
	for my $q (@q) {
	    $q->{X} = $wend[0];
	    $q->{Y} = $wend[1];
	}
	my $gc = Gtk2::Gdk::GC->new($self->{pixmap});
	$gc->set_rgb_fg_color(Gtk2::Gdk::Color->new(@{$self->{drawing_color}}));
	my $style = 'GDK_LINE_SOLID';
	$gc->set_line_attributes(2, $style, 'GDK_CAP_NOT_LAST', 'GDK_JOIN_MITER');
	$self->render_geometry($gc, $self->{drawing}, enhance_vertices => 1);

    } else {    

	for ($self->{rubberband_mode}.' '.$self->{rubberband_geometry}) {
	    /edit/ && do {
		last;
	    };
	    /pan/ && do {
		my $gc = Gtk2::Gdk::GC->new($pm);
		$pm->draw_rectangle($gc, 1, 0, 0, @{$self->{viewport_size}});
		$pm->draw_pixbuf($gc, $self->{pixbuf}, 0, 0, $w, $h, -1, -1, 'GDK_RGB_DITHER_NONE', 0, 0);
		last;
	    };
	    /line/ && do {
		$pm->draw_line($rgc, @rb) if @rb;
		@rb = (@begin, @end);
		$pm->draw_line($rgc, @rb);
	    };
	    /path/ && do {
		my @p = @{$self->{path}}; 
		for my $p (0..$#p-1) {
		    $pm->draw_line($rgc, @{$p[$p]}, @{$p[$p+1]});
		}
		$pm->draw_line($rgc, @rb) if @rb;
		@rb = (@{$p[$#p]}, @end);
		for my $p (0..$#p-1) {
		    $pm->draw_line($rgc, @{$p[$p]}, @{$p[$p+1]});
		}
		$pm->draw_line($rgc, @rb);
	    };
	    /rect/ && do {
		$pm->draw_rectangle($rgc, FALSE, @rb) if @rb;
		@rb = (min($begin[0], $end[0]), min($begin[1], $end[1]), abs($w), abs($h));
		$pm->draw_rectangle($rgc, FALSE, @rb);
	    };
	    /ellipse/ && do {
		$pm->draw_arc($rgc, FALSE, @rb, 0, 64*360) if @rb;
		my $a = abs(floor($w * sqrt(2)));
		my $b = abs(floor($h * sqrt(2)));
		@rb = ($begin[0] - $a, $begin[1] - $b, 2*$a, 2*$b);
		$pm->draw_arc($rgc, FALSE, @rb, 0, 64*360);
	    };
	    /polygon/ && do {
		my @p = @{$self->{path}};
		if (@p == 1) {
		    $pm->draw_line($rgc, @rb) if @rb;
		    @rb = (@begin, @end);
		    $pm->draw_line($rgc, @rb);
		} else {
		    $pm->draw_line($rgc, @rb) if @rb and @rb == 4 and @p == 2;
		    my @points;
		    for my $p (@p) {
			push @points, @$p;
		    }
		    push @points, @rb if @rb;
		    $pm->draw_polygon($rgc, 1, @points);
		    @rb = @end;
		    pop @points;
		    pop @points;
		    push @points, @rb;
		    $pm->draw_polygon($rgc, 1, @points);
		}
	    }
	}
    }
    
    @{$self->{rubberband}} = @rb;

    $self->{image}->set_from_pixbuf(undef);
    $self->{image}->set_from_pixmap($pm, undef);
    
    $self->signal_emit('motion-notify');
    return 1; # handled
}

sub rubberband_mode {
    my($self) = @_;
    my $mode = $self->{rubberband_mode};
    $mode .= ", add to collection" if $self->{_control_down};
    $mode .= ", add a hole" if $self->{_shift_down};
    return $mode;
}

## @method @rubberband_value()
# @brief Computes a value relevant to current rubberband (length or area) in world coordinates.
# @return ($dimension, $value) $dimension is either 1 or 2
sub rubberband_value {
    my($self) = @_;

    if ($self->{path}) {

	my @p0 = $self->event_pixel2point(@{$self->{path}[0]}) if $self->{path}[0];
	my @p1 = $self->event_pixel2point(@{$self->{event_coordinates}});

	for ($self->{rubberband_geometry}) {
	    (/line/ || /path/) && do {
		my $ogc = new Geo::OGC::LinearRing(points => $self->{path});
		$ogc->AddPoint(Geo::OGC::Point->new(@{$self->{event_coordinates}}));
		$ogc->ApplyTransformation( sub { return $self->event_pixel2point(@_); } );
		return (1, $ogc->Length);
	    };
	    /rect/ && do {
		return (2, abs(($p1[0]-$p0[0])*($p1[1]-$p0[1])));
	    };
	    /ellipse/ && do {
		my $a = ($p1[0]-$p0[0]) * sqrt(2);
		my $b = ($p1[1]-$p0[1]) * sqrt(2);
		return (2, abs(3.14159266*$a*$b));
	    };
	    /polygon/ && do {
		my $ogc = new Geo::OGC::LinearRing(points => $self->{path});
		$ogc->AddPoint(Geo::OGC::Point->new(@{$self->{event_coordinates}}));
		$ogc->ApplyTransformation( sub { return $self->event_pixel2point(@_); } );
		$ogc->Close;
		return (2, undef) unless $ogc->IsSimple;
		return (2, abs($ogc->Area));
	    };
	}
    }
}

## @method delete_rubberband()
# @brief Escapes from rubberbanding.
sub delete_rubberband {
    my $self = shift;
    delete $self->{path};
    delete $self->{rubberband};
    $self->update_image;
}

## @method button_release_event()
# @brief Finishes rubberbanding.
sub button_release_event {
    my(undef, $event, $self) = @_;
    
    return 0 unless $self->{layers} and @{$self->{layers}};
    
    my $handled = 0;
    if ($self->{path}) {

	my $pm = $self->{pixmap};
	my @rb = @{$self->{rubberband}} if $self->{rubberband};
	my $rgc = $self->{rubberband_gc};
	my @begin = @{$self->{path}[0]};
	my @end = ($event->x, $event->y);

	my $click = ($begin[0] == $end[0] and $begin[1] == $end[1]);

	my @wbegin = $self->event_pixel2point(@begin);
	my @wend = $self->event_pixel2point(@end);

	for ($self->{rubberband_mode}) {

	    /pan/ && do {
		$self->delete_rubberband;
		$self->pan($begin[0] - $end[0], $begin[1] - $end[1]);
	    };
	    /zoom/ && do {
		$self->delete_rubberband;
		unless ($click) {
		    my $w_offset = min($begin[0], $end[0]);
		    my $h_offset = min($begin[1], $end[1]);
		    
		    my $pixel_size = max(abs($wbegin[0]-$wend[0])/$self->{viewport_size}->[0],
					 abs($wbegin[1]-$wend[1])/$self->{viewport_size}->[1]);
		    
		    $w_offset = int((min($wbegin[0], $wend[0])-$self->{minX})/$pixel_size);
		    $h_offset = int(($self->{maxY}-max($wbegin[1], $wend[1]))/$pixel_size);
		    
		    $self->zoom($w_offset, $h_offset, $pixel_size, 1);
		}
	    };
	    (/select/ or /draw/) && do {
		if ($self->{rubberband_geometry} eq 'line') {
		    my $geom;
		    if ($click) {
			$geom = Geo::OGC::Point->new($wbegin[0], $wbegin[1]);
		    } else {
			$geom = new Geo::OGC::LineString;
			$geom->AddPoint(Geo::OGC::Point->new($wbegin[0], $wbegin[1]));
			$geom->AddPoint(Geo::OGC::Point->new($wend[0], $wend[1]));
		    }
		    $self->add_to_selection($geom);
		    $self->delete_rubberband;
		} elsif ($self->{rubberband_geometry} =~ /rect/) {
		    my $geom;
		    if ($click) {
			$geom = Geo::OGC::Point->new($wbegin[0], $wbegin[1]);
		    } else {
			my @rect = (min($wbegin[0], $wend[0]), min($wbegin[1], $wend[1]),
				    max($wbegin[0], $wend[0]), max($wbegin[1], $wend[1]));
			$geom = new Geo::OGC::Polygon;
			my $r = new Geo::OGC::LinearRing;
			# exterior is ccw
			$r->AddPoint(Geo::OGC::Point->new($rect[0], $rect[1]));
			$r->AddPoint(Geo::OGC::Point->new($rect[2], $rect[1]));
			$r->AddPoint(Geo::OGC::Point->new($rect[2], $rect[3]));
			$r->AddPoint(Geo::OGC::Point->new($rect[0], $rect[3]));
			$r->Close;
			$geom->ExteriorRing($r);
		    }
		    $self->add_to_selection($geom);
		    $self->delete_rubberband;
		} elsif ($self->{rubberband_geometry} eq 'ellipse') {
		    $self->delete_rubberband;
		} elsif ($self->{rubberband_geometry} eq 'path') {
		    delete $self->{rubberband};
		}
	    };
	    (/measure/ or /edit/) && do {		
		if ($self->{drawing_edit}) {
		    my @p = @{$self->{drawing_edit}};
		    my @q = $self->{drawing}->VertexAt(@p);
		    for my $q (@q) {
			$q->{X} = $wend[0];
			$q->{Y} = $wend[1];
		    }
		    delete $self->{drawing_edit};
		    $self->delete_rubberband;
		} elsif ($self->{rubberband_geometry} eq 'line') {
		    $self->delete_rubberband;		    
		} elsif ($self->{rubberband_geometry} eq 'rectangle') {
		    $self->delete_rubberband;
		} elsif ($self->{rubberband_geometry} eq 'ellipse') {
		    $self->delete_rubberband;
		} elsif ($self->{rubberband_geometry} eq 'path') {
		    delete $self->{rubberband};
		}
	    }
	}
    }
    return $handled;
}

## @method @pixel2point(@pixel)
# @brief Conversion from pixmap (event) coordinates to world
# coordinates. Alternative name: event_pixel2point:
sub event_pixel2point {
    my($self, @pixel) = @_;
    return unless $self->{layers} and @{$self->{layers}};
    @pixel = @{$self->{event_coordinates}} unless @pixel;
    return ($self->{minX} + $self->{pixel_size} * ($self->{offset}[0] + $pixel[0] + 0.5),
	    $self->{maxY} - $self->{pixel_size} * ($self->{offset}[1] + $pixel[1] + 0.5));
}
*pixel2point = *event_pixel2point;

## @method @point2pixel(@point)
# @brief Conversion from world coordinates to pixmap
# coordinates. Alternative name: point2pixmap_pixel.
sub point2pixmap_pixel {
    my($self, @p) = @_;
    return (round(($p[0] - $self->{minX})/$self->{pixel_size} - 0.5 - $self->{offset}[0]),
	    round(($self->{maxY} - $p[1])/$self->{pixel_size} - 0.5 - $self->{offset}[1]));
}
*point2pixel = *point2pixmap_pixel;

## @method @point2surface(@point)
# @brief Conversion from world coordinates to surface coordinates (as used in Cairo).
sub point2surface {
    my($self, @p) = @_;
    return ((($p[0] - $self->{minX})/$self->{pixel_size} - $self->{offset}[0]),
	    (($self->{maxY} - $p[1])/$self->{pixel_size} - $self->{offset}[1]));
}

## @ignore
sub min {
    $_[0] > $_[1] ? $_[1] : $_[0];
}

## @ignore
sub max {
    $_[0] > $_[1] ? $_[0] : $_[1];
}

## @ignore
sub round {
    return int($_[0] + .5 * ($_[0] <=> 0));
}

1;

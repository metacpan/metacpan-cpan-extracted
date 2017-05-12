package CanvasPrimitives;
use strict;
use Gnome2::Canvas;
use Gtk2::Gdk::Keysyms;
use Glib qw(TRUE FALSE);
use constant M_PI => 3.141529;

sub zoom_changed {
	my ($adj, $canvas) = @_;
	$canvas->set_pixels_per_unit ($adj->value);
}

my $dragging = FALSE;
my ($x, $y);

sub item_event {
	my ($item, $event) = @_;

	# set item_[xy] to the event x,y position in the parent's
	# item-relative coordinates
	my ($item_x, $item_y) = $item->parent->w2i ($event->coords);

	if ($event->type eq 'button-press') {
		if ($event->button == 1) {
			if ($event->state >= 'shift-mask') {
				$item->destroy;
			} else {
				$x = $item_x;
				$y = $item_y;

				$item->grab ([qw/pointer-motion-mask
				                 button-release-mask/],
				             Gtk2::Gdk::Cursor->new ('fleur'),
				            $event->time);

				$dragging = TRUE;
			}
		} elsif ($event->button == 2) {
			if ($event->state >= 'shift-mask') {
				$item->lower_to_bottom;
			} else {
				$item->lower (1);
			}
		} elsif ($event->button == 3) {
			if ($event->state >= 'shift-mask') {
				$item->raise_to_top;
			} else {
				$item->raise (1);
			}
		}

	} elsif ($event->type eq 'motion-notify') {
		if ($dragging && $event->state >= 'button1-mask') {
			my $new_x = $item_x;
			my $new_y = $item_y;

			$item->move ($new_x - $x, $new_y - $y);
			$x = $new_x;
			$y = $new_y;
		}

	} elsif ($event->type eq 'button-release') {
		$item->ungrab ($event->time);
		$dragging = FALSE;
	}

	return FALSE;
}

sub setup_item {
	my $item = shift;
	$item->signal_connect (event => \&item_event);
}

sub setup_heading {
	my ($root, $text, $pos) = @_;
	Gnome2::Canvas::Item->new ($root, 'Gnome2::Canvas::Text',
				   text => 'text',
				   x => (($pos % 3) * 200 + 100),
				   y => (($pos / 3) * 150 + 5),
				   font => 'Sans 12',
				   anchor => 'n', #GTK_ANCHOR_N,
				   fill_color => 'black');
}

sub setup_divisions {
	my $root = shift;

	my $group = Gnome2::Canvas::Item->new ($root, 'Gnome2::Canvas::Group',
	                                       x => 0.0, y => 0.0);
	setup_item ($group);

	Gnome2::Canvas::Item->new ($group,
				   'Gnome2::Canvas::Rect',
				   x1 => 0.0,
				   y1 => 0.0,
				   x2 => 600.0,
				   y2 => 450.0,
				   outline_color => 'black',
				   width_units => 4.0);

	Gnome2::Canvas::Item->new ($group,
				   'Gnome2::Canvas::Line',
		                   points => [0.0, 150.0, 600.0, 150.0],
				   fill_color => 'black',
				   width_units => 4.0);

	Gnome2::Canvas::Item->new ($group,
				   'Gnome2::Canvas::Line',
		                   points => [0.0, 300.0, 600.0, 300.0],
				   fill_color => 'black',
				   width_units => 4.0);

	Gnome2::Canvas::Item->new ($group,
				   'Gnome2::Canvas::Line',
		                   points => [200.0, 0.0, 200.0, 450.0],
				   fill_color => 'black',
				   width_units => 4.0);

	Gnome2::Canvas::Item->new ($group,
				   'Gnome2::Canvas::Line',
		                   points => [400.0, 0.0, 400.0, 450.0],
				   fill_color => 'black',
				   width_units => 4.0);

	setup_heading ($group, "Rectangles", 0);
	setup_heading ($group, "Ellipses", 1);
	setup_heading ($group, "Texts", 2);
	setup_heading ($group, "Images", 3);
	setup_heading ($group, "Lines", 4);
	setup_heading ($group, "Curves", 5);
	setup_heading ($group, "Arcs", 6);
	setup_heading ($group, "Polygons", 7);
	setup_heading ($group, "Widgets", 8);
}

my $gray50_width = 2;
my $gray50_height = 2;
my $gray50_bits = pack "CC", 0x02, 0x01;

sub setup_rectangles {
	my $root = shift;

	setup_item (Gnome2::Canvas::Item->new ($root,
					       'Gnome2::Canvas::Rect',
					       x1 => 20.0,
					       y1 => 30.0,
					       x2 => 70.0,
					       y2 => 60.0,
					       outline_color => 'red',
					       width_pixels => 8));

	if ($root->canvas->aa) {
		setup_item (Gnome2::Canvas::Item->new ($root,
					   'Gnome2::Canvas::Rect',
					   x1 => 90.0,
					   y1 => 40.0,
					   x2 => 180.0,
					   y2 => 100.0,
					   fill_color_rgba => 0x3cb37180,
					   outline_color => 'black',
					   width_units => 4.0));
	} else {
		my $stipple = Gtk2::Gdk::Bitmap->create_from_data
			(undef, $gray50_bits, $gray50_width, $gray50_height);
		setup_item (Gnome2::Canvas::Item->new ($root,
					'Gnome2::Canvas::Rect',
					x1 => 90.0,
					y1 => 40.0,
					x2 => 180.0,
					y2 => 100.0,
					fill_color => "mediumseagreen",
					fill_stipple => $stipple,
					outline_color => "black",
					width_units => 4.0));
	}

	setup_item (Gnome2::Canvas::Item->new ($root, 'Gnome2::Canvas::Rect',
					       x1 => 10.0,
					       y1 => 80.0,
					       x2 => 80.0,
					       y2 => 140.0,
					       fill_color => 'steelblue'));
}

sub setup_ellipses {
	my $root = shift;

	setup_item (Gnome2::Canvas::Item->new ($root,
					   'Gnome2::Canvas::Ellipse',
					   "x1", 220.0,
					   "y1", 30.0,
					   "x2", 270.0,
					   "y2", 60.0,
					   "outline_color", "goldenrod",
					   "width_pixels", 8));

	setup_item (Gnome2::Canvas::Item->new ($root,
					   'Gnome2::Canvas::Ellipse',
					   "x1", 290.0,
					   "y1", 40.0,
					   "x2", 380.0,
					   "y2", 100.0,
					   "fill_color", "wheat",
					   "outline_color", "midnightblue",
					   "width_units", 4.0));

	if ($root->canvas->aa) {
		setup_item (Gnome2::Canvas::Item->new ($root,
						   'Gnome2::Canvas::Ellipse',
						   "x1", 210.0,
						   "y1", 80.0,
						   "x2", 280.0,
						   "y2", 140.0,
						   "fill_color_rgba", 0x5f9ea080,
						   "outline_color", "black",
						   "width_pixels", 0));
	} else {
		my $stipple = Gtk2::Gdk::Bitmap->create_from_data
			(undef, $gray50_bits, $gray50_width, $gray50_height);
		setup_item (Gnome2::Canvas::Item->new ($root,
						   'Gnome2::Canvas::Ellipse',
						   "x1", 210.0,
						   "y1", 80.0,
						   "x2", 280.0,
						   "y2", 140.0,
						   "fill_color", "cadetblue",
						   "fill_stipple", $stipple,
						   "outline_color", "black",
						   "width_pixels", 0));
	}
}

sub make_anchor {
	my ($root, $x, $y) = @_;

	my $group = Gnome2::Canvas::Item->new ($root, 'Gnome2::Canvas::Group',
					       x => $x,
					       y => $y);
	setup_item ($group);

	Gnome2::Canvas::Item->new ($group, 'Gnome2::Canvas::Rect',
				   x1 => -2.0,
				   y1 => -2.0,
				   x2 => 2.0,
				   y2 => 2.0,
				   outline_color => "black",
				   width_pixels => 0);

	return $group;
}

sub setup_texts {
	my $root = shift;

	if ($root->canvas->aa) {
		Gnome2::Canvas::Item->new (make_anchor ($root, 420.0, 20.0),
				       'Gnome2::Canvas::Text',
				       "text", "Anchor NW",
				       "x", 0.0,
				       "y", 0.0,
				       "font", "Sans Bold 24",
				       "anchor", 'GTK_ANCHOR_NW',
				       "fill_color_rgba", 0x0000ff80);
	} else {
		my $stipple = Gtk2::Gdk::Bitmap->create_from_data
			(undef, $gray50_bits, $gray50_width, $gray50_height);
		Gnome2::Canvas::Item->new (make_anchor ($root, 420.0, 20.0),
				       'Gnome2::Canvas::Text',
				       "text", "Anchor NW",
				       "x", 0.0,
				       "y", 0.0,
				       "font", "Sans Bold 24",
				       "anchor", 'GTK_ANCHOR_NW',
				       "fill_color", "blue",
				       "fill_stipple", $stipple);
	}

	Gnome2::Canvas::Item->new (make_anchor ($root, 470.0, 75.0),
			       'Gnome2::Canvas::Text',
			       "text", "Anchor center\nJustify center\nMultiline text",
			       "x", 0.0,
			       "y", 0.0,
			       "font", "monospace bold 14",
			       "anchor", 'GTK_ANCHOR_CENTER',
			       "justification", 'GTK_JUSTIFY_CENTER',
			       "fill_color", "firebrick");

	Gnome2::Canvas::Item->new (make_anchor ($root, 590.0, 140.0),
			       'Gnome2::Canvas::Text',
			       "text", "Clipped text\nClipped text\nClipped text\nClipped text\nClipped text\nClipped text",
			       "x", 0.0,
			       "y", 0.0,
			       "font", "Sans 12",
			       "anchor", 'GTK_ANCHOR_SE',
			       "clip", TRUE,
			       "clip_width", 50.0,
			       "clip_height", 55.0,
			       "x_offset", 10.0,
			       "fill_color", "darkgreen");
}

sub plant_flower {
	my ($root, $x, $y, $anchor, $aa) = @_;

	eval {
	my $im = Gtk2::Gdk::Pixbuf->new_from_file("flower.png");
	my $image = Gnome2::Canvas::Item->new ($root,
					       'Gnome2::Canvas::Pixbuf',
					       "pixbuf", $im,
					       "x", $x,
					       "y", $y,
					       "width", $im->get_width,
					       "height", $im->get_height,
  					       "anchor", $anchor,
					       );
	setup_item ($image);
	}
}

sub setup_images {
	my ($root, $aa) = @_;

	eval {
	my $im = Gtk2::Gdk::Pixbuf->new_from_file("toroid.png");
	my $image = Gnome2::Canvas::Item->new ($root,
					       'Gnome2::Canvas::Pixbuf',
					       pixbuf => $im,
					       x      => 100.0,
					       y      => 225.0,
					       width  => $im->get_width,
					       height => $im->get_height,
					       anchor => 'center',
					       );
	setup_item ($image);

	plant_flower ($root,  20.0, 170.0, 'GTK_ANCHOR_NW', $aa);
	plant_flower ($root, 180.0, 170.0, 'GTK_ANCHOR_NE', $aa);
	plant_flower ($root,  20.0, 280.0, 'GTK_ANCHOR_SW', $aa);
	plant_flower ($root, 180.0, 280.0, 'GTK_ANCHOR_SE', $aa);
	}
}

use constant VERTICES => 10;
use constant RADIUS   => 60.0;

sub polish_diamond {
	my $root = shift;

	my $group = Gnome2::Canvas::Item->new ($root, 'Gnome2::Canvas::Group',
					       x => 270.0, y => 230.0);
	setup_item ($group);

	my @coords;

	for (my $i = 0; $i < VERTICES; $i++) {
		my $a = 2.0 * M_PI * $i / VERTICES;
		$coords[0] = RADIUS * cos ($a);
		$coords[1] = RADIUS * sin ($a);

		for (my $j = $i + 1; $j < VERTICES; $j++) {
			$a = 2.0 * M_PI * $j / VERTICES;
			$coords[2] = RADIUS * cos ($a);
			$coords[3] = RADIUS * sin ($a);
			Gnome2::Canvas::Item->new ($group,
						   'Gnome2::Canvas::Line',
						   points => \@coords,
						   fill_color => 'black',
						   width_units => 1.0,
						   cap_style => 'round');
		}
	}
}

use constant SCALE => 7.0;

sub make_hilbert {
	my $root = shift;
	my $hilbert = "urdrrulurulldluuruluurdrurddldrrruluurdrurddldrddlulldrdldrrurd";

	my @coords = (340.0, 290.0);
	my @d = split //, $hilbert;
	for (my $i = 0 ; $i < @d ; $i++) {
		if ($d[$i] eq 'u') {
			$coords[2*($i+1)+0] = $coords[2*$i+0];
			$coords[2*($i+1)+1] = $coords[2*$i+1] - SCALE;
		} elsif ($d[$i] eq 'd  ') {
			$coords[2*($i+1)+0] = $coords[2*$i+0];
			$coords[2*($i+1)+1] = $coords[2*$i+1] + SCALE;
		} elsif ($d[$i] eq 'l  ') {
			$coords[2*($i+1)+0] = $coords[2*$i+0] - SCALE;
			$coords[2*($i+1)+1] = $coords[2*$i+1];
		} elsif ($d[$i] eq 'r  ') {
			$coords[2*($i+1)+0] = $coords[2*$i+0] + SCALE;
			$coords[2*($i+1)+1] = $coords[2*$i+1];
		}
	}

	if ($root->canvas->aa) {
		setup_item (Gnome2::Canvas::Item->new ($root,
					'Gnome2::Canvas::Line',
					points => \@coords,
					fill_color_rgba => 0xff000080,
					width_units => 4.0,
					cap_style => 'projecting',
					join_style => 'miter'));
	} else {
		my $stipple = Gtk2::Gdk::Bitmap->create_from_data
			(undef, $gray50_bits, $gray50_width, $gray50_height);
		setup_item (Gnome2::Canvas::Item->new ($root,
					'Gnome2::Canvas::Line',
					points => \@coords,
					fill_color => "red",
					fill_stipple => $stipple,
					width_units => 4.0,
					cap_style => 'projecting',
					join_style => 'miter'));
	}
}

sub setup_lines {
	my $root = shift;

	polish_diamond ($root);
	make_hilbert ($root);

	# Arrow tests

	setup_item (Gnome2::Canvas::Item->new ($root, 'Gnome2::Canvas::Line',
					       "points", [340.0, 170.0,
							  340.0, 230.0,
							  390.0, 230.0,
							  390.0, 170.0],
					       "fill_color", "midnightblue",
					       "width_units", 3.0,
					       "first_arrowhead", TRUE,
					       "last_arrowhead", TRUE,
					       "arrow_shape_a", 8.0,
					       "arrow_shape_b", 12.0,
					       "arrow_shape_c", 4.0));

	setup_item (Gnome2::Canvas::Item->new ($root, 'Gnome2::Canvas::Line',
					       "points", [356.0, 180.0,
							  374.0, 220.0],
					       "fill_color", "blue",
					       "width_pixels", 0,
					       "first_arrowhead", TRUE,
					       "last_arrowhead", TRUE,
					       "arrow_shape_a", 6.0,
					       "arrow_shape_b", 6.0,
					       "arrow_shape_c", 4.0));

	setup_item (Gnome2::Canvas::Item->new ($root, 'Gnome2::Canvas::Line',
					       "points", [356.0, 220.0,
						 	  374.0, 180.0],
					       "fill_color", "blue",
					       "width_pixels", 0,
					       "first_arrowhead", TRUE,
					       "last_arrowhead", TRUE,
					       "arrow_shape_a", 6.0,
					       "arrow_shape_b", 6.0,
					       "arrow_shape_c", 4.0));
}

sub setup_curves {
	my $root = shift;
	my $path_def = Gnome2::Canvas::PathDef->new;
	$path_def->moveto (500.0, 175.0);
	$path_def->curveto (550.0, 175.0, 550.0, 275.0, 500.0, 275.0);	
	my $item = Gnome2::Canvas::Item->new ($root, 'Gnome2::Canvas::Bpath',
					      #### can't set this here
					      ####bpath => $path_def,
					      outline_color => "black",
					      width_pixels => 4);
	$item->set_path_def ($path_def);
	setup_item ($item);
}

sub setup_polygons {
	my $root = shift;

	my @points = (210.0, 320.0,
		      210.0, 380.0,
		      260.0, 350.0);
	if ($root->canvas->aa) {
		setup_item (Gnome2::Canvas::Item->new ($root,
					   'Gnome2::Canvas::Polygon',
					   points => \@points,
					   fill_color_rgba => 0x0000ff80,
					   outline_color => 'black'));
	} else {
		my $stipple = Gtk2::Gdk::Bitmap->create_from_data (undef,
				$gray50_bits, $gray50_width, $gray50_height);
		setup_item (Gnome2::Canvas::Item->new ($root,
					   'Gnome2::Canvas::Polygon',
					   points => \@points,
					   fill_color => "blue",
					   fill_stipple => $stipple,
					   outline_color => "black"));
	}

	@points = (270.0, 330.0,
		   270.0, 430.0,
		   390.0, 430.0,
		   390.0, 330.0,
		   310.0, 330.0,
		   310.0, 390.0,
		   350.0, 390.0,
		   350.0, 370.0,
		   330.0, 370.0,
		   330.0, 350.0,
		   370.0, 350.0,
		   370.0, 410.0,
		   290.0, 410.0,
		   290.0, 330.0);
	setup_item (Gnome2::Canvas::Item->new ($root,
					       'Gnome2::Canvas::Polygon',
					       points => \@points,
					       fill_color => 'tan',
					       outline_color => 'black',
					       width_units => 3.0));
}

sub setup_widgets {
	my $group = shift;

	my $w = Gtk2::Button->new ("Hello world!");
	setup_item (Gnome2::Canvas::Item->new ($group,
					       'Gnome2::Canvas::Widget',
					       widget => $w,
					       x => 420.0,
					       y => 330.0,
					       width => 100.0,
					       height => 40.0,
					       anchor => 'nw', #GTK_ANCHOR_NW,
					       size_pixels => FALSE));
	$w->show;
}

sub key_press {
	my ($canvas, $event) = @_;

	my ($x, $y) = $canvas->get_scroll_offsets;

	if ($event->keyval == $Gtk2::Gdk::Keysyms{Up}) {
		$canvas->scroll_to ($x, $y - 20);
	} elsif ($event->keyval == $Gtk2::Gdk::Keysyms{Down}) {
		$canvas->scroll_to ($x, $y + 20);
	} elsif ($event->keyval == $Gtk2::Gdk::Keysyms{Left}) {
		$canvas->scroll_to ($x - 10, $y);
	} elsif ($event->keyval == $Gtk2::Gdk::Keysyms{Right}) {
		$canvas->scroll_to ($x + 10, $y);
	} else {
		return FALSE;
	}

	return TRUE;
}

sub create {
	my $aa = shift;

	my $vbox = Gtk2::VBox->new (FALSE, 4);
	$vbox->set_border_width (4);
	$vbox->show;

	my $w = Gtk2::Label->new ("Drag an item with button 1.  Click button 2 on an item to lower it,\n"
			. "or button 3 to raise it.  Shift+click with buttons 2 or 3 to send\n"
			. "an item to the bottom or top, respectively.");
	$vbox->pack_start ($w, FALSE, FALSE, 0);
	$w->show;

	my $hbox = Gtk2::HBox->new (FALSE, 4);
	$vbox->pack_start ($hbox, FALSE, FALSE, 0);
	$hbox->show;

	# Create the canvas

	#gtk_widget_push_colormap (gdk_rgb_get_cmap ());
#### FIXME
###	Gtk2::Widget->push_colormap (Gtk2::Gdk::Rgb->get_cmap);
	my $canvas = $aa ? Gnome2::Canvas->new_aa : Gnome2::Canvas->new;

	$canvas->set_center_scroll_region (FALSE);

	# Setup canvas items

	my $root = $canvas->root;

	setup_divisions ($root);
	setup_rectangles ($root);
	setup_ellipses ($root);
  	setup_texts ($root); 
	setup_images ($root, $aa);
	setup_lines ($root);
	setup_polygons ($root);
	setup_curves ($root);
	setup_widgets ($root);

## (this FIXME was in the original C source, too)
## FIXME: we should have a 'rotation' spinbutton too - and fix the acute
##  bugs with that ... 
##if 0
#	{
#		double affine[6];
#
##if 1
#		art_affine_rotate (affine, 15);
##else
#		art_affine_scale (affine, 1.5, 0.7);
##endif
#		gnome_canvas_item_affine_relative (root, affine);
#	}
##endif

### FIXME
####	Gtk2::Widget->pop_colormap;

	# Zoom

	$w = Gtk2::Label->new ("Zoom:");
	$hbox->pack_start ($w, FALSE, FALSE, 0);
	$w->show;

	my $adj = Gtk2::Adjustment->new (1.00, 0.05, 5.00, 0.05, 0.50, 0.50);
	$adj->signal_connect (value_changed => \&zoom_changed, $canvas);
	$w = Gtk2::SpinButton->new ($adj, 0.0, 2);
	$w->set_size_request (50, -1);
	$hbox->pack_start ($w, FALSE, FALSE, 0);
	$w->show;

	# Layout the stuff

	my $table = Gtk2::Table->new (2, 2, FALSE);
	$table->set_row_spacings (4);
	$table->set_col_spacings (4);
	$vbox->pack_start ($table, TRUE, TRUE, 0);
	$table->show;

	my $frame = Gtk2::Frame->new;
	$frame->set_shadow_type ('in');
	$table->attach ($frame,
			0, 1, 0, 1,
			[qw/expand fill shrink/],
			[qw/expand fill shrink/],
			0, 0);
	$frame->show;

	$canvas->set_size_request (600, 450);
	$canvas->set_scroll_region (0, 0, 600, 450);
	$frame->add ($canvas);
	$canvas->show;

	$canvas->signal_connect_after (key_press_event => \&key_press);

	$w = Gtk2::HScrollBar->new ($canvas->get_hadjustment);
	$table->attach ($w,
			0, 1, 1, 2,
			[qw/expand fill shrink/],
			[qw/fill/],
			0, 0);
	$w->show;;

	$w = Gtk2::VScrollBar->new ($canvas->get_vadjustment);
	$table->attach ($w,
			1, 2, 0, 1,
			['fill'],
			[qw/expand fill shrink/],
			0, 0);
	$w->show;

	$canvas->set_flags ('can-focus');
	$canvas->grab_focus;

	return $vbox;
}

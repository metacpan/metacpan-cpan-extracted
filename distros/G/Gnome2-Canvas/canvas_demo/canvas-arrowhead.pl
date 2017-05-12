package CanvasArrowhead;
use strict;
use Glib qw(TRUE FALSE);
use Gnome2::Canvas;

use constant LEFT            => 50.0;
use constant RIGHT           => 350.0;
use constant MIDDLE          => 150.0;
use constant DEFAULT_WIDTH   => 2;
use constant DEFAULT_SHAPE_A => 8;
use constant DEFAULT_SHAPE_B => 10;
use constant DEFAULT_SHAPE_C => 3;


sub set_dimension {
	my ($canvas, $arrow_name, $text_name,
	    $x1, $y1, $x2, $y2, $tx, $ty, $dim) = @_;

	$canvas->{$arrow_name}->set (points => [$x1, $y1, $x2, $y2]);

	$canvas->{$text_name}->set (text => $dim,
	                            x => $tx,
	                            y => $ty);

}

sub move_drag_box {
	my ($item, $x, $y) = @_;

	$item->set (x1 => $x - 5.0,
		    y1 => $y - 5.0,
		    x2 => $x + 5.0,
		    y2 => $y + 5.0);
}

sub set_arrow_shape {
	my $canvas = shift;

	my $width   = $canvas->{width};
	my $shape_a = $canvas->{shape_a};
	my $shape_b = $canvas->{shape_b};
	my $shape_c = $canvas->{shape_c};

	# Big arrow

	$canvas->{big_arrow}->set (width_pixels => 10 * $width,
	                           arrow_shape_a => $shape_a * 10,
	                           arrow_shape_b => $shape_b * 10,
	                           arrow_shape_c => $shape_c * 10);

	# Outline

	my @coords = ();
	$coords[0] = RIGHT - 10 * $shape_a;
	$coords[1] = MIDDLE;
	$coords[2] = RIGHT - 10 * $shape_b;
	$coords[3] = MIDDLE - 10 * ($shape_c + $width / 2.0);
	$coords[4] = RIGHT;
	$coords[5] = MIDDLE;
	$coords[6] = $coords[2];
	$coords[7] = MIDDLE + 10 * ($shape_c + $width / 2.0);
	$coords[8] = $coords[0];
	$coords[9] = $coords[1];
	$canvas->{outline}->set (points => \@coords);

	# Drag boxes

	move_drag_box ($canvas->{width_drag_box},
		       LEFT,
		       MIDDLE - 10 * $width / 2.0);

	move_drag_box ($canvas->{shape_a_drag_box},
		       RIGHT - 10 * $shape_a,
		       MIDDLE);

	move_drag_box ($canvas->{shape_b_c_drag_box},
		       RIGHT - 10 * $shape_b,
		       MIDDLE - 10 * ($shape_c + $width / 2.0));

	# Dimensions

	set_dimension ($canvas, "width_arrow", "width_text",
		       LEFT - 10,
		       MIDDLE - 10 * $width / 2.0,
		       LEFT - 10,
		       MIDDLE + 10 * $width / 2.0,
		       LEFT - 15,
		       MIDDLE,
		       $width);

	set_dimension ($canvas, "shape_a_arrow", "shape_a_text",
		       RIGHT - 10 * $shape_a,
		       MIDDLE + 10 * ($width / 2.0 + $shape_c) + 10,
		       RIGHT,
		       MIDDLE + 10 * ($width / 2.0 + $shape_c) + 10,
		       RIGHT - 10 * $shape_a / 2.0,
		       MIDDLE + 10 * ($width / 2.0 + $shape_c) + 15,
		       $shape_a);

	set_dimension ($canvas, "shape_b_arrow", "shape_b_text",
		       RIGHT - 10 * $shape_b,
		       MIDDLE + 10 * ($width / 2.0 + $shape_c) + 35,
		       RIGHT,
		       MIDDLE + 10 * ($width / 2.0 + $shape_c) + 35,
		       RIGHT - 10 * $shape_b / 2.0,
		       MIDDLE + 10 * ($width / 2.0 + $shape_c) + 40,
		       $shape_b);

	set_dimension ($canvas, "shape_c_arrow", "shape_c_text",
		       RIGHT + 10,
		       MIDDLE - 10 * $width / 2.0,
		       RIGHT + 10,
		       MIDDLE - 10 * ($width / 2.0 + $shape_c),
		       RIGHT + 15,
		       MIDDLE - 10 * ($width / 2.0 + $shape_c / 2.0),
		       $shape_c);

	# Info

	$canvas->{width_info}->set (text => "width: $width");
	$canvas->{shape_a_info}->set (text => "arrow_shape_a: $shape_a");
	$canvas->{shape_b_info}->set (text => "arrow_shape_b: $shape_b");
	$canvas->{shape_c_info}->set (text => "arrow_shape_c: $shape_c");

	# Sample arrows

	$canvas->{sample_1}->set (width_pixels => $width,
	                          arrow_shape_a => $shape_a,
	                          arrow_shape_b => $shape_b,
	                          arrow_shape_c => $shape_c);
	$canvas->{sample_2}->set (width_pixels => $width,
	                          arrow_shape_a => $shape_a,
	                          arrow_shape_b => $shape_b,
	                          arrow_shape_c => $shape_c);
	$canvas->{sample_3}->set (width_pixels => $width,
	                          arrow_shape_a => $shape_a,
	                          arrow_shape_b => $shape_b,
	                          arrow_shape_c => $shape_c);
}

sub highlight_box {
	my ($item, $event) = @_;

	if ($event->type eq 'enter-notify') {
		$item->set (fill_color => 'red');

	} elsif ($event->type eq 'leave-notify') {
		$item->set (fill_color => undef)
			unless $event->state & 'button1-mask';

	} elsif ($event->type eq 'button-press') {
		$item->grab ([qw/pointer-motion-mask button-release-mask/],
		             Gtk2::Gdk::Cursor->new ('fleur'),
		             $event->time);

	} elsif ($event->type eq 'button-release') {
		$item->ungrab ($event->time);
	}

	return FALSE;
}

sub create_drag_box {
	my ($root, $box_name, $callback) = @_;
	my $box = Gnome2::Canvas::Item->new ($root, 'Gnome2::Canvas::Rect',
					     fill_color => undef,
					     outline_color => 'black',
					     width_pixels => 0);
	$box->signal_connect (event => \&highlight_box);
	$box->signal_connect (event => $callback);

	$root->canvas->{$box_name} = $box;
}

sub width_event {
	my ($item, $event) = @_;

	return FALSE
		if (($event->type ne 'motion-notify') || 
		    !($event->state >= 'button1-mask'));

	my $width = (MIDDLE - $event->y) / 5;
	return FALSE
		if $width < 0;

	$item->canvas->{width} = $width;
	set_arrow_shape ($item->canvas);

	return FALSE;
}

sub shape_a_event {
	my ($item, $event) = @_;

	return FALSE
		if (($event->type ne 'motion-notify') || 
		    !($event->state >= 'button1-mask'));

	my $shape_a = (RIGHT - $event->x) / 10;
	return FALSE if (($shape_a < 0) || ($shape_a > 30));

	$item->canvas->{shape_a} = $shape_a;
	set_arrow_shape ($item->canvas);

	return FALSE;
}

sub shape_b_c_event {
	my ($item, $event) = @_;

	return FALSE
		if (($event->type ne 'motion-notify') || 
		    !($event->state >= 'button1-mask'));

	my $change = FALSE;

	my $shape_b = (RIGHT - $event->x) / 10;
	if (($shape_b >= 0) && ($shape_b <= 30)) {
		$item->canvas->{shape_b} = $shape_b;
		$change = TRUE;
	}

	my $width = $item->canvas->{width};
	my $shape_c = ((MIDDLE - 5 * $width) - $event->y) / 10;
	if ($shape_c >= 0) {
		$item->canvas->{shape_c} = $shape_c;
		$change = TRUE;
	}

	set_arrow_shape ($item->canvas)
		if $change;

	return FALSE;
}

sub create_dimension {
	my ($root, $arrow_name, $text_name, $anchor) = @_;

	my $item = Gnome2::Canvas::Item->new ($root, 'Gnome2::Canvas::Line',
					      fill_color => 'black',
					      first_arrowhead => TRUE,
					      last_arrowhead => TRUE,
					      arrow_shape_a => 5.0,
					      arrow_shape_b => 5.0,
					      arrow_shape_c => 3.0);
	$root->canvas->{$arrow_name} = $item;

	$item = Gnome2::Canvas::Item->new ($root, 'Gnome2::Canvas::Text',
					   fill_color => 'black',
					   font => 'Sans 12',
					   anchor => $anchor);
	$root->canvas->{$text_name} = $item;
}

sub create_info {
	my ($root, $info_name, $x, $y) = @_;
	my $item = Gnome2::Canvas::Item->new ($root, 'Gnome2::Canvas::Text',
					      x => $x,
					      y => $y,
					      fill_color => 'black',
					      font => 'Sans 14',
					      anchor => 'GTK_ANCHOR_NW');
	$root->canvas->{$info_name} = $item;
}

sub create_sample_arrow {
	my ($root, $sample_name, $x1, $y1, $x2, $y2) = @_;

	my $item = Gnome2::Canvas::Item->new ($root, 'Gnome2::Canvas::Line',
					      points => [$x1, $y1, $x2, $y2],
					      fill_color => 'black',
					      first_arrowhead => TRUE,
					      last_arrowhead => TRUE);
	$root->canvas->{$sample_name} = $item;
}

sub create {
	my $vbox = Gtk2::VBox->new (FALSE, 4);
	$vbox->set_border_width (4);
	$vbox->show;

	my $w = Gtk2::Label->new ("This demo allows you to edit arrowhead shapes.  Drag the little boxes\n"
		. "to change the shape of the line and its arrowhead.  You can see the\n"
		. "arrows at their normal scale on the right hand side of the window.");
	$vbox->pack_start ($w, FALSE, FALSE, 0);
	$w->show;

	$w = Gtk2::Alignment->new (0.5, 0.5, 0.0, 0.0);
	$vbox->pack_start ($w, TRUE, TRUE, 0);
	$w->show;

	my $frame = Gtk2::Frame->new;
	$frame->set_shadow_type ('in');
	$w->add ($frame);
	$frame->show;

	my $canvas = Gnome2::Canvas->new;
	$canvas->set_size_request (500, 350);
	$canvas->set_scroll_region (0, 0, 500, 350);
	$frame->add ($canvas);
	$canvas->show;

	my $root = $canvas->root;

	$canvas->{width} = DEFAULT_WIDTH;
	$canvas->{shape_a} = DEFAULT_SHAPE_A;
	$canvas->{shape_b} = DEFAULT_SHAPE_B;
	$canvas->{shape_c} = DEFAULT_SHAPE_C;

	# Big arrow

	my $item = Gnome2::Canvas::Item->new ($root, 'Gnome2::Canvas::Line',
				      points => [LEFT, MIDDLE,
				                 RIGHT, MIDDLE],
				      fill_color => 'mediumseagreen',
				      width_pixels => DEFAULT_WIDTH * 10,
				      last_arrowhead => TRUE);
	$canvas->{big_arrow} = $item;

	# Arrow outline

	$item = Gnome2::Canvas::Item->new ($root, 'Gnome2::Canvas::Line',
				      fill_color => 'black',
				      width_pixels => 2,
				      cap_style => 'round',
				      join_style => 'round');
	$canvas->{outline} = $item;

	# Drag boxes

	create_drag_box ($root, "width_drag_box", \&width_event);
	create_drag_box ($root, "shape_a_drag_box", \&shape_a_event);
	create_drag_box ($root, "shape_b_c_drag_box", \&shape_b_c_event);

	# Dimensions

	create_dimension ($root, "width_arrow", "width_text", 'e');
	create_dimension ($root, "shape_a_arrow", "shape_a_text", 'n');
	create_dimension ($root, "shape_b_arrow", "shape_b_text", 'n');
	create_dimension ($root, "shape_c_arrow", "shape_c_text", 'w');

	# Info

	create_info ($root, "width_info", LEFT, 260);
	create_info ($root, "shape_a_info", LEFT, 280);
	create_info ($root, "shape_b_info", LEFT, 300);
	create_info ($root, "shape_c_info", LEFT, 320);

	# Division line

	Gnome2::Canvas::Item->new ($root, 'Gnome2::Canvas::Line',
	                           points => [RIGHT + 50, 0,
	                                      RIGHT + 50, 1000],
	                           fill_color => 'black',
	                           width_pixels => 2);

	# Sample arrows

	create_sample_arrow ($root, "sample_1", RIGHT + 100, 30, RIGHT + 100, MIDDLE - 30);
	create_sample_arrow ($root, "sample_2", RIGHT + 70, MIDDLE, RIGHT + 130, MIDDLE);
	create_sample_arrow ($root, "sample_3", RIGHT + 70, MIDDLE + 30, RIGHT + 130, MIDDLE + 120);

	# Done!
	
	set_arrow_shape ($canvas);

	return $vbox;
}

1;

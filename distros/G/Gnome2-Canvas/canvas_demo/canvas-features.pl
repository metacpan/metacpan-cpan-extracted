package CanvasFeatures;

use strict;
use Glib qw(TRUE FALSE);
use Gnome2::Canvas;

use constant GNOME_PAD_SMALL => 4;

#
# Event handler for the item to be reparented.  When the user clicks on the
# item, it will be reparented to another group.
#

sub item_event {
	my ($item, $event) = @_;

	return FALSE
		if ($event->type ne 'button-press') || ($event->button != 1);

	my $parent1 = $item->{parent1};
	my $parent2 = $item->{parent2};

	$item->reparent ($item->parent == $parent1 ? $parent2 : $parent1);

	return TRUE;
}

sub create {
	my $vbox = Gtk2::VBox->new (FALSE, GNOME_PAD_SMALL);
	$vbox->set_border_width (GNOME_PAD_SMALL);
	$vbox->show;

	# Instructions

	my $w = Gtk2::Label->new ("Reparent test:  click on the items to switch them between parents");
	$vbox->pack_start ($w, FALSE, FALSE, 0);
	$w->show;

	# Frame and canvas

	my $alignment = Gtk2::Alignment->new (0.5, 0.5, 0.0, 0.0);
	$vbox->pack_start ($alignment, FALSE, FALSE, 0);
	$alignment->show;

	my $frame = Gtk2::Frame->new;
	$frame->set_shadow_type ('in');
	$alignment->add ($frame);
	$frame->show;

	my $canvas = Gnome2::Canvas->new;
	$canvas->set_size_request (400, 200);
	$canvas->set_scroll_region (0, 0, 400, 200);
	$frame->add ($canvas);
	$canvas->show;

	# First parent and box

	my $parent1 = Gnome2::Canvas::Item->new ($canvas->root,
						 'Gnome2::Canvas::Group',
						 x => 0.0,
						 y => 0.0);

	Gnome2::Canvas::Item->new ($parent1, 'Gnome2::Canvas::Rect',
				   x1 => 0.0,
				   y1 => 0.0,
				   x2 => 200.0,
				   y2 => 200.0,
				   fill_color => 'tan');

	# Second parent and box

	my $parent2 = Gnome2::Canvas::Item->new ($canvas->root,
	                                         'Gnome2::Canvas::Group',
						 x => 200.0,
						 y => 0.0);

	Gnome2::Canvas::Item->new ($parent2, 'Gnome2::Canvas::Rect',
				   x1 => 0.0,
				   y1 => 0.0,
				   x2 => 200.0,
				   y2 => 200.0,
				   fill_color => "#204060");

	# Big circle to be reparented

	my $item = Gnome2::Canvas::Item->new ($parent1,
					      'Gnome2::Canvas::Ellipse',
					      x1 => 10.0,
					      y1 => 10.0,
					      x2 => 190.0,
					      y2 => 190.0,
					      outline_color => 'black',
					      fill_color => 'mediumseagreen',
					      width_units => 3.0);
	$item->{parent1} = $parent1;
	$item->{parent2} = $parent2;
	$item->signal_connect (event => \&item_event);

	# A group to be reparented

	my $group =
		Gnome2::Canvas::Item->new ($parent2, 'Gnome2::Canvas::Group',
					    x => 100.0,
					    y => 100.0);

	Gnome2::Canvas::Item->new ($group, 'Gnome2::Canvas::Ellipse',
				   x1 => -50.0,
				   y1 => -50.0,
				   x2 => 50.0,
				   y2 => 50.0,
				   outline_color => 'black',
				   fill_color => 'wheat',
				   width_units => 3.0);
	Gnome2::Canvas::Item->new ($group, 'Gnome2::Canvas::Ellipse',
				   x1 => -25.0,
				   y1 => -25.0,
				   x2 => 25.0,
				   y2 => 25.0,
				   fill_color => 'steelblue');

	$group->{parent1} = $parent1;
	$group->{parent2} = $parent2;
	$group->signal_connect (event => \&item_event);

	# Done

	return $vbox;
}

1;

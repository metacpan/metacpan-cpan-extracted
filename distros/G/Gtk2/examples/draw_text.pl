#!/usr/bin/perl -w
#
# Here's a simple example of how to draw text with Gdk.
#

use strict;
use Glib ':constants';
use Gtk2 -init;

my $window = Gtk2::Window->new;
$window->signal_connect (destroy => sub {Gtk2->main_quit});

# a widget we can draw on.  has its own GdkWindow and therefore can
# receive events.
my $drawing_area = Gtk2::DrawingArea->new;
$window->add ($drawing_area);

# expose event is called when a repaint is needed.
$drawing_area->signal_connect (expose_event => sub {
	# $event contains the area that actually needs updating.
	# for simplicity, we'll just paint the whole thing.  you could
	# set up a clip region, but again, this is a simple example.
	my ($widget, $event) = @_;

	# we need a layout that contains the text we want to draw.
	my $layout = $widget->create_pango_layout ("Hello, world");

	# clear the background.  base_gc is the base color for text
	# widgets; in the default theme, this is the white background
	# of the TreeView, TextView, and Entry.
	$widget->window->draw_rectangle
			($widget->get_style->base_gc ($widget->state),
			 TRUE, 0, 0, $widget->allocation->width,
			 $widget->allocation->height);

	# draw the text.  text_gc is the foreground complement to
	# base_gc.  we'll keep the text centered in the window.
	my ($text_width, $text_height) = $layout->get_pixel_size;
	$widget->window->draw_layout
			($widget->get_style->text_gc ($widget->state),
			 ($widget->allocation->width - $text_width) / 2,
			 ($widget->allocation->height - $text_height) / 2,
			 $layout);
});

$window->show_all;
Gtk2->main;

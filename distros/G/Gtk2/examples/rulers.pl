#!/usr/bin/perl -w

# this example came from Stephen Wilhelm's gtk-perl tutorial,
#      http://personal.riverusers.com/~swilhelm/gtkperl-tutorial/
# which was derived from the original gtk tutorial,
#      http://gtk.org/tutorial/
#
# ported to gtk2-perl (which wan't hard) by muppet

use strict;
use Glib qw/FALSE/;
use Gtk2 -init;

my $xsize = 600;
my $ysize = 400;

my $window;
my $table;
my $area;
my $hrule;
my $vrule;


# Create the window
$window = new Gtk2::Window ( "toplevel" );
$window->signal_connect ("delete_event", sub { Gtk2->main_quit; });
$window->set_border_width (10);

# Create a table for placing the ruler and the drawing area
$table = new Gtk2::Table (3, 2, FALSE);
$window->add ($table);

# Create the drawing area.
$area = new Gtk2::DrawingArea;
$area->size ($xsize, $ysize);
$table->attach ($area,
                1, 2,               1, 2,
                ['expand', 'fill'], ['expand', 'fill'],
                0,                  0);
$area->set_events (['pointer_motion_mask', 'pointer_motion_hint_mask']);

# The horizontal ruler goes on top. As the mouse moves across the
# drawing area, a motion_notify_event event is propagated to the
# ruler so that the ruler can update itself properly.
$hrule = new Gtk2::HRuler;
$hrule->set_metric ('pixels');
$hrule->set_range (7, 13, 0, 20);
$area->signal_connect (motion_notify_event => sub { $hrule->event ($_[1]) });
$table->attach ($hrule,
                1, 2,                         0, 1,
                ['expand', 'shrink', 'fill'], [],
                0,                            0 );

# The vertical ruler goes on the left. As the mouse moves across the
# drawing area, a motion_notify_event event is propagated to the
# ruler so that the ruler can update itself properly.
$vrule = new Gtk2::VRuler;
$vrule->set_metric ('pixels');
$vrule->set_range (0, $ysize, 10, $ysize);
$area->signal_connect (motion_notify_event => sub { $vrule->event ($_[1]) });
$table->attach ($vrule,
                0, 1,    1, 2,
                [],      ['fill', 'expand', 'shrink'],
                0,       0 );

# Now show everything
$window->show_all;

main Gtk2;

# END EXAMPLE PROGRAM

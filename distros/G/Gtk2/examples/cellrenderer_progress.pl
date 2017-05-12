#!/usr/bin/perl -w

# ported from Tim-Philipp Meuller's Tree View tutorial,
# http://scentric.net/tutorial/sec-custom-cell-renderers.html#sec-custom-cell-renderer-example-body
# by muppet, 6 feb 04.
#
# This is based mainly on GtkCellRendererProgress
#  in GAIM, written and (c) 2002 by Sean Egan
#  (Licensed under the GPL), which in turn is
#  based on Gtk's GtkCellRenderer[Text|Toggle|Pixbuf]
#  implementation by Jonathan Blandford */

package Mup::CellRendererProgress;

use strict;
use warnings;
use Glib qw(G_PARAM_READWRITE);
use Gtk2;
use Glib::Object::Subclass
  Gtk2::CellRenderer::,
  properties => [
    Glib::ParamSpec->double ('percentage',
                             'Percentage',
                             'The fractional progress to display',
                             0.0, 1.0, 0.0, G_PARAM_READWRITE),
  ],
  ;


sub INIT_INSTANCE {
  my $self = shift;
  $self->set (mode => 'inert',
              xpad => 2,
              ypad => 2);
  $self->{percentage} = 0.0;
}

# we'll use the default new, GET_PROPERTY and SET_PROPERTY provided by
# Glib::Object::Subclass.


#
# calculate the size of our cell, taking into account padding and
# alignment properties of parent.
#

use constant FIXED_WIDTH  => 100;
use constant FIXED_HEIGHT => 10;

sub MAX { $_[0] > $_[1] ? $_[0] : $_[1] }

sub GET_SIZE {
  my ($cell, $widget, $cell_area) = @_;
  my ($x_offset, $y_offset) = (0, 0);

  my $width  = int ($cell->get ('xpad') * 2 + FIXED_WIDTH);
  my $height = int ($cell->get ('ypad') * 2 + FIXED_HEIGHT);

  if ($cell_area) {

    $x_offset = $cell->get ('xalign') * ($cell_area->width - $width);
    $x_offset = MAX ($x_offset, 0);

    $y_offset = $cell->get ('yalign') * ($cell_area->height - $height);
    $y_offset = MAX ($y_offset, 0);
  }

  return ($x_offset, $y_offset, $width, $height);
}


sub RENDER {
  my ($cell, $window, $widget, $background_area, $cell_area, $expose_area, $flags) = @_;

  # invoke GET_SIZE directly to avoid a lot of marshalling overhead.
  my ($x_offset, $y_offset, $width, $height)
            = $cell->GET_SIZE ($widget, $cell_area);

  my $state = $widget->has_focus ? 'active' : 'normal';

  my ($xpad, $ypad) = $cell->get (qw(xpad ypad));

  $width  -= $xpad*2;
  $height -= $ypad*2;

  my $style = $widget->style;
  $style->paint_box ($window,
                     'normal', 'in',
                     undef, $widget, "trough",
                     $cell_area->x + $x_offset + $xpad,
                     $cell_area->y + $y_offset + $ypad,
                     $width - 1, $height - 1);

  $style->paint_box ($window,
                     $state, 'out',
                     undef, $widget, "bar",
                     $cell_area->x + $x_offset + $xpad,
                     $cell_area->y + $y_offset + $ypad,
                     $width * $cell->{percentage},
                     $height - 1);
}


package main;

use strict;
use Glib qw(TRUE FALSE);
use Gtk2 -init;

my $liststore;
my $increasing = TRUE; # direction of progress bar change

use constant {
  COL_PERCENTAGE => 0,
  COL_TEXT       => 1,
  NUM_COLS       => 2,

  STEP           => 0.01,
};


sub increase_progress_timeout {
  my $renderer = shift;
  my $iter = $liststore->get_iter_first; # first and only row

  my $perc = $liststore->get ($iter, COL_PERCENTAGE);

  if ($perc > (1.0 - STEP)  ||  ($perc < STEP && $perc > 0.0) ) {
    $increasing = (!$increasing);
  }

  if ($increasing) {
    $perc += STEP;
  } else {
    $perc -= STEP;
  }

  my $buf = sprintf '%u %%', $perc*100;

  $liststore->set ($iter, COL_PERCENTAGE, $perc, COL_TEXT, $buf);

  return TRUE; # Call again
}


sub create_view_and_model {
  $liststore = Gtk2::ListStore->new (qw(Glib::Double Glib::String));
  my $iter = $liststore->append;
  $liststore->set ($iter, COL_PERCENTAGE, 0.5); # start at 50%

  my $view = Gtk2::TreeView->new ($liststore);

  my $renderer = Gtk2::CellRendererText->new;
  my $col = Gtk2::TreeViewColumn->new;
  $col->pack_start ($renderer, TRUE);
  $col->add_attribute ($renderer, text => COL_TEXT);
  $col->set_title ("Progress");
  $view->append_column ($col);

  $renderer = Mup::CellRendererProgress->new;
  $col = Gtk2::TreeViewColumn->new;
  $col->pack_start ($renderer, TRUE);
  $col->add_attribute ($renderer, percentage => COL_PERCENTAGE);
  $col->set_title ("Progress");
  $view->append_column ($col);

  Glib::Timeout->add (50, \&increase_progress_timeout);

  return $view;
}


my $window = Gtk2::Window->new;
$window->set_default_size (150, 100);
$window->signal_connect (delete_event => sub {Gtk2->main_quit});

my $view = create_view_and_model();

$window->add ($view);

$window->show_all;

Gtk2->main;



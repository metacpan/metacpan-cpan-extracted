#!/usr/bin/perl -w
#
# Paned Widgets
#
# The GtkHPaned and GtkVPaned Widgets divide their content
# area into two panes with a divider in between that the
# user can adjust. A separate child is placed into each
# pane.
#
# There are a number of options that can be set for each pane.
# This test contains both a horizontal (HPaned) and a vertical
# (VPaned) widget, and allows you to adjust the options for
# each side of each widget.
#

package panes;

use strict;
use Glib qw(TRUE FALSE);
use Gtk2;

sub toggle_resize {
  my ($widget, $child) = @_;

  my $paned = $child->parent;
  my $is_child1 = ($child == $paned->child1);

  my $resize = $is_child1 ? $paned->child1_resize : $paned->child2_resize;
  my $shrink = $is_child1 ? $paned->child1_shrink : $paned->child2_shrink;

  $child->parent->remove ($child);
  if ($is_child1) {
    $paned->pack1 ($child, !$resize, $shrink);
  } else {
    $paned->pack2 ($child, !$resize, $shrink);
  }
}

sub toggle_shrink {
  my ($widget, $child) = @_;

  my $paned = $child->parent;
  my $is_child1 = ($child == $paned->child1);

  my $resize = $is_child1 ? $paned->child1_resize : $paned->child2_resize;
  my $shrink = $is_child1 ? $paned->child1_shrink : $paned->child2_shrink;

  $child->parent->remove ($child);
  if ($is_child1) {
    $paned->pack1 ($child, $resize, !$shrink);
  } else {
    $paned->pack2 ($child, $resize, !$shrink);
  }
}

sub create_pane_options {
  my ($paned, $frame_label, $label1, $label2) = @_;

  my $frame = Gtk2::Frame->new ($frame_label);
  $frame->set_border_width (4);
  
  my $table = Gtk2::Table->new (3, 2, TRUE);
  $frame->add ($table);
  
  my $label = Gtk2::Label->new ($label1);
  $table->attach_defaults ($label, 0, 1, 0, 1);
  
  my $check_button = Gtk2::CheckButton->new ("_Resize");
  $table->attach_defaults ($check_button, 0, 1, 1, 2);
  $check_button->signal_connect (toggled => \&toggle_resize, $paned->child1);
  
  $check_button = Gtk2::CheckButton->new ("_Shrink");
  $table->attach_defaults ($check_button, 0, 1, 2, 3);
  $check_button->set_active (TRUE);
  $check_button->signal_connect (toggled => \&toggle_shrink, $paned->child1);
  
  $label = Gtk2::Label->new ($label2);
  $table->attach_defaults ($label, 1, 2, 0, 1);
  
  $check_button = Gtk2::CheckButton->new ("_Resize");
  $table->attach_defaults ($check_button, 1, 2, 1, 2);
  $check_button->set_active (TRUE);
  $check_button->signal_connect (toggled => \&toggle_resize, $paned->child2);
  
  $check_button = Gtk2::CheckButton->new ("_Shrink");
  $table->attach_defaults ($check_button, 1, 2, 2, 3);
  $check_button->set_active (TRUE);
  $check_button->signal_connect (toggled => \&toggle_shrink, $paned->child2);

  return $frame;
}

my $window = undef;
sub do {
  if (!$window) {
      $window = Gtk2::Window->new;

      $window->signal_connect (destroy => sub { $window = undef; 1 });

      $window->set_title ("Panes");
      $window->set_border_width (0);

      my $vbox = Gtk2::VBox->new (FALSE, 0);
      $window->add ($vbox);
      
      my $vpaned = Gtk2::VPaned->new;
      $vbox->pack_start ($vpaned, TRUE, TRUE, 0);
      $vpaned->set_border_width (5);

      my $hpaned = Gtk2::HPaned->new;
      $vpaned->add1 ($hpaned);

      my $frame = Gtk2::Frame->new;
      $frame->set_shadow_type ('in');
      $frame->set_size_request (60, 60);
      $hpaned->add1 ($frame);
      
      my $button = Gtk2::Button->new ("_Hi there");
      $frame->add ($button);

      $frame = Gtk2::Frame->new;
      $frame->set_shadow_type ('in');
      $frame->set_size_request (80, 60);
      $hpaned->add2 ($frame);

      $frame = Gtk2::Frame->new;
      $frame->set_shadow_type ('in');
      $frame->set_size_request (60, 80);
      $vpaned->add2 ($frame);

      # Now create toggle buttons to control sizing

      $vbox->pack_start (create_pane_options ($hpaned, "Horizontal", "Left", "Right"),
                         FALSE, FALSE, 0);

      $vbox->pack_start (create_pane_options ($vpaned, "Vertical", "Top", "Bottom"),
                         FALSE, FALSE, 0);

      $vbox->show_all;
  }

  if (!$window->visible) {
      $window->show;
  } else {
      $window->destroy;
      $window = undef;
  }

  return $window;
}

1;
__END__
Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list)

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Library General Public License for more
details.

You should have received a copy of the GNU Library General Public License along
with this library; if not, write to the Free Software Foundation, Inc., 
51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA.

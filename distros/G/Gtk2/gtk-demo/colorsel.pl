#!/usr/bin/perl -w
#
# Color Selector
#
# GtkColorSelection lets the user choose a color. GtkColorSelectionDialog is
# a prebuilt dialog containing a GtkColorSelection.
#
#

package colorsel;

use Glib qw(TRUE FALSE);
use Gtk2;

my $window = undef;
my $da;
my $color;

sub change_color_callback {
  my $button = shift;
  
  my $dialog = Gtk2::ColorSelectionDialog->new ("Changing color");

  $dialog->set_transient_for ($window);
  
  my $colorsel = $dialog->colorsel;

  $colorsel->set_previous_color ($color);
  $colorsel->set_current_color ($color);
  $colorsel->set_has_palette (TRUE);
  
  my $response = $dialog->run;

  if ($response eq 'ok') {
      $color = $colorsel->get_current_color;

      $da->modify_bg ('normal', $color);
  }
  
  $dialog->destroy;
}

sub do {
  if (!$window) {
      $color = Gtk2::Gdk::Color->new (0, 65535, 0);
      
      $window = Gtk2::Window->new;
      $window->set_title ("Color Selection");

      $window->signal_connect (destroy => sub { $window = undef });

      $window->set_border_width (8);

      my $vbox = Gtk2::VBox->new (FALSE, 8);
      $vbox->set_border_width (8);
      $window->add ($vbox);

      #
      # Create the color swatch area
      #
      
      my $frame = Gtk2::Frame->new;
      $frame->set_shadow_type ('in');
      $vbox->pack_start ($frame, TRUE, TRUE, 0);
      
      $da = Gtk2::DrawingArea->new;
      # set a minimum size
      $da->set_size_request (200, 200);
      # set the color
      $da->modify_bg ('normal', $color);
      
      $frame->add ($da);

      my $alignment = Gtk2::Alignment->new (1.0, 0.5, 0.0, 0.0);
      
      my $button = Gtk2::Button->new_with_mnemonic ("_Change the above color");
      $alignment->add ($button);
      
      $vbox->pack_start ($alignment, FALSE, FALSE, 0);
      
      $button->signal_connect (clicked => \&change_color_callback);
  }

  if (!$window->visible) {
      $window->show_all;
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

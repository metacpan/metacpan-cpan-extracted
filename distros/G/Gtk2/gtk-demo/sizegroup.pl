#!/usr/bin/perl -w
#
# Size Groups
#
# GtkSizeGroup provides a mechanism for grouping a number of
# widgets together so they all request the same amount of space.
# This is typically useful when you want a column of widgets to 
# have the same size, but you can't use a GtkTable widget.
# 
# Note that size groups only affect the amount of space requested,
# not the size that the widgets finally receive. If you want the
# widgets in a GtkSizeGroup to actually be the same size, you need
# to pack them in such a way that they get the size they request
# and not more. For example, if you are packing your widgets
# into a table, you would not include the GTK_FILL flag.
#

package sizegroup;

use strict;
use Glib qw(TRUE FALSE);
use Gtk2;

my $window = undef;

#
# Convenience function to create an option menu holding a number of strings
#
sub create_option_menu {
  my @strings = @_;

  if (Gtk2->CHECK_VERSION (2, 4, 0)) {
    my $combo_box = Gtk2::ComboBox->new_text;

    foreach my $str (@strings) {
      $combo_box->append_text ($str);
    }
    $combo_box->set_active (0);

    return $combo_box;
  } else {
    # on older versions, Gtk2::ComboBox is not available.
    my $menu = Gtk2::Menu->new;
 
    foreach my $str (@strings) {
      my $menu_item = Gtk2::MenuItem->new_with_label ($str);
      $menu_item->show;

      $menu->append ($menu_item);
    }

    my $option_menu = Gtk2::OptionMenu->new;
    $option_menu->set_menu ($menu);

    return $option_menu;
  }
}

sub add_row {
  my ($table, $row, $size_group, $label_text, @options) = @_;

  my $label = Gtk2::Label->new_with_mnemonic ($label_text);
  $label->set_alignment (0, 1);
  $table->attach ($label,
		  0, 1,              $row, $row + 1,
		  [qw/expand fill/], [],
		  0,                 0);
  
  my $option_menu = create_option_menu (@options);
  $label->set_mnemonic_widget ($option_menu);
  $size_group->add_widget ($option_menu);
  $table->attach ($option_menu,
		  1, 2,  $row, $row + 1,
		  [],    [],
		  0,     0);
}

sub toggle_grouping {
  my ($check_button, $size_group) = @_;

  # GTK_SIZE_GROUP_NONE is not generally useful, but is useful
  # here to show the effect of GTK_SIZE_GROUP_HORIZONTAL by
  # contrast.
  my $new_mode = $check_button->get_active
            ? 'horizontal'
            : 'none';
  
  $size_group->set_mode ($new_mode);
}

sub do {
  my @color_options = qw/Red Green Blue/;
  my @dash_options  = qw/Solid Dashed Dotted/;
  my @end_options   = qw/Square Round Arrow/;
  
  if (!$window) {
      $window = Gtk2::Dialog->new_with_buttons ("GtkSizeGroup", undef, [],
                                                'gtk-close' => 'none');
      $window->set_resizable (FALSE);
      
      $window->signal_connect (response => sub { $window->destroy; 1 });
      $window->signal_connect (destroy => sub { $window = undef; 1 });

      my $vbox = Gtk2::VBox->new (FALSE, 5);
      $window->vbox->pack_start ($vbox, TRUE, TRUE, 0);
      $vbox->set_border_width (5);

      my $size_group = Gtk2::SizeGroup->new ('horizontal');
      
      # Create one frame holding color options
      #
      my $frame = Gtk2::Frame->new ("Color Options");
      $vbox->pack_start ($frame, TRUE, TRUE, 0);

      my $table = Gtk2::Table->new (2, 2, FALSE);
      $table->set_border_width (5);
      $table->set_row_spacings (5);
      $table->set_col_spacings (10);
      $frame->add ($table);

      add_row ($table, 0, $size_group, "_Foreground", @color_options);
      add_row ($table, 1, $size_group, "_Background", @color_options);

      # And another frame holding line style options
      #
      $frame = Gtk2::Frame->new ("Line Options");
      $vbox->pack_start ($frame, FALSE, FALSE, 0);

      $table = Gtk2::Table->new (2, 2, FALSE);
      $table->set_border_width (5);
      $table->set_row_spacings (5);
      $table->set_col_spacings (10);
      $frame->add ($table);

      add_row ($table, 0, $size_group, "_Dashing", @dash_options);
      add_row ($table, 1, $size_group, "_Line ends", @end_options);

      # And a check button to turn grouping on and off
      my $check_button = Gtk2::CheckButton->new ("_Enable grouping");
      $vbox->pack_start ($check_button, FALSE, FALSE, 0);
      
      $check_button->set_active (TRUE);
      $check_button->signal_connect (toggled => \&toggle_grouping, $size_group);
  }

  if (!$window->visible) {
    $window->show_all;
  } else {
    $window->destroy;
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

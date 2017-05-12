#!/usr/bin/perl -w
#
# Menus
#
# There are several widgets involved in displaying menus. The
# GtkMenuBar widget is a horizontal menu bar, which normally appears
# at the top of an application. The GtkMenu widget is the actual menu
# that pops up. Both GtkMenuBar and GtkMenu are subclasses of
# GtkMenuShell; a GtkMenuShell contains menu items
# (GtkMenuItem). Each menu item contains text and/or images and can
# be selected by the user.
#
# There are several kinds of menu item, including plain GtkMenuItem,
# GtkCheckMenuItem which can be checked/unchecked, GtkRadioMenuItem
# which is a check menu item that's in a mutually exclusive group,
# GtkSeparatorMenuItem which is a separator bar, GtkTearoffMenuItem
# which allows a GtkMenu to be torn off, and GtkImageMenuItem which
# can place a GtkImage or other widget next to the menu text.
#
# A GtkMenuItem can have a submenu, which is simply a GtkMenu to pop
# up when the menu item is selected. Typically, all menu items in a menu bar
# have submenus.
#
# The GtkOptionMenu widget is a button that pops up a GtkMenu when clicked.
# It's used inside dialogs and such.
#
# GtkItemFactory provides a higher-level interface for creating menu bars
# and menus; while you can construct menus manually, most people don't
# do that. There's a separate demo for GtkItemFactory.
# 
#

package menus;

use strict;
use Glib qw(TRUE FALSE);
use Gtk2;
use Gtk2::Gdk::Keysyms;

sub create_menu {
  my ($depth, $tearoff) = @_;

  return undef if $depth < 1;

  my $menu = Gtk2::Menu->new;
  my $group = undef;

  if ($tearoff) {
      my $menuitem = Gtk2::TearoffMenuItem->new;
      $menu->append ($menuitem);
      $menuitem->show;
  }

  my ($i, $j);
  for ($i = 0, $j = 1; $i < 5; $i++, $j++) {
      my $buf = sprintf 'item %2d - %d', $depth, $j;
      #warn "creating [".($group?$group:"undef")."][$buf]\n";
      my $menuitem = Gtk2::RadioMenuItem->new_with_label ($group, $buf);
      $group = $menuitem->get_group;

      $menu->append ($menuitem);
      $menuitem->show;
      $menuitem->set_sensitive (FALSE)
         if $i == 3;

      #$menuitem->set_submenu (create_menu ($depth - 1, TRUE));
      my $submenu = create_menu ($depth - 1, TRUE);
      $menuitem->set_submenu ($submenu) if defined $submenu;
  }

  return $menu;
}

my $window = undef;
sub do {
  if (!$window) {
      $window = Gtk2::Window->new;
      
      $window->signal_connect (destroy => sub { $window = undef; 1 });
      $window->signal_connect (delete_event => sub { 1 });
      
      my $accel_group = Gtk2::AccelGroup->new;
      $window->add_accel_group ($accel_group);

      $window->set_title ("menus");
      $window->set_border_width (0);
      
      
      my $box1 = Gtk2::VBox->new (FALSE, 0);
      $window->add ($box1);
      $box1->show;
      
      my $menubar = Gtk2::MenuBar->new;
      $box1->pack_start ($menubar, FALSE, TRUE, 0);
      $menubar->show;
      
      my $menu = create_menu (2, TRUE);
      
      my $menuitem = Gtk2::MenuItem->new_with_label ("test\nline2");
      $menuitem->set_submenu ($menu);
      $menubar->append ($menuitem);
      $menuitem->show;
      
      $menuitem = Gtk2::MenuItem->new_with_label ("foo");
      $menuitem->set_submenu (create_menu (3, TRUE));
      $menubar->append ($menuitem);
      $menuitem->show;

      $menuitem = Gtk2::MenuItem->new_with_label ("bar");
      $menuitem->set_submenu (create_menu (4, TRUE));
      $menuitem->set_right_justified (TRUE);
      $menubar->append ($menuitem);
      $menuitem->show;
      
      my $box2 = Gtk2::VBox->new (FALSE, 10);
      $box2->set_border_width (10);
      $box1->pack_start ($box2, TRUE, TRUE, 0);
      $box2->show;
      
      $menu = create_menu (1, FALSE);
      $menu->set_accel_group ($accel_group);
      
      $menuitem = Gtk2::SeparatorMenuItem->new;
      $menu->append ($menuitem);
      $menuitem->show;
      
      $menuitem = Gtk2::CheckMenuItem->new_with_label ("Accelerate Me");
      $menu->append ($menuitem);
      $menuitem->show;
      $menuitem->show;
      $menuitem->add_accelerator (activate => $accel_group,
				  $Gtk2::Gdk::Keysyms{F1}, #GDK_F1,
				  [], ['visible']);
      $menuitem = Gtk2::CheckMenuItem->new_with_label ("Accelerator Locked");
      $menu->append ($menuitem);
      $menuitem->show;
      $menuitem->add_accelerator (activate => $accel_group,
				  $Gtk2::Gdk::Keysyms{F2}, #GDK_F2,
				  [], [qw/visible locked/]);
      $menuitem = Gtk2::CheckMenuItem->new_with_label ("Accelerators Frozen");
      $menu->append ($menuitem);
      $menuitem->show;
      $menuitem->add_accelerator (activate => $accel_group,
				  $Gtk2::Gdk::Keysyms{F2}, #GDK_F2,
				  [], ['visible']);
      $menuitem->add_accelerator (activate => $accel_group,
				  $Gtk2::Gdk::Keysyms{F3}, #GDK_F3,
				  [], ['visible']);
      
      my $optionmenu = Gtk2::OptionMenu->new;
      $optionmenu->set_menu ($menu);
      $optionmenu->set_history (3);
      $box2->pack_start ($optionmenu, TRUE, TRUE, 0);
      $optionmenu->show;

      my $separator = Gtk2::HSeparator->new;
      $box1->pack_start ($separator, FALSE, TRUE, 0);
      $separator->show;

      $box2 = Gtk2::VBox->new (FALSE, 10);
      $box2->set_border_width (10);
      $box1->pack_start ($box2, FALSE, TRUE, 0);
      $box2->show;

##      my $button = Gtk2::Button->new_with_label ("close");
      my $button = Gtk2::Button->new ("close");
      $button->signal_connect_swapped (clicked => sub { $window->destroy; 1 });
      $box2->pack_start ($button, TRUE, TRUE, 0);
      $button->set_flags ('can-default');
      $button->grab_default;
      $button->show;
  }

  if (! $window->visible) {
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

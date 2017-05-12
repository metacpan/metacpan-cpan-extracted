#!/usr/bin/perl -w
#
# Application main window
#
# Demonstrates a typical application window, with menubar, toolbar, statusbar.
#

package appwindow;

use Glib ':constants';
use Gtk2;
#include "demo-common.h"

my $window = undef;


sub menuitem_cb {
  my ($callback_data, $callback_action, $widget) = @_;
  
  my $dialog = Gtk2::MessageDialog->new ($callback_data,
                                         'destroy-with-parent',
                                         'info',
                                         'close',
                                         sprintf "You selected or toggled the menu item: \"%s\"",
                                    Gtk2::ItemFactory->path_from_widget ($widget));

  # Close dialog on user response
  $dialog->signal_connect (response => sub { $dialog->destroy; 1 });
  
  $dialog->show;
}


my @menu_items = (
  [ "/_File",            undef,        undef,          0, "<Branch>" ],
  [ "/File/_New",        "<control>N", \&menuitem_cb,  0, "<StockItem>", 'gtk-new' ],
  [ "/File/_Open",       "<control>O", \&menuitem_cb,  0, "<StockItem>", 'gtk-open' ],
  [ "/File/_Save",       "<control>S", \&menuitem_cb,  0, "<StockItem>", 'gtk-save' ],
  [ "/File/Save _As...", undef,        \&menuitem_cb,  0, "<StockItem>", 'gtk-save' ],
  [ "/File/sep1",        undef,        \&menuitem_cb,  0, "<Separator>" ],
  [ "/File/_Quit",       "<control>Q", \&menuitem_cb,  0, "<StockItem>", 'gtk-quit' ],

  [ "/_Preferences",                  undef, undef,         0, "<Branch>" ],
  [ "/_Preferences/_Color",           undef, undef,         0, "<Branch>" ],
  [ "/_Preferences/Color/_Red",       undef, \&menuitem_cb, 0, "<RadioItem>" ],
  [ "/_Preferences/Color/_Green",     undef, \&menuitem_cb, 0, "/Preferences/Color/Red" ],
  [ "/_Preferences/Color/_Blue",      undef, \&menuitem_cb, 0, "/Preferences/Color/Red" ],
  [ "/_Preferences/_Shape",           undef, undef,         0, "<Branch>" ],
  [ "/_Preferences/Shape/_Square",    undef, \&menuitem_cb, 0, "<RadioItem>" ],
  [ "/_Preferences/Shape/_Rectangle", undef, \&menuitem_cb, 0, "/Preferences/Shape/Square" ],
  [ "/_Preferences/Shape/_Oval",      undef, \&menuitem_cb, 0, "/Preferences/Shape/Rectangle" ],

  # If you wanted this to be right justified you would use "<LastBranch>", not "<Branch>".
  # Right justified help menu items are generally considered a bad idea now days.
  [ "/_Help",       undef, undef,         0, "<Branch>" ],
  [ "/Help/_About", undef, \&menuitem_cb, 0 ],
);


sub toolbar_cb {
  my ($button, $data) = @_;
  
  my $dialog = Gtk2::MessageDialog->new ($data, 'destroy-with-parent',
                                         'info', 'close',
                                         "You selected a toolbar button");

  # Close dialog on user response
  $dialog->signal_connect (response => sub { $_[0]->destroy; 1 });
  
  $dialog->show;
}

#
# This function registers our custom toolbar icons, so they can be themed.
#
# It's totally optional to do this, you could just manually insert icons
# and have them not be themeable, especially if you never expect people
# to theme your app.
#
my $registered = FALSE;
sub register_stock_icons {
  if (!$registered) {
      my @items = (
        #[ "demo-gtk-logo", "_GTK!", 0, 0, undef ]
        {
           stock_id => "demo-gtk-logo",
           label => "_GTK!",
        },
      );
      
      $registered = TRUE;

      # Register our stock items
      Gtk2::Stock->add (@items);
      
      # Add our custom icon factory to the list of defaults
      my $factory = Gtk2::IconFactory->new;
      $factory->add_default;

      #
      # demo_find_file() looks in the the current directory first,
      # so you can run gtk-demo without installing GTK, then looks
      # in the location where the file is installed.
      #
      my $pixbuf = undef;
###      my $filename = demo_find_file ("gtk-logo-rgb.gif", undef);
      my $filename = "gtk-logo-rgb.gif";
      if ($filename) {
          eval {
             $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file (
		     main::demo_find_file ($filename));

             # The gtk-logo-rgb icon has a white background, make it transparent
             my $transparent = $pixbuf->add_alpha (TRUE, 0xff, 0xff, 0xff);
          
             my $icon_set = Gtk2::IconSet->new_from_pixbuf ($transparent);
             $factory->add ("demo-gtk-logo", $icon_set);
          };
          warn "failed to load GTK logo for toolbar"
              if $@;
      }
      # $factory goes out of scope here, but GTK will hold a reference on it.
  }
}

sub update_statusbar {
  my ($buffer, $statusbar) = @_;

  $statusbar->pop (0); # clear any previous message, underflow is allowed

  my $count = $buffer->get_char_count;

  my $iter = $buffer->get_iter_at_mark ($buffer->get_insert);

  my $row = $iter->get_line;
  my $col = $iter->get_line_offset;

  $statusbar->push (0, "Cursor at row $row column $col - $count chars in document");
}

sub mark_set_callback {
  my ($buffer, $new_location, $mark, $data) = @_;
  update_statusbar ($buffer, $data);
}


sub do {  
  if (!$window) {
      register_stock_icons ();
     
      # 
      # Create the toplevel window
      #
      
      $window = Gtk2::Window->new;
      $window->set_title ("Application Window");

      # NULL window variable when window is closed
      $window->signal_connect (destroy => sub { $window = undef; 1 });

      my $table = Gtk2::Table->new (1, 4, FALSE);
      
      $window->add ($table);
      
      #
      # Create the menubar
      #
      
      my $accel_group = Gtk2::AccelGroup->new;
      $window->add_accel_group ($accel_group);
      
      my $item_factory = Gtk2::ItemFactory->new ("Gtk2::MenuBar", "<main>", 
                                                 $accel_group);

      # Set up item factory to go away with the window
      $window->{'<main>'} = $item_factory;

      # create menu items
      $item_factory->create_items ($window, @menu_items);

      $table->attach ($item_factory->get_widget ("<main>"),
                      # X direction         Y direction
                      0, 1,                 0, 1,
                      [qw/expand fill/],    [],
                      0,                    0);

      #
      # Create the toolbar
      #
      my $toolbar = Gtk2::Toolbar->new;

      $toolbar->insert_stock ('gtk-open',
                              "This is a demo button with an 'open' icon",
                              undef,
                              \&toolbar_cb,
                              $window, # user data for callback
                              -1);  # -1 means "append"

      $toolbar->insert_stock ('gtk-quit',
                              "This is a demo button with a 'quit' icon",
                              undef,
                              \&toolbar_cb,
                              $window, # user data for callback
                              -1);  # -1 means "append"

      $toolbar->append_space;

      $toolbar->insert_stock ("demo-gtk-logo",
                              "This is a demo button with a 'gtk' icon",
                              undef,
                              \&toolbar_cb,
                              $window, # user data for callback
                              -1);  # -1 means "append"

      $table->attach ($toolbar,
                      # X direction      Y direction
                      0, 1,              1, 2,
                      [qw/expand fill/], [],
                      0,                 0);

      #
      # Create document
      #

      my $sw = Gtk2::ScrolledWindow->new;

      $sw->set_policy ('automatic', 'automatic');

      $sw->set_shadow_type ('in');
      
      $table->attach ($sw,
                      #  X direction     Y direction
                      0, 1,              2, 3,
                      [qw/expand fill/], [qw/expand fill/],
                      0,                 0);

      $window->set_default_size (200, 200);
      
      my $contents = Gtk2::TextView->new;

      $sw->add ($contents);

      # Create statusbar

      my $statusbar = Gtk2::Statusbar->new;
      $table->attach ($statusbar,
                      # X direction      Y direction
                      0, 1,              3, 4,
                      [qw/expand fill/], [],
                      0,                 0);

      # Show text widget info in the statusbar
      my $buffer = $contents->get_buffer;
      
      $buffer->signal_connect (changed => \&update_statusbar, $statusbar);

      # mark-set means cursor moved
      $buffer->signal_connect (mark_set => \&mark_set_callback, $statusbar);
      
      update_statusbar ($buffer, $statusbar);
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

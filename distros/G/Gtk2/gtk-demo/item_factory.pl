#!/usr/bin/perl -w
#
# Item Factory
#
# The GtkItemFactory object allows the easy creation of menus
# from an array of descriptions of menu items.
#

package item_factory;

use Glib qw(TRUE FALSE);
use Gtk2;

sub gtk_ifactory_cb {
  my ($data, $action, $widget) = @_;
  #use Data::Dumper;
  #print "gtk_ifactory_cb: ".Dumper(\@_);
  warn "ItemFactory: activated \""
     . Gtk2::ItemFactory->path_from_widget ($widget)
     . "\"\n";
}

my @menu_items = (
  [ "/_File",                         undef, undef,             0, "<Branch>" ],
  [ "/File/tearoff1",                 undef, \&gtk_ifactory_cb, 0, "<Tearoff>" ],
  [ "/File/_New",              "<control>N", \&gtk_ifactory_cb, 1 ],
  [ "/File/_Open",             "<control>O", \&gtk_ifactory_cb, 2 ],
  [ "/File/_Save",             "<control>S", \&gtk_ifactory_cb, 3 ],
  [ "/File/Save _As...",              undef, \&gtk_ifactory_cb, 4 ],
  [ "/File/sep1",                     undef, \&gtk_ifactory_cb, 0, "<Separator>" ],
  [ "/File/_Quit",             "<control>Q", \&gtk_ifactory_cb, 0 ],

  [ "/_Preferences",                  undef, undef,             0, "<Branch>" ],
  [ "/_Preferences/_Color",           undef, undef,             0, "<Branch>" ],
  [ "/_Preferences/Color/_Red",       undef, \&gtk_ifactory_cb, 0, "<RadioItem>" ],
  [ "/_Preferences/Color/_Green",     undef, \&gtk_ifactory_cb, 0, "/Preferences/Color/Red" ],
  [ "/_Preferences/Color/_Blue",      undef, \&gtk_ifactory_cb, 0, "/Preferences/Color/Red" ],
  [ "/_Preferences/_Shape",           undef, undef,             0, "<Branch>" ],
  [ "/_Preferences/Shape/_Square",    undef, \&gtk_ifactory_cb, 0, "<RadioItem>" ],
  [ "/_Preferences/Shape/_Rectangle", undef, \&gtk_ifactory_cb, 0, "/Preferences/Shape/Square" ],
  [ "/_Preferences/Shape/_Oval",      undef, \&gtk_ifactory_cb, 0, "/Preferences/Shape/Rectangle" ],

  [ "/_Help",                         undef, undef,             0, "<LastBranch>" ],
  [ "/Help/_About",                   undef, \&gtk_ifactory_cb, 0 ],
);


my $window = undef;

sub do {
  if (!$window) {
      $window = Gtk2::Window->new;
      
      $window->signal_connect (destroy => sub { $window = undef; 1 });
      $window->signal_connect (delete_event => sub { $window->destroy; 1 });
      
      my $accel_group = Gtk2::AccelGroup->new;
      my $item_factory = Gtk2::ItemFactory->new ('Gtk2::MenuBar', 
                                                 '<main>', $accel_group);
      $window->{"<main>"} = $item_factory;
      $window->add_accel_group ($accel_group);
      $window->set_title ("Item Factory");
      $window->set_border_width (0);
###      $item_factory->create_items (nmenu_items, menu_items, NULL);
      $item_factory->create_items (undef, @menu_items);

      # preselect /Preferences/Shape/Oval over the other radios
      $item_factory->get_item ("/Preferences/Shape/Oval")->set_active (TRUE);

      my $box1 = Gtk2::VBox->new (FALSE, 0);
      $window->add ($box1);
      
      $box1->pack_start ($item_factory->get_widget ("<main>"), FALSE, FALSE, 0);

      my $label = Gtk2::Label->new ("Type\n<alt>\nto start");
      $label->set_size_request (200, 200);
      $label->set_alignment (0.5, 0.5);
      $box1->pack_start ($label, TRUE, TRUE, 0);


      my $separator = Gtk2::HSeparator->new;
      $box1->pack_start ($separator, FALSE, TRUE, 0);


      my $box2 = Gtk2::VBox->new (FALSE, 10);
      $box2->set_border_width (10);
      $box1->pack_start ($box2, FALSE, TRUE, 0);

      my $button = Gtk2::Button->new ("close");
      $button->signal_connect (clicked => sub {$window->destroy; 1});
      $box2->pack_start ($button, TRUE, TRUE, 0);
      $button->set_flags ('can-default');
      $button->grab_default;

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

#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-ComboBoxBits.
#
# Gtk2-Ex-ComboBoxBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ComboBoxBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ComboBoxBits.  If not, see <http://www.gnu.org/licenses/>.


# gtk_radio_menu_item_activate() won't allow self to go off if no other in
# group is on.  When turning on sets all others in group to off.
#

use 5.010;
use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::Menu::EnumRadio 6; # v.6 in ComboBoxBits

use Smart::Comments;

use FindBin;
my $progname = $FindBin::Script;

if (0) {
  # my $menuitem = Gtk2::MenuItem->new ('_hello');
  my $menuitem = Gtk2::MenuItem->new_with_label ('hello');
  #  my $menuitem = Glib::Object::new ('Gtk2::MenuItem');
  ### child: $menuitem->get_child
  ### label: $menuitem->get('label')
  ### under: $menuitem->get('use-underline')
  # $menuitem->set(label => undef);
  exit 0;
}


Glib::Type->register_enum ('My::Test1', 'foo', 'bar-ski', 'quux',
                           # 100 .. 105,
                          );

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $menubar = Gtk2::MenuBar->new;
$vbox->pack_start ($menubar, 0,0,0);

my $item = Gtk2::MenuItem->new_with_label ('Menu');
$menubar->add ($item);

my $menu = Gtk2::Ex::Menu::EnumRadio->new
  (enum_type => 'My::Test1');
$menu->signal_connect ('notify::active-nick' => sub {
                         my ($menu) = @_;
                         print "$progname: active-nick now ",$menu->get('active-nick')||'[undef]',"\n";
                       });
$item->set_submenu ($menu);

my $tearoff = Gtk2::TearoffMenuItem->new;
$menu->prepend($tearoff);

{
  my $button = Gtk2::Button->new_with_label ('set active undef');
  $button->signal_connect (clicked => sub {
                             $menu->set (active_nick => undef);
                           });
  $vbox->pack_start ($button, 0, 0, 0);
}

$toplevel->show_all;
Gtk2->main;
exit 0;


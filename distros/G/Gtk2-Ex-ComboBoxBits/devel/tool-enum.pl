#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

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


use 5.008;
use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::ToolItem::ComboEnum;

use Smart::Comments;

use FindBin;
my $progname = $FindBin::Script;

Glib::Type->register_enum ('My::Test1', 'foo', 'bar-ski', 'quux',
                           # 100 .. 105,
                          );

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new;
$vbox->show;
$toplevel->add ($vbox);

my $toolbar = Gtk2::Toolbar->new;
$toolbar->show;
$vbox->pack_start ($toolbar, 0,0,0);

{
  my $toolitem = Gtk2::ToolButton->new(undef,'xxxxxxxxxxxxxxx');
  $toolitem->show;
  $toolbar->add($toolitem);
}

my $toolitem = Gtk2::Ex::ToolItem::ComboEnum->new
  (enum_type => 'My::Test1',
   visible => 1);
$toolitem->signal_connect ('notify::active-nick' => sub {
                         my ($toolitem) = @_;
                         print "$progname: active-nick now ",$toolitem->get('active-nick')||'[undef]',"\n";
                       });
$toolbar->add($toolitem);

{
  my $button = Gtk2::Button->new_with_label ('set active undef');
  $button->signal_connect (clicked => sub {
                             $toolitem->set (active_nick => undef);
                           });
  $button->show_all;
  $vbox->pack_start ($button, 0, 0, 0);
}

{
  my $button = Gtk2::CheckButton->new_with_label ('ComboBox add-tearoffs');
  my $combobox = $toolitem->get_child;
  require Glib::Ex::ConnectProperties;
  Glib::Ex::ConnectProperties->new
      ([$combobox, 'add-tearoffs'],
       [$button, 'active']);
  $button->show;
  $vbox->pack_start ($button, 0, 0, 0);
}

$toplevel->show;
Gtk2->main;
exit 0;


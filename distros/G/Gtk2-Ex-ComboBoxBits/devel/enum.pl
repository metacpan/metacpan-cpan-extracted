#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-ComboBoxBits.
#
# Gtk2-Ex-ComboBoxBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ComboBoxBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ComboBoxBits.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Gtk2::Ex::ComboBox::Enum;
use Gtk2 '-init';

use FindBin;
my $progname = $FindBin::Script;

# uncomment this to run the ### lines
use Smart::Comments;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

Glib::Type->register_enum ('My::Test1', 'foo', 'bar-ski', 'quux',
                          100 .. 199);

my $combo = Gtk2::Ex::ComboBox::Enum->new (enum_type => 'My::Test1',
                                           active => 2);
$vbox->pack_start ($combo, 0, 0, 0);

# my $model = $combo->get_model;
# ### model: "$model"
# ### row 0 values: $model->get ($model->get_iter_first)

### width: $combo->size_request->width
$combo->signal_connect (nick_to_display => sub {
                          my ($combo, $nick) = @_;
                          return "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx $nick";
                        });
### width: $combo->size_request->width

$combo->signal_connect
  ('notify::active' => sub {
     print "$progname: combo active now @{[$combo->get('active')]}\n";
   });
$combo->signal_connect
  ('notify::active-nick' => sub {
     my $nick = $combo->get('active-nick');
     print "$progname: notify::active-nick, value now ",
       (defined $nick ? $nick : '[undef]'),"\n";
   });

{
  my $button = Gtk2::Button->new_with_label ('Set "foo"');
  $button->signal_connect (clicked => sub { $combo->set(active_nick => 'foo'); });
  $vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Set "nosuch"');
  $button->signal_connect (clicked => sub { $combo->set(active_nick => 'nosuch'); });
  $vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Set 999');
  $button->signal_connect (clicked => sub { $combo->set_active(999); });
  $vbox->pack_start ($button, 0, 0, 0);
}

$toplevel->show_all;
Gtk2->main;

exit 0;

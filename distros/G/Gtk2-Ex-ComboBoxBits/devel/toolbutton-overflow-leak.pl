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
use Glib 1.220;
use Gtk2 '-init';

use FindBin;
my $progname = $FindBin::Script;

# uncomment this to run the ### lines
use Smart::Comments;

{
  my $menuitem = Gtk2::ImageMenuItem->new_with_label ("hello");
  require Scalar::Util;
  Scalar::Util::weaken ($menuitem);
  ### weakened imagemenuitem: $menuitem
}

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new;
$vbox->show;
$toplevel->add ($vbox);

my $toolbar = Gtk2::Toolbar->new;
$toolbar->show;
$vbox->pack_start ($toolbar, 0,0,0);

my $toolitem = Gtk2::ToolButton->new(undef,'FJSDKLFJDSKLFJSDLK');
$toolitem->show;
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
  require Devel::Mallinfo;
  my $old_used = 0;
  Glib::Timeout->add (500, sub {
                        my $m = Devel::Mallinfo::mallinfo();
                        my $used = $m->{'hblkhd'} + $m->{'uordblks'} + $m->{'usmblks'};
                        if ($used > $old_used) {
                          print "memory: $used\n";
                          $old_used = $used;
                        }
                        return Glib::SOURCE_CONTINUE;
                      });
}

$toplevel->show;
Gtk2->main;
exit 0;


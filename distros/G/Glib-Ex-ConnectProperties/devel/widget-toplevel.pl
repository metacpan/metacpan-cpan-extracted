#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Glib-Ex-ConnectProperties.
#
# Glib-Ex-ConnectProperties is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Glib-Ex-ConnectProperties is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ConnectProperties.  If not, see <http://www.gnu.org/licenses/>.


use 5.008;
use strict;
use warnings;
use Glib::Ex::ConnectProperties;
use Gtk2 '-init';
use Gtk2;

use FindBin;
my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $label = Gtk2::Label->new ('hello');
$label->signal_connect (hierarchy_changed => sub {
                          print "label hierarchy-changed\n";
                          my $top = $label->get_toplevel;
                          my $flag = $top->toplevel;
                          print "   toplevel $top flag $flag\n";
                        });
{
  my $top = $label->get_toplevel;
  my $flag = $top->toplevel;
  print "label initial toplevel $top flag $flag\n";
}

my $vbox = Gtk2::VBox->new;
$vbox->add ($label);
{
  my $top = $label->get_toplevel;
  my $flag = $top->toplevel;
  print "label in vbox toplevel $top flag $flag\n";
}

my $socket = Gtk2::Socket->new;
$toplevel->add ($socket);

# my $plug = Gtk2::Plug->new ($socket->get_id);
my $plug = Gtk2::Plug->new (0);
$plug->signal_connect (hierarchy_changed => sub {
                         print "plug hierarchy-changed\n";
                         my $top = $plug->get_toplevel;
                         my $flag = $top->toplevel;
                         print "   toplevel $top flag $flag\n";
                       });
print "add to plug\n";
$plug->add ($vbox);

print "plug to socket\n";
$socket->add_id ($plug->get_id);

print "toplevel show_all\n";
$toplevel->show_all;
{
  my $top = $plug->get_toplevel;
  my $flag = $top->toplevel;
  print "plug toplevel $top flag $flag\n";
}
Gtk2->main;
exit 0;

#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetCursor.
#
# Gtk2-Ex-WidgetCursor is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-WidgetCursor is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetCursor.  If not, see <http://www.gnu.org/licenses/>.


# The Busy/Open now has the new window noticed, the same as the way
# Busy/Open/Rebusy had to be done in WidgetCursor version 1.
# 

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::WidgetCursor;

use FindBin;
my $progname = $FindBin::Script;

# hack to get Gtk2-Perl 1.181 to finish loading Gtk2::Widget
# Gtk2::Widget->find_property ('name');
#
# use Data::Dumper;
# Gtk2::Widget->signal_add_emission_hook
#   (realize => sub {
#      print Dumper (\@_);
#      my ($invocation_hint, $param_list) = @_;
#      my ($widget) = @$param_list;
#      if ($widget->isa ('Gtk2::Window')) {
#        print "$progname: realize $widget\n";
#        print "$progname: toplevels now ",
#          join(' ', Gtk2::Window->list_toplevels),"\n";
#      }
#      return 1; # stay connected
#    });

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->set_name ("my_toplevel_1");
$toplevel->signal_connect (destroy => sub {
                             print "$progname: quit\n";
                             Gtk2->main_quit;
                           });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

{
  my $button = Gtk2::Button->new_with_label ("Another Toplevel");
  $button->signal_connect (clicked => sub {
                             print "$progname: another toplevel\n";
                             my $toplevel = Gtk2::Window->new ('toplevel');
                             $toplevel->set_size_request (75, 75);
                             $toplevel->show_all;
                           });
  $vbox->pack_start ($button, 1,1,0);
}

{
  my $button = Gtk2::Button->new_with_label ("Busy and Open");
  $button->signal_connect (clicked => sub {
                             print "$progname: busy\n";
                             Gtk2::Ex::WidgetCursor->busy;
                             my $toplevel = Gtk2::Window->new ('toplevel');
                             $toplevel->set_size_request (100, 100);

                             print "$progname: show $toplevel\n";
                             $toplevel->show_all;
                             print "$progname: sleep\n";
                             sleep (2);

                             print "$progname: flush\n";
                             $toplevel->get_display->flush;
                             print "$progname: sleep\n";
                             sleep (2);
                           });
  $vbox->pack_start ($button, 1,1,0);
}

{
  my $button = Gtk2::Button->new_with_label ("Busy / Open / Re-Busy");
  $button->signal_connect (clicked => sub {
                             print "$progname: busy\n";
                             Gtk2::Ex::WidgetCursor->busy;
                             my $toplevel = Gtk2::Window->new ('toplevel');
                             $toplevel->set_size_request (100, 100);

                             print "$progname: show $toplevel\n";
                             $toplevel->show_all;

                             print "$progname: re-busy\n";
                             Gtk2::Ex::WidgetCursor->busy;
                             print "$progname: sleep now\n";
                             sleep (4);
                           });
  $vbox->pack_start ($button, 1,1,0);
}

$toplevel->show_all;
Gtk2->main;
exit 0;

#!/usr/bin/perl -w

# Copyright 2007, 2008, 2010 Kevin Ryde

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


use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::WidgetCursor;

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->set_name ("my_toplevel_1");
$toplevel->signal_connect (destroy => sub {
                             print "run.pl: quit\n";
                             Gtk2->main_quit;
                           });

my $hbox = Gtk2::HBox->new (0, 0);
$toplevel->add ($hbox);

my $vbox = Gtk2::VBox->new (0, 0);
$hbox->pack_start ($vbox, 1,1,1);

{
  my $enter = sub {
    my ($label, $event) = @_;
    print "enter $label $event\n";
    return 0; # propagate event
  };
  my $leave = sub {
    my ($label, $event) = @_;
    print "leave $label $event\n";
    return 0; # propagate event
  };
  my $real = sub {
    my ($widget) = @_;
    print "realize $widget ", $widget->flags, "\n";
  };
  {
    my $label = Gtk2::Label->new ("Zero");
    $vbox->pack_start ($label, 1,1,1);
    $label->signal_connect (enter_notify_event => $enter);
    $label->signal_connect (leave_notify_event => $leave);
    $label->signal_connect (realize => $real);
    #       $label->{'wcursor'} = Gtk2::Ex::WidgetCursor->new (widget => $label,
    #                                                          cursor => 'fleur',
    #                                                          active => 1);
    $label->set_flags ('can-focus');
  }
  {
    my $label = Gtk2::Label->new ("One");
    $vbox->pack_start ($label, 1,1,1);
    $label->signal_connect (enter_notify_event => $enter);
    $label->signal_connect (leave_notify_event => $leave);
    $label->signal_connect (realize => $real);
    #       $label->{'wcursor'} = Gtk2::Ex::WidgetCursor->new (widget => $label,
    #                                                          cursor => 'fleur',
    #                                                          active => 1);
  }
  {
    my $label = Gtk2::Button->new_with_label ("Two");
    $vbox->pack_start ($label, 1,1,1);
    $label->signal_connect (enter_notify_event => $enter);
    $label->signal_connect (leave_notify_event => $leave);
    $label->signal_connect (realize => $real);
    $label->{'wcursor'} = Gtk2::Ex::WidgetCursor->new (widget => $label,
                                                       cursor => 'boat',
                                                       active => 1);
  }
  {
    my $label = Gtk2::Button->new_with_label ("Three");
    $vbox->pack_start ($label, 1,1,1);
    $label->signal_connect (enter_notify_event => $enter);
    $label->signal_connect (leave_notify_event => $leave);
    $label->signal_connect (realize => $real);
    #       $label->{'wcursor'} = Gtk2::Ex::WidgetCursor->new (widget => $label,
    #                                                          cursor => 'hand1',
    #                                                          active => 1);
  }
  {
    my $label = Gtk2::Button->new_with_label ("Four");
    $label->set_sensitive (1);
    $vbox->pack_start ($label, 1,1,1);
    $label->signal_connect (enter_notify_event => $enter);
    $label->signal_connect (leave_notify_event => $leave);
    $label->signal_connect (realize => $real);
    #       $label->{'wcursor'} = Gtk2::Ex::WidgetCursor->new (widget => $label,
    #                                                          cursor => 'hand1',
    #                                                          active => 1);

    $label->realize;
    my $win = $label->window;
    print "win ", $win,"\n";
    my @children = $win->get_children;
    print "subwins ", @children,"\n";
    my $event_win = $children[0];
    $event_win->set_cursor (Gtk2::Gdk::Cursor->new('xterm'));
  }
}

$toplevel->show_all;
$toplevel->realize;

sub tree {
  my ($win, $depth) = @_;
  printf "%*s%s\n", $depth, '', $win;
  my @children = $win->get_children;
  print "children ", @children, "\n";
  foreach my $subwin (@children) {
    
    tree ($subwin, $depth+1);
  }
}
print "top "; tree ($toplevel->window, 0);

Gtk2->main;
exit 0;

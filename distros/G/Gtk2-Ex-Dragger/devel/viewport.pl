#!/usr/bin/perl -w

# Copyright 2008, 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-Dragger.
#
# Gtk2-Ex-Dragger is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Dragger is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Dragger.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use List::Util qw(min max);
use Glib 1.220;
use Gtk2 '-init';
use Gtk2::Ex::Dragger;
use Data::Dumper;

use FindBin;
my $progname = $FindBin::Script;

# uncomment this to run the ### lines
use Smart::Comments;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->set_border_width (10);
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $viewport = Gtk2::Viewport->new;
$viewport->set_size_request (100,100);
$toplevel->add ($viewport);

my $label = Gtk2::Label->new (<<'HERE');
this is some text which can be scrolled around
blah
blah
blah
blah a b c a b c a b c a b c a b c a b c a b c a b c
blah
blah
blah
blah
blah
blah
blah d e f d e f d e f d e f d e f d e f d e f d e f d e f
blah
blah
blah
blah
blah ghi ghi ghi ghi ghi ghi ghi ghi ghi ghi ghi ghi ghi ghi
blah
blah
blah
blah
a final line
HERE
$label->set_size_request (400,400);
$label->set (xalign => 0, yalign => 0);
$viewport->add ($label);

my $hadj = $viewport->get_hadjustment;
my $vadj = $viewport->get_vadjustment;
print "$progname: vadj value=",$vadj->value,
  " page=",$vadj->page_size,
  " in ",$vadj->lower," to ",$vadj->upper,"\n";

# *Gtk2::Viewport::Gtk2_Ex_Dragger_window
#   = \&Gtk2::Viewport::bin_window;

my $confine = 1;
my $hinverted = 0;
my $vinverted = 0;
my $update_policy = 'default';
my $dragger = Gtk2::Ex::Dragger->new (widget        => $viewport,
                                      hadjustment   => $hadj,
                                      vadjustment   => $vadj,
                                      hinverted     => $hinverted,
                                      vinverted     => $vinverted,
                                      update_policy => $update_policy,
                                      confine       => $confine,
                                      cursor        => 'fleur');
print "$progname: ",($confine?"confined ":"unconfined "),
  ($hinverted?"hinv ":"hnorm "),
  ($vinverted?"vinv":"vnorm"),
  "policy $update_policy\n";

$viewport->add_events ('button-press-mask');
$viewport->signal_connect (button_press_event =>
                           sub {
                             my ($widget, $event) = @_;
                             print "$progname: start button $widget\n";
                             print "$progname: hadj value=",$hadj->value,
                               " page=",$hadj->page_size,
                                 " in ",$hadj->lower," to ",$hadj->upper,"\n";
                             # print "$progname: bin_window size ",
                             #   join(',',$viewport->bin_window->get_size),"\n";
                             $dragger->start ($event);
                             return 0; # propagate
                           });

$toplevel->show_all;

Glib::Timeout->add (1000,
                    sub {
                      ### bin_win: ''.$viewport->get_bin_window
                      my $win = $viewport->window;
                      ### win: ''.$win
                      ### win size: $win->get_size
                      my @children = $win->get_children;
                      ### @children
                      foreach (@children) {
                        ### child win: "$_"
                        ### child size: $_->get_size

                        my @children = $_->get_children;
                        foreach (@children) {
                          ### grandchild win: "$_"
                          ### grandchild size: $_->get_size
                        }
                      }
                      return Glib::SOURCE_REMOVE;
                    });

Gtk2->main;
exit 0;

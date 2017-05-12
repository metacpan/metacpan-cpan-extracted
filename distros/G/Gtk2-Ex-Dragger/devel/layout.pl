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
use Gtk2 '-init';
use Gtk2::Ex::Dragger;
use Data::Dumper;

use FindBin;
my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $layout = Gtk2::Layout->new;
$toplevel->add ($layout);
$layout->set_size (500, 500);

$layout->put (Gtk2::Label->new ('foo'), 10, 10);
$layout->put (Gtk2::Label->new ('bar'), 100, 100);
{ my $label = Gtk2::Label->new ('quux');
  my $req = $label->size_request;
  $layout->put ($label, 500 - $req->width, 500 - $req->height);
}

my $hadj = $layout->get_hadjustment;
my $vadj = $layout->get_vadjustment;
print "$progname: hadj value=",$hadj->value,
  " page=",$hadj->page_size,
  " in ",$hadj->lower," to ",$hadj->upper,"\n";

# *Gtk2::Layout::Gtk2_Ex_Dragger_window
#   = \&Gtk2::Layout::bin_window;

my $confine = 1;
my $hinverted = 0;
my $vinverted = 0;
my $update_policy = 0;
my $dragger = Gtk2::Ex::Dragger->new (widget        => $layout,
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

$layout->add_events ('button-press-mask');
$layout->signal_connect (button_press_event =>
                         sub {
                           my ($widget, $event) = @_;
                           print "$progname: start button $widget\n";
                           print "$progname: hadj value=",$hadj->value,
                             " page=",$hadj->page_size,
                               " in ",$hadj->lower," to ",$hadj->upper,"\n";
                           print "$progname: bin_window size ",
                             join(',',$layout->bin_window->get_size),"\n";
                           $dragger->start ($event);
                           return 0; # propagate
                         });

$toplevel->show_all;
Gtk2->main;
exit 0;

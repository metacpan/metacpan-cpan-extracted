#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-QuadButton.
#
# Gtk2-Ex-QuadButton is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-QuadButton is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-QuadButton.  If not, see <http://www.gnu.org/licenses/>.


use 5.008;
use strict;
use warnings;
use Gtk2 '-init';
use Glib::Ex::ConnectProperties;
use Gtk2::Ex::QuadButton::Scroll;

use FindBin;
my $progname = $FindBin::Script;

# uncomment this to run the ### lines
use Smart::Comments;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $vadj = Gtk2::Adjustment->new (0,  # initial
                                  -100,  # min
                                  100,  # max
                                  1,10,    # step,page increment
                                  20);      # page_size
my $hadj = Gtk2::Adjustment->new (0,  # initial
                                  -100,  # min
                                  100,  # max
                                  1,10,    # step,page increment
                                  20);      # page_size

my $qb = Gtk2::Ex::QuadButton::Scroll->new
  (hadjustment => $hadj,
   vadjustment => $vadj,
   vinverted   => 1);
$qb->signal_connect_after (clicked => sub {
                             print "$progname: clicked @_\n";
                             print "  hadj ",$hadj->value,"\n";
                             print "  vadj ",$vadj->value,"\n";
                           });
$vbox->pack_start ($qb, 1,1,0);
$qb->set_size_request (200, 100);

{
  my $button = Gtk2::CheckButton->new_with_label ('Sensitive');
  Glib::Ex::ConnectProperties->new
      ([$qb, 'sensitive'],
       [$button, 'active']);
  $vbox->pack_start ($button, 0, 0, 0);
}
{
  require Glib::Ex::ConnectProperties;
  my $adj = Gtk2::Adjustment->new (.5,        # initial
                                   0,1,    # min,max
                                   0.01, 0.1,  # step,page increment
                                   0);       # page_size
  Glib::Ex::ConnectProperties->new ([$qb,'xalign'],
                                    [$adj,'value']);
  my $spin = Gtk2::SpinButton->new ($adj, 10, 2);
  $vbox->pack_start ($spin, 0,0,0);
}
{
  require Glib::Ex::ConnectProperties;
  my $adj = Gtk2::Adjustment->new (.5,        # initial
                                   0,1,    # min,max
                                   0.01, 0.1,  # step,page increment
                                   0);       # page_size
  Glib::Ex::ConnectProperties->new ([$qb,'yalign'],
                                    [$adj,'value']);
  my $spin = Gtk2::SpinButton->new ($adj, 10, 2);
  $vbox->pack_start ($spin, 0,0,0);
}
{
  require Gtk2::Ex::ComboBox::Enum;
  my $combo = Gtk2::Ex::ComboBox::Enum->new
    (enum_type => 'Gtk2::TextDirection');
  Glib::Ex::ConnectProperties->new ([$qb,'widget#direction'],
                                    [$combo,'active-nick']);
  $vbox->pack_start ($combo, 1,1,0);
}

$toplevel->show_all;

print Gtk2::Gdk->screen_width_mm,",", Gtk2::Gdk->screen_height_mm,"\n";

# foreach my $arrow ($qb->get_children) {
#   my $req = $arrow->allocation;
#   ### arrow size: $req->width, $req->height
#   # $arrow->set_size_request (20,20);
# }

### normal: $qb->style->fg('normal')->to_string
### prelight: $qb->style->fg('prelight')->to_string
### active: $qb->style->fg('active')->to_string
### selected: $qb->style->fg('selected')->to_string
### insensitive: $qb->style->fg('insensitive')->to_string

### normal: $qb->style->bg('normal')->to_string
### prelight: $qb->style->bg('prelight')->to_string
### active: $qb->style->bg('active')->to_string
### selected: $qb->style->bg('selected')->to_string
### insensitive: $qb->style->bg('insensitive')->to_string

# ### inner-border: $qb->{'up'}->style_get_property('inner-border')
# ### default-border: $qb->{'up'}->style_get_property('default-border')
# ### image-spacing: $qb->{'up'}->style_get_property('image-spacing')
# ### focus-line-width: $qb->{'up'}->style_get_property('focus-line-width')

Gtk2->main;
exit 0;

#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

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

my $toolbar = Gtk2::Toolbar->new;
$vbox->pack_start ($toolbar, 1,1,0);

my $toolitem = Gtk2::ToolItem->new;
$toolbar->insert($toolitem, -1);

my $qb = Gtk2::Ex::QuadButton->new;
$qb->signal_connect_after (clicked => sub {
                             print "$progname: clicked @_\n";
                             if (my $hadj = $qb->{'hadjustment'}) {
                               print "  hadj ",$hadj->value,"\n";
                             }
                             if (my $vadj = $qb->{'vadjustment'}) {
                               print "  vadj ",$vadj->value,"\n";
                             }
                           });
$toolitem->add ($qb);

# require Glib::Ex::ConnectProperties;
# Glib::Ex::ConnectProperties->new ([$qb,'widget-allocation#height'],
#                                   [$qb,'width-request', write_only=>1]);


{
  my $toolitem = Gtk2::ToolItem->new;
  $toolbar->insert($toolitem, -1);
  my $button = Gtk2::Button->new;
  $toolitem->add ($button);
  my $arrow = Gtk2::Arrow->new('up','out');
  $button->add ($arrow);
}
# {
#   require Gtk2::Ex::ToolItem::CheckButton;
#   my $button = Gtk2::Ex::ToolItem::CheckButton->new;
#   # my $button = Gtk2::ToggleToolButton->new;
#   $button->set (label => 'Sensitive');
#   Glib::Ex::ConnectProperties->new
#       ([$qb, 'sensitive'],
#        [$button, 'active']);
#   $toolbar->insert($button, -1);
# }
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
  $vbox->pack_start ($combo, 0,0,0);
}

$toplevel->show_all;

print "screen mm: ",Gtk2::Gdk->screen_width_mm,",", Gtk2::Gdk->screen_height_mm,"\n";

{
  my $req = $toolbar->size_request;
  print "size-request ",$req->width," ",$req->height,"\n";
}
{
  my $req = $qb->size_request;
  print "qb size-request ",$req->width," ",$req->height,"\n";
  print "qb allocation-request ",$qb->allocation->width," ",$qb->allocation->height,"\n";
}


Gtk2->main;
exit 0;

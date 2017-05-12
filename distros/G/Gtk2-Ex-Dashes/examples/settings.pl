#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-Dashes.
#
# Gtk2-Ex-Dashes is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Dashes is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Dashes.  If not, see <http://www.gnu.org/licenses/>.


# This bit of nonsense makes some adjusters for the various settings in a
# Dashes so you can see how it draws with various values.
#
# The Gtk2::Frame widget around the dashes widget helps show where it ends,
# and in particular the way xpad and ypad make an inner border in the
# dashes.
#
# The initial xthickness/ythickness are established from the RC style stuff
# in the usual way according to whatever theme or setups you've got.  For
# example if you had in your ~/.gtkrc-2.0 file
#
#     style "my_rc_style" {
#       xthickness = 10
#       ythickness = 10
#     }
#     class "Gtk2__Ex__Dashes" style "my_rc_style"
#
# then it'd start 10 pixels wide (instead of the default style of 2
# usually).  But you probably wouldn't want that all the time.

use strict;
use warnings;
use Gtk2 '-init';

use Gtk2::Ex::Dashes;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->set_default_size (50, 300);
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $hbox = Gtk2::HBox->new;
$toplevel->add ($hbox);

my $vbox1 = Gtk2::VBox->new;
$hbox->pack_start ($vbox1, 0,0,5);

my $vbox2 = Gtk2::VBox->new;
$hbox->pack_start ($vbox2, 1,1,0);

my $frame = Gtk2::Frame->new;
$vbox2->pack_start ($frame, 1,1,0);

my $dashes = Gtk2::Ex::Dashes->new;
$frame->add ($dashes);

foreach my $elem (['xalign', 0, 1, 0.1 ],
                  ['yalign', 0, 1, 0.1 ],
                  ['xpad', 0, 99, 1 ],
                  ['ypad', 0, 99, 1 ],
                 ) {
  my ($propname, @spin_args) = @$elem;

  my $inner_hbox = Gtk2::HBox->new;
  $vbox1->pack_start ($inner_hbox, 0,0,0);

  my $label = Gtk2::Label->new ($propname);
  $inner_hbox->pack_start ($label, 0,0,0);

  my $spin = Gtk2::SpinButton->new_with_range (@spin_args);
  $inner_hbox->pack_start ($spin, 0,0,0);

  my $adj = $spin->get_adjustment;
  $adj->set (value => $dashes->get($propname));
  $adj->signal_connect (value_changed => \&adjustment_to_property,
                        $propname);
}
sub adjustment_to_property {
  my ($adj, $propname) = @_;
  $dashes->set ($propname, $adj->value);
}

my %style_adjustments;
foreach my $sname ('xthickness', 'ythickness') {
  my $inner_hbox = Gtk2::HBox->new;
  $vbox1->pack_start ($inner_hbox, 0,0,0);

  my $label = Gtk2::Label->new ($sname);
  $inner_hbox->pack_start ($label, 0,0,0);

  my $spin = Gtk2::SpinButton->new_with_range (1, 99, 1);
  $inner_hbox->pack_start ($spin, 0,0,0);

  my $adj = $style_adjustments{$sname} = $spin->get_adjustment;
  $adj->signal_connect (value_changed => sub {
                          my ($adj) = @_;
                          my $rcstyle = $dashes->get_modifier_style;
                          $rcstyle->$sname ($adj->value);
                          $dashes->modify_style ($rcstyle);
                        });
}


{
  my $button;  # radio grouping
  foreach my $orientation (sort     # a button for each enum value
                           map {$_->{'nick'}}
                           Glib::Type->list_values('Gtk2::Orientation')) {
    $button = Gtk2::RadioButton->new ($button, $orientation);
    $vbox1->pack_start ($button, 0,0,0);

    if ($dashes->get('orientation') eq $orientation) {
      $button->set_active (1);  # its initial value
    }
    $button->signal_connect ('notify::active',
                             sub {
                               my ($button, $pspec) = @_;
                               if ($button->get_active) {
                                 $dashes->set (orientation => $orientation);
                               }
                             });
  }
}


# dashes initially square according to the button vbox height
# (see Gtk2::Ex::Units set_default_size_with_subsizes() for a general
# approach to temporary set_size_request() like this)
#
$hbox->show_all;
my $req = $vbox1->size_request;
$frame->set_size_request ($req->height, $req->height);
$req = $toplevel->size_request;
$frame->set_size_request (-1, -1);
$toplevel->set_default_size ($req->width, $req->height);

# the style for a widget is only available after realized, or something like
# that, so wait until now to put initial values in the thickness adjusters
{
  $toplevel->realize;
  my $style = $dashes->get_style;
  $style_adjustments{'xthickness'}->set (value => $style->xthickness);
  $style_adjustments{'ythickness'}->set (value => $style->ythickness);
}

$toplevel->show;
Gtk2->main;
exit 0;

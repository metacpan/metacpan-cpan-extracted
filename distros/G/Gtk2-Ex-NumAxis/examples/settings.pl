#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-NumAxis.
#
# Gtk2-Ex-NumAxis is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-NumAxis is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-NumAxis.  If not, see <http://www.gnu.org/licenses/>.


# This bit of nonsense makes some controls for the various settings in a
# NumAxis and underlying Gtk2::Adjustment so you can see how it draws with
# various values.
#
# The Gtk2::Frame widget around the axis widget helps show where it ends.
#
# The font is established in the usual way from RC style stuff in your
# ~/.gtkrc-2.0 file etc.  In the font entry box press return to apply a new
# setting.  It can be anything understood by Pango::FontDescription.

use 5.008;
use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::NumAxis;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $hbox = Gtk2::HBox->new;
$toplevel->add ($hbox);

my $controls_vbox = Gtk2::VBox->new;
$hbox->pack_start ($controls_vbox, 0,0,5);

my $frame = Gtk2::Frame->new;
$hbox->pack_start ($frame, 1,1,0);

my $adj = Gtk2::Adjustment->new (100,    # value
                                 -10,    # lower
                                 500,    # upper
                                 1,      # step increment
                                 10,     # page increment
                                 20);    # page size
my $axis = Gtk2::Ex::NumAxis->new (adjustment => $adj);
$frame->add ($axis);

my $scrollbar = Gtk2::VScrollbar->new ($adj);
$hbox->pack_start ($scrollbar, 0,0,0);

#------------------------------------------------------------------------------
{
  my $label = Gtk2::Label->new('NumAxis widget');
  $label->set (xalign => 0);
  $controls_vbox->pack_start ($label, 0,0,0);
}

{
  my $button = Gtk2::CheckButton->new_with_label ('inverted');
  $controls_vbox->pack_start ($button, 0,0,0);
  $button->signal_connect ('notify::active',
                           sub {
                             my ($button, $pspec) = @_;
                             $axis->set (inverted => $button->get_active);
                             $scrollbar->set (inverted => $button->get_active);
                           });
}

{
  my $inner_hbox = Gtk2::HBox->new;
  $controls_vbox->pack_start ($inner_hbox, 0,0,0);

  my $label = Gtk2::Label->new ('min-decimals');
  $inner_hbox->pack_start ($label, 0,0,0);

  my $pspec = $axis->find_property ('min-decimals');
  my $spin = Gtk2::SpinButton->new_with_range ($pspec->get_minimum,
                                               $pspec->get_maximum,
                                               1);
  $inner_hbox->pack_start ($spin, 0,0,0);

  my $spin_adj = $spin->get_adjustment;
  $spin_adj->set (value => $axis->get('min-decimals'));
  $spin_adj->signal_connect (value_changed => sub {
                               my ($spin_adj) = @_;
                               $axis->set (min_decimals => $spin_adj->value);
                             });
}

my $font_entry;
{
  my $inner_hbox = Gtk2::HBox->new;
  $controls_vbox->pack_start ($inner_hbox, 0,0,0);

  my $label = Gtk2::Label->new ('Font');
  $inner_hbox->pack_start ($label, 0,0,0);

  $font_entry = Gtk2::Entry->new;
  $inner_hbox->pack_start ($font_entry, 0,0,0);

  $font_entry->signal_connect
    (activate => sub {
       my ($font_entry) = @_;
       my $rcstyle = $axis->get_modifier_style;
       my $str = $font_entry->get_text;
       my $font_desc = Gtk2::Pango::FontDescription->from_string ($str);
       $rcstyle->font_desc ($font_desc);
       $axis->modify_style ($rcstyle);
     });
}

$controls_vbox->pack_start (Gtk2::HSeparator->new, 0,0,0);
{
  my $label = Gtk2::Label->new('Adjustment object');
  $label->set (xalign => 0);
  $controls_vbox->pack_start ($label, 0,0,0);
}

foreach my $elem (['upper',     -10000, 10000, 0.1 ],
                  ['lower',     -10000, 10000, 0.1 ],
                  ['page-size', 0.01, 99, 1 ],
                 ) {
  my ($propname, @spin_args) = @$elem;

  my $inner_hbox = Gtk2::HBox->new;
  $controls_vbox->pack_start ($inner_hbox, 0,0,0);

  my $label = Gtk2::Label->new ($propname);
  $inner_hbox->pack_start ($label, 0,0,0);

  my $spin = Gtk2::SpinButton->new_with_range (@spin_args);
  $inner_hbox->pack_start ($spin, 0,0,0);

  my $spin_adj = $spin->get_adjustment;
  $spin_adj->set (value => $adj->get($propname));
  $spin_adj->signal_connect (value_changed => sub {
                               my ($spin_adj) = @_;
                               $adj->set ($propname, $spin_adj->value);
                             });
}

$hbox->show_all;
my $req = $toplevel->size_request;
$toplevel->set_default_size (-1, 2 * $req->height);

# the style for a widget is only available after realized, or something like
# that, so wait until now to set the $font_entry initial value
$toplevel->realize;
$font_entry->set_text ($axis->get_style->font_desc->to_string);

$toplevel->show;
Gtk2->main;
exit 0;

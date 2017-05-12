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


# This spot of code shows an axis of values formatted with the
# Locale::Currency::Format module.  The operative part is just the
# currency_format() call in the "number-to-text" signal handler.
#
# A real program would just choose a format a stick to it, the controls
# nonsense here lets you see have some variations come out.
#
# FMT_COMMON is probably the most suitable, showing just a "$" or similar
# rather than a "USD", but that might depend where else an application would
# be showing the currency, if it might vary.
#
# The axis_update() resize+redraw refreshes the display when changing the
# nature of the string format the "number-to-text" signal handler will do.
# Perhaps there should be a method for that.

use 5.008;
use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::NumAxis;
use Locale::Currency::Format;

my $format = FMT_STANDARD;
my $nozeros = 0;
my $currency = 'USD';

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $top_vbox = Gtk2::VBox->new;
$toplevel->add ($top_vbox);

my $heading = Gtk2::Label->new('Locale::Currency::Format');
$top_vbox->pack_start ($heading, 0,0,5);

my $hbox = Gtk2::HBox->new;
$top_vbox->pack_start ($hbox, 1,1,0);

my $controls_vbox = Gtk2::VBox->new;
$hbox->pack_start ($controls_vbox, 0,0,5);

my $frame = Gtk2::Frame->new;
$hbox->pack_start ($frame, 1,1,0);

my $adj = Gtk2::Adjustment->new (100,    # value
                                 -100,    # lower
                                 200,    # upper
                                 1,      # step increment
                                 4,      # page increment
                                 5);     # page size
my $axis = Gtk2::Ex::NumAxis->new (adjustment => $adj);
$frame->add ($axis);
$axis->signal_connect
  (number_to_text => sub {
     my ($axis, $value) = @_;
     return currency_format ($currency, $value, $format + $nozeros);
   });

sub axis_update {
  $axis->queue_resize;
  $axis->queue_draw;
}

my $scrollbar = Gtk2::VScrollbar->new ($adj);
$hbox->pack_start ($scrollbar, 0,0,0);

#------------------------------------------------------------------------------


{
  my @formats = (FMT_STANDARD,
                 FMT_COMMON,
                 FMT_SYMBOL,
                 FMT_NAME);

  my $combobox = Gtk2::ComboBox->new_text;
  $combobox->append_text ('FMT_STANDARD');
  $combobox->append_text ('FMT_COMMON');
  $combobox->append_text ('FMT_SYMBOL');
  $combobox->append_text ('FMT_NAME');
  $combobox->set_active (0);
  $controls_vbox->pack_start ($combobox, 0,0,0);
  $combobox->signal_connect (changed => sub {
                               my ($combobox) = @_;
                               $format = $formats[$combobox->get_active];
                               axis_update();
                             });
}

{
  my $button = Gtk2::CheckButton->new_with_label ('FMT_NOZEROS');
  $controls_vbox->pack_start ($button, 0,0,0);
  $button->signal_connect ('notify::active',
                           sub {
                             my ($button, $pspec) = @_;
                             $nozeros = ($button->get_active ? FMT_NOZEROS : 0);
                             axis_update();
                           });
}

{
  my $inner_hbox = Gtk2::HBox->new;
  $controls_vbox->pack_start ($inner_hbox, 0,0,0);

  my $label = Gtk2::Label->new ('Currency');
  $inner_hbox->pack_start ($label, 0,0,0);

  my $entry = Gtk2::Entry->new;
  $entry->set_width_chars (6);
  $entry->set_text ($currency);
  $inner_hbox->pack_start ($entry, 0,0,0);

  $entry->signal_connect
    (activate => sub {
       my ($entry) = @_;
       $currency = $entry->get_text;
       axis_update();
     });
}

$top_vbox->show_all;
my $req = $toplevel->size_request;
$toplevel->set_default_size (-1, 3 * $req->height);

$toplevel->show_all;
Gtk2->main;
exit 0;

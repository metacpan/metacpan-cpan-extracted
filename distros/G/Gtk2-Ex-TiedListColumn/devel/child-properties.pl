#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use Gtk2;

{
  my $hbox = Gtk2::HBox->new;
  my $vbox = Gtk2::VBox->new;

  my $label = Gtk2::Label->new('hello');
  $label->signal_connect (child_notify => sub {
                            my ($label, $pspec) = @_;
                            my $pname = $pspec->get_name;
                            say "notify: $pname";
                          });
  say "add to hbox";
  $hbox->add ($label);
  say "child_set_property";
  $hbox->child_set_property ($label, padding => 123);
  say $hbox->child_get_property ($label, 'padding');

  say "reparent to vbox";
  $label->reparent ($vbox);
  say $vbox->child_get_property ($label, 'padding');

  say "reparent to hbox";
  $label->reparent ($hbox);
  say $hbox->child_get_property ($label, 'padding');

  say "remove from hbox";
  $hbox->remove ($label);

  say "add to vbox";
  $vbox->add ($label);

  exit 0;
}
{
  my @pspecs = Glib::Object->list_properties;
  print scalar(@pspecs),"\n";

  while (1) {
    @pspecs = Glib::Object->list_properties;
  }
  exit 0;
}

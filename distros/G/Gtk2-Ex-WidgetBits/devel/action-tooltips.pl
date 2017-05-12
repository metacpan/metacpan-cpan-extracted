#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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

use strict;
use warnings;
use Gtk2;

{
  print Gtk2::Widget->find_property('tooltip-text'),"\n";
  print Gtk2::Widget->can('set_tooltip_text');
  exit 0;
}

my $label = Gtk2::Label->new;
my $action = Gtk2::Action->new (name => 'MyName');

#                                 label => '_Open',
#                                 tooltip => 'Open Something',
#                                 stock_id => 'gtk-open');
# my $action = Gtk2::Action->new ('myname', 'mylabel', undef, 'gtk-quit');
my $tip = $action->get('tooltip');
use Data::Dumper;
print Dumper(\$tip);


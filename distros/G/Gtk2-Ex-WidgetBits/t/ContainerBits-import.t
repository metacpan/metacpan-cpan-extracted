#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

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
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Gtk2;
use Test::More tests => 4;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Gtk2::Ex::ContainerBits qw(remove_all
                               remove_widgets);

{
  my $hbox = Gtk2::HBox->new;
  my $label = Gtk2::Label->new;

  $hbox->add ($label);
  is_deeply ([$hbox->get_children],[$label]);
  remove_widgets($hbox, $label);
  is_deeply ([$hbox->get_children],[]);

  $hbox->add ($label);
  remove_all($hbox);
  is_deeply ([$hbox->get_children],[]);

  remove_widgets($hbox);
  remove_all($hbox);
  is_deeply ([$hbox->get_children],[]);
}

exit 0;

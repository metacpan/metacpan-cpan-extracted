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


# Gtk2::Statusbar itself doesn't freeze/thaw

use strict;
use warnings;
use 5.008;
use Gtk2;
use Storable;
use Gtk2::Ex::Statusbar::DynamicContext;

# uncomment this to run the ### lines
use Smart::Comments;


{
  # grows unboundedly ...
  my $n = 0;
  for (;;) {
    my $statusbar = Gtk2::Statusbar->new;
    $statusbar->get_context_id ($n++);
    $statusbar->destroy;
  }
  exit 0;
}

{
  my $statusbar = Gtk2::Statusbar->new;
  ### $statusbar
  pop @{$statusbar->{some_thing}};
  ### $statusbar
  exit 0;
}
{
  my $statusbar = Gtk2::Statusbar->new;
  my $dc = Gtk2::Ex::Statusbar::DynamicContext->new($statusbar);
  ### $dc
  my $pst = Storable::freeze($dc);
  ### $pst

  my $dc2 = Storable::thaw($pst);
  ### $dc2

  exit 0;
}

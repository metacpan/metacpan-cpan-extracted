#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-NoShrink.
#
# Gtk2-Ex-NoShrink is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-NoShrink is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-NoShrink.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use lib 't';
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::NoShrink;

Gtk2->init_check
  or plan skip_all => 'due to no DISPLAY available';

plan tests => 8;

{
  # $noshrink->size_request calls only actually call the class method when
  # inside a parent container, or something, otherwise they spit back just
  # the widget->requisition -- hence $toplevel.
  #
  my $toplevel = Gtk2::Window->new ('toplevel');
  my $noshrink = Gtk2::Ex::NoShrink->new;
  $toplevel->add ($noshrink);
  $toplevel->show_all;

  my $req = $noshrink->size_request;
  is ($req->width,  0, 'width of empty');
  is ($req->height, 0, 'height of empty');

  $noshrink->set_border_width (5);
  $req = $noshrink->size_request;
  is ($req->width,  10, 'width with border');
  is ($req->height, 10, 'height with border');

  my $draw = Gtk2::DrawingArea->new;
  $noshrink->add ($draw);
  $draw->set_size_request (123, 456);
  $req = $noshrink->size_request;
  is ($req->width,  10, 'width with draw hidden');
  is ($req->height, 10, 'height with draw hidden');

  $draw->show;
  $req = $noshrink->size_request;
  is ($req->width,  133, 'width with draw');
  is ($req->height, 466, 'height with draw');

  $toplevel->destroy;
}

exit 0;

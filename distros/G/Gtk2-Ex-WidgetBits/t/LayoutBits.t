#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

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
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
#use Devel::Comments;

require Gtk2::Ex::LayoutBits;

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to Gtk2->init_check() unsuccessful';

plan tests => 13;

{
  my $want_version = 48;
  is ($Gtk2::Ex::LayoutBits::VERSION, $want_version,
      'VERSION variable');
  is (Gtk2::Ex::LayoutBits->VERSION,  $want_version,
      'VERSION class method');
  ok (eval { Gtk2::Ex::LayoutBits->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::LayoutBits->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# move_maybe()

{
  my $toplevel = Gtk2::Window->new;
  my $layout = Gtk2::Layout->new;
  $toplevel->add($layout);
  $toplevel->show_all;

  my $widget = Gtk2::Label->new;
  $widget->show;
  $layout->put ($widget, 10, 20);
  is ($layout->child_get_property($widget,'x'), 10);
  is ($layout->child_get_property($widget,'y'), 20);

  my $saw_size_request = 0;
  $layout->signal_connect (size_request => sub {
                             $saw_size_request++;
                           });
  $widget->signal_connect (size_request => sub {
                             $saw_size_request++;
                           });
  my $saw_child_notify = 0;
  $widget->signal_connect (child_notify => sub {
                             ### child_notify ...
                             $saw_child_notify++;
                           });

  Gtk2::Ex::LayoutBits::move_maybe ($layout, $widget, 10, 20);
  is ($layout->child_get_property($widget,'x'), 10);
  is ($layout->child_get_property($widget,'y'), 20);
  is ($saw_size_request, 0);
  is ($saw_child_notify, 0);

  Gtk2::Ex::LayoutBits::move_maybe ($layout, $widget, 15, 3);
  is ($layout->child_get_property($widget,'x'), 15);
  is ($layout->child_get_property($widget,'y'), 3);

  is ($saw_size_request, 0);
}

exit 0;

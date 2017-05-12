#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011 Kevin Ryde

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
use Test::More tests => 2;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

{
  package MyBucket;
  use Glib::Object::Subclass 'Gtk2::HBox';
  use Gtk2::Ex::ContainerBits 'remove_all';
}
my $bucket = MyBucket->new;
my $label = Gtk2::Label->new;
$bucket->add ($label);
is_deeply ([$bucket->get_children],[$label], 'MyBucket initial children');
$bucket->remove_all;
is_deeply ([$bucket->get_children],[], 'MyBucket remove_all() empties');
exit 0;


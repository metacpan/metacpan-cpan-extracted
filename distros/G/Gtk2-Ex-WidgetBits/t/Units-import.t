#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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
use Gtk2::Ex::Units ':all';
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2;
Gtk2->init_check
  or plan skip_all => 'due to Gtk2->init_check() unsuccessful';

plan tests => 12;

my $toplevel = Gtk2::Window->new ('toplevel');

cmp_ok (em($toplevel), '>', 0);
cmp_ok (ex($toplevel), '>', 0);
cmp_ok (char_width($toplevel), '>', 0);
cmp_ok (digit_width($toplevel), '>', 0);
cmp_ok (line_height($toplevel), '>', 0);
is (width($toplevel,'1 pixel'), 1);
is (height($toplevel,-1), -1);

my $req = size_request_with_subsizes($toplevel);
isa_ok ($req, 'Gtk2::Requisition');
isnt ($req->width, -1);
isnt ($req->height, -1);

set_default_size_with_subsizes($toplevel);
my ($width,$height) = $toplevel->get_default_size;
isnt ($width, -1);
isnt ($height, -1);

exit 0;

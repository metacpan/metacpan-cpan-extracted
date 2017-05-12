#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-Xor.
#
# Gtk2-Ex-Xor is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-Xor is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Xor.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2;
MyTestHelpers::glib_gtk_versions();

require Gtk2::Ex::CrossHair;
Gtk2::Builder->can('new')
  or plan skip_all => 'due to no Gtk2::Builder';

plan tests => 5;

#------------------------------------------------------------------------------
# buildable

my $builder = Gtk2::Builder->new;
$builder->add_from_string (<<'HERE');
<interface>
  <object class="GtkDrawingArea" id="draw1">
  </object>
  <object class="GtkDrawingArea" id="draw2">
  </object>
  <object class="Gtk2__Ex__CrossHair" id="cross">
    <property name="add-widget">draw1</property>
    <property name="add-widget">draw2</property>
  </object>
</interface>
HERE

my $cross = $builder->get_object('cross');
isa_ok ($cross, 'Gtk2::Ex::CrossHair', 'crosshair from buildable');

my $draw1 = $builder->get_object('draw1');
my $draw2 = $builder->get_object('draw2');
is_deeply ($cross->get('widgets'), [$draw1,$draw2],
           'add-widget widgets in crosshair');

# Something fishy seen in gtk 2.12.1 (with gtk2-perl 1.180, 1.183 or
# 1.200) that $builder stays non-undef when weakened, though the objects
# within it weaken away as expected.  Some of the ref counting changed in
# Gtk from what the very first gtkbuilder.c versions did, so think it's a
# gtk problem already fixed, so just ignore that test.
#
Scalar::Util::weaken ($builder);
Scalar::Util::weaken ($cross);
Scalar::Util::weaken ($draw1);
Scalar::Util::weaken ($draw2);
# is ($builder,  undef, 'builder weakened');
is ($cross, undef, 'cross from builder weakened');
is ($draw1,  undef, 'draw1 from builder weakened');
is ($draw2,  undef, 'draw2 from builder weakened');

exit 0;

#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-NumAxis.
#
# Gtk2-Ex-NumAxis is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-NumAxis is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-NumAxis.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::NumAxis;

require Gtk2;
MyTestHelpers::glib_gtk_versions();

Gtk2::Ex::NumAxis->isa('Gtk2::Buildable')
  or plan skip_all => 'due to no Gtk2::Buildable interface';

plan tests => 5;

#------------------------------------------------------------------------------
# buildable

my $builder = Gtk2::Builder->new;
$builder->add_from_string (<<'HERE');
<interface>
  <object class="GtkAdjustment" id="adj">
    <property name="lower">0</property>
    <property name="upper">100</property>
    <property name="page-size">12</property>
    <property name="page-increment">10</property>
    <property name="step-increment">1</property>
  </object>
  <object class="Gtk2__Ex__NumAxis" id="axis">
    <property name="height-request">200</property>
    <property name="adjustment">adj</property>
  </object>
</interface>
HERE

my $axis = $builder->get_object('axis');
isa_ok ($axis, 'Gtk2::Ex::NumAxis', 'axis from buildable');

my $adj = $builder->get_object('adj');
isa_ok ($adj, 'Gtk2::Adjustment', 'adjustment from buildable');

is ($axis->get('adjustment'), $adj, 'adjustment in axis');

# Something fishy seen in gtk 2.12.1 (with gtk2-perl 1.180, 1.183 or
# 1.200) that $builder stays non-undef when weakened, though the objects
# within it weaken away as expected.  Some of the ref counting changed in
# Gtk from what the very first gtkbuilder.c versions did, so think it's a
# gtk problem already fixed, so just ignore that test.
#
Scalar::Util::weaken ($builder);
Scalar::Util::weaken ($axis);
Scalar::Util::weaken ($adj);
# is ($builder,  undef, 'builder weakened');
is ($axis, undef, 'axis from builder weakened');
is ($adj,  undef, 'adjustement from builder weakened');

exit 0;

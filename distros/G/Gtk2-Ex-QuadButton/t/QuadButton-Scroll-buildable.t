#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-QuadButton.
#
# Gtk2-Ex-QuadButton is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-QuadButton is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-QuadButton.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::QuadButton::Scroll;

require Gtk2;
MyTestHelpers::glib_gtk_versions();

Gtk2::Ex::QuadButton->isa('Gtk2::Buildable')
  or plan skip_all => 'due to no Gtk2::Buildable interface';

plan tests => 8;

#------------------------------------------------------------------------------
# buildable

my $builder = Gtk2::Builder->new;
$builder->add_from_string (<<'HERE');
<interface>
  <object class="GtkAdjustment" id="hadj">
    <property name="lower">0</property>
    <property name="upper">100</property>
    <property name="page-size">12</property>
    <property name="page-increment">10</property>
    <property name="step-increment">1</property>
  </object>
  <object class="GtkAdjustment" id="vadj">
    <property name="lower">0</property>
    <property name="upper">100</property>
    <property name="page-size">12</property>
    <property name="page-increment">10</property>
    <property name="step-increment">1</property>
  </object>
  <object class="Gtk2__Ex__QuadButton__Scroll" id="qbs">
    <property name="hadjustment">hadj</property>
    <property name="vadjustment">vadj</property>
  </object>
</interface>
HERE

my $quadbutton = $builder->get_object('qbs');
isa_ok ($quadbutton, 'Gtk2::Ex::QuadButton::Scroll', 'qbs from buildable');

my $hadj = $builder->get_object('hadj');
isa_ok ($hadj, 'Gtk2::Adjustment', 'hadj from buildable');

my $vadj = $builder->get_object('vadj');
isa_ok ($vadj, 'Gtk2::Adjustment', 'vadj from buildable');

is ($quadbutton->get('hadjustment'), $hadj, 'hadjustment in quadbutton');
is ($quadbutton->get('vadjustment'), $vadj, 'vadjustment in quadbutton');

# Something fishy seen in gtk 2.12.1 (with gtk2-perl 1.180, 1.183 or
# 1.200) that $builder stays non-undef when weakened, though the objects
# within it weaken away as expected.  Some of the ref counting changed in
# Gtk from what the very first gtkbuilder.c versions did, so think it's a
# gtk problem already fixed, so just ignore that test.
#
Scalar::Util::weaken ($builder);
Scalar::Util::weaken ($quadbutton);
Scalar::Util::weaken ($hadj);
Scalar::Util::weaken ($vadj);
# is ($builder,  undef, 'builder weakened');
is ($quadbutton, undef, 'quadbutton from builder weakened');
is ($hadj,  undef, 'adjustement from builder weakened');
is ($vadj,  undef, 'adjustement from builder weakened');

exit 0;

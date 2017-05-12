#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-ListModelConcat.
#
# Gtk2-Ex-ListModelConcat is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ListModelConcat is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ListModelConcat.  If not, see <http://www.gnu.org/licenses/>.


# Usage: ./builder.pl
#
# This is an example of making a ListModelConcat in a GUI with Gtk2::Builder
# (which is new in Gtk 2.12).  The class name is
# "Gtk2__Ex__ListModelConcat", as usual for Gtk2-Perl package name to Gtk
# type name conversion.  There's nothing builder-specific in
# ListModelConcat, it's all inherited from the usual builder widget
# handling.
#
# The builder can create the underlying GtkAdjustment object too, though
# note that the <property> setting of the initial "value" gets clamped to
# the upper/lower range and so generally the value should be set after upper
# and lower.

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::ListModelConcat;

my $builder = Gtk2::Builder->new;
$builder->add_from_string (<<'HERE');
<interface>
  <object class="GtkListStore" id="list1">
    <columns>
      <column type="gint"/>
    </columns>
    <data>
      <row>
        <col id="0">123</col>
      </row>
      <row>
        <col id="0">456</col>
      </row>
    </data>
  </object>

  <object class="GtkListStore" id="list2">
    <columns>
      <column type="gint"/>
    </columns>
    <data>
      <row>
        <col id="0">789</col>
      </row>
    </data>
  </object>

  <object class="Gtk2__Ex__ListModelConcat" id="lmc">
    <property name="append-model">list1</property>
    <property name="append-model">list2</property>

    <child>
      <object class="GtkLabel" id="list3">
      </object>
    </child>

  </object>

</interface>
HERE

#     <child>
#       <object class="GtkListStore" id="list3">
#         <columns>
#           <column type="gint"/>
#         </columns>
#         <data>
#           <row>
#             <col id="0">999</col>
#           </row>
#           <row>
#             <col id="0">111</col>
#           </row>
#         </data>
#       </object>
#     </child>

print "LMC object contents:\n";
my $lmc = $builder->get_object('lmc');
for (my $iter = $lmc->get_iter_first; $iter; $iter = $lmc->iter_next($iter)) {
  print $lmc->get_value($iter,0), "\n";
}

exit 0;

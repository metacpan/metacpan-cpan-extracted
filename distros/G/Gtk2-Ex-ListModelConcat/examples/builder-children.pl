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


# Usage: ./builder-children.pl
#
# This is an example of making a ListModelConcat with Gtk2::Builder (new in
# Gtk 2.12), using <child> sub-objects.
#
# The class name is "Gtk2__Ex__ListModelConcat", as usual for Gtk2-Perl
# package name to Gtk type name conversion.  The bulk of the interface is
# the ListStore sub-model bits, the operative part for ListModelConcat is
# really just that such sub-models can be made as <child> elements.
#
# The sub-models created are not wedded to the ListModelConcat.  They can be
# referred to by their id for other parts of the builder, or from
# $builder->get_object('list1') etc.
#
# See builder-append.pl for another way to do it.

use strict;
use warnings;
use Gtk2;
use Gtk2::Ex::ListModelConcat;

my $builder = Gtk2::Builder->new;
$builder->add_from_string (<<'HERE');
<interface>

  <object class="Gtk2__Ex__ListModelConcat" id="lmc">

    <child>
      <object class="GtkListStore" id="list1">
        <columns>
          <column type="gint"/>
        </columns>
        <data>
          <row><col id="0">111</col></row>
          <row><col id="0">222</col></row>
        </data>
      </object>
    </child>

    <child>
      <object class="GtkListStore" id="list2">
        <columns>
          <column type="gint"/>
        </columns>
        <data>
          <row><col id="0">333</col></row>
          <row><col id="0">444</col></row>
        </data>
      </object>
    </child>

  </object>
</interface>
HERE

# get it out of the builder by name
my $lmc = $builder->get_object('lmc');

print "LMC object contents:\n";
for (my $iter = $lmc->get_iter_first;
     $iter;
     $iter = $lmc->iter_next($iter)) {
  print $lmc->get_value($iter,0), "\n";
}

exit 0;

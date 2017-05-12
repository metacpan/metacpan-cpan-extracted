#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-ComboBoxBits.
#
# Gtk2-Ex-ComboBoxBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-ComboBoxBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ComboBoxBits.  If not, see <http://www.gnu.org/licenses/>.


# Usage: perl tool-enum-builder.pl
#
# This is an example of making a ToolItem::ComboEnum using Gtk2::Builder
# (which is new in Gtk 2.12).
#
# The class name is "Gtk2__Ex__ToolItem__ComboEnum", as usual for Gtk2-Perl
# package name to Gtk type name in the builder.
#
# The enum-type and initial active-nick are set on the toolitem in the usual
# way.  Don't forget to set the enum-type first, since an active-nick can
# only be set once there's an enum of values for it.
#
# The <child internal-child="combobox"> provides access to the child
# combobox from the builder spec.  "internal-child" means it's not a new
# child object created, but a reference to a pre-built one, and the "id" is
# the name to use to refer to it in the builder spec.  (The syntax is rather
# unfortunately similar to a new child widget creation, but that's the way
# Gtk2::Builder works.)
#
# The combobox is referred to so as to set a couple of properties: the
# add-tearoffs option and a tooltip.  A tooltip can also be put on the
# toolitem itself, and in fact that may be the better place for it.
#

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::ToolItem::ComboEnum;

# uncomment this to run the ### lines
#use Smart::Comments;

use FindBin;
my $progname = $FindBin::Script;

my $builder = Gtk2::Builder->new;
$builder->add_from_string (<<"HERE");
<interface>
 <object class="GtkWindow" id="toplevel">
  <property name="type">toplevel</property>
  <signal name="destroy" handler="do_quit"/>

  <child>
   <object class="GtkToolbar" id="toolbar">

    <child>
     <object class="Gtk2__Ex__ToolItem__ComboEnum" id="toolitem">
      <property name="enum-type">GtkArrowType</property>
      <property name="active-nick">left</property>
      <property name="overflow-mnemonic">_Direction</property>

      <child internal-child="combobox">
       <object class="Gtk2__Ex__ComboBox__Enum" id="the_tool_combobox">
        <property name="add-tearoffs">true</property>
        <property name="tooltip-text">Tooltip for the ComboBox</property>
       </object>
      </child>

     </object>
    </child>

   </object>
  </child>

 </object>
</interface>
HERE

sub do_quit { Gtk2->main_quit; }
$builder->connect_signals;

my $toolitem = $builder->get_object('toolitem');
$toolitem->signal_connect
  ('notify::active-nick' => sub {
     my ($toolitem) = @_;
     my $nick = $toolitem->get('active-nick');
     print "$progname: active-nick is now \"",
       (defined $nick ? $nick : '[undef]'),
         "\"\n";
   });

my $toplevel = $builder->get_object('toplevel');
$toplevel->show_all;

Gtk2->main;
exit 0;

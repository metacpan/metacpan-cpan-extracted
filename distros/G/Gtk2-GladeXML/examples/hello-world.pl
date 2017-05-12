#!/usr/bin/perl -w

#----------------------------------------------------------------------
# hello-world.pl 
#
# A simple exapmle of Gtk2/GladeXML
#
# Copyright (C) 2003 Bruce Alderson
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
# 
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
#  
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; if not, write to the
#  Free Software Foundation, Inc., 59 Temple Place - Suite 330,
#  Boston, MA 02111-1307, USA.
#
#----------------------------------------------------------------------

use strict;
use warnings;

use Gtk2 '-init'; # auto-initializes Gtk2
use Gtk2::GladeXML;

my $glade;
my $window;
my $fortune;

# Some text to display in the label (notice the embedded pango-markup)
my @fortunes = (
    "This is an example\n<b>Gtk2::GladeXML</b> program.",
    "<i>Data-driven is good!</i>",
    "<span foreground=\"blue\">Blue text</span> is <i>fun</i>!",
    "<tt>Label-controls</tt> <i>can</i> <s>handle</s> simple<sub>1</sub> <u>markup</u><sup>2</sup>.",
    "GladeXML is as simple as:\n\n<tt>\$glade = \nGtk2::GladeXML->new(\n\"hello-world.glade\");</tt>",
    "<span size=\"70000\" style=\"oblique\">42</span>",
    "<big>A <b>Glade-XML</b>\nsample program</big>\n<small>by mx\@warpedvisions.org</small>"
    );
my $pos = -1;

# This example includes the Glade XML at the end of the script
# in the __DATA__ section.

# 'Load' glade-xml from DATA section
my $glade_data; {local $/ = undef; $glade_data = <DATA>;}

# Load the UI from xml definition
$glade = Gtk2::GladeXML->new_from_buffer($glade_data);

# Connect the signals
$glade->signal_autoconnect_from_package('main');

# Cache some controls in perl-variables
$window = $glade->get_widget('main');
$fortune = $glade->get_widget('fortune_label') or die;

# Start it up
Gtk2->main;

exit 0;

#----------------------------------------------------------------------
# Signal handlers, connected to signals we defined using glade-2

# Handle next-button click: show next message
sub on_next_button_clicked {
    $pos++; $pos %= $#fortunes + 1;   
    $fortune->set_markup($fortunes[$pos]); 
}

# Handle previous-button click: show prev message
sub on_back_button_clicked {
    $pos--; $pos %= $#fortunes + 1;   
    $fortune->set_markup($fortunes[$pos]); 
}

# Handles window-manager-quit: shuts down gtk2 lib
sub on_main_delete_event {Gtk2->main_quit;}

# Handles close-button quit
sub on_close_button_clicked {on_main_delete_event;}    


#----------------------------------------------------------------------
# We can append the glade file here instead of loading from file
#----------------------------------------------------------------------

__DATA__
<?xml version="1.0" standalone="no"?> <!--*- mode: xml -*-->
<!DOCTYPE glade-interface SYSTEM "http://glade.gnome.org/glade-2.0.dtd">

<glade-interface>

<widget class="GtkWindow" id="main">
  <property name="visible">True</property>
  <property name="title" translatable="yes">Gtk2::GladeXML-Power</property>
  <property name="type">GTK_WINDOW_TOPLEVEL</property>
  <property name="window_position">GTK_WIN_POS_NONE</property>
  <property name="modal">False</property>
  <property name="resizable">True</property>
  <property name="destroy_with_parent">False</property>
  <signal name="delete_event" handler="on_main_delete_event" last_modification_time="Sun, 16 Nov 2003 21:27:18 GMT"/>
  <signal name="delete_event" handler="on_main_delete_event" last_modification_time="Sun, 16 Nov 2003 21:27:25 GMT"/>

  <child>
    <widget class="GtkVBox" id="main_vbox">
      <property name="visible">True</property>
      <property name="homogeneous">False</property>
      <property name="spacing">0</property>

      <child>
	<widget class="GtkLabel" id="fortune_label">
	  <property name="width_request">300</property>
	  <property name="height_request">225</property>
	  <property name="visible">True</property>
	  <property name="can_focus">True</property>
	  <property name="label" translatable="yes">&lt;big&gt;&lt;b&gt;Hello World!&lt;/b&gt;&lt;/big&gt;</property>
	  <property name="use_underline">True</property>
	  <property name="use_markup">True</property>
	  <property name="justify">GTK_JUSTIFY_CENTER</property>
	  <property name="wrap">True</property>
	  <property name="selectable">True</property>
	  <property name="xalign">0.5</property>
	  <property name="yalign">0.5</property>
	  <property name="xpad">0</property>
	  <property name="ypad">0</property>
	</widget>
	<packing>
	  <property name="padding">0</property>
	  <property name="expand">True</property>
	  <property name="fill">True</property>
	</packing>
      </child>

      <child>
	<widget class="GtkHSeparator" id="hseparator">
	  <property name="visible">True</property>
	</widget>
	<packing>
	  <property name="padding">0</property>
	  <property name="expand">False</property>
	  <property name="fill">False</property>
	</packing>
      </child>

      <child>
	<widget class="GtkHButtonBox" id="main_hbuttonbox">
	  <property name="visible">True</property>
	  <property name="layout_style">GTK_BUTTONBOX_DEFAULT_STYLE</property>
	  <property name="spacing">0</property>

	  <child>
	    <widget class="GtkButton" id="back_button">
	      <property name="visible">True</property>
	      <property name="can_default">True</property>
	      <property name="can_focus">True</property>
	      <property name="label">gtk-go-back</property>
	      <property name="use_stock">True</property>
	      <property name="relief">GTK_RELIEF_NORMAL</property>
	      <signal name="clicked" handler="on_back_button_clicked" last_modification_time="Sun, 16 Nov 2003 21:23:34 GMT"/>
	    </widget>
	  </child>

	  <child>
	    <widget class="GtkButton" id="close_button">
	      <property name="visible">True</property>
	      <property name="can_default">True</property>
	      <property name="can_focus">True</property>
	      <property name="label">gtk-close</property>
	      <property name="use_stock">True</property>
	      <property name="relief">GTK_RELIEF_NORMAL</property>
	      <signal name="clicked" handler="on_close_button_clicked" last_modification_time="Sun, 16 Nov 2003 21:23:40 GMT"/>
	    </widget>
	  </child>

	  <child>
	    <widget class="GtkButton" id="next_button">
	      <property name="visible">True</property>
	      <property name="can_default">True</property>
	      <property name="can_focus">True</property>
	      <property name="label">gtk-go-forward</property>
	      <property name="use_stock">True</property>
	      <property name="relief">GTK_RELIEF_NORMAL</property>
	      <signal name="clicked" handler="on_next_button_clicked" last_modification_time="Sun, 16 Nov 2003 21:23:54 GMT"/>
	    </widget>
	  </child>
	</widget>
	<packing>
	  <property name="padding">0</property>
	  <property name="expand">False</property>
	  <property name="fill">True</property>
	</packing>
      </child>
    </widget>
  </child>
</widget>

</glade-interface>

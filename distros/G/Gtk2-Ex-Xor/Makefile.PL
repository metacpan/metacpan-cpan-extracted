#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2014, 2015, 2016 Kevin Ryde

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
use ExtUtils::MakeMaker;

WriteMakefile
  (NAME         => 'Gtk2::Ex::Xor',
   ABSTRACT     => 'Helpers for Gtk2 widgets.',
   VERSION_FROM => 'lib/Gtk2/Ex/Xor.pm',
   AUTHOR       => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   LICENSE      => 'gpl_3',
   SIGN         => 1,
   MIN_PERL_VERSION => '5.008',

   PREREQ_PM    => {
                    # version 1.200 for Gtk2::GC auto-release and various
                    'Gtk2' => '1.200',
                    'Glib::Object::Subclass' => 0,

                    # my Glib-Ex-ObjectBits
                    'Glib::Ex::SignalIds' => 0,

                    # my Gtk2-Ex-WidgetBits
                    'Gtk2::Ex::WidgetBits' => 31,
                    'Gtk2::Ex::KeySnooper' => 3,    # new in v.3
                    'Gtk2::Ex::SyncCall' => 12,     # v.12 for XID workaround
                    'Gtk2::Ex::WidgetEvents' => 21, # new in v.21
                    'Gtk2::Ex::GdkBits' => 38,  # v.38 draw_rectangle_corners()

                    # optional for Lasso but mandatory for CrossHair
                    # version 5 for weakening fixes
                    'Gtk2::Ex::WidgetCursor' => 5,

                    # 1.18 for pure-perl refaddr() fix
                    'Scalar::Util' => 1.18,

                    # maybe 0.05 for bug fixes
                    'Tie::RefHash::Weak' => '0.05',
                   },


   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/gtk2-ex-xor/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },

     # no index "package Gtk2::Bin" adding a private method
     no_index => { package => [ 'Gtk2::Bin' ],
                   directory=>['devel','xt','xtools'],
                 },

     optional_features =>
     {
      maximum_interoperation =>
      { description => 'Have maximum inter-operation with other modules (optional other stuff).',
        requires => { 'Locale::Messages' => 0 },
      },
     },
   },
  );

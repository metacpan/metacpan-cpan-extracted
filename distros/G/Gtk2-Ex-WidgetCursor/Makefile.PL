#!/usr/bin/perl

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetCursor.
#
# Gtk2-Ex-WidgetCursor is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-WidgetCursor is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetCursor.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use lib 'inc';
use MyMakeMakerExtras;

MyMakeMakerExtras::WriteMakefile
  (NAME         => 'Gtk2-Ex-WidgetCursor',
   ABSTRACT     => 'Mouse pointer cursor management for Gtk widgets.',
   VERSION_FROM => 'lib/Gtk2/Ex/WidgetCursor.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,
   MIN_PERL_VERSION => '5.008',

   PREREQ_PM    => {
                    # any version should be ok
                    'Gtk2' => 0,
                    'Glib::Object::Subclass' => 0,

                    # my ObjectBits
                    'Glib::Ex::SignalIds' => 1,

                    # 1.18 for pure-perl refaddr() fix
                    'Scalar::Util' => '1.18',
                   },

   META_MERGE
   => { resources
        => { homepage => 'http://user42.tuxfamily.org/gtk2-ex-widgetcursor/index.html' },
#         optional_features
#         => { maximum_tests
#              => { description => 'Have "make test" do as much as possible.',
#                   requires => { 
#                               },
#                 },
#            },
      },
  );

#!/usr/bin/perl

# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-Dragger.
#
# Gtk2-Ex-Dragger is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-Dragger is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Dragger.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use lib 'inc';
use MyMakeMakerExtras;

MyMakeMakerExtras::WriteMakefile
  (NAME         => 'Gtk2-Ex-Dragger',
   ABSTRACT     => 'Mouse drag to move widget contents.',
   VERSION_FROM => 'lib/Gtk2/Ex/Dragger.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,
   MIN_PERL_VERSION => '5.008',

   PREREQ_PM    => {
                    # version 1.220 for Glib::SOURCE_REMOVE and various
                    # bug fixes
                    'Glib' => '1.220',
                    'Glib::Object::Subclass' => 0,

                    # my Glib-Ex-ObjectBits
                    'Glib::Ex::SignalIds' => 0,

                    # version 1.220 for Gtk2::EVENT_PROPAGATE and various
                    # bug fixes
                    'Gtk2' => '1.220',

                    # my Gtk2-Ex-WidgetBits
                    'Gtk2::Ex::SyncCall' => 12, # v.12 workaround gtk 2.12 bug
                    'Gtk2::Ex::WidgetEvents' => 21, # new in version 21
                   },

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/gtk2-ex-dragger/index.html' },
     optional_features =>
     { cursor =>
       { description => 'Setting a different mouse cursor while dragging.',
         requires => { 'Gtk2::Ex::WidgetCursor' => 0 },
       },
       maximum_examples =>
       { description => 'Be able to run all the example programs.',
         requires => { 'Gtk2::Ex::WidgetCursor'  => 0,
                     },
       },
       maximum_interoperation =>
       { description => 'Have maximum inter-operation with other modules (optional other stuff).',
         requires => { 'Locale::Messages' => 0 },
       },
     },
   },
  );

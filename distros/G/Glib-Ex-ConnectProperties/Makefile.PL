#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011, 2012 Kevin Ryde

# This file is part of Glib-Ex-ConnectProperties.
#
# Glib-Ex-ConnectProperties is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Glib-Ex-ConnectProperties is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ConnectProperties.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use lib 'inc';
use MyMakeMakerExtras;

MyMakeMakerExtras::WriteMakefile
  (NAME         => 'Glib-Ex-ConnectProperties',
   ABSTRACT     => 'Link properties between objects.',
   VERSION_FROM => 'lib/Glib/Ex/ConnectProperties.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,

   PREREQ_PM    => {
                    # any version should be ok
                    'Glib' => 0,
                    'Glib::Object::Subclass' => 0,

                    'Module::Load' => 0,
                    'Glib::Ex::SignalIds' => 5, # version 5 for add()
                   },
   MIN_PERL_VERSION => 5.008,

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/glib-ex-connectproperties/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     no_index => { directory=>['devel'] },

     recommends =>
     { 'DateTime'           => 0,
       'DateTime::TimeZone' => 0,
     },
     optional_features =>
     { maximum_tests =>
       { description => 'Have "make test" do as much as possible.',
         requires => { 'Test::Weaken' => '2.002',
                       'Module::Util' => 0,
                       'Gtk2' => 0,
                     },
       },
       maximum_examples =>
       { description => 'Be able to run all the example programs.',
         requires => { 'Gtk2' => 0,
                     },
       },
     },
   },
  );

       # maximum_devel =>
       # { description => 'Stuff used variously for development.',
       #   requires => { 'Gtk2'        => 0,
       #                 'Gtk2::Pango' => 0,
       #                 'Glib::Object::Subclass' => 0,
       #                 'Tie::Hash::TwoWay' => 0,
       #                 'Goo::Canvas' => 0,
       #                 'Smart::Comments' => 0,
       #               },
       # },

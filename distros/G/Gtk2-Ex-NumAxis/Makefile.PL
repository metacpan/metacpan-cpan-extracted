#!/usr/bin/perl

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-NumAxis.
#
# Gtk2-Ex-NumAxis is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-NumAxis is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-NumAxis.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use lib 'inc';
use MyMakeMakerExtras;

MyMakeMakerExtras::WriteMakefile
  (NAME         => 'Gtk2-Ex-NumAxis',
   ABSTRACT     => 'Widget drawing a numbered axis.',
   VERSION_FROM => 'lib/Gtk2/Ex/NumAxis.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,
   MIN_PERL_VERSION => '5.008',

   PREREQ_PM    => {
                    # part of Glib, used explicitly so name it
                    'Glib::Object::Subclass' => 0,

                    'Gtk2' => '1.220',

                    # my Glib-Ex-ObjectBits
                    'Glib::Ex::SignalIds'  => 1,
                    'Glib::Ex::SignalBits' => 9, # new in v.9

                    # my Gtk2-Ex-WidgetBits
                    'Gtk2::Ex::AdjustmentBits' => 40, # new in v.40

                    'Math::Round' => 0,
                   },

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/gtk2-ex-numaxis/index.html' },
     optional_features =>
     {
      maximum_interoperation =>
      { description => 'Have maximum inter-operation with other modules (optional other stuff).',
        requires => { 'Locale::Messages' => 0 },
      },
      maximum_tests =>
      { description => 'Have "make test" do as much as possible.',
        requires => { 'Test::Weaken' => 3,
                      'Test::Weaken::Gtk2' => 0,
                    },
      },
     },
   },
  );

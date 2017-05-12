#!/usr/bin/perl

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-QuadButton.
#
# Gtk2-Ex-QuadButton is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-QuadButton is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-QuadButton.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use lib 'inc';
use MyMakeMakerExtras;

MyMakeMakerExtras::WriteMakefile
  (NAME         => 'Gtk2-Ex-QuadButton',
   ABSTRACT     => 'Widget for four arrow directions.',
   VERSION_FROM => 'lib/Gtk2/Ex/QuadButton.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,
   MIN_PERL_VERSION => '5.008',

   PREREQ_PM    => {
                    # part of Glib, used explicitly so name it
                    'Glib::Object::Subclass' => 0,

                    # my Gtk2-Ex-WidgetBits
                    'Gtk2::Ex::AdjustmentBits' => 40,   # new in v.40
                    'Gtk2::Ex::Units'      => 13,   # new in v.13
                    'Gtk2::Ex::WidgetBits' => 40,   # v.40 pixel_size_mm()

                    'Gtk2' => '1.220',
                   },

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/gtk2-ex-quadbutton/index.html' },
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
      maximum_devel =>
      { description => 'Stuff used variously for development.',
        requires => { 'Glib::Ex::ConnectProperties' => 0,
                      'Gtk2::Ex::ComboBox::Enum'      => 0,
                    },
      },
     },
   },
  );

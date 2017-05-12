#!/usr/bin/perl

# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-Dashes.
#
# Gtk2-Ex-Dashes is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Dashes is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Dashes.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use lib 'inc';
use MyMakeMakerExtras;

MyMakeMakerExtras::WriteMakefile
  (NAME         => 'Gtk2-Ex-Dashes',
   ABSTRACT     => 'Widget drawing a line of dashes.',
   VERSION_FROM => 'lib/Gtk2/Ex/Dashes.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,
   MIN_PERL_VERSION => '5.008',

   PREREQ_PM    => {
                    # part of Glib, used explicitly so name it
                    'Glib::Object::Subclass' => 0,

                    'Gtk2' => 0, # any version should be ok
                   },

   META_MERGE
   => { resources
        => { homepage => 'http://user42.tuxfamily.org/gtk2-ex-dashes/index.html' },
        optional_features
        => { maximum_tests
             => { description => 'Have "make test" do as much as possible.',
                  requires => { 'Test::Weaken' => 3,
                                'Test::Weaken::Gtk2' => 0,
                              },
                },
           },
      },
  );

#!/usr/bin/perl

# Copyright 2011 Kevin Ryde

# This file is part of Gtk2-Ex-Splash.
#
# Gtk2-Ex-Splash is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Splash is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Splash.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use lib 'inc';
use MyMakeMakerExtras;

MyMakeMakerExtras::WriteMakefile
  (NAME         => 'Gtk2-Ex-Splash',
   ABSTRACT     => 'Simple digital splash widget.',
   VERSION_FROM => 'lib/Gtk2/Ex/Splash.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,
   EXE_FILES    => [ 'gtk2-ex-splash' ],
   MIN_PERL_VERSION => '5.008',

   PREREQ_PM    => {
                    # Gtk2 version 1.220 for SOURCE_REMOVE
                    # (demanding a version just one constant is pretty
                    # gratuitous, but you'll almost certainly it for various
                    # bug fixes too)
                    'Glib' => '1.220',
                    'Gtk2' => 0,
                    'Glib::Object::Subclass' => 0,
                   },

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/gtk2-ex-splash/index.html',
     },
     optional_features =>
     { maximum_tests =>
       { description => 'Have "make test" do as much as possible.',
         requires => { 'Test::Weaken' => '2.000',
                     },
       },
       maximum_devel =>
       { description => 'Stuff used variously for development.',
         requires => { 'Devel::FindRef'              => 0,
                     },
       },
     },
   },

   MyMakeMakerExtras_Pod_Coverage =>
   [ 'Gtk2::Ex::Splash,also_private,[qr/^[A-Z_]+$$/]' ],
  );

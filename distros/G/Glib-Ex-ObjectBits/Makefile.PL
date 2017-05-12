#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2014 Kevin Ryde

# This file is part of Glib-Ex-ObjectBits.
#
# Glib-Ex-ObjectBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Glib-Ex-ObjectBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ObjectBits.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile
  (NAME         => 'Glib-Ex-ObjectBits',
   ABSTRACT     => 'Helpers for Glib objects.',
   VERSION_FROM => 'lib/Glib/Ex/SignalIds.pm',
   AUTHOR       => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   LICENSE      => 'gpl_3',
   SIGN         => 1,
   MIN_PERL_VERSION => '5.008',

   PREREQ_PM    => {
                    # any version should be ok
                    'Glib' => 0,
                    # used so name it explicitly
                    'Glib::Object::Subclass' => 0,

                    'Devel::GlobalDestruction' => 0,
                   },

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/glib-ex-objectbits/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     no_index => { directory=>['devel'] },

     optional_features =>
     { maximum_tests =>
       { description => 'Have "make test" do as much as possible.',
         requires => {
                      # 3.002 to traverse tied() obj
                      'Test::Weaken' => '3.002',
                     },
       },
     },
   },

   # MyMakeMakerExtras_Pod_Coverage =>
   # [ 'Glib::Ex::EnumBits',
   #   'Glib::Ex::FreezeNotify',
   #   'Glib::Ex::ObjectBits',
   #   'Glib::Ex::SignalIds',
   #   'Glib::Ex::SourceIds',
   #   'Glib::Ex::TieProperties',
   # 
   #   # Pod::Coverage 0.21 knows SCALAR()
   #   # ,also_private=>[qr/^SCALAR$$/]
   # ],
  );

#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012, 2014, 2015 Kevin Ryde

# This file is part of Gtk2-Ex-MenuView.
#
# Gtk2-Ex-MenuView is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-MenuView is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-MenuView.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile
  (NAME         => 'Gtk2::Ex::MenuView',
   ABSTRACT     => 'Menu of items from a TreeModel.',
   VERSION_FROM => 'lib/Gtk2/Ex/MenuView.pm',
   AUTHOR       => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   LICENSE      => 'gpl_3',
   SIGN         => 1,

   MIN_PERL_VERSION => '5.008',
   PREREQ_PM    => {
                    'Gtk2' => '1.200',
                    'Glib::Object::Subclass' => 0,

                    # my Glib-Ex-ObjectBits
                    'Glib::Ex::SignalIds' => 0,
                    'Glib::Ex::SourceIds' => 0,
                    'Glib::Ex::SignalBits' => 9, # new in v.9
                   },

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/gtk2-ex-menuview/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     no_index => { directory=>['devel','xt'] },

     prereqs =>
     { test =>
       { suggests =>
         { 'Test::Weaken' => '3',
           'Test::Weaken::Gtk2' => 0,
           'Devel::FindRef' => 0,
         },
       },
     },
     optional_features =>
     {
      maximum_interoperation =>
      { description => 'Have maximum inter-operation with other modules (optional other stuff).',
        requires => { 'Locale::Messages' => 0 },
      },
     },
   },

   # exclude capital INIT_INSTANCE etc
   MyMakeMakerExtras_Pod_Coverage =>
   [ 'Gtk2::Ex::MenuView,also_private=>[qr/^[A-Z_]+$$/]' ],
  );

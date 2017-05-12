#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2014, 2015, 2016 Kevin Ryde

# This file is part of Gtk2-Ex-ListModelConcat.
#
# Gtk2-Ex-ListModelConcat is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ListModelConcat is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ListModelConcat.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile
  (NAME         => 'Gtk2::Ex::ListModelConcat',
   ABSTRACT     => 'Concatenate list models in Gtk2-Perl.',
   VERSION_FROM => 'lib/Gtk2/Ex/ListModelConcat.pm',
   AUTHOR       => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   LICENSE      => 'gpl_3',
   SIGN         => 1,
   MIN_PERL_VERSION => '5.008',

   PREREQ_PM    => {
                    # Version 1.201 for stack fix in drag_data_get(), and at
                    # least 1.200 for it and $iter->set() to exist.
                    'Gtk2' => '1.201',

                    # part of Glib, used explicitly
                    'Glib::Object::Subclass' => 0,

                    # my Glib-Ex-ObjectBits
                    'Glib::Ex::SignalIds' => 0,

                    # my Gtk2-Ex-WidgetBits
                    'Gtk2::Ex::TreeModel::ImplBits' => 17,

                    # 1.18 for pure-perl refaddr() fix
                    'Scalar::Util' => 1.18,
                   },

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/gtk2-ex-listmodelconcat/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     no_index => { directory=>['devel','xt'] },

     prereqs =>
     { runtime =>
       { recommends =>
         { # recommend 1.2497 to avoid negative EXTEND() which Perl 5.24
           # doesn't like
          'Gtk2' => 1.2497,
         },
       },
       test =>
       { suggests =>
         { 'Test::Weaken' => 2,
           # my Gtk2-Ex-WidgetBits
           'Test::Weaken::Gtk2' => 0,
         },
       },
     },
   },
  );

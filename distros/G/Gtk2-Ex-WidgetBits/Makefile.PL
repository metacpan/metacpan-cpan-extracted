#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use lib 'inc';
use MyMakeMakerExtras;

MyMakeMakerExtras::WriteMakefile
  (NAME         => 'Gtk2-Ex-WidgetBits',
   ABSTRACT     => 'Helpers for Gtk2 widgets.',
   VERSION_FROM => 'lib/Gtk2/Ex/WidgetBits.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,
   MIN_PERL_VERSION => '5.008',

   PREREQ_PM    => {
                    'Glib' => 0,
                    # part of Glib, but used explicitly, so name it here
                    'Glib::Object::Subclass' => 0,

                    # 1.200 for TreeModelFilter::Change::remove() doing
                    # $iter->set(), and also 1.200 is a good idea for bug
                    # fixes
                    'Gtk2' => '1.200',
                    # part of Gtk2, but used explicitly
                    'Gtk2::Pango' => 0,

                    # my Glib-Ex-ObjectBits
                    'Glib::Ex::SignalIds' => 1,    # new in version 1
                    # FreezeNotify only used by TextBufferBits actually
                    'Glib::Ex::FreezeNotify' => 1,

                    'Scope::Guard' => 0,
                   },

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/gtk2-ex-widgetbits/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     no_index => { directory=>['devel'],
                 }
     #         optional_features
     #         => { maximum_tests
     #              => { description => 'Have "make test" do as much as possible.',
     #                   requires => {
     #                               },
     #                 },
     #            },
   },

   MY_NO_HTML => 1,
   MyMakeMakerExtras_Pod_Coverage =>
   [ 'Gtk2::Ex::ActionTooltips',
     'Gtk2::Ex::GdkBits',
     'Gtk2::Ex::EntryBits',
     'Gtk2::Ex::KeySnooper',
     'Gtk2::Ex::SyncCall',
     'Gtk2::Ex::MenuBits',
     'Gtk2::Ex::TextBufferBits',
     'Gtk2::Ex::TreeModelBits',
     'Gtk2::Ex::TreeModel::ImplBits',
     'Gtk2::Ex::TreeModelFilter::Change',
     'Gtk2::Ex::TreeViewBits',
     'Gtk2::Ex::WidgetBits',
     'Test::Weaken::Gtk2',
   ],
  );

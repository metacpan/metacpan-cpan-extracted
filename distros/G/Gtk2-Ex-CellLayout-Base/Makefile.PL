#!/usr/bin/perl

# Copyright 2007, 2008, 2009 Kevin Ryde

# This file is part of Gtk2-Ex-CellLayout-Base.
#
# Gtk2-Ex-CellLayout-Base is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-CellLayout-Base is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-CellLayout-Base.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use lib 'inc';
use MyMakeMakerExtras;

MyMakeMakerExtras::WriteMakefile
  (NAME         => 'Gtk2-Ex-CellLayout-Base',
   ABSTRACT     => 'Basic Gtk2::CellLayout interface implementation.',
   VERSION_FROM => 'lib/Gtk2/Ex/CellLayout/Base.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,
   MIN_PERL_VERSION => '5.008',

   PREREQ_PM    => {
                    'Glib::Object::Subclass' => 0,

                    # Gtk2-Perl 1.180 or higher for Gtk2::CellLayout as a
                    # GInterface from Perl.  Strictly speaking this is a
                    # prereq only of widgets which use CellLayout::Base, not
                    # of CellLayout::Base as such, but express it here to
                    # keep others out of trouble.  And the test suite
                    # depends on it, as currently written.
                    #
                    'Gtk2' => '1.180',

                    # my Glib-Ex-ObjectBits
                    'Glib::Ex::FreezeNotify' => 0,
                   },

   clean        => { FILES => "CellLayout-Base.html" },

   META_MERGE
   => { resources
        => { homepage
             => 'http://user42.tuxfamily.org/gtk2-ex-celllayout-base/index.html',
           },
        optional_features
        => { maximum_tests
             => { description => 'Have "make test" do as much as possible.',
                  requires => { 'Test::NoWarnings' => 0,
                              },
                },
           },
      },
  );

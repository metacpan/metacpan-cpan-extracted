#!/usr/bin/perl

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-TiedListColumn.
#
# Gtk2-Ex-TiedListColumn is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-TiedListColumn is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-TiedListColumn.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use lib 'inc';
use MyMakeMakerExtras;

MyMakeMakerExtras::WriteMakefile
  (NAME         => 'Gtk2-Ex-TiedListColumn',
   ABSTRACT     => 'Tie an array to a Gtk2-Perl TreeModel.',
   VERSION_FROM => 'lib/Gtk2/Ex/TiedListColumn.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,
   MIN_PERL_VERSION => '5.008',

   PREREQ_PM    => {
                    # think any version might be
                    'Gtk2' => 0,

                    # my WidgetBits
                    'Gtk2::Ex::ContainerBits' => 21, # new in v.21
                   },

   META_MERGE
   => { resources
        => { homepage
             => 'http://user42.tuxfamily.org/gtk2-ex-tiedlistcolumn/index.html',
           },
        optional_features
        => { maximum_tests
             => { description => 'Have "make test" do as much as possible.',
                  requires => {
                               # 3.002 preferred to traverse tied() obj
                               'Test::Weaken' => '3.002',
                              },
                },
             maximum_devel
             => { description => 'Stuff used variously for development.',
                  requires => {
                               # part of Gtk2 anyway ...
                               'Gtk2::Ex::Simple::TiedList' => 0,
                              },
                },
           },
      },
  );

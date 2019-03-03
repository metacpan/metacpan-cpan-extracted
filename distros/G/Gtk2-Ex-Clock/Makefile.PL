#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2014, 2015, 2019 Kevin Ryde

# This file is part of Gtk2-Ex-Clock.
#
# Gtk2-Ex-Clock is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Clock is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Clock.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %PREREQ_PM = (
                 # Gtk2 version 1.200 for GDK_PRIORITY_REDRAW
                 # (demanding a version just one constant is pretty
                 # gratuitous, but you'll almost certainly it for various
                 # bug fixes too)
                 'Gtk2' => '1.200',

                 'Glib::Object::Subclass' => 0,
                 'Glib::Ex::SourceIds' => 2,  # ObjectBits v.2

                 'List::Util' => 0,

                 # version 2 for netbsd 646 alias
                 'POSIX::Wide' => 2,

                 # actually this is only for the string timezone case,
                 # but it's small enough to grab always
                 'Tie::TZ' => 0,
                );
my %TEST_REQUIRES = (
                     'Test::More' => 0,
                    );
unless (eval { ExtUtils::MakeMaker->VERSION(6.64) }) {
  # past ExtUtils::MakeMaker without separate TEST_REQUIRES
  %PREREQ_PM = (%PREREQ_PM, %TEST_REQUIRES);
}

WriteMakefile
  (NAME          => 'Gtk2::Ex::Clock',
   ABSTRACT      => 'Simple digital clock widget.',
   VERSION_FROM  => 'lib/Gtk2/Ex/Clock.pm',
   AUTHOR        => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   LICENSE       => 'gpl_3',
   SIGN          => 1,
   PREREQ_PM     => \%PREREQ_PM,
   TEST_REQUIRES => \%TEST_REQUIRES,
   MIN_PERL_VERSION => '5.008',

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/gtk2-ex-clock/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     no_index => { directory=>['devel','xt'] },

     recommends =>
     { 'DateTime'           => 0,
       'DateTime::TimeZone' => 0,
     },
     prereqs =>
     { test =>
       { suggests =>
         { 'Test::Weaken' => '2.000',
         },
       },
     },

     optional_features =>
     { with_datetime =>
       { description => 'Have "make test" do as much as possible.',
         requires => { 'DateTime'           => 0,
                       'DateTime::TimeZone' => 0,
                     },
       },
       maximum_examples =>
       { description => 'Be able to run all the example programs.',
         prereqs =>
         { runtime =>
           { requires =>
             { 'DateTime'                => 0,
               'DateTime::TimeZone'      => 0,
               'DateTime::TimeZone::TAI' => 0,
               'DateTimeX::AATW'         => 0,
             },
           },
         },
       },
     },
   },
  );


# MyMakeMakerExtras_Pod_Coverage =>
# [ 'Gtk2::Ex::Clock,also_private,[qr/^[A-Z_]+$$/]' ],

# maximum_devel =>
# { description => 'Stuff used variously for development.',
#   requires => { 'Glib::Ex::ConnectProperties' => 0,
#                 'Glib::Ex::SignalIds'         => 0,
#                 'Devel::FindRef'              => 0,
#                 'DateTime'                    => 0,
#                 'DateTime::TimeZone'          => 0,
#                 'DateTime::TimeZone::TAI'     => 0,
#                 'Time::Mock'                  => 0,
#               },
# },

exit 0;

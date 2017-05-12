#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011, 2012 Kevin Ryde

# This file is part of Gtk2-Ex-DateSpinner.
#
# Gtk2-Ex-DateSpinner is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-DateSpinner is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-DateSpinner.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile
  (NAME         => 'Gtk2-Ex-DateSpinner',
   ABSTRACT     => 'Date entry widget using spin buttons.',
   VERSION_FROM => 'lib/Gtk2/Ex/DateSpinner.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,
   MIN_PERL_VERSION => '5.008',

   PREREQ_PM    => {
                    # 5.0 for new style Add_Delta_YMD() probably,
                    # otherwise at least 4.1 for bug fix in Add_Delta_YMD(),
                    # otherwise at least 4.0 for Today() func
                    'Date::Calc' => '5.0',

                    # part of Glib, used explicitly so name here
                    'Glib::Object::Subclass' => 0,

                    # my ObjectBits
                    'Glib::Ex::ObjectBits' => 12, # new in version 12
                    'Glib::Ex::SignalIds'  => 1,

                    # might work with almost any version ...
                    'Gtk2' => 0,

                    # my WidgetBits
                    'Gtk2::Ex::WidgetBits' => 0,

                    # 1.16 for turn_utf_8_on()
                    'Locale::Messages' => '1.16',
                   },
   clean        => { FILES => "DateSpinner.html" },

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/gtk2-ex-datespinner/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     no_index => { directory=>['devel'] },

     optional_features =>
     { maximum_tests =>
       { description => 'Have "make test" do as much as possible.',
         requires => { 'Test::Weaken' => 3,
                       'Test::Weaken::Gtk2' => 0,
                     },
       },
     },
   },
  );

# #------------------------------------------------------------------------------
# package MY;
# sub postamble {
#   my ($makemaker) = @_;
#   return MyMakeMakerExtras::postamble ($makemaker) . <<'HERE';
# 
# #----------------------------------------------------------------------------
# # extras from MY::postamble()
# 
# mydist:
# 	make dist COMPRESS='gzip --force --best'
# 	make check-copyright-years
# 	rm -rf mydist.tmp
# 	mkdir mydist.tmp
# 	(cd mydist.tmp; \
# 	 tar xfz ../$(DISTVNAME).tar.gz; \
# 	 cd $(DISTVNAME); \
# 	cpansign -v; \
# 	perl Makefile.PL SIGN=0; \
# 	make check-debug-constants; \
# 	)
# 	rm -rf mydist.tmp
# 
# HERE
# }

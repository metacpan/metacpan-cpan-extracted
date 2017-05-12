#!/usr/bin/perl

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-History.
#
# Gtk2-Ex-History is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-History is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-History.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

use lib 'inc';
use MyMakeMakerExtras;
use MyMakeMakerGettext;

MyMakeMakerExtras::WriteMakefile
  (NAME         => 'Gtk2-Ex-History',
   ABSTRACT     => 'History of current, back and forward places for user navigation.',
   VERSION_FROM => 'lib/Gtk2/Ex/History.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,
   MIN_PERL_VERSION => '5.008',

   PREREQ_PM    => {
                    # part of Glib, used explicitly so name it
                    'Glib::Object::Subclass' => 0,

                    'Gtk2' => '1.220',

                    # my Glib-Ex-ObjectBits
                    'Glib::Ex::ObjectBits'   => 12, # new in version 12
                    'Glib::Ex::SignalIds'    => 1,
                    'Glib::Ex::FreezeNotify' => 1,
                    'Glib::Ex::SignalBits'   => 9,  # new in version 9

                    # my Gtk2 Ex WidgetBits
                    'Gtk2::Ex::TreeModelBits' => 16, # for extra remove args
                    'Gtk2::Ex::Units'         => 13, # new in version 13
                    'Gtk2::Ex::WidgetEvents'  => 21, # new in version 21
                    'Test::Weaken::Gtk2'      => 17, # new in version 17

                    'Glib::Ex::ConnectProperties' => 13, # v.13 model-rows
                    'Gtk2::Ex::Dashes::MenuItem' => 0,
                    'Gtk2::Ex::MenuView' => 0,

                    # version 1.16 for bind_textdomain_filter() to mung
                    # gettext strings
                    'Locale::TextDomain' => 1.16,
                    # Locale::Messages doesn't declare a version, there's
                    # only one in Locale::TextDomain, until 1.18 or some such
                    'Locale::Messages'   => 0,
                   },

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/gtk2-ex-history/index.html' },
     optional_features =>
     { maximum_tests =>
       { description => 'Have "make test" do as much as possible.',
         requires => { 'Test::Weaken' => 3,
                     },
       },
       maximum_devel =>
       { description => 'Stuff used variously for development.',
         requires => { 'Smart::Comments'    => 0,
                       'lib::abs' => 0,
                       'Scalar::Lazy' => 0,
                     } },
     },
   },
  );

#------------------------------------------------------------------------------
package MY;
sub postamble {
  my ($makemaker) = @_;
  return MyMakeMakerExtras::postamble($makemaker)
    . MyMakeMakerGettext::postamble($makemaker)
      . <<'HERE';

# my-dist:
# 	unset PERL5LIB; export PERL5LIB; \
# 	  PATH=/bin:/usr/bin; export PATH; \
# 	  make my-dist-1 2>&1 | tee my-dist.log
my-dist:
	echo $(VERSION)
	make clean
	perl Makefile.PL
	make mo
	make test TEST_FILES=xt/*.t
	make dist COMPRESS='gzip --force --best'

my-test:
	: MY_TEST
	set -e -x;							      \
	make check-copyright-years;					      \
									      \
	tar xfz $(DISTVNAME).tar.gz;					      \
        cd $(DISTVNAME);						      \
	cpansign -v;							      \
	perl Makefile.PL SIGN=0;					      \
                                                                              \
	make check-spelling;						      \
	(cd t; perl -MTest::CheckChanges -e 'ok_changes()');		      \
	make check-fuzzy-po;						      \
									      \
	if [ -x /usr/bin/xvfb-run ]; then                                     \
	  echo 'Test with Xvfb';                                              \
	  unset DISPLAY; export DISPLAY;                                      \
          xvfb-run -a make test;                                              \
	fi;								      \
                                                                              \
	echo 'Test with DISPLAY';					      \
	DISPLAY=:0; export DISPLAY;                                           \
	make test;							      \
	DISPLAY=:0; export DISPLAY;                                           \
	HARNESS_PERL_SWITCHES="-MTest::Without::Gtk2Things=verbose,insert_with_values,widget_tooltip" make test; \
	HARNESS_PERL_SWITCHES="-MTest::Without::Module=Test::Weaken" make test;	\
                                                                              \
	echo 'Test without DISPLAY';                                          \
	unset DISPLAY; export DISPLAY;                                        \
	make test;                                                            \
	HARNESS_PERL_SWITCHES="-MTest::Without::Module=Test::Weaken" make test; \
	HARNESS_PERL_SWITCHES="-MTest::Without::Module=Test::Pod" make test;  \
                                                                              \
	make dist;                                                            \
	cd ..;                                                                \
	rm -rf $(DISTVNAME);
HERE
}

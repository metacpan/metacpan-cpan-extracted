#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011, 2012 Kevin Ryde

# This file is part of Gtk2-Ex-ErrorTextDialog.
#
# Gtk2-Ex-ErrorTextDialog is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ErrorTextDialog is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ErrorTextDialog.  If not, see <http://www.gnu.org/licenses/>.

use 5.008001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

use lib 'inc';
use MyMakeMakerExtras;
use MyMakeMakerGettext;

MyMakeMakerExtras::WriteMakefile
  (NAME         => 'Gtk2-Ex-ErrorTextDialog',
   ABSTRACT     => 'Dialog showing error messages in a TextView.',
   VERSION_FROM => 'lib/Gtk2/Ex/ErrorTextDialog.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,
   MIN_PERL_VERSION => '5.008001',

   PREREQ_PM    => {
                    'Devel::GlobalDestruction' => 0,

                    # not sure what version might actually be needed
                    'Glib' => 0,
                    'Glib::Object::Subclass' => 0,

                    # my ObjectBits
                    'Glib::Ex::ObjectBits' => 12, # new in version 12
                    'Glib::Ex::SignalIds'  => 0,  # in version 1

                    # not sure what version might actually be needed
                    'Gtk2' => 0,

                    # my WidgetBits, version 14 for char_width()
                    'Gtk2::Ex::Units' => 14,

                    # version 1.16 for bind_textdomain_filter() to mung
                    # gettext strings
                    'Locale::TextDomain' => 1.16,
                    # Locale::Messages doesn't declare a version, there's
                    # only one in Locale::TextDomain, until 1.18 or some such
                    'Locale::Messages'   => 0,
                   },
   clean     => { ## no critic (RequireInterpolationOfMetachars)
                 FILES => '$(POT_TEMP_FILE)', # if bad xgettext
                },

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/gtk2-ex-errortextdialog/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     no_index => { directory=>['devel'] },

     optional_features =>
     { maximum_tests =>
       { description => 'Have "make test" do as much as possible.',
         requires => { 'Test::Weaken' => 3,
                       'Devel::FindRef' => 0,
                     },
       },
     },
   },
  );

# maximum_devel =>
# { description => 'Stuff used variously for development.',
#   requires => { 'Devel::Loading' => 0,
#                 'lib::abs' => 0,
#                 'Scalar::Lazy' => 0,
#                 'X11::Protocol' => 0,
#                 # part of Gtk2, but name it since used directly
#                 'Gtk2::Pango' => 0,
#               },
# },

#------------------------------------------------------------------------------
package MY;
sub postamble {
  my ($makemaker) = @_;
  return (MyMakeMakerExtras::postamble($makemaker)
          . MyMakeMakerGettext::postamble($makemaker));
}

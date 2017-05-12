#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2013 Kevin Ryde

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


use 5.008;
use strict;
use warnings;
use Test::More tests => 7;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

## no critic (ProtectPrivateSubs)
require Gtk2::Ex::ErrorTextDialog::Handler;


#-----------------------------------------------------------------------------

my $want_version = 11;
is ($Gtk2::Ex::ErrorTextDialog::Handler::VERSION, $want_version,
    'VERSION variable');
is (Gtk2::Ex::ErrorTextDialog::Handler->VERSION, $want_version,
    'VERSION class method');
ok (eval { Gtk2::Ex::ErrorTextDialog::Handler->VERSION($want_version); 1 },
    "VERSION class check $want_version");
{ my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::ErrorTextDialog::Handler->VERSION($check_version); 1},
      "VERSION class check $check_version");
}

#-----------------------------------------------------------------------------
# _fh_prints_wide()

{
  require File::Spec;
  my $devnull = File::Spec->devnull();
  open my $out, '>:raw', $devnull or die "Cannot open $devnull for write";
  ok (! Gtk2::Ex::ErrorTextDialog::Handler::_fh_prints_wide($out),
      "_fh_prints_wide() devnull :raw no print wide");

 SKIP: {
    my $encoding = ':encoding(UTF-8)';
    binmode ($out, $encoding)
      or skip "Oops, can't push $encoding", 1;

    ok (Gtk2::Ex::ErrorTextDialog::Handler::_fh_prints_wide($out),
        "_fh_prints_wide() devnull with $encoding prints wide");
  }
}

#-----------------------------------------------------------------------------
# _locale_charset_or_ascii()

{
  my $c1 = Gtk2::Ex::ErrorTextDialog::Handler::_locale_charset_or_ascii();
  my $c2 = Gtk2::Ex::ErrorTextDialog::Handler::_locale_charset_or_ascii();
  is ($c1, $c2, '_locale_charset_or_ascii() same from two calls');
}

exit 0;

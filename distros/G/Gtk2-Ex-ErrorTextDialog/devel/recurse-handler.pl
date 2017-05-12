#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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
use Gtk2 '-init';
use Gtk2::Ex::ErrorTextDialog;
use Gtk2::Ex::ErrorTextDialog::Handler;

use FindBin;
use lib::abs $FindBin::Bin;
my $progname = $FindBin::Script;

{
  require Encode;
  require I18N::Langinfo;
  my $charset = I18N::Langinfo::langinfo (I18N::Langinfo::CODESET());
  { no warnings 'once';
    local $PerlIO::encoding::fallback = Encode::PERLQQ; # \x{1234} style
    (binmode (STDOUT, ":encoding($charset)") &&
     binmode (STDERR, ":encoding($charset)"))
      or die "Cannot set :encoding on stdout/stderr: $!\n";
  }
}

print "$progname: STDERR prints wide ",
  (Gtk2::Ex::ErrorTextDialog::Handler::_fh_prints_wide('STDERR')
   ? "yes" : "no"), "\n";


$SIG{'__WARN__'} = sub {
  print "$progname: warn handler runs\n";
  Gtk2::Ex::ErrorTextDialog::Handler::exception_handler(@_);
  print "$progname: warn handler ends\n";
};

my $bytes_to_wide
  = \&Gtk2::Ex::ErrorTextDialog::Handler::_maybe_locale_bytes_to_wide;
no warnings 'redefine';
*Gtk2::Ex::ErrorTextDialog::Handler::_maybe_locale_bytes_to_wide = sub {
  print "$progname: wrapped _maybe_locale_bytes_to_wide()\n";

  # die "$progname: inducing die in _maybe_locale_bytes_to_wide()";

  warn "$progname: inducing this warning";
  return "abc\n";
  # return &$bytes_to_wide(@_);
};

warn "look to your orb for the warning";

Gtk2->main;
exit 0;

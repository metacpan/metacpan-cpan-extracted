#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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


use strict;
use warnings;
use Data::Dumper;
use POSIX qw(setlocale LC_ALL LC_TIME);

{
  $ENV{'LANG'} = 'en_IN.UTF8';
  $ENV{'LANG'} = 'ar_IN';
  $ENV{'LANG'} = 'ja_JP';
  $ENV{'LANG'} = 'ja_JP.UTF8';
  setlocale(LC_ALL, '') or die;
}

sub POSIX_strftime {
  my $fmt = shift;
  require POSIX;
  require Encode;
  require I18N::Langinfo;
  my $charset = I18N::Langinfo::langinfo (I18N::Langinfo::CODESET());

  $fmt =~ s{(%[[:ascii:]]*)}{
    print "act on '$1'\n";
    Encode::decode ($charset, POSIX::strftime ($1, @_));
  }ge;
  return $fmt;
}

my $str = POSIX_strftime('%a %d %b %Y', localtime(0));
print "$str\n";
print Dumper($str);

exit 0;

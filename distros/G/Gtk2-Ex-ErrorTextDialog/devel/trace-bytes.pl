#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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

use FindBin;
my $progname = $FindBin::Script;

if (eval { require Devel::StackTrace }) {
  sub foo {
    print "$progname: ",length($_[0]),"\n";
    my $trace = Devel::StackTrace->new;
    my $str = $trace->as_string;
    print $str;
#     print "$progname: bytes ",
#       join(',',map{ord(substr($str,$_,1))} 0..length($str)-1),"\n";
    if ($str =~ /([^[:ascii:]])/) {
      print "non-ascii\n";
    } else {
      print "all ascii\n";
    }
  }
  foo ("abc \x{FF} def\n");
}

if (eval { require Devel::Backtrace }) {
  sub bar {
    print "$progname: ",length($_[0]),"\n";
    my $trace = Devel::Backtrace->new;
    my $str = $trace->to_string;
    print $str;
    #     print "$progname: bytes ",
    #       join(',',map{ord(substr($str,$_,1))} 0..length($str)-1),"\n";
    if ($str =~ /([^[:ascii:]])/) {
      print "non-ascii\n";
    } else {
      print "all ascii\n";
    }
  }
  bar ("\xFF\n");
}

exit 0;

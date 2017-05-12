#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2014 Kevin Ryde

# HTML-FormatExternal is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# HTML-FormatExternal is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with HTML-FormatExternal.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Module::Load;

foreach my $class ('HTML::FormatText::Elinks',
                   'HTML::FormatText::Html2text',
                   'HTML::FormatText::Lynx',
                   'HTML::FormatText::Links',
                   'HTML::FormatText::Netrik',
                   'HTML::FormatText::W3m',
                   'HTML::FormatText::Vilistextum',
                  ) {
  Module::Load::load($class);
  my $name = $class;
  $name =~ s/.*:://;

  my $html_string = '<html><body><p>&ouml;</p></body></html>';
  my $text = $class->format_string ($html_string);

  printf "%-12s ", $name;
  if (! defined $text) {
    print "undef\n";
    next;
  }
  $text =~ s/\n//g;
  $text =~ s/ //g;

  foreach my $i (0 .. length($text)-1) {
    print ord(substr($text,$i,1))," ";
  }
  if (length($text) == 0) {
    print "empty";
  }
  print "\n";
}

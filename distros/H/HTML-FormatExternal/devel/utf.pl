#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

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
use Data::Dumper;
use Encode;
use charnames ':full';
$Data::Dumper::Useqq=1;

foreach my $charset ('utf-16le','utf-16be','utf-32le','utf-32be') {
  foreach my $str ("\N{BYTE ORDER MARK}",
                   '<html><body><a href="page.html">Foo</a></body></html>',
                   'http://foo.org/page.html') {
    my $bytes = Encode::encode($charset, $str);
    print Dumper(\$bytes);
  }
  print "\n";
}
exit 0;

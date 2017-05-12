#!/usr/bin/perl -w

# Copyright 2008, 2010, 2013 Kevin Ryde

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
use HTML::FormatText::Lynx;

my $html = <<'HERE';
<html>
 <head>
  <title>A Page</title>
 </head>
 <body>
  <p> Hello <u>this</u> is some sample html input, with
      <a href="http://localhost/index.html">a link to your local host's
      toplevel index file</a>.
  </p>
 </body>
</html>
HERE

my $str = HTML::FormatText::Lynx->format_string ($html,
                                                 leftmargin  => 5,
                                                 rightmargin => 40);
print $str;
exit 0;

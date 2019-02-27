#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2015 Kevin Ryde

# This file is part of Finance-Quote-Grab.
#
# Finance-Quote-Grab is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Finance-Quote-Grab is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Finance-Quote-Grab.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use Test;
plan tests => 7;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Finance::Quote::MGEX;

# uncomment this to run the ### lines
#use Smart::Comments;

#------------------------------------------------------------------------------
my $want_version = 15;
ok ($Finance::Quote::MGEX::VERSION, $want_version, 'VERSION variable');
ok (Finance::Quote::MGEX->VERSION,  $want_version, 'VERSION class method');
{ ok (eval { Finance::Quote::MGEX->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Finance::Quote::MGEX->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# _javascript_document_write()

foreach my $elem ([ q{document.write('abc')}, 'abc' ],
                 ) {
  my ($java, $want) = @$elem;

  my $got = Finance::Quote::MGEX::_javascript_document_write ($java);
  ok ($got, $want, "_javascript_document_write: $java");
}

#------------------------------------------------------------------------------
# _javascript_string_unquote()

foreach my $elem ([ q{\\b\\t\\r\\n\\f\\'}, "\b\t\r\n\f'" ],
                  [ q{\\101\u0042C}, "ABC" ],
                 ) {
  my ($str, $want) = @$elem;

  my $got = Finance::Quote::MGEX::_javascript_string_unquote ($str);
  ok ($got, $want, "_javascript_string_unquote: $str");
}

exit 0;

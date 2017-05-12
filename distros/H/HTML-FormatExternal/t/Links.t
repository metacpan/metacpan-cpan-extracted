#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2013, 2015 Kevin Ryde

# This file is part of HTML-FormatExternal.
#
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
use Test::More tests => 9;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require HTML::FormatText::Links;
{
  my $want_version = 26;
  is ($HTML::FormatText::Links::VERSION, $want_version,
      'VERSION variable');
  is (HTML::FormatText::Links->VERSION,  $want_version,
      'VERSION class method');
  ok (eval { HTML::FormatText::Links->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { HTML::FormatText::Links->VERSION($check_version); 1 },
      "VERSION class check $check_version");

  my $formatter = HTML::FormatText::Links->new;
  is ($formatter->VERSION, $want_version, 'VERSION object method');
  ok (eval { $formatter->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $formatter->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

## no critic (ProtectPrivateSubs)

#-----------------------------------------------------------------------------
# _links_mung_charset()

foreach my $data (['latin-1', 'latin1'],
                  ['LATIN-2', 'LATIN2'],
                 ) {
  my ($str, $want) = @$data;
  is (HTML::FormatText::Links::_links_mung_charset($str),
      $want,
      "_links_mung_charset() '$str'");
}

exit 0;

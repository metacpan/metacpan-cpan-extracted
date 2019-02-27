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
use Test::More tests => 8;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Finance::Quote::MLC;


#------------------------------------------------------------------------------
my $want_version = 15;
is ($Finance::Quote::MLC::VERSION, $want_version,
    'VERSION variable');
is (Finance::Quote::MLC->VERSION,  $want_version,
    'VERSION class method');
{ ok (eval { Finance::Quote::MLC->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Finance::Quote::MLC->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# symbol_to_fund_and_product()

foreach my $elem (['Foo Bar,Quux Xyzzy', 'Foo Bar', 'Quux Xyzzy'],
                  # missing product is invalid, but see it splits ok
                  ['Foo Bar', 'Foo Bar', ''],
                 ) {
  my ($symbol, $want_fund, $want_product) = @$elem;
  my ($got_fund, $got_product)
    = Finance::Quote::MLC::symbol_to_fund_and_product ($symbol);

  is ($got_fund, $want_fund, "symbol: $symbol");
  is ($got_product, $want_product, "symbol: $symbol");
}

exit 0;

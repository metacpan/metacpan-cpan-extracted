#!/usr/bin/perl -w

# Copyright 2014, 2015, 2016 Kevin Ryde

# This file is part of Math-OEIS.
#
# Math-OEIS is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-OEIS is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-OEIS.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use Test::More tests => 11;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::OEIS::Stripped;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 10;
  is ($Math::OEIS::Stripped::VERSION, $want_version,
      'VERSION variable');
  is (Math::OEIS::Stripped->VERSION,  $want_version,
      'VERSION class method');

  is (eval { Math::OEIS::Stripped->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  is (! eval { Math::OEIS::Stripped->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# sample file reading

{
  my $stripped = Math::OEIS::Stripped->new (filename => 't/test-stripped');
  {
    my $str = $stripped->anum_to_values_str('A000001');
    is ($str, '1,2,3,4,5');
  }
  {
    my @values = $stripped->anum_to_values('A000002');
    is (join(':',@values), '6:7:8:9:10');
  }
  {
    # starting with negative
    my @values = $stripped->anum_to_values('A000003');
    is (join(':',@values), '-999:8:7');
  }

  {
    # non-existent A-number
    my @values = $stripped->anum_to_values('A111111');
    is (scalar(@values), 0);
    my $str = $stripped->anum_to_values_str('A111111');
    is ($str, undef);
  }

  {
    # draft with no values ,, same as not exist
    my @values = $stripped->anum_to_values('A999999');
    is (scalar(@values), 0);
    my $str = $stripped->anum_to_values_str('A999999');
    is ($str, undef);
  }
}

#------------------------------------------------------------------------------
exit 0;

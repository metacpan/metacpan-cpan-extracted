#!/usr/bin/perl -w

# Copyright 2014, 2015, 2016, 2017, 2019 Kevin Ryde

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
use Test::More tests => 22;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::OEIS::Stripped;

# uncomment this to run the ### lines
# use Smart::Comments;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 14;
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
# _IV_DECIMAL_DIGITS_MAX()

diag "_IV_DECIMAL_DIGITS_MAX is ",
  Math::OEIS::Stripped::_IV_DECIMAL_DIGITS_MAX();


#------------------------------------------------------------------------------
# line_split_anum()

is_deeply([Math::OEIS::Stripped->line_split_anum("A123456 ,1,9,12,\n")],
          ["A123456", "1,9,12"]);

is_deeply([Math::OEIS::Stripped->line_split_anum("A123456 ,,\n")],
          []);
is_deeply([Math::OEIS::Stripped->line_split_anum("# non A-number line\n")],
          []);


#------------------------------------------------------------------------------
# sample file reading

require FindBin;
require File::Spec;
my $test_stripped_filename = File::Spec->catfile($FindBin::Bin, 'test-stripped');
diag "bin dir ",$FindBin::Bin;
diag "test filename: ",$test_stripped_filename;

{
  my $stripped = Math::OEIS::Stripped->new (filename => $test_stripped_filename);
  {
    my $str = $stripped->anum_to_values_str('A000001');
    is ($str, '1,2,3,4,5');
  }
  {
    my @values = $stripped->anum_to_values('A000002');
    is (join(':',@values), '6:7:8:9:10');
    is (ref $values[0], '', 'small value not a bigint under if_necessary');
  }
  {
    # starting with negative
    my @values = $stripped->anum_to_values('A000003');
    is (join(':',@values), '-999:8:7');
  }

  # non-existent or bogus A-numbers are non found
  foreach my $anum ('A111111', 'A000002xyz', 'ZZZ') {
    my @values = $stripped->anum_to_values($anum);
    is (scalar(@values), 0);
    my $str = $stripped->anum_to_values_str($anum);
    is ($str, undef);
  }

  {
    # draft with no values ,, same as not exist
    my @values = $stripped->anum_to_values('A999999');
    is (scalar(@values), 0);
    my $str = $stripped->anum_to_values_str('A999999');
    is ($str, undef);
  }

 SKIP: {
    # bigint if_necessary
    if (Math::OEIS::Stripped::_IV_DECIMAL_DIGITS_MAX() >= 90) {
      skip "due to _IV_DECIMAL_DIGITS_MAX bigger than 90";
    }
    my @values = $stripped->anum_to_values('A000004');
    is (scalar(@values), 1);
    is (length($values[0]), 90);
    isa_ok($values[0], 'Math::BigInt');
  }
}


#------------------------------------------------------------------------------
exit 0;

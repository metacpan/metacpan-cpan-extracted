#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2016 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Test;
plan tests => 81;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::AsciiSelf;

# uncomment this to run the ### lines
#use Smart::Comments;

#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 73;
  ok ($Math::NumSeq::AsciiSelf::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::AsciiSelf->VERSION, $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::AsciiSelf->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::AsciiSelf->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# characteristic()

{
  my $seq = Math::NumSeq::AsciiSelf->new;
  ok ($seq->characteristic('count'), undef, 'characteristic(count)');
  ok ($seq->characteristic('integer'), 1, 'characteristic(integer)');
  ok ($seq->characteristic('smaller'), 1, 'characteristic(smaller)');
}


#------------------------------------------------------------------------------
# _digit_to_ascii()

ok (Math::NumSeq::AsciiSelf::_digit_to_ascii(0), 48);
ok (Math::NumSeq::AsciiSelf::_digit_to_ascii(1), 49);
ok (Math::NumSeq::AsciiSelf::_digit_to_ascii(9), 57);
ok (Math::NumSeq::AsciiSelf::_digit_to_ascii(10), 65);
ok (Math::NumSeq::AsciiSelf::_digit_to_ascii(11), 66);
ok (Math::NumSeq::AsciiSelf::_digit_to_ascii(15), 70);


#------------------------------------------------------------------------------
# next()

foreach my $radix (2 .. 35) {
  my $seq = Math::NumSeq::AsciiSelf->new (radix => $radix);
  my @got;
  my @ascii;
  foreach my $i (1 .. 50) {
    my ($i, $value) = $seq->next;
    push @got, $value;
    push @ascii, Math::NumSeq::AsciiSelf::_radix_ascii($radix,$value);
  }
  $#ascii = $#got;
  ok (join(',',@got), join(',',@ascii),
      "next() ascii expansion radix=$radix");
}

#------------------------------------------------------------------------------
# ith()

foreach my $radix (2 .. 35) {
  my $seq = Math::NumSeq::AsciiSelf->new (radix => $radix);

  ### can ith(): $seq->can('ith')
  my $skip = ($seq->can('ith')
              ? undef  # ith() available, no skip
              : 'ith() not available (eg. base 7)');

  my @got;
  my @ascii;
  foreach my $i (1 .. 50) {
    my $value = $seq->ith($i);
    push @got, $value;
    push @ascii, Math::NumSeq::AsciiSelf::_radix_ascii($radix,$value);
  }
  $#ascii = $#got;
  skip ($skip,
        join(',',@got), join(',',@ascii),
        "ith() ascii expansion radix=$radix");
}

exit 0;



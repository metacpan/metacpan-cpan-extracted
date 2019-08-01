#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2016 Kevin Ryde

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

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::NumSeq::ReverseAdd;

my $test_count = (tests => 13)[1];
plan tests => $test_count;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 73;
  ok ($Math::NumSeq::ReverseAdd::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::ReverseAdd->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::ReverseAdd->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::ReverseAdd->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# characteristic(), i_start(), parameters

{
  my $seq = Math::NumSeq::ReverseAdd->new;
  ok ($seq->characteristic('increasing'), 1, 'characteristic(increasing)');
  ok ($seq->characteristic('integer'),    1, 'characteristic(integer)');
  ok ($seq->i_start, 0, 'i_start()');

  my @pnames = map {$_->{'name'}} $seq->parameter_info_list;
  ok (join(',',@pnames),
      'start,radix');
}


#------------------------------------------------------------------------------
# _reverse_in_radix()

{
  my $str = "3377699871522813";
  my $n = Math::NumSeq::_to_bigint($str);
  MyTestHelpers::diag("n type: ", ref $n);
  MyTestHelpers::diag("str   : ", $str);
  MyTestHelpers::diag("n str : ", "$n");

  my $rev = Math::NumSeq::ReverseAdd::_reverse_in_radix($n,2);
  my $revstr = "$rev";
  $revstr =~ s/^\+//; # leading + from perl 5.6.2 BigInt
  ok ($revstr, "3377699468869635");

  my $bigint = Math::NumSeq::_bigint();
  MyTestHelpers::diag("BigInt can(as_bin): ",$bigint->can('as_bin'));
  if ($bigint->can('as_bin')) {
    my $as_bin = $n->as_bin;
    MyTestHelpers::diag("n as_bin(): ", $as_bin);
  }
  MyTestHelpers::diag("BigInt can(from_bin): ",$bigint->can('from_bin'));
}

{
  my $str = "256";
  my $n = Math::NumSeq::_to_bigint($str);
  my $rev = Math::NumSeq::ReverseAdd::_reverse_in_radix($n,4);
  my $revstr = "$rev";
  $revstr =~ s/^\+//; # leading + from perl 5.6.2 BigInt
  ok ($revstr, "1");
}
{
  my $str = "512";
  my $n = Math::NumSeq::_to_bigint($str);
  my $rev = Math::NumSeq::ReverseAdd::_reverse_in_radix($n,8);
  my $revstr = "$rev";
  $revstr =~ s/^\+//; # leading + from perl 5.6.2 BigInt
  ok ($revstr, "1");
}
{
  my $str = "256";
  my $n = Math::NumSeq::_to_bigint($str);
  my $rev = Math::NumSeq::ReverseAdd::_reverse_in_radix($n,16);
  my $revstr = "$rev";
  $revstr =~ s/^\+//; # leading + from perl 5.6.2 BigInt
  ok ($revstr, "1");
}
{
  my $str = "1234";
  my $n = Math::NumSeq::_to_bigint($str);
  my $rev = Math::NumSeq::ReverseAdd::_reverse_in_radix($n,10);
  my $revstr = "$rev";
  $revstr =~ s/^\+//; # leading + from perl 5.6.2 BigInt
  ok ($revstr, "4321");
}

exit 0;



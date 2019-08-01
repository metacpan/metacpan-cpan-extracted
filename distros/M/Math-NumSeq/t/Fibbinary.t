#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2016 Kevin Ryde

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
plan tests => 38;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::Fibbinary;

# uncomment this to run the ### lines
#use Smart::Comments;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 73;
  ok ($Math::NumSeq::Fibbinary::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::Fibbinary->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::Fibbinary->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::Fibbinary->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# characteristic()

{
  my $seq = Math::NumSeq::Fibbinary->new;
  ok ($seq->characteristic('integer'), 1, 'characteristic(integer)');
}

#------------------------------------------------------------------------------
# seek_to_i()

{
  my $seq = Math::NumSeq::Fibbinary->new;
  foreach my $i (0 .. 10, 20, 30) {
    $seq->seek_to_i($i);
    my ($got_i, $got_value) = $seq->next;
    ok ($got_i, $i);
    ok ($got_value, $seq->ith($i));
  }
}

#------------------------------------------------------------------------------
# pred()

{
  my $seq = Math::NumSeq::Fibbinary->new;
  ok ($seq->pred(0), 1);
  ok ($seq->pred(1), 1);
  ok (! $seq->pred(3), 1);
  ok ($seq->pred(4), 1);

  ok ($seq->pred(17), 1);

  # On cygwin perl 5.10.1 sprintf '%.0f' doesn't give an exact full set of
  # digits for 17*2**256.
  {
    my $nv = 17 * 2**256;
    my $pred_result = $seq->pred($nv);
    my $big_conv = Math::NumSeq::_to_bigint(sprintf('%.0f',$nv));
    my $big_calc = (Math::NumSeq::_to_bigint(2) ** 256) * 17;
    MyTestHelpers::diag ("big_calc ",$big_calc);
    MyTestHelpers::diag ("big_conv ",$big_conv);
    my $nv_to_bigint_good = ($big_conv == $big_calc);

    my $skip_nv_to_bigint = ($nv_to_bigint_good
                             ? undef
                             : 'sprintf NV -> BigInt is not exact');
    skip ($skip_nv_to_bigint,
          $pred_result, 1,
          '17*2**256 float -> bigint');
    MyTestHelpers::diag ("nv is ",$nv);
    MyTestHelpers::diag ("~0 is ",~0);
    my $str = sprintf('%.0f',$nv);
    MyTestHelpers::diag ("sprintf is ",$str);
    my $big = Math::NumSeq::_to_bigint($str);
    MyTestHelpers::diag ("_to_bigint(nv) is ",$big);
    MyTestHelpers::diag ("big & (big>>1) is ",$big & ($big>>1));
  }
}

#------------------------------------------------------------------------------
# value_to_i_floor()

{
  my $bad = 0;
  my $seq = Math::NumSeq::Fibbinary->new;
  my ($i, $value) = $seq->next;
 OUTER: foreach (1 .. 50) {
    my ($next_i, $next_value) = $seq->next;
    foreach my $try_value ($value .. $next_value-1) {
      my $got_i = $seq->value_to_i_floor($try_value);
      if ($i != $got_i) {
        MyTestHelpers::diag ("value_to_i_floor($try_value) got $got_i want $i");
        last OUTER if $bad++ > 20;
      }
    }
    $i = $next_i;
    $value = $next_value;
  }
  ok ($bad, 0, 'value_to_i_floor()');
}


exit 0;



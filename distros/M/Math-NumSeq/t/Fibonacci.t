#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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
plan tests => 2444;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::Fibonacci;

# uncomment this to run the ### lines
# use Smart::Comments;

#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 74;
  ok ($Math::NumSeq::Fibonacci::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::Fibonacci->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::Fibonacci->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::Fibonacci->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# negative ith()

{
  my $seq = Math::NumSeq::Fibonacci->new;
  my $f1 = $seq->ith(2);
  my $f0 = $seq->ith(1);
  for (my $i = 0; $i > -10; $i--) {
    my $f = $seq->ith($i);
    ok ($f + $f0, $f1, "i=$i  $f+$f0 should be $f1");
    $f1 = $f0;
    $f0 = $f;
  }
}


#------------------------------------------------------------------------------
# negative ith_pair()

{
  my $seq = Math::NumSeq::Fibonacci->new;
  my $want_f1 = $seq->ith(2);
  my $want_f0 = $seq->ith(1);
  for (my $i = 1; $i > -10; $i--) {
    my ($got_f0, $got_f1) = $seq->ith_pair($i);
    ok ("$got_f0,$got_f1", "$want_f0,$want_f1", "ith_pair() i=$i");

    # fprev + f0 = f1, so fprev = f1-f0
    ($want_f0, $want_f1) = ($want_f1 - $want_f0, $want_f0);
  }
}


#------------------------------------------------------------------------------
# seek_to_i()

{
  my $seq = Math::NumSeq::Fibonacci->new;
  foreach my $i (0 .. 150) {
    $seq->seek_to_i($i);

    foreach my $i ($i .. $i+3) {
      my ($got_i, $got_value) = $seq->next;
      ok ($got_i, $i);
      ok ($got_value == $seq->ith($i), 1);

      { my ($pair_0, $pair_1) = $seq->ith_pair($i);
        ok ($got_value == $pair_0, 1);
      }
      { my ($pair_0, $pair_1) = $seq->ith_pair($i-1);
        ok ($got_value == $pair_1, 1);
      }
    }

    # fib(103) = 1500520536206896083277
    # {
    #   my ($got_i, $got_value) = $seq->next;
    #   ok ($got_i, $i+3);
    #   my $got_ith = $seq->ith($i+3);
    #   ok ($got_value == $got_ith, 1, "at got_i=$i");
    #   unless ($got_value == $got_ith) {
    #     MyTestHelpers::diag ("got_value ",$got_value, " ", sprintf('%.1f',$got_value),
    #                          " ref=", ref($got_value));
    #     MyTestHelpers::diag ("got_ith   ",$got_ith, " ", sprintf('%.1f',$got_ith),
    #                          " ref=", ref($got_ith));
    #     my $diff = $got_ith - $got_value;
    #     MyTestHelpers::diag ("diff   ",$diff);
    #   }
    # }
  }
}

#------------------------------------------------------------------------------
# ith() automatic BigInt

{
  my $seq = Math::NumSeq::Fibonacci->new;
  {
    my $value = $seq->ith(256);
    ok (ref $value && $value->isa('Math::BigInt'),
        1);
  }
  {
    $seq->seek_to_i(256);
    my ($i, $value) = $seq->next;
    ok (ref $value && $value->isa('Math::BigInt'),
        1);
  }
}

#------------------------------------------------------------------------------
# bigfloat nan

my $skip_bigfloat;

# Note: not "require Math::BigFloat" since it does tie-ins to BigInt in its
if (! eval "use Math::BigFloat; 1") {
  MyTestHelpers::diag ("Math::BigFloat not available -- ",$@);
  $skip_bigfloat = "Math::BigFloat not available";
}

if (! Math::BigFloat->can('bnan')) {
  MyTestHelpers::diag ("Math::BigFloat no bnan()");
  $skip_bigfloat = "Math::BigFloat no bnan()";
}

{
  my @nans;
  unless ($skip_bigfloat) {
    my $seq = Math::NumSeq::Fibonacci->new;

    my $nan = Math::BigFloat->bnan;
    my $inf = Math::BigFloat->bnan;
    my $neginf = Math::BigFloat->bnan('-');

    foreach my $f ($nan, $inf, $neginf) {
      my $value = $seq->ith($f);
      my $value_is_nan = (ref $value && $value->is_nan ? 1 : 0);
      push @nans, $value_is_nan;
    }
  }

  skip ($skip_bigfloat,
        join(',',@nans),
        '1,1,1',
        'ith() on BigFloat nan,inf,neginf should return big nan');
}

#------------------------------------------------------------------------------
exit 0;

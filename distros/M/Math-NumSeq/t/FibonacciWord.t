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
plan tests => 13;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::FibonacciWord;

# uncomment this to run the ### lines
#use Smart::Comments;

#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 74;
  ok ($Math::NumSeq::FibonacciWord::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::FibonacciWord->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::FibonacciWord->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::FibonacciWord->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# pred()

{
  my $seq = Math::NumSeq::FibonacciWord->new;
  ok ($seq->pred(0), 1);
  ok ($seq->pred(1), 1);
  ok (! $seq->pred(2), 1);
  ok (! $seq->pred(1.5), 1);
  ok (! $seq->pred(-1), 1);
  ok ($seq->pred(-0), 1);
}

#------------------------------------------------------------------------------
# equals Fibbinary mod 2

{
  require Math::NumSeq::Fibbinary;
  my $word = Math::NumSeq::FibonacciWord->new;
  my $fibbinary = Math::NumSeq::Fibbinary->new;
  my $bad = 0;

  foreach my $rep (0 .. 500) {
    {
      my ($word_i, $word_value) = $word->next;
      my ($fibbinary_i, $fibbinary_value) = $fibbinary->next;
      my $fibbinary_value_mod = $fibbinary_value % 2;

      unless ($word_i == $fibbinary_i) {
        MyTestHelpers::diag ("next() i=$word_i vs $fibbinary_i");
        last if $bad++ > 10;
      }
      unless ($word_value == $fibbinary_value_mod) {
        MyTestHelpers::diag ("next() word=$word_value fibbinary=$fibbinary_value_mod");
        last if $bad++ > 10;
      }
    }
    {
      my $i = $rep;
      my $word_value = $word->ith($i);
      my $fibbinary_value_mod = $fibbinary->ith($i) % 2;
      unless ($word_value == $fibbinary_value_mod) {
        MyTestHelpers::diag ("ith($i) word=$word_value fibbinary=$fibbinary_value_mod");
        last if $bad++ > 10;
      }
    }

  }
  ok ($bad, 0, "FibonacciWord == Fibbinary mod 2");
}

#------------------------------------------------------------------------------
# ith() at UV max

{
  my $uv_max = ~0;
  my $seq = Math::NumSeq::FibonacciWord->new;

  require Math::BigInt;
  my $big_i = Math::BigInt->new("$uv_max");

  my $uv_got = $seq->ith($uv_max);
  my $big_got = $seq->ith($big_i);

  ok ($uv_got, $big_got);
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
    my $seq = Math::NumSeq::FibonacciWord->new;

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

exit 0;



#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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
plan tests => 69;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::OEIS::File;

# uncomment this to run the ### lines
#use Smart::Comments;

#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 75;
  ok ($Math::NumSeq::OEIS::File::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::OEIS::File->VERSION, $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::OEIS::File->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::OEIS::File->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# _value_cmp()

# foreach my $elem (['0', '1',  -1],
#                   ['-1', '1',  -1],
#                   ['-2', '1',  -1],
#                   ['2', '-1',  1],
#
#                   ['20', '9',  1],
#                   ['-20', '-9',  -1],
#                   ['-20', '9',  -1],
#
#                  ) {
#   my ($x,$y, $want) = @$elem;
#   {
#     my $got = Math::NumSeq::OEIS::File::_value_cmp($x,$y);
#     ok ($got, $want, "x=$x y=$y");
#   }
#   {
#     ($x,$y) = ($y,$x);
#     $want = -$want;
#     my $got = Math::NumSeq::OEIS::File::_value_cmp($x,$y);
#     ok ($got, $want, "x=$x y=$y (swapped)");
#   }
# }


#------------------------------------------------------------------------------
#

foreach my $options ([],
                     [_dont_use_afile=>1],

                     [_dont_use_afile=>1,
                      _dont_use_bfile=>1],

                     [_dont_use_afile=>1,
                      _dont_use_bfile=>1,
                      _dont_use_internal=>1],

                     [_dont_use_afile=>1,
                      _dont_use_bfile=>1,
                      _dont_use_html=>1],
                    ) {
  foreach my $anum ('A002260',  # a002260.txt some text not numbers
                    'A000396',  # perfect numbers
                    'A004540',  # sqrt(2) in base 3
                    'A000012',  # all 1s
                    'A003849',  # special case a003849.txt
                    'A027750',  # special case a027750.txt
                    'A005228',  # detect a005228.txt is source code
                    'A195467',  # detect a195467.txt is a table
                    'A001489',  # negative integers 0 downwards
                    'A067188',  # "full"
                    'A000796',  # pi in decimal
                    'A005105',  # a005105.txt is code
                    'A102419',  # a102419.txt is pairs but not n,value
                   ) {
    ### $anum

    my $bad = 0;
    my $skip;
    my $err;
    my $seq;
    if (! eval { $seq = Math::NumSeq::OEIS::File->new
                   (anum => $anum, @$options);
                 1 }) {
      $err = $@;
      if ($err =~ /not found for A-number/) {
        $skip = $err;
      } else {
        $bad = 1;
      }
    } else {
      if (defined $seq->{'next_seek'}) {
        $err = "oops, next_seek set on initial creation";
        $bad = 1;
      }        

      my ($i, $value) = $seq->next;

      my $i_start = $seq->i_start;
      if (defined $i && $i != $seq->i_start) {
        $err = "oops, i_start=$i_start but first i=$i";
        $bad = 1;
      }

      $seq->next;

      unless (($i, $value) = $seq->next) {
        $err = "oops, no values from $anum";
        $bad = 1;
      }

      if ($anum eq 'A001489') {
        unless (($value || 0) == '-2') {
          $err = "oops, A001489 value not -2";
          $bad = 1;
        }
      }

      if ($anum eq 'A067188') {
        my $values_min = $seq->values_min;
        my $values_max = $seq->values_max;
        unless (defined $values_min && $values_min == 10) {
          $err = "oops, A067188 values_min not 10: $values_min";
          $bad = 1;
        }
        unless (defined $values_max && $values_max == 68) {
          $err = "oops, A067188 values_max not 68";
          $bad = 1;
        }
      }

      if ($anum eq 'A000796') {
        my $values_min = $seq->values_min;
        my $values_max = $seq->values_max;
        my $digits = $seq->characteristic('digits');
        unless (defined $values_min && $values_min == 0) {
          $err = "oops, A000796 values_min not 0: $values_min";
          $bad = 1;
        }
        unless (defined $values_max && $values_max == 9) {
          $err = "oops, A000796 values_max not 9";
          $bad = 1;
        }
        unless (defined $digits && $digits == 10) {
          $err = "oops, A000796 characteristic(digits) not 10";
          $bad = 1;
        }
      }

      if ($anum eq 'A004540') {  # sqrt2 base 3
        my $values_min = $seq->values_min;
        my $values_max = $seq->values_max;
        my $digits = $seq->characteristic('digits');
        unless (defined $values_min && $values_min == 0) {
          $err = "oops, A004540 values_min not 0: $values_min";
          $bad = 1;
        }
        unless (defined $values_max && $values_max == 2) {
          $err = "oops, A004540 values_max not 2";
          $bad = 1;
        }
        unless ($seq->{'_dont_use_internal'}) {
          unless (defined $digits && $digits == 3) {
            $err = "oops, A004540 characteristic(digits) not 3: "
              . (defined $digits ? $digits : 'undef');
            $bad = 1;
          }
        }
      }

      if ($anum eq 'A000012') {
        my $values_min = $seq->values_min;
        my $values_max = $seq->values_max;
        my $digits = $seq->characteristic('digits');
        unless (defined $values_min && $values_min == 1) {
          $err = "oops, A000012 values_min not 1";
          $bad = 1;
        }
        unless (defined $values_max && $values_max == 1) {
          $err = "oops, A000012 values_max not 1";
          $bad = 1;
        }
        unless (! defined $digits) {
          $err = "oops, A000012 characteristic(digits) not undef";
          $bad = 1;
        }
      }


      foreach (1 .. 10) {
        ($i, $value) = $seq->next or last;
        ### $i
        ### $value
        if (length($value) > Math::NumSeq::OEIS::File::_MAX_DIGIT_LENGTH) {
          if (! ref $value) {
            $err = "large value not a bigint i=$i value=$value";
            $bad = 1;
          }
        }
      }
    }
    skip ($skip,
          $bad, 0, "$anum");
    if ($bad) {
      MyTestHelpers::diag("err: $err");
      MyTestHelpers::diag("options: ",join(', ',@$options));
    }
  }
}


exit 0;



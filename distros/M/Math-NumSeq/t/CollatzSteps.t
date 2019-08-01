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

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::CollatzSteps;

# uncomment this to run the ### lines
#use Devel::Comments;

my $test_count = (tests => 13)[1];
plan tests => $test_count;

{
  # Math::NumSeq::CollatzSteps uses Math::BigInt binc() and bmul()
  #
  require Math::NumSeq;
  my $n = Math::NumSeq::_to_bigint(123);
  if (! $n->can('binc')) {
    MyTestHelpers::diag ('skip due to Math::BigInt no binc() method');
    foreach (1 .. $test_count) {
      skip ('due to Math::BigInt no binc() method', 1, 1);
    }
    exit 0;
  }
}

#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 73;
  ok ($Math::NumSeq::CollatzSteps::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::CollatzSteps->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::CollatzSteps->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::CollatzSteps->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# characteristic()

{
  my $seq = Math::NumSeq::CollatzSteps->new;
  ok ($seq->characteristic('smaller'), 1, 'characteristic(smaller)');
  ok ($seq->characteristic('integer'), 1, 'characteristic(integer)');

  ok (! $seq->characteristic('increasing'), 1,
      'characteristic(increasing)');
  ok (! $seq->characteristic('non_decreasing'), 1,
      'characteristic(non_decreasing)');
  ok ($seq->characteristic('increasing_from_i'), undef,
      'characteristic(increasing_from_i)');
  ok ($seq->characteristic('non_decreasing_from_i'), undef,
      'characteristic(non_decreasing_from_i)');

  my @pnames = map {$_->{'name'}} $seq->parameter_info_list;
  ok (join(',',@pnames), 'step_type,on_values');
}


#------------------------------------------------------------------------------
# ith()

my $uv_bits = 0;
{
  my $uv = ~0;
  while ($uv) {
    $uv_bits++;
    $uv >>= 1;
    last if $uv_bits >= 64;
  }
}
MyTestHelpers::diag ("uv_bits is $uv_bits");

{
  my $seq = Math::NumSeq::CollatzSteps->new;
  foreach my $elem (
                    [0xFFFF_FFFF, 451],

                    ($uv_bits >= 64
                     ? [eval '18446744073709551615', 863]  # 2^64-1
                     : [0,0]),

                   ) {
    my ($i, $want_value) = @$elem;
    ### $i
    my $got_value = $seq->ith($i);
    ### $got_value
    ok ($got_value, $want_value, "CollatzSteps ith($i)");
  }
}

exit 0;



#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2016, 2018, 2019, 2020 Kevin Ryde

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

use Math::NumSeq::BalancedBinary;

# uncomment this to run the ### lines
#use Smart::Comments;

my $test_count = (tests => 187)[1];
plan tests => $test_count;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 75;
  ok ($Math::NumSeq::BalancedBinary::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::BalancedBinary->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::BalancedBinary->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::BalancedBinary->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# characteristic(), i_start(), parameters

{
  my $seq = Math::NumSeq::BalancedBinary->new;
  ok ($seq->characteristic('increasing'), 1, 'characteristic(increasing)');
  ok ($seq->characteristic('integer'),    1, 'characteristic(integer)');
  ok (! $seq->characteristic('smaller'),  1, 'characteristic(smaller)');
  ok ($seq->i_start, 1, 'i_start()');

  my @pnames = map {$_->{'name'}} $seq->parameter_info_list;
  ok (join(',',@pnames),
      '');
}


#------------------------------------------------------------------------------
# pred() vs next()

{
  my $seq = Math::NumSeq::BalancedBinary->new;
  ok (! $seq->pred(0), 1, "pred() not 0");
  ok (! $seq->pred(1), 1);
  ok ($seq->pred(2), 1);
  my $prev = -1;
  for (1 .. 10) {
    my ($i,$value) = $seq->next;
    foreach my $t ($prev+1 .. $value-1) {
      ok (! $seq->pred($t), 1, "pred() not t=$t");
    }
    ok ($seq->pred($value), 1);
    $prev = $value;
  }
}

#------------------------------------------------------------------------------
# value_to_i_ceil()

{
  my $seq = Math::NumSeq::BalancedBinary->new;

  ok ($seq->value_to_i_ceil(1.75), 1);
  ok ($seq->value_to_i_ceil(2.25), 2);

  my ($want_i_ceil, $target_value) = $seq->next;
  my $value = -5;
  for (1 .. 50) {
    for ( ; $value <= $target_value; $value++) {
      my $got_i_ceil = $seq->value_to_i_ceil($value);
      unless (equal($got_i_ceil,$want_i_ceil)) {
        die "value_to_i_ceil()";
      }
    }
    ($want_i_ceil, $target_value) = $seq->next;
  }
}


#------------------------------------------------------------------------------
# value_to_i_floor()

{
  my $seq = Math::NumSeq::BalancedBinary->new;
  my $want_i_floor = 1;
  my $value = -5;
  for (1 .. 50) {
    my ($target_i, $target_value) = $seq->next;
    for ( ; $value < $target_value; $value++) { 
      my $got_i_floor = $seq->value_to_i_floor($value);
      unless (equal($got_i_floor,$want_i_floor)) {
        die "value_to_i_floor()";
      }
    }
    $want_i_floor = $target_i;
  }
}

sub equal {
  my ($x,$y) = @_;
  return ((defined $x && defined $y && $x == $y)
          || (! defined $x && ! defined $y));
}


# #------------------------------------------------------------------------------
# # seek_to_value()
# 
# {
#   my $seq = Math::NumSeq::BalancedBinary->new;
#   {
#     $seq->seek_to_value(-123);
#     my ($i, $value) = $seq->next;
#     ok ($i, -123);
#     ok ($value, -123);
#   }
#   {
#     $seq->seek_to_value(-100.5);
#     my ($i, $value) = $seq->next;
#     ok ($i, -100);
#     ok ($value, -100);
#   }
#   {
#     $seq->seek_to_value(0);
#     my ($i, $value) = $seq->next;
#     ok ($i, 0);
#     ok ($value, 0);
#   }
#   {
#     $seq->seek_to_value(0.5);
#     my ($i, $value) = $seq->next;
#     ok ($i, 1);
#     ok ($value, 1);
#   }
#   {
#     $seq->seek_to_value(1);
#     my ($i, $value) = $seq->next;
#     ok ($i, 1);
#     ok ($value, 1);
#   }
#   {
#     $seq->seek_to_value(1.5);
#     my ($i, $value) = $seq->next;
#     ok ($i, 2);
#     ok ($value, 2);
#   }
#   {
#     $seq->seek_to_value(4);
#     my ($i, $value) = $seq->next;
#     ok ($i, 4);
#     ok ($value, 4);
#   }
#   {
#     $seq->seek_to_value(100.5);
#     my ($i, $value) = $seq->next;
#     ok ($i, 101);
#     ok ($value, 101);
#   }
# }

#------------------------------------------------------------------------------
exit 0;



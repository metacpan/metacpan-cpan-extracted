#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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
plan tests => 67;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::NumSeq::Catalan;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 74;
  ok ($Math::NumSeq::Catalan::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::Catalan->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::Catalan->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::Catalan->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# characteristic(), i_start(), parameters

{
  my $seq = Math::NumSeq::Catalan->new;
  ok ($seq->i_start, 0, 'i_start()');

  ok ($seq->characteristic('integer'),           1, 
      'characteristic(integer)');
  ok ($seq->characteristic('non_decreasing'),    1,
      'characteristic(non_decreasing)');
  ok (! $seq->characteristic('increasing'),      1,
      'characteristic(increasing)');
  ok ($seq->characteristic('increasing_from_i'), 1,
      'characteristic(increasing_from_i)');

  my @pnames = map {$_->{'name'}} $seq->parameter_info_list;
  ok (join(',',@pnames), 'values_type');
}
{
  my $seq = Math::NumSeq::Catalan->new (values_type => "odd");
  ok ($seq->i_start, 0, 'i_start()');

  ok ($seq->characteristic('integer'),           1,
      'characteristic(integer)');
  ok ($seq->characteristic('non_decreasing'),    1,
      'characteristic(non_decreasing)');
  ok (! $seq->characteristic('increasing'),      1,
      'characteristic(increasing)');
  ok ($seq->characteristic('increasing_from_i'), 2,
      'characteristic(increasing_from_i)');
}

#------------------------------------------------------------------------------
# seek_to_i()

foreach my $values_type ('C', 'odd') {
  my $seq = Math::NumSeq::Catalan->new (values_type => $values_type);
  foreach my $i ($seq->i_start .. 10, 20, 30) {
    $seq->seek_to_i($i);
    my ($got_i, $got_value) = $seq->next;
    ok ($got_i, $i);
    ok ($got_value, $seq->ith($i));
  }
}

# #------------------------------------------------------------------------------
# # value_to_i_floor()
# 
# {
#   my $seq = Math::NumSeq::Catalan->new;
# 
#   # {
#   #   require Math::BigInt;
#   #   my $v = Math::BigInt->new("2432902008176640000");
#   #   ok ($seq->value_to_i_floor($v-1), 19);
#   #   ok ($seq->value_to_i_floor($v), 20);
#   #   ok ($seq->value_to_i_floor($v+1), 20);
#   # }
# 
#   ok ($seq->value_to_i_floor(0), 0);
#   ok ($seq->value_to_i_floor(0.5), 0);
#   ok ($seq->value_to_i_floor(1), 0);
#   ok ($seq->value_to_i_floor(1.5), 0);
# 
#   ok ($seq->value_to_i_floor(2), 2);  # 1*2=6
#   ok ($seq->value_to_i_floor(3), 2);
# 
#   ok ($seq->value_to_i_floor(5), 2);
#   ok ($seq->value_to_i_floor(6), 3);  # 1*2*3=6
#   ok ($seq->value_to_i_floor(7), 3);
# 
#   ok ($seq->value_to_i_floor(23), 3);
#   ok ($seq->value_to_i_floor(24), 4);  # 1*2*3*4=24
#   ok ($seq->value_to_i_floor(25), 4);
# 
#   ok ($seq->value_to_i_floor(119), 4);
#   ok ($seq->value_to_i_floor(120), 5);  # 1*2*3*4*5=120
#   ok ($seq->value_to_i_floor(121), 5);
# }
# 
# # {
# #   my $seq = Math::NumSeq::Catalan->new;
# #   $seq->next;
# #   $seq->next;
# #   my ($prev_i, $prev_value) = $seq->next;
# #   foreach (1 .. 8) {
# #     my ($i, $value) = $seq->next;
# #     MyTestHelpers::diag("$value");
# #
# #     foreach my $try_value ($prev_value .. $value-1) {
# #       my $got_i = $seq->value_to_i_floor($try_value);
# #       if ($got_i != $prev_i) {
# #         die "try_value=$try_value want $prev_i got $got_i";
# #       }
# #     }
# #     $prev_i = $i;
# #     $prev_value = $value;
# #   }
# # }

#------------------------------------------------------------------------------
exit 0;

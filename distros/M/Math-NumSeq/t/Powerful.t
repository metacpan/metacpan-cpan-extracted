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
plan tests => 16;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::Powerful;

# uncomment this to run the ### lines
#use Smart::Comments;

#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 73;
  ok ($Math::NumSeq::Powerful::VERSION, $want_version, 'VERSION variable');
  ok (Math::NumSeq::Powerful->VERSION,  $want_version, 'VERSION class method');

  ok (eval { Math::NumSeq::Powerful->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::Powerful->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# characteristic()

{
  my $seq = Math::NumSeq::Powerful->new;
  ok ($seq->i_start, 1, 'i_start()');

  ok (! $seq->characteristic('count'), 1, 'characteristic(count)');
  ok ($seq->characteristic('digits'), undef, 'characteristic(digits)');
  ok ($seq->characteristic('integer'), 1, 'characteristic(integer)');
  ok (! $seq->characteristic('smaller'), 1, 'characteristic(smaller)');

  ok ($seq->characteristic('increasing'), 1, 'characteristic(increasing)');
  ok ($seq->characteristic('non_decreasing'), 1, 'characteristic(non_decreasing)');
  ok ($seq->characteristic('increasing_from_i'), $seq->i_start);
  ok ($seq->characteristic('non_decreasing_from_i'), $seq->i_start);

  my @pnames = map {$_->{'name'}} $seq->parameter_info_list;
  ok (join(',',@pnames),
      'powerful_type,power');
}


# Not implemented yet.
#
# #------------------------------------------------------------------------------
# # seek_to_value()
# 
# {
#   my $seq = Math::NumSeq::Powerful->new;
#   {
#     $seq->seek_to_value(-123);
#     my ($i, $value) = $seq->next;
#     ok ($i, 1);
#     ok ($value, 4);
#   }
#   {
#     $seq->seek_to_value(-100.5);
#     my ($i, $value) = $seq->next;
#     ok ($i, 1);
#     ok ($value, 4);
#   }
#   {
#     $seq->seek_to_value(0);
#     my ($i, $value) = $seq->next;
#     ok ($i, 1);
#     ok ($value, 4);
#   }
#   {
#     $seq->seek_to_value(3.75);
#     my ($i, $value) = $seq->next;
#     ok ($i, 1);
#     ok ($value, 4);
#   }
#   {
#     $seq->seek_to_value(4);
#     my ($i, $value) = $seq->next;
#     ok ($i, 1);
#     ok ($value, 4);
#   }
#   {
#     $seq->seek_to_value(4.5);
#     my ($i, $value) = $seq->next;
#     ok ($i, 2);
#     ok ($value, 9);
#   }
#   {
#     $seq->seek_to_value(17);
#     my ($i, $value) = $seq->next;
#     ok ($i, 6);
#     ok ($value, 18);
#   }
#   {
#     $seq->seek_to_value(17.75);
#     my ($i, $value) = $seq->next;
#     ok ($i, 6);
#     ok ($value, 18);
#   }
#   {
#     $seq->seek_to_value(18);
#     my ($i, $value) = $seq->next;
#     ok ($i, 6);
#     ok ($value, 18);
#   }
#   {
#     $seq->seek_to_value(18.25);
#     my ($i, $value) = $seq->next;
#     ok ($i, 7);
#     ok ($value, 20);
#   }
# }

#------------------------------------------------------------------------------
# pred() on BigInt

{
  require Math::BigInt;
  my $seq = Math::NumSeq::Powerful->new (powerful_type => 'all');
  {
    my $big = Math::BigInt->new(1);
    foreach (1 .. 43) { $big *= 2; }
    $big *= 9;
    ok (!! $seq->pred($big),
        1,
        'pred() big 9*2**43 is powerful_type=all');
  }
  {
    my $big = Math::BigInt->new(1);
    foreach (1 .. 67) { $big *= 2; }
    ok (!! $seq->pred($big),
        1,
        'pred() big 2**67 is powerful_type=all');
  }
}

#------------------------------------------------------------------------------
exit 0;



#!/usr/bin/perl -w

# Copyright 2013, 2014, 2016 Kevin Ryde

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
plan tests => 15;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::Abundant;

# uncomment this to run the ### lines
# use Smart::Comments;

#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 73;
  ok ($Math::NumSeq::Abundant::VERSION, $want_version, 'VERSION variable');
  ok (Math::NumSeq::Abundant->VERSION,  $want_version, 'VERSION class method');

  ok (eval { Math::NumSeq::Abundant->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::Abundant->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# characteristic()

{
  my $seq = Math::NumSeq::Abundant->new;
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
  ok (join(',',@pnames), 'abundant_type');
}


#------------------------------------------------------------------------------
# error from bad abundant_type

{
  my $error = 1;
  eval {
    my $seq = Math::NumSeq::Abundant->new (abundant_type => 'nosuchtype');
    ### $seq
    $seq->next;
    $error = 0;
  };
  if ($error) {
    # MyTestHelpers::diag ("abundant_type nosuchtype ", $@);
  }
  ok ($error, 1);
}


#------------------------------------------------------------------------------

exit 0;



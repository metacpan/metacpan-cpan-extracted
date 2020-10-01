#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Test;
plan tests => 64;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

# uncomment this to run the ### lines
#use Smart::Comments;

require Math::PlanePath::DigitGroups;
my $path = Math::PlanePath::DigitGroups->new;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 128;
  ok ($Math::PlanePath::DigitGroups::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::DigitGroups->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::DigitGroups->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::DigitGroups->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  ok ($path->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $path->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  ok (! eval { $path->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}


#------------------------------------------------------------------------------
# n_start, x_negative, y_negative

{
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative, 0, 'x_negative() instance method');
  ok ($path->y_negative, 0, 'y_negative() instance method');
  ok ($path->class_x_negative, 0, 'class_x_negative() instance method');
  ok ($path->class_y_negative, 0, 'class_y_negative() instance method');

  my @pnames = map {$_->{'name'}} $path->parameter_info_list;
  ok (join(',',@pnames), 'radix', 'parameter_info_list() keys');
}


#------------------------------------------------------------------------------
# diagonal bit runs duplicate

sub to_binary {
  my ($n) = @_;
  return ($n < 0 ? '-' : '') . sprintf('%b', abs($n));
}
sub from_binary {
  my ($str) = @_;
  return oct("0b$str");
}

# return $n with each run of bits "011...11" duplicated
# eg. n=1011 -> 101011011
sub duplicate_bit_runs {
  my ($n) = @_;
  ### duplicate_bit_runs(): $n
  my $str = '0' . to_binary($n);
  ### $str
  $str =~ s/(01*)/$1$1/g;
  ### $str
  return from_binary($str);
}

{
  my $path = Math::PlanePath::DigitGroups->new;
  foreach my $i (0 .. 50) {
    my $path_n = $path->xy_to_n($i,$i);
    my $dup_n = duplicate_bit_runs($i);
    ok ($dup_n, $path_n);
  }
}

#------------------------------------------------------------------------------

exit 0;

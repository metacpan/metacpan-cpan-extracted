#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

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


use 5.010;
use strict;
use warnings;
use lib '/so/perl/number-fraction/number-fraction/lib/';
use Number::Fraction;
print Number::Fraction->VERSION,"\n";

# uncomment this to run the ### lines
use Smart::Comments;

{
  my $x = Number::Fraction->new('4/3');
  my $y = Number::Fraction->new('2/1');
  my $pow = $x ** $y;
  print "pow: $pow\n";
  exit 0;
}

{
  my $x = Number::Fraction->new('0/2');
  my $y = Number::Fraction->new('0/1');
  my $eq = ($x == $y);
  print "equal: $eq\n";
  exit 0;
}

{
  my $nf = Number::Fraction->new('4/-3');
  print "$nf\n";
  $nf = int($nf);
  print "$nf  ",ref($nf),"\n";
  exit 0;
}

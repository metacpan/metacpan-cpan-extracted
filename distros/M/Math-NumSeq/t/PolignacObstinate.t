#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014 Kevin Ryde

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
plan tests => 7;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::PolignacObstinate;

# uncomment this to run the ### lines
#use Smart::Comments;

#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 72;
  ok ($Math::NumSeq::PolignacObstinate::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::PolignacObstinate->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::PolignacObstinate->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::PolignacObstinate->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# values

foreach my $rep (1 .. 3) {
  my $seq = Math::NumSeq::PolignacObstinate->new;
  my @next;
  for (1 .. 1000) {
    my ($i, $value) = $seq->next;
    $next[$value] = 1;
  }
  my $hi = $#next;

  my $good = 1;
  foreach my $value (1 .. $hi) {
    my $pred = ($seq->pred($value)?1:0);
    my $next = $next[$value] || 0;
    if ($pred != $next) {
      MyTestHelpers::diag("rep=$rep: value=$value wrong pred=$pred next=$next");
      $good = 0;
      last;
    }
  }
  ok ($good, 1, "rep=$rep good");
}

exit 0;



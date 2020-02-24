#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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
plan tests => 6;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::MephistoWaltz;

# uncomment this to run the ### lines
#use Smart::Comments;

#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 74;
  ok ($Math::NumSeq::MephistoWaltz::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::MephistoWaltz->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::MephistoWaltz->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::MephistoWaltz->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# by expansion

{
  my @expand = (0);
  for (1 .. 7) {
    @expand = map { $_ ? (1,1,0) : (0,0,1) } @expand;
  }
  # MyTestHelpers::diag ("expansion: ",join(', ', @expand[0..81]));

  my $bad = 0;
  {
    my $seq = Math::NumSeq::MephistoWaltz->new;
    for (my $want_i = 0; $want_i < @expand; $want_i++) {
      my ($i, $value) = $seq->next;
      unless ($i == $want_i) {
        MyTestHelpers::diag ("next($want_i) i, got $i want $want_i");
        $bad++ < 10 or die "too much badness";
      }
      unless ($value == $expand[$want_i]) {
        MyTestHelpers::diag ("next($want_i) value got $value, want $expand[$want_i]");
        $bad++ < 10 or die "too much badness";
      }
    }

    for (my $i = 0; $i < @expand; $i++) {
      my $value = $seq->ith($i);
      unless ($value == $expand[$i]) {
        MyTestHelpers::diag ("ith($i) value got $value, want $expand[$i]");
        $bad++ < 10 or die "too much badness";
      }
    }
  }
  ok ($bad, 0);
}

#------------------------------------------------------------------------------
# by parity

sub ith_by_parity {
  my ($i) = @_;

  my $ret = 0;
  while ($i) {
    $ret ^= (($i % 3) == 2);
    $i = int($i/3);
  }
  return $ret;
}


{
  my $bad = 0;
  {
    my $seq = Math::NumSeq::MephistoWaltz->new;
    for (my $i = 0; $i < 3 ** 5; $i++) {
      my $value = $seq->ith($i);
      my $value_by_parity = $seq->ith($i);
      unless ($value == $value_by_parity) {
        MyTestHelpers::diag ("ith_by_parity($i) value got $value, want $value_by_parity");
        $bad++ < 10 or die "too much badness";
      }
    }
  }
  ok ($bad, 0);
}

exit 0;



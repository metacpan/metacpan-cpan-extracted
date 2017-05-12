#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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
BEGIN {
  plan tests => 6;
}

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq;

my $skip;

# version 3.002 for "tracked_types"
if (! eval "use Test::Weaken 3.002; 1") {
  MyTestHelpers::diag ("Test::Weaken 3.002 not available -- $@");
  $skip = "due to Test::Weaken 3.002 not available";
}

unless ($skip) {
  if (! eval "use Test::Weaken::ExtraBits; 1") {
    MyTestHelpers::diag ("Test::Weaken::ExtraBits not available -- $@");
    $skip = "due to Test::Weaken::ExtraBits not available";
  }
}

#------------------------------------------------------------------------------

foreach my $anum ('A000040', # primes, a000040.txt
                  'A000027', # integers 1 up, array samples
                  'A999999', # no such number
                 ) {
  foreach my $clone (0, 1) {
    my $leaks;
    unless ($skip) {
      $leaks = Test::Weaken::leaks
        ({ constructor => sub {
             my $seq;
             eval { $seq = Math::NumSeq->new (anum => $anum) };
             my $old_fh;
             if ($seq) {
               $old_fh = $seq->{'fh'};
               if ($clone) {
                 Math::NumSeq->CLONE;
               }
             }
             return [ $seq, $old_fh ];
           },
           contents => \&Test::Weaken::ExtraBits::contents_glob_IO,
           tracked_types => [ 'GLOB', 'IO' ],

         });
    }
    skip ($skip,
          $leaks,
          undef,
          'Test::Weaken deep garbage collection');
    if ($leaks) {
      MyTestHelpers::dump($leaks);

      my $unfreed = $leaks->unfreed_proberefs;
      foreach my $proberef (@$unfreed) {
        MyTestHelpers::diag ("  unfreed $proberef");
      }
      foreach my $proberef (@$unfreed) {
        MyTestHelpers::diag ("  search $proberef");
        MyTestHelpers::findrefs($proberef);
      }
    }
  }
}

exit 0;

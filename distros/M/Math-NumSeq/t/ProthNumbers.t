#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014 Kevin Ryde

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

use Math::NumSeq::ProthNumbers;

my $test_count = (tests => 1584)[1];
plan tests => $test_count;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 72;
  ok ($Math::NumSeq::ProthNumbers::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::ProthNumbers->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::ProthNumbers->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::ProthNumbers->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# characteristic(), i_start(), parameters

{
  my $seq = Math::NumSeq::ProthNumbers->new;
  ok ($seq->characteristic('increasing'), 1, 'characteristic(increasing)');
  ok ($seq->characteristic('integer'),    1, 'characteristic(integer)');
  ok (! $seq->characteristic('smaller'),  1, 'characteristic(smaller)');
  ok ($seq->i_start, 1, 'i_start()');

  my @pnames = map {$_->{'name'}} $seq->parameter_info_list;
  ok (join(',',@pnames),
      '');
}


#------------------------------------------------------------------------------
# seek_to_i()

{
  my $nn = Math::NumSeq::ProthNumbers->new;
  my $ss = Math::NumSeq::ProthNumbers->new;

  foreach my $i (1 .. 512+10) {
    $ss->seek_to_i($i);
    ok ($ss->{'value'}, $nn->{'value'}, "value at i=$i");
    ok ($ss->{'inc'},   $nn->{'inc'},   "inc   at i=$i");
    ok ($ss->{'limit'}, $nn->{'limit'}, "limit at i=$i");
    $nn->next;
  }
}

#------------------------------------------------------------------------------
# pred()

{
  my $seq = Math::NumSeq::ProthNumbers->new;
  foreach my $elem ([ 3, 1 ], # 11
                    [ 4, 0 ], # 100
                    [ 5, 1 ], # 101

                    [ 8, 0 ], # 1000
                    [ 9, 1 ], # 1001
                    [ 10, 0 ], # 1011

                    # binary 10010101011111111010
                    [ 612346, 0 ],
                    [ Math::NumSeq::_to_bigint(612346), 0 ],

                    # binary 1001010101
                    #        0000000001
                    [ 611329, 1 ],
                   ) {
    my ($value, $want) = @$elem;
    my $got = $seq->pred($value) ? 1 : 0;
    ok ($got, $want, "pred() value=$value got $got want $want");
  }
}

#------------------------------------------------------------------------------
exit 0;



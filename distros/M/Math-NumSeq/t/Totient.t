#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2016 Kevin Ryde

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

use Math::NumSeq::Totient;

# uncomment this to run the ### lines
#use Smart::Comments;

#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 73;
  ok ($Math::NumSeq::Totient::VERSION, $want_version, 'VERSION variable');
  ok (Math::NumSeq::Totient->VERSION,  $want_version, 'VERSION class method');

  ok (eval { Math::NumSeq::Totient->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::Totient->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# characteristic()

{
  my $seq = Math::NumSeq::Totient->new;
  ok ($seq->characteristic('count'), 1, 'characteristic(count)');
  ok ($seq->characteristic('integer'), 1, 'characteristic(integer)');
}


#------------------------------------------------------------------------------
# _totient()

# {
#   my $seq = Math::NumSeq::Totient->new;
#   foreach my $elem ([0, 0],
#                     [1, 1],
#                     [2, 1],
#                     [3, 2],
#                     [4, 2],
#                     [5, 4],
#                    ) {
#     my ($i, $want) = @$elem;
#     my $got = Math::NumSeq::Totient::_totient($i);
#     ok ($got, $want, "_totient() i=$i got $got want $want");
#   }
# }

#------------------------------------------------------------------------------
# _totient()

{
  my $seq = Math::NumSeq::Totient->new;
  foreach my $elem ([0, 0],
                    [1, 1],
                    [2, 1],
                    [3, 2],
                    [4, 2],
                    [5, 4],

                    [9, 6],   # coprime 1,2,4,5,7,8
                    [10, 4],  # coprime 1,3,7,9
                    [11, 10],
                   ) {
    my ($i, $want) = @$elem;
    my $got = Math::NumSeq::Totient::_totient($i);
    ok ($got, $want, "_totient() i=$i got $got want $want");
  }
}

#------------------------------------------------------------------------------
# pred() on BigInt

{
  my $seq = Math::NumSeq::Totient->new;
  my $small = 120;
  require Math::BigInt;
  my $big = Math::BigInt->new(120);
  ok ($seq->pred($big), $seq->pred($small));
}

exit 0;



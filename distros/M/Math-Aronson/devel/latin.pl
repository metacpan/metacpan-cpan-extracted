#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Math-Aronson.
#
# Math-Aronson is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Aronson is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Aronson.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use Math::Aronson;

# uncomment this to run the ### lines
use Smart::Comments;

# http://www.csun.edu/~hcfll004/latin-numbers.html
#

# Bennet
#    100,000.  centum milia               centies millesimus
#  1,000,000.  decies centena milia       decies centies millesimus

my @ones = ('nonus',      # 0
            'primus',     # 1
            'secundus',   # 2
            'tertius',    # 3
            'quartus',    # 4
            'quintus',    # 5
            'sextus',     # 6
            'septimus',   # 7
            'octavus',    # 8
            'nonus',      # 9
            'decimus',    # 10
            'undecimus',  # 11
            'duodecimus', # 12
            'tertius decimus',  # 13
            'quartus decimus',  # 14
            'quintus decimus',  # 15
            'sextus decimus',   # 16
            'septimus decimus', # 17
            'duodevicesimus',   # 18
            'undevicesimus',    # 19
           );

my @tens = (undef, # 0
            'decimus', # 10
            'vicesimus', # 20
            'tricesimus',
            'quadragesimus',
            'quinquagesimus',
            'sexagesimus',
            'septuagesimus',
            'octogesimus',
            'nonagesimus',
           );

my @hundreds = (undef,           # 0
                'centesimus',    # 100
                'ducentesimus',  # 200
                'trecentesimus',  # 300
                'quadringentesimus', # 400
                'quingentesimus',    # 500
                'sescentesimus',     # 600
                'septingentesimus',  # 700
                'octingentesimus',   # 800
                'nongentesimus',     # 900
               );

my @thousands = (undef,           # 0
                 'millesimus',
                 'bis millesimus');

my $gender = 'f';
sub ordinal {
  my ($n) = @_;
  ### ordinal(): $n
  my @ret;
  if ($n < @ones) {
    push @ret, $ones[$n];
  } else {
    my $h = $n % 100;
    if ($h < @ones) {
      if ($h) {
        push @ret, $ones[$h];
      }
    } else {
      push @ret, $ones[$h%10];
      push @ret, $tens[int($h/10)];
    }
    $n = int ($n / 100);
    if (my $h = $n%10) {
      push @ret, $hundreds[$h];
    }
    if ($n = int ($n / 10)) {
      push @ret, $thousands[$n];
    }
  }
  ### @ret
  if ($gender eq 'f') {
    foreach (@ret) {s/us( |$)/a/g}
  } elsif ($gender eq 'm') {
    foreach (@ret) {s/us( |$)/um/g}
  }
  return join(' ', @ret);
}



{
  # 19 undevicesima or nona decima
  my $aronson = Math::Aronson->new (lang => 'la',
                                    initial_string => "T est",
                                    comma => ' et ',
                                    ordinal_func => sub {
                                      my ($n) = @_;
                                      return ordinal($n) . ' et ';
                                    },
                                   );
  my @want = (1, 4, 11, 16, 19, 29, 33, 42, 56, 70, 71, 74, 77, 87, 105,
              109, 121, 128, 132, 142, 151, 161, 166, 171, 181, 185, 192,
              202, 207, 212, 219, 227, 234, 251, 258, 261, 276, 283, 291,
              313, 320, 343, 350, 366, 375, 382, 401, 408, 412, 427, 434,
              443, 455, 462 );
  my @got = map {$aronson->next} 1 .. @want;
  require Test::More;
  Test::More::plan (tests => 1);
  Test::More::is_deeply(\@got,\@want);
  exit 0;

  ### $aronson
  $| = 1;
  foreach (1 .. 50) {
    print $aronson->next//last, ",";
  }
  exit 0;
}

{
  my $aronson = Math::Aronson->new (lang => 'la',
                                    initial_string => "P est",
                                    ordinal_func => sub {
                                      my ($n) = @_;
                                      return ordinal($n) . ' praeterea ';
                                    },
                                   );
  my @want = (1, 5, 10, 25, 40, 63, 84, 110, 135, 159, 192, 230, 265, 294,
              330, 366, 397, 434, 455, 483, 523, 557, 598, 634, 645, 679,
              717, 753, 795, 810, 832, 842, 856, 868, 898, 911, 938 );
  my @got = map {$aronson->next} 1 .. @want;
  require Test::More;
  Test::More::plan (tests => 1);
  Test::More::is_deeply(\@got,\@want);
  exit 0;

  ### $aronson
  $| = 1;
  foreach (1 .. 50) {
    print $aronson->next//last, ",";
  }
  exit 0;
}

{
  # N est
  my $aronson = Math::Aronson->new (lang => 'la',
                                    initial_string => "N est",
                                    ordinal_func => sub {
                                      my ($n) = @_;
                                      return ordinal($n) . ' littera in hic sententiam, ';
                                    },
                                   );

  my @want = (1, 18, 24, 27, 53, 59, 62, 95, 98, 126, 132, 135, 149, 155,
              170, 176, 184, 186, 191, 197, 212, 218, 221, 230, 251, 257,
              260, 268, 271, 273, 289, 295, 298, 309, 311, 327, 333, 336,
              356, 371, 377, 380, 389, 403, 418, 424, 427, 435, 449, 464,
              470, 473, 478, 480);
  my @got = map {$aronson->next} 1 .. @want;
  require Test::More;
  Test::More::plan (tests => 1);
  Test::More::is_deeply(\@got,\@want);
  exit 0;

  ### $aronson
  $| = 1;
  foreach (1 .. 50) {
    print $aronson->next//last, ",";
  }
  exit 0;
}


{
  foreach my $i (0 .. 45, 99 .. 101, 119 .. 122, 998 .. 1002, 1998 .. 2002) {
    print "$i ",ordinal($i),"\n";
  }
  exit 0;
}
exit 0;

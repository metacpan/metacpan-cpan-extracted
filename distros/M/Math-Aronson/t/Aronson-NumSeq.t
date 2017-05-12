#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

# This file is part of Math-Aronson.
#
# Math-Aronson is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Aronson is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Aronson.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Test;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

my $test_count = (tests => 28)[1];
plan tests => $test_count;

if (! eval { require Module::Util; 1 }) {
  my $err = $@;
  foreach (1 .. $test_count) {
    skip ("due to no Module::Util -- $err", 1, 1);
  }
  exit 0;
}

if (! Module::Util::find_installed('Math::NumSeq')) {
  foreach (1 .. $test_count) {
    skip ("due to no Math::NumSeq", 1, 1);
  }
  exit 0;
}

require Math::NumSeq::Aronson;

sub numeq_array {
  my ($a1, $a2) = @_;
  while (@$a1 && @$a2) {
    unless ((! defined $a1->[0] && ! defined $a2->[0])
            || (defined $a1->[0]
                && defined $a2->[0]
                && $a1->[0] == $a2->[0])) {
      return 0;
    }
    shift @$a1;
    shift @$a2;
  }
  return (@$a1 == @$a2);
}


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 9;
  ok ($Math::NumSeq::Aronson::VERSION, $want_version, 'VERSION variable');
  ok (Math::NumSeq::Aronson->VERSION,  $want_version, 'VERSION class method');

  ok (eval { Math::NumSeq::Aronson->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::Aronson->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------

foreach my $elem (
                  [ "default is en (with conjunctions)",
                    { },
                    [ 1, 4, 11, 16, 24, 29, 33 ] ],

                  [ "lang=undef is en",
                    { lang => undef },
                    [ 1, 4, 11, 16, 24, 29, 33 ] ],

                  [ "explicit letter=T",
                    { letter => 'T' },
                    [ 1, 4, 11, 16, 24, 29, 33 ] ],

                  [ "letter=F",
                    { letter => 'F' },
                    [ 1, 7 ] ],

                  [ "letter=H",
                    { letter => 'H' },
                    # H is the first, fifth, sixteenth
                    # 1 23 456 78901  23456  789012345
                    # ^     ^             ^
                    [ 1, 5, 16, 25 ] ],

                  [ "lang=en conjunctions=1",
                    { lang => 'en',
                      conjunctions => 1 },
                    [ 1, 4, 11, 16, 24, 29, 33, 35, 39, 45, 47, 51, 56, 58,
                      62, 64, 69, 73, 78, 80, 84, 89, 94, 99, 104, 111,
                      116, 122, 126, 131, 136, 142, 147, 158, 164, 169,
                      174, 181, 183, 193, 199, 205, 208, 214, 220, 226,
                      231, 237, 243, 249, 254, 273, 294, 312, 316, 331,
                      335, 356 ] ],

                  # English T
                  [ "lang=en, conjunctions=0",
                    { lang => 'en', conjunctions => 0 },
                    [ 1, 4, 11, 16, 24, 29, 33, 35, 39, 45, 47, 51, 56, 58,
                      62, 64, 69, 73, 78, 80, 84, 89, 94, 99, 104, 111,
                      116, 122, 126, 131, 136, 142, 147, 158, 164, 169,
                      174, 181, 183, 193, 199, 205, 208, 214, 220, 226,
                      231, 237, 243, 249, 254, 270, 288, 303, 307, 319,
                      323, 341 ],
                    'A005224' ],

                  [ "lang=en, letter=H, conjunctions=0",
                    { lang => 'en',
                      conjunctions => 0,
                      letter => 'H' },
                    [ 1, 5, 16, 25, 36, 38, 47, 49, 57, 59, 71, 81, 93, 103,
                      119, 134, 141, 149, 156, 172, 176, 184, 194, 198, 218,
                      234, 238, 254, 258, 281, 299, 303, 313, 321, 325, 343,
                      347, 363, 365, 369, 379, 385, 389, 397, 407, 411, 419,
                      427, 429, 433, 450, 454, 469, 471, 475 ],
                    'A055508' ],

                  # English I
                  [ "en, letter=I, conjunctions=0",
                    { lang => 'en',
                      conjunctions => 0,
                      letter => 'I' },
                    [ 1, 2, 8, 19, 25, 41, 51, 56, 61, 66, 71, 76, 81, 86,
                      91, 103, 115, 120, 126, 131, 137, 142, 148, 164, 178,
                      201, 222, 238, 243, 259, 307, 323, 351, 367, 405, 410,
                      432, 446, 451, 494, 510, 515, 532, 555, 588, 615, 631,
                      636, 652, 664, 680, 691, 700, 712, 723, 734 ],
                    'A049525' ],

                  [ "lying",
                    { lying => 1 },
                    # t is the second, third, fifth,
                    #             1             2
                    #   23  56 789012   4567  890 2
                    #
                    [ 2,3,
                      5,6,
                      7,8,9,10,11,12,
                      14,15,16,17,
                      18,19,20,22,
                    ] ],

                  # lying "T is the"
                  [ "lying",
                    { lying => 1,
                      conjunctions => 0 },
                    [ 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 14, 15, 16, 17, 18,
                      19, 20, 22, 23, 24, 25, 27, 28, 29, 30, 31, 32, 34,
                      35, 36, 37, 38, 40, 41, 42, 43, 45, 47, 48, 50, 51,
                      52, 53, 54, 55, 56, 58, 60, 61, 62, 63, 65, 66, 67,
                      68, 69, 71, 72, 73, 75 ],
                    'A081023' ],

                  # no initial_string option yet
                  #
                  # [ "lying S ain't the",
                  #   { lying => 1,
                  #     initial_string => "S ain't the",
                  #     conjunctions => 0  },
                  #   [ 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 14, 15, 16, 17,
                  #     18, 19, 20, 21, 22, 23, 24, 25,
                  #   ],
                  #   'A072886' ],

                  # complement ...
                  # http://www.research.att.com/~njas/sequences/A072887
                  # http://www.research.att.com/~njas/sequences/A081024

                  # French with conjunctions
                  # http://www.research.att.com/%7Enjas/sequences/A080520
                  [ "fr",
                    { lang => 'fr' },
                    [ 1, 2, 9, 12, 14, 16, 20, 22, 24, 28, 30, 36, 38, 47,
                      49, 51, 55, 57, 64, 66, 73, 77, 79, 91, 93, 104, 106,
                      109, 113, 115, 118, 121, 126, 128, 131, 134, 140, 142,
                      150, 152, 156, 158, 166, 168, 172, 174, 183, 184, 189,
                      191, 200, 207, 209, 218, 220, 224, 226, 234, 241 ],
                    'A080520' ],
                 ) {
  my ($name, $options, $want, $want_anum) = @$elem;
  my $seq = Math::NumSeq::Aronson->new (%$options);

  my $got_anum = $seq->oeis_anum;
  ok ($got_anum, $want_anum, "$name -- oeis_anum()");

  my @got = map {scalar($seq->next)} 1 .. @$want;
  my $eq = numeq_array(\@got, $want);
  ok ($eq, 1, $name);
  if (! $eq) {
    MyTestHelpers::dump(\@got);
    MyTestHelpers::dump($want);
  }
}

exit 0;

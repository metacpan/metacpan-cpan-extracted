#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Math-Polynomial-Horner.
#
# Math-Polynomial-Horner is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Math-Polynomial-Horner is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Polynomial-Horner.  If not, see <http://www.gnu.org/licenses/>.


use 5.006;
use strict;
use warnings;
use Test::More tests => 168;
use Math::Polynomial;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

require Math::Polynomial::Horner;

# Math::Polynomial->string_config ({ times => '*',
#                                    leading_minus => '-',
#                                    ascending => 0,
#                                  });

my @my_configs = (prefix        => '<',
                  suffix        => '>',
                  times         => '&',
                  plus          => ' p ',
                  minus         => ' m ',
                  leading_minus => 'lminus',
                  leading_plus  => 'lplus',
                  left_paren    => '{',
                  right_paren   => '}',
                 );

sub same {
  my ($config, $name, $poly) = @_;
  $poly->string_config ($config);
  my $want = "$poly";
  my $got = Math::Polynomial::Horner::as_string($poly);
  is ($got, $want, "vs stringize: $name");
}

foreach my $fold_one (0, 1) {
  foreach my $fold_sign (0, 1) {
    my $config = { @my_configs,
                   fold_one => $fold_one,
                   fold_sign => $fold_sign };

    same ($config, 'empty',
          Math::Polynomial->new());

    foreach my $constant (9, 1, -1, -9) {
      same ($config, "constant $constant",
            Math::Polynomial->new($constant));
    }

    foreach my $constant (9, 1, 0 -1, -9) {
      foreach my $high (9, 1, -1, -9) {
        same ($config, "constant $constant high $high",
              Math::Polynomial->new($constant,$high));
      }
    }
  }
}


foreach my $elem
  (
   #
   # empty
   #
   [ [], '<lplus0>' ],
   [ [], '<lplus0>',
     { ascending => 1 } ],

   #
   # leading plus
   #
   [ [5], '<lplus5>',
     { fold_sign => 0 } ],
   [ [5], '<lplus5>',
     { fold_sign => 1 } ],

   [ [5], '<lplus5>',
     { fold_sign => 0, ascending => 1 } ],
   [ [5], '<lplus5>',
     { fold_sign => 1, ascending => 1 } ],

   [ [5], 'lplus5',
     { fold_sign => 1,
       prefix => '', suffix => '' } ],

   [ [5], '<lplus5>',
     { fold_sign => 1, ascending => 1 } ],

   [ [1], '<lplus1>',
     { fold_sign => 0 } ],
   [ [1], '<lplus1>',
     { fold_sign => 1 } ],

   [ [1], 'lplus1',
     { prefix => '', suffix => '',
       fold_sign => 1 } ],

   #
   # leading minus
   #
   [ [-5], '<lplus-5>',
     { fold_sign => 0 } ],
   [ [-5], '<lminus5>',
     { fold_sign => 1 } ],

   [ [-5], 'lminus5',
     { prefix => '', suffix => '',
       fold_sign => 1 } ],

   [ [-5], '<lminus5>',
     { fold_sign => 1, ascending => 1 } ],

   #
   # solitary power +9
   #
   [ [0,0,0,0,9], '<lplus9&x^4>',
     { fold_sign => 0 } ],

   [ [0,0,0,0,9], '<lplus9&x^4>',
     { fold_sign => 1 } ],

   [ [0,0,0,0,9], '<x^4&9>',
     { ascending => 1,
       fold_sign => 0 } ],

   [ [0,0,0,0,9], '<x^4&9>',
     { ascending => 1,
       fold_sign => 1 } ],

   #
   # solitary power +1
   #
   [ [0,0,0,0,1], '<lplusx^4>',
     { fold_sign => 1, fold_one => 1 } ],

   [ [0,0,0,0,1], '<lplus1&x^4>',
     { fold_sign => 1, fold_one => 0 } ],

   [ [0,0,0,0,1], '<lplusx^4>',
     { fold_sign => 0, fold_one => 1 } ],

   [ [0,0,0,0,1], '<lplus1&x^4>',
     { fold_sign => 0, fold_one => 0 } ],

   [ [0,0,0,0,1], '<x^4>',
     { ascending => 1,
       fold_sign => 0, fold_one => 1 } ],

   [ [0,0,0,0,1], '<x^4&1>',
     { ascending => 1,
       fold_sign => 0, fold_one => 0 } ],

   #
   # solitary power -9
   #
   [ [0,0,0,0,-9], '<lplus-9&x^4>',
     { fold_sign => 0 } ],
   [ [0,0,0,0,-9], '<lminus9&x^4>',
     { fold_sign => 1 }],

   [ [0,0,0,0,-9], '<x^4&-9>',
     { ascending => 1,
       fold_sign => 0 } ],

   # FIXME: is this what's wanted?
   [ [0,0,0,0,-9], '<x^4&-9>',
     { ascending => 1,
       fold_sign => 1 } ],

   #
   # solitary power -1
   #
   [ [0,0,0,0,-1], '<lminus1&x^4>',
     { fold_sign => 1, fold_one => 0 } ],

   [ [0,0,0,0,-1], '<lminusx^4>',
     { fold_sign => 1, fold_one => 1 } ],

   [ [0,0,0,0,-1], '<lplus-1&x^4>',
     { fold_sign => 0, fold_one => 0 } ],

   [ [0,0,0,0,-1], '<lplus-1&x^4>',
     { fold_sign => 0, fold_one => 1 } ],

   [ [0,0,0,0,-1], '<x^4&-1>',
     { ascending => 1,
       fold_sign => 0, fold_one => 0 } ],

   [ [0,0,0,0,-1], '<x^4&-1>',
     { ascending => 1,
       fold_sign => 1, fold_one => 0 } ],

   # FIXME: is this what's wanted? high -1 unfolded
   [ [0,0,0,0,-1], '<x^4&-1>',
     { ascending => 1,
       fold_sign => 0, fold_one => 1 } ],

   [ [0,0,0,0,-1], '<x^4&-1>',
     { ascending => 1,
       fold_sign => 1, fold_one => 1 } ],

   #
   # descending, two terms
   #
   [ [9,8], '<lplus8&x p 9>' ],

   #
   # descending, three terms
   #
   [ [9,8,7], '<{lplus7&x p 8}&x p 9>' ],

   #
   # ascending, two terms
   #
   [ [9,8], '<lplus9 p x&8>',
     { ascending => 1 } ],

   #
   # ascending, three terms
   #
   [ [9,8,7], '<lplus9 p x&{lplus8 p x&7}>',
     { ascending => 1 }  ],

   #
   # ascending, four terms
   #
   [ [9,8,7,6], '<lplus9 p x&{lplus8 p x&{lplus7 p x&6}}>',
     { ascending => 1 }  ],

   #
   # ascending, fold_sign on last coeff
   #
   [ [5,-2], '<lplus5 p x&-2>',   # plain
     { ascending => 1 } ],

   [ [5,-2], '<lplus5 m x&2>',    # folded as 'minus'
     { ascending => 1,
       fold_sign => 1 } ],

   [ [5,0,-2], '<lplus5 m x^2&2>',
     { ascending => 1, fold_sign => 1 } ],

   [ [5,0,-2], '<lplus5 p x^2&-2>',
     { ascending => 1 } ],

   #
   # descending, fold_sign
   #
   [ [-7,0,0,0,-8], '<lplus-8&x^4 p -7>',
     { fold_sign => 0 } ],

   [ [-7,0,0,0,-8], '<lminus8&x^4 m 7>',
     { fold_sign => 1 } ],

   [ [-7,0,0,0,-8], '<lplus-8&x&x&x&x p -7>',
     { power_by_times_upto => 999, fold_one => 0 } ],

   [ [-7,0,0,0,-8], '<lminus8&x&x&x&x m 7>',
     { power_by_times_upto => 999, fold_sign => 1 } ],

   #
   # descending, high coeff fold_one
   #
   [ [1,0,0,0,1], '<lplus1&x^4 p 1>',
     { fold_one => 0 } ],

   [ [1,0,0,0,1], '<lplusx^4 p 1>',
     { fold_one => 1 } ],

   [ [1,0,0,0,1], '<lplus1&x&x&x&x p 1>',
     { power_by_times_upto => 999, fold_one => 0 } ],

   [ [1,0,0,0,1], '<lplusx&x&x&x p 1>',
     { power_by_times_upto => 999, fold_one => 1 } ],

   #
   # descending, high coeff fold_one and fold_sign
   #
   [ [7,0,0,0,-1], '<lminusx^4 p 7>',
     { fold_one => 1, fold_sign => 1 } ],

   [ [7,0,0,0,-1], '<lminusx&x&x&x p 7>',
     { power_by_times_upto => 999, fold_one => 1, fold_sign => 1 } ],

   #
   # descending, fold_sign_swap_end
   #
   [ [7,0,0,0,-5], '<lplus7 m 5&x^4>',
     { fold_one => 1, fold_sign => 1, fold_sign_swap_end => 1 } ],

   [ [7,0,0,6,-5], '<{lplus6 m 5&x}&x^3 p 7>',
     { fold_one => 1, fold_sign => 1, fold_sign_swap_end => 1 } ],

   #
   # ascending, fold_sign_swap_end
   #
   [ [-7,0,0,0,5], '<lplus5&x^4 m 7>',
     { ascending => 1,
       fold_sign => 1, fold_sign_swap_end => 1 } ],

   [ [7,0,0,-6,5], '<lplus7 p x^3&{lplus5&x m 6}>',
     { ascending => 1,
       fold_sign => 1, fold_sign_swap_end => 1 } ],

   #
   #

   [ [0,0,0,1,1], '<{lplusx p 1}&x^3>',
     {  } ],
   [ [0,0,0,1,1], '<{lplusx p 1}&x&x&x>',
     { power_by_times_upto => 999 } ],


   [ [5,-2], '<lminus2&x p 5>',
     { fold_sign => 1 } ],

   [ [-5,-2], '<lminus2&x m 5>',
     { fold_sign => 1 } ],

   [ [1,0,0,0,1], '<lplusx^4 p 1>',
     { } ],
   [ [1,0,0,0,1], '<lplusx&x&x&x p 1>',
     { power_by_times_upto => 999 } ],
   [ [1,0,0,0,1], '<lplus1 p x^4>',
     { ascending => 1 } ],
   [ [1,0,0,0,1], '<lplus1 p x&x&x&x>',
     { power_by_times_upto => 999,
       ascending => 1  } ],

   [ [-1,0,0,0,-1], '<lplus-1 p x^4&-1>',
     { ascending => 1,
       fold_one => 0 } ],
   [ [-1,0,0,0,-1], '<lplus-1 p x^4&-1>',
     { ascending => 1 } ],
   [ [-1,0,0,0,-1], '<lplus-1 p x&x&x&x&-1>',
     { power_by_times_upto => 999,
       ascending => 1  } ],
   [ [-1,0,0,0,-1], '<lplus-1 p x&x&x&x&-1>',
     { power_by_times_upto => 999,
       ascending => 1,
       fold_one => 1  } ],

   [ [0,0,0,1,1], '<x^3&{lplus1 p x}>',
     { ascending => 1 } ],
   [ [0,0,0,1,1], '<x&x&x&{lplus1 p x}>',
     { power_by_times_upto => 999,
       ascending => 1  } ],

   [ [0,0,0,1,1], '<{{{lplusx p 1}&x p 0}&x p 0}&x p 0>',
     { fold_zero => 0 } ],

   [ [3,2,1], '<{lplusx p 2}&x p 3>',
     { fold_one => 1 } ],

   [ [3,2,-1], '<{lplus-1&x p 2}&x p 3>',
     { fold_one => 0 } ],
   [ [3,2,-1], '<{lminusx p 2}&x p 3>',
     { fold_sign => 1} ],

   [ [3,2], '<lplus3 p x&2>',
     { ascending => 1 } ],

   [ [4,3,2], '<lplus4 p x&{lplus3 p x&2}>',
     { ascending => 1 } ],

   [ [0,3,2], '<{lplus2&x p 3}&x>' ],
   [ [0,3,2], '<{lplus2&x p 3}&x p 0>',
     { fold_zero => 0 } ],
   [ [0,3,2], '<{lplus2&x p 3}&x>',
     { fold_zero => 1 }],

   [ [0,0,3,2], '<{lplus2&x p 3}&x^2>',
     { fold_zero => 1 }],

  ) {
  my ($coeffs, $want, $configs) = @$elem;
  my $poly = Math::Polynomial->new(@$coeffs);
  $configs ||= {};

  my $name = "$poly  coeffs=[";
  foreach my $coeff (@$coeffs) {
    $name .= "$coeff,";
  }
  $name .= "] configs { ";
  foreach my $key (sort keys %$configs) {
    $name .= "$key=>$configs->{$key}, ";
  }
  $name .= "}";

  $configs = { @my_configs,
               %$configs };
  $poly->string_config ($configs);
  my $got = Math::Polynomial::Horner::as_string($poly);

  is ($got, $want, $name);
}

# foreach my $poly (Math::Polynomial->new(),
#                   Math::Polynomial->new(1),
#                   Math::Polynomial->new(-1),
#                   Math::Polynomial->new(1,0),
#                   Math::Polynomial->new(-1,0),
#                   Math::Polynomial->new(-1,0,1),
#                   Math::Polynomial->new(123,0,-456),
#                   Math::Polynomial->new(-1,-1,-456),
#                   Math::Polynomial->new(1,1,1,1,1),
#                   Math::Polynomial->new(1,1,1,1,0),
#                   Math::Polynomial->new(1,1,1,0,0),
#                   Math::Polynomial->new(0,1,1,1,0,0,9)) {
#   say Math::Polynomial::Horner::as_string($poly);
# }

exit 0;


#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

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
use Math::BigRat;
use Math::Polynomial 1;
use Math::Polynomial::Horner;

#use Devel::Comments;

my_interpolate ([  0,   1,   2,   3,    4  ],
                [ 0-0.5, 1-0.5, 4-0.5, 9-0.5, 16-0.5 ]
               );
# my_interpolate ([  1,  2,  3 ],
#                 [  2,  9, 21 ]
#                 );
# my_interpolate ([  reverse 0,1,2,3,4,5 ],
#                 [  map {$_-16} 0,5,9,12,14,15         ]
#                );
exit 0;



# [1,2,3,4],[1+4,12+4+8,35+4+8+8,70+4+8+8+8]
# # step==0
# my_interpolate ([  0,   1,   2,   3,   4 ],
#                 [0.5, 0.5, 0.5, 0.5, 0.5 ]);
# # step==1
# #  7 8 9 10
# #  4 5 6
# #  2 3
# #  1
# my_interpolate ([  0,   1,   2,   3 ],
#                 [0.5, 1.5, 3.5, 6.5 ]);
# # step==2
# my_interpolate ([  0,   1,   2,   3 ],
#                 [0.5, 1.5, 4.5, 9.5 ]);
# # step==3
# my_interpolate ([  0,   1,   2,   3 ],
#                 [0.5, 1.5, 5.5, 12.5 ]);
# # step==4
# my_interpolate ([  0,   1,   2,   3 ],
#                 [0.5, 1.5, 6.5, 15.5 ]);


# my_interpolate ([ 2,   3,  4,  5,   6,   7,   8,   9, 10 ],
#                 [ 9, 25, 49, 81, 121, 169, 225, 289, 361 ]
#                );
exit 0;

# N = a*s^2 + b*s + c
#   = a * (s^2 + b/a s + c/a)
#
# N/a = (s + b/2a)^2 - b^2/4a^2 + c/a
# (s + b/2a)^2 = N/a + b^2/4a^2 - c/a
# s+ b/2a = sqrt(4aN/4a^2 + b^2/4a^2 - 4ac/4a^2)
#         = 1/2a * sqrt(4aN + b^2 - 4ac)
#
#      -b + sqrt(4aN + b2 - 4ac)
# s =  ------------------------
#               2a
#




my_interpolate (
                [ 1,  2,    3,       4, 5],
                [ map {3*$_} 1,1+4,1+4+9,1+4+9+16,1+4+9+16+25 ],
               );

sub bigrat_to_decimal {
  my ($rat) = @_;
  if (is_pow2($rat->denominator)) {
    return $rat->as_float;
  } else {
    return $rat;
  }
}
sub is_pow2 {
  my ($n) = @_;
  while ($n > 1) {
    if ($n & 1) {
      return 0;
    }
    $n >>= 1;
  }
  return ($n == 1);
}

use constant my_string_config => (variable     => '$d',
                                  times       => '*',
                                  power       => '**',
                                  fold_one    => 1,
                                  fold_sign   => 1,
                                  fold_sign_swap_end => 1,
                                  power_by_times     => 1,
                                 );

#  @string_config = (
# #                      power       => '**',
# #                      fold_one    => 1,
# #                      fold_sign   => 1,
# #                      fold_sign_swap_end => 1,
# #                      power_by_times     => 1,
#                     );
sub my_interpolate {
  my ($xarray, $valarray) = @_;

  my $zero = 0;

  $zero = Math::BigRat->new(0);
  $xarray   = [ map {Math::BigRat->new($_)} @$xarray ];
  $valarray = [ map {Math::BigRat->new($_)} @$valarray ];

  my $p = Math::Polynomial->new($zero);
  $p = $p->interpolate($xarray, $valarray);

  $p->string_config({ fold_sign => 1,
                      variable  => 'd' });
  print "N = $p\n";

  $p->string_config({ my_string_config() });
  print "  = $p\n";

  $p->string_config({ my_string_config(),
                      #  convert_coeff  => \&bigrat_to_decimal,
                    });
  print "  = ",Math::Polynomial::Horner::as_string($p),"\n";

  my $a = $p->coeff(2);
  return if $a == 0;
  my $b = $p->coeff(1);
  my $c = $p->coeff(0);

  my $x = -$b/(2*$a);
  my $y = 4*$a / ((2*$a) ** 2);
  my $z = ($b*$b-4*$a*$c) / ((2*$a) ** 2);
  print "d = $x + sqrt($y * \$n + $z)\n";

  #   return;

  my $s_to_n = sub {
    my ($s) = @_;
    return $p->evaluate($s);
  };

  if (ref $x) {
    $x = $x->numify;
    $y = $y->numify;
    $z = $z->numify;
  }
  my $n_to_d = sub {
    my ($n) = @_;
    my $root = $y * $n + $z;
    if ($root < 0) {
      return 'neg sqrt';
    }
    return ($x + sqrt($root));
  };
  # for (my $i = 0; $i < 100; $i += 0.5) {
  #   printf "%4s  d=%s\n", $i, $n_to_d->($i);
  # }
  exit 0;
}
# {
#   package Math::Polynomial;
#   sub interpolate {
#     my ($this, $xvalues, $yvalues) = @_;
#     if (
#         !ref($xvalues) || !ref($yvalues) || @{$xvalues} != @{$yvalues}
#        ) {
#       croak 'usage: $q = $p->interpolate([$x1, $x2, ...], [$y1, $y2, ...])';
#     }
#     return $this->new if !@{$xvalues};
#     my @alpha  = @{$yvalues};
#     my $result = $this->new($alpha[0]);
#     my $aux    = $result->monomial(0);
#     my $zero   = $result->coeff_zero;
#     for (my $k=1; $k<=$#alpha; ++$k) {
#       for (my $j=$#alpha; $j>=$k; --$j) {
#         my $dx = $xvalues->[$j] - $xvalues->[$j-$k];
#         croak 'x values not disjoint' if $zero == $dx;
#         ### dx: "$dx",ref $dx
#         $alpha[$j] = ($alpha[$j] - $alpha[$j-1]) / $dx;
#       }
#       $aux = $aux->mul_root($xvalues->[$k-1]);
#       $result += $aux->mul_const($alpha[$k]);
#     ### alpha: join(' ',map{"$_"}@alpha)
#     }
#     return $result;
#   }
# }



{
  my $f1 = 1.5;
  my $f2 = 4.5;
  my $f3 = 9.5;
  my $f4 = 16.5;

  foreach ($f1, $f2, $f3, $f4) {
    $_ = Math::BigRat->new($_);
  }

  my $a = $f4/2 - $f3 + $f2/2;
  my $b = $f4*-5/2 + $f3*6 - $f2*7/2;
  my $c = $f4*3 - $f3*8 + $f2*6;

  print "$a\n";
  print "$b\n";
  print "$c\n";

  print "$a*\$s*\$s + $b*\$s + $c\n";
  exit 0;
}

{
  my $subr = sub {
    my ($s) = @_;
     return 3*$s*$s - 4*$s + 2;
    # return 2*$s*$s - 2*$s + 2;
    # return $s*$s + .5;
    # return $s*$s - $s + 1;
    # return $s*($s+1)*.5 + 0.5;
  };
  my $back = sub {
    my ($n) = @_;
    return (2 + sqrt(3*$n - 2)) / 3;
    # return .5 + sqrt(.5*$n-.75);
    # return sqrt ($n - .5);
    # return -.5 + sqrt(2*$n - .75);
    #    return int((sqrt(4*$n-1) - 1) / 2);
  };

  my $prev = 0;
  foreach (1..15) {
    my $this = $subr->($_);
    printf("%2d  %.2f  %.2f  %.2f\n", $_, $this, $this-$prev,$back->($this));
    $prev = $this;
  }
  for (my $n = 1; $n < 23; $n++) {
    printf "%.2f  %.2f\n", $n,$back->($n);
  }
  exit 0;
}

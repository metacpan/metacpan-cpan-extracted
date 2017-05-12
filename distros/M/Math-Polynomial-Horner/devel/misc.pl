#!/usr/bin/perl

# Copyright 2010 Kevin Ryde

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

use 5.010;
use strict;
use warnings;
use Math::Polynomial;

{
  sub upwards {
    my ($x) = @_;
    return (((($x + 1)*$x + 1)*$x + 1)*$x + 1);
  }
  sub downwards {
    my ($x) = @_;
    return (1 + $x*(1 + $x*(1 + $x*(1 + $x))));
  }
  sub pluseq {
    my ($x) = @_;
    my $ret = $x;
    $ret += 1;
    $ret *= $x;
    $ret += 1;
    $ret *= $x;
    $ret += 1;
    $ret *= $x;
    $ret += 1;
    return $ret;
  }
  sub swapend {
    my ($x) = @_;
    return (-$x**2+1);
  }

  require B::Concise;
  B::Concise::compile('-exec',\&upwards)->();
  B::Concise::compile('-exec',\&downwards)->();
  B::Concise::compile('-exec',\&pluseq)->();
  B::Concise::compile('-exec',\&swapend)->();
  exit 0;
}

{
  require Math::BigRat;
  my $p = Math::Polynomial->new(Math::BigRat->new(0));
  $p = $p->interpolate([ 4,5,6,7 ], [25,39,56,76]);
  $p->string_config
    ({variable    => '$d', ## no critic (RequireInterpolationOfMetachars)
      times       => '*',
      power       => '**',
      fold_one    => 1,
      fold_sign   => 1});
  say $p->as_string();      # '(2 x^3 - 3 x)'

  # $p = Math::Polynomial->new(Math::BigRat->new(-1),
  #                            Math::BigRat->new(1/2),
  #                            Math::BigRat->new(3/2));
  # say $p->as_string({fold_sign => 1});      # '(2 x^3 - 3 x)'
  exit 0;
}


{
  Math::Polynomial->string_config ({ fold_sign => 1,
                                   leading_plus => 'lplus',
                                   leading_minus => 'lminus',
                                   });
  say Math::Polynomial->new(-1);
  say Math::Polynomial->new(1,1);

  #   Math::Polynomial->new(1,0),
  #       Math::Polynomial->new(-1,0),
  #           Math::Polynomial->new(-1,0,1),
  #               Math::Polynomial->new(123,0,-456),
  #                   Math::Polynomial->new(-1,-1,-456),
  #                       Math::Polynomial->new(1,1,1,1,1),
  #                           Math::Polynomial->new(1,1,1,1,0),
  #                               Math::Polynomial->new(1,1,1,0,0),
  #                                   Math::Polynomial->new(0,1,1,1,0,0,9)) {
  #   say Math::Polynomial::Horner::to_string($poly);
  exit 0;
}

# Math::Polynomial::Horner


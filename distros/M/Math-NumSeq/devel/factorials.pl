#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use Math::NumSeq::Factorials;

#use Smart::Comments;

{
  # Zeckendorf

  require Math::NumSeq::Catalan;
  require Math::NumSeq::Fibbinary;
  require Math::BigInt;
  my $seq = Math::NumSeq::Catalan->new;
  my $fib = Math::NumSeq::Fibbinary->new;
  foreach (1..29) {
    my ($i, $value) = $seq->next;
    $value = Math::BigInt->new($value);
    ### $value
    my $z = $fib->ith($value);
    $z = Math::BigInt->new($z);
    printf "%2d  %72s\n", $i, $z->as_bin;
  }
  exit 0;
}

{
  # value_to_i_estimate()

  require Math::NumSeq::Catalan;
  my $seq = Math::NumSeq::Catalan->new;
  my $prev_value = 0;
  foreach (1..18) {
    my ($i, $value_next) = $seq->next;
    my $value_ith = $seq->ith($i);
    print "$i $value_next $value_ith\n";
    my $eq = ($value_ith == $value_next);
    my $streq = ($value_ith eq $value_next);

    unless ($streq) {
      die "oops, not streq";
    }
    unless ($eq) {
  require Devel::Peek;
  print Devel::Peek::Dump($value_next);
  print Devel::Peek::Dump($value_ith);
      die "oops, not eq";
    }
  }
  exit 0;
}

{
  # value_to_i_estimate()

  my $seq = Math::NumSeq::Factorials->new;
  my $prev_value = 0;
  foreach (1..120) {
    my ($i, $value) = $seq->next;
    # print "$i $value\n";

    # foreach my $try_value ($prev_value+1 .. $value-1) {
    #   my $est_i = $seq->value_to_i_estimate($try_value);
    #   my $factor = $est_i / ($i||1);
    #   printf "x  est=%d   tvalue=%b  f=%.3f\n",
    #     $est_i, $try_value, $factor;
    # }

    {
      my $est_i = $seq->value_to_i_estimate($value);
      my $factor = $est_i / ($i||1);
      printf "i=%d est=%.2f    f=%.3f\n", $i, $est_i, $factor;
    }

    $prev_value = $value;
  }
  exit 0;
}


{
  sub f {
    my ($x) = @_;
    return $x*log($x)-$x;
  }
  sub fd {
    my ($x) = @_;
    return log($x);
  }
  foreach my $x (2 .. 10) {
    my $f = f($x);
    my $fd = fd($x);
    my $d = f($x+1) - f($x);
    printf "%.3f %.3f %.3f\n", $f, $fd, $d;
  }
  exit 0;
}

{
  {
    package Math::Symbolic::Custom::MySimplification;
    use base 'Math::Symbolic::Custom::Simplification';

    # use Math::Symbolic::Custom::Pattern;
    # my $formula = Math::Symbolic->parse_from_string("TREE_a * (TREE_b / TREE_c)");
    # my $pattern = Math::Symbolic::Custom::Pattern->new($formula);

    use Math::Symbolic::Custom::Transformation;
    my $trafo = Math::Symbolic::Custom::Transformation::Group->new
      (
       ',',
       # 'TREE_a * (TREE_b / TREE_c)' => '(TREE_a * TREE_b) / TREE_c',
       # 'TREE_a * (TREE_b + TREE_c)' => 'TREE_a * TREE_b + TREE_a * TREE_c',
       # '(TREE_b + TREE_c) * TREE_a' => 'TREE_b * TREE_a + TREE_c * TREE_a',
       #
       # # '(TREE_a / TREE_b) / TREE_c' => 'TREE_a / (TREE_b * TREE_c)',
       #
       # '(TREE_a / TREE_b) / (TREE_c / TREE_d)'
       # => '(TREE_a * TREE_d) / (TREE_b * TREE_c)',
       #
       # '1 - TREE_a / TREE_b' => '(TREE_b - TREE_a) / TREE_b',
       #
       # 'TREE_a / TREE_b + TREE_c' => '(TREE_a + TREE_b * TREE_c) / TREE_b',
       #
       # '(TREE_a / TREE_b) * TREE_c' => '(TREE_a * TREE_c) / TREE_b',
       #
       # 'TREE_a - (TREE_b + TREE_c)' => 'TREE_a - TREE_b - TREE_c',
       # '(TREE_a - TREE_b) - TREE_c' => 'TREE_a - TREE_b - TREE_c',
       #
       # # '(TREE_a * 1)' => 'TREE_a',
       # '(TREE_a * (1 / TREE_b))' => 'TREE_a / TREE_b',
       # '(TREE_a / (TREE_b * TREE_a))' => '1/TREE_b',
       # # '(VAR_a / ((TREE_b) * VAR_a))' => '1/TREE_b',
       # 'log(CONST_a,CONST_b)' => 'value{log(CONST_a,CONST_b)}',
       # '(CONST_a-CONST_b)' => 'value{(CONST_a-CONST_b)}',
       # 'log(CONST_a,e)' => 'value{log(CONST_a,2.71828182845905)}',
       # '1/CONST_a' => 'value{1/CONST_a}',
       # '(TREE_a-CONST_b)+CONST_c' => 'TREE_a + (CONST_c - CONST_b)',
       # 'log(e,e)' => '1',
       # # '(TREE_a)' => 'TREE_a',

      );

    sub simplify {
      my $tree = shift;
      ### simplify(): "$tree"

      for (;;) {
        my $new_tree = $trafo->apply_recursive($tree);
        if ($new_tree) {
          ### new_tree: "$new_tree"
          $tree = $new_tree;
        } else {
          ### no more ...
          return $tree;
        }
      }


      # if (my $m = $pattern->match($tree)) {
      #   $m = $m->{'trees'};
      #   ### trees: $m
      #   ### return: ($m->{'a'} * $m->{'b'}) / $m->{'c'}
      #   return ($m->{'a'} * $m->{'b'}) / $m->{'c'};
      # } else {
      #   ### no match
      #   return $tree;
      # }
    }
    __PACKAGE__->register();
  }

  require Math::Symbolic;
  my $tree = Math::Symbolic->parse_from_string('x*(log(e,x)-1) - 123');
  print "tree: $tree\n";

  require Math::Symbolic::Derivative;
  my $deriv = Math::Symbolic::Derivative::total_derivative($tree, 'x');
  print "deriv $deriv\n";
  $deriv = $deriv->simplify;
  print "deriv $deriv\n";

  exit 0;
}

{
  my $n = 20;
  my $est = $n*(log($n)-1);
  print "$est\n";
  my $exp = exp($est);
  printf "%.0f\n", $exp;
  print Math::NumSeq::Factorials->ith($n-1),"\n";
  exit 0;
}

{
  # Math::BigInt on $value%3==0
  require Math::BigInt;
  my $inf = Math::BigInt->binf;
  my $rem = $inf % 3;
  ### $rem
  exit 0;
}

{
  # value_to_i_estimate()

  my $seq = Math::NumSeq::Factorials->new;
  my $prev_value = 0;
  foreach (1..5600) {
    my ($i, $value) = $seq->next;

    # foreach my $try_value ($prev_value+1 .. $value-1) {
    #   my $est_i = $seq->value_to_i_estimate($try_value);
    #   if (ref $est_i) { $est_i = $est_i->numify }
    #   my $factor = $est_i / ($i||1);
    #   printf "x  est=%d   tvalue=%b  f=%.3f\n",
    #     $est_i, $try_value, $factor;
    # }

    {
      # require Math::BigInt;
      # $value = Math::BigInt->new($value);

      my $est_i = $seq->value_to_i_estimate($value);
      if (ref $est_i) { $est_i = $est_i->numify }
      my $factor = $est_i / ($i||1);
      printf "i=%d est=%d   value=%s  f=%.3f\n",
        $i, $est_i, $value, $factor;
    }

    $prev_value = $value;
  }
  exit 0;
}

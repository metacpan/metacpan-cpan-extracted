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

package Math::Polynomial::Horner;
use 5.006;
use strict;
use warnings;
use vars '$VERSION';

# uncomment this to run the ### lines
#use Smart::Comments;

$VERSION = 3;

sub _stringize {
  return "$_[0]";
}

use constant _config_defaults =>
  (ascending     => 0,
   with_variable => 1,
   fold_sign     => 0,
   fold_zero     => 1,
   fold_one      => 1,
   fold_exp_zero => 1,
   fold_exp_one  => 1,
   convert_coeff => \&_stringize,
   plus          => q{ + },
   minus         => q{ - },
   leading_plus  => q{},
   leading_minus => q{- },
   times         => q{ },
   power         => q{^},
   variable      => q{x},
   prefix        => q{(},
   suffix        => q{)},

   # extras
   left_paren    => '(',
   right_paren   => ')',

   # secret extras
   fold_sign_swap_end  => 0,
   power_by_times_upto => 0,
  );

use constant _config_perl =>
  (fold_sign           => 1,
   fold_sign_swap_end  => 1,
   leading_minus       => q{-},
   power               => q{**},
   power_by_times_upto => 3);

use constant _EMPTY  => 0;
use constant _FACTOR => 1;
use constant _SUM    => 2;

sub as_string {
  my ($poly, $string_config) = @_;
  my $degree = $poly->degree;
  ### $degree

  $string_config ||= ($poly->string_config
                      || (ref $poly)->string_config);
  my %config = do {
    (_config_defaults(),
     ($string_config->{'for_perl'} ? _config_perl() : ()),
     %$string_config)
  };

  if ($degree <= 0) {
    ### empty or constant
    return $poly->as_string(\%config);
  }

  my $zero = $poly->coeff_zero;
  my $one  = $poly->coeff_one;
  my $convert = $config{'convert_coeff'};
  my $ret = '';
  my $pre = '';
  my $post = '';
  my $last = _EMPTY;

  my $leading_const = sub {
    my ($coeff) = @_;
    ### leading_const: "$coeff"
    if ($config{'fold_sign'} && $coeff < $zero) {
      $ret .= $config{'leading_minus'};
      $coeff = -$coeff;
    } else {
      $ret .= $config{'leading_plus'};
    }
    $ret .= $convert->($coeff);
    $last = _FACTOR;
  };

  my $leading_factor = sub {
    my ($coeff) = @_;
    ### leading_factor: "$coeff"
    my $pm = '';
    if ($config{'fold_sign'} && $coeff < $zero) {
      $ret .= $config{'leading_minus'};
      $coeff = -$coeff;
    } else {
      $ret .= $config{'leading_plus'};
    }
    if ($config{'fold_one'} && $coeff == $one) {
      ### fold_one skip to ret: $ret
      $last = _EMPTY;
      return;
    }
    $ret .= $pm . $convert->($coeff);
    $last = _FACTOR;
    ### gives ret: $ret
  };

  my $times_coeff = sub {
    my ($coeff) = @_;
    ### times_coeff: "$coeff"
    if ($config{'fold_one'}
        && $coeff == $one) {
      ### fold_one skip
      return;
    }
    if ($last ne _EMPTY) {
      $ret .= $config{'times'};
    }
    $ret .= $convert->($coeff);
    $last = _FACTOR;
    ### times_coeff gives ret: $ret
  };

  my $plus_coeff = sub {
    my ($coeff) = @_;
    if ($config{'fold_sign'} && $coeff < $zero) {
      $ret .= $config{'minus'};
      $coeff = -$coeff;
    } else {
      $ret .= $config{'plus'};
    }
    $ret .= $convert->($coeff);
    $last = _SUM;
  };

  my $xpow = 0;
  my $show_xpow = sub {
    ### show_xpow: $xpow
    return if ($xpow == 0);
    $ret .= $config{'variable'};
    if ($xpow == 1 && $config{'fold_exp_one'}) {
      # x^1 -> x
    } elsif ($xpow <= $config{'power_by_times_upto'}) {
      # x*x*...*x
      $ret .= ($config{'times'} . $config{'variable'}) x ($xpow-1);
    } else {
      # x^123
      $ret .= $config{'power'} . $xpow;
    }
    $xpow = 0;
    $last = _FACTOR;
  };

  my $times_xpow = sub {
    ### times_xpow: $xpow, $ret
    if ($xpow) {
      if ($last eq _SUM) {
        $pre .= $config{'left_paren'};
        $ret .= $config{'right_paren'};
        $last = _FACTOR;
      }
      if ($last ne _EMPTY) {
        $ret .= $config{'times'};
      }
      $show_xpow->();
      $last = _FACTOR;
    }
    ### times_xpow gives: "pre=$pre ret=$ret"
  };

  if ($config{'ascending'}) {
    ### ascending

    my $limit = $degree;
    {
      my ($j, $high, $second);
      if ($config{'fold_sign'} && $config{'fold_sign_swap_end'}
          && ($high = $poly->coeff($degree)) > $zero
          && (($j,$second) = _second_highest_coeff($poly,$config{'fold_zero'}))
          && $second < $zero) {
        $leading_const->($high);
        $last = _FACTOR;

        $xpow = $degree - $j;
        $times_xpow->();

        $plus_coeff->($second);
        $limit = $j - 1;
        $post = $ret;
        if ($limit >= 0) {
          $post = $config{'times'}
            . $config{'left_paren'} . $post . $config{'right_paren'};
        }
        $ret = '';
        $last = _EMPTY;
        ### fold_sign_swap_end gives
        ### $post
        ### $limit
      }
    }

    $xpow = -1;
    foreach my $i (0 .. $limit) {
      ### $i
      $xpow++;
      my $coeff = $poly->coeff($i);
      if ($config{'fold_zero'} && $coeff == $zero) {
        next;
      }

      if ($xpow) {
        if (length($ret)) {
          if ($i == $degree
              && $config{'fold_sign'}
              && $coeff < $zero) {
            ### highest coeff fold ... + x*-5 -> ... - x*5
            $coeff = - $coeff;
            $ret .= $config{'minus'};
          } else {
            # other coeffs ... + x*(...) or highest ... + x*5
            $ret .= $config{'plus'};
          }
        }
        $show_xpow->();
        if ($i == $degree) {
          if ($config{'fold_one'}
              && $coeff == $one) {
            ### highest coeff x*1 -> x
          } else {
            ### highest coeff: "$coeff"
            $times_coeff->($coeff);
          }
          last;
        }
        $ret .= $config{'times'} . $config{'left_paren'};
        $post .= $config{'right_paren'};
      }
      $leading_const->($coeff);
    }

    ### final xpow: $xpow
    if ($limit != $degree) {
      if ($last != _EMPTY) {
        $ret .= $config{'plus'};
      }
      $xpow++;
      $show_xpow->();
    }

  } else {
    ### descending

    my $coeff = $poly->coeff($degree);
    ### highest coeff: "$coeff"
    my $i = $degree;

    {
      my ($j, $second);
      if ($config{'fold_sign'} && $config{'fold_sign_swap_end'}
          && $coeff < $zero
          && (($j,$second) = _second_highest_coeff($poly,$config{'fold_zero'}))
          && $second > $zero) {
        $leading_const->($second);
        $plus_coeff->($coeff);
        $last = _FACTOR;
        $xpow = $degree - $j;
        $times_xpow->();
        $i = $j - 1;
        $last = _SUM;
        ### fold_sign_swap_end gives
        ### $ret
        ### $i
      }
    }

    # normal start from high coeff, ie. not the swap bit
    if ($i == $degree) {
      $leading_factor->($coeff);
      $i--;
    }
    for ( ; $i >= 0; $i--) {
      ### $i
      $xpow++;
      $coeff = $poly->coeff($i);
      if ($config{'fold_zero'} && $coeff == $zero) {
        next;
      }
      $times_xpow->();
      $plus_coeff->($coeff);
    }
    $times_xpow->();
  }

  ### prefix: $config{'prefix'}
  ### $pre
  ### $ret
  ### $post
  ### suffix: $config{'suffix'}
  return $config{'prefix'} . $pre . $ret . $post . $config{'suffix'};
}

sub _second_highest_coeff {
  my ($poly, $fold_zero) = @_;
  my $j = $poly->degree;
  ### assert: $j >= 0

  for (;;) {
    if (--$j < 0) {
      return; # not found
    }
    my $coeff = $poly->coeff($j);
    unless ($fold_zero && $coeff == $poly->coeff_zero) {
      return ($j, $coeff); # found
    }
  }
}

1;
__END__

=for stopwords stringize Horner config hashref parens Math-Polynomial-Horner Ryde

=head1 NAME

Math::Polynomial::Horner -- stringize Math::Polynomial in Horner form

=head1 SYNOPSIS

 use Math::Polynomial;
 my $poly = Math::Polynomial->new(7,8,0,9,4,5);

 use Math::Polynomial::Horner;
 print Math::Polynomial::Horner::as_string($poly, {times=>'*'});
 # ((((5*x + 4)*x + 9)*x^2 + 8)*x + 7)

=head1 DESCRIPTION

This is a few lines of code to format C<Math::Polynomial> objects as strings
in Horner form.  It uses parentheses to group terms for multiplications by x
rather than powering.

=head2 Program Code

Horner form is quite good for computer evaluation.  If you adjust C<times>,
C<power> etc in the string config then it can be pasted into a program.

For Perl the default "descending" comes out better than ascending because
Perl evaluates left to right so the descending does each coefficient
addition successively, whereas ascending pushes all the coefficients on the
stack before working down through them.

An obvious optimization for evaluation is to watch for middle powers like
x^2 in the synopsis above which arise from runs of zero coefficients, and
hold them in temporary variables if needed more than once.  Something like
that might be possible in the future for a program code form.

More sophisticated optimizations can be had from power trees or partly or
completely factorizing the polynomial to find repeated roots.  Some of that
may be a bit difficult, and for that matter C<Math::Symbolic> might be a
better way to keep track of transformations applied.

=head1 FUNCTIONS

=over 4

=item C<$string = Math::Polynomial::Horner::as_string ($poly)>

=item C<$string = Math::Polynomial::Horner::as_string ($poly, $sconfig)>

Return C<$poly> as a string in Horner form.

Optional C<$config> is a hashref of stringize parameters the same as
C<$poly-E<gt>as_string> takes, plus extra fields described below.

=back

=head1 STRING CONFIGURATION

In addition to the basic string configurations of C<Math::Polynomial> the
following are recognised.

=over

=item C<left_paren>, string, default "("

=item C<right_paren>, string, default ")"

Internal parentheses to use.  C<prefix> and C<suffix> are used at the very
start and end of the string so if you change C<left_paren> and
C<right_paren> then you will probably change C<prefix> and C<suffix> too,
perhaps to empty strings if you don't want an outermost set of parens.

    $str = Math::Polynomial::Horner::as_string
               ($poly,
                { left_paren  => '[',
                  right_paren => ']',
                  prefix      => '',
                  suffix      => '' });

=back

There's a couple of secret experimental options in the code too.
C<power_by_times_upto> prefers multiplications over powering when there's
zero coefficients to be skipped.  C<fold_sign_swap_end> extends C<fold_sign>
to swap the order of the high term and following factor to turn for instance
S<(-3*x + 1)> into S<(1 - 3*x)>.  It can save a negation if the high
coefficient is -1 and the next is positive.  And C<for_perl> gives Perl code
C<power> operator and turns on C<fold_sign>.  Not sure yet if these are a
good idea.  The Perl style might not suit if using values or coefficients
which are not plain numbers but instead an object, matrix, whatever.

=head1 SEE ALSO

L<Math::Polynomial>

=head1 HOME PAGE

http://user42.tuxfamily.org/math-polynomial-horner/index.html

=head1 LICENSE

Math-Polynomial-Horner is Copyright 2010, 2011 Kevin Ryde

Math-Polynomial-Horner is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option) any
later version.

Math-Polynomial-Horner is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
Math-Polynomial-Horner.  If not, see <http://www.gnu.org/licenses/>.

=cut

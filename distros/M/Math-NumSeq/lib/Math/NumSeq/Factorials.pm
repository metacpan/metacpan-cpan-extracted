# Copyright 2010, 2011, 2012, 2013, 2014, 2016 Kevin Ryde

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


# http://www.luschny.de/math/factorial/approx/SimpleCases.html
#


package Math::NumSeq::Factorials;
use 5.004;
use strict;

use vars '$VERSION','@ISA';
$VERSION = 73;

use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Fibonacci;
*_blog2_estimate = \&Math::NumSeq::Fibonacci::_blog2_estimate;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Factorials');
use constant description => Math::NumSeq::__('The factorials 1, 2, 6, 24, 120, etc, 1*2*...*N.');
use constant values_min => 1;
use constant i_start => 0;
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;

#------------------------------------------------------------------------------
# cf A006882 double a(n)=n*a(n-2), n*(n-2)*(n-4)*...*3*1 or *4*2
#    A001147 double factorial 1*3*5*...*(2n-1) odd numbers, bisection
#    A000165 double factorial 2*4*6*...*2n even numbers,    bisection
#    
#    A007661 triple a(n)=n*a(n-3)
#    A007662 quadruple a(n)=n*a(n-4)
#    A047053 quad 4^n*n! quad on multiples of 4
#    A007696 quad n=4k+1 products
#    A001813 quad (2*n)!/n!
#    A008545 quad n=4k+1 products
#    A080500 squares n*(n-1)*(n-4)*(n-9)*(n-16)*(n-25)*...*1
#
#    A001013 Jordan-Polya products of factorials
#
# A008906 n! num digits excl trailing zeros
# A027868 n! num trailing zeros, is power of 5
# A000966 n! never ends these 0s
#
# A008904 n! low non-zero 
# A136690 base 3
# A136691 base 4
# A136692 base 5
# A136693 base 6
# A136694 base 7
# A136695 base 8
# A136696 base 9
# A136697 base 11
# A136698 base 12
# A136699 base 13
# A136700 base 14
# A136701 base 15
# A136702 base 16
#
# A008905 n! leading digit
# A136754 base 3
# A136755 base 4
# A136756 base 5
# A136757 base 6
# A136758 base 7
# A136759 base 8
# A136760 base 9
# A136761 base 11
# A136762 base 12
# A136763 base 13
# A136764 base 14
# A136765 base 15
# A136766 base 16

use constant oeis_anum => 'A000142'; # factorials 1,1,2,6,24, including 0!==1

#------------------------------------------------------------------------------


use constant 1.02;  # for leading underscore
use constant _UV_I_LIMIT => do {
  my $u = ~0 >> 1;
  my $limit = 1;
  my $i = 2;
  for (; $i++; ) {
    if ($u < $i) {
      ### _UV_LIMIT stop before: "i=$i"
      last;
    }
    $u -= ($u % $i);
    $u /= $i;
    $limit *= $i;
  }
  ### $limit
  ### $i
  $i
};
### _UV_I_LIMIT: _UV_I_LIMIT()

use constant _NV_LIMIT => do {
  my $f = 1.0;
  my $max;
  for (;;) {
    $max = $f;
    my $l = 2.0*$f;
    my $h = 2.0*$f+2.0;
    $f = 2.0*$f + 1.0;
    $f = sprintf '%.0f', $f;
    last unless ($f < $h && $f > $l);
  }
  ### uv : ~0
  ### 53  : 1<<53
  ### $max
  $max
};



sub rewind {
  my ($self) = @_;
  ### Factorials rewind()
  $self->{'i'} = $self->i_start;
  $self->{'f'} = 1;
}
sub seek_to_i {
  my ($self, $i) = @_;
  $self->{'i'} = $i;
  $self->{'f'} = $self->ith($i-1);
}
sub _UNTESTED__seek_to_value {
  my ($self, $value) = @_;
  my $i = $self->{'i'} = $self->value_to_i_ceil($value);
  $self->{'f'} = $self->ith($i);
}
sub next {
  my ($self) = @_;
  ### Factorials next() ...

  my $i = $self->{'i'}++;
  if ($i == _UV_I_LIMIT) {
    $self->{'f'} = Math::NumSeq::_to_bigint($self->{'f'});
  }
  return ($i, $self->{'f'} *= ($i||1));
}

sub ith {
  my ($self, $i) = @_;
  ### Factorials ith() ...

  if (_is_infinite($i)) {
    return $i;
  }

  if (! ref $i && $i >= _UV_I_LIMIT) {
    # Plain index $i automatically use Math::BigInt when UV limit reached.
    # Maybe should check if BigInt new enough to have bfac(), circa vers 1.60
    return Math::NumSeq::_bigint()->bfac($i);
  }

  my $value = ($i*0) + 1;   # inherit bignum 1
  while ($i >= 2) {
    $value *= $i;
    $i -= 1;
  }
  return $value;
}

sub pred {
  my ($self, $value) = @_;
  return defined($self->value_to_i($value));
}
sub value_to_i {
  my ($self, $value) = @_;

  # NV inf or nan gets $value%$i=nan and nan==0 is false,
  # but Math::BigInt binf()%$i=0 so would go into infinite loop
  # hence explicit check against _is_infinite()
  #
  if (_is_infinite($value)) {
    return undef;
  }

  if ($value == 1) {
    return 0;
  }

  my $i = 1;
  for (;;) {
    if ($value <= 1) {
      return ($value == 1 ? $i : undef);
    }
    $i++;
    if (($value % $i) == 0) {
      $value /= $i;
    } else {
      return undef;
    }
  }
  return $i;
}

sub value_to_i_floor {
  my ($self, $value) = @_;
  if (_is_infinite($value)) {
    return $value;
  }
  if ($value < 2) {
    return $self->i_start;
  }

  # "/" operator converts 64-bit UV to an NV and so loses bits, making the
  # result come out 1 too small sometimes.  Experimental switch to BigInt to
  # keep precision.  ENHANCE-ME: Maybe better _divrem().
  #
  if (! ref $value && $value > _NV_LIMIT) {
    $value = Math::NumSeq::_to_bigint($value);
  }

  my $i = 2;
  for (;; $i++) {
    ### $value
    ### $i

    if ($value < $i) {
      return $i-1;
    }
    $value = int($value/$i);
  }
}

# ENHANCE-ME: should be able to notice rounding in $value/$i divisions of
# value_to_i_floor(), rather than multiplying back.
#
sub _UNTESTED__value_to_i_ceil {
  my ($self, $value) = @_;
  if ($value < 0) { return 0; }
  my $i = $self->value_to_i_floor($value);
  if ($self->ith($i) < $value) {
    $i += 1;
  }
  return $i;
}


#--------
# Stirling
# n! ~= sqrt(2pi*n) * binomial(n,e)^n
# n! ~= sqrt(2*Pi) * n^(n+1/2) / e^n
# log(i!) ~= i*log(i) - i
#
# f(x) = x*log(x) - x - t
# f'(x) = log(x)
# sub = f(x) / f'(x)
#     = (x*log(x) - x - t) / log(x)
#     = x - (x+t)/log(x)
# new = x - sub
#     = x - (x - (x+t)/log(x))
#     = (x+t)/log(x)
#
# start x=t
# new1 = 2t/log(t)
# new2 = (2t/log(t) + t) / log(2t/log(t))
#      = (2t/log(t) + t) / (log(2t) - log(log(t)))
#
# log2(i!) = log(i!)/log(2)
#         ~= (i*log(i) - i)/log(2)
# log2(i!)*log(2) ~= i*log(i) - i
#
#--------
# Gosper, approximating terms of Stirling series
#
# n! ~= sqrt((2n+1/3)pi) * n^n * e^-n
#
sub value_to_i_estimate {
  my ($self, $value) = @_;
  ### value_to_i_estimate: $value

  if ($value <= 1) {
    return 0;
  }
  if ($value <= 3) {
    return 1;
  }

  my $t;
  if (defined (my $blog2 = _blog2_estimate($value))) {
    $t = $blog2 * log(2);
  } else {
    $t = log($value);
  }

  # two steps of Newton's method
  my $x = 2*$t/log($t);
  return int(($x+$t)/log($x));


  # # single step of Newton's method starting x=t
  # # x-1 is a touch under the true i, so just int() down
  # return int(2*$t/log($t));
  #
  # multiple steps
  # my $x = $t;
  # for (1 .. 10) {
  #   ### $x
  #   ### log: log($x)
  #   ### f: ($x*log($x)-$x - $t)
  #   ### fd: log($x)
  #   ### sub: ($x*log($x) - $x - $t)/log($x)
  #   ### new: ($x+$t)/log($x)
  # 
  #   $x = ($x+$t)/log($x);
  # }
  # return int($x)-1;
}

1;
__END__

=for stopwords Ryde Math-NumSeq ie Stirling's

=head1 NAME

Math::NumSeq::Factorials -- factorials i! = 1*2*...*i

=head1 SYNOPSIS

 use Math::NumSeq::Factorials;
 my $seq = Math::NumSeq::Factorials->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The factorials being product 1*2*3*...*i, 1 to i inclusive.

    1, 2, 6, 24, 120, 720, ...
    starting i=1

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::Factorials-E<gt>new ()>

Create and return a new sequence object.

=back

=head2 Iterating

=over

=item C<$seq-E<gt>seek_to_i($i)>

Move the current sequence position to C<$i>.  The next call to C<next()>
will return C<$i> and corresponding value.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return C<1*2*...*$i>.  For C<$i==0> this is considered an empty product and
the return is 1.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is a factorial, ie. equal to C<1*2*...*i> for
some i.

=item C<$i = $seq-E<gt>value_to_i($value)>

=item C<$i = $seq-E<gt>value_to_i_floor($value)>

Return the index i of C<$value>.  If C<$value> is not a factorial then
C<value_to_i()> returns C<undef>, or C<value_to_i_floor()> the i of the next
lower value which is or C<undef> if C<$value E<lt> 1>.

=item C<$i = $seq-E<gt>value_to_i_estimate($value)>

Return an estimate of the i corresponding to C<$value>.

=back

=head1 FORMULAS

=head2 Value to i Estimate

The current code uses Stirling's approximation

    log(n!) ~= n*log(n) - n

by seeking an i for which the target factorial "value" has

    i*log(i) - i == log(value)

Newton's method is applied to solve for i,

    target=log(value)
    f(x) = x*log(x) - x - target      wanting f(x)=0
    f'(x) = log(x)

    iterate next_x = x - f(x)/f'(x)
                   = (x+target)/log(x)

Just two iterations is quite close

    target = log(value)
    i0 = target
    i1 = (i0+target)/log(target)
       = 2*target/log(target)
    i2 = (i1+target)/log(i1)

    i ~= int(i2)

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Primorials>

L<Math::BigInt> (C<bfac()>),
L<Math::Combinatorics> (C<factorial()>,
L<Math::NumberCruncher> (C<Factorial()>
L<Math::BigApprox> (C<Fact()>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2016 Kevin Ryde

Math-NumSeq is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Math-NumSeq is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

=cut

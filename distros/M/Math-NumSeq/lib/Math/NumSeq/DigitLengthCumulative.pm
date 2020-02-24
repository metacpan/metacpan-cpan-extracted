# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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

package Math::NumSeq::DigitLengthCumulative;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 74;
use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Fibonacci;
*_blog2_estimate = \&Math::NumSeq::Fibonacci::_blog2_estimate;

use Math::NumSeq::Base::Digits
  'parameter_info_array';   # radix parameter

# uncomment this to run the ### lines
#use Smart::Comments;


use vars '$VERSION';
$VERSION = 74;

# use constant name => Math::NumSeq::__('Digit Length Cumulative');
use constant description => Math::NumSeq::__('Cumulative length of numbers 0,1,2,3,etc written out in the given radix.  For example binary 1,2,4,6,9,12,15,18,22,etc, 2 steps by 2, then 4 steps by 3, then 8 steps by 4, then 16 steps by 5, etc.');
use constant i_start => 0;
use constant values_min => 1;
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;

#------------------------------------------------------------------------------
# cf A117804 - natural position of n in 012345678910111213
#    A061168
#
my @oeis_anum;
$oeis_anum[2] = 'A083652';   # 2 binary
# OEIS-Catalogue: A083652 radix=2

sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum[$self->{'radix'}];
}

#------------------------------------------------------------------------------

sub rewind {
  my ($self) = @_;
  ### DigitLengthCumulative rewind(): $self

  $self->{'i'} = $self->i_start;
  $self->{'length'} = 1;
  $self->{'limit'} = $self->{'radix'};
  $self->{'total'} = 0;

  $self->{'logR'} = log($self->{'radix'});
}
sub _UNTESTED__seek_to_i {
  my ($self, $i) = @_;
  $self->{'i'} = $i;
  my $length = $self->{'length'} = $self->Math::NumSeq::DigitLength::ith($i);
  $self->{'limit'} = $self->{'radix'} ** ($length+1);
  $self->{'total'} = $self->ith($i);
}
sub next {
  my ($self) = @_;
  ### DigitLengthCumulative next(): $self
  ### count: $self->{'count'}
  ### bits: $self->{'bits'}

  my $i = $self->{'i'}++;
  if ($i >= $self->{'limit'}) {
    $self->{'limit'} *= $self->{'radix'};
    $self->{'length'}++;
    ### step to
    ### length: $self->{'length'}
    ### remaining: $self->{'limit'}
  }
  return ($i, ($self->{'total'} += $self->{'length'}));
}

# 0 to 9 is 10 of
sub ith {
  my ($self, $i) = @_;
  ### DigitLengthCumulative ith(): $i

  if (_is_infinite($i)) {
    return $i;  # don't loop forever if $i is +infinity
  }
  my $ret = 1;
  my $length = 1;
  my $radix = $self->{'radix'};
  my $power = ($i*0)+1; # inherit bignum 1
  for (;;) {
    ### $ret
    ### $length
    ### $power
    my $next_power = $power * $radix;
    if ($i < $next_power) {
      ### final extra: $length * ($i - $power + 1)
      return $ret + $length * ($i - $power + 1);
    }
    ### add: $length * $next_power
    $ret += $length++ * ($next_power - $power);
    $power = $next_power;
  }
}

sub pred {
  my ($self, $value) = @_;

  if (_is_infinite($value)) {
    return undef;
  }
  {
    my $int = int($value);
    if ($value != $int) {
      return 0;
    }
    $value = $int;
  }
  if ($value == 0) {
    return 0;
  }

  my $radix = $self->{'radix'};

  # length=1
  # values     0,1,2,...,9
  # cumulative 1,2,3,...,10
  if ($value <= $radix) {
    return 1;
  }
  $value -= $radix;

  # initial 10 to 99 = 90 values R*(R-1)
  # later 1000 to 9999 = 9000 values R*R*R*(R-1)
  # eg length=3
  # values 1000 to 9999
  # cumulative 3,6,...,
  my $length = 2;
  my $count = ($value*0)  # inherit bignum $value
    + $radix*($radix-1);

  for (;;) {
    my $limit = $count*$length;

    ### $length
    ### $count
    ### remainder: $value
    ### $limit

    if ($value <= $limit) {
      return ($value % $length) == 0;
    }
    $value -= $limit;
    $length++;
    $count *= $radix;
  }
}

sub value_to_i {
  my ($self, $value) = @_;
  my $i = $self->value_to_i_floor($value);
  if ($value == $self->ith($i)) {
    return $i;
  }
  return undef;
}
sub value_to_i_floor {
  my ($self, $value) = @_;

  if (_is_infinite($value)) {
    return $value;
  }
  $value = int($value);

  if ($value < 1) {
    return 0;
  }

  # length=1
  # values     0,1,2,...,9
  # cumulative 1,2,3,...,10
  #
  my $radix = $self->{'radix'};
  if ($value <= $radix) {
    return $value-1;
  }
  $value -= $radix;

  # initial 10 to 99 = 90 values R*(R-1)
  # later 1000 to 9999 = 9000 values R*R*R*(R-1)
  # eg length=3
  # values 1000 to 9999
  # cumulative 3,6,...,
  my $length = 2;
  my $count = ($value*0)  # inherit bignum $value
    + $radix*($radix-1);
  my $i = $radix-1;

  for (;;) {
    my $limit = $count*$length;

    ### $length
    ### $count
    ### remainder: $value
    ### $limit

    if ($value <= $limit) {
      return $i + int($value/$length);
    }
    $value -= $limit;
    $i += $count;
    $length++;
    $count *= $radix;
  }
}

# OR: estimate
# value = 1 + (R-1) + 2*R*(R-1) + 3*R*R*(R-1) + ... + k*R^(k-1)*(R-1)
#       = 1+ (R-1) * [ 1 + R + R^2 + R^3 + ... + R^(k-1)
#                        + R + R^2 + R^3 + ... + R^(k-1)
#                            + R^2 + R^3 + ... + R^(k-1)
#                      ...                     + R^(k-1) ]
#       = 1+ (R-1) * [ (R^k - 1) / (R-1)
#                        + R *(R^(k-1) - 1) / (R-1)
#                        + R^2 *(R^(k-2) - 1) / (R-1)
#                    ... + R^(k-1) *(R - 1) / (R-1) ]
#       = 1+ [ (R^k - 1)
#                + R *(R^(k-1) - 1)
#                + R^2 *(R^(k-2) - 1)
#            ... + R^(k-1) *(R - 1) ]
#      ~= (R^k)
#          + R *(R^(k-1))
#          + R^2 *(R^(k-2))
#      ... + R^(k-1) *(R)
#       = k*R^k    at i=R^k
#
# log(k*R^k) = log(k) + k*log(R)
# target t=log(value)
# f(x) = x*log(R) + log(x) - t
# f'(x) = log(R) + log(x)
# next_x = x - f(x)/f'(x)
#        = x - (x*log(R) + log(x) - t)/(log(R) + log(x))
#        = (x*(log(R) + log(x)) - (x*log(R) + log(x) - t))
#          / (log(R) + log(x))
#        = (x*log(R) + x*log(x) - x*log(R) - log(x) + t)
#          / (log(R) + log(x))
#        = (x*log(x) - log(x) + t) / (log(R) + log(x))
#        = ((x-1)*log(x) + t) / (log(R) + log(x))
#
# For i=R^k value=k*R^k estimate k as kest=logR(value), which is only a bit
# bigger than it should be, and divide that out value/kest~=R^k=i

sub value_to_i_estimate {
  my ($self, $value) = @_;

  if ($value <= 1) {
    return 0;
  }

  my $t;
  if (defined (my $blog2 = _blog2_estimate($value))) {
    $t = $blog2 * log(2);
  } else {
    $t = log($value);
  }

  # integer divisor to help Math::BigInt $value
  my $div = int($t/$self->{'logR'});
  if ($div > 1) {
    $value /= $div;
  }
  return int($value);
}

1;
__END__

=for stopwords Ryde Math-NumSeq

=head1 NAME

Math::NumSeq::DigitLengthCumulative -- total length in digits of numbers 1 to i

=head1 SYNOPSIS

 use Math::NumSeq::DigitLengthCumulative;
 my $seq = Math::NumSeq::DigitLengthCumulative->new (radix => 10);
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The total length of numbers 0 to i, starting from i=0.

    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 14, 16, 18, 20, 22, 24, 26, ...

"0" is taken to be a single digit, so the initial i=0 is total length 1.
Then it's length 1 more for each of i=1 to i=9, then at i=10 length 2 more,
etc.

The default is decimal, or the optional C<radix> parameter can select
another base.  For example C<radix =E<gt> 3> ternary,

    1, 2, 3, 5, 7, 9, 11, 13, 15, 18, 21, 24, 27, 30, ...

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::DigitLengthCumulative-E<gt>new (radix =E<gt> $r)>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return total length in digits of the numbers 0 to C<$i>, inclusive.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs in the sequence.

=item C<$i = $seq-E<gt>value_to_i_floor($value)>

Return the index i of C<$value> or of the next cumulative total below
C<$value>.

=item C<$i = $seq-E<gt>value_to_i_estimate($value)>

Return an estimate of the i corresponding to C<$value>.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::DigitLength>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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

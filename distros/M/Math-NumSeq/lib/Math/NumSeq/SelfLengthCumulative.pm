# Copyright 2012, 2013, 2014, 2016, 2017 Kevin Ryde

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

package Math::NumSeq::SelfLengthCumulative;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 73;

use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Fibonacci;
*_blog2_estimate = \&Math::NumSeq::Fibonacci::_blog2_estimate;


use constant name => Math::NumSeq::__('Self Length Cumulative');
use constant description => Math::NumSeq::__('Cumulative digit length of own values.');
use constant default_i_start => 1;
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;
use constant values_min => 1;

use Math::NumSeq::Base::Digits
  'parameter_info_array';   # radix parameter


#------------------------------------------------------------------------------

my @oeis_anum;
$oeis_anum[10] = 'A064223';
# OEIS-Catalogue: A064223

sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum[$self->{'radix'}];
}


#------------------------------------------------------------------------------

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  $self->{'value'} = 1;
  $self->{'power'} = $self->{'radix'};
  $self->{'length'} = 1;
}
sub next {
  my ($self) = @_;

  my $value = $self->{'value'};
  if ($value >= $self->{'power'}) {
    $self->{'power'} *= $self->{'radix'};
    $self->{'length'}++;
  }
  $self->{'value'} += $self->{'length'};
  return ($self->{'i'}++, $value);
}

sub pred {
  my ($self, $value) = @_;

  if ($value < 1 || $value != int($value)) {
    return 0;
  }
  if (_is_infinite($value)) {
    return undef;
  }

  my $length = 1;
  my $radix = $self->{'radix'};
  my $power = ($value * 0) + $radix;  # inherit bignum $value
  my $upto = 1;
  for (;;) {
    if ($value < $power) {
      return (($value - $upto) % $length) == 0;
    }
    $upto = $power + ($upto-$power)%$length;

    $power *= $radix;
    $length++;
  }
}

# value = 10  i=10
# value = 100  i=10+90/2
# value = 1000  i=10+90/2+900/3
#
# value = R^k
# i = R + R^2/2 + R^3/3 + ... + R^k/k
# i = R + R^2/2 + R^3/3 + ... + R^k/k
#   <= (R + R^2 + R^3 + ... + R^k)/k
#    = (R^(k+1)-1)/(R-1) /k
#   ~= R^k/k
# i ~= value/logR(value)
# logR(value) = log(value)/log(R)
#
# est(R^k) = R^k/k
# log(est(R^k)) = log(R^k/k)
#               = log(value) - log(k)
#
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

  $self->{'logR'} = log($self->{'radix'});

  # integer divisor to help Math::BigInt
  my $div = int($t/$self->{'logR'});
  if ($div > 1) {
    $value /= $div;
  }
  return int($value);
}

1;
__END__

=for stopwords Ryde Math-NumSeq DigitLengthCumulative

=head1 NAME

Math::NumSeq::SelfLengthCumulative -- cumulative digit length of own values

=head1 SYNOPSIS

 use Math::NumSeq::SelfLengthCumulative;
 my $seq = Math::NumSeq::SelfLengthCumulative->new (radix => 10);
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

Cumulative digit length of values from the sequence itself,

    1, 2, 3, 4, ... 9, 10, 12, 14, 16, ... 98, 100, 103, 106, ...

Value 9 is 1 digit, so add 1 to give 10.  Then 10 is 2 digits so add 2 to
give 12, etc.

The default is decimal digits, or optional C<radix> parameter can give
another base.  For example C<radix =E<gt> 2> binary

    1, 2, 4, 7, 10, 14, 18, 23, 28, 33, 39, 45, ...

The effect in all cases is to step by 1s up to 10, then by 2s up to 100,
then 3s up to 1000, etc, in whatever C<radix>.  This is similar to
DigitLengthCumulative, but its lengths are from i whereas here they're from
the values.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::SelfLengthCumulative-E<gt>new ()>

=item C<$seq = Math::NumSeq::SelfLengthCumulative-E<gt>new (radix =E<gt> $r, to_radix =E<gt> $t)>

Create and return a new sequence object.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs in the sequence.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::DigitLength>,
L<Math::NumSeq::DigitLengthCumulative>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2016, 2017 Kevin Ryde

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

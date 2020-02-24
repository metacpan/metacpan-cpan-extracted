# Copyright 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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

package Math::NumSeq::MoranNumbers;
use 5.004;
use strict;
use Math::Prime::XS 0.23 'is_prime'; # version 0.23 fix for 1928099

use vars '$VERSION', '@ISA';
$VERSION = 74;

use Math::NumSeq;
use Math::NumSeq::Base::IteratePred;
@ISA = ('Math::NumSeq::Base::IteratePred',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
#use Devel::Comments;

use constant name => Math::NumSeq::__('Moran Numbers');
use constant description => Math::NumSeq::__('Moran numbers, divisible by the sum of their digits and that division resulting in a prime.');
use constant i_start => 1;

use Math::NumSeq::Base::Digits
  'parameter_info_array';   # radix parameter

sub values_min {
  my ($self) = @_;
  if (! $self->{'values_min'}) {
    for (my $value = $self->{'radix'}; ; $value++) {
      if ($self->pred($value)) {
        $self->{'values_min'} = $value;
        last;
      }
    }
  }
  return $self->{'values_min'};
}

#------------------------------------------------------------------------------
# cf A007953 digit sum (in Math::NumSeq::DigitSum)
#    A085775 both n/digitsum(n) and (n+1)/digitsum(n+1) prime
#    A108780 n/digitsum(n) is a golden semiprime
#    A130338 primes not occurring as n/digitsum(n)
#    A003635 inconsummate, quotients not occurring as n/digitsum(n)
#
my @oeis_anum;
$oeis_anum[10] = 'A001101';  # OFFSET=1
# OEIS-Catalogue: A001101

sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum[$self->{'radix'}];
}

#------------------------------------------------------------------------------

sub pred {
  my ($self, $value) = @_;
  ### MoranNumbers pred(): $value

  if ($value <= 0 || $value != int($value)) {
    return 0;
  }
  if (_is_infinite($value)) {
    return undef;
  }

  my $radix = $self->{'radix'};
  my $sum = 0;
  my $v = $value;
  while ($v) {
    $sum += ($v % $radix);
    $v = int($v/$radix);
  }
  if ($value % $sum) {
    return 0;
  }
  $value /= $sum;
  if ($value > 0xFFFF_FFFF) {
    return undef;
  }
  return is_prime($value);
}

1;
__END__

=for stopwords Ryde Math-NumSeq moran ie harshad

=head1 NAME

Math::NumSeq::MoranNumbers -- numbers divided by sum of digits giving a prime

=head1 SYNOPSIS

 use Math::NumSeq::MoranNumbers;
 my $seq = Math::NumSeq::MoranNumbers->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The Moran numbers,

    18, 21, 27, 42, 45, 63, 84, ...

being integers which are divisible by the sum of their digits and that
division resulting in a prime.  For example 42 has digit sum 4+2=6 and
42/6=7 is an integer and a prime.

This is a subset of the harshad numbers (L<Math::NumSeq::HarshadNumbers>),
those being all integers divisible by the their digit sum.  The further
restriction here is that the division gives a prime.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::MoranNumbers-E<gt>new ()>

=item C<$seq = Math::NumSeq::MoranNumbers-E<gt>new (radix =E<gt> $r)>

Create and return a new sequence object.

The optional C<radix> parameter (default 10, decimal) sets the base to use
for the digits.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is a Moran number, ie. is divisible by the sum of
its digits in the given C<radix>, and that division gives a prime.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::DigitSum>,
L<Math::NumSeq::HarshadNumbers>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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

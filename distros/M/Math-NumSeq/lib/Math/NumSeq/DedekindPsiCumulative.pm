# Copyright 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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

package Math::NumSeq::DedekindPsiCumulative;
use 5.004;
use strict;
use Math::NumSeq::Primes;

use vars '$VERSION', '@ISA';
$VERSION = 75;

use Math::NumSeq;
@ISA = ('Math::NumSeq');

use Math::NumSeq::PrimeFactorCount;;
*_prime_factors = \&Math::NumSeq::PrimeFactorCount::_prime_factors;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Dedekind Psi Cumulative');
use constant description => Math::NumSeq::__('Cumulative Dedekind Psi function.');
use constant default_i_start => 1;
use constant characteristic_integer => 1;
use constant characteristic_increasing => 1;
use constant values_min => 1;

# A001615 dedekind psi
# A019268 dedekind psi first of n steps
# A019269 number of steps
# A173290 dedekind psi cumulative
#
use constant oeis_anum => 'A173290';

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  $self->{'total'} = 0;
}

sub next {
  my ($self) = @_;

  my $i = $self->{'i'}++;
  return ($i,
          $self->{'total'} += _psi($i));
}

sub _psi {
  my ($n) = @_;
  ### _psi(): $n
  my ($good, @primes) = _prime_factors($n);
  return undef unless $good;

  my $prev = 0;
  foreach my $p (@primes) {
    if ($p != $prev) {
      $n /= $p;
      $n *= $p+1;
      $prev = $p;
    }
  }
  ### $n
  return $n;
}

# v1.02 for leading underscore
use constant 1.02 _PI => 4*atan2(1,1); # similar to Math::Complex pi()

# Enrique Pérez Herrero in the OEIS
# value = 15*n^2/(2*Pi^2) + O(n*log(n))
#
# sqrt(value) = sqrt(15/2)/pi * n
# n = sqrt(value) * pi/sqrt(15/2)
# with pi/sqrt(15/2) ~= 39/34 for the benefit of Math::BigInt which can't
# do BigInt*flonum
#
# very close even neglecting n*log(n)
#
sub value_to_i_estimate {
  my ($self, $value) = @_;
  if ($value <= 1) { return 1; }
  return int (sqrt(int($value)) * 39/34);
}

1;
__END__

=for stopwords Ryde Math-NumSeq ie Euler's totient

=head1 NAME

Math::NumSeq::DedekindPsiCumulative -- cumulative Psi function

=head1 SYNOPSIS

 use Math::NumSeq::DedekindPsiCumulative;
 my $seq = Math::NumSeq::DedekindPsiCumulative->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The cumulative Dedekind Psi function,

    1, 4, 8, 14, 20, 32, 40, 52, 64, 82, 94, 118, ...
    starting i=1

    value = sum n=1 to n=i of Psi(n)

where the Psi function is

    Psi(n) =        product          (p+1) * p^(e-1)
             prime factors p^e in n

The p+1 means one copy of each distinct prime in n is changed from p to p+1.
This is similar to Euler's totient function phi(n) (see
L<Math::NumSeq::Totient>) but phi(n) is p-1 instead of p+1.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::DedekindPsiCumulative-E<gt>new ()>

Create and return a new sequence object.

=item C<$i = $seq-E<gt>value_to_i_estimate($value)>

Return an estimate of the i corresponding to C<$value>.  Currently this is
based on the asymptotic

    value = 15*n^2/(2*Pi^2) + O(n*log(n))

which neglecting the O(n*log(n)) becomes

    i ~= sqrt(value) * pi/sqrt(15/2)

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::DedekindPsiSteps>,
L<Math::NumSeq::TotientCumulative>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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

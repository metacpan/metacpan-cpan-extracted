# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2017 Kevin Ryde

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

package Math::NumSeq::SophieGermainPrimes;
use 5.004;
use strict;
use Math::Prime::XS 0.23 'is_prime'; # version 0.23 fix for 1928099

use vars '$VERSION', '@ISA';
$VERSION = 73;

use Math::NumSeq;
use Math::NumSeq::Primes;
@ISA = ('Math::NumSeq');


# use constant name => Math::NumSeq::__('Sophie Germain Primes');
use constant description => Math::NumSeq::__('Sophie Germain primes 3,5,7,11,23,29, being primes P where 2*P+1 is also prime (those latter being the "safe" primes).');
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;
use constant values_min => 2; # first 2*2+1=5

#------------------------------------------------------------------------------
# cf. A156874 count SG primes <= n
#     A092816 count SG primes <= 10^n
#     A007700 for n,2n+1,4n+3 are all primes - or something?
#     A005385 the safe primes
#     A156875 count safe primes <= n
#     A117360 n and 2*n+1 have same number of prime factors
#
#     A156876 count SG or safe
#     A156877 count SG and safe
#     A156878 count neither SG nor safe
#    A156875 safe count
#    A156659 safe charact
#    A156658 p also 2*p+1 or (p-1)/2 prime
#    A156657 not safe primes

use constant oeis_anum => 'A005384';

#------------------------------------------------------------------------------

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  $self->{'prime_seq'} = Math::NumSeq::Primes->new;
}

sub next {
  my ($self) = @_;

  my $prime_seq = $self->{'prime_seq'};
  for (;;) {
    (undef, my $prime) = $prime_seq->next
      or return;
    if ($prime >= 0x7FFF_FFFF) {
      return;
    }
    if (is_prime(2*$prime+1)) {
      return ($self->{'i'}++, $prime);
    }
  }
}

# ENHANCE-ME: are_all_prime() to look for small divisors in both values
# simultaneously, in case one or the other easily excluded.
#
sub pred {
  my ($self, $value) = @_;
  return ($self->Math::NumSeq::Primes::pred ($value)
          && $self->Math::NumSeq::Primes::pred (2*$value + 1));
}

use Math::NumSeq::TwinPrimes;
*value_to_i_estimate = \&Math::NumSeq::TwinPrimes::value_to_i_estimate;

1;
__END__

=for stopwords Ryde Math-NumSeq Germain Littlewood Jacobsen

=head1 NAME

Math::NumSeq::SophieGermainPrimes -- Sophie Germain primes p and 2*p+1 prime

=head1 SYNOPSIS

 use Math::NumSeq::SophieGermainPrimes;
 my $seq = Math::NumSeq::SophieGermainPrimes->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The primes P for which 2*P+1 is also prime,

    2, 3, 5, 11, 23, 29, 41, 53, 83, 89, 113, 131, 173, 179, ...
    starting i=1

=cut

# X<Germain, Sophie>Sophie Germain proved that for such primes Fermat's last
# theorem is true, ie. if p is an S-G prime then x^p+y^p=z^p has no solution
# in integers x,y,z not zero and not multiples of p ... maybe.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::SophieGermainPrimes-E<gt>new ()>

Create and return a new sequence object.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is a Sophie Germain prime, meaning both C<$value>
and C<2*$value+1> are prime.

=item C<$i = $seq-E<gt>value_to_i_estimate($value)>

Return an estimate of the i corresponding to C<$value>.

X<Hardy>X<Littlewood>Currently this is the same as the TwinPrimes estimate.
Is it a conjecture by Hardy and Littlewood that the two are asymptotically
the same?  In any case the result is roughly a factor 0.9 too small for the
small to medium size integers this module might calculate.  (See
L<Math::NumSeq::TwinPrimes>.)

=back

=head1 FORMULAS

=head2 Next

C<next()> is implemented by a C<Math::NumSeq::Primes> sequence filtered for
primes where 2P+1 is a prime too.  Dana Jacobsen noticed this is faster than
running a second Primes iterator for primes 2P+1.  This is since for a prime
P often 2P+1 has a small factor such as 3, 5 or 11.  A factor 3 occurs for
any P=6k+1 since in that case 2P+1 is a multiple of 3.  What else can be
said about the density or chance of a small factor?

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Primes>,
L<Math::NumSeq::TwinPrimes>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2017 Kevin Ryde

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

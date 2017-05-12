# Copyright 2012, 2013, 2014 Kevin Ryde

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

package Math::NumSeq::LongFractionPrimes;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 72;
use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::PrimeFactorCount;;
*_prime_factors = \&Math::NumSeq::PrimeFactorCount::_prime_factors;

use Math::NumSeq::Primes;
use Math::NumSeq::Squares;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('...');
use constant description => Math::NumSeq::__('Primes where the fraction 1/p has digits repeating in full-length period p-1.  This is when the radix is a primitive root modulo p.');
use constant default_i_start => 1;
use constant characteristic_integer => 1;

use Math::NumSeq::Base::Digits
  'parameter_info_array';   # radix parameter

sub values_min {
  my ($self) = @_;
  unless (exists $self->{'values_min'}) {
    for (my $value = 2; ; $value++) {
      if ($self->pred($value)) {
        $self->{'values_min'} = $value;
        last;
      }
    }
  }
  return $self->{'values_min'};
}
sub values_max {
  my ($self) = @_;
  unless (exists $self->{'values_max'}) {
    $self->{'values_max'} = undef;
    if ($self->{'perfect_square'}) {
      for (my $value = $self->{'radix'}**2; $value >= 2; $value--) {
        if ($self->pred($value)) {
          $self->{'values_max'} = $value;
          last;
        }
      }
    }
  }
  return $self->{'values_max'};
}

#------------------------------------------------------------------------------

my @oeis_anum;
$oeis_anum[10] = 'A006883';
# OEIS-Catalogue: A006883

sub oeis_anum {
  my ($self) = @_;
  ### oeis_anum: $self
  return $oeis_anum[$self->{'radix'}];
}

#------------------------------------------------------------------------------

sub rewind {
  my ($self) = @_;
  $self->{'primes'} = Math::NumSeq::Primes->new;
  $self->{'i'} = $self->i_start;
  $self->{'perfect_square'} = Math::NumSeq::Squares->pred($self->{'radix'});
}

sub next {
  my ($self) = @_;
  ### LongFractionPrimes next() ...
  my $radix = $self->{'radix'};
  for (;;) {
    (undef, my $prime) = $self->{'primes'}->next;
    # FIXME: 3 ?
    if (_is_primitive_root ($self->{'radix'}, $prime) && $prime != 3) {
      return ($self->{'i'}++, $prime);
    }
    if ($self->{'perfect_square'} && $prime > $radix) {
      return;
    }
  }
}

sub pred {
  my ($self, $value) = @_;
  ### LongFractionPrimes pred(): "$value"
  return (Math::NumSeq::Primes->pred($value)
          && _is_primitive_root ($self->{'radix'}, $value));
}

sub _is_primitive_root {
  my ($base, $modulus) = @_;

  if (_is_infinite($modulus)) {
    return undef;
  }
  if ($modulus < 2) {
    return 0;
  }

  my $exponent = $modulus - 1;
  my ($good, @primes) = _prime_factors($exponent);
  return undef unless $good;

  my $prev_p = 0;
  while (defined (my $p = shift @primes)) {
    next if $p == $prev_p;
    $prev_p = $p;

    ### $p
    ### div: $exponent/$p
    ### powmod: _powmod($base, $exponent/$p, $modulus)

    if (_powmod($base, $exponent/$p, $modulus) <= 1) {
      return 0;
    }
  }

  # my $power = $base;
  # foreach (1 .. $value-2) {
  #   $power %= $value;
  #   if ($power == 1) {
  #     ### no, at: $_
  #     return 0;
  #   }
  #   $power *= $base;
  # }

  return 1;
}

sub _powmod {
  my ($base, $exponent, $modulus) = @_;

  my @exponent = _bit_split_hightolow($exponent)
    or return 1;

  my $power = $base;
  shift @exponent; # high 1 bit

  while (defined (my $bit = shift @exponent)) {  # high to low
    $power *= $power;
    $power %= $modulus;
    if ($bit) {
      $power *= $base;
      $power %= $modulus;
    }
  }
  return $power;
}

sub _bit_split_hightolow {
  my ($n) = @_;
  # ### _bit_split_hightolow(): "$n"

  if (ref $n) {
    if ($n->isa('Math::BigInt')
        && $n->can('as_bin')) {
      ### BigInt: $n->as_bin
      return split //, substr($n->as_bin,2);
    }
  }
  my @bits;
  while ($n) {
    push @bits, $n % 2;
    $n = int($n/2);
  }
  return reverse @bits;
}

1;
__END__

=for stopwords Ryde Math-NumSeq

=head1 NAME

Math::NumSeq::LongFractionPrimes -- primes for which fraction 1/p has a long period

=head1 SYNOPSIS

 use Math::NumSeq::LongFractionPrimes;
 my $seq = Math::NumSeq::LongFractionPrimes->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

I<In progress ...>

This is the primes for which fraction 1/p written out in decimal has digits
repeating in period p-1.

    2, 3, 7, 17, 19, 23, 29, 47, 59, 61, 97, 109, 113, 131, ...
    starting i=1 for prime=2

For example 1/7=0.142857142857142857... is runs of 7-1=6 repeating digits
"142857", so 7 is in the sequence.  On the other hand 1/11=0.09090909... is
only 2 repeating digits, so is not in the sequence.

A prime p has full period p-1 digits when the base 10 is a primitive root
modulo p, meaning that 10 mod p, 100 mod p, 1000 mod p, ..., 10^(p-2) mod p,
are all != 1.

=head2 Radix

An optional C<radix> parameter selects a base other than decimal.

If C<radix> is a square, 4,9,16,etc then only primes 2 and 3 have period p-1
and the sequence stops after them.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::LongFractionPrimes-E<gt>new ()>

Create and return a new sequence object.

=item C<$value = $seq-E<gt>pred($value)>

Return true if C<$value> is a prime and fraction 1/p has digit period p-1.

=item C<$i = $seq-E<gt>i_start ()>

Return 1, the first term in the sequence being at i=1.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Primes>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014 Kevin Ryde

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

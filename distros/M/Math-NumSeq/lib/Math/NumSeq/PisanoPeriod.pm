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


# Mark Renault
# http://www.math.temple.edu/~renault/fibonacci/fib.html
# http://www.math.temple.edu/~renault/fibonacci/thesis.ps
# http://web.archive.org/web/20100813104051/http://webspace.ship.edu/msrenault/fibonacci/FibThesis.html
#
# On Arithmetical Functions Related to the Fibonacci Numbers, Fulton and Morris
# aa1621.pdf
#
# period(m)=m iff m=24*5^(l-1) for some l
# l = Leonardo logarithm
# A001179 leonardo logarithm
#
# K.S.Brown a(n)/n <= 6 for all n, a(n)=6n iff n=2*5^k.
#
# Andreas-Stephan Elsenhans and Jorg Jahnel
# http://www.uni-math.gwdg.de/tschinkel/gauss/Fibon.pdf
# through to 10^14


package Math::NumSeq::PisanoPeriod;
use 5.004;
use strict;
use Math::Prime::XS 'is_prime';

use vars '$VERSION', '@ISA';
$VERSION = 75;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Base::Cache
  'cache_hash';

use Math::NumSeq::PrimeFactorCount;;
*_prime_factors = \&Math::NumSeq::PrimeFactorCount::_prime_factors;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('...');
use constant description => Math::NumSeq::__('The cycle length of the Fibonacci numbers modulo i.');
use constant i_start => 1;
use constant characteristic_smaller => 1;
use constant characteristic_integer => 1;
use constant characteristic_count => 1;

use constant values_min => 1;

#------------------------------------------------------------------------------
# cf A071774 n for which period(n)==2n+1
#    A060305 period mod nthprime
#    A001176 how many zeros
#    A001177 least k where n divides F[k]

use constant oeis_anum => 'A001175';

#------------------------------------------------------------------------------

sub ith {
  my ($self, $i) = @_;
  ### PisanoPeriod ith(): "$i"

  if ($i < 1) {
    return undef;
  }
  if (_is_infinite($i)) {
    return $i;
  }

  my ($good, @primes) = _prime_factors($i);
  return undef unless $good;

  my $lcm = Math::NumSeq::_to_bigint(1);
  while (@primes) {
    my $prime = shift @primes;

    my $period = 1;
    my $power = 1;
    my $modulus;

    if ($prime < 1e14) {
      # period(p^e) = period(p) * p^(e-1)
      while (@primes && $primes[0] == $prime) {
        shift @primes;
        $period *= $prime;
      }
      $modulus = $prime;
    } else {
      # full period(p^e)
      while (@primes && $primes[0] == $prime) {
        shift @primes;
        $power++;
      }
      $modulus = $prime ** $power;
    }

    $period *= (cache_hash()->{"PisanoPeriod:$prime,$power"} ||= do {
      my $f0 = 0;
      my $f1 = 1;
      my $period = 1;
      for ( ; ; $period++) {
        ### at: "f0=$f0 f1=$f1"
        ($f0,$f1) = ($f1, ($f0+$f1) % $modulus);
        if ($f0 == 0 && $f1 == 1) {
          last;
        }
      }
      ### period calcuated: "prime=$prime power=$power  period=$period"
      $period;
    });

    $lcm /= Math::BigInt::bgcd($period,$lcm);
    $lcm *= $period;
  }

  if ($lcm <= 0xFFFF_FFFF) {
    return $lcm->numify;
  } else {
    return $lcm;
  }
}

1;
__END__



  # prime_factors($i);
  # my $past_f0 = 1;
  # my $past_f1 = 1;
  # my $f0 = 1;
  # my $f1 = 1;
  # for (;;) {
  #   if ($f0 == $past_f0 && $f1 == $past_f1) {
  #     last;
  #   }
  #   ($past_f0,$past_f1) = ($past_f1, ($past_f0+$past_f1) % $i);
  # 
  #   $f0 += $f1;
  #   $f1 += $f0;
  #   $f0 %= $i;
  #   $f1 %= $i;
  # }
  # 
  # my $pos = 1;
  # for (;;) {
  #   ($f0,$f1) = ($f1, ($f0+$f1) % $i);
  #   if ($f0 == $past_f0 && $f1 == $past_f1) {
  #     return $pos;
  #   }
  #   $pos++;
  # }


=for stopwords Ryde Math-NumSeq Fibonaccis Pisano

=head1 NAME

Math::NumSeq::PisanoPeriod -- cycle length of Fibonacci numbers mod i

=head1 SYNOPSIS

 use Math::NumSeq::PisanoPeriod;
 my $seq = Math::NumSeq::PisanoPeriod->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is the length cycle of Fibonacci numbers modulo i.

    1, 3, 8, 6, 20, 24, 16, 12, 24, 60, 10, 24, 28, 48, 40, ...
    starting i=1

For example Fibonacci numbers modulo 4 repeat in a cycle of 6 numbers, so
value=6.

   Fibonacci  0, 1, 1, 2, 3, 5, 8,13,21,34,55,89,144,...
   mod 4      0, 1, 1, 2, 3, 1, 0, 1, 1, 2, 3, 1, 0,...
              \--------------/  \--------------/  \---
            repeating cycle of 6

The Fibonaccis are determined by a pair F[i],F[i+1] and there can be at most
i*i many different pairs mod i, so there's always a finite repeating period.
Since the Fibonaccis can go backwards as F[i-1]=F[i+1]-F[i] the modulo
sequence is purely periodic, so the initial 0,1 is always part of the cycle.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::PisanoPeriod-E<gt>new ()>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the Pisano period of C<$i>.

=cut

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Fibonacci>,
L<Math::NumSeq::FibonacciWord>

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

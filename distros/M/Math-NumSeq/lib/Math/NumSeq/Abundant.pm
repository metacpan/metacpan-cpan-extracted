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

package Math::NumSeq::Abundant;
use 5.004;
use strict;
use Carp;

use vars '$VERSION', '@ISA';
$VERSION = 73;
use Math::NumSeq 7; # v.7 for _is_infinite()
use Math::NumSeq::Base::IteratePred;
@ISA = ('Math::NumSeq::Base::IteratePred',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::PrimeFactorCount;
*_prime_factors = \&Math::NumSeq::PrimeFactorCount::_prime_factors;

# uncomment this to run the ### lines
# use Smart::Comments;


# use constant name => Math::NumSeq::__('Abundant Numbers');
sub description {
  my ($self) = @_;
  if (ref $self) {
    if ($self->{'abundant_type'} eq 'deficient') {
      return Math::NumSeq::__('Numbers N which are < sum of its divisors.');
    }
    if ($self->{'abundant_type'} eq 'primitive') {
      return Math::NumSeq::__('Numbers N which are > sum of its divisors, and not a multiple of some smaller abundant.');
    }
  }
  return Math::NumSeq::__('Numbers N with sum of its divisors > N, eg. 12 is divisible by 1,2,3,4,6 total 16 is > 12.');
}

use constant parameter_info_array =>
  [
   { name    => 'abundant_type',
     type    => 'enum',
     default => 'abundant',
     choices => [ 'abundant','deficient','primitive','non-primitive' ],
     choices_display => [Math::NumSeq::__('Abundant'),
                         Math::NumSeq::__('Deficient'),
                         Math::NumSeq::__('Primitive'),
                         Math::NumSeq::__('Non-Primitive'),
                        ],
     # description => Math::NumSeq::__(''),
   },
  ];

my %values_min = (abundant        => 12,
                  deficient       => 1,
                  primitive       => 12,
                  'non-primitive' => 24,
                 );
sub values_min {
  my ($self) = @_;
  return $values_min{$self->{'abundant_type'}};
}

#------------------------------------------------------------------------------
# cf A000396 perfect sigma(n) == 2n
#    A005231 odd abundants, starting 945 (slightly sparse)
#    A103288 sigma(n) >= 2n-1, so abundant+perfect+least deficient
#            least deficient sigma(n)==2n-1 might be only 2^k
#
#    Abundancy = sigma(n)/n so >2 or <2
#    A017665 / A017666 frac
#    A007691 multiperfect where abundancy=integer
#    A054030 abundancy in the multiperfect
#            conjectured each value n occurs only finite times
#
#    A000203 sigma(n) sum of divisors
#
#    primitiveness
#    A080224 number of abundant divisors, being 1 when primitive
#
my %oeis_anum = (abundant        => 'A005101',
                 deficient       => 'A005100',
                 primitive       => 'A091191',
                 'non-primitive' => 'A091192',
                 # OEIS-Catalogue: A005101
                 # OEIS-Catalogue: A005100 abundant_type=deficient
                 # OEIS-Catalogue: A091191 abundant_type=primitive
                 # OEIS-Catalogue: A091192 abundant_type=non-primitive
                );
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum{$self->{'abundant_type'}};
}


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);
  exists $values_min{$self->{'abundant_type'}}
    or croak "Unrecognised abundant_type ", $self->{'abundant_type'};
  return $self;
}

# i = primes p^k * ...
# sumdivisors(i) = (p^(k+1) - 1)/(p-1) * ...
# if k=1 then (p^2-1)/(p-1)
#
# abundant = sumdivisors(i) > 2*i
#
# sumdivisors(i/p) = (p^k - 1)/(p-1) * ...
#                  = sumdivisors(i) * (p^k - 1) / (p^(k+1) - 1)    if k>=2
# if sumdivisors(i/p) > 2*i/p then divisor is abundant
# sumdivisors(i) * (p^k - 1) / (p^(k+1) - 1) > 2*i/p
# sumdivisors(i) * (p^(k+1) - p) / (p^(k+1) - 1) > 2*i
#
# if k=1 then (p-1)/(p^2-1) * p = (p^2-p)/(p^2-1) still
#
# sumdivisors reduced by factor (p^(k+1)-p) / (p^(k+1)-1)
#
# term = (p^(k+1)-1) / (p-1)
# fmul = (p^(k+1)-p) / (p-1) = term - (p-1)/(p-1) = term-1
# sumdivisors * fmul/term
#    = sumdivisors * (term-1)/term
#    = sumdivisors - sumdivisors/term
# smallest subtraction is biggest term
#
# 12=2^2*3 sumdivisors = (2^3-1)/(2-1) * (3^2-1)/(3-1) = 28 > 2*12=24
# 6=2*3 sumdivisors = (2^2-1)/(2-1) * (3^2-1)/(3-1) = 12 == 2*6=12
#
# 2828 = 2^2 * 7 * 101
# sumdivisor(2828) = (2^3-1)/(2-1) * (7^2-1)/(7-1) * (101^2-1)/(101-1)
#                  = 7 * 8 * 102 = 5712
# for 101, f = (p^(k+1)-p) / (p^(k+1)-1) = 10100 / 10200
#      so 5712 * 10100 / 10200 = 5656
#
sub pred {
  my ($self, $value) = @_;
  ### Abundant pred(): $value

  if ($value != int($value)) {
    return 0;
  }
  my ($good, @primes) = _prime_factors($value);
  return undef unless $good;
  ### @primes

  my $zero = ($value*0);  # inherit bignum 0
  my $sigma = $zero + 1;  # inherit bignum 1
  my $max_term = 1;

  while (defined (my $p = shift @primes)) {
    my $pow = $p + $zero;
    while (($primes[0]||0) == $p) {
      $pow *= $p;
      shift @primes;
    }
    ### $p
    ### $pow

    my $term = ($pow*$p - 1) / ($p-1);
    $max_term = _max($max_term, $term);
    $sigma *= $term;
  }

  $value *= 2;
  ### $sigma
  ### 2*value: $value

  if ($self->{'abundant_type'} eq 'deficient') {
    return $sigma < $value;
  }

  if ($sigma <= $value) {
    ### small sigma, not abundant ...
    return 0;
  }

  if ($self->{'abundant_type'} eq 'abundant') {
    ### abundant ...
    return 1;
  }

  if ($sigma - $sigma / $max_term > $value) {
    ### abundant but non-primitive ...
    return ($self->{'abundant_type'} eq 'non-primitive');
  } else {
    ### abundant and also primitive ...
    return ($self->{'abundant_type'} eq 'primitive');
  }
}

#------------------------------------------------------------------------------

# pending List::Util max() correctly handling BigInt etc overloads
sub _max {
  my $ret = shift;
  while (@_) {
    my $next = shift;
    if ($next > $ret) {
      $ret = $next;
    }
  }
  return $ret;
}

1;
__END__

# This was next() done by sieve, but it's scarcely faster than ith() and
# uses a lot of memory if call next() for a long time.
#
# sub rewind {
#   my ($self) = @_;
#   $self->{'i'} = $self->i_start;
#   $self->{'done'} = 0;
#   _restart_sieve ($self, 20);
# }
# sub _restart_sieve {
#   my ($self, $hi) = @_;
#   ### _restart_sieve() ...
#   $self->{'hi'} = $hi;
#   my $array = $self->{'array'} = [];
#   $#$array = $hi;  # pre-extend
#   $array->[0] = 1;
#   $array->[1] = 1;
#   return $array;
# }
#
# sub next {
#   my ($self) = @_;
#   ### Abundant next(): $self->{'i'}
#
#   my $v = $self->{'done'};
#   my $primitive = ($self->{'abundant_type'} eq 'primitive');
#   my $deficient = ($self->{'abundant_type'} eq 'deficient');
#   my $hi = $self->{'hi'};
#   my $array = $self->{'array'};
#
#   for (;;) {
#     ### consider: "v=".($v+1)."  cf done=$self->{'done'}"
#     if (++$v > $hi) {
#       $array = _restart_sieve ($self,
#                                $hi = ($self->{'hi'} *= 2));
#       $v = 2;
#       ### restart to v: $v
#     }
#
#     my $sigma = $array->[$v];
#     if (defined $sigma) {
#       ### composite: $v, $sigma
#
#       if ($primitive && $sigma>2*$v) {
#         for (my $j = $v; $j <= $hi; $j += $v) {
#           $array->[$j] = 0;  # zap multiples of this abundant
#         }
#       }
#       if ($v > $self->{'done'}
#           && ($deficient
#               ? $sigma<2*$v   # deficient
#               : $sigma>2*$v)  # abundant
#          ) {
#         return ($self->{'i'}++,
#                 $self->{'done'} = $v);
#       }
#       # if ($] >= 5.006) {
#       #   delete $array->[$v];
#       # } else {
#       #   undef $array->[$v];
#       # }
#
#     } else {
#       ### prime: $v
#       my $prev = 1;
#       for (my $step = $v; $step <= $hi; $step *= $v) {
#         my $this = $prev + $step;
#         ### $step
#         ### $prev
#         ### $this
#         for (my $j = $step; $j <= $hi; $j += $step) {
#           ### $j
#           ### before: $array->[$j]
#           $array->[$j] = ($array->[$j]||1) / $prev * $this;
#           ### after: $array->[$j]
#         }
#         $prev = $this;
#       }
#       # print "applied: $v\n";
#       # for (my $j = 0; $j < $hi; $j++) {
#       #   printf "  %2d %2d\n", $j, ($array->[$j]||0);
#       # }
#
#       if ($v > $self->{'done'}
#           && $deficient) {  # primes are always deficient
#         return ($self->{'i'}++,
#                 $self->{'done'} = $v);
#       }
#     }
#   }
# }

=for stopwords Ryde Math-NumSeq abundants oldterm Mersenne ie

=head1 NAME

Math::NumSeq::Abundant -- abundant numbers, greater than sum of divisors

=head1 SYNOPSIS

 use Math::NumSeq::Abundant;
 my $seq = Math::NumSeq::Abundant->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The abundant numbers, being integers greater than the sum of their divisors,

    12, 18, 20, 24, 30, 36, ...
    starting i=1

For example 12 is abundant because its divisors 1,2,3,4,6 add up to 16 which
is E<gt> 12.

This is often expressed as 2*nE<gt>sigma(n) where sigma(n) is the sum of
divisors of n including n itself.

=head2 Deficient

Option C<abundant_type =E<gt> "deficient"> is those integers n with n E<lt>
sum divisors,

    abundant_type => "deficient"
    1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 13,

This is the opposite of abundant, except the few perfect numbers n == sum
divisors are excluded (see L</Perfect Numbers> below).

=head2 Primitive Abundant

Option C<abundant_type =E<gt> "primitive"> gives abundant numbers which are
not a multiple of some smaller abundant,

    abundant_type => "primitive"
    12, 18, 20, 30, 42, 56, 66, 70, 78, ...

If an integer n is abundant then so are all multiples 2*n, 3*n, 4*n, etc.
The "primitive" abundants are those which are not such a multiple.

Option C<abundant_type =E<gt> "non-primitive"> gives abundant numbers which
are not primitive, ie. which have a divisor which is also abundant.

    abundant_type => "non-primitive"
    24, 36, 40, 48, 54, 60, 72, 80, 84, ...

The abundant are all either primitive or non-primitive.

=head2 Perfect Numbers

Numbers with n == sum divisors are the perfect numbers 6, 28, 496, 8128,
33550336, etc.  There's nothing here for them currently.  They're quite
sparse, with Euler proving the even ones are always n=2^(k-1)*(2^k-1) for
prime 2^k-1 (those being the Mersenne primes).  The existence of any odd
perfect numbers is a famous unsolved problem.  If there are any odd perfect
numbers then they're very big.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::Abundant-E<gt>new ()>

=item C<$seq = Math::NumSeq::Abundant-E<gt>new (abundant_type =E<gt> $str)>

Create and return a new sequence object.  C<abundant_type> (a string) can be

   "abundant"        n > sum divisors (the default)
   "deficient"       n < sum divisors
   "primitive"       abundant and not a multiple of an abundant
   "non-primitive"   abundant and also a multiple of an abundant

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is abundant, deficient or primitive abundant per
C<$seq>.

This check requires factorizing C<$value> and in the current code a hard
limit of 2**32 is placed on values to be checked, in the interests of not
going into a near-infinite loop.

=back

=head1 FORMULAS

=head2 Predicate

For prime factorization n=p^a * q^b * ... the divisors are all of

    divisor = p^A * q^B * ...   for A=0 to a, B=0 to b, etc

This includes n itself with A=a,B=b,etc.  The sum is formed by grouping each
with factor p^i, etc, resulting in a product,

    sigma =   (1 + p + p^2 + ... + p^a)
            * (1 + q + q^2 + ... + q^a)
            * ...

    sigma = (p^(a+1)-1)/(p-1) * (q^(b+1)-1)/(q-1) * ...

So from the prime factorization of n the sigma is formed and compared
against n,

    sigma > 2*n      abundant
    sigma < 2*n      deficient

=head2 Predicate -- Primitive

For primitive abundant we want to know also that no divisor of n is
abundant.

For divisors of n it suffices to consider n reduced by a single prime, so
n/p.  If taking out some non-prime such as n/(p*q) gives an abundant then so
is n/p because it's a multiple of n/(p*q).  To testing an n/p for abundance,

    sigma(n/p) > 2*n/p     means have an abundant divisor

sigma(n/p) can be calculated from sigma(n) by dividing out the p^a term
described above and replacing it with the term for p^(a-1).

    oldterm = (p^(a+1) - 1)/(p-1)
    newterm = (p^a     - 1)/(p-1)

    sigma(n) * newterm / oldterm > n/p
    sigma(n) * p*newterm / oldterm > n

p*newterm/oldterm simplifies to

    sigma(n) * (1 - 1/oldterm) > n      means an abundant divisor

The left side is a maximum when the factor (1 - 1/oldterm) reduces sigma(n)
by the least, and that's when oldterm is the biggest.  So to test for
primitive abundance note the largest term in the sigma(n) calculation above.

    if sigma(n) > 2*n
    then n is abundant

    if sigma(n) * (1-1/maxterm) > 2*n
    then have an abundant divisor and so n is not primitive abundant

=head1 SEE ALSO

L<Math::NumSeq>

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

# Copyright 2011, 2012, 2013, 2014, 2016, 2017 Kevin Ryde

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


package Math::NumSeq::DivisorCount;
use 5.004;
use strict;

use vars '$VERSION','@ISA';
$VERSION = 73;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');

use Math::NumSeq::PrimeFactorCount;
*_prime_factors = \&Math::NumSeq::PrimeFactorCount::_prime_factors;


# use constant name => Math::NumSeq::__('Divisor Count');
use constant description => Math::NumSeq::__('Count of divisors of i (including 1 and i).');
use constant i_start => 1;
use constant characteristic_count => 1;
use constant characteristic_smaller => 1;
use constant characteristic_increasing => 0;


# "proper" divisors just means 1 less in each value, not sure much use for
# that.
#
# n itself -- proper, or not
# 1        -- proper, or not
# square, non-square
#
# use constant parameter_info_array =>
#   [ { name    => 'divisor_type',
#       display => Math::NumSeq::__('Divisor Type'),
#       type    => 'enum',
#       choices => ['all','proper'],   # ,'propn1'
#       default => 'all',
#       # description => Math::NumSeq::__(''),
#     },
#   ];


my %values_min = (all    => 1,
                  proper => 0,
                  propn1 => 0);
sub values_min {
  my ($self) = @_;
  # or values_min=0 if i_start=0
  return 1;       # $values_min{$self->{'divisor_type'}};
}

#------------------------------------------------------------------------------
# cf A032741 - 1 <= d < n starting n=0
#    A147588 - 1 < d < n starting n=1
#
#    A006218 - cumulative count of divisors
#    A002541 - cumulative proper divisors
#
#    A001227 - count odd divisors
#    A001826 - count 4k+1 divisors
#    A038548 - count divisors <= sqrt(n)
#    A070824 - proper divisors starting n=2
#    A002182 - number with new highest number of divisors
#    A002183 -    that count of divisors
#    A001876 - count 5k+1 divisors
#    A001877 - count 5k+2 divisors
#    A001878 - count 5k+3 divisors
#    A001899 - count 5k+4 divisors
#
#    A028422 - count of ways to factorize
#    A033834 - n with new high count factorizations
#    A033833 - highly factorable
#
#    A056595 - count non-square divisors
#    A046951 - count square divisors
#    A013936 - cumulative count square divisors
#    A137518 - same divisor count as n, and > a(n-1) so increasing
#
sub oeis_anum {
  my ($self) = @_;
  return 'A000005';
  # OEIS-Catalogue: A000005

  # my %oeis_anum = (all    => 'A000005',  # all divisors starting n=1
  #                  # proper => 'A032741', # starts n=0 ...
  #                  # propn1 => 'A147588',
  #                 );
  # return $oeis_anum{$self->{'divisor_type'}};
}


#------------------------------------------------------------------------------
sub ith {
  my ($self, $i) = @_;

  $i = abs($i);
  if ($i == 0) {
    return 0;
  }

  # If i = p^a * q^b * ... then divisorcount = (a+1)*(b+1)*...
  # which is each possible power p^0, p^1, ..., p^a of each prime,
  # including all zeros p^0*q^0*... = 1 and p^a*q^b*... itself.
  #
  # If i is a primorial 2*3*5*7*13*... with k primes then divisorcount=2^k
  # so the $value product can become a bignum if $i is a bignum.

  my ($good, @primes) = _prime_factors($i);
  return undef unless $good;

  my $value = ($i*0) + 1;   # inherit possible bignum
  my $prev = 0;
  my $dcount = 1;
  while (my $p = shift @primes) {
    if ($p == $prev) {
      $dcount++;
    } else {
      $value *= $dcount;
      $dcount = 2;
      $prev = $p;
    }
  }
  return $value * $dcount;

  # if ($self->{'divisor_type'} eq 'propn1') {
  #   if ($ret <= 2) {
  #     return 0;
  #   }
  #   $ret -= 2;
  # }
}

sub pred {
  my ($self, $value) = @_;
  return ($value >= 1 && $value == int($value));
}

1;
__END__


# This was next() done by sieve, but it's slower from about i=5000 with XS
# code for prime_factors() and it uses a lot of memory if continue next()
# for a long time.
#
# sub rewind {
#   my ($self) = @_;
#   ### DivisorCount rewind()
#   $self->{'i'} = $self->i_start;
#   _restart_sieve ($self, 5);
# }
# sub _restart_sieve {
#   my ($self, $hi) = @_;
# 
#   $self->{'hi'} = $hi;
#   $self->{'array'} = [ 0, (1) x $self->{'hi'} ];
# }
# 
# sub next {
#   my ($self) = @_;
#   ### DivisorCount next(): $self->{'i'}
# 
#   my $hi = $self->{'hi'};
#   my $start = my $i = $self->{'i'}++;
#   if ($i > $hi) {
#     _restart_sieve ($self, $hi *= 2);
#     $start = 2;
#   }
# 
#   my $aref = $self->{'array'};
#   if ($start <= $i) {
#     if ($start < 2) {
#       $start = 2;
#     }
#     foreach my $i ($start .. $i) {
#       if ($aref->[$i] == 1) {
#         ### apply prime: $i
#         my $step = 1;
#         for (my $pcount = 1; ; $pcount++) {
#           $step *= $i;
#           ### $step
#           last if ($step > $hi);
#           my $pmul = $pcount+1;
#           for (my $j = $step; $j <= $hi; $j += $step) {
#             ($aref->[$j] /= $pcount) *= $pmul;
#           }
#           # last if $self->{'divisor_type'} eq 'propn1';
#         }
#         # print "applied: $i\n";
#         # for (my $j = 0; $j < $hi; $j++) {
#         #   printf "  %2d %2d\n", $j, vec($$aref, $j,8));
#         # }
#       }
#     }
#   }
#   ### ret: "$i, $aref->[$i]"
#   return ($i, $aref->[$i]);
# }


=for stopwords Ryde Math-NumSeq

=head1 NAME

Math::NumSeq::DivisorCount -- how many divisors

=head1 SYNOPSIS

 use Math::NumSeq::DivisorCount;
 my $seq = Math::NumSeq::DivisorCount->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The number of divisors of i,

    1, 2, 2, 3, 2, 4, 2, 4, 3, 4, 2, 6, 2, 4, 4, 5, 2, 6, 2, ...
    starting i=1

i=1 is divisible only by 1 so value=1.  Then i=2 is divisible by 1 and 2 so
value=2.  Or for example i=6 is divisible by 4 numbers 1,2,3,6 so value=4.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::DivisorCount-E<gt>new ()>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the number of prime factors in C<$i>.

This calculation requires factorizing C<$i> and in the current code after
small factors a hard limit of 2**32 is enforced in the interests of not
going into a near-infinite loop.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs as a divisor count, which simply means
C<$value E<gt>= 1>.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::PrimeFactorCount>

L<Math::Factor::XS>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2016, 2017 Kevin Ryde

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

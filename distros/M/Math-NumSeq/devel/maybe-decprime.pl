#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.


# prime to test much too big too quickly without some special strategy ...
#
# $values_info{'binary_primes'} =
#   { subr => \&values_make_binary_primes,
#     pred => \&is_binary_prime,
#     name => Math::NumSeq::__('Binary is Decimal Prime'),
#     description => Math::NumSeq::__('Numbers which when written out in binary are a decimal prime.  For example 185 is 10011101 which in decimal is a prime.'),
#   };
# sub values_make_binary_primes {
#   my ($self, $lo, $hi) = @_;
#   require Math::Prime::XS;
#   Math::Prime::XS->VERSION (0.22);
#   my $n = $lo-1;
#   return sub {
#     for (;;) {
#       if (++$n > $hi) {
#         return undef;
#       }
#       if ($self->is_binary_prime($n)) {
#         ### return: $n
#         return $n;
#       }
#     }
#   };
#   # require Math::BaseCnv;
#   # ### primes hi: sprintf('%b', $hi+1)
#   # my @array = map {Math::BaseCnv::cnv($_,2,10)}
#   #   grep {/^[01]+$/}
#   #   Math::Prime::XS::sieve_primes (sprintf('%b', $lo),
#   #                                  sprintf('%b', $hi+1));
#   # @array = @array;
#   # return $self->make_iter_arrayref (\@array);
# }
# sub is_binary_prime {
#   my ($self, $n) = @_;
#   ### $n
#   ### binary: sprintf('%b',$n)
#   # my $p = Math::Prime::XS::is_prime(sprintf('%b',$n));
#   # ### isprime: $p
#   return Math::Prime::XS::is_prime(sprintf('%b',$n))
# }

# binary form gets too big to prime check
# sub values_make_binary_primes {
#   my ($self, $lo, $hi) = @_;
# 
#   require Math::Prime::XS;
#   Math::Prime::XS->VERSION (0.22);
#   my $i = 1;
#   return sub {
#     for (;;) {
#       $i += 2;
#       if (Math::Prime::XS::is_prime($i)) {
#         return $i;
#       }
#     }
#   };
# }


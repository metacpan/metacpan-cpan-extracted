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


# use constant::defer bigint => sub {
#   require Math::BigInt;
#   Math::BigInt->import (try => 'GMP');
#   undef;
# };
# 
# # FIXME: although this converges much too slowly
# sub values_make_ln3 {
#   my ($self, $lo, $hi) = @_;
# 
#   bigint();
#   my $calcbits = int($hi * 1.5 + 20);
#   ### $calcbits
#   my $total = Math::BigInt->new(0);
#   my $num = Math::BigInt->new(1);
#   $num->blsft ($calcbits);
#   for (my $k = 0; ; $k++) {
#     my $den = 2*$k + 1;
#     my $q = $num / $den;
#     $total->badd ($q);
#     #     printf("1 / 4**%-2d * %2d   %*s\n", $k, 2*$k+1,
#     #            $calcbits/4+3, $q->as_hex);
#     $num->brsft(2);
#     if ($num < $den) {
#       last;
#     }
#   }
#   #   print $total->as_hex,"\n";
#   #   print $total,"\n";
#   #   print $total->numify / 2**$bits,"\n";
#   return binary_positions($total, $hi);
# }


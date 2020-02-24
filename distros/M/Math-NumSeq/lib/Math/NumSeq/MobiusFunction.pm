# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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

package Math::NumSeq::MobiusFunction;
use 5.004;
use strict;
use List::Util 'min','max';

use vars '$VERSION','@ISA';
$VERSION = 74;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Fibonacci;
*_blog2_estimate = \&Math::NumSeq::Fibonacci::_blog2_estimate;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Mobius Function');
use constant description => Math::NumSeq::__('The Mobius function, being 1 for an even number of prime factors, -1 for an odd number, or 0 if any repeated factors (ie. not square-free).');
use constant characteristic_increasing => 0;
use constant characteristic_integer => 1;
use constant values_min => -1;
use constant values_max => 1;
use constant default_i_start => 1;

#------------------------------------------------------------------------------
# cf A030059 the -1 positions, being odd number of distinct primes
#    A030229 the 1 positions, being even number of distinct primes
#    A013929 the 0 positions, being square factor, ie. the non-square-frees
#    A005117 square free numbers, mobius -1 or +1
#
use constant oeis_anum => 'A008683'; # mobius -1,0,1 starting i=1


#------------------------------------------------------------------------------

sub ith {
  my ($self, $i) = @_;
  ### MobiusFunction ith(): $i

  my $ret = 0;

  if (_is_infinite($i) || $i < 0) {
    return undef;
  }

  if (($i % 2) == 0) {
    $i /= 2;
    if (($i % 2) == 0) {
      return 0;  # square factor
    }
    $ret = 1;
  }

  if ($i <= 0xFFFF_FFFF) {
    $i = "$i"; # numize Math::BigInt for speed
  }

  my $sqrt = int(sqrt($i));
  my $limit = min ($sqrt,
                   10_000 / (_blog2_estimate($i) || 1));
  ### $sqrt
  ### $limit

  for (my $p = 3; $p <= $limit; $p += 2) {
    if (($i % $p) == 0) {
      $i /= $p;
      if (($i % $p) == 0) {
        ### square factor, zero ...
        return 0;
      }
      $ret ^= 1;
      $sqrt = int(sqrt($i));  # new smaller limit
      $limit = min ($sqrt, $limit);
      ### factor: "$p new ret $ret new limit $limit"
    }
  }
  if ($sqrt > $limit) {
    ### not all factors found up to limit ...
    # ENHANCE-ME: prime_factors() here if <2^32
    return undef;
  }
  if ($i != 1) {
    $ret ^= 1;
  }
  return ($ret ? -1 : 1);
}

sub pred {
  my ($self, $value) = @_;
  return ($value == 0 || $value == 1 || $value == -1);
}

1;
__END__

# This was next() done by sieve, but it's scarcely faster than ith() and
# uses a lot of memory if call next() for a long time.
#
# # each 2-bit vec() value is
# #    0 unset
# #    1 square factor
# #    2 even count of factors
# #    3 odd count of factors
# 
# my @transform = (0, 0, 1, -1);
# 
# sub rewind {
#   my ($self) = @_;
#   $self->{'i'} = $self->i_start;
#   _restart_sieve ($self, 500);
# }
# sub _restart_sieve {
#   my ($self, $hi) = @_;
#   ### _restart_sieve() ...
#   $self->{'hi'} = $hi;
#   $self->{'string'} = "\0" x (($hi+1)/4);  # 4 of 2 bits each
#   vec($self->{'string'}, 0,2) = 1;  # N=0 treated as square
#   vec($self->{'string'}, 1,2) = 2;  # N=1 treated as even
# }
# 
# sub next {
#   my ($self) = @_;
# 
#   my $i = $self->{'i'}++;
#   my $hi = $self->{'hi'};
#   if ($i <= 1) {
#     if ($i <= 0) {
#       return ($i, 0);
#     }
#     else {
#       return ($i, 1);
#     }
#   }
# 
#   my $start = $i;
#   if ($i > $hi) {
#     _restart_sieve ($self, $hi *= 2);
#     $start = 2;
#   }
#   my $sref = \$self->{'string'};
# 
#   my $ret;
#   foreach my $i ($start .. $i) {
#     $ret = vec($$sref, $i,2);
#     if ($ret == 0) {
#       ### prime: $i
#       $ret = 3; # odd
# 
#       # existing squares $v==1 left alone, others toggle 2=odd,3=even
#       for (my $j = $i; $j <= $hi; $j += $i) {
#         ### p: "$j ".vec($$sref, $j,2)
#         if ((my $v = vec($$sref, $j,2)) != 1) {
#           vec($$sref, $j,2) = ($v ^ 1) | 2;
#           ### set: vec($$sref, $j,2)
#         }
#       }
# 
#       # squares set to $v==1
#       my $step = $i * $i;
#       for (my $j = $step; $j <= $hi; $j += $step) {
#         vec($$sref, $j,2) = 1;
#       }
#       # print "applied: $i\n";
#       # for (my $j = 0; $j < $hi; $j++) {
#       #   printf "  %2d %2d\n", $j, vec($$sref,$j,2);
#       # }
#     }
#   }
#   ### ret: "$i, $ret -> ".$transform[$ret]
#   return ($i, $transform[$ret]);
# }

=for stopwords Ryde Mobius ie Math-NumSeq

=head1 NAME

Math::NumSeq::MobiusFunction -- Mobius function sequence

=head1 SYNOPSIS

 use Math::NumSeq::MobiusFunction;
 my $seq = Math::NumSeq::MobiusFunction->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The sequence of the Mobius function,

    1, -1, -1, 0, -1, 1, ...
    starting i=1

Each value is

    1   if i has an even number of distinct prime factors
    -1  if i has an odd number of distinct prime factors
    0   if i has a repeated prime factor

The sequence starts from i=1 and it's reckoned as no prime factors, ie. 0
factors, which is considered even, hence value=1.  Then i=2 and i=3 are
value=-1 since they have one prime factor (they're primes), and i=4 is
value=0 because it's 2*2 which is a repeated prime 2.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::MobiusFunction-E<gt>new ()>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the Mobius function of C<$i>, being 1, 0 or -1 according to the prime
factors of C<$i>.

This calculation requires factorizing C<$i> and in the current code small
primes are checked then a hard limit of 2**32 is placed on C<$i>, in the
interests of not going into a near-infinite loop.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs in the sequence, which means simply 1, 0
or -1.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::LiouvilleFunction>,
L<Math::NumSeq::PrimeFactorCount>

L<Math::Prime::Util/moebius>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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

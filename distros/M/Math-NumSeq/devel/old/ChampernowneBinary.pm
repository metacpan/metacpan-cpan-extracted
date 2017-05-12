
   # # A030190 bits, A030303 positions of 1s
   # [ 'Math::NumSeq::ChampernowneBinary', 0,
   #   [ 1, 2, 4, 5, 6, 9, 11, 12, 13, 15, 16, 17, 18, 22,
   #     25, 26, 28, 30, 32, 33, 34, 35, 38, 39, 41, 42, 43,
   #     44, 46, 47, 48, 49, 50, 55, 59, 60, 63, 65, 68, 69,
   #     70, 72, 75, 77, 79, 80, 82, 83, 85, 87, 88, 89, 90,
   #     91, 95, 96, 99, 100, 101, 103, 105 ] ],



# Copyright 2010, 2011, 2013 Kevin Ryde

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

package Math::NumSeq::ChampernowneBinary;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 86;
use Math::NumSeq;
@ISA = ('Math::NumSeq');


# uncomment this to run the ### lines
#use Smart::Comments;

# use constant name => Math::NumSeq::__('Champernowne Sequence');
use constant description => Math::NumSeq::__('Champernowne sequence 1 positions, 1,2,4,5,6,9,11,etc, being the 1-bit positions when the integers 1,2,3,4,5 etc are written out concatenated in binary 1 10 11 100 101 etc.');
use constant i_start => 1;
use constant values_min => 1;
use constant characteristic_increasing => 1;

# 0 1 10  11 100 101  110 111
#   1 2  4,5 6   9,11 12,13 15,16,17,
#    
# cf A030302 - base 2, starting i=1 value=1
#    A030190 - base 2, start i=0 value=0
#    A030303 - base 2 positions of 1s, start 1
#    A030308 - binary reverse starting from 1
#    A030309 - positions of 0 in reverse
#    A030310 - positions of 1 in reverse
#    A030305 - base 2 lengths of runs of 0s
#    A030306 - base 2 lengths of runs of 1s
#
#    A003137 - base 3, start i=1 value=1
#    A054635 - base 3, start i=0 value=0
#    A054637 - base 3 partial sums, start i=0 value=0
#
#    A030998 - base 7, start i=0 value=0
#    A031007 - base 7 reverse, start i=1 value=1
#
#    A031035 - base 8, start i=1 value=1
#    A054634 - base 8, start i=0 value=0
#    A031045 - base 8 reverse, start i=1 value=1
#
#    A031076 - base 9, start i=1 value=1
#    A031087 - base 9 reverse, start i=1 value=1
#
#    A033307 - decimal, start i=1 value=1
#    A007376 - same, decimal, Barbier infinite word, start i=1 value=1
#    A054632 - decimal partial sums
#    A031298 - decimal reverse to LSB digit first, start i=1 value=1
#
#    A136414 - decimal 2 digits at a time, start i=1 value=1
#    A193431 - decimal 3 digits at a time
#    A193492 - decimal 4 digits at a time
#    A193493 - decimal 5 digits at a time
#    A001704 - concatenate n,n+1
#    A127421 - numbers concat of n,n+1, eg. 1819
#
#    A033308 - concatenate primes
#
# sub oeis_anum {
#   my ($class_or_self) = @_;
#   if (! ref $class_or_self ||
#       $class_or_self->{'radix'} == 2) {
#     return 'A030303';
#   }
#   return undef;
# }
#
use constant oeis_anum => 'A030303'; # position of i'th 1


sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  $self->{'n'} = 0;
  $self->{'val'} = 0;
  $self->{'bitmask'} = 0;
}
sub next {
  my ($self) = @_;
  ### ChampernowneBinary next(): $self

  my $bitmask = $self->{'bitmask'};
  for (;;) {
    if ($bitmask == 0) {
      $self->{'val'}++;
      $bitmask = 1;
      while ($bitmask <= $self->{'val'}) {
        $bitmask <<= 1;
      }
      $bitmask >>= 1;
      ### next val: sprintf('%#X',$self->{'val'})
      ### bitmask: sprintf('%#X',$bitmask)
    }
    $self->{'n'}++;
    if ($bitmask & $self->{'val'}) {
      $self->{'bitmask'} = $bitmask >> 1;
      ### result: $self->{'n'}
      return ($self->{'i'}++, $self->{'n'});
    }
    $bitmask >>= 1;
  }
}

# ENHANCE-ME: msb 1 bit position determines next lower (k+1)*2^k.
#
# 0   0 1
# 2   10 11
# 6   100 101 110 111
#
sub pred {
  my ($self, $n) = @_;
  ### ChampernowneBinary pred(): $n
  if ($n < 2) { return $n; }

  my $base = 2;
  my $bits_each = 2;
  my $nums = 2;
  for (;;) {
    my $next_base = $base + $nums*$bits_each;
    last if ($next_base > $n);
    $base = $next_base;
    $bits_each++;
    $nums <<= 1;
  }
  $n -= $base;
  ### offset: $n
  my $pos = (-1-$n) % $bits_each;
  $n = int($n / $bits_each) + $nums;
  ### $base
  ### $bits_each
  ### $nums
  ### $pos
  ### val: sprintf('%#X',$n)
  return (($n >> $pos) & 1);
}

1;
__END__


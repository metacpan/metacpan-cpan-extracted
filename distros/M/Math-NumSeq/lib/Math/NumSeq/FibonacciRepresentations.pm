# Copyright 2014, 2016, 2019 Kevin Ryde

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


# https://eudml.org/doc/92679
# J. Berstel, An Exercise on Fibonacci Representations, RAIRO/
# Informatique Theorique, Vol. 35, No 6, 2001, pp. 491-498, in
# the issue dedicated to Aldo De Luca on the occasion of his
# 60-th anniversary.

# Paul K. Stockmeyer, "A Smooth Tight Upper Bound for the Fibonacci
# Representation Function R(N)", Fibonacci Quarterly, Volume 46/47, Number
# 2, May 2009.
# Free access only post 2003
# http://www.fq.math.ca/46_47-2.html
# http://www.fq.math.ca/Papers/46_47-2/Stockmeyer.pdf

# Klarner 1966
# Product (1+x^fib(i)) gives coefficients R(N)
# R(F[n])   = floor((n+2)/2)       n > 1
# R(F[n]-1) = floor((n+1)/2)       n > 0
# R(F[n]-2) = n-2                  n > 2
# R(F[n]-3) = n-3                  n > 4

# http://www.math.tugraz.at/~edson/Publications/Representations%20in%20Fibonacci%20Base.pdf


package Math::NumSeq::FibonacciRepresentations;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 74;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth', 'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
# use Smart::Comments;

# use constant name => Math::NumSeq::__('Fibonacci Representations');
use constant description => Math::NumSeq::__('Fibonacci representations sequence, the number of ways i can be formed as a sum of distinct Fibonacci numbers.');
use constant default_i_start => 0;
use constant characteristic_count => 1;
use constant characteristic_smaller => 1;
use constant characteristic_integer => 1;
use constant characteristic_increasing => 0;
use constant values_min => 1;

#------------------------------------------------------------------------------
#
use constant oeis_anum => 'A000119';

#------------------------------------------------------------------------------

sub ith {
  my ($self, $i) = @_;
  return ($self->ith_pair($i))[0];
}

sub ith_pair {
  my ($self, $i) = @_;
  ### ith_pair(): $i

  if ($i < 0) {
    return (undef,undef);
  }
  if (_is_infinite($i)) {
    return ($i,$i);  # +inf or nan
  }

  # seeking f2 >= i+1
  # but stop at f1 >= i so not go past UV_MAX if i=UV_MAX
  #
  my @fibs;  # all Fibonacci numbers <= $i
  {
    # find biggest fibonacci f1 <= i
    # if f1+f0 > i then stop loop
    # f1+f0 might overflow UV_MAX so do the loop
    # condition as stop when f1 > i-f0, continue while f1 <= i-f0
    #
    my $f0 = ($i*0) + 1;   # $f0=1, inherit bignum from $i
    my $f1 = $f0 + 1;      # $f1=2, inherit bignum from $i
    while ($f0 <= $i-$f1) {
      push @fibs, $f0;
      ($f1,$f0) = ($f1+$f0,$f1);
    }
    ### @fibs
    ### $f0
    ### $f1

    # here have f1 <= i < f0+f1
    # subtract i+1 - f1
    $i -= $f1;
    $i += 1;
    ### i+1 - f1: $i

    # If i+1-f1 >= f0 then high fib is not the f1 just subtracted but
    # instead f2=f1+f0.  Subtract also f0 so i+1 - (f1+f0).  Now skip f1
    # since the Zeck form has no consecutive fibs.  Push f0 onto @fibs to be
    # the next fib tested in the loop.
    #
    # Actually i+1-(f1+f0) = 0 here, since f1 <= i and f0+f1 <= i+1 means
    # i+1==f0+f1 exactly.  Could return r += $#fibs/2 which is the effect of
    # every second 0-bit step, but i+1=fibonacci will be fairly rare.
    #
    # If i+1-f1 < f0 then high fib is f1 just subtracted.  Now skip f0 since
    # the Zeck form has no consecutive fibs.
    #
    if ($i >= $f0) {
      return (1, int(scalar(@fibs)/2) + 2);

      # $i -= $f0;
      # ### subtract f0, so i+1 sub f2=f1+f0: $i
      # push @fibs, $f0;
    }
  }

  my $r = 1;         # R(0) = 1
  my $rplus1 = 1;    # R(1) = 1
  my $odd_zeros = 1; # high zeck "10..." initial zero

  while (my $f = pop @fibs) {
    ### at: "f=$f i=$i  r=$r rplus1=$rplus1   odd_zeros=$odd_zeros"

    if ($i < $f) {
      ### 0-bit ...

      if ($odd_zeros) {
        ### odd zeros on i+1, add to rplus1 ...
        $rplus1 += $r;
      }
      $odd_zeros ^= 1;

    } else {
      $i -= $f;
      ### 1-bit sub: "$f to i=$i"

      if ($odd_zeros) {
        ### odd zeros on i+1, add to r ...
        $r += $rplus1;
      } else {
        ### even zeros on i+1, r same as rplus1 ...
        $r = $rplus1;
      }

      ### never consecutive fibs, so pop without comparing to i ...
      pop @fibs || last;
      $odd_zeros = 1;   # one trailing 0-bit is odd
    }
  }

  ### final: "r=$r  rplus1=$rplus1"
  return ($r, $rplus1);
}

sub pred {
  my ($self, $value) = @_;
  ### FibonacciRepresentations pred(): $value
  return ($value >= 1 && $value == int($value));
}

1;
__END__


# Old ith() code which calculated pair R(i-1),R(i).
#
# {
#   # f1+f0 > i
#   # f0 > i-f1
#   # check i-f1 as the stopping point, so that if i=UV_MAX then won't
#   # overflow a UV trying to get to f1>=i
#   #
#   my @fibs;  # all Fibonacci numbers <= $i
#   {
#     my $f0 = ($i * 0);  # inherit bignum 0
#     my $f1 = $f0 + 1;   # inherit bignum 1
#     @fibs = ($f0);
#     while ($f0 <= $i-$f1) {
#       ($f1,$f0) = ($f1+$f0,$f1);
#       push @fibs, $f1;
#     }
#   }
#   ### @fibs
#
#   my $rsub1 = 1;  # R(0) = 1
#   my $r = 1;      # R(1) = 1
#   my $trailing = 0;
#   while (my $f = pop @fibs) {
#     ### at: "f=$f i=$i  r=$r rsub1=$rsub1   trailing=$trailing"
#
#     if ($i < $f) {
#       ### 0-bit ...
#
#       if ($trailing) {
#         ### odd trailing zeros, add to r ...
#         $r += $rsub1;
#       }
#       $trailing ^= 1;
#
#     } else {
#       $i -= $f;
#       ### 1-bit sub: "$f to i=$i"
#
#       if ($trailing) {
#         ### odd trailing zeros, add to rsub1 ...
#         $rsub1 += $r;
#       } else {
#         ### even trailing zeros, rsub1 same as r ...
#         $rsub1 = $r;
#       }
#
#       # never consecutive fibs, so pop without comparing to i
#       pop @fibs || last;
#       $trailing = 1;   # one trailing 0-bit is odd
#     }
#   }
#
#   ### final: "r=$r  rsub1=$rsub1"
#   return $r;
# }

# Old ith() code which counted representations by subtracting fibs.
#
# {
#   my $count = 0;
#   my @fibs;
#   my @cumul;
#   {
#     my $zero = ($i * 0);
#     my $f0 = $zero + 1;  # inherit bignum 1
#     my $f1 = $zero + 2;  # inherit bignum 2
#     @fibs  = ($f1);
#     @cumul = ($f1 + 1);  # 2 + 1 = 3
#     while ($f0 <= $i-$f1) {
#       ($f1, $f0) = ($f1+$f0, $f1);
#       push @fibs, $f1;
#       push @cumul, $f1 + $cumul[-1];
#     }
#   }
#   ### @fibs
#
#   my @pending = ($i);
#   while (@fibs) {
#     my $f = pop @fibs;
#     my $c = pop @cumul;
#     ### at: "f=$f  cumul=$c  pending=".join(',',@pending)
#
#     my @new_pending;
#     foreach my $p (@pending) {
#       if ($p >= $f) {
#         ### sub to: $p-$f
#         push @new_pending, $p - $f;
#       }
#       if ($p < $c) {
#         push @new_pending, $p;
#       }
#     }
#     @pending = @new_pending;
#   }
#   ### final: "count=$count  pending=".join(',',@pending)
#   return $count + scalar(grep {$_<=1} @pending);
# }


=for stopwords Ryde Math-NumSeq duplications Ith Zeckendorf rprev mediant Berstel Informatics eg Bicknell Fibonaccis fibbinary

=head1 NAME

Math::NumSeq::FibonacciRepresentations -- count of representations by sum of Fibonacci numbers

=head1 SYNOPSIS

 use Math::NumSeq::FibonacciRepresentations;
 my $seq = Math::NumSeq::FibonacciRepresentations->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is the Fibonacci representations function R(i) which is the number of
ways i can be represented as a sum of distinct Fibonacci numbers,

    1, 1, 1, 2, 1, 2, 2, 1, 3, 2, 2, 3, 1, 3, 3, 2, 4, 2, 3, 3, ...
    starting i=0

For example R(11)=3 because 11 is a sum of Fibonacci numbers in the
following three different ways

    11 = 8 + 3                R(11)=3 sums
       = 8 + 2 + 1
       = 5 + 3 + 2 + 1

=head2 Array

The pattern in the values can be seen by arranging them in rows of an array.

                         1                          i=0 to 0
    1                                         1     i=0 to 1
    1                                         1     i=1 to 2
    1                    2                    1     i=2 to 4
    1               2         2               1     i=4 to 7
    1       3       2         2       3       1     i=7 to 12
    1     3   3     2    4    2     3   3     1     i=12 to 20
    1  4  3   3  5  2   4 4   2  5  3   3  4  1     i=20 to 33
    1 4 4 3 6 3 5 5 2 6 4 4 6 2 5 5 3 6 3 4 4 1     i=33 to 54
                                                  F[y]-1 to F[y+1]-1

There are Fibonacci F[y-1] many values in each row, running from i=F[y]-1 to
i=F[y+1]-1.  Notice the ranges overlap so each "1" at the right hand end is
a repeat of the "1" at the left end.  There's just a single 1 in the
sequence for each block.

New values in row y are the sum of adjacent values in row y-2, or
equivalently a pattern of duplications and sums from row y-1.  For example
in the third row the "2" has duplicated to be 2,2, then in the fourth row
the adjacent 1,2 values sum to give new "3".  The row y-2 is a kind of
Fibonacci style delay to when values are summed, resulting in F many values
in each row.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::FibonacciRepresentations-E<gt>new ()>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the C<$i>'th value of the sequence.

=item C<($v0, $v1) = $seq-E<gt>ith_pair($i)>

Return two values C<ith($i)> and C<ith($i+1)> from the sequence.  As
described below (L</Ith Pair>) two values can be calculated with the same
work as one.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs in the sequence, which means simply integer
C<$valueE<gt>=1>.

=back

=head1 FORMULAS

=head2 Ith Pair

For C<ith_pair()> the two sequence values at an arbitrary i,i+1 can be
calculated from the Zeckendorf form of i+1 (see
L<Math::NumSeq::Fibbinary/Zeckendorf Base>) as per

=over

Jean Berstel, "An Exercise on Fibonacci Representations", Theoretical
Informatics and Applications, volume 35, 2001, pages 491-498.
L<http://archive.numdam.org/numdam-bin/fitem?id=ITA_2001__35_6_491_0>

=back

Berstel uses a state machine which results in matrices based on runs of
consecutive 0-bits in the Zeckendorf form.  If making the Zeckendorf
breakdown by some sort of logarithm or high binary bit then that would be
Fibonacci number indices and their differences are the run lengths.

If making the Zeckendorf breakdown by individual Fibonacci number
comparisons to give the fibbinary form then it's convenient to take each bit
individually rather than in runs.  In the following algorithm, runs of
0-bits do "r += rprev" every second time and hence become "r +=
rprev*floor(run/2)" which is per the M matrices of Berstel.

    rprev = 1  = R(0)    will become R[i]
    r     = 1  = R(1)    will become R[i+1]
    zeros = 0            how many consecutive bit=0 seen

    for each bit of fibbinary(i+1) from high to low
      if bit=0 then
        if zeros odd then r += rprev
        zeros ^= 1
      if bit=1 then
        if zeros odd then rprev += r
                     else rprev = r
        zeros = 0

    result R[i]=rprev, R[i+1]=r

The loop maintains r=R[bits] where "bits" is those bits of fibbinary(i+1)
which have been processed so far.  rprev is the immediately preceding
sequence value.

The loop action is to append either a 0-bit or 1-bit Zeckendorf term to the
bits processed so far and step r,rprev accordingly.

"zeros" is the count of 0-bits seen since the last 1-bit.  This is kept only
modulo 2 since the test is just for odd or even run of zeros, not the full
count.

For a 1-bit the zeros count becomes 0 since there are now no 0-bits since
the last 1-bit seen.  In the Zeckendorf form a 1-bit always has a 0-bit
immediately below it.  That bit can be worked into the bit=1 case,

      if bit=1 then
        if zeros odd then rprev += r
                     else rprev = r
        next lower bit of fibbinary(i+1) is 0-bit, skip it
        zeros = 1

This is as if the bit=0 code is done immediately after the bit=1.  zeros=0
is even after the bit=1 so there's no change to r,rprev by the bit=0 code,
simply skip the 0-bit and record zeros=1.

When calculating Fibonacci numbers for fibbinary(i+1) it's desirable to use
integers E<lt>=i only so as not to overflow a finite number type.  This can
be done by finding the biggest Fibonacci f1E<lt>=i and subtracting it before
doing the +1, giving i+1-f1 without overflow.  If the biggest Fibonacci
E<lt>=i+1 is in fact f2=f1+f0E<lt>=i+1 then will have i+1-f1 E<gt>= f0 and
should subtract that too for i+1-(f1+f0).  The loop begins at the f1 bit in
this case, or at the f0 bit if not.

When the high 1-bit is handled like this to avoid overflow the second
highest bit is always a 0-bit the same as above.  So the loop can begin one
lower, so f0 if f2 was subtracted or the Fibonacci below f0 if not.  Initial
zero=1 to record the 0-bit skipped.

f1E<lt>=i and f1+f0E<lt>=i+1 only occurs when i+1=f1+f0 exactly, so it has
all 0-bits.  This can be treated explicitly by floor(count/2) which is the
0-bit cases in the loop.  i+1=Fibonacci won't occur very often, but
returning count/2 is about the amount code as an i-=f0 and setup to loop
from f1.

The effect of the algorithm in each case is to descend through the array
above (L</Array>) by taking or not taking mediant r+rprev or duplication
rprev=r.  This can be compared to the Stern diatomic sequence calculation
which goes by taking or not taking the mediant, no duplicating rprev=r case.

=head2 Stern Diatomic

The Fibonacci representations sequence contains the Stern diatomic sequence
(eg. L<Math::NumSeq::SternDiatomic>) as a subset, per

=over

Marjorie Bicknell-Johnson, "Stern's Diatomic Array Applied to Fibonacci
Representations", Fibonacci Quarterly, volume 41, number 2, May 2003, pages
169-180.

L<http://www.fq.math.ca/41-2.html>
L<http://www.fq.math.ca/Scanned/41-2/bicknell.pdf>

=back

Taking the R(i) at indices i for which i in Zeckendorf form uses only even
Fibonaccis gives the Stern diatomic sequence.

These indices have fibbinary value (L<Math::NumSeq::Fibbinary>) with 1-bits
only at even bit positions (counting the least significant bit position as 0
and going up from there).  Even positions are either 0 or 1.  Odd positions
are always 0.  The highest bit is always a 1-bit and it must be at an even
position.

    fibbinary(i) = 10a0b0c...0z
                     ^ ^ ^    ^
                     even bits a,b,c,etc 0 or 1,
                     odd bits always 0

In the L</Ith Pair> calculation above this kind of i always has an odd
number of 0-bits between each 1-bit.  So the 1-bit step is always rprev+=r,
and the 0-bit step at the even positions is r+=prev.  Those two steps are
the same as the Stern diatomic calculation per
L<Math::NumSeq::SternDiatomic/Ith Pair>.

=head1 SEE ALSO

L<Math::NumSeq::Fibonacci>,
L<Math::NumSeq::SternDiatomic>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2014, 2016, 2019 Kevin Ryde

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

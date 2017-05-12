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


# http://www.iki.fi/~kartturi/matikka/tab9766.htm
# A009766 Catalan triangle
# A099039 Riordan array

package Math::NumSeq::BalancedBinary;
use 5.004;
use strict;
use List::Util 'max';

use vars '$VERSION', '@ISA';
$VERSION = 72;

use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;
*_to_bigint = \&Math::NumSeq::_to_bigint;

use Math::NumSeq::Repdigits;
*_digit_split_lowtohigh = \&Math::NumSeq::Repdigits::_digit_split_lowtohigh;

use Math::NumSeq::Fibonacci;
*_blog2_estimate = \&Math::NumSeq::Fibonacci::_blog2_estimate;

# uncomment this to run the ### lines
# use Smart::Comments;


# use constant name => Math::NumSeq::__('Balanced Binary');
use constant description => Math::NumSeq::__('Bits 1,0 balanced like parentheses.');
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;
use constant default_i_start => 1;
use constant values_min => 2;

# pred() works, next() doesn't.
# Any merit in bit-reversed form ?
#
# use constant parameter_info_array =>
#   [ { name      => 'direction',
#       share_key => 'pairs_fsb',
#       display   => Math::NumSeq::__('Direction'),
#       type      => 'enum',
#       default   => 'HtoL',
#       choices => ['HtoL','LtoH'],
#       choices_display => [Math::NumSeq::__('HtoL'),
#                           Math::NumSeq::__('LtoH'),
#                          ],
#     },
#   ];

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'direction'} ||= 'HtoL';
  return $self;
}

#------------------------------------------------------------------------------
# A063171 same in binary
# A080116 predicate 0,1
# A080300 inverse, ranking value->i or 0
# A080237 num trailing zeros
# A085192 first diffs
# A000108 Catalan numbers, count of values in 4^k blocks
# A071152 balanced/2, Lukasiewicz words for the rooted plane binary trees
# A075171 trees by binary runs in integers, coded to Dyck words
# A071153 Lukasiewicz coded digits
#
my %oeis_anum = (HtoL => 'A014486',  # balanced binary
                 # OEIS-Catalogue: A014486

                 LtoH => undef,
                );
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum{$self->{'direction'}};
}


#------------------------------------------------------------------------------

# When $self->{'wantlen'} becomes equal to _WANTLEN_TO_BIGINT then go to
# Math::BigInt since the bits of a UV would be overflowed.
#
# _WANTLEN_TO_BIGINT is floor(numbits(UV)/2), but calculated by a probe of
# "~0".
#
# On a 32-bit UV balance binary value=0xFFFF0000 is reached at i=48_760_366
# which is fairly big but might be reached by a long running loop.  On a
# 64-bit UV the corresponding limit is i=75*10^15 so would not be reached in
# any reasonable time.
#
use constant 1.02 _WANTLEN_TO_BIGINT => do {
  my $uv = ~0;
  my $limit = 0;
  while ($uv >= 3) {
    $uv >>= 2;
    $limit++;
  }
  ### $limit
  $limit
};

sub rewind {
  my ($self) = @_;
  $self->{'wantlen'} = 0;
  $self->{'bits'} = [];
  $self->{'value'} = 0;
  $self->{'i'} = $self->i_start;
}

sub next {
  my ($self) = @_;
  ### BalancedBinary next() ...
  my $bits = $self->{'bits'};
  my $value;

  if (! @$bits) {
    ### initial 2 ...
    push @$bits, 2;
    $value = 2;

  } else {
    $value = $self->{'value'};
    for (;;) {
      ### at: "bits=".join(',',@{$self->{'bits'}})
      if (scalar(@$bits) < 2) {
        ### extend to wantlen: $self->{'wantlen'}+1
        $value = ($bits->[0] *= 4);
        if (++$self->{'wantlen'} == _WANTLEN_TO_BIGINT) {
          ### promote to BigInt from now on ...
          $bits->[0] = $value = _to_bigint($value);
        }
        last;
      }

      $value -= $bits->[-1];
      my $bit = ($bits->[-1] *= 2);
      if ($bit < $bits->[-2]) {
        ### shifted bit ...
        $value += $bit;
        last;
      }
      ### drop this bit ...
      pop @$bits;
    }

    ### pad for: "value=$value  bits=".join(',',@$bits)
    # trailing bits ...,128, 32, 8, 2
    my $bit = 2 + ($bits->[0]&1); # inherit BigInt
    foreach my $pos (reverse scalar(@$bits) .. $self->{'wantlen'}) {
      ### pad with: $bit
      $bits->[$pos] = $bit;
      $value += $bit;
      $bit *= 4;
    }
  }

  ### return: "value=$value bits=".join(',',@$bits)
  return ($self->{'i'}++,
          $self->{'value'} = $value);
}

sub ith {
  my ($self, $i) = @_;
  ### BalancedBinary ith(): $i

  if ($i < 1) {
    return undef;
  }
  if (_is_infinite($i)) {
    return $i;
  }

  $i -= 1;
  ### initial i remainder: $i

  my $zero = ($i*0);

  my @num;
  $num[0][0] = 0;
  $num[1][0] = 1;
  $num[1][1] = 1;
  my $z = 1;

  for ( ; ; $z++) {
    my $prev = $num[$z][0] = 1;  # all zeros, no ones
    if ($z == 16) {
      $prev += $zero;
      if (! ref $zero) {
        ### promote to BigInt ...
        $zero = _to_bigint($zero);
      }
    }
    foreach my $o (1 .. $z) {
      $num[$z][$o]
        = ($prev                        # 1...   $num[$z][$o-1]
           += ($num[$z-1][$o] || 0));   # 0... if $z>=1
    }
    my $catalan = $num[$z][$z];
    if ($i < $catalan) {
      last;
    }
    ### subtract catalan: $catalan
    $i -= $catalan;
  }

  ### i remaining: $i
  my @ret = (1);
  my $o = $z-1;
  while ($o >= 1) {
    ### at: "i=$i  z=$z o=$o  ret=".join('',@ret)
    ### assert: $z >= $o

    if ($z > $o) {
      ### compare: "z=".($z-1).",o=$o  num=".($num[$z-1][$o]||'undef')
      my $znum = $num[$z-1][$o];
      if ($i < $znum) {
        ### 0 ...
        push @ret, 0;
        $z--;
        next;
      }
      $i -= $znum;
    }
    ### 1 ...
    push @ret, 1;
    $o--;
  }

  push @ret, (0) x $z;
  ### final: "ret=".join('',@ret)

  if (! ref $zero && @ret >= 2*_WANTLEN_TO_BIGINT) {
    ### promote to BigInt ...
    $zero = _to_bigint($zero);
  }

  @ret = reverse @ret;
  ### return: _digit_join(\@ret, 2, $zero)
  return _digit_join(\@ret, 2, $zero);
}

# $aref->[0] low digit
sub _digit_join {
  my ($aref, $radix, $zero) = @_;
  my $n = $zero;
  foreach my $digit (reverse @$aref) { # high to low
    $n *= $radix;
    $n += $digit;
  }
  return $n;
}

sub value_to_i {
  my ($self, $value) = @_;
  ### BalancedBinary value_to_i(): $value

  if ($value < 2 || $value != int($value)) {
    return undef;
  }
  if (_is_infinite($value)) {
    return $value;
  }

  my @bits = _digit_split_lowtohigh($value,2)
    or return undef;

  _pred_on_bits($self,\@bits)
    or return undef;

  my @num;
  $num[0][0] = 0;
  $num[1][0] = 1;
  $num[1][1] = 1;
  my $w = scalar(@bits) / 2;
  ### $w

  my $zero = $value*0;
  my $i = 1 + $zero;

  foreach my $z (1 .. $w) {
    my $prev = $num[$z][0] = 1;  # all zeros, no ones
    if ($z > 16) {
      $prev += $zero;
    }
    foreach my $o (1 .. $z) {
      $num[$z][$o]
        = ($prev                        # 1...   $num[$z][$o-1]
           += ($num[$z-1][$o] || 0));   # 0... if $z>=1
    }
    $i += $num[$z-1][$z-1];
  }
  ### base i: $i

  ### bits: join('',@bits)
  shift @bits;  # skip high 1-bit
  my $z = $w;
  my $o = $w-1;
  foreach my $bit (@bits) {   # high to low
    ### at: "z=$z o=$o  bit=$bit"
    ### assert: $o >= 0
    ### assert: $z >= $o
    if ($bit) {
      ### bit 1 add: $num[$z-1][$o]
      $i += $num[$z-1][$o] || 0;
      $o--;
    } else {
      $z--;
    }
  }
  return $i;
}

sub value_to_i_floor {
  my ($self, $value) = @_;
  return _value_to_i_round ($self, $value, 0);
}
sub value_to_i_ceil {
  my ($self, $value) = @_;
  return _value_to_i_round ($self, $value, 1);
}

# Return the i corresponding to $value.
# If $value is not balanced binary then round according to $ceil.
# $ceil=1 to round up, or $ceil=0 to round down.
#
sub _value_to_i_round {
  my ($self, $value, $ceil) = @_;
  ### _value_to_i_round(): $value

  if ($value < 2) {
    return $self->i_start();
  }
  if (_is_infinite($value)) {
    return $value;
  }

  {
    my $int = int($value);
    if ($value != $int) {
      $value = $int + $ceil;  # +1 if not integer and want ceil
    }
  }
  my @bits = reverse _digit_split_lowtohigh($value,2);

  if (scalar(@bits) & 1) {
    # ENHANCE-ME: this is Catalan cumulative, or cumulative+1
    ### odd num bits ...
    @bits = ((0) x scalar(@bits), 1);
  }
  ### assert: (scalar(@bits) % 2) == 0

  my @num;
  $num[0][0] = 0;
  $num[1][0] = 1;
  $num[1][1] = 1;
  my $w = scalar(@bits)/2;
  ### $w

  my $zero = $value*0;
  my $i = 1 + $zero;

  foreach my $z (1 .. $w) {
    my $prev = $num[$z][0] = 1;  # all zeros, no ones
    if ($z > 16) {
      $prev += $zero;
    }
    foreach my $o (1 .. $z) {
      $num[$z][$o]
        = ($prev                        # 1...   $num[$z][$o-1]
           += ($num[$z-1][$o] || 0));   # 0... if $z>=1
    }
    $i += $num[$z-1][$z-1];
  }
  ### base i: $i

  ### bits: join('',@bits)
  shift @bits;  # skip high 1-bit
  my $z = $w;
  my $o = $w-1;

  foreach my $bit (@bits) {   # high to low
    ### at: "z=$z o=$o  bit=$bit"
    ### assert: $o >= 0
    ### assert: $z >= $o
    if ($bit) {
      if ($o == 0) {
        ### all 1s used, rest round down to zeros, so done: $i + $ceil
        return $i + $ceil;
      }
      ### bit 1 add: $num[$z-1][$o]
      $i += $num[$z-1][$o] || 0;
      $o--;

    } else {
      if ($z == $o) {
        ### 0 out of place, round up to 101010 ...
        while ($o) {
          $i += $num[$o-1][$o] || 0;
          $o--;
        }
        return $i - (1-$ceil);
      }

      $z--;
    }
  }
  return $i;
}



# 1       10,
# 2     1010,
# 3     1100,
# 4   101010,
# 5   101100,
# 6   110010,
# 7   110100,
# 8   111000,
# 9 10101010,   170
#
# 10xxxx
# 1xxxx0
# num(width) = 2*num(width-1) + extra
# num(1) = 1
# num(2) = 2*1 = 2
# num(3) = 2*2 + 1 = 5
# total(width)
#   = num(1) + num(2) + num(3) + ... + num(width)
#   = 1 + 2*1 + 2*2+1 +

sub pred {
  my ($self, $value) = @_;
  ### BalancedBinary pred(): $value

  if ($value != int($value) || _is_infinite($value)) {
    return 0;
  }

  my @bits = _digit_split_lowtohigh($value,2)
    or return 0;
  return _pred_on_bits($self,\@bits);
}
sub _pred_on_bits {
  my ($self, $bits) = @_;
  ### _pred_on_bits(): $bits

  if (scalar(@$bits) & 1) {
    return 0;
  }

  if ($self->{'direction'} eq 'HtoL') {
    @$bits = reverse @$bits;
    ### reversed bits: @$bits
  }

  my @count = (0,0);
  foreach my $bit (@$bits) {
    $count[$bit]++;
    if ($count[0] > $count[1]) {
      return 0;
    }
  }
  ### @count
  return ($count[0] == $count[1]);
}

# w = log2(value) / 2
# Catalan = 4^w / (sqrt(Pi * w) * (w + 1))
#         = 4^(log2(v)/2) / (sqrt(pi*log2(v)/2) * (log2(v)/2+1))
#         = v / (sqrt(pi*log2(v)/2) * (log2(v)/2+1))
#         = v / (sqrt(pi*log2(v)/2) * (log2(v)+2)/2)
#         = v / (sqrt(pi*log2(v)/2)/2 * (log2(v)+2))
#         = v / (sqrt(pi/8*log2(v)) * (log2(v)+2))
#
# if value has 2*w bits then cumulative catalan 
# i = sum w=0 to log2(value)/2
#       of value / (sqrt(pi/8*log2(value)) * (log2(value)+2))
#
# is cumulative close enough to the plain ?
#
# 2*w bits, ipart=Catalan(w) value=4^w
# so w = log4(value)
#    ipart = Catalan(log4(value))
#          = 

sub value_to_i_estimate {
  my ($self, $value) = @_;
  ### value_to_i_estimate: $value

  if ($value <= 2) {
    return 1;
  }

  my $log2 = _blog2_estimate($value);
  if (! defined $log2) {
    $log2 = log($value) * (1/log(2));
  }
  $log2 = max($log2,1);

  if (ref $value && $value->isa('Math::BigInt')) {
    # oldish BigInt doesn't like to divide BigInt/NV
    require Math::BigFloat;
    $value = Math::BigFloat->new($value);
  }

  return max(1,
             int($value / (sqrt((3.141592/8)*$log2) * ($log2+1))));
}

1;
__END__

=for stopwords Ryde Math-NumSeq ie recurse recursing encodings Ith i'th

=head1 NAME

Math::NumSeq::BalancedBinary -- balanced 1,0 bits

=head1 SYNOPSIS

 use Math::NumSeq::BalancedBinary;
 my $seq = Math::NumSeq::BalancedBinary->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This sequence is integers with 1-bits and 0-bits balanced like opening and
closing parentheses.

    2, 10, 12, 42, 44, 50, 52, 56, 170, 172, 178, ...
    starting i=1

Written in binary a 1-bit is an opening "(" and a 0-bit is a closing ")".

           value     
     i   in binary   as parens
    ---  ---------   ----------
     1         10    ()
     2       1010    () ()
     3       1100    (())
     4     101010    () () ()
     5     101100    () (())
     6     110010    (()) ()
     7     110100    (() ())
     8     111000    ((()))
     9   10101010    () () () ()
    10   10101100    () () (())

Balanced means the total number of 1s and 0s are the same and when reading
from high to low has count(1s) E<gt>= count(0s) at all times, which is to
say any closing ")" must have a preceding matching open "(".

Because the number of 1s and 0s are equal the width is always an even 2*w.
The number of values with a given width is the Catalan number C(w) =
(2w)!/(w!*(w+1)!).  For example 6-bit values w=6/2=3 gives C(3) =
(2*3)!/(3!*4!) = 5 many such values, being i=4 through i=8 inclusive as
shown above.  (See L<Math::NumSeq::Catalan>.)

=head2 Binary Trees

The sequence values correspond to binary trees where each node can have a
left and/or right child.  Such a tree can be encoded by writing

    0                         if no node (empty tree)
    1,left-tree,right-tree    at a node

The "left-tree" and "right-tree" parts are the left and right legs of the
node written out recursively.  If those legs are both empty (ie. the node is
a leaf) then they're empty trees and are "0" giving node "100".  Otherwise
the node is 1 followed by various more 1s and 0s.  For example,

        d  
       /
  b   c   =>   11001010 [0]
   \ /         ab  c d   ^-final zero of encoding omitted
    a  

At "a" write 1 and recurse to write its left then right legs.  The left leg
is "b" so write 1 and the two legs of "b" are empty so write 0,0.  That
completes the left side of "a" so resume at the right side of "a" which is 1
for "c" and descend to the left and right of "c".  The left of "c" is empty
so write 0.  The right of "c" is "d" so write 1 and the two empty legs of
"d" are 0,0.  The very final 0 from that right-most leaf "d" is dropped
(shown "[0]" above).

This encoding can also be applied breadth-first by pushing the left and
right descents onto a queue of pending work instead of onto a stack by
recursing.  In both cases there's an extra final 0 which is dropped.  This 0
arises because in any binary tree with K nodes there are K+1 empty legs.
That would give K many 1-bits and K+1 many 0-bits.

In this encoding the balanced binary condition "count 1s E<gt>= count 0s"
corresponds to there being at least one unfinished node at any time in the
traversal (by whichever node order).

The C<NumSeq> code here acts on values as numbers.  Tree encodings like this
are probably better handled as a string or list of bits.

=head2 Mountain Ranges

A cute interpretation of the opens and closes is as up and down slopes of a
mountain range.  1-bit for up, 0-bit for down.  For example,

        /\
       /  \  /\
      /    \/  \    
     /          \/\
    ----------------
     11110001100010

The mountain range must end at its starting level and must remain at or
above its starting level at all times.

Numerical order of the values means narrower mountain ranges are before
wider ones, and two ranges with equal width are ordered by down-slope
preceding up-slope at the first place they differ.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::BalancedBinary-E<gt>new ()>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the C<$i>'th balanced binary number.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is balanced binary.

=item C<$i = $seq-E<gt>value_to_i($value)>

If C<$value> is balanced binary then return its index i.  If C<$value> is
not balanced binary then return C<undef>.

=item C<$i = $seq-E<gt>value_to_i_ceil($value)>

=item C<$i = $seq-E<gt>value_to_i_floor($value)>

Return the index i of C<$value> or if C<$value> is not a balanced binary
integer then return the i of the next higher or lower value, respectively.

=back

=head1 FORMULAS

=head2 Next

When stepping to the next value the number of 1s and 0s does not change.
The 1s move to make a numerically higher value.  The simplest case is an
isolated low 1-bit.  It must move up one place.  For example,

    11100100             isolated low 1-bit
    ->                   shifts up
    11101000

If the low 1 has a 1 above it then that bit must move up and the lower one
goes to the low end of the value.  For example

    1110011000           pair of bits
    ->                   one shifts up, other drops to low end
    1110100010

In general the lowest run of 1-bits is changed to have the highest of them
move up one place and the rest move down to be a ...101010 pattern at the
low end.  For example a low run of 3 bits

    1111100111000000     run of bits
    ->                   one shifts up, rest drop to low end
    1111101000001010
          ^     ^ ^
         up     low end

The final value in a 2*w block has all 1s at the high end.  The first of the
next bigger block of values is an alternating 1010..10.  For example

      111000    last 6-bit value, all 1-bits at high end
    ->
    10101010    first 8-bit value

=head2 Ith

As described above there are Catalan(w) many values with 2*w bits.  The
width of the i'th value can be found by successively subtracting C(1), C(2),
etc until reaching a remainder S<i E<lt> C(w)>.  At that point the value is
2*w many bits, being w many "1"s and w many "0"s.

In general after outputting some bits of the value (at the high end) there
will be a number z many "0"s and n many "1"s yet to be output.  The choice
is then to output either 0 or 1 and reduce z or n accordingly.

    numvalues(z,n) = number of sequences of z "0"s and n "1"s
                     with remaining 1s >= remaining 0s at all times

    N = numvalues(z-1,n)
      = how many combinations starting with zero "0..."

    if i < N  then output 0   
    if i >= N then output 1 and subtract N from i
                    (which is the "0..." combinations skipped)

numvalues() is the "Catalan table" constructed by

    for z=1 upwards
      numvalues(z,0) = 1
      for n = 1 to z
        numvalues(z,n) = numvalues(z-1,n)  # the 0... forms
                       + numvalues(z,n-1)  # the 1... forms

In each numvalues(z,n) the numvalues(z,n-1) term is the previous numvalues
calculated, so a simple addition loop for the table

    for z=1 upwards
      t = numvalues(z,0) = 1
      for n = 1 to z
        t += numvalues(z-1,n)
        numvalues(z,n) = t

The last entry numvalues(w,w) in each row is Catalan(w), so that can be used
for the initial i subtractions seeking the width w.  If building or
extending a table each time then stop the table at that point.

Catalan(w) grows as a little less than a power 4^w so the table has a little
more than log4(i) many rows.

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Catalan>,
L<Math::NumSeq::Fibbinary>

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

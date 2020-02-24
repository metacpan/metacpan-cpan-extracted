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

package Math::NumSeq::NumAronson;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 74;
use Math::NumSeq;
@ISA = ('Math::NumSeq');

# uncomment this to run the ### lines
#use Devel::Comments;


# use constant name => Math::NumSeq::__('Numerical Aronson');
use constant description => Math::NumSeq::__('Numerical version of Aronson\'s sequence');
use constant values_min => 1;
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;
use constant i_start => 1;

# cf A080596 - a(1)=1
#    A079253 - even
#    A081023 - lying
#    A014132 - lying opposite parity
use constant oeis_anum => 'A079000';

# a(9*2^k - 3 + j) = 12*2^k - 3 + (3/2)*j + (1/2)*abs(j)
#     where k>=0 and -3*2^k <= j < 3*2^k
# step
#     a(n+1) - 2*a(n) + a(n-1) = 1   if n=9*2^k-3, k>=0
#                              = -1  if n = 2 and 3*2^k-3, k>=1
#                              = 0   otherwise.
#
# lying
# g(3*2^k-1 + j) = 2*2^(k+1)-1 + (3/2)*j + (1/2)*abs(j)
# where -2^k <= j < 2^k  and k>0
#
# then lying is d(n)=g(n+1)-1  n>=1

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  $self->{'pow'} = 0;
  $self->{'j'} = -1;
}

sub next {
  my ($self) = @_;
  my $pow = $self->{'pow'};
  my $j = ++ $self->{'j'};

  if ($pow == 0) {
    # low special cases initial 1,4,
    if ($j < 2) {
      return ($self->{'i'}++, $j*3 + 1);
    }
    $pow = $self->{'pow'} = 1;    # 2**k for k=0
    $j   = $self->{'j'}   = -3;   # -3*(2**k) for k=0
  } elsif ($j >= 3 * $pow) {
    $pow = ($self->{'pow'} *= 2);
    $j = $self->{'j'} = -3 * $pow;
  }

  ### assert: -3 * $pow <= $j
  ### assert: $j < 3 * $pow

  return ($self->{'i'}++, 12*$pow - 3 + (3*$j + abs($j))/2);
}

# i = 9*2^k - 3 + j
# base at j=-3*2^k
# is i >= 9*2^k - 3 - 3*2^k
#    i >= 6*2^k - 3
#    i+3 >= 6*2^k
#    (i+3)/6 >= 2^k
#    2^k <= (i+3)/6
# then i = 9*2^k - 3 + j
#      j = i - 9*2^k + 3
#
sub ith {
  my ($self, $i) = @_;
  ### NumAronson ith(): $i

  # special cases ith(1)=1, ith(2)=4
  if ($i <= 2) {
    if ($i < 0) {
      return undef;
    } else {
      return $i*$i;
    }
  }

  my ($pow, $k) = _round_down_pow (int(($i+3)/6), 2);
  my $j = $i - 9*$pow + 3;

  ### round down for k: ($i+3)/6
  ### $k
  ### $pow
  ### $j
  ### assert: $k >= 0
  ### assert: -3 * 2 ** $k <= $j
  ### assert: $j < 3 * 2 ** $k

  return 12*$pow - 3 + (3*$j + abs($j))/2;
}

# value = 12*2^k - 3 + (3/2)*j + (1/2)*abs(j)
# minimum j=-3*2^k
# value = 12*2^k - 3 + (3*j + abs(j))/2
#       = 12*2^k - 3 + (3*-3*2^k + 3*2^k)/2
#       = 12*2^k - 3 + (-9 + 3)*2^k/2
#       = 12*2^k - 3 + -6*2^k/2
#       = 12*2^k - 3 + -3*2^k
#       = 9*2^k - 3
# value >= 9*2^k - 3
# value+3 >= 9*2^k
# 9*2^k <= value+3
# 2^k <= (value+3)/9
#
# from which 
#     value = 12*2^k - 3 + (3*j + abs(j))/2
#     (3*j + abs(j))/2 = value - 12*2^k + 3
#     3*j + abs(j) = 2*(value - 12*2^k + 3)
#
# j>=0  4*j = a, j=a/4
# j<0   3*$j-$j = 2*$j = a, j=a/2
# 
sub pred {
  my ($self, $value) = @_;
  ### NumAronson pred(): $value

  # special cases pred(1) true, pred(4) true
  if ($value < 6) {
    return ($value == 1 || $value == 4);
  }

  my $k = _round_down_pow (int(($value+3)/9), 2);
  my $pow = 2**$k;
  my $aj = 2*($value - 12*$pow + 3);
  return ($aj % ($aj < 0 ? 2 : 4)) == 0;
}

#------------------------------------------------------------------------------
# generic

# return ($pow, $exp) with $pow = $base**$exp <= $n,
# the next power of $base at or below $n
#
sub _round_down_pow {
  my ($n, $base) = @_;
  ### _round_down_pow(): "$n base $base"

  if ($n < $base) {
    return (1, 0);
  }

  # Math::BigInt and Math::BigRat overloaded log() return NaN, use integer
  # based blog()
  if (ref $n && ($n->isa('Math::BigInt') || $n->isa('Math::BigRat'))) {
    my $exp = $n->copy->blog($base);
    return (Math::BigInt->new(1)->blsft($exp,$base),
            $exp);
  }

  my $exp = int(log($n)/log($base));
  my $pow = $base**$exp;

  ### n:   ref($n)."  $n"
  ### exp: ref($exp)."  $exp"
  ### pow: ref($pow)."  $pow"

  # check how $pow actually falls against $n, not sure should trust float
  # rounding in log()/log($base)
  # Crib: $n as first arg in case $n==BigFloat and $pow==BigInt
  if ($n < $pow) {
    ### hmm, int(log) too big, decrease...
    $exp -= 1;
    $pow = $base**$exp;
  } elsif ($n >= $base*$pow) {
    ### hmm, int(log) too small, increase...
    $exp += 1;
    $pow *= $base;
  }
  return ($pow, $exp);
}

1;
__END__

=for stopwords Ryde Math-NumSeq Aronson's Cloitre Vandermast iff

=head1 NAME

Math::NumSeq::NumAronson -- numerical version of Aronson's sequence

=head1 SYNOPSIS

 use Math::NumSeq::NumAronson;
 my $seq = Math::NumSeq::NumAronson->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

X<Cloitre, Benoit>X<Sloane, Neil>X<Vandermast, Matthew>This is a
self-referential sequence by Cloitre, Sloane and Vandermast,

=over

"Numerical Analogues of Aronson's Sequence",
L<http://arxiv.org/abs/math.NT/0305308>

=back

The sequence begins

    1, 4, 6, 7, 8, 9, 11, 13, ...
    starting i=1

Starting with a(1)=1 the rule is "n is in the sequence iff a(n) is odd".
The result is a uniform pattern 3 steps by 1 then 3 steps by 2, followed by
6 steps by 1 and 6 steps by 2, then 12, 24, 48, etc.

    1,
    4,
    6,  7,  8,                   # 3 steps by 1
    9,  11, 13,                  # 3 steps by 2
    15, 16, 17, 18, 19, 20,      # 6 steps by 1
    21, 23, 25, 27, 29, 31,      # 6 steps by 2
                                 # 3*2^k steps by 1
                                 # 3*2^k steps by 2

In general

    numaronson(9*2^k-3+j) = 12*2^k - 3 + (3*j+abs(j))/2
    where -3*2^k <= j < 3*2^k

The (3*j+abs(j))/2 part is the step, going by 1 if jE<lt>=0 and by 2 if
jE<gt>0.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::NumAronson-E<gt>new ()>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the C<$i>th value in the sequence.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs in the sequence.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Aronson>

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

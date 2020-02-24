# Copyright 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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

package Math::NumSeq::ProthNumbers;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 74;

use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::NumAronson;
*_round_down_pow = \&Math::NumSeq::NumAronson::_round_down_pow;

# uncomment this to run the ### lines
# use Smart::Comments;


# use constant name => Math::NumSeq::__('Proth Numbers');
use constant description => Math::NumSeq::__('Proth numbers k*2^n+1 for odd k and k < 2^n.');
use constant i_start => 1;
use constant values_min => 3;
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;

# cf A157892 - value of k
#    A157893 - value of n
#    A080076 - Proth primes
#    A134876 - how many Proth primes for given n
#
#    A002253 3*2^n+1 is prime
#    A002254 5*2^n+1
#    A032353 7*2^n+1
#    A002256 9*2^n+1
#
#    A086341 - 2^x+/-1 is sqrt of Proth squares
#
use constant oeis_anum => 'A080075';


# $uv_limit is the biggest power 4**k which fits in a UV
#
my $uv_limit = do {
  my $max = ~0;

  # limit <= floor(max/4) means 4*limit <= max is still good
  my $limit = 4;
  while ($limit <= ($max >> 2)) {
    $limit <<= 2;
  }

  ### ProthNumbers UV limit ...
  ### $limit
  ### limit: sprintf('%#X',$limit)

  $limit
};

sub rewind {
  my ($self) = @_;
  $self->{'value'} = 1;
  $self->{'inc'} = 2;
  $self->{'limit'} = 4;
  $self->{'i'} = $self->i_start;
}
sub next {
  my ($self) = @_;
  ### ProthNumbers next(): sprintf('value=%b inc=%b limit=%b', $self->{'value'}, $self->{'inc'}, $self->{'limit'})

  my $value = ($self->{'value'} += $self->{'inc'});
  if ($value >= $self->{'limit'}) {
    ### bigger 2^n now ...
    if ($self->{'limit'} == $uv_limit) {
      ### go to BigInt
      $self->{'value'} = Math::NumSeq::_to_bigint($self->{'value'});
      $self->{'inc'}   = Math::NumSeq::_to_bigint($self->{'inc'});
      $self->{'limit'} = Math::NumSeq::_to_bigint($self->{'limit'});
    }
    $self->{'inc'} *= 2;
    $self->{'limit'} *= 4;
  }
  return ($self->{'i'}++, $value);
}

# seek value at i-1, inc and limit ready to make next value
#
# i     i         value       inc     limit           next value
#  1     1             1       10         100               11
#  2    10            11       10         100              101
#  3    11           101      100       10000             1001
#  4   100          1001      100       10000             1101
#  5   101          1101      100       10000            10001
#  6   110         10001     1000     1000000            11001
#  7   111         11001     1000     1000000           100001
#  8  1000        100001     1000     1000000           101001
#  9  1001        101001     1000     1000000           110001
# 10  1010        110001     1000     1000000           111001
# 11  1011        111001     1000     1000000          1000001
# 12  1100       1000001    10000   100000000          1010001
# 13  1101       1010001    10000   100000000          1100001
# 14  1110       1100001    10000   100000000          1110001
# 15  1111       1110001    10000   100000000         10000001
# 16 10000      10000001    10000   100000000         10010001
#
sub seek_to_i {
  my ($self, $i) = @_;
  $self->{'i'} = $i;

  my ($pow) = _round_down_pow($i, 2);  # i = 1zxxx
  $i -= $pow;                          # without high bit, so i=zxxx

  # $zpow is the z bit position, or 1 if $i==1
  my $zpow = ($pow >= 2 ? $pow/2 : 0);

  if ($i >= $zpow) {
    # z=1 so return value=1xxx 0 0001, extra low 0-bit
    $pow *= 2;
  } else {
    # z=0 so return value=1xxx 0001, turn on 1-bit in i
    $i += $zpow;    # i=0xxx becomes i=1xxx
  }

  if ($pow*$pow >= $uv_limit) {
    $pow = Math::NumSeq::_to_bigint($pow);
  }
  $self->{'value'} = $pow*$i + 1;
  $self->{'inc'}   = $pow;
  $self->{'limit'} = $pow*$pow;
}

sub ith {
  my ($self, $i) = @_;
  ### ProthNumbers ith(): $i

  $i += 1;
  my ($pow) = _round_down_pow($i, 2);  # i = 1zxxx
  $i -= $pow;                          # without high bit, so i=zxxx

  my $zpow = $pow/2;
  if ($i >= $zpow) { # test z bit
    # z=1 so return value=1xxx 0 0001, extra low 0-bit
    $pow *= 2;
  } else {
    # z=1 so return value=1xxx 0001, turn on 1-bit in i
    $i += $zpow;    # i=0xxx becomes i=1xxx
  }
  return $i*$pow + 1;
}

sub pred {
  my ($self, $value) = @_;
  ### ProthNumbers pred(): $value
  {
    my $int = int($value);
    if ($value != $int) { return 0; }
    $value = $int;
  }
  unless ($value >= 3
          && ($value % 2)
          && ! _is_infinite($value)) {
    return 0;
  }

  # ENHANCE-ME: maybe BigInt as_bin() and string match position of lowest 1
  # ENHANCE-ME: maybe (v^(v-1))+1 for lowest 1, ask if v < m*m
  #
  my $pow = ($value*0) + 2; # inherit bignum 2
  for (;;) {
    ### at: "$value   $pow"
    $value = int($value/2);
    if ($value < $pow) {
      return 1;
    }
    if ($value % 2) {
      return ($value < $pow);
    }
    $pow *= 2;
  }
}

# use 41/29 ~= sqrt(2) in case $value is a Math::BigInt, since can't
# multiply BigInt*float
#
sub value_to_i_estimate {
  my ($self, $value) = @_;
  if ($value < 0) { return 0; }
  my $est = int(sqrt(int($value)) * 41 / 29);
}

1;
__END__

=for stopwords Ryde Math-NumSeq ProthNumbers Ith ith 1zxxx 1zxx x's hhxx..xx hxx hh-1 Proth incrementing Incrementing

=head1 NAME

Math::NumSeq::ProthNumbers -- Proth number sequence

=head1 SYNOPSIS

 use Math::NumSeq::ProthNumbers;
 my $seq = Math::NumSeq::ProthNumbers->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The Proth numbers

    3, 5, 9, 13, 17, 25, 33, 41, 49, 57, 65, 81, 97, 113, ...
    starting i=1

being integers of the form k*2^n+1 for some k and n and where
S<k E<lt> 2^n>.

The k E<lt> 2^n condition means the values in binary have low half 00..01
and high half some value k,

    binary 1xxx0000000...0001

    value    binary        k  n  2^n
      3       11           1  1   2
      5       101          1  2   4
      9      1001          2  2   4
     13      1101          3  2   4
     17      10001         2  3   8
     25      11001         3  3   8
     33     100001         4  3   8
     41     101001         5  3   8
              ^^
              ||
     k part --++-- low part

Taking all k E<lt> 2^n duplicates some values, as for example 33 is k=4 n=3
as 4*2^3+1 and also k=2 n=4 as 2*2^4+1.  This happens for any even k.
Incrementing n on reaching k=2^n-1 makes a regular pattern, per L</Ith>
below.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::ProthNumbers-E<gt>new()>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the C<$i>'th Proth number.  The first number is 3 at C<$i==1>.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is a Proth number, meaning is equal to k*2^n+1 for
some k and n with k E<lt> 2^n.

=item C<$i = $seq-E<gt>value_to_i_estimate($value)>

Return an estimate of the i corresponding to C<$value>.  This is roughly
sqrt(2*$value).

=back

=head1 FORMULAS

=head2 Next

Successive values can be calculated by keeping track of the 2^n power and
incrementing k by adding such a power,

    initial
      value = 1   # to give 3 on first next() call
      inc = 2
      limit = 4

    next()
      value += inc
      if value >= limit
         inc *= 2       # ready for next time
         limit *= 4
      return value

=head2 Ith

Taking the values by their length in bits, the values are

       11        1 value  i=1
       101       1 value  i=2
      1x01       2 values i=3,4
      1x001      2 values i=5,6
     1xx001      4 values i=7 to 10
     1xx0001     4 values
    1xxx0001     8 values
    1xxx00001    8 values

For a given 1xxx high part the low zeros, which is the 2^n factor, is the
same length and then repeated 1 bigger.  That doubling can be controlled by
a high bit of the i, so in the following Z is either a zero bit or omitted,

       1Z1
      1xZ01
     1xxZ001
    1xxxZ0001

The ith Proth number can be formed from the bits of the index

    i+1 = 1zxx..xx    binary
    k = 1xx..xx
    n = z + 1 + number of x's

The first 1zxxx desired is 10, which is had from i+1 starting from i=1.  The
z second highest bit makes n bigger, giving the Z above present or omitted.

For example i=9 is bits i+1=1010 binary which as 1zxx is k=0b110=6,
n=0+1+2=3, for value 6*2^3+1=49, or binary 110001.

It can be convenient to take the two highest bits of the index i together,
so hhxx..xx so hh=2 or 3, then n = hh-1 + number of x's.

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::CullenNumbers>,
L<Math::NumSeq::WoodallNumbers>

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

# Copyright 2012, 2013, 2014, 2016 Kevin Ryde

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

package Math::NumSeq::RadixConversion;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 73;

use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;
*_to_bigint = \&Math::NumSeq::_to_bigint;

use Math::NumSeq::NumAronson 8; # new in v.8
*_round_down_pow = \&Math::NumSeq::NumAronson::_round_down_pow;

# uncomment this to run the ### lines
#use Smart::Comments;

use constant name => Math::NumSeq::__('Radix Conversion');
use constant description => Math::NumSeq::__('Integers converted from one radix into another.');
use constant default_i_start => 0;
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;

sub values_min {
  my ($self) = @_;
  return $self->ith($self->i_start);
}
sub characteristic_smaller {
  my ($self) = @_;
  return ($self->{'to_radix'} < $self->{'from_radix'});
}

use constant parameter_info_array =>
  [
   { name          => 'from_radix',
     share_key     => 'radix_2',
     type          => 'integer',
     display       => Math::NumSeq::__('From Radix'),
     default       => 2,
     minimum       => 2,
     width         => 3,
     # description => Math::NumSeq::__('...'),
   },
   { name          => 'to_radix',
     share_key     => 'radix',
     type          => 'integer',
     display       => Math::NumSeq::__('To Radix'),
     default       => 10,
     minimum       => 2,
     width         => 3,
     # description => Math::NumSeq::__('...'),
   },
  ];


#------------------------------------------------------------------------------
# cf A136399 decimal is not entirely 0,1 digits
#    A055983 a(n+1) = a(n) base 10 converted to base 12, repeated conversion
#    A032917 decimal digits 1,3 only
#    A199341 decimal digits 1,3,4 only
#    A032940 base 5 odd positions 0, but counting from top end
#
#    A099820 even numbers written in binary
#    A099821 odd numbers written in binary
#    A001737 squares written in binary
#    A031345 primes written in 10 interpret as base 13
#

my @oeis_anum;
$oeis_anum[10]->[2] = 'A007088';  # numbers written in base 2, starting n=0
$oeis_anum[10]->[3] = 'A007089';  # numbers written in base 3, starting n=0
$oeis_anum[10]->[4] = 'A007090';  # numbers written in base 4, starting n=0
$oeis_anum[10]->[5] = 'A007091';  # numbers written in base 5, starting n=0
$oeis_anum[10]->[6] = 'A007092';  # numbers written in base 6, starting n=0
$oeis_anum[10]->[7] = 'A007093';  # numbers written in base 7, starting n=0
$oeis_anum[10]->[8] = 'A007094';  # numbers written in base 8, starting n=0
$oeis_anum[10]->[9] = 'A007095';  # numbers written in base 9, starting n=0
# OEIS-Catalogue: A007088
# OEIS-Catalogue: A007089 from_radix=3
# OEIS-Catalogue: A007090 from_radix=4
# OEIS-Catalogue: A007091 from_radix=5
# OEIS-Catalogue: A007092 from_radix=6
# OEIS-Catalogue: A007093 from_radix=7
# OEIS-Catalogue: A007094 from_radix=8
# OEIS-Other:     A007095 from_radix=9   # in RadixWithoutDigit

$oeis_anum[4]->[3] = 'A023717'; # base 4 no 3    OFFSET=0
# OEIS-Other: A023717 from_radix=3 to_radix=4  # in RadixWithoutDigit

# Not quite, OFFSET=1 value=0
# $oeis_anum[5]->[4] = 'A023737'; # base 5 no 4    OFFSET=1
# # OEIS-Other: A023737 radix=5 digit=4  # base 5 no 4, in RadixWithoutDigit

# $oeis_anum[7]->[6] = 'A020657'; # "no 7-term arithmetic progression" OFFSET=1

# Not quite, A102489 starts OFFSET=1 value=0
# $oeis_anum[10]->[16] = 'A102489'; # base 10 treated as base 16
# # OEIS-Catalogue: A102489 from_radix=10 to_radix=16

# Not quite, A005836 starts OFFSET=1 value=0
# $oeis_anum[3]->[2] = 'A005836';  # binary in base 3, base3 without 2s
$oeis_anum[4]->[2] = 'A000695';  # binary in base 4, digits 0,1 only
$oeis_anum[5]->[2]  = 'A033042';  # binary in base 5
$oeis_anum[6]->[2]  = 'A033043';  # binary in base 6
# $oeis_anum[7]->[2]  = 'A033044';  # binary in base 7, but OFFSET=1 value=0
$oeis_anum[8]->[2]  = 'A033045';  # binary in base 8
$oeis_anum[9]->[2]  = 'A033046';  # binary in base 9
$oeis_anum[11]->[2] = 'A033047';  # binary in base 11
$oeis_anum[12]->[2] = 'A033048';  # binary in base 12
$oeis_anum[13]->[2] = 'A033049';  # binary in base 13
$oeis_anum[14]->[2] = 'A033050';  # binary in base 14
$oeis_anum[15]->[2] = 'A033051';  # binary in base 15
$oeis_anum[16]->[2] = 'A033052';  # binary in base 16
# OEIS-Catalogue: A000695 to_radix=4
# OEIS-Catalogue: A033042 to_radix=5
# OEIS-Catalogue: A033043 to_radix=6
# # OEIS-Catalogue: A033044 to_radix=7 # but OFFSET=1 value=0
# OEIS-Catalogue: A033045 to_radix=8
# OEIS-Catalogue: A033046 to_radix=9
# OEIS-Catalogue: A033047 to_radix=11
# OEIS-Catalogue: A033048 to_radix=12
# OEIS-Catalogue: A033049 to_radix=13
# OEIS-Catalogue: A033050 to_radix=14
# OEIS-Catalogue: A033051 to_radix=15
# OEIS-Catalogue: A033052 to_radix=16


sub oeis_anum {
  my ($self) = @_;

  if ($self->{'to_radix'} == $self->{'from_radix'}) {
    return 'A001477'; # all integers 0 up
  }
  # OEIS-Other: A001477 from_radix=10 to_radix=10
  # OEIS-Other: A001477 from_radix=2 to_radix=2

  return $oeis_anum[$self->{'to_radix'}]->[$self->{'from_radix'}];
}


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);

  # Round down to a power of to_radix as the UV limit.  For example in
  # 32-bits to_radix=10 the limit is 1_000_000_000.  Usually a bigger limit
  # is possible, but this round-down is an easy calculation.
  #
  my ($pow) = _round_down_pow (~0, $self->{'to_radix'});
  $self->{'value_uv_limit'} = $pow;
  ### value_uv_limit: $self->{'value_uv_limit'}

  return $self;
}

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
}
sub next {
  my ($self) = @_;
  my $i = $self->{'i'}++;
  my $value = $self->ith($i);
  if ($value == $self->{'value_uv_limit'}) {
    $self->{'i'} = _to_bigint($self->{'i'});
  }
  return ($i, $value);
}

# ENHANCE-ME: BigInt use as_bin,oct.hex when to_radix decimal or likewise
#
sub ith {
  my ($self, $i) = @_;
  ### RadixConversion ith(): $i

  if (_is_infinite($i)) {
    return $i;
  }

  my $neg; # secret undocumented support for negative i
  if ($i < 0) {
    $neg = 1;
    $i = - $i;
  }
  my $value = _digit_join_lowtohigh
    (_digit_split_lowtohigh($i, $self->{'from_radix'}),
     $self->{'to_radix'});
  return ($neg ? -$value : $value);
}

sub pred {
  my ($self, $value) = @_;
  ### RadixConversion pred(): $value

  if (_is_infinite($value)) {
    return undef;
  }
  {
    my $int = int($value);
    if ($value != $int) {
      return 0;
    }
    $value = $int;
  }

  my $from_radix = $self->{'from_radix'};
  my $to_radix = $self->{'to_radix'};
  if ($to_radix <= $from_radix) {
    return 1;
  }

  while ($value) {
    my $digit = $value % $to_radix;
    if ($digit >= $from_radix) {
      return 0;
    }
    $value = int($value/$to_radix);
  }
  return 1;
}

#------------------------------------------------------------------------------
# generic

# returning array[0] low digit
sub _digit_split_lowtohigh {
  my ($n, $radix) = @_;
  ### _digit_split(): $n
  my @ret;
  while ($n) {
    push @ret, $n % $radix;
    $n = int($n/$radix);
  }
  return \@ret;
}

# taking $aref->[0] low digit
sub _digit_join_lowtohigh {
  my ($aref, $radix) = @_;
  my $n = 0;
  while (defined (my $digit = pop @$aref)) {
    $n *= $radix;
    $n += $digit;
  }
  return $n;
}

1;
__END__

=for stopwords Ryde Math-NumSeq radix ie

=head1 NAME

Math::NumSeq::RadixConversion -- radix conversion

=head1 SYNOPSIS

 use Math::NumSeq::RadixConversion;
 my $seq = Math::NumSeq::RadixConversion->new (from_radix => 2,
                                               to_radix => 10);
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This sequence is the index i converted from one radix to another.  The
default is from binary to decimal,

    0, 1, 10, 11, 100, 101, 110, 111, 1000, 1001, 1010, 1011, ...
    starting i=0

For example i=3 in binary is 0b11 which is interpreted as decimal for value
11, ie. eleven.

When C<from_radix E<lt> to_radix> the effect is to give values which in
C<to_radix> use only the digits of C<from_radix>.  The default is all
integers which in decimal use only the binary digits, ie. 0 and 1.

When C<from_radix E<gt> to_radix> the conversion is a reduction.  The
calculation is still a breakdown and re-assembly

    i = d[k]*from_radix^k + ... + d[1]*from_radix + d[0]
    value = d[k]*to_radix^k + ... + d[1]*to_radix + d[0]

but because C<to_radix> is smaller the value is smaller than the index i.
For example from_radix=10 and to_radix=8 turns i=345 into
value=3*8^2+4*8+5=229.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::RadixConversion-E<gt>new ()>

=item C<$seq = Math::NumSeq::RadixConversion-E<gt>new (from_radix =E<gt> $r, to_radix =E<gt> $t)>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return C<$i> as digits of base C<radix> encoded in C<to_radix>.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs in the sequence.

If C<to_radix E<lt>= from_radix> then all integer C<$value> occurs.  If
C<to_radix E<gt> from_radix> then C<$value> written in C<to_radix> must use
only digits 0 to S<C<from_radix - 1>> inclusive.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::DigitSum>,
L<Math::NumSeq::HarshadNumbers>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2016 Kevin Ryde

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

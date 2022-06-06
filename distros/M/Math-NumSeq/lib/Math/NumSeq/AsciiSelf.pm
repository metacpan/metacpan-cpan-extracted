# Copyright 2011, 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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

# math-image --values=AsciiSelf --output=list


package Math::NumSeq::AsciiSelf;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 75;
use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
# use Smart::Comments;


# use constant name => Math::NumSeq::__('Ascii Self');
use constant description => Math::NumSeq::__('Sequence is itself in ASCII.');
use constant i_start => 1;
use constant characteristic_increasing => 0;
use constant characteristic_smaller => 1;
use constant characteristic_integer => 1;

# use constant characteristic_charset => 'ASCII';
# sub characteristic_charset_digits {
#   my ($self) = @_;
#   return $self->{'radix'};
# }

use Math::NumSeq::Base::Digits
  'parameter_info_array';   # radix parameter

{
  my @values_min;
  my @values_max;
  $values_min[3] = 49;
  $values_min[6] = 49;
  $values_min[8] = $values_max[8] = 54;
  $values_min[11] = 49;
  $values_min[12] = 52;
  $values_min[14] = 49;
  $values_min[15] = 51;
  $values_min[16] = $values_max[16] = 51;  # only 51s
  $values_min[20] = 50;
  $values_min[21] = 50;
  $values_min[23] = 50;
  $values_min[24] = $values_max[24] = 50;  # only 50s
  $values_min[28] = 49;
  $values_min[29] = 49;
  $values_min[30] = 49;
  $values_min[31] = 49;
  $values_min[32] = 49;
  $values_min[33] = 49;
  $values_min[34] = 49;

  $values_max[6] = 50;
  $values_max[11] = 65;
  $values_max[12] = 52;
  $values_max[13] = 67;
  $values_max[14] = 68;
  $values_max[15] = 67;
  $values_max[16] = 51;
  $values_max[17] = 71;
  $values_max[18] = 72;
  $values_max[19] = 73;
  $values_max[20] = 72;
  $values_max[21] = 70;
  $values_max[22] = 76;
  $values_max[23] = 75;
  $values_max[24] = 50;
  $values_max[25] = 79;
  $values_max[26] = 80;
  $values_max[27] = 81;
  $values_max[28] = 77;
  $values_max[29] = 83;
  $values_max[30] = 82;
  $values_max[31] = 80;
  $values_max[32] = 80;
  $values_max[33] = 87;
  $values_max[34] = 78;
  $values_max[35] = 89;

  sub values_min {
    my ($self) = @_;
    my $radix = $self->{'radix'};
    return ($values_max[$radix] || 48);
  }
  sub values_max {
    my ($self) = @_;
    my $radix = $self->{'radix'};
    return ($values_max[$radix]
            || $radix + ($radix <= 10 ? 47 : 65-10));
  }
}

#------------------------------------------------------------------------------

# cf A109648 ascii with comma and space
my @oeis_anum;
$oeis_anum[10] = 'A109733';
# OEIS-Catalogue: A109733
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum[$self->{'radix'}];
}

#------------------------------------------------------------------------------

# ith() on radix 7 is wrong, report it as not available
sub can {
  my ($self, $name) = @_;
  if ($name eq 'ith' && ref $self && $self->{'radix'} == 7) {
    return undef;
  }
  return $self->SUPER::can($name);
}

sub rewind {
  my ($self) = @_;
  ### AsciiSelf rewind() ...
  $self->{'i'} = $self->i_start;

  # FIXME: this is a pre-calculation rather than a rewind ...
  my $radix = $self->{'radix'};
  ### $radix;
  my $start;
  foreach my $digit (0 .. $radix-1) {
    my $ascii = _digit_to_ascii($digit);
    my $r = $self->{'map'}->[$ascii] = [ _radix_ascii($radix,$ascii) ];
    if ($r->[0] == $ascii) {
      $start ||= $r->[0];
    }
  }
  $start ||= 48;
  $self->{'width'} = scalar(@{$self->{'map'}->[48]});
  $self->{'start'} = $start;
  ### $start

  $self->{'state'} = [ $self->{'map'}->[$start] ];
  $self->{'digits'} = [ -1 ];  # to start from 0 with preincrement
}

sub next {
  my ($self) = @_;
  ### AsciiSelf next(): "$self->{'i'}"
  ### digits: $self->{'digits'}
  ### state:  $self->{'state'}

  my $state = $self->{'state'};
  my $digits = $self->{'digits'};
  my $pos = 0;
  my $digit;
  for (;;) {
    if ($pos >= @$digits) {
      push @$state, $self->{'map'}->[$self->{'start'}];
      push @$digits, ($digit = 1);

      ### extend at pos: $pos
      ### extended digits: $digits
      ### extended state: $state
      last;
    }
    $digit = ++($digits->[$pos]);
    if ($digit < scalar(@{$state->[$pos]})) {
      last;
    }
    $pos++;
  }

  ### $pos
  ### $digit

  my $value = $state->[$pos]->[$digit];
  while ($pos > 0) {
    ### $value
    my $newtable = $state->[--$pos] = $self->{'map'}->[$value];
    $digits->[$pos] = 0;
    $value = $newtable->[0];
  }

  ### now digits: $digits
  ### now state: $state
  ### final value: $value

  return ($self->{'i'}++, $value);
}

sub ith {
  my ($self, $i) = @_;
  ### AsciiSelf ith(): "$i"

  if (_is_infinite($i) || ($i -= 1) < 0) {
    return undef;
  }

  my $map = $self->{'map'};
  my $width = $self->{'width'};
  my @digits;
  while ($i) {
    push @digits, $i % $width;
    $i = int($i/$width);
  }

  my $value = $self->{'start'};
  while (@digits) {
    my $digit = pop @digits;
    $value = $map->[$value]->[$digit];
  }
  return $value;
}

sub _radix_ascii {
  my ($radix, $n) = @_;
  my @digits;
  while ($n) {
    my $digit = ($n % $radix);
    push @digits, _digit_to_ascii($digit);
    $n = int($n/$radix);
  }
  return reverse @digits;
}

sub _digit_to_ascii {
  my ($digit) = @_;
  ### assert: $digit >= 0
  ### assert: $digit < 36
  return $digit + ($digit < 10 ? 48 : 65-10);  # '0' or 'A'
}

1;
__END__

=for stopwords Ryde Math-NumSeq OEIS Ith ith Radix radix ok

=head1 NAME

Math::NumSeq::AsciiSelf -- sequence is its own ASCII digits

=head1 SYNOPSIS

 use Math::NumSeq::AsciiSelf;
 my $seq = Math::NumSeq::AsciiSelf->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

A sequence which is itself in ASCII, Sloane's OEIS A109733.

    53, 51, 53, 49, 53, 51, 52, 57, etc

The first value 53 is digits 5,3 which in ASCII is the initial 53 and append
51.  That new 51 is digits 5,1 which is ASCII 53 and 49 which are appended.
Then those new digits 5,3,4,9 are ASCII 53,51,52,57 which are appended, and
so on.

Notice that interpreting the sequence values as ASCII gives the digits of
the sequence itself, and conversely expanding each value to its digits
represented in ASCII leaves the sequence unchanged.

The default is digits in decimal.  There's an experimental mostly-working
C<radix> parameter to do it in other bases.  Bases 8, 12 and 16 end up as
repetitions of a single value, which is not very interesting.  Bases 5, 9
and 13 have a choice of two starting self-ASCII values, but only the
smallest is used for now.  Base 7 C<ith()> is wrong, but <next()> is right.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::AsciiSelf-E<gt>new ()>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the C<$i>'th member of the sequence.  The first is i=1.

=back

=head1 FORMULAS

=head2 Ith

The doubling described above is the key to the sequence structure.
Numbering from k=i-1 so k=0 is the first member, take the bits of k from
high to low.  Start with value 53.  At each bit expand the value to its
digits in ASCII so for example 53 -> 53,51.  Take the first or second
according to whether the bit from k is 0 or 1.

=head2 Next

The bits of k for the ith calculation can be retained and incremented by a
carry algorithm, rather than breaking down in each C<next()> call.  The two
expanded ASCII values can be kept at each bit and selected by the bit value.

=head2 Radix

With the experimental C<radix> parameter for base 6 and smaller the ASCII
expands to 3 or more values.  For example 48 in binary is 110000 so six
ASCII 49,49,48,48,48,48.  The calculations are the same, but digits of that
size rather than bits.

In base 7 the digit lengths vary, since 48=66[7] and 49=100[7], so for it
the digit range depends on the expansion.  That's fine for C<next()> where
the number of digits at each state is available, but how best might C<ith()>
notice the shorter count for zeros?

=head1 BUGS

C<ith()> gives wrong values for the experimental C<radix> parameter for
radix 7.  C<can('ith')> returns false for that radix, as a way of saying
C<ith()> is not available.  (Other bases are ok.)

=head1 SEE ALSO

L<Math::NumSeq>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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

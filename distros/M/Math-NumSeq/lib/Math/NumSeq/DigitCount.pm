# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2017, 2019 Kevin Ryde

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

package Math::NumSeq::DigitCount;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 74;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Repdigits;
*_digit_split_lowtohigh = \&Math::NumSeq::Repdigits::_digit_split_lowtohigh;


# use constant name => Math::NumSeq::__('Digit Count');
use constant description => Math::NumSeq::__('How many of a given digit in each number, in a given radix, for example how many 1-bits in binary.');
use constant values_min => 0;
use constant default_i_start => 0;
use constant characteristic_count => 1;
use constant characteristic_smaller => 1;
use constant characteristic_increasing => 0;

use Math::NumSeq::Base::Digits;
use constant parameter_info_array =>
  [
   Math::NumSeq::Base::Digits->parameter_info_list(),
   {
    name        => 'digit',
    type        => 'integer',
    share_key   => 'digit-1',
    display     => Math::NumSeq::__('Digit'),
    default     => -1,
    minimum     => -1,
    width       => 2,
    description => Math::NumSeq::__('Digit to count, default -1 means radix-1.'),
   },
  ];

#------------------------------------------------------------------------------

# cf A008687 - count 1s in twos-complement -n
#    A000788 - cumulative count 1-bits in 0 to n
#    A033093 - total count 0s in all bases 2 to n+1
#    A059015 - cumulative count 0-bits
#    A000788 - cumulative count 1-bits
#    A077266 - triangle of count 0s in bases 2 to n+1
#    A077268 - num bases with at least one 0

my @oeis_anum;  # $oeis_anum[radix]->[digit]
BEGIN {
  # cf A023416 treating "0" as a single digit zero
  $oeis_anum[0]->[2]->[0] = 'A080791'; # base 2 count 0s, start i=0
  $oeis_anum[0]->[2]->[1] = 'A000120'; # base 2 count 1s, start i=0
  # OEIS-Catalogue: A080791 radix=2 digit=0
  # OEIS-Catalogue: A000120 radix=2 digit=1

  $oeis_anum[1]->[3]->[0] = 'A077267'; # base 3 count 0s, start i=1
  $oeis_anum[0]->[3]->[1] = 'A062756'; # base 3 count 1s, start i=0
  $oeis_anum[0]->[3]->[2] = 'A081603'; # base 3 count 2s, start i=0
  # OEIS-Catalogue: A077267 radix=3 digit=0 i_start=1
  # OEIS-Catalogue: A062756 radix=3 digit=1
  # OEIS-Catalogue: A081603 radix=3 digit=2
  #
  # cf A081602 start i=0 but considers i=0 to have 1 zero, unlike other counts
  # $oeis_anum[0]->[3]->[0] = 'A081602'; # base 3 count 0s, start i=0
  # # OEIS-Catalogue: A081602 radix=3 digit=0

  $oeis_anum[0]->[4]->[0] = 'A160380'; # base 4 count 0s, start i=0
  $oeis_anum[0]->[4]->[1] = 'A160381'; # base 4 count 1s, start i=0
  $oeis_anum[0]->[4]->[2] = 'A160382'; # base 4 count 2s, start i=0
  $oeis_anum[0]->[4]->[3] = 'A160383'; # base 4 count 3s, start i=0
  # OEIS-Catalogue: A160380 radix=4 digit=0
  # OEIS-Catalogue: A160381 radix=4 digit=1
  # OEIS-Catalogue: A160382 radix=4 digit=2
  # OEIS-Catalogue: A160383 radix=4 digit=3

  # almost A055641 decimal count 9s, but it starts i=0 has 1 zero

  $oeis_anum[0]->[10]->[9] = 'A102683'; # base 10 count 9s, start i=0
  # OEIS-Catalogue: A102683 radix=10 digit=9
}
sub oeis_anum {
  my ($self) = @_;
  my $radix = $self->{'radix'};
  my $digit = $self->{'digit'};
  if ($digit == -1) {
    $digit = $radix-1;
  } elsif ($digit >= $radix) {
    return 'A000004'; # all zeros, starting i=0
  }
  return $oeis_anum[$self->i_start]->[$radix]->[$digit];
}

sub ith {
  my ($self, $i) = @_;
  $i = abs($i);
  if (_is_infinite ($i)) {
    return $i;
  }

  my $radix = $self->{'radix'};
  my $digit = $self->{'digit'};
  if ($digit == -1) { $digit = $radix - 1; }

  my $count = 0;
  foreach my $got_digit (_digit_split_lowtohigh($i, $radix)) {
    if ($got_digit == $digit) {
      $count++;
    }
  }
  return $count;
}

sub pred {
  my ($self, $value) = @_;
  return ($value >= 0 && $value==int($value));
}

1;
__END__

=for stopwords Ryde Math-NumSeq radix radix-1

=head1 NAME

Math::NumSeq::DigitCount -- count of a given digit

=head1 SYNOPSIS

 use Math::NumSeq::DigitCount;
 my $seq = Math::NumSeq::DigitCount->new (radix => 10,
                                          digit => 9);
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The count of how many of a given digit is in C<$i> when written out in a
given radix.  The default is to count how many 9s in decimal.

    0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, ...
    starting i=0

For example i=19 has a single "9" so value=1.

The C<radix> and C<digit> options can select a different number base or
different digit to count.  For example to count the 0-bits in binary,

    # radix=>2, digit=>0
    0, 0, 1, 0, 2, 1, 1, 0, 3, 2, 2, 1, 2, 1, 1, 0, 4, 3, 3, 2, ...
    starting i=0

i=0 is treated as no digits at all, so it has value=0 for the count of
0-bits, and similarly in other bases counting 0 digits.

Option C<digit =E<gt> -1> gives the highest digit in the radix, ie. radix-1.
This is the default, so if C<radix> is given the count is of its biggest
digit.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::DigitCount-E<gt>new (radix =E<gt> $r, digit =E<gt> $d)>

Create and return a new sequence object.

C<digit> can be -1 to mean digit radix-1, the highest digit in the radix.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return how many of the given C<digit> is in C<$i> written in C<radix>.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> might occur as a digit count, which means simply
C<$valueE<gt>=0>.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::DigitLength>,
L<Math::NumSeq::RadixWithoutDigit>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2017, 2019 Kevin Ryde

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

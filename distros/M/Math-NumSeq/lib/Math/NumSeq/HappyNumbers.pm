# Copyright 2011, 2012, 2013, 2014, 2016 Kevin Ryde

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

package Math::NumSeq::HappyNumbers;
use 5.004;
use strict;
use List::Util 'sum';

use vars '$VERSION', '@ISA';
$VERSION = 73;

use Math::NumSeq;
use Math::NumSeq::Base::IteratePred;
@ISA = ('Math::NumSeq::Base::IteratePred',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Repdigits;
*_digit_split_lowtohigh = \&Math::NumSeq::Repdigits::_digit_split_lowtohigh;

# uncomment this to run the ### lines
# use Smart::Comments;


# use constant name => Math::NumSeq::__('Happy Numbers');
use constant description => Math::NumSeq::__('Happy numbers 1,7,10,13,19,23,etc, reaching 1 under iterating sum of squares of digits.');
use constant default_i_start => 1;
use constant values_min => 1;

use Math::NumSeq::Base::Digits
  'parameter_info_array';   # radix parameter

#------------------------------------------------------------------------------
# cf A035497 happy primes, happy numbers which are prime
#    A003621 how many steps to reach 1 or 4
#    A090425 how many steps for just the happy numbers
#    A031176 period of final cycle, being 1 or 8 in decimal
#
#    A000216 start 2 the cycle 4,16,37,58,89,145,42,20
#    A000218 start 3
#    A080709 start 4
#    A000221 start 5
#    A008460 start 6
#    A008462 start 8
#    A008463 start 9
#    A139566 start 15
#    A122065 start 74169
#
my @oeis_anum;
$oeis_anum[2] = 'A000027'; # 1,2,3,4, everything happy in base 2
# OEIS-Other: A000027 radix=2

$oeis_anum[4] = 'A000027'; # 1,2,3,4, everything happy in base 4
# OEIS-Other: A000027 radix=4

$oeis_anum[10] = 'A007770';
# OEIS-Catalogue: A007770 radix=10

sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum[$self->{'radix'}];
}

#------------------------------------------------------------------------------

sub pred {
  my ($self, $value) = @_;
  ### HappyNumbers pred(): $value
  if ($value <= 0
      || $value != int($value)
      || _is_infinite($value)) {
    return 0;
  }
  my $radix = $self->{'radix'};
  my %seen;
  for (;;) {
    ### $value
    if ($value == 1) {
      return 1;
    }
    if ($seen{$value}) {
      return 0;  # inf loop
    }
    $seen{$value} = 1;
    $value = _sum_of_squares_of_digits($value,$radix);
  }
}
sub _sum_of_squares_of_digits {
  my ($n, $radix) = @_;
  return sum (map {$_ * $_} _digit_split_lowtohigh($n,$radix));
}

1;
__END__

=for stopwords Ryde Math-NumSeq ie

=head1 NAME

Math::NumSeq::HappyNumbers -- reaching 1 under repeated sum of squares of digits

=head1 SYNOPSIS

 use Math::NumSeq::HappyNumbers;
 my $seq = Math::NumSeq::HappyNumbers->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This sequence is the happy numbers which are the numbers eventually reaching
1 on repeatedly taking the sum of the squares of the digits.

    1, 7, 10, 13, 19, 23, ...
    starting i=1

For example 23 is a happy number because the sum of squares of its digits
(ie. 2 and 3) is 2*2+3*3=13, then the same sum of squares again 1*1+3*3=10,
then 1*1+0*0=1 reaches 1.

In decimal it can be shown that for a non-zero starting point this procedure
always reaches either 1 or the cycle 4,16,37,58,89,145,42,20.  The values
which reach 1 are called happy numbers.

An optional C<radix> parameter can select a base other than decimal.  Base 2
and base 4 are not very interesting since for them every number except 0 is
happy.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::HappyNumbers-E<gt>new ()>

=item C<$seq = Math::NumSeq::HappyNumbers-E<gt>new (radix =E<gt> $r)>

Create and return a new sequence object.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is a happy number, meaning repeated sum of squares
of its digits reaches 1.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::HappySteps>,
L<Math::NumSeq::DigitSum>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2016 Kevin Ryde

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

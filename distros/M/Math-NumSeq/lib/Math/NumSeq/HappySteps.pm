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

package Math::NumSeq::HappySteps;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 73;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
#use Devel::Comments;


# use constant name => Math::NumSeq::__('Happy Steps');
use constant description => Math::NumSeq::__('How many sum of squares of digits steps to get to a repeating iteration.');
use constant i_start => 1;
use constant values_min => 1;
use constant characteristic_count => 1;
use constant characteristic_smaller => 1;
use constant characteristic_increasing => 0;

use Math::NumSeq::Base::Digits
  'parameter_info_array';   # radix parameter

#------------------------------------------------------------------------------
# cf A001273 smallest happy which takes N steps
#
my @oeis_anum;

$oeis_anum[2] = 'A078627'; # starting i=1 ...
# OEIS-Catalogue: A078627 radix=2

$oeis_anum[10] = 'A193995'; # but starting i=1 ...
# OEIS-Catalogue: A193995

sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum[$self->{'radix'}];
}

#------------------------------------------------------------------------------

sub ith {
  my ($self, $i) = @_;

  if ($i <= 0) {
    return 0;
  }
  if (_is_infinite($i)) {
    return $i;
  }

  my $radix = $self->{'radix'};
  my $steps = 0;
  my %seen;
  for (;;) {
    ### $i
    my $sum = 0;
    if ($seen{$i}) {
      return $steps;
    }
    $seen{$i} = 1;
    while ($i) {
      my $digit = ($i % $radix);
      $sum += $digit * $digit;
      $i = int($i/$radix);
    }
    $i = $sum;
    $steps++;
  }
}

sub pred {
  my ($self, $value) = @_;
  ### HappySteps pred(): $value
  return ($value >= 0 && $value == int($value));
}

1;
__END__

=for stopwords Ryde HappyNumbers HappySteps Math-NumSeq Radix

=head1 NAME

Math::NumSeq::HappySteps -- number of sum of squares of digits iterations to reach a repeat

=head1 SYNOPSIS

 use Math::NumSeq::HappySteps;
 my $seq = Math::NumSeq::HappySteps->new (radix => 10);
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is the number of iterations of the C<HappyNumbers> style "sum of
squares of digits" is required to reach a repeat of a value seen before, and
therefore to establish whether a number is a happy number or not.

    1, 9, 13, 8, 12, 17, 6, 13, 12, 2,
    starting i=1

For example i=10 is value 2 because 10-E<gt>1-E<gt>1 is 2 iterations to get
to a repeat (a repeat of 1).  At i=1 itself the value is 1 since 1 iteration
reaches 1 again which is itself the repeat.  That count 1 at i=1 is the
minimum.

=head2 Radix

An optional C<radix> parameter selects a base other than decimal.  In binary
C<radix=E<gt>2> the digits are all either 0 or 1 so "sum of squares of
digits" is the same as a plain "sum of digits".

In some bases there's longer cycles than others which a non-happy number
might fall into.  For example base 20 has a cycle

    10 -> 100 -> 25 -> 26 -> ... -> 61 -> 10
    total 26 elements

When a non-happy falls into such a cycle its C<HappySteps> count here is at
least 26 (or whatever amount) to reach a repeat.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::HappySteps-E<gt>new ()>

=item C<$seq = Math::NumSeq::HappySteps-E<gt>new (radix =E<gt> $r)>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the number of iterations starting from C<$i> required to reach a
repeat.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::HappyNumbers>,
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

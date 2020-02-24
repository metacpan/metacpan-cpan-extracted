# Copyright 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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


# http://www.inwap.com/pdp10/hbaker/hakmem/number.html#item56
# /so/hakmem/number.html


package Math::NumSeq::DigitProductSteps;
use 5.004;
use strict;
use List::Util 'reduce';

use vars '$VERSION', '@ISA';
$VERSION = 74;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Repdigits;
*_digit_split_lowtohigh = \&Math::NumSeq::Repdigits::_digit_split_lowtohigh;

use Math::NumSeq::DigitProduct;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('...');
use constant description => Math::NumSeq::__('Number of steps of digit product until reaching a single digit.');
use constant i_start => 0;
use constant characteristic_count => 1;
use constant characteristic_smaller => 1;
use constant characteristic_integer => 1;

use Math::NumSeq::Base::Digits;   # radix
use constant parameter_info_array =>
  [
   Math::NumSeq::Base::Digits::parameter_common_radix(),
   {
    name => 'values_type',
    type    => 'enum',
    share_key => 'values_type_countroot',
    default => 'count',
    choices => ['count',
                'root',
               ],
    choices_display => [Math::NumSeq::__('Count'),
                        Math::NumSeq::__('Root'),
                       ],
    description => Math::NumSeq::__('The values, either steps count or the final value after the steps.'),
   } ];
use constant values_min => 0;

#------------------------------------------------------------------------------
# cf A046511 - numbers with persistence 2
#
#    A031348 - iterate product of squares of digits until 0,1
#    A031349 - iterate product of cubes of digits
#    A031350 -
#    A031351
#    A031352
#    A031353
#    A031354
#    A031355 -
#    A031356 - 10th powers of digits
#
#    A087471 - iterate product of alternate digits, final digit
#    A087472 - num steps
#    A087473 - first of n iterations
#    A087474 - triangle of values of those first taking n iterations
#
#    A031286 - additive persistence to single digit
#    A010888 - additive root single digit

my %oeis_anum;

$oeis_anum{'count'}->[10] = 'A031346';
$oeis_anum{'root'}->[10] = 'A031347';
# OEIS-Catalogue: A031346
# OEIS-Catalogue: A031347 values_type=root

sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum{$self->{'values_type'}}->[$self->{'radix'}];
}

#------------------------------------------------------------------------------

sub ith {
  my ($self, $i) = @_;
  ### ith(): $i

  if (_is_infinite($i)) {
    return $i;  # don't loop forever if $i is +infinity
  }

  my $radix = $self->{'radix'};
  my $count = 0;
  for (;;) {
    my @digits = _digit_split_lowtohigh($i, $radix);
    if (@digits <= 1) {
      if ($self->{'values_type'} eq 'count') {
        return $count;
      } else {
        return $i;  # final root
      }
    }
    $i = reduce {$a*$b} @digits;
    $count++;
  }
}

sub pred {
  my ($self, $value) = @_;
  return ($value == int($value)
          && $value >= 0
          && ($self->{'values_type'} eq 'count'  # anything for count
              || $value < $self->{'radix'}));    # 0 to R-1 for root
}

1;
__END__

=for stopwords Ryde Math-NumSeq BigInt repunits Radix

=head1 NAME

Math::NumSeq::DigitProductSteps -- multiplicative persistence and digital root

=head1 SYNOPSIS

 use Math::NumSeq::DigitProductSteps;
 my $seq = Math::NumSeq::DigitProductSteps->new (values_type => 'count');
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is an iteration taking the product of the digits of a number until
reaching a single digit value.  The sequence values are the count of steps,
also called the multiplicative persistence.

    0,0,..0,0,1,1,..1,1,2,2,2,2,2,1,1,1,1,2,2,2,2,2,3,1,1,1,2,...
    starting i=0

For example i=39 goes 3*9=27 -E<gt> 2*7=14 -E<gt> 1*4=4 to reach a single
digit, so value=3 iterations.

The C<values_type =E<gt> 'root'> gives the final digit reached by the steps,
which is called the multiplicative digital root.

    values_type => 'root'
    0,1,2,...,9,0,1,...,9,0,2,4,6,8,0,2,4,6,8,0,3,6,9,2,5,8,...

i=0 through i=9 are already single digits so their count is 0 and root is
the value itself.  Then i=10 to i=19 all take just a single iteration to
reach a single digit.  i=25 is the first to require 2 iterations.

Any i with a 0 digit takes just one iteration to get to root 0.  Any i like
119111 which is all 1s except for at most a single non-1 takes just one
iteration.  This includes the repunits 111..11.

=head2 Radix

An optional C<radix> parameter selects a base other than decimal.

Binary C<radix=E<gt>2> is not very interesting since the digit product is
always either 0 or 1.  iE<gt>=2 always takes just 1 iteration and has root 0
except for i=2^k-1 all 1s with root 1.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::DigitProductSteps-E<gt>new ()>

=item C<$seq = Math::NumSeq::DigitProductSteps-E<gt>new (values_type =E<gt> $str, radix =E<gt> $integer)>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the sequence value, either count or final root value as selected.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs in the sequence.  For the count of steps
this means any integer C<$value E<gt>= 0>, or for a root any digit C<0
E<lt>= $value < radix>.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::DigitProduct>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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

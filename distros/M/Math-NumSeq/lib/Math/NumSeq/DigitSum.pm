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

package Math::NumSeq::DigitSum;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 74;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Digit Sum');
use constant description => Math::NumSeq::__('Sum of the digits in the given radix.  For binary this is how many 1-bits.');
use constant values_min => 0;
use constant i_start => 0;
use constant characteristic_increasing => 0;
use constant characteristic_smaller => 1;
use constant characteristic_integer => 1;

use Math::NumSeq::Base::Digits;
use constant parameter_info_array =>
  [ Math::NumSeq::Base::Digits->parameter_info_list,
    { name       => 'power',
      display    => Math::NumSeq::__('Power'),
      type       => 'integer',
      width      => 1,
      default    => '1',
      minimum    => 1,
      description => Math::NumSeq::__('Power of the digits, 1=plain sum, 2=sum of squares, 3=sum of cubes, etc.'),
    },
  ];


#------------------------------------------------------------------------------
# cf A010888 repeat DigitSum until single digit, is (n mod 9)+1, so 1 to 9
#    A179083 even with an odd sum of digits
#    A052018 digit sum occurs in the number
#    A054868 sum-of-bits then sum-of-bits again

my @oeis_anum;

$oeis_anum[1]->[2] = 'A000120';  # 2 binary, count of 1-bits like DigitCount
# OEIS-Other: A000120 radix=2
# OEIS-Other: A000120 radix=2 power=2
# OEIS-Other: A000120 radix=2 power=3

$oeis_anum[1]->[3] = 'A053735'; # 3 ternary
$oeis_anum[2]->[3] = 'A006287'; # 3 ternary squared digits
# OEIS-Catalogue: A053735 radix=3
# OEIS-Catalogue: A006287 radix=3 power=2

$oeis_anum[1]->[4] = 'A053737'; # 4
# OEIS-Catalogue: A053737 radix=4

$oeis_anum[1]->[5] = 'A053824'; # 5
# OEIS-Catalogue: A053824 radix=5

$oeis_anum[1]->[6] = 'A053827'; # 6
# OEIS-Catalogue: A053827 radix=6

$oeis_anum[1]->[7] = 'A053828'; # 7
# OEIS-Catalogue: A053828 radix=7

$oeis_anum[1]->[8] = 'A053829'; # 8
# OEIS-Catalogue: A053829 radix=8

$oeis_anum[1]->[9] = 'A053830'; # 9
# OEIS-Catalogue: A053830 radix=9

$oeis_anum[1]->[10] = 'A007953'; # 10 decimal
# OEIS-Catalogue: A007953

$oeis_anum[1]->[11] = 'A053831'; # 11
# OEIS-Catalogue: A053831 radix=11

$oeis_anum[1]->[12] = 'A053832'; # 12
# OEIS-Catalogue: A053832 radix=12

$oeis_anum[1]->[13] = 'A053833'; # 13
# OEIS-Catalogue: A053833 radix=13

$oeis_anum[1]->[14] = 'A053834'; # 14
# OEIS-Catalogue: A053834 radix=14

$oeis_anum[1]->[15] = 'A053835'; # 15
# OEIS-Catalogue: A053835 radix=15

$oeis_anum[1]->[16] = 'A053836'; # 16
# OEIS-Catalogue: A053836 radix=16

$oeis_anum[2]->[10] = 'A003132';
# OEIS-Catalogue: A003132 power=2

$oeis_anum[3]->[10] = 'A055012';
# OEIS-Catalogue: A055012 power=3

$oeis_anum[4]->[10] = 'A055013';
# OEIS-Catalogue: A055013 power=4

$oeis_anum[5]->[10] = 'A055014';
# OEIS-Catalogue: A055014 power=5

$oeis_anum[6]->[10] = 'A055015';
# OEIS-Catalogue: A055015 power=6

sub oeis_anum {
  my ($self) = @_;
  my $power = $self->{'power'};
  my $radix = $self->{'radix'};
  if ($radix == 2) { $power = 1; }
  return $oeis_anum[$power]->[$radix];
}

#------------------------------------------------------------------------------

# ENHANCE-ME:
# next() is +1 until wraps 09 to 10 is -8, or 0999 to 1000 is -998, etc
# radix=2 is DigitCount
#
# sub next {
#   my ($self) = @_;
#   my $radix = $self->{'radix'};
#   my $sum = $self->{'sum'} + 1;
#   if (++$self->{'digits'}->[0] >= $radix) {
#     $self->{'digits'}->[0] = 0;
#     my $i = 1;
#     for (;;) {
#       $sum++;
#       if (++$self->{'digits'}->[$i] < $radix) {
#         last;
#       }
#     }
#   }
#   return ($self->{'i'}++, ($self->{'sum'} = ($sum % $radix)));
# }

# ENHANCE-ME: radix=2 share Math::NumSeq::DigitCount binary
sub ith {
  my ($self, $i) = @_;
  ### DigitSum ith(): $i

  if (_is_infinite ($i)) {
    return $i;
  }

  my $radix = $self->{'radix'};
  my $power = $self->{'power'};
  my $sum = 0;
  while ($i) {
    $sum += ($i % $radix) ** $power;
    $i = int($i/$radix);
  }
  return $sum;
}

sub pred {
  my ($self, $value) = @_;
  return ($value == int($value)
          && $value >= 0);
}

1;
__END__

=for stopwords Ryde Math-NumSeq

=head1 NAME

Math::NumSeq::DigitSum -- sum of digits, possibly with powering

=head1 SYNOPSIS

 use Math::NumSeq::DigitSum;
 my $seq = Math::NumSeq::DigitSum->new (radix => 10);
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The sum of digits in each i, so 0,1,...,9,1,2,..., etc.  For example at
i=123 the value is 1+2+3=6.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::DigitSum-E<gt>new ()>

=item C<$seq = Math::NumSeq::DigitSum-E<gt>new (radix =E<gt> $r, power =E<gt> $p)>

Create and return a new sequence object.  The default is decimal, with no
powering, or C<radix> and/or C<power> parameters can be given.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the sum of the digits of C<$i>, each raised to the given C<power>
parameter.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs as a sum of digits, which means simply
C<$value E<gt>= 0>.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::DigitLength>,
L<Math::NumSeq::DigitProduct>,
L<Math::NumSeq::DigitSumModulo>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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

# Copyright 2011, 2012, 2013, 2014 Kevin Ryde

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

package Math::NumSeq::DigitSumSquares;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 71;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');

# uncomment this to run the ### lines
#use Smart::Comments;


use constant name => Math::NumSeq::__('Digit Sum of Squares');
use constant description => Math::NumSeq::__('Sum of the squares of the digits in the given radix.  (For binary this is how many 1-bits.)');
use constant values_min => 0;
use constant characteristic_increasing => 0;
use constant characteristic_smaller => 1;

use Math::NumSeq::Base::Digits
  'parameter_info_array';   # radix parameter


#------------------------------------------------------------------------------
my @oeis_anum;
$oeis_anum[2] = 'A000120';   # 2 binary, number of 1s, cf DigitCount
$oeis_anum[10] = 'A003132';
# OEIS-Catalogue: A003132

sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum[$self->{'radix'}];
}

#------------------------------------------------------------------------------

# ENHANCE-ME:
# next() is add 2*d+1 until wrap around then subtract
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
  
sub ith {
  my ($self, $i) = @_;
  my $radix = $self->{'radix'};
  my $sum = 0;
  while ($i) {
    $sum += ($i % $radix) ** 2;
    $i = int($i/$radix)
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

Math::NumSeq::DigitSumSquares -- sum of digits

=head1 SYNOPSIS

 use Math::NumSeq::DigitSumSquares;
 my $seq = Math::NumSeq::DigitSumSquares->new (radix => 10);
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The sum of squares of digits in each i, so 0, 1, 4, 9, 16, ..., 81, 1, 2, 5,
10, .., etc.  For example at i=123 the value is 1*1+2*2+3*3=14.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::DigitSumSquares-E<gt>new ()>

=item C<$seq = Math::NumSeq::DigitSumSquares-E<gt>new (radix =E<gt> $r)>

Create and return a new sequence object.  The default radix is 10,
ie. decimal, or a C<radix> parameter can be given.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the sum of the digits of C<$i>.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs as the sum of squares of digits, which means
simply C<$value E<gt>= 0>.  Any integer C<$value> can occur from all-ones
11..11.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::DigitSum>

=head1 HOME PAGE

http://user42.tuxfamily.org/math-numseq/index.html

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014 Kevin Ryde

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

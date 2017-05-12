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

package Math::NumSeq::HarshadNumbers;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 72;

use Math::NumSeq;
use Math::NumSeq::Base::IteratePred;
@ISA = ('Math::NumSeq::Base::IteratePred',
        'Math::NumSeq');

# uncomment this to run the ### lines
#use Devel::Comments;

# use constant name => Math::NumSeq::__('Harshad Numbers');
use constant description => Math::NumSeq::__('Harshad numbers, divisible by the sum of their digits.');
use constant default_i_start => 1;
use constant values_min => 1;

use Math::NumSeq::Base::Digits
  'parameter_info_array';   # radix parameter

#------------------------------------------------------------------------------

my @oeis_anum;
$oeis_anum[2]  = 'A049445';  # binary 1s divide N  OFFSET=1
$oeis_anum[3]  = 'A064150';  # base 3              OFFSET=0
$oeis_anum[4]  = 'A064438';  # base 4              OFFSET=1
$oeis_anum[5]  = 'A064481';  # base 5              OFFSET=1
$oeis_anum[10] = 'A005349';  # decimal sum digits divide N  OFFSET=1
# OEIS-Catalogue: A049445 radix=2
# OEIS-Catalogue: A064150 radix=3 i_start=0
# OEIS-Catalogue: A064438 radix=4
# OEIS-Catalogue: A064481 radix=5
# OEIS-Catalogue: A005349

sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum[$self->{'radix'}];
}

#------------------------------------------------------------------------------

sub pred {
  my ($self, $value) = @_;
  ### HarshadNumbers pred(): $value
  if ($value <= 0) {
    return 0;
  }
  my $radix = $self->{'radix'};
  my $sum = 0;
  my $v = $value;
  while ($v) {
    $sum += ($v % $radix);
    $v = int($v/$radix);
  }
  return ($sum > 0 && ($value % $sum) == 0);
}
# sub ith {
#   my ($self, $i) = @_;
#   return ...
# }

1;
__END__

=for stopwords Ryde Math-NumSeq harshad ie

=head1 NAME

Math::NumSeq::HarshadNumbers -- numbers divisible by sum of digits

=head1 SYNOPSIS

 use Math::NumSeq::HarshadNumbers;
 my $seq = Math::NumSeq::HarshadNumbers->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The harshad numbers 1 to 10, then 12, 18, 20, 21, etc, being integers which
are divisible by the sum of their digits.  For example 18 is a harshad
number because 18 is divisible by its digit sum 1+8=9.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::HarshadNumbers-E<gt>new ()>

=item C<$seq = Math::NumSeq::HarshadNumbers-E<gt>new (radix =E<gt> $r)>

Create and return a new sequence object.

The optional C<radix> parameter (default 10, decimal) sets the base to use
for the digits.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is a harshad number, ie. is divisible by the sum of
its digits (in the given C<radix>).

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::DigitSum>,
L<Math::NumSeq::MoranNumbers>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

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

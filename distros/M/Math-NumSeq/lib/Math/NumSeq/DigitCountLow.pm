# Copyright 2010, 2011, 2012, 2013, 2014 Kevin Ryde

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

package Math::NumSeq::DigitCountLow;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 72;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Digit Count Low');
use constant description => Math::NumSeq::__('How many of a given digit at the low end of a number, in a given radix.');
use constant values_min => 0;
use constant default_i_start => 0;
use constant characteristic_count => 1;
use constant characteristic_smaller => 1;
use constant characteristic_increasing => 0;

use Math::NumSeq::DigitCount 4; # radix,digit parameter
*parameter_info_array = \&Math::NumSeq::DigitCount::parameter_info_array;

#------------------------------------------------------------------------------
# cf A006519 - highest k s.t. 2^k+1 divides n
#    A001511 low 0s in 2*n, ie +1
#    A070940 low 0s pos counting from the left
#    A051064 low 0s of 3*n in ternary, ie +1
#    A160094 low zeros in 10 counting from the right from 1
#    A160093 low zeros in 10 pos counting from the left
#
my @oeis_anum;

$oeis_anum[1]->[2]->[0] = 'A007814'; # base 2 low 0s, starting i=1
# OEIS-Catalogue: A007814 radix=2 digit=0 i_start=1

$oeis_anum[1]->[3]->[0] = 'A007949'; # base 3 low 0s, starting i=1
# OEIS-Catalogue: A007949 radix=3 digit=0 i_start=1

$oeis_anum[1]->[5]->[0] = 'A112765'; # base 5 low 0s, starting i=1
# OEIS-Catalogue: A112765 radix=5 digit=0 i_start=1

$oeis_anum[1]->[6]->[0] = 'A122841'; # base 6 low 0s, starting i=1
# OEIS-Catalogue: A122841 radix=6 digit=0 i_start=1

$oeis_anum[1]->[10]->[0] = 'A122840'; # base 10 low 0s, starting i=1
# OEIS-Catalogue: A122840 radix=10 digit=0 i_start=1

sub oeis_anum {
  my ($self) = @_;
  my $radix = $self->{'radix'};
  my $digit = $self->{'digit'};
  if ($digit == -1) {
    $digit = $radix-1;
  } elsif ($digit >= $radix) {
    return 'A000004'; # all zeros,
  }
  return $oeis_anum[$self->i_start]->[$radix]->[$digit];
}

#------------------------------------------------------------------------------

sub ith {
  my ($self, $i) = @_;
  ### DigitCountLow ith(): $i

  $i = abs($i);
  if (_is_infinite($i)) {
    return $i;  # don't loop forever if $i is +infinity
  }

  my $radix = $self->{'radix'};
  my $digit = $self->{'digit'};
  if ($digit == -1) { $digit = $radix - 1; }

  my $count = 0;
  if ($radix == 2) {
    ### binary ...
    while ($i) {
      last unless (($i & 1) == $digit);
      $count++;
      $i >>= 1;
    }
  } else {
    ### general radix: $radix
    while ($i) {
      last unless (($i % $radix) == $digit);
      $count++;
      $i = int($i/$radix);
    }
  }
  return $count;
}

sub pred {
  my ($self, $value) = @_;
  return ($value >= 0 && $value == int($value));
}

1;
__END__

=for stopwords Ryde Math-NumSeq radix radix-1

=head1 NAME

Math::NumSeq::DigitCountLow -- count of given low digits

=head1 SYNOPSIS

 use Math::NumSeq::DigitCountLow;
 my $seq = Math::NumSeq::DigitCountLow->new (radix => 10,
                                             digit => 9);
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The count of how many of a given digit are at the low end of C<$i> when
written out in a given radix.  The default is to count how many low 9s in
decimal.  For example i=9599 has value 2 as there's two consecutive 9s at
the low end.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::DigitCountLow-E<gt>new (radix =E<gt> $r, digit =E<gt> $d)>

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
L<Math::NumSeq::DigitCount>,
L<Math::NumSeq::DigitCountHigh>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014 Kevin Ryde

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

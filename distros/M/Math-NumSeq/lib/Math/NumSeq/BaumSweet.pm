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


# math-image --values=BaumSweet --path=ZOrderCurve
#
# radix parameter ?


package Math::NumSeq::BaumSweet;
use 5.004;
use strict;

use vars '$VERSION','@ISA';
$VERSION = 72;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
#use Smart::Comments;

# use constant name => Math::NumSeq::__('Baum-Sweet');
use constant description => Math::NumSeq::__('Baum-Sweet sequence, 1 if i contains no odd-length run of 0-bits, 0 if it does.');
use constant default_i_start => 0;
use constant values_min => 0;
use constant values_max => 1;
use constant characteristic_integer => 1;

# cf A037011 "Baum Sweet cubic"
#            a(k)=1 iff k/3 is in A003714 fibbinary
#
use constant oeis_anum => 'A086747'; # starting OFFSET=0 value 1

sub ith {
  my ($self, $i) = @_;
  ### BaumSweet ith(): $i

  if (_is_infinite($i)) {
    return $i;
  }
  while ($i >= 1) {
    if (($i % 2) == 0) {
      my $oddzeros = 0;
      do {
        $oddzeros ^= 1;
        $i /= 2;
      } until ($i % 2);
      if ($oddzeros) {
        return 0;
      }
    }
    $i = int($i/2);
  }
  return 1;
}

sub pred {
  my ($self, $value) = @_;
  return ($value == 0 || $value == 1);
}

1;
__END__

=for stopwords Ryde Math-NumSeq BaumSweet ie

=head1 NAME

Math::NumSeq::BaumSweet -- Baum-Sweet sequence

=head1 SYNOPSIS

 use Math::NumSeq::BaumSweet;
 my $seq = Math::NumSeq::BaumSweet->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The Baum-Sweet sequence

    1, 1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 0, ...
    starting i=0

where each value is 1 if the index i contains no odd-length run of 0-bits,
or 0 if it does.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::BaumSweet-E<gt>new ()>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the C<$i>'th BaumSweet number, ie. 1 or 0 according to whether C<$i>
is without or with an odd-length run of 0-bits.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs in the sequence, which simply means 0 or 1.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::GolayRudinShapiro>,
L<Math::NumSeq::Fibbinary>

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

# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2017 Kevin Ryde

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

package Math::NumSeq::StarNumbers;
use 5.004;
use strict;
use POSIX 'ceil';
use List::Util 'max';

use vars '$VERSION','@ISA';
$VERSION = 73;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');


# use constant name => Math::NumSeq::__('Star Numbers');
use constant description =>  Math::NumSeq::__('The star numbers 1, 13, 37, 73, 121, etc, 6*n*(n-1)+1, also called the centred 12-gonals.');
use constant default_i_start => 1;
use constant values_min => 1;
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;

# cf
# A006060 - which are also triangular numbers
#     A068774 - indices of the triangulars
#     A068775 - indices of the stars
# A006061 - which are also perfect squares
#     A054320 - indices of the squares
#     A068778 - indices of the stars
#

# centered polygonal numbers (k*n^2-k*n+2)/2, for k = 3 through 14 sides:
# A005448 , A001844 , A005891 , A003215 , A069099 , A016754 , A060544 ,
# A062786 , A069125 , A003154 , A069126 , A069127
#
# centered polygonal numbers (k*n^2-k*n+2)/2, for k = 15 through 20 sides:
# A069128 , A069129 , A069130 , A069131 , A069132 , A069133
#
use constant oeis_anum => 'A003154'; # star numbers

sub _UNTESTED__seek_to_value {
  my ($self, $value) = @_;
  $self->{'i'} = $self->value_to_i_ceil($value);
}

sub ith {
  my ($self, $i) = @_;
  return 6*$i*($i-1)+1;
}
sub pred {
  my ($self, $value) = @_;
  if ($value >= 0) {
    my $int = int($value);
    if ($value == $int) {
      my $i = _inverse($int);
      return ($int == $self->ith($i));
    }
  }
  return 0;
}

sub value_to_i {
  my ($self, $value) = @_;
  if ($value >= 0) {
    my $int = int($value);
    if ($value == $int) {
      my $i = int(_inverse($int));
      if ($int == $self->ith($i)) {
        return $i;
      }
    }
  }
  return undef;
}
sub value_to_i_floor {
  my ($self, $value) = @_;
  if ($value < 0) { return 0; }
  return int(_inverse(int($value)));
}
*value_to_i_estimate = \&value_to_i_floor;

# i = 1/2 + sqrt(1/6 * $n + 1/12)
#   = (3 + sqrt(6 * $n + 3)) / 6
#
sub _inverse {
  my ($int) = @_;
  return int ((sqrt(6*$int + 3) + 3) / 6);
}

1;
__END__

=for stopwords Ryde Math-NumSeq 12-gonals

=head1 NAME

Math::NumSeq::StarNumbers -- star numbers 6*i*(i-1)+1

=head1 SYNOPSIS

 use Math::NumSeq::StarNumbers;
 my $seq = Math::NumSeq::StarNumbers->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The sequence of star numbers 1, 13, 37, 73, 121, etc, 6*i*(i-1)+1, also
called the centred 12-gonals.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::StarNumbers-E<gt>new ()>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return C<6*$i*($i-1)+1>.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is of the form 6*i*(i-1)+1 for some i.

=item C<$i = $seq-E<gt>value_to_i_floor($value)>

=item C<$i = $seq-E<gt>value_to_i_estimate($value)>

Return the i for the star number E<lt>= $value.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Polygonal>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2017 Kevin Ryde

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

# Copyright 2010, 2011, 2012, 2013, 2014, 2016 Kevin Ryde

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

package Math::NumSeq::Triangular;
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

# uncomment this to run the ### lines
# use Smart::Comments;


# use constant name => Math::NumSeq::__('Triangular Numbers');
use constant description => Math::NumSeq::__('The triangular numbers 0, 1, 3, 6, 10, 15, 21, 28, etc, i*(i+1)/2.');
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;
use constant default_i_start => 0;
use constant values_min => 0;  # at i=0

#------------------------------------------------------------------------------
# cf A062828 gcd(2n,triangular(n))
#

use constant oeis_anum => 'A000217'; # starting from i=0 value=0

#------------------------------------------------------------------------------

sub ith {
  my ($self, $i) = @_;
  return $i*($i+1)/2;
}

# [1,2,3,4,5],[1,3,6,10,15]
# N = ((1/2*$d + 1/2)*$d)
# d = -1/2 + sqrt(2 * $n + 1/4)
#   = (-1 + 2*sqrt(2 * $n + 1/4))/2
#   = (sqrt(4*2*$n + 1) - 1)/2
#   = (sqrt(8*$n + 1) - 1)/2
sub pred {
  my ($self, $value) = @_;
  ### Triangular pred(): $value

  if ($value < 0) { return 0; }
  my $int = int($value);
  if ($value != $int) { return 0; }

  $int *= 2;
  my $i = int((sqrt(4*$int + 1) - 1)/2);

  ### $int
  ### $i
  ### triangular: ($i+1)*$i/2

  return ($int == ($i+1)*$i);
}

sub value_to_i {
  my ($self, $value) = @_;
  if ($value >= 0) {
    my $int = int($value);
    if ($value == $int) {
      my $i = int((sqrt(8*$int + 1) - 1)/2);
      if ($int == $self->ith($i)) {
        return $i;
      }
    }
  }
  return undef;
}
sub value_to_i_floor {
  my ($self, $value) = @_;
  if ($value < 0) {
    return 0;
  }
  return int((sqrt(8*int($value) + 1) - 1)/2);
}
*value_to_i_estimate = \&value_to_i_floor;

sub value_to_i_ceil {
  my ($self, $value) = @_;
  ### value_to_i_ceil(): $value
  if ($value <= 0) {
    return 0;
  }
  my $i = $self->value_to_i_floor($value);
  if ($self->ith($i) < $value) {
    return $i+1;
  } else {
    return $i;
  }
}

1;
__END__

=for stopwords Ryde Math-NumSeq ie

=head1 NAME

Math::NumSeq::Triangular -- triangular numbers

=head1 SYNOPSIS

 use Math::NumSeq::Triangular;
 my $seq = Math::NumSeq::Triangular->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The triangular numbers i*(i+1)/2,

    0, 1, 3, 6, 10, 15, 21, 28, ...
    starting i=0

The numbers are how many points are in an equilateral triangle of side i,

       *      i=1  1

       *      i=2  3
      * *

       * 
      * *     i=3  6
     * * *

       *      
      * *     i=4  10
     * * *
    * * * *

From a given i, the next value is formed by adding i+1, being a new row of
that length on the bottom of the triangle.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::Triangular-E<gt>new ()>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return C<$i*($i+1)/2>.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is a triangular number, ie. i*(i+1)/2 for some
integer i.

=item C<$i = $seq-E<gt>value_to_i_ceil($value)>

=item C<$i = $seq-E<gt>value_to_i_floor($value)>

Return the index i of C<$value>, or if C<$value> is not a triangular number
then the next higher for C<ceil> or lower for C<floor>.

=item C<$i = $seq-E<gt>value_to_i_estimate($value)>

Return an estimate of the i corresponding to C<$value>.  This is
value=i*(i+1)/2 is inverted to

    $i = int ((sqrt(8*$value + 1) - 1)/2)

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Pronic>,
L<Math::NumSeq::Squares>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2016 Kevin Ryde

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

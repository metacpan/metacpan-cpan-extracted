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

package Math::NumSeq::Pronic;
use 5.004;
use strict;
use POSIX 'ceil';
use List::Util 'max';

use vars '$VERSION','@ISA';
$VERSION = 72;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');

# uncomment this to run the ### lines
#use Smart::Comments;

# use constant name => Math::NumSeq::__('Pronic Numbers');
use constant description => Math::NumSeq::__('The pronic numbers 0, 2, 6, 12, 20, 30, etc, etc, i*(i+1).  These are twice the triangular numbers, and half way between perfect squares.');
use constant default_i_start => 0;
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;
use constant values_min => 0; # at i=0
use constant oeis_anum => 'A002378'; # pronic, starting from 0

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
}
sub seek_to_i {
  my ($self, $i) = @_;
  $self->{'i'} = $i;
}
sub seek_to_value {
  my ($self, $value) = @_;
  $self->seek_to_i($self->value_to_i_ceil($value));
}
sub ith {
  my ($self, $i) = @_;
  return $i*($i+1);
}

# [0,1,2,3,4],[0,2,6,12,20]
# N = (d^2 + d)
#   = ($d**2 + $d)
#   = (($d + 1)*$d)
# d = -1/2 + sqrt(1 * $n + 1/4)
#   = (-1 + 2*sqrt(1 * $n + 1/4))/2
#   = (-1 + sqrt(4 * $n + 1))/2
#   = (sqrt(4*$n + 1) - 1)/2

sub pred {
  my ($self, $value) = @_;
  if ($value < 0) { return 0; }
  my $i = $self->value_to_i_floor($value);
  return ($value == $i*($i+1));
}

sub value_to_i {
  my ($self, $value) = @_;
  if ($value >= 0) {
    my $int = int($value);
    if ($value == $int) {
      my $i = int((sqrt(4*$int + 1) - 1)/2);
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
  return int((sqrt(4*int($value) + 1) - 1)/2);
}
sub value_to_i_ceil {
  my ($self, $value) = @_;
  my $i = $self->value_to_i_floor($value);
  if ($self->ith($i) < $value) {
    return $i+1;
  } else {
    return $i;
  }
}
*value_to_i_estimate = \&value_to_i_floor;

1;
__END__

=for stopwords Ryde Math-NumSeq pronic ie

=head1 NAME

Math::NumSeq::Pronic -- pronic numbers

=head1 SYNOPSIS

 use Math::NumSeq::Pronic;
 my $seq = Math::NumSeq::Pronic->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The pronic numbers i*(i+1),

    0, 2, 6, 12, 20, 30, ...
    starting i=0

These are twice the triangular numbers, and half way between the perfect
squares.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::Pronic-E<gt>new ()>

Create and return a new sequence object.

=back

=head2 Iterating

=over

=item C<$seq-E<gt>seek_to_i($i)>

Move the current sequence position to C<$i>.  The next call to C<next()>
will return C<$i> and corresponding value.

=item C<$seq-E<gt>seek_to_value($value)>

Move the current sequence position so that C<next()> will give C<$value> on
the next call, or if C<$value> is not a pronic number then the next pronic
above C<$value>.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return C<$i*($i+1)>.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is a pronic number, ie. i*(i+1) for some i.

=item C<$i = $seq-E<gt>value_to_i_ceil($value)>

=item C<$i = $seq-E<gt>value_to_i_floor($value)>

Return the C<$i> index of C<$value>, rounding up or down if C<$value> is not
a pronic number.

=item C<$i = $seq-E<gt>value_to_i_estimate($value)>

Return an estimate of the i corresponding to C<$value>.  value=i*(i+1) is
inverted by

    $i = int( (sqrt(4*$value + 1) - 1)/2 )

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Squares>,
L<Math::NumSeq::Triangular>

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

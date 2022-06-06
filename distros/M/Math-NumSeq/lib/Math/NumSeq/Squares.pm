# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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

package Math::NumSeq::Squares;
use 5.004;
use strict;
use POSIX 'ceil';
use List::Util 'max';

use vars '$VERSION','@ISA';
$VERSION = 75;

use Math::NumSeq;
@ISA = ('Math::NumSeq');

# uncomment this to run the ### lines
#use Smart::Comments;

# use constant name =>  Math::NumSeq::__('Perfect Squares');
use constant description => Math::NumSeq::__('The squares 1,4,9,16,25, etc k*k.');
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;
use constant i_start => 0;
use constant values_min => 0;

#------------------------------------------------------------------------------
# cf A001105 2*n^2
#    A000037 non-squares
#    A010052 characterisic 1/0 for squares
#
use constant oeis_anum => 'A000290'; # squares

#------------------------------------------------------------------------------

use constant 1.02 _UV_I_LIMIT => do {
  # Float integers too when IV=32bits ?
  # my $max = 1;
  # for (1 .. 256) {
  #   my $try = $max*2 + 1;
  #   ### $try
  #   if ($try == 2*$max || $try == 2*$max+2) {
  #     last;
  #   }
  #   $max = $try;
  # }
  my $max = ~0;

  my $bit = 4;
  for (my $i = $max; $i != 0; $i=int($i/8)) {
    $bit *= 2;
  }
  ### $bit

  my $sqrt = 0;
  for ( ; $bit != 0; $bit=int($bit/2)) {
    my $try = $sqrt + $bit;
    if ($try <= $max / $try) {
      $sqrt = $try;
    }
  }

  ### $max
  ### limit sqrt: $sqrt
  ### limit square: $sqrt*$sqrt
  ### sqrt hex: sprintf '%X', $sqrt
  ### square hex: sprintf '%X', $sqrt*$sqrt

  ### assert: $sqrt <= $max/$sqrt

  $sqrt
};

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
}
sub seek_to_i {
  my ($self, $i) = @_;
  if ($i >= _UV_I_LIMIT) {
    $i = Math::NumSeq::_to_bigint($i);
  }
  $self->{'i'} = $i;
}
sub seek_to_value {
  my ($self, $value) = @_;
  $self->seek_to_i($self->value_to_i_ceil($value));
}
sub next {
  my ($self) = @_;
  ### Squares next(): $self->{'i'}
  my $i = $self->{'i'}++;
  if ($i == _UV_I_LIMIT) {
    $self->{'i'} = Math::NumSeq::_to_bigint($self->{'i'});
  }
  return ($i, $i*$i);
}

sub ith {
  my ($self, $i) = @_;
  return $i*$i;
}
sub pred {
  my ($self, $value) = @_;
  ### Squares pred(): $value

  if ($value < 0) { return 0; }

  my $int = int($value);
  if ($value != $int) { return 0; }

  my $i = int(sqrt($int));
  return ($int == $i*$i);
}

sub value_to_i {
  my ($self, $value) = @_;
  if ($value >= 0) {
    my $int = int($value);
    if ($value == $int) {
      my $i = int(sqrt($int));
      if ($int == $self->ith($i)) {
        return $i;
      }
    }
  }
  return undef;
}
sub value_to_i_floor {
  my ($self, $value) = @_;
  if ($value < 0) { $value = 0; }
  return int(sqrt(int($value)));
}
*value_to_i_estimate = \&value_to_i_floor;

sub value_to_i_ceil {
  my ($self, $value) = @_;
  if ($value < 0) { return 0; }
  my $i = $self->value_to_i_floor($value);
  if ($i*$i < $value) {
    $i += 1;
  }
  return $i;
}


1;
__END__

=for stopwords Ryde Math-NumSeq ie

=head1 NAME

Math::NumSeq::Squares -- perfect squares

=head1 SYNOPSIS

 use Math::NumSeq::Squares;
 my $seq = Math::NumSeq::Squares->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The sequence of squares i**2,

    0, 1, 4, 9, 16, 25, ...     (A000290)

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::Squares-E<gt>new ()>

Create and return a new sequence object.

=back

=head2 Iterating

=over

=item C<$seq-E<gt>seek_to_i($i)>

Move the current sequence position to C<$i>.  The next call to C<next()>
will return C<$i> and corresponding value.

=item C<$seq-E<gt>seek_to_value($value)>

Move the current sequence position so that C<next()> will give C<$value> on
the next call, or if C<$value> is not a square then the next square above
C<$value>.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return C<$i * $i>.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is a square, ie. k*k for some integer k.

=item C<$i = $seq-E<gt>value_to_i_ceil($value)>

=item C<$i = $seq-E<gt>value_to_i_floor($value)>

Return the square root of C<$value>, rounded up or down to the next integer.

=item C<$i = $seq-E<gt>value_to_i_estimate($value)>

Return an estimate of the i corresponding to C<$value>.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Pronic>,
L<Math::NumSeq::Triangular>,
L<Math::NumSeq::Cubes>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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

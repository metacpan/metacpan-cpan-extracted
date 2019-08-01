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

package Math::NumSeq::Even;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 73;
use Math::NumSeq;
@ISA = ('Math::NumSeq');


# uncomment this to run the ### lines
#use Smart::Comments;

# use constant name => Math::NumSeq::__('Even Integers');
use constant description => Math::NumSeq::__('The even integers 0, 2, 4, 6, 8, 10, etc.');
use constant i_start => 0;
use constant values_min => 0;
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;

# cf A007958 even with at least one odd digit
use constant oeis_anum => 'A005843'; # even 0,2,4

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
sub next {
  my ($self) = @_;
  my $i = $self->{'i'}++;
  return ($i, 2*$i);
}
sub ith {
  my ($self, $i) = @_;
  return 2*$i;
}
sub pred {
  my ($self, $value) = @_;
  ### Even pred(): $value
  return ($value == int($value)
          && ($value % 2) == 0);
}

sub value_to_i {
  my ($self, $value) = @_;
  my $int = int($value);
  if ($value == $int
      && ($int % 2) == 0) {
    return $int/2;
  }
  return undef;
}
sub value_to_i_floor {
  my ($self, $value) = @_;
  if ($value < 0) {
    my $i = int($value/2);
    if (2*$i == $value) {
      return $i;
    } else {
      return $i-1;
    }
  } else {
    return int($value/2);
  }
}
sub value_to_i_ceil {
  my ($self, $value) = @_;
  my $i = int($value/2);
  if (2*$i < $value) {
    return $i+1;
  } else {
    return $i;
  }
}
sub value_to_i_estimate {
  my ($self, $value) = @_;
  return int($value/2);
}

1;
__END__

=for stopwords Ryde Math-NumSeq

=head1 NAME

Math::NumSeq::Even -- even integers

=head1 SYNOPSIS

 use Math::NumSeq::Even;
 my $seq = Math::NumSeq::Even->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The even integers,

    0, 2, 4, 6, 8, 10, ...
    starting i=0

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::Even-E<gt>new ()>

Create and return a new sequence object.

=back

=head2 Iterating

=over

=item C<$seq-E<gt>seek_to_i($i)>

Move the current sequence position to C<$i>.  The next call to C<next()>
will return C<$i> and corresponding value.

=item C<$seq-E<gt>seek_to_value($value)>

Move the current i so that C<next()> gives C<$value> on the next call, or if
C<$value> is an even integer then the next higher even.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return C<2*$i>.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is even.

=item C<$i = $seq-E<gt>value_to_i_ceil($value)>

=item C<$i = $seq-E<gt>value_to_i_floor($value)>

Return value/2 rounded up or down to the next integer.

=item C<$i = $seq-E<gt>value_to_i_estimate($value)>

Return an estimate of the i corresponding to C<$value>.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Odd>,
L<Math::NumSeq::All>

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

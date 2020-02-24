# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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

package Math::NumSeq::All;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 74;
use Math::NumSeq;
@ISA = ('Math::NumSeq');

# uncomment this to run the ### lines
#use Smart::Comments;

# use constant name => Math::NumSeq::__('All Integers');
use constant description => Math::NumSeq::__('All integers 0,1,2,3,etc.');
use constant default_i_start => 0;
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;

# experimental i_start to get natural numbers ... probably not very important
# OEIS-Catalogue: A000027 i_start=1
# OEIS-Catalogue: A001477
my %oeis_anum = (0 => 'A001477',  # non-negatives,  starting 0
                 1 => 'A000027'); # natural numbers starting 1
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum{$self->i_start};
}
sub values_min {
  my ($self) = @_;
  return $self->i_start;
}

sub rewind {
  my ($self) = @_;
  $self->seek_to_i($self->i_start);
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
  return ($i, $i);
}

sub ith {
  my ($self, $i) = @_;
  return $i;
}

sub pred {
  my ($self, $value) = @_;
  return ($value == int($value));
}

sub value_to_i {
  my ($self, $value) = @_;
  if ($value == int($value)) {
    return $value;
  }
  return undef;
}
sub value_to_i_floor {
  my ($self, $value) = @_;
  return _floor($value);
}
sub value_to_i_ceil {
  my ($self, $value) = @_;
  return _ceil($value);
}
sub value_to_i_estimate {
  my ($self, $value) = @_;
  return int($value);
}

#------------------------------------------------------------------------------
# generic

# _floor() trying to work with BigRat/BigFloat too.
#
# For reference, POSIX::floor() in perl 5.12.4 is a bit bizarre on UV=64bit
# and NV=53bit double.  UV=2^64-1 rounds up to NV=2^64 which floor() then
# returns, so floor() in fact increases the value of what was an integer
# already.
#
sub _floor {
  my ($x) = @_;
  ### _floor(): "$x", $x
  my $int = int($x);
  if ($x == $int) {
    ### is an integer ...
    return $x;
  }
  $x -= $int;
  ### frac: "$x"
  if ($x >= 0) {
    ### frac is non-negative ...
    return $int;
  } else {
    ### frac is negative ...
    return $int-1;
  }
}

# _ceil() trying to work with BigRat/BigFloat too.
#
sub _ceil {
  my ($x) = @_;
  ### _ceil(): "$x", $x

  my $int = int($x);
  if ($x == $int) {
    ### is an integer ...
    return $x;
  }
  $x -= $int;
  ### frac: "$x"
  if ($x > 0) {
    ### frac is positive ...
    return $int+1;
  } else {
    ### frac is non-negative ...
    return $int;
  }
}

1;
__END__

=for stopwords Ryde Math-NumSeq NumSeq

=head1 NAME

Math::NumSeq::All -- all integers

=head1 SYNOPSIS

 use Math::NumSeq::All;
 my $seq = Math::NumSeq::All->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The non-negative integers 0,1,2,3,4, etc.

As a module this is trivial, but it helps put all integers into things using
NumSeq.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::All-E<gt>new ()>

Create and return a new sequence object.

=item C<$i = $seq-E<gt>seek_to_value($value)>

Move the current i so that C<next()> will give C<$value> on the next call,
or ceil($value) if C<$value> is an integer.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return C<$i>.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is an integer.

=item C<$i = $seq-E<gt>value_to_i_ceil($value)>

=item C<$i = $seq-E<gt>value_to_i_floor($value)>

=item C<$i = $seq-E<gt>value_to_i_estimate($value)>

Return C<$value> rounded to the next higher or lower integer.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Even>,
L<Math::NumSeq::Odd>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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

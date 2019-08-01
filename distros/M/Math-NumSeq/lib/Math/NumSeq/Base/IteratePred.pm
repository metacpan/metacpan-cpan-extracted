# Copyright 2011, 2012, 2013, 2014, 2016 Kevin Ryde

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

package Math::NumSeq::Base::IteratePred;
use 5.004;
use strict;
use List::Util 'max';

use vars '$VERSION';
$VERSION = 73;

# uncomment this to run the ### lines
# use Smart::Comments;

use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;
use constant characteristic_smaller => 0;

sub rewind {
  my ($self) = @_;
  ### IteratePred rewind() ...

  $self->{'i'} = $self->i_start;
  my $value = $self->values_min;
  if (! defined $value) { die "Oops, no values_min() for predicate start"; }
  $self->{'value'} = $value;

  ### i: $self->{'i'}
  ### $value
}

sub next {
  my ($self) = @_;
  ### IteratePred next() at value: $self->{'value'}

  for (my $value = $self->{'value'}; ; $value++) {
    if ($self->pred($value)) {
      $self->{'value'} = $value+1;
      return ($self->{'i'}++, $value);
    }
  }
}

# Would have to scan all values to find correct i.
# sub seek_to_value {
#   my ($self, $value) = @_;
#   $value = int($value);
#   $self->{'value'} = max ($value, $self->values_min);
#   $self->{'i'} = ...
# }

# Slow to scan through all values.
# sub ith {
#   my ($self, $i) = @_;
#   $i -= $self->i_start;
#   my $value = $self->value_min - 1;
#   while ($i >= 0) {
#     $value++;
#     if ($self->pred($value)) {
#       $i--;
#     }
#   }
#   return $value;    
# }


1;
__END__

=for stopwords Ryde Math-NumSeq multi-inheritance

=head1 NAME

Math::NumSeq::Base::IteratePred -- iterate by searching with pred()

=for test_synopsis my @ISA

=head1 SYNOPSIS

 package MyNumSeqSubclass;
 use Math::NumSeq;
 use Math::NumSeq::Base::IteratePred;
 @ISA = ('Math::NumSeq::Base::IteratePred',
         'Math::NumSeq');
 sub ith {
   my ($self, $i) = @_;
   return something($i);
 }

=head1 DESCRIPTION

This is a multi-inheritance mix-in providing the following methods

    rewind()   # return to $self->i_start() and $self->values_min()
    next()     # search using $self->pred()

    characteristic_increasing()    # always true
    characteristic_integer()       # always true

C<next()> iterates by searching for values satisfying
C<$self-E<gt>pred($value)>, starting at C<values_min()> and stepping by 1
each time.

This is a handy way to implement the iterating methods for a C<NumSeq> if
there's no easy way to step or have random access to values, only a test of
a condition.

The current implementation is designed for infinite sequences, it doesn't
check for a C<values_max()> limit.

The two "characteristic" methods mean that calls

    $self->characteristic('increasing')
    $self->characteristic('integer')

are both true.  "Increasing" is since C<next()> always searches upwards.
"Integer" currently presumes that the starting C<values_min()> is an
integer.

=head1 SEE ALSO

L<Math::NumSeq>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2016 Kevin Ryde

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

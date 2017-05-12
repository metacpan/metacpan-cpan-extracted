# Copyright 2010, 2011 Kevin Ryde

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

package Math::NumSeq::PentagonalGeneralized;
use 5.004;
use strict;

use Math::NumSeq;
use base 'Math::NumSeq';

use vars '$VERSION';
$VERSION = 38;

# uncomment this to run the ### lines
#use Smart::Comments;

# use constant name => Math::NumSeq::__('Pentagonal Numbers, generalized');
use constant description => Math::NumSeq::__('The generalized pentagonal numbers 1, 2, 5, 7, 15, 22, 22, 26, etc, (3k-1)*k/2 for k positive and negative.  This is the plain pentagonal and second pentagonals taken together.');
use constant oeis_anum => 'A001318';

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  $self->{'neg'} = 1;
}
sub next {
  my ($self) = @_;
  my $i = $self->{'i'}++;
  # ENHANCE-ME: step by 2*i etc
  return ($i, $self->ith($i));

  # if ($self->{'neg'} ^= 1) {
  #   my $i = $self->{'i'};
  #   return ($i, (3*-$i+1)*-$i/2);
  # } else {
  #   my $i = $self->{'i'}++;
  #   return ($i, (3*$i+1)*$i/2);
  # }
}
sub ith {
  my ($self, $i) = @_;
  if ($i & 1) {
    $i = ($i - 1) / 2;
    return (3*-$i+1)*-$i/2
  } else {
    $i /= 2;
    return (3*$i+1)*$i/2;
  }
}
# sub pred {
#   my ($self, $n) = @_;
#   return ($n & 1);
# }

1;
__END__

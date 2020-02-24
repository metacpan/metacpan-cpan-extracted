# Copyright 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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

package Math::NumSeq::Derived::Cumulative;
use 5.004;
use strict;
use POSIX 'ceil';
use List::Util 'max';

use vars '$VERSION','@ISA';
$VERSION = 74;
use Math::NumSeq;
@ISA = ('Math::NumSeq');

# uncomment this to run the ### lines
#use Smart::Comments;

use constant description => Math::NumSeq::__('Cumulative ...');
sub values_min {
  my ($self) = @_;
  return $self->{'sequence'}->values_min;
}

sub rewind {
  my ($self) = @_;
  $self->{'sum'} = 0;
  $self->{'sequence'}->rewind;
}
sub next {
  my ($self) = @_;
  ### Cumulative next()...
  my ($i, $value) = $self->{'sequence'}->next();
  return ($i, $self->{'sum'} += $value);
}

1;
__END__

=for stopwords Ryde 

=head1 NAME

Math::NumSeq::Derived::Cumulative -- cumulative sum of a sequence

=head1 SYNOPSIS

 use Math::NumSeq::Derived::Cumulative;
 my $seq = Math::NumSeq::Derived::Cumulative->new
             (sequence = $parent_sequence);
 my ($i, $value) = $seq->next;

=head1 SEE ALSO

L<Math::NumSeq>

=head1 HOME PAGE

http://user42.tuxfamily.org/math-numseq/index.html

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

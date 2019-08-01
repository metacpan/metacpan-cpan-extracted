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

package Math::NumSeq::Base::IterateIth;
use 5.004;
use strict;

use vars '$VERSION';
$VERSION = 73;

sub rewind {
  my ($self) = @_;
  $self->seek_to_i($self->i_start);
}
sub seek_to_i {
  my ($self, $i) = @_;
  $self->{'i'} = $i;
}
sub next {
  my ($self) = @_;
  my $i = $self->{'i'}++;
  if (defined (my $value = $self->ith($i))) {
    return ($i, $value);
  } else {
    return;
  }
}

1;
__END__

=for stopwords Ryde Math-NumSeq multi-inheritance

=head1 NAME

Math::NumSeq::Base::IterateIth -- iterate by calling ith() successively

=for test_synopsis my @ISA

=head1 SYNOPSIS

 package MyNumSeqSubclass;
 use Math::NumSeq;
 use Math::NumSeq::Base::IterateIth;
 @ISA = ('Math::NumSeq::Base::IterateIth',
         'Math::NumSeq');
 sub ith {
   my ($self, $i) = @_;
   return something($i);
 }

=head1 DESCRIPTION

This is a multi-inheritance mix-in providing the following methods

    rewind()
    next()
    seek_to_i()

They iterate simply by calling C<ith()> to get each successive value,
starting from C<i_start()>.

This is a handy way to implement the iterating methods for a C<NumSeq> if
there's nothing special that C<next()> can do beyond a full C<ith()>
calculation.

If C<ith()> returns C<undef> then that's taken to be the end of the sequence
and C<next()> returns no values.

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

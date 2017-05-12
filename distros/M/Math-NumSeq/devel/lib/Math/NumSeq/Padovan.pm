# start at 1,1,1
# or oeis is 1,0,0 ?



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

package Math::NumSeq::Padovan;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 72;
use Math::NumSeq::Base::Sparse;
@ISA = ('Math::NumSeq::Base::Sparse');


use constant name => Math::NumSeq::__('Padovan Numbers');
use constant description => Math::NumSeq::__('Padovan numbers 1, 1, 1, 2, 2, 3, 4, 5, 7, 9, etc, being P(i) = P(i-2) + P(i-3) starting from 1,1,1.');
use constant characteristic_non_decreasing => 1;
use constant characteristic_increasing_from_i => 5;
use constant values_min => 1;

# cf A100891 - prime padovans
#    A112882 - index position of those prime padovans
#    A133034 - first differences of padovans
#    A078027 - expansion (1-x)/(1-x^2-x^3), starts 1,-1,0
#    A096231 - triangles generation starting 1,3,5
#    A145462,A146973 - eisentriangle row sums value at left is padovan
#    A134816 - starting 1,1,1 spiral sides
#    A000931 - starting 1,0,0
# use constant oeis_anum => 'A000931'; # padovan, but starting 1,0,0

# uncomment this to run the ### lines
#use Smart::Comments;

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  $self->{'f0'} = 1;
  $self->{'f1'} = 1;
  $self->{'f2'} = 1;
}
sub next {
  my ($self) = @_;
  ### Padovan next(): "$self->{'f0'} $self->{'f1'} $self->{'f2'}"
  (my $ret,
   $self->{'f0'},
   $self->{'f1'},
   $self->{'f2'})
   = ($self->{'f0'},
      $self->{'f1'},
      $self->{'f2'},
      $self->{'f0'}+$self->{'f1'});
  return ($self->{'i'}++, $ret);
}
# sub pred {
#   my ($self, $n) = @_;
#   return (($n >= 0)
#           && do {
#             $n = sqrt($n);
#             $n == int($n)
#           });
# }

1;
__END__



# clockwise version
#                     +-----------------------------------+
#                    / \                                 /
#                   /   \                               /
#                  /     \                             /
#                 /       \                           /
#                /         \                         /
#               /           \            9          /
#              /             \                     /
#             /       7       \                   /
#            /                 \                 /
#           /                   \               /
#          /                     \             /
#         /                       \           /
#        /                         \         /
#       +-------------------+-------+       /
#        \                 /1\  2  / \     /
#         \               +---+   /  2\   /
#          \             / \1/1\ /     \ /
#           \     5     /   +---+-------+
#            \         /     \         /
#             \       /       \   3   /
#              \     /    4    \     /
#               \   /           \   /
#                \ /             \ /
#                 +---------------+
#
#
#




=for stopwords Ryde Math-NumSeq

=head1 NAME

Math::NumSeq::Padovan -- Padovan sequence

=head1 SYNOPSIS

 use Math::NumSeq::Padovan;
 my $seq = Math::NumSeq::Padovan->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

I<In progress ...>

This is the Padovan sequence,

    1, 1, 1, 2, 2, 3, 4, 5, 7, 9, 12, 16, 21, 28, 37, 49, 65, ...

which is the recurrence

    P[i] = P[i-2] + P[i-3]

starting from 1,1,1.  So for example 28 is 12+16.

    12, 16, 21, 28

     |   |       ^
     |   |       |
     +---+---add-+

The recurrence is the same as the Perrin sequence (L<Math::NumSeq::Perrin>)
but with different staring values.

=head2 Triangles

There's an attractive geometric interpretation of these numbers.

    +-----------------------------------+
     \                                 / \
      \                               /   \
       \                             /     \
        \                           /       \
         \                         /         \
          \                       /           \
           \         9           /             \
            \                   /       7       \
             \                 /                 \
              \               /                   \
               \             /                     \
                \           /                       \
                 \         /                         \
                  \       +-------+-------------------+
                   \     / \  2  /1\                 /
                    \   / 2 \   +---+               /
                     \ /     \ /1\1/ \             /
                      +-------+---+   \     5     /
                       \         /     \         /
                        \   3   /       \       /
                         \     /    4    \     /
                          \   /           \   /
                           \ /             \ /
                            +---------------+

The pattern starts from an equilateral triangle of side length 1, the lower
left one shown above.  Then put a new triangle successively to the right,
left and lower sides, each time the side length of the triangle is the width
of the figure so far.

The effect is to add the immediately preceding triangle side and the side of
the 5th previous,

    P[i] = P[i-1] + P[i-5]

This is the same as the i-2,i-3 formula shown above since

    P[i] = P[i-2] + P[i-3]          # formula above
         = P[i-4]+P[i-5] + P[i-3]
         = P[i-3]+P[i-4] + P[i-5]
         = P[i-1] + P[i-5]          # geometric form

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::Padovan-E<gt>new ()>

=item C<$seq = Math::NumSeq::Padovan-E<gt>new (language =E<gt> $str)>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the number of letters in C<$i> written out in the selected language.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Perrin>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014 Kevin Ryde

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

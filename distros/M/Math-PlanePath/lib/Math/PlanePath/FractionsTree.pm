# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.


# PowerPart has mostly square-free for X/Y > 1/2, then wedge of mostly
# multiple of 4, then mostly multiple of 16, then wedge of higher powers
# of 2.  Similar in AYT.



package Math::PlanePath::FractionsTree;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 125;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'bit_split_lowtohigh',
  'digit_join_lowtohigh';
use Math::PlanePath::RationalsTree;

use Math::PlanePath::CoprimeColumns;
*_coprime = \&Math::PlanePath::CoprimeColumns::_coprime;

# uncomment this to run the ### lines
#use Smart::Comments;


use constant class_x_negative => 0;
use constant class_y_negative => 0;
use constant x_minimum => 1;
use constant y_minimum => 2;
use constant diffxy_maximum => -1; # upper octant X<=Y-1 so X-Y<=-1
use constant gcdxy_maximum => 1;  # no common factor
use constant tree_num_children_list => (2); # complete binary tree
use constant tree_n_to_subheight => undef; # complete tree, all infinity

use constant parameter_info_array =>
  [
   { name       => 'tree_type',
     share_key  => 'tree_type_fractionstree',
     display    => 'Tree Type',
     type       => 'enum',
     default    => 'Kepler',
     choices    => ['Kepler'],
   },
  ];

use constant dir_maximum_dxdy => (-2, -(sqrt(5)+1)); # phi


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'tree_type'} ||= 'Kepler';
  $self->{'n_start'} = 1; # for RationalsTree sharing
  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### FractionsTree n_to_xy(): "$n"

  if ($n < 1) { return; }
  if (is_infinite($n)) { return ($n,$n); }

  # what to do for fractional $n?
  {
    my $int = int($n);
    if ($n != $int) {
      ### frac ...
      my $frac = $n - $int;  # inherit possible BigFloat/BigRat
      my ($x1,$y1) = $self->n_to_xy($int);
      my ($x2,$y2) = $self->n_to_xy($int+1);
      my $dx = $x2-$x1;
      my $dy = $y2-$y1;
      ### x1,y1: "$x1, $y1"
      ### x2,y2: "$x2, $y2"
      ### dx,dy: "$dx, $dy"
      ### result: ($frac*$dx + $x1).', '.($frac*$dy + $y1)
      return ($frac*$dx + $x1, $frac*$dy + $y1);
    }
    $n = $int;
  }

  my $zero = ($n * 0);  # inherit bignum 0
  my $one = $zero + 1;  # inherit bignum 1

  # my $tree_type = $self->{'tree_type'};
  # if ($tree_type eq 'Kepler')

  {
    ### Kepler tree ...

    #       X/Y
    #     /     \
    # X/(X+Y)  Y/(X+Y)
    #
    # (1 0) (x) = ( x )     (a b) (1 0) = (a+b b)   digit 0
    # (1 1) (y)   (x+y)     (c d) (1 1)   (c+d d)
    #
    # (0 1) (x) = ( y )     (a b) (0 1) = (b a+b)   digit 1
    # (1 1) (y)   (x+y)     (c d) (1 1)   (d c+d)

    my @bits = bit_split_lowtohigh($n);
    pop @bits;  # drop high 1 bit

    my $a = $one;     # initial  (1 0)
    my $b = $zero;    #          (0 1)
    my $c = $zero;
    my $d = $one;
    while (@bits) {
      ### at: "($a $b)"
      ### at: "($c $d)"
      ### $digit

      if (shift @bits) {      # low to high
        ($a,$b) = ($b, $a+$b);
        ($c,$d) = ($d, $c+$d);
      } else {
        $a += $b;
        $c += $d;
      }
    }
    ### final: "($a $b)"
    ### final: "($c $d)"

    # (a b) (1) = (a+b)
    # (c d) (2)   (c+d)
    return ($a+2*$b, $c+2*$d);
  }
}

sub xy_is_visited {
  my ($self, $x, $y) = @_;
  $x = round_nearest ($x);
  $y = round_nearest ($y);
  if ($x < 1 || $y < 2 || $x >= $y || ! _coprime($x,$y)) {
    return 0;
  }
  return 1;
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  $x = round_nearest ($x);
  $y = round_nearest ($y);
  ### FractionsTree xy_to_n(): "$x,$y   $self->{'tree_type'}"

  if ($x < 1 || $y < 2 || $x >= $y) {
    return undef;
  }
  if (is_infinite($x)) { return $x; }
  if (is_infinite($y)) { return $y; }

  my $zero = $x * 0 * $y;   # inherit bignum 0

  #       X/Y
  #     /     \
  # X/(X+Y)  Y/(X+Y)
  #
  # (x,y) <- (x, y-x)  nbit 0
  # (x,y) <- (y-x, x)  nbit 1
  #
  my @nbits;   # low to high
  for (;;) {
    ### at: "$x,$y n=$n"

    if ($y <= 2) {
      if ($x == 1 && $y == 2) {
        push @nbits, 1;  # high bit
        return digit_join_lowtohigh(\@nbits, 2, $zero);
      } else {
        return undef;
      }
    }

    ($y -= $x)          # (X,Y) <- (X, Y-X)
      || return undef;  # common factor if had X==Y
    if ($x > $y) {
      ($x,$y) = ($y,$x);
      push @nbits, 1;
    } else {
      push @nbits, 0;
    }
  }
}


# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### rect_to_n_range()

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;
  ### $x2
  ### $y2


  #   |    /
  #   |   / x1
  #   |  /  +-----y2
  #   | /   |
  #   |/    +-----
  #
  if ($x2 < 1 || $y2 < 2 || $x1 >= $y2) {
    ### no values, rect outside upper octant ...
    return (1,0);
  }

  my $zero = ($x1 * 0 * $y1 * $x2 * $y2);  # inherit bignum
  ### $zero

  if ($x2 >= $y2) { $x2 = $y2-1; }
  if ($x1 < 1) { $x1 = 1; }
  if ($y1 < 2) { $y1 = 2; }

  # big x2, small y1
  # big y2, small x1
  # my $level = _bingcd_max ($y2,$x1);
  ### $level

  my $level = $y2;
  return (1, ($zero+2) ** $level);
}

sub _bingcd_max {
  my ($x,$y) = @_;
  ### _bingcd_max(): "$x,$y"

  if ($x < $y) { ($x,$y) = ($y,$x) }

  ### div: int($x/$y)
  ### bingcd: int($x/$y) + $y

  return int($x/$y) + $y + 1;
}

#------------------------------------------------------------------------------
use constant tree_num_roots => 1;

# Same structure as RationalsTree
*tree_n_children     = \&Math::PlanePath::RationalsTree::tree_n_children;
*tree_n_num_children = \&Math::PlanePath::RationalsTree::tree_n_num_children;
*tree_n_parent       = \&Math::PlanePath::RationalsTree::tree_n_parent;
*tree_n_to_depth     = \&Math::PlanePath::RationalsTree::tree_n_to_depth;
*tree_depth_to_n     = \&Math::PlanePath::RationalsTree::tree_depth_to_n;
*tree_depth_to_n_end = \&Math::PlanePath::RationalsTree::tree_depth_to_n_end;
*tree_depth_to_n_range=\&Math::PlanePath::RationalsTree::tree_depth_to_n_range;
*tree_depth_to_width = \&Math::PlanePath::RationalsTree::tree_depth_to_width;


1;
__END__

=for stopwords eg Ryde OEIS ie Math-PlanePath coprime Harmonices Mundi octant onwards Aiton

=head1 NAME

Math::PlanePath::FractionsTree -- fractions by tree

=head1 SYNOPSIS

 use Math::PlanePath::FractionsTree;
 my $path = Math::PlanePath::FractionsTree->new (tree_type => 'Kepler');
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path enumerates fractions X/Y in the range 0 E<lt> X/Y E<lt> 1 and in
reduced form, ie. X and Y having no common factor, using a method by
Johannes Kepler.

Fractions are traversed by rows of a binary tree which effectively
represents a coprime pair X,Y by subtraction steps of a subtraction-only
form of Euclid's greatest common divisor algorithm which would prove X,Y
coprime.  The steps left or right are encoded/decoded as an N value.

=head2 Kepler Tree

X<Kepler, Johannes>The default and only tree currently is by Kepler.

=over

Johannes Kepler, "Harmonices Mundi", Book III.  Excerpt of translation by
Aiton, Duncan and Field at
L<http://ndirty.cute.fi/~karttu/Kepler/a086592.htm>

=back

In principle similar bit reversal etc variations as in C<RationalsTree>
would be possible.

    N=1                             1/2
                              ------   ------
    N=2 to N=3             1/3               2/3
                          /    \            /   \
    N=4 to N=7         1/4      3/4      2/5      3/5
                       | |      | |      | |      | |
    N=8 to N=15     1/5  4/5  3/7 4/7  2/7 5/7  3/8 5/8

A node descends as

          X/Y
        /     \
    X/(X+Y)  Y/(X+Y)

Kepler described the tree as starting at 1, ie. 1/1, which descends to two
identical 1/2 and 1/2.  For the code here a single copy starting from 1/2 is
used.

Plotting the N values by X,Y is as follows.  Since it's only fractions
X/YE<lt>1, ie. XE<lt>Y, all points are above the X=Y diagonal.  The unused
X,Y positions are where X and Y have a common factor.  For example X=2,Y=6
have common factor 2 so is never reached.

    12  |    1024                  26        27                1025
    11  |     512   48   28   22   34   35   23   29   49  513     
    10  |     256        20                  21       257          
     9  |     128   24        18   19        25  129               
     8  |      64        14        15        65                    
     7  |      32   12   10   11   13   33                         
     6  |      16                  17                              
     5  |       8    6    7    9                                   
     4  |       4         5                                        
     3  |       2    3                                             
     2  |       1                                                  
     1  |
    Y=0 |   
         ----------------------------------------------------------
          X=0   1    2    3    4    5    6    7    8    9   10   11

The X=1 vertical is the fractions 1/Y at the left end of each tree row,
which is

    Nstart=2^level

The diagonal X=Y-1, fraction K/(K+1), is the second in each row, at
N=Nstart+1.  That's the maximum X/Y in each level.

The N values in the upper octant, ie. above the line Y=2*X, are even and
those below that line are odd.  This arises since XE<lt>Y so the left leg
X/(X+Y) E<lt> 1/2 and the right leg Y/(X+Y) E<gt> 1/2.  The left is an even
N and the right an odd N.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over

=item C<$path = Math::PlanePath::FractionsTree-E<gt>new ()>

Create and return a new path object.

=item C<$n = $path-E<gt>n_start()>

Return 1, the first N in the path.

=item C<($n_lo, $n_hi) = $path-E<gt>rect_to_n_range ($x1,$y1, $x2,$y2)>

Return a range of N values which occur in a rectangle with corners at
C<$x1>,C<$y1> and C<$x2>,C<$y2>.  The range is inclusive.

For reference, C<$n_hi> can be quite large because within each row there's
only one new 1/Y fraction.  So if X=1 is included then roughly C<$n_hi =
2**max(x,y)>.

=back

=head2 Tree Methods

X<Complete binary tree>Each point has 2 children, so the path is a complete
binary tree.

=over

=item C<@n_children = $path-E<gt>tree_n_children($n)>

Return the two children of C<$n>, or an empty list if C<$n E<lt> 1>
(before the start of the path).

This is simply C<2*$n, 2*$n+1>.  The children are C<$n> with an extra bit
appended, either a 0-bit or a 1-bit.

=item C<$num = $path-E<gt>tree_n_num_children($n)>

Return 2, since every node has two children, or return C<undef> if
C<$nE<lt>1> (before the start of the path).

=item C<$n_parent = $path-E<gt>tree_n_parent($n)>

Return the parent node of C<$n>, or C<undef> if C<$n E<lt>= 1> (the top of
the tree).

This is simply C<floor($n/2)>, stripping the least significant bit from
C<$n> (undoing what C<tree_n_children()> appends).

=item C<$depth = $path-E<gt>tree_n_to_depth($n)>

Return the depth of node C<$n>, or C<undef> if there's no point C<$n>.  The
top of the tree at N=1 is depth=0, then its children depth=1, etc.

The structure of the tree with 2 nodes per point means the depth is simply
floor(log2(N)), so for example N=4 through N=7 are all depth=2.

=back

=head2 Tree Descriptive Methods

=over

=item C<$num = $path-E<gt>tree_num_children_minimum()>

=item C<$num = $path-E<gt>tree_num_children_maximum()>

Return 2 since every node has 2 children, making that both the minimum and
maximum.

=item C<$bool = $path-E<gt>tree_any_leaf()>

Return false, since there are no leaf nodes in the tree.

=back

=head1 OEIS

The trees are in Sloane's Online Encyclopedia of Integer Sequences in the
following forms

=over

L<http://oeis.org/A020651> (etc)

=back

    tree_type=Kepler
      A020651  - X numerator (RationalsTree AYT denominators)
      A086592  - Y denominators
      A086593  - X+Y sum, and every second denominator
      A020650  - Y-X difference (RationalsTree AYT numerators)

The tree descends as X/(X+Y) and Y/(X+Y) so the denominators are two copies
of X+Y time after the initial 1/2.  A086593 is every second, starting at 2,
eliminating the duplication.  This is also the sum X+Y, from value 3
onwards, as can be seen by thinking of writing a node as the X+Y which would
be the denominators it descends to.

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::RationalsTree>,
L<Math::PlanePath::CoprimeColumns>,
L<Math::PlanePath::PythagoreanTree>

L<Math::NumSeq::SternDiatomic>,
L<Math::ContinuedFraction>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

This file is part of Math-PlanePath.

Math-PlanePath is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Math-PlanePath is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.

=cut

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



# cf A005894 centered tetrahedral numbers. (2*n+1)*(n^2+n+3)/3
#    A005906 truncated tetrahedral numbers. (n+1)*(23*n^2+19*n+6)/6
#    A015219 odd tetrahedrals (4n+1)(4n+2)(4n+3)/6
#    A015220 even tetrahedrals


package Math::NumSeq::Tetrahedral;
use 5.004;
use strict;

use vars '$VERSION','@ISA';
$VERSION = 75;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');

use Math::NumSeq::Cubes;
*_cbrt_floor = \&Math::NumSeq::Cubes::_cbrt_floor;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Tetrahedral Numbers');
use constant description => Math::NumSeq::__('The tetrahedral numbers 0, 1, 4, 10, 20, 35, 56, 84, 120, etc, i*(i+1)*(i+2)/6.');
use constant default_i_start => 0;
use constant values_min => 0;
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;
use constant oeis_anum => 'A000292'; # tetrahedrals

# could next() by increment
# 0
# 1    +1
# 4    +3  +2
# 10   +6  +3
# 20  +10  +4
# 35  +15  +5
# 56  +21  +6
# 84  +28  +7
# 120 +36  +8
#
# T(i) = i*(i+1)*(i+2)/6
#      = i*(i^2 + 3i + 2)/6
#      = (i^3 + 3i^2 + 2i)/6

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
}
sub _UNTESTED__seek_to_value {
  my ($self, $value) = @_;
  $self->seek_to_i($self->value_to_i_ceil($value));
}

sub ith {
  my ($self, $i) = @_;
  return $i*($i+1)*($i+2)/6;
}

sub pred {
  my ($self, $value) = @_;
  ### Tetrahedral pred(): $value

  $value *= 6;
  my $i = _cbrt_floor($value);
  return ($i*($i+1)*($i+2) == $value);
}

# Cubic root formula
# 6*T(i) = i^3 + 3i^2 + 2i
# i^3 + 3i^2 + 2i - value = 0
# subst j=i+1, i=j-1
# (j-1)^3 + 3(j-1)^2 + 2(j-1) - value = 0
# j^3-3j^2+3j-1 + 3j^2-6j+3 + 2j-2 - value = 0
# j^3 + (-3+3)^2 + (3-6+2)j + (-1+3+-2) - value = 0
# j^3 - j - value = 0   p=-1 q=-v
#
# x^3+px+q=0
#  x=a-b
# a^3 - 3*b*a^2 + 3*b^2*a - b^3 + p(a-b) + q = 0
# a^3 - b^3 + 3ab(-a+b) + p(a-b) + q = 0
# a^3 - b^3 + (-3ab+p)(a-b) + q = 0
#  and 3ab=p so -3ab+p=0
# a^3 - b^3 + q = 0
#  mul (3a)^3
# 27a^6 - (3ab)^3 + 27q*a^3 = 0
# 27a^6 - p^3 + 27q*a^3 = 0
# 27a^6 + 27q*a^3 - p^3 = 0
# 27(a^3)^2 + 27q*(a^3) - p^3 = 0    quadratic in a^3
# a^3 = (-27q + sqrt((27q)^2 + 4*27*p^3)) / 2*27
#     = (-q + sqrt(q^2 + 4*p^3/27)) / 2
# 3ab=p b=p/3a
# b^3 = (-27q + sqrt((27q)^2 - 4*27*p^3)) / 2*27
#
# v=56=6*7*8/6
# p=-1 q=-v
# a^3 = (v + sqrt(v^2 - 4/27)) / 2
#     = (56 + sqrt(56^2 - 4/27))/2
# a = 3.825847303806096100878703127
# b = -1/3a
# 
# j^3 - j - 6*value = 0
# a^3 - 3*b*a^2 + 3*b^2*a - b^3 + -(a-b) - 6v = 0
# a^3 - b^3 + 3ab(-a + b) + -(a-b) - 6v = 0
# a^3 - b^3 - 3ab(a-b) + -(a-b) - 6v = 0
# a^3 - b^3 + (-1-3ab)*(a-b) - 6v = 0
# -1-3ab=0 3ab=-1
# a^3 - b^3 - 6v = 0
# 27a^6 - (3ab)^3 - 27*6v*a^3 = 0
# 27a^6 - (-1)^3 - 27*6v*a^3 = 0
# 27(a^3)^2 - 27*6v*(a^3) - (-1)^3 = 0
# 27(a^3)^2 - 27*6v*(a^3) + 1 = 0
# (a^3)^2 - 6v*(a^3) + 1/27 = 0
# a^3 = (6v + sqrt((6v)^2 - 4/27))/2
#     = (6*56+sqrt((6*56)^2 - 4/27))/2
# 3ab=-1
# b=-1/3a
#
# 
# 6*T(i)   = i^3 + 3i^2 + 2i
# estimate i=cbrt(6*value)
# (i+1)^3 = i^3 + 3i^2 + 3i + 1 is bigger than T(i)
#
# v just below a cube so
# v=x^3-1
# then cbrt gives x
# T(x+1) = (x+1)^3 + 3*(x+1)^2 + 2*(x+1)
#        = x^3 + 6*x^2 + 11*x + 6


# 6*value = i*(i+1)*(i+2)
#         = i^3 + 3*i^2 + 2*i
# so i^3 < 6T(i) < (i+1)^3
#
sub value_to_i_estimate {
  my ($self, $value) = @_;
  return _cbrt_floor(6*$value);
}
sub value_to_i_floor {
  my ($self, $value) = @_;
  ### value_to_i_floor(): "$value"

  $value *= 6;
  if ($value >= 0) {
    my $i = _cbrt_floor($value);
    if ($i*($i+1)*($i+2) <= $value) {
      return $i;
    } else {
      return $i-1;
    }
  } else {
    # secret undocumented negatives ...

    $value = abs($value);
    my $i = _cbrt_floor($value);

    ### $i
    ### prod: $i*($i+1)*($i+2)
    ### value*6: "$value"

    if ($i*($i+1)*($i+2) >= $value) {
      return -2-$i;
    } else {
      return -3-$i;
    }
  }
}

1;
__END__

=for stopwords Ryde Math-NumSeq tetrahedrals

=head1 NAME

Math::NumSeq::Tetrahedral -- tetrahedral numbers i*(i+1)*(i+2)/6

=head1 SYNOPSIS

 use Math::NumSeq::Tetrahedral;
 my $seq = Math::NumSeq::Tetrahedral->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The tetrahedral numbers, i*(i+1)*(i+2)/6.

    0, 1, 4, 10, 20, 35, 56, 84, 120, ...

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::Tetrahedral-E<gt>new ()>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return C<$i*($i+1)*($i+2)/6>.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> has the form i*(i+1)*(i+2)/6 for some positive
integer i.

=item C<$i = $seq-E<gt>value_to_i_floor($value)>

Return the index i of C<$value> or of the next tetrahedral number below
C<$value>.

=item C<$i = $seq-E<gt>value_to_i_estimate($value)>

Return an estimate of the i corresponding to C<$value>.

In the current code this C<$i> gives the tetrahedral above or below
C<$value>, so is out by no more than 1.

=back

=head1 FORMULAS

=head2 Value to i Estimate

i*(i+1)*(i+2) always fall in between cubes,  so

    T(i) = i*(i+1)*(i+2)/6
         = (i^3 + 3*i^2 + 2*i)/6

    i^3 < 6*T(i) < (i+1)^3

For C<value_to_i_estimate()> it's enough to apply a cube root,

    i_estimate = floor(cbrt(6*value))

=head2 Value to i Floor

For C<value_to_i_floor()> the cube root can be 1 too big when the given
value is in between successive T() tetrahedrals.  For example if value=57
floor(cbrt(6*57))=6 is correct, but value=58 floor(cbrt(6*58))=7 is 1 too
big.

    i = floor(cbrt(6*value))
    if i*(i+1)*(i+2) <= 6*value
    then i_floor = i
    else i_floor = i-1    # cbrt was 1 too big

=head1 SEE ALSO

L<Math::NumSeq>,
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

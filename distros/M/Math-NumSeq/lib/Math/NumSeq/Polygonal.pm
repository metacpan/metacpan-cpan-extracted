# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2018, 2019, 2020, 2021 Kevin Ryde

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

package Math::NumSeq::Polygonal;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 75;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');

# uncomment this to run the ### lines
#use Smart::Comments;

# use constant name => Math::NumSeq::__('Polygonal Numbers');
use constant i_start => 0;
use constant values_min => 0;
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;
use constant parameter_info_array =>
  [
   { name    => 'polygonal',
     display => Math::NumSeq::__('Polygonal'),
     type    => 'integer',
     default => 5,
     minimum => 3,
     width   => 3,
     description => Math::NumSeq::__('Which polygonal numbers to show.  3 is the triangular numbers, 4 the perfect squares, 5 the pentagonal numbers, etc.'),
   },
   { name    => 'pairs',
     display => Math::NumSeq::__('Pairs'),
     type    => 'enum',
     default => 'first',
     choices => ['first',
                 'second',
                 'both',
                 'average'],
     choices_display => [Math::NumSeq::__('First'),
                         Math::NumSeq::__('Second'),
                         Math::NumSeq::__('Both'),
                         Math::NumSeq::__('Average')],
     description => Math::NumSeq::__('Which of the pair of values to show.'),
   },
  ];

sub description {
  my ($self) = @_;
  if (ref $self) {
    return "$self->{'polygonal'}-gonal numbers"
      . ($self->{'pairs'} eq 'second' ? " of the second kind"
         : $self->{'pairs'} eq 'both' ? " of both first and second kind"
         : $self->{'pairs'} eq 'average' ? ", average of first and second kind"
         : '');
  } else {
    # class method
    return Math::NumSeq::__('Polygonal numbers');
  }
}


#------------------------------------------------------------------------------
# cf A183221 complement of 9-gonals
#    A008795 molien from naive interleaved unsorted "average" polygonal=3
#    A144065 generalized pentagonals - 1,
#              being 2*3*4*(n+1)+1 is a perfect square

my %oeis_anum;

$oeis_anum{'first'}->[3]   = 'A000217';  # 3 triangular
$oeis_anum{'second'}->[3]  = 'A000217';  # triangular same as "first"
$oeis_anum{'both'}->[3]    = 'A000217';  # no duplicates
$oeis_anum{'average'}->[3] = 'A000217';  # first==second so average same
# OEIS-Other: A000217 polygonal=3
# OEIS-Other: A000217 polygonal=3 pairs=second
# OEIS-Other: A000217 polygonal=3 pairs=both
# OEIS-Other: A000217 polygonal=3 pairs=average

$oeis_anum{'first'}->[4]   = 'A000290'; # 4 squares
$oeis_anum{'second'}->[4]  = 'A000290'; # squares, same as "first"
$oeis_anum{'both'}->[4]    = 'A000290'; # no duplicates
$oeis_anum{'average'}->[4] = 'A000290'; # squares, same as "first"
# OEIS-Other: A000290 polygonal=4
# OEIS-Other: A000290 polygonal=4 pairs=second
# OEIS-Other: A000290 polygonal=4 pairs=both
# OEIS-Other: A000290 polygonal=4 pairs=average

$oeis_anum{'first'}->[5]  = 'A000326';   # 5 pentagonal
$oeis_anum{'second'}->[5] = 'A005449';
$oeis_anum{'both'}->[5]   = 'A001318';
# OEIS-Catalogue: A000326 polygonal=5  pairs=first
# OEIS-Catalogue: A005449 polygonal=5  pairs=second
# OEIS-Catalogue: A001318 polygonal=5  pairs=both

$oeis_anum{'first'}->[6]   = 'A000384';  # 6 hexagonal
$oeis_anum{'second'}->[6]  = 'A014105';
$oeis_anum{'both'}->[6]    = 'A000217';  # together triangular numbers
$oeis_anum{'average'}->[6] = 'A001105';  # (k-2)/2==2 is 2*n^2
# OEIS-Catalogue: A000384 polygonal=6  pairs=first
# OEIS-Catalogue: A014105 polygonal=6  pairs=second
# OEIS-Other:     A000217 polygonal=6  pairs=both
# OEIS-Catalogue: A001105 polygonal=6  pairs=average

$oeis_anum{'first'}->[7]  = 'A000566'; # 7 heptagonal n(5n-3)/2
$oeis_anum{'both'}->[7]   = 'A085787';
# OEIS-Catalogue: A000566 polygonal=7
# OEIS-Catalogue: A085787 polygonal=7 pairs=both
#
# Not quite, (5n-2)(n-1)/2 starting n=1 is the same values, whereas
# Polygonal seconds starting n=0 would be (-n)(5*-n-3)/2=n(5n+3)
# # $oeis_anum{'second'}->[7] = 'A147875'; # (5n-2)(n-1)/2
# # # OEIS-Catalogue: A147875 polygonal=7 pairs=second

$oeis_anum{'first'}->[8]   = 'A000567'; # 8 octagonal
$oeis_anum{'second'}->[8]  = 'A045944'; # Rhombic matchstick n*(3*n+2)
$oeis_anum{'average'}->[8] = 'A033428'; # (k-2)/2==3 is 3*squares
# OEIS-Catalogue: A000567 polygonal=8
# OEIS-Catalogue: A045944 polygonal=8 pairs=second
# OEIS-Catalogue: A033428 polygonal=8 pairs=average
#
# A001082 n(3n-4)/4 if n even, (n-1)(3n+1)/4 if n odd
# is not quite generalized octagonals
# Generalized would be n*(3n-2) for n=0,1,-1,2,-2,etc
# # $oeis_anum{'both'}->[8]   = 'A001082';
# # # OEIS-Catalogue: A001082 polygonal=8 pairs=both

$oeis_anum{'first'}->[9]  = 'A001106'; # 9 nonagonal
$oeis_anum{'second'}->[9] = 'A179986'; # 9 nonagonal second n*(7*n+5)/2
$oeis_anum{'both'}->[9]   = 'A118277'; # 9 nonagonal "generalized"
# OEIS-Catalogue: A001106 polygonal=9
# OEIS-Catalogue: A179986 polygonal=9 pairs=second
# OEIS-Catalogue: A118277 polygonal=9 pairs=both

$oeis_anum{'first'}->[10]   = 'A001107'; # 10 decogaonal
$oeis_anum{'second'}->[10]  = 'A033954'; # 10 second n*(4*n+3)
$oeis_anum{'both'}->[10]    = 'A074377'; # 10 both "generalized"
$oeis_anum{'average'}->[10] = 'A016742'; # (k-2)/2==4 is 4*squares
# OEIS-Catalogue: A001107 polygonal=10
# OEIS-Catalogue: A033954 polygonal=10 pairs=second
# OEIS-Catalogue: A074377 polygonal=10 pairs=both
# OEIS-Catalogue: A016742 polygonal=10 pairs=average

$oeis_anum{'first'}->[11]  = 'A051682'; # 11 hendecagonal
$oeis_anum{'second'}->[11] = 'A062728'; # 11 second n*(9n+7)/2
$oeis_anum{'both'}->[11]   = 'A195160'; # 11 generalized
# OEIS-Catalogue: A051682 polygonal=11
# OEIS-Catalogue: A062728 polygonal=11 pairs=second
# OEIS-Catalogue: A195160 polygonal=11 pairs=both

$oeis_anum{'first'}->[12]   = 'A051624'; # 12-gonal
$oeis_anum{'second'}->[12]  = 'A135705'; # 12-gonal second
$oeis_anum{'both'}->[12]    = 'A195162'; # 12-gonal generalized
$oeis_anum{'average'}->[12] = 'A033429'; # (k-2)/2==5 is 5*squares
# OEIS-Catalogue: A051624 polygonal=12
# OEIS-Catalogue: A135705 polygonal=12 pairs=second
# OEIS-Catalogue: A195162 polygonal=12 pairs=both
# OEIS-Catalogue: A033429 polygonal=12 pairs=average

$oeis_anum{'second'}->[13] = 'A211013'; # 13-gonal second
$oeis_anum{'both'}->[13]   = 'A195313'; # 13-gonal generalized
# OEIS-Catalogue: A211013 polygonal=13 pairs=second
# OEIS-Catalogue: A195313 polygonal=13 pairs=both

$oeis_anum{'second'}->[14]  = 'A211014'; # 14-gonal second
$oeis_anum{'both'}->[14]    = 'A195818'; # 14-gonal generalized
$oeis_anum{'average'}->[14] = 'A033581'; # (k-2)/2==6 is 6*squares
# OEIS-Catalogue: A211014 polygonal=14 pairs=second
# OEIS-Catalogue: A195818 polygonal=14 pairs=both
# OEIS-Catalogue: A033581 polygonal=14 pairs=average

$oeis_anum{'both'}->[15]   = 'A277082'; # 15-gonal generalized
# OEIS-Catalogue: A277082 polygonal=15 pairs=both

$oeis_anum{'both'}->[16]    = 'A274978'; # 16-gonal generalized
$oeis_anum{'average'}->[16] = 'A033582'; # (k-2)/2==7 is 7*squares
# OEIS-Catalogue: A033582 polygonal=16 pairs=average

# these in sequence ...
$oeis_anum{'first'}->[13]  =  'A051865'; # 13 tridecagonal
$oeis_anum{'first'}->[14]  =  'A051866'; # 14-gonal
$oeis_anum{'first'}->[15]  =  'A051867'; # 15
$oeis_anum{'first'}->[16]  =  'A051868'; # 16
$oeis_anum{'first'}->[17]  =  'A051869'; # 17
$oeis_anum{'first'}->[18]  =  'A051870'; # 18
$oeis_anum{'first'}->[19]  =  'A051871'; # 19
$oeis_anum{'first'}->[20]  =  'A051872'; # 20
$oeis_anum{'first'}->[21]  =  'A051873'; # 21
$oeis_anum{'first'}->[22]  =  'A051874'; # 22
$oeis_anum{'first'}->[23]  =  'A051875'; # 23
$oeis_anum{'first'}->[24]  =  'A051876'; # 24
# OEIS-Catalogue: A051865 polygonal=13
# OEIS-Catalogue: A051866 polygonal=14
# OEIS-Catalogue: A051867 polygonal=15
# OEIS-Catalogue: A051868 polygonal=16
# OEIS-Catalogue: A051869 polygonal=17
# OEIS-Catalogue: A051870 polygonal=18
# OEIS-Catalogue: A051871 polygonal=19
# OEIS-Catalogue: A051872 polygonal=20
# OEIS-Catalogue: A051873 polygonal=21
# OEIS-Catalogue: A051874 polygonal=22
# OEIS-Catalogue: A051875 polygonal=23
# OEIS-Catalogue: A051876 polygonal=24

$oeis_anum{'first'}->[25]  =  'A255184'; # 25
$oeis_anum{'first'}->[26]  =  'A255185'; # 26
$oeis_anum{'first'}->[27]  =  'A255186'; # 27
$oeis_anum{'first'}->[29]  =  'A255187'; # 29
# OEIS-Catalogue: A255184 polygonal=25
# OEIS-Catalogue: A255185 polygonal=26
# OEIS-Catalogue: A255186 polygonal=27
# OEIS-Catalogue: A255187 polygonal=29

# A161935 (n+1)*(13*n+1) is 28-gonals but OFFSET=1

$oeis_anum{'first'}->[30]   = 'A254474';
$oeis_anum{'second'}->[30]  = 'A195028';
$oeis_anum{'average'}->[30] = 'A144555'; # (k-2)/2==14 is 14*squares
# OEIS-Catalogue: A254474 polygonal=30
# OEIS-Catalogue: A195028 polygonal=30 pairs=second
# OEIS-Catalogue: A144555 polygonal=30 pairs=average

$oeis_anum{'second'}->[18] = 'A139278';
$oeis_anum{'average'}->[18] = 'A139098'; # (k-2)/2==8 is 8*squares
# OEIS-Catalogue: A139278 polygonal=18 pairs=second
# OEIS-Catalogue: A139098 polygonal=18 pairs=average

$oeis_anum{'average'}->[20] = 'A016766'; # (k-2)/2==9 is 9*squares
# OEIS-Catalogue: A016766 polygonal=20 pairs=average

$oeis_anum{'average'}->[22] = 'A033583'; # (k-2)/2==10 is 10*squares
# OEIS-Catalogue: A033583 polygonal=22 pairs=average

$oeis_anum{'average'}->[24] = 'A033584'; # (k-2)/2==11 is 11*squares
# OEIS-Catalogue: A033584 polygonal=24 pairs=average

$oeis_anum{'average'}->[26] = 'A135453'; # (k-2)/2==12 is 12*squares
# OEIS-Catalogue: A135453 polygonal=26 pairs=average

$oeis_anum{'average'}->[28] = 'A152742'; # (k-2)/2==13 is 13*squares
# OEIS-Catalogue: A152742 polygonal=28 pairs=average

$oeis_anum{'average'}->[32] = 'A064761'; # (k-2)/2==15 is 15*squares
# OEIS-Catalogue: A064761 polygonal=32 pairs=average

$oeis_anum{'first'}->[33]  =  'A098923'; # 33
# OEIS-Catalogue: A098923 polygonal=33

$oeis_anum{'first'}->[34]  =  'A282854'; # 34
$oeis_anum{'average'}->[34] = 'A016802'; # (k-2)/2==16 is 16*squares
# OEIS-Catalogue: A282854 polygonal=34
# OEIS-Catalogue: A016802 polygonal=34 pairs=average

$oeis_anum{'first'}->[35]  =  'A282851'; # 35
# OEIS-Catalogue: A282851 polygonal=35

$oeis_anum{'first'}->[36]  =  'A282853'; # 36
$oeis_anum{'first'}->[37]  =  'A282852'; # 37
$oeis_anum{'first'}->[38]  =  'A282850'; # 38
$oeis_anum{'first'}->[40]  =  'A261191'; # 40
# OEIS-Catalogue: A282853 polygonal=36
# OEIS-Catalogue: A282852 polygonal=37
# OEIS-Catalogue: A282850 polygonal=38
# OEIS-Catalogue: A261191 polygonal=40

# ENHANCE-ME: let i_start=1 get the right oeis_anum()
# $oeis_anum{'first'}->[45]  =  'A098924'; # 45
# NOT Catalogue: A098924 polygonal=45 i_start=1
# $oeis_anum{'first'}->[47]  =  'A095311'; # 47
# NOT Catalogue: A095311 polygonal=47 i_start=1

$oeis_anum{'first'}->[50]  =  'A261343'; # 50
# OEIS-Catalogue: A261343 polygonal=50

$oeis_anum{'first'}->[60]  =  'A249911'; # 60
$oeis_anum{'first'}->[63]  =  'A098140'; # 63
# OEIS-Catalogue: A249911 polygonal=60
# OEIS-Catalogue: A098140 polygonal=63

$oeis_anum{'first'}->[75]  =  'A098230'; # 75
# OEIS-Catalogue: A098230 polygonal=75

$oeis_anum{'first'}->[100]  =  'A261276'; # 100
# OEIS-Catalogue: A261276 polygonal=100

$oeis_anum{'average'}->[290] = 'A017522'; # (k-2)/2==290 is 144*squares (12n)^2
# OEIS-Catalogue: A017522 polygonal=290 pairs=average


sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum{$self->{'pairs'}}->[$self->{'k'}];
}

#------------------------------------------------------------------------------

# ($k-2)*$i*($i+1)/2 - ($k-3)*$i
# = ($k-2)/2*$i*i + ($k-2)/2*$i - ($k-3)*$i
# = ($k-2)/2*$i*i + ($k - 2 - 2*$k + 6)/2*$i
# = ($k-2)/2*$i*i + (-$k + 4)/2*$i
# = 0.5 * (($k-2)*$i*i + (-$k +4)*$i)
# = 0.5 * $i * (($k-2)*$i - $k + 4)

# 25*i*(i+1)/2 - 24i
# 25*i*(i+1)/2 - 48i/2
# i/2*(25*(i+1) - 48)
# i/2*(25*i + 25 - 48)
# i/2*(25*i - 23)
#
# P(i) = (k-2)/2 * i*(i+1) - (k-3)*i
# S(i) = (k-2)/2 * i*(i-1) + (k-3)*i
# P(i)-S(i)
#     = (k-2)/2 * i*(i+1) - (k-3)*i  - [ (k-2)/2 * i*(i-1) + (k-3)*i ]
#     = (k-2)/2 * [ i*(i+1) - i*(i-1) ]  - (k-3)*i  - (k-3)*i
#     = (k-2)/2 * [ i*i+i - (i*i-i) ]  - 2*(k-3)*i
#     = (k-2)/2 * [ i*i+i - i*i + i ]  - 2*(k-3)*i
#     = (k-2)/2 * [ i + i ]  - 2*(k-3)*i
#     = (k-2)/2 * 2*i]  - 2*(k-3)*i
#     = 2*i * [ (k-2)/2 - (k-3) ]
#     = 2*i * [ (k-2) - (2k-6) ] / 2
#     = i * [ -k + 4 ] / 2
#     = i * (4-k) / 2
#
# average
# (P(i) + S(i)) / 2
#     = [ (k-2)/2 * i*(i+1) - (k-3)*i + (k-2)/2 * i*(i-1) + (k-3)*i ] / 2
#     = [ (k-2)/2 * i*(i+1) + (k-2)/2 * i*(i-1) ] / 2
#     = (k-2)/2 * [ i*(i+1) + i*(i-1) ] / 2
#     = (k-2)/2 * i * [ (i+1) + (i-1) ] / 2
#     = (k-2)/2 * i * [ 2i ] / 2
#     = (k-2)/2 * i*i

sub rewind {
  my ($self) = @_;

  my $k = $self->{'polygonal'} || 2;
  my $add = 4 - $k;
  my $pairs = $self->{'pairs'} || ($self->{'pairs'} = 'first');
  if ($k >= 5) {
    if ($pairs eq 'second') {
      $add = - $add;
    } elsif ($pairs eq 'both') {
      $add = - abs($add);
    } elsif ($pairs eq 'average') {
      $add = 0;
    }
  }
  $self->{'k'} = $k;
  $self->{'add'} = $add;

  $self->SUPER::rewind;
}

sub ith {
  my ($self, $i) = @_;
  my $k = $self->{'k'};
  if ($k < 3) {
    if ($i == 0) {
      return 1;
    } else {
      return undef;
    }
  }
  my $pairs = $self->{'pairs'};
  if ($k >= 5 && $pairs eq 'both') {
    if ($i & 1) {
      $i = ($i+1)/2;
    } else {
      $i = -$i/2;
    }
  }
  ### $i
  return $i * (($k-2)*$i + $self->{'add'}) / 2;
}

# k=3  -1/2 + sqrt(2/1 * $n + 1/4)
# k=4         sqrt(2/2 * $n      )
# k=5   1/6 + sqrt(2/3 * $n + 1/36)
# k=6   2/8 + sqrt(2/4 * $n + 4/64)
# k=7  3/10 + sqrt(2/5 * $n + 9/100)
# k=8  4/12 + sqrt(2/6 * $n + 1/9)
#
# i = 1/(2*(k-2)) * [k-4 + sqrt( 8*(k-2)*n + (4-k)^2 ) ]
#
# average A(i) = (k-2)/2 * i*i
#   i*i = A*2/(k-2)
#   i = sqrt(2A / (k-2))
#   i = sqrt(2A * (k-2)) / (k-2)
#   i = sqrt(8A * (k-2)) / (2*(k-2))
#   which is add==0
#
sub pred {
  my ($self, $value) = @_;
  ### Polygonal pred(): $value
  ### k: $self->{'k'}
  ### add: $self->{'add'}

  if ($value <= 0) {
    return ($value == 0);
  }

  my $k = $self->{'k'};
  my $add = $self->{'add'};
  my $sqrt = int(sqrt(int(8*($k-2) * $value + $add*$add)));

  ### sqrt of: (8*($k-2) * $value + $add*$add)

  if ($self->{'pairs'} eq 'both') {
    my $i = int (($sqrt + $self->{'add'}) / (2*($k-2)));
    if ($value == $i * (($k-2)*$i - $self->{'add'}) / 2) {
      return 1;
    }
  }
  my $i = int (($sqrt - $self->{'add'}) / (2*($k-2)));

  ### $sqrt
  ### $i

  return ($value == $i * (($k-2)*$i + $self->{'add'}) / 2);
}

# P(i) = (k-2)/2 * i*(i+1) - (k-3)*i
# P(i) ~= (k-2)/2 * i*i
# i ~= sqrt( P(i)*2/(k-2) )
#
sub value_to_i_estimate {
  my ($self, $value) = @_;
  if ($value < 0) { return 0; }
  return int(sqrt(int($value)*2/($self->{'k'}-2)));
}

1;
__END__

=for stopwords Ryde Math-NumSeq 3-gonals 4-gonals 5-gonals k-gonals pentagonals polygonals

=head1 NAME

Math::NumSeq::Polygonal -- polygonal numbers, triangular, square, pentagonal, etc

=head1 SYNOPSIS

 use Math::NumSeq::Polygonal;
 my $seq = Math::NumSeq::Polygonal->new (polygonal => 7);
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The sequence of polygonal numbers.  The 3-gonals are the triangular numbers
i*(i+1)/2, the 4-gonals are squares i*i, the 5-gonals are pentagonals
(3i-1)*i/2, etc.

In general the k-gonals for kE<gt>=3 are

    P(i) = (k-2)/2 * i*(i+1) - (k-3)*i

The values are how many points are in a triangle, square, pentagon, hexagon,
etc of side i.  For example the triangular numbers,

                                         d
                             c          c d
                b           b c        b c d
    a          a b         a b c      a b c d

    i=1        i=2         i=3        i=4
    value=1    value=3     value=6    value=10

Or the squares,

                                      d d d d
                           c c c      c c c d
               b b         b b c      b b c d
    a          a b         a b c      a b c d

    i=1        i=2         i=3        i=4
    value=1    value=4     value=9    value=16

Or pentagons (which should be a pentagonal grid, so skewing a bit here),

                                              d
                                            d   d
                               c          d  c    d
                             c   c      d  c   c    d
                  b        c  b    c     c  b    c d
                b   b       b   b c       b   b c d
    a            a b         a b c         a b c d

    i=1        i=2         i=3          i=4
    value=1    value=5     value=12     value=22

The letters "a", "b" "c" show the extra added onto the previous figure to
grow its points.  Each side except two are extended.  In general the
k-gonals increment by k-2 sides of i points, plus 1 at the end of the last
side, so

   P(i+1) = P(i) + (k-2)*i + 1

=head2 Second Kind

Option C<pairs =E<gt> 'second'> gives the polygonals of the second kind,
which are the same formula but with a negative i.

    S(i) = P(-i) = (k-2)/2 * i*(i-1) + (k-3)*i

The result is still positive values, bigger than the plain P(i).  For
example the pentagonals are 0,1,5,12,22,etc and the second pentagonals are
0,2,7,15,26,etc.

=head2 Both Kinds

C<pairs =E<gt> 'both'> gives the firsts and seconds interleaved.  P(0) and
S(0) are both 0 and that value is given just once at i=0, so

    0, P(1), S(1), P(2), S(2), P(3), S(3), ...

=head2 Average

Option C<pairs =E<gt> 'average'> is the average of the first and second,
which ends up being simply a multiple of the perfect squares,

    A(i) = (P(i)+S(i))/2
         = (k-2)/2 * i*i

This is an integer if k is even, or k odd and i is even.  If k and i both
odd then it's an 0.5 fraction.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::Polygonal-E<gt>new ()>

=item C<$seq = Math::NumSeq::Polygonal-E<gt>new (pairs =E<gt> $str)>

Create and return a new sequence object.  The default is the polygonals of
the "first" kind, or the C<pairs> option (a string) can be

    "first"
    "second"
    "both"
    "average"

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the C<$i>'th polygonal value, of the given C<pairs> type.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is a polygonal number, of the given C<pairs> type.

=item C<$i = $seq-E<gt>value_to_i_estimate($value)>

Return an estimate of the i corresponding to C<$value>.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Cubes>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2018, 2019, 2020, 2021 Kevin Ryde

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

# expression => 'cbrt(2)'
# expression => 'cbrt 2'
# expression => '7throot 10'
# rootof(x^3-2)
# type => 'custom'
# 





# Copyright 2012 Kevin Ryde

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

package Math::NumSeq::CbrtContinued;
use 5.004;
use strict;
use Carp;

use vars '$VERSION', '@ISA';
$VERSION = 53;
use Math::NumSeq 7; # v.7 for _is_infinite()
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;
*_to_bigint = \&Math::NumSeq::_to_bigint;

use Math::NumSeq::Cubes;

# uncomment this to run the ### lines
use Smart::Comments;


# use constant name => Math::NumSeq::__('Cbrt Continued Fraction');
use constant description => Math::NumSeq::__('Continued fraction expansion of a cube root.');
use constant i_start => 0;
use constant characteristic_smaller => 1;
use constant characteristic_increasing => 0;
# use constant characteristic_continued_fraction => 1;

use constant parameter_info_array =>
  [
   {
    name    => 'cbrt',
    display => Math::NumSeq::__('Cbrt'),
    type    => 'integer',
    default => 2,
    minimum => 2,
    width   => 5,
    description => Math::NumSeq::__('Number to take the cube root of.  If this is a cube then there\'s just a single term in the expansion.  Non cubes go on infinitely.'),
   },
  ];

#------------------------------------------------------------------------------

# cf A002951 contfrac 5^(1/5)
#    A003117 contfrac 3^(1/5)
#    A003118 contfrac 4^(1/5)
#
# A002945 to A002949 are OFFSET=1, unlike i_start=0 here
# (OFFSET=0 is rumoured to be the preferred style for continued fractions)
#
# cbrt 2
# 1,3,1,5,1,1,4,1,1,8,1,14,1,10,2,1,4,12,2,3,2,1,3,   
#
my @oeis_anum = (
                 # OEIS-Catalogue array begin
                 undef,     # cbrt=0
                 undef,     # cbrt=1
                 undef, # 'A002945', # cbrt=2 but OFFSET=1
                 undef, # 'A002946', # cbrt=3
                 undef, # 'A002947', # cbrt=4
                 undef, # 'A002948', # cbrt=5
                 undef, # 'A002949', # cbrt=6
                 undef,     # cbrt=7
                 undef,     # cbrt=8
                 'A010239', # cbrt=9
                 'A010240', # cbrt=10
                 'A010241', # cbrt=11
                 'A010242', # cbrt=12
                 'A010243', # cbrt=13
                 'A010244', # cbrt=14
                 'A010245', # cbrt=15
                 'A010246', # cbrt=16
                 'A010247', # cbrt=17
                 'A010248', # cbrt=18
                 'A010249', # cbrt=19
                 'A010250', # cbrt=20
                 'A010251', # cbrt=21
                 'A010252', # cbrt=22
                 'A010253', # cbrt=23
                 'A010254', # cbrt=24
                 'A010255', # cbrt=25
                 'A010256', # cbrt=26
                 undef,     # 27
                 'A010257', # cbrt=28
                 'A010258', # cbrt=29
                 'A010259', # cbrt=30
                 'A010260', # cbrt=31
                 'A010261', # cbrt=32
                 'A010262', # cbrt=33
                 'A010263', # cbrt=34
                 'A010264', # cbrt=35
                 'A010265', # cbrt=36
                 'A010266', # cbrt=37
                 'A010267', # cbrt=38
                 'A010268', # cbrt=39
                 'A010269', # cbrt=40
                 'A010270', # cbrt=41
                 'A010271', # cbrt=42
                 'A010272', # cbrt=43
                 'A010273', # cbrt=44
                 'A010274', # cbrt=45
                 'A010275', # cbrt=46
                 'A010276', # cbrt=47
                 'A010277', # cbrt=48
                 'A010278', # cbrt=49
                 'A010279', # cbrt=50
                 'A010280', # cbrt=51
                 'A010281', # cbrt=52
                 'A010282', # cbrt=53
                 'A010283', # cbrt=54
                 'A010284', # cbrt=55
                 'A010285', # cbrt=56
                 'A010286', # cbrt=57
                 'A010287', # cbrt=58
                 'A010288', # cbrt=59
                 'A010289', # cbrt=60
                 'A010290', # cbrt=61
                 'A010291', # cbrt=62
                 'A010292', # cbrt=63
                 undef,     # 64
                 'A010293', # cbrt=65
                 'A010294', # cbrt=66
                 'A010295', # cbrt=67
                 'A010296', # cbrt=68
                 'A010297', # cbrt=69
                 'A010298', # cbrt=70
                 'A010299', # cbrt=71
                 'A010300', # cbrt=72
                 'A010301', # cbrt=73
                 'A010302', # cbrt=74
                 'A010303', # cbrt=75
                 'A010304', # cbrt=76
                 'A010305', # cbrt=77
                 'A010306', # cbrt=78
                 'A010307', # cbrt=79
                 'A010308', # cbrt=80
                 'A010309', # cbrt=81
                 'A010310', # cbrt=82
                 'A010311', # cbrt=83
                 'A010312', # cbrt=84
                 'A010313', # cbrt=85
                 'A010314', # cbrt=86
                 'A010315', # cbrt=87
                 'A010316', # cbrt=88
                 'A010317', # cbrt=89
                 'A010318', # cbrt=90
                 'A010319', # cbrt=91
                 'A010320', # cbrt=92
                 'A010321', # cbrt=93
                 'A010322', # cbrt=94
                 'A010323', # cbrt=95
                 'A010324', # cbrt=96
                 'A010325', # cbrt=97
                 'A010326', # cbrt=98
                 'A010327', # cbrt=99
                 'A010328', # cbrt=100

                 # OEIS-Catalogue array end
                );

sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum[$self->{'cbrt'}];
}

#------------------------------------------------------------------------------

sub values_min {
  my ($self) = @_;
  if (Math::NumSeq::Cubes->pred($self->{'cbrt'})) {
    ### pefect cube ...
    return Math::NumSeq::Cubes->value_to_i_floor($self->{'cbrt'});
  }
  return 1;
}
sub values_max {
  my ($self) = @_;
  if (Math::NumSeq::Cubes->pred($self->{'cbrt'})) {
    ### pefect cube ...
    return Math::NumSeq::Cubes->value_to_i_floor($self->{'cbrt'});
  }
  return undef;
}

#------------------------------------------------------------------------------
#
# (aC+b)/(cC+d) - j >= 0
# (aC+b) - j*(cC+d) >= 0
# aC + b - jcC - jd >= 0
# (a-jc)C >= (jd-b)
# CC*(a-jc)^3 >= (jd-b)^3
# CC*(a-jc)^3 - (jd-b)^3 >= 0
#  (-d^3 - c^3*CC)*j^3
#  + (3*b*d^2 + 3*c^2*a*CC)*j^2
#  + (-3*b^2*d - 3*c*a^2*CC)*j
#  + (b^3 + a^3*CC)
# poly
# p = -d^3 - c^3*CC
# q = 3*b*d^2 + 3*c^2*a*CC
# r = -3*b^2*d - 3*c*a^2*CC
# s = b^3 + a^3*CC
# initial a=1,b=0,c=0,d=1
# p = -1
# q = 0
# r = 0
# s = 1*CC
#
# new = 1 / ((aC+b)/(cC+d) - j)
#     =  1 / (((aC+b) - j*(cC+d))/(cC+d))
#     =  (cC+d) / ((aC+b) - j*(cC+d))
#     =  (cC+d) / ((a-jc)*C + b-jd)
# new p = -(b-jd)^3 - (a-jc)^3*CC
#       = (d^3 + c^3*CC)*j^3 + (-3*b*d^2 - 3*c^2*a*CC)*j^2 + (3*b^2*d + 3*c*a^2*CC)*j + (-b^3 - a^3*CC)
#       = -p*j^3 + (-3*b*d^2 - 3*c^2*a*CC)*j^2 + (3*b^2*d + 3*c*a^2*CC)*j + (-b^3 - a^3*CC)
#       = d^3*j^3 + c^3*CC*j^3
#         + (-3*b*d^2*j^2 - 3*c^2*a*CC*j^2)
#         + (3*b^2*d*j + 3*c*a^2*j*CC)
#         + (-b^3 - a^3*CC)
# new q = 3*d*(b-jd)^2 + 3*(a-jc)^2*c*CC
# new r = -3*d^2*(b-jd) - 3*(a-jc)*c^2*CC
# new s = d^3 + c^3*CC
#       = -p

# x = root of p,q,r,s
# shift to (x+j)
# p*(x+j)^3 + q*(x+j)^2 + r*(x+j) + s
# reverse and negate for -1/x
# new s = -p
# new r = -(3*p*j + q)
# new q = -(3*p*j^2 + 2*q*j + r)
# new p = -(p*j^3 + q*j^2 + r*j + s)
#
# o*(x+j)^4 + p*(x+j)^3 + q*(x+j)^2 + r*(x+j) + s
# low  = s + r*j + q*j^2 + p*j^3 + o*j^4
# next =     r   + q*2*j + p*3j^2 + o*4*j^3
# next =           q     + p*3j + o* 6 j^2           1,3,6,10,15,21,28
# next =                   p    + o*4j               1,4,10,20,35,56
# high =                          o                  1,5,15,35,70,126
#
# bin(n,m) = n!/m!(n-m)!
# bin(n+1,m+1) = (n+1)!/(m+1)!(n+1-m-1)!
#              = (n+1)/(m+1) * n!/m!/(n-m)!
# bin(10,3)=120   120*11/4 = 330
# bin(11,4)=330 = 120*11/4
#
#-------------
# perfect cube C=2
# new = (C+0)/(0+1) - 2
#     = (0+1) / ((1-2*0)C + 0-2*1)
#     = (0+1) / (1C + -2)
# p = -(-2)^3 - 1^3 * CC
#   = 0

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;

  $self->{'p'} = _to_bigint(-1);
  $self->{'q'} = $self->{'r'} = Math::NumSeq::_to_bigint(0);
  $self->{'s'} = Math::NumSeq::_to_bigint($self->{'cbrt'});
}

sub next {
  my ($self) = @_;
  ### CbrtContinued next() ...


  my $cbrt = $self->{'cbrt'};
  my $p = $self->{'p'};
  my $q = $self->{'q'};
  my $r = $self->{'r'};
  my $s = $self->{'s'};
  ### p: "$p"
  ### q: "$q"
  ### r: "$r"
  ### s: "$s"
  
  if ($p == 0) {
    ### perfect cube ...
    return;
  }
  if ($p > 0) {
    die "Oops, CbrtContinued poly not negative";
  }
  
  my $poly = sub {
    my ($j) = @_;
    return (($p*$j + $q)*$j + $r)*$j + $s;
  };
  
  my $lo = 1;
  my $hi = 2;
  while ($poly->($hi) >= 0) {
    ### assert: $poly->($lo) >= 0
    ### lohi: "$lo,$hi  poly ".$poly->($lo)." ".$poly->($hi)
    ($lo,$hi) = ($hi,2*$hi);
  }
  
  my $j;
  for (;;) {
    $j = int(($lo+$hi)/2);
  
    ### lohi: "$lo,$hi  poly ".$poly->($lo)." ".$poly->($hi)
    ### $j
    ### assert: $poly->($lo) >= 0
    ### assert: $poly->($hi) < 0
  
    if ($j == $lo) {
      last;
    }
    if ($poly->($j) >= 0) {
      $lo = $j;
    } else {
      $hi = $j;
    }
  }
  ### $j
  
  $self->{'p'} = -($p*$j**3 + $q*$j**2 + $r*$j + $s);
  $self->{'q'} = -(3*$p*$j**2 + 2*$q*$j + $r);
  $self->{'r'} = -(3*$p*$j + $q);
  $self->{'s'} = -$p;
  
  return ($self->{'i'}++, $j);
}

1;
__END__

=for stopwords Ryde Math-NumSeq BigInt

=head1 NAME

Math::NumSeq::CbrtContinued -- continued fraction expansion of a cube root

=head1 SYNOPSIS

 use Math::NumSeq::CbrtContinued;
 my $seq = Math::NumSeq::CbrtContinued->new (cbrt => 2);
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

I<In progress ... general algebraic irrational ?>

This is terms in the continued fraction expansion of a cube root.  For example cbrt(2),

    1, 3, 1, 5, 1, 1, 4, 1, 1, 8, 1, 14, 1, 10, 2, 1, 4, 12, 2, ...

The continued fraction approaches the root by

                      1   
   cbrt(C) = a[0] + ----------- 
                    a[1] +   1
                           -----------
                           a[2] +   1
                                  ----------
                                  a[3] + ...

The first term a[0] is the integer part of the root, leaving a remainder
S<0 E<lt> r E<lt> 1> which is expressed as r=1/R with S<R E<gt> 1>, so

                     1   
   cbrt(C) = a[0] + ---
                     R

Then a[1] is the integer part of that R, and so on recursively.

The current code uses a fairly generic algebraic root approach and
C<Math::BigInt> coefficients (see L</FORMULAS> below).  The coefficients
tend to be come large and the calculation a bit slow.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::CbrtContinued-E<gt>new (cbrt =E<gt> $s)>

Create and return a new sequence object.

=item C<$i = $seq-E<gt>i_start ()>

Return 0, the first term in the sequence being at i=0.

=back

=head1 FORMULAS

=head2 Next

The continued fraction can be developed by maintaining a cubic equation with
real root equal to the remainder R at each stage.  Initially this is cbrt(C)
so

    -x^3 + C = 0

and later in general

    p*x^3 + q*x^2 + r*x + s = 0
    p,q,r,s integers and p < 0

From such a cubic equation the integer part of the root can be found by
looking for the biggest integer x with

    p*x^3 + q*x^2 + r*x + s < 0

Choosing the signs so C<pE<lt>0> means the cubic is positive for small x and
becomes negative after the root.

Various root finding algorithms could probably be used, but the current code
is just a binary search.  The integer part of the remainder is often 1, so
often it's enough to make a single check to see if x=2 gives cubicE<lt>0.

The integer part is subtracted R-a and inverted 1/(R-a) for the continued
fraction.  This is applied to the cubic equation by a substitution x+a,

    p*x^3 + (3pa+q)*x^2 + (3pa^2+2qa+r)x + (pa^3+qa^2+ra+s)

and then 1/x which is a reversal p,q,r,s -> s,r,q,p, then a term-wise
negation to keep S<pE<lt>0>.  So

    new p = -(p*a^3 + q*a^2 + r*a + s)
    new q = -(3p*a^2 + 2q*a + r)
    new r = -(3p*a + q)
    new s = -p

The values p,q,r,s are integers but may become large, growing by about 1.7
bits per term generated.  Presumably growth is related to the average size
of the a[i] terms.

This same approach extends to any algebraic number, ie. root of a
polynomial.  But quadratics can be handled more easily.

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::SqrtContinued>

=head1 HOME PAGE

http://user42.tuxfamily.org/math-numseq/index.html

=head1 LICENSE

Copyright 2012 Kevin Ryde

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

# Copyright 2012, 2013, 2014, 2016 Kevin Ryde

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

package Math::NumSeq::AlgebraicContinued;
use 5.004;
use strict;
use Carp;

use vars '$VERSION', '@ISA';
$VERSION = 73;
use Math::NumSeq 7; # v.7 for _is_infinite()
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;
*_to_bigint = \&Math::NumSeq::_to_bigint;

use Math::NumSeq::Cubes;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Algebraic Continued Fraction');
use constant description => Math::NumSeq::__('Continued fraction expansion of an algebraic number, such as cube root or nth root.');
use constant default_i_start => 0;
use constant characteristic_smaller => 1;
use constant characteristic_increasing => 0;
# use constant characteristic_continued_fraction => 1;

use constant parameter_info_array =>
  [
   {
    name    => 'expression',
    display => Math::NumSeq::__('Expression'),
    type    => 'string',
    width   => 20,
    default => 'cbrt 2',
    choices => ['cbrt 2','7throot 123'],
    description => Math::NumSeq::__('Expression to take continued fraction.  Can be "cbrt 123", "7throot 123", etc'),
   },
  ];

#------------------------------------------------------------------------------

# A002945 to A002949 are OFFSET=1, unlike i_start=0 here
# (OFFSET=0 is rumoured to be the preferred style for continued fractions)
#
my @oeis_anum;

$oeis_anum[3]
  = {
     # OEIS-Catalogue array begin

     '2,0,0,-1,i_start=1' => 'A002945', # expression=cbrt2 i_start=1
     '3,0,0,-1,i_start=1' => 'A002946', # expression=cbrt3 i_start=1
     '4,0,0,-1,i_start=1' => 'A002947', # expression=cbrt4 i_start=1
     '5,0,0,-1,i_start=1' => 'A002948', # expression=cbrt5 i_start=1
     '6,0,0,-1,i_start=1' => 'A002949', # expression=cbrt6 i_start=1
     # undef,     # expression=cbrt7
     # undef,     # expression=cbrt8
     '9,0,0,-1'   => 'A010239', # expression=cbrt9
     '10,0,0,-1'  => 'A010240', # expression=cbrt10
     '11,0,0,-1'  => 'A010241', # expression=cbrt11
     '12,0,0,-1'  => 'A010242', # expression=cbrt12
     '13,0,0,-1'  => 'A010243', # expression=cbrt13
     '14,0,0,-1'  => 'A010244', # expression=cbrt14
     '15,0,0,-1'  => 'A010245', # expression=cbrt15
     '16,0,0,-1'  => 'A010246', # expression=cbrt16
     '17,0,0,-1'  => 'A010247', # expression=cbrt17
     '18,0,0,-1'  => 'A010248', # expression=cbrt18
     '19,0,0,-1'  => 'A010249', # expression=cbrt19
     '20,0,0,-1'  => 'A010250', # expression=cbrt20
     '21,0,0,-1'  => 'A010251', # expression=cbrt21
     '22,0,0,-1'  => 'A010252', # expression=cbrt22
     '23,0,0,-1'  => 'A010253', # expression=cbrt23
     '24,0,0,-1'  => 'A010254', # expression=cbrt24
     '25,0,0,-1'  => 'A010255', # expression=cbrt25
     '26,0,0,-1'  => 'A010256', # expression=cbrt26
     # '27,0,0,-1' =>   undef,     # 27
     '28,0,0,-1'  => 'A010257', # expression=cbrt28
     '29,0,0,-1'  => 'A010258', # expression=cbrt29
     '30,0,0,-1'  => 'A010259', # expression=cbrt30
     '31,0,0,-1'  => 'A010260', # expression=cbrt31
     '32,0,0,-1'  => 'A010261', # expression=cbrt32
     '33,0,0,-1'  => 'A010262', # expression=cbrt33
     '34,0,0,-1'  => 'A010263', # expression=cbrt34
     '35,0,0,-1'  => 'A010264', # expression=cbrt35
     '36,0,0,-1'  => 'A010265', # expression=cbrt36
     '37,0,0,-1'  => 'A010266', # expression=cbrt37
     '38,0,0,-1'  => 'A010267', # expression=cbrt38
     '39,0,0,-1'  => 'A010268', # expression=cbrt39
     '40,0,0,-1'  => 'A010269', # expression=cbrt40
     '41,0,0,-1'  => 'A010270', # expression=cbrt41
     '42,0,0,-1'  => 'A010271', # expression=cbrt42
     '43,0,0,-1'  => 'A010272', # expression=cbrt43
     '44,0,0,-1'  => 'A010273', # expression=cbrt44
     '45,0,0,-1'  => 'A010274', # expression=cbrt45
     '46,0,0,-1'  => 'A010275', # expression=cbrt46
     '47,0,0,-1'  => 'A010276', # expression=cbrt47
     '48,0,0,-1'  => 'A010277', # expression=cbrt48
     '49,0,0,-1'  => 'A010278', # expression=cbrt49
     '50,0,0,-1'  => 'A010279', # expression=cbrt50
     '51,0,0,-1'  => 'A010280', # expression=cbrt51
     '52,0,0,-1'  => 'A010281', # expression=cbrt52
     '53,0,0,-1'  => 'A010282', # expression=cbrt53
     '54,0,0,-1'  => 'A010283', # expression=cbrt54
     '55,0,0,-1'  => 'A010284', # expression=cbrt55
     '56,0,0,-1'  => 'A010285', # expression=cbrt56
     '57,0,0,-1'  => 'A010286', # expression=cbrt57
     '58,0,0,-1'  => 'A010287', # expression=cbrt58
     '59,0,0,-1'  => 'A010288', # expression=cbrt59
     '60,0,0,-1'  => 'A010289', # expression=cbrt60
     '61,0,0,-1'  => 'A010290', # expression=cbrt61
     '62,0,0,-1'  => 'A010291', # expression=cbrt62
     '63,0,0,-1'  => 'A010292', # expression=cbrt63
     # '64,0,0,-1'  =>   undef,     # 64
     '65,0,0,-1'  => 'A010293', # expression=cbrt65
     '66,0,0,-1'  => 'A010294', # expression=cbrt66
     '67,0,0,-1'  => 'A010295', # expression=cbrt67
     '68,0,0,-1'  => 'A010296', # expression=cbrt68
     '69,0,0,-1'  => 'A010297', # expression=cbrt69
     '70,0,0,-1'  => 'A010298', # expression=cbrt70
     '71,0,0,-1'  => 'A010299', # expression=cbrt71
     '72,0,0,-1'  => 'A010300', # expression=cbrt72
     '73,0,0,-1'  => 'A010301', # expression=cbrt73
     '74,0,0,-1'  => 'A010302', # expression=cbrt74
     '75,0,0,-1'  => 'A010303', # expression=cbrt75
     '76,0,0,-1'  => 'A010304', # expression=cbrt76
     '77,0,0,-1'  => 'A010305', # expression=cbrt77
     '78,0,0,-1'  => 'A010306', # expression=cbrt78
     '79,0,0,-1'  => 'A010307', # expression=cbrt79
     '80,0,0,-1'  => 'A010308', # expression=cbrt80
     '81,0,0,-1'  => 'A010309', # expression=cbrt81
     '82,0,0,-1'  => 'A010310', # expression=cbrt82
     '83,0,0,-1'  => 'A010311', # expression=cbrt83
     '84,0,0,-1'  => 'A010312', # expression=cbrt84
     '85,0,0,-1'  => 'A010313', # expression=cbrt85
     '86,0,0,-1'  => 'A010314', # expression=cbrt86
     '87,0,0,-1'  => 'A010315', # expression=cbrt87
     '88,0,0,-1'  => 'A010316', # expression=cbrt88
     '89,0,0,-1'  => 'A010317', # expression=cbrt89
     '90,0,0,-1'  => 'A010318', # expression=cbrt90
     '91,0,0,-1'  => 'A010319', # expression=cbrt91
     '92,0,0,-1'  => 'A010320', # expression=cbrt92
     '93,0,0,-1'  => 'A010321', # expression=cbrt93
     '94,0,0,-1'  => 'A010322', # expression=cbrt94
     '95,0,0,-1'  => 'A010323', # expression=cbrt95
     '96,0,0,-1'  => 'A010324', # expression=cbrt96
     '97,0,0,-1'  => 'A010325', # expression=cbrt97
     '98,0,0,-1'  => 'A010326', # expression=cbrt98
     '99,0,0,-1'  => 'A010327', # expression=cbrt99
     '100,0,0,-1' => 'A010328', # expression=cbrt100

     # OEIS-Catalogue array end
    };

$oeis_anum[4]
  = {
     # OEIS-Catalogue array begin
     '2,0,0,0,-1,i_start=1'   => 'A179613', # expression=4throot2 i_start=1
     '3,0,0,0,-1,i_start=1'   => 'A179615', # expression=4throot3 i_start=1
     '5,0,0,0,-1,i_start=1'   => 'A179616', # expression=4throot5 i_start=1
     '91,0,0,0,-10,i_start=1' => 'A093876', # expression=4throot9.1 i_start=1
     # OEIS-Catalogue array end
    };

$oeis_anum[5]
  = {
     # OEIS-Catalogue array begin
     '2,0,0,0,0,-1,i_start=1' => 'A002950', # expression=5throot2 i_start=1
     '3,0,0,0,0,-1,i_start=1' => 'A003117', # expression=5throot3 i_start=1
     '4,0,0,0,0,-1,i_start=1' => 'A003118', # expression=5throot4 i_start=1
     '5,0,0,0,0,-1,i_start=1' => 'A002951', # expression=5throot5 i_start=1
     # OEIS-Catalogue array end
    };

sub oeis_anum {
  my ($self) = @_;
  my $key = join(',',@{$self->{'orig_poly'}});
  if (my $i_start = $self->i_start) {
    ### $i_start
    $key .= ",i_start=$i_start";  # if non-zero
  }
  ### $key
  return $oeis_anum[$self->{'root'}]->{$key};
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

# nthroot(num/den)
# f(x) = num/den - x^n 
#      = num - den*x^n
sub _nthroot_to_poly {
  my ($power, $num, $den) = @_;
  my $zero = Math::NumSeq::_to_bigint(0);
  return (_to_bigint("$num"),
          ($zero) x ($power-1),
          - _to_bigint("$den"));
}

my %name_to_root = (sqrt => 2,
                    cbrt => 3);
sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;

  if (! $self->{'orig_poly'}) {
    my $str = $self->{'expression'};
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    $str =~ s/\s+/ /g;
    my ($root, $operand);
    if ($str =~ /^(sqrt|cbrt|(\d+)throot) ?\(? ?(\d+(\.\d*)?|\d*\.\d+) ?\)?$/) {
      $root = (defined $2 ? $2 : $name_to_root{$1});
      $operand = $3;
    } else {
      croak "Unrecognised expression: ",$str;
    }
    ### $root
    ### $operand

    my ($num, $den);
    if ($operand =~ /^(\d*)\.(\d*)$/) {
      $num = $1.$2;
      $den = '1' . ('0' x length($2));
    } else {
      $num = $operand;
      $den = 1;
    }

    $self->{'orig_poly'} = [ _nthroot_to_poly($root,$num,$den) ];
    ### orig_poly join(',',@{$self->{'orig_poly'}})

    # if root<1 then initial continued fraction term is 0
    $self->{'values_min'} = (_eval($self->{'orig_poly'},1) < 0 ? 0 : 1);

    $self->{'root'} = $root;
    $self->{'operand'} = $operand;
  }

  $self->{'poly'} = [ @{$self->{'orig_poly'}} ];  # copy array
}

sub _eval {
  my ($poly, $x) = @_;
  my $ret = 0;
  foreach my $coeff (reverse @$poly) {  # high to low
    $ret *= $x;
    $ret += $coeff;
  }
  return $ret;
}

sub next {
  my ($self) = @_;
  ### AlgebraicContinued next(): "poly=".join(',',@{$self->{'poly'}})

  my $poly = $self->{'poly'};
  if ($poly->[-1] == 0) {
    ### poly high zero, perfect power ...
    return;
  }

  # doubling probe for p(lo) >= 0 by p(hi) < 0
  my $lo = $self->{'values_min'};  # 0 or 1
  my $hi = 2;
  while (_eval($poly,$hi) >= 0) {
    ### assert: _eval($poly,$lo) >= 0
    ### lohi: "$lo,$hi  eval "._eval($poly,$lo)." "._eval($poly,$hi)
    if ($hi == 0x4000_0000) {
      # ENHANCE-ME: are terms ever bignums ?
      $hi = _to_bigint($hi);
    }
    ($lo,$hi) = ($hi,2*$hi);
  }

  # binary search for smallest c with poly(c) < 0
  my $c;
  for (;;) {
    $c = int(($lo+$hi)/2);

    ### lohi: "$lo,$hi  poly "._eval($poly,$lo)." "._eval($poly,$hi)
    ### c: "$c"
    ### assert: _eval($poly,$lo) >= 0
    ### assert: _eval($poly,$hi) < 0

    if ($c == $lo) {
      last;
    }
    if (_eval($poly,$c) >= 0) {
      $lo = $c;
    } else {
      $hi = $c;
    }
  }
  ### c: "$c"

  # column = j  row=j-i
  # binomial(j+1,j-i+1)
  # factor (n+1)/(m+1) = (j+2)/(j-i+2)
  #
  my @new = @$poly;
  {
    my $cpow = _to_bigint($c);  # c^i
    foreach my $i (1 .. $#$poly) {
      my $t = $cpow;
      foreach my $j ($i .. $#$poly-1) {
        ### term: "t=$t coeff=$poly->[$j]  next mul ".($j+1)." div ".($j+1-$i)
        $new[$j-$i] += $t * $poly->[$j];
        $t *= $j+1;
        ### assert: $t % ($j+1-$i) == 0
        $t /= $j+1-$i;
      }
      $new[$#$poly-$i] += $t * $poly->[-1];
      $cpow *= $c;
    }
  }
  @$poly = map{-$_} reverse @new;

  if ($poly->[-1] > 0) {
    die "Oops, AlgebraicContinued poly not negative";
  }

  return ($self->{'i'}++, $c);


  # $self->{'p'} = -($p*$c**3 + $q*$c**2 + $r*$c + $s);
  # $self->{'q'} = -(3*$p*$c**2 + 2*$q*$c + $r);
  # $self->{'r'} = -(3*$p*$c + $q);
  # $self->{'s'} = -$p;
}

1;
__END__

=for stopwords Ryde Math-NumSeq BigInt Seminumerical OEIS

=head1 NAME

Math::NumSeq::AlgebraicContinued -- continued fraction expansion of algebraic numbers

=head1 SYNOPSIS

 use Math::NumSeq::AlgebraicContinued;
 my $seq = Math::NumSeq::AlgebraicContinued->new (expression => 'cbrt 2');
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is terms in the continued fraction expansion of an algebraic number
such as a cube root or Nth root.  For example cbrt(2),

    1, 3, 1, 5, 1, 1, 4, 1, 1, 8, 1, 14, 1, 10, 2, 1, 4, 12, 2, ...
    starting i=0

A continued fraction approaches the root by a form

                 1   
    C = a[0] + -------------
               a[1] +   1
                      -------------
                      a[2] +   1
                             ----------
                             a[3] + ...

The first term a[0] is the integer part of C, leaving a remainder
S<0 E<lt> r E<lt> 1> which is expressed as r=1/R with S<R E<gt> 1>, so

               1   
   C = a[0] + ---
               R

Then a[1] is the integer part of that R, and so on repeatedly.

The current code uses a generic approach manipulating a polynomial with
C<Math::BigInt> coefficients (see L</FORMULAS> below).  It tends to be a
little slow because the coefficients become large, representing an ever more
precise approximation to the target value.

=head2 Expression

The C<expression> parameter currently only accepts a couple of forms for a
cube root or Nth root.

    cbrt 123
    7throot 123

The intention would be to perhaps take some simple fractions or products if
they can be turned into a polynomial easily.  Or take an initial polynomial
directly.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::AlgebraicContinued-E<gt>new (expression =E<gt> $str)>

Create and return a new sequence object.

=item C<$i = $seq-E<gt>i_start ()>

Return 0, the first term in the sequence being at i=0.

=back

=head1 FORMULAS

=head2 Next

The continued fraction can be developed by maintaining a polynomial with
single real root equal to the remainder R at each stage.  (As per for
example Knuth volume 2 Seminumerical Algorithms section 4.5.3 exercise 13,
following Lagrange.)

As an example, a cube root cbrt(C) begins

    -x^3 + C = 0

and later has a set of coefficients p,q,r,s

    p*x^3 + q*x^2 + r*x + s = 0
    p,q,r,s integers and p < 0

From such an equation the integer part of the root can be found by looking
for the biggest integer x with

    p*x^3 + q*x^2 + r*x + s < 0

Choosing the signs so the high coefficient C<pE<lt>0> means the polynomial
is positive for small x and becomes negative above the root.

Various root finding algorithms could probably be used, but the current code
is a binary search.

The integer part is subtracted R-c and then inverted 1/(R-c) for the
continued fraction.  This is applied to the cubic equation first by a
substitution x+c,

    p*x^3 + (3pc+q)*x^2 + (3pc^2+2qc+r)x + (pc^3+qc^2+rc+s)

and then 1/x which is a reversal p,q,r,s -> s,r,q,p, and a term-wise
negation to keep S<pE<lt>0>.  So

    new p = -(p*c^3 + q*c^2 + r*c + s)
    new q = -(3p*c^2 + 2q*c + r)
    new r = -(3p*c + q)
    new s = -p

The values p,q,r,s are integers but may become large.  For a cube root they
seem to grow by about 1.7 bits per term.  Presumably growth is related to
the average size of the a[i] terms.

For a general polynomial the substitution x+c becomes a set of binomial
factors for the coefficients.

For a square root or other quadratic equation q*x^2+rx+s the continued
fraction terms repeat and can be calculated more efficiently than this
general approach (see L<Math::NumSeq::SqrtContinued>).

The binary search or similar root finding algorithm for the integer part is
important.  The integer part is often 1, and in that case a single check to
see if x=2 gives polyE<lt>0 suffices.  But a term can be quite large so a
linear search 1,2,3,4,etc is undesirable.  An example with large terms can
be found in Sloane's OEIS,

=over

L<http://oeis.org/A093876>
continued fraction of 4th root of 9.1, ie. (91/10)^(1/4)

=back

The first few terms include 75656 and 262344, before settling down to more
usual size terms it seems.

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::SqrtContinued>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2016 Kevin Ryde

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

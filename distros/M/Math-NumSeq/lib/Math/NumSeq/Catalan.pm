# Copyright 2012, 2013, 2014, 2016, 2018, 2019, 2020 Kevin Ryde

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

package Math::NumSeq::Catalan;
use 5.004;
use strict;

use vars '$VERSION','@ISA';
$VERSION = 75;

use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Fibonacci;
*_blog2_estimate = \&Math::NumSeq::Fibonacci::_blog2_estimate;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Catalan Numbers');
use constant values_min => 1;
use constant default_i_start => 0;
use constant characteristic_integer => 1;
use constant characteristic_non_decreasing => 1;
{
  my %characteristic_increasing_from_i = (C   => 1,
                                          odd => 2);
  sub characteristic_increasing_from_i {
    my ($self) = @_;
    return $characteristic_increasing_from_i{$self->{'values_type'}};
  }
}
{
  my %description = (C   => Math::NumSeq::__('The Catalan numbers 1, 1, 2, 5, 14, 42, ... (2n)!/(n!*(n+1)!).'),
                     odd => Math::NumSeq::__('The odd part of the Catalan numbers 1, 1, 2, 5, 14, 42, ... (2n)!/(n!*(n+1)!).'),);
  sub description {
    my ($self) = @_;
    return $description{ref $self ? $self->{'values_type'} : 'C'};
  }
}

use constant parameter_info_array =>
  [ {
     name      => 'values_type',
     share_key => 'values_type_Codd',
     type      => 'enum',
     default   => 'C',
     choices   => ['C',
                   'odd',
                  ],
     choices_display => [Math::NumSeq::__('C'),
                         Math::NumSeq::__('Odd'),
                        ],
     description => Math::NumSeq::__('The Catalan numbers, or just the odd part.'),
    },
  ];

#------------------------------------------------------------------------------
# A048990 Catalans at even i
# A024492 Catalans at odd i
# A014137 Catalans cumulative
# A094639 Catalans squared cumulative
# A000984 central binomial coeff (2n)! / n!^2
# A048881 trailing zeros a(n) = A000120(n+1) - 1 = onebits(n+1) - 1
#
my %oeis_anum = (C   => 'A000108',
                 odd => 'A098597', # Catalan odd part, divide out powers-of-2
                 # OEIS-Catalogue: A000108
                 # OEIS-Catalogue: A098597 values_type=odd
                );
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum{$self->{'values_type'}};
}


#------------------------------------------------------------------------------

use constant 1.02 _UV_I_LIMIT => do {
  my $uv_max = ~0 >> 1;
  ### $uv_max
  my $value = 1;
  my $i = 1;
  for (; $i++; ) {
    ### at: "i=$i value=$value"
    my $mul = 2*(2*$i-1);
    my $div = $i+1;
    if ($value > ($uv_max - ($uv_max%$mul)) / $mul) {
      last;
    }
    $value *= $mul;
    $value /= $div;
  }
  ### _UV_I_LIMIT: $i
  ### $value
  $i
};

# use constant _NV_LIMIT => do {
#   my $f = 1.0;
#   my $max;
#   for (;;) {
#     $max = $f;
#     my $l = 2.0*$f;
#     my $h = 2.0*$f+2.0;
#     $f = 2.0*$f + 1.0;
#     $f = sprintf '%.0f', $f;
#     last unless ($f < $h && $f > $l);
#   }
#   ### uv : ~0
#   ### 53  : 1<<53
#   ### $max
#   $max
# };


# C(0) = 0!/(0!*1!) = 1
# C(1) = 2!/(1!*2!) = 1
# C(2) = 4!/(2!*3!) = 4/2 = 2
sub rewind {
  my ($self) = @_;
  ### Catalan rewind()
  $self->{'i'} = $self->i_start;
  $self->{'f'} = 1;
}
sub seek_to_i {
  my ($self, $i) = @_;
  $self->{'i'} = $i;
  $self->{'f'} = $self->ith($i-1);
}
# sub _UNTESTED__seek_to_value {
#   my ($self, $value) = @_;
#   my $i = $self->{'i'} = $self->value_to_i_ceil($value);
#   $self->{'f'} = $self->ith($i);
# }

# C(i) = C(i-1) * 2i(2i-1) / i*(i+1)
#      = C(i-1) * 2(2i-1) / (i+1)
# at i=0 mul 2*(2i+1)=2
#        div 1
sub next {
  my ($self) = @_;
  ### Catalan next() ...

  my $i = $self->{'i'}++;
  if ($i == _UV_I_LIMIT) {
    $self->{'f'} = Math::NumSeq::_to_bigint($self->{'f'});
  }
  if ($i) {
    if ($self->{'values_type'} eq 'odd') {
      $self->{'f'} *= (2*$i-1);
      my $div = $i+1;
      until ($div & 1) {
        $div >>= 1;
      }
      ### next f: $self->{'f'} / $div
      ### assert: ($self->{'f'} % $div) == 0
      $self->{'f'} /= $div;

    } else {
      $self->{'f'} *= 2*(2*$i-1);
      ### next f: $self->{'f'} / ($i+1)
      ### assert: ($self->{'f'} % ($i+1)) == 0
      $self->{'f'} /= ($i+1);
    }
  }

  return ($i, $self->{'f'});
}

sub ith {
  my ($self, $i) = @_;
  ### Catalan ith(): $i

  if (_is_infinite($i)) {
    return $i;
  }

  my $value;
  if (! ref $i && $i >= _UV_I_LIMIT) {
    ### use bigint ...
    $value = Math::NumSeq::_to_bigint(1);
  } else {
    $value = ($i*0) + 1;   # inherit bignum 1
  }

  if ($self->{'values_type'} eq 'odd') {
    foreach my $k (1 .. $i) {
      $value *= (2*$k-1);
      my $div = $k+1;
      until ($div & 1) { $div >>= 1 }
      ### assert: ($value % $div) == 0
      $value /= $div;
    }
  } else {
    foreach my $k (1 .. $i) {
      $value *= 2*(2*$k-1);
      ### assert: ($value % ($k+1)) == 0
      $value /= ($k+1);
    }
  }

  ### $value
  return $value;
}

#     i=0  i=1   i=2   i=3   i=4   i=5
#          2*1   2*3   2*5   2*7   2*9
# C =    * --- * --- * --- * --- * ---
#           2     3     4     5     6
#     C=1  C=1   C=2   C=5   C=14   C=42
#                             =2*7   =14*3
#
# C(5) = 42 = 14 * 2*(2*5-1)/6
#
# sub pred {
#   my ($self, $value) = @_;
#   ### Catalan pred(): $value
# 
#   # NV inf or nan gets $value%$i=nan and nan==0 is false.
#   # Math::BigInt binf()%$i=0 so would go into infinite loop
#   # hence explicit check against _is_infinite()
#   #
#   if (_is_infinite($value)) {
#     return undef;
#   }
# 
#   for (my $i = 2; ; $i++) {
#     ### at: "i=$i value=$value  mul ".($i+1)." div ".(2*(2*$i-1))
#     if ($value <= 1) {
#       return ($value == 1);
#     }
#     $value *= ($i+1);
#     my $div = 2*(2*$i-1);
#     if ($value % $div) {
#       ### not divisible, false: "value=$value div=$div"
#       return 0;
#     }
#     $value /= $div;
#   }
# }
# =item C<$bool = $seq-E<gt>pred($value)>
# 
# Return true if C<$value> is a factorial, ie. equal to C<1*2*...*i> for
# some i.


# sub _UNTESTED__value_to_i {
#   my ($self, $value) = @_;
# 
#   if (_is_infinite($value)) {
#     return undef;
#   }
#   my $i = 1;
#   for (;;) {
#     if ($value <= 1) {
#       return $i;
#     }
#     $i++;
#     if (($value % $i) == 0) {
#       $value /= $i;
#     } else {
#       return 0;
#     }
#   }
# }

# sub _UNTESTED__value_to_i_floor {
#   my ($self, $value) = @_;
#   if (_is_infinite($value)) {
#     return $value;
#   }
#   if ($value < 2) {
#     return $self->i_start;
#   }
# 
#   # "/" operator converts 64-bit UV to an NV and so loses bits, making the
#   # result come out 1 too small sometimes.  Experimental switch to BigInt to
#   # keep precision.
#   #
#   if (! ref $value && $value > _NV_LIMIT) {
#     $value = Math::NumSeq::_to_bigint($value);
#   }
# 
#   my $i = 2;
#   for (;; $i++) {
#     ### $value
#     ### $i
# 
#     $value *= ($i+1);
#     my $mul = 2*(2*$i-1);
#     if ($value < $mul) {
#       return $i-1;
#     }
#     $value = int($value/$mul);
#   }
# }

# # ENHANCE-ME: should be able to notice rounding in $value/$i divisions of
# # value_to_i_floor(), rather than multiplying back.
# #
# sub _UNTESTED__value_to_i_ceil {
#   my ($self, $value) = @_;
#   if ($value < 0) { return 0; }
#   my $i = $self->value_to_i_floor($value);
#   if ($self->ith($i) < $value) {
#     $i += 1;
#   }
#   return $i;
# }


#--------
# Stirling approximation to n!
# n! ~= sqrt(2pi*n) * binomial(n,e)^n
# log(i!) ~= i*log(i) - i
#
# noted by Dan Fux in A000108 gives
#   C(n) ~= 4^n / (sqrt(pi*n)*(n+1))
# 
# log((2i)!/(i!(i+1)!))
#    ~= (2i*log(2i) - 2i) - (i*log(i) - i) - ((i+1)*log(i+1) - i+1)
#     = 2i*log(2i) - 2i - i*log(i) + i - (i+1)*log(i+1) + i+1
#     = 2i*log(2i) - i*log(i) - (i+1)*log(i+1) + 1
#     = 2i*(log(2)+log(i)) - i*log(i) - (i+1)*log(i+1) + 1
#     = 2i*log(2) + 2i*log(i) - i*log(i) - (i+1)*log(i+1) + 1
#     = 2i*log(2) + (2i-i)*log(i) - (i+1)*log(i+1) + 1
#    ~= 2i*log(2) + (2i-i-i-1)*log(i) + 1
#     = 2i*log(2) - log(i) + 1
#
# f(x) = 2x*log(2) - log(x) + 1 - t
# f'(x) = 2log(2) - log(x)
# sub = f(x) / f'(x)
#     = (2x*log(2) - log(x) + 1 - t) / (2log(2) - log(x))
# new = x - sub
#     = x - (2x*log(2) - log(x) + 1 - t) / (2log(2) - log(x))
#     = ( - x*log(x) + log(x) - 1 + t) / (2log(2) - log(x))
#     = ((1-x)*log(x) - 1 + t) / (2log(2) - log(x))
#
# start x=t
# new1 = 
# new2 =
#------
#
# f(x) = 4^x / (sqrt(Pi * x) * (x + 1)) - targ
# f'(x) = (((((((4 ^ x) * 1.38629436111989) * ((3.14 * x) ^ 0.5)) - ((4 ^ x) * ((0.5 * ((3.14 * x) ^ 0.5)) * (3.14 / (3.14 * x))))) / (3.14 * x)) * (1 + x)) - ((4 ^ x) / ((3.14 * x) ^ 0.5))) / ((1 + x) ^ 2)
#       = ((((((4^x * 1.38629436111989) * sqrt(pi*x)) - (4^x * (0.5 * sqrt(pi*x) * 1/x))) / (pi*x)) * (1 + x)) - ((4^x) / (sqrt(pi*x)))) / ((1 + x) ^ 2)

# ENHANCE-ME: slightly off for small values, but for big the 4^n dominates
sub value_to_i_estimate {
  my ($self, $value) = @_;
  ### value_to_i_estimate: $value

  if ($value <= 1) {
    return 0;
  }
  if ($value <= 3) {
    return 1;
  }

  my $i = _blog2_estimate($value);
  unless (defined $i) {
    $i = log($value) * (1/log(2));
  }
  $i /= 2;

  return int($i);
}

1;
__END__

=for stopwords Ryde Math-NumSeq ie num2s

=head1 NAME

Math::NumSeq::Catalan -- Catalan numbers (2n)! / (n!*(n+1)!)

=head1 SYNOPSIS

 use Math::NumSeq::Catalan;
 my $seq = Math::NumSeq::Catalan->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The Catalan numbers

    C(n) = binomial(2n,n) / (n+1)
         = (2n)! / (n!*(n+1)!)

    1, 1, 2, 5, 14, 42, 132, 429, 1430, 4862, 16796, ...  (A000108)
    starting i=0

From the factorial expression it can be seen the values grow roughly as a
power-of-4,

    C(i) = C(i-1) * (2i)*(2i-1) / (i*(i+1))
    C(i) = C(i-1) * 2*(2i-1)/(i+1)
         < C(i-1) * 4

=head2 Odd

Option C<values_type =E<gt> "odd"> can give just the odd part of each
number, ie. with factors of 2 divided out,

    values_type => "odd"

    1, 1, 1, 5, 7, 21, 33, 429, 715, 2431, 4199, ...  (A098597)
    starting i=0

The number of 2s in C(i) is

    num2s = (count-1-bits of i+1) - 1

The odd part is always monotonically increasing.  When i increments num2s
increases by at most 1, ie. a single factor of 2.  In the formula above

    C(i) = C(i-1) * 2*(2i-1)/(i+1)

it can be seen that C(i) gains at least 1 factor of 2, so after dividing out
2^num2s it's still greater than C(i-1).

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::Catalan-E<gt>new ()>

=item C<$seq = Math::NumSeq::Catalan-E<gt>new (values_type =E<gt> $str)>

Create and return a new sequence object.

=back

=head2 Iterating

=over

=item C<$seq-E<gt>seek_to_i($i)>

Move the current sequence position to C<$i>.  The next call to C<next()>
will return C<$i> and its corresponding value.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the C<$i>'th value.

=item C<$i = $seq-E<gt>value_to_i_estimate($value)>

Return an estimate of the i corresponding to C<$value>.

The current code is based on

    C(n) ~= 4^n / (sqrt(pi*n)*(n+1))

but ignoring the denominator there and so simply taking

    C(n) ~= 4^n
    hence i ~= log4(value)

The 4^n term dominates for medium to large C<$value> (for both plain and
"odd").

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Factorials>,
L<Math::NumSeq::BalancedBinary>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2016, 2018, 2019, 2020 Kevin Ryde

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

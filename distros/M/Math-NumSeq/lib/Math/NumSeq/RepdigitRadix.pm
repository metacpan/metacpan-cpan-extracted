# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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


# ENHANCE-ME: ith() might be a touch faster than next() now, perhaps
# something sieve/flag in next()


package Math::NumSeq::RepdigitRadix;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 74;
use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::NumAronson;
*_round_down_pow = \&Math::NumSeq::NumAronson::_round_down_pow;

use Math::Factor::XS 0.40 'factors'; # version 0.40 for factors() on BigInt

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Repdigit Radix');
use constant description => Math::NumSeq::__('First radix in which i is a repdigit (at most base=i-1 since otherwise "11" would always give i).');
use constant characteristic_smaller => 1;
use constant characteristic_increasing => 0;
use constant characteristic_integer => 1;
use constant characteristic_value_is_radix => 1;
sub values_min {
  my ($self) = @_;
  return ($self->i_start >= 3 ? 2 : 0);
}
sub i_start {
  my ($self) = @_;
  return $self->{'i_start'} || 0;
}

# smallest base in which n is a repdigit, starting n=3
sub oeis_anum { 'A059711' }
# OEIS-Catalogue: A059711 i_start=3


# d * (b^3 + b^2 + b + 1) = i
# b^3 + b^2 + b + 1 = i/d
# (b+1)^3 = b^3 + 3b^2 + 3b + 1
#
# (b-1) * (b^3 + b^2 + b + 1) = b^4 - 1
#
# 8888 base 9 = 6560
# 1111 base 10

# b^2 + b + 1 = k
# (b+0.5)^2 + .75 = k
# (b+0.5)^2 = (k-0.75)
# b = sqrt(k-0.75)-0.5;

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  $self->{'ones'}   = [ undef, undef, 7 ];
  $self->{'digits'} = [ undef, undef, 1 ];
  ### rewind to: $self
}

# (r+1)^2 + (r+1) + 1
#   = r^2 + 2r + 1 + r +1 + 1
#   = r^2 + 3r + 3
#   = (r + 3)*r + 3

#            0  1  2
my @small = (2, 0, 0);

sub next {
  my ($self) = @_;
  ### RepdigitRadix next(): $self->{'i'}

  my $i = $self->{'i'}++;
  my $ones = $self->{'ones'};
  my $digits = $self->{'digits'};

  if ($i < 3) {
    return ($i, $small[$i]);
  }

  for (my $radix = 2; ; $radix++) {
    ### $radix
    ### ones: $ones->[$radix]
    ### digit: $digits->[$radix]

    my $one;
    if ($radix > $#$ones) {
      ### maybe extend array: $radix
      $one = $radix + 1;  # or three digits ... ($radix + 1) * 
      unless ($one <= $i) {
        ### not repdigit of 3 digits in any radix, take as 2 digits ...
        return ($i, $i-1);
      }
      $ones->[$radix] = $one;
      $digits->[$radix] = 1;

    } else {
      $one = $ones->[$radix];
    }

    my $repdigit = $one * $digits->[$radix];
    while ($repdigit < $i) {
      my $digit = ++$digits->[$radix];
      if ($digit >= $radix) {
        $digit = $digits->[$radix] = 1;
        $one = $ones->[$radix] = ($one * $radix + 1);
      }
      $repdigit = $one * $digit;
    }
    ### consider repdigit: $repdigit
    if ($repdigit == $i) {
      ### found radix: $radix
      return ($i, $radix);
    }
  }
}

# d=r-1
# v = d*(r^(len-1)+...+1)
#   = r^len-1
# dlimit = nthroot(v+1, len)
#
# q=v/d
# q=r^(len-1)+...+1
# q > r^(len-1)    # when len>2
# r < nthroot(q, len-1)  

sub ith {
  my ($self, $i) = @_;
  ### RepdigitRadix ith(): $i
  if ($i < 0) {
    $i = abs($i);
  }
  if ($i < 3) {
    return $small[$i];
  }
  if ($i > 0xFFFF_FFFF) {
    return undef;
  }
  if (_is_infinite($i)) {
    return $i; # nan
  }

  my @factors = reverse (1, factors($i));
  ### @factors

  my ($pow, $len) = _round_down_pow ($i, 2);
  $len++;
  ### initial len: $len

  my $r_found;
  for ( ; $len >= 3; $len--) {
    my $d_limit = (defined $r_found ? $r_found-1 : _nth_root_floor($i+1,$len));
    ### $len
    ### $d_limit

    foreach my $d (grep {$_<=$d_limit} @factors) {  # descending order
      ### try d: $d

      # if ($d > $d_limit) {
      #   ### stop for d > d_limit ...
      #   last;
      # }

      my $q = $i / $d;
      my $r = _nth_root_floor($q,$len-1);
      ### $q
      ### $r
      ### ones: ($r**$len - 1) / ($r-1)

      if (defined $r_found && $r >= $r_found) {
        ### stop at r >= r_found ...
        last;
      }

      if ($r <= $d) {
        ### r smaller than d ...
        # since d>=1 this also excludes r<2
        next;
      }

      if ($q == ($r**$len - 1) / ($r-1)) {
        $r_found = $r;
      }
    }
  }

  my $d_limit = (defined $r_found ? $r_found-1 : int(sqrt($i+1)));
  foreach my $d (grep {$_<=$d_limit} @factors) {  # descending order
    ### try d: $d

    # v = d*(r+1)
    # v/d = r+1
    # r = v/d - 1
    #
    my $r = $i/$d - 1;
    ### $r

    if (defined $r_found && $r >= $r_found) {
      ### stop at r >= r_found ...
      last;
    }

    if ($r <= $d) {
      ### r smaller than d ...
      # since d>=1 this also excludes r<2
      next;
    }

    $r_found = $r;
  }

  return (defined $r_found ? $r_found : $i-1);


  # for (my $radix = 2; ; $radix++) {
  #   ### $radix
  # 
  #   my $one = $radix + 1;  # ... or 3 digits 111 ($radix + 1) *
  #   unless ($one <= $i) {
  #     ### stop at ones too big not a 3-digit repdigit: $one
  #     return $i-1;
  #   }
  #   ### $one
  # 
  #   do {
  #     if ($one == $i) {
  #       return $radix;
  #     }
  #     foreach my $digit (2 .. $radix-1) {
  #       ### $digit
  #       if ((my $repdigit = $digit * $one) <= $i) {
  #         if ($repdigit == $i) {
  #           return $radix;
  #         }
  #       }
  #     }
  #   } while (($one = $one * $radix + 1) <= $i);
  # }
}

# value = root^power
# log(value) = power*log(root)
# log(root) = log(value)/power
# root = exp(log(value)/power)
#
sub _nth_root_floor {
  my ($value, $power) = @_;
  my $root = int (exp (log($value)/$power));
  if ($root**$power > $value) {
    return $root-1;
  }
  if (($root+1)**$power < $value) {
    return $root+1;
  }
  return $root;
}

# R^2+R+1
# R=65 "111"=4291
#
# Does every radix occur?  Is it certain that at least one repdigit in base
# R is not a repdigit in anything smaller?
#
# sub pred {
#   my ($self, $value) = @_;
#   return ($value == int($value)
#           && ($value == 0 || $value >= 2));
# }

1;
__END__

=for stopwords Ryde radix repdigit repdigits len radices ie repunit nthroot Math-NumSeq

=head1 NAME

Math::NumSeq::RepdigitRadix -- radix in which i is a repdigit

=head1 SYNOPSIS

 use Math::NumSeq::RepdigitRadix;
 my $seq = Math::NumSeq::RepdigitRadix->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The radix in which i is a repdigit,

    2, 0, 0, 2, 3, 4, 5, 2, 3, 8, 4, 10, etc
    starting i=0

i=0 is taken to be a repdigit "00" in base 2.  i=1 and i=2 are not repdigits
in any radix.  Then i=3 is repdigit "11" in base 2.  Any iE<gt>=3 is at
worst a repdigit "11" in base i-1, but may be a repdigit in a smaller base.
For example i=8 is "22" in base 3.

Is this behaviour for i=0,1,2 any good?  Perhaps it will change.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::RepdigitRadix-E<gt>new ()>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the radix in which C<$i> is a repdigit.

The current code relies on factorizing C<$i> and a hard limit of 2**32 is
placed on C<$i> in the interests of not going into a near-infinite loop.

=back

=head1 FORMULAS

=head2 ith() Value

C<ith()> looks for the smallest radix r for which there's a digit d and
length len satisfying

    i = d * repunit(len)
    i = d * (r^(len-1) + r^(len-2) + ... + r^2 + r + 1)

The current approach is to consider repdigit lengths successively from
log2(i) downwards and candidate digits d from among the divisors of i.

    for len=log2(i) down to 2
      for d each divisor of i, descending
        r = nthroot(i/d, len-1)
        if r >= r_found then next len
        if r <= d then next divisor
        if (r^len-1)/(r-1) == i/d then r_found=r, next len

    if no r_found then r_found = i-1

For a given d the radix r to give i would be

    i/d = r^(len-1) + ... + r + 1

but it's enough to calculate

    i/d = r^(len-1)
    r = floor nthroot(i/d, len-1)

and then power up to see if it gives the desired i/d.

    repunit(len) = r^(len-1) + ... + r + 1
                 = (r^len - 1) / (r-1)
    check if equals i/d

floor(nthroot()) is never too small, since an r+1 from it would give

    (r+1)^(len-1) = r^(len-1) + binomial*r^(len-2) + ... + 1
                  > r^(len-1) +          r^(len-2) + ... + 1

Divisors are taken in descending order so the radices r are in increasing
order.  So if a repdigit is found in a given len then it's the smallest of
that length and can go on to other lengths.

The lengths can be considered in any order but the current code goes from
high to low since a bigger length means a smaller maximum radix within that
length (occurring when d=1, ie. a repunit), so it might establish a smaller
"r_found" and a smaller r_found limits the number of divisors to be tried in
subsequent lengths.  But does that actually happen often enough to make any
difference?

=head2 ith() Other Possibilities

When len is even the repunit part r^(len-1)+...+1 is a multiple of r+1.  Can
that cut the search?  For a given divisor the r is found easily enough by
nthroot, but maybe i with only two prime factors can never be an even
lengthE<gt>=4 repdigit, or something like that.

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::RepdigitAny>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

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

#!/usr/bin/perl -w

# Copyright 2012, 2013 Kevin Ryde

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


use 5.010;
use strict;
use List::Util 'min', 'max';
use Math::PlanePath::FactorRationals;

# uncomment this to run the ### lines
use Smart::Comments;

{
  foreach my $n (1 .. 20) {
    print Math::PlanePath::FactorRationals::_pos_to_pn__negabinary($n),",";
  }
  exit 0;
}

{
  # different pos=49 numbers got=69 want=88, and more diff
  # N=50 = 5*5*2
  my $path = Math::PlanePath::FactorRationals->new;
  foreach my $x (1 .. 50) {
    my $n = $path->xy_to_n(1,$x);
    print "$x   $n\n";
  }
  exit 0;
}


# Return ($good, $prime,$exp, $prime,$exp,...).
# $good is true if a full factorization is found.
# $good is false if cannot factorize because $n is too big or infinite.
#
# If $n==0 or $n==1 then there are no prime factors and the return is
# $good=1 and an empty list of primes.
#
sub INPROGRESS_prime_factors_and_exps {
  my ($n) = @_;
  ### _prime_factors(): $n

  unless ($n >= 0) {
    return 0;
  }
  if (_is_infinite($n)) {
    return 0;
  }

  # if ($n <= 0xFFFF_FFFF) {
  #   return (1, prime_factors($n));
  # }

  my @ret;
  unless ($n % 2) {
    my $count = 0;
    do {
      $count++;
      $n /= 2;
    } until ($n % 2);
    push @ret, 2, $count;
  }

  # Stop at when prime $p reaches $limit and when no prime factor has been
  # found for the last 20 attempted $p.  Stopping only after a run of no
  # factors found allows big primorials 2*3*5*7*13*... to be divided out.
  # If the divisions are making progress reducing $i then continue.
  #
  # Would like $p and $gap to count primes, not just odd numbers.  Perhaps
  # a table of small primes.  The first gap of 36 odds between primes
  # occurs at prime=31469.  cf A000230 smallest prime p for gap 2n.

  my $limit = 10_000 / (_blog2_estimate($n) || 1);
  my $gap = 0;
  for (my $p = 3; $gap < 36 || $p <= $limit ; $p += 2) {
    if ($n % $p) {
      $gap++;
    } else {
      do  {
        ### prime: $p
        $n /= $p;
        push @ret, $p;
      } until ($n % $p);

      if ($n <= 1) {
        ### all factors found ...
        return (1, @ret);
      }
      # if ($n < 0xFFFF_FFFF) {
      #   ### remaining factors by XS ...
      #   return (1, @ret, prime_factors($n));
      # }
      $gap = 0;
    }
  }
  return 0;  # factors too big
}

{
  my @primes = (2,3,5,7);
  sub _extend_primes {
    for (my $p = $primes[-1] + 2; ; $p += 2) {
      if (_is_prime($p)) {
        push @primes, $p;
        return;
      }
    }
  }
  sub _is_prime {
    my ($n) = @_;
    my $limit = int(sqrt($n));
    for (my $i = 0; ; $i++) {
      if ($i > $#primes) { _extend_primes(); }
      my $prime = $primes[$i];
      if ($n % $prime == 0) { return 0; }
      if ($prime > $limit) { return 1; }
    }
  }

  # $aref is an arrayref of prime exponents, [a,b,c,...]
  # Return their product 2**a * 3**b * 5**c * ...
  #
  sub _factors_join {
    my ($aref, $zero) = @_;
    ### _factors_join(): $aref
    my $n = $zero + 1;
    for (my $i = 0; $i <= $#$aref; $i++) {
      if ($i > $#primes) { _extend_primes(); }
      $n *= ($primes[$i] + $zero) ** $aref->[$i];
    }
    ### join: $n
    return $n;
  }

  # Return an arrayref of prime exponents of $n.
  # Eg. [a,b,c,...] for $n == 2**a * 3**b * 5**c * ...
  sub _factors_split {
    my ($n) = @_;
    ### _factors_split(): $n
    my @ret;
    for (my $i = 0; $n > 1; $i++) {
      if ($i > 6541) {
        ### stop, primes too big ...
        return;
      }
      if ($i > $#primes) { _extend_primes(); }

      my $count = 0;
      while ($n % $primes[$i] == 0) {
        $n /= $primes[$i];
        $count++;
      }
      push @ret, $count;
    }
    return \@ret;
  }

  # ### f: 2*3*3*5*19
  # ### f: _factors_split(2*3*3*5*19)
  # ### f: _factors_join(_factors_split(2*3*3*5*19),0)


  # factor_coding => 'spread'

  # "spread"
  # if ($self->{'factor_coding'} eq 'spread') {
  #   # N = 2^e1 * 3^e2 * 5^e3 * 7^e4 * 11^e5 * 13^e6 * 17^e7
  #   # X = 2^e1 * 3^e3 * 5^e5 * 7^e7,  Y = 1
  #   #
  #   # X = 2^e1        * 5^e5          e3=0,e7=0
  #   # Y =        3^e2        * 7^e4
  #   #
  #   # X=1,0,1
  #   # Y=0,0,0
  #   # 22 = 1,0,0,0,1
  #   # num = 1,0,1 = 2*5 = 10
  #   #
  #   my $xexps = _factors_split($x)
  #     or return undef;  # overflow
  #   my $yexps = _factors_split($y)
  #     or return undef;  # overflow
  #   ### $xexps
  #   ### $yexps
  #
  #   my @nexps;
  #   my $denpos = -1; # to store first at $nexps[1]
  #   while (@$xexps || @$yexps) {
  #     my $xexp = shift @$xexps || 0;
  #     my $yexp = shift @$yexps || 0;
  #     ### @nexps
  #     ### $xexp
  #     ### $yexp
  #     push @nexps, $xexp, 0;
  #     if ($xexp) {
  #       if ($yexp) {
  #         ### X,Y common factor ...
  #         return undef;
  #       }
  #     } else {
  #       ### den store to: "denpos=".($denpos+2)."  yexp=$yexp"
  #       $nexps[$denpos+=2] = $yexp;
  #     }
  #   }
  #   ### @nexps
  #   return (_factors_join(\@nexps, $x*0*$y));
  #
  # } els

  # if ($self->{'factor_coding'} eq 'spread') {
  #   # N = 2^e1 * 3^e2 * 5^e3 * 7^e4 * 11^e5 * 13^e6 * 17^e7
  #   # X = 2^e1 * 3^e3 * 5^e5 * 7^e7,  Y = 1
  #   #
  #   # X = 2^e1        * 5^e5          e3=0,e7=0
  #   # Y =        3^e2        * 7^e4
  #   #
  #   # 22 = 1,0,0,0,1
  #   # num = 1,0,1 = 2*5 = 10
  #   # den = 0
  #   #
  #   my $nexps = _factors_split($n)
  #     or return;  # too big
  #   ### $nexps
  #   my @dens;
  #   my (@xexps, @yexps);
  #   while (@$nexps || @dens) {
  #     my $exp = shift @$nexps;
  #     if (@$nexps)  {
  #       push @dens, shift @$nexps;
  #     }
  #
  #     if ($exp) {
  #       ### to num: $exp
  #       push @xexps, $exp;
  #       push @yexps, 0;
  #     } else {
  #       ### zero take den: $dens[0]
  #       push @xexps, 0;
  #       push @yexps, shift @dens;
  #     }
  #   }
  #   ### @xexps
  #   ### @yexps
  #   return (_factors_join(\@xexps,$zero),
  #           _factors_join(\@yexps,$zero));
  #
  # } else
}

{
  # reversing binary, max factor=3
  # 0 0  0  fac=0
  # 1 1  1  fac=1
  # 2 2  2  fac=1
  # 3 -1  3  fac=3
  # 4 4  4  fac=
  # 5 -3  5  fac=
  # 6 -2  6  fac=3
  # 7 3  7  fac=
  # 8 8  8  fac=
  # 9 -7  9  fac=
  # 10 -6  10  fac=
  # 11 7  11  fac=
  # 12 -4  12  fac=3
  # 13 5  13  fac=
  # 14 6  14  fac=
  # 15 -5  15  fac=3
  # 16 16  16  fac=

  my $max_fac = 0;
  foreach my $n (0 .. 2**20) {
    my $pn = Math::PlanePath::FactorRationals::_pos_to_pn__revbinary($n);
    my $ninv = Math::PlanePath::FactorRationals::_pn_to_pos__revbinary($pn);

    my $fac = $n / abs($pn||1);
    if ($fac >= $max_fac) {
      $max_fac = $fac;
    } else {
      $fac = '';
    }
    print "$n $pn  $ninv  fac=$fac\n";

    die unless $ninv == $n;
  }
  print "\n";
  exit 0;
}

{
  # negabinary, max factor approach 5
  my %rev;
  my $max_fac = 0;
  foreach my $n (0 .. 2**20) {
    my $power = 1;
    my $nega = 0;
    for (my $bit = 1; $bit <= $n; $bit <<= 1) {
      if ($n & $bit) {
        $nega += $power;
      }
      $power *= -2;
    }
    my $fnega = Math::PlanePath::FactorRationals::_pos_to_pn__negabinary($n);
    my $ninv = Math::PlanePath::FactorRationals::_pn_to_pos__negabinary($nega);

    my $fac = -$n / ($nega||1);
    if ($fac > $max_fac) {
      $max_fac = $fac;
      print "$n $nega   $fnega $ninv  fac=$fac\n";
    } else {
      $fac = '';
    }
    $rev{$nega} = $n;
  }
  print "\n";
  exit 0;
  foreach my $nega (sort {$a<=>$b} keys %rev) {
    my $n = $rev{$nega};
    print "$nega $n\n";
  }
  exit 0;
}

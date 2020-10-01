#!/usr/bin/perl -w

# Copyright 2012, 2019, 2020 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
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
use warnings;
use Math::PlanePath::SquareSpiral;
use Math::Prime::XS;
$|=1;

# uncomment this to run the ### lines
#use Smart::Comments;

{
  # A136626 num prime neighbours 8 directions
  my $path = Math::PlanePath::SquareSpiral->new;
  my @dir8_to_dx = (1,1, 0,-1, -1,-1, 0,1);
  my @dir8_to_dy = (0,1, 1,1,  0,-1, -1,-1);
  my $A136626 = sub {
    my ($n) = @_;
    my ($x,$y) = $path->n_to_xy($n);
    my $count = 0;
    if (Math::Prime::XS::is_prime($n)) { $count++; } # for A136627
    foreach my $dir (0 .. 7) {
      my $sn = $path->xy_to_n ($x+$dir8_to_dx[$dir], $y+$dir8_to_dy[$dir]);
      if (Math::Prime::XS::is_prime($sn)) { $count++; }
    }
    return $count;
  };
  my @seen;
  my $prev = 0;
  for (my $n = 1; ; $n++) {
    my $this = $n >> 14;
    if ($this != $prev) {
      print "$n\r";
      $prev = $this;
    }
    my $count = $A136626->($n);
    if (!$seen[$count]++) {
      print "$count at $n\n";
    }
  }
  exit 0;
}
{
  # A240025 L-system

  my %to;

  %to = (S => 'SFT+FT+',   # SquareSpiral
         T => 'FT',
         F => 'F',
         '+' => '+');

  %to = (S => 'STF+TF+',   # SquareSpiral2
         T => 'TF',
         F => 'F',
         '+' => '+');

  my $str = 'S';
  foreach (1 .. 7) {
    my $padded = $str;
    $padded =~ s/./$& /g;  # spaces between symbols
    print "$padded\n";
    $str =~ s{.}{$to{$&} // die}ge;
  }

  $str =~ s/F(?=[^+]*F)/F0/g;
  $str =~ s/F//g;
  $str =~ s/\+/1/g;
  $str =~ s/S/1/g;
  $str =~ s/T//g;
  print $str,"\n";

  require Math::NumSeq::OEIS;
  my $seq = Math::NumSeq::OEIS->new (anum => 'A240025');
  my $want = '';
  while (length($want) < length($str)) {
    my ($i,$value) = $seq->next;
    $want .= $value;
  }
  $str eq $want or die "oops, different";
  print "end\n";
  exit 0;
}
{
  # cf A002620 quarter squares  = floor(n^2/4) = (n^2-(n%2))/4
  # concat(vector(10,n,[n^2,n*(n+1)]))
  #
  # vector(10,n, (n^2-(n%2))/4)
  # q=(n^2-(n%2))/4
  # 4q = n^2 - (n%2)
  # n^2 = 4q + (n%2)
  # vector(20,n, ((n^2-(n%2))/4) % 4)
  # vector(20,n, n%2)
  # n*n = 0 or 1 mod 4
  # q = n*(n+1) = n*n + n = 0 or 2 mod 4
  # n^2 + n - q = 0
  # q=12
  # n = ( -1 + sqrt(4*q + 1) )/2
  #
  # a(n) = issquare(n) || issquare(4*n+1);
  # vector(20,n, (n^2)%8)    \\ 0,1, 4
  # for(n=1,10, print(n*n" "n*(n+1)))
  # for(n=1,20, print(n, "   ", (n*n)%4," ",(n*(n+1))%4 ))

  exit 0;
}

{
  my $path = Math::PlanePath::SquareSpiral->new;
  foreach my $n (1 .. 100) {
    my ($x,$y) = $path->n_to_xy($n);
    print "$x,";
  }

  # v=[0,1,1,0,-1,-1,-1,0,1,2,2,2,2,1,0,-1,-2,-2,-2,-2,-2,-1,0,1,2,3,3,3,3,3,3,2,1,0,-1,-2,-3,-3,-3,-3,-3,-3,-3,-2,-1,0,1,2,3,4,4,4,4,4,4,4,4,3,2,1,0,-1,-2,-3,-4,-4,-4,-4,-4,-4,-4,-4,-4,-3,-2,-1,0,1,2,3,4,5,5,5,5,5,5,5,5,5,5,4,3,2,1,0,-1,-2,-3,-4];
  # a(n) = if(n==1,'e,my(d=(2+sqrtint(4*n-7))\4); n--; n -= 4*d^2; \
  #   if(n>=0, if(n<=2*d, -d, n-3*d), if(n>=-2*d, -n-d, d)));
  # a(n) = my(d=(sqrtint(4*n-3)+1)\2); n -= d*d+1; \
  #   -(-1)^d * if(n>=0, d\2+1, d\2+n+1);

  # a(n) = my(d=ceil(sqrtint(n-1)/2)); n -= 4*d^2; \
  #   if(n<=0, if(n<=-2*d, d, 1-d-n), if(n<=2*d, -d, n-3*d-1));
  # a(n) = n--; my(k=ceil(sqrtint(n)/2)); n -= 4*k^2; \
  #   if(n<0, if(n<-2*k, k, -k-n), if(n<2*k, -k, n-3*k));
  #
  # a(n) = n--; my(m=sqrtint(n), k=ceil(m/2)); n -= 4*k^2; \
  #   if(n<0, if(n<-m, k, -k-n), if(n<m, -k, n-3*k));

  # vector(20,n,n+=20; a(n))
  # vector(#v,n, iferr(a(n),e,'e)) == v  /* OFFSET=1 */
  # 1,1,2,2,3,3,4,4
  # 1   3   7   13
  # vector(20,d, sum(i=1,d,2*i))
  # vector(20,d, d*(d-1)+1)
  # n-1 = d*(d-1)
  # d^2-d+(1-n) = 0
  # d = (1 + sqrt(1-4*(1-n)))/2
  #   = (1 + sqrt(4*n-3)))/2        # n>=1
  # e = 1+sqrtint(4*n-7)
  # vector(20,n, (1+sqrtint(4*n-3))\2)
  # vector(20,n, my(d=(1+sqrtint(4*n-3))\2); n-d*(d-1))


  exit 0;
}
{
  require Math::Prime::XS;
  my @primes = (0,
                Math::Prime::XS::sieve_primes (1000));
  my $path = Math::PlanePath::SquareSpiral->new;

  foreach my $y (reverse -4 .. 4) {
    foreach my $x (-4 .. 4) {
      my $n = $path->xy_to_n($x,$y);
      my $p = $primes[$n] // '';
      printf " %4d", $p;
    }
    print "\n";
  }
  exit 0;
}

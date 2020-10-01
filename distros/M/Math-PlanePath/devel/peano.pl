#!/usr/bin/perl -w

# Copyright 2012, 2013, 2019, 2020 Kevin Ryde

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

use 5.004;
use strict;
use List::Util 'sum';
use Math::BaseCnv 'cnv';
use Math::PlanePath;
use Math::PlanePath::PeanoCurve;
use Math::PlanePath::PeanoDiagonals;
use Math::PlanePath::Base::Digits
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

# uncomment this to run the ### lines
use Smart::Comments;


{
  # PeanoDiagonals devel
  # N=15     33
  #          yx   y=3 x->0  yrev=1 xrev=0
  # N=125  1331

  my $n = 7;
  my $radix = 3;
  my $path = Math::PlanePath::PeanoDiagonals->new (radix => $radix);
  my ($x,$y) = $path->n_to_xy($n);
  ### xy: "$x, $y"
  ### $n
  ### cnv: cnv($n,10,$radix)

  $x = 1;
  $y = 1;
  my @n_list = $path->xy_to_n_list($x,$y);
  ### @n_list
  exit 0;
}
{
  # PeanoDiagonals arrows for Tikz

  my $radix = 4;
  my $path = Math::PlanePath::PeanoDiagonals->new (radix => $radix);
  my $prev_x = 0;
  my $prev_y = 0;
  foreach my $n (0 .. $radix**4-1) {
    my ($x1,$y1) = $path->n_to_xy($n+.1);
    my ($x2,$y2) = $path->n_to_xy($n+.9);
    printf "  \\fill (%.1f,%.1f) circle (.1); \\draw[my grey] (%.1f,%.1f) -- (%.1f,%.1f);\n",
      $x1,$y1, $prev_x,$prev_y, $x1,$y1;
    printf "  \\draw[->] (%.1f,%.1f) -- (%.1f,%.1f);\n",
      $x1,$y1, $x2,$y2;
    ($prev_x,$prev_y) = ($x2,$y2);
  }
  exit 0;
}

{
  # PeanoDiagonals devel

  my $plain = Math::PlanePath::PeanoCurve->new (radix => 4);
  my $diag  = Math::PlanePath::PeanoDiagonals->new (radix => 4);
  foreach my $n (0 .. 4**4) {
    my ($plain_x,$plain_y) = $plain->n_to_xy($n);
    my ($diag_x,$diag_y) = $diag->n_to_xy($n);
    printf "%6d %6d  %d %d   %3d %3d\n",
      $n, cnv($n,10,4), $diag_x-$plain_x, $diag_y-$plain_y,
      cnv($diag_x,10,4), cnv($diag_y,10,4);
  }
  exit 0;
}

# Uniform Grids
# 4.1-O  Wunderlich serpentine in diamond
#    bottom right between squares = Wunderlich Figure 3
#    top left across diagonals = Mandelbrot page 62
#
# 1.3-A  Peano squares starting X direction

{
  # PeanoDiagonals X axis
  # not in OEIS: 2,16,18,20,142,144,146,160,162,164,178,180,182,1276,1278
  # half
  # not in OEIS: 1,8,9,10,71,72,73,80,81,82,89,90,91,638,639,640,647

  # -----> <------ ------>
  #     3*9^k    6*9^k
  # base 9 digits 0,-2,2
  # xx(n) = my(v=digits(n,3)); v=apply(d->if(d==0,-2,d==1,0,d==2,2), v); fromdigits(v,9);
  # vector(20,n,xx(n))
  # Set(select(n->n>=0,vector(55,n,xx(n)))) == \
  # [0,2,16,18,20,142,144,146,160,162,164,178,180,182,1276,1278]

  my $path = Math::PlanePath::PeanoDiagonals->new;
  foreach my $x (0 .. 81) {
    my $n = $path->xy_to_n($x,0) // next;
    my $n3 = cnv($n,10,3);
    my $n9 = cnv($n,10,9);
    print "n=$n  $n3  $n9\n";
    # print $n/2,",";
  }
  print "\n";
  exit 0;
}

{
  # PeanoDiagonals other N
  my $path = Math::PlanePath::PeanoDiagonals->new;
  foreach my $n (1 .. 10) {
    my ($x,$y) = $path->n_to_xy($n);
    my @n_list = $path->xy_to_n_list($x,$y);
    @n_list <= 2 or die;
    my ($other) = grep {$_!=$n} @n_list;
    my $n3 = cnv($n,10,3);
    my $other3 = (defined $other ? cnv($other,10,3) : 'undef');
    my $delta = (defined $other ? abs($other - $n) : undef);
    my $delta3 = (defined $delta ? cnv($delta,10,3) : 'undef');
    my $by_func = PeanoDiagonals_other_n($n);
    my $by_func3 = (defined $by_func ? cnv($by_func,10,3) : 'undef');
    $by_func //= 'undef';
    my $diff = $other3 eq $by_func3 ? '' : '   ****';
    print "n=$n  $n3 other $other3 $by_func3$diff  d=$delta3\n";
  }
  print "\n";
  exit 0;

  sub PeanoDiagonals_other_n {
    my ($n) = @_;
    ### PeanoDiagonals_other_n(): $n
    my @digits = digit_split_lowtohigh($n,3);
    my $c = 0;
    for (my $i = 0; $c>0 || $i <= $#digits; $i++) {
      $c += $digits[$i] || 0;
      my $d = $c % 3;
      ### at: "i=$i c=$c is d=$d"
      if ($d == 1) {
        $c += 4;
        $digits[$i] = _divrem_mutate($c,3);
        $c += $digits[++$i] || 0;
        $digits[$i] = _divrem_mutate($c,3);
      } elsif ($d == 2) {
        $c -= 4;
        $digits[$i] = _divrem_mutate($c,3);
        $c += $digits[++$i] || 0;
        $digits[$i] = _divrem_mutate($c,3);
      } else {
        $digits[$i] = _divrem_mutate($c,3);
      }
    }
    ### final: "c=$c digits ".join(',',@digits)
    if ($c < 0) {
      return undef;
    }
    $digits[scalar(@digits)] = $c;
    return digit_join_lowtohigh(\@digits,3);
  }
}

{
  my $path = Math::PlanePath::PeanoCurve->new;
  foreach my $x (0 .. 20) {
    print $path->xy_to_n($x,0),",";
  }
  print "\n";
  foreach my $y (0 .. 20) {
    print $path->xy_to_n(0,$y),",";
  }
  print "\n";
  exit 0;
}

{
  # Mephisto Waltz Picture
  require Image::Base::GD;
  my $size = 3**6;
  my $scale = 1;
  my $width = $size*$scale;
  my $height = $size*$scale;

  my $transform = sub {
    my ($x,$y) = @_;
    $x *= $scale;
    $y *= $scale;
    return ($x,$height-1-$y);
  };

  my @dir4_to_dx = (1,0,-1,0);
  my @dir4_to_dy = (0,1,0,-1);

  my $path = Math::PlanePath::PeanoCurve->new;
  my $image = Image::Base::GD->new (-height => $height,
                                    -width  => $width);
  $image->rectangle(0,0, $width-1,$height-1, 'black');

  require Math::NumSeq::MephistoWaltz;
  my $seq = Math::NumSeq::MephistoWaltz->new;
  foreach my $n (0 .. $size**2) {
    my ($x,$y) = $path->n_to_xy($n);
    my $value = $seq->ith($n);
    if ($value) {
      ($x,$y) = $transform->($x,$y);
      $image->rectangle($x,$y, $x+$scale-1, $y-($scale-1), 'white', 1);
    }
  }
  my $filename = '/tmp/mephisto-waltz.png';
  $image->save($filename);
  require IPC::Run;
  IPC::Run::start(['xzgv',$filename],'&');
  exit 0;
}
{
  # Cf segment substitution per Wunderlich alternating

  #      2---3
  #      |   |
  #      /   /
  # *---1 5-4 8---*
  #      /   /
  #      |   |
  #      6---7
  # turn(n) = my(m=n/9^valuation(n,9)); [1, -1,-1,-1, 1, 1, 1, -1][m%9];
  # turn(n) = my(m=n/3^valuation(n,3)); (-1)^((m%3)+(n%3!=0));
  # vector(27,n,turn(n))
  # not A216430 only middle match
  # vector(100,n,turn(3*n))
  # vector(20,n,turn(n))
  # vector(20,n,(turn(n)+1)/2)
  # vector(20,n,(1-turn(n))/2)

  exit 0;
}
{
  # PeanoDiagonals Turns Morphism
  # turn(3*n))   == -turn(n)
  # turn(3*n+1)) == -(-1)^n
  # turn(3*n+2)) ==  (-1)^n

  # X = end of even
  # Y = end of odd
  my %expand = (X => 'X -FY +FX +FY +FX -FY -FX -FY +FX',
                Y => 'Y +FX -FY -FX -FY +FX +FY +FX -FY');
  %expand = (X => 'Y +FX -FY',     # applied an even number of times
             Y => 'X -FY +FX');
  %expand = (X => 'X -FY +FX ++',
             Y => 'Y +FX -FY ++');
  my $str = 'FX';
  foreach (1 .. 8) {
    $str =~ s{[XY]}{$expand{$&}}eg;
  }
  print substr($str,0,60),"\n";
  $str =~ s/[XY ]//g;
  $str =~ s/(\+\+)+$//;
  $str =~ s{[-+]+}{pm_str_net($&)}eg;
  $str =~ s/[^-+]//g;
  print substr($str,0,27),"\n";

  my $path = Math::PlanePath::PeanoDiagonals->new;
  require Math::NumSeq::PlanePathTurn;
  my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                              turn_type => 'LSR');
  my $max = 0;
  my $by_path = '';
  for (1 .. length($str)) {
    my ($i,$value) = $seq->next;
    my $c = $value > 0 ? '+' : '-';
    if ($i < 27) { print $c; }
    $by_path .= $c;
  }
  print "\n";
  $str eq $by_path or die;
  exit 0;

  sub pm_str_net {
    my ($str) = @_;
    my $net = 0;
    foreach my $c (split //, $str) {
      if ($c eq '+') { $net++; }
      elsif ($c eq '-') { $net--; }
      else { die $c; }
    }
    $net %= 4;
    if ($net == 1) { return '+'; }
    if ($net == 3) { return '-'; }
    die "net $net";
  }
}

{
  # turn LSR

  # plain:
  # signed 0,1,1,0,-1,-1,0,0,0,0,-1,-1,0,1,1,0,0,0,0,1,1,0,-1,-1,0,1,1,0,-1,-1,
  # signed 0,-1,-1,0,1,1,0,0,0,0,1,1,0,-1,-1,0,0,0,0,-1,-1,0,1,1,0,-1,-1,0,1,1,
  # ones  0,1,1,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,1,1,0,0,0,0,1,1,0,0,0,
  # zeros  1,0,0,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,0,0,1,1,1,1,0,0,1,1,1,

  # diagturn(n) = my(v=digits(n,3)); sum(i=1,#v,v[i]!=1)

  my $radix = 4;
  my $path;
  $path = Math::PlanePath::PeanoDiagonals->new;
  $path = Math::PlanePath::PeanoCurve->new (radix => $radix);
  require Math::NumSeq::PlanePathTurn;
  my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                              turn_type => 'LSR');
  my $max = 0;
  for (1 .. 80) {
    my ($i,$value) = $seq->next;
    my $got = n_to_turn_LSR($i, $radix);
    $got = _UNDOCUMENTED__n_to_turn_LSR($path,$i);

    my $i3 = cnv($i,10,$radix);
    my $diff = $got==$value ? '' : ' ***';
    printf "%2d %3s     %d %d%s\n", $i,$i3, $value, $got, $diff;
  }

  print "signed ";
  $seq->rewind;
  for (1 .. 30) {
    my ($i,$value) = $seq->next;
    print $value,",";
  }
  print "\n";

  print "signed ";
  $seq->rewind;
  for (1 .. 30) {
    my ($i,$value) = $seq->next;
    print -$value,",";
  }
  print "\n";

  print "ones  ";
  $seq->rewind;
  for (1 .. 30) {
    my ($i,$value) = $seq->next;
    print $value==1?1:0,",";
  }
  print "\n";

  print "zeros  ";
  $seq->rewind;
  for (1 .. 30) {
    my ($i,$value) = $seq->next;
    print $value==1?0:1,",";
  }
  print "\n";
  exit 0;
}

{
  # Diagonals Pattern

  my $path = Math::PlanePath::PeanoDiagonals->new;
  $path->xy_to_n(0,0);
  $path->xy_to_n(2,0);
  #  exit;
  my @slope;
  foreach my $n (0 .. 900) {
    my ($x,$y) = $path->n_to_xy($n);
    my ($x2,$y2) = $path->n_to_xy($n+1);
    my $dir = dxdy_to_dir8($x2-$x, $y2-$y);
    my $tx = $x+$x2;
    my $ty = $y+$y2;
    $slope[$tx]->[$ty] = $dir;
    if ($n < 10) {
      print "n=$n  $x,$y to $x2,$y2  for $tx,$ty   dir=$dir\n";
    }
  }
  print "1,1 is $slope[1]->[1]\n";
  foreach my $y (reverse 0 .. 27) {
    printf "y=%2d ", $y;
    # my $y = 2*$y+1;
    foreach my $x (0 .. 27) {
      # my $x = 2*$x+1;
      my $dir = $slope[$x]->[$y] // '';
      printf '%3s', $dir;
    }
    print "\n";
  }
  print "     ";
  foreach my $x (0 .. 27) {
    printf '%3s', $x;
  }
  print "\n";
  exit 0;


  # return 0..7
  sub dxdy_to_dir8 {
    my ($dx, $dy) = @_;
    return atan2($dy,$dx) / atan2(1,1);
    if ($dx == 1) {
      if ($dy == 1) { return 1; }
      if ($dy == 0) { return 0; }
      if ($dy == -1) { return 7; }
    }
    if ($dx == 0) {
      if ($dy == 1) { return 2; }
      if ($dy == -1) { return 6; }
    }
    if ($dx == -1) {
      if ($dy == 1) { return 3; }
      if ($dy == 0) { return 4; }
      if ($dy == -1) { return 5; }
    }
    die 'oops';
  }

}



#  8           60--61--62--63--64--65  78--79--80--...
#               |                   |   |
#  7           59--58--57  68--67--66  77--76--75
#                       |   |                   |
#  6     -1    54--55--56  69--70--71--72--73--74
#               |
#  5     -1    53--52--51  38--37--36--35--34--33
#                       |   |                   |
#  4           48--49--50  39--40--41  30--31--32
#               |                   |   |
#  3           47--46--45--44--43--42  29--28--27     +1
#                                               |
#  2            6---7---8---9--10--11  24--25--26     +1
#               |                   |   |
#  1            5---4---3  14--13--12  23--22--21
#                       |   |                   |
# Y=0           0---1---2  15--16--17--18--19--20
#                                   0   0
# +1 is low 0s to none
# 1000  1001
#
# 0 1 2 0 1 2 0 1 2 0 1 2 0
#     \-/   \-/   \-/   \-/
#
# GP-DEFINE  A163536(n) = {
# GP-DEFINE    if(n%3==2,n++);
# GP-DEFINE    if(valuation(n,3)%2, 2-(n%2), 0);
# GP-DEFINE  }
# my(v=OEIS_samples("A163536")); vector(#v,n, A163536(n)) == v
# OEIS_samples("A163536")
# vector(20,n, ceil(2*n/3))
# vector(20,n, valuation(n,3)%2)
# GP-DEFINE  A163536_b(n) = {
# GP-DEFINE    if(n%3==1,return(0));
# GP-DEFINE    my(m=ceil(2*(n+1)/3));
# GP-DEFINE    if(valuation(m\2,3)%2,0,2-(m\2)%2);
# GP-DEFINE  }
# my(v=OEIS_samples("A163536")); vector(#v,n, A163536_b(n)) == v
# vector(20,n, my(n=3*n-1, a=A163536(n)); if(a,-(-1)^a,0))
# vector(20,n, if(valuation(n,3)%2,0,-(-1)^n))
# for(n=1,27,my(n=n);print(n" "ceil(2*n/3)"  "A163536(n)" "A163536_b(n)))
# vector(20,n, A163536(n))
# vector(20,n, A163536(9*n))
# vector(20,n, A163536(81*n))
#
# GP-DEFINE  A163536_c(n) = {
# GP-DEFINE    if(n%3==1,return(0),
# GP-DEFINE       n%3==2,n++);
# GP-DEFINE    if(valuation(n,3)%2, 2-(n%2), 0);
# GP-DEFINE  }
# my(v=OEIS_samples("A163536")); vector(#v,n, A163536_c(n)) == v
# vector(20,n, A163536(n))
#
# 5 4  2 10
# 8 6  0 10
# 11 8  2 10
# 14 10  1 10
# 17 12  0 10
# 20 14  1 10
# 23 16  2 10
# 26 18  1 10
# 29 20  2 10
# 32 22  1 10
# 35 24  0 10
# 38 26  1 10
# 41 28  2 10
# 44 30  0 10
# 47 32  2 10
# 50 34  1 10
# 53 36  2 10
# 56 38  1 10
# 59 40  2 10
# 62 42  0 10
# 65 44  2 10
# 68 46  1 10
# 71 48  0 10
# 74 50  1 10
# 77 52  2 10
# 80 54  0 10
# 83 56  2 10

# In odd bases, the parity of sum(@digits) is the parity of $n itself,
# so no need for a full digit split (only examine the low end for low 0s).
#
sub _UNDOCUMENTED__n_to_turn_LSR {
  my ($self, $n) = @_;
  if ($n <= 0) {
    return undef;
  }
  my $radix = $self->{'radix'};
  {
    my $r = $n % $radix;
    if ($r == $radix-1) {
      $n++;                # ...222 and ...000 are same turns
    } elsif ($r != 0) {
      return 0;            # straight ahead across rows, turn only at ends
    }
  }
  my $z = 1;
  until ($n % $radix) {   # low 0s
    $z = !$z;
    $n /= $radix;
  }
  if ($z) { return 0; }    # even number of low zeros

  return (($radix & 1 ? sum(digit_split_lowtohigh($n,$radix)) : $n) & 1
          ? 1 : -1);
}

sub n_to_turn_LSR {
  my ($n,$radix) = @_;
  # {
  #   if ($n % $radix != 0
  #       && $n % $radix != $radix-1) {
  #     return 0;
  #   }
  #   # vector(20,n, ceil(2*n/3))
  #   # vector(20,n, floor((2*n+2)/3))
  #   $n = int((2*$n+2)/$radix);
  # }
  {
    if ($n % $radix == $radix-1) {
      $n++;
    } elsif ($n % $radix != 0) {
      return 0;
    }
    my @digits = digit_split_lowtohigh($n,$radix);
    my $turn = 1;
    while (@digits) {  # low to high
      last if $digits[0];
      $turn = -$turn;
      shift @digits;
    }
    if ($turn == 1) { return 0; }    # even number of low zeros
    return (sum(@digits) & 1 ? -$turn : $turn);
  }
  {
    if ($n % $radix == $radix-1) {
      $n++;
    } elsif ($n % $radix != 0) {
      return 0;
    }
    my $low = 0;
    my $z = $n;
    while ($z % $radix == 0) {
      $low = 1-$low;
      $z /= $radix;
    }
    if ($low == 0) {
      return 0;         # even num low 0s
    }
    return ($z % 2 ? 1 : -1);
  }
  {
    if ($n % $radix == $radix-1) {
      $n++;
    }
    while ($n % $radix**2 == 0) {
      $n /= $radix**2;
    }
    if ($n % $radix != 0) {
      return 0;
    }
    return diagonal_n_to_turn_LSR($n,$radix);
  }
  {
    my $turn = 1;
    my $turn2 = 1;
    my $m = $n;
    while ($m % $radix == $radix-1) {    # odd low 2s is -1
      $turn2 = -$turn2;
      $m = int($m/$radix);
    }
    my $z = $n;
    while ($z % $radix == 0) {    # odd low 0s is -1
      $turn = -$turn;
      $z /= $radix;
    }
    my $o = $n;

    if ($turn==$turn2) { return 0; }
    # return ($n % 2 ? 1 : -1);

    # my $opos = 0;
    # until ($o % 3 == 1) {    # odd low 0s is -1
    #   $opos = 1-$opos;
    #   $o = int($o/3);
    # }
    # if ($o==0) { return 0; }

    if ($n % 2) {            # flip one or other
      $turn = -$turn;
    } else {
      $turn2 = -$turn2;
    }
    return ($turn+$turn2)/2;
  }
  {
    return (diagonal_n_to_turn_LSR($n,$radix)
            + diagonal_n_to_turn_LSR($n+1,$radix))/2;
  }
}

{
  # X=Y diagonal
  my $path = Math::PlanePath::PeanoCurve->new;
  foreach my $i (0 .. 20) {
    my $n = $path->xy_to_n($i,$i);
    printf "i=%3d %4s  n=%3s %6s\n",
      $i,cnv($i,10,3),
      $n,cnv($n,10,3);
  }
  exit 0;
}

{
  # dx,dy on even radix
  require Math::BigInt;
  foreach my $radix (4, 2, 6, 8) {
    print "radix=$radix\n";
    my $path = Math::PlanePath::PeanoCurve->new (radix => $radix);
    my $limit = 4000000000;
    {
      my %seen_dx;
      for my $len (0 .. 8) {
        for my $high (1 .. $radix-1) {
          my $n = Math::BigInt->new($high);
          foreach (1 .. $len) { $n *= $radix; $n += $radix-1; }

          my ($dx,$dy) = $path->n_to_dxdy($n);
          $dx = abs($dx);
            my ($x,$y) = $path->n_to_xy($n);
            my $xr = cnv($x,10,$radix);
            my $dr = cnv($dx,10,$radix);
            my $nr = cnv($n,10,$radix);
            print "N=$n [$nr]  dx=$dx [$dr]  x=[$xr]\n";
          unless ($seen_dx{$dx}++) {
          }
        }
      }
    }
    {
      my %seen_dy;
      for my $len (0 .. 8) {
        for my $high (1 .. $radix-1) {
          my $n = Math::BigInt->new($high);
          foreach (1 .. $len) { $n *= $radix; $n += $radix-1; }

          my ($dx,$dy) = $path->n_to_dxdy($n);
          $dy = abs($dy);
          unless ($seen_dy{$dy}++) {
            my $dr = cnv($dy,10,$radix);
            my $nr = cnv($n,10,$radix);
            print "N=$n [$nr]  dy=$dy [$dr]\n";
          }
        }
      }
    }
    print "\n";
  }
  exit 0;
}

{
  # abs(dY) = count low 2-digits, mod 2
  # abs(dX) = opposite, 1-abs(dY)
  #                                        x x
  # vertical when odd number of low 2s  ..0222
  # N+1 carry propagates to change      ..1000
  #                                       y y
  # high y+1 complements x from 0->2 so X unchanged
  # Y becomes Y+1 02 -> 10, or if complement then Y-1 20 -> 12
  #
  my $radix = 3;
  require Math::PlanePath::PeanoCurve;
  require Math::NumSeq::PlanePathDelta;
  require Math::NumSeq::DigitCountLow;
  require Math::BigInt;
  my $path = Math::PlanePath::PeanoCurve->new (radix => $radix);
  my $seq = Math::NumSeq::PlanePathDelta->new (planepath_object => $path,
                                               delta_type => 'AbsdX');
  my $cnt = Math::NumSeq::DigitCountLow->new (radix => 3, digit => 2);
  foreach my $n (0 .. 40) {
    my ($dx,$dy) = $path->n_to_dxdy($n);
    my $absdx = abs($dx);
    my $absdy = abs($dy);
    my $c = $cnt->ith($n);
    my $by_c = $c & 1;
    my $diff = $absdy == $by_c ? '' : '  ***';

    # my $n = $n+1;
    my $nr = cnv($n,10,$radix);

    printf "%3d %7s  %2d,%2d  low=%d%s\n",
      $n, $nr, abs($dx),abs($dy), $c, $diff;
    # print "$n,";
    if ($absdx != 0) {
    }
  }
  exit 0;
}

{
  # Dir4 maximum
  my $radix = 6;
  require Math::PlanePath::PeanoCurve;
  require Math::NumSeq::PlanePathDelta;
  require Math::BigInt;
  my $path = Math::PlanePath::PeanoCurve->new (radix => $radix);
  my $seq = Math::NumSeq::PlanePathDelta->new (planepath_object => $path,
                                               delta_type => 'Dir4');
  my $dir4_max = 0;
  foreach my $n (0 .. 600000) {
    # my $n = Math::BigInt->new(2)**$level - 1;
    my $dir4 = $seq->ith($n);
    if ($dir4 > $dir4_max) {
      $dir4_max = $dir4;
      my ($dx,$dy) = $path->n_to_dxdy($n);
      my $nr = cnv($n,10,$radix);
      printf "%7s  %2b,\n    %2b %8.6f\n", $nr, abs($dx),abs($dy), $dir4;
    }
  }
  exit 0;
}

{
  # axis increasing
  my $radix = 4;
  my $rsquared = $radix * $radix;
  my $re = '.' x $radix;

  require Math::NumSeq::PlanePathN;
  foreach my $line_type ('Y_axis', 'X_axis', 'Diagonal') {
  OUTER: foreach my $serpentine_num (0 .. 2**$rsquared-1) {
      my $serpentine_type = sprintf "%0*b", $rsquared, $serpentine_num;
      # $serpentine_type = reverse $serpentine_type;
      $serpentine_type =~ s/($re)/$1_/go;
      ### $serpentine_type

      my $seq = Math::NumSeq::PlanePathN->new
        (
         planepath => "WunderlichSerpentine,radix=$radix,serpentine_type=$serpentine_type",
         line_type => $line_type,
        );
      ### $seq

      # my $path = Math::NumSeq::PlanePathN->new
      #   (
      #    e,radix=$radix,serpentine_type=$serpentine_type",
      #    line_type => $line_type,
      #   );

      my $prev = -1;
      for (1 .. 1000) {
        my ($i, $value) = $seq->next;
        if ($value <= $prev) {
          # print "$line_type $serpentine_type   decrease at i=$i  value=$value cf prev=$prev\n";
          # my $path = $seq->{'planepath_object'};
          # my ($prev_x,$prev_y) = $path->n_to_xy($prev);
          # my ($x,$y) = $path->n_to_xy($value);
          # # print "  N=$prev $prev_x,$prev_y  N=$value $x,$y\n";
          next OUTER;
        }
        $prev = $value;
      }
      print "$line_type $serpentine_type   all increasing\n";
    }
  }
  exit 0;
}

{
  # max Dir4

  my $radix = 4;

  print 4-atan2(2,1)/atan2(1,1)/2,"\n";

  require Math::NumSeq::PlanePathDelta;
  my $seq = Math::NumSeq::PlanePathDelta->new (planepath => "PeanoCurve,radix=$radix",
                                               delta_type => 'Dir4');
  my $dx_seq = Math::NumSeq::PlanePathDelta->new (planepath => "PeanoCurve,radix=$radix",
                                                  delta_type => 'dX');
  my $dy_seq = Math::NumSeq::PlanePathDelta->new (planepath => "PeanoCurve,radix=$radix",
                                                  delta_type => 'dY');
  my $max = 0;
  for (1 .. 10000000) {
    my ($i, $value) = $seq->next;

  # foreach my $k (1 .. 1000000) {
  #   my $i = $radix ** (4*$k+3) - 1;
  #   my $value = $seq->ith($i);

    if ($value > $max
        # || $i == 0b100011111
       ) {
      my $dx = $dx_seq->ith($i);
      my $dy = $dy_seq->ith($i);
      my $ri  = cnv($i,10,$radix);
      my $rdx = cnv($dx,10,$radix);
      my $rdy = cnv($dy,10,$radix);
      my $f = $dy ? $dx/$dy : -1;
      printf "%d %s %.5f  %s %s   %.3f\n", $i, $ri, $value, $rdx,$rdy, $f;
      $max = $value;
    }
  }

  exit 0;
}

__END__


#------------------------------------------------------------------------------
# xy_to_n() using pair of arrays for more symmetry ...

  # my @digits = digit_split_lowtohigh($n,$radix);
  # ### @digits
  # ### range: (scalar(@digits) | 1)
  # my @arrays = ([],[]);
  # my @rev = (0,0);
  # foreach my $i (reverse 0 .. $#digits) {  # high to low
  #   my $digit = $digits[$i];
  #   $rev[1-($i&1)] ^= $digit & 1;
  #   $arrays[$i&1]->[$i>>1] = ($rev[$i&1] ? $radix_minus_1 - $digit : $digit);
  # }
  # ### final ...
  # ### @arrays
  # ### rev : join('  ',@rev)
  # # foreach my $i (0,1) {
  # #   $arrays[$i]->[0] += $rev[$i];
  # # }
  # my $zero = $n*0;
  # return map { digit_join_lowtohigh($arrays[$_], $radix, $zero)
  #                + ($rev[$_] ? 1-$frac : $frac) } 0,1;


#------------------------------------------------------------------------------
# n_to_xy() other ways:

  # my $radix = $self->{'radix'};
  # my @ndigits = digit_split_lowtohigh($n,$radix);
  # 
  # # high to low style
  # #
  # my $radix_minus_1 = $radix - 1;
  # my $xk = 0;
  # my $yk = 0;
  # my @ydigits;
  # my @xdigits;
  # 
  # if (scalar(@ndigits) & 1) {
  #   push @ndigits, 0;            # so even number of entries
  # }
  # ### @ndigits
  # 
  # for (my $i = $#ndigits >> 1; @ndigits; $i--) {    # high to low
  #   ### $i
  #   {
  #     my $ndigit = pop @ndigits;  # high to low
  #     $xk ^= $ndigit;
  #     $ydigits[$i] = ($yk & 1 ? $radix_minus_1-$ndigit : $ndigit);
  #   }
  #   {
  #     my $ndigit = pop @ndigits;
  #     $yk ^= $ndigit;
  #     $xdigits[$i] = ($xk & 1 ? $radix_minus_1-$ndigit : $ndigit);
  #   }
  # }
  # 
  # ### @xdigits
  # ### @ydigits
  # my $zero = ($n * 0);  # inherit bignum 0
  # return (digit_join_lowtohigh(\@xdigits, $radix, $zero),
  #         digit_join_lowtohigh(\@ydigits, $radix, $zero));

  # low to high style
  #
  # my $x = my $y = ($n * 0);  # inherit bignum 0
  # my $power = 1 + $x;        # inherit bignum 1
  #
  # while (@ndigits) {   # N digits low to high
  #   ### $power
  #   {
  #     my $ndigit = shift @ndigits;  # low to high
  #     if ($ndigit & 1) {
  #       $y = $power-1 - $y;   # 99..99 - Y
  #     }
  #     $x += $power * $ndigit;
  #   }
  #   @ndigits || last;
  #   {
  #     my $ndigit = shift @ndigits;  # low to high
  #     $y += $power * $ndigit;
  #     $power *= $radix;
  #
  #     if ($ndigit & 1) {
  #       $x = $power-1 - $x;
  #     }
  #   }
  # }
  # return ($x, $y);


#------------------------------------------------------------------------------
# Past docs before PeanoDiagonals

# The is equivalent to the square form by drawing diagonal lines alternately
# in the direction of the leading diagonal or opposite diagonal, per the ".."
# marked lines in the following.
# 
#     +--------+--------+--------+        +--------+--------+--------+
#     |     .. | ..     |     .. |        |        |        |        |
#     |6  ..   |7  ..   |8  ..   |        |    6--------7--------8   |
#     | ..     |     .. | ..     |        |    |   |        |        |
#     +--------+--------+--------+        +----|---+--------+--------+
#     | ..     |     .. | ..     |        |    |   |        |        |
#     |   ..  5|   ..  4|   ..  3|        |    5--------4--------3   |
#     |     .. | ..     |     .. |        |        |        |    |   |
#     +--------+--------+--------+        +--------+--------+----|---+
#     |     .. | ..     |     .. |        |        |        |    |   |
#     |0  ..   |1  ..   |2  ..   |        |    0--------1--------2   |
#     | ..     |     .. | ..     |        |        |        |        |
#     +--------+--------+--------+        +--------+--------+--------+
# 
#     X==Y mod 2 "even" points leading-diagonal  "/"
#     X!=Y mod 2 "odd"  points opposite-diagonal "\"
# 
#       -----7        /
#      /      \      /
#     6        -----8
#     |
#     |        4-----
#      \      /      \
#       5-----        3
#                     |
#       -----1        |
#      /      \      /
#     0        -----2


#------------------------------------------------------------------------------


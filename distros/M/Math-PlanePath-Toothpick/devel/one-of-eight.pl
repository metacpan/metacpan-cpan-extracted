#!/usr/bin/perl -w

# Copyright 2012, 2013 Kevin Ryde

# This file is part of Math-PlanePath-Toothpick.
#
# Math-PlanePath-Toothpick is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Math-PlanePath-Toothpick is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath-Toothpick.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use List::Util 'min', 'max';
use List::MoreUtils 'uniq';
use Math::PlanePath::Base::Digits 'round_down_pow';

# uncomment this to run the ### lines
# use Smart::Comments;


{
  require Math::PlanePath::OneOfEight;
  foreach my $depth (2,
                      0 .. 80
                    ) {
    print "\ndepth=$depth\n";
    my $parts = '3side';
    my $path = Math::PlanePath::OneOfEight->new (parts => $parts);
    foreach my $n ($path->tree_depth_to_n($depth)
                   .. $path->tree_depth_to_n_end($depth)) {
      my $subheight_search = path_tree_n_to_subheight_by_search($path,$n);
      my $subheight = $path->tree_n_to_subheight($n);
      if (! defined $subheight) { $subheight = 'undef'; }
      if (! defined $subheight_search) { $subheight_search = 'undef'; }
      my $diff = ($subheight eq $subheight_search ? '' : '  ****');
      printf "%2d %s %s%s\n", $n, $subheight_search, $subheight, $diff;
    }
  }
  exit 0;


  use constant SUBHEIGHT_SEARCH_LIMIT => 90;
  sub path_tree_n_to_subheight_by_search {
    my ($path, $n, $limit) = @_;

    if (! defined $limit) { $limit = SUBHEIGHT_SEARCH_LIMIT; }
    if ($limit <= 0) {
      return undef;  # presumed infinite
    }
    if (! exists $path->{'path_tree_n_to_subheight_by_search__cache'}->{$n}) {
      my @children = $path->tree_n_children($n);
      my $height = 0;
      foreach my $n_child (@children) {
        my $h = path_tree_n_to_subheight_by_search($path,$n_child,$limit-1);
        if (! defined $h) {
          $height = undef;  # infinite
          last;
        }
        $h++;
        if ($h >= $height) {
          $height = $h;  # new bigger subheight among the children
        }
      }
      ### maximum is: $height
      if (defined $height || $limit >= SUBHEIGHT_SEARCH_LIMIT*4/5) {
        ### set cache: "n=$n  ".($height//'[undef]')
        $path->{'path_tree_n_to_subheight_by_search__cache'}->{$n} = $height;
        ### cache: $path->{'path_tree_n_to_subheight_by_search__cache'}
      }
    }
    ### path_tree_n_to_subheight_by_search(): "n=$n"
    return $path->{'path_tree_n_to_subheight_by_search__cache'}->{$n};


    # my @n = ($n);
    # my $height = 0;
    # my @pending = ($n);
    # for (;;) {
    #   my $n = pop @pending;
    #   @n = map {} @n
    #     or return $height;
    #
    #   if (defined my $h = $path->{'path_tree_n_to_subheight_by_search__cache'}->{$n}) {
    #     return $height + $h;
    #   }
    #   @n = map {$path->tree_n_children($_)} @n
    #     or return $height;
    #   $height++;
    #   if (@n > 200 || $height > 200) {
    #     return undef;  # presumed infinite
    #   }
    # }
  }
}
{
  # octant path->tree_depth_to_n() vs ByCells
  require Math::PlanePath::OneOfEightByCells;
  my $parts = 'side';
  my $path = Math::PlanePath::OneOfEight->new (parts => $parts);
  my $cells = Math::PlanePath::OneOfEightByCells->new (parts => $parts);
  foreach my $depth (0 .. 32) {
    my $n = $path->tree_depth_to_n($depth);
    my $c = $cells->tree_depth_to_n($depth);
    # my $c = octant($depth);
    my $diff = $n - $c;
    print "$depth  path=$n cells=$c = $diff\n";
  }
  exit 0;
}
{
  # at 2^k-1
  # V(2^k)     = (16*4^k + 24*k - 7) / 9
  # V(2^k + r) = V(2^k) + 2*V(r) + V(r+1) - 8*floor(log2(r+1)) + 1

  # V(15) = V(8) + 2*V(7) + V(8) - 8*floor(log2(8)) + 1
  #       = 2*V(8) + 2*V(7) - 8*floor(log2(8)) + 1

  # V(2^k - 1)
  # = V(2^(k-1)) + 2*V(2^(k-1) - 1) + V(2^(k-1)) - 8*floor(log2(2^(k-1))) + 1
  # = 2*V(2^(k-1)) + 2*V(2^(k-1) - 1) - 8*(k-1) + 1
  # = 2*V(2^(k-1))+4*V(2^(k-2))+...+2^k*V(1)
  #   - 8*(k-1 + k-2 + ... + 1) + k
  ;
}

{
  # print octant_added()
  require Math::PlanePath::OneOfEightByCells;
  my $cells = Math::PlanePath::OneOfEightByCells->new (parts => 'octant');
  my @values;
  foreach my $depth (4 .. 128) {
    push @values, $cells->tree_depth_to_n($depth+1) - $cells->tree_depth_to_n($depth);
  }
  @values = sort {$a<=>$b} @values;
  @values = uniq(@values);
  print join(',',@values),"\n";
  exit 0;
}

{
  # octant_added() func vs ByCells
  require Math::PlanePath::OneOfEight;
  require Math::PlanePath::OneOfEightByCells;
  my $cells = Math::PlanePath::OneOfEightByCells->new (parts => 'octant');
  foreach my $depth (0 .. 64) {
    my $n = $cells->tree_depth_to_n($depth+1) - $cells->tree_depth_to_n($depth);
    my $a = Math::PlanePath::OneOfEight::_depth_to_octant_added([$depth],[1],0);
    # my $a = octant_added($depth);
    my $diff = $a - $n;
    print "$depth  cells=$n func=$a   $diff\n";
     die if $diff != 0;
  }
  exit 0;

  sub octant_added {
    my ($depth) = @_;
    ### octant(): $depth
    if ($depth == 0) { return 1; }
    if ($depth == 1) { return 2; }

    my ($pow,$exp) = round_down_pow ($depth, 2);
    my $rem = $depth - $pow;
    my $f = ((4*$pow+9)*$pow + 6*$exp + 14)/18;
    if ($rem == 0) {
      return 1;
    }
    if ($rem == 1) {
      return 3;
    }
    # if ($rem == 2) {
    #   return $f + 4;
    # }
    if ($rem == $pow-1) {
      return $pow + $pow/2;
    }
    return (octant_added($rem)        # extend
            + octant_added($rem)      # upper
            + octant_added($rem+1)    # lower, until pow-1
            + (is_pow2($rem+2) ? -1 : 0)  # no log2_extra on lower
            - 1          # upper,lower overlap diagonal
           );
  }
  use Memoize;
  BEGIN {
    Memoize::memoize('octant_added');
  }

  sub is_pow2 {
    my ($n) = @_;
    while ($n > 1) {
      if ($n & 1) {
        return 0;
      }
      $n >>= 1;
    }
    return ($n == 1);
  }
}

{
  # _depth_to_octant_added() vs ByCells
  require Math::PlanePath::OneOfEight;
  # print Math::PlanePath::OneOfEight::_depth_to_octant_added([7],[1],0),"\n";
  #exit 0;

  require Math::PlanePath::OneOfEightByCells;
  my $oct = Math::PlanePath::OneOfEightByCells->new (parts => 'octant');
  foreach my $depth (0 .. 32) {
    my $added = Math::PlanePath::OneOfEight::_depth_to_octant_added([$depth],[1],0);
    my $c = $oct->tree_depth_to_n($depth+1) - $oct->tree_depth_to_n($depth);
    my $diff = $added - $c;
    print "$depth  added=$added cells=$c  diff=$diff\n";
    die if $diff;
  }
  exit 0;
}

{
  # octant() func vs ByCells
  require Math::PlanePath::OneOfEightByCells;
  my $cells = Math::PlanePath::OneOfEightByCells->new (parts => 'octant');
  foreach my $depth (0 .. 32) {
    my $n = $cells->tree_depth_to_n($depth);
    my $s = octant($depth);
    my $diff = $s - $n;
    print "$depth  $n    $diff\n";
  }
  exit 0;

  # eg. oct(6) = 7 + 2*oct(2) + oct(3) - 1 - 2 - 3
  #            = 7 + 2*3 + 4 - 1 - 2 - 3 = 11
  #     oct(9) = 20 + 1
  #     oct(10) = 20 + 4
  #     oct(14) = 20 + 2*oct(6) - 1 + oct(5) - log2(6+1) - (6-2)
  #             = 20 + 2*11 - 1 + 8 - 2 - (6-2)
  #             = 43
  sub octant {
    my ($depth) = @_;
    ### octant(): $depth
    if ($depth == 0) { return 0; }
    if ($depth == 1) { return 1; }

    my ($pow,$exp) = round_down_pow ($depth, 2);
    my $rem = $depth - $pow;
    my $f = ((4*$pow+9)*$pow + 6*$exp + 14)/18;
    if ($rem == 0) {
      return $f;
    }
    if ($rem == 1) {
      return $f + 1;
    }
    # if ($rem == 2) {
    #   return $f + 4;
    # }
    return ($f                  # pow
            + 2 * octant($rem)  # extend+upper
            + octant($rem+1)    # lower
            - log2_floor($rem+1)   # lower no log2_extras
            - $rem - 1          # upper,lower overlap diagonal
            - 2                 # upper,extend overlap initials
           );
  }
  use Memoize;
  BEGIN {
    Memoize::memoize('octant');
  }
}


{
  # octant powers
  require Math::PlanePath::OneOfEightByCells;
  my $path = Math::PlanePath::OneOfEightByCells->new (parts => 'octant');
  foreach my $k (0 .. 9) {
    my $pow = 2**$k;
    my $n = $path->tree_depth_to_n($pow);
    # my $prev = $path->tree_depth_to_n($pow/2);
    # my $diff = 4*$prev - $n - $k - $pow/2 - 1;
    # my $f = (2*$pow*$pow + 3*$k + 7)/9 + $pow/2;
    my $f = ((4*$pow+9)*$pow + 6*$k + 14)/18;
    my $diff = $f - $n;
    print "$k  $pow  $n    $diff\n";
  }
  exit 0;
}
{
  # ByCells octant vs centre
  require Math::PlanePath::OneOfEightByCells;
  my $centre = Math::PlanePath::OneOfEightByCells->new (parts => '1');
  my $oct = Math::PlanePath::OneOfEightByCells->new (parts => 'octant');
  foreach my $depth (0 .. 32) {
    my $nc = $centre->tree_depth_to_n($depth);
    my $no = $oct->tree_depth_to_n($depth);
    my $c = 2*$no - $depth;
    my $diff = $nc - $c;
    print "$depth  $nc    $diff\n";
  }
  exit 0;
}
{
  # centre from side
  # s(d)=e(d)+e(d+1)
  # s(d) - s(d-1) = e(d+1) - e(d-1)
  # s(d) - s(d-1) + e(d-2) = e(d+1) + e(d-2)
  # s(d)-sadd(d) = 2*e(d)
  # sadd(d) = s(d+1) - s(d)
  # eadd(d) = e(d+1) - e(d)
  # sadd(d) = eadd(d) + eadd(d+1)

  foreach my $k (0 .. 8) {
    my $pow = 2**$k;
    print "[$pow]  ";
    foreach my $rem (0 .. $pow-1) {
      my $depth = $pow + $rem;
      my $centre = centre($depth);
      my $s    = side($depth-1);
      for (my $d = $depth-2; $d >= 0; $d--) {
        $s -= side($d);
        $d--;
        last if $d < 0;
        $s += side($d);
      }
      my $c    = 2*$s - $depth + ($depth & 1 ? -2 : 2) + $pow + 2*$k;
      my $diff = $c - $centre;
      # print $s,",";
      print $diff,",";
    }
    print "\n";
  }
  exit 0;
}
{
  # side from centre
  # c(d) = 2*e(d)
  # s(d)=e(d)+e(d+1)
  foreach my $k (0 .. 8) {
    my $pow = 2**$k;
    print "[$pow]  ";
    foreach my $rem (0 .. $pow-1) {
      my $depth = $pow + $rem;
      my $side = side($depth);
      my $c    = centre($depth);
      my $c1   = centre($depth+1);
      my $s    = ($c + $c1 - 2*$depth - 1)/2 + $pow-$k + $rem - 2
        - ($rem+1 == $pow);
      my $diff = $s - $side;
      print $diff,",";
    }
    print "\n";
  }
  exit 0;
}
{
  # centre diffs

  # pow = 2^k
  # centre(pow+rem) = centre(pow) + centre(rem+1) + 2*centre(rem)
  #                   - 5 - 2*floor(log2(rem+1))
  #                  
  require Math::PlanePath::OneOfEightByCells;
  my $path = Math::PlanePath::OneOfEightByCells->new (parts => 1);
  foreach my $k (0 .. 9) {
    my $pow = 2**$k;
    my $p = $path->tree_depth_to_n($pow);
    print "[$pow]  ";
    foreach my $rem (0 .. $pow-1) {
      my $depth = $pow + $rem;
      my $t = $path->tree_depth_to_n($depth);
      my $r1 = $path->tree_depth_to_n($rem+1);
      my $r  = $path->tree_depth_to_n($rem+0);
      my $f = $p + $r1 + 2*$r - 5 - 2*log2_floor($rem+1);   # parts=1
      # my $f = $p + $r1 + 2*$r + 1 - 8*log2_floor($rem+1);   # parts=4
      my $diff = $f - $t;
      print $diff,",";
    }
    print "\n";
  }
  exit 0;
}

{
  # density decreasing as doubling, parts=4

  require Math::PlanePath::OneOfEight;
  my $path = Math::PlanePath::OneOfEight->new (parts => 4);
  for (my $depth = 1; $depth < 65536; $depth *= 2) {
    my $a = (2*$depth-1)**2;
    my $c = $path->tree_depth_to_n($depth);
    my $f = $c / $a;
    print "$depth  $c / $a =  $f\n";
  }
  exit 0;
}


#    |   1691 1690 1689      1688 1687 1686      1685 1684 1683      1682 1681 1680      1679 1678 1677      1676 1675 1674      1673 1672 1671      1670 1669 1668
#    |        1457                1456                1453                1452                1443                1442                1439                1438 1667
#    |        1458 1252 1251 1250 1455                1454 1249 1248 1247 1451                1444 1242 1241 1240 1441                1440 1239 1238 1237      1666
#    |        1459      1118                                    1117      1450                1445      1112                                    1111 1236
#    |                  1119 1006 1005 1004      1003 1002 1001 1116                                    1113 1000  999  998       997  996  995      1235      1665
#    |        1460      1120       912                 911      1115      1449                1446      1114       908                 907  994      1436 1437 1664
#    |        1461 1253 1254       913  849  848  847  910      1245 1246 1448                1447 1243 1244       909  846  845  844       993                1663
#    |        1462                 914       813                                                                             812  843
#    |                                       814  739  738  737       736  735  734       733  732  731       730  729  728       842       992                1662
#    |        1463                 915       815       655                 654                 651                 650  727       905  906  991      1435 1434 1661
#    |        1464 1256 1255       916  850  851       656  593  592  591  653                 652  590  589  588       726                 990      1234      1660
#    |        1465      1121       917                 657       557                                     556  587                1230 1108 1109 1110 1233
#    |                  1122 1007 1008 1009 1125                 558  519  518  517       516  515  514       586       725      1231                1232      1659
#    |        1466      1123                1124       658       559       492                 491  513       648  649  724      1429 1430      1431 1432 1433 1658
#    |        1467 1257 1258 1259      1260 1261       659  594  595       493  473  472  471       512                 723                                    1657
# 16 |                                                                               465  470
# 15 |    395  394  393       392  391  390       389  388  387       386  385  384       469       511                 722                                    1656
# 14 |         311                 310                 307                 306  383       489  490  510       647  646  721      1428 1427      1426 1425 1424 1655
# 13 |         312  249  248  247  309                 308  246  245  244       382                 509       585       720      1228                1227      1654
# 12 |         313       213                                     212  243                 581  553  554  555  584                1229 1107 1106 1105 1226
# 11 |                   214  175  174  173       172  171  170       242       381       582                 583       719                 989      1225      1653
# 10 |         314       215       148                 147  169       304  305  380       641  642       643  644  645  718       904  903  988      1422 1423 1652
#  9 |         315  250  251       149  129  128  127       168                 379                                     717       841       987                1651
#  8 |                                       121  126                                    1213 1098 1097       837  809  810  811  840
#  7 |     87   86   85        84   83   82       125       167                 378      1214       981       838                 839       986                1650
#  6 |          60                  59   81       145  146  166       303  302  377                 982  897  898  899       900  901  902  985      1421 1420 1649
#  5 |          61   41   40   39        80                 165       241       376      1215       983                                     984      1224      1648
#  4 |                    33   38                 237  209  210  211  240                1216 1099 1100 1101 1219                1220 1102 1103 1104 1223
#  3 |     17   16   15        37        79       238                 239       375      1217                1218                1221                1222      1647
#  2 |           9   14        57   58   78       297  298       299  300  301  374      1409 1410      1411 1412 1413      1414 1415 1416      1417 1418 1419 1646
#  1 | 3    2        13                  77                                     373                                                                            1645
#  0 | 0    1
#     -------------------------------------------------------------------------------------------------------------------------------------------------------------
#      0    1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30   31


# 7 |     7   7   7       7   7   7
# 6 |         6               6   7
# 5 |         6   5   5   5       7
# 4 |                 4   5
# 3 |     3   3   3       5       7
# 2 |         2   3       6   6   7
# 1 | 1   1       3               7
# 0 | 0   1
#    -------------------------------
#     0   1   2   3   4   5   6   7


#
# 16 |                                                 16
# 15 |    15 15 15    15 15 15    15 15 15    15 15 15 16     k=4 depth=16
# 14 |       14          14          14          14    16
# 13 |       14 13 13 13 14          14 13 13 13 14
# 12 |       14    12                      12    14
# 11 |             12 11 11 11    11 11 11 12
# 10 |       14    12    10          10    12    14
#  9 |       14 13 13    10  9  9e 9d10    13 13 14
#  8 |                          8c   10          14
#  7 |     7  7  7     7  7  7  8b
#  6 |        6           6     8a   10          14      rotate -90  1->8
#  5 |        6  5  5  5  6     9  9 10    13 13 14      miss one in corner
#  4 |              4     6          10    12    14
#  3 |     3  3  3  4          12 11 11 11 12
#  2 |        2     4     6    12          12    14
#  1 |  .  1  2     5  5  6    13 13    13 13 13 14
#  0 |  .  .            ****                    ****
#    +---------------------------------------------------
#       0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16







{
  # centre(), side()
  # A151725 total cells 0,1,9,13, 33,37,57,77, 121,125,145,165,209,237,297,373,

  print centre(6),"\n";
  # print centre(4),"\n";
  # print centre(8),"\n";
  # print centre(7),"\n";
  #exit 0;

  foreach my $depth (0 .. 68) {
    my $full = full($depth);
    my $centre = centre($depth);
    my $side = side($depth);
    my $diff = $centre - $side;
    print "$depth  $full  $centre  $side  diff=$diff\n";
  }

  unshift @INC, 't','xt';
  require MyOEIS;
  require Test; Test::plan(tests => 1);
  MyOEIS::compare_values
      (anum => 'A151725',
       func => sub {
         my ($count) = @_;
         my @got;
         for (my $depth = 0; @got < $count; $depth++) {
           push @got, full($depth);
         }
         return \@got;
       });
  MyOEIS::compare_values
      (anum => 'A151735',
       func => sub {
         my ($count) = @_;
         my @got;
         for (my $depth = 0; @got < $count; $depth++) {
           push @got, centre($depth);
         }
         return \@got;
       });

  sub full {
    my ($depth) = @_;
    if ($depth == 0) { return 0; }
    if ($depth == 1) { return 1; }
    return 4*centre($depth) - 7;
  }
  sub centre {
    my ($depth) = @_;
    ### centre(): $depth
    if ($depth == 0) { return 0; }
    if ($depth == 1) { return 1; }
    if ($depth == 2) { return 4; }

    {
      # centre(pow+rem) = centre(pow) + centre(rem) + 2*side(rem)
      #
      my ($pow,$exp) = round_down_pow ($depth, 2);
      my $ret = 0;
      while ($exp >= 0) {
        ### at: "depth=$depth pow=$pow exp=$exp"

        if ($depth == 0) {
          ### depth=0 end ...
          last;
        }
        if ($depth == 1) {
          ### depth=1 end add 1 ...
          $ret += 1;
          last;
        }
        if ($depth == 2) {
          ### depth=2 end add 4 to: $ret
          $ret += 4;
          last;
        }
        if ($depth >= $pow) {
          my $rem = $depth - $pow;
          ### $rem
          my $exp = $exp - 0;
          my $c = (4*$pow*$pow + 6*$exp + 14) / 9;
          my $s = side($rem);
          ### $c
          ### $s
          $ret += $c + 2*$s;
          $depth = $rem;
        }

        $pow /= 2;
        $exp--;
      }

      ### return: $ret
      return $ret;
    }

    {
      # expanding out the recursive centre(pow) part ...
      # but this is not quite right ...
      #
      # centre(pow+rem) = 2*side(pow/2) + 4*side(pow/4) + ...
      #                   + centre(rem) + 2*side(rem)
      #
      # should be per main code powers-of-2  p[i]=2^k[i]
      #
      # C(p1+p2+p3+p4) = C(p1) + C(p2) + C(p3) + C(p4)
      #                  + 2*side(p2+p3+p4) + 2*side(p3+p4) + 2*side(p4)

      my ($pow,$exp) = round_down_pow ($depth, 2);
      my $ret = 0;
      my $sf = 2;
      while ($exp > 1) {
        ### $depth
        ### $pow
        if ($depth == 1) { $ret += 1; $depth = 0; }
        if ($depth == 2) { $ret += 4; $depth = 0; }
        my $rem = $depth - $pow;
        if ($rem == 0) {
        } elsif ($rem == 1) {
          $ret += 3;
        } elsif ($rem > 0) {
          ### $rem
          $sf += 2;
          $ret += 2*side($rem);
          ### now ret: $ret
        }
        $depth = $rem;

        $ret += $sf * side($pow/2);
        ### apply sf: $sf.' * pow/2='.($pow/2)." for ret=$ret"

        $pow /= 2;
        $exp--;
        $sf *= 2;
      }
      $ret += $sf * 2;
      return $ret;
    }
    {
      if ($depth == 0) { return 0; }
      if ($depth == 1) { return 1; }
      if ($depth == 2) { return 4; }
      my ($pow,$exp) = round_down_pow ($depth-1, 2);
      my $rem = $depth - $pow;
      return centre($pow) + centre($rem) + 2*side($rem);
    }
  }
  sub side {
    my ($depth) = @_;
    if ($depth == 0) { return 0; }
    if ($depth == 1) { return 0; }
    if ($depth == 2) { return 1; }
    if ($depth == 3) { return 3; }
    my ($pow,$exp) = round_down_pow ($depth, 2);
    my $rem = $depth - $pow;
    if ($rem == 0) {
      $exp--;
      return (16*4**$exp - 3*$exp - 7)/9;
    }
    if ($rem == 1) {
      $exp--;
      return (16*4**$exp - 3*$exp - 7)/9  + 3;
    }
    return (side($pow)
            + side($rem+1) + ($rem+1==$pow ? -1 : 0)
            + 2*side($rem) + log2_floor($rem+1)
            + 2);
  }
  sub log2_floor {
    my ($n) = @_;
    if ($n < 2) { return 0; }
    my ($pow,$exp) = round_down_pow ($n, 2);
    return $exp;
  }
  use Memoize;
  BEGIN {
    Memoize::memoize('full');
    Memoize::memoize('centre');
    Memoize::memoize('side');
  }
  exit 0;
}


{
  # A151726 added triangle
  require Math::PlanePath::OneOfEightByCells;
  my $path = Math::PlanePath::OneOfEightByCells->new;
  my $depth = 0;
  foreach my $k (0 .. 7) {
    print "[$depth]  ";
    while ($depth < 2**$k) {
      print $path->tree_depth_to_n($depth+1)
        - $path->tree_depth_to_n($depth),
          ",";
      $depth++;
    }
    print "\n";
  }
  exit 0;
}

{
  # centre added
  #                     0 1 2  3   4  5  6  7
  # A151725 total       0,1,9,13, 33,37,57,77, 121,125,145,165,209,237,297,373,
  # A151726 added       0,1,8,4,  20, 4,20,20, 44,   4, 20, 20, 44, 28, 60, 76,

  require Math::PlanePath::OneOfEight;
  print Math::PlanePath::OneOfEight::_depth_to_added(0,[4],[1],0),"\n";
  # print centre(4),"\n";
  # print centre(8),"\n";
  # print centre(7),"\n";
  #exit 0;

  foreach my $depth (0 .. 16) {
    my $centre_calc = centre($depth+1) - centre($depth);
    my $centre_added = Math::PlanePath::OneOfEight::_depth_to_added($depth,[],[],0);
    my $diff = $centre_added - $centre_calc;
    print "$depth  $centre_calc $centre_added diff=$diff\n";
  }
  exit 0;
}
{
  # tree_depth_to_n()
  require Math::PlanePath::OneOfEight;
  my $path = Math::PlanePath::OneOfEight->new (parts => 1);
  foreach my $depth (0 .. 500) {
    my $centre = centre($depth);
    my $full = full($depth);
    my $value = $centre;
    my $n = $path->tree_depth_to_n($depth);
    my $flag = ($n == $value ? '' : '  ***');
    print "$depth  $value  $n$flag\n";
  }
  exit 0;
}


{
  # tree_depth_to_n() of 2^k
  #  1       1
  #  2       9
  #  4      33
  #  8     121
  # 16     465

  # total(1) = 1
  # total(2^k) = total(2^(k-1)) + 101010...1010101011000
  #            = total(2^(k-1)) + (4*4^k + 8)/3
  # k=1 total(2) = 1 + (4*4^1 + 8)/3 =
  #
  # k=16 total(16) = 121 + (4*4^4+8)/3 = 465
  # add   101011000
  #         1011000
  #           11000
  #            1000
  #               1
  #
  # total(2^k) = (4*4^k + 8)/3 + ... + (4*4^1 + 8)/3 + 1
  #            = (4*4^k + 8 + ... + 4*4^1 + 8)/3 + 1
  #            = (4*4^k + ... + 4*4^1  + 8*k)/3 + 1
  #            = (4*(4^k + ... + 4^1)  + 8*k)/3 + 1
  #            = (4*(4*4^k - 4)/3  + 8*k)/3 + 1
  #            = (16*(4^k - 1)/3  + 8*k)/3 + 1
  #            = (16*(4^k - 1) + 3*8*k)/9 + 1
  #            = (16*4^k - 16 + 3*8*k)/9 + 1
  #            = (16*4^k + 3*8*k - 16 + 9)/9
  #            = (16*4^k + 24*k - 7)/9

  # quarter
  # (total(2^k)-1)/4
  #    = ((16*4^k + 24*k - 7)/9 - 1) /4
  #    = (16*4^k + 24*k - 16)/9/4
  #    = (4*4^k + 6*k - 4)/9

  require Math::PlanePath::OneOfEightByCells;
  require Math::BaseCnv;
  my $c = Math::PlanePath::OneOfEightByCells->new;
  my $p = Math::PlanePath::OneOfEightByCells->new;
  my $prev_n = 0;
  for (my $k = 1; $k <= 16; $k++) {
    my $depth = 2**$k;

    my $n = $c->tree_depth_to_n($depth);
    my $n2 = Math::BaseCnv::cnv($n,10,2);

    my $pn = $p->tree_depth_to_n($depth);

    my $calc = (16*4**$k + 24*$k - 7) / 9;

    my $delta = $n - $prev_n;
    my $d2 = Math::BaseCnv::cnv($delta,10,2);

    printf "%5d path=%8d formula=%8d cells=%8d %20s\n",
      $depth, $pn, $calc, $n, $n2;
    # printf "%5d %8d  %20s\n", $depth, $delta, $d2;
    $prev_n = $n;
  }
  exit 0;
}
{
  # rect_to_n_range() on 2^k

  require Math::PlanePath::OneOfEight;
  require Math::PlanePath::OneOfEightByCells;
  my $c = Math::PlanePath::OneOfEightByCells->new;
  my $p = Math::PlanePath::OneOfEight->new;
  foreach my $k (0 .. 10) {
    my $depth = 2**$k;
    my $c_hi = $c->tree_depth_to_n($depth);

    my $x = my $y = 2**$k-1;
    my ($p_lo, $p_hi) = $p->rect_to_n_range(0,0,$x,$y);

    print "$k  $c_hi $p_hi\n";
  }
  exit 0;
}
{
  # side depth to N
  #
  # delta
  #  2        1                     1
  #  4        5                   101
  #  8       21                 10101
  # 16       85               1010101
  # 32      341             101010101
  #
  # total
  #   2        1                     1
  #   4        6                   110
  #   8       27                 11011
  #  16      112               1110000
  #  32      453             111000101
  #  64     1818           11100011010
  # 128     7279         1110001101111
  #
  # side(2^k) = (4^k-1)/3 + ... + 1
  #           = (4^k + ... + 1 - k)/3
  #           = ((4*4^k - 1)/3 0 k)/3
  #           = (4*4^k - 3*k - 1)/9
  #
  require Math::PlanePath::OneOfEightByCells;
  require Math::BaseCnv;
  require Math::BigRat;
  my $path = Math::PlanePath::OneOfEightByCells->new;
  my $prev_n = 0;

  for (my $k = 1; $k <= 16; $k++) {
    my $depth = 2**$k;

    my $n = 0;
    foreach my $x (0 .. $depth-1) {
      foreach my $y ($depth .. 2*$depth-1) {
        if (defined ($path->xy_to_n($x,$y))) {
          $n++;
        }
      }
    }
    my $n2 = Math::BaseCnv::cnv($n,10,2);

    $k = Math::BigRat->new($k);
    my $calc = (4*4**$k - 3*$k - 1) / 9;

    my $delta = $n - $prev_n;
    my $d2 = Math::BaseCnv::cnv($delta,10,2);

    printf "%5d %8d %8d  %20s\n", $depth, $calc, $n, $n2;
    # printf "%5d %8d  %20s\n", $depth, $delta, $d2;
    $prev_n = $n;
  }
  exit 0;
}

{
  require Math::PlanePath::OneOfEightByCells;
  my $path = Math::PlanePath::OneOfEightByCells->new;
  my $n = $path->xy_to_n(4,4);
  ### $n

  $path->n_to_xy(999);
  $n = $path->xy_to_n(4,4);
  ### $n
  exit 0;
}



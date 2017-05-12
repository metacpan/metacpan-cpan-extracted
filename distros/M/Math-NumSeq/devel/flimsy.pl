#!/usr/bin/perl -w

# Copyright 2013 Kevin Ryde

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


# A005360 flimsy numbers, n*k has fewer 1-bits than n for some k
# A125121 sturdy, not flimsy
# A143069 the smallest k giving the fewest 1-bits in n*k
# A143073 the smallest k giving fewer 1-bits
# A086342 smallest 1s-count in any n*k
# 
# A003147 primes fib prim root
# A095810 2^k mod 10^j
# A100661 count how many 2^k-1 terms add up to n cf A080468 A080578


# n=37    100101
# k=7085  1101110101101
# n*k     1000000000000000001

use 5.010;
use strict;
use List::Util 'min','max';
# use Math::BigInt try => 'GMP';

# use Math::NumSeq;
# *_is_infinite = \&Math::NumSeq::_is_infinite;

# use Math::NumSeq::NumAronson;
# *_round_down_pow = \&Math::NumSeq::NumAronson::_round_down_pow;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  print "want_is_flimsy_i_end() ",want_is_flimsy_i_end(),"\n";
  foreach my $n (0 .. want_is_flimsy_i_end()) {
 #  foreach my $n (17) {
    my $got = is_flimsy_by_division($n);
    my $want = want_is_flimsy($n);
    my $diff = ($got == $want ? '' : ' ********');
    print "$n got=$got want=$want$diff\n";
  }
  exit 0;
}


{
  foreach my $n (3 .. 121) {
    my $got = is_flimsy_by_division($n);
    my $want = want_is_flimsy($n);
    my $diff = ($got == $want ? '' : ' ********');
    # print "$n got=$got want=$want$diff   peakpos=$peak_pos\n";
    print "$n got=$got want=$want$diff\n";
  }
  exit 0;
}

{
  sub is_flimsy_by_division {
    my ($n) = @_;
    ### is_flimsy_by_division(): $n

    while ($n && $n % 2 == 0) {
      $n /= 2;
    }
    if ($n <= 3) {
      return 0;
    }

    my $n_bits = count_1_bits($n);
    my $max_bits = $n_bits - 2;
    ### $n_bits
    ### $max_bits

    if ($max_bits < 1) {
      # n has 2 or fewer bits, cannot be bettered ...
      return 0;
    }

    my $seen = '';
    my @backtrack_r;
    my $bits = 1;
    my $r = 1;
    my $target = $n - 1;

    for (;;) {
      ### at: "r=$r bits=$bits"
      if ($r == $target) {
        ### yes ...
        return 1;
      }
      my $s = vec($seen,$r,8);
      if ($s && $s <= $bits) {
        if (--$bits) {
          $r = pop @backtrack_r;
        } else {
          ### no more backtrack ...
          return 0;
        }
      } else {
        vec($seen,$r,8) = $bits;
        if (($r *= 2) > $n) { $r -= $n; }

        if ($bits < $max_bits) {
          push @backtrack_r, $r;
          $bits++;
          if (($r += 1) > $n) { $r -= $n; }
        }
      }
    }
  }
}
{
  # Given h can be reached from four places f,
  #
  # h=1 reached from kbit=0  f=11 drop bit to h=1    if f<n
  #                          f=10 zero bit to h=1
  #
  # h=1 reached from kbit=1
  #   from f odd (f+n)/2 = h     drop zero  f=2h-n     if >= 0
  #   from f even (f+n-1)/2 = h   drop one  f=2h-n+1

  sub is_flimsy {
    my ($n) = @_;
    ### is_flimsy(): $n

    while ($n && ! ($n & 1)) {
      $n >>= 1;
    }
    if ($n <= 3) {
      return 0;
    }

    # use Math::NumSeq::LeastPrimitiveRoot;
    # if (Math::NumSeq::LeastPrimitiveRoot::_is_primitive_root(2, $n)) {
    #   return 1;
    # }

    my @minbits;
    foreach my $h (1 .. $n-1) {
      $minbits[$h] = $n;
    }
    $minbits[0] = count_1_bits($n);

    my @pending_h = (1);
    my @pending_minbits = (1);
    while (@pending_h) {
      ### assert: scalar(@pending_h) == scalar(@pending_minbits)

      my $h         = pop @pending_h;
      my $h_minbits = pop @pending_minbits;

      ### pop: "h=$h=".sprintf('%b',$h)." h_minbits=$h_minbits"
      ### assert: $h < $n
      ### assert: $h >= 0

      if ($h_minbits >= $minbits[$h]) {
        ### not an improvement over existing minbits: $minbits[$h]
        next;
      }
      if ($h == 0) {
        ### found improved n ...
        return 1;
      }
      $minbits[$h] = $h_minbits;

      {
        my $f = 2*$h;
        if ($f < $n) {
          push @pending_h, $f;
          push @pending_minbits, $h_minbits;
          $f++;
          if ($f < $n) {
            push @pending_h, $f;
            push @pending_minbits, $h_minbits + 1;
          }
        }
      }
      {
        my $f = 2*$h - $n + 1;
        if ($f >= 0) {
          push @pending_h, $f;
          push @pending_minbits, $h_minbits + 1;
          $f--;
          if ($f >= 0) {
            push @pending_h, $f;
            push @pending_minbits, $h_minbits;
          }
        }
      }
    }
    return 0;
  }
}


{
  for (my $m = 3; $m < 20; $m += 2) {
    my $e = ($m+1)/2;
    my $p = powmod(2,$e,$m);
    my $q = powmod(2,2*$e,$m);
    if ($p == $m-1) {
      $p = -1;
    }
    print "$m  $p  $q\n";
  }
  exit 0;

  sub powmod {
    my ($b, $e, $m) = @_;
    my $ret = 1;
    while ($e) {
      if ($e & 1) {
        $ret *= $b;
        $ret %= $m;
      }
      $b *= $b;
      $b %= $m;
      $e >>= 1;
    }
    return $ret;
  }
}


{
  require Math::BigInt;
  require Math::NumSeq::OEIS;
  my $seq = Math::NumSeq::OEIS->new(anum=>'A143069');
  while (my ($i,$value) = $seq->next) {
    next unless $i % 2;
    $i = Math::BigInt->new($i);
    $value = Math::BigInt->new($value);
    my $p = $i*$value;
    my $ibits = count_1_bits($i);
    my $pbits = count_1_bits($p);
    next unless $pbits == 3;
    my $i2 = $i->as_bin;
    my $value2 = $value->as_bin;
    my $p2 = $p->as_bin;
    my $order = order_of_2($i);
    my $ofrac = ($i-1)/$order;
    next unless $ofrac > 3;
    printf "%s * %s = %s\n  %s * %s = %s     %s -> %s bits\n",
      $i, $value, $p,
        $i2, $value2, $p2,
          $ibits, $pbits;
    printf "  order %d div %d\n",
      $order, $ofrac;
  }
  exit 0;
}
{
  my $n = 73;
  my $p = 1;
  my $count = 0;
  do {
    print "$p ";
    $p = (2*$p) % $n;
    $count++;
  } while ($p != 1);
  print "\n";
  print "order $count\n";
  exit 0;
}
sub order_of_2 {
  my ($n) = @_;
  my $p = 1;
  my %seen;
  my $count = 0;
  do {
    $p = (2*$p) % $n;
    $count++;
  } until ($seen{$p}++);
  return $count;
}



{
  # graphs
  require Graph::Easy;
  my $graph = Graph::Easy->new;
  my $n = 11;
  foreach my $h (0 .. $n-1) {
    $graph->add_node($h);
  }
  foreach my $h (0 .. $n-1) {
    $graph->add_edge($h, ($h - ($h&1))/2, ($h&1));
    $graph->add_edge($h, ($h + $n - (1-($h&1)))/2, 1-($h&1));
  }
  print $graph->as_ascii;
  print $graph->as_svg;

  open FH, ">", "/tmp/x.svg";
  print FH $graph->as_svg_file;
  close FH;
  system("see /tmp/x.svg");

  open FH, ">", "/tmp/x.graphviz";
  print FH $graph->as_graphviz;
  close FH;
  system("dot -Tpng /tmp/x.graphviz >/tmp/x.png && xzgv /tmp/x.png");
  exit 0;
}


# h+k*n

# n=11=1011 k=3 3*11=33=100001
# at h=1011 either kbit=0 for new h=101 lowbit+1       (h-1)/2
#                  kbit=1 for 1011   (h-1)/2 + n
#                           + 1011
#                          = 10110   lowbit+0    ((h+n - (1-low))/2
# at h=1010 either kbit=0 for new h=101  h/2 lowbit+0  (h-low)/2
#                  kbit=1 for 1010
#                           + 1011
#                          = 10101  lowbit+1     ((h+n)-1)/2
#
# n=13=1101 k=5 5*13=65=1000001
#
sub WORKS1__is_flimsy {
  my ($n) = @_;
  ### is_flimsy(): $n

  if ($n <= 3) {
    return 0;
  }
  until ($n & 1) {
    $n >>= 1;
  }
  my $nbits = count_1_bits($n);

  my @minbits;
  my @pending_h = ($n);
  my @pending_lowbits = (0);
  while (@pending_h) {
    ### assert: scalar(@pending_h) == scalar(@pending_lowbits)

    my $h = pop @pending_h;
    my $lowbits = pop @pending_lowbits;

    ### pop: "h=$h=".sprintf('%b',$h)." lowbits=$lowbits"

    if (defined $minbits[$h] && $minbits[$h] <= $lowbits) {
      next;
    }
    if (count_1_bits($h) + $lowbits < $nbits) {
      ### found ...
      return 1;
    }
    $minbits[$h] = $lowbits;

    ### descend: "h=$h=".sprintf('%b',$h)." lowbits=$lowbits"

    my $low = $h & 1;
    my $t = ($h - $low)/2;
    push @pending_h, $t;
    push @pending_lowbits, $lowbits + $low;
    ### kbit=0: "to h=$pending_h[-1]=".sprintf('%b',$pending_h[-1])."  $pending_lowbits[-1]"

    $low ^= 1;
    push @pending_h, ($h + $n - $low) / 2;
    push @pending_lowbits, $lowbits + $low;
    ### kbit=1: "sum= ".sprintf('%b',$h+$n)
    ### kbit=1: "to h=$pending_h[-1]=".sprintf('%b',$pending_h[-1])."  $pending_lowbits[-1]"
  }
  return 0;





  # my ($limit,$exp) = _round_down_pow($n,2);
  # $limit *= 2;
  # $limit--;
  #
  # my @hbits;
  # my @minbits;
  # foreach my $h (0 .. $n) {
  #   $minbits[$h] = $hbits[$h] = count_1_bits($h);
  # }
  # $minbits[0] = $hbits[$n];  # h=0 must have k=1 at least
  #
  # my $changed;
  # my $min = sub {
  #   my ($t, $bits) = @_;
  #   ### consider: "t=$t bits=$bits  cf minbits=$minbits[$t]"
  #   if ($t != int($t)) { die "t not an integer: $t"; }
  #   if ($t > $#minbits) { die "t too big: $t"; }
  #   $bits += $hbits[$t];
  #   if ($bits < $minbits[$t]) {
  #     ### store: "t=$t new minbits=$bits"
  #     $minbits[$t] = $bits;
  #     $changed = 1;
  #   }
  # };
  #
  # for (;;) {
  #   $changed = 0;
  #   foreach my $h (0 .. $n) {
  #     ### $h
  #     my $low = $h & 1;
  #
  #     ### kbit=0 ...
  #     my $t = ($h - $low)/2;
  #     $min->($t, $minbits[$h] + $low);
  #
  #     ### kbit=1 ...
  #     $low ^= 1;
  #     $t = ($h + $n - $low) / 2;
  #     $min->($t, $minbits[$h] + $low);
  #   }
  #   ### $changed
  #   #exit;
  #   last unless $changed;
  # }
  #
  # ### bits: join('',@minbits)
  #
  # my $nbits = $hbits[$n];
  # if ($minbits[$n] < $nbits) {
  #   return 1;
  # }
  # return 0;





  # my @addlowbits;
  #
  # for (;;) {
  #   my $changed;
  #   foreach my $h (0 .. $limit) {
  #     my $t = ($h & 1 ? ($h+$n)/2 : $h/2);
  #     next if defined $addlowbits[$t];
  #     ### store: "h=$h t=$t"
  #     $addlowbits[$t] = 0;
  #     $changed = 1;
  #   }
  #   last unless $changed;
  # }
  #
  # ### addlowbits: join('',map {$_//'_'} @addlowbits)
  # exit;


  # if ($n <= 3) {
  #   return 0;
  # }
  #
  # $n = Math::BigInt->new($n);
  # my $n_count = bigint_count_1bits($n);
  # if ($n_count <= 1) {
  #   ### no, single 1 bit ...
  #   return 0;
  # }
  # ### n binary: $n->as_bin." n_count=$n_count"
  #
  # my $pos = 0;
  # my $prod = $n;  # k=1 so prod=1*n
  # my $limit = bit_length($prod) + 2;
  #
  # my @pos;
  # my @prod;
  # my @limit;
  #
  # for (;;) {
  #   $pos++;
  #   ### at: "prod=".$prod->as_bin." k=".($prod/$n)->as_bin." pos=$pos limit=$limit   pending=".scalar(@pos)
  #   if ($pos > $limit) {
  #     $peak_pos = max($peak_pos,$pos);
  #     if (@pos) {
  #       ### backtrack ...
  #       $pos = pop @pos;
  #       $prod = pop @prod;
  #       $limit = pop @limit;
  #       next;
  #     } else {
  #       ### no more backtracking ...
  #       return 0;
  #     }
  #   }
  #
  #   # n*(k+2^pos) = n*k + n*2^pos
  #   my $new_prod = $prod + ($n << $pos);
  #
  #   if (bigint_count_1bits($new_prod) < $n_count) {
  #     ### yes ...
  #     return 1;
  #   }
  #
  #   my $mask = ($mask[$pos] ||= (Math::BigInt->new(1) << ($pos+1)) - 1);
  #   my $plow = $new_prod & $mask;
  #
  #   ### prod: $new_prod->as_bin
  #   ### mask: $mask[$pos]->as_bin
  #   ### prod low: $plow->as_bin
  #
  #   if (bigint_count_1bits($plow) < $n_count) {
  #     ### low bits good, push ...
  #     push @prod, $new_prod;
  #     push @pos, $pos;
  #     push @limit, bit_length($new_prod) + 3;
  #   }
  # }
}
sub count_1_bits {
  my ($n) = @_;
  my $count = 0;
  while ($n) {
    $count += ($n & 1);
    $n >>= 1;
  }
  return $count;
}










sub bit_length {
  my ($n) = @_;
  my ($pow,$exp) = _round_down_pow($n, 2);
  return $exp+1;
}
bit_length(3) == 2 or die;
bit_length(4) == 3 or die;
bit_length(7) == 3 or die;
bit_length(8) == 4 or die;

sub bigint_count_1bits {
  my ($n) = @_;
  return scalar($n->as_bin() =~ tr/1/1/);
}
bigint_count_1bits(Math::BigInt->new(0b1011)) == 3 or die;
my @mask;
my @newbit;
my $peak_pos = 0;

sub XXis_flimsy {
  my ($n) = @_;
  $peak_pos = 0;
  
  if ($n <= 3) {
    return 0;
  }
  while ($n % 2 == 0) {
    $n /= 2;
  }
  if ($n <= 3) {
    return 0;
  }

  $n = Math::BigInt->new($n);
  my $n_count = bigint_count_1bits($n);
  if ($n_count <= 1) {
    ### no, single 1 bit ...
    return 0;
  }
  ### n binary: $n->as_bin." n_count=$n_count"

  my $pos = 0;
  my $prod = $n;  # k=1 so prod=1*n
  my $limit = bit_length($prod) + 2;

  my @pos;
  my @prod;
  my @limit;

  for (;;) {
    $pos++;
    ### at: "prod=".$prod->as_bin." k=".($prod/$n)->as_bin." pos=$pos limit=$limit   pending=".scalar(@pos)
    if ($pos > $limit) {
      $peak_pos = max($peak_pos,$pos);
      if (@pos) {
        ### backtrack ...
        $pos = pop @pos;
        $prod = pop @prod;
        $limit = pop @limit;
        next;
      } else {
        ### no more backtracking ...
        return 0;
      }
    }

    # n*(k+2^pos) = n*k + n*2^pos
    my $new_prod = $prod + ($n << $pos);

    if (bigint_count_1bits($new_prod) < $n_count) {
      ### yes ...
      return 1;
    }

    my $mask = ($mask[$pos] ||= (Math::BigInt->new(1) << ($pos+1)) - 1);
    my $plow = $new_prod & $mask;

    ### prod: $new_prod->as_bin
    ### mask: $mask[$pos]->as_bin
    ### prod low: $plow->as_bin

    if (bigint_count_1bits($plow) < $n_count) {
      ### low bits good, push ...
      push @prod, $new_prod;
      push @pos, $pos;
      push @limit, bit_length($new_prod) + 3;
    }
  }
}

BEGIN {
  my @want;
  sub want_is_flimsy {
    my ($n) = @_;
    return ($n >= 0 && $want[$n] ? 1 : 0);
  }
  sub want_is_flimsy_i_end {
    return $#want;
  }

  {
    require Math::NumSeq::OEIS;
    my $seq = Math::NumSeq::OEIS->new(anum=>'A005360');
    ### $seq
    while (my ($i,$value) = $seq->next) {
      $want[$value] = 1;
    }
  }
  # {
  #   # A-file listing not complete
  #   open FH, "< $ENV{HOME}/OEIS/a005360.txt" or die;
  #   while (<FH>) {
  #     if (/(\d+) (\d+) \[/) {
  #       $want[$1] = 1;
  #     }
  #   }
  #   close FH;
  #   foreach (@want) { $_ ||= 0 }
  # }
}


{
  # sames

  my $n = 11;
  my @seen;
  foreach my $h (reverse 0 .. $n) {
    next if $seen[$h];
    print "$h";
    $seen[$h] = 1;
    my $t = $h;
    for (;;) {
      $t = ($t&1 ? ($t+$n)/2 : $t/2);
      ### $t
      last if $seen[$t];
      print " -> $t";
      $seen[$t] = 1;
    }
    print "\n";
  }
  exit 0;
}

#!/usr/bin/perl -w

# Copyright 2012, 2014 Kevin Ryde

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

require 5;
use strict;
use Math::NumSeq::GolayRudinShapiroCumulative;

# uncomment this to run the ### lines
use Smart::Comments;

{
  # graphs of b-files
  # A000010 totient
  # A002321 cumulative mobius cf A002819 liouville

  # A002487 stern diatomic
  # A007305 stern-brocot numerators A007306 A047679 A057431
  # cf A162499 peaks
  # A000119 num fib representations

  # A003986 bitwise-OR skewed Sierpinski triangle A003987 A004198 AND
  #     A080098 A080099

  # A006667 collatz steps
  # A100002 ReReplace

  # A080465 alternate digits 

  # grid
  # A136414 all numbers taken 2 digits at a time
  # A193431 A193492

  # A035517 zeck terms

  # A153153 gray code reverse low bits A154438 lamplighter
  # A003100 decimal gray A003188
  # "vessels"
  # cf A129594 pattern

  # borderline
  # A003132 sum of squares of digits
  # A010554 phi(phi(n)) totient has horizontals at high res
  # A064275 inverse of integers ordered by totient

  use lib 't','xt';
  require MyOEIS;
  require IPC::Run;
  require Text::Elide;

  my @filename_list = ('A020986');
  # my $filename = File::Spec->catfile ($dir, "b$num.txt");

  @filename_list = glob(MyOEIS->oeis_directory() . '/b*.txt');
  print "filename count ",scalar(@filename_list),"\n";

  my $dir = MyOEIS->oeis_directory();
  foreach my $filename (@filename_list) {
    next if ! -e $filename;
    $filename =~ /(\d+)\.txt$/;
    my $num = $1;
    my $anum = "A$num";

    my $name = Math::OEIS::Names->anum_to_name($anum) || '';
    $name = Text::Elide::elide($name,50);
    $name =~ s/'/''/g;  # escape quotes

    my $str = <<"HERE";
set title '$name' tc lt 1
set terminal png size 1100, 850 background rgb "black"
plot '$filename' with dots lt rgb "white"
HERE
    IPC::Run::run(['gnuplot'],
                  '<',\$str,
                  '>',"/tmp/g$num.png");
  }
  IPC::Run::run(['xzgv','--geometry','1390x880', '/tmp']);
  exit 0;
}

{
  my $seq = Math::NumSeq::GolayRudinShapiroCumulative->new;
  for (1 .. 32) {
    my ($i,$value) = $seq->next;
    # my $calc = ith_low_to_high($i+1);
    #my $calc = ith_low_to_high($i+1);
     my $calc = Math::NumSeq::GolayRudinShapiroCumulative::ith(undef,$i);
    my $diff = ($calc == $value ? '' : '   ***');
    print "$i  $value  $calc$diff\n";
  }

  sub ith_high_to_low {
    my ($n) = @_;
    ### ith(): $n

    my $power = 1;
    my @bits;
    while ($n) {
      push @bits, $n % 2;
      $n = int($n/2);

      push @bits, $n % 2;
      $n = int($n/2);

      $power *= 2;
    }

    my $ret = 0;
    my $prev = 0;
    my $neg = 0;

    while (@bits) {
      my $bit = pop @bits;
      if ($bit) {
        if ($neg) {
          $ret -= $power;
        } else {
          ### first add: $power
          $ret += $power;
        }
      }
      if ($bit && $prev) {
        $neg ^= 1;
      }
      $prev = $bit;

      $power /= 2;
      last unless @bits;

      $bit = pop @bits;
      if ($bit) {
        if ($neg) {
          $ret -= $power;
        } else {
          ### second add: $power
          $ret += $power;
        }
      }
      if ($bit && $prev) {
        $neg ^= 1;
      }
      $prev = $bit;
    }
    return $ret;
  }

  sub Xith_low_to_high {
    my ($n) = @_;
    my $ret = 0;
    my $power = 1;
    my $neg = 0;
    my $pos = 0;
    while ($n) {
      if ($n % 2) {
        if ($neg) {
          $ret -= $power;
        } else {
          $ret += $power;
        }
        $neg ^= $pos;
      }
      $n = int($n/2);
      $pos ^= 1;

      $power *= 2;

      if ($n % 2) {
        if ($neg) {
          $ret -= $power;
        } else {
          $ret += $power;
        }
        $neg ^= $pos;
      }
      $n = int($n/2);
      $pos ^= 1;
    }
    return $ret;
  }
  exit 0;
}

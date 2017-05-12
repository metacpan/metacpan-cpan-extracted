#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

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

# uncomment this to run the ### lines
use Smart::Comments;

{
  # Knot overlapping points
  # 0,1,  4,16,68,288,1220,5168
  #    /4 1,4,17,72,305,1292 = A001076 a(n) = 4a(n-1) + a(n-2)
  #       denom continued fract converg to sqrt(5), 4-Fibonacci
  # each next = this*4 + prev

  require Math::PlanePath::FibonacciWordKnott;
  require Math::BaseCnv;
  require Math::NumSeq::BalancedBinary;
  my $path = Math::PlanePath::FibonacciWordKnott->new;
  my %seen;
  my %diffs; require Tie::IxHash; tie %diffs, 'Tie::IxHash';

  foreach my $n ($path->n_start .. 10000) {
    my ($x,$y) = $path->n_to_xy($n);
    if (my $p = $seen{$x,$y}) {
      my $d = $n - $p;
      # print "$x,$y  $p $n  diff $d\n";
      $diffs{$d} ||= 1;
    }
    $seen{$x,$y} = $n;
  }
  my $bal = Math::NumSeq::BalancedBinary->new;
  foreach my $d (keys %diffs) {
    my $b = Math::BaseCnv::cnv($d,10,2);
    my $z = $bal->ith($d);
    $z = Math::BaseCnv::cnv($z,10,2);
    print "$d  bin=$b  zeck=$z\n";
  }
  exit 0;
}
{
  # Dense Fibonacci Word turns
  require Math::NumSeq::FibonacciWord;

  require Image::Base::Text;
  my $image = Image::Base::Text->new (-width => 79, -height => 40);
  my $foreground = '*';
  my $doubleground = '+';

  # require Image::Base::GD;
  # $image = Image::Base::GD->new (-width => 200, -height => 200);
  # $image->rectangle (0,0, 200,200, 'black');
  # $foreground = 'white';
  # $doubleground = 'red';

  my $seq = Math::NumSeq::FibonacciWord->new (fibonacci_word_type => 'dense');
  my $dx = 1;
  my $dy = 0;
  my $x = 1;
  my $y = 1;

  my $transpose = 1;

  my $char = sub {
    if ($transpose) {
      if (($image->xy($y,$x)//' ') eq $foreground) {
        $image->xy ($y,$x, $doubleground);
      } else {
        $image->xy ($y,$x, $foreground);
      }
    } else {
      if (($image->xy($x,$y)//' ') eq $foreground) {
        $image->xy ($x,$y, $doubleground);
      } else {
        $image->xy ($x,$y, $foreground);
      }
    }
  };
  my $draw = sub {
    &$char ($x,$y);
    $x += $dx;
    $y += $dy;
    &$char ($x,$y);
    $x += $dx;
    $y += $dy;
    # &$char ($x,$y);
    # $x += $dx;
    # $y += $dy;
  };

  my $natural = sub {
    my ($value) = @_;
    &$draw();
    if ($value == 1) {
      ($dx,$dy) = (-$dy,$dx);
    } elsif ($value == 2) {
      ($dx,$dy) = ($dy,-$dx);
    }
  };

  my $apply;

  $apply = sub {
    # dfw natural, rot +45
    my ($i, $value) = $seq->next;
    &$natural($value);
  };

  # # plus, rot -45
  # $apply = sub {
  #   my ($i, $value) = $seq->next;
  #   if ($value == 0) {
  #     # empty
  #   } else {
  #     &$natural($value);
  #   }
  # };
  # $x += 20;
  # $y += 20;

  $apply = sub {
    # standard
    my ($i, $value) = $seq->next;
    if ($value == 0) {
      &$natural(1);
      &$natural(2);
    } elsif ($value == 1) {
      &$natural(1);
      &$natural(0);
    } else {
      &$natural(0);
      &$natural(2);
    }
  };

  # $x += 2;
  # $y += int ($image->get('-height') / 2);
  # $apply = sub {
  #   # rot pi/5 = 36deg  curly
  #   my ($i, $value) = $seq->next;
  #   if ($value == 0) {
  #     &$natural(2);
  #     &$natural(1);
  #   } elsif ($value == 1) {
  #     &$natural(0);
  #     &$natural(2);
  #   } else {
  #     &$natural(1);
  #     &$natural(0);
  #   }
  # };

  # $x += 20;
  # $y += 20;
  $apply = sub {
    # expanded
    my ($i, $value) = $seq->next;
    if ($value == 0) {
      &$natural(0);
      &$natural(1);
      &$natural(0);
      &$natural(2);
    } elsif ($value == 1) {
      &$natural(0);
      &$natural(1);
      &$natural(0);
    } else {
      &$natural(0);
      &$natural(0);
      &$natural(2);
    }
  };

  $apply = sub {
    # Ron Knott
    my ($i, $value) = $seq->next;
    if ($value == 0) {
      &$natural(1);
      &$natural(2);
    } else {
      &$natural($value);
    }
  };

  print "$x,$y\n";

  for (1 .. 2000) {
    &$apply();
  }

  # $image->save('/tmp/x.png');
  # system('xzgv /tmp/x.png');

  my $lines = $image->save_string;
  my @lines = split /\n/, $lines;
  $, = "\n";
  print reverse @lines;

  exit 0;
}

{
  my @xend = (0,0,1);
  my @yend = (0,1,1);
  my $f0 = 1;
  my $f1 = 2;
  my $level = 1;
  my $transpose = 0;
  my $rot = 0;

  ### at: "$xend[-1],$xend[-1] for $f1"

  foreach (1 .. 20) {
    ($f1,$f0) = ($f1+$f0,$f1);
    my $six = $level % 6;
    $transpose ^= 1;

    my ($x,$y);
    if (($level % 6) == 0) {
      $x = $yend[-2];     # T
      $y = $xend[-2];
    } elsif (($level % 6) == 1) {
      $x = $yend[-2];      # -90
      $y = - $xend[-2];
    } elsif (($level % 6) == 2) {
      $x = $xend[-2];     # T -90
      $y = - $yend[-2];

    } elsif (($level % 6) == 3) {
      ### T
      $x = $yend[-2];     # T
      $y = $xend[-2];
    } elsif (($level % 6) == 4) {
      $x = - $yend[-2];     # +90
      $y = $xend[-2];
    } elsif (($level % 6) == 5) {
      $x = - $xend[-2];     # T +90
      $y = $yend[-2];
    }

    push @xend, $xend[-1] + $x;
    push @yend, $yend[-1] + $y;
    ### new: ($level%6)." add $x,$y for $xend[-1],$yend[-1]  for $f1"
    $level++;
  }
  exit 0;
}

{
  my @xend = (0, 1);
  my @yend = (1, 1);
  my $f0 = 1;
  my $f1 = 2;

  foreach (1 .. 10) {
    {
      ($f1,$f0) = ($f1+$f0,$f1);
      my ($nx,$ny) = ($xend[-1] + $yend[-2], $yend[-1] + $xend[-2]); # T
      push @xend, $nx;
      push @yend, $ny;
      ### new 1: "$nx, $ny    for $f1"
    }

    {
      ($f1,$f0) = ($f1+$f0,$f1);
      my ($nx,$ny) = ($xend[-1] + $xend[-2], $yend[-1] - $yend[-2]); # T ...
      push @xend, $nx;
      push @yend, $ny;
      ### new 2: "$nx, $ny    for $f1"
    }

    {
      ($f1,$f0) = ($f1+$f0,$f1);
      my ($nx,$ny) = ($xend[-1] + $yend[-2], $yend[-1] + $xend[-2]); # T
      push @xend, $nx;
      push @yend, $ny;
      ### new 3: "$nx, $ny    for $f1"
    }

    {
      ($f1,$f0) = ($f1+$f0,$f1);
      my ($nx,$ny) = ($xend[-1] + $yend[-2], $yend[-1] + $xend[-2]);  # T
      push @xend, $nx;
      push @yend, $ny;
      ### new 1b: "$nx, $ny    for $f1"
    }

    {
      ($f1,$f0) = ($f1+$f0,$f1);
      my ($nx,$ny) = ($xend[-1] - $xend[-2], $yend[-1] + $yend[-2]); # T +90
      push @xend, $nx;
      push @yend, $ny;
      ### new 2b: "$nx, $ny    for $f1"
    }

    {
      ($f1,$f0) = ($f1+$f0,$f1);
      my ($nx,$ny) = ($xend[-1] + $yend[-2], $yend[-1] + $xend[-2]); # T
      push @xend, $nx;
      push @yend, $ny;
      ### new 1c: "$nx, $ny    for $f1"
    }

    {
      ($f1,$f0) = ($f1+$f0,$f1);
      my ($nx,$ny) = ($xend[-1] + $yend[-2], $yend[-1] - $xend[-2]);  # rot -90
      push @xend, $nx;
      push @yend, $ny;
      ### new 2c: "$nx, $ny    for $f1"
    }

  }
  exit 0;
}

#!/usr/bin/perl -w

# Copyright 2015 Kevin Ryde

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
use POSIX ();
use Math::Trig 'pi';
use Math::PlanePath::SierpinskiCurve;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # drawing turn sequence Language::Logo

  require Language::Logo;
  require Math::NumSeq::OEIS;

  # A003982=0,1 characteristic of A001844=2n(n+1)+1
  # constant A190406
  # my $seq = Math::NumSeq::OEIS->new (anum => 'A003982');
  # each leg 4 longer
  # 1, 0, 0, 0,
  # 1, 0, 0, 0, 0, 0, 0, 0,
  # 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  # 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  # 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  # 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  # 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,

  require Math::NumSeq::Squares;
  my $square = Math::NumSeq::Squares->new;

  my @value = (1, 0,
               1, 0, 0, 0,
               1, 0, 0, 0, 0, 0,
               1, 0, 0, 0, 0, 0, 0, 0,
               1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
               1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
               1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              );

  # A010052 charact of squares
  # 1,
  # 1, 0, 0,
  # 1, 0, 0, 0, 0,
  # 1, 0, 0, 0, 0, 0, 0,
  # 1, 0, 0, 0, 0, 0, 0, 0, 0,
  # 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  # 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,

  # A047838
  @value = (1, 0,
            1, 0, 0, 0,
            1, 0, 0, 0,
            1, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
           );

  for (my $i = 0; $i <= $#value; $i++) {
    if ($value[$i]) { print $i+1,","; }
  }
  print "\n";
  #  exit 0;

  my $lo = Logo->new(update => 20, port=>8222+time()%100);
  $lo->command("pendown");
  $lo->command("seth 0");
  foreach my $n (1 .. 2560) {
    # my ($i, $value) = $seq->next or last;

    # 2n(n+1)+1
    # my $i = $n+1;
    # my $value = $square->pred(2*$n+1);

    # my $i = $n+1;
    # my $value = $value[$i-1] // last;

    # i = floor(n^2/2)-1.
    # i+1 = floor(n^2/2)
    # 2i+2 = n^2
    my $i = $n+1;
    my $value = A080827_pred($i);

    $lo->command("forward 10");
    if (! $value) {
      if ($i & 1) {
        $lo->command("left 90");
      } else {
        $lo->command("right 90");
      }
    }
  }
  $lo->disconnect("Finished...");
  exit 0;

  my $init;
  my %values;
  sub A080827_pred {
    my ($value) = @_;
    unless ($init) {
      require Math::NumSeq::OEIS;

      # # cf A047838 or A080827 giving Aztec diamond spiral
      # my $seq = Math::NumSeq::OEIS->new (anum => 'A080827');
      # my $seq = Math::NumSeq::OEIS->new (anum => 'A047838');

      while (my($i,$value) = $seq->next) {
        $values{$value} = 1;
      }
      $init = 1;
    }
    return $values{$value};
    # return $seq->pred($value);
  }
}

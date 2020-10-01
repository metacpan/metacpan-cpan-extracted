#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2015, 2019, 2020 Kevin Ryde

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
# use Smart::Comments;

{
  # A023531 L-system

  my %to;

  %to = (S => 'STF+',   # TF second form "TriangleSpiral2" in a023531.l
         T => 'TF',
         F => 'F',
         '+' => '+');

  %to = (S => 'SFT+',   # FT first form "TriangleSpiral" in a023531.l
         T => 'FT',
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
  $str =~ s/S|T//g;
  print $str,"\n";

  require Math::NumSeq::OEIS;
  my $seq = Math::NumSeq::OEIS->new (anum => 'A023531');
  my $want = '';
  while (length($want) < length($str)) {
    my ($i,$value) = $seq->next;
    $want .= $value;
  }
  $str eq $want or die "oops";
  print "end\n";
  exit 0;
}

{
  # A010054 L-system

  my %to = (S => 'S+TF',
            T => 'TF',
            F => 'F', '+' => '+');
  my $str = 'S+TF';
  $str = 'S';
  foreach (1 .. 7) {
    my $pad = $str;
    $pad =~ s/./$& /g;
    print "$pad\n";
    $str =~ s{.}{$to{$&} // die}ge;
  }
  exit 0;
}
{
  # A010054 characteristic of triangular numbers
  # turn seq with Language::Logo

  require Math::NumSeq::OEIS;
  my $seq = Math::NumSeq::OEIS->new(anum=>'A010054');

  #     $seq->next;

  require Language::Logo;
  my $lo = Logo->new(update => 20, port=>8222);
  $lo->command("seth 0; forward 50; pendown; forward 200; backward 200; penup; backward 50; pendown");

  for (;;) {
    logo_blob(5);
    my ($i,$value) = $seq->next;
      $lo->command("left ".($value*120));
    if ($i > 0) {
    }
    $lo->command("forward 30");
  }
  $lo->disconnect("Finished...");
  exit 0;

  sub logo_blob {
    my ($size) = @_;
    my $half = $size/2;
    $lo->command("
    penup; forward $half; pendown;
    left 90; forward $half;
    left 90; forward $size;
    left 90; forward $size;
    left 90; forward $size;
    left 90; forward $half;
    right 90;
    penup; backward $half; pendown
");
  }
}

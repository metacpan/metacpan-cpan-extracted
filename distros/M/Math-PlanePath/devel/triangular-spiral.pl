#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2015 Kevin Ryde

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

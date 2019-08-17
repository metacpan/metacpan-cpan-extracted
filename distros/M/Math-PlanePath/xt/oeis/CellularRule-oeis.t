#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2019 Kevin Ryde

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


# cf A094605 rule 30 period of nth diagonal
#    A094606 log2 of that period
#



use 5.004;
use strict;
use Math::BigInt try => 'GMP';   # for bignums in reverse-add steps
use List::Util 'min';
use Test;
plan tests => 516;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::CellularRule;

# uncomment this to run the ### lines
# use Smart::Comments '###';


sub streq_array {
  my ($a1, $a2) = @_;
  if (! ref $a1 || ! ref $a2) {
    return 0;
  }
  while (@$a1 && @$a2) {
    if ($a1->[0] ne $a2->[0]) {
      MyTestHelpers::diag ("differ: ", $a1->[0], ' ', $a2->[0]);
      return 0;
    }
    shift @$a1;
    shift @$a2;
  }
  return (@$a1 == @$a2);
}


#------------------------------------------------------------------------------
# duplications

foreach my $elem (# [ 'A071030', 'A118109', 'rule=54' ],
                  # [ 'A071033', 'A118102', 'rule=94' ],
                  # [ 'A071036', 'A118110', 'rule=150' ],
                  [ 'A071037', 'A118172', 'rule=158' ],
                  [ 'A071039', 'A118111', 'rule=190' ],
                 ) {
  my ($anum1, $anum2, $name) = @$elem;
  my ($aref1) = MyOEIS::read_values($anum1);
  my ($aref2) = MyOEIS::read_values($anum2);
  $#$aref1 = min($#$aref1, $#$aref2);
  $#$aref2 = min($#$aref1, $#$aref2);
  my $str1 = join(',', @$aref1);
  my $str2 = join(',', @$aref2);
  print "$name ", $str1 eq $str2 ? "same" : "different","\n";
  if ($str1 ne $str2) {
    print " $str1\n";
    print " $str2\n";
  }
}

#------------------------------------------------------------------------------
# A061579 - permutation N at -X,Y

MyOEIS::compare_values
  (anum => 'A061579',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::CellularRule->new (n_start => 0, rule => 50);
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, $path->xy_to_n (-$x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------

# A262867 Total number of ON (black) cells after n iterations of the "Rule 153" elementary cellular automaton starting with a single ON (black) cell.
# A263511 Total number of ON (black) cells after n iterations of the "Rule 155" elementary cellular automaton starting with a single ON (black) cell.
# A263807 Total number of ON (black) cells after n iterations of the "Rule 157" elementary cellular automaton starting with a single ON (black) cell.
# A265205 Number of ON cells in the n-th iteration of the "Rule 73" elementary cellular automaton starting with a single ON cell.
# A265206 Total number of ON cells after n iterations of the "Rule 73" elementary cellular automaton starting with a single ON cell.
# A265219 Number of OFF (white) cells in the n-th iteration of the "Rule 73" elementary cellular automaton starting with a single ON (black) cell.
# A265220 Total number of OFF (white) cells after n iterations of the "Rule 73" elementary cellular automaton starting with a single ON (black) cell.
# A265223 Total number of OFF (white) cells after n iterations of the "Rule 150" elementary cellular automaton starting with a single ON (black) cell.
# A265224 Total number of OFF (white) cells after n iterations of the "Rule 30" elementary cellular automaton starting with a single ON (black) cell.
# A265225 Total number of ON (black) cells after n iterations of the "Rule 54" elementary cellular automaton starting with a single ON (black) cell.
# A265283 Number of ON (black) cells in the n-th iteration of the "Rule 94" elementary cellular automaton starting with a single ON (black) cell.
# A265284 Total number of ON (black) cells after n iterations of the "Rule 94" elementary cellular automaton starting with a single ON (black) cell.
# A265321 Total number of ON (black) cells after n iterations of the "Rule 110" elementary cellular automaton starting with a single ON (black) cell.
# A265322 Number of OFF (white) cells in the n-th iteration of the "Rule 110" elementary cellular automaton starting with a single ON (black) cell.
# A265323 Total number of OFF (white) cells after n iterations of the "Rule 110" elementary cellular automaton starting with a single ON (black) cell.
# A265382 Total number of ON (black) cells after n iterations of the "Rule 158" elementary cellular automaton starting with a single ON (black) cell.
# A265428 Number of ON (black) cells in the n-th iteration of the "Rule 188" elementary cellular automaton starting with a single ON (black) cell.
# A265429 Total number of ON (black) cells after n iterations of the "Rule 188" elementary cellular automaton starting with a single ON (black) cell.
# A265430 Number of OFF (white) cells in the n-th iteration of the "Rule 188" elementary cellular automaton starting with a single ON (black) cell.
# A265431 Total number of OFF (white) cells after n iterations of the "Rule 188" elementary cellular automaton starting with a single ON (black) cell.
# A267880 Decimal representation of the middle column of the "Rule 233" elementary cellular automaton starting with a single ON (black) cell.
# A267881 Number of ON (black) cells in the n-th iteration of the "Rule 233" elementary cellular automaton starting with a single ON (black) cell.
# A267882 Total number of ON (black) cells after n iterations of the "Rule 233" elementary cellular automaton starting with a single ON (black) cell.
# A267883 Number of OFF (white) cells in the n-th iteration of the "Rule 233" elementary cellular automaton starting with a single ON (black) cell.
# A267884 Total number of OFF (white) cells after n iterations of the "Rule 233" elementary cellular automaton starting with a single ON (black) cell.
# A267872 Number of ON (black) cells in the n-th iteration of the "Rule 237" elementary cellular automaton starting with a single ON (black) cell.
# A267873 Number of ON (black) cells in the n-th iteration of the "Rule 235" elementary cellular automaton starting with a single ON (black) cell.
# A267874 Total number of ON (black) cells after n iterations of the "Rule 235" elementary cellular automaton starting with a single ON (black) cell.

# A267610 Total number of OFF (white) cells after n iterations of the "Rule 182" elementary cellular automaton starting with a single ON (black) cell.
   # A267590 Number of ON (black) cells in the n-th iteration of the "Rule 169" elementary cellular automaton starting with a single ON (black) cell.
   # A267591 Total number of ON (black) cells after n iterations of the "Rule 169" elementary cellular automaton starting with a single ON (black) cell.
   # A267592 Number of OFF (white) cells in the n-th iteration of the "Rule 169" elementary cellular automaton starting with a single ON (black) cell.
   # A267593 Total number of OFF (white) cells after n iterations of the "Rule 169" elementary cellular automaton starting with a single ON (black) cell.
   # A267582 Number of ON (black) cells in the n-th iteration of the "Rule 167" elementary cellular automaton starting with a single ON (black) cell.
   # A267583 Total number of ON (black) cells after n iterations of the "Rule 167" elementary cellular automaton starting with a single ON (black) cell.
   # A267528 Number of ON (black) cells in the n-th iteration of the "Rule 141" elementary cellular automaton starting with a single ON (black) cell.
   # A267529 Total number of ON (black) cells after n iterations of the "Rule 141" elementary cellular automaton starting with a single ON (black) cell.
   # A267530 Number of OFF (white) cells in the n-th iteration of the "Rule 141" elementary cellular automaton starting with a single ON (black) cell.
   # A267531 Total number of OFF (white) cells after n iterations of the "Rule 141" elementary cellular automaton starting with a single ON (black) cell.
   # A267516 Number of ON (black) cells in the n-th iteration of the "Rule 137" elementary cellular automaton starting with a single ON (black) cell.
   # A267517 Total number of ON (black) cells after n iterations of the "Rule 137" elementary cellular automaton starting with a single ON (black) cell.
   # A267518 Number of OFF (white) cells in the n-th iteration of the "Rule 137" elementary cellular automaton starting with a single ON (black) cell.
   # A267519 Total number of OFF (white) cells after n iterations of the "Rule 137" elementary cellular automaton starting with a single ON (black) cell.
   # A267458 Number of ON (black) cells in the n-th iteration of the "Rule 133" elementary cellular automaton starting with a single ON (black) cell.
   # A267459 Total number of ON (black) cells after n iterations of the "Rule 133" elementary cellular automaton starting with a single ON (black) cell.
   # A267460 Number of OFF (white) cells in the n-th iteration of the "Rule 133" elementary cellular automaton starting with a single ON (black) cell.
   # A267461 Total number of OFF (white) cells after n iterations of the "Rule 133" elementary cellular automaton starting with a single ON (black) cell.
   # A267451 Number of ON (black) cells in the n-th iteration of the "Rule 131" elementary cellular automaton starting with a single ON (black) cell.
   # A267452 Total number of ON (black) cells after n iterations of the "Rule 131" elementary cellular automaton starting with a single ON (black) cell.
   # A267453 Number of OFF (white) cells in the n-th iteration of the "Rule 131" elementary cellular automaton starting with a single ON (black) cell.
   # A267454 Total number of OFF (white) cells after n iterations of the "Rule 131" elementary cellular automaton starting with a single ON (black) cell.
   # A267445 Number of ON (black) cells in the n-th iteration of the "Rule 129" elementary cellular automaton starting with a single ON (black) cell.
   # A267446 Total number of ON (black) cells after n iterations of the "Rule 129" elementary cellular automaton starting with a single ON (black) cell.
   # A267447 Number of OFF (white) cells in the n-th iteration of the "Rule 129" elementary cellular automaton starting with a single ON (black) cell.
   # A267448 Total number of OFF (white) cells after n iterations of the "Rule 129" elementary cellular automaton starting with a single ON (black) cell.
   # A267368 Total number of ON (black) cells after n iterations of the "Rule 126" elementary cellular automaton starting with a single ON (black) cell.
   # A267369 Total number of OFF (white) cells after n iterations of the "Rule 126" elementary cellular automaton starting with a single ON (black) cell.
   # A267352 Number of ON (black) cells in the n-th iteration of the "Rule 123" elementary cellular automaton starting with a single ON (black) cell.
   # A267353 Total number of ON (black) cells after n iterations of the "Rule 123" elementary cellular automaton starting with a single ON (black) cell.
   # A267354 Number of OFF (white) cells in the n-th iteration of the "Rule 123" elementary cellular automaton starting with a single ON (black) cell.
   # A267259 Number of ON (black) cells in the n-th iteration of the "Rule 111" elementary cellular automaton starting with a single ON (black) cell.
   # A267260 Total number of ON (black) cells after n iterations of the "Rule 111" elementary cellular automaton starting with a single ON (black) cell.
   # A267261 Number of OFF (white) cells in the n-th iteration of the "Rule 111" elementary cellular automaton starting with a single ON (black) cell.
   # A267262 Total number of OFF (white) cells after n iterations of the "Rule 111" elementary cellular automaton starting with a single ON (black) cell.
   # A267212 Total number of ON (black) cells after n iterations of the "Rule 109" elementary cellular automaton starting with a single ON (black) cell.
   # A267214 Total number of OFF (white) cells after n iterations of the "Rule 109" elementary cellular automaton starting with a single ON (black) cell.
   # A267159 Total number of ON (black) cells after n iterations of the "Rule 107" elementary cellular automaton starting with a single ON (black) cell.
   # A267161 Total number of OFF (white) cells after n iterations of the "Rule 107" elementary cellular automaton starting with a single ON (black) cell.
   # A267149 Total number of ON (black) cells after n iterations of the "Rule 105" elementary cellular automaton starting with a single ON (black) cell.
   # A267151 Total number of OFF (white) cells after n iterations of the "Rule 105" elementary cellular automaton starting with a single ON (black) cell.
   # A267047 Total number of ON (black) cells after n iterations of the "Rule 91" elementary cellular automaton starting with a single ON (black) cell.
   # A267049 Total number of OFF (white) cells after n iterations of the "Rule 91" elementary cellular automaton starting with a single ON (black) cell.
   # A266899 Total number of ON (black) cells after n iterations of the "Rule 75" elementary cellular automaton starting with a single ON (black) cell.
   # A266901 Total number of OFF (white) cells after n iterations of the "Rule 75" elementary cellular automaton starting with a single ON (black) cell.

my @data =
  (
   # Not quite, initial values differ
   # [ 'A051341', 7, 'bits' ],
   
   # A080513 Number of ON (black) cells in the n-th iteration of the "Rule 70" elementary cellular automaton starting with a single ON (black) cell.
   # 
   # A226463 Triangle read by rows giving successive states of cellular automaton generated by "Rule 135".
   # A226464 Triangle read by rows giving successive states of cellular automaton generated by "Rule 149".
   # A226482 Number of runs of consecutive ones and zeros in successive states of cellular automaton generated by "Rule 30".
   # 
   # A265688 Binary representation of the n-th iteration of the "Rule 190" elementary cellular automaton starting with a single ON (black) cell.
   # A265695 Triangle read by rows giving successive states of cellular automaton generated by "Rule 135" initiated with a single ON (black) cell.
   # A265696 Binary representation of the n-th iteration of the "Rule 135" elementary cellular automaton starting with a single ON (black) cell.
   # A265697 Decimal representation of the n-th iteration of the "Rule 135" elementary cellular automaton starting with a single ON (black) cell.
   # A265698 Middle column of the "Rule 135" elementary cellular automaton starting with a single ON (black) cell.
   # A265699 Binary representation of the middle column of the "Rule 135" elementary cellular automaton starting with a single ON (black) cell.
   # A265700 Decimal representation of the middle column of the "Rule 135" elementary cellular automaton starting with a single ON (black) cell.
   # A265701 Number of ON (black) cells in the n-th iteration of the "Rule 135" elementary cellular automaton starting with a single ON (black) cell.
   # A265702 Total number of ON (black) cells after n iterations of the "Rule 135" elementary cellular automaton starting with a single ON (black) cell.
   # A265703 Number of OFF (white) cells in the n-th iteration of the "Rule 135" elementary cellular automaton starting with a single ON (black) cell.
   # A265704 Total number of OFF (white) cells after n iterations of the "Rule 135" elementary cellular automaton starting with a single ON (black) cell.
   # A265715 Binary representation of the n-th iteration of the "Rule 149" elementary cellular automaton starting with a single ON (black) cell.
   # A265717 Decimal representation of the n-th iteration of the "Rule 149" elementary cellular automaton starting with a single ON (black) cell.
   # A265718 Triangle read by rows giving successive states of cellular automaton generated by "Rule 1" initiated with a single ON (black) cell.
   # A265720 Binary representation of the n-th iteration of the "Rule 1" elementary cellular automaton starting with a single ON (black) cell.
   # A265721 Decimal representation of the n-th iteration of the "Rule 1" elementary cellular automaton starting with a single ON (black) cell.
   # A265722 Number of ON (black) cells in the n-th iteration of the "Rule 1" elementary cellular automaton starting with a single ON (black) cell.
   # A265723 Number of OFF (white) cells in the n-th iteration of the "Rule 1" elementary cellular automaton starting with a single ON (black) cell.
   # A265724 Total number of OFF (white) cells after n iterations of the "Rule 1" elementary cellular automaton starting with a single ON (black) cell.
   # A266068 Binary representation of the n-th iteration of the "Rule 3" elementary cellular automaton starting with a single ON (black) cell.
   # A266069 Decimal representation of the n-th iteration of the "Rule 3" elementary cellular automaton starting with a single ON (black) cell.
   # A266070 Middle column of the "Rule 3" elementary cellular automaton starting with a single ON (black) cell.
   # A266071 Binary representation of the middle column of the "Rule 3" elementary cellular automaton starting with a single ON (black) cell.
   # A266072 Number of ON (black) cells in the n-th iteration of the "Rule 3" elementary cellular automaton starting with a single ON (black) cell.
   # A266073 Number of OFF (white) cells in the n-th iteration of the "Rule 3" elementary cellular automaton starting with a single ON (black) cell.
   # A266074 Total number of OFF (white) cells after n iterations of the "Rule 3" elementary cellular automaton starting with a single ON (black) cell.
   # A266090 Decimal representation of the n-th iteration of the "Rule 17" elementary cellular automaton starting with a single ON (black) cell.
   # A266155 Triangle read by rows giving successive states of cellular automaton generated by "Rule 19" initiated with a single ON (black) cell.
   # A266174 Triangle read by rows giving successive states of cellular automaton generated by "Rule 5" initiated with a single ON (black) cell.
   # A266175 Binary representation of the n-th iteration of the "Rule 5" elementary cellular automaton starting with a single ON (black) cell.
   # A266176 Decimal representation of the n-th iteration of the "Rule 5" elementary cellular automaton starting with a single ON (black) cell.
   # A266178 Triangle read by rows giving successive states of cellular automaton generated by "Rule 6" initiated with a single ON (black) cell.
   # A266179 Binary representation of the n-th iteration of the "Rule 6" elementary cellular automaton starting with a single ON (black) cell.
   # A266180 Decimal representation of the n-th iteration of the "Rule 6" elementary cellular automaton starting with a single ON (black) cell.
   # A266216 Triangle read by rows giving successive states of cellular automaton generated by "Rule 7" initiated with a single ON (black) cell.
   # A266217 Binary representation of the n-th iteration of the "Rule 7" elementary cellular automaton starting with a single ON (black) cell.
   # A266218 Decimal representation of the n-th iteration of the "Rule 7" elementary cellular automaton starting with a single ON (black) cell.
   # A266219 Binary representation of the middle column of the "Rule 7" elementary cellular automaton starting with a single ON (black) cell.
   # A266220 Number of ON (black) cells in the n-th iteration of the "Rule 7" elementary cellular automaton starting with a single ON (black) cell.
   # A266221 Total number of ON (black) cells after n iterations of the "Rule 7" elementary cellular automaton starting with a single ON (black) cell.
   # A266222 Number of OFF (white) cells in the n-th iteration of the "Rule 7" elementary cellular automaton starting with a single ON (black) cell.
   # A266223 Total number of OFF (white) cells after n iterations of the "Rule 7" elementary cellular automaton starting with a single ON (black) cell.
   # A266243 Triangle read by rows giving successive states of cellular automaton generated by "Rule 9" initiated with a single ON (black) cell.
   # A266244 Binary representation of the n-th iteration of the "Rule 9" elementary cellular automaton starting with a single ON (black) cell.
   # A266245 Decimal representation of the n-th iteration of the "Rule 9" elementary cellular automaton starting with a single ON (black) cell.
   # A266246 Middle column of the "Rule 9" elementary cellular automaton starting with a single ON (black) cell.
   # A266247 Binary representation of the middle column of the "Rule 9" elementary cellular automaton starting with a single ON (black) cell.
   # A266248 Decimal representation of the middle column of the "Rule 9" elementary cellular automaton starting with a single ON (black) cell.
   # A266249 Number of ON (black) cells in the n-th iteration of the "Rule 9" elementary cellular automaton starting with a single ON (black) cell.
   # A266250 Total number of ON (black) cells after n iterations of the "Rule 9" elementary cellular automaton starting with a single ON (black) cell.
   # A266251 Number of OFF (white) cells in the n-th iteration of the "Rule 9" elementary cellular automaton starting with a single ON (black) cell.
   # A266252 Total number of OFF (white) cells after n iterations of the "Rule 9" elementary cellular automaton starting with a single ON (black) cell.
   # A266253 Triangle read by rows giving successive states of cellular automaton generated by "Rule 11" initiated with a single ON (black) cell.
   # A266254 Binary representation of the n-th iteration of the "Rule 11" elementary cellular automaton starting with a single ON (black) cell.
   # A266255 Decimal representation of the n-th iteration of the "Rule 11" elementary cellular automaton starting with a single ON (black) cell.
   # A266256 Number of ON (black) cells in the n-th iteration of the "Rule 11" elementary cellular automaton starting with a single ON (black) cell.
   # A266257 Total number of ON (black) cells after n iterations of the "Rule 11" elementary cellular automaton starting with a single ON (black) cell.
   # A266258 Number of OFF (white) cells in the n-th iteration of the "Rule 11" elementary cellular automaton starting with a single ON (black) cell.
   # A266259 Total number of OFF (white) cells after n iterations of the "Rule 11" elementary cellular automaton starting with a single ON (black) cell.
   # A266282 Triangle read by rows giving successive states of cellular automaton generated by "Rule 13" initiated with a single ON (black) cell.
   # A266283 Binary representation of the n-th iteration of the "Rule 13" elementary cellular automaton starting with a single ON (black) cell.
   # A266284 Decimal representation of the n-th iteration of the "Rule 13" elementary cellular automaton starting with a single ON (black) cell.
   # A266285 Number of ON (black) cells in the n-th iteration of the "Rule 13" elementary cellular automaton starting with a single ON (black) cell.
   # A266286 Number of OFF (white) cells in the n-th iteration of the "Rule 13" elementary cellular automaton starting with a single ON (black) cell.
   # A266287 Total number of OFF (white) cells after n iterations of the "Rule 13" elementary cellular automaton starting with a single ON (black) cell.
   # A266298 Triangle read by rows giving successive states of cellular automaton generated by "Rule 14" initiated with a single ON (black) cell.
   # A266299 Binary representation of the n-th iteration of the "Rule 14" elementary cellular automaton starting with a single ON (black) cell.
   # A266300 Triangle read by rows giving successive states of cellular automaton generated by "Rule 15" initiated with a single ON (black) cell.
   # A266301 Binary representation of the n-th iteration of the "Rule 15" elementary cellular automaton starting with a single ON (black) cell.
   # A266302 Decimal representation of the n-th iteration of the "Rule 15" elementary cellular automaton starting with a single ON (black) cell.
   # A266303 Number of ON (black) cells in the n-th iteration of the "Rule 15" elementary cellular automaton starting with a single ON (black) cell.
   # A266304 Total number of OFF (white) cells after n iterations of the "Rule 15" elementary cellular automaton starting with a single ON (black) cell.
   # A266323 Binary representation of the n-th iteration of the "Rule 19" elementary cellular automaton starting with a single ON (black) cell.
   # A266324 Decimal representation of the n-th iteration of the "Rule 19" elementary cellular automaton starting with a single ON (black) cell.
   # A266326 Triangle read by rows giving successive states of cellular automaton generated by "Rule 20" initiated with a single ON (black) cell.
   # A266327 Binary representation of the n-th iteration of the "Rule 20" elementary cellular automaton starting with a single ON (black) cell.
   # A266377 Triangle read by rows giving successive states of cellular automaton generated by "Rule 21" initiated with a single ON (black) cell.
   # A266379 Binary representation of the n-th iteration of the "Rule 21" elementary cellular automaton starting with a single ON (black) cell.
   # A266380 Decimal representation of the n-th iteration of the "Rule 21" elementary cellular automaton starting with a single ON (black) cell.
   # A266381 Binary representation of the n-th iteration of the "Rule 22" elementary cellular automaton starting with a single ON (black) cell.
   # A266382 Decimal representation of the n-th iteration of the "Rule 22" elementary cellular automaton starting with a single ON (black) cell.
   # A266383 Total number of ON (black) cells after n iterations of the "Rule 22" elementary cellular automaton starting with a single ON (black) cell.
   # A266384 Total number of OFF (white) cells after n iterations of the "Rule 22" elementary cellular automaton starting with a single ON (black) cell.
   # A266434 Triangle read by rows giving successive states of cellular automaton generated by "Rule 23" initiated with a single ON (black) cell.
   # A266435 Binary representation of the n-th iteration of the "Rule 23" elementary cellular automaton starting with a single ON (black) cell.
   # A266436 Decimal representation of the n-th iteration of the "Rule 23" elementary cellular automaton starting with a single ON (black) cell.
   # A266437 Number of ON (black) cells in the n-th iteration of the "Rule 23" elementary cellular automaton starting with a single ON (black) cell.
   # A266438 Total number of ON (black) cells after n iterations of the "Rule 23" elementary cellular automaton starting with a single ON (black) cell.
   # A266439 Number of OFF (white) cells in the n-th iteration of the "Rule 23" elementary cellular automaton starting with a single ON (black) cell.
   # A266440 Total number of OFF (white) cells after n iterations of the "Rule 23" elementary cellular automaton starting with a single ON (black) cell.
   # A266441 Triangle read by rows giving successive states of cellular automaton generated by "Rule 25" initiated with a single ON (black) cell.
   # A266442 Binary representation of the n-th iteration of the "Rule 25" elementary cellular automaton starting with a single ON (black) cell.
   # A266443 Decimal representation of the n-th iteration of the "Rule 25" elementary cellular automaton starting with a single ON (black) cell.
   # A266444 Middle column of the "Rule 25" elementary cellular automaton starting with a single ON (black) cell.
   # A266445 Binary representation of the middle column of the "Rule 25" elementary cellular automaton starting with a single ON (black) cell.
   # A266446 Decimal representation of the middle column of the "Rule 25" elementary cellular automaton starting with a single ON (black) cell.
   # A266447 Number of ON (black) cells in the n-th iteration of the "Rule 25" elementary cellular automaton starting with a single ON (black) cell.
   # A266448 Total number of ON (black) cells after n iterations of the "Rule 25" elementary cellular automaton starting with a single ON (black) cell.
   # A266449 Number of OFF (white) cells in the n-th iteration of the "Rule 25" elementary cellular automaton starting with a single ON (black) cell.
   # A266450 Total number of OFF (white) cells after n iterations of the "Rule 25" elementary cellular automaton starting with a single ON (black) cell.
   # A266459 Triangle read by rows giving successive states of cellular automaton generated by "Rule 27" initiated with a single ON (black) cell.
   # A266460 Binary representation of the n-th iteration of the "Rule 27" elementary cellular automaton starting with a single ON (black) cell.
   # A266461 Decimal representation of the n-th iteration of the "Rule 27" elementary cellular automaton starting with a single ON (black) cell.
   # A266502 Triangle read by rows giving successive states of cellular automaton generated by "Rule 28" initiated with a single ON (black) cell.
   # A266508 Binary representation of the n-th iteration of the "Rule 28" elementary cellular automaton starting with a single ON (black) cell.
   # A266514 Triangle read by rows giving successive states of cellular automaton generated by "Rule 29" initiated with a single ON (black) cell.
   # A266515 Binary representation of the n-th iteration of the "Rule 29" elementary cellular automaton starting with a single ON (black) cell.
   # A266516 Decimal representation of the n-th iteration of the "Rule 29" elementary cellular automaton starting with a single ON (black) cell.
   # A266588 Triangle read by rows giving successive states of cellular automaton generated by "Rule 37" initiated with a single ON (black) cell.
   # A266589 Binary representation of the n-th iteration of the "Rule 37" elementary cellular automaton starting with a single ON (black) cell.
   # A266590 Decimal representation of the n-th iteration of the "Rule 37" elementary cellular automaton starting with a single ON (black) cell.
   # A266591 Middle column of the "Rule 37" elementary cellular automaton starting with a single ON (black) cell.
   # A266592 Binary representation of the middle column of the "Rule 37" elementary cellular automaton starting with a single ON (black) cell.
   # A266593 Number of ON (black) cells in the n-th iteration of the "Rule 37" elementary cellular automaton starting with a single ON (black) cell.
   # A266594 Total number of ON (black) cells after n iterations of the "Rule 37" elementary cellular automaton starting with a single ON (black) cell.
   # A266595 Number of OFF (white) cells in the n-th iteration of the "Rule 37" elementary cellular automaton starting with a single ON (black) cell.
   # A266596 Total number of OFF (white) cells after n iterations of the "Rule 37" elementary cellular automaton starting with a single ON (black) cell.
   # A266605 Triangle read by rows giving successive states of cellular automaton generated by "Rule 39" initiated with a single ON (black) cell.
   # A266606 Binary representation of the n-th iteration of the "Rule 39" elementary cellular automaton starting with a single ON (black) cell.
   # A266607 Decimal representation of the n-th iteration of the "Rule 39" elementary cellular automaton starting with a single ON (black) cell.
   # A266608 Triangle read by rows giving successive states of cellular automaton generated by "Rule 41" initiated with a single ON (black) cell.
   # A266609 Binary representation of the n-th iteration of the "Rule 41" elementary cellular automaton starting with a single ON (black) cell.
   # A266610 Decimal representation of the n-th iteration of the "Rule 41" elementary cellular automaton starting with a single ON (black) cell.
   # A266611 Middle column of the "Rule 41" elementary cellular automaton starting with a single ON (black) cell.
   # A266612 Binary representation of the middle column of the "Rule 41" elementary cellular automaton starting with a single ON (black) cell.
   # A266613 Decimal representation of the middle column of the "Rule 41" elementary cellular automaton starting with a single ON (black) cell.
   # A266614 Number of ON (black) cells in the n-th iteration of the "Rule 41" elementary cellular automaton starting with a single ON (black) cell.
   # A266615 Total number of ON (black) cells after n iterations of the "Rule 41" elementary cellular automaton starting with a single ON (black) cell.
   # A266616 Number of OFF (white) cells in the n-th iteration of the "Rule 41" elementary cellular automaton starting with a single ON (black) cell.
   # A266617 Total number of OFF (white) cells after n iterations of the "Rule 41" elementary cellular automaton starting with a single ON (black) cell.
   # A266619 Triangle read by rows giving successive states of cellular automaton generated by "Rule 45" initiated with a single ON (black) cell.
   # A266621 Binary representation of the n-th iteration of the "Rule 45" elementary cellular automaton starting with a single ON (black) cell.
   # A266622 Decimal representation of the n-th iteration of the "Rule 45" elementary cellular automaton starting with a single ON (black) cell.
   # A266623 Middle column of the "Rule 45" elementary cellular automaton starting with a single ON (black) cell.
   # A266624 Binary representation of the middle column of the "Rule 45" elementary cellular automaton starting with a single ON (black) cell.
   # A266625 Decimal representation of the middle column of the "Rule 45" elementary cellular automaton starting with a single ON (black) cell.
   # A266626 Number of ON (black) cells in the n-th iteration of the "Rule 45" elementary cellular automaton starting with a single ON (black) cell.
   # A266627 Total number of ON (black) cells after n iterations of the "Rule 45" elementary cellular automaton starting with a single ON (black) cell.
   # A266628 Number of OFF (white) cells in the n-th iteration of the "Rule 45" elementary cellular automaton starting with a single ON (black) cell.
   # A266629 Total number of OFF (white) cells after n iterations of the "Rule 45" elementary cellular automaton starting with a single ON (black) cell.
   # A266659 Triangle read by rows giving successive states of cellular automaton generated by "Rule 47" initiated with a single ON (black) cell.
   # A266660 Binary representation of the n-th iteration of the "Rule 47" elementary cellular automaton starting with a single ON (black) cell.
   # A266661 Decimal representation of the n-th iteration of the "Rule 47" elementary cellular automaton starting with a single ON (black) cell.
   # A266662 Number of ON (black) cells in the n-th iteration of the "Rule 47" elementary cellular automaton starting with a single ON (black) cell.
   # A266663 Total number of ON (black) cells after n iterations of the "Rule 47" elementary cellular automaton starting with a single ON (black) cell.
   # A266664 Number of OFF (white) cells in the n-th iteration of the "Rule 47" elementary cellular automaton starting with a single ON (black) cell.
   # A266665 Total number of OFF (white) cells after n iterations of the "Rule 47" elementary cellular automaton starting with a single ON (black) cell.
   # A266666 Triangle read by rows giving successive states of cellular automaton generated by "Rule 51" initiated with a single ON (black) cell.
   # A266667 Binary representation of the n-th iteration of the "Rule 51" elementary cellular automaton starting with a single ON (black) cell.
   # A266668 Decimal representation of the n-th iteration of the "Rule 51" elementary cellular automaton starting with a single ON (black) cell.
   # A266669 Triangle read by rows giving successive states of cellular automaton generated by "Rule 53" initiated with a single ON (black) cell.
   # A266670 Binary representation of the n-th iteration of the "Rule 53" elementary cellular automaton starting with a single ON (black) cell.
   # A266671 Decimal representation of the n-th iteration of the "Rule 53" elementary cellular automaton starting with a single ON (black) cell.
   # A266672 Triangle read by rows giving successive states of cellular automaton generated by "Rule 57" initiated with a single ON (black) cell.
   # A266673 Binary representation of the n-th iteration of the "Rule 57" elementary cellular automaton starting with a single ON (black) cell.
   # A266674 Decimal representation of the n-th iteration of the "Rule 57" elementary cellular automaton starting with a single ON (black) cell.
   # A266678 Middle column of the "Rule 175" elementary cellular automaton starting with a single ON (black) cell.
   # A266680 Binary representation of the middle column of the "Rule 175" elementary cellular automaton starting with a single ON (black) cell.
   # A266716 Triangle read by rows giving successive states of cellular automaton generated by "Rule 59" initiated with a single ON (black) cell.
   # A266717 Binary representation of the n-th iteration of the "Rule 59" elementary cellular automaton starting with a single ON (black) cell.
   # A266718 Decimal representation of the n-th iteration of the "Rule 59" elementary cellular automaton starting with a single ON (black) cell.
   # A266719 Middle column of the "Rule 59" elementary cellular automaton starting with a single ON (black) cell.
   # A266720 Binary representation of the middle column of the "Rule 59" elementary cellular automaton starting with a single ON (black) cell.
   # A266721 Decimal representation of the middle column of the "Rule 59" elementary cellular automaton starting with a single ON (black) cell.
   # A266722 Number of ON (black) cells in the n-th iteration of the "Rule 59" elementary cellular automaton starting with a single ON (black) cell.
   # A266723 Total number of ON (black) cells after n iterations of the "Rule 59" elementary cellular automaton starting with a single ON (black) cell.
   # A266724 Number of OFF (white) cells in the n-th iteration of the "Rule 59" elementary cellular automaton starting with a single ON (black) cell.
   # A266725 Total number of OFF (white) cells after n iterations of the "Rule 59" elementary cellular automaton starting with a single ON (black) cell.
   # A266752 Binary representation of the n-th iteration of the "Rule 163" elementary cellular automaton starting with a single ON (black) cell.
   # A266753 Decimal representation of the n-th iteration of the "Rule 163" elementary cellular automaton starting with a single ON (black) cell.
   # A266754 Triangle read by rows giving successive states of cellular automaton generated by "Rule 165" initiated with a single ON (black) cell.
   # A266786 Triangle read by rows giving successive states of cellular automaton generated by "Rule 61" initiated with a single ON (black) cell.
   # A266787 Binary representation of the n-th iteration of the "Rule 61" elementary cellular automaton starting with a single ON (black) cell.
   # A266788 Decimal representation of the n-th iteration of the "Rule 61" elementary cellular automaton starting with a single ON (black) cell.
   # A266789 Middle column of the "Rule 61" elementary cellular automaton starting with a single ON (black) cell.
   # A266790 Binary representation of the middle column of the "Rule 61" elementary cellular automaton starting with a single ON (black) cell.
   # A266791 Decimal representation of the middle column of the "Rule 61" elementary cellular automaton starting with a single ON (black) cell.
   # A266792 Number of ON (black) cells in the n-th iteration of the "Rule 61" elementary cellular automaton starting with a single ON (black) cell.
   # A266793 Total number of ON (black) cells after n iterations of the "Rule 61" elementary cellular automaton starting with a single ON (black) cell.
   # A266794 Number of OFF (white) cells in the n-th iteration of the "Rule 61" elementary cellular automaton starting with a single ON (black) cell.
   # A266795 Total number of OFF (white) cells after n iterations of the "Rule 61" elementary cellular automaton starting with a single ON (black) cell.
   # A266809 Binary representation of the n-th iteration of the "Rule 62" elementary cellular automaton starting with a single ON (black) cell.
   # A266810 Decimal representation of the n-th iteration of the "Rule 62" elementary cellular automaton starting with a single ON (black) cell.
   # A266811 Total number of ON (black) cells after n iterations of the "Rule 62" elementary cellular automaton starting with a single ON (black) cell.
   # A266813 Total number of OFF (white) cells after n iterations of the "Rule 62" elementary cellular automaton starting with a single ON (black) cell.

   [ 'A266837',   67, 'bits' ],
   [ 'A266838',   67, 'bignum', base=>2 ],
   [ 'A266839',   67, 'bignum' ],

   [ 'A266840',   69, 'bits' ],
   [ 'A266841',   69, 'bignum', base=>2 ],
   [ 'A266842',   69, 'bignum' ],

   [ 'A266843',   70, 'bits' ],
   [ 'A266844',   70, 'bignum', base=>2 ],
   [ 'A266846',   70, 'bignum' ],
   [ 'A071022',   70, 'bits', part=>'left' ],

   [ 'A266848',   71, 'bits' ],
   [ 'A266849',   71, 'bignum', base=>2 ],
   [ 'A266850',   71, 'bignum' ],

   [ 'A266892',   75, 'bits' ],
   [ 'A266893',   75, 'bignum', base=>2 ],
   [ 'A266894',   75, 'bignum' ],
   [ 'A266895',   75, 'bits', part => 'centre' ],
   [ 'A266896',   75, 'bignum_central_column' ],
   [ 'A266897',   75, 'bignum_central_column', base=>2 ],
   [ 'A266900',   75, 'number_of', value=>0 ],
   [ 'A266898',   75, 'number_of', value=>1 ],

   [ 'A266872',   77, 'bignum', base=>2 ],
   [ 'A266873',   77, 'bignum' ],

   [ 'A266974',   78, 'bits' ],
   [ 'A266975',   78, 'bignum', base=>2 ],
   [ 'A266976',   78, 'bignum' ],
   [ 'A266977',   78, 'number_of', value=>1 ],

   [ 'A266978',   79, 'bits' ],
   [ 'A266979',   79, 'bignum', base=>2 ],
   [ 'A266980',   79, 'bignum' ],
   [ 'A266981',   79, 'number_of', value=>1 ],

   [ 'A266982',   81, 'bits' ],
   [ 'A266983',   81, 'bignum', base=>2 ],
   [ 'A266984',   81, 'bignum' ],

   [ 'A267001',   83, 'bits' ],
   [ 'A267002',   83, 'bignum', base=>2 ],
   [ 'A267003',   83, 'bignum' ],

   [ 'A267006',   84, 'bits' ],

   [ 'A267034',   85, 'bits' ],
   [ 'A267035',   85, 'bignum', base=>2 ],
   [ 'A267036',   85, 'bignum' ],

   [ 'A265280',   86, 'bignum', base=>2 ],
   [ 'A265281',   86, 'bignum' ],

   [ 'A267037',   89, 'bits' ],
   [ 'A267038',   89, 'bignum', base=>2 ],
   [ 'A267039',   89, 'bignum' ],

   [ 'A265172',   90, 'bignum', base=>2 ],
   
   [ 'A267015',   91, 'bits' ],
   [ 'A267041',   91, 'bignum', base=>2 ],
   [ 'A267042',   91, 'bignum' ],
   [ 'A267043',   91, 'bits', part => 'centre' ],
   [ 'A267044',   91, 'bignum_central_column' ],
   [ 'A267045',   91, 'bignum_central_column', base=>2 ],
   [ 'A267048',   91, 'number_of', value=>0 ],
   [ 'A267046',   91, 'number_of', value=>1 ],

   [ 'A267050',   92, 'bits' ],
   [ 'A267051',   92, 'bignum', base=>2 ],
   [ 'A267052',   92, 'bignum' ],

   [ 'A267053',   93, 'bits' ],
   [ 'A267054',   93, 'bignum', base=>2 ],
   [ 'A267055',   93, 'bignum' ],

   [ 'A267056',   97, 'bits' ],
   [ 'A267057',   97, 'bignum', base=>2 ],
   [ 'A267058',   97, 'bignum' ],

   [ 'A267126',   99, 'bits' ],
   [ 'A267127',   99, 'bignum', base=>2 ],
   [ 'A267128',   99, 'bignum' ],

   [ 'A267129',  101, 'bits' ],
   [ 'A267130',  101, 'bignum', base=>2 ],
   [ 'A267131',  101, 'bignum' ],

   [ 'A265319',  102, 'bignum', base=>2 ],

   [ 'A267136',  103, 'bits' ],
   [ 'A267138',  103, 'bignum', base=>2 ],
   [ 'A267139',  103, 'bignum' ],

   [ 'A267145',  105, 'bits' ],
   [ 'A267146',  105, 'bignum', base=>2 ],
   [ 'A267147',  105, 'bignum' ],
   [ 'A267150',  105, 'number_of', value=>0 ],
   [ 'A267148',  105, 'number_of', value=>1 ],

   [ 'A267152',  107, 'bits' ],
   [ 'A267153',  107, 'bignum', base=>2 ],
   [ 'A267154',  107, 'bignum' ],
   [ 'A267155',  107, 'bits', part => 'centre' ],
   [ 'A267156',  107, 'bignum_central_column' ],
   [ 'A267157',  107, 'bignum_central_column', base=>2 ],
   [ 'A267160',  107, 'number_of', value=>0 ],
   [ 'A267158',  107, 'number_of', value=>1 ],

   [ 'A243566',  109, 'bits' ],
   [ 'A267206',  109, 'bignum', base=>2 ],
   [ 'A267207',  109, 'bignum' ],
   [ 'A267208',  109, 'bits', part => 'centre' ],
   [ 'A267209',  109, 'bignum_central_column' ],
   [ 'A267210',  109, 'bignum_central_column', base=>2 ],
   [ 'A267213',  109, 'number_of', value=>0 ],
   [ 'A267211',  109, 'number_of', value=>1 ],

   [ 'A265320',  110, 'bignum', base=>2 ],

   [ 'A267253',  111, 'bits' ],
   [ 'A267254',  111, 'bignum', base=>2 ],
   [ 'A267255',  111, 'bignum' ],
   [ 'A267256',  111, 'bits', part => 'centre' ],
   [ 'A267257',  111, 'bignum_central_column' ],
   [ 'A267258',  111, 'bignum_central_column', base=>2 ],

   [ 'A267269',  115, 'bits' ],
   [ 'A267270',  115, 'bignum', base=>2 ],
   [ 'A267271',  115, 'bignum' ],

   [ 'A267272',  117, 'bits' ],
   [ 'A267273',  117, 'bignum', base=>2 ],
   [ 'A267274',  117, 'bignum' ],

   [ 'A267275',  118, 'bignum', base=>2 ],
   [ 'A267276',  118, 'bignum' ],

   [ 'A267292',  121, 'bits' ],
   [ 'A267293',  121, 'bignum', base=>2 ],
   [ 'A267294',  121, 'bignum' ],

   [ 'A267349',  123, 'bits' ],
   [ 'A267350',  123, 'bignum', base=>2 ],
   [ 'A267351',  123, 'bignum' ],

   [ 'A267355',  124, 'bits' ],
   [ 'A267356',  124, 'bignum', base=>2 ],
   [ 'A267357',  124, 'bignum' ],

   [ 'A267358',  125, 'bits' ],
   [ 'A267359',  125, 'bignum', base=>2 ],
   [ 'A267360',  125, 'bignum' ],

   [ 'A071035',  126, 'bits' ],
   [ 'A267364',  126, 'bignum', base=>2 ],
   [ 'A267365',  126, 'bignum' ],
   [ 'A267366',  126, 'bignum_central_column' ],
   [ 'A267367',  126, 'bignum_central_column', base=>2 ],

   [ 'A267417',  129, 'bits' ],
   [ 'A267440',  129, 'bignum', base=>2 ],
   [ 'A267441',  129, 'bignum' ],
   [ 'A267442',  129, 'bits', part => 'centre' ],
   [ 'A267443',  129, 'bignum_central_column' ],
   [ 'A267444',  129, 'bignum_central_column', base=>2 ],

   [ 'A267418',  131, 'bits' ],
   [ 'A267449',  131, 'bignum', base=>2 ],
   [ 'A267450',  131, 'bignum' ],

   [ 'A267423',  133, 'bits' ],
   [ 'A267456',  133, 'bignum', base=>2 ],
   [ 'A267457',  133, 'bignum' ],

   [ 'A267463',  137, 'bits' ],
   [ 'A267511',  137, 'bignum', base=>2 ],
   [ 'A267512',  137, 'bignum' ],
   [ 'A267513',  137, 'bits', part => 'centre' ],
   [ 'A267514',  137, 'bignum_central_column' ],
   [ 'A267515',  137, 'bignum_central_column', base=>2 ],

   [ 'A267520',  139, 'bits' ],
   [ 'A267523',  139, 'bignum', base=>2 ],
   [ 'A267524',  139, 'bignum_central_column' ],

   [ 'A267525',  141, 'bits' ],
   [ 'A267526',  141, 'bignum', base=>2 ],
   [ 'A267527',  141, 'bignum' ],

   [ 'A267533',  143, 'bits' ],
   [ 'A267535',  143, 'bignum', base=>2 ],
   [ 'A267536',  143, 'bignum' ],
   [ 'A267537',  143, 'bits', part => 'centre' ],
   [ 'A267538',  143, 'bignum_central_column' ],
   [ 'A267539',  143, 'bignum_central_column', base=>2 ],

   [ 'A262805',  145, 'bits' ],
   [ 'A262860',  145, 'bignum' ],
   [ 'A262859',  145, 'bignum', base=>2 ],

   [ 'A262808',  147, 'bits' ],
   [ 'A262862',  147, 'bignum' ],
   [ 'A262861',  147, 'bignum', base=>2 ],
   [ 'A262864',  147, 'bignum_central_column', base=>2 ],
   [ 'A262863',  147, 'bignum_central_column' ],

   [ 'A265246',  149, 'bits' ],

   [ 'A262866',  153, 'bignum' ],
   [ 'A262855',  153, 'bits' ],
   [ 'A262865',  153, 'bignum', part => 'centre', base=>2 ],
   
   [ 'A263243',  155, 'bits' ],
   [ 'A263244',  155, 'bignum', base=>2 ],
   [ 'A263245',  155, 'bignum' ],
   
   [ 'A263804',  157, 'bits' ],
   [ 'A263805',  157, 'bignum', base=>2 ],
   [ 'A263806',  157, 'bignum' ],
   
   [ 'A265379',  158, 'bignum', base=>2 ],
   [ 'A265380',  158, 'bignum_central_column' ],
   [ 'A265381',  158, 'bignum_central_column', base=>2 ],
   
   [ 'A263919',  163, 'bits' ],

   [ 'A267246',  165, 'bignum', base=>2 ],
   [ 'A267247',  165, 'bignum' ],

   [ 'A267576',  167, 'bits' ],
   [ 'A267577',  167, 'bignum', base=>2 ],
   [ 'A267578',  167, 'bignum' ],
   [ 'A267579',  167, 'bits', part => 'centre' ],
   [ 'A267580',  167, 'bignum_central_column' ],
   [ 'A267581',  167, 'bignum_central_column', base=>2 ],

   [ 'A264442',  169, 'bits' ],
   [ 'A267585',  169, 'bignum', base=>2 ],
   [ 'A267586',  169, 'bignum' ],
   [ 'A267587',  169, 'bits', part => 'centre' ],
   [ 'A267588',  169, 'bignum_central_column' ],
   [ 'A267589',  169, 'bignum_central_column', base=>2 ],

   [ 'A267594',  173, 'bits' ],
   [ 'A267595',  173, 'bignum', base=>2 ],
   [ 'A267596',  173, 'bignum' ],

   [ 'A265186',  175, 'bits' ],
   [ 'A262779',  175, 'bignum', base=>2 ],
   [ 'A267604',  175, 'bignum_central_column', base=>2 ],

   [ 'A267598',  177, 'bits' ],
   [ 'A267599',  177, 'bignum', base=>2 ],

   [ 'A267605',  181, 'bits' ],
   [ 'A267606',  181, 'bignum', base=>2 ],
   [ 'A267607',  181, 'bignum' ],

   [ 'A267608',  182, 'bignum', base=>2 ],
   [ 'A267609',  182, 'bignum' ],

   [ 'A267612',  185, 'bits' ],
   [ 'A267613',  185, 'bignum', base=>2 ],
   [ 'A267614',  185, 'bignum' ],

   [ 'A267621',  187, 'bits' ],
   [ 'A267622',  187, 'bignum', base=>2 ],
   [ 'A267623',  187, 'bignum_central_column' ],

   [ 'A265427',  188, 'bignum', base=>2 ],

   [ 'A267635',  189, 'bits' ],

   [ 'A267636',  193, 'bits' ],
   [ 'A267645',  193, 'bignum', base=>2 ],
   [ 'A267646',  193, 'bignum' ],

   [ 'A267673',  195, 'bits' ],
   [ 'A267674',  195, 'bignum', base=>2 ],
   [ 'A267675',  195, 'bignum' ],

   [ 'A267676',  197, 'bits' ],
   [ 'A267677',  197, 'bignum', base=>2 ],
   [ 'A267678',  197, 'bignum' ],

   [ 'A267687',  199, 'bits' ],
   [ 'A267688',  199, 'bignum', base=>2 ],
   [ 'A267689',  199, 'bignum' ],

   [ 'A267679',  201, 'bits' ],
   [ 'A267680',  201, 'bignum', base=>2 ],
   [ 'A267681',  201, 'bignum' ],
   [ 'A267682',  201, 'number_of', cumulative=>1 ],

   [ 'A267683',  203, 'bits' ],
   [ 'A267684',  203, 'bignum', base=>2 ],
   [ 'A267685',  203, 'bignum' ],

   [ 'A267704',  205, 'bits' ],
   [ 'A267705',  205, 'bignum', base=>2 ],

   [ 'A267708',  206, 'bits' ],

   [ 'A267773',  207, 'bits' ],
   [ 'A267774',  207, 'bignum' ],
   [ 'A267775',  207, 'bignum', base=>2 ],

   [ 'A267776',  209, 'bits' ],
   [ 'A267777',  209, 'bignum', base=>2 ],

   [ 'A267778',  211, 'bits' ],
   [ 'A267779',  211, 'bignum', base=>2 ],
   [ 'A267780',  211, 'bignum' ],

   [ 'A267800',  213, 'bits' ],
   [ 'A267801',  213, 'bignum', base=>2 ],
   [ 'A267802',  213, 'bignum' ],

   [ 'A267804',  214, 'bignum', base=>2 ],
   [ 'A267805',  214, 'bignum' ],

   [ 'A267810',  217, 'bits' ],
   [ 'A267811',  217, 'bignum', base=>2 ],
   [ 'A267812',  217, 'bignum' ],

   [ 'A267813',  219, 'bits' ],

   [ 'A267814',  221, 'bits' ],
   [ 'A267815',  221, 'bignum', base=>2 ],
   [ 'A267816',  221, 'bignum' ],

   [ 'A267841',  225, 'bits' ],
   [ 'A267842',  225, 'bignum', base=>2 ],
   [ 'A267843',  225, 'bignum' ],

   [ 'A267845',  227, 'bits' ],
   [ 'A267846',  227, 'bignum', base=>2 ],
   [ 'A267847',  227, 'bignum' ],

   [ 'A267848',  229, 'bits' ],
   [ 'A267850',  229, 'bignum', base=>2 ],
   [ 'A267851',  229, 'bignum' ],

   [ 'A267853',  230, 'bits' ],
   [ 'A267854',  230, 'bignum', base=>2 ],
   [ 'A267855',  230, 'bignum' ],

   [ 'A267866',  231, 'bits' ],
   [ 'A267867',  231, 'bignum', base=>2 ],
   [ 'A267868',  233, 'bits' ],
   [ 'A267869',  235, 'bits' ],
   [ 'A267870',  237, 'bits' ],
   [ 'A267871',  239, 'bits' ],
   
   [ 'A267876',  233, 'bignum', base=>2 ],
   [ 'A267877',  233, 'bignum' ],
   [ 'A267878',  233, 'bits', part => 'centre' ],
   [ 'A267879',  233, 'bignum_central_column' ],

   [ 'A267885',  235, 'bignum', base=>2 ],
   [ 'A267886',  235, 'bignum' ],
   
   [ 'A267887',  237, 'bignum', base=>2 ],
   [ 'A267888',  237, 'bignum' ],
   
   [ 'A267889',  239, 'bignum', base=>2 ],
   [ 'A267890',  239, 'bignum' ],
   
   [ 'A267919',  243, 'bits' ],
   [ 'A267920',  243, 'bignum', base=>2 ],
   [ 'A267921',  243, 'bignum' ],
   
   [ 'A267922',  245, 'bits' ],
   [ 'A267923',  245, 'bignum', base=>2 ],
   [ 'A267924',  245, 'bignum' ],
   
   [ 'A267925',  246, 'bignum', base=>2 ],
   [ 'A267926',  246, 'bignum' ],
   
   [ 'A267927',  249, 'bits' ],
   [ 'A267934',  249, 'bignum', base=>2 ],
   [ 'A267935',  249, 'bignum' ],
   
   [ 'A267936',  251, 'bits' ],
   [ 'A267937',  251, 'bignum', base=>2 ],
   [ 'A267938',  251, 'bignum' ],
   
   [ 'A267940',  253, 'bignum', base=>2 ],
   [ 'A267941',  253, 'bignum' ],
   
   
   [ 'A265122',   73, 'bignum', base=>2 ],
   [ 'A265156',   73, 'bignum' ],
   
   [ 'A263428',    3, 'bits' ],
   
   [ 'A262448',   73, 'bits' ],
   
   [ 'A259661',   54, 'bignum_central_column' ],
   [ 'A260552',   17, 'bits' ],
   [ 'A260692',   17, 'bignum', base=>2 ],
   [ 'A261299',   30, 'bignum_central_column' ],
   
   
   
   
   
   [ 'A098608',   2, 'bignum', base=>2 ],  # 100^n
   [ 'A011557',   4, 'bignum', base=>2 ],  # 10^n
   [ 'A245549',  30, 'bignum', base=>2 ],
   [ 'A094028',  50, 'bignum', base=>2 ],
   [ 'A006943',  60, 'bignum', base=>2 ],  # Sierpinski
   [ 'A245548', 150, 'bignum', base=>2 ],
   [ 'A100706', 151, 'bignum', base=>2 ],
   [ 'A109241', 206, 'bignum', base=>2 ],
   [ 'A000042', 220, 'bignum', base=>2 ],  # half-width 1s
   
   # http://oeis.org/A118110
   # http://oeis.org/A245548
   
   # characteristic func of pronics m*(m+1)
   # rule=4,12,36,44,68,76,100,108,132,140,164,172,196,204,228,236
   [ 'A005369',   4, 'bits' ],
   
   [ 'A071022', 198, 'bits', part=>'left' ],
   [ 'A071023',  78, 'bits', part=>'left' ],
   [ 'A071024',  92, 'bits', part=>'right' ],
   [ 'A071025', 124, 'bits', part=>'right' ],
   [ 'A071026', 188, 'bits', part=>'right' ],
   [ 'A071027', 230, 'bits', part=>'left' ],
   [ 'A071028',  50, 'bits' ],
   [ 'A071029',  22, 'bits' ],
   [ 'A071030',  54, 'bits' ],
   [ 'A071031',  62, 'bits' ],
   [ 'A071032',  86, 'bits' ],
   [ 'A071033',  94, 'bignum', base=>2 ],
   [ 'A071034', 118, 'bits' ],
   [ 'A071036', 150, 'bits' ],  # same as A118110
   [ 'A071037', 158, 'bits' ],
   [ 'A071038', 182, 'bits' ],
   [ 'A071039', 190, 'bits' ],
   [ 'A071040', 214, 'bits' ],
   [ 'A071041', 246, 'bits' ],
   
   # [ 'A060576', 255, 'bits' ], # homeomorphically irreducibles ...
   
   [ 'A070909',  28, 'bits', part=>'right' ],
   [ 'A070909', 156, 'bits', part=>'right' ],
   
   [ 'A075437', 110, 'bits' ],
   
   [ 'A118101',  94, 'bignum' ],
   [ 'A118102',  94, 'bits' ],
   [ 'A118108',  54, 'bignum' ],
   [ 'A118109',  54, 'bignum', base=>2 ],
   [ 'A118110', 150, 'bignum', base=>2 ],
   [ 'A118111', 190, 'bits' ],
   [ 'A118171', 158, 'bignum' ],
   [ 'A118172', 158, 'bits' ],
   [ 'A118173', 188, 'bignum' ],
   [ 'A118174', 188, 'bits' ],
   [ 'A118175', 220, 'bits' ],
   [ 'A118175', 252, 'bits' ],
   
   [ 'A070887', 110, 'bits', part=>'left' ],
   
   [ 'A071042',  90, 'number_of', value=>0 ],
   [ 'A071043',  22, 'number_of', value=>0 ],
   [ 'A071044',  22, 'number_of', value=>1 ],
   [ 'A071045',  54, 'number_of', value=>0 ],
   [ 'A071046',  62, 'number_of', value=>0 ],
   [ 'A071047',  62, 'number_of', value=>1 ],
   [ 'A071049', 110, 'number_of', value=>1, initial=>[0] ],
   [ 'A071048', 110, 'number_of', value=>0, part=>'left' ],
   [ 'A071050', 126, 'number_of', value=>0 ],
   [ 'A071051', 126, 'number_of', value=>1 ],
   [ 'A071052', 150, 'number_of', value=>0 ],
   [ 'A071053', 150, 'number_of', value=>1 ],
   [ 'A071054', 158, 'number_of', value=>1 ],
   [ 'A071055', 182, 'number_of', value=>0 ],

   [ 'A038184', 150, 'bignum' ],
   [ 'A038185', 150, 'bignum', part=>'left' ], # cut after central column

   [ 'A001045',  28, 'bignum', initial=>[0,1] ], # Jacobsthal
   [ 'A110240',  30, 'bignum' ], # cf A074890 some strange form
   [ 'A117998', 102, 'bignum' ],
   [ 'A117999', 110, 'bignum' ],
   [ 'A037576', 190, 'bignum' ],
   [ 'A002450', 250, 'bignum', initial=>[0] ], # (4^n-1)/3 10101 extra 0 start

   [ 'A006977', 230, 'bignum', part=>'left' ],
   [ 'A078176', 225, 'bignum', part=>'whole', ystart=>1, inverse=>1 ],

   [ 'A051023',  30, 'bits', part=>'centre' ],
   [ 'A070950',  30, 'bits' ],
   [ 'A070951',  30, 'number_of', value=>0 ],
   [ 'A070952',  30, 'number_of', value=>1, max_count=>400, initial=>[0] ],
   [ 'A151929',  30, 'number_of_1s_first_diff', max_count=>200,
     initial=>[0], # without diffs yet applied ...
   ],
   [ 'A092539',  30, 'bignum_central_column', base=>2 ],
   [ 'A094603',  30, 'trailing_number_of', value=>1 ],
   [ 'A094604',  30, 'new_maximum_trailing_number_of', 1 ],

   [ 'A001316',  90, 'number_of', value=>1 ], # Gould's sequence


   #--------------------------------------------------------------------------
   # Sierpinski triangle, 8 of whole
   
   # rule=60 right half
   [ 'A047999',  60, 'bits', part=>'right' ], # Sierpinski triangle  in right
   [ 'A001317',  60, 'bignum' ], # Sierpinski triangle right half
   [ 'A075438',  60, 'bits' ], # including 0s in left half

   # rule=102 left half
   [ 'A047999', 102, 'bits', part=>'left' ],
   [ 'A075439', 102, 'bits' ],

   [ 'A038183',  18, 'bignum' ], # Sierpinski bignums
   [ 'A038183',  26, 'bignum' ],
   [ 'A038183',  82, 'bignum' ],
   [ 'A038183',  90, 'bignum' ],
   [ 'A038183', 146, 'bignum' ],
   [ 'A038183', 154, 'bignum' ],
   [ 'A038183', 210, 'bignum' ],
   [ 'A038183', 218, 'bignum' ],

   [ 'A070886',  18, 'bits' ], # Sierpinski 0/1
   [ 'A070886',  26, 'bits' ],
   [ 'A070886',  82, 'bits' ],
   [ 'A070886',  90, 'bits' ],
   [ 'A070886', 146, 'bits' ],
   [ 'A070886', 154, 'bits' ],
   [ 'A070886', 210, 'bits' ],
   [ 'A070886', 218, 'bits' ],

   #--------------------------------------------------------------------------
   # simple stuff

   # whole solid, values 2^(2n)-1
   [ 'A083420', 151, 'bignum' ], # 8 of
   [ 'A083420', 159, 'bignum' ],
   [ 'A083420', 183, 'bignum' ],
   [ 'A083420', 191, 'bignum' ],
   [ 'A083420', 215, 'bignum' ],
   [ 'A083420', 223, 'bignum' ],
   [ 'A083420', 247, 'bignum' ],
   [ 'A083420', 254, 'bignum' ],
   # and also
   [ 'A083420', 222, 'bignum' ], # 2 of
   [ 'A083420', 255, 'bignum' ],

   # right half solid 2^n-1
   [ 'A000225', 220, 'bignum', initial=>[0] ], # 2^n-1 want start from 1
   [ 'A000225', 252, 'bignum', initial=>[0] ],

   # left half solid, # 2^n-1
   [ 'A000225', 206, 'bignum', part=>'left', initial=>[0] ], # 0xCE
   [ 'A000225', 238, 'bignum', part=>'left', initial=>[0] ], # 0xEE

   # central column only, values all 1s
   [ 'A000012',   4, 'bignum', part=>'left' ],
   [ 'A000012',  12, 'bignum', part=>'left' ],
   [ 'A000012',  36, 'bignum', part=>'left' ],
   [ 'A000012',  44, 'bignum', part=>'left' ],
   [ 'A000012',  68, 'bignum', part=>'left' ],
   [ 'A000012',  76, 'bignum', part=>'left' ],
   [ 'A000012', 100, 'bignum', part=>'left' ],
   [ 'A000012', 108, 'bignum', part=>'left' ],
   [ 'A000012', 132, 'bignum', part=>'left' ],
   [ 'A000012', 140, 'bignum', part=>'left' ],
   [ 'A000012', 164, 'bignum', part=>'left' ],
   [ 'A000012', 172, 'bignum', part=>'left' ],
   [ 'A000012', 196, 'bignum', part=>'left' ],
   [ 'A000012', 204, 'bignum', part=>'left' ],
   [ 'A000012', 228, 'bignum', part=>'left' ],
   [ 'A000012', 236, 'bignum', part=>'left' ],
   #
   # central column only, central values N=1,2,3,etc all integers
   [ 'A000027', 4, 'central_column_N' ],
   [ 'A000027', 12, 'central_column_N' ],
   [ 'A000027', 36, 'central_column_N' ],
   [ 'A000027', 44, 'central_column_N' ],
   [ 'A000027', 76, 'central_column_N' ],
   [ 'A000027', 108, 'central_column_N' ],
   [ 'A000027', 132, 'central_column_N' ],
   [ 'A000027', 140, 'central_column_N' ],
   [ 'A000027', 164, 'central_column_N' ],
   [ 'A000027', 172, 'central_column_N' ],
   [ 'A000027', 196, 'central_column_N' ],
   [ 'A000027', 204, 'central_column_N' ],
   [ 'A000027', 228, 'central_column_N' ],
   [ 'A000027', 236, 'central_column_N' ],
   #
   # central column only, values 2^k
   [ 'A000079', 4, 'bignum' ],
   [ 'A000079', 12, 'bignum' ],
   [ 'A000079', 36, 'bignum' ],
   [ 'A000079', 44, 'bignum' ],
   [ 'A000079', 68, 'bignum' ],
   [ 'A000079', 76, 'bignum' ],
   [ 'A000079', 100, 'bignum' ],
   [ 'A000079', 108, 'bignum' ],
   [ 'A000079', 132, 'bignum' ],
   [ 'A000079', 140, 'bignum' ],
   [ 'A000079', 164, 'bignum' ],
   [ 'A000079', 172, 'bignum' ],
   [ 'A000079', 196, 'bignum' ],
   [ 'A000079', 204, 'bignum' ],
   [ 'A000079', 228, 'bignum' ],
   [ 'A000079', 236, 'bignum' ],

   # right diagonal only, values all 1, 16 of
   [ 'A000012', 0x10, 'bignum' ],
   [ 'A000012', 0x18, 'bignum' ],
   [ 'A000012', 0x30, 'bignum' ],
   [ 'A000012', 0x38, 'bignum' ],
   [ 'A000012', 0x50, 'bignum' ],
   [ 'A000012', 0x58, 'bignum' ],
   [ 'A000012', 0x70, 'bignum' ],
   [ 'A000012', 0x78, 'bignum' ],
   [ 'A000012', 0x90, 'bignum' ],
   [ 'A000012', 0x98, 'bignum' ],
   [ 'A000012', 0xB0, 'bignum' ],
   [ 'A000012', 0xB8, 'bignum' ],
   [ 'A000012', 0xD0, 'bignum' ],
   [ 'A000012', 0xD8, 'bignum' ],
   [ 'A000012', 0xF0, 'bignum' ],
   [ 'A000012', 0xF8, 'bignum' ],

   # left diagonal only, values 2^k
   [ 'A000079', 0x02, 'bignum', part=>'left' ],
   [ 'A000079', 0x0A, 'bignum', part=>'left' ],
   [ 'A000079', 0x22, 'bignum', part=>'left' ],
   [ 'A000079', 0x2A, 'bignum', part=>'left' ],
   [ 'A000079', 0x42, 'bignum', part=>'left' ],
   [ 'A000079', 0x4A, 'bignum', part=>'left' ],
   [ 'A000079', 0x62, 'bignum', part=>'left' ],
   [ 'A000079', 0x6A, 'bignum', part=>'left' ],
   [ 'A000079', 0x82, 'bignum', part=>'left' ],
   [ 'A000079', 0x8A, 'bignum', part=>'left' ],
   [ 'A000079', 0xA2, 'bignum', part=>'left' ],
   [ 'A000079', 0xAA, 'bignum', part=>'left' ],
   [ 'A000079', 0xC2, 'bignum', part=>'left' ],
   [ 'A000079', 0xCA, 'bignum', part=>'left' ],
   [ 'A000079', 0xE2, 'bignum', part=>'left' ],
   [ 'A000079', 0xEA, 'bignum', part=>'left' ],
   # bits, characteristic of square
   [ 'A010052', 0x02, 'bits' ],
   [ 'A010052', 0x0A, 'bits' ],
   [ 'A010052', 0x22, 'bits' ],
   [ 'A010052', 0x2A, 'bits' ],
   [ 'A010052', 0x42, 'bits' ],
   [ 'A010052', 0x4A, 'bits' ],
   [ 'A010052', 0x62, 'bits' ],
   [ 'A010052', 0x6A, 'bits' ],
   [ 'A010052', 0x82, 'bits' ],
   [ 'A010052', 0x8A, 'bits' ],
   [ 'A010052', 0xA2, 'bits' ],
   [ 'A010052', 0xAA, 'bits' ],
   [ 'A010052', 0xC2, 'bits' ],
   [ 'A010052', 0xCA, 'bits' ],
   [ 'A010052', 0xE2, 'bits' ],
   [ 'A010052', 0xEA, 'bits' ],
            );

# {
#   require Data::Dumper;
#   foreach my $i (0 .. $#data) {
#     my $e1 = $data[$i];
#     my @a1 = @$e1; shift @a1;
#     my $a1 = Data::Dumper->Dump([\@a1],['args']);
#     ### $e1
#     ### @a1
#     ### $a1
#     foreach my $j ($i+1 .. $#data) {
#       my $e2 = $data[$j];
#       my @a2 = @$e2; shift @a2;
#       my $a2 = Data::Dumper->Dump([\@a2],['args']);
# 
#       if ($a1 eq $a2) {
#         print "duplicate $e1->[0] = $e2->[0] params $a1\n";
#       }
#     }
#   }
# }

foreach my $elem (@data) {
  ### $elem
  my ($anum, $rule, $method, @params) = @$elem;
  my $func = main->can($method) || die "Unrecognised method $method";
  &$func ($anum, $rule, @params);
}

#------------------------------------------------------------------------------
# number of 0s or 1s in row

sub number_of {
  my ($anum, $rule, %params) = @_;
  my $part = $params{'part'} || 'whole';
  my $want_value = $params{'value'} // 1;
  my $max_count = $params{'max_count'} || 100;

  MyOEIS::compare_values
      (anum => $anum,
       name => "$anum number of ${want_value}s in rows rule $rule, $part",
       max_count => $max_count,
       func => sub {
         my ($count) = @_;
         return number_of_make_values($count, $anum, $rule, %params);
       });
}

sub number_of_1s_first_diff {
  my ($anum, $rule, %params) = @_;
  my $max_count = $params{'max_count'};

  MyOEIS::compare_values
      (anum => $anum,
       name => "$anum number of 1s first differences",
       max_count => $max_count,
       func => sub {
         my ($count) = @_;
         my $aref = number_of_make_values($count+1, $anum, $rule, %params);
         return [ MyOEIS::first_differences(@$aref) ];
       });
}

sub number_of_make_values {
  my ($count, $anum, $rule, %params) = @_;
  my $initial = $params{'initial'} || [];
  my $part = $params{'part'} || 'whole';
  my $want_value = $params{'value'} // 1;
  my $max_count = $params{'max_count'};

  my $path = Math::PlanePath::CellularRule->new (rule => $rule);

  my @got = @$initial;
  my $number_of;
  for (my $y = 0; @got < $count; $y++) {
    unless ($params{'cumulative'}) { $number_of = 0 }
    foreach my $x (($part eq 'right' || $part eq 'centre' ? 0 : -$y)
                   .. ($part eq 'left' || $part eq 'centre' ? 0 : $y)) {
      my $n = $path->xy_to_n ($x, $y);
      my $got_value = (defined $n ? 1 : 0);
      if ($got_value == $want_value) {
        $number_of++;
      }
    }
    push @got, $number_of;
  }
  return \@got;
}

#------------------------------------------------------------------------------
# number of 0s or 1s in row at the rightmost end

sub trailing_number_of {
  my ($anum, $rule, %params) = @_;
  my $initial = $params{'initial'} || [];
  my $part = $params{'part'} || 'whole';
  my $want_value = $params{'value'} // 1;

  MyOEIS::compare_values
      (anum => $anum,
       name => "$anum trailing number of ${want_value}s in rows rule $rule",
       func => sub {
         my ($count) = @_;
         my $path = Math::PlanePath::CellularRule->new (rule => $rule);

         my @got = @$initial;
         for (my $y = 0; @got < $count; $y++) {
           my $number_of = 0;
           for (my $x = $y; $x >= -$y; $x--) {
             my $n = $path->xy_to_n ($x, $y);
             my $got_value = (defined $n ? 1 : 0);
             if ($got_value == $want_value) {
               $number_of++;
             } else {
               last;
             }
           }
           push @got, $number_of;
         }
         return \@got;
       });
}

sub new_maximum_trailing_number_of {
  my ($anum, $rule, $want_value) = @_;
  my $path = Math::PlanePath::CellularRule->new (rule => $rule);
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    MyTestHelpers::diag ("$anum new_maximum_trailing_number_of");

    if ($anum eq 'A094604') {
      # new max only at Y=2^k, so limit search
      if ($#$bvalues > 10) {
        $#$bvalues = 10;
      }
    }

    my $prev = 0;
    for (my $y = 0; @got < @$bvalues; $y++) {
      my $count = 0;
      for (my $x = $y; $x >= -$y; $x--) {
        my $n = $path->xy_to_n ($x, $y);
        my $got_value = (defined $n ? 1 : 0);
        if ($got_value == $want_value) {
          $count++;
        } else {
          last;
        }
      }
      if ($count > $prev) {
        push @got, $count;
        $prev = $count;
      }
    }
    if (! streq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        streq_array(\@got, $bvalues),
        1, "$anum");
}

#------------------------------------------------------------------------------
# bignum rows

sub bignum {
  my ($anum, $rule, %params) = @_;
  my $part = $params{'part'} || 'whole';
  my $initial = $params{'initial'} || [];
  my $ystart = $params{'ystart'} || 0;
  my $inverse = $params{'inverse'} ? 1 : 0;   # for bitwise invert
  my $base = $params{'base'} || 10;
  my $max_count = $params{'max_count'};

  # if ($anum eq 'A000012') {  # trim all-ones
  #   if ($#$bvalues > 50) { $#$bvalues = 50; }
  # }

  MyOEIS::compare_values
      (anum => $anum,
       name => "$anum bignums $part, inverse=$inverse",
       max_count => $max_count,
       func => sub {
         my ($count) = @_;
         my $path = Math::PlanePath::CellularRule->new (rule => $rule);

         my @got = @$initial;
         for (my $y = $ystart; @got < $count; $y++) {
           my $b = Math::BigInt->new(0);
           foreach my $x (($part eq 'right' ? 0 : -$y)
                          .. ($part eq 'left' ? 0 : $y)) {
             my $bit = ($path->xy_is_visited($x,$y) ? 1 : 0);
             if ($inverse) { $bit ^= 1; }
             $b = 2*$b + $bit;
           }
           if ($base == 2) {
             $b = $b->as_bin;
             $b =~ s/^0b//;
           }
           push @got, "$b";
         }
         return \@got;
       });
}

#------------------------------------------------------------------------------
# 0/1 by rows

sub bits {
  my ($anum, $rule, %params) = @_;
  ### bits(): @_
  my $part = $params{'part'} || 'whole';
  my $initial = $params{'initial'} || [];

  MyOEIS::compare_values
      (anum => $anum,
       name => "$anum 0/1 rows rule $rule, $part",
       func => sub {
         my ($count) = @_;
         my $path = Math::PlanePath::CellularRule->new (rule => $rule);

         my @got = @$initial;
       OUTER: for (my $y = 0; ; $y++) {
           foreach my $x (($part eq 'right' || $part eq 'centre' ? 0 : -$y)
                          .. ($part eq 'left' || $part eq 'centre' ? 0 : $y)) {
             last OUTER if @got >= $count;

             push @got, ($path->xy_to_n ($x, $y) ? 1 : 0);
           }
         }
         return \@got;
       });
}


#------------------------------------------------------------------------------
# bignum central vertical column in decimal

sub bignum_central_column {
  my ($anum, $rule, %params) = @_;
  my $base = $params{'base'} || 10;

  MyOEIS::compare_values
      (anum => $anum,
       name => "$anum central column bignum, decimal",
       func => sub {
         my ($count) = @_;
         my $path = Math::PlanePath::CellularRule->new (rule => $rule);

         my @got;
         my $b = Math::BigInt->new(0);
         for (my $y = 0; @got < $count; $y++) {
           my $bit = ($path->xy_to_n (0, $y) ? 1 : 0);
           $b = $base*$b + $bit;
           push @got, "$b";
         }
         return \@got;
       });
}

#------------------------------------------------------------------------------
# N values of central vertical column

sub central_column_N {
  my ($anum, $rule) = @_;

  MyOEIS::compare_values
      (anum => $anum,
       name => "$anum central column N",
       func => sub {
         my ($count) = @_;
         my $path = Math::PlanePath::CellularRule->new (rule => $rule);

         my @got;
         for (my $y = 0; @got < $count; $y++) {
           push @got, $path->xy_to_n (0, $y);
         }
         return \@got;
       });
}

#------------------------------------------------------------------------------
# A071029 rule 22 ... ?
#
# 22 = 00010110
#     111 -> 0
#     110 -> 0
#     101 -> 0
#     100 -> 1
#     011 -> 0
#     010 -> 1
#     001 -> 1
#     000 -> 0
#                            0,
#                         1, 0, 1,
#                      0, 1, 0, 1, 0,
#                   1, 0, 1, 0, 1, 0, 1,
#                0, 1, 0, 1, 0, 1, 0, 1, 0,
#             1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1,
#          1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1,
#       0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0,
#    1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0,
# 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0

#                            0,
#                            1,
#                         0, 1, 0,
#                      1, 0, 1, 0, 1,
#                   0, 1, 0, 1, 0, 1, 0,
#                1, 0, 1, 0, 1, 0, 1, 0, 1,
#             0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1,
#          0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0,
#       1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1,
#    0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1,
# 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0

# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0, 1,
# 0

# A071043  Number of 0's in n-th row of triangle in A071029.
#    0, 0, 3, 1, 7, 5, 9, 3, 15, 13, 17, 11, 21, 15, 21, 7, 31, 29, 33, 27,
#    37, 31, 37, 23, 45, 39, 45, 31, 49, 35, 45, 15, 63, 61, 65, 59, 69, 63,
#    69, 55, 77, 71, 77, 63, 81, 67, 77, 47, 93, 87, 93, 79, 97, 83, 93, 63,
#    105, 91, 101, 71, 105, 75, 93, 31, 127, 125, 129
#
# A071044         Number of 1's in n-th row of triangle in A071029.
#    1, 3, 2, 6, 2, 6, 4, 12, 2, 6, 4, 12, 4, 12, 8, 24, 2, 6, 4, 12, 4, 12,
#    8, 24, 4, 12, 8, 24, 8, 24, 16, 48, 2, 6, 4, 12, 4, 12, 8, 24, 4, 12,
#    8, 24, 8, 24, 16, 48, 4, 12, 8, 24, 8, 24, 16, 48, 8, 24, 16, 48, 16,
#    48, 32, 96, 2, 6, 4, 12, 4, 12, 8, 24, 4, 12, 8, 24, 8, 24, 16, 48
#
# *** *** *** ***
#  *   *   *   *
#   ***     ***
#    *       *
#     *** ***
#      *   *
#       ***
#        *


#------------------------------------------------------------------------------
# A071026 rule 188
# rows n+1
#
# 1,
# 1, 0,
# 0, 1, 1,
# 0, 1, 0, 1,
# 1, 1, 1, 1, 0,
# 0, 0, 1, 1, 0, 1,
# 1, 1, 1, 1, 1, 1, 1,
# 1, 0, 1, 1, 0, 0, 1, 1,
# 1, 1, 0, 0, 0, 0, 0, 0, 1,
# 1, 1, 1, 1, 1, 1, 0, 1, 0, 0,
# 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1,
# 0, 0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 0,
# 0, 0, 0, 1, 0, 1, 1, 1, 1, 0, 0, 1, 0,
# 0, 1, 1, 1, 0, 1, 1, 0
#
# * *** *
# ** ***
# *** *
# ****
# * *
# **
# *


#------------------------------------------------------------------------------
# A071023 rule 78

# *** * * *               
#  ** * * *               
#   *** * *               
#    ** * *               
#     *** *               
#      ** *               
#       ***               
#        **               
#         *               

# 1, 1, 1,
# 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1,
# 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0,
# 1, 1, 1,
# 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0,
# 1, 1, 1, 1, 1, 1, 1, 1, 1,
# 0, 1, 1, 1, 1,
# 0, 1, 1, 1,
# 0, 1, 0,
# 1, 1, 1


#     111 -> 
#     110 -> 
#     101 -> 
#     100 -> 
#     011 -> 
#     010 -> 1
#     001 -> 1
#     000 -> 
#                      1,
#                   1, 1,
#                0, 1, 0,
#             1, 0, 1, 0,
#          1, 0, 1, 0, 1,
#       0, 1, 0, 1, 0, 1,
#    0, 1, 0, 1, 1, 0, 1,
# 0, 1, 0, 1, 0, 1, 0, 1,
# 0, 1, 0, 1, 0, 1, 0, 1, 0,
# 1, 0, 1, 0, 1, 1, 1, 0, 1, 0,
# 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1,
# 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1,
# 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1,
# 1, 1, 0, 1, 0, 1, 1, 1


#------------------------------------------------------------------------------
# A071024 rule 92

# 0, 1, 0, 1, 0,
# 1, 1, 1,
# 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0,
# 1, 1, 1, 1,
# 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0,
# 1, 1, 1,
# 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0,
# 1, 1, 1, 1,
# 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0

#------------------------------------------------------------------------------
# A071027 rule 230

     # * *** *** *               
     #  *** *** **               
     #   * *** ***               
     #    *** ****               
     #     * *** *               
     #      *** **               
     #       * ***               
     #        ****               
     #         * *               
     #          **               
     #           *               

# 1, 1, 1, 1, 1, 1, 0,
# 1, 1, 1, 0,
# 1, 1, 1, 0,
# 1, 1, 1, 0,
# 1, 1, 1, 0,
# 1, 1, 1, 0,
# 1, 1, 1, 1, 0,
# 1, 1, 1, 0,
# 1, 1, 1, 0,
# 1, 1, 1, 0,
# 1, 1, 1, 1, 1, 0,
# 1, 1, 1, 0,
# 1, 1, 1, 0,
# 1, 1, 1, 1, 1, 1, 0,
# 1, 1, 1, 0,
# 1, 1, 1, 0,
# 1, 1, 1, 0,
# 1, 1, 1, 0,
# 1, 1, 1, 0,
# 1, 1, 1, 0,
# 1, 1, 1, 0,
# 1, 1, 1, 1, 0,
# 1

#------------------------------------------------------------------------------
# # A071035 rule 126 sierpinski
#
#          1,
#       1, 0, 1,
#       1, 0, 1,
#    1, 0, 0, 0, 1,
# 1, 1, 1, 0, 1, 0, 1, 1, 1,
# 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1,
# 0, 1, 1, 0, 1, 0, 1, 1, 0, 0, 0, 
# 1, 1, 1, 1, 0, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 
# 0, 1, 0, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0


#------------------------------------------------------------------------------
# A071022 rule 70,198

# ** * * * *               
#  * * * * *               
#   ** * * *               
#    * * * *               
#     ** * *               
#      * * *               
#       ** *               
#        * *               
#         **               
#          *               

# 1, 0,
# 1, 0,
# 1, 0,
# 1, 0,
# 1, 0,
# 1, 0,
# 1, 0,
# 1, 0,
# 1, 0,
# 1, 0,
# 1, 0,
# 1, 0,
# 1, 1, 1, 1, 1, 1, 0,
# 1, 1, 1, 0,
# 1, 1, 0,
# 1, 0,
# 1, 1, 1, 0,
# 1, 0,
# 1, 1, 0,
# 1, 0,
# 1, 0,
# 1, 1, 1, 0,
# 1, 0,
# 1, 0,
# 1, 1, 0,
# 1, 0,
# 1, 0,
# 1, 0,
# 1, 1, 1, 0,
# 1, 0,
# 1, 0,
# 1, 0,
# 1, 1, 0,
# 1, 0,
# 1, 0,
# 1, 0,
# 1, 0,
# 1, 1, 1, 0,
# 1, 0,
# 1, 0


#------------------------------------------------------------------------------
# A071030 - rule 54, rows 2n+1

#                            0,
#                         1, 0, 1,
#                      0, 1, 0, 1, 0,
#                   1, 0, 1, 0, 1, 0, 1,
#                0, 1, 0, 1, 0, 1, 0, 1, 0,
#             1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1,
#          1, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0,
#       0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0,
#    0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, 0, 1, 1,
# 1, 0, 1, 1, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0

#------------------------------------------------------------------------------
# A071039 rule 190, rows 2n+1

#                            1,
#                         0, 1, 0,
#                      1, 1, 1, 1, 1,
#                   0, 1, 0, 1, 0, 1, 0,
#                1, 0, 1, 0, 1, 0, 1, 1, 1,
#             1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0,
#          1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1,
#       0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0,
#    1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1,
# 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1


#------------------------------------------------------------------------------
# A071036 rule 150

# ** ** *** ** **        
#  * *   *   * *         
#   *** *** ***          
#    *   *   *           
#     ** * **            
#      * * *             
#       ***              
#        *               

#                            1,
#                         0, 1, 1,
#                      0, 1, 1, 0, 0,
#                   0, 1, 1, 1, 1, 0, 1,
#                0, 1, 1, 0, 0, 0, 1, 1, 1,
#             1, 0, 0, 1, 1, 1, 0, 1, 1, 0, 1,
#          1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1,
#       0, 1, 1, 0, 1, 0, 1, 1, 0, 0, 0, 1, 1, 1, 1,
#    0, 1, 0, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1,
# 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1

#------------------------------------------------------------------------------

# A071022 rule 70,198
# A071023 rule 78
# A071024 rule 92
# A071025 rule 124
# A071026 rule 188
# A071027 rule 230
# A071028 rule 50   ok
# A071029 rule 22
# A071030 rule 54 -- cf A118108 bignum A118109 binary bignum
# A071031 rule 62
# A071032 rule 86
# A071033 rule 94
# A071034 rule 118
# A071035 rule 126 sierpinski
# A071036 rule 150
# A071037 rule 158
# A071038 rule 182
# A071039 rule 190
# A071040 rule 214
# A071041 rule 246
#
# A071042 num 0s in A070886 rule 90 sierpinski ok
# A071043 num 0s in A071029 rule 22  ok
# A071044 num 1s in A071029 rule 22  ok
# A071045 num 0s in A071030 rule 54  ok
# A071046 num 0s in A071031 rule 62  ok
# A071047
# A071048
# A071049
# A071050
# A071051 num 1s in A071035 rule 126 sierpinski
# A071052
# A071053
# A071054
# A071055
#

# A267682 cumulative number of ON cells, by rows
# A267682_samples = [1, 1, 4, 8, 15, 23, 34, 46, 61, 77, 96, 116, 139, 163, 190, 218, 249, 281, 316, 352, 391, 431, 474, 518, 565, 613, 664, 716, 771, 827, 886, 946, 1009, 1073, 1140, 1208, 1279, 1351, 1426, 1502, 1581, 1661, 1744, 1828, 1915, 2003, 2094, 2186, 2281, 2377, 2476];
# A267682(n) = n*(2*n-1)/2 + if(n%2==0,1,1/2);
# A267682(n) = if(n%2==0, n^2 - (n-2)/2, n^2 - (n-1)/2);
# vector(#A267682_samples,n,n--; A267682(n)) - \
# A267682_samples
# recurrence_guess(A267682_samples)
# vector(10,n,n--;n=2*n+1; A267682(n))
# even A054556
# odd A033951
# recurrence_guess(vector(10,n,n--; sum(i=0,n, 2*2*i+1 + 2*(2*i+1)+3)))
exit 0;

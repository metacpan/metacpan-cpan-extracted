#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2019, 2020 Kevin Ryde

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


use 5.004;
use strict;
use Math::BigInt try => 'GMP';   # for bignums in reverse-add steps
use List::Util 'min','max';
use Test;
plan tests => 800;

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

foreach my $elem (# [ 'A071033', 'A118102', 'rule=94' ],
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

my @data =
  (
   # Not quite, initial values differ
   # [ 'A051341', 7, 'bits' ],
   
   [ 'A265718',    1, 'bits' ],
   [ 'A265721',    1, 'bignum' ],
   [ 'A265720',    1, 'bignum', base=>2 ],
   [ 'A265722',    1, 'number_of', value=>1 ],
   [ 'A265723',    1, 'number_of', value=>0 ],
   [ 'A265724',    1, 'number_of', value=>0, cumulative=>1 ],
   
   # rule=2,10,34,42,66,74,98,106,130,138,162,170,194,202,226,234 (mirror image is rule 16)
   [ 'A098608',    2, 'bignum', base=>2 ],  # 100^n
   
   # rule=3,35 (mirror image is rule 17)
   [ 'A263428',    3, 'bits' ],
   [ 'A266069',    3, 'bignum' ],
   [ 'A266068',    3, 'bignum', base=>2 ],
   [ 'A266070',    3, 'bits', part => 'centre' ],
   [ 'A266071',    3, 'bignum_central_column' ],
   [ 'A266072',    3, 'number_of', value=>1 ],
   [ 'A266073',    3, 'number_of', value=>0 ],
   [ 'A266074',    3, 'number_of', value=>0, cumulative=>1 ],
   
   # characteristic func of pronics m*(m+1)
   # rule=4,12,36,44,68,76,100,108,132,140,164,172,196,204,228,236
   [ 'A005369',    4, 'bits' ],
   [ 'A011557',    4, 'bignum', base=>2 ],  # 10^n
   
   [ 'A266174',    5, 'bits' ],
   [ 'A266176',    5, 'bignum' ],
   [ 'A266175',    5, 'bignum', base=>2 ],
   
   [ 'A266178',    6, 'bits' ],
   [ 'A266180',    6, 'bignum' ],
   [ 'A266179',    6, 'bignum', base=>2 ],
   
   [ 'A266216',    7, 'bits' ],
   [ 'A266218',    7, 'bignum' ],
   [ 'A266217',    7, 'bignum', base=>2 ],
   [ 'A266219',    7, 'bignum_central_column' ],
   [ 'A266220',    7, 'number_of', value=>1 ],
   [ 'A266222',    7, 'number_of', value=>0 ],
   [ 'A266221',    7, 'number_of', value=>1, cumulative=>1 ],
   [ 'A266223',    7, 'number_of', value=>0, cumulative=>1 ],
   
   [ 'A266243',    9, 'bits' ],
   [ 'A266245',    9, 'bignum' ],
   [ 'A266244',    9, 'bignum', base=>2 ],
   [ 'A266246',    9, 'bits', part => 'centre' ],
   [ 'A266247',    9, 'bignum_central_column' ],
   [ 'A266248',    9, 'bignum_central_column', base=>2 ],
   [ 'A266249',    9, 'number_of', value=>1 ],
   [ 'A266251',    9, 'number_of', value=>0 ],
   [ 'A266250',    9, 'number_of', value=>1, cumulative=>1 ],
   [ 'A266252',    9, 'number_of', value=>0, cumulative=>1 ],
   
   [ 'A266253',   11, 'bits' ],
   [ 'A266255',   11, 'bignum' ],
   [ 'A266254',   11, 'bignum', base=>2 ],
   [ 'A266256',   11, 'number_of', value=>1 ],
   [ 'A266258',   11, 'number_of', value=>0 ],
   [ 'A266257',   11, 'number_of', value=>1, cumulative=>1 ],
   [ 'A266259',   11, 'number_of', value=>0, cumulative=>1 ],
   
   [ 'A266282',   13, 'bits' ],
   [ 'A266284',   13, 'bignum' ],
   [ 'A266283',   13, 'bignum', base=>2 ],
   [ 'A266285',   13, 'number_of', value=>1 ],
   [ 'A266286',   13, 'number_of', value=>0 ],
   [ 'A266287',   13, 'number_of', value=>0, cumulative=>1 ],
   
   [ 'A266298',   14, 'bits' ],
   [ 'A266299',   14, 'bignum', base=>2 ],
   
   [ 'A266300',   15, 'bits' ],
   [ 'A266302',   15, 'bignum' ],
   [ 'A266301',   15, 'bignum', base=>2 ],
   [ 'A266303',   15, 'number_of', value=>1 ],
   [ 'A266304',   15, 'number_of', value=>0, cumulative=>1 ],
   
   [ 'A260552',   17, 'bits' ],
   [ 'A266090',   17, 'bignum' ],
   [ 'A260692',   17, 'bignum', base=>2 ],
   
   # rule=19
   [ 'A266155',   19, 'bits' ],
   [ 'A266323',   19, 'bignum', base=>2 ],
   [ 'A266324',   19, 'bignum' ],
   
   # rule=20,52,148,180 (mirror image of rule 6)
   [ 'A266326',   20, 'bits' ],
   [ 'A266327',   20, 'bignum', base=>2 ],
   
   # rule=21 (mirror image of rule 7)
   [ 'A266377',   21, 'bits' ],
   [ 'A266379',   21, 'bignum', base=>2 ],
   [ 'A266380',   21, 'bignum' ],
   
   # rule=22
   [ 'A071029',   22, 'bits' ],
   [ 'A266381',   22, 'bignum', base=>2 ],
   [ 'A266382',   22, 'bignum' ],
   [ 'A071043',   22, 'number_of', value=>0 ],
   [ 'A071044',   22, 'number_of', value=>1 ],
   [ 'A266383',   22, 'number_of', value=>1, cumulative=>1 ],
   [ 'A266384',   22, 'number_of', value=>0, cumulative=>1 ],
   
   # rule=23,31,55,63,87,95,119,127
   [ 'A266434',   23, 'bits' ],
   [ 'A266435',   23, 'bignum', base=>2 ],
   [ 'A266436',   23, 'bignum' ],
   [ 'A266437',   23, 'number_of', value=>1 ],
   [ 'A266439',   23, 'number_of', value=>0 ],
   [ 'A266438',   23, 'number_of', value=>1, cumulative=>1 ],
   [ 'A266440',   23, 'number_of', value=>0, cumulative=>1 ],
   
   # rule=25 (mirror image is rule 67)
   [ 'A266441',   25, 'bits' ],
   [ 'A266443',   25, 'bignum' ],
   [ 'A266442',   25, 'bignum', base=>2 ],
   [ 'A266444',   25, 'bits', part => 'centre' ],
   [ 'A266445',   25, 'bignum_central_column' ],
   [ 'A266446',   25, 'bignum_central_column', base=>2 ],
   [ 'A266447',   25, 'number_of', value=>1 ],
   [ 'A266449',   25, 'number_of', value=>0 ],
   [ 'A266448',   25, 'number_of', value=>1, cumulative=>1 ],
   [ 'A266450',   25, 'number_of', value=>0, cumulative=>1 ],
   
   # rule=27 (mirror image is rule 83)
   [ 'A266459',   27, 'bits' ],
   [ 'A266461',   27, 'bignum' ],
   [ 'A266460',   27, 'bignum', base=>2 ],
   
   # rule=28,156 (mirror image is rule 70)
   [ 'A266502',   28, 'bits' ],
   [ 'A283642',   28, 'bignum' ],     # sharing "Rule 678"
   [ 'A001045',   28, 'bignum', initial=>[0,1] ], # Jacobsthal
   [ 'A266508',   28, 'bignum', base=>2 ],
   [ 'A070909',   28, 'bits', part=>'right' ],
   
   # rule=29 (mirror image is rule 71)
   [ 'A266514',   29, 'bits' ],
   [ 'A266516',   29, 'bignum' ],
   [ 'A266515',   29, 'bignum', base=>2 ],
   
   # rule=30 (mirror image is rule 86)
   # 111 110 101 100 011 010 001 000
   #  0   0   0   1   1   1   1   0
   # 135 started from 0 = complement of rule 30 started from 1
   [ 'A070950',  30, 'bits' ],
   [ 'A226463',  30, 'bits', complement => 1 ],    # rule 135 starting from "0"
   [ 'A110240',  30, 'bignum' ], # cf A074890 some strange form
   [ 'A245549',  30, 'bignum', base=>2 ],
   [ 'A051023',  30, 'bits', part=>'centre' ],
   [ 'A261299',  30, 'bignum_central_column' ],
   [ 'A070951',  30, 'number_of', value=>0 ],
   [ 'A070952',  30, 'number_of', value=>1, max_count=>400, initial=>[0] ],
   [ 'A151929',  30, 'number_of_1s_first_diff', max_count=>200,
     initial=>[0], # without diffs yet applied ...
   ],
   [ 'A110267',  30, 'number_of', cumulative=>1 ],
   [ 'A265224',  30, 'number_of', cumulative=>1, value=>0 ],
   [ 'A226482',  30, 'number_of_runs' ],
   [ 'A110266',  30, 'number_of_runs', value=>1 ],
   [ 'A092539',  30, 'bignum_central_column', base=>2 ],
   [ 'A094603',  30, 'trailing_number_of', value=>1 ],
   [ 'A094604',  30, 'new_maximum_trailing_number_of', 1 ],
   [ 'A100053',  30, 'longest_run', value=>0 ],
   
   [ 'A266588',   37, 'bits' ],
   [ 'A266590',   37, 'bignum' ],
   [ 'A266589',   37, 'bignum', base=>2 ],
   [ 'A266591',   37, 'bits', part => 'centre' ],
   [ 'A266592',   37, 'bignum_central_column' ],
   [ 'A052997',   37, 'bignum_central_column', base=>2 ],
   [ 'A266593',   37, 'number_of', value=>1 ],
   [ 'A266595',   37, 'number_of', value=>0 ],
   [ 'A266594',   37, 'number_of', value=>1, cumulative=>1 ],
   [ 'A266596',   37, 'number_of', value=>0, cumulative=>1 ],
   
   [ 'A266605',   39, 'bits' ],
   [ 'A266607',   39, 'bignum' ],
   [ 'A266606',   39, 'bignum', base=>2 ],
   
   [ 'A266608',   41, 'bits' ],
   [ 'A266610',   41, 'bignum' ],
   [ 'A266609',   41, 'bignum', base=>2 ],
   [ 'A266611',   41, 'bits', part => 'centre' ],
   [ 'A266612',   41, 'bignum_central_column' ],
   [ 'A266613',   41, 'bignum_central_column', base=>2 ],
   [ 'A266614',   41, 'number_of', value=>1 ],
   [ 'A266616',   41, 'number_of', value=>0 ],
   [ 'A266615',   41, 'number_of', value=>1, cumulative=>1 ],
   [ 'A266617',   41, 'number_of', value=>0, cumulative=>1 ],
   
   [ 'A266619',   45, 'bits' ],
   [ 'A266622',   45, 'bignum' ],
   [ 'A266621',   45, 'bignum', base=>2 ],
   [ 'A266623',   45, 'bits', part => 'centre' ],
   [ 'A266624',   45, 'bignum_central_column' ],
   [ 'A266625',   45, 'bignum_central_column', base=>2 ],
   [ 'A266628',   45, 'number_of', value=>0 ],
   [ 'A266626',   45, 'number_of', value=>1 ],
   [ 'A266627',   45, 'number_of', value=>1, cumulative=>1 ],
   [ 'A266629',   45, 'number_of', value=>0, cumulative=>1 ],
   
   [ 'A266659',   47, 'bits' ],
   [ 'A266661',   47, 'bignum' ],
   [ 'A266660',   47, 'bignum', base=>2 ],
   [ 'A266664',   47, 'number_of', value=>0 ],
   [ 'A266662',   47, 'number_of', value=>1 ],
   [ 'A266663',   47, 'number_of', value=>1, cumulative=>1 ],
   [ 'A266665',   47, 'number_of', value=>0, cumulative=>1 ],
   
   [ 'A071028',   50, 'bits' ],
   [ 'A094028',   50, 'bignum', base=>2 ],

   [ 'A266666',   51, 'bits' ],
   [ 'A266668',   51, 'bignum' ],
   [ 'A266667',   51, 'bignum', base=>2 ],
   
   [ 'A266669',   53, 'bits' ],
   [ 'A266671',   53, 'bignum' ],
   [ 'A266670',   53, 'bignum', base=>2 ],
   
   [ 'A071030',   54, 'bits' ],
   [ 'A118108',   54, 'bignum' ],
   [ 'A118109',   54, 'bignum', base=>2 ],
   [ 'A259661',   54, 'bignum_central_column' ],
   [ 'A064455',   54, 'number_of', value=>1 ],
   [ 'A071045',   54, 'number_of', value=>0 ],
   [ 'A265225',   54, 'number_of', value=>1, cumulative=>1 ],
   [ 'A050187',   54, 'number_of', value=>0, cumulative=>1, y_start=>1 ],

   [ 'A266672',   57, 'bits' ],
   [ 'A266674',   57, 'bignum' ],
   [ 'A266673',   57, 'bignum', base=>2 ],
   
   [ 'A266716',   59, 'bits' ],
   [ 'A266717',   59, 'bignum', base=>2 ],
   [ 'A266718',   59, 'bignum' ],
   [ 'A266719',   59, 'bits', part=>'centre' ],
   [ 'A266720',   59, 'bignum_central_column' ],
   [ 'A266721',   59, 'bignum_central_column', base=>2 ],
   [ 'A266722',   59, 'number_of', value=>1 ],
   [ 'A266724',   59, 'number_of', value=>0 ],
   [ 'A266723',   59, 'number_of', value=>1, cumulative=>1 ],
   [ 'A266725',   59, 'number_of', value=>0, cumulative=>1 ],

   [ 'A006943',   60, 'bignum', base=>2 ],  # Sierpinski
   
   [ 'A266786',   61, 'bits' ],
   [ 'A266788',   61, 'bignum' ],
   [ 'A266787',   61, 'bignum', base=>2 ],
   [ 'A266789',   61, 'bits', part=>'centre' ],
   [ 'A266790',   61, 'bignum_central_column' ],
   [ 'A266791',   61, 'bignum_central_column', base=>2 ],
   [ 'A266792',   61, 'number_of', value=>1 ],
   [ 'A266794',   61, 'number_of', value=>0 ],
   [ 'A266793',   61, 'number_of', value=>1, cumulative=>1 ],
   [ 'A266795',   61, 'number_of', value=>0, cumulative=>1 ],
   
   [ 'A071031',   62, 'bits' ],
   [ 'A266809',   62, 'bignum', base=>2 ],
   [ 'A266810',   62, 'bignum' ],
   [ 'A071046',   62, 'number_of', value=>0 ],
   [ 'A071047',   62, 'number_of', value=>1 ],
   [ 'A266811',   62, 'number_of', value=>1, cumulative=>1 ],
   [ 'A266813',   62, 'number_of', value=>0, cumulative=>1 ],
   
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
   [ 'A080513',   70, 'number_of', value=>1 ],
   
   [ 'A266848',   71, 'bits' ],
   [ 'A266849',   71, 'bignum', base=>2 ],
   [ 'A266850',   71, 'bignum' ],

   [ 'A262448',   73, 'bits' ],
   [ 'A265122',   73, 'bignum', base=>2 ],
   [ 'A265156',   73, 'bignum' ],
   [ 'A265205',   73, 'number_of', value=>1 ],
   [ 'A265219',   73, 'number_of', value=>0 ],
   [ 'A265206',   73, 'number_of', value=>1, cumulative=>1 ],
   [ 'A265220',   73, 'number_of', value=>0, cumulative=>1 ],
   
   [ 'A266892',   75, 'bits' ],
   [ 'A266894',   75, 'bignum' ],
   [ 'A266893',   75, 'bignum', base=>2 ],
   [ 'A266895',   75, 'bits', part => 'centre' ],
   [ 'A266896',   75, 'bignum_central_column' ],
   [ 'A266897',   75, 'bignum_central_column', base=>2 ],
   [ 'A266900',   75, 'number_of', value=>0 ],
   [ 'A266898',   75, 'number_of', value=>1 ],
   [ 'A266899',   75, 'number_of', value=>1, cumulative=>1 ],
   [ 'A266901',   75, 'number_of', value=>0, cumulative=>1 ],
   
   [ 'A266872',   77, 'bignum', base=>2 ],
   [ 'A266873',   77, 'bignum' ],

   [ 'A266974',   78, 'bits' ],
   [ 'A266975',   78, 'bignum', base=>2 ],
   [ 'A266976',   78, 'bignum' ],
   [ 'A266977',   78, 'number_of', value=>1 ],
   [ 'A071023',   78, 'bits', part=>'left' ],

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

   # mirror image of rule 30
   [ 'A071032',  86, 'bits' ],
   [ 'A265280',  86, 'bignum', base=>2 ],
   [ 'A265281',  86, 'bignum' ],

   [ 'A267037',   89, 'bits' ],
   [ 'A267038',   89, 'bignum', base=>2 ],
   [ 'A267039',   89, 'bignum' ],

   [ 'A265172',   90, 'bignum', base=>2 ],
   [ 'A001316',   90, 'number_of', value=>1 ], # Gould's sequence
   [ 'A071042',   90, 'number_of', value=>0 ],

   [ 'A267015',   91, 'bits' ],
   [ 'A267041',   91, 'bignum', base=>2 ],
   [ 'A267042',   91, 'bignum' ],
   [ 'A267043',   91, 'bits', part => 'centre' ],
   [ 'A267044',   91, 'bignum_central_column' ],
   [ 'A267045',   91, 'bignum_central_column', base=>2 ],
   [ 'A267048',   91, 'number_of', value=>0 ],
   [ 'A267046',   91, 'number_of', value=>1 ],
   [ 'A267047',   91, 'number_of', value=>1, cumulative=>1 ],
   [ 'A267049',   91, 'number_of', value=>0, cumulative=>1 ],
   
   [ 'A267050',   92, 'bits' ],
   [ 'A267051',   92, 'bignum', base=>2 ],
   [ 'A267052',   92, 'bignum' ],
   [ 'A071024',   92, 'bits', part=>'right' ],

   [ 'A267053',   93, 'bits' ],
   [ 'A267054',   93, 'bignum', base=>2 ],
   [ 'A267055',   93, 'bignum' ],

   [ 'A118102',   94, 'bits' ],
   [ 'A118101',   94, 'bignum' ],
   [ 'A071033',   94, 'bignum', base=>2 ],
   [ 'A265283',   94, 'number_of', value=>1 ],
   [ 'A265284',   94, 'number_of', value=>1, cumulative=>1 ],

   [ 'A267056',   97, 'bits' ],
   [ 'A267057',   97, 'bignum', base=>2 ],
   [ 'A267058',   97, 'bignum' ],

   [ 'A267126',   99, 'bits' ],
   [ 'A267127',   99, 'bignum', base=>2 ],
   [ 'A267128',   99, 'bignum' ],

   [ 'A267129',  101, 'bits' ],
   [ 'A267130',  101, 'bignum', base=>2 ],
   [ 'A267131',  101, 'bignum' ],

   [ 'A117998',  102, 'bignum' ],
   [ 'A265319',  102, 'bignum', base=>2 ],

   [ 'A267136',  103, 'bits' ],
   [ 'A267138',  103, 'bignum', base=>2 ],
   [ 'A267139',  103, 'bignum' ],

   [ 'A267145',  105, 'bits' ],
   [ 'A267146',  105, 'bignum', base=>2 ],
   [ 'A267147',  105, 'bignum' ],
   [ 'A267148',  105, 'number_of', value=>1 ],
   [ 'A267150',  105, 'number_of', value=>0 ],
   [ 'A267149',  105, 'number_of', value=>1, cumulative=>1 ],
   [ 'A267151',  105, 'number_of', value=>0, cumulative=>1 ],

   [ 'A267152',  107, 'bits' ],
   [ 'A267153',  107, 'bignum', base=>2 ],
   [ 'A267154',  107, 'bignum' ],
   [ 'A267155',  107, 'bits', part => 'centre' ],
   [ 'A267156',  107, 'bignum_central_column' ],
   [ 'A267157',  107, 'bignum_central_column', base=>2 ],
   [ 'A267160',  107, 'number_of', value=>0 ],
   [ 'A267158',  107, 'number_of', value=>1 ],
   [ 'A267159',  107, 'number_of', value=>1, cumulative=>1 ],
   [ 'A267161',  107, 'number_of', value=>0, cumulative=>1 ],

   [ 'A243566',  109, 'bits' ],
   [ 'A267206',  109, 'bignum', base=>2 ],
   [ 'A267207',  109, 'bignum' ],
   [ 'A267208',  109, 'bits', part => 'centre' ],
   [ 'A267209',  109, 'bignum_central_column' ],
   [ 'A267210',  109, 'bignum_central_column', base=>2 ],
   [ 'A267211',  109, 'number_of', value=>1 ],
   [ 'A267213',  109, 'number_of', value=>0 ],
   [ 'A267212',  109, 'number_of', value=>1, cumulative=>1 ],
   [ 'A267214',  109, 'number_of', value=>0, cumulative=>1 ],

   [ 'A075437',  110, 'bits' ],
   [ 'A117999',  110, 'bignum' ],
   [ 'A265320',  110, 'bignum', base=>2 ],
   [ 'A265322',  110, 'number_of', value=>0 ],
   [ 'A265321',  110, 'number_of', value=>1, cumulative=>1 ],
   [ 'A265323',  110, 'number_of', value=>0, cumulative=>1 ],
   [ 'A070887',  110, 'bits', part=>'left' ],
   [ 'A071049',  110, 'number_of', value=>1, initial=>[0] ],

   [ 'A267253',  111, 'bits' ],
   [ 'A267254',  111, 'bignum', base=>2 ],
   [ 'A267255',  111, 'bignum' ],
   [ 'A267256',  111, 'bits', part => 'centre' ],
   [ 'A267257',  111, 'bignum_central_column' ],
   [ 'A267258',  111, 'bignum_central_column', base=>2 ],
   [ 'A267259',  111, 'number_of', value=>1 ],
   [ 'A267261',  111, 'number_of', value=>0 ],
   [ 'A267260',  111, 'number_of', value=>1, cumulative=>1 ],
   [ 'A267262',  111, 'number_of', value=>0, cumulative=>1 ],

   [ 'A267269',  115, 'bits' ],
   [ 'A267270',  115, 'bignum', base=>2 ],
   [ 'A267271',  115, 'bignum' ],

   [ 'A267272',  117, 'bits' ],
   [ 'A267273',  117, 'bignum', base=>2 ],
   [ 'A267274',  117, 'bignum' ],

   [ 'A071034',  118, 'bits' ],
   [ 'A267275',  118, 'bignum', base=>2 ],
   [ 'A267276',  118, 'bignum' ],

   [ 'A267292',  121, 'bits' ],
   [ 'A267293',  121, 'bignum', base=>2 ],
   [ 'A267294',  121, 'bignum' ],

   [ 'A267349',  123, 'bits' ],
   [ 'A267350',  123, 'bignum', base=>2 ],
   [ 'A267351',  123, 'bignum' ],
   [ 'A267352',  123, 'number_of', value=>1 ],
   [ 'A267354',  123, 'number_of', value=>0 ],
   [ 'A267353',  123, 'number_of', value=>1, cumulative=>1 ],

   [ 'A267355',  124, 'bits' ],
   [ 'A267356',  124, 'bignum', base=>2 ],
   [ 'A267357',  124, 'bignum' ],
   [ 'A071025',  124, 'bits', part=>'right' ],

   [ 'A267358',  125, 'bits' ],
   [ 'A267359',  125, 'bignum', base=>2 ],
   [ 'A267360',  125, 'bignum' ],

   [ 'A071035',  126, 'bits' ],
   [ 'A267364',  126, 'bignum', base=>2 ],
   [ 'A267365',  126, 'bignum' ],
   [ 'A267366',  126, 'bignum_central_column' ],
   [ 'A267367',  126, 'bignum_central_column', base=>2 ],
   [ 'A071050',  126, 'number_of', value=>0 ],
   [ 'A071051',  126, 'number_of', value=>1 ],
   [ 'A267368',  126, 'number_of', value=>1, cumulative=>1 ],
   [ 'A267369',  126, 'number_of', value=>0, cumulative=>1 ],
   
   [ 'A267417',  129, 'bits' ],
   [ 'A267440',  129, 'bignum', base=>2 ],
   [ 'A267441',  129, 'bignum' ],
   [ 'A267442',  129, 'bits', part => 'centre' ],
   [ 'A267443',  129, 'bignum_central_column' ],
   [ 'A267444',  129, 'bignum_central_column', base=>2 ],
   [ 'A267445',  129, 'number_of', value=>1 ],
   [ 'A267447',  129, 'number_of', value=>0 ],
   [ 'A267446',  129, 'number_of', value=>1, cumulative=>1 ],
   [ 'A267448',  129, 'number_of', value=>0, cumulative=>1 ],

   [ 'A267418',  131, 'bits' ],
   [ 'A267449',  131, 'bignum', base=>2 ],
   [ 'A267450',  131, 'bignum' ],
   [ 'A267451',  131, 'number_of', value=>1 ],
   [ 'A267453',  131, 'number_of', value=>0 ],
   [ 'A267452',  131, 'number_of', value=>1, cumulative=>1 ],
   [ 'A267454',  131, 'number_of', value=>0, cumulative=>1 ],

   [ 'A267423',  133, 'bits' ],
   [ 'A267456',  133, 'bignum', base=>2 ],
   [ 'A267457',  133, 'bignum' ],
   [ 'A267458',  133, 'number_of', value=>1 ],
   [ 'A267460',  133, 'number_of', value=>0 ],
   [ 'A267459',  133, 'number_of', value=>1, cumulative=>1 ],
   [ 'A267461',  133, 'number_of', value=>0, cumulative=>1 ],

   # 111 110 101 100 011 010 001 000
   #  1   0   0   0   0   1   1   1
   [ 'A265695',  135, 'bits' ],
   [ 'A265697',  135, 'bignum' ],
   [ 'A265696',  135, 'bignum', base=>2 ],
   [ 'A265698',  135, 'bits', part => 'centre' ],
   [ 'A265699',  135, 'bignum_central_column' ],
   [ 'A265700',  135, 'bignum_central_column', base=>2 ],
   [ 'A265703',  135, 'number_of', value=>0 ],
   [ 'A265701',  135, 'number_of', value=>1 ],
   [ 'A265702',  135, 'number_of', value=>1, cumulative=>1 ],
   [ 'A265704',  135, 'number_of', value=>0, cumulative=>1 ],
   
   [ 'A071036',  150, 'bits' ],
   [ 'A038184',  150, 'bignum' ],
   [ 'A118110',  150, 'bignum', base=>2 ],  # (previously also A245548)
   [ 'A038185',  150, 'bignum', part=>'left' ], # cut after central column
   [ 'A071053',  150, 'number_of', value=>1 ],
   [ 'A071052',  150, 'number_of', value=>0 ],
   [ 'A134659',  150, 'number_of', value=>1, cumulative=>1 ],
   [ 'A265223',  150, 'number_of', value=>0, cumulative=>1 ],

   [ 'A262866',  153, 'bignum' ],
   [ 'A262855',  153, 'bits' ],
   [ 'A262865',  153, 'bignum', part => 'centre', base=>2 ],
   [ 'A262867',  153, 'number_of', value=>1, cumulative=>1 ],
   [ 'A074330',  153, 'number_of', value=>0, cumulative=>1, y_start=>1 ],
   [ 'A071042',  153, 'number_of', value=>1,  # cf rule 90
      y_start=>1, initial=>[0] ], # sequence starts 0,... instead
   # [ 'A999999',  153, 'number_of', value=>0 ],  # 2*A001316
   
   [ 'A263243',  155, 'bits' ],
   [ 'A263244',  155, 'bignum', base=>2 ],
   [ 'A263245',  155, 'bignum' ],
   [ 'A263511',  155, 'number_of', value=>1, cumulative=>1 ],
   
   [ 'A071037',  158, 'bits' ],
   [ 'A118172',  158, 'bits' ],  # duplicate
   [ 'A118171',  158, 'bignum' ],
   [ 'A265379',  158, 'bignum', base=>2 ],
   [ 'A265380',  158, 'bignum_central_column' ],
   [ 'A265381',  158, 'bignum_central_column', base=>2 ],
   [ 'A071054',  158, 'number_of', value=>1 ],
   [ 'A029578',  158, 'number_of', value=>0 ],
   [ 'A265382',  158, 'number_of', value=>1, cumulative=>1 ],
   [ 'A211538',  158, 'number_of', value=>0, cumulative=>1, initial=>[0] ],
   
   [ 'A267463',  137, 'bits' ],
   [ 'A267511',  137, 'bignum', base=>2 ],
   [ 'A267512',  137, 'bignum' ],
   [ 'A267513',  137, 'bits', part => 'centre' ],
   [ 'A267514',  137, 'bignum_central_column' ],
   [ 'A267515',  137, 'bignum_central_column', base=>2 ],
   [ 'A267516',  137, 'number_of', value=>1 ],
   [ 'A267518',  137, 'number_of', value=>0 ],
   [ 'A267517',  137, 'number_of', value=>1, cumulative=>1 ],
   [ 'A267519',  137, 'number_of', value=>0, cumulative=>1 ],

   [ 'A267520',  139, 'bits' ],
   [ 'A267523',  139, 'bignum', base=>2 ],
   [ 'A267524',  139, 'bignum_central_column' ],

   [ 'A267525',  141, 'bits' ],
   [ 'A267526',  141, 'bignum', base=>2 ],
   [ 'A267527',  141, 'bignum' ],
   [ 'A267528',  141, 'number_of', value=>1 ],
   [ 'A267530',  141, 'number_of', value=>0 ],
   [ 'A267529',  141, 'number_of', value=>1, cumulative=>1 ],
   [ 'A267531',  141, 'number_of', value=>0, cumulative=>1 ],

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
   # [ 'A226464',  149, 'bits' ],  # no, this started from single 0
   [ 'A265717',  149, 'bignum' ],
   [ 'A265715',  149, 'bignum', base=>2 ],

   [ 'A070909',  156, 'bits', part=>'right' ],

   [ 'A263804',  157, 'bits' ],
   [ 'A263806',  157, 'bignum' ],
   [ 'A263805',  157, 'bignum', base=>2 ],
   [ 'A263807',  157, 'number_of', value=>1, cumulative=>1 ],

   [ 'A263919',  163, 'bits' ],
   [ 'A266753',  163, 'bignum' ],
   [ 'A266752',  163, 'bignum', base=>2 ],
   
   [ 'A266754',  165, 'bits' ],
   [ 'A267246',  165, 'bignum', base=>2 ],
   [ 'A267247',  165, 'bignum' ],
   
   [ 'A267576',  167, 'bits' ],
   [ 'A267577',  167, 'bignum', base=>2 ],
   [ 'A267578',  167, 'bignum' ],
   [ 'A267579',  167, 'bits', part => 'centre' ],
   [ 'A267580',  167, 'bignum_central_column' ],
   [ 'A267581',  167, 'bignum_central_column', base=>2 ],
   [ 'A267582',  167, 'number_of', value=>1 ],
   [ 'A267583',  167, 'number_of', value=>1, cumulative=>1 ],

   [ 'A264442',  169, 'bits' ],
   [ 'A267585',  169, 'bignum', base=>2 ],
   [ 'A267586',  169, 'bignum' ],
   [ 'A267587',  169, 'bits', part => 'centre' ],
   [ 'A267588',  169, 'bignum_central_column' ],
   [ 'A267589',  169, 'bignum_central_column', base=>2 ],
   [ 'A267590',  169, 'number_of', value=>1 ],
   [ 'A267592',  169, 'number_of', value=>0 ],
   [ 'A267591',  169, 'number_of', value=>1, cumulative=>1 ],
   [ 'A267593',  169, 'number_of', value=>0, cumulative=>1 ],

   [ 'A267594',  173, 'bits' ],
   [ 'A267595',  173, 'bignum', base=>2 ],
   [ 'A267596',  173, 'bignum' ],

   [ 'A265186',  175, 'bits' ],
   [ 'A262779',  175, 'bignum', base=>2 ],
   [ 'A266678',  175, 'bits', part=>'centre' ],
   [ 'A266680',  175, 'bignum_central_column' ],
   [ 'A267604',  175, 'bignum_central_column', base=>2 ],
   
   [ 'A267598',  177, 'bits' ],
   [ 'A267599',  177, 'bignum', base=>2 ],

   [ 'A267605',  181, 'bits' ],
   [ 'A267606',  181, 'bignum', base=>2 ],
   [ 'A267607',  181, 'bignum' ],

   [ 'A071038',  182, 'bits' ],
   [ 'A267608',  182, 'bignum', base=>2 ],
   [ 'A267609',  182, 'bignum' ],
   [ 'A071055',  182, 'number_of', value=>0 ],
   [ 'A267610',  182, 'number_of', value=>0, cumulative=>1 ],

   [ 'A267612',  185, 'bits' ],
   [ 'A267613',  185, 'bignum', base=>2 ],
   [ 'A267614',  185, 'bignum' ],

   [ 'A267621',  187, 'bits' ],
   [ 'A267622',  187, 'bignum', base=>2 ],
   [ 'A267623',  187, 'bignum_central_column' ],

   [ 'A118174',  188, 'bits' ],
   [ 'A118173',  188, 'bignum' ],
   [ 'A265427',  188, 'bignum', base=>2 ],
   [ 'A071026',  188, 'bits', part=>'right' ],
   [ 'A265428',  188, 'number_of', value=>1 ],
   [ 'A265430',  188, 'number_of', value=>0 ],
   [ 'A265429',  188, 'number_of', value=>1, cumulative=>1 ],
   [ 'A265431',  188, 'number_of', value=>0, cumulative=>1 ],

   [ 'A267635',  189, 'bits' ],

   [ 'A118111',  190, 'bits' ],
   [ 'A071039',  190, 'bits' ],  # dupliate
   [ 'A037576',  190, 'bignum' ],
   [ 'A265688',  190, 'bignum', base=>2 ],
   [ 'A032766',  190, 'number_of', value=>1, initial=>[0] ],
   [ 'A004526',  190, 'number_of', value=>0 ],
   [ 'A006578',  190, 'number_of', value=>1, cumulative=>1, initial=>[0] ],
   [ 'A002620',  190, 'number_of', value=>0, cumulative=>1 ],
   [ 'A166486',  190, 'bits', part => 'centre', initial=>[0] ], # rep 1,1,1,0
   [ 'A265380',  190, 'bignum_central_column' ],                # same rule 158
   [ 'A265381',  190, 'bignum_central_column', base=>2 ],       #

   [ 'A267636',  193, 'bits' ],
   [ 'A267645',  193, 'bignum', base=>2 ],
   [ 'A267646',  193, 'bignum' ],

   [ 'A267673',  195, 'bits' ],
   [ 'A267674',  195, 'bignum', base=>2 ],
   [ 'A267675',  195, 'bignum' ],

   # counts same as 141, bits different
   [ 'A267676',  197, 'bits' ],
   [ 'A267677',  197, 'bignum', base=>2 ],
   [ 'A267678',  197, 'bignum' ],
   [ 'A267528',  197, 'number_of', value=>1 ],
   [ 'A267530',  197, 'number_of', value=>0 ],
   [ 'A267529',  197, 'number_of', value=>1, cumulative=>1 ],
   [ 'A267531',  197, 'number_of', value=>0, cumulative=>1 ],

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
   [ 'A109241',  206, 'bignum', base=>2 ],

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

   [ 'A071040',  214, 'bits' ],
   [ 'A267805',  214, 'bignum' ],
   [ 'A267804',  214, 'bignum', base=>2 ],

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
   [ 'A078176',  225, 'bignum', part=>'whole', ystart=>1, inverse=>1 ],

   [ 'A267845',  227, 'bits' ],
   [ 'A267846',  227, 'bignum', base=>2 ],
   [ 'A267847',  227, 'bignum' ],

   [ 'A267848',  229, 'bits' ],
   [ 'A267850',  229, 'bignum', base=>2 ],
   [ 'A267851',  229, 'bignum' ],

   [ 'A267853',  230, 'bits' ],
   [ 'A267855',  230, 'bignum' ],
   [ 'A267854',  230, 'bignum', base=>2 ],
   [ 'A071027',  230, 'bits', part=>'left' ],
   [ 'A006977',  230, 'bignum', part=>'left' ],

   [ 'A267866',  231, 'bits' ],
   [ 'A267867',  231, 'bignum', base=>2 ],

   [ 'A267868',  233, 'bits' ],
   [ 'A267877',  233, 'bignum' ],
   [ 'A267876',  233, 'bignum', base=>2 ],
   [ 'A267878',  233, 'bits', part => 'centre' ],
   [ 'A267879',  233, 'bignum_central_column' ],
   [ 'A267880',  233, 'bignum_central_column', base=>2 ],
   [ 'A267881',  233, 'number_of', value=>1 ],
   [ 'A267883',  233, 'number_of', value=>0 ],
   [ 'A267882',  233, 'number_of', value=>1, cumulative=>1 ],
   [ 'A267884',  233, 'number_of', value=>0, cumulative=>1 ],

   [ 'A267869',  235, 'bits' ],
   [ 'A267885',  235, 'bignum', base=>2 ],
   [ 'A267886',  235, 'bignum' ],
   [ 'A267873',  235, 'number_of', value=>1 ],
   [ 'A267874',  235, 'number_of', value=>1, cumulative=>1 ],
   # 0s are fixed 0,1,2
   
   [ 'A267870',  237, 'bits' ],
   [ 'A267888',  237, 'bignum' ],
   [ 'A267887',  237, 'bignum', base=>2 ],
   [ 'A267872',  237, 'number_of', value=>1 ],

   [ 'A267871',  239, 'bits' ],
   [ 'A267889',  239, 'bignum', base=>2 ],
   [ 'A267890',  239, 'bignum' ],

   [ 'A267919',  243, 'bits' ],
   [ 'A267920',  243, 'bignum', base=>2 ],
   [ 'A267921',  243, 'bignum' ],

   [ 'A267922',  245, 'bits' ],
   [ 'A267923',  245, 'bignum', base=>2 ],
   [ 'A267924',  245, 'bignum' ],

   [ 'A071041',  246, 'bits' ],
   [ 'A267926',  246, 'bignum' ],
   [ 'A267925',  246, 'bignum', base=>2 ],

   [ 'A267927',  249, 'bits' ],
   [ 'A267934',  249, 'bignum', base=>2 ],
   [ 'A267935',  249, 'bignum' ],

   [ 'A002450',  250, 'bignum', initial=>[0] ], # (4^n-1)/3 10101 extra 0 start

   [ 'A267936',  251, 'bits' ],
   [ 'A267937',  251, 'bignum', base=>2 ],
   [ 'A267938',  251, 'bignum' ],

   [ 'A118175',  252, 'bits' ],

   [ 'A267940',  253, 'bignum', base=>2 ],
   [ 'A267941',  253, 'bignum' ],

   # [ 'A060576', 255, 'bits' ], # homeomorphically irreducibles ...

   [ 'A071022', 198, 'bits', part=>'left' ],

   # right half solid 2^n-1
   [ 'A118175', 220, 'bits' ],
   [ 'A000225', 220, 'bignum', initial=>[0] ], # 2^n-1 want start from 1
   [ 'A000042', 220, 'bignum', base=>2 ],  # half-width 1s


   [ 'A071048', 110, 'number_of', value=>0, part=>'left' ],



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

   # whole solid, decimal repunits
   [ 'A100706', 151, 'bignum', base=>2 ],

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

if (0) {
  my @seen;
  my $prev = $data[0]->[1];
  foreach my $elem (@data) {
    my ($anum, $rule, $method, @params) = @$elem;
    if ($rule != $prev && $seen[$rule]) {
      warn "rule $rule second block, method=$method";
    }
    $seen[$rule] = 1;
    $prev = $rule;
  }
}
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
  my $want_value = $params{'value'};
  if (! defined $want_value) { $want_value = 1; }
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
  my $y_start = $params{'y_start'} // 0;
  my $part = $params{'part'} || 'whole';
  my $want_value = $params{'value'};
  if (! defined $want_value) { $want_value = 1; }
  my $max_count = $params{'max_count'};

  my $path = Math::PlanePath::CellularRule->new (rule => $rule);

  my @got = @$initial;
  my $number_of = 0;
  for (my $y = $y_start; @got < $count; $y++) {
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
# number of runs (or blocks) of value 0 or 1

sub number_of_runs {
  my ($anum, $rule, %params) = @_;
  my $want_value = $params{'value'};
  my $max_count = $params{'max_count'} || 100;

  MyOEIS::compare_values
      (anum => $anum,
       name => "$anum number of runs in rows rule $rule"
       . (defined $want_value ? ", value $want_value" : ""),
       max_count => $max_count,
       func => sub {
         my ($count) = @_;
         my $path = Math::PlanePath::CellularRule->new (rule => $rule);
         my @got;
         for (my $y = 0; @got < $count; $y++) {
           my $prev = -1;
           my $number_of_runs = 0;
           foreach my $x (-$y .. $y) {
             my $n = $path->xy_to_n ($x, $y);
             my $got_value = (defined $n ? 1 : 0);
             if ((! defined $want_value || $got_value == $want_value)
                 && $got_value != $prev) {
               $number_of_runs++;
             }
             $prev = $got_value;
           }
           push @got, $number_of_runs;
         }
         return \@got;
       });
}

sub longest_run {
  my ($anum, $rule, %params) = @_;
  my $want_value = $params{'value'};
  if (! defined $want_value) { $want_value = 1; }
  my $max_count = $params{'max_count'} || 100;

  MyOEIS::compare_values
      (anum => $anum,
       name => "$anum number of ${want_value}s in rows rule $rule",
       max_count => $max_count,
       func => sub {
         my ($count) = @_;
         my $path = Math::PlanePath::CellularRule->new (rule => $rule);
         my @got;
         for (my $y = 0; @got < $count; $y++) {
           my $longest = 0;
           my $len = 0;
           foreach my $x (-$y .. $y) {
             my $n = $path->xy_to_n ($x, $y);
             my $got_value = (defined $n ? 1 : 0);
             if ($got_value == $want_value) {
               $len++;
             } else {
               if ($len) { $longest = max($longest, $len); }
               $len = 0;
             }
           }
           push @got, $longest;
         }
         return \@got;
       });
}

#------------------------------------------------------------------------------
# number of 0s or 1s in row at the rightmost end

sub trailing_number_of {
  my ($anum, $rule, %params) = @_;
  my $initial = $params{'initial'} || [];
  my $part = $params{'part'} || 'whole';
  my $want_value = $params{'value'};
  if (! defined $want_value) { $want_value = 1; }

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
             my $cell = $path->xy_is_visited ($x,$y) ? 1 : 0;
             if ($params{'complement'}) { $cell = 1-$cell; }
             push @got, $cell;
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

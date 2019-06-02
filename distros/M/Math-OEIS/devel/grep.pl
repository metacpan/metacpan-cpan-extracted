#!/usr/bin/perl -w

# Copyright 2014, 2015, 2016, 2017, 2019 Kevin Ryde

# This file is part of Math-OEIS.
#
# Math-OEIS is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-OEIS is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-OEIS.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use FindBin;
use Math::OEIS::Grep;

# uncomment this to run the ### lines
use Smart::Comments;


{
  # grep-not-in-oeis.pl non-ascii
  system("$FindBin::Bin/../examples/grep-not-in-oeis.pl",
         "$FindBin::Bin/$FindBin::Script");
  # Sierpinski
  # not in OEIS: 24, 60, 168, 492, 1464, 4380, 13128
  # not A178674 3^n+3 is half
  exit 0;
}
{
  # my ($m,$n);
  # require Data::Dumper;
  # use Math::BigInt try => 'Calc';
  # BEGIN {
  #   $m = Math::BigInt->new(123);
  #   print Data::Dumper::Dumper($m);
  # }
  # use Math::BigInt try => 'GMP';
  # BEGIN {
  #   $n = Math::BigInt->new(123);
  #   print Data::Dumper::Dumper($n);
  # }
  # ### $m
  # ### $n
  # print $m + $n;
  exit;
}
{
  # non-ascii
  # require Module::Mask;
  # my $mask = Module::Mask->new;
  # $mask->mask_modules('Encode::Locale');

  # Math::OEIS::Grep->import(-search=>1,2,12,152,3472,126752,6781632,500231552);

  # Sierpinski
  Math::OEIS::Grep->import(-search=>1,3,5,15,17,51,85,255,257,771,1285,3855,4369,13107,21845,65535);
  exit 0;
}

{
  # bug of matching too much when regexp allowed to end
  # 2,2,1,1,2,1,2,2,1,2,1,1,2,2,1,1
  my $aref = [1, '9'x70];
  Math::OEIS::Grep->search(verbose=>1, array=>$aref);
  exit 0;
}

{
  # bug of matching too much when regexp allowed to end
  # 2,2,1,1,2,1,2,2,1,2,1,1,2,2,1,1
  my $str = '2,2,1,1,2,1,2,2,1,2,1,1,2,2,1,1';
  my $aref = [2,2,1,1,2,1,2,2,1,2,1,1,2,2,1,1];
  # $aref = [1,2,3,4,5,6,7,8,9,10,11,12,13];

  my $re = Math::OEIS::Grep->array_to_regexp($aref);
  print "$re\n";
  system("grep $str ~/OEIS/stripped");
  Math::OEIS::Grep->search(verbose=>1, array=>$aref);

  my $line = 'A049710 ,2,1,2,2,1,2,1,1,2,1,1,2,2,1,2,2,1,1,2,1,2,2,1,2,1,1,2,2,1,2,2,1,2,1,1,2,1,1,2,2,1,2,1,1,2,1,2,2,1,2,2,1,1,2,1,1,2,2,1,2,1,1,2,1,1,2,2,1,2,2,1,2,1,1,2,1,2,2,1,1,2,1,1,2,2,1,2,1,1,2,1,1,2,2,1,2,2,1,1,2,1,2,2,1,2,';
  if ($line =~ $re) {
    print "match\n";
  }
  exit 0;
}

{
  # match of A109680 which has only a few terms
  # A109680 = 2^(4n-2) - A104403(n)
  # A104403 = 0 then A102371(4n)/4.
  # A102371 = numbers missing from A102370
  # A102370 = sloping binary numbers
  # 1, 2, 3, 4, 1, 6, 7, 8, 5, 10, 11, 12, 9, 14, 15, 16, 13, 18, 19, 20
  Math::OEIS::Grep->search(array=>[1, 2, 3, 4, 1, 6, 7, 8, 5, 10, 11, 12, 9, 14, 15, 16, 13, 18, 19, 20 ],
                           use_mmap => 0);
  Math::OEIS::Grep->search(array=>[1, 2, 3, 4, 1, 6, 7, 8, 5 ],
                           use_mmap => 0);
  exit 0;
}

{
  # average line length in the "stripped" file

  require Math::OEIS::Stripped;
  my $fh = Math::OEIS::Stripped->fh;
  my $max_len = 0;
  my $max_len_anum = '';
  my $count;
  my $total;
  while (my $line = readline $fh) {
    my ($anum, $values) = Math::OEIS::Stripped->line_split_anum($line)
      or next;
    $values =~ /\d/ or next;
    if (length($line) > $max_len) {
      $max_len = length($values);
      $max_len_anum = $anum;
    }
    $count++;
    $total += length($values);
  }
  my $average = $total/$count;
  print "max len $max_len at $max_len_anum average $average of $count\n";
  exit 0;
}

{
  # negative initial value
  require Math::OEIS::Stripped;
  my $anum = 'A118831';
  my $str = Math::OEIS::Stripped->anum_to_values_str($anum);
  ### $str
  exit 0;
}
{
  Math::OEIS::Grep->search(array=>[ 8,26,80,242,728,2186,6560,19682,59048,177146,531440 ]);
  exit 0;
}
{
  # leading "+" signs
  system('perl -MMath::OEIS::Grep=-search,+123,456,789');
  exit 0;
}
{
  system('HOME=/no/such/dir perl -MMath::OEIS::Grep=-search,123,456,789');

  # when no ~/OEIS/stripped file
  $ENV{'HOME'} = '/no/such/dir';
  Math::OEIS::Grep->search(array=>[ 123,456,789 ]);
  exit 0;
}
{
  # dodgy stringizing from Math::BigInt::GMP
  require Math::BigInt;
  Math::BigInt->import (try => 'GMP');

  Math::OEIS::Grep->search(array=>[ 13802006746828966928 ]);
  Math::OEIS::Grep->search(array=>[ '13802006746828966928' ]);
  exit 0;
}
{
  Math::OEIS::Grep->search(array=>[2,10,34,106,322,970,2914]);
  exit 0;
}
{
  # grep with names

  Math::OEIS::Grep->search(name => 'name one',
                           array=>['70760']);
  Math::OEIS::Grep->search(name => 'name two',
                           array=>['-70769800810139187843']);
  Math::OEIS::Grep->search(name => 'name two',
                           array=>[42894032],
                           verbose => 1);
  exit 0;
}

{
  Math::OEIS::Grep->search(array=>['70760'],
                           use_mmap => 0);
  Math::OEIS::Grep->search(array=>['70769800810139187843'],
                           use_mmap => 0);
  Math::OEIS::Grep->search(array=>[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,2,1],
                           use_mmap => 0);
  exit 0;
}



{
  my $fh;
  open $fh, '< /etc/passwd';
  print readline $fh;
  exit 0;
}

#!/usr/bin/perl -w

# Copyright 2014, 2015, 2016, 2017, 2019, 2020 Kevin Ryde

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
use File::Slurp;
use Math::OEIS;

# uncomment this to run the ### lines
use Smart::Comments;


{
  # ~/OEIS/Index to OEIS Section Rec - OeisWiki.html

  my $filename = Math::OEIS->local_filename
    ('Index to OEIS Section Rec - OeisWiki.html');
  my $str = File::Slurp::read_file($filename);
  open my $fh, '>', '/tmp/foo.gp' or die;
  print $fh <<'HERE';
default(recover,0);
default(strictargs,1);
signatures={[
HERE
  my $count = 0;
  while ($str =~ m{<dd>\((.*?)\)}sg) {
    my $coeffs = $1;
    # print "$coeffs\n";
    my @coeffs = split /,/, $coeffs;
    next unless @coeffs >= 2;
    next if $coeffs =~ /\.\.\./;  # incomplete
    print $fh "[$coeffs],\n";
    $count++;
  }
  print $fh "[]]};\n";
  print "$count signatures\n";
  print $fh <<'HERE';
print(#signatures" vector length");
want = x^3 - x^2 - 2;
want = x^5 - x^4 - x^2 - 1;
want = x^2 - 11*x + 9;
want = x^2 - 5*x + 2;     \\ A082486, rpp, rpq growth
printcompact(v) =
{
  print1("[");
  for(i=1,#v, print1(v[i],if(i==#v,"",",")));
  print1("]");
}
{
  for(i=1,#signatures,
    my(p=-Pol(concat([1],-signatures[i])),
       f=factor(p));
    \\ printcompact(signatures[i]); print(" "p" "f);
    for(j=1,matsize(f)[1],
       if(f[j,1]==want,
         printcompact(signatures[i]);
         print("      "p" "f);
         my(roots=vecsort(abs(polroots(p)),,4));
         print("  biggest "roots[1]);
       )));
}
HERE
  system 'gp --quiet </tmp/foo.gp';
  exit 0;
}

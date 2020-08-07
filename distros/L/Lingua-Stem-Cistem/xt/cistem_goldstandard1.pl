#!perl

use strict;
use warnings;

use utf8;

binmode(STDOUT,":encoding(UTF-8)");
binmode(STDERR,":encoding(UTF-8)");


#use lib qw(../CISTEM);
#use lib qw(../CISTEM-orig/CISTEM);
use lib qw(./lib/);

use CistemOrigFast;

my $file = '../CISTEM/gold_standards/goldstandard1.txt';

my $line_count = 0;
my $word_count = 0;

  open(my $file_in,"<:encoding(UTF-8)",$file)
    or die "cannot open $file: $!";

  while (my $line = <$file_in>) {
    $line_count++;

    chomp $line;
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;
    for my $word ( split(/\s+/,$line) ) {
      $word_count++;

      CistemOrigFast::segment($word,0);
      #Cistem::stem($word,0);
  	}
  }

  close $file_in;

  print '$line_count: ',$line_count,' $word_count: ', $word_count, "\n";

=pod

items

gs1 $line_count: 30746 $word_count: 317441
gs2 $line_count: 50362 $word_count: 310067


performance

Intel® Core™ i7-4770HQ Processor
4 Cores, 8 Threads
2.20 - 3.40 GHz
6 MB Cache
16GB DDR3 RAM


File  method  casing  real     factor variant
gs1   stem    0       0m2.897s 1.000  0) original (0m2.850s)
                      0m2.577s 0.889  1) no s/öö/oo/g
                      0m2.576s 0.889  2) no pass
                      0m2.560s 0.883  3) 1) + 2) *** fastest ***
                      0m2.859s        4) 3) + strict, warnings
                      0m2.633s        5) 4) + tr///
                      0m3.218s        6) 5) + NFC # slower 22%
                      0m3.095s        7) 6) + no /ei/\%/
                      0m3.086s        10) stem() wraps segment()
                      0m2.643s 0.912  11) ~ 5)
                      0m2.657s        OrigFast: 1) + 2) + 5)

gs1   segment 0       0m2.626s 1.000  0) original (0m2.560s)
                      0m2.695s        3) 1) + 2)
                      0m2.706s        4) 3) + strict, warnings
                      0m3.486s        7) 6) + no /ei/\%/
                      0m2.903s        8) - NFC
                      0m5.169s        9) 8) + precompiled qr//
                      0m2.876s 1.095  10) 11) + returns ($prefix,$word,$suffix)
                      0m2.860s        12) 10) no tr/// no s/ß/ss/
                      0m2.826s        13) 12) no s/^ge//
                      0m2.573s        OrigFast: 0)

=cut

=pod

for my $word (@words) {
  for my $case_sensitive (0..1) {
    print 'Cistem::stem(',$word,',',$case_sensitive,'): ',
    Cistem::stem($word,$case_sensitive),"\n";
  }

  for my $case_sensitive (0..1) {
    print 'Cistem::segment(',$word,',',$case_sensitive,'): ',
    join('-',Cistem::segment($word,$case_sensitive)),"\n";
  }
}

=cut



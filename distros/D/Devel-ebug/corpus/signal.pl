#!perl
use strict;
use warnings;

foreach my $i (1..50) {
  my $square = $i * $i;
  kill 2, $$ if $square > 100;
  print "$square\n";
}

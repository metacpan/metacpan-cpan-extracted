#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;
#Checks the open2 function

my $machine = shift || 'orion.pcg.ull.es';
my $m = GRID::Machine->new( host => $machine );

my ($fc, $tc);
my $pid = $m->open2($fc, $tc, 'sort -n');
my $i;
for($i=10; $i>=0;$i--) {
  print $tc "$i\n";
}
close($tc); # Finish sort

print while <$fc>;

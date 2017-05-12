#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $machine = shift || 'orion.pcg.ull.es';
my $m = GRID::Machine->new( host => $machine );

my $i;
my $f = $m->open('| sort -n > /tmp/sorted.txt');
for($i=10; $i>=0;$i--) {
  $f->print("$i\n")
}
$f->close();

my $g = $m->open('/tmp/sorted.txt');
print while <$g>;

#!/usr/bin/perl -w
use strict;
use GRID::Machine;
use GRID::Machine::Group;
use List::Util qw(sum);

my $host = $ENV{GRID_REMOTE_MACHINE}; 
my $code = << 'EOFUNCTION';
   double sigma(int id, int N, int np) {
     double sum = 0;
     int i;
     for(i = id; i < N; i += np) {
         double x = (i + 0.5) / N;
         sum += 4 / (1 + x * x);
     }
     sum /= N; 
     return sum;
   }
EOFUNCTION
;

my $c = GRID::Machine->new(
  host => $host, 
  uses => [ qq{Inline  'C' => q{$code}} ],
);

print($c->eval(q{
  print sigma(0,1000, 1);
}));

print "\n";



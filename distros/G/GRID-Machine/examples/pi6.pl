#!/usr/bin/perl -w
use strict;
use GRID::Machine;
use GRID::Machine::Group;
use List::Util qw(sum);

my @MACHINE_NAMES = split /\s+/, $ENV{MACHINES};
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

my @m = map { 
              GRID::Machine->new(
                 host => $_, 
                 wait => 5, 
                 uses => [ qq{Inline  'C' => q{$code}} ],
                 survive => 1,
              ) 
            } @MACHINE_NAMES;

my $c = GRID::Machine::Group->new(cluster => [ @m ]);

$c->makemethod('sigma'); # filter => 'result' does not work

my ($N, $np, $pi)  = (1000, 4, 0);

my @args = map {  [$_, $N, $np] } 0..$np-1;

print sum($c->sigma(args => \@args)->Results)."\n";




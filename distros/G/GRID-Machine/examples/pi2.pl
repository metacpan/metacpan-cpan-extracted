#!/usr/bin/perl -w
use strict;
use GRID::Machine;
use GRID::Machine::Group;
use List::Util qw(sum);

my @MACHINE_NAMES = split /\s+/, $ENV{MACHINES};
my $c = GRID::Machine::Group->new(cluster => [ @MACHINE_NAMES ]);

$c->sub(suma_areas => q{
   my ($id, $N, $np) = @_;
     
   my $sum = 0;
   for (my $i = $id; $i < $N; $i += $np) {
       my $x = ($i + 0.5) / $N;
       $sum += 4 / (1 + $x * $x);
   }
   $sum /= $N; 
});

my ($N, $np, $pi)  = (1000, 4, 0);

my @args = map {  [$_, $N, $np] } 0..$np-1;

print sum($c->suma_areas( args => \@args )->Results)."\n";
print sum($c->suma_areas( args => \@args )->Results)."\n";
print sum($c->suma_areas( args => \@args )->Results)."\n";



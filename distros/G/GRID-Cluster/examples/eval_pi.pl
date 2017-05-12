#!/usr/bin/perl
use warnings;
use strict;

use GRID::Cluster;
use Data::Dumper;

my $cluster = GRID::Cluster->new( 
              debug =>      { orion => 0, beowulf => 0, europa => 0, bw => 0 },
              max_num_np => { orion => 1, beowulf => 1, europa => 1, bw => 1} );

my @machines = ('orion', 'bw', 'beowulf', 'europa');
my $np = @machines;
my $N = 100000000;

my $r = $cluster->eval(q{

             my ($N, $np) = @_;
               
             my $sum = 0;
              
             for (my $i = SERVER->logic_id; $i < $N; $i += $np) {
                 my $x = ($i + 0.5) / $N;
                 $sum += 4 / (1 + $x * $x);
             }

             $sum /= $N;

         }, $N, $np );

print Dumper($r);

my $result = 0;

foreach (@machines) {
  $result += $r->{$_}->result;
}

print "\nEl resultado del cálculo de PI es: $result\n";

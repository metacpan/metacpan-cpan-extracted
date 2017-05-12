#!/usr/bin/perl
use warnings;
use strict;

use GRID::Cluster;
use Data::Dumper;

my @machines = split(/:/, $ENV{GRID_REMOTE_MACHINES});

my ($debug, $max_num_np);

for (@machines) {
  $debug->{$_} = 0;
  $max_num_np->{$_} = 1;
}

my $cluster = GRID::Cluster->new(host_names => \@machines, debug => $debug, max_num_np => $max_num_np)
   || die "No machines has been initialized in the cluster";


my $np = @machines;
my $N = 1000; 

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

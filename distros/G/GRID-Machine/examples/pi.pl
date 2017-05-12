#!/usr/bin/perl -w
use strict;
use GRID::Machine;
use GRID::Machine::Group;
use List::Util qw(sum);
use Time::HiRes qw(time gettimeofday tv_interval);

my @MACHINE_NAMES = ('', '');
@MACHINE_NAMES = split /\s+/, $ENV{MACHINES} if $ENV{MACHINES};

my @m = map { GRID::Machine->new(host => $_, wait => 5, survive => 1) } @MACHINE_NAMES;

my $c = GRID::Machine::Group->new(cluster => [ @m ]);

$c->sub(suma_areas => q{
   my ($id, $N, $np) = @_;
     
   my $sum = 0;
   for (my $i = $id; $i < $N; $i += $np) {
       my $x = ($i + 0.5) / $N;
       $sum += 4 / (1 + $x * $x);
   }
   $sum /= $N; 
});

my ($N, $np, $pi)  = (1e7, 32, 0);

my @args = map {  [$_, $N, $np] } 0..$np-1;

my $t0 = [gettimeofday];
$pi = sum($c->suma_areas(args => \@args)->Results);
my $elapsed = tv_interval ($t0);
print "Pi = $pi. N = $N Time = $elapsed\n";



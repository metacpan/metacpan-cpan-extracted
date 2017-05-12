#!/usr/local/bin/perl -w
use strict;
use GRID::Machine qw(is_operative);
use Data::Dumper;

my $host = 'beowulf.pcg.ull.es';
#my $host = 'rbeo';

my $machine = GRID::Machine->new( 
      host => $host,
      sshoptions => '-i /home/pp2/.ssh/ursu -l ursulill',
      cleanup => 1,
      sendstdout => 1,
      startdir => 'tutu',
   );

my $dir = $machine->getcwd->result;
print "$dir\n";
$machine->put([qw{chdir.pl nested.pl}]);
print $machine->eval(q{ system('ls -l') })->stdout;

$machine->put([qw{chdir.pl nested.pl}], '..');
print $machine->eval(q{ system('ls -l ..') })->stdout;

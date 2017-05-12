#!/usr/local/bin/perl -w
use strict;
use GRID::Machine qw(is_operative);
use Data::Dumper;

#my $host = 'casiano@orion.pcg.ull.es:22';
#my $host = 'rbeo';

my $machine = GRID::Machine->new( 
      #host => $host,
      command => q{ssh -i /home/pp2/.ssh/ursu -p 2048 ursulill@localhost perl},
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

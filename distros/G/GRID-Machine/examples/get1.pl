#!/usr/local/bin/perl -w
use strict;
use GRID::Machine qw(is_operative);
use Data::Dumper;

my $host = shift || 'casiano@orion.pcg.ull.es';

my $machine = GRID::Machine->new( 
      host => $host,
      cleanup => 1,
      sendstdout => 1,
      startdir => 'tutu',
   );

my $dir = $machine->getcwd->result;
print "$dir\n";
$machine->put([qw{chdir.pl nested.pl}]);
print $machine->eval(q{ system('ls -l') })->stdout;

$machine->get([qw{chdir.pl nested.pl}], '..');

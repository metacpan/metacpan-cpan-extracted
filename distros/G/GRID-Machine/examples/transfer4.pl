#!/usr/local/bin/perl -w
use strict;
use GRID::Machine qw(is_operative);
use Data::Dumper;

my $host = shift || 'casiano@orion.pcg.ull.es';

my $machine = GRID::Machine->new( 
      host => $host,
      cleanup => 1,
      sendstdout => 1,
      startdir => 'perl5lib',
      prefix => '/home/casiano/perl5lib/',
   );

my $dir = $machine->getcwd->result;
print "$dir\n";

$machine->modput('Parse::Eyapp::');
my $a = $machine->qx('tree');
print $a;


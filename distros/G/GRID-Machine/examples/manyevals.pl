#!/usr/local/bin/perl -w
use strict;
use GRID::Machine qw(is_operative);
use Data::Dumper;

my $host = 'casiano@orion.pcg.ull.es';

my $machine = GRID::Machine->new( 
      host => $host,
      cleanup => 1,
      sendstdout => 1,
      startdir => 'tutu',
   );

print "**************\n".$machine->eval(q{ system('ls -l') })->stdout;
print "**************\n".$machine->eval(q{ system('ls -l') })->stdout;


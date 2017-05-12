#!/usr/local/bin/perl -w
use strict;
use GRID::Machine qw(is_operative);
use Data::Dumper;

my $host = 'casiano@orion.pcg.ull.es';

my $machine = GRID::Machine->new( 
      host => $host,
      cleanup => 1,
      sendstdout => 1,
      startdir => '/tmp',
   );

my $dir = $machine->getcwd->result;
print "$dir\n";

my $umask = $machine->umask(044);
print Dumper($umask);
$umask = $machine->umask(022);
print Dumper($umask);

my $r = $machine->mkdir("remote$$", 0777);
#my $r = $machine->mkdir("remote$$");
print Dumper($r);
print $machine->eval(q{ system('ls -ltr') })->stdout;

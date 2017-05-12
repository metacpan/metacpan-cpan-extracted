#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $host = 'orion.pcg.ull.es';
my $dir = shift || "somedir";
my $file = shift || $0; # By default copy this program

my $machine = GRID::Machine->new( 
  host => $host, 
  uses => [qw(Sys::Hostname)],
);

my $r;
$r = $machine->mkdir($dir, 0777) unless $machine->_w($dir);
die "Can't make dir\n" unless $r->ok;
$machine->chdir($dir)->ok or die "Can't change dir\n";
$machine->put([$file]) or die "Can't copy file\n";
print "HOST: ",$machine->eval(" hostname ")->result,"\n",
      "DIR: ",$machine->getcwd->result,"\n",
      "FILE: ",$machine->glob('*')->result,"\n";


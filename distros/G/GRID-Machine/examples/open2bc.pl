#!/usr/bin/perl -w
use strict;
use GRID::Machine;
use POSIX;
use constant BUFFERSIZE => 1024;

my $line;

my $machine = shift || 'orion.pcg.ull.es';
my $m = GRID::Machine->new( host => $machine );

my $WTR = IO::Handle->new();  
my $RDR = IO::Handle->new(); 
my $pid = $m->open2($RDR, $WTR, 'bc'); 
# Execute bc in trusted remote machine
$RDR->blocking(1); # Non blocking read

while (<STDIN>) {         # read command from user
  syswrite($WTR, $_);     # write a command to 'bc' in $m
  my $br = sysread($RDR, $line, BUFFERSIZE);
  if (defined $br) {
    exit 0 if $br == 0;
    print STDOUT $line;
  }
}
print $WTR "quit\n";
wait;

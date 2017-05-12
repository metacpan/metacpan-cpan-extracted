#!/usr/bin/perl -w
use strict;
use GRID::Machine;
use Data::Dumper;

my $host = $ENV{GRID_REMOTE_MACHINE};
my $machine = GRID::Machine->new( host => $host );

$machine->sub(hi=> q{

   print "stdout: Hello from process $$. args = (@_)\n";
   print STDERR "stderr: Hello from process $$\n";

   use List::Util qw{sum};
   return { s => sum(@_), args => [ @_ ] };
});

my $p = $machine->async( hi => 1..4 );

# GRID::Machine::Process objects are overloaded
print "Doing something while $p is still alive  ...\n" if $p; 

my $r = $machine->waitall();

print "Result from process '$p': ",Dumper($r),"\n";
print "GRID::Machine::Process::Result objects are overloaded in a string context:\n$r\n";

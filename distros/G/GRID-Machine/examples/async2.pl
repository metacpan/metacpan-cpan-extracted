#!/usr/bin/perl -w
use strict;
use GRID::Machine;
use Data::Dumper;
$Data::Dumper::Indent = 1;

my $host = $ENV{GRID_REMOTE_MACHINE};
my $machine = GRID::Machine->new( host => $host );

$machine->sub(sum => q{
   use List::Util qw{sum};
   return sum(@_);
 });

$machine->sub(add => q{
   use List::Util qw{min};
   return  min(@_);
});

my $p  = $machine->async( sum  =>  1..4 );
my $p1 = $machine->async( add =>  7, 2, 9, 8, -1, 4 );

# GRID::Machine::Process objects are overloaded
print "Doing something while $p and $p1 are still alive  ...\n" if ($p and $p1); 

my $r = $machine->waitall()->result;

print "Result from process: $r\n";

$r = $machine->waitall()->result;
print "Result from process: $r\n";


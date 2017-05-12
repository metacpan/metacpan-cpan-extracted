#!/usr/bin/perl -w
use strict;
use GRID::Machine;

my $host = $ENV{GRID_REMOTE_MACHINE}; 
my $debug = @ARGV ? 1234 : 0;

my $machine = GRID::Machine->new(host => $host, debug => $debug);

$machine->sub( hi => q{ my $n = shift; "Hello $n\n"; } );

print $machine->hi('Jane')->result;

# same thing
print $machine->eval(q{ hi(shift()) }, 'Jane')->result;

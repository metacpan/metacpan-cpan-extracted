#!/usr/local/bin/perl -w
use strict;
use GRID::Machine qw(is_operative);
use Data::Dumper;

my $host = $ENV{GRID_REMOTE_MACHINE};

my $machine = GRID::Machine->new( 
      host => $host,
      cleanup => 1,
      sendstdout => 1,
   );

my $dir = $machine->getcwd->result;
print "$dir\n";

# see the difference in the output with include.pl
# sub new is installed but with the name 'buzz'
#
$machine->include("GRID::Machine::Result", alias => { new => 'buzz' });

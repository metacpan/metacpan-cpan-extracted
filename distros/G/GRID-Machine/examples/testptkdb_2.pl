#!/usr/local/bin/perl -w
# Execute this program being the user
# that initiated the X11 session
use strict;
use GRID::Machine;

my $host = $ENV{GRID_REMOTE_MACHINE};

my $machine = GRID::Machine->new(
   command => "ssh -X $host perl", 
);

print $machine->eval(q{ 
  print "$ENV{DISPLAY}\n" if $ENV{DISPLAY};
  CORE::system('xclock') and  warn "Mmmm.. something went wrong!\n";
  print "Hello world!\n";
});

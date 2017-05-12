#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $host = $ENV{GRID_REMOTE_MACHINE};

my $machine = GRID::Machine->new(host => $host,);

$machine->include(shift() || "Include4");

print "1+..+5 = ".$machine->sigma( 1..5 )->result."\n";

$machine->put([$0]);

for my $method (qw(r w e x s t f d)) {
  if ($machine->can($method)) {
    my $r = $machine->$method($0)->result || "";
    print $machine->host."->$method( include4.pl ) = <$r>\n";
  }
}

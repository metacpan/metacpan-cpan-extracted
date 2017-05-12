#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $name = shift;
my $host = $ENV{GRID_REMOTE_MACHINE} || shift;

for my $r (qw(MyRemote MyRemote2)) {
  my $machine = GRID::Machine->new(host => $host, remotelibs => [ $r ]);

  $machine->send_operation( "MYTAG", $name);
  my ($type, $result) = $machine->read_operation();

  print $result;
}


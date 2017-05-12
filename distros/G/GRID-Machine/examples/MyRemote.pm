package GRID::Machine;
use strict;

sub MYTAG {
  my ($server, $name) = @_;

  $server->send_operation("RETURNED", "Hello $name!\n") if defined($name); 
  $server->send_operation("DIED", "Error: Provide a name to greet!\n");
}

1;

package MyMachine;
use GRID::Machine;
use strict;

sub myrequest {
   my $self = shift;
   my $name = shift;

   $self->send_operation( "MyMachine::MYTAG", $name );

   my ($type, $result) = $self->read_operation();
   return $result;
}

1;

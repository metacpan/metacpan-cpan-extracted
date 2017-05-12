{
  package GRID::Machine::Process;
  use warnings;
  use strict;
  use GRID::Machine::MakeAccessors; 

  my @legal = qw(machine pid stdin stdout stderr result);
  my %legal = map { $_ => 1 } @legal;

  GRID::Machine::MakeAccessors::make_accessors(@legal);

  use overload q("") => 'str',
               bool  => 'alive';

  sub waitpid {
   my $self = shift;

   my $machine = $self->machine;
   
   #delegate
   $machine->waitpid($self, @_);
  }

  our $separator = ':';
  sub str {
    my $self = shift;

    my $machine = $self->machine;

    "$$".$separator.
    $machine->{pid}.$separator.
    $machine->host.$separator.
    $machine->getpid.$separator.
    $self->pid;
  }

  sub alive {
    my $self = shift;

    my $pid = $self->{pid};
    $self->{machine}->poll($pid);
  }
}

{
  package GRID::Machine::Process::Result;
  use warnings;
  use strict;
  use GRID::Machine::MakeAccessors; 

  my @legal = qw(stdout stderr results status waitpid descriptor machineID errmsg);
  my %legal = map { $_ => 1 } @legal;

  GRID::Machine::MakeAccessors::make_accessors(@legal);

  use overload q("") => 'str',
               bool  => 'bool';

  sub bool {
    my $self = shift;

    0+$self->Results > 1 ? 1 : $self->result;
  }

  sub result {
    my $self = shift;

    return $self->{results}[0];
  }

  sub Results {
    my $self = shift;

    return @{$self->{results}};
  }

  sub str {
    my $self = shift;

    return $self->{stdout}.$self->{stderr}.$self->{errmsg}
  }
}

1;

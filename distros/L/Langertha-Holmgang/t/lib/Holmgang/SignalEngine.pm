package Holmgang::SignalEngine;
# Test engine for holmgang run's cancel on a signal (k15): a
# Langertha::Engine::Virtual that sends its own process SIGINT with its first
# request, as an operator pressing Ctrl-C while the first case runs.
use Moose;
extends 'Langertha::Engine::Virtual';

my $SENT = 0;

around chat_f => sub {
  my ( $orig, $self, @args ) = @_;
  kill 'INT', $$ unless $SENT++;
  return $self->$orig(@args);
};

__PACKAGE__->meta->make_immutable;

1;

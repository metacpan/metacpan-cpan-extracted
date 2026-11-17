package Holmgang::HeldEngine;
# Test engine for the batch's concurrency (k15): a Langertha::Engine::Virtual
# whose answers the test hands out. Each chat_f is answered by the Virtual
# rules at once (so requests records the order the requests went out), but
# returns a pending Future that completes only when the test calls release.
# in_flight is the number of open requests, most the highest it reached.
use Moose;
use Future;
extends 'Langertha::Engine::Virtual';

has held      => ( is => 'ro', default => sub { [] } );
has in_flight => ( is => 'rw', default => 0 );
has most      => ( is => 'rw', default => 0 );

around chat_f => sub {
  my ( $orig, $self, @args ) = @_;
  my $answer  = $self->$orig(@args);
  my $pending = Future->new;
  $self->in_flight( $self->in_flight + 1 );
  $self->most( $self->in_flight ) if $self->in_flight > $self->most;
  push @{ $self->held }, [ $pending, $answer ];
  return $pending;
};

# hands out the oldest open answer; false when none is open
sub release {
  my ( $self ) = @_;
  my $h = shift @{ $self->held } or return 0;
  $self->in_flight( $self->in_flight - 1 );
  $h->[1]->on_ready( $h->[0] );
  return 1;
}

__PACKAGE__->meta->make_immutable;

1;

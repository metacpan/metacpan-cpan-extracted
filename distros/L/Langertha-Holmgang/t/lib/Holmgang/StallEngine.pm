package Holmgang::StallEngine;
# Test engine for the variant's deadline (k15): a Langertha::Engine::Virtual
# on an IO::Async loop whose requests never come back. The request is seen
# (requests), the answer never arrives; cancelled says the open request was
# cancelled.
use Moose;
extends 'Langertha::Engine::Virtual';

has loop      => ( is => 'ro', required => 1 );
has cancelled => ( is => 'rw', default => 0 );

sub async_loop { $_[0]->loop }

around chat_f => sub {
  my ( $orig, $self, @args ) = @_;
  $self->$orig(@args);
  my $never = $self->loop->new_future;
  $never->on_cancel( sub { $self->cancelled( $self->cancelled + 1 ) } );
  return $never;
};

__PACKAGE__->meta->make_immutable;

1;

package Message::Passing::Fluentd::ConnectionManager;

use Moo;
use Scalar::Util 'weaken';
use Fluent::Logger;
use AnyEvent;
use namespace::autoclean;

with qw/
  Message::Passing::Role::ConnectionManager
  Message::Passing::Role::HasHostnameAndPort
/;

sub _default_port { 24224 }

sub _build_connection {
  my $self = shift;
  weaken($self);
  my $client = Fluent::Logger->new(
    host => $self->hostname || 'localhost',
    port => $self->port || $self->_default_port,
    retry_immediately => 1,
    timeout => $self->timeout,
    buffer_overflow_handler => sub {
      $self->error->consume(shift)
    }
  );
  # Delay calling set_connected till we've finished building the client
  my $i; $i = AnyEvent->idle(cb => sub { undef $i; $self->_set_connected(1) });
  return $client;
}

1;

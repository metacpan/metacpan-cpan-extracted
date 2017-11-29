package Ion::Server;
# ABSTRACT: An Ion TCP service
$Ion::Server::VERSION = '0.02';
use common::sense;

use Moo;
use Carp;
use Coro;
use AnyEvent::Socket qw(tcp_server);
use Coro::Handle qw(unblock);
use Scalar::Util qw(weaken);
use Ion::Conn;

use overload (
  '<>'     => 'accept',
  fallback => 1,
);

with 'Ion::Role::Socket';

has guard  => (is => 'rw', clearer => 1);
has handle => (is => 'rw', clearer => 1);
has queue  => (is => 'rw', clearer => 1, default => sub{ Coro::Channel->new });
has conn   => (is => 'rw', default => sub{ {} });

sub DEMOLISH {
  my $self = shift;
  $self->stop;
}

sub accept {
  my $self = shift;
  $self->queue->get;
}

sub start {
  my ($self, $port, $host) = @_;
  $self->stop if $self->handle;
  $self->queue(Coro::Channel->new) unless $self->queue;

  my $guard = tcp_server $host, $port,
    sub {
      my ($fh, $host, $port) = @_;
      return unless $fh;

      my $conn = Ion::Conn->new(
        host   => $host,
        port   => $port,
        handle => unblock($fh),
      );

      $self->queue->put($conn);
    },
    rouse_cb;

  weaken $self;

  my @sock = rouse_wait;
  $self->handle(unblock(shift @sock));
  $self->host(shift @sock);
  $self->port(shift @sock);
  $self->guard($guard);

  return 1;
}

sub stop {
  my $self = shift;
  return unless $self->guard;

  $self->queue->shutdown;
  $self->clear_queue;

  $self->clear_guard;

  $self->handle->shutdown;
  $self->handle->close;
  $self->clear_handle;

  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ion::Server - An Ion TCP service

=head1 VERSION

version 0.02

=head1 METHODS

=head2 start

Starts the listening socket. Optionally accepts a port number and host
interface on which to listen. If left unspecified, these will be assigned by
the operating system.

=head2 stop

Stops the listener and shuts down the incoming connection queue.

=head2 port

Returns the listening port of a L<started|/start> service.

=head2 host

Returns the host interface of a L<started|/start> service.

=head2 accept

Returns the next incoming connection. This method will block until a new
connection is received.

=head1 OVERLOADED OPERATORS

=head2 <>

Calls L</accept>.

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

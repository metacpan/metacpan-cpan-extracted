package Ion::Conn;
# ABSTRACT: An Ion TCP socket connection
$Ion::Conn::VERSION = '0.08';
use common::sense;

use Class::Slot;
use Carp;
use Coro;
use AnyEvent::Socket qw(tcp_connect);
use Coro::Handle qw(unblock);
use List::Util qw(reduce);

use overload (
  '<>'  => 'readline',
  '&{}' => 'writer',
  '>>'  => 'encodes',
  '>>=' => 'encodes',
  '<<'  => 'decodes',
  '<<=' => 'decodes',
  fallback => 1,
);

slot 'port';
slot 'host';
slot 'guard';
slot 'handle';
slot 'encoders',  def => sub{ [] };
slot 'decoders',  def => sub{ [] };
slot 'connected', def => 0;

sub DESTROY {
  my $self = shift;
  $self->close;
}

sub copy {
  my $self = shift;
  my $dup  = \%$self;
  $dup->close;
  return $dup;
}

sub connect {
  my $self = shift;

  $self->{connected} = 1
    if $self->handle;

  unless ($self->connected) {
    my $host = $self->host || croak 'host is required when handle is not specified';
    my $port = $self->port || croak 'port is required when handle is not specified';
    my $fh;

    my $guard = tcp_connect($host, $port, rouse_cb);
    ($fh, $host, $port) = rouse_wait;

    croak "connection failed: $!" unless $fh;
    $self->{handle}    = unblock $fh;
    $self->{guard}     = $guard;
    $self->{host}      = $host;
    $self->{port}      = $port;
    $self->{connected} = 1;

    return 1;
  }

  return;
}

sub print {
  my ($self, $msg) = @_;
  $self->connect;
  $msg = reduce{ $b->($a) } $msg, @{$self->encoders};
  $self->handle->print($msg, $/);
}

sub readline {
  my $self = shift;
  $self->connect;
  my $line = $self->handle->readline($/) or return;
  chomp $line;
  reduce{ $b->($a) } $line, @{$self->decoders};
}

sub close {
  my $self = shift;
  $self->handle->shutdown if $self->handle;
  $self->handle->close    if $self->handle;
  undef $self->{handle};
  undef $self->{guard};
  $self->{connected} = 0;
  return 1;
}

sub writer {
  my $self = shift;
  sub {
    $self->connect;
    $self->print(shift);
  };
}

sub encodes {
  my ($self, $encoder) = @_;
  push @{$self->encoders}, $encoder;
  return $self;
}

sub decodes {
  my ($self, $decoder) = @_;
  push @{$self->decoders}, $decoder;
  return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ion::Conn - An Ion TCP socket connection

=head1 VERSION

version 0.08

=head1 METHODS

=head2 host

Returns the peer host IP.

=head2 port

Returns the peer port.

=head2 connect

Connects to the remote host unless already connected.

=head2 print

Writes data to the socket. The line is automatically appended with the value of
C<$/>.

=head2 readline

Returns the next line of data received on the socket. This method will cede
control of the thread until a complete line is available. The value will have
already been chomped to remove the line terminator (C<$/>).

=head2 close

Closes the socket. After calling this method, the connection object may not be
reopened.

=head2 encodes

Adds a subroutine to process outgoing messages to this client. Encoder subs are
applied in the order in which they are added.

=head2 decodes

Adds a subroutine to decode incoming messages from this client. Decoder subs
are applied in the order in which they are added.

=head1 OVERLOADED OPERATORS

=head2 <>

Calls L</readline>.

=head2 ${} (e.g. C<$conn->($data)>)

Calls L</print>.

=head2 >>, <<=

Calls L<encodes>.

=head2 <<, <<=

Calls L<decodes>.

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

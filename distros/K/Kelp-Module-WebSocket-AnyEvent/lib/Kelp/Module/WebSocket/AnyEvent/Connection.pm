package Kelp::Module::WebSocket::AnyEvent::Connection;

our $VERSION = '1.04';

use Kelp::Base;
use Carp;
use Scalar::Util qw(weaken blessed);

attr "-id";
attr "-manager";
attr "-connection";
attr "data" => sub { {} };

sub new
{
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	$self->manager->connections->{$self->id} = $self;
	weaken($self->{manager});
	weaken($self->{connection});
	return $self;
}

sub send
{
	my ($self, $message) = @_;
	my $serializer = $self->manager->get_serializer;
	my $is_inst = blessed $message && $message->isa("AnyEvent::WebSocket::Message");

	if ($serializer && (!blessed $message || !$is_inst)) {
		$message = $serializer->encode($message);
	}

	if (ref $message && !$is_inst) {
		carp "invalid data sent to websocket peer, disconnecting";
		$self->connection->close;
		return;
	}

	$self->connection->send($message);
}

sub close
{
	my ($self) = @_;
	delete $self->manager->connections->{$self->id};
	$self->connection->close;
}

1;
__END__

=pod

=head1 NAME

Kelp::Module::WebSocket::AnyEvent::Connection - Thin wrapper around Plack::App::WebSocket::Connection

=head1 SYNOPSIS

	my $id = $connection->id;
	$connection->data->{test} = 'custom data';

	$connection->send('hello there');

=head1 DESCRIPTION

Connection objects of this class fly around in L<Kelp::Module::WebSocket::AnyEvent>. Refer to its documentation for details

=head1 ATTRIBUTES

=head2 id

an autoincremented identifier.

=head2 manager

an instance of L<Kelp::Module::WebSocket::AnyEvent> (weakened).

=head2 connection

an instance of L<Plack::App::WebSocket::Connection> (weakened).

=head2 data

custom data, a hash by default. Can be written by specifying the first argument.

=head1 METHODS

=head2 new

a Kelp-style constructor.

=head2 send

sends data to the websocket peer.

=head2 close

closes the connection gracefully.


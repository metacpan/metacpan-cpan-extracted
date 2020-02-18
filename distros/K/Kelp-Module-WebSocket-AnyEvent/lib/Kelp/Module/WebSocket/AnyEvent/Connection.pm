package Kelp::Module::WebSocket::AnyEvent::Connection;

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

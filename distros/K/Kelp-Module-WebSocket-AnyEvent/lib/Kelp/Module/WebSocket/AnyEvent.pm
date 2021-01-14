package Kelp::Module::WebSocket::AnyEvent;

our $VERSION = '1.02';

use Kelp::Base qw(Kelp::Module::Symbiosis::Base);
use Plack::App::WebSocket;
use Kelp::Module::WebSocket::AnyEvent::Connection;
use Carp qw(croak carp cluck);
use Try::Tiny;

attr "-serializer";
attr "-connections" => sub { {} };

attr "on_open" => sub {
	sub { }
};
attr "on_close" => sub {
	sub { }
};
attr "on_message" => sub {
	sub { }
};
attr "on_error";

# This function is here to work around Twiggy bug that is silencing errors
# Warn them instead, so they can be logged and spotted
sub _trap(&)
{
	my ($block) = @_;
	try {
		$block->();
	}
	catch {
		cluck $_;
		die $_;
	};
}

sub psgi
{
	my ($self) = @_;

	my $conn_max_id = 0;
	my $websocket = Plack::App::WebSocket->new(

		# on_error - optional
		(defined $self->on_error ? (on_error => sub { $self->on_error->(@_) }) : ()),

		# on_establish - mandatory
		on_establish => sub {
			my ($orig_conn, $env) = @_;

			my $conn = Kelp::Module::WebSocket::AnyEvent::Connection->new(
				connection => $orig_conn,
				id => ++$conn_max_id,
				manager => $self
			);
			_trap { $self->on_open->($conn, $env) };

			$conn->connection->on(
				message => sub {
					my ($orig_conn, $message) = @_;
					if (my $s = $self->get_serializer) {
						$message = $s->decode($message);
					}
					_trap { $self->on_message->($conn, $message) };
				},
				finish => sub {
					_trap { $self->on_close->($conn) };
					$conn->close;
					undef $orig_conn;
				},
			);
		}
	);

	return $websocket->to_app;
}

sub add
{
	my ($self, $type, $sub) = @_;

	$type = "on_$type";
	my $setter = $self->can($type);
	croak "unknown websocket event `$type`"
		unless defined $setter;

	return $setter->($self, $sub);
}

sub get_serializer
{
	my ($self) = @_;
	return undef unless defined $self->serializer;

	my $real_serializer_method = $self->app->can($self->serializer);
	croak "Kelp doesn't have $self->serializer serializer"
		unless defined $real_serializer_method;

	return $real_serializer_method->($self->app);
}

sub build
{
	my ($self, %args) = @_;
	$self->SUPER::build(%args);
	$self->{serializer} = $args{serializer} // $self->serializer;

	$self->register(websocket => $self);
}

1;
__END__

=head1 NAME

Kelp::Module::WebSocket::AnyEvent - AnyEvent websocket server integration with Kelp

=head1 SYNOPSIS

	# in config
	modules => [qw(Symbiosis WebSocket::AnyEvent)],
	modules_init => {
		"WebSocket::AnyEvent" => {
			serializer => "json",
		},
	},

	# in application's build method
	my $ws = $self->websocket;
	$ws->add(message => sub {
		my ($conn, $msg) = @_;
		$conn->send({received => $msg});
	});
	$self->symbiosis->mount("/ws" => $ws);

	# in psgi script
	$app = MyApp->new;
	$app->run_all;


=head1 DESCRIPTION

This is a module that integrates a websocket instance into Kelp using L<Kelp::Module::Symbiosis>. To run it, a non-blocking Plack server based on AnyEvent is required, like L<Twiggy>. All this module does is wrap L<Plack::App::WebSocket> instance in Kelp's module, introduce a method to get this instance in Kelp and integrate it into running alongside Kelp using Symbiosis. An instance of this class will be available in Kelp under the I<websocket> method.

=head1 METHODS

=head2 connections

	sig: connections($self)

Returns a hashref containing all available L<Kelp::Module::WebSocket::AnyEvent::Connection> instances (open connections) keyed by their unique id. An id is autoincremented from 1 and guaranteed not to change and not to be replaced by a different connection unless the server restarts.

=head2 middleware

	sig: middleware($self)

Returns an arrayref of all middlewares in format: C<[ middleware_class, [ middleware_config ] ]>.

=head2 psgi

	sig: psgi($self)

Returns a ran instance of L<Plack::App::WebSocket>.

=head2 run

	sig: run($self)

Same as psgi, but wraps the instance in all wanted middlewares.

=head2 add

	sig: add($self, $event, $handler)

Registers a $handler (coderef) for websocket $event (string). Handler will be passed an instance of L<Kelp::Module::WebSocket::AnyEvent::Connection> and an incoming message. $event can be either one of: I<open close message error>. You can only specify one handler for each event type.

=head1 SEE ALSO

=over 2

=item * L<Dancer2::Plugin::WebSocket>, same integration for Dancer2 framework this module was inspired by

=item * L<Kelp>, the framework

=item * L<Twiggy>, a server capable of running this websocket

=back

=head1 AUTHOR

Bartosz Jarzyna, E<lt>brtastic.dev@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut

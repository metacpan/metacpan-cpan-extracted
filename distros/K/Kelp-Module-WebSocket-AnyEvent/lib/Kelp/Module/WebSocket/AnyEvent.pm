package Kelp::Module::WebSocket::AnyEvent;

our $VERSION = '1.04';

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
attr "on_malformed_message" => sub {
	sub { die pop }
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

sub name { 'websocket' }

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
					my $err;

					if (my $s = $self->get_serializer) {
						try {
							$message = $s->decode($message);
						}
						catch {
							$err = $_ || 'unknown error';
						};
					}

					_trap {
						if ($err) {
							$self->on_malformed_message->($conn, $message, $err);
						}
						else {
							$self->on_message->($conn, $message);
						}
					};
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

	croak "websocket handler for $type is not a code reference"
		unless ref $sub eq 'CODE';

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

=pod

=head1 NAME

Kelp::Module::WebSocket::AnyEvent - AnyEvent websocket server integration with Kelp

=head1 SYNOPSIS

	# in config

	modules => [qw(Symbiosis WebSocket::AnyEvent)],
	modules_init => {
		"WebSocket::AnyEvent" => {
			mount => '/ws',
			serializer => "json",
		},
	},


	# in application's build method

	my $ws = $self->websocket;
	$ws->add(message => sub {
		my ($conn, $msg) = @_;
		$conn->send({received => $msg});
	});

	# can also be mounted like this, if not specified in config
	$self->symbiosis->mount("/ws" => $ws);         # by module object
	$self->symbiosis->mount("/ws" => 'websocket'); # by name


	# in psgi script

	$app = MyApp->new;
	$app->run_all;


=head1 DESCRIPTION

This is a module that integrates a websocket instance into Kelp using L<Kelp::Module::Symbiosis>. To run it, a non-blocking Plack server based on AnyEvent is required, like L<Twiggy>. All this module does is wrap L<Plack::App::WebSocket> instance in Kelp's module, introduce a method to get this instance in Kelp and integrate it into running alongside Kelp using Symbiosis. An instance of this class will be available in Kelp under the I<websocket> method.

=head1 METHODS INTRODUCED TO KELP

=head2 websocket

Returns the instance of this class (Kelp::Module::WebSocket::AnyEvent).

=head1 METHODS

=head2 name

	sig: name($self)

Reimplemented from L<Kelp::Module::Symbiosis::Base>. Returns a name of a module that can be used in C<< $symbiosis->loaded >> hash or when mounting by name. The return value is constant string I<'websocket'>.

Requires Symbiosis version I<1.10> for name mounting to function.

=head2 connections

	sig: connections($self)

Returns a hashref containing all available L<Kelp::Module::WebSocket::AnyEvent::Connection> instances (open connections) keyed by their unique id. An id is autoincremented from 1 and guaranteed not to change and not to be replaced by a different connection unless the server restarts.

A connection holds some additional data that can be used to hold custom data associated with that connection:

	# set / get data fields (it's an empty hash ref by default)
	$connection->data->{internal_id} = $internal_id;

	# get the entire hash reference
	$hash_ref = $connection->data;

	# replace the hash reference with something else
	$connection->data($something_else);

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

=head1 EVENTS

All event handlers must be code references.

=head2 open

	open => sub ($new_connection, $env) { ... }

B<Optional>. Called when a new connection opens. A good place to set up its variables.

=head2 message

	message => sub ($connection, $message) { ... }

B<Optional>. This is where you handle all the incoming websocket messages. If a serializer is specified, C<$message> will already be unserialized.

=head2 malformed_message

	message => sub ($connection, $message, $error) { ... }

B<Optional>. This is where you handle the incoming websocket messages which could not be unserialized by a serializer. By default, an exception will be re-thrown, and effectively the connection will be closed.

If Kelp JSON module is initialized with I<'allow_nonref'> flag then this event will never occur.

C<$error> will not be likely be fit for end user message, as it will contain file names and line numbers.

=head2 close

	close => sub ($connection) { ... }

B<Optional>. Called when the connection is closing.

=head2 error

	error => $psgi_app

B<Optional>. The code reference should be a psgi application. It will be called if an error occurs and the websocket connection have to be closed.

=head1 CONFIGURATION

=head2 middleware, middleware_init

See L<Kelp::Module::Symbiosis::Base/middleware, middleware_init>.

=head2 mount

See L<Kelp::Module::Symbiosis::Base/mount>.

=head2 serializer

Contains the name of the method that will be called to obtain an instance of serializer. Kelp instance must have that method registered. It must be able to C<< ->encode >> and C<< ->decode >>. Should also throw exception on error.

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

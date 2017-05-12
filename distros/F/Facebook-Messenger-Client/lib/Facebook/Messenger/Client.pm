package Facebook::Messenger::Client;

use Moose;

our $VERSION = '1.0';

use Mojo::URL;
use Mojo::UserAgent;

use Facebook::Messenger::Client::Text;

my $GRAPH_URL = 'https://graph.facebook.com/v2.6/';

has 'access_token' => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	default => sub { $ENV{GRAPH_ACCESS_TOKEN} }
);

has 'ua' => (
	is => 'ro',
	isa => 'Mojo::UserAgent',
	lazy => 1,
	default => sub { Mojo::UserAgent->new() }
);

sub send {
	my ( $self, $recipient, $message ) = @_;

	die( 'No token defined!' )
		unless( $self->access_token() );

	# NOTE: Please be careful when changing the value to the path
	# attribute. Consult the documentation for Mojo::Path before doing that.
	my $url = Mojo::URL->new( $GRAPH_URL )
		->path( 'me/messages' )
		->query( access_token => $self->access_token() );

	my $payload = {
		recipient => { id => $recipient },
		message => $message->pack(),
	};

	my $tx = $self->ua()
		->post( $url, json => $payload );

	my $response = $tx->success();
	unless( $response ) {
		my $error = $tx->error();
		die( sprintf( 'Error: %s', $error->{message} ) )
	}

	return $response->json();
}

sub send_text {
	my ( $self, $recipient, $text ) = @_;

	my $message = Facebook::Messenger::Client::Text->new(
		{ text => $text }
	);

	return $self->send( $recipient, $message );
}

sub get_user {
	my ( $self, $id ) = @_;

	my $url = Mojo::URL->new( $GRAPH_URL )
		->path( $id )
		->query(
			access_token => $self->access_token(),
			fields => 'first_name,last_name,locale,timezone,gender'
		);

	my $tx = $self->ua()->get( $url );

	my $response = $tx->success();
	unless( $response ) {
		my $error = $tx->error();
		die( sprintf( 'Error: %s', $error->{message} ) )
	}

	return $response->json();
}

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=head1 NAME

Facebook::Messenger::Client - Messenger Send API

=head1 SYNOPSIS

	use Facebook::Messenger::Client;

	my $client = Facebook::Messenger::Client->new(
		access_token => 'blabla'
	);

	$client->send_text( 0123456789, 'Some message...' );

	my $hashref = $client->get_user( 01234567890 );

=head1 DESCRIPTION

If you want to build a Facebook chatbot you will need to use the Send API to send
back messages to a recipient. This is a basic implementation of the Messenger Send API
that allows (for the moment) to send text messages.

=head1 ATTRIBUTES

=head2 access_token

The access token provided by Facebook. This can also be set via the B<GRAPH_ACCESS_TOKEN>
environment variable.

=head1 METHODS

=head2 send

	my $hashref = $client->send( $recipient_id, $model );

Generic send function. This will that a L<Facebook::Messenger::Client::Model> instance
and send it to the server.

=head2 send_text

	my $hashref = $client->send_text( $recipient_id, 'The message goes here ...' );

=head2 get_user

	$hashref = $client->get_user( $user_id );

=head1 AUTHOR

Tudor Marghidanu <tudor@marghidanu.com>

=head1 SEE ALSO

=over 4

=item *

L<Moose>

=item *

L<Mojolicious>

=back

=head1 LICENSE

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

=cut

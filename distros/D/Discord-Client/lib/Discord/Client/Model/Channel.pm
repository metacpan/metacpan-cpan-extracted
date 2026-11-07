package Discord::Client::Model::Channel;

use v5.26;
use strict;
use warnings;
use parent 'Discord::Client::Model';

our $VERSION = '0.002';
sub name { $_[0]->get('name') }
sub mention { '<#' . $_[0]->id . '>' }

sub send {
    my ( $self, $body ) = @_;

    # Use the known channel ID directly; no preliminary channel fetch is necessary.
    my $request = $self->_call( create_message => $self->id, $body );
    return $self->_model_future( message => $request );
}

sub fetch_message {
    my ( $self, $message_id ) = @_;

    # Turn the fetched resource into a new snapshot sharing this REST client.
    my $request = $self->_call( get_message => $self->id, $message_id );
    return $self->_model_future( message => $request );
}

sub typing {
    my ($self) = @_;
    return $self->_call( trigger_typing => $self->id );
}

sub refresh {
    my ($self) = @_;

    # Return a replacement snapshot without changing references held by other callers.
    my $request = $self->_call( get_channel => $self->id );
    return $self->_model_future( channel => $request );
}

1;

__END__

=encoding UTF-8

=head1 NAME

Discord::Client::Model::Channel - channel snapshots and REST operations

=head1 SYNOPSIS

    # Use an ID-only channel reference without fetching details first.
    my $channel = $bot->model(channel => {id => $channel_id});
    my $sent = $channel->send('Hello');

=head1 DESCRIPTION

A channel snapshot. Inherits construction and data access from
L<Discord::Client::Model>. REST operations use its associated REST client.

=head1 METHODS

=head2 name

Returns the name or undef when absent.

=head2 mention

Returns the channel mention string.

=head2 send

C<send(text_or_hash)> returns a Future containing a new
L<Discord::Client::Model::Message> snapshot.

=head2 fetch_message

C<fetch_message(message_id)> returns a Future containing a Message snapshot.

=head2 typing

Returns a Future resolving to undef after triggering the typing indicator.

=head2 refresh

Fetches current channel data and returns a Future containing a new Channel
snapshot. The existing snapshot does not change.

=head1 LICENSE

Apache License 2.0.

=cut

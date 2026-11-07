package Discord::Client::Model::Message;

use v5.26;
use strict;
use warnings;
use parent 'Discord::Client::Model';

our $VERSION = '0.002';
sub channel_id { $_[0]->get('channel_id') }
sub content { $_[0]->get('content') }

sub is_from_bot {
    my ($self) = @_;

    # Missing author metadata does not imply a bot; callers decide whether to ignore it.
    my $author = $self->get('author');
    return ref($author) eq 'HASH' && $author->{bot} ? 1 : 0;
}

sub author {
    my ($self) = @_;

    # Wrap the embedded user without another request or a cache dependency.
    my $author = $self->get('author');
    return undef unless ref($author) eq 'HASH';
    return Discord::Client::Model->wrap( user => $author, rest => $self->rest );
}

sub channel {
    my ($self) = @_;

    # A channel reference permits sending without a cache or a preliminary fetch.
    return undef unless defined $self->channel_id;
    return Discord::Client::Model->wrap(
        channel => { id => $self->channel_id },
        rest => $self->rest,
    );
}

sub edit {
    my ( $self, $body ) = @_;

    # Edits return a new snapshot; this message remains the originally observed version.
    my $request = $self->_call( edit_message => $self->channel_id, $self->id, $body );
    return $self->_model_future( message => $request );
}

sub delete {
    my ($self) = @_;
    return $self->_call( delete_message => $self->channel_id, $self->id );
}

sub reply {
    my ( $self, $body ) = @_;

    # Copy caller data before adding the source message reference.
    $body = { content => "$body" } if defined($body) && !ref($body);
    if ( ref($body) eq 'HASH' ) {
        $body = { %$body, message_reference => { message_id => $self->id, channel_id => $self->channel_id }, };
    }
    my $request = $self->_call( create_message => $self->channel_id, $body );
    return $self->_model_future( message => $request );
}

1;

__END__

=encoding UTF-8

=head1 NAME

Discord::Client::Model::Message - message snapshots and REST operations

=head1 SYNOPSIS

    # Ignore bots and return the reply Future from a message handler.
    $bot->on_message(sub {
        my ($message, $bot) = @_;
        return if $message->is_from_bot;
        return unless $message->content eq '!ping';
        return $message->reply('Pong!');
    });

=head1 DESCRIPTION

A message snapshot with REST operations. Inherits construction and data access
from L<Discord::Client::Model>. Set message intents explicitly; enable Message
Content in the Developer Portal for the example. Raw events remain available
through L<Discord::Client/on>.

=head1 METHODS

=head2 channel_id

Returns the channel ID or undef.

=head2 content

Returns the message content or undef if absent from the payload.

=head2 is_from_bot

Returns a boolean from the author's C<bot> flag; false when absent.

=head2 author

Returns a L<Discord::Client::Model::User> snapshot or undef. Performs no request.

=head2 channel

Returns an ID-only L<Discord::Client::Model::Channel> reference or undef.
It shares the Message's REST client and performs no request. Use its C<refresh>
to fetch channel details.

=head2 edit

C<edit(text_or_hash)> returns a Future containing a new Message snapshot.

=head2 delete

Returns a Future resolving to undef after deletion.

=head2 reply

C<reply(text_or_hash)> adds a message reference and returns a Future containing
the new Message snapshot. Set C<allowed_mentions> to control pings.

=head1 LICENSE

Apache License 2.0.

=cut

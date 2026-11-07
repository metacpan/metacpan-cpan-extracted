package Discord::Client::Model::Guild;

use v5.26;
use strict;
use warnings;
use parent 'Discord::Client::Model';

our $VERSION = '0.002';
sub name { $_[0]->get('name') }

sub refresh {
    my ( $self, %query ) = @_;

    # Forward query options and return a fresh guild snapshot.
    my $request = $self->_call( get_guild => $self->id, %query );
    return $self->_model_future( guild => $request );
}

sub fetch_member {
    my ( $self, $user_id ) = @_;

    # Member data remains raw; the SDK does not maintain a member cache.
    return $self->_call( get_guild_member => $self->id, $user_id );
}

sub channels {
    my ($self) = @_;

    # Fetch the collection once and wrap each returned channel without more I/O.
    my $request = $self->_call( get_guild_channels => $self->id );
    return $request->then(
        sub {
            my ($data) = @_;

            # Reject an invalid collection or resource as one protocol failure.
            my $models = eval {
                die 'invalid list' unless ref($data) eq 'ARRAY';
                [ map { Discord::Client::Model->wrap( channel => $_, rest => $self->{rest} ) } @$data ];
            };
            return Future->done($models) if $models;
            return $self->_failed( 'Discord returned invalid channel data', 'protocol' );
        }
    );
}

1;

__END__

=encoding UTF-8

=head1 NAME

Discord::Client::Model::Guild - guild snapshots and REST operations

=head1 SYNOPSIS

    # Fetch this server's channels as resource snapshots.
    my $channels = $guild->channels;

=head1 DESCRIPTION

A guild snapshot. Inherits construction and data access from
L<Discord::Client::Model>. Member responses remain raw hashrefs;
no automatic member scan occurs.

=head1 METHODS

=head2 name

Returns the guild name or undef when absent.

=head2 refresh

C<refresh(query_pairs)> fetches current guild data and returns a Future containing
a new Guild snapshot. Query pairs are optional; the existing snapshot does not change.

=head2 channels

Returns a Future containing an arrayref of L<Discord::Client::Model::Channel>
snapshots.

=head2 fetch_member

C<fetch_member(user_id)> returns a Future containing a member hashref.

=head1 LICENSE

Apache License 2.0.

=cut

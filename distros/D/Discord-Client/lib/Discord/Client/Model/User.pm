package Discord::Client::Model::User;

use v5.26;
use strict;
use warnings;
use parent 'Discord::Client::Model';

our $VERSION = '0.002';
sub username { $_[0]->get('username') }
sub mention { '<@' . $_[0]->id . '>' }

sub create_dm {
    my ($self) = @_;

    # Open the DM explicitly and share REST with the returned channel snapshot.
    my $request = $self->_call( create_dm => $self->id );
    return $self->_model_future( channel => $request );
}

sub refresh {
    my ($self) = @_;

    # Fetch a replacement user snapshot without mutating this one.
    my $request = $self->_call( get_user => $self->id );
    return $self->_model_future( user => $request );
}

1;

__END__

=encoding UTF-8

=head1 NAME

Discord::Client::Model::User - user snapshots and REST operations

=head1 SYNOPSIS

    # Open a DM and send through the returned Channel snapshot.
    my $work = $user->create_dm->then(sub {
        return $_[0]->send('Hello');
    });

=head1 DESCRIPTION

A user snapshot. Inherits construction and data access from
L<Discord::Client::Model>.

=head1 METHODS

=head2 username

Returns the username or undef when absent.

=head2 mention

Returns the user mention string.

=head2 create_dm

Returns a Future containing a L<Discord::Client::Model::Channel> snapshot.

=head2 refresh

Fetches current user data and returns a Future containing a new User snapshot.
The existing snapshot does not change.

=head1 LICENSE

Apache License 2.0.

=cut

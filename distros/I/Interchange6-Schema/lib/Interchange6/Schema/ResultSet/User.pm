use utf8;

package Interchange6::Schema::ResultSet::User;

=head1 NAME

Interchange6::Schema::ResultSet::User

=cut

=head1 SYNOPSIS

Provides extra accessor methods for L<Interchange6::Schema::Result::User>

=cut

use strict;
use warnings;
use mro 'c3';

use parent 'Interchange6::Schema::ResultSet';

=head1 METHODS

=head2 find

Override L<DBIx::Class::ResultSet/find> for lookup of
L<Interchange6::Schema::Result::User/username> so that leading/trailing spaces
are stripped from username and it is also lower-cased.

=cut

sub find {
    my $self = shift;

    if ( ref( $_[0] ) eq 'HASH' && defined $_[0]->{username} ) {

        # looking for a username
        $_[0]->{username} = lc( $_[0]->{username} );
        $_[0]->{username} =~ s/(^\s+|\s+$)//g;
    }

    $self->next::method(@_);
}

=head2 find_user_with_reset_token( $token );

Where $token is the combined <Interchange6::Schema::Result::User/reset_token>
and <Interchange6::Schema::Result::User/reset_token_checksum> as would be
returned by <Interchange6::Schema::Result::User/reset_token_generate>.

Returns an <Interchange6::Schema::Result::User> object if $token is found and
is valid. On failure returns undef.

=cut

sub find_user_with_reset_token {
    my ( $self, $arg ) = @_;

    $self->throw_exception("Bad argument to find_user_with_reset_token")
      unless $arg;

    my ( $token, $checksum ) = split(/_/, $arg);

    $self->throw_exception("Bad argument to find_user_with_reset_token")
      unless ( $token && $checksum );

    my $users = $self->search({reset_token => $token});

    while ( my $user = $users->next ) {
        return $user if $user->reset_token_verify( $arg );
    }

    return undef;
}

1;

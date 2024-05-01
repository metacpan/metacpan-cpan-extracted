package Lemonldap::NG::Portal::Main::UserDB;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants;

our $VERSION = '2.19.0';

extends 'Lemonldap::NG::Portal::Main::Plugin';

# This method is meant to be used in cases where UserDB/Auth imports $groups
# from another system (SAML, etc)
sub setGroups {
    my ( $self, $req ) = @_;

    my $groups  = $req->sessionInfo->{groups};
    my $hGroups = $req->sessionInfo->{hGroups};

    # Populate $hGroups from $groups
    if ( $groups and not( $hGroups and keys %$hGroups ) ) {
        for my $group ( split( $self->conf->{multiValuesSeparator}, $groups ) )
        {
            $req->sessionInfo->{hGroups}->{$group} = { name => $group };
        }
    }
    # Populate $groups from $hGroups
    elsif ( ( $hGroups and keys %$hGroups ) and not $groups ) {
        $req->sessionInfo->{groups} =
          join( $self->conf->{multiValuesSeparator}, keys %$hGroups );
    }

    return PE_OK;
}

1;

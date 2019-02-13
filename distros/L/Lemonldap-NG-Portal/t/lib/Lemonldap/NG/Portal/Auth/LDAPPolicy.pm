package Lemonldap::NG::Portal::Auth::LDAPPolicy;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants
  qw(PE_OK PE_LDAPCONNECTFAILED PE_PP_PASSWORD_TOO_SHORT PE_PP_PASSWORD_EXPIRED);

our $VERSION = '2.0.2';

extends qw(Lemonldap::NG::Portal::Auth::LDAP);

# RUNNING METHODS

sub authenticate {
    my ( $self, $req ) = @_;
    unless ( $self->ldap ) {
        return PE_LDAPCONNECTFAILED;
    }

    # Set the dn unless done before
    unless ( $req->data->{dn} ) {
        if ( my $tmp = $self->getUser($req) ) {
            $self->setSecurity($req);
            return $tmp;
        }
    }

    if (    $req->data->{password}
        and $req->data->{password} eq ( $ENV{LDAPPWD} || 'dwho' ) )
    {
        $req->data->{noerror} = 1;
        $self->setSecurity($req);
        return PE_PP_PASSWORD_EXPIRED;
    }
    if ( $req->data->{newpassword} and $req->data->{newpassword} eq 'newp' ) {
        $req->data->{noerror} = 1;
        $self->setSecurity($req);
        return PE_PP_PASSWORD_TOO_SHORT;
    }
    return $self->SUPER::authenticate($req);
}

1;

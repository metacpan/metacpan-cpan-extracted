package Lemonldap::NG::Portal::Auth::LDAP;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants
  qw(PE_OK PE_LDAPCONNECTFAILED PE_PP_CHANGE_AFTER_RESET PE_PP_PASSWORD_EXPIRED);

our $VERSION = '2.0.0';

# Inheritance: UserDB::LDAP provides all needed ldap functions
extends
  qw(Lemonldap::NG::Portal::Auth::_WebForm Lemonldap::NG::Portal::Lib::LDAP);

sub init {
    my ($self) = @_;
    return (  $self->Lemonldap::NG::Portal::Auth::_WebForm::init
          and $self->Lemonldap::NG::Portal::Lib::LDAP::init );
}

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

    my $res =
      $self->userBind( $req, $req->data->{dn},
        password => $req->data->{password} );

    # Remember password if password reset needed
    $req->data->{oldpassword} = $self->{password}
      if (
        $res == PE_PP_CHANGE_AFTER_RESET
        or (    $res == PE_PP_PASSWORD_EXPIRED
            and $self->conf->{ldapAllowResetExpiredPassword} )
      );

    return $res;

}

sub authLogout {
    PE_OK;
}

# Test LDAP connection before trying to bind
sub userBind {
    my $self = shift;
    unless ($self->ldap
        and $self->ldap->root_dse( attrs => ['supportedLDAPVersion'] ) )
    {
        $self->ldap( $self->newLdap );
    }
    return $self->ldap ? $self->ldap->userBind(@_) : undef;
}

1;

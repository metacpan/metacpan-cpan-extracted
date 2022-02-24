package Lemonldap::NG::Portal::Auth::LDAP;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_DONE
  PE_ERROR
  PE_LDAPCONNECTFAILED
  PE_PP_ACCOUNT_LOCKED
  PE_PP_PASSWORD_EXPIRED
  PE_PP_CHANGE_AFTER_RESET
);

our $VERSION = '2.0.14';

# Inheritance: UserDB::LDAP provides all needed ldap functions
extends qw(
  Lemonldap::NG::Portal::Lib::LDAP
  Lemonldap::NG::Portal::Auth::_WebForm
);

sub init {
    my ($self) = @_;
    return (  $self->Lemonldap::NG::Portal::Auth::_WebForm::init
          and $self->Lemonldap::NG::Portal::Lib::LDAP::init );
}

has authnLevel => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{ldapAuthnLevel};
    }
);

# RUNNING METHODS

sub authenticate {
    my ( $self, $req ) = @_;

    # Set the dn unless done before
    unless ( $req->data->{dn} ) {
        if ( my $tmp = $self->getUser($req) ) {
            eval { $self->setSecurity($req) };
            $self->logger->warn($@) if ($@);
            return $tmp;
        }
    }

    unless ( $req->data->{password} ) {
        $self->p->{user} = $req->userData->{_dn} = $req->data->{dn};
        unless ( $self->p->{_passwordDB} ) {
            $self->logger->error('No password database configured, aborting');
            return PE_ERROR;
        }
        my $res = $self->p->{_passwordDB}->_modifyPassword( $req, 1 );

        # Refresh entry
        if ( $self->p->{_userDB}->getUser($req) != PE_OK ) {
            $self->logger->error(
                "Unable to refresh entry for " . $self->p->{user} );
        }

        $req->data->{noerror} = 1;
        $self->setSecurity($req);

        # Security: never create session here
        return $res || PE_DONE;
    }

    $self->validateLdap;

    unless ( $self->ldap ) {
        return PE_LDAPCONNECTFAILED;
    }

    my $res =
      $self->ldap->userBind( $req, $req->data->{dn},
        password => $req->data->{password} );
    $self->setSecurity($req) if ( $res > PE_OK );

    # Remember password if password reset needed
    if (
        $res == PE_PP_CHANGE_AFTER_RESET
        or (    $res == PE_PP_PASSWORD_EXPIRED
            and $self->conf->{ldapAllowResetExpiredPassword} )
      )
    {
        $req->data->{oldpassword} = $req->data->{password};    # Fix 2377
        $req->data->{noerror}     = 1;
        $self->setSecurity($req);
    }

    return $res;

}

sub authLogout {
    return PE_OK;
}

# Define which error codes will stop Combination process
# @param res error code
# @return result 1 if stop is needed
sub stop {
    my ( $self, $res ) = @_;

    return 1
      if ( $res == PE_PP_PASSWORD_EXPIRED
        or $res == PE_PP_ACCOUNT_LOCKED
        or $res == PE_PP_CHANGE_AFTER_RESET );
    return 0;
}

1;

package Lemonldap::NG::Portal::Auth::LDAP;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_DONE
  PE_ERROR
  PE_LDAPCONNECTFAILED
  PE_PP_CHANGE_AFTER_RESET
  PE_PP_PASSWORD_EXPIRED
);

our $VERSION = '2.0.5';

# Inheritance: UserDB::LDAP provides all needed ldap functions
extends
  qw(Lemonldap::NG::Portal::Auth::_WebForm Lemonldap::NG::Portal::Lib::LDAP);

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
    unless ( $self->ldap ) {
        return PE_LDAPCONNECTFAILED;
    }

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
    my $res =
      $self->userBind( $req, $req->data->{dn},
        password => $req->data->{password} );
    $self->setSecurity($req) if ( $res > PE_OK );

    # Remember password if password reset needed
    if (
        $res == PE_PP_CHANGE_AFTER_RESET
        or (    $res == PE_PP_PASSWORD_EXPIRED
            and $self->conf->{ldapAllowResetExpiredPassword} )
      )
    {
        $req->data->{oldpassword} = $self->{password};
        $req->data->{noerror}     = 1;
        $self->setSecurity($req);
    }

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

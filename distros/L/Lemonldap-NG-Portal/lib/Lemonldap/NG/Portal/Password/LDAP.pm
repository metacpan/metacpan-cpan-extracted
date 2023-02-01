package Lemonldap::NG::Portal::Password::LDAP;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_ERROR
  PE_LDAPERROR
  PE_PASSWORD_OK
  PE_LDAPCONNECTFAILED
);

extends qw(
  Lemonldap::NG::Portal::Lib::LDAP
  Lemonldap::NG::Portal::Password::Base
);

our $VERSION = '2.0.16';

sub init {
    my ($self) = @_;
    return (  $self->Lemonldap::NG::Portal::Password::Base::init
          and $self->Lemonldap::NG::Portal::Lib::LDAP::init );
}

# Confirmation is done by Lib::Net::LDAP::userModifyPassword
sub confirm {
    return 1;
}

sub modifyPassword {
    my ( $self, $req, $pwd, %args ) = @_;
    my ( $dn, $requireOldPassword );

    # If the password change is done in a different backend,
    # we need to reload the correct DN
    $self->getUser( $req, useMail => $args{useMail} )
      if $self->conf->{ldapGetUserBeforePasswordChange};

    if ( $req->data->{dn} ) {
        $dn = $req->data->{dn};
        $requireOldPassword =
          $self->requireOldPwdRule->( $req, $req->userData );
        $self->logger->debug("Get DN from request data: $dn");
    }
    else {
        $dn = $req->sessionInfo->{_dn};
        $requireOldPassword =
          $self->requireOldPwdRule->( $req, $req->sessionInfo );
        $self->logger->debug("Get DN from session data: $dn");
    }
    unless ($dn) {
        $self->logger->error('"dn" is not set, aborting password modification');
        return PE_ERROR;
    }
    $requireOldPassword = 0 if $args{passwordReset};

    # Ensure connection is valid
    $self->bind;
    return PE_LDAPCONNECTFAILED unless $self->ldap;

    # Call the modify password method
    my $code =
      $self->ldap->userModifyPassword( $dn, $pwd, $req->data->{oldpassword},
        0, $requireOldPassword );
    return $code unless ( $code == PE_PASSWORD_OK );

    # If password policy and force reset, set reset flag
    if (    $self->conf->{ldapPpolicyControl}
        and $req->data->{forceReset}
        and $self->conf->{ldapUsePasswordResetAttribute} )
    {
        my $result = $self->ldap->modify(
            $dn,
            replace => {
                $self->conf->{ldapPasswordResetAttribute} =>
                  $self->conf->{ldapPasswordResetAttributeValue}
            }
        );

        unless ( $result->code == 0 ) {
            $self->logger->error( "LDAP modify "
                  . $self->conf->{ldapPasswordResetAttribute}
                  . " error "
                  . $result->code . ": "
                  . $result->error );
            return PE_LDAPERROR;
        }

        $self->logger->debug( $self->conf->{ldapPasswordResetAttribute}
              . " set to "
              . $self->conf->{ldapPasswordResetAttributeValue} );
    }

    return $code;
}

1;

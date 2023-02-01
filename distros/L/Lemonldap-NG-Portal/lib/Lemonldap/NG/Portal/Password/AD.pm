package Lemonldap::NG::Portal::Password::AD;

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

    # If the password change is done in a different backend,
    # we need to reload the correct DN
    $self->getUser( $req, useMail => $args{useMail} )
      if $self->conf->{ldapGetUserBeforePasswordChange};

    my $dn = $req->data->{dn} || $req->sessionInfo->{_dn};
    unless ($dn) {
        $self->logger->error('"dn" is not set, abort password modification');
        return PE_ERROR;
    }

    my $requireOldPassword = (
          $req->userData
        ? $self->requireOldPwdRule->( $req, $req->userData )
        : $self->requireOldPwdRule->( $req, $req->sessionInfo )
    );
    $requireOldPassword = 0 if $args{passwordReset};

    # Ensure connection is valid
    $self->bind;
    return PE_LDAPCONNECTFAILED unless $self->ldap;

    # Call the modify password method
    my $code =
      $self->ldap->userModifyPassword( $dn, $pwd, $req->data->{oldpassword},
        1, $requireOldPassword );
    return $code unless ( $code == PE_PASSWORD_OK );

    # If force reset, set reset flag
    if ( $req->data->{forceReset} ) {
        my $result = $self->ldap->modify(
            $dn,
            replace => {
                'pwdLastSet' => '0'
            }
        );

        unless ( $result->code == 0 ) {
            $self->logger->error( "LDAP modify pwdLastSet error "
                  . $result->code . ": "
                  . $result->error );
            return PE_LDAPERROR;
        }

        $self->logger->debug("pwdLastSet set to 0");
    }

    return $code;
}

1;

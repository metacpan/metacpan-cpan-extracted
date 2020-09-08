package Lemonldap::NG::Portal::Password::LDAP;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_PASSWORD_OK
  PE_LDAPERROR
  PE_LDAPCONNECTFAILED
  PE_ERROR
);

extends 'Lemonldap::NG::Portal::Lib::LDAP',
  'Lemonldap::NG::Portal::Password::Base';

our $VERSION = '2.0.2';

sub init {
    my ($self) = @_;
    $self->ldap
      and $self->filter
      and $self->Lemonldap::NG::Portal::Password::Base::init;
}

# Confirmation is done by Lib::Net::LDAP::userModifyPassword
sub confirm {
    return 1;
}

sub modifyPassword {
    my ( $self, $req, $pwd ) = @_;
    my $dn;
    my $requireOldPassword;
    my $rule = $self->p->HANDLER->buildSub(
        $self->p->HANDLER->substitute(
            $self->conf->{portalRequireOldPassword}
        )
    );
    unless ($rule) {
        my $error = $self->p->HANDLER->tsv->{jail}->error || '???';
    }
    if ( $req->data->{dn} ) {
        $dn                 = $req->data->{dn};
        $requireOldPassword = $rule->( $req, $req->userData );
        $self->logger->debug("Get DN from request data: $dn");
    }
    else {
        $dn                 = $req->sessionInfo->{_dn};
        $requireOldPassword = $rule->( $req, $req->sessionInfo );
        $self->logger->debug("Get DN from session data: $dn");
    }
    unless ($dn) {
        $self->logger->error('"dn" is not set, aborting password modification');
        return PE_ERROR;
    }

    # Ensure connection is valid
    $self->bind;
    return PE_LDAPCONNECTFAILED unless $self->ldap;

    # Call the modify password method
    my $code =
      $self->ldap->userModifyPassword( $dn, $pwd, $req->data->{oldpassword},
        0, $requireOldPassword );

    unless ( $code == PE_PASSWORD_OK ) {
        return $code;
    }

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

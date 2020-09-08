package Lemonldap::NG::Portal::Password::AD;

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

our $VERSION = '2.0.9';

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
    my $dn = $req->data->{dn} || $req->sessionInfo->{_dn};
    unless ($dn) {
        $self->logger->error('"dn" is not set, aborting password modification');
        return PE_ERROR;
    }
    my $rule = $self->p->HANDLER->buildSub(
        $self->p->HANDLER->substitute(
            $self->conf->{portalRequireOldPassword}
        )
    );
    unless ($rule) {
        my $error = $self->p->HANDLER->tsv->{jail}->error || '???';
    }
    my $requireOldPassword = (
          $req->userData
        ? $rule->( $req, $req->userData )
        : $rule->( $req, $req->sessionInfo )
    );

    # Ensure connection is valid
    $self->bind;
    return PE_LDAPCONNECTFAILED unless $self->ldap;

    # Call the modify password method
    my $code =
      $self->ldap->userModifyPassword( $dn, $pwd, $req->data->{oldpassword},
        1, $requireOldPassword );

    unless ( $code == PE_PASSWORD_OK ) {
        return $code;
    }

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

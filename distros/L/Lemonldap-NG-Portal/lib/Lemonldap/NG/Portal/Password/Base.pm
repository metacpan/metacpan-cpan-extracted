# Base package for Password modules
package Lemonldap::NG::Portal::Password::Base;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_BADOLDPASSWORD
  PE_PASSWORD_OK
  PE_PASSWORD_MISMATCH
  PE_PP_MUST_SUPPLY_OLD_PASSWORD
  PE_PP_PASSWORD_TOO_SHORT
  PE_PP_INSUFFICIENT_PASSWORD_QUALITY
);

extends 'Lemonldap::NG::Portal::Main::Plugin';

our $VERSION = '2.0.6';

# INITIALIZATION

sub init {
    $_[0]->p->{_passwordDB} = $_[0];
}

# INTERFACE

sub forAuthUser { '_modifyPassword' }

# RUNNING METHODS

sub _modifyPassword {
    my ( $self, $req, $requireOldPwd ) = @_;

    # Exit if no password change requested
    return PE_OK
      unless ( $req->data->{newpassword} = $req->param('newpassword') );

    # Verify that old password is good
    return PE_PASSWORD_MISMATCH
      unless ( $req->data->{newpassword} eq $req->param('confirmpassword') );

    # Check if portal require old password
    if ( $self->conf->{portalRequireOldPassword} or $requireOldPwd ) {

        # TODO: verify oldpassword
        unless ( $req->data->{oldpassword} = $req->param('oldpassword') ) {
            $self->logger->warn("Portal require old password");
            return PE_PP_MUST_SUPPLY_OLD_PASSWORD;
        }

        # Verify old password
        return PE_BADOLDPASSWORD
          unless ( $self->confirm( $req, $req->data->{oldpassword} ) );
    }

    my $cpq = $self->checkPasswordQuality( $req->data->{newpassword} );
    return $cpq unless ( $cpq == PE_OK );

    # Call password package
    my $res = $self->modifyPassword( $req, $req->data->{newpassword} );
    if ( $res == PE_PASSWORD_OK ) {
        $self->logger->debug( 'Update password in session for ' . $req->user );
        my $infos;

        # Store new password if asked
        if ( $self->conf->{storePassword} ) {
            $self->p->updateSession(
                $req,
                {
                    _passwordDB => $self->p->getModule( $req, 'password' ),
                    _password   => $req->{newpassword}
                }
            );
        }
        else {
            $self->p->updateSession( $req,
                { _passwordDB => $self->p->getModule( $req, 'password' ) } );
        }

        # Set a flag to ignore password change in Menu
        $req->{ignorePasswordChange} = 1;

        # Set a flag to allow sending a mail
        $req->{passwordWasChanged} = 1;

        #  Continue process if password change is ok
        return PE_PASSWORD_OK;
    }
    return $res;
}

sub checkPasswordQuality {
    my ( $self, $password ) = @_;

    # Min size
    if ( $self->conf->{passwordPolicyMinSize}
        and length($password) < $self->conf->{passwordPolicyMinSize} )
    {
        $self->logger->error("Password too short");
        return PE_PP_PASSWORD_TOO_SHORT;
    }

    # Min lower
    if ( $self->conf->{passwordPolicyMinLower} ) {
        my $lower = 0;
        $lower++ while ( $password =~ m/\p{lowercase}/g );
        if ( $lower < $self->conf->{passwordPolicyMinLower} ) {
            $self->logger->error("Password has not enough lower characters");
            return PE_PP_INSUFFICIENT_PASSWORD_QUALITY;
        }
    }

    # Min upper
    if ( $self->conf->{passwordPolicyMinUpper} ) {
        my $upper = 0;
        $upper++ while ( $password =~ m/\p{uppercase}/g );
        if ( $upper < $self->conf->{passwordPolicyMinUpper} ) {
            $self->logger->error("Password has not enough upper characters");
            return PE_PP_INSUFFICIENT_PASSWORD_QUALITY;
        }
    }

    # Min digit
    if ( $self->conf->{passwordPolicyMinDigit} ) {
        my $digit = 0;
        $digit++ while ( $password =~ m/\d/g );
        if ( $digit < $self->conf->{passwordPolicyMinDigit} ) {
            $self->logger->error("Password has not enough digit characters");
            return PE_PP_INSUFFICIENT_PASSWORD_QUALITY;
        }
    }

    return PE_OK;
}

1;

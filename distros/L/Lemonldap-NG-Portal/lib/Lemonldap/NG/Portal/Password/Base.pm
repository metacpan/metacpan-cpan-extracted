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
);

extends 'Lemonldap::NG::Portal::Main::Plugin';

our $VERSION = '2.0.0';

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

1;

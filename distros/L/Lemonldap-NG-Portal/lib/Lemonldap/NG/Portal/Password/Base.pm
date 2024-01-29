# Base package for Password modules
package Lemonldap::NG::Portal::Password::Base;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_PASSWORD_OK
  PE_BADOLDPASSWORD
  PE_PASSWORD_MISMATCH
  PE_PP_PASSWORD_TOO_SHORT
  PE_PP_NOT_ALLOWED_CHARACTER
  PE_PP_NOT_ALLOWED_CHARACTERS
  PE_PP_MUST_SUPPLY_OLD_PASSWORD
  PE_PP_INSUFFICIENT_PASSWORD_QUALITY
);

extends 'Lemonldap::NG::Portal::Main::Plugin';

our $VERSION = '2.18.0';

# INITIALIZATION

has requireOldPwdRule => ( is => 'rw' );

sub init {
    my ($self) = shift;
    $self->requireOldPwdRule(
        $self->p->buildRule(
            $self->conf->{portalRequireOldPassword},
            'portalRequireOldPassword'
        )
    );
    return 0 unless $self->requireOldPwdRule;

    $self->p->{_passwordDB} = $self;
}

# INTERFACE

use constant forAuthUser => '_modifyPassword';

# RUNNING METHODS

sub _modifyPassword {
    my ( $self, $req, $requireOldPwd ) = @_;

    # Exit if no password change requested
    return PE_OK
      unless ( $req->data->{newpassword} = $req->param('newpassword') );

    # Verify that old password is good
    return PE_PASSWORD_MISMATCH
      unless ( $req->data->{newpassword} eq $req->param('confirmpassword') );

    my $oldPwdRule = $self->p->HANDLER->buildSub(
        $self->p->HANDLER->substitute(
            $self->conf->{portalRequireOldPassword}
        )
    );
    unless ($oldPwdRule) {
        my $error =
          $self->p->HANDLER->tsv->{jail}->error || 'Unable to compile rule';
    }

    # Check if portal require old password
    if ( $oldPwdRule->( $req, $req->userData ) or $requireOldPwd ) {
        unless ( $req->data->{oldpassword} = $req->param('oldpassword') ) {
            $self->logger->warn("Portal require old password");
            return PE_PP_MUST_SUPPLY_OLD_PASSWORD;
        }

        # Verify old password
        return PE_BADOLDPASSWORD
          unless $self->confirm( $req, $req->data->{oldpassword} );
    }

    my $hook_result = $self->p->processHook(
        $req, 'passwordBeforeChange', $req->user,
        $req->data->{newpassword},
        $req->data->{oldpassword}
    );
    return $hook_result if ( $hook_result != PE_OK );

    # Call password package
    my $res = $self->modifyPassword( $req, $req->data->{newpassword} );
    if ( $res == PE_PASSWORD_OK ) {

        my $hook_result = $self->p->processHook(
            $req, 'passwordAfterChange', $req->user,
            $req->data->{newpassword},
            $req->data->{oldpassword}
        );

        $self->logger->debug( 'Update password in session for ' . $req->user );
        my $userlog = $req->sessionInfo->{ $self->conf->{whatToTrace} };
        my $iplog   = $req->sessionInfo->{ipAddr};
        $self->userLogger->notice("Password changed for $userlog ($iplog)")
          if ( defined $userlog and $iplog );
        my $infos;

        # Store new password if asked
        if ( $self->conf->{storePassword} ) {
            my $passwordToStore = $req->data->{'newpassword'};
            $self->p->updateSession(
                $req,
                {
                    _passwordDB => $self->p->getModule( $req, 'password' ),
                    _password   => $self->conf->{storePasswordEncrypted}
                    ? $self->p->HANDLER->tsv->{cipher}
                      ->encrypt($passwordToStore)
                    : $passwordToStore
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
        return ( $hook_result != PE_OK ) ? $hook_result : PE_PASSWORD_OK;
    }
    return $res;
}

# This method should be called when resetting the password
# in order to call the password hook
sub setNewPassword {
    my ( $self, $req, $pwd, $useMail ) = @_;
    my %args;
    my $hook_result =
      $self->p->processHook( $req, 'passwordBeforeChange', $req->user, $pwd );
    return $hook_result if ( $hook_result != PE_OK );

    # Delegate to subclass
    $args{useMail}       = $useMail;
    $args{passwordReset} = 1;
    my $mod_result = $self->modifyPassword( $req, $pwd, %args );

    if ( $mod_result == PE_PASSWORD_OK ) {
        $hook_result =
          $self->p->processHook( $req, 'passwordAfterChange', $req->user,
            $pwd );
        return ( $hook_result != PE_OK ) ? $hook_result : PE_PASSWORD_OK;
    }
    else {
        return $mod_result;
    }

}

1;

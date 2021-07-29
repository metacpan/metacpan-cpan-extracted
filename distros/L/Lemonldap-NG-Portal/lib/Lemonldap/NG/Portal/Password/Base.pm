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

our $VERSION = '2.0.12';

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
        my $error = $self->p->HANDLER->tsv->{jail}->error || '???';
    }

    my $pwdPolicyRule = $self->p->HANDLER->buildSub(
        $self->p->HANDLER->substitute(
            $self->conf->{passwordPolicyActivation}
        )
    );
    unless ($pwdPolicyRule) {
        my $error = $self->p->HANDLER->tsv->{jail}->error || '???';
    }

    # Check if portal require old password
    if ( $oldPwdRule->( $req, $req->userData ) or $requireOldPwd ) {

        # TODO: verify oldpassword
        unless ( $req->data->{oldpassword} = $req->param('oldpassword') ) {
            $self->logger->warn("Portal require old password");
            return PE_PP_MUST_SUPPLY_OLD_PASSWORD;
        }

        # Verify old password
        return PE_BADOLDPASSWORD
          unless ( $self->confirm( $req, $req->data->{oldpassword} ) );
    }

    my $cpq =
        $pwdPolicyRule->( $req, $req->userData )
      ? $self->checkPasswordQuality( $req->data->{newpassword} )
      : PE_OK;
    return $cpq unless ( $cpq == PE_OK );

    my $hook_result = $self->p->processHook(
        $req, 'passwordBeforeChange', $req->user,
        $req->data->{newpassword},
        $req->data->{oldpassword}
    );
    return $hook_result if ( $hook_result != PE_OK );

    # Call password package
    my $res = $self->modifyPassword( $req, $req->data->{newpassword} );
    if ( $res == PE_PASSWORD_OK ) {

        $self->p->processHook(
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
            $self->p->updateSession(
                $req,
                {
                    _passwordDB => $self->p->getModule( $req, 'password' ),
                    _password   => $req->data->{newpassword}
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

    ### Special characters policy
    my $speChars = $self->conf->{passwordPolicySpecialChar};
    $speChars =~ s/\s+//g;

    ## Min special characters
    # Just number of special characters must be checked
    if ( $self->conf->{passwordPolicyMinSpeChar} && $speChars eq '__ALL__' ) {
        my $spe = $password =~ s/\W//g;
        if ( $spe < $self->conf->{passwordPolicyMinSpeChar} ) {
            $self->logger->error("Password has not enough special characters");
            return PE_PP_INSUFFICIENT_PASSWORD_QUALITY;
        }
        return PE_OK;
    }

    # Number of special characters must be checked
    if ( $self->conf->{passwordPolicyMinSpeChar} && $speChars ) {
        my $test = $password;
        my $spe  = $test =~ s/[\Q$speChars\E]//g;
        if ( $spe < $self->conf->{passwordPolicyMinSpeChar} ) {
            $self->logger->error("Password has not enough special characters");
            return PE_PP_INSUFFICIENT_PASSWORD_QUALITY;
        }
    }

    ## Fobidden special characters
    unless ( $speChars eq '__ALL__' ) {
        $password =~ s/[\Q$speChars\E\w]//g;
        if ($password) {
            $self->logger->error( 'Password contains '
                  . length($password)
                  . " forbidden character(s): $password" );
            return length($password) > 1
              ? PE_PP_NOT_ALLOWED_CHARACTERS
              : PE_PP_NOT_ALLOWED_CHARACTER;
        }
    }

    return PE_OK;
}

# This method should be called when resetting the password
# in order to call the password hook
sub setNewPassword {
    my ( $self, $req, $pwd, $useMail ) = @_;

    my $hook_result =
      $self->p->processHook( $req, 'passwordBeforeChange', $req->user, $pwd );
    return $hook_result if ( $hook_result != PE_OK );

    # Delegate to subclass
    my $mod_result = $self->modifyPassword( $req, $pwd, $useMail );

    if ( $mod_result == PE_PASSWORD_OK ) {
        $hook_result =
          $self->p->processHook( $req, 'passwordAfterChange', $req->user,
            $pwd );
        if ( $hook_result != PE_OK ) {
            return $hook_result;
        }
        else {
            return PE_PASSWORD_OK;
        }
    }
    else {
        return $mod_result;
    }

}

1;

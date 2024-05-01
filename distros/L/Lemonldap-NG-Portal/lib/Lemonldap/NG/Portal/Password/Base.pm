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

extends
  qw/Lemonldap::NG::Portal::Main::Plugin Lemonldap::NG::Portal::Lib::SMTP/;

our $VERSION = '2.19.0';

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

        if ( $self->conf->{mailOnPasswordChange} ) {

            # Send mail containing the new password
            $req->data->{mailAddress} ||=
              $self->p->getFirstValue(
                $req->{sessionInfo}->{ $self->conf->{mailSessionKey} } );

            # Build mail content
            my $tr      = $self->translate($req);
            my $subject = $self->conf->{mailSubject};
            unless ($subject) {
                $subject = 'mailSubject';
                $tr->( \$subject );
            }
            my $body;
            my $html;
            my $password = $req->data->{newpassword};

            if ( $self->conf->{mailBody} ) {

                # We use a specific text message, no html
                $body = $self->conf->{mailBody};

                # Replace variables in body
                $body =~ s/\$password/$password/g;
                $body =~ s/\$(\w+)/$req->{sessionInfo}->{$1} || ''/ge;

            }

            else {

                # Use HTML template
                $body = $self->loadMailTemplate(
                    $req,
                    'mail_password',
                    filter => $tr,
                    params => {
                        password => $password,
                    },
                );
                $html = 1;
            }

            # Send mail
            unless (
                $self->send_mail(
                    $req->data->{mailAddress},
                    $subject, $body, $html
                )
              )
            {
                $self->logger->warn( "Unable to send password changed mail to "
                      . $req->data->{mailAddress} );
            }
        }

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

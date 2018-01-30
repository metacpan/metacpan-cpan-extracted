## @file
# Module for registering a new user

## @class Lemonldap::NG::Portal::Register
# Module for registering a new user
package Lemonldap::NG::Portal::Register;

use strict;
use warnings;

our $VERSION = '1.9.15';

use Lemonldap::NG::Portal::Simple qw(:all);
use base qw(Lemonldap::NG::Portal::SharedConf Exporter);
use HTML::Template;
use Encode;
use POSIX qw(strftime);

#inherits Lemonldap::NG::Portal::_SMTP

*EXPORT_OK   = *Lemonldap::NG::Portal::Simple::EXPORT_OK;
*EXPORT_TAGS = *Lemonldap::NG::Portal::Simple::EXPORT_TAGS;
*EXPORT      = *Lemonldap::NG::Portal::Simple::EXPORT;

## @method boolean process()
# Call functions for registering user
# - itself:
#   - smtpInit
#   - extractRegisterInfo
#   - storeRegisterSession
#   - sendConfirmationMail
#   - registerUser
#   - sendRegisterMail
# - portal core module:
#   - controlUrlOrigin
# - authentication module:
#   - authInit
#   - authFinish
# - userDB module:
#   - userDBInit
#   - getUser
#   - userDBFinish
# - registerDB module:
#  - getLogin
#  - createUser
#  - registerDBFinish
# @return 1 if all is OK
sub process {
    my ($self) = @_;

    # Process subroutines
    $self->{error} = PE_OK;

    $self->{error} = $self->_subProcess(
        qw(controlUrlOrigin smtpInit authInit extractRegisterInfo userDBInit getRegisterUser
          userDBFinish storeRegisterSession sendConfirmationMail
          registerUser registerDBFinish sendRegisterMail authFinish)
    );

    return (
        (
                 $self->{error} <= 0
              or $self->{error} == PE_CAPTCHAERROR
              or $self->{error} == PE_CAPTCHAEMPTY
              or $self->{error} == PE_MAILCONFIRMOK
              or $self->{error} == PE_MAILOK
        ) ? 0 : 1
    );
}

## @method int smtpInit()
# Load SMTP methods
# @return Lemonldap::NG::Portal constant
sub smtpInit {
    my ($self) = @_;

    eval { use base qw(Lemonldap::NG::Portal::_SMTP) };

    if ($@) {
        $self->lmLog( "Unable to load SMTP functions ($@)", 'error' );
        return PE_ERROR;
    }

    PE_OK;
}

## @method int extractRegisterInfo
# Get info from form or from register_token
# @return Lemonldap::NG::Portal constant
sub extractRegisterInfo {
    my ($self) = @_;

    if ( $self->{captcha_register_enabled} ) {
        eval { $self->initCaptcha(); };
        $self->lmLog( "Can't init captcha: $@", "error" ) if $@;
    }

    unless ( $self->param('mail') || $self->param('register_token') ) {
        return PE_REGISTERFIRSTACCESS if ( $self->request_method =~ /GET/ );
        return PE_REGISTERFORMEMPTY;
    }

    $self->{register_token} = $self->param('register_token');

    # If a register token is present, find the corresponding info
    if ( $self->{register_token} ) {

        $self->lmLog( "Token given for register: " . $self->{register_token},
            'debug' );

        # Get the corresponding session
        my $registerSession =
          $self->getApacheSession( $self->{register_token} );

        if ( $registerSession && $registerSession->data ) {
            $self->{registerInfo}->{mail} = $registerSession->data->{mail};
            $self->{registerInfo}->{firstname} =
              $registerSession->data->{firstname};
            $self->{registerInfo}->{lastname} =
              $registerSession->data->{lastname};
            $self->{registerInfo}->{ipAddr} = $registerSession->data->{ipAddr};
            $self->lmLog(
                "User associated to token: " . $self->{registerInfo}->{mail},
                'debug' );
        }

        return PE_BADMAILTOKEN unless ( $self->{registerInfo}->{mail} );
    }
    else {

        # Use submitted value
        $self->{registerInfo}->{mail}      = $self->param('mail');
        $self->{registerInfo}->{firstname} = $self->param('firstname');
        $self->{registerInfo}->{lastname}  = $self->param('lastname');
        $self->{registerInfo}->{ipAddr}    = $self->ipAddr();

        # Captcha for register form
        # Only if register session does not already exist
        if (   $self->{captcha_register_enabled}
            && $self->{registerInfo}->{mail}
            && !$self->getRegisterSession( $self->{registerInfo}->{mail} ) )
        {
            $self->{captcha_user_code}  = $self->param('captcha_user_code');
            $self->{captcha_check_code} = $self->param('captcha_code');

            unless ( $self->{captcha_user_code} && $self->{captcha_check_code} )
            {
                $self->lmLog( "Captcha not filled", 'warn' );
                return PE_CAPTCHAEMPTY;
            }

            $self->lmLog(
                "Captcha data received: "
                  . $self->{captcha_user_code} . " and "
                  . $self->{captcha_check_code},
                'debug'
            );

            # Check captcha
            my $captcha_result =
              $self->checkCaptcha( $self->{captcha_user_code},
                $self->{captcha_check_code} );

            if ( $captcha_result != 1 ) {
                if (   $captcha_result == -3
                    or $captcha_result == -2 )
                {
                    $self->lmLog( "Captcha failed: wrong code", 'warn' );
                    return PE_CAPTCHAERROR;
                }
                elsif ( $captcha_result == 0 ) {
                    $self->lmLog(
                        "Captcha failed: code not checked (file error)",
                        'warn' );
                    return PE_CAPTCHAERROR;
                }
                elsif ( $captcha_result == -1 ) {
                    $self->lmLog( "Captcha failed: code has expired", 'warn' );
                    return PE_CAPTCHAERROR;
                }
            }
            $self->lmLog( "Captcha code verified", 'debug' );
        }

    }

    # Check mail
    return PE_MALFORMEDUSER
      unless ( $self->{registerInfo}->{mail} =~ /$self->{userControl}/o );

    PE_OK;
}

## @method int getRegisterUser
# Search for user using UserDB module
# If the user already exists, register is forbidden
# @return Lemonldap::NG::Portal constant
sub getRegisterUser {
    my ($self) = @_;

    $self->{mail} = $self->{registerInfo}->{mail};

    if ( $self->getUser() == PE_OK ) {

        # User already exists
        $self->lmLog(
"Register: refuse mail $self->{mail} because already exists in UserDB",
            'error'
        );
        return PE_REGISTERALREADYEXISTS;
    }

    return PE_OK;
}

## @method int storeRegisterSession
# Create register session and store token
# @return Lemonldap::NG::Portal constant
sub storeRegisterSession {
    my ($self) = @_;

    # Skip this step if confirmation was already sent
    return PE_OK
      if ( $self->{register_token}
        or $self->getRegisterSession( $self->{registerInfo}->{mail} ) );

    # Create a new session
    my $registerSession = $self->getApacheSession();

    # Set _utime for session autoremove
    # Use default session timeout and register session timeout to compute it
    my $time            = time();
    my $timeout         = $self->{timeout};
    my $registerTimeout = $self->{registerTimeout} || $timeout;

    my $infos = {};
    $infos->{_utime} = $time + ( $registerTimeout - $timeout );

    # Store expiration timestamp for further use
    $infos->{registerSessionTimeoutTimestamp} = $time + $registerTimeout;
    $self->{registerInfo}->{registerSessionTimeoutTimestamp} =
      $time + $registerTimeout;

    # Store start timestamp for further use
    $infos->{registerSessionStartTimestamp} = $time;
    $self->{registerInfo}->{registerSessionStartTimestamp} = $time;

    # Store infos
    $infos->{mail}      = $self->{registerInfo}->{mail};
    $infos->{firstname} = $self->{registerInfo}->{firstname};
    $infos->{lastname}  = $self->{registerInfo}->{lastname};
    $infos->{ipAddr}    = $self->{registerInfo}->{ipAddr};

    # Store type
    $infos->{_type} = "register";

    # Update session
    $registerSession->update($infos);

    PE_OK;
}

## @method int sendConfirmationMail
# Send confirmation mail
# @return Lemonldap::NG::Portal constant
sub sendConfirmationMail {
    my ($self) = @_;

    # Skip this step if user clicked on the confirmation link
    return PE_OK if $self->{register_token};

    # Check if confirmation mail has already been sent
    my $register_session =
      $self->getRegisterSession( $self->{registerInfo}->{mail} );
    $self->{mail_already_sent} = ( $register_session and !$self->{id} ) ? 1 : 0;

    # Read session to get creation and expiration dates
    $self->{id} = $register_session unless $self->{id};

    $self->lmLog( "Register session found: $register_session", 'debug' );

    my $registerSession = $self->getApacheSession( $register_session, 1 );
    $self->{registerInfo}->{registerSessionTimeoutTimestamp} =
      $registerSession->data->{registerSessionTimeoutTimestamp};
    $self->{registerInfo}->{registerSessionStartTimestamp} =
      $registerSession->data->{registerSessionStartTimestamp};

    # Mail session expiration date
    my $expTimestamp = $self->{registerInfo}->{registerSessionTimeoutTimestamp};

    $self->lmLog( "Register expiration timestamp: $expTimestamp", 'debug' );

    $self->{expMailDate} = strftime( "%d/%m/%Y", localtime $expTimestamp );
    $self->{expMailTime} = strftime( "%H:%M",    localtime $expTimestamp );

    # Mail session start date
    my $startTimestamp = $self->{registerInfo}->{registerSessionStartTimestamp};

    $self->lmLog( "Register start timestamp: $startTimestamp", 'debug' );

    $self->{startMailDate} = strftime( "%d/%m/%Y", localtime $startTimestamp );
    $self->{startMailTime} = strftime( "%H:%M",    localtime $startTimestamp );

    # Ask if user want another confirmation email
    if ( $self->{mail_already_sent} and !$self->param('resendconfirmation') ) {
        return PE_MAILCONFIRMATION_ALREADY_SENT;
    }

    # Build confirmation url
    my $url = $self->{registerUrl} . "?register_token=" . $self->{id};
    $url .= '&skin=' . $self->getSkin();
    $url .= '&' . $self->{authChoiceParam} . '=' . $self->{_authChoice}
      if ( $self->{_authChoice} );
    $url .= '&url=' . $self->{_url} if $self->{_url};

    # Build mail content
    my $subject = $self->{registerConfirmSubject};
    my $body;
    my $html = 1;

    # Use HTML template
    my $tplfile = $self->getApacheHtdocsPath
      . "/skins/$self->{portalSkin}/mail_register_confirm.tpl";
    $tplfile =
      $self->getApacheHtdocsPath . "/skins/common/mail_register_confirm.tpl"
      unless ( -e $tplfile );
    my $template = HTML::Template->new(
        filename => $tplfile,
        filter   => sub { $self->translate_template(@_) }
    );
    $body = $template->output();

    # Replace variables in body
    $body =~ s/\$expMailDate/$self->{expMailDate}/g;
    $body =~ s/\$expMailTime/$self->{expMailTime}/g;
    $body =~ s/\$url/$url/g;
    $body =~ s/\$(\w+)/decode("utf8",$self->{registerInfo}->{$1})/ge;

    # Send mail
    return PE_MAILERROR
      unless $self->send_mail( $self->{registerInfo}->{mail}, $subject, $body,
        $html );

    PE_MAILCONFIRMOK;
}

## @method int registerUser
# Create the account
# @return Lemonldap::NG::Portal constant
sub registerUser {
    my ($self) = @_;
    my $result;

    # Check mail is still unused
    $result = $self->getRegisterUser;
    unless ( $result == PE_OK ) {
        return $result;
    }

    # Generate a complex password
    my $password = $self->gen_password( $self->{randomPasswordRegexp} );

    $self->lmLog( "Generated password: " . $password, 'debug' );

    $self->{registerInfo}->{password} = $password;
    $self->{forceReset} = 1;

    # Find a login
    $result = $self->computeLogin;
    unless ( $result == PE_OK ) {
        $self->lmLog(
            "Could not compute login for " . $self->{registerInfo}->{mail},
            'error' );
        return $result;
    }

    # Create user
    $self->lmLog( "Create new user $self->{registerInfo}->{login}", 'debug' );
    $result = $self->createUser;
    unless ( $result == PE_OK ) {
        $self->lmLog( "Could not create user " . $self->{registerInfo}->{login},
            'error' );
        return $result;
    }

    # Register token can be used only one time, delete the session if all is ok
    if ( $result == PE_OK ) {

        # Get the corresponding session
        my $registerSession =
          $self->getApacheSession( $self->{register_token} );

        if ($registerSession) {

            $self->lmLog( "Delete register session " . $self->{register_token},
                'debug' );

            $registerSession->remove;
        }
        else {
            $self->lmLog( "Register session not found", 'warn' );
        }

        # Force result to PE_OK to continue the process
        $result = PE_OK;
    }

    return $result;
}

## @method int sendRegisterMail
# Send mail containing a temporary password
# @return Lemonldap::NG::Portal constant
sub sendRegisterMail {
    my ($self) = @_;

    # Build mail content
    my $subject = $self->{registerDoneSubject};
    my $body;
    my $html = 1;

    # Build portal url
    my $url = $self->{portal};
    $url .= '?skin=' . $self->getSkin();
    $url .= '&' . $self->{authChoiceParam} . '=' . $self->{_authChoice}
      if ( $self->{_authChoice} );
    $url .= '&url=' . $self->{_url} if $self->{_url};

    # Use HTML template
    my $tplfile = $self->getApacheHtdocsPath
      . "/skins/$self->{portalSkin}/mail_register_done.tpl";
    $tplfile =
      $self->getApacheHtdocsPath . "/skins/common/mail_register_done.tpl"
      unless ( -e $tplfile );
    my $template = HTML::Template->new(
        filename => $tplfile,
        filter   => sub { $self->translate_template(@_) }
    );
    $body = $template->output();

    # Replace variables in body
    $body =~ s/\$url/$url/g;
    $body =~ s/\$(\w+)/decode("utf8",$self->{registerInfo}->{$1})/ge;

    # Send mail
    return PE_MAILERROR
      unless $self->send_mail( $self->{registerInfo}->{mail}, $subject, $body,
        $html );

    PE_MAILOK;
}

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::Register - Register a new user

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::Register;
  
  my $portal = new Lemonldap::NG::Portal::Register();
 
  $portal->process();

  # Write here HTML to manage errors and confirmation messages

=head1 DESCRIPTION

Lemonldap::NG::Portal::Register - Register a new user

See L<Lemonldap::NG::Portal::SharedConf> for a complete example of use of
Lemonldap::Portal::* libraries.

=head1 METHODS

=head3 process

Main method.

=head1 SEE ALSO

L<Lemonldap::NG::Handler>, L<Lemonldap::NG::Portal::SharedConf>, L<CGI>,
L<http://lemonldap-ng.org/>

=head1 AUTHOR

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng/issues>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2010-2015, 2012 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=back

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut

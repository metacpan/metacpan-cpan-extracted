## @file
# Module for password reset by mail

## @class Lemonldap::NG::Portal::MailReset
# Module for password reset by mail
package Lemonldap::NG::Portal::MailReset;

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
# Call functions to handle password reset by mail issued from
# - itself:
#   - smtpInit
#   - extractMailInfo
#   - getMailUser
#   - storeMailSession
#   - sendConfirmationMail
#   - changePassword
#   - sendPasswordMail
# - portal core module:
#   - controlUrlOrigin
#   - setMacros
#   - setLocalGroups
#   - setGroups
# - authentication module:
#   - authInit
#   - authFinish
# - userDB module:
#   - userDBInit
#   - setSessionInfo
#   - userDBFinish
# - passwordDB module:
#   - passwordDBInit
#   - passwordDBFinish
# @return 1 if all is OK
sub process {
    my ($self) = @_;

    # Process subroutines
    $self->{error} = PE_OK;

    $self->{error} = $self->_subProcess(
        qw(controlUrlOrigin smtpInit authInit extractMailInfo userDBInit getMailUser setSessionInfo
          setMacros setGroups setPersistentSessionInfo setLocalGroups userDBFinish
          storeMailSession sendConfirmationMail passwordDBInit changePassword passwordDBFinish
          sendPasswordMail authFinish)
    );

    return (
        (
                 $self->{error} <= 0
              or $self->{error} == PE_PASSWORD_OK
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

## @method int extractMailInfo
# Get mail from form or from mail_token
# @return Lemonldap::NG::Portal constant
sub extractMailInfo {
    my ($self) = @_;

    if ( $self->{captcha_mail_enabled} ) {
        eval { $self->initCaptcha(); };
        $self->lmLog( "Can't init captcha: $@", "error" ) if $@;
    }

    unless ( $self->param('mail') || $self->param('mail_token') ) {
        return PE_MAILFIRSTACCESS if ( $self->request_method =~ /GET/ );
        return PE_MAILFORMEMPTY;
    }

    $self->{mail_token}      = $self->param('mail_token');
    $self->{newpassword}     = $self->param('newpassword');
    $self->{confirmpassword} = $self->param('confirmpassword');

    # If a mail token is present, find the corresponding mail
    if ( $self->{mail_token} ) {

        $self->lmLog( "Token given for password reset: " . $self->{mail_token},
            'debug' );

        # Get the corresponding session
        my $mailSession = $self->getApacheSession( $self->{mail_token} );

        if ($mailSession) {
            $self->{mail} = $mailSession->data->{user};
            $self->{mailAddress} =
              $mailSession->data->{ $self->{mailSessionKey} };
            $self->lmLog( "User associated to token: " . $self->{mail},
                'debug' );
        }

        return PE_BADMAILTOKEN unless ( $self->{mail} );
    }
    else {

        # Use submitted value
        $self->{mail} = $self->param('mail');

        # Captcha for mail form
        # Only if mail session does not already exist
        if (   $self->{captcha_mail_enabled}
            && $self->{mail}
            && !$self->getMailSession( $self->{mail} ) )
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
    return PE_MALFORMEDUSER unless ( $self->{mail} =~ /$self->{userControl}/o );

    PE_OK;
}

## @method int getMailUser
# Search for user using UserDB module
# @return Lemonldap::NG::Portal constant
sub getMailUser {
    my ($self) = @_;

    my $error = $self->getUser();

    if ( $error == PE_USERNOTFOUND or $error == PE_BADCREDENTIALS ) {
        $self->_sub('userDBFinish');
        if ( $self->{portalErrorOnMailNotFound} ) {
            return PE_MAILNOTFOUND;
        }
        my $mailTimeout = $self->{mailTimeout} || $self->{timeout};
        my $expTimestamp = time() + $mailTimeout;
        $self->{expMailDate} = strftime( "%d/%m/%Y", localtime $expTimestamp );
        $self->{expMailTime} = strftime( "%H:%M",    localtime $expTimestamp );
        return PE_MAILCONFIRMOK;
    }

    return $error;
}

## @method int storeMailSession
# Create mail session and store token
# @return Lemonldap::NG::Portal constant
sub storeMailSession {
    my ($self) = @_;

    # Skip this step if confirmation was already sent
    return PE_OK
      if ( $self->{mail_token} or $self->getMailSession( $self->{mail} ) );

    # Create a new session
    my $mailSession = $self->getApacheSession();

    # Set _utime for session autoremove
    # Use default session timeout and mail session timeout to compute it
    my $time        = time();
    my $timeout     = $self->{timeout};
    my $mailTimeout = $self->{mailTimeout} || $timeout;

    my $infos = {};
    $infos->{_utime} = $time + ( $mailTimeout - $timeout );

    # Store expiration timestamp for further use
    $infos->{mailSessionTimeoutTimestamp} = $time + $mailTimeout;
    $self->{mailSessionTimeoutTimestamp}  = $time + $mailTimeout;

    # Store start timestamp for further use
    $infos->{mailSessionStartTimestamp} = $time;
    $self->{mailSessionStartTimestamp}  = $time;

    # Store mail
    $infos->{ $self->{mailSessionKey} } =
      $self->getFirstValue( $self->{sessionInfo}->{ $self->{mailSessionKey} } );

    # Store user
    $infos->{user} = $self->{mail};

    # Store type
    $infos->{_type} = "mail";

    # Update session
    $mailSession->update($infos);

    PE_OK;
}

## @method int sendConfirmationMail
# Send confirmation mail
# @return Lemonldap::NG::Portal constant
sub sendConfirmationMail {
    my ($self) = @_;

    # Skip this step if user clicked on the confirmation link
    return PE_OK if $self->{mail_token};

    # Check if confirmation mail has already been sent
    my $mail_session = $self->getMailSession( $self->{mail} );
    $self->{mail_already_sent} = ( $mail_session and !$self->{id} ) ? 1 : 0;

    # Read mail session to get creation and expiration dates
    $self->{id} = $mail_session unless $self->{id};

    $self->lmLog( "Mail session found: $mail_session", 'debug' );

    my $mailSession = $self->getApacheSession( $mail_session, 1 );
    $self->{mailSessionTimeoutTimestamp} =
      $mailSession->data->{mailSessionTimeoutTimestamp};
    $self->{mailSessionStartTimestamp} =
      $mailSession->data->{mailSessionStartTimestamp};

    # Mail session expiration date
    my $expTimestamp = $self->{mailSessionTimeoutTimestamp};

    $self->lmLog( "Mail expiration timestamp: $expTimestamp", 'debug' );

    $self->{expMailDate} = strftime( "%d/%m/%Y", localtime $expTimestamp );
    $self->{expMailTime} = strftime( "%H:%M",    localtime $expTimestamp );

    # Mail session start date
    my $startTimestamp = $self->{mailSessionStartTimestamp};

    $self->lmLog( "Mail start timestamp: $startTimestamp", 'debug' );

    $self->{startMailDate} = strftime( "%d/%m/%Y", localtime $startTimestamp );
    $self->{startMailTime} = strftime( "%H:%M",    localtime $startTimestamp );

    # Ask if user want another confirmation email
    if ( $self->{mail_already_sent} and !$self->param('resendconfirmation') ) {
        return PE_MAILCONFIRMATION_ALREADY_SENT;
    }

    # Get mail address
    unless ( $self->{mailAddress} ) {
        $self->{mailAddress} =
          $self->getFirstValue(
            $self->{sessionInfo}->{ $self->{mailSessionKey} } );
    }

    # Build confirmation url
    my $url = $self->{mailUrl} . "?mail_token=" . $self->{id};
    $url .= '&skin=' . $self->getSkin();
    $url .= '&' . $self->{authChoiceParam} . '=' . $self->{_authChoice}
      if ( $self->{_authChoice} );
    $url .= '&url=' . $self->{_url} if $self->{_url};

    # Build mail content
    my $subject = $self->{mailConfirmSubject};
    my $body;
    my $html;
    if ( $self->{mailConfirmBody} ) {

        # We use a specific text message, no html
        $body = $self->{mailConfirmBody};
    }
    else {

        # Use HTML template
        my $tplfile = $self->getApacheHtdocsPath
          . "/skins/$self->{portalSkin}/mail_confirm.tpl";
        $tplfile = $self->getApacheHtdocsPath . "/skins/common/mail_confirm.tpl"
          unless ( -e $tplfile );
        my $template = HTML::Template->new(
            filename => $tplfile,
            filter   => sub { $self->translate_template(@_) }
        );
        $body = $template->output();
        $html = 1;
    }

    # Replace variables in body
    $body =~ s/\$expMailDate/$self->{expMailDate}/g;
    $body =~ s/\$expMailTime/$self->{expMailTime}/g;
    $body =~ s/\$url/$url/g;
    $body =~ s/\$(\w+)/$self->{sessionInfo}->{$1}/ge;

    # Send mail
    return PE_MAILCONFIRMOK
      unless $self->send_mail( $self->{mailAddress}, $subject, $body, $html );

    PE_MAILCONFIRMOK;
}

## @method int changePassword
# Change the password or generate a new password
# @return Lemonldap::NG::Portal constant
sub changePassword {
    my ($self) = @_;

    # Check if user wants to generate the new password
    if ( $self->param('reset') ) {

        $self->lmLog(
            "Reset password request for " . $self->{sessionInfo}->{_user},
            'debug' );

        # Generate a complex password
        my $password = $self->gen_password( $self->{randomPasswordRegexp} );

        $self->lmLog( "Generated password: " . $password, 'debug' );

        $self->{newpassword}     = $password;
        $self->{confirmpassword} = $password;
        $self->{forceReset}      = 1;
    }

    # Else a password is required
    else {
        unless ( $self->{newpassword} && $self->{confirmpassword} ) {
            return PE_PASSWORDFIRSTACCESS if ( $self->request_method =~ /GET/ );
            return PE_PASSWORDFORMEMPTY;
        }
    }

    # Modify the password
    $self->{portalRequireOldPassword} = 0;
    $self->{user}                     = $self->{mail};
    my $result = $self->modifyPassword();
    $self->{user} = undef;

    # Mail token can be used only one time, delete the session if all is ok
    if ( $result == PE_PASSWORD_OK or $result == PE_OK ) {

        # Get the corresponding session
        my $mailSession = $self->getApacheSession( $self->{mail_token} );

        if ($mailSession) {

            $self->lmLog( "Delete mail session " . $self->{mail_token},
                'debug' );

            $mailSession->remove;
        }
        else {
            $self->lmLog( "Mail session not found", 'warn' );
        }

        # Force result to PE_OK to continue the process
        $result = PE_OK;
    }

    return $result;
}

## @method int sendPasswordMail
# Send mail containing the new password
# @return Lemonldap::NG::Portal constant
sub sendPasswordMail {
    my ($self) = @_;

    # Get mail address
    unless ( $self->{mailAddress} ) {
        $self->{mailAddress} =
          $self->getFirstValue(
            $self->{sessionInfo}->{ $self->{mailSessionKey} } );
    }

    # Build mail content
    my $subject = $self->{mailSubject};
    my $body;
    my $html;
    if ( $self->{mailBody} ) {

        # We use a specific text message, no html
        $body = $self->{mailBody};
    }
    else {

        # Use HTML template
        my $tplfile = $self->getApacheHtdocsPath
          . "/skins/$self->{portalSkin}/mail_password.tpl";
        $tplfile =
          $self->getApacheHtdocsPath . "/skins/common/mail_password.tpl"
          unless ( -e $tplfile );
        my $template = HTML::Template->new(
            filename => $tplfile,
            filter   => sub { $self->translate_template(@_) }
        );
        $template->param( RESET => $self->{forceReset} );
        $body = $template->output();
        $html = 1;
    }

    # Replace variables in body
    my $password = $self->{newpassword};
    $body =~ s/\$password/$password/g;
    $body =~ s/\$(\w+)/$self->{sessionInfo}->{$1}/ge;

    # Send mail
    return PE_MAILERROR
      unless $self->send_mail( $self->{mailAddress}, $subject, $body, $html );

    PE_MAILOK;
}

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::MailReset - Manage password reset by mail

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::MailReset;
  
  my $portal = new Lemonldap::NG::Portal::MailReset();
 
  $portal->process();

  # Write here HTML to manage errors and confirmation messages

=head1 DESCRIPTION

Lemonldap::NG::Portal::MailReset enables password reset by mail

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

=item François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Sandro Cazzaniga, E<lt>cazzaniga.sandro@gmail.comE<gt>

=item Thomas Chemineau, E<lt>thomas.chemineau@gmail.comE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng/issues>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2010-2012 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2012 by Sandro Cazzaniga, E<lt>cazzaniga.sandro@gmail.comE<gt>

=item Copyright (C) 2012 by François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Copyright (C) 2010-2015 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item Copyright (C) 2011 by Thomas Chemineau, E<lt>thomas.chemineau@gmail.comE<gt>

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

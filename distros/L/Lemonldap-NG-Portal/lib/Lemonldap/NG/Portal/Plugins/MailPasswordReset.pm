package Lemonldap::NG::Portal::Plugins::MailPasswordReset;

use strict;
use Encode;
use Mouse;
use POSIX qw(strftime);
use Lemonldap::NG::Common::FormEncode;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_MAILOK
  PE_NOTOKEN
  PE_MAILERROR
  PE_PASSWORD_OK
  PE_BADMAILTOKEN
  PE_CAPTCHAEMPTY
  PE_CAPTCHAERROR
  PE_MAILNOTFOUND
  PE_TOKENEXPIRED
  PE_USERNOTFOUND
  PE_MAILCONFIRMOK
  PE_MALFORMEDUSER
  PE_MAILFORMEMPTY
  PE_BADCREDENTIALS
  PE_MAILFIRSTACCESS
  PE_PASSWORDFORMEMPTY
  PE_PASSWORD_MISMATCH
  PE_PASSWORDFIRSTACCESS
  PE_PP_PASSWORD_TOO_SHORT
  PE_PP_PASSWORD_TOO_YOUNG
  PE_PP_PASSWORD_IN_HISTORY
  PE_MAILCONFIRMATION_ALREADY_SENT
  PE_PP_INSUFFICIENT_PASSWORD_QUALITY
);

our $VERSION = '2.16.1';

extends qw(
  Lemonldap::NG::Portal::Lib::SMTP
  Lemonldap::NG::Portal::Main::Plugin
  Lemonldap::NG::Portal::Lib::_tokenRule
);

# PROPERTIES

# Reset URL to set in mail
has resetUrl => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = $_[0];
        my $p    = $self->conf->{portal};
        $p =~ s#/*$##;
        return $self->conf->{mailUrl} ? $self->conf->{mailUrl} : "$p/resetpwd";
    }
);

# Mail timeout token generator
# Form timout token generator (used even if requireToken is not set)
has ott => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $ott =
          $_[0]->{p}->loadModule('Lemonldap::NG::Portal::Lib::OneTimeToken');
        $ott->cache(0);
        $ott->timeout( $_[0]->conf->{formTimeout} || $_[0]->conf->{timeout} );
        return $ott;
    }
);

# Captcha generator
has captcha => ( is => 'rw' );

# Password policy activation rule
has passwordPolicyActivationRule => ( is => 'rw', default => sub { 0 } );

# INITIALIZATION

sub init {
    my ($self) = @_;

    # Declare REST route
    $self->addUnauthRoute( resetpwd => 'resetPwd', [ 'POST', 'GET' ] );

    # Initialize Captcha if needed
    if ( $self->conf->{captcha_mail_enabled} ) {
        $self->captcha(1);
    }

    # Parse password policy activation rule
    $self->passwordPolicyActivationRule(
        $self->p->buildRule(
            $self->conf->{passwordPolicyActivation},
            'passwordPolicyActivation'
        )
    );

    return $self->passwordPolicyActivationRule ? 1 : 0;
}

# RUNNIG METHODS

# Handle reset requests
sub resetPwd {
    my ( $self, $req ) = @_;

    $self->p->controlUrl($req);

    # Check parameters
    $req->error( $self->_reset($req) );

    # Display form
    my ( $tpl, $prms ) = $self->display($req);
    return $self->p->sendHtml( $req, $tpl, params => $prms );
}

sub _reset {
    my ( $self, $req ) = @_;
    my $mailToken;

    # PASSWORD CHANGE FORM => changePwd()
    return $self->changePwd($req)
      if (
        $req->method =~ /^POST$/i
        and (  $req->param('newpassword')
            or $req->param('confirmpassword')
            or $req->param('reset') )
      );

    # FIRST FORM
    $mailToken = $req->data->{mailToken} = $req->param('mail_token');
    unless ( $req->param('mail') || $mailToken ) {
        $self->setSecurity($req);
        return $req->method eq 'GET' ? PE_MAILFIRSTACCESS : PE_MAILFORMEMPTY;
    }

    # OTHER FORMS
    my $searchByMail = 1;
    if ($mailToken) {
        $self->logger->debug("Token given for password reset: $mailToken");

        # Check if token is valid
        my $mailSession =
          $self->p->getApacheSession( $mailToken, kind => "TOKEN" );
        unless ($mailSession) {
            $self->userLogger->warn('Bad reset token');
            return PE_BADMAILTOKEN;
        }

        $req->{user} = $mailSession->data->{user};
        $req->data->{mailAddress} =
          $mailSession->data->{ $self->conf->{mailSessionKey} };
        $self->logger->debug( 'User associated to: ' . $req->{user} );

        # Restore pdata if any
        $req->pdata( $mailSession->data->{_pdata} || {} );
        $searchByMail = 0 unless ( $req->{user} =~ /\@/ );
    }

    # Check for values posted
    else {

        # Use submitted value
        $req->{user} = $req->param('mail');

        # Captcha for register form
        if ( $self->captcha ) {
            my $result = $self->p->_captcha->check_captcha($req);
            if ($result) {
                $self->logger->debug("Captcha code verified");
            }
            else {
                $self->setSecurity($req);
                $self->userLogger->warn("Captcha failed");
                return PE_CAPTCHAERROR;
            }
        }
        elsif ( $self->ottRule->( $req, {} ) ) {
            my $token = $req->param('token');
            unless ($token) {
                $self->setSecurity($req);
                $self->userLogger->warn('Reset try without token');
                return PE_NOTOKEN;
            }
            unless ( $self->ott->getToken($token) ) {
                $self->setSecurity($req);
                $self->userLogger->warn('Reset try with expired/bad token');
                return PE_TOKENEXPIRED;
            }
        }

        unless ( $req->{user} =~ /$self->{conf}->{userControl}/o ) {
            $self->setSecurity($req);
            return PE_MALFORMEDUSER;
        }
    }

    # Search user in database
    $req->steps( [
            'getUser',                 'setSessionInfo',
            $self->p->groupsAndMacros, 'setPersistentSessionInfo',
            'setLocalGroups'
        ]
    );
    if ( my $error = $self->p->process( $req, useMail => $searchByMail ) ) {
        if ( $error == PE_USERNOTFOUND or $error == PE_BADCREDENTIALS ) {
            $self->userLogger->warn( 'Reset asked for an invalid user ('
                  . $req->param('mail')
                  . ')' );

            # To avoid mail enumeration, return OK
            # unless portalErrorOnMailNotFound is set

            if ( $self->conf->{portalErrorOnMailNotFound} ) {
                $self->setSecurity($req);
                return PE_MAILNOTFOUND;
            }

            my $mailTimeout =
              $self->conf->{mailTimeout} || $self->conf->{timeout};
            my $expTimestamp = time() + $mailTimeout;
            $req->data->{expMailDate} =
              strftime( '%d/%m/%Y', localtime $expTimestamp );
            $req->data->{expMailTime} =
              strftime( '%H:%M', localtime $expTimestamp );
            return PE_MAILCONFIRMOK;
        }
        return $error;
    }

    # Build temporary session
    my $mailSession = $self->getMailSession( $req->{user} );
    unless ( $mailSession or $mailToken ) {

        # Create a new session
        my $infos = {};

        # Set _utime for session autoremove
        # Use default session timeout and mail session timeout to compute it
        my $time        = time();
        my $timeout     = $self->conf->{timeout};
        my $mailTimeout = $self->conf->{mailTimeout} || $timeout;

        $infos->{_utime} = $time + ( $mailTimeout - $timeout );

        # Store expiration timestamp for further use
        $infos->{mailSessionTimeoutTimestamp} = $time + $mailTimeout;

        # Store start timestamp for further use
        $infos->{mailSessionStartTimestamp} = $time;

        # Store mail
        $infos->{ $self->conf->{mailSessionKey} } =
          $self->p->getFirstValue(
            $req->{sessionInfo}->{ $self->conf->{mailSessionKey} } );

        # Store user
        $infos->{user} = $req->{user};

        # Store type
        $infos->{_type} = 'mail';

        # Store pdata
        $infos->{_pdata} = $req->pdata;

        # create session
        $mailSession =
          $self->p->getApacheSession( undef, kind => "TOKEN", info => $infos );

        $req->id( $mailSession->id );
    }
    elsif ($mailSession) {
        $self->logger->debug( 'Mail session found: ' . $mailSession->id );
        $req->id( $mailSession->id );
        $req->data->{mailAlreadySent} = 1;
    }

    # Send confirmation mail
    unless ($mailToken) {

        # Mail session expiration date
        my $expTimestamp = $mailSession->data->{mailSessionTimeoutTimestamp};

        $self->logger->debug("Mail expiration timestamp: $expTimestamp");

        $req->data->{expMailDate} =
          strftime( '%d/%m/%Y', localtime $expTimestamp );
        $req->data->{expMailTime} =
          strftime( '%H:%M', localtime $expTimestamp );

        # Mail session start date
        my $startTimestamp = $mailSession->data->{mailSessionStartTimestamp};

        $self->logger->debug("Mail start timestamp: $startTimestamp");
        $req->data->{startMailDate} =
          strftime( '%d/%m/%Y', localtime $startTimestamp );
        $req->data->{startMailTime} =
          strftime( '%H:%M', localtime $startTimestamp );

        # Ask if user wants an another confirmation email
        if ( $req->data->{mailAlreadySent}
            and not $req->param('resendconfirmation') )
        {
            $self->userLogger->notice(
                'Reset mail already sent to ' . $req->{user} );

            # Return mail already sent only if it is allowed at previous step
            if ( $self->conf->{portalErrorOnMailNotFound} ) {
                $self->setSecurity($req);
                return PE_MAILCONFIRMATION_ALREADY_SENT;
            }
        }

        # Get mail address
        $req->data->{mailAddress} ||=
          $self->p->getFirstValue(
            $req->{sessionInfo}->{ $self->conf->{mailSessionKey} } );
        return PE_MAILERROR unless $req->data->{mailAddress};

        # Build confirmation url
        my $req_url = $req->data->{_url};
        my $skin    = $self->p->getSkin($req);
        my $url =
          $self->resetUrl . '?'
          . build_urlencoded(
            mail_token => $req->{id},
            skin       => $skin,
            ( $req_url ? ( url => $req_url ) : () ),
          );

        # Build mail content
        my $tr      = $self->translate($req);
        my $subject = $self->conf->{mailConfirmSubject};
        unless ($subject) {
            $subject = 'mailConfirmSubject';
            $tr->( \$subject );
        }
        my ( $body, $html );
        if ( $self->conf->{mailConfirmBody} ) {

            # We use a specific text message, no html
            $body = $self->conf->{mailConfirmBody};

            # Replace variables in body
            $body =~ s/\$expMailDate/$req->data->{expMailDate}/ge;
            $body =~ s/\$expMailTime/$req->data->{expMailTime}/ge;
            $body =~ s/\$url/$url/g;
            $body =~ s/\$(\w+)/$req->{sessionInfo}->{$1} || ''/ge;

        }
        else {

            # Use HTML template
            $body = $self->loadMailTemplate(
                $req,
                'mail_confirm',
                filter => $tr,
                params => {
                    expMailDate => $req->data->{expMailDate},
                    expMailTime => $req->data->{expMailTime},
                    url         => $url,
                },
            );
            $html = 1;
        }

        $self->logger->info( "User "
              . $req->data->{mailAddress}
              . " is trying to reset his/her password" );

        # Send mail
        $self->logger->debug('Unable to send reset mail')
          unless (
            $self->send_mail(
                $req->data->{mailAddress},
                $subject, $body, $html
            )
          );

        # Do not return an error here to avoid enumeration
        return PE_MAILCONFIRMOK;
    }

    # User has a valid mailToken, allow to change password
    # A token is required
    $self->ott->setToken(
        $req,
        {
            %{ $req->sessionInfo },
            pwdAllowed => $self->conf->{passwordResetAllowedRetries}
        }
    );
    return PE_PASSWORDFIRSTACCESS if ( $req->method eq 'GET' );
    return PE_PASSWORDFORMEMPTY;
}

sub changePwd {
    my ( $self, $req ) = @_;
    my %tplPrms;
    $self->logger->debug('Change password form response');

    if ( my $token = $req->param('token') ) {
        $req->sessionInfo( $self->ott->getToken($token) );
        unless ( $req->sessionInfo ) {
            $self->userLogger->warn(
                'User tries to change password with an invalid or expired token'
            );
            return PE_NOTOKEN;
        }
    }

    # These 2 cases means that a user tries to change password without
    # following valid links!!!
    else {
        $self->userLogger->error('User tries to change password without token');
        return PE_NOTOKEN;
    }

    unless ( $req->sessionInfo->{pwdAllowed}-- ) {
        $self->userLogger->error(
            'User tries to use another token to change a password');
        return PE_NOTOKEN;
    }

    # Remove the mail token session if mail token is provided
    my $mailToken = $req->param('mail_token');
    if ($mailToken) {
        $self->logger->debug("Token given for password reset: $mailToken");

        # Check if token is valid
        my $mailSession =
          $self->p->getApacheSession( $mailToken, kind => "TOKEN" );
        unless ($mailSession) {
            $self->userLogger->warn('Bad reset token');
            return PE_BADMAILTOKEN;
        }

        $self->logger->debug("Delete token $mailToken");
        $mailSession->remove;
    }

    # Check if user wants to generate the new password
    if ( $req->param('reset') ) {
        $self->logger->debug(
            "Reset password request for $req->{sessionInfo}->{_user}");

        # Generate a complex password
        my $pwdRegEx;
        if ( $self->passwordPolicyActivationRule->( $req, $req->sessionInfo )
            && !$self->conf->{randomPasswordRegexp} )
        {
            my $uppers = $self->conf->{passwordPolicyMinUpper} || 3;
            my $lowers = $self->conf->{passwordPolicyMinLower} || 5;
            my $digits = $self->conf->{passwordPolicyMinDigit} || 2;
            my $chars =
              $self->conf->{passwordPolicyMinSize} -
              $self->conf->{passwordPolicyMinUpper} -
              $self->conf->{passwordPolicyMinLower} -
              $self->conf->{passwordPolicyMinDigit};
            $chars    = 1 if $chars < 1;
            $pwdRegEx = "[A-Z]{$uppers}[a-z]{$lowers}\\d{$digits}";
            $pwdRegEx .=
              $self->conf->{passwordPolicySpecialChar} eq '__ALL__'
              ? '\W{$chars}'
              : "[$self->{conf}->{passwordPolicySpecialChar}]{$chars}";
            $self->logger->debug("Generated password RegEx: $pwdRegEx");
        }
        else {
            $pwdRegEx =
              $self->conf->{randomPasswordRegexp} || '[A-Z]{3}[a-z]{5}.\d{2}';
            $self->logger->debug("Used password RegEx: $pwdRegEx");
        }
        my $password = $self->gen_password($pwdRegEx);
        $self->logger->debug("Generated password: $password");
        $req->data->{newpassword}     = $password;
        $req->data->{confirmpassword} = $password;
        $req->data->{forceReset}      = 1;
        $tplPrms{RESET}               = 1;
    }

    # Else a password is required in request
    else {
        $req->data->{newpassword}     = $req->param('newpassword');
        $req->data->{confirmpassword} = $req->param('confirmpassword');
        unless ($req->data->{newpassword}
            and $req->data->{confirmpassword}
            and $req->data->{newpassword} eq $req->data->{confirmpassword} )
        {
            $self->ott->setToken( $req, $req->sessionInfo );
            ( $req->data->{newpassword} && $req->data->{confirmpassword} )
              ? return PE_PASSWORD_MISMATCH
              : return PE_PASSWORDFORMEMPTY;

        }
    }

    # Check password quality if enabled
    require Lemonldap::NG::Portal::Password::Base;
    my $cpq =
      $self->passwordPolicyActivationRule->( $req, $req->sessionInfo )
      ? $self->Lemonldap::NG::Portal::Password::Base::checkPasswordQuality(
        $req->data->{newpassword} )
      : PE_OK;
    unless ( $cpq == PE_OK ) {
        $self->ott->setToken( $req, $req->sessionInfo );
        return $cpq;
    }

    $req->user( $req->{sessionInfo}->{_user} );
    my $result =
      $self->p->_passwordDB->setNewPassword( $req,
        $req->data->{newpassword}, 1 );
    undef $req->{user};

    # Mail token can be used only one time, delete the session if all is ok
    unless ( $result == PE_PASSWORD_OK or $result == PE_OK ) {
        $self->ott->setToken( $req, $req->sessionInfo );
        return $result;
    }

    my $userlog = $req->sessionInfo->{ $self->conf->{whatToTrace} };
    my $iplog   = $req->sessionInfo->{ipAddr};
    $self->userLogger->notice("Password changed for $userlog ($iplog)")
      if ( defined $userlog and $iplog );

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
                %tplPrms, password => $password,
            },
        );
        $html = 1;
    }

    # Send mail
    return $self->send_mail( $req->data->{mailAddress}, $subject, $body, $html )
      ? PE_MAILOK
      : PE_MAILERROR;
}

sub setSecurity {
    my ( $self, $req ) = @_;
    if ( $self->captcha ) {
        $self->p->_captcha->init_captcha($req);
    }
    elsif ( $self->ottRule->( $req, {} ) ) {
        $self->ott->setToken($req);
    }
    return 1;
}

sub display {
    my ( $self, $req ) = @_;
    my $speChars =
      $self->conf->{passwordPolicySpecialChar} eq '__ALL__'
      ? ''
      : $self->conf->{passwordPolicySpecialChar};
    $speChars =~ s/\s+/ /g;
    $speChars =~ s/(?:^\s|\s$)//g;
    my $isPP =
         $self->conf->{passwordPolicyMinSize}
      || $self->conf->{passwordPolicyMinLower}
      || $self->conf->{passwordPolicyMinUpper}
      || $self->conf->{passwordPolicyMinDigit}
      || $self->conf->{passwordPolicyMinSpeChar}
      || $speChars;
    $self->logger->debug( 'Display called with code: ' . $req->error );

    my %tplPrm = (
        AUTH_ERROR      => $req->error,
        AUTH_ERROR_TYPE => $req->error_type,
        AUTH_ERROR_ROLE => $req->error_role,
        AUTH_URL        => $req->data->{_url},
        CHOICE_VALUE    => $req->{_authChoice},
        EXPMAILDATE     => $req->data->{expMailDate},
        EXPMAILTIME     => $req->data->{expMailTime},
        STARTMAILDATE   => $req->data->{startMailDate},
        STARTMAILTIME   => $req->data->{startMailTime},
        MAILALREADYSENT => $req->data->{mailAlreadySent},
        (
            $req->data->{customScript}
            ? ( CUSTOM_SCRIPT => $req->data->{customScript} )
            : ()
        ),
        MAIL => (
              $self->p->checkXSSAttack( 'mail', $req->{user} ) ? ''
            : $req->{user}
        ),
        DISPLAY_FORM            => 0,
        DISPLAY_RESEND_FORM     => 0,
        DISPLAY_CONFIRMMAILSENT => 0,
        DISPLAY_MAILSENT        => 0,
        DISPLAY_PASSWORD_FORM   => 0,
        ENABLE_PASSWORD_DISPLAY => $self->conf->{portalEnablePasswordDisplay},
        ENABLE_CHECKHIBP        => $self->conf->{checkHIBP},
        DONT_STORE_PASSWORD     => $self->conf->{browsersDontStorePassword},
        DISPLAY_PPOLICY  => $self->conf->{portalDisplayPasswordPolicy} && $isPP,
        PPOLICY_MINSIZE  => $self->conf->{passwordPolicyMinSize},
        PPOLICY_MINLOWER => $self->conf->{passwordPolicyMinLower},
        PPOLICY_MINUPPER => $self->conf->{passwordPolicyMinUpper},
        PPOLICY_MINDIGIT => $self->conf->{passwordPolicyMinDigit},
        PPOLICY_MINSPECHAR        => $self->conf->{passwordPolicyMinSpeChar},
        PPOLICY_ALLOWEDSPECHAR    => $speChars,
        DISPLAY_GENERATE_PASSWORD =>
          $self->conf->{portalDisplayGeneratePassword},
    );
    if ( $req->data->{mailToken}
        and
        not $self->p->checkXSSAttack( 'mail_token', $req->data->{mailToken} ) )
    {
        $tplPrm{MAIL_TOKEN} = $req->data->{mailToken};
    }

    # Display captcha if enabled
    $tplPrm{CAPTCHA_HTML} = $req->captchaHtml if ( $req->captchaHtml );
    $tplPrm{TOKEN}        = $req->token       if $req->token;

    # DEPRECATED: This is only used for compatibility with existing templates
    if ( $req->captcha ) {
        $tplPrm{CAPTCHA_SRC}  = $req->captcha;
        $tplPrm{CAPTCHA_SIZE} = $self->conf->{captcha_size};
    }

    # Display form the first time
    if ( (
               $req->error == PE_MAILFORMEMPTY
            or $req->error == PE_MAILFIRSTACCESS
            or $req->error == PE_MAILNOTFOUND
            or $req->error == PE_CAPTCHAERROR
            or $req->error == PE_CAPTCHAEMPTY
        )
        and not $req->data->{mailToken}
      )
    {
        $self->logger->debug('Display form');
        $tplPrm{DISPLAY_FORM} = 1;
    }

    # Display mail confirmation resent form
    elsif ( $req->error == PE_MAILCONFIRMATION_ALREADY_SENT ) {
        $self->logger->debug('Display resend form');
        $tplPrm{DISPLAY_RESEND_FORM} = 1;
    }

    # Display confirmation mail sent
    elsif ( $req->error == PE_MAILCONFIRMOK ) {
        $self->logger->debug('Display "confirm mail sent"');
        $tplPrm{DISPLAY_CONFIRMMAILSENT} = 1;
    }

    # Display mail sent
    elsif ( $req->error == PE_MAILOK ) {
        $self->logger->debug('Display "mail sent"');
        $tplPrm{DISPLAY_MAILSENT} = 1;
    }

    # Display password change form
    elsif ( $req->data->{mailToken}
        and $req->error != PE_MAILERROR
        and $req->error != PE_BADMAILTOKEN
        and $req->error != PE_MAILOK )
    {
        $self->logger->debug('Display password form');
        $tplPrm{DISPLAY_PASSWORD_FORM} = 1;
    }

    # Display password change form again
    # - if passwords mismatch
    # - if password quality check fail
    elsif ($req->error == PE_PASSWORDFORMEMPTY
        || $req->error == PE_PASSWORD_MISMATCH
        || $req->error == PE_PP_INSUFFICIENT_PASSWORD_QUALITY
        || $req->error == PE_PP_PASSWORD_TOO_SHORT
        || $req->error == PE_PP_PASSWORD_TOO_YOUNG
        || $req->error == PE_PP_PASSWORD_IN_HISTORY )
    {
        $self->logger->debug('Display password form');
        $tplPrm{DISPLAY_PASSWORD_FORM} = $req->sessionInfo->{pwdAllowed};
    }

    return 'mail', \%tplPrm;
}

1;

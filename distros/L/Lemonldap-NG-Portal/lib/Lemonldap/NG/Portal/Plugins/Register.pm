package Lemonldap::NG::Portal::Plugins::Register;

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
  PE_BADMAILTOKEN
  PE_CAPTCHAEMPTY
  PE_CAPTCHAERROR
  PE_TOKENEXPIRED
  PE_MAILCONFIRMOK
  PE_MALFORMEDUSER
  PE_REGISTERFORMEMPTY
  PE_REGISTERFIRSTACCESS
  PE_REGISTERALREADYEXISTS
  PE_MAILCONFIRMATION_ALREADY_SENT
);

our $VERSION = '2.0.15';

extends qw(
  Lemonldap::NG::Portal::Lib::SMTP
  Lemonldap::NG::Portal::Main::Plugin
  Lemonldap::NG::Portal::Lib::_tokenRule
);

# PROPERTIES

# Sub module (Demo, LDAP,...)
has registerModule => ( is => 'rw' );

# Register url to set in the mail
has registerUrl => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $p = $_[0]->conf->{portal};
        $p =~ s#/*$##;
        return "$p/register";
    }
);

# Mail timeout token generator
has mailott => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $ott =
          $_[0]->{p}->loadModule('Lemonldap::NG::Portal::Lib::OneTimeToken');
        $ott->cache(0);
        $ott->timeout( $_[0]->conf->{registerTimeout}
              || $_[0]->conf->{timeout} );
        return $ott;
    }
);

# Form timout token generator (used if requireToken is set)
has ott => ( is => 'rw' );

# Captcha generator
has captcha => ( is => 'rw' );

# INITIALIZATION

sub init {
    my ($self) = @_;

    # Declare REST route
    $self->addUnauthRoute( register => 'register', [ 'POST', 'GET' ] );

    # Initialize Captcha if needed
    if ( $self->conf->{captcha_register_enabled} ) {
        $self->captcha(1);
    }

    # Initialize form token if needed (captcha provides also a token)
    else {
        $_[0]->ott(
            $_[0]->p->loadModule('Lemonldap::NG::Portal::Lib::OneTimeToken') )
          or return 0;
        $_[0]->ott->timeout( $_[0]->conf->{formTimeout} );
    }

    # Load registered module
    $self->registerModule(
        $self->p->loadPlugin( '::Register::' . $self->conf->{registerDB} ) )
      or return 0;

    return 1;
}

# RUNNIG METHODS

# Handle register requests
sub register {
    my ( $self, $req ) = @_;

    $self->p->controlUrl($req);

    # Check parameters
    $req->error( $self->_register($req) );

    # Display form
    my ( $tpl, $prms ) = $self->display($req);
    return $self->p->sendHtml( $req, $tpl, params => $prms );
}

# Parameters check
sub _register {
    my ( $self, $req ) = @_;

    # Check if it's a first access
    unless ( ( $req->method =~ /^POST$/i and $req->param('mail') )
        or $req->param('register_token') )
    {

        # Set captcha or token
        $self->setSecurity($req);
        $self->logger->debug('First access to register form');
        return PE_REGISTERFIRSTACCESS if ( $req->method eq 'GET' );
        return PE_REGISTERFORMEMPTY;
    }

    # Get register token (mail link)
    $req->data->{register_token} = $req->param('register_token');

    # If a register token is present, find the corresponding info
    if ( $req->data->{register_token} ) {

        $self->logger->debug(
            "Token provided for register: " . $req->data->{register_token} );

        # Get the corresponding session
        if ( my $data =
            $self->mailott->getToken( $req->data->{register_token} ) )
        {
            $self->logger->debug(
                'Token ' . $req->data->{register_token} . ' found' );
            foreach (qw(mail firstname lastname ipAddr)) {
                $req->data->{registerInfo}->{$_} = $data->{$_};
            }
            $self->logger->debug( "User associated to token: "
                  . $req->data->{registerInfo}->{mail} );
        }
        else {
            return PE_BADMAILTOKEN;
        }
    }

    # Case else: user tries to register
    else {

        # Use submitted value
        $req->data->{registerInfo}->{mail}      = $req->param('mail');
        $req->data->{registerInfo}->{firstname} = $req->param('firstname');
        $req->data->{registerInfo}->{lastname}  = $req->param('lastname');
        $req->data->{registerInfo}->{ipAddr}    = $req->address;

        # Check captcha/token only if register session does not already exist
        if ( $req->data->{registerInfo}->{mail}
            and
            !$self->getRegisterSession( $req->data->{registerInfo}->{mail} ) )
        {

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
                    $self->userLogger->warn('Register try without token');
                    return PE_NOTOKEN;
                }
                unless ( $self->ott->getToken($token) ) {
                    $self->setSecurity($req);
                    $self->userLogger->warn(
                        'Register try with expired/bad token');
                    return PE_TOKENEXPIRED;
                }
            }
        }
    }

    # Check mail
    return PE_MALFORMEDUSER
      unless ( $req->data->{registerInfo}->{mail} =~
        m/$self->{conf}->{userControl}/o );

    # Search for user using UserDB module
    # If the user already exists, register is forbidden
    $req->user( $req->data->{registerInfo}->{mail} );
    if ( $self->p->_userDB->getUser( $req, useMail => 1 ) == PE_OK ) {
        $self->userLogger->error(
"Register: refuse mail $req->{data}->{registerInfo}->{mail} because already exists in UserDB"
        );
        return PE_REGISTERALREADYEXISTS;
    }
    my $register_session =
      $self->getRegisterSession( $req->data->{registerInfo}->{mail} );
    $req->data->{mail_already_sent} =
      ( $register_session and !$req->id ) ? 1 : 0;

    # Skip this step if confirmation was already sent
    unless ( $req->data->{register_token} or $register_session ) {

        # Create mail token
        $register_session = $self->mailott->createToken( {
                mail      => $req->data->{registerInfo}->{mail},
                firstname => $req->data->{registerInfo}->{firstname},
                lastname  => $req->data->{registerInfo}->{lastname},
                ipAddr    => $req->data->{registerInfo}->{ipAddr},
                _type     => 'register',
            }
        );
        $self->logger->debug("Token $register_session created");
    }

    # Send confirmation mail

    # Skip this step if user clicked on the confirmation link
    unless ( $req->data->{register_token} ) {

        # Check if confirmation mail has already been sent
        $self->logger->debug('No register_token');

        # Read session to get creation and expiration dates
        $req->id($register_session) unless $req->id;

        $self->logger->debug("Register session found: $register_session");

        # Mail session expiration date
        my $expTimestamp =
          ( $self->conf->{registerTimeout} || $self->conf->{timeout} ) + time;

        $self->logger->debug("Register expiration timestamp: $expTimestamp");

        $req->data->{expMailDate} =
          strftime( "%d/%m/%Y", localtime $expTimestamp );
        $req->data->{expMailTime} =
          strftime( "%H:%M", localtime $expTimestamp );

        # Mail session start date
        my $startTimestamp = time;

        $self->logger->debug("Register start timestamp: $startTimestamp");

        $req->data->{startMailDate} =
          strftime( "%d/%m/%Y", localtime $startTimestamp );
        $req->data->{startMailTime} =
          strftime( "%H:%M", localtime $startTimestamp );

        # Ask if user want another confirmation email
        if ( $req->data->{mail_already_sent}
            and !$req->param('resendconfirmation') )
        {
            return PE_MAILCONFIRMATION_ALREADY_SENT;
        }

        # Build confirmation url
        my $req_url = $req->data->{_url};
        my $skin    = $self->p->getSkin($req);
        my $url =
          $self->registerUrl . '?'
          . build_urlencoded(
            register_token => $req->{id},
            skin           => $skin,
            ( $req_url ? ( url => $req_url ) : () ),
          );

        # Build mail content
        my $tr      = $self->translate($req);
        my $subject = $self->conf->{registerConfirmSubject};
        unless ($subject) {
            $self->logger->debug('Use default confirm subject');
            $subject = 'registerConfirmSubject';
            $tr->( \$subject );
        }
        my ( $body, $html );
        if ( $self->conf->{registerConfirmBody} ) {

            # We use a specific text message, no html
            $self->logger->debug('Use specific confirm body message');
            $body = $self->conf->{registerConfirmBody};

            # Replace variables in body
            $body =~ s/\$url/$url/g;
            $body =~ s/\$expMailDate/$req->{data}->{expMailDate}/g;
            $body =~ s/\$expMailTime/$req->{data}->{expMailTime}/g;
            $body =~ s/\$(\w+)/$req->{data}->{registerInfo}->{$1} || ''/ge;
        }
        else {

            # Use HTML template
            $self->logger->debug('Use default confirm HTML template body');
            $body = $self->loadMailTemplate(
                $req,
                'mail_register_confirm',
                filter => $tr,
                params => {
                    expMailDate => $req->data->{expMailDate},
                    expMailTime => $req->data->{expMailTime},
                    url         => $url,
                    %{ $req->data->{registerInfo} || {} },
                },
            );
            $html = 1;
        }

        # Send mail
        return PE_MAILERROR
          unless $self->send_mail( $req->data->{registerInfo}->{mail},
            $subject, $body, $html );

        $self->logger->debug('Register message sent');
        return PE_MAILCONFIRMOK;
    }

    # Generate a complex password
    my $password = $self->gen_password( $self->conf->{randomPasswordRegexp} );

    $self->logger->debug( "Generated password: " . $password );

    $req->data->{registerInfo}->{password} = $password;
    $req->data->{forceReset} = 1;

    # Find a login
    my $result = $self->registerModule->computeLogin($req);
    unless ( $result == PE_OK ) {
        $self->logger->error( "Could not compute login for "
              . $req->data->{registerInfo}->{mail} );
        return $result;
    }

    # Create user
    $self->logger->debug(
        'Create new user ' . $req->data->{registerInfo}->{login} );
    $result = $self->registerModule->createUser($req);
    unless ( $result == PE_OK ) {
        $self->logger->error(
            "Could not create user " . $req->data->{registerInfo}->{login} );
        return $result;
    }

    # Build portal url
    my $url = $self->conf->{portal};
    $url =~ s#/*$##;
    my $req_url = $req->data->{_url};
    my $skin    = $self->p->getSkin($req);
    $url .= '/?'
      . build_urlencoded(
        skin => $skin,
        ( $req_url ? ( url => $req_url ) : () ),
      );

    # Build mail content
    my $tr      = $self->translate($req);
    my $subject = $self->conf->{registerDoneSubject};
    unless ($subject) {
        $self->logger->debug('Use default done subject');
        $subject = 'registerDoneSubject';
        $tr->( \$subject );
    }
    my ( $body, $html );
    if ( $self->conf->{registerDoneBody} ) {

        # We use a specific text message, no html
        $self->logger->debug('Use specific done body message');
        $body = $self->conf->{registerDoneBody};

        # Replace variables in body
        $body =~ s/\$url/$url/g;
        $body =~ s/\$(\w+)/$req->{data}->{registerInfo}->{$1} || ''/ge;
    }
    else {

        # Use HTML template
        $self->logger->debug('Use default done HTML template body');
        $body = $self->loadMailTemplate(
            $req,
            'mail_register_done',
            filter => $tr,
            params => {
                url => $url,
                %{ $req->data->{registerInfo} || {} },
            },
        );
        $html = 1;
    }

    # Send mail
    return PE_MAILERROR
      unless $self->send_mail( $req->data->{registerInfo}->{mail},
        $subject, $body, $html );

    return PE_MAILOK;
}

sub display {
    my ( $self, $req ) = @_;
    my %templateParams = (
        SKIN_PATH       => $self->conf->{staticPrefix},
        SKIN            => $self->p->getSkin($req),
        SKIN_BG         => $self->conf->{portalSkinBackground},
        MAIN_LOGO       => $self->conf->{portalMainLogo},
        AUTH_ERROR      => $req->error,
        AUTH_ERROR_TYPE => $req->error_type,
        AUTH_ERROR_ROLE => $req->error_role,
        AUTH_URL        => $req->data->{_url},
        CHOICE_PARAM    => $self->conf->{authChoiceParam},
        CHOICE_VALUE    => $req->data->{_authChoice},
        EXPMAILDATE     => $req->data->{expMailDate},
        EXPMAILTIME     => $req->data->{expMailTime},
        STARTMAILDATE   => $req->data->{startMailDate},
        STARTMAILTIME   => $req->data->{startMailTime},
        MAILALREADYSENT => $req->data->{mail_already_sent},
        (
            $req->data->{customScript}
            ? ( CUSTOM_SCRIPT => $req->data->{customScript} )
            : ()
        ),
        MAIL => $self->p->checkXSSAttack(
            'mail', $req->data->{registerInfo}->{mail}
          ) ? ""
        : $req->data->{registerInfo}->{mail},
        FIRSTNAME => $self->p->checkXSSAttack( 'firstname',
            $req->data->{registerInfo}->{firstname} ) ? ""
        : $req->data->{registerInfo}->{firstname},
        LASTNAME => $self->p->checkXSSAttack( 'lastname',
            $req->data->{registerInfo}->{lastname} ) ? ""
        : $req->data->{registerInfo}->{lastname},
        REGISTER_TOKEN => $self->p->checkXSSAttack( 'register_token',
            $req->data->{register_token} ) ? ""
        : $req->data->{register_token},
    );

    # Display form the first time
    if ( (
               $req->error == PE_REGISTERFORMEMPTY
            or $req->error == PE_REGISTERFIRSTACCESS
            or $req->error == PE_CAPTCHAERROR
            or $req->error == PE_CAPTCHAEMPTY
            or $req->error == PE_NOTOKEN
            or $req->error == PE_TOKENEXPIRED
        )
        and !$req->param('mail_token')
      )
    {
        %templateParams = (
            %templateParams,
            DISPLAY_FORM            => 1,
            DISPLAY_RESEND_FORM     => 0,
            DISPLAY_CONFIRMMAILSENT => 0,
            DISPLAY_MAILSENT        => 0,
            DISPLAY_PASSWORD_FORM   => 0,
        );
    }

    # Display captcha if it's enabled
    if ( $req->captchaHtml ) {
        $templateParams{CAPTCHA_HTML} = $req->captchaHtml;
    }
    if ( $req->token ) {
        $templateParams{TOKEN} = $req->token;
    }

    # DEPRECATED: This is only used for compatibility with existing templates
    if ( $req->captcha ) {
        $templateParams{CAPTCHA_SRC}  = $req->captcha;
        $templateParams{CAPTCHA_SIZE} = $self->conf->{captcha_size};
    }

    if ( $req->error == PE_REGISTERALREADYEXISTS ) {
        %templateParams = (
            %templateParams,
            DISPLAY_FORM            => 0,
            DISPLAY_RESEND_FORM     => 0,
            DISPLAY_CONFIRMMAILSENT => 0,
            DISPLAY_MAILSENT        => 0,
            DISPLAY_PASSWORD_FORM   => 0,
        );
    }

    # Display mail confirmation resent form
    if ( $req->{error} == PE_MAILCONFIRMATION_ALREADY_SENT ) {
        %templateParams = (
            %templateParams,
            DISPLAY_FORM            => 0,
            DISPLAY_RESEND_FORM     => 1,
            DISPLAY_CONFIRMMAILSENT => 0,
            DISPLAY_MAILSENT        => 0,
            DISPLAY_PASSWORD_FORM   => 0,
        );
    }

    # Display confirmation mail sent
    if ( $req->{error} == PE_MAILCONFIRMOK ) {
        %templateParams = (
            %templateParams,
            DISPLAY_FORM            => 0,
            DISPLAY_RESEND_FORM     => 0,
            DISPLAY_CONFIRMMAILSENT => 1,
            DISPLAY_MAILSENT        => 0,
            DISPLAY_PASSWORD_FORM   => 0,
        );
    }

    # Display mail sent
    if ( $req->{error} == PE_MAILOK ) {
        %templateParams = (
            %templateParams,
            DISPLAY_FORM            => 0,
            DISPLAY_RESEND_FORM     => 0,
            DISPLAY_CONFIRMMAILSENT => 0,
            DISPLAY_MAILSENT        => 1,
            DISPLAY_PASSWORD_FORM   => 0,
        );
    }

    # Display password change form
    if (    $req->param('mail_token')
        and $req->{error} != PE_MAILERROR
        and $req->{error} != PE_BADMAILTOKEN
        and $req->{error} != PE_MAILOK )
    {
        %templateParams = (
            %templateParams,
            DISPLAY_FORM            => 0,
            DISPLAY_RESEND_FORM     => 0,
            DISPLAY_CONFIRMMAILSENT => 0,
            DISPLAY_MAILSENT        => 0,
            DISPLAY_PASSWORD_FORM   => 1,
        );
    }

    return ( 'register', \%templateParams );
}

sub setSecurity {
    my ( $self, $req ) = @_;
    if ( $self->captcha ) {
        $self->p->_captcha->init_captcha($req);
    }
    elsif ( $self->ottRule->( $req, {} ) ) {
        $self->ott->setToken($req);
    }
}

1;

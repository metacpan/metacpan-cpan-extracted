package Lemonldap::NG::Portal::Plugins::CertificateResetByMail;

use strict;
use Encode;
use Mouse;
use Net::SSLeay;
use DateTime::Format::RFC3339;
use Digest::SHA qw(sha256_hex);
use MIME::Base64;
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
  PE_MAILNOTFOUND
  PE_TOKENEXPIRED
  PE_USERNOTFOUND
  PE_MAILCONFIRMOK
  PE_MAILFORMEMPTY
  PE_MALFORMEDUSER
  PE_BADCREDENTIALS
  PE_MAILFIRSTACCESS
  PE_RESETCERTIFICATE_INVALID
  PE_RESETCERTIFICATE_FORMEMPTY
  PE_RESETCERTIFICATE_FIRSTACCESS
  PE_MAILCONFIRMATION_ALREADY_SENT
);

our $VERSION = '2.0.15';

extends qw(
  Lemonldap::NG::Portal::Lib::SMTP
  Lemonldap::NG::Portal::Main::Plugin
  Lemonldap::NG::Portal::Lib::_tokenRule
);

# PROPERTIES

# Mail timeout token generator
# Form timout token generator (used even if requireToken is not set)
has ott => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $ott =
          $_[0]->{p}->loadModule('Lemonldap::NG::Portal::Lib::OneTimeToken');
        $ott->timeout( $_[0]->conf->{formTimeout} );
        return $ott;
    }
);

# Sub module (Demo, LDAP,...)
has registerModule => ( is => 'rw' );

# Captcha generator
has captcha => ( is => 'rw' );

# certificate reset url
has certificateResetUrl => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $p = $_[0]->conf->{portal};
        $p =~ s#/*$##;
        return "$p/certificateReset";
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

# INITIALIZATION

sub init {
    my ($self) = @_;

    # Declare REST route
    $self->addUnauthRoute(
        certificateReset => 'certificateReset',
        [ 'POST', 'GET' ]
    );

    # Initialize Captcha if needed
    if ( $self->conf->{captcha_mail_enabled} ) {
        $self->captcha(1);
    }

    # Load registered module
    $self->registerModule(
        $self->p->loadPlugin(
            '::CertificateResetByMail::' . $self->conf->{registerDB}
        )
    ) or return 0;

    return 1;
}

# RUNNIG METHODS

# Handle reset requests
sub certificateReset {
    my ( $self, $req ) = @_;

    $self->p->controlUrl($req);

    # Check parameters
    $req->error( $self->_certificateReset($req) );

    # Display form
    my ( $tpl, $prms ) = $self->display($req);
    return $self->p->sendHtml( $req, $tpl, params => $prms );
}

sub _certificateReset {
    my ( $self, $req ) = @_;
    my ($mailToken);

    # CertificatReset FORM => modifyCertificate()
    if ( $req->method =~ /^POST$/i
        and ( $req->uploads->{certif} ) )
    {
        my $upload = $req->uploads->{certif};

        return $self->modifyCertificate($req);
    }

    # FIRST FORM
    $mailToken = $req->data->{mailToken} = $req->param('mail_token');
    unless ( $req->param('mail') || $mailToken ) {
        $self->setSecurity($req);
        return PE_MAILFIRSTACCESS if ( $req->method eq 'GET' );
        return PE_MAILFORMEMPTY;
    }

    my $searchByMail = 1;

    # OTHER FORMS
    if ($mailToken) {
        $self->logger->debug("Token given for certificate reset: $mailToken");

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
        $mailSession->remove;
        $searchByMail = 0 unless ( $req->{user} =~ /\@/ );
    }

    # Check for posted values
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
    my $mailSession = $self->getCertificateSession( $req->{user} );
    unless ( $mailSession or $mailToken ) {

        ## Create a new session
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
        $infos->{_type} = 'certificate';

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
        return PE_MAILERROR unless ( $req->data->{mailAddress} );

        # Build confirmation url
        my $req_url = $req->data->{_url};
        my $skin    = $self->p->getSkin($req);
        my $url =
          $self->certificateResetUrl . '?'
          . build_urlencoded(
            mail_token => $req->{id},
            skin       => $skin,
            ( $req_url ? ( url => $req_url ) : () ),
          );

        # Build mail content
        my $tr      = $self->translate($req);
        my $subject = $self->conf->{certificateResetByMailStep1Subject};
        unless ($subject) {
            $subject = 'certificateResetByMailStep1Subject';
            $tr->( \$subject );
        }
        my $body;
        my $html;
        if ( $self->conf->{certificateResetByMailStep1Body} ) {

            # We use a specific text message, no html
            $body = $self->conf->{certificateResetByMailStep1Body};

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
                'mail_certificateConfirm',
                filter => $tr,
                params => {
                    expMailDate => $req->data->{expMailDate},
                    expMailTime => $req->data->{expMailTime},
                    url         => $url,
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
            $self->logger->debug('Unable to send reset mail');

            # Don't return an error here to avoid enumeration
        }
        return PE_MAILCONFIRMOK;
    }

    # User has a valid mailToken, allow to reset certificate
    # A token is required
    $self->ott->setToken(
        $req,
        {
            %{ $req->sessionInfo }, certificateResetAllowed => 1
        }
    );
    return PE_RESETCERTIFICATE_FIRSTACCESS if ( $req->method eq 'GET' );
    return PE_RESETCERTIFICATE_FORMEMPTY;
}

sub modifyCertificate {
    my ( $self, $req ) = @_;
    my $nbio;
    my $x509;
    my $notAfter;

    $self->logger->debug('Change your certificate form response');

    if ( my $token = $req->param('token') ) {
        $req->sessionInfo( $self->ott->getToken($token) );
        unless ( $req->sessionInfo ) {
            $self->userLogger->warn(
'User tries to change certificate with an invalid or expired token'
            );
            return PE_NOTOKEN;
        }
    }

    # These 2 cases means that a user tries to reset certificate without
    # following valid links!!!
    else {
        $self->userLogger->error(
            'User tries to reset certificate without token');
        return PE_NOTOKEN;
    }

    unless ( $req->sessionInfo->{certificateResetAllowed} ) {
        $self->userLogger->error(
            'User tries to use another token to reset certificate');
        return PE_NOTOKEN;
    }

    #Updload certificate
    my $upload = $req->uploads->{certif};
    return PE_RESETCERTIFICATE_FORMEMPTY unless ( $upload->size > 0 );

    # Get certificate
    my $file = $upload->path;
    $self->userLogger->debug( "Temporaly file " . $file );

    # Convert certificate file uploaded on DER format with openssl library

    #my $certifbase64 =`openssl x509 -outform der -in $file -out $file`;

    # load certificate from file with openssl library
    $nbio = Net::SSLeay::BIO_new_file( $file, 'r' ) or die $!;

    # for PEM certificate
    $x509 = Net::SSLeay::PEM_read_bio_X509($nbio);

    Net::SSLeay::BIO_free($nbio);
    unless ($x509) {
        $self->userLogger->debug( "Unable to decode certificate for user  "
              . Net::SSLeay::ERR_error_string( Net::SSLeay::ERR_get_error() ) );
        return PE_RESETCERTIFICATE_INVALID;
    }
    $self->userLogger->debug("Certificate successfully decoded");
    $notAfter = Net::SSLeay::P_ASN1_TIME_get_isotime(
        Net::SSLeay::X509_get_notAfter($x509) );

    my $x509issuer = Net::SSLeay::X509_NAME_oneline(
        Net::SSLeay::X509_get_issuer_name($x509) );

    my $x509serial = Net::SSLeay::P_ASN1_INTEGER_get_hex(
        Net::SSLeay::X509_get_serialNumber($x509) );

    $self->userLogger->debug(
"Certificate will expire after $notAfter, Issuer $x509issuer and serialNumber $x509serial"
    );

    # Check certificate validity before store
    if (
        $self->checkCertificateValidity( $notAfter,
            $self->conf->{certificateResetByMailValidityDelay} ) == 0
      )
    {
        $self->userLogger->debug(
"Your certificate is no longer valid in $self->conf->{certificateValidityDelay}"
        );
        return PE_RESETCERTIFICATE_INVALID;
    }

    # Build serial number hex: example f3:08:52:63:28:29:fa:e2
    my @numberstring = split //, lc($x509serial);
    my $serial       = "";
    for ( my $i = 0 ; $i <= $#numberstring ; $i += 2 ) {
        $serial = $serial . $numberstring[$i] . $numberstring[ $i + 1 ];
        if ( $i + 2 < $#numberstring ) { $serial = $serial . ":"; }
    }

# format issuer in the good format example "CN=CA,OU=CISIRH,O=MINEFI,L=Paris,ST=France,C=FR"
    my @issuertab = split /\//, $x509issuer;
    shift(@issuertab);
    my $issuer = join( ",", reverse(@issuertab) );

    #$issuer = lc($issuer);

    my $certificatExactAssertion =
      '{ serialNumber ' . $serial . ', issuer rdnSequence:"' . $issuer . '" }';
    $self->userLogger->debug( "Description::  " . $certificatExactAssertion );

    # Get attribut userCertificate;binary  value
    my $cert = $self->certificateHash($file);

    # Modify ldap certificate attribute
    $req->user( $req->{sessionInfo}->{_user} );
    my $result =
      $self->registerModule->modifCertificate( $req, $certificatExactAssertion,
        $cert );
    $self->{user} = undef;

    # Mail token can be used only one time, delete the session if all is ok
    return $result unless ( $result == PE_OK );

    # Send mail to notify the certificate has been successfully reset
    $req->data->{mailAddress} ||=
      $self->p->getFirstValue(
        $req->{sessionInfo}->{ $self->conf->{mailSessionKey} } );

    # Build mail content
    my $tr      = $self->translate($req);
    my $subject = $self->conf->{certificateResetByMailStep2Subject};
    unless ($subject) {
        $subject = 'certificateResetByMailStep2Subject';
        $tr->( \$subject );
    }
    my $body;
    my $html;
    if ( $self->conf->{certificateResetByMailStep2Body} ) {

        # We use a specific text message, no html
        $body = $self->conf->{certificateResetByMailStep2Body};

        # Replace variables in body
        $body =~ s/\$(\w+)/$req->{sessionInfo}->{$1} || ''/ge;

    }
    else {

        # Use HTML template
        $body = $self->loadMailTemplate(
            $req,
            'mail_certificateReset',
            filter => $tr,
            params => {},
        );
        $html = 1;
    }

    # Send mail
    return PE_MAILERROR
      unless $self->send_mail( $req->data->{mailAddress}, $subject, $body,
        $html );

    return PE_MAILOK;
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
    $self->logger->debug( 'Display called with code: ' . $req->error );
    my %tplPrm = (
        SKIN_PATH       => $self->conf->{staticPrefix},
        SKIN            => $self->p->getSkin($req),
        SKIN_BG         => $self->conf->{portalSkinBackground},
        MAIN_LOGO       => $self->conf->{portalMainLogo},
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
        DISPLAY_CERTIF_FORM     => 0,
    );
    if ( $req->data->{mailToken}
        and
        not $self->p->checkXSSAttack( 'mail_token', $req->data->{mailToken} ) )
    {
        $tplPrm{MAIL_TOKEN} = $req->data->{mailToken};
    }

    # Display captcha if enabled
    if ( $req->captchaHtml ) {
        $tplPrm{CAPTCHA_HTML} = $req->captchaHtml;
    }
    if ( $req->token ) {
        $tplPrm{TOKEN} = $req->token;
    }

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

    # Display certificate reset form
    elsif ( $req->data->{mailToken}
        and $req->error != PE_MAILERROR
        and $req->error != PE_BADMAILTOKEN
        and $req->error != PE_MAILOK )
    {
        $self->logger->debug('Display certificate reset form');
        $tplPrm{DISPLAY_CERTIF_FORM} = 1;
    }

    # Display certificate reset form again if certificate invalid
    elsif ($req->error == PE_RESETCERTIFICATE_FORMEMPTY
        || $req->error == PE_RESETCERTIFICATE_INVALID )
    {
        $self->logger->debug('Display Certificate Reset form');
        $tplPrm{DISPLAY_CERTIF_FORM} = 1;
    }

    return 'certificateReset', \%tplPrm;
}

#string getCertifResetSession (string mail)
# Check if a certificate reset session exists
# @param mail the value of the mail key in session
# @return the first session id found or nothing if no session
sub getCertificateSession {
    my ( $self, $user ) = @_;
    my $moduleOptions = $self->conf->{globalStorageOptions} || {};
    $moduleOptions->{backend} = $self->conf->{globalStorage};
    my $module = "Lemonldap::NG::Common::Apache::Session";

    # Search on modifyaccount sessions
    my $sessions = $module->searchOn( $moduleOptions, "user", $user );

    # Browse found sessions to check if it's a modifyaccount session
    foreach my $id ( keys %$sessions ) {
        my $certificateResetSession =
          $self->p->getApacheSession( $id, ( kind => "TOKEN" ) );
        next unless ($certificateResetSession);
        return $certificateResetSession
          if (  $certificateResetSession->data->{_type}
            and $certificateResetSession->data->{_type} =~ /^certificate$/ );
    }

    # No modifyaccount session found, return empty string
    return "";
}

sub checkCertificateValidity {
    my ( $self, $notAfter, $delay ) = @_;
    my $dtNow;    # now in format DateTime
    my $days;     # difference between NotAfter and now
    my $f          = DateTime::Format::RFC3339->new();
    my $dtNotAfter = $f->parse_datetime($notAfter);
    $self->userLogger->debug("Not After Date: $dtNotAfter");

    $dtNow = DateTime->now;
    $days  = $dtNotAfter->delta_days($dtNow)->delta_days;
    $dtNow->add_duration( DateTime::Duration->new( days => $delay ) );

    # test if ( now + $validity ) > certificate_expiration
    if ( DateTime::compare( $dtNow, $dtNotAfter ) >= 0 ) {

        # certificate is about to expire
        $self->userLogger->debug(
            "Certificate is about to expire or already expired");
        return 0;
    }
    else {
        # certificate is still valid
        $self->userLogger->debug("Certificate is still valid for $days days");
        return 1;
    }
}

sub certificateHash {
    my ( $self, $file ) = @_;
    my $cert;

    {
        local $/ = undef;    # Slurp mode
        open CERT, "$file" or die;
        $cert = <CERT>;
        close CERT;
    }

    # Normalize certificate
    $cert =~ s/-----(BEGIN|END) CERTIFICATE-----//gi;
    $cert =~ s/["]//gi;
    $cert = decode_base64($cert);

    #$self->userLogger->debug( "UserBinary::".$cert);
    return $cert;
}

1;

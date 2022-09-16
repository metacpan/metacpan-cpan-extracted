package Lemonldap::NG::Portal::Lib::Code2F;

# Base class for 2F methods that work by
# * optionally generating a code
# * delivering the code through an external system (mail/rest/shell...)
# * validating that the input code is the correct one

use strict;
use Mouse;

use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_NOTOKEN
  PE_TOKENEXPIRED
  PE_ERROR
  PE_BADOTP
  PE_FORMEMPTY
  PE_SENDRESPONSE
);

has resend_interval => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        $_[0]->{conf}->{ $_[0]->type . '2fResendInterval' } || 0;
    }
);

has code_activation => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        $_[0]->{conf}->{ $_[0]->type . '2fCodeActivation' };
    }
);

has random => ( is => 'rw' );

our $VERSION = '2.0.15';

extends 'Lemonldap::NG::Portal::Main::SecondFactor';

sub init {
    my ($self) = @_;
    if ( $self->code_activation ) {
        $self->random( Lemonldap::NG::Common::Crypto::srandom() );
    }

    $self->addUnauthRoute(
        $self->prefix . '2fresend' => '_resend',
        ['POST']
    );

    $self->addAuthRoute(
        $self->prefix . '2fresend' => '_resend',
        ['POST']
    );

    return $self->SUPER::init();
}

sub run {
    my ( $self, $req, $token ) = @_;

    # Generate Code to send
    my $code;
    if ( $self->code_activation ) {
        $code = $self->random->randregex( $self->code_activation );
        $self->logger->debug( "Generated " . $self->type . "2f code : $code" );
        $self->ott->updateToken( $token,
            '__' . $self->type . '2fcode' => $code );
    }

    return PE_ERROR unless $self->sendCode( $req, $req->sessionInfo, $code );

    $self->logger->debug("Prepare external 2F verification");
    my $tmp =
      $self->sendCodeForm( $req, TOKEN => $token, LEGEND => $self->legend );

    $req->response($tmp);
    return PE_SENDRESPONSE;
}

sub _resend {
    my ( $self, $req ) = @_;

    # Check token
    my $token;
    unless ( $token = $req->param('token') ) {
        $self->userLogger->error( $self->type . ' 2F access without token' );
        eval { $self->setSecurity($req) };
        $req->mustRedirect(1);
        return $self->p->do( $req, [ sub { PE_NOTOKEN } ] );
    }

    my $session;

    # Do not invalidate the token while getting it
    unless ( $session = $self->ott->getToken( $token, 1 ) ) {
        $self->userLogger->info('Token expired');
        $self->setSecurity($req);
        return $self->p->do( $req, [ sub { PE_TOKENEXPIRED } ] );
    }

    my $code = $session->{ '__' . $self->type . '2fcode' };

    my $legend = $self->legend;

    # Timer
    my $lastretry =
      $session->{__lastRetry} || $session->{tokenSessionStartTimestamp} || time;
    if ( $self->resend_interval
        and ( $lastretry + $self->resend_interval < time ) )
    {

        # Resend code and update last retry
        return PE_ERROR unless $self->sendCode( $req, $session, $code );
        $self->ott->updateToken( $token, __lastRetry => time );
    }
    else {
        $legend = "resendTooSoon";
    }

    return $self->sendCodeForm( $req, TOKEN => $token, LEGEND => $legend );
}

sub verify {
    my ( $self, $req, $session ) = @_;
    my $usercode;
    unless ( $usercode = $req->param('code') ) {
        $self->userLogger->error( $self->type . '2f: no code found' );
        return PE_FORMEMPTY;
    }

    if ( $self->code_activation ) {
        return $self->verify_internal( $req, $session, $usercode );
    }
    else {
        return $self->verify_external( $req, $session, $usercode );
    }
}

sub verify_internal {
    my ( $self, $req, $session, $code ) = @_;

    my $savedcode = $session->{ '__' . $self->type . '2fcode' };
    unless ($savedcode) {
        $self->logger->error(
            'Unable to find generated 2F code in token session');
        return PE_ERROR;
    }

    $self->logger->debug(
        "Verifying " . $self->type . "2f code: $code VS $savedcode" );
    if ( $code eq $savedcode ) {
        return PE_OK;
    }
    else {
        $self->userLogger->warn( 'Second factor failed for '
              . $session->{ $self->conf->{whatToTrace} } );
        return PE_BADOTP;
    }
}

sub sendCodeForm {
    my ( $self, $req, %params ) = @_;

    my $checkLogins = $req->param('checkLogins');
    $self->logger->debug( $self->type . "2f: checkLogins set" )
      if $checkLogins;

    my $stayconnected = $req->param('stayconnected');
    $self->logger->debug( $self->type . "2f: stayconnected set" )
      if $stayconnected;

    # Prepare form
    return $self->p->sendHtml(
        $req,
        'ext2fcheck',
        params => {
            MAIN_LOGO => $self->conf->{portalMainLogo},
            SKIN      => $self->p->getSkin($req),
            PREFIX    => $self->prefix,
            (
                $self->resend_interval
                ? ( RESENDTARGET => '/'
                      . $self->prefix
                      . '2fresend?skin='
                      . $self->p->getSkin($req) )
                : ()
            ),
            TARGET => '/'
              . $self->prefix
              . '2fcheck?skin='
              . $self->p->getSkin($req),
            CHECKLOGINS   => $checkLogins,
            STAYCONNECTED => $stayconnected,
            %params,
        }
    );
}

1;

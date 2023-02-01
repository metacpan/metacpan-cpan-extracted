# TOTP second factor authentication
#
# This plugin handle authentications to ask TOTP second factor for users that
# have registered their TOTP secret
package Lemonldap::NG::Portal::2F::TOTP;

use strict;
use Mouse;
use JSON qw(from_json to_json);
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_BADOTP
  PE_FORMEMPTY
  PE_SENDRESPONSE
);

our $VERSION = '2.0.16';

extends qw(
  Lemonldap::NG::Portal::Main::SecondFactor
  Lemonldap::NG::Common::TOTP
);
with 'Lemonldap::NG::Portal::Lib::2fDevices';

# INITIALIZATION

has prefix => ( is => 'ro', default => 'totp' );
has logo   => ( is => 'rw', default => 'totp.png' );

sub init {
    my ($self) = @_;

    # If "activation" is just set to "enabled",
    # replace the rule to detect if user has registered its key
    $self->conf->{totp2fActivation} = 'has2f("TOTP")'
      if $self->conf->{totp2fActivation} eq '1';

    return $self->SUPER::init();
}

# RUNNING METHODS

sub run {
    my ( $self, $req, $token ) = @_;
    $self->logger->debug( $self->prefix . '2f: generate form' );

    # Prepare form
    my ( $checkLogins, $stayConnected ) = $self->getFormParams($req);
    my $tmp = $self->p->sendHtml(
        $req,
        'totp2fcheck',
        params => {
            TOKEN         => $token,
            CHECKLOGINS   => $checkLogins,
            STAYCONNECTED => $stayConnected
        }
    );
    $self->logger->debug( $self->prefix . '2f: prepare verification' );

    $req->response($tmp);
    return PE_SENDRESPONSE;
}

sub verify {
    my ( $self, $req, $session ) = @_;
    my ( $code, $secret, @totp2f );
    $self->logger->debug( $self->prefix . '2f: verification' );

    unless ( $code = $req->param('code') ) {
        $self->userLogger->error( $self->prefix . '2f: no code provided' );
        return PE_FORMEMPTY;
    }

    @totp2f = $self->find2fDevicesByType( $req, $session, $self->type );
    $secret = $_->{_secret} foreach @totp2f;
    unless ($secret) {
        $self->logger->debug( $self->prefix . '2f: no secret found' );
        return PE_BADOTP;
    }

    my $r = $self->verifyCode(
        $self->conf->{totp2fInterval},
        $self->conf->{totp2fRange},
        $self->conf->{totp2fDigits},
        $secret, $code
    );
    return PE_ERROR if $r == -1;

    if ($r) {
        $self->userLogger->info( $self->prefix . '2f: succeed' );
        return PE_OK;
    }
    else {
        $self->userLogger->notice( $self->prefix
              . '2f: invalid attempt for '
              . $session->{ $self->conf->{whatToTrace} } );
        return PE_BADOTP;
    }
}

1;

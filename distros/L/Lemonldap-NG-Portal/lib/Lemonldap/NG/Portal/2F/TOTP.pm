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
use Lemonldap::NG::Common::Util qw/display2F/;

our $VERSION = '2.19.0';

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
    my $tmp = $self->p->sendHtml(
        $req,
        'totp2fcheck',
        params => {
            TOKEN => $token,
            $self->get2fTplParams($req),
        }
    );
    $self->logger->debug( $self->prefix . '2f: prepare verification' );

    $req->response($tmp);
    return PE_SENDRESPONSE;
}

sub verify {
    my ( $self, $req, $session ) = @_;
    my ( $code, $secret, @totp2f );
    my $uid = $session->{ $self->conf->{whatToTrace} };
    $self->logger->debug( $self->prefix . '2f: verification' );

    unless ( $code = $req->param('code') ) {
        $self->userLogger->error( $self->prefix . '2f: no code provided' );
        return PE_FORMEMPTY;
    }

    @totp2f = $self->find2fDevicesByType( $req, $session, $self->type );

    foreach my $device (@totp2f) {
        $self->logger->debug( "Trying TOTP device " . display2F($device) );

        if ( my $secret = $device->{_secret} ) {
            my ( $r, $range ) = $self->verifyCode(
                $self->conf->{totp2fInterval},
                $self->conf->{totp2fRange},
                $self->conf->{totp2fDigits},
                $secret, $code
            );
            if ( $r == 1 ) {
                $req->data->{_2fDevice}  = $device;
                $req->data->{_2fLogInfo} = { range => $range };
                return PE_OK;
            }
        }
        else {
            $self->logger->warn( "TOTP device "
                  . display2F($device)
                  . " has no secret for user $uid" );
        }
    }

    $self->userLogger->notice( $self->prefix
          . '2f: code did not match any of the registered TOTP for '
          . $uid );
    return PE_BADOTP;
}

1;

# TOTP second factor authentication
#
# This plugin handle authentications to ask TOTP second factor for users that
# have registered their TOTP secret
package Lemonldap::NG::Portal::2F::TOTP;

use strict;
use Mouse;
use JSON qw(from_json to_json);
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_BADCREDENTIALS
  PE_ERROR
  PE_FORMEMPTY
  PE_OK
  PE_SENDRESPONSE
);

our $VERSION = '2.0.0';

extends 'Lemonldap::NG::Portal::Main::SecondFactor',
  'Lemonldap::NG::Common::TOTP';

# INITIALIZATION

has prefix => ( is => 'ro', default => 'totp' );

has logo => ( is => 'rw', default => 'totp.png' );

sub init {
    my ($self) = @_;

    # If self registration is enabled and "activation" is just set to
    # "enabled", replace the rule to detect if user has registered its key
    if (    $self->conf->{totp2fSelfRegistration}
        and $self->conf->{totp2fActivation} eq '1' )
    {
        $self->conf->{totp2fActivation} =
          '$_2fDevices && $_2fDevices =~ /"type":\s*"TOTP"/s';
    }
    return $self->SUPER::init();
}

# RUNNING METHODS

sub run {
    my ( $self, $req, $token ) = @_;
    $self->logger->debug('Generate TOTP form');

    my $checkLogins = $req->param('checkLogins');
    $self->logger->debug("TOTP checkLogins set") if ($checkLogins);

    # Prepare form
    my $tmp = $self->p->sendHtml(
        $req,
        'totp2fcheck',
        params => {
            MAIN_LOGO   => $self->conf->{portalMainLogo},
            SKIN        => $self->p->getSkin($req),
            TOKEN       => $token,
            CHECKLOGINS => $checkLogins
        }
    );
    $self->logger->debug("Prepare TOTP 2F verification");

    $req->response($tmp);
    return PE_SENDRESPONSE;
}

sub verify {
    my ( $self, $req, $session ) = @_;
    $self->logger->debug('TOTP verification');
    my $code;
    unless ( $code = $req->param('code') ) {
        $self->userLogger->error('TOTP 2F: no code');
        return PE_FORMEMPTY;
    }

    my $secret = '';
    my $_2fDevices;
    if ( $session->{_2fDevices} ) {
        $self->logger->debug("Loading 2F Devices ...");

        # Read existing 2FDevices
        $_2fDevices =
          eval { from_json( $session->{_2fDevices}, { allow_nonref => 1 } ); };
        if ($@) {
            $self->logger->error("Bad encoding in _2fDevices: $@");
            return PE_ERROR;
        }
        $self->logger->debug("2F Device(s) found");
        foreach (@$_2fDevices) {
            $self->logger->debug("Reading TOTP secret if exists ...");
            if ( $_->{type} eq 'TOTP' ) {
                $secret = $_->{_secret};
                last;
            }
        }
    }

    unless ($secret) {
        $self->logger->debug("No TOTP secret found");
        return PE_BADCREDENTIALS;
    }

    my $r = $self->verifyCode(
        $self->conf->{totp2fInterval},
        $self->conf->{totp2fRange},
        $self->conf->{totp2fDigits},
        $secret, $code
    );
    if ( $r == -1 ) { return PE_ERROR; }
    elsif ($r) {
        $self->userLogger->info('TOTP succeed');
        return PE_OK;
    }
    else {
        $self->userLogger->notice( 'Invalid TOTP for '
              . $session->{ $self->conf->{whatToTrace} }
              . ')' );
        return PE_BADCREDENTIALS;
    }
}

1;

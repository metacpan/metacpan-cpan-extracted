# Yubico OTP second factor authentication
#
# This plugin handle authentications to ask Yubikey second factor for users that
# have registered their Yubikey using legacy OTP mode
package Lemonldap::NG::Portal::2F::Yubikey;

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

extends 'Lemonldap::NG::Portal::Main::SecondFactor';
with 'Lemonldap::NG::Portal::Lib::2fDevices';

# INITIALIZATION

has type   => ( is => 'rw', default => 'UBK' );
has prefix => ( is => 'ro', default => 'yubikey' );
has logo   => ( is => 'rw', default => 'yubikey.png' );
has yubi   => ( is => 'rw' );

sub init {
    my ($self) = @_;

    eval { require Auth::Yubikey_WebClient };
    if ($@) {
        $self->logger->error("Can't load Yubikey_WebClient  library: $@");
        $self->error("Can't load Yubikey_WebClient library: $@");
        return 0;
    }

    # Try to be smart about Yubikey 2F activation
    if ( $self->conf->{yubikey2fActivation} eq '1' ) {
        my @newrules;

        # If self registration is enabled,
        # detect if user has registered its key
        push @newrules, 'has2f("UBK")'
          if $self->conf->{yubikey2fSelfRegistration};

        # If Yubikey looked up from an attribute, test attribute's presence
        if ( $self->conf->{yubikey2fFromSessionAttribute} ) {
            my $attr = $self->conf->{yubikey2fFromSessionAttribute};
            push @newrules, "\$$attr";
        }

        # Aggregate rules
        if (@newrules) {
            my $rule = join( " || ", @newrules );
            $self->conf->{yubikey2fActivation} = $rule;
            $self->logger->debug(
                $self->prefix . "2f: activation rule -> $rule" );
        }
    }

    unless ($self->conf->{yubikey2fClientID}
        and $self->conf->{yubikey2fSecretKey} )
    {
        $self->error( $self->prefix
              . '2f: missing mandatory parameters (client ID or secret key)' );
        return 0;
    }

    $self->yubi(
        Auth::Yubikey_WebClient->new( {
                id  => $self->conf->{yubikey2fClientID},
                api => $self->conf->{yubikey2fSecretKey},
                (
                    $self->conf->{yubikey2fNonce}
                    ? ( nonce => $self->conf->{yubikey2fNonce} )
                    : ()
                ),
                (
                    $self->conf->{yubikey2fUrl}
                    ? ( url => $self->conf->{yubikey2fUrl} )
                    : ()
                )
            }
        )
    );
    return $self->SUPER::init();
}

sub _findYubikey {
    my ( $self, $req, $session ) = @_;
    my ( $yubikey, @ubk2f );

    # First, lookup from session attribute
    if ( $self->conf->{yubikey2fFromSessionAttribute} ) {
        my $attr = $self->conf->{yubikey2fFromSessionAttribute};
        $yubikey = $session->{$attr};
    }

    # If we didn't find a key, lookup psession
    if ( !$yubikey and $session->{_2fDevices} ) {
        @ubk2f = $self->find2fDevicesByType( $req, $session, $self->type );
        if ( my $code = $req->param('code') ) {
            $yubikey = $_->{_yubikey} foreach grep {
                $_->{_yubikey} eq
                  substr( $code, 0, $self->conf->{yubikey2fPublicIDSize} )
            } @ubk2f;
        }
        else {
            $yubikey = $_->{_yubikey} foreach @ubk2f;
        }
    }

    return $yubikey || '';
}

sub run {
    my ( $self, $req, $token ) = @_;
    my $yubikey = $self->_findYubikey( $req, $req->sessionInfo );
    unless ($yubikey) {
        $self->userLogger->warn( $self->prefix
              . '2f: user '
              . $req->{sessionInfo}->{ $self->conf->{whatToTrace} }
              . ' has no device registered' );
        return PE_BADOTP;
    }
    $self->logger->debug( $self->prefix . "2f: found $yubikey" );

    # Prepare form
    my ( $checkLogins, $stayConnected ) = $self->getFormParams($req);
    my $tmp = $self->p->sendHtml(
        $req,
        'ext2fcheck',
        params => {
            TOKEN         => $token,
            TARGET        => '/yubikey2fcheck?skin=' . $self->p->getSkin($req),
            INPUTLOGO     => $self->logo,
            LEGEND        => 'clickOnYubikey',
            CHECKLOGINS   => $checkLogins,
            STAYCONNECTED => $stayConnected
        }
    );
    $self->logger->debug( $self->prefix . '2f: display form' );

    $req->response($tmp);
    return PE_SENDRESPONSE;
}

sub verify {
    my ( $self, $req, $session ) = @_;
    my $code;
    unless ( $code = $req->param('code') ) {
        $self->userLogger->error( $self->prefix . '2f: no code provided' );
        return PE_FORMEMPTY;
    }

    # Verify OTP
    my $yubikey = $self->_findYubikey( $req, $session );
    if (
        index( $yubikey,
            substr( $code, 0, $self->conf->{yubikey2fPublicIDSize} ) ) == -1
      )
    {
        $self->userLogger->warn( $self->prefix . '2f: device not registered' );
        return PE_BADOTP;
    }

    $self->logger->debug( $self->prefix
          . "2f: validating $code of $yubikey against external API" );
    if ( $self->yubi->otp($code) ne 'OK' ) {
        $self->userLogger->warn( $self->prefix . '2f: verification failed' );
        return PE_BADOTP;
    }
    return PE_OK;
}

1

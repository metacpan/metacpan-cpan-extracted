# Yubikey second factor authentication
#
# This plugin handle authentications to ask Yubikey second factor for users that
# have registered their Yubikey
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

our $VERSION = '2.0.12';

extends 'Lemonldap::NG::Portal::Main::SecondFactor';

# INITIALIZATION

has prefix => ( is => 'ro', default => 'yubikey' );
has logo   => ( is => 'rw', default => 'yubikey.png' );
has yubi   => ( is => 'rw' );

sub init {
    my ($self) = @_;
    eval { require Auth::Yubikey_WebClient };
    if ($@) {
        $self->logger->error($@);
        return 0;
    }

    # Try to be smart about Yubikey 2F activation
    if ( $self->conf->{yubikey2fActivation} eq '1' ) {
        my @newrules;

        # If self registration is enabled, detect if user has registered its
        # key
        if ( $self->conf->{yubikey2fSelfRegistration} ) {
            push @newrules, '$_2fDevices && $_2fDevices =~ /"type":\s*"UBK"/s';
        }

        # If Yubikey looked up from an attribute, test attribute's presence
        if ( $self->conf->{yubikey2fFromSessionAttribute} ) {
            my $attr = $self->conf->{yubikey2fFromSessionAttribute};
            push @newrules, "\$$attr";
        }

        # Aggregate rules
        if (@newrules) {
            my $rule = join( " || ", @newrules );
            $self->conf->{yubikey2fActivation} = $rule;
            $self->logger->debug("Yubikey activation rule: $rule");
        }
    }

    unless ($self->conf->{yubikey2fClientID}
        and $self->conf->{yubikey2fSecretKey} )
    {
        $self->error('Missing mandatory parameters (Client ID and secret key)');
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
    my ( $self, $req, $sessionInfo ) = @_;
    my ( $yubikey, $_2fDevices );

    # First, lookup from session attribute
    if ( $self->conf->{yubikey2fFromSessionAttribute} ) {
        my $attr = $self->conf->{yubikey2fFromSessionAttribute};
        $yubikey = $sessionInfo->{$attr};
    }

    # If we didn't find a key, lookup psession
    if ( !$yubikey and $sessionInfo->{_2fDevices} ) {
        $self->logger->debug("Loading 2F Devices...");

        # Read existing 2FDevices
        $_2fDevices = eval {
            from_json( $sessionInfo->{_2fDevices}, { allow_nonref => 1 } );
        };
        if ($@) {
            $self->logger->error("Bad encoding in _2fDevices: $@");
            return PE_ERROR;
        }
        $self->logger->debug("2F Device(s) found");
        $self->logger->debug("Reading Yubikey...");

        if ( my $code = $req->param('code') ) {
            $yubikey = $_->{_yubikey} foreach grep {
                ( $_->{type} eq 'UBK' )
                  and ( $_->{_yubikey} eq
                    substr( $code, 0, $self->conf->{yubikey2fPublicIDSize} ) )
            } @$_2fDevices;
        }
        else {
            $yubikey = $_->{_yubikey}
              foreach grep { $_->{type} eq 'UBK' } @$_2fDevices;
        }
    }

    return $yubikey;

}

sub run {
    my ( $self, $req, $token, $_2fDevices ) = @_;

    my $checkLogins = $req->param('checkLogins');
    $self->logger->debug("Yubikey; checkLogins set") if $checkLogins;

    my $stayconnected = $req->param('stayconnected');
    $self->logger->debug("Yubikey: stayconnected set") if $stayconnected;

    my $yubikey = $self->_findYubikey( $req, $req->sessionInfo );

    unless ($yubikey) {
        $self->userLogger->warn( 'User '
              . $req->{sessionInfo}->{ $self->conf->{whatToTrace} }
              . ' has no Yubikey registered' );
        return PE_BADOTP;
    }
    $self->logger->debug("Found Yubikey : $yubikey");

    # Prepare form
    my $tmp = $self->p->sendHtml(
        $req,
        'ext2fcheck',
        params => {
            MAIN_LOGO     => $self->conf->{portalMainLogo},
            SKIN          => $self->p->getSkin($req),
            TOKEN         => $token,
            TARGET        => '/yubikey2fcheck?skin=' . $self->p->getSkin($req),
            INPUTLOGO     => 'yubikey.png',
            LEGEND        => 'clickOnYubikey',
            CHECKLOGINS   => $checkLogins,
            STAYCONNECTED => $stayconnected
        }
    );
    $self->logger->debug("Display Yubikey form");

    $req->response($tmp);
    return PE_SENDRESPONSE;
}

sub verify {
    my ( $self, $req, $session ) = @_;
    my $code;
    unless ( $code = $req->param('code') ) {
        $self->userLogger->error('Yubikey 2F: no code');
        return PE_FORMEMPTY;
    }

    # Verify OTP
    my $yubikey = $self->_findYubikey( $req, $session );

    if (
        index( $yubikey,
            substr( $code, 0, $self->conf->{yubikey2fPublicIDSize} ) ) == -1
      )
    {
        $self->userLogger->warn('Yubikey not registered');
        return PE_BADOTP;
    }

    $self->logger->debug(
        "Validating $code of yubikey $yubikey against external API");
    if ( $self->yubi->otp($code) ne 'OK' ) {
        $self->userLogger->warn('Yubikey verification failed');
        return PE_BADOTP;
    }
    return PE_OK;
}

1

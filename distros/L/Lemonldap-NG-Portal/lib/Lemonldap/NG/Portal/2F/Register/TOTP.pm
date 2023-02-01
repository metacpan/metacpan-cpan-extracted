# Self TOTP registration
package Lemonldap::NG::Portal::2F::Register::TOTP;

use strict;
use Mouse;
use JSON qw(from_json to_json);

our $VERSION = '2.0.16';

extends qw(
  Lemonldap::NG::Portal::2F::Register::Base
  Lemonldap::NG::Common::TOTP
);
with 'Lemonldap::NG::Portal::Lib::2fDevices';

# INITIALIZATION

has logo     => ( is => 'rw', default => 'totp.png' );
has prefix   => ( is => 'rw', default => 'totp' );
has template => ( is => 'ro', default => 'totp2fregister' );
has welcome  => ( is => 'ro', default => 'yourNewTotpKey' );
has ott => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $ott =
          $_[0]->{p}->loadModule('Lemonldap::NG::Portal::Lib::OneTimeToken');
        my $timeout = $_[0]->{conf}->{sfRegisterTimeout}
          // $_[0]->{conf}->{formTimeout};
        $ott->timeout($timeout);
        return $ott;
    }
);

sub run {
    my ( $self, $req, $action ) = @_;
    my $user = $req->userData->{ $self->conf->{whatToTrace} };
    return $self->p->sendError( $req, 'PE82', 400 )
      unless $user;

    # Verification that user has a valid TOTP app
    if ( $action eq 'verify' ) {

        # Get form token
        my $token = $req->param('token');
        unless ($token) {
            $self->userLogger->warn( $self->prefix
                  . "2f: registration -> attempt without token for $user" );
            return $self->p->sendError( $req, 'noTOTPFound', 400 );
        }

        # Verify that token exists in DB (note that "keep" flag is set to
        # permit more than 1 try during token life
        unless ( $token = $self->ott->getToken( $token, 1 ) ) {
            $self->userLogger->notice(
                $self->prefix . "2f: registration -> token expired for $user" );
            return $self->p->sendError( $req, 'PE82', 400 );
        }

        # Token is valid, so we have the master key proposed
        # ($token->{_totp2fSecret})

        # Now check TOTP code to verify that user has a valid TOTP app
        my $code = $req->param('code');
        unless ($code) {
            $self->userLogger->info(
                $self->prefix . '2f: registration -> empty validation form' );
            return $self->p->sendError( $req, 'missingCode', 400 );
        }

        my $TOTPName =
          $self->checkNameSfa( $req, $self->type, $req->param('TOTPName') );
        return $self->p->sendError( $req, 'badName', 200 ) unless $TOTPName;

        my $r = $self->verifyCode(
            $self->conf->{totp2fInterval},
            $self->conf->{totp2fRange},
            $self->conf->{totp2fDigits},
            $token->{_totp2fSecret}, $code
        );
        return $self->p->sendError( $req, 'serverError' ) if $r == -1;

        # Invalid try is returned with a 200 code. Javascript will read error
        # and propose to retry
        if ( $r == 0 ) {
            $self->userLogger->notice(
                $self->prefix . "2f: registration -> invalid code for $user" );
            return $self->p->sendError( $req, 'badCode', 200 );
        }

        $self->logger->debug( $self->prefix . '2f: code verified' );

        # Test if a TOTP is already registered
        my @totp2f =
          $self->find2fDevicesByType( $req, $req->userData, $self->type );
        return $self->p->sendError( $req, 'totpExistingKey', 200 )
          if scalar @totp2f;

        $self->logger->debug( $self->prefix . '2f: no secret found' );
        my $storable_secret =
          $self->get_storable_secret( $token->{_totp2fSecret} );
        unless ($storable_secret) {
            $self->logger->error(
                $self->prefix . '2f: unable to encrypt secret' );
            return $self->p->sendError( $req, "serverError" );
        }

        # Store TOTP secret
        if (
            $self->add2fDevice(
                $req,
                $req->userData,
                {
                    _secret => $storable_secret,
                    type    => $self->type,
                    name    => $TOTPName,
                    epoch   => time()
                }
            )
          )
        {
            $self->userLogger->notice( $self->prefix
                  . "2f: registration of $TOTPName succeeds for $user" );
            return [
                200,
                [
                    'Content-Type'   => 'application/json',
                    'Content-Length' => 12,
                ],
                ['{"result":1}']
            ];
        }
        else {
            $self->logger->debug( $self->prefix . "2f: unable to add device" );
            return $self->p->sendError( $req, 'serverError' );
        }
    }

    # Get or generate master key
    elsif ( $action eq 'getkey' ) {
        my ( $nk, $secret, $issuer ) = ( 0, '' );

        # Read existing TOTP 2F
        my @totp2f =
          $self->find2fDevicesByType( $req, $req->userData, $self->type );

        # Loading TOTP secret
        $self->logger->debug(
            $self->prefix . '2f: read existing secret(s)...' );
        $secret = $_->{_secret} foreach (@totp2f);
        return $self->p->sendError( $req, 'totpExistingKey', 200 ) if $secret;

        $secret = $self->newSecret;
        $self->logger->debug(
            $self->prefix . "2f: generate new secret ($secret)" );
        $nk = 1;

        # Secret is stored in a token: we choose to not accept secret returned
        # by Ajax request to avoid some attacks
        my $token = $self->ott->createToken( {
                _totp2fSecret => $secret,
            }
        );
        unless ( $issuer = $self->conf->{totp2fIssuer} ) {
            $issuer = $self->conf->{portal};
            $issuer =~ s#^https?://([^/:]+).*$#$1#;
        }

        # QR-code will be generated by a javascript, here we just send data
        return $self->p->sendJSONresponse(
            $req,
            {
                secret   => $secret,
                token    => $token,
                portal   => $issuer,
                user     => $user,
                newkey   => $nk,
                digits   => $self->conf->{totp2fDigits},
                interval => $self->conf->{totp2fInterval}
            }
        );
    }

    # Delete TOTP
    elsif ( $action eq 'delete' ) {

        # Check if unregistration is allowed
        return $self->p->sendError( $req, 'notAuthorized', 400 )
          unless $self->userCanRemove;

        my $epoch = $req->param('epoch')
          or return $self->p->sendError( $req,
            $self->prefix . '2f: "epoch" parameter is missing', 400 );
        if ( $self->del2fDevice( $req, $req->userData, $self->type, $epoch ) ) {
            $self->userLogger->notice(
                $self->prefix . "2f: device deleted for $user" );
            return [
                200,
                [
                    'Content-Type'   => 'application/json',
                    'Content-Length' => 12,
                ],
                ['{"result":1}']
            ];
        }
        $self->logger->error( $self->prefix . "2f: device not found" );
        return $self->p->sendError( $req, '2FDeviceNotFound', 400 );
    }

    else {
        $self->logger->error( $self->prefix . "2f: unknown action ($action)" );
        return $self->p->sendError( $req, 'unknownAction', 400 );
    }
}

1;

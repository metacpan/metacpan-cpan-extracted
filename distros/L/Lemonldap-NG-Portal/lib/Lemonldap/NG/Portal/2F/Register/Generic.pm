# A generic 2FA module which registers a simple value into the psession
# This is meant to be used with sfExtra
package Lemonldap::NG::Portal::2F::Register::Generic;

use strict;
use Mouse;
use JSON qw(from_json to_json);
use Lemonldap::NG::Common::Crypto;
use Lemonldap::NG::Portal::Main::Constants 'PE_OK';

our $VERSION = '2.0.16';

extends 'Lemonldap::NG::Portal::2F::Register::Base';
with 'Lemonldap::NG::Portal::Lib::2fDevices';

# INITIALIZATION

has ott => (
    is      => 'ro',
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

# The verification module that we'll use
has verificationModule => (
    is       => 'rw',
    isa      => 'Lemonldap::NG::Portal::Lib::Code2F',
    weak_ref => 1,
);

# Overriden by sfExtra
has logo     => ( is => 'rw', default => 'generic.png' );
has prefix   => ( is => 'rw', default => 'generic' );
has template => ( is => 'ro', default => 'generic2fregister' );
has welcome  => ( is => 'ro', default => 'generic2fwelcome' );

sub run {
    my ( $self, $req, $action ) = @_;
    my $user = $req->userData->{ $self->conf->{whatToTrace} };
    return $self->p->sendError( $req, 'PE82', 400 )
      unless $user;

    # Send a code to generic
    if ( $action eq 'sendcode' ) {
        my $generic = $req->param('generic');

        unless ($generic) {
            $self->userLogger->info(
                $self->prefix . "2f: registration -> empty validation form" );
            return $self->p->sendError( $req, 'PE79', 200 );
        }

        # Generate and send code

        # Save current session info into a token
        my $sessionInfo = { %{ $req->userData } };

        # Inject candidate value
        $sessionInfo->{destination} = $generic;
        my $token = $self->ott->createToken($sessionInfo);
        my $result =
          $self->verificationModule->challenge( $req, $sessionInfo, $token );
        return $self->p->sendError( $req, 'serverError' ) unless $result;

        # Send response
        $self->userLogger->notice( $self->prefix
              . "2f: send verification code to $generic for $user" );
        my $json_response = qq({"result":1,"token":"$token"});
        return [
            200,
            [
                'Content-Type'   => 'application/json',
                'Content-Length' => length($json_response),
            ],
            [$json_response]
        ];
    }

    # Verification that user has a valid generic
    elsif ( $action eq 'verify' ) {
        my $generic     = $req->param('generic');
        my $tokenid     = $req->param("token");
        my $genericcode = $req->param('genericcode');
        my $genericname = $self->checkNameSfa( $req, $self->prefix,
            $req->param('genericname') );
        return $self->p->sendError( $req, 'badName', 200 ) unless $genericname;

        # Verify code
        my $token = $self->ott->getToken( $tokenid, 1 );
        my $res = $self->verificationModule->verify_supplied_code( $req, $token,
            $genericcode );
        return $self->p->sendError( $req, "PE$res", 400 )
          unless ( $res == PE_OK );

        # Now generic is verified, let's store it in persistent data
        # Reading existing 2FDevices
        my @generic2f =
          $self->find2fDevicesByType( $req, $req->userData, $self->prefix );

        # Delete previous generic if any
        if (@generic2f) {
            if ( $self->del2fDevices( $req, $req->userData, \@generic2f ) ) {
                $self->logger->debug(
                    $self->prefix . "2f: old device(s) deleted" );
            }
            else {
                $self->logger->error(
                    $self->prefix . "2f: unable to delete old device(s)" );
                return $self->p->sendError( $req, 'serverError' );
            }
        }

        # Add a new one
        if (
            $self->add2fDevice(
                $req,
                $req->userData,
                {
                    _generic => $generic,
                    name     => $genericname,
                    type     => $self->prefix,
                    epoch    => time()
                }
            )
          )
        {
            $self->userLogger->notice( $self->prefix
                  . "2f: registration of $genericname succeeds for $user" );
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

    elsif ( $action eq 'delete' ) {

        # Check if unregistration is allowed
        return $self->p->sendError( $req, 'notAuthorized', 400 )
          unless $self->userCanRemove;

        my $epoch = $req->param('epoch')
          or return $self->p->sendError( $req,
            $self->prefix . '2f: "epoch" parameter is missing', 400 );

        if ( $self->del2fDevice( $req, $req->userData, $self->prefix, $epoch ) )
        {
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

